# Project Spec

**What:** a local cloud lab for trying infrastructure, observability and
automation tools on a laptop or a VM.

**Goals**

- Every step is a command you can read and run — no hidden automation.
- Adding a service: copy `template/`, add its `.env` values, create its
  database if it needs one, add it to `STACKS`.
- Same flow on a laptop or a VM, and on both branches.

**Not in scope:** production use, multi-tenancy, Kubernetes (see
`k3s-argocd-sandbox`).

**Done when:** a new user goes from clone to a running lab in under 15
minutes using only the README.
