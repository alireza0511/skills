---
name: architecture-flutter
description: "Flutter/Dart architecture — BLoC pattern, clean architecture, go_router, feature-first structure, dependency injection for banking apps"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Edit
argument-hint: "path to Flutter feature or module to review"
---

# Architecture — Flutter Stack

You are a software architect reviewer for the bank's Flutter applications.
When invoked, evaluate Flutter/Dart code structure against clean architecture, BLoC pattern, and dependency inversion principles.

> All rules from `core/architecture/SKILL.md` apply here. This adds Flutter-specific implementation.

---

## Hard Rules

### HR-1: Widgets must never contain business logic

```dart
// WRONG — calculation in widget
Text('Fee: \$${amount * 0.015}')

// CORRECT — delegate to BLoC/domain
BlocBuilder<TransferBloc, TransferState>(
  builder: (context, state) => Text('Fee: ${state.formattedFee}'),
)
```

### HR-2: BLoCs must not depend on Flutter framework

```dart
// WRONG — BLoC imports Flutter
import 'package:flutter/material.dart';
class TransferBloc extends Bloc<TransferEvent, TransferState> { ... }

// CORRECT — BLoC depends only on domain and bloc package
import 'package:bloc/bloc.dart';
class TransferBloc extends Bloc<TransferEvent, TransferState> { ... }
```

### HR-3: Repository implementations must not leak into domain

```dart
// WRONG — domain depends on Dio
class TransferUseCase {
  final Dio _dio; // infrastructure type in domain

// CORRECT — domain depends on abstract repository
class TransferUseCase {
  final TransferRepository _repository; // domain interface
```

---

## Core Standards

| Area | Standard | Enforcement |
|---|---|---|
| State management | BLoC/Cubit via `flutter_bloc` | Mandatory |
| Architecture | Clean architecture: presentation / domain / data | Build rule |
| Routing | `go_router` with type-safe routes | Mandatory |
| Folder structure | Feature-first with shared core | Convention |
| Dependency injection | `get_it` with interface registration | Mandatory |
| Domain purity | Zero Flutter/infrastructure imports in domain | Code review |
| Value objects | Money, IBAN, AccountId — always typed | Mandatory |
| One BLoC per feature | Each feature has exactly one BLoC/Cubit | Recommended |
| Immutable state | BLoC states use `freezed` or `equatable` | Mandatory |
| Event-driven | BLoC uses events (not methods) for state changes | Mandatory |

---

## Layer Model

```
┌─────────────────────────────────────┐
│  Presentation (Widgets, Pages)      │  Flutter widgets, BLoC consumers
├─────────────────────────────────────┤
│  Application (BLoCs, Cubits)        │  State management, orchestration
├─────────────────────────────────────┤
│  Domain (Entities, Use Cases)       │  Pure Dart — no Flutter imports
├─────────────────────────────────────┤
│  Data (Repositories, Data Sources)  │  Dio, Drift, platform channels
└─────────────────────────────────────┘
       ↑ dependencies point UP (inward) ↑
```

---

## Workflow

1. **Map layers** — Identify which layer each changed file belongs to.
2. **Check BLoC boundaries** — Verify one BLoC per feature, events for input, immutable states.
3. **Validate domain purity** — Confirm domain layer has zero Flutter/infrastructure imports.
4. **Review DI registration** — Verify `get_it` registers interfaces, not implementations.
5. **Check routing** — Confirm `go_router` routes are type-safe and guarded.
6. **Assess folder structure** — Verify feature-first organization with proper layer separation.

---

## Checklist

- [ ] Business logic in BLoCs/domain, never in widgets (§BLoC-Pattern)
- [ ] BLoCs use events and immutable states with `equatable`/`freezed` (§BLoC-Pattern)
- [ ] Domain layer has zero Flutter or infrastructure imports (§Clean-Layers)
- [ ] Repositories define interfaces in domain, implementations in data (§Clean-Layers)
- [ ] `go_router` with type-safe routes and auth guards (§Router-Setup)
- [ ] Feature-first folder structure followed (§Folder-Structure)
- [ ] `get_it` registers abstractions, not concrete classes (§DI-Setup)
- [ ] Value objects used for Money, IBAN, AccountId (§Value-Objects)
- [ ] No circular dependencies between features
- [ ] Widgets are thin — only layout and BLoC consumption

---

## References

- §BLoC-Pattern — BLoC setup, event/state design, and testing patterns
- §Clean-Layers — Layer boundaries and allowed imports per layer
- §Router-Setup — go_router configuration with type-safe routes and guards
- §Folder-Structure — Feature-first directory organization
- §DI-Setup — get_it registration and scoping patterns
- §Value-Objects — Financial value object implementations in Dart

See `reference.md` for full details on each section.
