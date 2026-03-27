# Architecture Flutter — Reference

## §BLoC-Pattern

### BLoC Structure

```dart
// Events — one sealed class per feature
sealed class TransferEvent {}

final class TransferSubmitted extends TransferEvent {
  final String fromAccount;
  final String toAccount;
  final Money amount;

  TransferSubmitted({
    required this.fromAccount,
    required this.toAccount,
    required this.amount,
  });
}

final class TransferReset extends TransferEvent {}

// States — immutable with equatable
final class TransferState extends Equatable {
  final TransferStatus status;
  final String? errorMessage;
  final TransferResult? result;

  const TransferState({
    this.status = TransferStatus.initial,
    this.errorMessage,
    this.result,
  });

  TransferState copyWith({
    TransferStatus? status,
    String? errorMessage,
    TransferResult? result,
  }) =>
      TransferState(
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
        result: result ?? this.result,
      );

  @override
  List<Object?> get props => [status, errorMessage, result];
}

enum TransferStatus { initial, loading, success, failure }
```

### BLoC Implementation

```dart
class TransferBloc extends Bloc<TransferEvent, TransferState> {
  final TransferUseCase _transferUseCase;

  TransferBloc({required TransferUseCase transferUseCase})
      : _transferUseCase = transferUseCase,
        super(const TransferState()) {
    on<TransferSubmitted>(_onSubmitted);
    on<TransferReset>(_onReset);
  }

  Future<void> _onSubmitted(
    TransferSubmitted event,
    Emitter<TransferState> emit,
  ) async {
    emit(state.copyWith(status: TransferStatus.loading));

    final result = await _transferUseCase.execute(
      TransferCommand(
        fromAccount: event.fromAccount,
        toAccount: event.toAccount,
        amount: event.amount,
      ),
    );

    result.when(
      success: (data) => emit(state.copyWith(
        status: TransferStatus.success,
        result: data,
      )),
      failure: (error) => emit(state.copyWith(
        status: TransferStatus.failure,
        errorMessage: error.userMessage,
      )),
    );
  }

  void _onReset(TransferReset event, Emitter<TransferState> emit) {
    emit(const TransferState());
  }
}
```

### BLoC Consumer in Widget

```dart
class TransferScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TransferBloc>(),
      child: BlocConsumer<TransferBloc, TransferState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.status == TransferStatus.success) {
            context.go('/transfer/confirmation/${state.result!.id}');
          }
          if (state.status == TransferStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Transfer failed')),
            );
          }
        },
        builder: (context, state) {
          if (state.status == TransferStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return TransferForm(
            onSubmit: (from, to, amount) {
              context.read<TransferBloc>().add(
                TransferSubmitted(fromAccount: from, toAccount: to, amount: amount),
              );
            },
          );
        },
      ),
    );
  }
}
```

### BLoC Testing

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransferUseCase extends Mock implements TransferUseCase {}

void main() {
  late MockTransferUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockTransferUseCase();
    registerFallbackValue(TransferCommand.empty());
  });

  blocTest<TransferBloc, TransferState>(
    'emits [loading, success] when transfer succeeds',
    build: () {
      when(() => mockUseCase.execute(any()))
          .thenAnswer((_) async => Result.success(TransferResult(id: 'tx-1')));
      return TransferBloc(transferUseCase: mockUseCase);
    },
    act: (bloc) => bloc.add(TransferSubmitted(
      fromAccount: 'A', toAccount: 'B', amount: Money(1000, 'USD'),
    )),
    expect: () => [
      const TransferState(status: TransferStatus.loading),
      isA<TransferState>()
          .having((s) => s.status, 'status', TransferStatus.success)
          .having((s) => s.result?.id, 'result.id', 'tx-1'),
    ],
  );
}
```

---

## §Clean-Layers

### Allowed Imports per Layer

| Layer | Can Import | Cannot Import |
|---|---|---|
| Presentation (widgets) | Application, Domain, Flutter SDK | Data layer directly |
| Application (BLoC) | Domain | Flutter SDK, Data layer |
| Domain (entities, use cases) | Dart core only | Flutter, Application, Data |
| Data (repositories, sources) | Domain (interfaces) | Presentation, Application |

### Domain Layer Example

```dart
// lib/features/transfer/domain/entities/transfer.dart
// Pure Dart — no Flutter imports

class Transfer {
  final TransferId id;
  final AccountId fromAccount;
  final AccountId toAccount;
  final Money amount;
  final TransferStatus status;
  final DateTime createdAt;

  const Transfer({
    required this.id,
    required this.fromAccount,
    required this.toAccount,
    required this.amount,
    required this.status,
    required this.createdAt,
  });
}

// lib/features/transfer/domain/repositories/transfer_repository.dart
abstract interface class TransferRepository {
  Future<Result<Transfer>> execute(TransferCommand command);
  Future<Result<List<Transfer>>> getHistory(AccountId accountId);
}
```

### Data Layer Implementation

```dart
// lib/features/transfer/data/repositories/transfer_repository_impl.dart
class TransferRepositoryImpl implements TransferRepository {
  final TransferRemoteDataSource _remote;
  final TransferLocalDataSource _local;

  TransferRepositoryImpl({
    required TransferRemoteDataSource remote,
    required TransferLocalDataSource local,
  })  : _remote = remote,
        _local = local;

  @override
  Future<Result<Transfer>> execute(TransferCommand command) async {
    try {
      final dto = TransferRequestDto.fromCommand(command);
      final response = await _remote.postTransfer(dto);
      final transfer = response.toDomain();
      await _local.cacheTransfer(transfer);
      return Result.success(transfer);
    } on DioException catch (e) {
      return Result.failure(e.toAppError());
    }
  }
}
```

---

## §Router-Setup

### go_router Configuration

```dart
// lib/app/router.dart
import 'package:go_router/go_router.dart';

final goRouter = GoRouter(
  initialLocation: '/login',
  redirect: _authGuard,
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/accounts/:accountId',
          name: 'accountDetail',
          builder: (context, state) => AccountDetailScreen(
            accountId: state.pathParameters['accountId']!,
          ),
        ),
        GoRoute(
          path: '/transfer',
          name: 'transfer',
          builder: (context, state) => const TransferScreen(),
          routes: [
            GoRoute(
              path: 'confirmation/:transferId',
              name: 'transferConfirmation',
              builder: (context, state) => TransferConfirmationScreen(
                transferId: state.pathParameters['transferId']!,
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);

// Auth guard
String? _authGuard(BuildContext context, GoRouterState state) {
  final isAuthenticated = getIt<AuthService>().isAuthenticated;
  final isLoginRoute = state.matchedLocation == '/login';

  if (!isAuthenticated && !isLoginRoute) return '/login';
  if (isAuthenticated && isLoginRoute) return '/dashboard';
  return null;
}
```

---

## §Folder-Structure

### Feature-First Organization

```
lib/
├── app/
│   ├── app.dart                    # MaterialApp widget
│   ├── router.dart                 # go_router configuration
│   └── di.dart                     # get_it registration
├── core/
│   ├── error/                      # Error types, Result class
│   ├── network/                    # Dio client, interceptors
│   ├── theme/                      # BankTheme, colors, typography
│   ├── widgets/                    # Shared widgets (buttons, cards)
│   └── extensions/                 # Dart extensions
├── features/
│   ├── auth/
│   │   ├── presentation/           # LoginScreen, widgets
│   │   ├── application/            # AuthBloc
│   │   ├── domain/                 # AuthRepository interface, User entity
│   │   └── data/                   # AuthRepositoryImpl, DTOs, data sources
│   ├── dashboard/
│   │   ├── presentation/
│   │   ├── application/
│   │   ├── domain/
│   │   └── data/
│   ├── transfer/
│   │   ├── presentation/
│   │   ├── application/
│   │   ├── domain/
│   │   └── data/
│   └── accounts/
│       ├── presentation/
│       ├── application/
│       ├── domain/
│       └── data/
└── main.dart
```

### Rules

| Rule | Detail |
|---|---|
| Feature independence | Features must not import from other features directly |
| Cross-feature communication | Through domain events or shared interfaces in `core/` |
| Shared code | Lives in `core/` — never in a feature folder |
| One BLoC per feature | `application/` contains exactly one BLoC or Cubit |
| Barrel exports | Each feature exposes a single barrel file for its public API |

---

## §DI-Setup

### get_it Registration

```dart
// lib/app/di.dart
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  // Core
  getIt.registerLazySingleton<Dio>(() => SecureApiClient.create());

  // Auth feature
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSource(dio: getIt()),
  );
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remote: getIt()),
  );
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(repository: getIt()),
  );

  // Transfer feature
  getIt.registerLazySingleton<TransferRemoteDataSource>(
    () => TransferRemoteDataSource(dio: getIt()),
  );
  getIt.registerLazySingleton<TransferRepository>(
    () => TransferRepositoryImpl(remote: getIt(), local: getIt()),
  );
  getIt.registerLazySingleton<TransferUseCase>(
    () => TransferUseCase(repository: getIt()),
  );
  getIt.registerFactory<TransferBloc>(
    () => TransferBloc(transferUseCase: getIt()),
  );
}
```

### Registration Rules

| Scope | get_it Method | Use Case |
|---|---|---|
| Singleton | `registerLazySingleton` | Dio, repositories, services |
| Factory | `registerFactory` | BLoCs, Cubits (new instance per screen) |
| Scoped | `registerScopedAs` | Feature-scoped dependencies |

---

## §Value-Objects

### Financial Value Objects

```dart
// lib/core/domain/money.dart
class Money extends Equatable {
  final int amountInMinorUnits; // Store as cents/pence — avoid floating point
  final String currencyCode;

  const Money(this.amountInMinorUnits, this.currencyCode);

  factory Money.fromDouble(double amount, String currency) =>
      Money((amount * 100).round(), currency);

  double get asDouble => amountInMinorUnits / 100;

  Money operator +(Money other) {
    assert(currencyCode == other.currencyCode, 'Currency mismatch');
    return Money(amountInMinorUnits + other.amountInMinorUnits, currencyCode);
  }

  Money operator -(Money other) {
    assert(currencyCode == other.currencyCode, 'Currency mismatch');
    return Money(amountInMinorUnits - other.amountInMinorUnits, currencyCode);
  }

  bool get isNegative => amountInMinorUnits < 0;

  @override
  List<Object> get props => [amountInMinorUnits, currencyCode];

  @override
  String toString() => '${(amountInMinorUnits / 100).toStringAsFixed(2)} $currencyCode';
}

// lib/core/domain/iban.dart
class Iban extends Equatable {
  final String value;

  Iban._(this.value);

  factory Iban.parse(String input) {
    final normalized = input.replaceAll(RegExp(r'\s'), '').toUpperCase();
    if (!_isValid(normalized)) throw FormatException('Invalid IBAN: $input');
    return Iban._(normalized);
  }

  static bool _isValid(String iban) {
    if (iban.length < 15 || iban.length > 34) return false;
    final rearranged = iban.substring(4) + iban.substring(0, 4);
    final numeric = rearranged.split('').map((c) {
      final code = c.codeUnitAt(0);
      return code >= 65 ? '${code - 55}' : c;
    }).join();
    return BigInt.parse(numeric) % BigInt.from(97) == BigInt.one;
  }

  String get masked => '${value.substring(0, 4)}****${value.substring(value.length - 4)}';

  @override
  List<Object> get props => [value];
}
```
