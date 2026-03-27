---
name: internationalization-flutter
description: "Flutter/Dart i18n — flutter_localizations, ARB files, intl package, RTL support, locale-aware formatting for banking apps"
allowed-tools:
  - Read
  - Grep
  - Glob
  - Edit
  - Write
argument-hint: "path to Flutter widget or ARB file to audit"
---

# Internationalization — Flutter Stack

You are an i18n/l10n specialist for the bank's Flutter applications.
When invoked, audit Flutter/Dart code for proper string externalization, ARB-based localization, RTL support, and locale-aware formatting.

> All rules from `core/internationalization/SKILL.md` apply here. This adds Flutter-specific implementation.

---

## Hard Rules

### HR-1: Never hardcode user-facing strings in widgets

```dart
// WRONG
Text('Account Balance')

// CORRECT
Text(context.l10n.accountBalance)
```

### HR-2: Never concatenate strings for translation

```dart
// WRONG
Text('Welcome, $userName! You have $count transactions.')

// CORRECT — use ARB placeholders
Text(context.l10n.welcomeMessage(userName, count))
// ARB: "welcomeMessage": "Welcome, {userName}! You have {count} transactions."
```

### HR-3: Never format currency/dates with custom code

```dart
// WRONG
Text('\$${amount.toStringAsFixed(2)}')

// CORRECT
Text(NumberFormat.currency(locale: Localizations.localeOf(context).toString(),
    symbol: currencySymbol).format(amount))
```

### HR-4: Never use physical directions for layout

```dart
// WRONG
Padding(padding: EdgeInsets.only(left: 16))

// CORRECT — RTL-aware
Padding(padding: EdgeInsetsDirectional.only(start: 16))
```

---

## Core Standards

| Area | Standard | Enforcement |
|---|---|---|
| String externalization | All user-facing text in ARB files via `flutter_localizations` | Mandatory |
| ARB files | One per locale, `app_<locale>.arb` format | Mandatory |
| Placeholders | Named placeholders with type annotations in ARB | Mandatory |
| Plurals | ICU plural syntax in ARB files | Mandatory |
| Date/time | `DateFormat` from `intl` with user locale | Mandatory |
| Numbers | `NumberFormat` from `intl` with user locale | Mandatory |
| Currency | `NumberFormat.currency` with locale and currency code | Mandatory |
| RTL layout | `Directionality`, `EdgeInsetsDirectional`, `TextDirection` | Mandatory |
| Locale fallback | App locale > user preference > `en` | Mandatory |
| Context.l10n | Access via `context.l10n` extension — never pass strings | Convention |
| Text expansion | UI accommodates 40% expansion without overflow | Mandatory |

---

## Workflow

1. **Scan strings** — Search for hardcoded user-facing strings in widget files.
2. **Check ARB files** — Verify all locales have matching keys; no missing translations.
3. **Validate placeholders** — Confirm named placeholders with types in ARB metadata.
4. **Audit formatting** — Verify `DateFormat`, `NumberFormat`, and `NumberFormat.currency` usage.
5. **Review RTL** — Check for `EdgeInsetsDirectional`, `TextDirection`, mirrored icons.
6. **Test locales** — Verify Tier 1 locales render correctly and RTL layout is correct.
7. **Check overflow** — Test longest locale (e.g., German) for text overflow.

---

## Checklist

- [ ] Zero hardcoded user-facing strings in widget files (§ARB-Setup)
- [ ] ARB files exist for all Tier 1 locales (`en`, `fa`) (§ARB-Setup)
- [ ] All ARB keys have matching translations in every locale (§ARB-Setup)
- [ ] Placeholders use named parameters with type annotations (§Placeholders)
- [ ] Plurals use ICU plural syntax in ARB (§Plurals)
- [ ] Dates formatted with `DateFormat` and user locale (§Date-Format)
- [ ] Currency formatted with `NumberFormat.currency` (§Currency-Format)
- [ ] All directional properties use `Directional` variants (§RTL-Support)
- [ ] Icons mirrored for RTL where directional (§RTL-Support)
- [ ] `context.l10n` used consistently — no raw string access (§L10n-Access)
- [ ] UI tested with longest locale for overflow (§Text-Expansion)
- [ ] `flutter_localizations` configured in `MaterialApp` (§App-Config)

---

## References

- §ARB-Setup — ARB file structure, l10n.yaml configuration, code generation
- §Placeholders — Named placeholder syntax with type annotations
- §Plurals — ICU plural format in ARB files
- §Date-Format — DateFormat patterns with locale awareness
- §Currency-Format — NumberFormat.currency usage for financial amounts
- §RTL-Support — RTL layout patterns and directional widgets
- §L10n-Access — context.l10n extension setup and usage
- §App-Config — MaterialApp localization delegates configuration

See `reference.md` for full details on each section.
