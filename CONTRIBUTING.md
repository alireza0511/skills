# Contributing to Bank Copilot Skills

Thank you for your interest in contributing to the National Bank Copilot skills repository. This document outlines the ownership model, PR workflow, authoring guidelines, and CI requirements.

## Federated Ownership Model

This repository follows a federated ownership model. Each area has a designated owning team responsible for reviews, quality, and maintenance.

| Path | Owner |
|---|---|
| `/` (root), `core/`, `agents/`, `scripts/`, `.github/` | **Platform Engineering** (`@bank/platform-engineering`) |
| `stacks/flutter/` | **Mobile Team** (`@bank/mobile-team`) |
| `stacks/java/` | **Backend Team** (`@bank/backend-team`) |
| `stacks/react/` | **Frontend Team** (`@bank/frontend-team`) |

Ownership is enforced via the `CODEOWNERS` file at the repository root.

## PR Workflow

1. **Create a feature branch** from `main` with a descriptive name (e.g., `feat/core-security-sql-injection-rule`).
2. **Open a Pull Request** targeting `main`.
3. **Required reviewers** are automatically assigned via CODEOWNERS:
   - **Platform Engineering** is required on every PR (they own root).
   - The **domain owner** for the affected path is also required (e.g., `@bank/mobile-team` for changes under `stacks/flutter/`).
4. **CI must pass** -- all checks described below must be green before merge.
5. **Merge** using squash-merge to keep the history clean.

## SKILL.md Authoring Guidelines

Every skill directory must contain a `SKILL.md` file with valid YAML frontmatter. For comprehensive authoring instructions, templates, and examples, refer to the **`core/skill-development/`** meta-skill.

### Frontmatter Requirements

Every `SKILL.md` must include the following frontmatter fields:

```yaml
---
name: <skill-name>
description: <one-line description>
allowed-tools: <list of tools the skill may invoke>
---
```

Additional optional fields (version, tags, dependencies) are documented in `core/skill-development/`.

### Line Budget

Keep skills concise. The following thresholds apply to `SKILL.md` files:

| Lines | Status |
|---|---|
| < 150 | Ideal |
| 150 -- 300 | Acceptable |
| 300 -- 500 | Needs written justification in the PR description |
| > 500 | Must be split into sub-skills |

CI will warn on files exceeding 300 lines and block on files exceeding 500 lines without an approved exception.

### reference.md

Every skill **must** include a `reference.md` file alongside its `SKILL.md`. This file contains the detailed reference material that the skill draws upon.

- Use **section notation** (`\u00a7`) to organize content (e.g., `\u00a7 SQL Injection Prevention`, `\u00a7 Input Validation`).
- Keep reference material factual, linkable, and version-stamped where applicable.

## CI Checks

The following checks must pass on every PR:

1. **Frontmatter validation** -- `SKILL.md` files must have `name`, `description`, and `allowed-tools` in their YAML frontmatter.
2. **reference.md presence** -- every skill directory containing a `SKILL.md` must also contain a `reference.md`.
3. **Line budget enforcement** -- `SKILL.md` files exceeding 500 lines cause a failure; files exceeding 300 lines cause a warning.
4. **JSON lint** -- `manifest.json` must be valid JSON.
5. **Shell lint** -- `install.sh` must pass `shellcheck`.
6. **CODEOWNERS validity** -- the `CODEOWNERS` file must reference valid teams.
