# License Compliance — Reference

## Exception Request Template

### Request Form

```
Exception Request: Third-Party License
========================================

Date:               [YYYY-MM-DD]
Requestor:          [Name, team]
Service/Project:    [Service name]

Dependency:         [package-name@version]
License:            [SPDX identifier]
Category:           [Conditional / Banned]
Repository URL:     [link]

Justification:
  Why is this dependency needed?
  [1-3 sentences]

Alternatives Evaluated:
  | Alternative         | License    | Reason Rejected         |
  |---------------------|------------|-------------------------|
  | [alt-package-1]     | [license]  | [missing feature X]     |
  | [alt-package-2]     | [license]  | [unmaintained]          |
  | Build in-house      | N/A        | [estimated effort: Xd]  |

Isolation Plan:
  How will this dependency be isolated to minimize license risk?
  [ ] Separate module/service boundary
  [ ] Dynamic linking only (for LGPL)
  [ ] No modifications to licensed source
  [ ] Network-isolated (no AGPL exposure)

Risk Assessment:
  | Risk                        | Mitigation                |
  |-----------------------------|---------------------------|
  | Source disclosure obligation | [plan]                    |
  | Viral licensing             | [isolation approach]      |
  | Supply chain risk           | [pinned version, audit]   |

Requested Duration:   [6 / 12 months]
Review Date:          [YYYY-MM-DD]

Approvals:
  [ ] Tech Lead:      ____________  Date: ______
  [ ] Legal:          ____________  Date: ______
  [ ] CISO:           ____________  Date: ______
```

## SBOM Generation

### Tool-Agnostic Process

| Step | Command (example) | Output |
|------|-------------------|--------|
| Install scanner | `install-tool sbom-generator` | — |
| Scan project | `sbom-generate --format=spdx --output=sbom.spdx.json` | SPDX JSON |
| Scan project | `sbom-generate --format=cyclonedx --output=sbom.cdx.json` | CycloneDX JSON |
| Validate SBOM | `sbom-validate sbom.spdx.json` | Validation report |
| Diff SBOMs | `sbom-diff previous.spdx.json current.spdx.json` | Added/removed deps |

### Sample SPDX Output (abbreviated)

```json
{
  "spdxVersion": "SPDX-2.3",
  "dataLicense": "CC0-1.0",
  "SPDXID": "SPDXRef-DOCUMENT",
  "name": "payment-service-2.4.1",
  "documentNamespace": "https://bank.example.com/sbom/payment-service-2.4.1",
  "creationInfo": {
    "created": "2026-03-27T10:00:00Z",
    "creators": ["Tool: sbom-generator-3.2.0"],
    "licenseListVersion": "3.19"
  },
  "packages": [
    {
      "SPDXID": "SPDXRef-Package-http-client-4.0.0",
      "name": "http-client",
      "versionInfo": "4.0.0",
      "supplier": "Organization: HTTP Foundation",
      "downloadLocation": "https://registry.example.com/http-client-4.0.0.tar.gz",
      "licenseConcluded": "MIT",
      "licenseDeclared": "MIT",
      "checksums": [
        {
          "algorithm": "SHA256",
          "checksumValue": "a1b2c3d4e5f6..."
        }
      ]
    }
  ],
  "relationships": [
    {
      "spdxElementId": "SPDXRef-DOCUMENT",
      "relationshipType": "DESCRIBES",
      "relatedSpdxElement": "SPDXRef-Package-payment-service"
    },
    {
      "spdxElementId": "SPDXRef-Package-payment-service",
      "relationshipType": "DEPENDS_ON",
      "relatedSpdxElement": "SPDXRef-Package-http-client-4.0.0"
    }
  ]
}
```

### CI Pipeline Integration

```yaml
license-check:
  stage: security
  steps:
    - scan-licenses --lockfile --fail-on=banned,unknown
    - generate-sbom --format=spdx --output=sbom.spdx.json
    - validate-sbom sbom.spdx.json
    - upload-artifact sbom.spdx.json
  fail-conditions:
    - banned license detected
    - unknown license detected
    - SBOM validation fails
```

## Audit Reports

### Audit Report Template

```
License Audit Report
=====================

Date:           [YYYY-MM-DD]
Project:        [Service name]
Version:        [Version]
Auditor:        [Name or CI pipeline ID]
Scanner:        [Tool name + version]

Summary:
  Total dependencies:     [N]
  Direct:                 [N]
  Transitive:             [N]

  Approved:               [N]  ✓
  Conditionally Approved: [N]  ⚠
  Banned:                 [N]  ✗
  Unknown:                [N]  ✗

Violations:
  | Package          | Version | License   | Category | Action Required     |
  |------------------|---------|-----------|----------|---------------------|
  | [package-name]   | [ver]   | [SPDX]   | Banned   | Remove or replace   |
  | [package-name]   | [ver]   | UNKNOWN   | Unknown  | Identify license    |

Conditional — Compliance Verification:
  | Package          | License  | Restriction          | Compliant? |
  |------------------|----------|----------------------|------------|
  | [package-name]   | LGPL-3.0 | Dynamic linking only | Yes / No   |
  | [package-name]   | MPL-2.0  | File-level copyleft  | Yes / No   |

Active Exceptions:
  | Package          | License  | Approved By | Expires    | Status    |
  |------------------|----------|-------------|------------|-----------|
  | [package-name]   | [SPDX]  | [Name]      | [Date]     | Active    |

SBOM:
  Format:   SPDX 2.3
  Location: [artifact-url]/sbom.spdx.json
  Checksum: [SHA-256]
```

## NOTICE File Template

```
NOTICE
======

This product includes third-party software licensed under various
open-source licenses. The following is a list of these dependencies
and their respective licenses.

--------------------------------------------------------------------------------
Package:    http-client
Version:    4.0.0
License:    MIT
URL:        https://github.com/example/http-client
Copyright:  Copyright (c) 2024 HTTP Foundation

Permission is hereby granted, free of charge, to any person obtaining a copy...
[full MIT license text]
--------------------------------------------------------------------------------

Package:    date-utils
Version:    2.1.0
License:    Apache-2.0
URL:        https://github.com/example/date-utils
Copyright:  Copyright 2024 Date Utils Contributors

Licensed under the Apache License, Version 2.0...
[full Apache 2.0 license text or reference]
--------------------------------------------------------------------------------
```

## Common License Identifiers (SPDX)

| SPDX ID | Full Name | Category |
|---------|-----------|----------|
| MIT | MIT License | Approved |
| Apache-2.0 | Apache License 2.0 | Approved |
| BSD-2-Clause | BSD 2-Clause "Simplified" | Approved |
| BSD-3-Clause | BSD 3-Clause "New" | Approved |
| ISC | ISC License | Approved |
| Unlicense | The Unlicense | Approved |
| CC0-1.0 | Creative Commons Zero 1.0 | Approved |
| Zlib | zlib License | Approved |
| BSL-1.0 | Boost Software License 1.0 | Approved |
| MPL-2.0 | Mozilla Public License 2.0 | Conditional |
| LGPL-2.1-only | GNU Lesser GPL v2.1 only | Conditional |
| LGPL-3.0-only | GNU Lesser GPL v3.0 only | Conditional |
| EPL-2.0 | Eclipse Public License 2.0 | Conditional |
| CDDL-1.0 | Common Development and Distribution License 1.0 | Conditional |
| GPL-2.0-only | GNU GPL v2.0 only | Banned |
| GPL-3.0-only | GNU GPL v3.0 only | Banned |
| AGPL-3.0-only | GNU Affero GPL v3.0 only | Banned |
| SSPL-1.0 | Server Side Public License v1 | Banned |
| CC-BY-SA-4.0 | Creative Commons Attribution ShareAlike 4.0 | Banned |

## Dual-License Decision Matrix

When a dependency offers multiple licenses, choose using this priority:

| Priority | Choose | Reason |
|----------|--------|--------|
| 1 | MIT or ISC | Most permissive; fewest obligations |
| 2 | Apache-2.0 | Permissive with patent grant |
| 3 | BSD-2/3-Clause | Permissive; attribution required |
| 4 | MPL-2.0 | Least restrictive copyleft option |
| 5 | LGPL | Only if no permissive option exists |

Document the chosen license in the NOTICE file and SBOM.
