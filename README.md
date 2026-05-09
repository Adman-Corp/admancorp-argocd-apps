# admancorp-argocd-apps

Argo CD application repository for AdmanCorp's multi-cloud Kubernetes platform.

## Purpose

This repository is a GitOps control repo. It stores Argo CD resources that define what should run in each cluster and environment.

This repo is designed so multiple Argo CD control planes can consume the same Git repository without managing each other's applications.

The pattern in this repo is:
- `bootstrap/` contains one bootstrap `Application` per Argo CD control plane
- `roots/dev-base/` contains the shared Argo CD desired state for mirrored dev clusters
- `roots/<target>/` contains a thin Kustomize overlay for exactly one target cluster

## Example Layout

```text
.
├── bootstrap/
│   ├── azure-dev.yaml
│   └── gcp-dev.yaml
└── roots/
    ├── dev-base/
    │   ├── application/
    │   │   └── platform-dev.yaml
    │   ├── project/
    │   │   └── platform.yaml
    │   └── kustomization.yaml
    ├── azure-dev/
    │   ├── patches/
    │   │   └── platform-app.yaml
    │   └── kustomization.yaml
    └── gcp-dev/
        ├── patches/
        │   └── platform-app.yaml
        └── kustomization.yaml
```

## Bootstrap

Apply the matching bootstrap application in each Argo CD control plane namespace.

For the Azure Argo CD instance:

```bash
kubectl apply -n argocd -f bootstrap/azure-dev.yaml
```

For the GCP Argo CD instance:

```bash
kubectl apply -n argocd -f bootstrap/gcp-dev.yaml
```

Each Argo CD instance only reconciles the subtree it points to.

## What This Deploys

- `bootstrap/azure-dev.yaml` creates `root-azure-dev`, which reconciles `roots/azure-dev`
- `roots/azure-dev` creates `platform-azure-dev`, which deploys `environments/dev/azure`
- `bootstrap/gcp-dev.yaml` creates `root-gcp-dev`, which reconciles `roots/gcp-dev`
- `roots/gcp-dev` creates `platform-gcp-dev`, which deploys `environments/dev/gcp`

The shared Argo CD desired state lives in `roots/dev-base`. The cloud-specific roots only patch the application name and source path.

Both targets deploy to the in-cluster destination `https://kubernetes.default.svc`, so each Argo CD instance manages its own cluster.

## Notes

- Replace `https://github.com/Adman-Corp/admancorp-argocd-apps.git` if you fork this repo.
- `platform-azure-dev` points at `https://github.com/Adman-Corp/admancorp-platform-manifest.git` and path `environments/dev/azure`.
- `platform-gcp-dev` points at `https://github.com/Adman-Corp/admancorp-platform-manifest.git` and path `environments/dev/gcp`.
- The shared mirrored dev application shape lives in `roots/dev-base/application/platform-dev.yaml`.
- This layout is the simplest model when each Argo CD runs inside the cluster it manages.
- If you later add `uat` and `prod`, keep using one bootstrap file and one root subtree per Argo CD target.
- For production, pin Git SHAs or tags rather than floating branches where possible.
- Keep secrets out of this repo unless they are encrypted with a supported workflow such as SOPS or Sealed Secrets.
