---
name: license-compliance-flutter
description: "Flutter/Dart license compliance — pub license check, pana scoring, dependency audit, SBOM, approved packages for banking apps"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Edit
  - Bash
argument-hint: "path to Flutter project root or pubspec.yaml to audit"
---

# License Compliance — Flutter Stack

You are a license compliance reviewer for the bank's Flutter applications.
When invoked, audit Dart/Flutter package licenses, dependency health, and compliance against bank procurement policy.

> All rules from `core/license-compliance/SKILL.md` apply here. This adds Flutter/Dart-specific implementation.

---

## Hard Rules

### HR-1: Never use AGPL or GPL packages in proprietary banking app

```yaml
# WRONG — GPL-licensed package
dependencies:
  some_gpl_package: ^1.0.0  # License: GPL-3.0

# CORRECT — MIT/BSD/Apache licensed
dependencies:
  dio: ^5.0.0  # License: MIT
```

### HR-2: Never use unpublished or unverified packages

```yaml
# WRONG — git dependency with no version pinning
dependencies:
  custom_lib:
    git: https://github.com/unknown/lib.git

# CORRECT — published package with pinned version
dependencies:
  custom_lib: ^2.1.0
```

### HR-3: All dependencies must be audited before adoption

```bash
# WRONG — add and use immediately
flutter pub add new_package

# CORRECT — audit first
dart pub score new_package  # Check pana score
flutter pub deps --no-dev   # Review transitive deps
```

---

## Core Standards

| Area | Standard | Threshold |
|---|---|---|
| License allowlist | MIT, BSD-2, BSD-3, Apache-2.0, ISC, Zlib | Mandatory |
| License denylist | GPL, AGPL, SSPL, EUPL, CC-BY-SA | Blocked |
| Pana score | Minimum 120/160 for new packages | Mandatory |
| Pub outdated | Zero packages more than 2 major versions behind | CI check |
| Transitive deps | All transitive dependencies audited | Mandatory |
| Dependency count | Minimize — justify each addition | Code review |
| SBOM | Generated per release | Mandatory |
| Vulnerability scan | `dart pub outdated` + advisory check per build | CI gate |
| Version pinning | Caret syntax (`^`) for all direct deps | Convention |
| Flutter SDK | Only stable channel for production | Mandatory |

---

## Workflow

1. **Check licenses** — Run license check on all direct and transitive dependencies.
2. **Audit new packages** — Verify pana score, license, maintenance, and popularity.
3. **Review outdated** — Run `dart pub outdated` and flag packages behind > 2 major versions.
4. **Validate deps tree** — Check `flutter pub deps` for unexpected transitive dependencies.
5. **Generate SBOM** — Produce software bill of materials for the release.
6. **Scan advisories** — Check for known vulnerabilities in dependencies.

---

## Checklist

- [ ] All direct dependencies use approved licenses (§License-Allowlist)
- [ ] All transitive dependencies use approved licenses (§License-Allowlist)
- [ ] No GPL, AGPL, or SSPL packages in dependency tree (§License-Denylist)
- [ ] New packages have pana score >= 120/160 (§Pana-Scoring)
- [ ] `dart pub outdated` shows no major version gaps > 2 (§Outdated-Check)
- [ ] All dependencies from pub.dev — no git or path deps in prod (§Dependency-Sources)
- [ ] SBOM generated and archived with release (§SBOM-Generation)
- [ ] No known vulnerabilities in dependency tree (§Advisory-Check)
- [ ] Dependency additions justified in PR description
- [ ] Flutter stable channel used for production builds

---

## References

- §License-Allowlist — Approved and denied license list with rationale
- §Pana-Scoring — pana scoring criteria and minimum thresholds
- §Outdated-Check — dart pub outdated audit process
- §Dependency-Sources — Approved dependency source policy
- §SBOM-Generation — Software bill of materials generation
- §Advisory-Check — Vulnerability scanning for Dart packages

See `reference.md` for full details on each section.
