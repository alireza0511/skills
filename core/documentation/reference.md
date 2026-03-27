# Documentation Standards — Reference

## ADR Template

```markdown
# NNNN — [Decision Title]

## Status

[Proposed | Accepted | Deprecated | Superseded by [NNNN]]

## Date

YYYY-MM-DD

## Context

[Describe the problem, constraints, and forces. What prompted this decision?
Include relevant technical context, business requirements, and constraints.
2-4 paragraphs maximum.]

## Decision

[State the decision clearly. Use imperative voice.
"We will use X because Y."
1-2 paragraphs maximum.]

## Consequences

### Positive
- [Benefit 1]
- [Benefit 2]

### Negative
- [Trade-off 1]
- [Trade-off 2]

### Neutral
- [Side effect that is neither positive nor negative]

## Alternatives Considered

### [Alternative A]
- **Description:** [What this option entails]
- **Pros:** [advantages]
- **Cons:** [disadvantages]
- **Reason rejected:** [why]

### [Alternative B]
- **Description:** [What this option entails]
- **Pros:** [advantages]
- **Cons:** [disadvantages]
- **Reason rejected:** [why]

## References

- [Link to relevant RFC, documentation, or prior ADR]
```

### ADR Naming Convention

| Pattern | Example |
|---------|---------|
| `NNNN-kebab-case-title.md` | `0012-use-message-queues-for-inter-service-communication.md` |
| Sequence | Zero-padded, monotonically increasing |
| Directory | `docs/adr/` at repository root |
| Index | `docs/adr/README.md` lists all ADRs with status |

### ADR Status Transitions

```
Proposed → Accepted → (Deprecated | Superseded by NNNN)
```

- **Proposed**: Under discussion; not yet agreed upon.
- **Accepted**: Agreed and in effect. The ADR body is immutable after acceptance.
- **Deprecated**: No longer relevant; context has changed.
- **Superseded**: Replaced by a newer ADR (link to it).

Never edit an accepted ADR. Write a new ADR that supersedes it.

## README Template

```markdown
# [Service Name]

[![CI](badge-url)](pipeline-url) [![Coverage](badge-url)](coverage-url)

[One paragraph describing what this service does, why it exists, and who uses it.]

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| [Runtime] | >= X.Y | [link or command] |
| [Database] | >= X.Y | [link or command] |

## Quick Start

1. Clone the repository
2. Copy environment config: `cp .env.example .env`
3. Install dependencies: `[install command]`
4. Start dependencies: `[docker-compose or equivalent]`
5. Run the service: `[run command]`

## Architecture

[High-level description or link to architecture diagram.]

See [ADR-0001](docs/adr/0001-initial-architecture.md) for architectural decisions.

## API Reference

[Link to generated OpenAPI documentation or hosted docs.]

## Configuration

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DATABASE_URL` | Yes | — | PostgreSQL connection string |
| `LOG_LEVEL` | No | `info` | Logging verbosity: debug, info, warn, error |
| `PORT` | No | `8080` | HTTP server port |

## Testing

Run all tests:
```
[test command]
```

Run with coverage:
```
[coverage command]
```

## Deployment

See [Runbook](docs/runbook.md) for deployment and operational procedures.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[License type]. See [LICENSE](LICENSE).
```

## Runbook Template

```markdown
# [Service Name] — Runbook

## Service Overview

| Field | Value |
|-------|-------|
| Service | [name] |
| Team | [owning team] |
| Criticality | [P1 / P2 / P3] |
| Business Impact | [what breaks if this service is down] |
| Repository | [link] |
| Dashboard | [link to monitoring dashboard] |
| On-call | [rotation name or link] |

## Dependencies

### Upstream (this service depends on)

| Service | Type | Failure Impact |
|---------|------|----------------|
| [service-a] | HTTP API | [degraded feature X] |
| [database] | PostgreSQL | [full outage] |
| [message-queue] | Async | [delayed processing] |

### Downstream (depends on this service)

| Service | Type | Impact if We Fail |
|---------|------|-------------------|
| [service-b] | HTTP API | [feature Y unavailable] |

## Health Checks

| Endpoint | Expected Response | Interval |
|----------|-------------------|----------|
| `GET /health` | `200 {"status": "ok"}` | 30s |
| `GET /health/ready` | `200` when ready to serve | 30s |
| `GET /health/live` | `200` when process is alive | 10s |

## Common Alerts

### [Alert Name: High Error Rate]

- **Trigger:** 5xx error rate > 1% for 5 minutes
- **Severity:** P2
- **Diagnosis:**
  1. Check service logs: `[log query command]`
  2. Check dependency health: `[health check commands]`
  3. Check recent deployments: `[deployment log command]`
- **Resolution:**
  1. If caused by recent deployment → rollback (see Rollback section)
  2. If caused by dependency failure → check upstream status; enable circuit breaker
  3. If cause unknown → scale up replicas; engage on-call for root cause
- **Rollback:** `[rollback command]`

### [Alert Name: High Latency]

- **Trigger:** p99 latency > 2s for 5 minutes
- **Severity:** P3
- **Diagnosis:**
  1. Check slow query log: `[query command]`
  2. Check connection pool: `[pool status command]`
  3. Check CPU/memory: `[resource command]`
- **Resolution:**
  1. If database-related → check for long-running queries; kill if safe
  2. If resource-related → scale up; investigate memory leak
  3. If traffic spike → enable rate limiting
- **Rollback:** N/A (latency alert; rollback only if deployment-caused)

## Scaling

| Action | Command | Rollback |
|--------|---------|----------|
| Scale up | `scale-service --replicas=N` | `scale-service --replicas=[previous]` |
| Auto-scale threshold | CPU > 70% for 3 min → add replica | CPU < 30% for 10 min → remove replica |
| Max replicas | [N] | — |
| Min replicas | [N] | — |

## Deployment

- **Pipeline:** [link to CI/CD pipeline]
- **Deploy command:** [if manual override needed]
- **Canary strategy:** 5% → 25% → 100% over 30 minutes
- **Smoke test:** Runs automatically post-deploy

## Rollback

| Step | Action | Command | Verification |
|------|--------|---------|--------------|
| 1 | Identify last-good version | `get-deployment-history --env=prod --limit=5` | — |
| 2 | Execute rollback | `deploy --env=prod --tag=[LAST_GOOD_SHA]` | — |
| 3 | Verify health | `check-health --env=prod` | All endpoints return 200 |
| 4 | Verify smoke tests | `run-smoke --env=prod` | All pass |
| 5 | Notify team | Post in #deployments channel | — |
| 6 | Create incident | `create-incident --service=[name] --severity=[P]` | — |

## Contacts

| Role | Contact | Escalation |
|------|---------|------------|
| On-call engineer | [rotation link] | — |
| Tech lead | [name] | If on-call cannot resolve in 30 min |
| Service owner | [name] | If P1; or if unresolved after 1 hour |
| Management | [name] | If P1 and customer-impacting > 30 min |

## Review History

| Date | Reviewer | Changes |
|------|----------|---------|
| [YYYY-MM-DD] | [Name] | [Initial version / Updated X section] |
```

## OpenAPI Specification Standards

### Required Fields

| Field | Location | Requirement |
|-------|----------|-------------|
| `info.title` | Root | Service name |
| `info.version` | Root | Semantic version matching service version |
| `info.description` | Root | One paragraph describing the API |
| `servers` | Root | All environments (dev, staging, prod) |
| `paths.*.operationId` | Each operation | Unique, camelCase identifier |
| `paths.*.summary` | Each operation | One-line description |
| `paths.*.description` | Each operation | Detailed behavior, edge cases |
| `paths.*.responses` | Each operation | All possible status codes |
| `paths.*.responses.*.description` | Each response | When this response occurs |
| `components.schemas` | Shared | All request/response models |
| `security` | Root or operation | Authentication requirements |

### Response Documentation

Every endpoint must document these responses:

| Status | When |
|--------|------|
| `200` / `201` | Success |
| `400` | Validation error (document common cases) |
| `401` | Not authenticated |
| `403` | Not authorized |
| `404` | Resource not found |
| `429` | Rate limit exceeded |
| `500` | Internal server error |

### CI Validation

```yaml
api-docs:
  steps:
    - validate-openapi openapi/service.yaml
    - check-breaking-changes --base=main openapi/service.yaml
    - generate-docs openapi/service.yaml --output=docs/api/
```

## Changelog Format

Follow [Keep a Changelog](https://keepachangelog.com/) format:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- [New feature description]

### Changed
- [Enhancement to existing feature]

### Fixed
- [Bug fix description]

### Removed
- [Removed feature or deprecated item]

## [2.4.1] - 2026-03-27

### Fixed
- Correct currency formatting for IRR locale

## [2.4.0] - 2026-03-20

### Added
- Multi-currency transfer support
```

### Changelog Categories

| Category | Use When |
|----------|----------|
| Added | New feature |
| Changed | Enhancement to existing feature |
| Deprecated | Feature will be removed in future |
| Removed | Feature removed |
| Fixed | Bug fix |
| Security | Vulnerability fix |

## Documentation Review Checklist (Detailed)

### General

- [ ] Correct template used
- [ ] All required sections present
- [ ] No placeholder text (`[TODO]`, `TBD`, `...`)
- [ ] Spelling and grammar checked
- [ ] Consistent terminology (see project glossary)
- [ ] Imperative voice throughout ("Run the command" not "You should run the command")

### Technical Accuracy

- [ ] Code examples tested and working
- [ ] Commands copy-pasteable
- [ ] Version numbers current
- [ ] Links valid (no 404s)
- [ ] Environment variables match actual config
- [ ] Architecture diagram matches implementation

### Accessibility

- [ ] All images have alt text
- [ ] Tables have header rows
- [ ] No information conveyed by color alone
- [ ] Code blocks have language annotations
- [ ] Heading hierarchy is correct (no skipped levels)
