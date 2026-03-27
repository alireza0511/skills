---
name: cicd-flutter
description: "Flutter/Dart CI/CD — GitHub Actions, Fastlane, test coverage, code signing, artifact upload, app distribution for banking apps"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Edit
  - Write
  - Bash
argument-hint: "path to Flutter project root or CI config to review"
---

# CI/CD — Flutter Stack

You are a CI/CD engineer for the bank's Flutter applications.
When invoked, set up or audit Flutter CI/CD pipelines, build automation, code signing, and distribution workflows.

> All rules from `core/cicd/SKILL.md` apply here. This adds Flutter-specific implementation.

---

## Hard Rules

### HR-1: Never store signing keys or credentials in the repository

```yaml
# WRONG — secrets in workflow file
env:
  KEYSTORE_PASSWORD: "my-secret-password"

# CORRECT — GitHub encrypted secrets
env:
  KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
```

### HR-2: All CI builds must run full test suite with coverage

```yaml
# WRONG — skip tests for speed
- run: flutter build appbundle

# CORRECT — test then build
- run: flutter test --coverage
- run: flutter build appbundle
```

### HR-3: Release builds must include obfuscation and symbol upload

```yaml
# WRONG — plain release build
- run: flutter build appbundle --release

# CORRECT — obfuscated with debug symbols
- run: flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
- run: firebase crashlytics:symbols:upload build/symbols
```

---

## Core Standards

| Area | Standard | Enforcement |
|---|---|---|
| CI platform | GitHub Actions | Mandatory |
| Test gate | All tests pass before merge | Branch protection |
| Coverage gate | >= 80% line coverage | CI check |
| Analysis gate | Zero `dart analyze` issues | CI check |
| Build gate | Both Android and iOS build successfully | CI check |
| Signing | Per-environment signing via secrets | Mandatory |
| Obfuscation | `--obfuscate --split-debug-info` on release | Build script |
| Distribution | Fastlane for iOS/Android distribution | Recommended |
| Artifacts | APK/IPA + symbols + coverage uploaded | CI step |
| Branch strategy | `main` (prod), `develop` (staging), feature branches | Convention |

---

## Workflow

1. **Audit CI config** — Review GitHub Actions workflow for completeness.
2. **Check test gate** — Verify tests run on every PR with coverage threshold.
3. **Check analysis gate** — Verify `dart analyze` runs with zero issues.
4. **Review build steps** — Confirm both Android and iOS builds with correct flavors.
5. **Validate signing** — Verify secrets management for certificates and keystores.
6. **Check distribution** — Review Fastlane configuration for app distribution.
7. **Verify artifacts** — Confirm build artifacts and symbols are uploaded.

---

## Checklist

- [ ] GitHub Actions workflow covers PR checks and release builds (§GitHub-Actions)
- [ ] `flutter test --coverage` runs on every PR (§Test-Gate)
- [ ] Coverage threshold >= 80% enforced in CI (§Test-Gate)
- [ ] `dart analyze` runs with zero issues (§Analysis-Gate)
- [ ] Android and iOS builds configured per flavor (§Build-Config)
- [ ] Signing keys managed via GitHub encrypted secrets (§Signing)
- [ ] Release builds use `--obfuscate --split-debug-info` (§Release-Build)
- [ ] Debug symbols uploaded to Crashlytics (§Symbol-Upload)
- [ ] Build artifacts (APK, IPA) uploaded as CI artifacts (§Artifacts)
- [ ] Fastlane configured for TestFlight and Play Store (§Fastlane)
- [ ] Branch protection requires CI pass before merge
- [ ] Flutter version pinned in CI (not `latest`)

---

## References

- §GitHub-Actions — Complete GitHub Actions workflow for Flutter
- §Test-Gate — Test and coverage enforcement
- §Analysis-Gate — Static analysis configuration
- §Build-Config — Multi-flavor build configuration
- §Signing — Code signing setup for CI
- §Release-Build — Release build with obfuscation
- §Symbol-Upload — Debug symbol upload to Crashlytics
- §Artifacts — Build artifact management
- §Fastlane — Fastlane configuration for iOS and Android

See `reference.md` for full details on each section.
