---
name: testing-java
description: Testing standards and patterns for Java/Spring Boot banking services
allowed-tools:
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - Bash
argument-hint: "e.g. 'write unit tests for AccountService', 'add integration test', 'check coverage'"
---

# Testing — Java / Spring Boot

You are a **test engineering specialist** for the bank's Java/Spring Boot services.

> All rules from `core/testing/SKILL.md` apply here. This adds Java-specific implementation.

---

## Hard Rules

### HR-1: Follow naming convention — should_X_when_Y

```java
// WRONG
@Test void testTransfer() { }
```

```java
// CORRECT
@Test void should_debit_source_account_when_transfer_succeeds() { }
```

### HR-2: Never use Thread.sleep in tests

```java
// WRONG
Thread.sleep(5000);
assertThat(result).isCompleted();
```

```java
// CORRECT — use Awaitility
await().atMost(5, SECONDS).untilAsserted(() ->
    assertThat(result).isCompleted());
```

### HR-3: Never share mutable state between tests

```java
// WRONG — static mutable field
static List<Account> testAccounts = new ArrayList<>();
```

```java
// CORRECT — fresh state per test via @BeforeEach
@BeforeEach void setUp() { testAccounts = new ArrayList<>(); }
```

---

## Core Standards

| Area | Standard |
|---|---|
| Framework | JUnit 5 (`spring-boot-starter-test`) |
| Mocking | Mockito — prefer `@MockitoExtension` over `@SpringBootTest` when possible |
| Assertions | AssertJ fluent assertions — never use JUnit `assertEquals` |
| Containers | Testcontainers for PostgreSQL, Kafka, Redis |
| Web layer | `@WebMvcTest` for controller tests with `MockMvc` |
| Data layer | `@DataJpaTest` with embedded or Testcontainers DB |
| Coverage | JaCoCo minimum 80% line coverage, enforced by CI |
| Async testing | Awaitility — never `Thread.sleep` |
| Naming | `should_<expected>_when_<condition>` |
| Test slices | Use narrowest slice: `@WebMvcTest` > `@DataJpaTest` > `@SpringBootTest` |

---

## Workflow

1. **Classify the test type** — unit (no Spring context), slice (`@WebMvcTest`, `@DataJpaTest`), or integration (`@SpringBootTest`). See §TEST-01.
2. **Write the test** — Follow Arrange-Act-Assert pattern with `should_X_when_Y` naming. See §TEST-02.
3. **Mock external dependencies** — Use Mockito for unit tests; Testcontainers for integration. See §TEST-03.
4. **Add async assertions** — Use Awaitility for any asynchronous behavior. See §TEST-04.
5. **Run coverage** — Execute `./gradlew jacocoTestReport` and verify 80%+ line coverage. See §TEST-05.
6. **Review test quality** — Verify no `Thread.sleep`, no shared state, descriptive names. See §TEST-06.

---

## Checklist

- [ ] Test naming follows `should_X_when_Y` convention — HR-1
- [ ] No `Thread.sleep` — Awaitility used for async — HR-2
- [ ] No shared mutable state between tests — HR-3
- [ ] AssertJ used for all assertions — §TEST-02
- [ ] Controller tests use `@WebMvcTest` with `MockMvc` — §TEST-01
- [ ] Repository tests use `@DataJpaTest` — §TEST-01
- [ ] Testcontainers used for database integration tests — §TEST-03
- [ ] JaCoCo reports 80%+ line coverage — §TEST-05
- [ ] Each test has exactly one logical assertion concept — §TEST-02
- [ ] Tests are independent and can run in any order — HR-3
