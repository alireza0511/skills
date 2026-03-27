# License Compliance Flutter — Reference

## §License-Allowlist

### Approved Licenses

| License | SPDX ID | Status | Notes |
|---|---|---|---|
| MIT | MIT | Approved | Most common in Dart ecosystem |
| BSD 2-Clause | BSD-2-Clause | Approved | Minimal restrictions |
| BSD 3-Clause | BSD-3-Clause | Approved | Flutter SDK license |
| Apache 2.0 | Apache-2.0 | Approved | Patent grant included |
| ISC | ISC | Approved | Equivalent to MIT |
| Zlib | Zlib | Approved | Minimal restrictions |
| Unicode | Unicode-DFS-2016 | Approved | For intl/ICU packages |

### Denied Licenses

| License | SPDX ID | Status | Reason |
|---|---|---|---|
| GPL 2.0/3.0 | GPL-2.0/GPL-3.0 | Denied | Copyleft — requires source disclosure |
| AGPL 3.0 | AGPL-3.0 | Denied | Network copyleft — strictest |
| SSPL | SSPL-1.0 | Denied | Server-side copyleft |
| LGPL | LGPL-2.1/LGPL-3.0 | Review Required | Dynamic linking may be acceptable |
| CC-BY-SA | CC-BY-SA-4.0 | Denied | Share-alike requirement |
| Unlicense | Unlicense | Review Required | No warranty, unclear liability |

### Checking Licenses

```bash
# Check all direct dependency licenses
dart pub deps --no-dev --style=compact

# Use oss_licenses package for runtime license display
# Required for app store compliance (show licenses in Settings)
```

```dart
// List all package licenses programmatically
import 'package:flutter/foundation.dart';

void printLicenses() {
  LicenseRegistry.licenses.listen((license) {
    for (final paragraph in license.paragraphs) {
      debugPrint('${license.packages.join(', ')}: ${paragraph.text}');
    }
  });
}
```

---

## §Pana-Scoring

### Pana Score Criteria

| Category | Max Points | Bank Minimum | Criteria |
|---|---|---|---|
| Follow conventions | 30 | 25 | pubspec, analysis_options, formatting |
| Documentation | 20 | 15 | API docs, README, example |
| Platform support | 20 | 15 | Declared platforms, platform-specific code |
| Analysis | 50 | 40 | No errors, no warnings, no hints |
| Dependency | 20 | 15 | Up-to-date deps, no deprecated |
| Null safety | 20 | 20 | Full null safety |
| **Total** | **160** | **120** | |

### Running Pana

```bash
# Install pana
dart pub global activate pana

# Score a published package
pana <package_name>

# Score a local package
pana --source path .
```

### Package Evaluation Template

| Criterion | Check | Pass/Fail |
|---|---|---|
| License | Approved license (MIT, BSD, Apache) | |
| Pana score | >= 120/160 | |
| Null safety | Full null safety | |
| Last publish | Within 12 months | |
| Pub likes | > 100 (for critical deps) | |
| GitHub issues | Responsive maintainer (< 30 days avg) | |
| Transitive deps | All transitive deps also pass audit | |
| Security advisories | No known CVEs | |
| Alternatives | Evaluated alternatives and justified choice | |

---

## §Outdated-Check

### Running Outdated Check

```bash
# Check for outdated packages
dart pub outdated

# Output columns:
# Package | Current | Upgradable | Resolvable | Latest
```

### Outdated Policy

| Gap | Action | SLA |
|---|---|---|
| Patch version behind | Update in next sprint | 2 weeks |
| Minor version behind | Update in current quarter | 3 months |
| 1 major version behind | Plan migration | 6 months |
| 2+ major versions behind | Urgent migration — blocks release | 30 days |
| Discontinued package | Replace with alternative | 90 days |

### Automated Outdated Check in CI

```bash
#!/bin/bash
# scripts/check_outdated.sh

echo "Checking for severely outdated packages..."

# Parse dart pub outdated output
dart pub outdated --json | dart run scripts/check_major_gaps.dart

# Exit with error if any package is 2+ major versions behind
```

---

## §Dependency-Sources

### Approved Sources

| Source | Allowed | Conditions |
|---|---|---|
| pub.dev (published) | Yes | Default and preferred |
| pub.dev (verified publisher) | Yes, preferred | Extra trust signal |
| Private pub server | Yes | For internal packages |
| Git dependency | No (prod) | Only for dev/testing |
| Path dependency | No (prod) | Only for monorepo local dev |
| Hosted URL (non pub.dev) | Requires approval | Must be bank-managed server |

### pubspec.yaml Dependency Rules

```yaml
# CORRECT — published packages with caret versioning
dependencies:
  dio: ^5.4.0
  flutter_bloc: ^8.1.0

# CORRECT — internal private package
dependencies:
  bank_design_system:
    hosted:
      name: bank_design_system
      url: https://pub.internal.bank.com
    version: ^2.0.0

# WRONG — git dependency in production
dependencies:
  some_lib:
    git:
      url: https://github.com/org/lib.git
      ref: main
```

---

## §SBOM-Generation

### Generating SBOM

```bash
# Generate CycloneDX SBOM from pubspec.lock
# Using cdxgen (CycloneDX generator)
npx @cyclonedx/cdxgen -t dart -o sbom.json .

# Or using dart-specific tools
dart pub deps --json > dependency_tree.json
```

### SBOM Contents

| Field | Description | Example |
|---|---|---|
| Component name | Package name | `dio` |
| Version | Exact resolved version | `5.4.0` |
| License | SPDX license ID | `MIT` |
| Source | Registry URL | `https://pub.dev` |
| Hash | SHA-256 of package archive | `abc123...` |
| Scope | direct / transitive | `direct` |

### SBOM Policy

| Rule | Detail |
|---|---|
| Generation frequency | Every release build |
| Storage | Archived with release artifacts |
| Retention | 5 years minimum (regulatory) |
| Format | CycloneDX JSON or SPDX |
| Review | Security team reviews before major releases |

---

## §Advisory-Check

### Checking for Vulnerabilities

```bash
# dart pub outdated includes advisory information
dart pub outdated --show-all

# Check specific package for advisories
# pub.dev displays security advisories on package pages

# GitHub Advisory Database
# https://github.com/advisories?query=ecosystem%3Apub
```

### Vulnerability Response SLAs

| Severity | SLA | Action |
|---|---|---|
| Critical (CVSS 9.0+) | 24 hours | Patch or replace; block release |
| High (CVSS 7.0-8.9) | 7 days | Patch; block release after SLA |
| Medium (CVSS 4.0-6.9) | 30 days | Patch in next release |
| Low (CVSS < 4.0) | 90 days | Track and patch opportunistically |

### License Display in App

```dart
// Required for app store compliance — show third-party licenses
// Flutter provides built-in license page
void showLicenses(BuildContext context) {
  showLicensePage(
    context: context,
    applicationName: 'National Bank',
    applicationVersion: '1.0.0',
    applicationIcon: Image.asset('assets/icons/bank_logo.png', width: 48),
    applicationLegalese: '\u00A9 2024 National Bank. All rights reserved.',
  );
}
```
