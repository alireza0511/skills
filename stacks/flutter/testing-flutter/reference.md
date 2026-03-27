# Testing Flutter — Reference

## §Widget-Tests

### Basic Widget Test Pattern

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAccountRepository extends Mock implements AccountRepository {}

void main() {
  late MockAccountRepository mockRepo;

  setUp(() {
    mockRepo = MockAccountRepository();
  });

  group('AccountBalanceCard', () {
    testWidgets('displays formatted balance when loaded', (tester) async {
      when(() => mockRepo.getBalance(any()))
          .thenAnswer((_) async => Balance(amount: 12500.50, currency: 'USD'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccountBalanceCard(repository: mockRepo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('\$12,500.50'), findsOneWidget);
      expect(find.text('Available Balance'), findsOneWidget);
    });

    testWidgets('shows error state when fetch fails', (tester) async {
      when(() => mockRepo.getBalance(any()))
          .thenThrow(NetworkException('Connection failed'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccountBalanceCard(repository: mockRepo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Unable to load balance'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('refresh button retries fetch', (tester) async {
      when(() => mockRepo.getBalance(any()))
          .thenThrow(NetworkException('fail'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccountBalanceCard(repository: mockRepo),
          ),
        ),
      );
      await tester.pumpAndSettle();

      when(() => mockRepo.getBalance(any()))
          .thenAnswer((_) async => Balance(amount: 500, currency: 'USD'));

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(find.text('\$500.00'), findsOneWidget);
      verify(() => mockRepo.getBalance(any())).called(2);
    });
  });
}
```

### Testing Async Operations

```dart
testWidgets('shows loading indicator during transfer', (tester) async {
  final completer = Completer<TransferResult>();
  when(() => mockService.transfer(any()))
      .thenAnswer((_) => completer.future);

  await tester.pumpWidget(
    MaterialApp(home: TransferScreen(service: mockService)),
  );

  await tester.tap(find.byKey(const Key('submit_transfer')));
  await tester.pump(); // One frame — shows loading

  expect(find.byType(CircularProgressIndicator), findsOneWidget);
  expect(find.byKey(const Key('submit_transfer')), findsNothing);

  completer.complete(TransferResult.success());
  await tester.pumpAndSettle();

  expect(find.byType(CircularProgressIndicator), findsNothing);
  expect(find.text('Transfer Successful'), findsOneWidget);
});
```

### Testing Navigation

```dart
testWidgets('navigates to detail on account tap', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: AccountListScreen(accounts: testAccounts),
      onGenerateRoute: (settings) {
        if (settings.name == '/account/detail') {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Detail')),
          );
        }
        return null;
      },
    ),
  );

  await tester.tap(find.text('Checking Account'));
  await tester.pumpAndSettle();

  expect(find.text('Detail'), findsOneWidget);
});
```

---

## §Golden-Tests

### Setup with golden_toolkit

```yaml
# pubspec.yaml
dev_dependencies:
  golden_toolkit: ^0.15.0
  flutter_test:
    sdk: flutter
```

```dart
// test/golden/flutter_test_config.dart
import 'dart:async';
import 'package:golden_toolkit/golden_toolkit.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await loadAppFonts();
  return testMain();
}
```

### Golden Test Examples

```dart
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TransferScreen golden tests', () {
    testGoldens('renders initial state', (tester) async {
      final builder = DeviceBuilder()
        ..overrideDevicesForAllScenarios(devices: [
          Device.phone,
          Device.tabletLandscape,
        ])
        ..addScenario(
          name: 'initial',
          widget: _buildTransferScreen(state: TransferState.initial()),
        )
        ..addScenario(
          name: 'filled',
          widget: _buildTransferScreen(
            state: TransferState.filled(
              amount: '1500.00',
              recipient: 'Jane Doe',
            ),
          ),
        )
        ..addScenario(
          name: 'error',
          widget: _buildTransferScreen(
            state: TransferState.error('Insufficient funds'),
          ),
        );

      await tester.pumpDeviceBuilder(builder);
      await screenMatchesGolden(tester, 'transfer_screen_states');
    });
  });
}

Widget _buildTransferScreen({required TransferState state}) {
  return MaterialApp(
    theme: BankTheme.light,
    home: TransferScreen.withState(state),
  );
}
```

### CI Golden Test Configuration

```bash
# Generate golden files locally
flutter test --update-goldens

# Verify golden files in CI (fails on pixel diff)
flutter test --tags golden
```

| Concern | Approach |
|---|---|
| Font rendering differences | Use `loadAppFonts()` from golden_toolkit |
| Platform rendering differences | Generate goldens on CI (Linux); never locally |
| Threshold tolerance | Use `matchesGoldenFile` with 0.5% tolerance in CI |
| File storage | Commit golden PNGs to `test/golden/` directory |

---

## §Mock-Patterns

### mocktail Setup

```yaml
# pubspec.yaml
dev_dependencies:
  mocktail: ^1.0.0
```

### Common Mock Patterns

```dart
import 'package:mocktail/mocktail.dart';

// Mock classes
class MockTransferService extends Mock implements TransferService {}
class MockAuthRepository extends Mock implements AuthRepository {}
class MockNavigator extends Mock implements NavigatorObserver {}

// Register fallback values (required for any() matching on custom types)
void main() {
  setUpAll(() {
    registerFallbackValue(TransferRequest.empty());
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  late MockTransferService mockService;

  setUp(() {
    mockService = MockTransferService();
  });

  test('executes transfer with correct parameters', () async {
    when(() => mockService.execute(any()))
        .thenAnswer((_) async => TransferResult.success(id: 'tx-001'));

    final useCase = TransferUseCase(service: mockService);
    final result = await useCase.run(
      from: 'ACC-001',
      to: 'ACC-002',
      amount: Money(1000, 'USD'),
    );

    expect(result.isSuccess, isTrue);
    verify(() => mockService.execute(
      any(that: isA<TransferRequest>()
          .having((r) => r.fromAccount, 'from', 'ACC-001')
          .having((r) => r.amount.value, 'amount', 1000)),
    )).called(1);
  });
}
```

### Mocking Streams (BLoC Testing)

```dart
class MockAccountBloc extends Mock implements AccountBloc {}

testWidgets('rebuilds on bloc state change', (tester) async {
  final mockBloc = MockAccountBloc();

  whenListen(
    mockBloc,
    Stream.fromIterable([
      AccountLoading(),
      AccountLoaded(balance: Balance(5000, 'USD')),
    ]),
    initialState: AccountInitial(),
  );

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<AccountBloc>.value(
        value: mockBloc,
        child: const AccountScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text('\$5,000.00'), findsOneWidget);
});
```

---

## §Integration-Tests

### Setup

```yaml
# pubspec.yaml
dev_dependencies:
  integration_test:
    sdk: flutter
  flutter_test:
    sdk: flutter
```

### Integration Test Example

```dart
// integration_test/transfer_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:bank_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Transfer flow', () {
    testWidgets('complete transfer from login to confirmation', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login
      await tester.enterText(find.byKey(const Key('email_field')), 'test@bank.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'Test1234!');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Navigate to transfer
      await tester.tap(find.byKey(const Key('transfer_tab')));
      await tester.pumpAndSettle();

      // Fill transfer form
      await tester.enterText(find.byKey(const Key('recipient_field')), 'IR123456789');
      await tester.enterText(find.byKey(const Key('amount_field')), '1500');
      await tester.tap(find.byKey(const Key('submit_transfer')));
      await tester.pumpAndSettle();

      // Verify confirmation screen
      expect(find.text('Confirm Transfer'), findsOneWidget);
      expect(find.text('1,500.00'), findsOneWidget);

      // Confirm
      await tester.tap(find.byKey(const Key('confirm_button')));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Transfer Successful'), findsOneWidget);
    });
  });
}
```

### Running Integration Tests

```bash
# Run on connected device
flutter test integration_test/

# Run on specific device
flutter test integration_test/ -d emulator-5554

# Run with screenshots (for CI artifacts)
flutter test integration_test/ --dart-define=SCREENSHOTS=true
```

---

## §A11y-Tests

### Accessibility Guideline Tests

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Accessibility', () {
    testWidgets('TransferScreen meets Android tap target guidelines',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: TransferScreen()),
      );
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });

    testWidgets('TransferScreen meets iOS tap target guidelines',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: TransferScreen()),
      );
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    });

    testWidgets('TransferScreen meets text contrast guidelines',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: TransferScreen()),
      );
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });

    testWidgets('TransferScreen meets labelled tap target guidelines',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: TransferScreen()),
      );
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    });
  });
}
```

### Semantic Tree Testing

```dart
testWidgets('balance card has correct semantics', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AccountBalanceCard(balance: Balance(12500.50, 'USD')),
      ),
    ),
  );

  final semantics = tester.getSemantics(find.byType(AccountBalanceCard));
  expect(semantics.label, contains('Available Balance'));
  expect(semantics.label, contains('12,500'));
  expect(semantics.hasFlag(SemanticsFlag.isHeader), isTrue);
});
```

---

## §Coverage-Setup

### Running Coverage

```bash
# Generate coverage
flutter test --coverage

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Check coverage threshold in CI
flutter test --coverage
COVERAGE=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" | awk '{print $2}' | sed 's/%//')
if (( $(echo "$COVERAGE < 80" | bc -l) )); then
  echo "Coverage $COVERAGE% is below 80% threshold"
  exit 1
fi
```

### Excluding Generated Files

```yaml
# analysis_options.yaml or coverage helper
# Create test/coverage_helper_test.dart to include all files
# Exclude generated code from coverage:
```

```bash
# Remove generated files from coverage report
lcov --remove coverage/lcov.info \
  '*.g.dart' \
  '*.freezed.dart' \
  '*/generated/*' \
  '*/l10n/*' \
  -o coverage/lcov_cleaned.info
```

### Coverage by Module

| Module | Minimum Coverage | Focus |
|---|---|---|
| Domain (entities, value objects) | 95% | Business rules, calculations |
| BLoC / Cubit | 90% | State transitions, event handling |
| Repository | 80% | API mapping, error handling |
| Widgets | 80% | User interactions, state rendering |
| Utils / Extensions | 90% | Edge cases, formatting |
| Generated code | Excluded | Not meaningful to test |
