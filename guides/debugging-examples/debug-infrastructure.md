---
name: debug-infrastructure
description: >
  Diagnose infrastructure-level issues — containers that don't start, services that can't reach
  each other, DNS failures, port conflicts, resource limits. Use when user says 'container
  won't start', 'service unreachable', 'DNS not resolving', 'port in use', 'out of memory',
  or 'OOMKilled'. Do NOT use for application-level bugs inside a running container
  (use debug-backend), database-specific issues (use debug-database), or CI pipeline failures
  (those are CI-specific; debug in that context).
allowed-tools: Read, Grep, Glob, Bash
---

# Debug an infrastructure issue

## Before You Start

- Root `CLAUDE.md` → the project's deployment model (Docker Compose, Kubernetes, serverless, bare metal).
- `docker-compose.yml` / `k8s/` manifests / `Dockerfile` — the canonical infra config for this project.
- Access to the environment: `docker`, `kubectl`, the relevant cloud CLI.
- Knowledge of the project's networking topology — a monolith with one service is different from a mesh with ten.

## Step 1: classify the symptom

| Symptom | Likely class |
|---|---|
| Container exits immediately after start | Config or command issue in the image — logs will tell you. |
| Container restarts in a loop | Crash on startup — check recent logs AND previous container logs. |
| Container running, but service unreachable | Port mapping, network config, or readiness probe. |
| Works from one container, not another | Networking — DNS, service discovery, firewall. |
| Intermittent timeouts | Resource saturation — CPU, memory, disk, network. |
| OOMKilled | Memory limit too low OR application leak. |
| PostgreSQL: "too many clients" | Pool exhaustion — see debug-database. |
| Disk full | Log rotation broken, or runaway temp files. |

## Step 2: gather evidence

### Docker Compose

```bash
# State of all services
docker compose ps

# Most recent logs for the failing service (including crashed ones)
docker compose logs --tail=200 <service>

# Logs from the PREVIOUS instance if the container is restart-looping
docker compose logs --tail=200 --timestamps <service>

# Inspect the container
docker compose exec <service> /bin/sh           # or bash
docker inspect <container-id>
```

### Kubernetes

```bash
# Pod status
kubectl get pods -n <namespace> -l app=<service>

# Describe the pod (events, image, resources, probes)
kubectl describe pod -n <namespace> <pod-name>

# Logs — current and previous
kubectl logs -n <namespace> <pod-name> --tail=200
kubectl logs -n <namespace> <pod-name> --tail=200 --previous

# Shell into a running pod
kubectl exec -it -n <namespace> <pod-name> -- /bin/sh

# Node-level resource pressure
kubectl top nodes
kubectl top pods -n <namespace>
```

### Container not starting — read the entrypoint errors

The first 20 lines of logs almost always tell you why.

- Missing env var
- Config file not found at the expected path
- Permission denied on a volume mount
- Command not found (wrong shell, wrong path in `CMD`)

## Step 3: network and DNS diagnostics

When containers can't reach each other:

```bash
# Inside the calling container
nslookup <target-service-name>       # or: dig <name>
curl -v http://<target>:<port>/health
ping -c 3 <target>                    # some images don't ship ping; use `wget -O- ...` instead

# From host (for a container bound to a host port)
curl -v http://localhost:<host-port>/

# Docker networks
docker network ls
docker network inspect <network-name>

# Kubernetes: services, endpoints, policies
kubectl get svc -n <namespace>
kubectl get endpoints <svc-name> -n <namespace>
kubectl get networkpolicy -n <namespace>
```

Watch for:

- **No endpoints** for a service — the selector doesn't match any pod. Check pod labels vs selector.
- **DNS not resolving inside the cluster/compose network** — resolver config or the service name is wrong.
- **NetworkPolicy blocking** — explicit deny without a matching allow.
- **Port bound on a different IP** — `localhost` vs `0.0.0.0` — container binding 127.0.0.1 isn't reachable from outside.

## Step 4: resource diagnostics

```bash
# Process-level inside a container
top
ps aux --sort=-rss | head
df -h               # disk
free -m             # memory

# Host level
docker stats                                      # compose / docker
kubectl top pods -n <namespace> --sort-by=memory  # k8s
```

### OOMKilled

```bash
# K8s: most recent pod termination reason
kubectl get pod <name> -o yaml | grep -A 5 -B 2 reason

# Docker: inspect "OOMKilled: true"
docker inspect <container> | grep OOM
```

Fix by either raising the limit (if the consumption is legitimate) or finding the leak (usually a growing cache, unbounded queue, or connection not closed).

### Disk full

```bash
df -h                                      # which mount
du -sh /* 2>/dev/null | sort -rh | head    # biggest consumers in /
```

Common culprits: unrotated logs, old container images (`docker system prune`), stuck core dumps.

## Step 5: narrow

Once you know the class:

- **Config/env:** diff the failing env's config against a working env. `diff <(ssh a env) <(ssh b env)`.
- **Networking:** trace the path. If A can't reach B, test A → B directly vs through the proxy/service.
- **Resource:** measure the actual ceiling, compare to the declared limit. Usually one is wrong.

## Step 6: propose or apply the fix

Infra fixes land in YAML/config files — `docker-compose.yml`, Kubernetes manifests, Terraform. Match the project's GitOps / PR flow. **Never edit live manifests directly unless that's the project's explicit workflow** — they drift from the repo.

## Step 7: prevent regression

- **Health + readiness probes** — if the failure was "service appeared up before it was ready," add a readiness probe that checks the real signal.
- **Resource limits + alerts** — if OOM, add a memory alert under the limit.
- **Network policies as tests** — if a policy blocked a legitimate call, add a policy test that asserts the call succeeds.
- **`Things to Know` entry** in root `CLAUDE.md` if the fix depended on project-specific infra knowledge.

## Verify

```bash
# Container running and healthy
docker compose ps                              # expected: "up (healthy)"
kubectl get pods -n <namespace>                # expected: 1/1 Running

# The symptom is gone — repro the original failing call
curl -v http://<target>/<path>                 # expected: 200

# Resource usage stable
kubectl top pods -n <namespace> <name> --watch  # or docker stats
```

## Common Mistakes

| Mistake | Correction |
|---|---|
| Editing live manifests out of band | Change the manifest in the repo, commit, deploy through the project's flow. Ad-hoc edits drift and confuse the next debugger. |
| Raising memory limits without investigating | A growing leak eats any limit. Investigate first; raise only after you understand the consumption. |
| Assuming a service is reachable because `curl localhost:PORT` works on the host | Test from inside the calling container. Host-level access bypasses network policies and service discovery. |
| Deleting pods/containers to "fix" a bug | Deleting erases the evidence. Capture logs + describe output first, THEN delete if needed. |
