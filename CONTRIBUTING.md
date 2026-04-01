# Contributing to Copilot Skills

Thank you for your interest in contributing to the Copilot skills repository. This document outlines the ownership model, PR workflow, authoring guidelines, and CI requirements.

## Federated Ownership Model

This repository follows a federated ownership model. Each area has a designated owning team responsible for reviews, quality, and maintenance.

| Path | Owner |
|---|---|
| `/` (root), `skills/`, `agents/`, `scripts/`, `.github/` | **Platform Engineering** (`@org/platform-engineering`) |
| `skills/frontend/` | **Frontend Team** (`@org/frontend-team`) |

Ownership is enforced via the `CODEOWNERS` file at the repository root.

## PR Workflow

1. **Create a feature branch** from `main` with a descriptive name (e.g., `feat/frontend-accessibility-color-contrast`).
2. **Open a Pull Request** targeting `main`.
3. **Required reviewers** are automatically assigned via CODEOWNERS:
   - **Platform Engineering** is required on every PR (they own root).
   - The **domain owner** for the affected path is also required (e.g., `@org/frontend-team` for changes under `skills/frontend/`).
4. **CI must pass** -- all checks described below must be green before merge.
5. **Merge** using squash-merge to keep the history clean.

## Skill Authoring Guidelines

Skills follow a platform-specific structure. Multi-platform core skills have a `CONTRACT.md` at the skill root, with platform subdirectories each containing a `SKILL.md` and `REFERENCE.md`.

```
skills/<category>/<name>/
├── CONTRACT.md
├── flutter/
│   ├── SKILL.md
│   └── REFERENCE.md
└── react/
    ├── SKILL.md
    └── REFERENCE.md
```

For comprehensive authoring instructions, templates, and examples, refer to the **`skills/skill-development/`** meta-skill.

### Frontmatter Requirements

Every `SKILL.md` must include the following frontmatter fields:

```yaml
---
name: <skill-name>
description: <one-line description>
allowed-tools: <list of tools the skill may invoke>
---
```

Additional optional fields (version, tags, dependencies) are documented in `skills/skill-development/`.

### Line Budget

Keep skills concise. The following thresholds apply to `SKILL.md` files:

| Lines | Status |
|---|---|
| < 150 | Ideal |
| 150 -- 300 | Acceptable |
| 300 -- 500 | Needs written justification in the PR description |
| > 500 | Must be split into sub-skills |

CI will warn on files exceeding 300 lines and block on files exceeding 500 lines without an approved exception.

### REFERENCE.md

Every `SKILL.md` **must** have a sibling `REFERENCE.md` in the same directory. This file contains detailed reference material that the skill draws upon. Core reference content (shared standards, checklists) is merged into each platform's `REFERENCE.md` — there is no shared reference file at the skill root.

- Use **section notation** (`§`) to organize content (e.g., `§ SQL Injection Prevention`, `§ Input Validation`).
- Keep reference material factual, linkable, and version-stamped where applicable.

## CI Checks

The following checks must pass on every PR:

1. **Frontmatter validation** -- `SKILL.md` files must have `name`, `description`, and `allowed-tools` in their YAML frontmatter.
2. **REFERENCE.md presence** -- every directory containing a `SKILL.md` must also contain a `REFERENCE.md`.
3. **CONTRACT.md presence** -- every multi-platform skill must have a `CONTRACT.md` at the skill root.
4. **Line budget enforcement** -- `SKILL.md` files exceeding 500 lines cause a failure; files exceeding 300 lines cause a warning.
5. **JSON lint** -- `manifest.json` must be valid JSON.
6. **Shell lint** -- `install.sh` must pass `shellcheck`.
7. **CODEOWNERS validity** -- the `CODEOWNERS` file must reference valid teams.
