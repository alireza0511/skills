# Error Handling Flutter — Reference

## §Result-Type

### Result Sealed Class

```dart
// lib/core/error/result.dart
sealed class Result<T> {
  const Result();

  factory Result.success(T data) = Success<T>;
  factory Result.failure(AppError error) = Failure<T>;

  R when<R>({
    required R Function(T data) success,
    required R Function(AppError error) failure,
  });

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => switch (this) {
        Success(data: final d) => d,
        Failure() => null,
      };
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(AppError error) failure,
  }) => success(data);
}

final class Failure<T> extends Result<T> {
  final AppError error;
  const Failure(this.error);

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(AppError error) failure,
  }) => failure(error);
}
```

### AppError Hierarchy

```dart
// lib/core/error/app_error.dart
sealed class AppError {
  final String code;
  final String userMessage;
  final String internalMessage;
  final String? traceId;

  const AppError({
    required this.code,
    required this.userMessage,
    required this.internalMessage,
    this.traceId,
  });
}

final class ValidationError extends AppError {
  final Map<String, String> fieldErrors;

  const ValidationError({
    required this.fieldErrors,
    required super.userMessage,
    super.code = 'VALIDATION_FAILED',
    super.internalMessage = '',
    super.traceId,
  });
}

final class NetworkError extends AppError {
  final bool retryable;

  const NetworkError({
    required super.userMessage,
    required super.internalMessage,
    this.retryable = true,
    super.code = 'NETWORK_ERROR',
    super.traceId,
  });
}

final class BusinessError extends AppError {
  const BusinessError({
    required super.code,
    required super.userMessage,
    required super.internalMessage,
    super.traceId,
  });
}

final class ServerError extends AppError {
  final int? statusCode;

  const ServerError({
    required super.userMessage,
    required super.internalMessage,
    this.statusCode,
    super.code = 'SERVER_ERROR',
    super.traceId,
  });
}
```

### Usage in Repository

```dart
class TransferRepositoryImpl implements TransferRepository {
  final Dio _dio;

  @override
  Future<Result<Transfer>> execute(TransferCommand cmd) async {
    try {
      final response = await _dio.post('/transfers', data: cmd.toJson());
      return Result.success(Transfer.fromJson(response.data));
    } on DioException catch (e) {
      return Result.failure(_mapDioError(e));
    }
  }

  AppError _mapDioError(DioException e) {
    final traceId = e.response?.headers.value('x-trace-id');

    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout =>
        NetworkError(
          userMessage: 'Connection timed out. Please try again.',
          internalMessage: 'Timeout: ${e.message}',
          traceId: traceId,
        ),
      DioExceptionType.badResponse => _mapStatusCode(e.response!, traceId),
      _ => NetworkError(
          userMessage: 'Unable to connect. Check your network.',
          internalMessage: e.message ?? 'Unknown network error',
          traceId: traceId,
        ),
    };
  }

  AppError _mapStatusCode(Response response, String? traceId) {
    return switch (response.statusCode) {
      400 || 422 => ValidationError(
          fieldErrors: _parseFieldErrors(response.data),
          userMessage: 'Please check the form and try again.',
          traceId: traceId,
        ),
      401 => const BusinessError(
          code: 'AUTH_REQUIRED',
          userMessage: 'Session expired. Please sign in again.',
          internalMessage: '401 Unauthorized',
        ),
      403 => const BusinessError(
          code: 'PERMISSION_DENIED',
          userMessage: 'You do not have permission for this action.',
          internalMessage: '403 Forbidden',
        ),
      409 => const BusinessError(
          code: 'DUPLICATE_REQUEST',
          userMessage: 'This transfer may have already been processed.',
          internalMessage: '409 Conflict',
        ),
      429 => NetworkError(
          userMessage: 'Too many requests. Please wait a moment.',
          internalMessage: '429 Rate limited',
          retryable: true,
          traceId: traceId,
        ),
      _ => ServerError(
          userMessage: 'Something went wrong. Please try again.',
          internalMessage: 'HTTP ${response.statusCode}: ${response.data}',
          statusCode: response.statusCode,
          traceId: traceId,
        ),
    };
  }
}
```

---

## §Global-Handlers

### Main Entry Point Setup

```dart
// lib/main.dart
import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp();

      // Flutter framework errors
      FlutterError.onError = (details) {
        FlutterError.presentError(details); // Debug console
        if (!kDebugMode) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        }
      };

      // Platform dispatcher errors (e.g., codec errors)
      PlatformDispatcher.instance.onError = (error, stack) {
        if (!kDebugMode) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        }
        return true;
      };

      // Custom error widget for release builds
      if (!kDebugMode) {
        ErrorWidget.builder = (details) => const MaterialApp(
              home: AppErrorScreen(),
            );
      }

      configureDependencies();
      runApp(const BankApp());
    },
    (error, stack) {
      // Catches all uncaught async errors
      if (!kDebugMode) {
        FirebaseCrashlytics.instance.recordError(error, stack);
      }
    },
  );
}
```

---

## §Error-Boundary

### Error Boundary Widget

```dart
// lib/core/widgets/error_boundary.dart
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails)? errorBuilder;

  const ErrorBoundary({required this.child, this.errorBuilder});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _errorDetails;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorDetails != null) {
      return widget.errorBuilder?.call(_errorDetails!) ??
          _DefaultErrorWidget(
            onRetry: () => setState(() => _errorDetails = null),
          );
    }

    return widget.child;
  }
}

class _DefaultErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;

  const _DefaultErrorWidget({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              context.l10n.genericErrorTitle,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.genericErrorMessage,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## §Error-UI

### Error State Patterns in BLoC

```dart
// In BLoC builder
BlocBuilder<TransferBloc, TransferState>(
  builder: (context, state) => switch (state.status) {
    TransferStatus.initial => TransferForm(onSubmit: _submit),
    TransferStatus.loading => const LoadingOverlay(child: TransferForm()),
    TransferStatus.success => TransferSuccessView(result: state.result!),
    TransferStatus.failure => TransferErrorView(
      error: state.error!,
      onRetry: state.error!.isRetryable ? _submit : null,
      onContactSupport: () => _openSupport(state.error!.traceId),
    ),
  },
)
```

### Snackbar Error Pattern

```dart
void _showError(BuildContext context, AppError error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(error.userMessage),
      action: error is NetworkError && error.retryable
          ? SnackBarAction(
              label: context.l10n.retry,
              onPressed: _retryLastAction,
            )
          : null,
      duration: const Duration(seconds: 5),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
```

### Full Error Screen

```dart
class AppErrorScreen extends StatelessWidget {
  final String? traceId;
  final VoidCallback? onRetry;

  const AppErrorScreen({this.traceId, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, size: 64,
                  color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 24),
              Text(context.l10n.somethingWentWrong,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Text(context.l10n.tryAgainMessage,
                  textAlign: TextAlign.center),
              if (traceId != null) ...[
                const SizedBox(height: 16),
                Text('${context.l10n.referenceLabel}: $traceId',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 32),
              if (onRetry != null)
                ElevatedButton(
                  onPressed: onRetry,
                  child: Text(context.l10n.tryAgain),
                ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => _contactSupport(context, traceId),
                child: Text(context.l10n.contactSupport),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## §Exception-Types

### Typed Exception Hierarchy

```dart
// Base exception
sealed class BankException implements Exception {
  final String message;
  final String? traceId;
  const BankException(this.message, {this.traceId});
}

// Network exceptions
class NetworkException extends BankException {
  const NetworkException(super.message, {super.traceId});
}

class TimeoutException extends NetworkException {
  const TimeoutException({String? traceId})
      : super('Request timed out', traceId: traceId);
}

// Business exceptions
class InsufficientFundsException extends BankException {
  final double available;
  final double requested;
  const InsufficientFundsException({
    required this.available,
    required this.requested,
    String? traceId,
  }) : super('Insufficient funds', traceId: traceId);
}

class TransferLimitExceededException extends BankException {
  final double limit;
  const TransferLimitExceededException({required this.limit, String? traceId})
      : super('Transfer limit exceeded', traceId: traceId);
}

class AccountFrozenException extends BankException {
  const AccountFrozenException({String? traceId})
      : super('Account is frozen', traceId: traceId);
}
```

---

## §Crashlytics

### Firebase Crashlytics Configuration

```yaml
# pubspec.yaml
dependencies:
  firebase_core: ^3.0.0
  firebase_crashlytics: ^4.0.0
```

### Custom Keys and User Context

```dart
class CrashlyticsService {
  final FirebaseCrashlytics _crashlytics;

  CrashlyticsService(this._crashlytics);

  Future<void> setUserContext(String userId) async {
    await _crashlytics.setUserIdentifier(userId);
  }

  Future<void> recordError(
    dynamic error,
    StackTrace stack, {
    String? reason,
    bool fatal = false,
    Map<String, String>? context,
  }) async {
    if (context != null) {
      for (final entry in context.entries) {
        await _crashlytics.setCustomKey(entry.key, entry.value);
      }
    }

    await _crashlytics.recordError(
      error,
      stack,
      reason: reason,
      fatal: fatal,
    );
  }

  /// Log non-fatal error with banking context
  Future<void> recordTransferError(
    dynamic error,
    StackTrace stack, {
    required String fromAccount,
    required String toAccount,
    required String amount,
  }) async {
    await recordError(
      error,
      stack,
      reason: 'Transfer failed',
      context: {
        'from_account': _mask(fromAccount),
        'to_account': _mask(toAccount),
        'amount_range': _amountRange(amount), // Never log exact amount
      },
    );
  }

  String _mask(String value) =>
      '****${value.substring(value.length - 4)}';

  String _amountRange(String amount) {
    final value = double.tryParse(amount) ?? 0;
    if (value < 100) return '<100';
    if (value < 1000) return '100-1K';
    if (value < 10000) return '1K-10K';
    return '>10K';
  }
}
```
