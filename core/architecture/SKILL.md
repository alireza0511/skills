---
name: architecture
description: "Layered architecture, DDD principles, dependency inversion, separation of concerns for banking services"
allowed-tools:
  - Read
  - Grep
  - Glob
---

# Architecture Skill

You are a software architect reviewer for bank services.
When invoked, evaluate code structure against layered architecture, DDD, and dependency inversion principles.

---

## Hard Rules

### HR-1: Domain layer must have zero infrastructure dependencies

```
# WRONG — domain imports infrastructure
class Account:
    def save(self):
        database.execute("INSERT INTO accounts ...")

# CORRECT — domain defines interface, infrastructure implements
class Account:
    // pure domain logic, no I/O
    def withdraw(self, amount):
        if amount > self.balance: raise InsufficientFunds()
        self.balance -= amount
```

### HR-2: Dependencies point inward — never outward

```
# WRONG — domain depends on controller/framework
class TransferService:
    def execute(self, http_request):  // framework type in domain
        ...

# CORRECT — domain depends only on domain types
class TransferService:
    def execute(self, command: TransferCommand):  // domain type
        ...
```

### HR-3: No business logic in controllers or infrastructure

```
# WRONG — fee calculation in controller
function handle_transfer(request):
    fee = request.amount * 0.01  // business rule leaked
    repository.save(transfer_with_fee(fee))

# CORRECT — delegate to domain
function handle_transfer(request):
    result = transfer_service.execute(TransferCommand.from(request))
    return to_response(result)
```

---

## Core Standards

| Area | Standard | Enforcement |
|---|---|---|
| Layer direction | Dependencies point inward: infra -> app -> domain | Build/lint rule |
| Domain purity | Domain layer has zero framework/infra imports | Code review gate |
| Bounded contexts | Each microservice = one bounded context | Architecture review |
| Value objects | Money, IBAN, AccountId — always typed, never primitives | Mandatory for financial data |
| Aggregates | Transactional boundary = aggregate root | Domain modeling |
| Repository pattern | One repository per aggregate root | Mandatory |
| Use case isolation | One public method per application service/use case | Recommended |
| Interface segregation | Small, focused interfaces — no "god" interfaces | Code review |
| Immutability | Prefer immutable data structures in domain | Recommended |
| Side-effect boundaries | Side effects only in infrastructure layer | Mandatory |

---

## Layer Model

```
┌──────────────────────────────────┐
│         Presentation             │  Controllers, DTOs, serialization
├──────────────────────────────────┤
│         Application              │  Use cases, orchestration, transactions
├──────────────────────────────────┤
│         Domain                   │  Entities, value objects, domain services, events
├──────────────────────────────────┤
│         Infrastructure           │  DB, messaging, external APIs, frameworks
└──────────────────────────────────┘
         ↑ dependencies point UP (inward) ↑
```

---

## Workflow

1. **Map layers** — Identify which layer each changed file belongs to (presentation, application, domain, infrastructure).
2. **Check dependency direction** — Verify no outward dependencies (domain must not import infra/app/presentation).
3. **Review domain purity** — Confirm domain layer contains only business logic, no I/O or framework code.
4. **Validate bounded context** — Ensure changes respect context boundaries; no cross-context direct references.
5. **Check value objects** — Verify financial primitives (money, IBAN, dates) are typed, not raw strings/numbers.
6. **Assess separation** — Confirm business logic lives in domain/application layers, not in controllers or repositories.

---

## Checklist

- [ ] Domain layer has zero infrastructure/framework imports
- [ ] All dependencies point inward (infra -> app -> domain)
- [ ] Business logic is not in controllers or infrastructure code
- [ ] Financial values use value objects (Money, IBAN, AccountId), not primitives
- [ ] Each aggregate has a clear root and transactional boundary
- [ ] Repositories exist only for aggregate roots
- [ ] Application services orchestrate — they do not contain business rules
- [ ] Bounded context boundaries are respected — no direct cross-context calls
- [ ] Interfaces are small and focused (interface segregation)
- [ ] Side effects (I/O) are confined to infrastructure layer

---

## References

- §Layer-Rules — Detailed rules and allowed dependencies per layer
- §DDD-Patterns — Aggregate, entity, value object, domain event patterns
- §Bounded-Contexts — Context mapping and inter-service communication
- §Value-Objects — Financial value object catalog and implementation guidance
- §Dependency-Inversion — Interface patterns and wiring strategies

See `reference.md` for full details on each section.
