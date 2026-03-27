# Architecture — Java / Spring Boot Reference

## §ARCH-01 Package-by-Feature Structure

```
src/main/java/com/bank/
├── account/
│   ├── controller/
│   │   └── AccountController.java
│   ├── service/
│   │   ├── AccountService.java
│   │   └── AccountServiceImpl.java
│   ├── repository/
│   │   └── AccountRepository.java
│   ├── domain/
│   │   ├── Account.java            (aggregate root)
│   │   ├── AccountStatus.java      (enum)
│   │   └── Money.java              (value object)
│   ├── dto/
│   │   ├── AccountResponse.java
│   │   └── CreateAccountRequest.java
│   ├── mapper/
│   │   └── AccountMapper.java
│   └── event/
│       └── AccountCreatedEvent.java
├── transfer/
│   ├── controller/
│   ├── service/
│   ├── repository/
│   ├── domain/
│   ├── dto/
│   └── event/
├── config/
│   ├── SecurityConfig.java
│   ├── JpaConfig.java
│   └── AsyncConfig.java
└── shared/
    ├── domain/
    │   ├── BaseEntity.java
    │   └── DomainEvent.java
    └── exception/
        ├── GlobalExceptionHandler.java
        └── ResourceNotFoundException.java
```

---

## §ARCH-02 DDD Aggregates and Value Objects

### Aggregate Root

```java
package com.bank.account.domain;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

@Entity
@Table(name = "accounts")
public class Account {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String iban;

    @Embedded
    private Money balance;

    @Enumerated(EnumType.STRING)
    private AccountStatus status;

    @OneToMany(mappedBy = "account", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<AccountTransaction> transactions = new ArrayList<>();

    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    protected Account() { } // JPA

    public Account(String iban, Money initialBalance) {
        this.iban = iban;
        this.balance = initialBalance;
        this.status = AccountStatus.ACTIVE;
        this.createdAt = Instant.now();
    }

    public void debit(Money amount) {
        if (this.status != AccountStatus.ACTIVE) {
            throw new AccountInactiveException(this.id);
        }
        if (this.balance.isLessThan(amount)) {
            throw new InsufficientFundsException(this.id, amount);
        }
        this.balance = this.balance.subtract(amount);
        this.transactions.add(AccountTransaction.debit(this, amount));
    }

    public void credit(Money amount) {
        if (this.status != AccountStatus.ACTIVE) {
            throw new AccountInactiveException(this.id);
        }
        this.balance = this.balance.add(amount);
        this.transactions.add(AccountTransaction.credit(this, amount));
    }

    public List<AccountTransaction> getTransactions() {
        return Collections.unmodifiableList(transactions);
    }

    // getters only — no setters for domain integrity
    public Long getId() { return id; }
    public String getIban() { return iban; }
    public Money getBalance() { return balance; }
    public AccountStatus getStatus() { return status; }
}
```

### Value Object

```java
package com.bank.account.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.math.BigDecimal;
import java.util.Objects;

@Embeddable
public class Money {

    @Column(name = "amount", nullable = false, precision = 19, scale = 4)
    private BigDecimal amount;

    @Column(name = "currency", nullable = false, length = 3)
    private String currency;

    protected Money() { } // JPA

    public Money(BigDecimal amount, String currency) {
        if (amount == null || currency == null || currency.length() != 3) {
            throw new IllegalArgumentException("Invalid money value");
        }
        this.amount = amount;
        this.currency = currency.toUpperCase();
    }

    public static Money eur(String amount) {
        return new Money(new BigDecimal(amount), "EUR");
    }

    public Money add(Money other) {
        assertSameCurrency(other);
        return new Money(this.amount.add(other.amount), this.currency);
    }

    public Money subtract(Money other) {
        assertSameCurrency(other);
        return new Money(this.amount.subtract(other.amount), this.currency);
    }

    public boolean isLessThan(Money other) {
        assertSameCurrency(other);
        return this.amount.compareTo(other.amount) < 0;
    }

    private void assertSameCurrency(Money other) {
        if (!this.currency.equals(other.currency)) {
            throw new CurrencyMismatchException(this.currency, other.currency);
        }
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Money money = (Money) o;
        return amount.compareTo(money.amount) == 0 && currency.equals(money.currency);
    }

    @Override
    public int hashCode() {
        return Objects.hash(amount.stripTrailingZeros(), currency);
    }
}
```

---

## §ARCH-03 Layered Architecture

### Controller Layer

```java
package com.bank.account.controller;

import com.bank.account.dto.AccountResponse;
import com.bank.account.dto.CreateAccountRequest;
import com.bank.account.service.AccountService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.net.URI;

@RestController
@RequestMapping("/api/v1/accounts")
public class AccountController {

    private final AccountService accountService;

    public AccountController(AccountService accountService) {
        this.accountService = accountService;
    }

    @GetMapping("/{id}")
    public ResponseEntity<AccountResponse> getAccount(@PathVariable Long id) {
        return ResponseEntity.ok(accountService.getAccount(id));
    }

    @PostMapping
    public ResponseEntity<AccountResponse> createAccount(
            @Valid @RequestBody CreateAccountRequest request) {
        AccountResponse created = accountService.createAccount(request);
        URI location = ServletUriComponentsBuilder.fromCurrentRequest()
            .path("/{id}").buildAndExpand(created.id()).toUri();
        return ResponseEntity.created(location).body(created);
    }
}
```

### Service Layer

```java
package com.bank.account.service;

import com.bank.account.domain.Account;
import com.bank.account.domain.Money;
import com.bank.account.dto.AccountResponse;
import com.bank.account.dto.CreateAccountRequest;
import com.bank.account.event.AccountCreatedEvent;
import com.bank.account.mapper.AccountMapper;
import com.bank.account.repository.AccountRepository;
import com.bank.shared.exception.ResourceNotFoundException;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional(readOnly = true)
public class AccountServiceImpl implements AccountService {

    private final AccountRepository accountRepository;
    private final AccountMapper accountMapper;
    private final ApplicationEventPublisher eventPublisher;

    public AccountServiceImpl(AccountRepository accountRepository,
                              AccountMapper accountMapper,
                              ApplicationEventPublisher eventPublisher) {
        this.accountRepository = accountRepository;
        this.accountMapper = accountMapper;
        this.eventPublisher = eventPublisher;
    }

    @Override
    public AccountResponse getAccount(Long id) {
        return accountRepository.findById(id)
            .map(accountMapper::toResponse)
            .orElseThrow(() -> new ResourceNotFoundException("Account", id));
    }

    @Override
    @Transactional
    public AccountResponse createAccount(CreateAccountRequest request) {
        Account account = new Account(
            request.iban(),
            new Money(request.initialBalance(), request.currency()));
        Account saved = accountRepository.save(account);
        eventPublisher.publishEvent(new AccountCreatedEvent(saved.getId(), saved.getIban()));
        return accountMapper.toResponse(saved);
    }
}
```

---

## §ARCH-04 Package-Private Encapsulation

```java
// Repository is package-private — only accessible within the account feature
package com.bank.account.repository;

import com.bank.account.domain.Account;
import org.springframework.data.jpa.repository.JpaRepository;

interface AccountRepository extends JpaRepository<Account, Long> {
    Optional<Account> findByIban(String iban);
}
```

```java
// Service interface is public — this is the feature's API
package com.bank.account.service;

public interface AccountService {
    AccountResponse getAccount(Long id);
    AccountResponse createAccount(CreateAccountRequest request);
}
```

---

## §ARCH-05 Domain Events

### Event Definition

```java
package com.bank.account.event;

public record AccountCreatedEvent(Long accountId, String iban) {}
```

### Event Listener in Another Feature

```java
package com.bank.notification.listener;

import com.bank.account.event.AccountCreatedEvent;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Component;

@Component
public class AccountNotificationListener {

    private final NotificationService notificationService;

    public AccountNotificationListener(NotificationService notificationService) {
        this.notificationService = notificationService;
    }

    @Async
    @EventListener
    public void onAccountCreated(AccountCreatedEvent event) {
        notificationService.sendWelcomeNotification(event.accountId());
    }
}
```

### Transactional Event Listener

```java
@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
public void onTransferCompleted(TransferCompletedEvent event) {
    auditService.recordTransfer(event);
}
```

---

## §ARCH-06 MapStruct DTO Mapping

### Gradle Dependency

```groovy
dependencies {
    implementation 'org.mapstruct:mapstruct:1.5.5.Final'
    annotationProcessor 'org.mapstruct:mapstruct-processor:1.5.5.Final'
}
```

### Mapper Interface

```java
package com.bank.account.mapper;

import com.bank.account.domain.Account;
import com.bank.account.dto.AccountResponse;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface AccountMapper {

    @Mapping(source = "balance.amount", target = "balance")
    @Mapping(source = "balance.currency", target = "currency")
    AccountResponse toResponse(Account account);
}
```

### DTO Record

```java
package com.bank.account.dto;

import java.math.BigDecimal;

public record AccountResponse(
    Long id,
    String iban,
    BigDecimal balance,
    String currency,
    String status
) {}
```

---

## §ARCH-07 ArchUnit Tests

### Gradle Dependency

```groovy
testImplementation 'com.tngtech.archunit:archunit-junit5:1.2.1'
```

### Architecture Test

```java
package com.bank;

import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;
import static com.tngtech.archunit.library.Architectures.layeredArchitecture;

@AnalyzeClasses(packages = "com.bank", importOptions = ImportOption.DoNotIncludeTests.class)
class ArchitectureTest {

    @ArchTest
    static final ArchRule layer_dependencies = layeredArchitecture()
        .consideringAllDependencies()
        .layer("Controller").definedBy("..controller..")
        .layer("Service").definedBy("..service..")
        .layer("Repository").definedBy("..repository..")
        .layer("Domain").definedBy("..domain..")
        .whereLayer("Controller").mayNotBeAccessedByAnyLayer()
        .whereLayer("Service").mayOnlyBeAccessedByLayers("Controller")
        .whereLayer("Repository").mayOnlyBeAccessedByLayers("Service");

    @ArchTest
    static final ArchRule controllers_should_not_access_repositories =
        noClasses().that().resideInAPackage("..controller..")
            .should().dependOnClassesThat().resideInAPackage("..repository..");

    @ArchTest
    static final ArchRule domain_should_not_depend_on_spring =
        noClasses().that().resideInAPackage("..domain..")
            .should().dependOnClassesThat()
            .resideInAPackage("org.springframework..");

    @ArchTest
    static final ArchRule controllers_should_only_return_dtos =
        classes().that().resideInAPackage("..controller..")
            .should().onlyDependOnClassesThat()
            .resideInAnyPackage("..controller..", "..service..", "..dto..",
                "org.springframework..", "jakarta..", "java..", "lombok..");
}
```
