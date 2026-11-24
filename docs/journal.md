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