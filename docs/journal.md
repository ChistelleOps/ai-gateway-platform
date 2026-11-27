# Journal

## Day 1 (Mon 11/23)

- 
- Created public repo with folder structure, .gitignore, design doc and plan
- Turned on secret scanning and push protection
- Created project board and Sprint 1 issues (#1-#7)
- Tomorrow 5:00: Terraform remote state (#1) and budget alert (#2)

## Tue 11/24 — Ticket #1 remote state
- State migrated to S3 (bootstrap/terraform.tfstate). Plan = No changes.
- envs/dev backend initialized (key envs/dev/terraform.tfstate).
- Lock test: terraform console did not block. Held the lock with apply at the
  approval prompt instead. Second plan got 412 PreconditionFailed + Lock Info.
  .tflock file seen in S3, then released automatically.

## Tue 11/24 — Ticket #2 budget import
- Budget "billing-Budget" ($10/month) was created by hand in the console.
- Imported with an import block + plan -generate-config-out.
- Cleaned the generated draft: removed computed attributes (arn, id, tags_all),
  account ID, and moved the email to a variable (terraform.tfvars, gitignored).
- Plan = 1 to import, 0 to change. Then No changes.
- prevent_destroy tested with plan -destroy: blocked.

## Fri 11/27 — Day 4
- 4G swap via cloud-init (new server, hostname still OK).
- Docker redo: layers, namespaces, user network DNS, volumes.
- Ollama: 2 models, cold start 6.0s vs warm 2.1s, token usage.
- LiteLLM + Postgres + Redis + Ollama with Compose: all healthy,
  chat through the gateway, fallback tested, spend logged in Postgres.


