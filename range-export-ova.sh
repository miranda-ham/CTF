#!/usr/bin/env bash
# Usage: range-export-ova.sh <VM-name> <output.ova>
set -euo pipefail
VM="$1"; OUT="$2"
VBoxManage list runningvms | grep -q "\"$VM\"" && VBoxManage controlvm "$VM" poweroff
VBoxManage showvminfo "$VM" --machinereadable \
  | { grep -iE '"(SATA|SCSI|IDE)-[0-9]+-[0-9]+"=".*configdrive.*\.vmdk"' || true; } \
  | while IFS='=' read -r slot _; do
      slot="${slot//\"/}"
      ctl="${slot%-*-*}"; port="${slot#*-}"; port="${port%-*}"; dev="${slot##*-}"
      VBoxManage storageattach "$VM" --storagectl "$ctl" --port "$port" --device "$dev" --medium none
    done
VBoxManage export "$VM" -o "$OUT"
