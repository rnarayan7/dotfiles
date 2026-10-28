---
name: check-environments
description: Answer one question across every Valkai environment (for example "which envs have a read replica?" or "what Postgres version runs everywhere?") and report a per-environment table with evidence. Use for /check-environments <question> or "check this across all envs".
argument-hint: "<question>"
---

# Check environments

Read-only. Never apply Terraform, change Kubernetes or Helm, write to a database, or run any cloud CLI command that changes state. If an answer needs a write, stop and say so.

## 1. Load the environment list

Read the lists from `origin/main`, not from the working tree. A feature branch can be stale.

```bash
git fetch -q origin main
git show origin/main:.github/deploy-environments.json
git show origin/main:.github/terraform-stacks.json
```

- **App envs:** `deploy-environments.json`. Each key is one deployed env. It holds the cloud, cluster, resource group or AWS role and region, `access` (`direct` or `aks-invoke`), `customer`, and `environment_tier`.
- **Terraform stacks:** `terraform-stacks.json`. Each key is one stack, and `dir` is its Terraform root. Some stacks are not app envs (`rootly`, `sentry`, `github`, `grafana`, `*-shared`, `azure-analytics`). Include those only when the question is about them.
- **AbbVie:** not in either file. AbbVie runs its own deploys from the release mirror. Its Terraform is in `deployment/terraform/providers/aws/environments/onprem/abbvie/` (`infrastructure/` and `environments/{dev,qa,prod}/terraform.tfvars`). Always add AbbVie dev, qa and prod as rows. Answer them from the repo only, and mark them "repo only, not live-checked".

If the user names a subset ("only prod envs", "only AWS"), filter on `environment_tier`, `cloud` or `customer`. Otherwise check every env.

## 2. Decide where the answer lives

- **Config question** (what Terraform or Helm values set: versions, flags, sizes, feature toggles): read the repo at `origin/main`. Use the stack `dir`, the env tfvars, and the Helm values under `deployment/helm/`. Note that a merged change can still be unapplied.
- **Live-state question** (what actually runs or exists right now: pods, image tags, replicas, DB settings): run read-only commands per env. Follow the access patterns in `.claude/skills/on-call-debug/references/environments.md` and `kubectl-commands.md`.
  - `access: aks-invoke` (Zimmer): use `az aks command invoke`. Direct kubectl does not reach these clusters.
  - Pass an explicit `--context` / `--kube-context` to every kubectl and helm command.
  - For what is deployed, read the deploy run's own record. Do not infer it from titles, tags or the Deployment SHA.
- **Both** (for example "is X turned on everywhere?"): check config first, then confirm live where you have access. Report any mismatch as drift.

If you cannot tell which kind of question it is, check config and say so.

## 3. Check each env

- Run the per-env checks in parallel where you can. When each env needs many reads, spawn one Explore agent per cloud (Azure, AWS) with the env list and the question, and have each return one row per env.
- When access fails (no login, no role, a timeout), mark the row "unknown" with the error line. Do not guess, and do not try other access paths.
- Never print secrets, passwords, connection strings or tokens.

## 4. Report

Lead with a one-line answer ("8 of 13 envs have a read replica; Zimmer prod has no DNS for it").

Then one table, one row per env, grouped by cloud:

| Env | Answer | Evidence |
|---|---|---|
| dev (Azure) | yes | `providers/azure/environments/dev/main.tf:142` |
| zimmerbiomet-prod | yes, no DNS | `az postgres flexible-server show …` |
| abbvie-prod | no | repo only: `abbvie/infrastructure/main.tf:128` |

- **Evidence:** a `file:line` at `origin/main` for config, or the command for live state.
- After the table, list drift (config differs from live), "unknown" rows with their cause, and envs you left out on purpose.
