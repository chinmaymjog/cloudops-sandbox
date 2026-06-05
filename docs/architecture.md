# Architecture and Decisions

Template note: remove or replace all "Example" and "Mini example" content after your first real draft.

## Document Control

- Project: CloudOps-Sandbox
- Owner: Chinmay Jog
- Last updated: 2026-06-05
- Version: 0.1.0

## How To Use This File

- Explain design choices so a new engineer can understand trade-offs quickly.
- Keep each section tied to requirement IDs from docs/project-spec.md.
- Add one ADR entry whenever a non-trivial decision is made.

## System Context

### Business and Technical Context

CloudOps-Sandbox provides a local-cloud style platform for testing infrastructure components, observability stacks, and automation tools with a consistent ingress and environment model.

### Architecture Goals

- Keep onboarding of new stacks modular and low-friction.
- Ensure consistent ingress/routing and shared persistence patterns.

## High-Level Design

### Component Overview

| Component | Responsibility | Owner |
| --------- | -------------- | ----- |
| Traefik Edge | TLS/routing and ingress entry point | Platform Team |
| Stack Catalog (`stacks/*`) | Modular application/service definitions | Platform Team |
| Shared Datastores | Stateful backends for dependent services | Platform Team |
| Automation Scripts/Make | Lifecycle orchestration and setup | Platform Team |

### Interaction Diagram

See high-level architecture diagram in `README.md`.

## Data and Control Flow

### Request/Response Flow

1. User accesses stack host (`<service>.<APP_DOMAIN>`).
2. Traefik resolves route and forwards request to target stack service.
3. Service reads stack-specific env and optional shared datastore credentials.
4. Observability stack captures metrics and service health signals.

### State and Data Model Notes

- Persistent service state is maintained through named Docker volumes.
- Shared DB initialization scripts create service-specific users/databases.

### Failure Paths

- Broken stack env generation blocks startup in setup phase.
- Routing misconfiguration causes service unreachability despite container health.
- Database sync failures leave partially initialized dependencies.

## Deployment Architecture

### Environments

- Local laptop/dev workstation
- Remote VM (public IP or managed DNS)

### Runtime Topology

- Single Docker host with multiple compose-defined stacks.
- Shared control-plane network for ingress and inter-stack connectivity.

### Release and Rollback Strategy

- Deploy changes via Git branch + PR.
- Rollback by reverting compose/env/script changes and re-running lifecycle commands.

## Security and Compliance

- AuthN/AuthZ model: Stack-specific auth; optional identity provider integration via Keycloak.
- Secret management: `.env.template` tracked, real `.env` excluded from VCS.
- Input validation boundaries: Traefik routing + stack application validation.
- Audit/logging requirements: Service logs plus Traefik and observability telemetry.

## Observability Strategy

- Logs: container/service logs via Docker and stack tools.
- Metrics: Prometheus scraping for stack monitoring.
- Traces: not standardized yet; candidate future enhancement.
- Alerts/SLOs: currently manual/experimental; to be formalized.

## External Dependencies

| Dependency | Purpose | SLA/Risk | Backup Plan |
| ---------- | ------- | -------- | ----------- |
| Docker Engine/Desktop | Runtime execution | Local daemon instability | Restart daemon and re-run lifecycle |
| DNS (`nip.io` or public provider) | Hostname routing strategy | DNS/cert setup errors | Fall back to host mapping/self-signed mode |

## Architecture Decision Records (ADR-lite)

### Decision Template

- ID: ADR-00X
- Title:
- Status: Proposed | Accepted | Deprecated | Superseded
- Date:
- Context:
- Decision:
- Requirement links: FR-... | NFR-...
- Alternatives considered:
- Consequences:
- Review trigger:

### Decisions

- ID: ADR-001
- Title: Use modular stack directories under `stacks/<name>`
- Status: Accepted
- Date: 2026-06-05
- Context: Need scalable onboarding for many tools without monolithic compose file.
- Decision: Each tool/service is encapsulated in its own stack directory with compose and env template.
- Requirement links: FR-002, NFR-002
- Alternatives considered: Single large compose file.
- Consequences: Better modularity, more files to maintain.
- Review trigger: Stack count causes excessive orchestration overhead.

- ID: ADR-002
- Title: Standardize ingress on Traefik with wildcard host strategy
- Status: Accepted
- Date: 2026-06-05
- Context: Need consistent access pattern for local and remote runs.
- Decision: Route all stack access through Traefik using APP_DOMAIN pattern.
- Requirement links: FR-003, NFR-001
- Alternatives considered: Per-stack host port exposure.
- Consequences: Better consistency, ingress complexity increases.
- Review trigger: Routing conflicts or TLS management overhead becomes dominant.

## Requirement to Design Mapping

| Requirement ID | Architectural Element | ADR ID | Notes |
| -------------- | --------------------- | ------ | ----- |
| FR-001 | Makefile + scripts lifecycle | ADR-001 | setup/up/down/status contract |
| FR-002 | `stacks/<name>` modular pattern | ADR-001 | per-stack encapsulation |
| FR-003 | Traefik edge routing | ADR-002 | wildcard host approach |
| FR-004 | DB sync workflow | ADR-001 | incremental DB provisioning |
| FR-005 | README deployment flows | ADR-002 | local + remote consistency |
| NFR-001 | Cross-OS workflow | ADR-002 | local/remote deployment options |
| NFR-002 | Low-friction lifecycle ops | ADR-001 | make-target standardization |
| NFR-003 | Env template strategy | ADR-001 | real env excluded from VCS |
| NFR-004 | Named volume persistence | ADR-001 | state retention model |

## Lessons Learned

- Modular stack boundaries reduce coupling and experimentation risk.
- Unified ingress significantly improves operator usability.

## Pending Decisions

- Decision needed: Standard tracing approach across stacks.
- Owner: Platform Team
- Due date: 2026-07-15
