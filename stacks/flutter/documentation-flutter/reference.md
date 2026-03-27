# Documentation Flutter — Reference

## §Doc-Comment-Style

### Dart Doc Comment Syntax

```dart
/// A single-line summary of the class or member.
///
/// Additional details in subsequent paragraphs. Use blank `///` lines
/// to separate paragraphs.
///
/// Use [OtherClass] to reference other types. Use [methodName] to
/// reference members within the same class.
///
/// ## Sections
///
/// Use markdown headers for major sections within longer docs.
///
/// ## Example
///
/// ```dart
/// final result = MyClass().doSomething();
/// ```
class MyClass {}
```

### Do's and Don'ts

| Do | Don't |
|---|---|
| Use `///` for all doc comments | Use `/** */` block comments |
| Start with a single-sentence summary | Start with "This class..." |
| Use `[BracketRef]` for type references | Use `@param`, `@return`, `@see` |
| Write in third person: "Returns the..." | Write in imperative: "Return the..." |
| Document the "why", not just the "what" | Restate the method signature in prose |
| Include code examples for complex APIs | Leave complex usage undocumented |

### Summary Line Rules

```dart
// WRONG — starts with article, too vague
/// A class for transfers.
class TransferService {}

// WRONG — restates the obvious
/// The TransferService class.
class TransferService {}

// CORRECT — concise, informative
/// Orchestrates fund transfers between bank accounts.
///
/// Validates business rules, executes the transfer via [TransferRepository],
/// and emits domain events for downstream processing.
class TransferService {}
```

---

## §Method-Docs

### Method Documentation Pattern

```dart
/// Executes a fund transfer from [fromAccount] to [toAccount].
///
/// Validates that the source account has sufficient funds and that
/// the transfer does not exceed daily limits.
///
/// Returns a [Result] containing the [Transfer] on success, or an
/// [AppError] with one of:
/// - [InsufficientFundsException] — balance too low
/// - [TransferLimitExceededException] — daily limit reached
/// - [AccountFrozenException] — source or target account is frozen
///
/// The [idempotencyKey] prevents duplicate transfers if the request
/// is retried due to network failures.
///
/// ```dart
/// final result = await transferService.execute(
///   fromAccount: AccountId('ACC-001'),
///   toAccount: AccountId('ACC-002'),
///   amount: Money(150000, 'USD'), // $1,500.00
///   idempotencyKey: uuid.v4(),
/// );
/// result.when(
///   success: (transfer) => print('Transfer ${transfer.id} completed'),
///   failure: (error) => print('Failed: ${error.userMessage}'),
/// );
/// ```
Future<Result<Transfer>> execute({
  required AccountId fromAccount,
  required AccountId toAccount,
  required Money amount,
  required String idempotencyKey,
});
```

### Getter/Property Documentation

```dart
/// Whether the account is eligible for instant transfers.
///
/// Returns `true` if the account is active, verified, and has been
/// open for at least 30 days. See [AccountEligibility] for full rules.
bool get isEligibleForInstantTransfer;

/// The masked account number (e.g., "****4521").
///
/// Always use this for display. Never expose [fullAccountNumber]
/// in the UI layer.
String get maskedAccountNumber;
```

---

## §Widget-Docs

### Reusable Widget Documentation

```dart
/// Displays a bank account summary card with balance and account type.
///
/// Shows the account name, masked account number, available balance,
/// and account type icon. Tapping the card navigates to account detail.
///
/// ## Usage
///
/// ```dart
/// AccountSummaryCard(
///   account: Account(
///     name: 'Checking Account',
///     number: AccountNumber('1234567890'),
///     balance: Money(520050, 'USD'),
///     type: AccountType.checking,
///   ),
///   onTap: () => context.go('/accounts/${account.id}'),
/// )
/// ```
///
/// ## States
///
/// The card handles three visual states:
/// - **Normal** — displays balance and account info
/// - **Frozen** — displays frozen indicator with muted colors
/// - **Loading** — displays shimmer placeholder
///
/// ## Accessibility
///
/// The card merges all child semantics into a single announcement:
/// "Checking Account ending in 7890, balance $5,200.50"
///
/// See also:
/// - [AccountDetailScreen] — full account detail view
/// - [AccountListScreen] — screen that hosts multiple cards
class AccountSummaryCard extends StatelessWidget {
  /// The account data to display.
  final Account account;

  /// Called when the user taps the card.
  ///
  /// Typically navigates to [AccountDetailScreen].
  final VoidCallback? onTap;

  /// Creates an account summary card.
  const AccountSummaryCard({
    required this.account,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) { /* ... */ }
}
```

### Enum Documentation

```dart
/// The status of a fund transfer.
///
/// Transitions follow this flow:
/// ```
/// pending → processing → completed
///                      → failed
///                      → cancelled
/// ```
enum TransferStatus {
  /// Transfer has been submitted but not yet processed.
  pending,

  /// Transfer is being processed by the payment system.
  processing,

  /// Transfer completed successfully. Funds have been moved.
  completed,

  /// Transfer failed. See [Transfer.failureReason] for details.
  failed,

  /// Transfer was cancelled by the user before processing.
  cancelled,
}
```

---

## §BLoC-Docs

### Event Documentation

```dart
/// Events that drive the [TransferBloc] state machine.
///
/// ## Event Flow
///
/// 1. [TransferFormUpdated] — user edits form fields
/// 2. [TransferValidated] — form passes client-side validation
/// 3. [TransferSubmitted] — user confirms the transfer
/// 4. [TransferReset] — user starts a new transfer
sealed class TransferEvent {}

/// Emitted when the user updates a form field.
///
/// Triggers validation of the changed field and updates
/// [TransferState.formData].
final class TransferFormUpdated extends TransferEvent {
  /// The field that was updated.
  final String fieldName;

  /// The new value of the field.
  final String value;

  TransferFormUpdated({required this.fieldName, required this.value});
}

/// Emitted when the user submits the transfer for processing.
///
/// Triggers the full transfer flow:
/// 1. Server-side validation
/// 2. Biometric authentication (if required)
/// 3. Transfer execution via [TransferUseCase]
///
/// On success, state transitions to [TransferStatus.success].
/// On failure, state transitions to [TransferStatus.failure]
/// with [TransferState.error] populated.
final class TransferSubmitted extends TransferEvent {}
```

### State Documentation

```dart
/// The state of the transfer flow managed by [TransferBloc].
///
/// Contains form data, validation results, and transfer outcome.
/// States are immutable — use [copyWith] to create new instances.
///
/// ## Key Properties
///
/// - [status] — current step in the flow
/// - [formData] — current form field values
/// - [error] — populated when [status] is [TransferStatus.failure]
/// - [result] — populated when [status] is [TransferStatus.success]
class TransferState extends Equatable {
  /// The current status of the transfer flow.
  final TransferStatus status;

  /// Form field values, keyed by field name.
  final Map<String, String> formData;

  /// Validation errors, keyed by field name.
  ///
  /// Empty when all fields are valid.
  final Map<String, String> validationErrors;

  /// The error that caused the transfer to fail.
  ///
  /// Only populated when [status] is [TransferStatus.failure].
  final AppError? error;

  /// The successful transfer result.
  ///
  /// Only populated when [status] is [TransferStatus.success].
  final TransferResult? result;

  // ... constructor, copyWith, props
}
```

---

## §Dartdoc-Setup

### Generating Documentation

```bash
# Generate dartdoc for the project
dart doc .

# Serve locally for review
dart doc . && cd doc/api && python3 -m http.server 8080
```

### dartdoc Options (dartdoc_options.yaml)

```yaml
dartdoc:
  categories:
    "Features":
      markdown: doc/features.md
    "Core":
      markdown: doc/core.md
  exclude:
    - "**.g.dart"
    - "**.freezed.dart"
  showUndocumentedCategories: false
```

### CI Dartdoc Validation

```yaml
# In CI pipeline
- name: Validate documentation
  run: |
    dart doc . 2>&1 | tee dartdoc_output.txt
    if grep -q "warning" dartdoc_output.txt; then
      echo "Dartdoc warnings found — fix before merging"
      exit 1
    fi
```

---

## §Deprecation

### Deprecation Patterns

```dart
/// Use [TransferBloc] instead.
///
/// Migration:
/// ```dart
/// // Before
/// final service = TransferService();
/// final result = await service.execute(cmd);
///
/// // After
/// context.read<TransferBloc>().add(TransferSubmitted(cmd));
/// ```
@Deprecated('Use TransferBloc instead. Will be removed in v4.0.0')
class TransferService {
  // ...
}

/// Use [Money.fromMinorUnits] instead.
@Deprecated('Use Money.fromMinorUnits(). Removed in v3.0.0')
factory Money.fromDouble(double amount, String currency) =>
    Money((amount * 100).round(), currency);
```

### Deprecation Rules

| Rule | Detail |
|---|---|
| Always specify replacement | "Use [NewThing] instead" |
| Always specify removal version | "Will be removed in v4.0.0" |
| Include migration example | Show before/after code in doc comment |
| Keep for 2 minor versions | Deprecated in 3.1, remove in 3.3 |
| Add analyzer warning | `@Deprecated` triggers lint warning |
