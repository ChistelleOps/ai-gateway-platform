#!/usr/bin/env bash
 # Start the lab server and print how to connect.
 set -euo pipefail
 cd "$(dirname "$0")/../terraform/envs/dev"
 ID=$(terraform output -raw lab_instance_id)
 # Warn if your home IP changed (SSH would be blocked by the security group)
 MY_IP="$(curl -s https://checkip.amazonaws.com)/32"
 if ! grep -q "\"$MY_IP\"" terraform.tfvars; then
   echo "WARNING: your IP is now $MY_IP. Update my_ip_cidr in
 terraform.tfvars, then run terraform apply."
 fi
 echo "Starting $ID ..."
 aws ec2 start-instances --instance-ids "$ID" --output text > /dev/null
 aws ec2 wait instance-status-ok --instance-ids "$ID"
 echo "Ready: $(terraform output -raw lab_ssh)  (or: ssh ai-lab)"
