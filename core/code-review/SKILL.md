---
name: code-review
description: "PR conventions, conventional commits, branch strategy, review checklist for banking services"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
---

# Code Review Skill

You are a code review standards enforcer for bank services.
When invoked, evaluate pull requests against commit, branch, and review conventions.

---

## Hard Rules

### HR-1: Commit messages must follow Conventional Commits

```
# WRONG
Fixed stuff
update
wip

# CORRECT
fix(transfers): prevent negative amount in fund transfer
feat(accounts): add IBAN validation for EU accounts
```

### HR-2: PRs must be scoped to a single concern

```
# WRONG — PR title
"Fix transfer bug, add new account page, and update dependencies"

# CORRECT — three separate PRs
"fix(transfers): reject transfers to frozen accounts"
"feat(accounts): add account overview page"
"chore(deps): update payment-sdk to 3.2.1"
```

### HR-3: Never merge without required approvals

```
# WRONG
merge directly to main without review  // even "small fixes"

# CORRECT
open PR -> pass CI -> get required approvals -> merge
```

---

## Core Standards

| Area | Standard | Detail |
|---|---|---|
| Commit format | Conventional Commits 1.0.0 | `type(scope): description` |
| PR size | Max 400 lines changed (excluding generated code) | Smaller = faster review, fewer bugs |
| PR scope | Single concern per PR | One feature, one bug fix, or one refactor |
| Branch naming | `type/ticket-id-short-description` | `feat/PAY-123-iban-validation` |
| Required approvals | 2 for main; 1 for feature branches | At least 1 from code owner |
| CI gate | All checks pass before merge | Tests, lint, security scan, build |
| Merge strategy | Squash merge to main | Clean linear history |
| PR description | Template with summary, test plan, checklist | Mandatory for all PRs |
| Review turnaround | First review within 4 business hours | SLA for team velocity |
| Draft PRs | Use draft status for WIP | Do not request review on drafts |

---

## Conventional Commits

| Type | Purpose | Triggers |
|---|---|---|
| `feat` | New feature | Minor version bump |
| `fix` | Bug fix | Patch version bump |
| `docs` | Documentation only | No version bump |
| `style` | Formatting, no logic change | No version bump |
| `refactor` | Code restructuring, no behavior change | No version bump |
| `perf` | Performance improvement | Patch version bump |
| `test` | Adding or fixing tests | No version bump |
| `chore` | Build, CI, dependency updates | No version bump |
| `revert` | Revert a previous commit | Depends on original |

### Breaking Changes

Append `!` after type or add `BREAKING CHANGE:` footer:

```
feat(api)!: change transfer response schema

BREAKING CHANGE: removed `legacy_status` field from transfer response.
Consumers must use `status` field instead.
```

---

## Workflow

1. **Check branch name** — Verify format: `type/ticket-id-short-description`.
2. **Review commits** — Confirm all commits follow Conventional Commits; squash fixups.
3. **Assess PR scope** — Verify single concern; flag if PR mixes features, fixes, and refactors.
4. **Check PR size** — Flag if > 400 lines changed (suggest split).
5. **Verify CI status** — All checks must pass: tests, lint, security scan, build.
6. **Review PR description** — Confirm summary, test plan, and checklist are complete.
7. **Validate approvals** — Ensure required approvals met, including code owner.

---

## Checklist

- [ ] Branch name follows `type/ticket-id-short-description` convention
- [ ] All commits follow Conventional Commits format
- [ ] PR addresses a single concern (no mixed features/fixes/refactors)
- [ ] PR is within 400-line limit (or justified split plan documented)
- [ ] PR description includes summary, test plan, and checklist
- [ ] All CI checks pass (tests, lint, security scan, build)
- [ ] Required approvals obtained (2 for main, including code owner)
- [ ] No TODO/FIXME/HACK without linked ticket
- [ ] No commented-out code
- [ ] No hardcoded secrets or environment-specific values
- [ ] Breaking changes flagged with `!` or `BREAKING CHANGE:` footer
- [ ] Related documentation updated (API docs, ADRs if architectural change)

---

## References

- §Commit-Format — Full Conventional Commits specification with examples
- §Branch-Strategy — Branch naming and Git flow details
- §PR-Template — Pull request description template
- §Review-Guide — Reviewer checklist and feedback guidelines
- §Merge-Policy — Merge strategies and protected branch rules

See `reference.md` for full details on each section.
