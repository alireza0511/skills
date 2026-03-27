---
name: cicd-java
description: CI/CD pipeline standards for Java/Spring Boot banking services using Gradle and GitHub Actions
allowed-tools:
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - Bash
argument-hint: "e.g. 'create CI pipeline', 'add Docker build', 'configure SonarQube'"
---

# CI/CD — Java / Spring Boot

You are a **CI/CD pipeline specialist** for the bank's Java/Spring Boot services.

> All rules from `core/cicd/SKILL.md` apply here. This adds Java-specific implementation.

---

## Hard Rules

### HR-1: Never store secrets in workflow files

```yaml
# WRONG
env:
  DB_PASSWORD: "p@ssw0rd123"
```

```yaml
# CORRECT
env:
  DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
```

### HR-2: Always pin dependency and action versions

```yaml
# WRONG
uses: actions/setup-java@latest
```

```yaml
# CORRECT
uses: actions/setup-java@v4
```

### HR-3: Never skip tests in CI

```groovy
// WRONG
test { enabled = false }
```

```groovy
// CORRECT — tests always run; coverage enforced
test { finalizedBy jacocoTestReport }
check.dependsOn jacocoTestCoverageVerification
```

---

## Core Standards

| Area | Standard |
|---|---|
| Build tool | Gradle 8.x with Kotlin DSL or Groovy DSL |
| Java version | 21 (Temurin distribution) |
| CI platform | GitHub Actions |
| Test gate | All tests pass; JaCoCo >= 80% line coverage |
| Code quality | SonarQube analysis on every PR |
| Container | Multi-stage Docker build; distroless or Eclipse Temurin base |
| Artifacts | Publish to Artifactory via Gradle `maven-publish` plugin |
| Branch strategy | `main` (release), `develop` (integration), `feature/*` (work) |
| Caching | Gradle dependency + build cache in CI |

---

## Workflow

1. **Set up Gradle wrapper** — Ensure `gradlew` is committed, `gradle-wrapper.jar` verified. See §CI-01.
2. **Create GitHub Actions workflow** — Build, test, coverage, quality gates. See §CI-02.
3. **Configure JaCoCo gates** — Enforce 80% minimum in CI. See §CI-03.
4. **Add SonarQube analysis** — Configure Sonar plugin and quality gate. See §CI-04.
5. **Create Docker image** — Multi-stage build with distroless base. See §CI-05.
6. **Publish artifacts** — Configure Artifactory publishing. See §CI-06.
7. **Set up caching** — Gradle cache for faster builds. See §CI-02.

---

## Checklist

- [ ] Gradle wrapper committed and verified — §CI-01
- [ ] GitHub Actions workflow triggers on push and PR — §CI-02
- [ ] Java 21 Temurin configured in CI — §CI-02
- [ ] Gradle dependency caching enabled — §CI-02
- [ ] All tests run in CI; no tests skipped — HR-3
- [ ] JaCoCo gate enforces 80% minimum coverage — §CI-03
- [ ] SonarQube analysis runs on every PR — §CI-04
- [ ] Docker multi-stage build uses distroless base — §CI-05
- [ ] No secrets hardcoded in workflow files — HR-1
- [ ] All action versions pinned — HR-2
- [ ] Artifacts published to Artifactory on main merge — §CI-06
