---
name: testing-flutter
description: "Flutter/Dart testing — widget tests, golden tests, mocktail, integration tests, coverage, accessibility testing"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Edit
  - Bash
argument-hint: "path to Flutter test file or module to review"
---

# Testing — Flutter Stack

You are a test quality reviewer for the bank's Flutter applications.
When invoked, evaluate Flutter/Dart test coverage, structure, widget testing patterns, and accessibility testing compliance.

> All rules from `core/testing/SKILL.md` apply here. This adds Flutter-specific implementation.

---

## Hard Rules

### HR-1: Widget tests must use pumpWidget with complete dependency tree

```dart
// WRONG — missing MaterialApp, missing dependencies
await tester.pumpWidget(TransferScreen());

// CORRECT — full widget tree with required ancestors
await tester.pumpWidget(
  MaterialApp(home: ProviderScope(child: TransferScreen())),
);
```

### HR-2: Never use real HTTP in widget or unit tests

```dart
// WRONG — real network call in test
final result = await ApiClient().getBalance('acc-123');

// CORRECT — mock the dependency
final mockClient = MockApiClient();
when(() => mockClient.getBalance(any())).thenAnswer((_) async => Balance(1000));
```

### HR-3: Golden tests must have deterministic rendering

```dart
// WRONG — depends on system locale/time
await tester.pumpWidget(AccountCard(date: DateTime.now()));

// CORRECT — fixed test data
await tester.pumpWidget(AccountCard(date: DateTime(2024, 1, 15)));
```

---

## Core Standards

| Area | Standard | Threshold |
|---|---|---|
| Widget test coverage | All screens and reusable widgets tested | 100% of widgets |
| Unit test coverage | Line coverage minimum | 80% |
| Golden tests | All critical UI states captured | All bank-branded screens |
| Integration tests | Critical user journeys | All P0 flows |
| Accessibility tests | `meetsGuideline` checks on all screens | Mandatory |
| Mock framework | `mocktail` (no codegen, null-safe) | Standardized |
| Test naming | `group('Widget')` + descriptive test names | Mandatory |
| Test isolation | No shared mutable state; `setUp`/`tearDown` | Mandatory |
| Flaky tests | Zero tolerance on main branch | Quarantine within 24h |
| CI execution | All widget tests < 5 min; golden tests < 10 min | Mandatory |

---

## Flutter Test Pyramid

| Layer | Tool | Scope | Speed |
|---|---|---|---|
| Unit | `flutter_test` | Dart logic, BLoCs, repositories | < 10ms each |
| Widget | `testWidgets` + `pumpWidget` | Single widget behavior | < 100ms each |
| Golden | `golden_toolkit` | Visual regression of screens | < 500ms each |
| Integration | `integration_test` | Full app user journeys | < 60s each |
| Accessibility | `meetsGuideline` | Semantics tree validation | Per widget test |

---

## Workflow

1. **Check coverage** — Run `flutter test --coverage` and verify >= 80% line coverage.
2. **Review widget tests** — Confirm all screens have `testWidgets` with full dependency tree.
3. **Audit golden tests** — Verify golden files exist for all critical UI states and branded screens.
4. **Validate mocks** — Confirm `mocktail` is used; no real I/O in unit/widget tests.
5. **Check accessibility** — Verify `meetsGuideline` assertions on all screen tests.
6. **Review integration tests** — Confirm P0 flows (login, transfer, statement) have integration tests.
7. **Assess naming** — Validate descriptive test names within `group()` blocks.

---

## Checklist

- [ ] Line coverage >= 80% via `flutter test --coverage` (§Coverage-Setup)
- [ ] All screens have widget tests with `testWidgets` (§Widget-Tests)
- [ ] Golden files exist for all critical UI states (§Golden-Tests)
- [ ] All mocks use `mocktail` — no manual mocks or `mockito` codegen (§Mock-Patterns)
- [ ] `meetsGuideline(androidTapTargetGuideline)` in all screen tests (§A11y-Tests)
- [ ] `meetsGuideline(textContrastGuideline)` in all screen tests (§A11y-Tests)
- [ ] Integration tests cover login, transfer, and account flows (§Integration-Tests)
- [ ] No real HTTP/IO in unit or widget tests
- [ ] Test names are descriptive: `'shows error when transfer amount exceeds balance'`
- [ ] Golden test images committed and reviewed in PR
- [ ] No `skip:` annotations on main branch tests
- [ ] `setUp`/`tearDown` used for test isolation

---

## References

- §Widget-Tests — Widget test patterns with pumpWidget, finder, and matcher examples
- §Golden-Tests — Golden test setup with `golden_toolkit` and CI configuration
- §Mock-Patterns — `mocktail` setup and common mock patterns for banking
- §Integration-Tests — Integration test setup and critical flow examples
- §A11y-Tests — Accessibility guideline assertions and semantic testing
- §Coverage-Setup — Coverage collection, reporting, and threshold enforcement

See `reference.md` for full details on each section.
