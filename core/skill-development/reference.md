# Skill Development — Reference

Detailed reference material for authoring enterprise Copilot skills. See `SKILL.md` for core rules and workflow.

## Example SKILL.md — Core Skill (Language-Agnostic)

A core skill lives in `core/<name>/` and provides language-agnostic principles that apply across all stacks.

```markdown
---
name: error-handling
description: Error taxonomy, user-facing messages, retry/backoff, and circuit breaker patterns for bank services
allowed-tools: Read, Edit, Grep
argument-hint: "[service name] — e.g. 'payment-service', 'notification-service'"
---

# Error Handling

You are an error handling expert for bank services. When invoked, audit and fix error handling patterns against bank standards.

## Hard Rules

### Never expose internal errors to users

` ``
// WRONG — stack trace in API response
{ "error": "NullPointerException at PaymentService.java:42" }
// CORRECT — safe error with correlation ID
{ "type": "about:blank", "title": "Payment failed", "status": 500, "traceId": "abc-123" }
` ``

### Always use error codes from the bank taxonomy

| Category | Code Range | Example |
|----------|-----------|---------|
| Validation | 1000–1999 | 1001: Invalid IBAN format |
| Business | 2000–2999 | 2001: Insufficient funds |
| Infrastructure | 3000–3999 | 3001: Downstream timeout |

## Core Standards

| Area | Rule |
|------|------|
| API errors | RFC 7807 Problem Detail format |
| Retry | Exponential backoff, max 3 attempts |
| Circuit breaker | Open after 5 consecutive failures, half-open after 30s |
| Logging | Log full error internally, return safe message externally |
| Correlation | Every error response includes traceId |

## Workflow

1. Identify service error handling surface (API endpoints, async handlers, scheduled jobs)
2. Audit against Core Standards table
3. Fix violations, applying Hard Rules
4. Verify with checklist

## Checklist

- [ ] All API errors use RFC 7807 format
- [ ] No internal details in user-facing errors
- [ ] Retry with backoff on all network calls
- [ ] Circuit breaker on all downstream dependencies
- [ ] Error codes from bank taxonomy
- [ ] traceId in every error response

For full error code registry and circuit breaker config, read `core/error-handling/reference.md` § Error Code Registry.
```

**Line count:** ~60 lines. Well under 150 — ideal.

## Example SKILL.md — Stack Skill (Language-Specific)

A stack skill lives in `stacks/<lang>/<name>/` and provides implementation guidance for a specific language/framework.

```markdown
---
name: testing-java
description: JUnit 5, Mockito, Testcontainers, and Spring Boot Test patterns for bank Java services — coverage, naming, test data
allowed-tools: Read, Edit, Write, Glob, Grep, Bash
argument-hint: "[class or module name] — e.g. 'PaymentService', 'auth-module'"
---

# Testing — Java / Spring Boot

You are a testing expert for the bank's Java/Spring services. When invoked, generate or audit test suites following bank testing standards.

> Coverage thresholds and test pyramid rules from `core/testing/SKILL.md` apply here.

## Hard Rules

### Always use Testcontainers for database tests

` ``java
// WRONG — in-memory H2 diverges from production Postgres
@DataJpaTest
class AccountRepoTest { ... }
// CORRECT — real Postgres via Testcontainers
@Testcontainers
@DataJpaTest
class AccountRepoTest {
    @Container static PostgreSQLContainer<?> pg = new PostgreSQLContainer<>("postgres:15");
}
` ``

### Never use Thread.sleep in tests

` ``java
// WRONG
Thread.sleep(2000);
// CORRECT — use Awaitility
await().atMost(2, SECONDS).until(() -> service.isReady());
` ``

## Test Patterns

| Type | Framework | Location | Purpose |
|------|-----------|----------|---------|
| Unit | JUnit 5 + Mockito | `src/test/java/.../unit/` | Business logic isolation |
| Integration | Spring Boot Test + Testcontainers | `src/test/java/.../integration/` | Layer interaction |
| API | MockMvc / WebTestClient | `src/test/java/.../api/` | Controller contracts |
| E2E | RestAssured | `src/test/java/.../e2e/` | Full service flow |

## Naming Convention

` ``
should_<expected>_when_<condition>
` ``

Example: `should_rejectTransfer_when_insufficientFunds`

## Workflow

1. Identify class/module under test
2. Determine test types needed (unit, integration, API, E2E)
3. Generate tests following patterns table
4. Verify coverage meets 80% threshold
5. Run `mvn test` and fix failures

## Checklist

- [ ] Unit tests for all business logic
- [ ] Integration tests with Testcontainers (no H2)
- [ ] API tests for all endpoints
- [ ] Naming follows `should_X_when_Y` convention
- [ ] No Thread.sleep — uses Awaitility
- [ ] Coverage ≥ 80% (JaCoCo)

For full test templates, read `stacks/java/testing-java/reference.md` § Unit Test Template.
```

**Line count:** ~70 lines. Ideal range.

## Example reference.md

```markdown
# Testing — Java: Reference

## Unit Test Template

` ``java
@ExtendWith(MockitoExtension.class)
class PaymentServiceTest {

    @Mock PaymentRepository paymentRepo;
    @Mock NotificationService notificationService;
    @InjectMocks PaymentService paymentService;

    @Test
    void should_createPayment_when_validRequest() {
        // Arrange
        var request = new PaymentRequest("ACC-001", BigDecimal.valueOf(100));
        when(paymentRepo.save(any())).thenReturn(new Payment("PAY-001"));

        // Act
        var result = paymentService.create(request);

        // Assert
        assertThat(result.id()).isEqualTo("PAY-001");
        verify(notificationService).send(any());
    }

    @Test
    void should_rejectPayment_when_insufficientFunds() {
        var request = new PaymentRequest("ACC-001", BigDecimal.valueOf(999999));
        when(paymentRepo.findBalance("ACC-001")).thenReturn(BigDecimal.ZERO);

        assertThatThrownBy(() -> paymentService.create(request))
            .isInstanceOf(InsufficientFundsException.class)
            .hasMessageContaining("ACC-001");
    }
}
` ``

## Integration Test Template

` ``java
@SpringBootTest
@Testcontainers
@ActiveProfiles("test")
class PaymentIntegrationTest {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15")
        .withDatabaseName("testdb");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
    }

    @Autowired PaymentService paymentService;
    @Autowired PaymentRepository paymentRepo;

    @Test
    void should_persistPayment_when_created() {
        var request = new PaymentRequest("ACC-001", BigDecimal.valueOf(100));
        var result = paymentService.create(request);

        assertThat(paymentRepo.findById(result.id())).isPresent();
    }
}
` ``

## API Test Template

` ``java
@WebMvcTest(PaymentController.class)
class PaymentApiTest {

    @Autowired MockMvc mockMvc;
    @MockBean PaymentService paymentService;

    @Test
    void should_return201_when_validPayment() throws Exception {
        when(paymentService.create(any())).thenReturn(new Payment("PAY-001"));

        mockMvc.perform(post("/api/v1/payments")
                .contentType(APPLICATION_JSON)
                .content("""
                    {"accountId": "ACC-001", "amount": 100}
                    """))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.id").value("PAY-001"));
    }

    @Test
    void should_return400_when_missingAccountId() throws Exception {
        mockMvc.perform(post("/api/v1/payments")
                .contentType(APPLICATION_JSON)
                .content("""
                    {"amount": 100}
                    """))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.type").value("about:blank"))
            .andExpect(jsonPath("$.title").value("Validation failed"));
    }
}
` ``

## Coverage Configuration

### JaCoCo Maven Plugin

` ``xml
<plugin>
    <groupId>org.jacoco</groupId>
    <artifactId>jacoco-maven-plugin</artifactId>
    <version>0.8.11</version>
    <executions>
        <execution>
            <goals><goal>prepare-agent</goal></goals>
        </execution>
        <execution>
            <id>report</id>
            <phase>test</phase>
            <goals><goal>report</goal></goals>
        </execution>
        <execution>
            <id>check</id>
            <phase>verify</phase>
            <goals><goal>check</goal></goals>
            <configuration>
                <rules>
                    <rule>
                        <element>BUNDLE</element>
                        <limits>
                            <limit>
                                <counter>LINE</counter>
                                <value>COVEREDRATIO</value>
                                <minimum>0.80</minimum>
                            </limit>
                        </limits>
                    </rule>
                </rules>
            </configuration>
        </execution>
    </executions>
</plugin>
` ``

## Awaitility Patterns

` ``java
// Wait for async operation
await()
    .atMost(5, SECONDS)
    .pollInterval(100, MILLISECONDS)
    .until(() -> paymentRepo.findById("PAY-001").isPresent());

// Wait with assertion
await()
    .atMost(5, SECONDS)
    .untilAsserted(() ->
        assertThat(notificationService.getSent()).hasSize(1)
    );
` ``

## Test Data Builders

` ``java
public class PaymentRequestBuilder {
    private String accountId = "ACC-001";
    private BigDecimal amount = BigDecimal.valueOf(100);

    public static PaymentRequestBuilder aPaymentRequest() {
        return new PaymentRequestBuilder();
    }

    public PaymentRequestBuilder withAccountId(String accountId) {
        this.accountId = accountId;
        return this;
    }

    public PaymentRequestBuilder withAmount(BigDecimal amount) {
        this.amount = amount;
        return this;
    }

    public PaymentRequest build() {
        return new PaymentRequest(accountId, amount);
    }
}

// Usage in tests:
var request = aPaymentRequest()
    .withAccountId("ACC-002")
    .withAmount(BigDecimal.valueOf(500))
    .build();
` ``
```

## Naming Convention for Skill Directories

### Core skills

```
core/<topic>/
```

Topic names are singular, kebab-case: `security`, `testing`, `api-design`, `error-handling`.

### Stack skills

```
stacks/<language>/<topic>-<language>/
```

Examples:
- `stacks/java/security-java/`
- `stacks/flutter/accessibility-flutter/`
- `stacks/react/testing-react/`

The `<topic>` in the stack skill name matches the core skill it extends.

## Cross-Referencing Between Skills

### Core skill referencing another core skill

```markdown
> Logging rules from `core/observability/SKILL.md` § Hard Rules apply to error logging.
```

### Stack skill referencing its parent core skill

```markdown
> All rules from `core/security/SKILL.md` apply here. This skill adds Java-specific implementation guidance.
```

### Stack skill referencing another stack skill

```markdown
For test patterns, see `stacks/java/testing-java/SKILL.md` § Test Patterns.
```

### SKILL.md referencing its own reference.md

```markdown
For full code examples, read `stacks/java/testing-java/reference.md` § Unit Test Template.
```

## CI Validation Rules

The following CI checks run on every PR that modifies skills:

| Check | Script | Fails when |
|-------|--------|-----------|
| Frontmatter validation | `scripts/validate-frontmatter.sh` | Missing `name`, `description`, or `allowed-tools` |
| Name-directory match | `scripts/validate-frontmatter.sh` | `name` doesn't match parent directory |
| Line budget | `scripts/check-line-budget.sh` | SKILL.md > 500 lines |
| Structure check | `scripts/check-structure.sh` | Missing required sections (rules, workflow, checklist) |
| reference.md existence | CI workflow | Skill directory has no `reference.md` |
| Code block size | `scripts/check-codeblock-size.sh` | SKILL.md code block > 20 lines |
| Secrets scan | CI workflow | Detected API keys, passwords, tokens |

## Common Authoring Mistakes

| Mistake | Impact | Fix |
|---------|--------|-----|
| Writing Java examples in a core skill | Core skill unusable for React/Flutter teams | Use pseudocode or language-agnostic patterns |
| Duplicating security rules in testing skill | Bloats token usage, diverges over time | Reference: `See core/security/SKILL.md § Hard Rules` |
| Putting full class files in SKILL.md | 100+ lines consumed on every invocation | Move to reference.md, show 3–5 key lines in SKILL.md |
| Forgetting reference.md | CI fails, no deep-dive content | Always create both files |
| Using `license` instead of `allowed-tools` | Frontmatter validation fails | Follow schema: `name`, `description`, `allowed-tools` |
| Non-matching name and directory | CI fails | `name: testing-java` must be in `testing-java/` directory |
| Prose-heavy SKILL.md | Wastes tokens, hard to scan | Convert to tables, delete filler words |
