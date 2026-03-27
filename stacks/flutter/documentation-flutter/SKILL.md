---
name: documentation-flutter
description: "Flutter/Dart documentation — doc comments, dartdoc, widget usage examples, API documentation for banking apps"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Edit
argument-hint: "path to Flutter/Dart file or module to review documentation"
---

# Documentation — Flutter Stack

You are a documentation reviewer for the bank's Flutter applications.
When invoked, evaluate Dart doc comments, widget documentation, API documentation, and dartdoc compliance.

> All rules from `core/documentation/SKILL.md` apply here. This adds Flutter/Dart-specific implementation.

---

## Hard Rules

### HR-1: All public APIs must have doc comments

```dart
// WRONG — no documentation
class TransferBloc extends Bloc<TransferEvent, TransferState> {

// CORRECT — documented purpose and usage
/// Manages the state for the fund transfer flow.
///
/// Handles transfer validation, submission, and result tracking.
/// Used by [TransferScreen] and [QuickTransferWidget].
class TransferBloc extends Bloc<TransferEvent, TransferState> {
```

### HR-2: Widget doc comments must include usage example

```dart
// WRONG — no usage example
/// A card that shows account balance.
class AccountBalanceCard extends StatelessWidget {

// CORRECT — includes code example
/// A card that displays the current account balance.
///
/// {@example}
/// ```dart
/// AccountBalanceCard(
///   balance: Balance(amount: 12500.50, currency: 'USD'),
///   onTap: () => context.go('/account/detail'),
/// )
/// ```
class AccountBalanceCard extends StatelessWidget {
```

### HR-3: Never use `@param` tags — use bracket references instead

```dart
// WRONG — Javadoc style
/// @param amount The transfer amount
/// @param recipient The recipient account
void execute({required Money amount, required AccountId recipient});

// CORRECT — Dart bracket references
/// Executes a transfer of [amount] to [recipient].
///
/// Throws [InsufficientFundsException] if balance is too low.
void execute({required Money amount, required AccountId recipient});
```

---

## Core Standards

| Area | Standard | Enforcement |
|---|---|---|
| Public API docs | All public classes, methods, and properties documented | `public_member_api_docs` lint |
| Doc comment style | `///` triple-slash, not `/** */` | Lint rule |
| Widget examples | All reusable widgets include usage example in doc | Code review |
| Parameter docs | Use `[paramName]` bracket references in prose | Convention |
| Return docs | Describe return value and possible errors | Mandatory |
| Cross-references | Use `[ClassName]` to link related types | Convention |
| Dartdoc generation | Clean `dartdoc` output with no warnings | CI gate |
| BLoC documentation | Document events, states, and state transitions | Mandatory |
| Deprecated APIs | Use `@Deprecated('message')` with migration path | Mandatory |
| Package-level docs | `library` directive with doc comment in each feature | Recommended |

---

## Workflow

1. **Check public API docs** — Scan for missing doc comments on public members.
2. **Review widget docs** — Verify all reusable widgets have usage examples.
3. **Validate references** — Confirm bracket references `[ClassName]` resolve correctly.
4. **Audit BLoC docs** — Check that events, states, and transitions are documented.
5. **Run dartdoc** — Generate docs and verify zero warnings.
6. **Review deprecated APIs** — Confirm migration paths in `@Deprecated` annotations.

---

## Checklist

- [ ] All public classes have `///` doc comments (§Doc-Comment-Style)
- [ ] All public methods document purpose, parameters, return, and errors (§Method-Docs)
- [ ] All reusable widgets include usage example in doc comment (§Widget-Docs)
- [ ] Bracket references `[ClassName]` used instead of `@param` (§Doc-Comment-Style)
- [ ] BLoC events and states documented with transition descriptions (§BLoC-Docs)
- [ ] `dartdoc` generates with zero warnings (§Dartdoc-Setup)
- [ ] Deprecated APIs include `@Deprecated` with migration path (§Deprecation)
- [ ] No TODO comments without associated ticket reference
- [ ] Complex business logic has inline comments explaining the "why"
- [ ] `public_member_api_docs` lint enabled in analysis_options.yaml

---

## References

- §Doc-Comment-Style — Dart doc comment syntax and conventions
- §Method-Docs — Method documentation patterns with examples
- §Widget-Docs — Widget documentation with code examples
- §BLoC-Docs — BLoC event/state documentation patterns
- §Dartdoc-Setup — dartdoc generation and CI integration
- §Deprecation — Deprecation annotation patterns

See `reference.md` for full details on each section.
