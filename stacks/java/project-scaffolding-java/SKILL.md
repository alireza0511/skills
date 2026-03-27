---
name: project-scaffolding-java
description: Project scaffolding and setup standards for Java/Spring Boot banking services
allowed-tools:
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - Bash
argument-hint: "e.g. 'scaffold new service', 'add standard dependencies', 'create project layout'"
---

# Project Scaffolding — Java / Spring Boot

You are a **project scaffolding specialist** for the bank's Java/Spring Boot services.

> All rules from `core/project-scaffolding/SKILL.md` apply here. This adds Java-specific implementation.

---

## Hard Rules

### HR-1: Always use Gradle wrapper

```bash
# WRONG — requires global Gradle install
gradle build
```

```bash
# CORRECT — wrapper committed to repo
./gradlew build
```

### HR-2: Never use wildcard dependency versions

```groovy
// WRONG
implementation 'org.mapstruct:mapstruct:+'
```

```groovy
// CORRECT — managed by Spring BOM or explicit version
implementation 'org.mapstruct:mapstruct:1.5.5.Final'
```

### HR-3: Always include standard operational dependencies

```groovy
// WRONG — missing actuator, validation, security
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
}
```

```groovy
// CORRECT — full operational stack
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation 'org.springframework.boot:spring-boot-starter-actuator'
    implementation 'org.springframework.boot:spring-boot-starter-security'
    implementation 'org.springframework.boot:spring-boot-starter-validation'
}
```

---

## Core Standards

| Area | Standard |
|---|---|
| Build tool | Gradle 8.x with Groovy or Kotlin DSL |
| Java version | 21 (Temurin distribution) via toolchain |
| Spring Boot | 3.3.x (latest stable 3.x) |
| Project layout | Standard Gradle `src/main/java`, `src/test/java` |
| Config format | `application.yml` (not `.properties`) |
| Profiles | `local`, `dev`, `staging`, `production` |
| Docker | Multi-stage Dockerfile with distroless base |
| CI | GitHub Actions workflow from day one |
| .gitignore | Standard Java/Gradle ignores |

---

## Workflow

1. **Initialize Gradle project** — Use Spring Initializr or `gradle init`. See §SCAFF-01.
2. **Configure build.gradle** — Add required plugins and dependencies. See §SCAFF-02.
3. **Create application.yml** — Set up profiles and standard properties. See §SCAFF-03.
4. **Set up Docker** — Create Dockerfile and docker-compose.yml. See §SCAFF-04.
5. **Add CI pipeline** — Create GitHub Actions workflow. See §SCAFF-05.
6. **Create directory structure** — Set up package-by-feature layout. See §SCAFF-06.
7. **Add standard files** — .gitignore, README, .editorconfig. See §SCAFF-07.

---

## Checklist

- [ ] Gradle wrapper committed (`gradlew`, `gradle/wrapper/`) — HR-1
- [ ] Java 21 toolchain configured — §SCAFF-02
- [ ] Spring Boot 3.x with BOM managing dependency versions — §SCAFF-02
- [ ] Required starters: web, actuator, security, validation — HR-3
- [ ] `application.yml` with profile-specific configs — §SCAFF-03
- [ ] Dockerfile with multi-stage build — §SCAFF-04
- [ ] `docker-compose.yml` for local development — §SCAFF-04
- [ ] GitHub Actions CI workflow — §SCAFF-05
- [ ] Package-by-feature directory structure — §SCAFF-06
- [ ] `.gitignore`, `.editorconfig`, README in place — §SCAFF-07
- [ ] No wildcard dependency versions — HR-2
