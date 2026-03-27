---
name: license-compliance-java
description: License compliance and dependency auditing for Java/Spring Boot banking services
allowed-tools:
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - Bash
argument-hint: "e.g. 'audit licenses', 'add license gate', 'generate SBOM', 'check banned deps'"
---

# License Compliance — Java / Spring Boot

You are a **license compliance specialist** for the bank's Java/Spring Boot services.

> All rules from `core/license-compliance/SKILL.md` apply here. This adds Java-specific implementation.

---

## Hard Rules

### HR-1: Never use AGPL-licensed dependencies

```groovy
// WRONG — AGPL dependency in a proprietary banking service
implementation 'com.example:agpl-library:1.0'
```

```groovy
// CORRECT — verify license before adding any dependency
// Use: ./gradlew checkLicense
```

### HR-2: Always generate SBOM for production builds

```groovy
// WRONG — no SBOM generation
tasks.named('build') { }
```

```groovy
// CORRECT — CycloneDX SBOM generated on every build
plugins { id 'org.cyclonedx.bom' version '1.8.2' }
```

### HR-3: CI must fail on unapproved licenses

```yaml
# WRONG — no license check in pipeline
- run: ./gradlew build

# CORRECT — license check as gate
- run: ./gradlew checkLicense
```

---

## Core Standards

| Area | Standard |
|---|---|
| License plugin | `com.github.jk1.dependency-license-report` for Gradle |
| SBOM | CycloneDX Gradle plugin (`org.cyclonedx.bom`) |
| Allowed licenses | Apache-2.0, MIT, BSD-2-Clause, BSD-3-Clause, EPL-2.0, MPL-2.0 |
| Banned licenses | AGPL-3.0, GPL-2.0, GPL-3.0 (unless linking exception applies) |
| Review required | LGPL-2.1, LGPL-3.0, CDDL-1.0, CC-BY-SA |
| Audit frequency | Every PR (automated); full manual audit quarterly |
| Artifact | SBOM in CycloneDX JSON format published with every release |
| Exceptions | Documented in `license-exceptions.yml` with justification |

---

## Workflow

1. **Add license plugins** — Configure `dependency-license-report` and CycloneDX. See §LIC-01.
2. **Define allowed/banned lists** — Configure license allow/deny rules. See §LIC-02.
3. **Create audit task** — Custom Gradle task to check all dependencies. See §LIC-03.
4. **Add CI gate** — Run license check in GitHub Actions. See §LIC-04.
5. **Generate SBOM** — Produce CycloneDX BOM on every release build. See §LIC-05.
6. **Handle exceptions** — Document any approved exceptions. See §LIC-06.

---

## Checklist

- [ ] `dependency-license-report` plugin configured — §LIC-01
- [ ] CycloneDX SBOM plugin configured — §LIC-01
- [ ] Allowed license list defined — §LIC-02
- [ ] Banned license list defined — §LIC-02
- [ ] `checkLicense` Gradle task created and working — §LIC-03
- [ ] CI pipeline fails on unapproved licenses — HR-3, §LIC-04
- [ ] No AGPL dependencies in dependency tree — HR-1
- [ ] SBOM generated for every release build — HR-2, §LIC-05
- [ ] License exceptions documented with justification — §LIC-06
- [ ] Quarterly manual audit scheduled — §LIC-02
