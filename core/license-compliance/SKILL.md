---
name: license-compliance
description: Open-source license compliance — approved/banned licenses, audit process, SBOM generation, exception workflow for bank services
allowed-tools: Read, Edit, Write, Glob, Grep
---

# License Compliance Standards

You are a license compliance enforcer for bank services. When invoked, audit dependencies for license violations, generate SBOMs, or process exception requests.

## Hard Rules

### Never introduce a copyleft-licensed dependency without an approved exception

```
# WRONG — adding GPL dependency without review
dependencies:
  some-library: "^2.0.0"  # License: GPL-3.0

# CORRECT — use a permissively licensed alternative
dependencies:
  alt-library: "^1.5.0"   # License: MIT
```

### Every dependency must have a declared license

```
# WRONG — dependency with no license metadata
dependencies:
  unknown-lib: "^1.0.0"   # License: NONE / UNKNOWN

# CORRECT — verify license before adding
# Step 1: Check license
# Step 2: Confirm it's on the approved list
# Step 3: Add dependency
dependencies:
  known-lib: "^1.0.0"     # License: Apache-2.0 ✓
```

### SBOM must be generated and stored with every release artifact

```
# WRONG — release without SBOM
release:
  steps: [build, test, deploy]

# CORRECT — SBOM generated as part of build
release:
  steps: [build, generate-sbom, test, deploy]
  artifacts: [binary, sbom.spdx.json]
```

## License Classification

| Category | Licenses | Policy |
|----------|----------|--------|
| **Approved** | MIT, Apache-2.0, BSD-2-Clause, BSD-3-Clause, ISC, Unlicense, CC0-1.0, Zlib, BSL-1.0 | Use freely |
| **Conditionally Approved** | MPL-2.0, LGPL-2.1, LGPL-3.0, EPL-2.0, CDDL-1.0 | Allowed with restrictions (see table below) |
| **Banned** | GPL-2.0, GPL-3.0, AGPL-3.0, SSPL-1.0, CC-BY-SA-4.0, Artistic-2.0 | Never use; no exceptions for production code |
| **Unknown / No License** | Any unlicensed code | Treat as banned; do not use |

### Conditionally Approved — Restrictions

| License | Condition |
|---------|-----------|
| MPL-2.0 | Modifications to MPL files must be open-sourced; separate files only |
| LGPL-2.1/3.0 | Dynamic linking only; no static linking; no modification of LGPL source |
| EPL-2.0 | Must offer source of EPL components on request |
| CDDL-1.0 | File-level copyleft; modifications to CDDL files must be shared |

## Core Standards

| Standard | Requirement |
|----------|-------------|
| Pre-merge scan | License check runs in CI before any PR merge |
| Transitive dependencies | Scan includes all transitive (indirect) dependencies |
| SBOM format | SPDX 2.3 or CycloneDX 1.5; machine-readable JSON |
| SBOM storage | Stored alongside release artifact; retained per artifact retention policy |
| Audit frequency | Full audit on every release; incremental on every dependency change |
| Exception process | Written request → legal review → CISO approval → time-boxed (max 12 months) |
| Inventory | Central registry of all third-party dependencies with license metadata |
| Dual-licensed | Choose the most permissive option; document choice |
| Internal code | All bank-authored code uses the organization's proprietary license |
| Attribution | NOTICE file must list all third-party licenses and attributions |

## Exception Request Workflow

| Step | Owner | SLA |
|------|-------|-----|
| 1. Submit request (dependency, license, justification, alternatives evaluated) | Developer | — |
| 2. Technical review (risk assessment, isolation feasibility) | Tech Lead | 3 business days |
| 3. Legal review (license obligations, compliance impact) | Legal/Compliance | 5 business days |
| 4. CISO approval (security and data risk) | CISO | 5 business days |
| 5. Document exception (registry entry, expiry date, conditions) | Compliance team | 2 business days |
| 6. Re-review before expiry | Original requestor | 30 days before expiry |

For the full exception request template, read `core/license-compliance/reference.md` § Exception Request Template.

## SBOM Requirements

| Field | Required | Description |
|-------|----------|-------------|
| Document name | Yes | Service name + version |
| Creation timestamp | Yes | ISO 8601 |
| Creator tool | Yes | Tool name + version |
| Package name | Yes | For each dependency |
| Package version | Yes | Exact resolved version |
| License (SPDX ID) | Yes | SPDX license identifier |
| Supplier | Yes | Package author/organization |
| Checksum | Yes | SHA-256 of package |
| Relationship | Yes | Direct or transitive dependency |

For SBOM generation commands and sample output, read `core/license-compliance/reference.md` § SBOM Generation.

## Workflow

1. **Scan dependencies** — run license scanner against lockfile; include transitive dependencies.
2. **Classify findings** — map each license to approved/conditional/banned/unknown.
3. **Block violations** — flag banned or unknown licenses; fail CI if found.
4. **Review conditional** — verify conditional licenses meet their specific restrictions.
5. **Generate SBOM** — produce SPDX or CycloneDX JSON; attach to build artifact.
6. **Update NOTICE** — ensure attribution file reflects current dependency set.

## Checklist

- [ ] License scanner integrated in CI pipeline
- [ ] All direct dependencies have approved licenses
- [ ] All transitive dependencies scanned and classified
- [ ] No banned licenses present (GPL, AGPL, SSPL, unknown)
- [ ] Conditional licenses meet their specific restrictions
- [ ] SBOM generated in SPDX or CycloneDX format
- [ ] SBOM stored with release artifact
- [ ] NOTICE file lists all third-party attributions
- [ ] Active exceptions documented with expiry dates
- [ ] Dual-licensed dependencies have documented license choice

For audit report templates and scanner configurations, read `core/license-compliance/reference.md` § Audit Reports.
