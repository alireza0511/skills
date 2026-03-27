# Testing — Reference

## §Test-Naming

### Convention: `<unit>_<scenario>_<expected>`

| Part | Description | Example |
|---|---|---|
| `<unit>` | Function, method, or class under test | `transfer_funds` |
| `<scenario>` | Input condition or context | `when_insufficient_balance` |
| `<expected>` | Expected outcome | `returns_error` |

### Full Examples

| Test Name | What It Tests |
|---|---|
| `transfer_funds_when_insufficient_balance_returns_error` | Overdraft prevention |
| `calculate_interest_with_zero_balance_returns_zero` | Edge case handling |
| `validate_iban_with_invalid_checksum_rejects_input` | Input validation |
| `create_account_with_valid_data_persists_and_returns_id` | Happy path |
| `session_after_15min_idle_expires_and_redirects` | Security timeout |
| `parse_amount_with_locale_comma_decimal_parses_correctly` | Internationalization |

### Anti-Patterns

| Bad Name | Problem | Better Name |
|---|---|---|
| `test1` | No meaning | `calculate_fee_with_zero_amount_returns_zero` |
| `testTransfer` | No scenario or expectation | `transfer_funds_to_same_account_rejects_request` |
| `it_works` | No specificity | `validate_iban_with_valid_de_format_accepts_input` |
| `should_not_fail` | Negative, vague | `process_payment_with_valid_card_succeeds` |

---

## §Test-Data

### Principles

1. **Synthetic only** — All test data is generated. Never copy from production.
2. **Deterministic** — Same seed produces same data. No random values without fixed seeds.
3. **Minimal** — Create only what the test requires. No "kitchen sink" fixtures.
4. **Self-contained** — Each test sets up its own data or uses shared immutable fixtures.
5. **PII-free** — Use obviously fake data: "Jane Doe", "0000000001", "test@example.com".

### Synthetic Data Patterns

| Data Type | Generator Pattern | Example Output |
|---|---|---|
| Account number | Sequential with prefix | `TEST-0000000001` |
| IBAN | Valid format, test prefix | `DE89370400440532013000` (known test IBAN) |
| Currency amount | Fixed decimals | `1234.56` |
| Customer name | Fake name library | `Jane Doe`, `John Smith` |
| Date | Relative to test execution | `today - 30 days` |
| Email | Test domain | `jane.doe@test.example.com` |
| Phone | Fake prefix | `+1-555-0100` (reserved test range) |

### Fixture Management

| Pattern | Use Case | Example |
|---|---|---|
| Builder/Factory | Complex domain objects | `AccountBuilder().with_balance(1000).with_currency("EUR").build()` |
| Fixture file | Static reference data | `test/fixtures/currency_codes.json` |
| Database seed | Integration test baseline | `test/seeds/base_accounts.sql` — run before each test suite |
| Snapshot | Response format validation | `test/snapshots/transfer_response.json` |

### Test Data Cleanup

| Test Layer | Cleanup Strategy |
|---|---|
| Unit | No cleanup needed — no I/O |
| Integration | Transaction rollback after each test, or truncate tables |
| E2E | Dedicated test environment with reset between suites |
| Shared DB | Each test uses unique identifiers; cleanup in teardown |

---

## §Pyramid-Guidelines

### Unit Tests (80% of tests)

**Scope**: Single function, method, or class in isolation.

| Rule | Detail |
|---|---|
| No I/O | No database, network, filesystem, clock |
| Fast | Each test < 10ms; entire unit suite < 5 min |
| Isolated | Mock/stub all dependencies |
| Focused | One assertion concept per test (multiple asserts OK if testing one behavior) |
| Coverage | Target 80% line, 75% branch on business logic |

**What to unit test in banking**:
- Interest calculations
- Fee computations
- Input validation rules
- Currency conversion logic
- Account state transitions
- Date/period calculations
- Formatting functions (amounts, IBANs, dates)

### Integration Tests (15% of tests)

**Scope**: Component boundaries — DB queries, API clients, message handlers.

| Rule | Detail |
|---|---|
| Real dependencies | Use real database (test instance), real message broker (test topic) |
| Isolated per test | Each test gets clean state |
| Contract focus | Verify correct queries, serialization, error handling at boundaries |
| Timeout | Each test < 5s |

**What to integration test in banking**:
- Repository queries (especially financial queries with decimal precision)
- External API client behavior (payment gateways, credit bureaus)
- Message producer/consumer contracts
- Cache behavior
- Database migration correctness

### E2E Tests (5% of tests)

**Scope**: Full user journey through the real system.

| Rule | Detail |
|---|---|
| P0 flows only | Only critical banking journeys |
| Stable selectors | Use data-testid attributes, not CSS classes |
| Retry logic | Handle transient network issues; max 2 retries |
| Timeout | Each test < 60s |

**Required P0 banking E2E tests**:
- Customer login (with MFA)
- View account balance and transactions
- Initiate and confirm a fund transfer
- Download account statement
- Update personal details
- Logout and session expiry

### Contract Tests

**Scope**: API compatibility between services.

| Rule | Detail |
|---|---|
| Consumer-driven | Consumer defines expected contract |
| Provider verifies | Provider CI runs consumer contracts |
| Version-aware | Contracts tagged per consumer version |
| Breaking change gate | Failing contract test blocks deployment |

---

## §Mutation-Testing

### What Is Mutation Testing

Mutation testing modifies (mutates) source code and checks whether tests detect the change. Surviving mutants indicate weak tests.

### When Required

| Code Category | Mutation Testing Required | Minimum Score |
|---|---|---|
| Financial calculations | Yes | 70% |
| Authentication/authorization logic | Yes | 70% |
| Input validation | Yes | 70% |
| Rate/fee computation | Yes | 70% |
| General business logic | Recommended | 60% |
| UI rendering | No | — |
| Configuration | No | — |

### Common Mutation Categories

| Mutation Type | Example | Risk if Undetected |
|---|---|---|
| Arithmetic operator | `+` changed to `-` | Wrong calculation |
| Comparison boundary | `>=` changed to `>` | Off-by-one in limits |
| Conditional negation | `if valid` changed to `if !valid` | Logic inversion |
| Return value | Return `true` always | Bypassed validation |
| Void method removal | Delete method call | Skipped side effect |

---

## §Flaky-Tests

### Definition

A flaky test is one that produces different results (pass/fail) on the same code without any changes.

### Common Causes in Banking Systems

| Cause | Example | Fix |
|---|---|---|
| Time dependency | Test assumes "today" is a specific date | Inject clock; use relative dates |
| Ordering dependency | Test relies on another test running first | Ensure independent setup |
| Shared state | Two tests modify the same DB row | Isolate data per test |
| Async timing | Assertion before async operation completes | Use explicit waits/polling, not sleep |
| External dependency | Test calls live third-party API | Mock external services |
| Floating point | `0.1 + 0.2 != 0.3` | Use decimal types for money; epsilon comparison |
| Resource contention | Port conflict, file lock | Use dynamic ports; unique temp dirs |

### Quarantine Process

1. **Detect** — CI flags test as flaky (passed on retry, or failed without code change).
2. **Quarantine** — Move to quarantine suite within 24 hours. Quarantine runs separately, does not block deployments.
3. **Investigate** — Assigned developer diagnoses root cause within 48 hours.
4. **Fix or remove** — Fix the root cause and return to main suite, or delete if test has no value.
5. **Track** — Log flaky test incidents for trend analysis. Target: zero quarantined tests.
