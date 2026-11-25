#!/usr/bin/env bash
# Usage: ./scripts/tf-init.sh terraform/envs/dev
set -euo pipefail

LAYER="${1:?usage: tf-init.sh <layer folder>}"
cd "$(dirname "$0")/../$LAYER"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
sed "s/<ACCOUNT_ID>/$ACCOUNT_ID/" backend.hcl.example > backend.hcl

terraform init -backend-config=backend.hcl
