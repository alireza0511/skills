# Project Scaffolding — Reference

## Bootstrap Script Template

A generic bootstrap script that creates the required structure for a new repository:

```
#!/usr/bin/env bash
# bootstrap.sh — Initialize a new bank service repository
# Usage: ./bootstrap.sh <service-name> <team-name> [repo-type]
# repo-type: service (default), library, infrastructure

set -euo pipefail

SERVICE_NAME="${1:?Usage: bootstrap.sh <service-name> <team-name> [repo-type]}"
TEAM_NAME="${2:?Usage: bootstrap.sh <service-name> <team-name> [repo-type]}"
REPO_TYPE="${3:-service}"

echo "Bootstrapping ${REPO_TYPE}: ${SERVICE_NAME} for team ${TEAM_NAME}"

# Create base directories
mkdir -p .github/workflows
mkdir -p docs/adr
mkdir -p src
mkdir -p test
mkdir -p scripts

# Type-specific directories
case "${REPO_TYPE}" in
  service)
    mkdir -p openapi
    mkdir -p infra
    ;;
  library)
    mkdir -p examples
    ;;
  infrastructure)
    mkdir -p modules
    mkdir -p environments
    ;;
esac

# Create CODEOWNERS
cat > .github/CODEOWNERS << EOF
* @org/${TEAM_NAME}
EOF

# Create PR template
cat > .github/pull_request_template.md << 'EOF'
## Description
[What does this PR do? Link to ticket.]

## Type
- [ ] Feature
- [ ] Bug fix
- [ ] Refactor
- [ ] Documentation
- [ ] Infrastructure

## Testing
[How was this tested?]

## Checklist
- [ ] Tests pass locally
- [ ] Documentation updated (if applicable)
- [ ] No secrets committed
- [ ] CHANGELOG updated (if user-facing change)
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
# Secrets
.env
*.pem
*.key
credentials.json
secrets/

# Build output
build/
dist/
out/
target/

# Dependencies
node_modules/
vendor/
.venv/
__pycache__/

# IDE
.idea/
.vscode/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db
desktop.ini

# Test artifacts
coverage/
*.lcov
test-results/
EOF

# Create CHANGELOG
cat > CHANGELOG.md << EOF
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- Initial project setup
EOF

# Create CONTRIBUTING.md
cat > CONTRIBUTING.md << EOF
# Contributing to ${SERVICE_NAME}

## Getting Started
1. Clone the repository
2. Follow the Quick Start in README.md
3. Create a feature branch from \`develop\`

## Pull Request Process
1. Update documentation for any changed behavior
2. Update CHANGELOG.md for user-facing changes
3. Ensure CI passes
4. Request review from CODEOWNERS

## Commit Messages
Use conventional commits: \`type(scope): description\`

Types: feat, fix, docs, refactor, test, chore
EOF

# Create initial ADR
cat > docs/adr/README.md << EOF
# Architecture Decision Records

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [0001](0001-initial-architecture.md) | Initial Architecture | Proposed | $(date +%Y-%m-%d) |
EOF

# Create .env.example (services and infrastructure)
if [[ "${REPO_TYPE}" != "library" ]]; then
  cat > .env.example << 'EOF'
# Copy to .env and fill in values
# DO NOT commit .env — it is in .gitignore

# Application
PORT=8080
LOG_LEVEL=info

# Database
DATABASE_URL=<set-from-vault>

# External Services
# API_KEY=<set-from-vault>
EOF
fi

echo "Bootstrap complete. Next steps:"
echo "  1. Initialize git: git init && git checkout -b main"
echo "  2. Write README.md (see core/documentation § README Template)"
echo "  3. Add CI pipeline config in .github/workflows/"
echo "  4. Add LICENSE file"
echo "  5. Make initial commit"
```

## CODEOWNERS Patterns

### Syntax Reference

| Pattern | Meaning |
|---------|---------|
| `*` | Default owners for everything |
| `/src/` | Directory at repo root |
| `*.py` | All Python files anywhere |
| `/docs/` | Documentation directory |
| `CODEOWNERS` | The CODEOWNERS file itself (protect it) |

### Example — Multi-Team Service

```
# Default — service owning team
*                           @org/payments-team

# Infrastructure — platform team
/infra/                     @org/platform-team
/.github/workflows/         @org/platform-team

# API specification — API governance team
/openapi/                   @org/payments-team @org/api-governance

# Security-sensitive files — security team must also review
CODEOWNERS                  @org/payments-team @org/security-team
.github/workflows/          @org/payments-team @org/platform-team
```

## CI Pipeline Templates

### Minimal CI (GitHub Actions syntax)

```yaml
name: CI
on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main, develop]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install dependencies
        run: [install-command]
      - name: Lint
        run: [lint-command]

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install dependencies
        run: [install-command]
      - name: Run tests
        run: [test-command] --coverage
      - name: Check coverage threshold
        run: [coverage-check] --min=80

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: SAST scan
        run: [sast-command] --fail-on=high,critical
      - name: Dependency scan
        run: [dependency-scan-command]
      - name: License scan
        run: [license-scan-command] --policy=bank-approved
```

### Release Pipeline

```yaml
name: Release
on:
  push:
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build artifact
        run: [build-command]
      - name: Sign artifact
        run: [sign-command]
      - name: Generate SBOM
        run: [sbom-command] --format=spdx
      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: release-${{ github.ref_name }}
          path: |
            dist/*
            sbom.spdx.json
```

## Branch Protection Configuration

### Recommended Settings

| Setting | Value | Reason |
|---------|-------|--------|
| Require PR | Yes | No direct pushes to main |
| Required reviewers | ≥ 1 | Peer review |
| Dismiss stale reviews | Yes | Re-review after changes |
| Require status checks | Yes | CI must pass |
| Required checks | lint, test, security | Minimum gate set |
| Require up-to-date branch | Yes | No stale merges |
| Require signed commits | Yes (prod repos) | Verify commit author |
| Allow force push | No | Protect history |
| Allow deletion | No | Protect main branch |

## Repository Naming Convention

| Type | Pattern | Example |
|------|---------|---------|
| Service | `<domain>-service` | `payment-service` |
| Library | `<purpose>-lib` | `auth-lib` |
| SDK | `<platform>-sdk` | `mobile-sdk` |
| Infrastructure | `<scope>-infra` | `core-infra` |
| Documentation | `<scope>-docs` | `api-docs` |
| Config | `<scope>-config` | `deploy-config` |

Rules:
- Lowercase, kebab-case
- No organization prefix (handled by org namespace)
- Descriptive but concise (2-3 words)
- No abbreviations unless universally known (API, SDK, CLI)

## New Repository Validation Checklist

Run this after bootstrapping to verify completeness:

```
Repository Validation Report
==============================

Repository: [name]
Type:       [service / library / infrastructure]
Date:       [YYYY-MM-DD]
Validator:  [name or CI]

Required Files:
  [✓/✗] README.md — present and has all required sections
  [✓/✗] CODEOWNERS — present and covers all paths
  [✓/✗] CONTRIBUTING.md — present
  [✓/✗] LICENSE — present
  [✓/✗] .gitignore — present; excludes secrets, builds, IDE files
  [✓/✗] CHANGELOG.md — present (service/library)
  [✓/✗] .env.example — present; no real secrets (service/infra)
  [✓/✗] CI pipeline config — present and functional
  [✓/✗] PR template — present

Type-Specific:
  [✓/✗] openapi/*.yaml — present (service)
  [✓/✗] docs/runbook.md — present (service)
  [✓/✗] docs/adr/ — directory with initial ADR (service)

Configuration:
  [✓/✗] Branch protection on main
  [✓/✗] Secret scanning enabled
  [✓/✗] Default branch is 'main'
  [✓/✗] CI runs on PR and push to main

Result: [PASS / FAIL — list missing items]
```
