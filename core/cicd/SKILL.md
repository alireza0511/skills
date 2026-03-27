---
name: cicd
description: CI/CD pipeline standards — deployment gates, environment promotion, rollback policy, immutable artifacts for bank services
allowed-tools: Read, Edit, Write, Glob, Grep
---

# CI/CD Pipeline Standards

You are a CI/CD standards enforcer for bank services. When invoked, audit or scaffold pipeline configurations against deployment gates, promotion policy, and artifact integrity rules.

## Hard Rules

### Every deployment must pass all gates before promotion

```yaml
# WRONG — deploying without security scan
stages: [build, test, deploy-prod]

# CORRECT — all gates enforced
stages: [build, test, security-scan, approval, deploy-staging, smoke-test, deploy-prod]
```

### Artifacts must be immutable — build once, deploy everywhere

```yaml
# WRONG — rebuilding per environment
build-staging:
  script: build --env=staging
build-prod:
  script: build --env=prod

# CORRECT — build once, inject config at deploy time
build:
  script: build && publish-artifact --tag=$SHA
deploy:
  script: pull-artifact --tag=$SHA && configure --env=$TARGET_ENV
```

### Rollback must use a previously verified artifact, never a new build

```yaml
# WRONG — rebuilding from old commit
rollback:
  script: git checkout $OLD_SHA && build && deploy

# CORRECT — redeploy known-good artifact
rollback:
  script: deploy-artifact --tag=$LAST_GOOD_SHA --env=prod
```

### Secrets must never appear in pipeline logs or artifact metadata

```yaml
# WRONG — secret in plain text
env:
  DB_PASSWORD: "s3cret"

# CORRECT — reference from vault
env:
  DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
```

## Core Standards

| Standard | Requirement |
|----------|-------------|
| Build reproducibility | Deterministic builds; pinned dependencies; content-addressable artifact tags |
| Security scan | SAST + dependency scan must pass before any deployment |
| Test gate | Unit + integration tests must pass with ≥80% coverage |
| Approval gate | Production deployments require ≥1 authorized approver |
| Environment promotion | dev → staging → prod; no skipping stages |
| Artifact storage | Signed, versioned, stored in immutable registry; 90-day retention |
| Rollback SLA | Rollback executable within 15 minutes; automated health-check triggers |
| Secrets management | All secrets from vault/secret manager; rotated per policy |
| Audit trail | Every deployment logged: who, what, when, artifact SHA, approval ID |
| Branch policy | `main` protected; merge requires PR + passing pipeline + review |

## Deployment Gates

| Gate | Stage | Blocks Promotion If |
|------|-------|---------------------|
| Lint & format | Build | Any lint error |
| Unit tests | Test | Any failure or coverage < threshold |
| Integration tests | Test | Any failure |
| SAST scan | Security | Critical or high findings |
| Dependency scan | Security | Known CVEs in dependencies |
| License scan | Security | Banned license detected (see `core/license-compliance`) |
| Manual approval | Pre-prod | No authorized approval recorded |
| Smoke tests | Post-deploy | Health endpoints fail |
| Canary metrics | Post-deploy | Error rate > baseline + threshold |

## Environment Promotion

| Environment | Purpose | Promotion Trigger | Rollback Policy |
|-------------|---------|-------------------|-----------------|
| dev | Feature integration | Merge to `develop` | Automatic; redeploy `develop` HEAD |
| staging | Pre-production validation | All gates pass on `release/*` | Redeploy last-good artifact |
| prod | Live traffic | Manual approval + staging smoke pass | Automated canary; manual override within 15 min |

For full pipeline templates and environment-specific configs, read `core/cicd/reference.md` § Pipeline Templates.

## Workflow

1. **Identify scope** — new pipeline, audit existing, or add deployment gate.
2. **Verify gate coverage** — check all gates from the table above are present in pipeline config.
3. **Validate promotion path** — confirm dev → staging → prod with no skipped stages.
4. **Check artifact integrity** — ensure build-once pattern; no per-environment rebuilds.
5. **Verify rollback mechanism** — confirm rollback uses previously verified artifact, not a new build.
6. **Audit secrets** — confirm no hardcoded secrets; all sourced from vault.
7. **Validate audit trail** — confirm deployment events are logged with required metadata.

## Checklist

- [ ] All deployment gates present and enforced
- [ ] Environment promotion follows dev → staging → prod
- [ ] Artifacts are immutable; built once, deployed everywhere
- [ ] Rollback uses known-good artifact (no rebuild)
- [ ] Secrets sourced from vault; none in logs or config files
- [ ] Production deployment requires manual approval
- [ ] Smoke tests run post-deployment in every environment
- [ ] Audit trail captures who, what, when, SHA, approval ID
- [ ] Branch protection enforced on `main`
- [ ] Pipeline config stored in version control

For detailed templates and examples, read `core/cicd/reference.md` § Pipeline Templates.
