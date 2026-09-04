# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure("2") do |config|
# Base box: Ubuntu 22.04 LTS (Jammy Jellyfish)
# This is the official Canonical image
config.vm.box = "ubuntu/jammy64"
# Set hostname (visible in prompt, logs)
config.vm.hostname = "deepdive"
# Network configuration: Host-Only network
# This creates an isolated network between host and VMs
# The VM is NOT accessible from the internet
config.vm.network "private_network", type: "dhcp"
# VirtualBox-specific settings
config.vm.provider "virtualbox" do |vb|
# VM display name in VirtualBox Manager
vb.name = "DeepDive-CTF"
# Allocate 2 GB RAM (minimum for WordPress + MySQL + Elastic Agent)
vb.memory = "2048"
# Allocate 2 CPU cores (speeds up provisioning)
vb.cpus = 2
# Don't show VirtualBox GUI window (headless)
vb.gui = false
# Linked clone (faster, uses less disk space)
vb.linked_clone = false
end
# Provisioning: Use ansible_local (runs Ansible INSIDE the VM)
# This avoids Python/conda conflicts on the host machine
config.vm.provision "ansible_local" do |ansible|
# Path to the playbook (relative to /vagrant inside the VM)
ansible.playbook = "ansible/playbook.yml"
# Verbose output (useful for debugging)
ansible.verbose = "v"
# Install Ansible automatically inside the VM
ansible.install = true
# Extra variables passed to Ansible
ansible.extra_vars = {
  # === Machine identity ===
  machine_hostname: "bluewater",

  # === User accounts ===
  divemaster_name: "divemaster",
  divemaster_password: "D1veM@ster2023!",   # recovered via SQLi on port 8080
  
  shopowner_name: "shopowner",
  shopowner_password: "BlueWater2019!",

  # === MySQL ===
  mysql_root_password: "c582a6dc2125e4ec12cbb0bbe180bc1f",

  # grafana_user: limited access - can query dive_logs, denied on dive_logs_archived and staff table
  grafana_db_user: "grafana_user",
  grafana_db_password: "Gr@f@n@DB2023!",   # exposed in grafana.ini via CVE-2021-43798

  # portal_user: used by staff portal Flask app internally
  portal_db_user: "portal_user",
  portal_db_password: "P0rt@lDB2023!",
  
  # === Database names ===
  db_public: "dive_logs",            # real records - grafana_user has SELECT
  db_internal: "bluewater_internal",         # falsified data and staff records

  # === Grafana ===
  grafana_admin_password: "BlueWater2023!",  # not on attack path, but must be set

  # === Staff portal (port 8080) ===
  # Credentials found in grafana.ini, used to log into portal before SQLi
  portal_admin_user: "admin",
  portal_admin_password: "BlueWater2023!",

  # === Flags ===
  user_flag: "FF{w3lc0m3_t0_blu3w4t3r_1nt3rn4l}",   # /home/divemaster/user.txt
  root_flag: "FF{th3_d4t4_n3v3r_l13s}",              # output of generate_report.py
}
end
# Post-provisioning message
config.vm.post_up_message = <<-MSG
DeepDive CTF machine is ready!
Access: http://192.168.56.101/ or http://localhost:8080/
SSH: ssh divemaster@192.168.56.101 (password: see Ansible vars)
To connect: vagrant ssh
To halt: vagrant halt
To rebuild: vagrant destroy && vagrant up
MSG
end
