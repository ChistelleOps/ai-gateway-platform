# AI Gateway Platform: Plan to the Team Interview

Christelle Nono Tigang · Full-time project, run like a real job, **weekends included** · Monday, November 23 → **team interview Wednesday, December 9** (may be earlier)

**The project:** rebuild a small version of the Lincoln Lab AI platform: **LiteLLM** (AI gateway) and **LibreChat** (chat) on **Docker Swarm**, then **migrate** them to **Kubernetes** with **Terraform**, high availability, monitoring and reporting. Everything goes to GitHub: **`ai-gateway-platform`**.

**How this plan works:** each day has **tickets**, **steps in order**, a **"done when"** checklist and **"explain it"** questions. We do each day **together in the chat, step by step**. The most valuable work comes **first**: at each **checkpoint**, you already have a strong story. If the interview moves earlier, **stop building one day before** and do the **prep day**.

## Calendar

| Day | Date | Focus | Checkpoint |
|---|---|---|---|
| 1 | Mon 11/23 (afternoon) | Repo, board, AWS budget, Terraform remote state | |
| 2 | Tue 11/24 | Terraform: lab server + import last week's resources | |
| 3 | Wed 11/25 | **Linux deep redo** (7 scenarios) | |
| — | Thu 11/26 | **Thanksgiving: off** | |
| 4 | Fri 11/27 | **Docker deep redo** + Ollama + **LiteLLM** with Postgres and Redis | |
| 5 | Sat 11/28 | **Virtual keys, LibreChat, Docker Swarm**, dependency tests. **Sprint 1 demo** | **A: I know their current stack** |
| — | Sun 11/29 | **Short day:** review + practice (your activity 10–3) | |
| 6 | Mon 11/30 | **Kubernetes deep redo** + k3s with Terraform | |
| 7 | Tue 12/1 | ArgoCD via Terraform; LiteLLM and LibreChat with **Helm + GitOps** | |
| 8 | Wed 12/2 | **High availability** + autoscaling + load test | |
| 9 | Thu 12/3 | **Migration part 1:** traffic, data, runbook, rehearsal | |
| 10 | Fri 12/4 | **Migration part 2:** cutover + rollback drill. **Sprint 2 demo** | **B: my core story is ready** |
| 11 | Sat 12/5 | **Monitoring** + end-to-end synthetic check + alerts | |
| 12 | Sun 12/6 | **Short day:** usage reporting dashboard | **C: Todd's and Igor's needs** |
| 13 | Mon 12/7 | **Air-gapped mode** + README + resume line | **D: project done** |
| 14 | Tue 12/8 | **Interview prep day.** Rest in the evening. | |
| — | **Wed 12/9** | **Team interview** | |
| *After* | *Dec 10+* | *Full pipeline, chaos test, EKS (optional)* | |

**If the interview moves:**

| New date | What to do |
|---|---|
| Before Fri 12/4 | Stop after Checkpoint A, do the prep day the day before. Present the migration as **"in progress, here's my plan and what I've built."** |
| 12/4 – 12/7 | Stop at the last checkpoint reached, prep day the day before. |
| 12/9 | Follow the plan. |

## Daily schedule

| Time | Block |
|---|---|
| 9:00 – 9:15 | **Stand-up with Claude:** yesterday, today, blockers |
| 9:15 – 12:00 | **Deep work, block 1** |
| 12:00 – 13:00 | Lunch, away from the screen |
| 13:00 – 15:30 | **Deep work, block 2** |
| 15:30 – 16:30 | **Practice:** one Linux scenario out loud + one team interview question |
| 16:30 – 17:00 | **Job search:** applications, recruiter follow-ups |
| 17:00 – 17:15 | **Close the day:** board, push, journal, **stop the EC2 instances** |

**Sundays:** a short block before 10 and/or after 3. No new building, except the Day 12 dashboard. **Take real rest too:** two weeks without a break makes the interview harder, not easier.

## Rules for every ticket

1. **Branch → pull request → review → merge.** Ask Claude to review each PR.
2. **Nothing by hand in AWS.** It goes in Terraform.
3. **Break it on purpose** at least once per ticket.
4. **Done =** it works, it's in Git, notes in `docs/`, and **you can explain it in 1 minute.**
5. **No secrets in Git:** no `.tfstate`, `.tfvars`, `.env`, API keys or kubeconfig.

## Cost control

- **EC2, not Lightsail:** a stopped EC2 instance only charges for its disk. **Stop instances every evening.**
- **AWS budget alert** (Day 1). **Cost Explorer** check every Friday.
- **No EKS before the interview.**


# Sprint 1: Foundations, Terraform, "today" on Swarm

**Sprint goal:** a lab server built by Terraform, deep understanding of Linux and Docker, and LiteLLM + LibreChat running on Docker Swarm, like Lincoln Lab today.

## Day 1 · Monday 11/23 (afternoon) · Project setup

**Tickets:** repo and board · AWS budget alert · Terraform remote state

| Time | Steps |
|---|---|
| **14:45 – 15:30** | **1.** Create the `ai-gateway-platform` repo (private) with folders: `terraform/`, `swarm/`, `gitops/`, `docs/`, `.github/workflows/`, and a `.gitignore` for Terraform state, `.tfvars`, `.env`. **2.** Create the GitHub Project board (To do · In progress · Review · Done). **3.** Create the Sprint 1 issues. |
| **15:30 – 16:15** | **4.** Install or update **Terraform** on your Mac (`brew install hashicorp/tap/terraform`) and check `terraform version` (1.10 or newer). **5.** In `terraform/bootstrap/`: an **S3 bucket** for state with **versioning**, **encryption**, **public access blocked**. `init`, `plan`, `apply`. |
| **16:15 – 16:45** | **6.** In `terraform/envs/dev/`: a **backend "s3"** pointing to that bucket, with **`use_lockfile = true`** (state locking). **7.** First resource: an **AWS budget** with an email alert at 80% of your monthly limit. `plan`, `apply`. |
| **16:45 – 17:00** | **8.** PR → review → merge. **9.** Journal: what you set up, what you want to learn this week. |

**Done when:**

- ☐ Repo, board and 7 issues exist
- ☐ State bucket created by Terraform; `envs/dev` uses the S3 backend with locking
- ☐ Budget alert visible in the AWS Billing console
- ☐ `git status` clean, no state files in Git

**Explain it:** *Why remote state? What is state locking, and what happens without it? Why is the bootstrap layer separate from `envs/dev`?*


## Day 2 · Tuesday 11/24 · Terraform: lab server + import

**Tickets:** EC2 lab server with cloud-init · import ECR repo and OIDC role

| Time | Steps |
|---|---|
| **9:15 – 10:30** | **1.** Module `terraform/modules/lab-server/`: **EC2 instance** (8 GB, Amazon Linux 2023), latest AMI from a **data source**, **security group** with SSH from **your IP only** (a variable), key pair, 30 GB disk. **2.** Variables, outputs (public IP, instance ID). |
| **10:30 – 12:00** | **3.** **cloud-init** with `templatefile`: install Docker, git, `sysstat`, `lsof`, `bind-utils`; add `ec2-user` to the `docker` group. **4.** `apply`, SSH in, check Docker works. **5.** Connect VS Code Remote-SSH to it. |
| **13:00 – 14:00** | **6.** Two scripts in `scripts/`: `lab-start.sh` and `lab-stop.sh` (AWS CLI `start-instances` / `stop-instances`). **Break it:** stop, start, check the IP changed; fix with an **Elastic IP** in Terraform, or by reading the IP from outputs. |
| **14:00 – 15:30** | **7.** **Import** the ECR repo and the GitHub OIDC role from last week into `envs/dev` with **`import` blocks**. Write the matching resources. **8.** Account ID from **`data "aws_caller_identity"`**, never typed. **Goal: `terraform plan` shows no changes.** |
| 15:30 – 16:30 | **Study:** Terraform state, `import`, `moved` blocks, data sources |
| 17:00 | PR, journal, **`lab-stop.sh`** |

**Done when:**

- ☐ `terraform apply` builds the server; `destroy` and `apply` again works
- ☐ ECR repo and OIDC role are managed by Terraform; **plan = no changes**
- ☐ Start/stop scripts work

**Explain it:** *What does cloud-init do and when does it run? How do you bring a manual resource under Terraform? Why use a data source for the account ID?*

## Day 3 · Wednesday 11/25 · Linux deep redo

**Ticket:** Linux scenarios 1–7, slowly, with notes

| Time | Steps |
|---|---|
| **9:15 – 10:45** | **Scenario 1 (slow server)** and **6 (high CPU)**. Read every column of `top`, `vmstat`, `iostat`. Limit a process with `systemd-run` + `CPUQuota`. |
| **10:45 – 12:00** | **Scenario 2 (disk full)**: inodes, `lsof +L1`. **LVM:** add a second EBS volume **in Terraform**, then `pvcreate` → `vgcreate` → `lvcreate` → `mkfs.xfs` → fstab → **extend online** with `lvextend -r`. |
| **13:00 – 14:15** | **Scenario 7 (boot)**: fstab with `findmnt --verify`, `nofail`, `_netdev`, kernels with `grubby`. **Scenario 3 (service)**: config test, port conflict, SELinux (check `getenforce` first). |
| **14:15 – 15:30** | **Scenario 4 (unreachable)**: the 127.0.0.1 trap, `/etc/hosts`, **both firewalls** (security group in Terraform + firewalld). **Scenario 5 (SSH)** with a test user. |
| 15:30 – 16:30 | **Study:** draw the 7 flowcharts from memory; compare with the PDF |
| 17:00 | `docs/linux/` notes, journal, **stop the instance** |

**Done when:**

- ☐ One page per scenario in `docs/linux/`: break, check, cause, fix, prevent
- ☐ Each scenario explained out loud in under 90 seconds
- ☐ The LVM volume extended online; the extra EBS volume is in Terraform

**Explain it:** *Load average vs CPU count? Why doesn't space come back after deleting a file? PV, VG, LV? Why never disable SELinux?*

## Day 4 · Friday 11/27 · Docker deep redo + Ollama + LiteLLM

**Tickets:** Docker internals redo · Ollama · LiteLLM with Postgres and Redis

| Time | Steps |
|---|---|
| **9:15 – 10:30** | **Docker redo:** container = process (PID, `/proc/PID/ns`, cgroup files), OOM 137 + `dmesg`, layers and cache, the 127.0.0.1 trap, volumes. Notes in `docs/docker.md`. |
| **10:30 – 12:00** | **Ollama:** run it in Docker, pull a **very small model**, call its API with `curl`. Measure memory with `docker stats`. |
| **13:00 – 15:00** | **LiteLLM with Docker Compose:** `litellm` + **Postgres** + **Redis**. A `config.yaml` that routes a model name to Ollama. Set the **master key** and **salt key** from a `.env` file (**not in Git**). Call LiteLLM with `curl`, OpenAI style. Open the **Admin UI**. |
| **15:00 – 15:30** | **Break it:** wrong model name, wrong key (401), Ollama stopped (what error?). |
| 15:30 – 16:30 | **Study:** Terraform modules: inputs, outputs, versions |
| 17:00 | PR, journal, stop the instance |

**Done when:**

- ☐ A request through LiteLLM gets an answer from the Ollama model
- ☐ Secrets in `.env`, which is in `.gitignore`
- ☐ You can draw: client → LiteLLM → Ollama, with Postgres and Redis beside it

**Explain it:** *What is an AI gateway and why use one? What does Postgres store for LiteLLM? Why is the salt key important?*

## Day 5 · Saturday 11/28 · Virtual keys, LibreChat, Docker Swarm

**Tickets:** keys and limits · LibreChat · Swarm stack · dependency tests · **Sprint 1 demo**

| Time | Steps |
|---|---|
| **9:15 – 10:30** | **Virtual keys:** create keys for 2 "teams" with **budgets** and **rate limits** (requests per minute). Exceed the limit → see the **429**. Look at **spend logs** in Postgres with `psql`. |
| **10:30 – 12:00** | **LibreChat** + **MongoDB** + **Meilisearch** in Compose, pointed at LiteLLM with a virtual key. Log in, chat, search old chats. |
| **13:00 – 14:30** | **Docker Swarm:** `docker swarm init`, convert Compose to a **stack file** with **Docker secrets**, `docker stack deploy`. **2 replicas** of LiteLLM. Explain the overlay network. |
| **14:30 – 15:15** | **Dependency tests:** stop Redis, stop Postgres, kill a LiteLLM replica, stop Ollama. **Write down what users see each time.** This table becomes your tier-0 thinking. |
| **15:15 – 15:30** | **Sprint 1 demo** to Claude: 5 minutes, as in a team meeting |
| 15:30 – 16:30 | **Study:** Terraform workflow, `fmt`, `validate`, `plan` output |
| 17:00 | PR, sprint retro in the journal (what went well, what to improve), stop the instance |

**Done when:**

- ☐ Swarm runs LiteLLM (2 replicas), Postgres, Redis, Ollama, LibreChat, MongoDB, Meilisearch
- ☐ `docs/dependencies.md`: a table "if X fails → users see Y"
- ☐ Architecture diagram in the README

**Explain it:** *How do teams get access? What happens when Redis is down with 2 replicas? Swarm service vs Kubernetes Deployment?*

**Checkpoint A:** you can talk about **their current stack from hands-on experience**: LiteLLM, keys, limits, spend, LibreChat, Swarm and its dependencies.

## Sunday 11/29 · Short day · Review and practice

| When | What |
|---|---|
| Before 10:00 or after 15:00 (1–2 h) | Read your `docs/` notes from the week. Draw the architecture from memory. Say the **new intro** and **"How would you migrate from Swarm to EKS?"** out loud. Update the journal. |


# Sprint 2: Kubernetes and the migration

**Sprint goal:** a Kubernetes platform built with Terraform and GitOps, highly available, and a **real migration** from Swarm with live traffic and data.

## Day 6 · Monday 11/30 · Kubernetes deep redo + k3s with Terraform

| Time | Steps |
|---|---|
| **9:15 – 10:30** | **Reuse the `lab-server` module** for a second instance, `k3s-node`, with a different cloud-init: install **k3s**. Two servers from one module = **why modules exist.** |
| **10:30 – 12:00** | Kubeconfig to your Mac (securely). Deploy your `myapp`; Deployment → ReplicaSet → Pods; Services and endpoints. |
| **13:00 – 15:30** | **The 6 Kubernetes scenarios, slowly:** ImagePullBackOff, CrashLoopBackOff, OOMKilled, Pending, broken Service, readiness. Rolling update + rollback. Notes in `docs/kubernetes/`. |
| 15:30 – 16:30 | **Study:** Terraform providers and `required_providers` |
| 17:00 | PR, journal, stop both instances |

**Done when:** k3s node built by Terraform · 6 scenarios explained in notes · rollback works

**Explain it:** *Reading pod status → command → cause. Readiness vs liveness. Why one module for two servers?*

## Day 7 · Tuesday 12/1 · ArgoCD + Helm + GitOps

| Time | Steps |
|---|---|
| **9:15 – 10:45** | New Terraform root `terraform/platform/`: the **helm provider** installs **ArgoCD** on k3s. Separate state from `envs/dev`. |
| **10:45 – 12:00** | `gitops/`: an **app-of-apps**. ArgoCD watches your repo. |
| **13:00 – 14:30** | **LiteLLM with its official Helm chart**: values in Git, Postgres and Redis in the cluster (lab), secrets created by a script (**not in Git**). Same `config.yaml` logic as Swarm. |
| **14:30 – 15:30** | **LibreChat with its Helm chart** (MongoDB, Meilisearch). **Break it:** change a value in Git → ArgoCD syncs; change something by hand → ArgoCD reverts it (**drift**). |
| 15:30 – 16:30 | **Study:** Terraform: why platform and apps are separate layers |
| 17:00 | PR, journal, stop instances |

**Done when:** ArgoCD installed by Terraform · LiteLLM and LibreChat deployed from Git · drift test done

**Explain it:** *Why Terraform for the platform but GitOps for apps? What is drift? How does a Swarm stack map to Helm values?*

## Day 8 · Wednesday 12/2 · High availability + autoscaling

| Time | Steps |
|---|---|
| **9:15 – 10:45** | LiteLLM: **3 replicas**, readiness probe on **`/health/readiness`**, **PodDisruptionBudget**, rolling update with **`maxUnavailable: 0`**, requests and limits. |
| **10:45 – 12:00** | **Database connections:** count `replicas × workers × pool size` and compare with Postgres `max_connections`. Write it in `docs/capacity.md`. |
| **13:00 – 14:30** | **HPA** on LiteLLM (CPU). **Load test with k6** at rising rates. Watch pods scale. Record p95 latency and errors at each step. |
| **14:30 – 15:30** | **Capacity math:** with 80% monthly growth, when does your lab hit its limit? Add the table to `docs/capacity.md`. Note the **single-node** limit of the lab and what changes on EKS (multi-AZ, node autoscaling). |
| 15:30 – 16:30 | **Study:** Terraform `count` vs `for_each` |
| 17:00 | PR, journal, stop instances |

**Done when:** HPA scales under load · `docs/capacity.md` has real numbers · rollout with no errors

**Explain it:** *What makes a service tier 0? Why maxUnavailable 0? How do DB connections grow with pods?*

## Day 9 · Thursday 12/3 · Migration part 1: prepare

| Time | Steps |
|---|---|
| **9:15 – 10:30** | **Make Swarm "production":** a **traffic generator** (low steady rate) on Swarm; **seed data**: keys, spend history, LibreChat users and conversations. |
| **10:30 – 12:00** | **Synthetic check** script: a request every 5 seconds; logs time, status and latency to a CSV. This measures **user impact**. |
| **13:00 – 14:00** | **`docs/migration-runbook.md`:** inventory (images, versions, config, secrets, volumes, dependencies), stateless vs stateful, risks, **go/no-go checklist**, **rollback plan**. |
| **14:00 – 15:30** | **Rehearsal:** same `LITELLM_MASTER_KEY` and **`LITELLM_SALT_KEY`** on Kubernetes; `pg_dump` → `pg_restore`; `mongodump` → `mongorestore`. **Validate:** same number of keys, same spend totals, same conversations. Then wipe the target and do it again: **a migration is practiced before it's done.** |
| 15:30 – 16:30 | **Study:** Terraform `lifecycle` (`prevent_destroy`, `create_before_destroy`) |
| 17:00 | PR, journal, stop instances (Swarm data stays on disk) |

**Done when:** runbook written · data copy rehearsed twice and validated · synthetic check running

**Explain it:** *Why is the data the hard part? What breaks if the salt key changes? What's in a go/no-go checklist?*

## Day 10 · Friday 12/4 · Migration part 2: cut over

| Time | Steps |
|---|---|
| **9:15 – 10:15** | **Traffic switch:** a small **HAProxy or nginx** in front, with weights between Swarm and Kubernetes. Synthetic check and traffic generator go through it. |
| **10:15 – 12:00** | **Cutover:** final data sync (short write freeze) → **10%** to Kubernetes → watch errors and latency → **50%** → **100%**. Follow the runbook, tick each step. |
| **13:00 – 14:00** | **Rollback drill:** send traffic back to Swarm on purpose. Measure the time. Then forward again. |
| **14:00 – 15:00** | **`docs/migration-results.md`:** graph from the synthetic CSV, seconds of impact, problems and fixes, what you'd do differently in production. |
| **15:00 – 15:30** | **Sprint 2 demo** to Claude: tell the migration story in 3 minutes |
| 15:30 – 16:30 | **Study:** Terraform workspaces vs separate environment folders |
| 17:00 | PR, sprint retro, stop instances |

**Done when:** 100% on Kubernetes · rollback tested and timed · results with a number for user impact

**Explain it:** *Your migration in 3 minutes. How did you handle writes during the cutover? How long did rollback take?*

**Checkpoint B: your core story is ready.** "I rebuilt your setup on Swarm and migrated it to Kubernetes with live traffic, a gradual cutover and a tested rollback."


# Sprint 3: Tier 0, reporting, air-gapped

**Sprint goal:** monitoring of the whole path, usage reporting, and a no-internet mode, then a finished README.

## Day 11 · Saturday 12/5 · Monitoring + synthetic check + alerts

| Time | Steps |
|---|---|
| **9:15 – 10:45** | **kube-prometheus-stack** via ArgoCD (Prometheus, Grafana, Alertmanager). Size it for the lab. |
| **10:45 – 12:00** | **LiteLLM metrics:** enable the Prometheus endpoint if your version allows it (check if it needs a license). If not, use the database and logs instead (Day 12). |
| **13:00 – 14:15** | **End-to-end synthetic check in the cluster:** a CronJob or blackbox exporter that calls LiteLLM → model every minute. Exports success and latency to Prometheus. |
| **14:15 – 15:30** | **Alerts:** synthetic check failing, high 5xx rate, high 429 rate, high p95 latency, pod restarts, Postgres down. Route to email or a webhook. **Break it:** stop the model → the alert fires. |
| 15:30 – 16:30 | **Study:** Terraform functions and expressions |
| 17:00 | PR, journal, stop instances |

**Done when:** an alert fires when the path breaks · dashboards for gateway, cluster and dependencies

**Explain it:** *How do you monitor the whole path? Why alert on user impact? What are the golden signals?*

## Day 12 · Sunday 12/6 (short day) · Usage reporting dashboard

| When | Steps |
|---|---|
| **Before 10:00** (about 1 h) | **1.** A **read-only Postgres user** for reporting (least privilege). **2.** Grafana **Postgres data source**. **3.** Explore LiteLLM's spend tables with `psql`. |
| **After 15:00** (2–3 h) | **4. Usage dashboard** from the spend logs: requests, tokens and cost **per team, key and model**; daily trend; top users. **5.** A simple **management view**: total usage, growth %, availability. **6.** PR, journal, stop instances. |

**Done when:**

- ☐ Usage dashboard + management view
- ☐ You can connect it to your Claude Code metrics work at ADI

**Checkpoint C:** you can answer **Todd's** "monitor the whole path" and **Igor's** "data reporting" **with your own dashboards**.

## Day 13 · Monday 12/7 · Air-gapped mode + finish

| Time | Steps |
|---|---|
| **9:15 – 10:30** | **1. Air-gapped mode:** a **private registry**; mirror every image; point k3s and the Helm values at the mirror. |
| **10:30 – 12:00** | **2. Block internet:** NetworkPolicy deny egress + security group egress limited in Terraform. Restart everything. **Proof: it still works** (the model is local). Notes in `docs/airgap.md`. |
| **13:00 – 14:30** | **3. README:** the problem, **architecture diagram** (Mermaid), how to run it, **results** (migration impact, load test), production next steps, lessons learned. Check: **no secrets** in `git log`. |
| **14:30 – 15:30** | **4. Resume:** a project line with real numbers. |
| 15:30 – 16:30 | **Practice:** Kubernetes scenarios + "How do you build for an air-gapped environment?" |
| 17:00 | Push, journal, stop instances |

**Checkpoint D:** project done. **Nothing new after today.**


## Day 14 · Tuesday 12/8 · Interview prep day

**No building today.**

| Time | Steps |
|---|---|
| **9:15 – 10:15** | **Read the lab's website:** mission, divisions (communications, space, quantum, missile defense, air traffic control), central IT. |
| **10:15 – 11:30** | **Read again:** the Team Interview Guide, your README, your migration results. |
| **11:30 – 12:00** | **Write your 5 questions** for them, based on what they told you. |
| **13:00 – 14:00** | **Mock team interview with Claude (1 hour):** infrastructure engineer, developer, data scientist, business analyst. |
| **14:00 – 15:00** | Fix weak answers. Intro and migration story, 3 times each. |
| **15:00 – 15:30** | **Logistics:** confirm time and link with the recruiter; ask **who will be in the interview**; test camera, microphone, internet. |
| Afternoon | **Stop. Rest.** Sleep early. |

## Wednesday 12/9 · Team interview

| When | What |
|---|---|
| Morning | Light review: intro, migration story, your questions |
| 5 min before | Join the link. Recruiter's number ready. |
| After | Call the recruiter. Write down the questions they asked. |

# After the interview (optional)

### Secure pipeline (the full version)

| Time | Steps |
|---|---|
| **9:15 – 10:45** | **Pipeline (GitHub Actions):** `terraform fmt` + `validate` + **`plan` on PR** (OIDC role with **read-only** permissions for plan); **Trivy config scan** on Terraform and Helm values; `helm lint` / `helm template` + schema check. |
| **10:45 – 12:00** | **Image scanning:** scan the **third-party images** you deploy (LiteLLM, LibreChat, Postgres, Redis); SBOMs as artifacts; document findings and decisions. |
| 15:30 – 16:30 | **Study:** Terraform in CI/CD, plan files, policy as code |
| 17:00 | PR, journal, stop instances |



### EKS with Terraform (one day only)

| Time | Steps |
|---|---|
| **9:15 – 10:30** | **Reuse your `aws-eks-platform` modules:** VPC with private subnets across AZs, EKS, managed node group. **`envs/dev`** and **`envs/secure`** with different `.tfvars`; **no hard-coded region, account or ARN.** |
| **10:30 – 12:00** | **VPC endpoints:** ECR (api, dkr), S3, STS, CloudWatch Logs (+ Bedrock runtime if used). `apply` (EKS takes time: study during the wait). |
| **13:00 – 14:30** | Point ArgoCD at the **same `gitops/` repo** → the same apps on EKS. **Multi-AZ** spread now works for real. *(Optional:* **Bedrock** as a second model, with **EKS Pod Identity or IRSA** for LiteLLM.*)* |
| **14:30 – 15:00** | Screenshots, notes, cost check |
| **15:00 – 15:30** | **`terraform destroy`.** Confirm in the console that nothing is left (load balancers, NAT gateways, volumes). |
| 15:30 – 16:30 | **Study:** Terraform Associate practice questions |
| 17:00 | PR, journal, Cost Explorer check |

**Done when:** EKS built and destroyed by Terraform · same code, two environments · nothing left running

**Explain it:** *How would you make the infrastructure copyable to a classified environment? Pod Identity vs IRSA?*


## Your story for the team interview (goal)

> "After our conversation, I rebuilt a small version of your platform to understand it: LiteLLM and LibreChat on Docker Swarm, with virtual keys, budgets and rate limits. Then I migrated it to Kubernetes with Terraform and ArgoCD. The real work was the data and secrets: the same salt key, Postgres and MongoDB copied and validated, then a gradual 10-50-100% cutover with a tested rollback, at [X seconds] of user impact. I made it highly available with replicas, PDBs, readiness probes and autoscaling, monitored the whole path with a synthetic check, built a usage dashboard per team, and ran it with no internet from mirrored images."
