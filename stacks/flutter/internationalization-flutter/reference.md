# Internationalization Flutter — Reference

## §ARB-Setup

### l10n.yaml Configuration

```yaml
# l10n.yaml (project root)
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
nullable-getter: false
```

### ARB File Structure

```
lib/
└── l10n/
    ├── app_en.arb          # English (template)
    ├── app_fa.arb          # Farsi
    ├── app_ar.arb          # Arabic
    └── app_de.arb          # German
```

### Template ARB File (English)

```json
{
  "@@locale": "en",
  "accountBalance": "Account Balance",
  "@accountBalance": {
    "description": "Label for the account balance display"
  },
  "welcomeMessage": "Welcome, {userName}!",
  "@welcomeMessage": {
    "description": "Greeting on the dashboard",
    "placeholders": {
      "userName": {
        "type": "String",
        "example": "Jane"
      }
    }
  },
  "transactionCount": "{count, plural, =0{No transactions} =1{1 transaction} other{{count} transactions}}",
  "@transactionCount": {
    "description": "Number of transactions in the list",
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  },
  "transferConfirmation": "Transfer {amount} to {recipient}?",
  "@transferConfirmation": {
    "description": "Confirmation dialog for transfers",
    "placeholders": {
      "amount": {
        "type": "String",
        "example": "$1,500.00"
      },
      "recipient": {
        "type": "String",
        "example": "Jane Doe"
      }
    }
  },
  "accountStatus": "{status, select, active{Active} frozen{Frozen} closed{Closed} other{Unknown}}",
  "@accountStatus": {
    "description": "Account status display",
    "placeholders": {
      "status": {
        "type": "String"
      }
    }
  }
}
```

### Farsi ARB File

```json
{
  "@@locale": "fa",
  "accountBalance": "\u0645\u0648\u062c\u0648\u062f\u06cc \u062d\u0633\u0627\u0628",
  "welcomeMessage": "{userName} \u062e\u0648\u0634 \u0622\u0645\u062f\u06cc\u062f\u060c",
  "transactionCount": "{count, plural, =0{\u0628\u062f\u0648\u0646 \u062a\u0631\u0627\u06a9\u0646\u0634} =1{\u06f1 \u062a\u0631\u0627\u06a9\u0646\u0634} other{{count} \u062a\u0631\u0627\u06a9\u0646\u0634}}",
  "transferConfirmation": "\u0627\u0646\u062a\u0642\u0627\u0644 {amount} \u0628\u0647 {recipient}\u061f",
  "accountStatus": "{status, select, active{\u0641\u0639\u0627\u0644} frozen{\u0645\u0633\u062f\u0648\u062f} closed{\u0628\u0633\u062a\u0647} other{\u0646\u0627\u0645\u0634\u062e\u0635}}"
}
```

### Code Generation

```bash
# ARB files are compiled automatically by flutter gen-l10n
flutter gen-l10n

# Or automatically on build:
flutter run  # generates on every build when l10n.yaml is present
```

---

## §Placeholders

### Named Placeholder Syntax

```json
{
  "greeting": "Hello, {name}! Your account {accountNumber} has {balance}.",
  "@greeting": {
    "placeholders": {
      "name": { "type": "String", "example": "Jane" },
      "accountNumber": { "type": "String", "example": "****4521" },
      "balance": { "type": "String", "example": "$5,200.00" }
    }
  }
}
```

### Usage in Code

```dart
// Generated class provides type-safe access
Text(context.l10n.greeting(
  user.displayName,
  account.maskedNumber,
  formatCurrency(account.balance, context),
));
```

### Placeholder Types

| Type | ARB Type | Dart Type | Example |
|---|---|---|---|
| Text | `String` | `String` | Name, label |
| Count | `int` | `int` | Transaction count |
| Amount | `String` | Pre-formatted `String` | "$1,500.00" |
| Date | `DateTime` | `DateTime` | With `format` param |
| Number | `num` | `num` | With `format` param |

---

## §Plurals

### ICU Plural Syntax in ARB

```json
{
  "itemCount": "{count, plural, =0{No items} =1{One item} other{{count} items}}",
  "@itemCount": {
    "placeholders": {
      "count": { "type": "int" }
    }
  },
  "daysRemaining": "{days, plural, =0{Expires today} =1{Expires tomorrow} other{Expires in {days} days}}",
  "@daysRemaining": {
    "placeholders": {
      "days": { "type": "int" }
    }
  }
}
```

### Plural Categories by Language

| Language | Categories Used |
|---|---|
| English | one, other |
| Arabic | zero, one, two, few, many, other |
| Farsi | one, other |
| German | one, other |
| French | one, other |

---

## §Date-Format

### DateFormat Usage

```dart
import 'package:intl/intl.dart';

class DateFormatter {
  /// Format transaction date for display
  static String transactionDate(DateTime date, BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(date);
    // en: "Jan 15, 2024"
    // fa: "۱۵ ژانویهٔ ۲۰۲۴"
    // de: "15. Jan. 2024"
  }

  /// Format time for transaction detail
  static String transactionTime(DateTime date, BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.jm(locale).format(date);
    // en: "2:30 PM"
    // fa: "۲:۳۰ ب.ظ."
    // de: "14:30"
  }

  /// Full date and time for statements
  static String statementDateTime(DateTime date, BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMMEEEEd(locale).add_jm().format(date);
    // en: "Monday, January 15, 2024 2:30 PM"
  }

  /// Relative date for recent transactions
  static String relativeDate(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final diff = now.difference(date);
    final l10n = context.l10n;

    if (diff.inDays == 0) return l10n.today;
    if (diff.inDays == 1) return l10n.yesterday;
    if (diff.inDays < 7) return l10n.daysAgo(diff.inDays);
    return transactionDate(date, context);
  }
}
```

---

## §Currency-Format

### NumberFormat.currency Usage

```dart
import 'package:intl/intl.dart';

class CurrencyFormatter {
  /// Format currency amount with locale awareness
  static String format({
    required double amount,
    required String currencyCode,
    required BuildContext context,
  }) {
    final locale = Localizations.localeOf(context).toString();
    return NumberFormat.currency(
      locale: locale,
      name: currencyCode,
      symbol: _currencySymbol(currencyCode),
      decimalDigits: _decimalDigits(currencyCode),
    ).format(amount);
    // USD in en: "$1,500.00"
    // IRR in fa: "۱٬۵۰۰ ﷼"
    // EUR in de: "1.500,00 €"
  }

  /// Compact format for large amounts
  static String compact({
    required double amount,
    required String currencyCode,
    required BuildContext context,
  }) {
    final locale = Localizations.localeOf(context).toString();
    return NumberFormat.compactCurrency(
      locale: locale,
      name: currencyCode,
      symbol: _currencySymbol(currencyCode),
    ).format(amount);
    // en: "$1.5K", "$2.3M"
  }

  static String _currencySymbol(String code) => switch (code) {
        'USD' => '\$',
        'EUR' => '\u20AC',
        'GBP' => '\u00A3',
        'IRR' => '\uFDFC',
        _ => code,
      };

  static int _decimalDigits(String code) => switch (code) {
        'IRR' || 'JPY' => 0,
        _ => 2,
      };
}
```

### Number Formatting

```dart
class NumberFormatter {
  /// Format plain numbers with locale grouping
  static String format(num number, BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return NumberFormat.decimalPattern(locale).format(number);
    // en: "1,500,000"
    // fa: "۱٬۵۰۰٬۰۰۰"
    // de: "1.500.000"
  }

  /// Format percentage
  static String percent(double value, BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return NumberFormat.percentPattern(locale).format(value);
    // en: "15%"
  }
}
```

---

## §RTL-Support

### Directional Widgets

```dart
// WRONG — physical directions
Padding(padding: EdgeInsets.only(left: 16, right: 8))
Row(children: [icon, Expanded(child: text), arrow])
Align(alignment: Alignment.centerLeft)

// CORRECT — logical directions (RTL-aware)
Padding(padding: EdgeInsetsDirectional.only(start: 16, end: 8))
Row(children: [icon, Expanded(child: text), arrow])  // Row auto-reverses in RTL
Align(alignment: AlignmentDirectional.centerStart)
```

### Mirroring Directional Icons

```dart
Widget directionalIcon(BuildContext context) {
  final isRtl = Directionality.of(context) == TextDirection.rtl;

  // Arrow icons must mirror in RTL
  return Icon(isRtl ? Icons.arrow_back : Icons.arrow_forward);
}

// Non-directional icons do NOT mirror
// Settings, search, home, check — these stay the same
```

### Forcing LTR for Specific Content

```dart
// Phone numbers, account numbers, and IBANs are always LTR
Directionality(
  textDirection: TextDirection.ltr,
  child: Text(iban, style: monoStyle),
)

// Mixed direction text
Text.rich(TextSpan(children: [
  TextSpan(text: context.l10n.accountLabel), // Localized
  TextSpan(
    text: '\u200E$accountNumber', // LTR mark + number
    style: monoStyle,
  ),
]));
```

---

## §L10n-Access

### context.l10n Extension

```dart
// lib/core/extensions/l10n_extension.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension L10nExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
```

### Usage

```dart
// In any widget with BuildContext
Text(context.l10n.accountBalance)
Text(context.l10n.welcomeMessage(user.name))
Text(context.l10n.transactionCount(transactions.length))
```

---

## §App-Config

### MaterialApp Configuration

```dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class BankApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: goRouter,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),          // English
        Locale('fa'),          // Farsi
        Locale('ar'),          // Arabic
        Locale('de'),          // German
      ],
      locale: _userPreferredLocale(), // From settings or device
      theme: BankTheme.light,
      darkTheme: BankTheme.dark,
    );
  }
}
```

### pubspec.yaml Dependencies

```yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0

flutter:
  generate: true  # Enables code generation from ARB files
```

---

## §Text-Expansion

### Testing for Overflow

| Language | Typical Expansion vs English |
|---|---|
| German | +30-40% |
| French | +15-25% |
| Arabic | +20-30% |
| Farsi | +20-30% |

### Design Guidelines

```dart
// Use flexible layout that handles expansion
Row(
  children: [
    Expanded(
      child: Text(
        context.l10n.transferButton,
        overflow: TextOverflow.ellipsis, // Fallback for extreme cases
        maxLines: 1,
      ),
    ),
  ],
)

// Avoid fixed-width containers for text
// WRONG
SizedBox(width: 100, child: Text(context.l10n.label))

// CORRECT
ConstrainedBox(
  constraints: BoxConstraints(minWidth: 80),
  child: Text(context.l10n.label),
)
```
