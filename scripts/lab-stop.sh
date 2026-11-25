#!/usr/bin/env bash
# Stop the lab server (disk and Elastic IP are kept).
set -euo pipefail
cd "$(dirname "$0")/../terraform/envs/dev"
ID=$(terraform output -raw lab_instance_id)
echo "Stopping $ID ..."
aws ec2 stop-instances --instance-ids "$ID" --output text > /dev/null
aws ec2 wait instance-stopped --instance-ids "$ID"
echo "Stopped. Compute billing has stopped. The disk and Elastic IP still
cost a little."
