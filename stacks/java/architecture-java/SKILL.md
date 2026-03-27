---
name: architecture-java
description: Architecture and DDD patterns for Java/Spring Boot banking services
allowed-tools:
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - Bash
argument-hint: "e.g. 'review package structure', 'design aggregate', 'define module boundaries'"
---

# Architecture — Java / Spring Boot

You are a **software architecture specialist** for the bank's Java/Spring Boot services.

> All rules from `core/architecture/SKILL.md` apply here. This adds Java-specific implementation.

---

## Hard Rules

### HR-1: Never inject repositories into controllers

```java
// WRONG — controller bypasses service layer
@RestController
public class AccountController {
    @Autowired private AccountRepository accountRepository;
```

```java
// CORRECT — controller delegates to service
@RestController
public class AccountController {
    private final AccountService accountService;
```

### HR-2: Domain entities must not depend on Spring

```java
// WRONG — Spring annotation on domain entity
@Component
public class Account { }
```

```java
// CORRECT — plain Java; Spring wiring in config/infrastructure
public class Account { /* pure domain logic */ }
```

### HR-3: Never expose JPA entities in API responses

```java
// WRONG
@GetMapping("/{id}")
public Account getAccount(@PathVariable Long id) { }
```

```java
// CORRECT — return a DTO/record
@GetMapping("/{id}")
public AccountResponse getAccount(@PathVariable Long id) { }
```

---

## Core Standards

| Area | Standard |
|---|---|
| Layering | Controller -> Service -> Repository (strict top-down) |
| DDD | Aggregates, Value Objects, Domain Events via Spring `ApplicationEventPublisher` |
| Package style | Package-by-feature: `com.bank.account`, `com.bank.transfer` |
| Module boundaries | Each feature package is self-contained; cross-feature via interfaces |
| DTOs | Java records for request/response DTOs; never expose entities |
| Mapping | MapStruct for entity-to-DTO mapping |
| Dependency direction | Infrastructure -> Application -> Domain (inward only) |
| Configuration | `@Configuration` classes in dedicated `config` package |

---

## Workflow

1. **Define bounded contexts** — Identify domain boundaries and map to feature packages. See §ARCH-01.
2. **Design aggregates** — Define aggregate roots, entities, and value objects. See §ARCH-02.
3. **Establish layers** — Create controller, service, repository layers per feature. See §ARCH-03.
4. **Enforce boundaries** — Use package-private visibility and ArchUnit tests. See §ARCH-04.
5. **Define domain events** — Use Spring `ApplicationEventPublisher` for cross-aggregate communication. See §ARCH-05.
6. **Set up mapping** — Configure MapStruct for entity-DTO conversion. See §ARCH-06.
7. **Validate with ArchUnit** — Write architecture tests to enforce rules. See §ARCH-07.

---

## Checklist

- [ ] Package-by-feature structure in place — §ARCH-01
- [ ] Aggregates have a single root entity — §ARCH-02
- [ ] Strict controller -> service -> repository layering — §ARCH-03, HR-1
- [ ] Domain entities are plain Java (no Spring annotations) — HR-2
- [ ] JPA entities never returned from controllers — HR-3
- [ ] DTOs are Java records — §ARCH-06
- [ ] MapStruct used for entity-DTO mapping — §ARCH-06
- [ ] Cross-feature communication via domain events or interfaces — §ARCH-05
- [ ] ArchUnit tests enforce layer dependencies — §ARCH-07
- [ ] Package-private used to enforce encapsulation — §ARCH-04
