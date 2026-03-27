---
name: testing
description: "Test pyramid, coverage thresholds, naming conventions, test data management for banking services"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Edit
  - Bash
---

# Testing Skill

You are a test quality reviewer for bank services.
When invoked, evaluate test coverage, structure, naming, and data management against bank testing standards.

---

## Hard Rules

### HR-1: Never use production data in tests

```
# WRONG
test_user = fetch_from_prod_db("customer_12345")

# CORRECT
test_user = create_test_fixture("customer", name="Jane Doe", account="0000000001")
```

### HR-2: Tests must be deterministic — no flaky tests in main

```
# WRONG
assert response_time < 100ms  // flaky — depends on system load

# CORRECT
assert response.status == 200
assert response.body.account_id == expected_id
```

### HR-3: Test the behavior, not the implementation

```
# WRONG
assert mock_repository.save.called_with(internal_dto)

# CORRECT
result = transfer_funds(from="A", to="B", amount=100)
assert result.status == "completed"
assert get_balance("A") == original_balance - 100
```

---

## Core Standards

| Area | Standard | Threshold |
|---|---|---|
| Unit test coverage | Line coverage minimum | 80% |
| Branch coverage | Branch coverage minimum | 75% |
| Integration tests | Cover all external boundaries | Every adapter/client |
| E2E tests | Cover critical user journeys | All P0 flows |
| Test naming | `<unit>_<scenario>_<expected>` pattern | Mandatory |
| Test isolation | No shared mutable state between tests | Mandatory |
| Test data | Synthetic only — never production PII | Mandatory |
| Flaky tests | Zero tolerance on main branch | Quarantine + fix within 48h |
| Test execution | All unit tests pass in < 5 min | Mandatory |
| Mutation testing | Mutation score for critical financial logic | 70% minimum |

---

## Test Pyramid

```
         /  E2E  \          ~5%   — Critical user journeys only
        /----------\
       / Integration \      ~15%  — API boundaries, DB, external services
      /----------------\
     /      Unit        \   ~80%  — Business logic, domain rules, utilities
    /--------------------\
```

| Layer | Scope | Speed | Isolation | Bank-Critical Focus |
|---|---|---|---|---|
| Unit | Single function/class | < 10ms each | Full — no I/O | Calculations, validation, domain rules |
| Integration | Component boundaries | < 5s each | Partial — real DB/mocks | Repository queries, API clients, message handling |
| E2E | Full user journey | < 60s each | None — real env | Login, transfer, statement download |
| Contract | API compatibility | < 5s each | Provider/consumer stubs | Service-to-service interfaces |

---

## Workflow

1. **Assess coverage** — Check current coverage metrics against thresholds (80% line, 75% branch).
2. **Review pyramid balance** — Verify test distribution follows 80/15/5 unit/integration/E2E ratio.
3. **Check naming** — Validate all tests follow `<unit>_<scenario>_<expected>` convention.
4. **Verify isolation** — Confirm no shared state, no test ordering dependencies, no I/O in unit tests.
5. **Audit test data** — Ensure synthetic data only; no PII, no production data references.
6. **Review assertions** — Confirm tests assert behavior (outputs/state), not implementation details.
7. **Check critical paths** — Verify all financial calculations and security logic have mutation testing.

---

## Checklist

- [ ] Line coverage >= 80%, branch coverage >= 75%
- [ ] All test names follow `<unit>_<scenario>_<expected>` pattern
- [ ] Test pyramid ratio approximately 80/15/5 (unit/integration/E2E)
- [ ] No production data or real PII in test fixtures
- [ ] Unit tests have zero I/O — all dependencies mocked/stubbed
- [ ] Integration tests clean up after themselves (no leaked state)
- [ ] No flaky tests — all tests are deterministic
- [ ] Financial calculations have mutation testing (>= 70% score)
- [ ] E2E tests cover all P0 critical journeys
- [ ] Tests assert behavior, not implementation internals
- [ ] Test suite completes within CI time budget (unit < 5 min)
- [ ] Edge cases covered: zero amounts, max values, boundary dates, unicode input

---

## References

- §Test-Naming — Full naming convention with examples
- §Test-Data — Synthetic data generation and fixture management
- §Pyramid-Guidelines — Detailed guidance for each test layer
- §Mutation-Testing — Setup and threshold guidance for financial logic
- §Flaky-Tests — Detection, quarantine, and resolution process

See `reference.md` for full details on each section.
