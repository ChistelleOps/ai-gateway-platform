# Project Design Document: AI Gateway Platform

Christelle Nono Tigang · Version 1.0 · November 23, 2026 · Companion to the plan "AI Gateway Platform: Plan to the Team Interview"

**What this document is:** the design you write **before** building, like on a real team. It answers: **why** (objectives), **what** (architecture), **how** (sequence, tests, monitoring), and **what you deliver** (GitHub). The daily plan tells you **when**. Put this document in your repo as `docs/design.md`.

# 1. Objectives

## 1.1 The problem (from the Lincoln Lab screening)

An enterprise AI team runs an **AI gateway (LiteLLM)** and a **chat app (LibreChat)** on **Docker Swarm**, on Linux VMs. Usage grows **about 80% per month**, the service must become **tier 0** (no downtime), capacity planning is **manual**, and the platform must move to **Kubernetes on AWS** with **infrastructure as code**, so it can be **copied to an air-gapped classified environment**. The team also needs **usage reporting**.

## 1.2 Project objectives

| # | Objective |
|---|---|
| O1 | **Reproduce the current state:** LiteLLM + LibreChat + dependencies on Docker Swarm |
| O2 | **Build the target:** the same services on Kubernetes, deployed with **Terraform + GitOps** |
| O3 | **Migrate** with live traffic and real data, with a **gradual cutover** and a **tested rollback** |
| O4 | **Tier 0 basics:** replicas, health checks, safe rollouts, autoscaling, capacity numbers |
| O5 | **Observe the whole path:** synthetic end-to-end check, metrics, alerts |
| O6 | **Report usage:** per team, key and model, plus a management view |
| O7 | **Air-gapped mode:** run with **no internet**, from mirrored images |
| O8 | **Deep-review** Linux, Docker and Kubernetes fundamentals along the way |

## 1.3 Success criteria (how you know it worked)

| Objective | Pass criteria (measurable) |
|---|---|
| O1 | All 7 services run on Swarm; a request through LiteLLM gets a model answer; LibreChat chats work |
| O2 | `terraform apply` + ArgoCD sync creates everything from Git, with no manual steps |
| O3 | 100% traffic on Kubernetes; **all keys, spend totals and conversations match**; rollback **tested and timed**; user impact **measured in seconds** |
| O4 | A rolling update under load shows **0 failed requests**; HPA scales under a load test; DB connection math documented |
| O5 | Stopping the model makes an **alert fire within 2 minutes** |
| O6 | A dashboard shows requests, tokens and cost per team, from real data |
| O7 | With egress blocked, the platform **still answers** requests |
| O8 | Notes for the 7 Linux and 6 Kubernetes scenarios in `docs/` |

## 1.4 Scope

| In scope | Out of scope (and why) |
|---|---|
| LiteLLM, Postgres, Redis, Ollama, LibreChat, MongoDB, Meilisearch | LibreChat RAG API with pgvector (optional, if time) |
| Single-node Swarm and single-node k3s in AWS | Multi-node clusters (noted as a production difference) |
| Terraform for all AWS resources | Managed RDS/ElastiCache (discussed in docs as the production choice) |
| Synthetic check, Prometheus, Grafana, alerts | 24/7 on-call (described, not run) |
| EKS **after** the interview | A real classified environment (simulated by air-gapped mode) |


# 2. Architecture

## 2.1 Current state ("today"): Docker Swarm

```
                        +---------------------- swarm-node (EC2, 8 GB) ----------------------+
                        |                                                                     |
  Users / tools  ---->  |  LiteLLM x2 (:4000) ------> Ollama (:11434)  [small local model]     |
  (curl, scripts)       |      |      \                                                       |
                        |      |       +----> Redis (:6379)   [rate limits, shared state]     |
                        |      +------------> Postgres (:5432) [keys, teams, spend logs]      |
                        |                                                                     |
  Browser  ---------->  |  LibreChat (:3080) --> LiteLLM (virtual key)                        |
                        |      |---> MongoDB (:27017)     [users, conversations]              |
                        |      +---> Meilisearch (:7700)  [chat search]                       |
                        |                                                                     |
                        |  Docker Swarm: overlay network, Docker secrets, stack file          |
                        +---------------------------------------------------------------------+
```

## 2.2 Target state: Kubernetes (k3s) with GitOps

```
  GitHub repo (gitops/) --watched by--> ArgoCD
                                          |
                                          v
  +---------------------------- k3s-node (EC2, 8 GB) -----------------------------------+
  |  namespace: ai-gateway                                                              |
  |    LiteLLM Deployment x3  (readiness /health/readiness, PDB, HPA, maxUnavailable 0) |
  |    Postgres, Redis, Ollama                                                          |
  |  namespace: librechat                                                               |
  |    LibreChat, MongoDB, Meilisearch                                                  |
  |  namespace: monitoring                                                              |
  |    Prometheus, Grafana, Alertmanager, synthetic check (every minute)                |
  |  namespace: argocd                                                                  |
  |    ArgoCD (installed by Terraform helm provider)                                    |
  +-------------------------------------------------------------------------------------+
```

## 2.3 Migration setup (Days 9–10)

```
                              +----> swarm-node   (old)   weight 100 -> 50 -> 0
  traffic generator  -->  HAProxy
  synthetic check         (front)
                              +----> k3s-node     (new)   weight   0 -> 50 -> 100

  Data copy before cutover:  Postgres (pg_dump/restore), MongoDB (mongodump/restore)
  Same secrets on both:      LITELLM_MASTER_KEY, LITELLM_SALT_KEY
```

## 2.4 Components

| Component | Port | Role | Stateful? | Data to migrate |
|---|---|---|---|---|
| **LiteLLM** | 4000 | AI gateway: keys, budgets, rate limits, routing, spend | **No** | None (config in Git) |
| **Postgres** | 5432 | LiteLLM keys, teams, users, **spend logs** | **Yes** | **Yes**: dump/restore + validation |
| **Redis** | 6379 | Rate-limit counters, router state, cache | Mostly no | No (rebuilt on start) |
| **Ollama** | 11434 | Runs the small model (replaces Bedrock in the lab) | Model files | Re-pull or mirror the model |
| **LibreChat** | 3080 | Chat web app | **No** | None |
| **MongoDB** | 27017 | LibreChat users and conversations | **Yes** | **Yes**: dump/restore + validation |
| **Meilisearch** | 7700 | Chat search index | Index | Rebuild from MongoDB, or copy |
| HAProxy | 80, 8404 (stats) | Weighted traffic switch for the cutover | No | — |
| Prometheus / Grafana | 9090 / 3000 | Metrics, dashboards | Metrics | Not migrated |
| ArgoCD | 443 | GitOps deployment | No | Git is the source |
| k3s API | 6443 | Kubernetes API | — | — |

## 2.5 Request flow and failure points

```
client -> HAProxy -> LiteLLM -> (check key in Postgres, limits in Redis) -> Ollama -> answer
                                       |
                               spend log written to Postgres
```

| If this fails... | Users likely see | Protection |
|---|---|---|
| One LiteLLM pod | Nothing (other replicas) | Replicas, readiness probe |
| All LiteLLM pods | Gateway down | PDB, safe rollouts, alerts |
| Postgres | Auth and key checks fail | HA database (RDS Multi-AZ in production), backups |
| Redis (with 2+ replicas) | Rate limits wrong or errors | HA Redis (ElastiCache in production) |
| Ollama / Bedrock | Model errors or slowness | Fallback models, quotas, upstream alerts |
| Network / ingress | Can't reach the service | Synthetic check alerts |

**You will fill the "users see" column with real results on Day 5.**


# 3. Infrastructure (Terraform)

## 3.1 Layers

| Layer | Folder | Creates | State |
|---|---|---|---|
| **Bootstrap** | `terraform/bootstrap/` | S3 state bucket (versioning, encryption, no public access) | Local (one time) |
| **Infrastructure** | `terraform/envs/dev/` | Budget alert, swarm-node, k3s-node, security groups, Elastic IPs, extra EBS volume, ECR repo, OIDC role (imported) | S3 + lock file |
| **Platform** | `terraform/platform/` | ArgoCD on k3s (helm provider) | S3 + lock file (separate key) |
| *(After interview)* | `terraform/envs/secure/` + EKS module | EKS, VPC endpoints, same code with other variables | S3 |

**Why layers:** smaller blast radius, faster plans, and **apps are deployed by GitOps, not Terraform.**

## 3.2 Modules

| Module | Inputs (variables) | Outputs |
|---|---|---|
| `lab-server` | name, instance type, disk size, allowed SSH CIDR, cloud-init template | instance ID, public IP |
| `budget` | monthly limit, alert email | — |
| *(Later)* `eks` | VPC CIDR, subnets, node size, region | cluster name, endpoint |

**Rule:** no hard-coded account IDs, regions or ARNs. Use **variables** and **data sources** (`aws_caller_identity`, `aws_region`, `aws_ami`).

## 3.3 Network and security

| Rule | From | To | Port |
|---|---|---|---|
| SSH | **Your IP only** | Both nodes | 22 |
| Kubernetes API | **Your IP only** | k3s-node | 6443 |
| LiteLLM, LibreChat, Grafana | **Your IP only** (or via SSH tunnel) | Nodes | 4000, 3080, 3000 |
| Migration traffic | HAProxy | Both nodes | 4000 |
| Air-gapped mode (Day 13) | Nodes | Internet | **Blocked** (egress limited) |

**Never open these ports to `0.0.0.0/0`.**

## 3.4 Secrets

| Secret | Where it lives | Never in |
|---|---|---|
| `LITELLM_MASTER_KEY`, **`LITELLM_SALT_KEY`** | `.env` on your Mac → Docker secrets (Swarm) / Kubernetes Secrets | Git |
| Postgres, MongoDB passwords | Same | Git |
| Virtual keys for "teams" | LiteLLM database | Git, screenshots |
| Kubeconfig | `~/.kube/config` on your Mac (mode 600) | Git |
| Terraform state | S3 bucket (encrypted) | Git |

**Salt key rule:** set once, **never change it**; it encrypts credentials stored in the database. The **same** salt key must be used on Swarm and Kubernetes.


# 4. Implementation sequence

Each step needs the one before it. **Don't skip ahead.**

| Order | Step | Needs | Day |
|---|---|---|---|
| 1 | Repo, board, `.gitignore` | — | 1 |
| 2 | State bucket + backend with locking | 1 | 1 |
| 3 | Budget alert | 2 | 1 |
| 4 | `lab-server` module → swarm-node | 2 | 2 |
| 5 | Import ECR repo + OIDC role | 2 | 2 |
| 6 | Linux deep redo (on swarm-node) | 4 | 3 |
| 7 | Docker redo → Ollama → LiteLLM + Postgres + Redis (Compose) | 4 | 4 |
| 8 | Virtual keys, limits → LibreChat → **Swarm stack** → dependency tests | 7 | 5 |
| 9 | Same module → k3s-node → Kubernetes redo | 4 | 6 |
| 10 | ArgoCD (Terraform) → LiteLLM + LibreChat (Helm, GitOps) | 9 | 7 |
| 11 | HA + HPA + load test + capacity math | 10 | 8 |
| 12 | Traffic generator + seed data + synthetic check + runbook + **rehearsal** | 8, 10 | 9 |
| 13 | HAProxy → **cutover** → **rollback drill** → results | 12 | 10 |
| 14 | Monitoring + in-cluster synthetic check + alerts | 10 | 11 |
| 15 | Usage dashboard + management view | 14 | 12 |
| 16 | Air-gapped mode → README → resume | 13 | 13 |


# 5. Test plan

## 5.1 Migration and rollback tests

| ID | Test | How | Pass criteria |
|---|---|---|---|
| M1 | Data copy, Postgres | `pg_dump` → `pg_restore` | Same number of keys, teams; **same spend totals** |
| M2 | Data copy, MongoDB | `mongodump` → `mongorestore` | Same number of users and conversations |
| M3 | Secrets | Old virtual key used on Kubernetes | Request **succeeds** (proves same master and salt keys) |
| M4 | Rehearsal | M1–M3 twice, wiping the target between | Both runs pass |
| M5 | Canary 10% | HAProxy weights 90/10 | Error rate and p95 latency **same as before** |
| M6 | 50% → 100% | Raise weights step by step | Same as M5 at each step |
| M7 | Writes during cutover | Final sync with short write freeze | **No lost spend records** (compare totals) |
| M8 | **Rollback** | Weights back to Swarm | Traffic served by Swarm; **time measured** |
| M9 | User impact | Synthetic check CSV during M5–M8 | **Seconds of errors** recorded |

## 5.2 Reliability tests

| ID | Test | Pass criteria |
|---|---|---|
| R1 | Delete one LiteLLM pod under load | 0 failed requests |
| R2 | Rolling update under load | 0 failed requests |
| R3 | Load test, rising rate (k6) | HPA adds pods; p95 recorded per step |
| R4 | Stop Redis / Postgres / Ollama | Behavior matches `docs/dependencies.md`; alerts fire |
| R5 | Air-gapped restart | Platform works with egress blocked |

## 5.3 Monitoring plan

| Signal (SLI) | Source | Alert when | Lab SLO |
|---|---|---|---|
| End-to-end success | Synthetic check | 2 failures in a row | 99.9% success |
| p95 latency | LiteLLM metrics or synthetic | Above baseline × 2 for 5 min | Set from the Day 5 baseline |
| 5xx error rate | LiteLLM / HAProxy | > 1% for 5 min | < 0.1% |
| 429 rate | LiteLLM | Sudden rise | Watch only |
| Pod restarts | Kubernetes | > 3 in 10 min | 0 |
| Postgres up, connections | Exporter or checks | Down, or > 80% of max | — |

**Why SLOs from a baseline:** a small CPU model is slow, so latency targets must come from **your own measurements**, not guesses.


# 6. GitHub deliverables

## 6.1 Final repo structure

```
ai-gateway-platform/
├── README.md                    # story, diagram, how to run, results
├── terraform/
│   ├── bootstrap/               # state bucket
│   ├── modules/lab-server/      # reused for swarm-node and k3s-node
│   ├── envs/dev/                # budget, nodes, SGs, ECR, OIDC (imported)
│   └── platform/                # ArgoCD via helm provider
├── swarm/
│   ├── docker-compose.yml       # Day 4
│   ├── stack.yml                # Day 5
│   └── litellm-config.yaml
├── gitops/
│   ├── apps/                    # ArgoCD Applications (app-of-apps)
│   ├── litellm/values.yaml
│   ├── librechat/values.yaml
│   └── monitoring/
├── migration/
│   ├── haproxy.cfg
│   ├── synthetic-check.sh
│   ├── traffic-generator.js     # k6
│   └── seed-data.sh
├── scripts/                     # lab-start.sh, lab-stop.sh, secrets.sh
├── .github/workflows/           # (after interview: full pipeline)
└── docs/
    ├── design.md                # this document
    ├── journal.md               # daily log
    ├── linux/  kubernetes.md  docker.md
    ├── dependencies.md          # if X fails -> users see Y
    ├── capacity.md
    ├── migration-runbook.md
    ├── migration-results.md     # with graph and seconds of impact
    ├── monitoring.md   airgap.md
    └── screenshots/
```

## 6.2 Deliverables by day

| Day | Deliverable in Git |
|---|---|
| 1 | Repo skeleton, `.gitignore`, `terraform/bootstrap/`, backend, budget, `docs/design.md`, `journal.md` |
| 2 | `modules/lab-server/`, cloud-init, `scripts/lab-*.sh`, imported ECR + OIDC role |
| 3 | `docs/linux/` (7 pages), extra EBS volume in Terraform |
| 4 | `swarm/docker-compose.yml`, `litellm-config.yaml`, `docs/docker.md` |
| 5 | `swarm/stack.yml`, `docs/dependencies.md`, README diagram |
| 6 | k3s cloud-init, `docs/kubernetes.md` |
| 7 | `terraform/platform/`, `gitops/` (LiteLLM, LibreChat) |
| 8 | HA values (PDB, HPA, probes), `docs/capacity.md`, k6 results |
| 9 | `migration/` scripts, `docs/migration-runbook.md` |
| 10 | `migration/haproxy.cfg`, `docs/migration-results.md` + graph |
| 11 | `gitops/monitoring/`, alert rules, `docs/monitoring.md` |
| 12 | Grafana dashboard JSON, screenshots |
| 13 | Mirror script, NetworkPolicy, `docs/airgap.md`, **final README** |

## 6.3 Final quality checklist

- ☐ README explains the **problem**, **architecture**, **results**, **lessons**, in plain words
- ☐ Every number in the README comes from your own tests
- ☐ **No secrets** anywhere in Git history (`git log -p | grep -i key` check)
- ☐ Versions pinned (images, charts, Terraform providers)
- ☐ Someone else could follow "How to run"


# 7. Technical panel preparation

## 7.1 Daily practice rotation (15:30 block)

| Day | Linux scenario (out loud) | Team interview question (out loud) |
|---|---|---|
| 2 | 1. Slow server | "Tell us about yourself" (new intro) |
| 3 | 2. Disk full + LVM | "How would you migrate from Swarm to EKS?" |
| 4 | 3. Service won't start | "How do you make a service tier 0?" |
| 5 | 4. Can't reach the app | "Usage grows 80% a month. Capacity?" |
| 6 | 5. Can't SSH | "How would you monitor the whole path?" |
| 7 | 6. High CPU | "How do you manage secrets in Kubernetes?" |
| 8 | 7. Won't boot | "How do you deploy without downtime?" |
| 9 | Permissions, SELinux, systemd basics | "What's in your migration runbook?" |
| 10 | Networking basics | **"Tell us about your migration"** (lab story) |
| 11 | All flowcharts from memory | "We need better reporting" |
| 12 | — (short day) | — |
| 13 | Kubernetes scenarios | "How do you build for an air-gapped environment?" |

## 7.2 Who you'll meet, and what they'll ask

See the **Team Interview Guide** (PDF): questions by person (infrastructure engineer, developers, data scientists, business analysts), model answers, and your questions for them.

## 7.3 The 5-minute demo (for the prep day, and maybe the interview)

1. **The problem** (30 s): their situation, in one sentence each
2. **Architecture** (1 min): before and after diagrams
3. **The migration** (2 min): data and secrets, gradual cutover, rollback, **seconds of impact**
4. **Tier 0** (1 min): HA, autoscaling, synthetic check, usage dashboard, air-gapped
5. **What I'd do differently in production** (30 s): RDS/ElastiCache, multi-AZ EKS, Bedrock quotas, on-call


# 8. Risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| 8 GB is not enough (model + k3s + monitoring) | Pods evicted, slow | Smallest model; small monitoring values; stop Swarm stack when not needed; bigger instance for Days 9–10 only |
| AWS cost grows | Budget surprise | Budget alert; stop instances daily; no EKS before the interview |
| A tool version changes its config | Lost time | Pin versions; read the official docs for the version you use |
| LiteLLM metrics need a license in your version | No `/metrics` | Use the synthetic check + Postgres spend data instead |
| Behind schedule | Unfinished story | Checkpoints; cut the optional parts first (pipeline, chaos) |
| Interview moved earlier | Less time | Stop the day before; prep day; present the rest as "my plan" |
| Tiredness | Weaker interview | Sunday short days; real breaks; stop at 17:15 |

# 9. Project definition of done

- ☐ All objectives O1–O8 pass their success criteria, **or** the README honestly says what's left
- ☐ Migration results with a measured user impact and a timed rollback
- ☐ README, diagrams and docs complete; no secrets in Git
- ☐ You can present the project in 5 minutes and answer follow-up questions
