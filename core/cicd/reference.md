# CI/CD Pipeline Standards — Reference

## Pipeline Templates

### Minimal Pipeline Structure

```yaml
# Generic pipeline — adapt to your CI system (GitHub Actions, GitLab CI, Jenkins, etc.)
pipeline:
  stages:
    - build
    - test
    - security
    - approval
    - deploy-staging
    - smoke-staging
    - deploy-prod
    - smoke-prod

  build:
    steps:
      - checkout
      - install-dependencies --lockfile-only
      - compile
      - publish-artifact --tag=$COMMIT_SHA --sign

  test:
    steps:
      - pull-artifact --tag=$COMMIT_SHA
      - run-unit-tests --coverage --min-coverage=80
      - run-integration-tests
      - upload-test-results

  security:
    steps:
      - run-sast --fail-on=high,critical
      - run-dependency-scan --fail-on-cve
      - run-license-scan --policy=bank-approved
      - upload-security-report

  approval:
    type: manual
    required-approvers: 1
    allowed-roles: [release-manager, tech-lead]
    timeout: 48h

  deploy-staging:
    steps:
      - pull-artifact --tag=$COMMIT_SHA
      - deploy --env=staging --config=staging.env
      - wait-healthy --timeout=5m

  smoke-staging:
    steps:
      - run-smoke-tests --env=staging
      - validate-health-endpoints --env=staging

  deploy-prod:
    strategy: canary
    steps:
      - pull-artifact --tag=$COMMIT_SHA
      - deploy-canary --env=prod --percentage=5
      - monitor-metrics --duration=10m --error-threshold=0.1%
      - promote-canary --percentage=100
      - record-deployment --artifact=$COMMIT_SHA --approver=$APPROVER

  smoke-prod:
    steps:
      - run-smoke-tests --env=prod
      - validate-health-endpoints --env=prod
```

## Rollback Procedures

### Automated Rollback

```yaml
rollback:
  trigger:
    - error-rate > baseline + 2%
    - p99-latency > baseline + 500ms
    - health-check-failures > 3 consecutive
  action:
    - identify-last-good-artifact
    - deploy --env=$ENV --tag=$LAST_GOOD_SHA
    - notify-oncall --channel=deployments
    - create-incident --severity=P2
```

### Manual Rollback Procedure

| Step | Action | Owner |
|------|--------|-------|
| 1 | Identify last-good artifact SHA from deployment log | On-call engineer |
| 2 | Execute rollback: `deploy --env=prod --tag=$LAST_GOOD_SHA` | On-call engineer |
| 3 | Verify health endpoints return 200 | Automated |
| 4 | Run smoke tests against production | Automated |
| 5 | Notify stakeholders via incident channel | On-call engineer |
| 6 | Create post-mortem ticket | Release manager |

## Artifact Management

### Artifact Naming Convention

```
<service-name>-<semver>-<commit-sha-short>.<ext>
```

Example: `payment-service-2.4.1-a1b2c3d.tar.gz`

### Artifact Metadata

| Field | Required | Example |
|-------|----------|---------|
| `sha256` | Yes | `e3b0c44298fc1c149...` |
| `commit` | Yes | `a1b2c3d4e5f6` |
| `branch` | Yes | `release/2.4.1` |
| `build-time` | Yes | `2026-03-27T10:00:00Z` |
| `builder` | Yes | `ci-pipeline-id-12345` |
| `signature` | Yes | GPG or cosign signature |
| `test-report-url` | Yes | Link to test results |
| `security-scan-url` | Yes | Link to scan report |

### Retention Policy

| Artifact Type | Retention | Storage |
|---------------|-----------|---------|
| Production-deployed | 1 year minimum | Immutable registry |
| Staging-verified | 90 days | Immutable registry |
| Dev builds | 30 days | Standard registry |
| Failed builds | 7 days | Standard registry (for debugging) |

## Branch Strategy

### Branch Naming

| Branch | Purpose | Deploys To |
|--------|---------|------------|
| `main` | Production-ready code | prod (via release tag) |
| `develop` | Integration branch | dev |
| `release/<version>` | Release candidate | staging → prod |
| `feature/<ticket-id>-<desc>` | Feature work | dev (on merge to develop) |
| `hotfix/<ticket-id>-<desc>` | Emergency fix | staging → prod (expedited) |

### Hotfix Pipeline

Hotfixes follow an expedited path but still enforce all gates:

| Step | Standard Release | Hotfix |
|------|-----------------|--------|
| Build & test | Yes | Yes |
| Security scan | Yes | Yes (abbreviated — critical only) |
| Staging deploy | Yes | Yes (automated) |
| Staging smoke | Yes | Yes (automated) |
| Approval | 1 approver, 48h timeout | 1 approver, 2h timeout |
| Prod deploy | Canary 5% → 100% | Canary 10% → 100% (faster ramp) |

## Deployment Audit Log Schema

```json
{
  "deployment_id": "deploy-20260327-001",
  "timestamp": "2026-03-27T14:30:00Z",
  "environment": "prod",
  "service": "payment-service",
  "artifact_sha": "a1b2c3d4e5f6",
  "artifact_version": "2.4.1",
  "deployer": "ci-pipeline",
  "approver": "jane.doe@bank.com",
  "approval_id": "approval-98765",
  "status": "success",
  "rollback_of": null,
  "canary_percentage": 100,
  "health_check_passed": true,
  "smoke_test_passed": true
}
```

## Monitoring & Alerts Post-Deploy

| Metric | Threshold | Action |
|--------|-----------|--------|
| Error rate (5xx) | > baseline + 1% | Alert on-call |
| Error rate (5xx) | > baseline + 2% | Auto-rollback |
| p99 latency | > baseline + 500ms | Alert on-call |
| p99 latency | > baseline + 1s | Auto-rollback |
| Health check failures | 3 consecutive | Auto-rollback |
| CPU/Memory | > 90% sustained 5 min | Alert on-call |

## Security Scan Configuration

### SAST Rules

| Severity | Action | Examples |
|----------|--------|----------|
| Critical | Block deployment | SQL injection, hardcoded credentials, path traversal |
| High | Block deployment | XSS, insecure deserialization, weak crypto |
| Medium | Warn; track in backlog | Missing input validation, verbose errors |
| Low | Informational | Code style security hints |

### Dependency Scan

| Finding | Action |
|---------|--------|
| Known CVE (critical/high) | Block; patch or exclude dependency |
| Known CVE (medium/low) | Warn; create backlog ticket with SLA |
| Outdated dependency (no CVE) | Informational; update in next cycle |
| Banned license | Block; see `core/license-compliance` |
