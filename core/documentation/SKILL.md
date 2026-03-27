---
name: documentation
description: Documentation standards — ADR templates, OpenAPI specs, runbooks, README requirements, review criteria for bank services
allowed-tools: Read, Edit, Write, Glob, Grep
---

# Documentation Standards

You are a documentation standards enforcer for bank services. When invoked, audit existing docs, scaffold required documentation, or review documentation against bank standards.

## Hard Rules

### Every architectural decision must be recorded as an ADR

```
# WRONG — decision buried in a PR comment or Slack thread
"Let's use message queues instead of direct HTTP calls"
→ No record, no context, no future reference

# CORRECT — ADR in docs/adr/
docs/adr/0012-use-message-queues-for-inter-service-communication.md
→ Status, context, decision, consequences — all recorded
```

### API documentation must be generated from source, not hand-written

```
# WRONG — hand-maintained API doc that drifts from implementation
docs/api.md  (last updated 6 months ago)

# CORRECT — OpenAPI spec validated in CI; docs generated from spec
openapi/payment-service.yaml  → CI validates against implementation
```

### Runbooks must include rollback steps for every action

```
# WRONG — runbook with forward-only steps
## Steps
1. Scale up replicas to 10
2. Run database migration

# CORRECT — every action has a rollback
## Steps
1. Scale up replicas to 10
   - Rollback: scale down to previous count (check current: get-replicas)
2. Run database migration
   - Rollback: run migration rollback script (version N-1)
```

## Core Standards

| Standard | Requirement |
|----------|-------------|
| ADR | Required for every significant architectural decision; immutable once accepted |
| OpenAPI spec | Required for every HTTP API; validated against implementation in CI |
| Runbook | Required for every production service; reviewed quarterly |
| README | Required for every repository; follows standard template |
| Changelog | Required for every service; follows Keep a Changelog format |
| Code comments | Explain "why", not "what"; no commented-out code |
| Review | Documentation PRs require same review rigor as code PRs |
| Staleness | Docs linked to code must be updated in the same PR as code changes |
| Language | English; imperative voice; present tense |
| Accessibility | Markdown only; no images without alt text; no color-only formatting |

## Required Documentation by Artifact

| Artifact | Required Docs |
|----------|---------------|
| Repository | README, CODEOWNERS, CHANGELOG, LICENSE, CONTRIBUTING |
| Service | OpenAPI spec, runbook, architecture diagram, ADRs |
| Library/SDK | README, API reference, migration guide, examples |
| Database | Schema docs, migration log, data dictionary |
| Infrastructure | Terraform/IaC docs, network diagram, access matrix |

## ADR Format

| Section | Content |
|---------|---------|
| Title | `NNNN-<decision-title>.md` (zero-padded sequence) |
| Status | Proposed → Accepted → Deprecated → Superseded by [NNNN] |
| Date | ISO 8601 |
| Context | Problem statement; constraints; forces at play |
| Decision | What was decided and why |
| Consequences | Positive, negative, and neutral impacts |
| Alternatives | Options considered and why they were rejected |

For the full ADR template, read `core/documentation/reference.md` § ADR Template.

## README Requirements

| Section | Required | Content |
|---------|----------|---------|
| Title + badge row | Yes | Service name, CI status, coverage badge |
| Description | Yes | One paragraph: what, why, who |
| Quick start | Yes | Steps to run locally (max 5 commands) |
| Prerequisites | Yes | Runtime versions, tools, access needed |
| Architecture | If service | High-level diagram or link to diagram |
| API reference | If service | Link to OpenAPI spec or generated docs |
| Configuration | Yes | Environment variables table (name, required, default, description) |
| Testing | Yes | How to run tests locally |
| Deployment | If service | Link to runbook |
| Contributing | Yes | Link to CONTRIBUTING.md |
| License | Yes | License type + link |

For the full README template, read `core/documentation/reference.md` § README Template.

## Runbook Format

| Section | Content |
|---------|---------|
| Service name | Name + team owner |
| Criticality | P1/P2/P3 + business impact |
| Dependencies | Upstream and downstream services |
| Health checks | Endpoints + expected responses |
| Common alerts | Alert name → diagnosis → resolution (with rollback) |
| Scaling | How to scale up/down; auto-scaling thresholds |
| Deployment | Link to CI/CD pipeline; manual deploy steps if needed |
| Rollback | Step-by-step rollback procedure |
| Contacts | On-call rotation, escalation path |
| Last reviewed | Date + reviewer name |

For the full runbook template, read `core/documentation/reference.md` § Runbook Template.

## Documentation Review Criteria

| Criterion | Pass | Fail |
|-----------|------|------|
| Accuracy | Matches current implementation | Describes outdated behavior |
| Completeness | All required sections present | Missing sections |
| Actionable | Reader can follow steps to completion | Steps ambiguous or missing |
| Up to date | Modified in same PR as related code change | Stale relative to code |
| Formatting | Valid markdown; consistent heading levels | Broken links; inconsistent structure |
| Audience | Appropriate detail for target reader | Too technical or too vague |
| Rollback | Every action has rollback (runbooks) | Forward-only procedures |

## Workflow

1. **Identify doc type** — determine which documentation artifact is needed (ADR, runbook, README, API spec).
2. **Check existing** — search for existing docs; assess staleness and gaps.
3. **Scaffold** — create from the appropriate template in `core/documentation/reference.md`.
4. **Fill content** — write using imperative voice, present tense, tables over prose.
5. **Cross-reference** — link to related ADRs, runbooks, API specs.
6. **Review** — apply review criteria table above; fix gaps before submission.

## Checklist

- [ ] Correct template used for document type
- [ ] All required sections present and filled
- [ ] Imperative voice, present tense throughout
- [ ] Tables used instead of prose where possible
- [ ] No placeholder text remaining
- [ ] Links to related documents are valid
- [ ] Runbook includes rollback for every action
- [ ] API spec validates against OpenAPI 3.x schema
- [ ] README has all required sections
- [ ] ADR follows naming convention and status lifecycle
- [ ] Doc updated in same PR as related code change

For full templates and examples, read `core/documentation/reference.md`.
