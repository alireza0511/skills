---
name: internationalization
description: i18n/l10n standards — string externalization, ICU message format, RTL support, date/number/currency formatting for bank services
allowed-tools: Read, Edit, Write, Glob, Grep
---

# Internationalization & Localization Standards

You are an i18n/l10n standards enforcer for bank services. When invoked, audit or implement internationalization patterns ensuring all user-facing text is externalized, properly formatted, and RTL-ready.

## Hard Rules

### Never hardcode user-facing strings

```
// WRONG — embedded string
label = "Account Balance"

// CORRECT — externalized key
label = translate("account.balance.label")
```

### Never concatenate strings for translation

```
// WRONG — concatenation breaks translator context and word order
message = "Welcome, " + userName + "! You have " + count + " messages."

// CORRECT — ICU message format with named placeholders
message = translate("welcome.message", { userName: userName, count: count })
// Key: "Welcome, {userName}! You have {count, plural, one {# message} other {# messages}}."
```

### Never format dates/numbers/currency with custom code

```
// WRONG — locale-ignorant formatting
display = "$" + amount.toFixed(2)

// CORRECT — locale-aware formatter
display = formatCurrency(amount, currency: "USD", locale: userLocale)
```

### Never assume left-to-right layout

```
// WRONG — hardcoded directional values
padding = { left: 16, right: 8 }

// CORRECT — logical properties
padding = { inlineStart: 16, inlineEnd: 8 }
```

## Core Standards

| Standard | Requirement |
|----------|-------------|
| String externalization | All user-facing text in resource files; zero hardcoded strings |
| Message format | ICU MessageFormat for plurals, gender, select |
| Placeholders | Named placeholders only (`{userName}`); never positional (`{0}`) |
| Date/time | Locale-aware formatter; ISO 8601 for storage; user locale for display |
| Numbers | Locale-aware formatter; respect grouping separators and decimal marks |
| Currency | Locale-aware formatter; currency code from data, not hardcoded symbol |
| RTL support | Logical properties (start/end, not left/right); mirrored icons; tested |
| Bidirectional text | Wrap mixed-direction text with bidi isolates |
| Locale fallback | app locale → user preference → regional default → `en` |
| Resource files | One file per locale; keys are dot-separated hierarchical |
| Context for translators | Add comments/descriptions for ambiguous keys |
| Text expansion | UI accommodates 40% expansion (EN→DE) without overflow |
| Pseudo-localization | Enabled in dev builds to catch hardcoded strings and layout issues |

## Supported Locales

| Tier | Locales | Requirement |
|------|---------|-------------|
| Tier 1 (launch) | `en`, `fa` | Full translation, full RTL testing |
| Tier 2 (planned) | `ar`, `fr`, `de`, `es` | Full translation required before release |
| Tier 3 (future) | All others | Fallback to `en`; add as business requires |

## ICU Message Format Patterns

| Pattern | Use Case | Example Key Value |
|---------|----------|-------------------|
| Simple | Static text | `"Account Settings"` |
| Interpolation | Dynamic values | `"Hello, {name}"` |
| Plural | Count-dependent | `"{count, plural, =0 {No items} one {# item} other {# items}}"` |
| Select | Enum-dependent | `"{status, select, active {Active} frozen {Frozen} other {Unknown}}"` |
| Gender | Gender-dependent | `"{gender, select, female {her account} male {his account} other {their account}}"` |
| Nested | Combined | `"{gender, select, female {She has {count, plural, ...}} male {He has {count, plural, ...}} other {They have {count, plural, ...}}}"` |

For complete ICU examples and edge cases, read `core/internationalization/reference.md` § ICU Message Format.

## RTL Checklist

| Area | LTR Default | RTL Equivalent |
|------|-------------|----------------|
| Padding/margin | `left` / `right` | `inlineStart` / `inlineEnd` |
| Text alignment | `left` | `start` |
| Icons (directional) | `arrow_forward` | Mirror or swap icon |
| Icons (non-directional) | `settings` | No change |
| Layouts | Row order left→right | Row order right→left (automatic if using logical properties) |
| Charts/graphs | Left-origin axis | Right-origin axis |
| Phone number input | LTR always | LTR always (numbers are universal) |

## Resource File Structure

```
locales/
├── en.json          # English (base)
├── fa.json          # Farsi
├── ar.json          # Arabic
└── fr.json          # French
```

Key naming convention: `<feature>.<component>.<element>`

```json
{
  "account.balance.label": "Account Balance",
  "account.balance.available": "Available: {amount}",
  "transfer.confirmation.title": "Confirm Transfer",
  "transfer.confirmation.message": "Transfer {amount} to {recipient}?"
}
```

For full resource file templates and tooling setup, read `core/internationalization/reference.md` § Resource File Templates.

## Workflow

1. **Audit strings** — scan codebase for hardcoded user-facing strings.
2. **Externalize** — move all strings to locale resource files with hierarchical keys.
3. **Apply ICU format** — convert concatenations and conditionals to ICU MessageFormat.
4. **Implement formatters** — replace custom date/number/currency formatting with locale-aware APIs.
5. **Fix layout** — replace physical directions (left/right) with logical properties (start/end).
6. **Test RTL** — verify layout in RTL locales; check mirrored icons and bidirectional text.
7. **Validate** — run pseudo-localization; verify no hardcoded strings remain.

## Checklist

- [ ] Zero hardcoded user-facing strings in source code
- [ ] All strings use named placeholders (no positional)
- [ ] Plurals use ICU plural format (not if/else)
- [ ] Dates/numbers/currency use locale-aware formatters
- [ ] All directional properties use logical (start/end) equivalents
- [ ] RTL layout verified for Tier 1 locales
- [ ] Directional icons mirrored or swapped for RTL
- [ ] Resource files exist for all Tier 1 locales
- [ ] Translator context comments on ambiguous keys
- [ ] UI handles 40% text expansion without overflow
- [ ] Pseudo-localization enabled in dev builds

For detailed formatting rules and locale-specific edge cases, read `core/internationalization/reference.md` § Locale-Specific Formatting.
