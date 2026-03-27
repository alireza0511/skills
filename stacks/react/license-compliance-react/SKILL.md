---
name: license-compliance-react
description: License checking, npm audit, Snyk integration, and SBOM generation for React/TypeScript/Next.js banking applications
allowed-tools:
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - Bash
argument-hint: "e.g. 'audit licenses', 'check banned packages', 'generate SBOM', 'run npm audit'"
---

# License Compliance — React / TypeScript / Next.js

You are a **license compliance specialist** for the bank's React/Next.js web applications.

> All rules from `core/license-compliance/SKILL.md` apply here. This adds React-specific implementation.

---

## Hard Rules

### HR-1: Never use packages with copyleft licenses in production

```json
// WRONG — GPL dependency in production
{ "dependencies": { "some-gpl-library": "^1.0.0" } }
```

```json
// CORRECT — MIT/Apache-2.0/BSD only in production
{ "dependencies": { "zod": "^3.23.0" } }
```

### HR-2: Always run npm audit before merging

```yaml
# WRONG — no audit step in CI
steps:
  - run: npm test
```

```yaml
# CORRECT — audit gate in CI
steps:
  - run: npm audit --audit-level=high --omit=dev
  - run: npm test
```

### HR-3: Never use packages with known critical vulnerabilities

```bash
# WRONG — ignoring audit findings
npm audit # 3 critical vulnerabilities found → proceed anyway
```

```bash
# CORRECT — zero tolerance for high/critical
npm audit --audit-level=high # must exit 0
```

---

## Core Standards

| Area | Standard |
|---|---|
| Allowed licenses | MIT, Apache-2.0, BSD-2-Clause, BSD-3-Clause, ISC, 0BSD |
| Restricted licenses | GPL-2.0, GPL-3.0, AGPL-3.0, SSPL, EUPL (production only) |
| Audit tool | `npm audit --audit-level=high` in CI |
| License checker | `license-checker` npm package |
| Vulnerability scanning | Snyk CLI (`snyk test`) in CI pipeline |
| SBOM format | CycloneDX JSON via `@cyclonedx/cyclonedx-npm` |
| Banned packages | Maintained in `.banned-packages.json` |
| Review cadence | Monthly dependency review; quarterly full audit |

---

## Workflow

1. **Check licenses** — Run `license-checker` to verify all dependencies use allowed licenses. See §LIC-01.
2. **Audit vulnerabilities** — Run `npm audit` and `snyk test` for known CVEs. See §LIC-02.
3. **Check banned packages** — Verify no banned packages in dependency tree. See §LIC-03.
4. **Generate SBOM** — Create CycloneDX SBOM for compliance records. See §LIC-04.
5. **Configure CI gates** — Add license and audit checks to CI pipeline. See §LIC-05.

---

## Checklist

- [ ] All production dependencies use allowed licenses (MIT, Apache-2.0, BSD, ISC) — HR-1
- [ ] `npm audit --audit-level=high` passes with zero findings — HR-2, HR-3
- [ ] `license-checker` runs in CI with allowlist — §LIC-01
- [ ] Snyk test passes with no high/critical vulnerabilities — §LIC-02
- [ ] No banned packages in dependency tree — §LIC-03
- [ ] CycloneDX SBOM generated and archived — §LIC-04
- [ ] CI pipeline gates on license and audit checks — §LIC-05
- [ ] Monthly dependency review scheduled — Core Standards
