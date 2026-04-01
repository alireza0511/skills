# Code Review — Flutter Reference

Flutter-specific code review patterns for mobile applications. See `skills/frontend/code-review/flutter/SKILL.md` for core rules.

## Flutter Review Patterns

### Core Principle

**Review Flutter PRs for correctness, Dart idioms, widget structure, and accessibility.** Flutter's widget tree model and Dart's type system catch many issues at compile time — focus reviews on architecture, state management, and runtime behavior.

### What to Look For

| Area | Check |
|---|---|
| Widget structure | Is the widget tree appropriately decomposed? Are widgets too deeply nested? |
| State management | Is state lifted appropriately? No business logic in widgets? |
| Const constructors | Are `const` constructors used where possible to enable tree shaking? |
| Build method | Is `build()` free of heavy computation? No side effects? |
| Dispose | Are controllers, streams, and subscriptions disposed? |
| Keys | Are `Key`s used correctly in lists and animated widgets? |
| Platform channels | Are platform channel calls wrapped in try-catch? |
| Navigation | Is navigation handled through the router, not ad-hoc pushes? |

## Dart Analysis

### Required Configuration

```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - always_use_package_imports
    - avoid_print
    - avoid_relative_lib_imports
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_locals
    - sort_constructors_first
    - unawaited_futures
```

### Review Checks

| Check | Flag If |
|---|---|
| `dart analyze` | Any warnings or errors |
| `dart format` | Any unformatted files |
| `avoid_print` | Any `print()` calls in production code |
| `prefer_const_constructors` | Missing `const` on immutable widgets |
| Import style | Relative imports instead of package imports |

## Flutter Anti-Patterns

Flag these during review:

### setState in async gaps

```dart
// WRONG — widget may be unmounted after await
Future<void> _loadData() async {
  final data = await fetchData();
  setState(() => _data = data);  // unsafe
}

// CORRECT — check mounted
Future<void> _loadData() async {
  final data = await fetchData();
  if (mounted) setState(() => _data = data);
}
```

### Business logic in widgets

```dart
// WRONG — business logic mixed into widget
class TransferScreen extends StatefulWidget {
  void _transfer() {
    if (amount > balance) throw InsufficientFundsException();
    // ... validation, API call, state update all in widget
  }
}

// CORRECT — logic in a separate service/bloc/provider
class TransferBloc {
  Future<void> transfer(TransferRequest request) { ... }
}
```

### Deeply nested widget trees

```dart
// WRONG — deeply nested, hard to read
Widget build(BuildContext context) {
  return Scaffold(
    body: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(...),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    // ... 10 more levels
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// CORRECT — extract sub-widgets
Widget build(BuildContext context) {
  return Scaffold(body: Padding(padding: EdgeInsets.all(16), child: _TransferForm()));
}
```

### Missing error handling on Future

```dart
// WRONG — unhandled future error
void initState() {
  super.initState();
  _loadAccounts();  // fire-and-forget, errors silently swallowed
}

// CORRECT — handle errors
void initState() {
  super.initState();
  _loadAccounts().catchError((e) => _handleError(e));
}
```

## Flutter Testing

### Test Expectations for PRs

| Change Type | Required Tests |
|---|---|
| New widget | Widget test: renders correctly, semantic labels, user interaction |
| New screen | Widget test + integration test for navigation |
| State management | Unit test for bloc/provider/notifier logic |
| API integration | Unit test with mocked HTTP client |
| Bug fix | Regression test that fails without the fix |
| Refactor | Existing tests must still pass (no new tests needed unless coverage gap) |

### Widget Test Pattern

```dart
testWidgets('transfer button submits form', (tester) async {
  await tester.pumpWidget(MaterialApp(home: TransferScreen()));

  await tester.enterText(find.byKey(Key('amount_field')), '50.00');
  await tester.tap(find.byKey(Key('submit_button')));
  await tester.pump();

  expect(find.text('Transfer submitted'), findsOneWidget);
});
```

### Golden Test Pattern

```dart
testWidgets('account card matches golden', (tester) async {
  await tester.pumpWidget(MaterialApp(home: AccountCard(account: mockAccount)));
  await expectLater(
    find.byType(AccountCard),
    matchesGoldenFile('goldens/account_card.png'),
  );
});
```

## Flutter Performance

### Review Checklist

| Check | Flag If |
|---|---|
| `build()` complexity | Heavy computation or I/O in build method |
| ListView | Large lists not using `ListView.builder` |
| Images | Large images not cached or resized |
| Animations | Animations not using `const` curves; not respecting reduce motion |
| Rebuilds | Unnecessary rebuilds (missing `const`, overly broad state listeners) |
| Memory | Streams/controllers not disposed in `dispose()` |

### Common Performance Issues

```dart
// WRONG — rebuilds entire list
ListView(children: items.map((i) => ItemWidget(i)).toList())

// CORRECT — lazy building
ListView.builder(itemCount: items.length, itemBuilder: (_, i) => ItemWidget(items[i]))
```

## Flutter Security

### Review Checklist

| Check | Flag If |
|---|---|
| API keys | Hardcoded keys or secrets in Dart code |
| Storage | Sensitive data stored in SharedPreferences instead of flutter_secure_storage |
| Network | HTTP used instead of HTTPS |
| Logging | PII or sensitive data logged in production |
| Obfuscation | Release build not using `--obfuscate` flag |
| Certificate pinning | Missing for banking API endpoints |

---

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
- [ ] Widget tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing on Android
- [ ] Manual testing on iOS
- [ ] Describe test scenarios:

## Flutter-Specific

- [ ] `dart analyze` passes with zero warnings
- [ ] `dart format` applied
- [ ] `const` constructors used where possible
- [ ] No `GestureDetector` for interactive elements
- [ ] `pubspec.lock` changes intentional

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
| Performance | Unnecessary rebuilds, heavy build methods, missing lazy loading? |
| Maintainability | Is the code readable, well-structured, appropriately documented? |
| Test coverage | Are new behaviors tested? Are edge cases covered? |
| Conventions | Does it follow Effective Dart and team conventions? |
| Accessibility | Semantic labels, touch targets, keyboard navigation? |

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
| CI pipeline | Yes | All jobs green (tests, dart analyze, build) |
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
