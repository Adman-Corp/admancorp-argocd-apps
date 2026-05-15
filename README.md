# admancorp-argocd-apps

Argo CD application repository for AdmanCorp's multi-cloud Kubernetes platform.

## Purpose

This repository is a GitOps control repo. It stores Argo CD resources that define what should run in each cluster and environment.

This repo is designed so multiple Argo CD control planes can consume the same Git repository without managing each other's applications.

The pattern in this repo is:
- `charts/argocd-apps/` is a Helm chart that generates all Argo CD `Application` and `AppProject` resources
- `values-azure-dev.yaml` and `values-gcp-dev.yaml` provide environment-specific overrides (app names, source paths, Helm value files)

## Layout

```text
.
├── charts/
│   └── argocd-apps/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│           ├── _helpers.tpl
│           ├── appprojects.yaml
│           └── applications.yaml
├── values-azure-dev.yaml
└── values-gcp-dev.yaml
```

## Usage

Render the manifests for a target environment:

```bash
# Azure dev
helm template argocd-apps charts/argocd-apps -f values-azure-dev.yaml

# GCP dev
helm template argocd-apps charts/argocd-apps -f values-gcp-dev.yaml
```

Apply the rendered output in each Argo CD control plane namespace:

```bash
helm template argocd-apps charts/argocd-apps -f values-azure-dev.yaml | kubectl apply -n argocd -f -
helm template argocd-apps charts/argocd-apps -f values-gcp-dev.yaml | kubectl apply -n argocd -f -
```

## What This Deploys

- `platform-azure-dev` Application points at `admancorp-platform-manifest` chart `charts/admancorp-platform` with `values-dev-azure.yaml`
- `platform-gcp-dev` Application points at `admancorp-platform-manifest` chart `charts/admancorp-platform` with `values-dev-gcp.yaml`
- `demo-app` Application deploys the demo Helm chart from `admancorp-applications-manifests`

The platform umbrella chart deploys all shared components: namespaces, cert-manager, external-secrets, envoy-gateway, kyverno, and observability (kube-prometheus-stack, loki, alloy). Observability defaults to disabled in dev and enabled in uat/prod via the values files.

The shared Argo CD desired state lives in `charts/argocd-apps/values.yaml` (the base/defaults). Cloud-specific overrides are provided via `values-azure-dev.yaml` and `values-gcp-dev.yaml`.

Both targets deploy to the in-cluster destination `https://kubernetes.default.svc`, so each Argo CD instance manages its own cluster.

## Notes

- Replace `https://github.com/Adman-Corp/admancorp-argocd-apps.git` if you fork this repo.
- `platform-azure-dev` points at `https://github.com/Adman-Corp/admancorp-platform-manifest.git` path `charts/admancorp-platform`.
- `platform-gcp-dev` points at `https://github.com/Adman-Corp/admancorp-platform-manifest.git` path `charts/admancorp-platform`.
- If you later add `uat` and `prod`, create additional `values-<env>.yaml` files with the same overrides pattern.
- For production, pin Git SHAs or tags rather than floating branches where possible.
- Keep secrets out of this repo unless they are encrypted with a supported workflow such as SOPS or Sealed Secrets.
