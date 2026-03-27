# Code Review — Reference

## §Commit-Format

### Conventional Commits Specification

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

### Rules

| Rule | Detail |
|---|---|
| Type | Required. One of: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `revert` |
| Scope | Optional but recommended. Module or component name in kebab-case |
| Description | Required. Imperative mood, lowercase, no period at end, max 72 chars |
| Body | Optional. Explain *why*, not *what*. Wrap at 72 chars |
| Footer | Optional. `BREAKING CHANGE:`, `Closes #123`, `Co-authored-by:` |

### Good Commit Examples

```
feat(transfers): add scheduled transfer support

Allow customers to schedule one-time and recurring transfers
with a future execution date. Transfers are validated at
creation and re-validated at execution time.

Closes PAY-456

---

fix(accounts): correct interest calculation for leap years

The daily interest calculation used 365 days for all years,
causing a small discrepancy in leap years. Now checks for
leap year and uses 366 when applicable.

Fixes PAY-789

---

chore(deps): update payment-sdk from 3.1.0 to 3.2.1

Addresses CVE-2025-1234 (high severity) in XML parsing.
No breaking changes in this minor version update.

---

refactor(auth): extract token validation to dedicated service

Moves JWT validation logic from middleware into a standalone
TokenValidationService to improve testability and reuse.
No behavior change.
```

### Bad Commit Examples

| Message | Problem |
|---|---|
| `fixed bug` | No type, no scope, vague description |
| `WIP` | Not a meaningful commit; squash before PR |
| `feat: Updated the thing` | Past tense; too vague; capitalized |
| `misc changes` | No type; no information |
| `fix(transfers): fix the transfer bug that was causing issues` | Redundant "fix"; describe what was fixed |

---

## §Branch-Strategy

### Branch Naming Convention

```
<type>/<ticket-id>-<short-description>
```

| Component | Rule | Example |
|---|---|---|
| Type | Matches commit type: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `perf` | `feat` |
| Ticket ID | JIRA/issue tracker ID, uppercase | `PAY-123` |
| Description | Kebab-case, 2-4 words | `iban-validation` |

### Examples

| Branch Name | Purpose |
|---|---|
| `feat/PAY-123-iban-validation` | New IBAN validation feature |
| `fix/PAY-456-negative-transfer` | Fix negative transfer amount bug |
| `chore/PAY-789-update-sdk` | Dependency update |
| `refactor/PAY-101-extract-auth` | Auth refactoring |
| `docs/PAY-202-api-migration` | API migration documentation |

### Branch Lifecycle

| Phase | Action |
|---|---|
| Create | Branch from `main` (or `develop` if using Gitflow) |
| Develop | Commit often, push regularly |
| PR | Open PR when ready; request review |
| Merge | Squash merge to target branch |
| Delete | Delete branch after merge (automated) |

### Protected Branches

| Branch | Protection Rules |
|---|---|
| `main` | 2 approvals, CI pass, no force push, no direct commits, code owner review |
| `release/*` | 1 approval, CI pass, no force push |
| `develop` (if used) | 1 approval, CI pass |

---

## §PR-Template

### Pull Request Description Template

```markdown
## Summary

<!-- 1-3 sentences: what does this PR do and why? -->

## Changes

<!-- Bulleted list of key changes -->
-
-
-

## Test Plan

<!-- How did you verify this change? -->
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing performed
- [ ] Describe test scenarios:

## Checklist

- [ ] Code follows project conventions
- [ ] Tests pass locally and in CI
- [ ] No new warnings or lint errors
- [ ] Documentation updated (if applicable)
- [ ] Security considerations reviewed
- [ ] Breaking changes flagged and communicated

## Related

<!-- Links to tickets, related PRs, documentation -->
- Ticket: [PAY-XXX](link)
- Related PR: #NNN
```

---

## §Review-Guide

### Reviewer Responsibilities

| Responsibility | Detail |
|---|---|
| Correctness | Does the code do what the PR claims? |
| Security | Any new attack vectors, PII exposure, auth gaps? |
| Performance | Any N+1 queries, missing indexes, unbounded collections? |
| Maintainability | Is the code readable, well-structured, appropriately documented? |
| Test coverage | Are new behaviors tested? Are edge cases covered? |
| Conventions | Does it follow project and team conventions? |

### Feedback Guidelines

| Do | Do Not |
|---|---|
| Comment on the code, not the person | "You always do this wrong" |
| Explain *why* something should change | "Change this" (without reason) |
| Suggest alternatives with examples | Just say "this is bad" |
| Distinguish blocking vs. non-blocking | Leave all comments as blocking |
| Acknowledge good work | Only point out negatives |

### Comment Prefixes

Use prefixes to clarify intent:

| Prefix | Meaning | Blocks Merge? |
|---|---|---|
| `blocking:` | Must be addressed before merge | Yes |
| `suggestion:` | Improvement idea, author decides | No |
| `question:` | Seeking understanding, not necessarily a change | No |
| `nit:` | Trivial style/preference issue | No |
| `praise:` | Something done well | No |

### Review Turnaround SLA

| Priority | First Review | Follow-Up |
|---|---|---|
| Critical (hotfix) | 2 hours | Same day |
| Normal | 4 business hours | 1 business day |
| Low (docs, chore) | 1 business day | 2 business days |

---

## §Merge-Policy

### Merge Strategies

| Strategy | Use When | Branch Target |
|---|---|---|
| Squash merge | Feature/fix branches to main | main |
| Merge commit | Release branches (preserve history) | main (from release) |
| Rebase | Updating feature branch from main | feature branch |
| Fast-forward | Never (always create merge record) | — |

### Squash Merge Rules

| Rule | Detail |
|---|---|
| Final message | Use PR title as squash commit message (must follow Conventional Commits) |
| Body | Include PR number: `feat(transfers): add scheduled transfers (#123)` |
| Co-authors | Preserve co-author trailers from individual commits |
| Branch cleanup | Auto-delete source branch after merge |

### Pre-Merge Checklist (Automated)

| Check | Required | Detail |
|---|---|---|
| CI pipeline | Yes | All jobs green |
| Approvals | Yes | 2 for main, 1 for feature |
| Conversations resolved | Yes | All blocking comments addressed |
| Branch up to date | Yes | Rebased on latest target branch |
| No merge conflicts | Yes | Clean merge possible |
| Security scan | Yes | No new critical/high findings |

### Hotfix Process

| Step | Action |
|---|---|
| 1 | Branch from `main`: `fix/PAY-XXX-critical-description` |
| 2 | Implement fix with tests |
| 3 | Open PR with `[HOTFIX]` prefix in title |
| 4 | Minimum 1 approval (expedited review) |
| 5 | Squash merge to `main` |
| 6 | Tag release immediately |
| 7 | Post-incident: full review within 48 hours |
