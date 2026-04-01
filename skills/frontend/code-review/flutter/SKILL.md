---
name: code-review-flutter
description: "PR conventions, conventional commits, branch strategy, and Flutter-specific review checklist for banking services"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash
argument-hint: "[scope] — e.g. 'full PR', 'commits only', 'PR #123', 'branch naming'"
---

# Flutter Code Review Skill

You are a code review standards enforcer for Flutter applications. When invoked, evaluate pull requests against commit, branch, review, and Flutter-specific conventions.

## Step 0 — Collect Context (MANDATORY)

Before any work, you MUST ask this question. Do not guess. Do not infer. Do not proceed until answered.

**Q1: Review scope**
> "What should I review: **full PR**, **commit messages only**, **branch/naming conventions**, **PR description**, or **specific files**?"

### After Answer — Load Reference

Read this file before proceeding:
- `skills/frontend/code-review/flutter/REFERENCE.md` — Full review standards, commit format, branch strategy, PR template, Flutter-specific patterns

**Do NOT proceed to Step 1 until reference is loaded.**

## Section Navigation Guide

| Need | Section heading to read |
|------|-------------------------|
| Commit message format | `## §Commit-Format` |
| Branch naming rules | `## §Branch-Strategy` |
| PR description template | `## §PR-Template` |
| Reviewer responsibilities | `## §Review-Guide` |
| Merge rules | `## §Merge-Policy` |
| Flutter-specific review | `## Flutter Review Patterns` |
| Dart analysis rules | `## Dart Analysis` |
| Widget test expectations | `## Flutter Testing` |
| Flutter anti-patterns | `## Flutter Anti-Patterns` |
| Performance review | `## Flutter Performance` |

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

### HR-4: Dart analysis must pass with zero warnings

```
# WRONG — merging with analysis warnings
dart analyze  // 3 warnings found

# CORRECT — clean analysis
dart analyze  // No issues found!
```

### HR-5: Never use GestureDetector for interactive elements

```dart
// WRONG — review must flag this
GestureDetector(onTap: _onTap, child: Text('Click me'))

// CORRECT — suggest this replacement
InkWell(onTap: _onTap, child: Text('Click me'))
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
| CI gate | All checks pass before merge | Tests, lint, dart analyze, build |
| Merge strategy | Squash merge to main | Clean linear history |
| PR description | Template with summary, test plan, checklist | Mandatory for all PRs |
| Review turnaround | First review within 4 business hours | SLA for team velocity |
| Dart analysis | Zero warnings, zero errors | `dart analyze` must be clean |
| Widget tests | Required for all new UI components | Minimum: renders, semantic labels, interaction |
| Generated code | Must be committed if using build_runner | `*.g.dart`, `*.freezed.dart` |

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
5. **Verify CI status** — All checks must pass: tests, lint, dart analyze, build.
6. **Review PR description** — Confirm summary, test plan, and checklist are complete.
7. **Flutter-specific review** — Apply Flutter patterns from REFERENCE.md:
   - Dart analysis clean
   - Widget tests for new UI components
   - No `GestureDetector` for interactive elements
   - Proper use of `const` constructors
   - State management patterns followed
   - `pubspec.lock` changes intentional
8. **Validate approvals** — Ensure required approvals met, including code owner.

---

## Checklist

- [ ] Branch name follows `type/ticket-id-short-description` convention
- [ ] All commits follow Conventional Commits format
- [ ] PR addresses a single concern (no mixed features/fixes/refactors)
- [ ] PR is within 400-line limit (or justified split plan documented)
- [ ] PR description includes summary, test plan, and checklist
- [ ] All CI checks pass (tests, lint, dart analyze, build)
- [ ] Required approvals obtained (2 for main, including code owner)
- [ ] No TODO/FIXME/HACK without linked ticket
- [ ] No commented-out code
- [ ] No hardcoded secrets or environment-specific values
- [ ] Breaking changes flagged with `!` or `BREAKING CHANGE:` footer
- [ ] Related documentation updated (API docs, ADRs if architectural change)
- [ ] `dart analyze` passes with zero warnings
- [ ] Widget tests written for new UI components
- [ ] No `GestureDetector` for interactive elements
- [ ] `const` constructors used where possible
- [ ] `pubspec.lock` changes reviewed and intentional
- [ ] Generated code (`*.g.dart`, `*.freezed.dart`) committed if applicable
