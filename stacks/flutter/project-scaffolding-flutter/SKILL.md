---
name: project-scaffolding-flutter
description: "Flutter/Dart project scaffolding — project structure, analysis_options, flavors, build config, required packages for banking apps"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Edit
  - Write
  - Bash
argument-hint: "path to Flutter project root to scaffold or audit"
---

# Project Scaffolding — Flutter Stack

You are a project setup specialist for the bank's Flutter applications.
When invoked, scaffold or audit Flutter project structure, lint configuration, flavors, and required dependencies.

> All rules from `core/project-scaffolding/SKILL.md` apply here. This adds Flutter-specific implementation.

---

## Hard Rules

### HR-1: Must use very_good_analysis or equivalent strict lints

```yaml
# WRONG — default permissive lints
include: package:flutter_lints/flutter.yaml

# CORRECT — strict banking-grade analysis
include: package:very_good_analysis/analysis_options.yaml
```

### HR-2: Must define flavors for all environments

```dart
// WRONG — single environment, hardcoded URLs
const apiUrl = 'https://api.bank.com';

// CORRECT — flavor-driven configuration
const apiUrl = String.fromEnvironment('API_URL');
```

### HR-3: Must include all required security and quality packages

```yaml
# WRONG — missing critical packages
dependencies:
  http: ^1.0.0

# CORRECT — bank-approved stack
dependencies:
  dio: ^5.0.0
  flutter_secure_storage: ^9.0.0
  flutter_bloc: ^8.0.0
  go_router: ^14.0.0
```

---

## Core Standards

| Area | Standard | Enforcement |
|---|---|---|
| Linting | `very_good_analysis` with zero warnings | CI gate |
| Flavors | `dev`, `staging`, `prod` environments | Build configuration |
| Dart SDK | `>=3.0.0 <4.0.0` constraint | pubspec.yaml |
| Flutter SDK | `>=3.16.0` minimum | pubspec.yaml |
| Folder structure | Feature-first with clean architecture layers | Convention |
| Required packages | Bank-approved package list | Code review |
| Code generation | `build_runner` for freezed, json_serializable | Build step |
| Min platform versions | Android API 24+, iOS 15+ | Build config |
| Signing | Flavor-specific signing configurations | Release build |
| Analysis | Zero `info`, `warning`, or `error` in `dart analyze` | CI gate |

---

## Workflow

1. **Check structure** — Verify feature-first folder organization with clean architecture layers.
2. **Audit analysis_options** — Confirm `very_good_analysis` or equivalent with strict rules.
3. **Verify flavors** — Check that `dev`, `staging`, `prod` flavors are configured.
4. **Check dependencies** — Verify all required packages are present and versions are pinned.
5. **Validate build config** — Confirm min SDK versions, signing, and obfuscation settings.
6. **Run analysis** — Execute `dart analyze` and verify zero issues.
7. **Check code generation** — Verify `build_runner` is configured for generated code.

---

## Checklist

- [ ] Feature-first folder structure in place (§Project-Structure)
- [ ] `very_good_analysis` configured in `analysis_options.yaml` (§Analysis-Options)
- [ ] `dart analyze` reports zero issues (§Analysis-Options)
- [ ] `dev`, `staging`, `prod` flavors configured (§Flavor-Setup)
- [ ] All required bank packages present and version-pinned (§Required-Packages)
- [ ] Dart SDK `>=3.0.0 <4.0.0` in pubspec.yaml (§Pubspec-Config)
- [ ] Android `minSdkVersion 24` and iOS deployment target `15.0` (§Platform-Config)
- [ ] `build_runner` configured for code generation (§Build-Config)
- [ ] `.gitignore` covers generated files, build artifacts, IDE config
- [ ] Signing configurations per flavor (§Signing)
- [ ] `--obfuscate` and `--split-debug-info` in release builds

---

## References

- §Project-Structure — Full directory tree with descriptions
- §Analysis-Options — analysis_options.yaml with all rules
- §Flavor-Setup — Flavor configuration for Android and iOS
- §Required-Packages — Bank-approved package list with versions
- §Pubspec-Config — pubspec.yaml template
- §Platform-Config — Android and iOS platform configuration
- §Build-Config — build.yaml and build_runner setup
- §Signing — Code signing configuration per environment

See `reference.md` for full details on each section.
