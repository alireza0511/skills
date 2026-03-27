---
name: error-handling-flutter
description: "Flutter/Dart error handling — Result type, FlutterError.onError, zone handling, error boundaries, Crashlytics for banking apps"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Edit
argument-hint: "path to Flutter module or error handling code to review"
---

# Error Handling — Flutter Stack

You are an error handling reviewer for the bank's Flutter applications.
When invoked, evaluate Flutter/Dart error classification, user-facing error UI, crash reporting, and resilience patterns.

> All rules from `core/error-handling/SKILL.md` apply here. This adds Flutter-specific implementation.

---

## Hard Rules

### HR-1: Never show raw exceptions to users

```dart
// WRONG
catch (e) { showDialog(child: Text(e.toString())); }

// CORRECT
catch (e) { showDialog(child: Text(context.l10n.transferFailed)); }
```

### HR-2: Never use bare catch-all without classification

```dart
// WRONG
try { await transfer(); } catch (e) { print(e); }

// CORRECT
try { await transfer(); }
on InsufficientFundsException catch (e) { emit(state.insufficientFunds(e)); }
on NetworkException catch (e) { emit(state.networkError(e)); }
on Exception catch (e, stack) { _crashlytics.recordError(e, stack); }
```

### HR-3: Always use Result type for domain operations

```dart
// WRONG — throwing from repository
Future<Transfer> execute(cmd) async => throw TransferFailedException();

// CORRECT — return Result
Future<Result<Transfer>> execute(cmd) async => Result.failure(TransferError.insufficientFunds);
```

---

## Core Standards

| Area | Standard | Severity |
|---|---|---|
| Result type | All repository/use case returns use `Result<T>` | Mandatory |
| FlutterError.onError | Configured to send to Crashlytics | Critical |
| Zone error handling | `runZonedGuarded` wraps `runApp` | Critical |
| Error boundaries | `ErrorWidget.builder` customized for release | High |
| User error UI | Friendly messages, retry actions, support contact | Mandatory |
| Crashlytics | All unhandled errors forwarded with stack traces | Critical |
| Error classification | Typed exceptions per domain area | Mandatory |
| Trace ID | Every error response includes trace ID for support | High |
| Graceful degradation | Non-critical failures do not crash the app | High |
| Retry UI | Transient errors show retry button | High |

---

## Workflow

1. **Check Result usage** — Verify all repository and use case methods return `Result<T>`, not raw throws.
2. **Audit catch blocks** — Confirm specific exception types are caught and classified.
3. **Verify global handlers** — Check `FlutterError.onError`, `runZonedGuarded`, and `ErrorWidget.builder`.
4. **Review user error UI** — Confirm friendly messages with retry actions and support contacts.
5. **Validate Crashlytics** — Verify unhandled errors are forwarded with stack traces and user context.
6. **Test degradation** — Confirm non-critical feature failures do not crash the app.

---

## Checklist

- [ ] All repository/use case methods return `Result<T>` (§Result-Type)
- [ ] `FlutterError.onError` configured for Crashlytics (§Global-Handlers)
- [ ] `runZonedGuarded` wraps `runApp` (§Global-Handlers)
- [ ] `ErrorWidget.builder` customized for release builds (§Error-Boundary)
- [ ] User-facing error messages are friendly and actionable (§Error-UI)
- [ ] Specific exception types caught — no bare `catch (e)` (§Exception-Types)
- [ ] Crashlytics receives all unhandled errors with stack traces (§Crashlytics)
- [ ] Trace IDs included in error UI for support correlation
- [ ] Retry buttons on transient error states
- [ ] Non-critical feature failures do not crash the app
- [ ] No `print()` for error logging — use structured logger
- [ ] Loading and error states handled in every BLoC

---

## References

- §Result-Type — Result sealed class implementation and usage patterns
- §Global-Handlers — FlutterError.onError, runZonedGuarded, ErrorWidget.builder
- §Error-Boundary — Error boundary widget patterns
- §Error-UI — User-facing error screen and snackbar patterns
- §Exception-Types — Typed exception hierarchy for banking
- §Crashlytics — Firebase Crashlytics integration and configuration

See `reference.md` for full details on each section.
