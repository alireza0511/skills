# Architecture — Reference

## §Layer-Rules

### Allowed Dependencies per Layer

| Layer | May Depend On | Must Not Depend On |
|---|---|---|
| Presentation | Application, Domain | Infrastructure (directly) |
| Application | Domain | Presentation, Infrastructure (directly) |
| Domain | Nothing (self-contained) | All other layers |
| Infrastructure | Application, Domain (implements interfaces) | Presentation |

### Layer Responsibilities

| Layer | Contains | Does Not Contain |
|---|---|---|
| **Presentation** | Controllers, request/response DTOs, input validation (format only), serialization, routing | Business rules, DB queries, domain logic |
| **Application** | Use case orchestration, transaction boundaries, DTO mapping, authorization checks, event publishing | Business rules (delegate to domain), direct DB access, HTTP concerns |
| **Domain** | Entities, value objects, domain services, domain events, repository interfaces, domain exceptions | Framework code, annotations, I/O, logging, serialization |
| **Infrastructure** | Repository implementations, DB clients, message producers/consumers, external API clients, caching | Business rules, request handling, orchestration |

### Package/Module Structure

```
service-name/
├── presentation/        # or "api/", "web/", "controller/"
│   ├── controllers/
│   ├── dto/request/
│   ├── dto/response/
│   └── mappers/
├── application/         # or "usecase/", "service/"
│   ├── commands/
│   ├── queries/
│   ├── handlers/
│   └── dto/
├── domain/
│   ├── model/           # entities, aggregates
│   ├── value/           # value objects
│   ├── service/         # domain services
│   ├── event/           # domain events
│   ├── repository/      # interfaces only
│   └── exception/
└── infrastructure/      # or "adapter/", "infra/"
    ├── persistence/     # repository implementations
    ├── messaging/
    ├── external/        # third-party API clients
    └── config/
```

---

## §DDD-Patterns

### Aggregate Rules

| Rule | Detail |
|---|---|
| Single root | Each aggregate has exactly one root entity |
| Transactional boundary | One transaction = one aggregate |
| Reference by ID | Aggregates reference other aggregates by ID only, never direct object reference |
| Invariant protection | Aggregate root enforces all business invariants for its cluster |
| Size | Keep aggregates small — prefer fewer entities per aggregate |

### Banking Aggregate Examples

| Aggregate Root | Contains | Invariants |
|---|---|---|
| `Account` | Balance, AccountHolder reference (by ID), AccountStatus | Balance >= 0 (or >= overdraft limit); status transitions valid |
| `Transfer` | TransferStatus, Amount, SourceAccountId, TargetAccountId | Amount > 0; source != target; status transitions valid |
| `Customer` | Name, ContactInfo, KYC status | KYC must be verified before account creation |
| `LoanApplication` | RequestedAmount, Term, CreditScore, ApplicationStatus | Amount within product limits; valid status transitions |

### Entity vs. Value Object

| Characteristic | Entity | Value Object |
|---|---|---|
| Identity | Has unique ID | No identity — defined by attributes |
| Equality | Compared by ID | Compared by all attributes |
| Mutability | May have state changes | Always immutable |
| Lifecycle | Created, modified, persisted | Created, replaced (never modified) |
| Example | Account, Customer, Transfer | Money, IBAN, DateRange, Address |

### Domain Events

| Guideline | Detail |
|---|---|
| Naming | Past tense: `TransferCompleted`, `AccountOpened`, `LimitExceeded` |
| Content | Event carries all data needed by consumers — no callbacks to source |
| Immutability | Events are immutable once published |
| Ordering | Events within an aggregate are ordered |
| Idempotency | Consumers must handle duplicate events |

---

## §Bounded-Contexts

### Context Map for Banking

| Context | Owns | Communicates With |
|---|---|---|
| Account Management | Accounts, balances, statements | Transfers, Notifications |
| Transfers | Fund transfers, standing orders | Account Management, Compliance |
| Customer Onboarding | KYC, customer profiles | Account Management, Compliance |
| Compliance | AML checks, regulatory reporting | All contexts (read-only) |
| Notifications | Email, SMS, push delivery | Account Management, Transfers |
| Lending | Loans, credit scoring | Account Management, Compliance |

### Inter-Context Communication

| Pattern | Use When | Implementation |
|---|---|---|
| Domain events (async) | Eventual consistency acceptable | Message broker (default choice) |
| Synchronous API call | Strong consistency required | REST/gRPC with circuit breaker |
| Shared kernel | Two contexts co-evolve tightly | Shared library — minimize scope |
| Anti-corruption layer | Integrating with legacy/external system | Translator at boundary |

### Boundary Rules

- Never share database tables between bounded contexts.
- Never directly instantiate another context's domain objects.
- Translate at the boundary using anti-corruption layers or DTOs.
- Each context has its own deployment pipeline and data store.

---

## §Value-Objects

### Financial Value Object Catalog

| Value Object | Encapsulates | Validation Rules |
|---|---|---|
| `Money` | Amount (decimal) + Currency (ISO 4217) | Amount >= 0 (or explicitly signed); currency is valid ISO code; precision per currency |
| `IBAN` | Country code + check digits + BBAN | ISO 13616 format; modulo-97 checksum; country-specific length |
| `AccountId` | Internal account identifier | Non-empty; format matches bank scheme |
| `DateRange` | Start date + end date | Start <= end; both valid ISO 8601 dates |
| `Percentage` | Rate value | 0-100 range (or 0-1 depending on convention); explicit precision |
| `PhoneNumber` | Country code + number | E.164 format |
| `EmailAddress` | Email string | RFC 5322 format |
| `CurrencyCode` | ISO 4217 code | Must exist in approved currency list |

### Money Arithmetic Rules

| Operation | Rule |
|---|---|
| Addition | Same currency only; error on mismatch |
| Subtraction | Same currency only; decide on negative policy per context |
| Multiplication | By scalar only (e.g., interest rate); result rounds per currency rules |
| Division | By scalar only; use banker's rounding; handle remainder explicitly |
| Comparison | Same currency only |
| Storage | Use decimal/numeric DB types — never float |
| Serialization | String with explicit currency: `{"amount": "1234.56", "currency": "EUR"}` |

---

## §Dependency-Inversion

### Pattern

The domain layer defines interfaces. The infrastructure layer implements them. The application layer wires them together.

```
// Domain layer — defines the interface
interface AccountRepository:
    find_by_id(id: AccountId) -> Account?
    save(account: Account) -> void

// Infrastructure layer — implements the interface
class PostgresAccountRepository implements AccountRepository:
    find_by_id(id: AccountId) -> Account?:
        row = db.query("SELECT ... WHERE id = ?", id.value)
        return map_to_account(row)

// Application layer — depends on the interface, not the implementation
class TransferService:
    constructor(account_repo: AccountRepository):  // interface type
        self.account_repo = account_repo
```

### Wiring Strategies

| Strategy | Description | When to Use |
|---|---|---|
| Constructor injection | Pass dependencies via constructor | Default choice — most testable |
| Framework DI container | Container resolves and injects | Large applications with many dependencies |
| Factory/provider | Factory creates objects with dependencies | When creation logic is complex |
| Manual wiring | Explicit wiring in composition root | Small services, no framework DI available |

### Benefits for Banking

| Benefit | Detail |
|---|---|
| Testability | Domain and application layers testable without DB/network |
| Swappability | Switch DB, message broker, or external provider without domain changes |
| Compliance | Domain rules isolated and auditable |
| Team autonomy | Infrastructure team and domain team work independently |
