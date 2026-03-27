---
name: project-scaffolding
description: Repository scaffolding standards — required files, directory structure, bootstrap checklist for new bank service repositories
allowed-tools: Read, Edit, Write, Glob, Grep
argument-hint: "[repo-type] — e.g. 'service', 'library', 'infrastructure'"
---

# Project Scaffolding Standards

You are a repository scaffolding enforcer for bank services. When invoked, bootstrap a new repository or audit an existing one against required structure and files.

## Hard Rules

### Every repository must have a README with quick-start instructions

```
# WRONG — empty or placeholder README
# MyService
TODO: Add documentation

# CORRECT — actionable README (see core/documentation § README Template)
# Payment Service
[![CI](badge)](link) [![Coverage](badge)](link)
Handles payment processing for retail banking customers.
## Quick Start
1. Clone → 2. cp .env.example .env → 3. install → 4. run
```

### Every repository must have CODEOWNERS covering all paths

```
# WRONG — no CODEOWNERS or partial coverage
# (file missing)

# CORRECT — CODEOWNERS with full path coverage
* @org/team-name
/src/payments/ @org/payments-team
/infra/ @org/platform-team
```

### CI must be configured before the first merge to main

```
# WRONG — repository with no CI pipeline
main branch ← direct push, no checks

# CORRECT — CI pipeline enforced from day one
main branch ← PR required, CI must pass (lint, test, security scan)
```

### Secrets must never be committed; use .env.example for templates

```
# WRONG — .env with real credentials
DB_PASSWORD=realpassword123

# CORRECT — .env.example with placeholders; .env in .gitignore
DB_PASSWORD=<set-in-vault>
```

## Required Files by Repository Type

| File | Service | Library | Infrastructure | Purpose |
|------|---------|---------|----------------|---------|
| `README.md` | Yes | Yes | Yes | Project overview and quick start |
| `CODEOWNERS` | Yes | Yes | Yes | Review routing |
| `CONTRIBUTING.md` | Yes | Yes | Yes | Contribution guidelines |
| `CHANGELOG.md` | Yes | Yes | No | Change history |
| `LICENSE` | Yes | Yes | Yes | License declaration |
| `.gitignore` | Yes | Yes | Yes | Exclude build artifacts, secrets, IDE files |
| `.env.example` | Yes | No | Yes | Environment variable template |
| `CI pipeline config` | Yes | Yes | Yes | Build, test, security scan |
| `openapi/*.yaml` | Yes | No | No | API specification |
| `docs/adr/` | Yes | If complex | Yes | Architectural decisions |
| `docs/runbook.md` | Yes | No | Yes | Operational procedures |

## Directory Structure — Service Repository

```
<service-name>/
├── .github/
│   ├── CODEOWNERS
│   ├── workflows/
│   │   ├── ci.yaml
│   │   └── release.yaml
│   └── pull_request_template.md
├── docs/
│   ├── adr/
│   │   ├── README.md            # ADR index
│   │   └── 0001-initial-architecture.md
│   └── runbook.md
├── openapi/
│   └── service.yaml
├── src/                          # Source code (language-specific structure inside)
├── test/                         # Test code
├── infra/                        # Infrastructure-as-code (if colocated)
├── scripts/                      # Build, deploy, utility scripts
├── .env.example
├── .gitignore
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

## Directory Structure — Library Repository

```
<library-name>/
├── .github/
│   ├── CODEOWNERS
│   └── workflows/
│       └── ci.yaml
├── docs/
│   └── adr/                      # If complex architecture decisions exist
├── src/
├── test/
├── examples/                     # Usage examples
├── .gitignore
├── CHANGELOG.md
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

## Core Standards

| Standard | Requirement |
|----------|-------------|
| Branch protection | `main` protected; PRs required; CI must pass; ≥1 review |
| Default branch | `main` (not `master`) |
| Commit signing | Required for production repositories |
| PR template | Must include description, testing, and checklist sections |
| .gitignore | Must exclude: build outputs, IDE files, `.env`, OS files, dependency dirs |
| License | Proprietary for internal code; see `core/license-compliance` for dependencies |
| CI on day one | Pipeline must exist before first merge to `main` |
| Secret scanning | Enabled at repository level; blocks commits with detected secrets |

## .gitignore Essentials

| Category | Patterns |
|----------|----------|
| Secrets | `.env`, `*.pem`, `*.key`, `credentials.json`, `secrets/` |
| Build output | `build/`, `dist/`, `out/`, `target/`, `*.o`, `*.class` |
| Dependencies | `node_modules/`, `vendor/`, `.venv/`, `__pycache__/` |
| IDE | `.idea/`, `.vscode/`, `*.swp`, `*.swo`, `.DS_Store` |
| OS | `Thumbs.db`, `.DS_Store`, `desktop.ini` |
| Test artifacts | `coverage/`, `*.lcov`, `test-results/` |

## PR Template

```markdown
## Description
[What does this PR do? Link to ticket.]

## Type
- [ ] Feature
- [ ] Bug fix
- [ ] Refactor
- [ ] Documentation
- [ ] Infrastructure

## Testing
[How was this tested? Include commands or screenshots.]

## Checklist
- [ ] Tests pass locally
- [ ] Documentation updated (if applicable)
- [ ] No secrets committed
- [ ] CHANGELOG updated (if user-facing change)
```

## Workflow

1. **Determine repo type** — service, library, or infrastructure.
2. **Create directory structure** — follow the appropriate template above.
3. **Generate required files** — create all files marked "Yes" for the repo type.
4. **Configure CI** — scaffold pipeline config with lint, test, and security scan stages.
5. **Set branch protection** — configure `main` with required PR, CI checks, and review.
6. **Verify** — run the checklist below; confirm no placeholder content remains.

## Checklist

- [ ] README.md present with all required sections filled
- [ ] CODEOWNERS covers all paths
- [ ] CONTRIBUTING.md present
- [ ] LICENSE present
- [ ] .gitignore excludes secrets, build output, IDE files
- [ ] .env.example present (services/infra); no real secrets
- [ ] CI pipeline configured and passing
- [ ] Branch protection enabled on `main`
- [ ] PR template created
- [ ] Secret scanning enabled
- [ ] CHANGELOG.md initialized (services/libraries)
- [ ] docs/adr/ directory created with initial ADR (services)
- [ ] Runbook created (services)
- [ ] OpenAPI spec created (services with HTTP APIs)

For detailed file templates, read `core/documentation/reference.md`.
