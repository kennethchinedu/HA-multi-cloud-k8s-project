# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an SRE learning project that deploys a microservices e-commerce application (Google's Online Boutique) on a self-managed Kubernetes cluster. It demonstrates GitOps, service mesh, infrastructure-as-code, and platform engineering patterns.

## Architecture

The project has three distinct layers:

### 1. Infrastructure Layer (`infra/`)
Terragrunt wraps Terraform to provision platform tooling onto an existing Kubernetes cluster. The `root.hcl` defines the Kubernetes and Helm providers (pointing to `~/.kube/config`). The only environment is `prod/`, with a single `utils` module that installs via Helm:
- **ArgoCD** (GitOps controller)
- **Istio** (service mesh: base, istiod, CNI, and ingress gateway)
- **Chaos Mesh** (fault injection)

Run infra from the leaf directory:
```bash
cd infra/environments/prod/utils
terragrunt plan
terragrunt apply
```

### 2. Application Layer (`base/`)
Raw Kubernetes manifests for the 11 microservices of the Online Boutique app. All images are tagged `anamskenneth/<service>:2025-07-24` and pulled with the `reposecret` imagePullSecret. Every pod mounts a `hostPath` volume at `/etc/app` → `/etc/localdev`.

Services and their ports:
| Service | Port |
|---|---|
| frontend | 8080 |
| product-catalog | 3550 |
| cart | 7070 |
| email | 8080 |
| checkout | 5050 |
| recommendation | 8080 |
| currency | 7000 |
| ads | 9555 |
| shipping | 50051 |
| payment | 5000 |
| redis-cart | 6379 |

HPAs in `base/hpa.yaml` cover all services (1–10 replicas, CPU 50% / memory 75%).

Apply the full app stack:
```bash
kubectl apply -f base/
```

### 3. GitOps Layer (`gitops/`)
ArgoCD ApplicationSets are intended to live under `gitops/apps/appsets/`, with Applications under `gitops/apps/applications/` and platform tools under `gitops/apps/platform/`. The `gitops/project/` directory holds ArgoCD Project definitions. These directories are currently empty — this is where GitOps config should be added.

### Policy Layer (`policies/`)
Intended for OPA/Kyverno policies organized by concern: `security/`, `networking/`, `cost/`, `mutations/`. Currently empty.

### Helm Charts
- `boutique-app/` — Helm chart wrapping the boutique application
- `platform/istio/` — Helm chart scaffold for Istio (placeholder, actual Istio is installed via `infra/`)

## Local Cluster Bootstrap

The `bootstrap/vagrantfile` provisions a 4-node Kubernetes cluster via VirtualBox:
- Control plane: `192.168.56.10` (4GB RAM, 2 CPU)
- Workers: `192.168.56.11–13` (2GB RAM each, 2 CPU)

```bash
cd bootstrap
vagrant up
```

Enable Istio sidecar injection on a namespace:
```bash
kubectl label namespace <your-namespace> istio-injection=enabled
```

## Key Conventions

- **Image pull secret**: All services except `email-app` use `imagePullSecret: reposecret`. Create it before applying manifests.
- **Namespace**: All base manifests deploy to `default`.
- **Resource limits**: All resource requests/limits are commented out — uncomment and tune before production use.
- **Terragrunt environment variable**: `kubeconfig_context` in `prod.tfvars` defaults to `"minikube"` — change this to match the target cluster context.
