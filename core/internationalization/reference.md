# Internationalization & Localization — Reference

## ICU Message Format

### Plural Rules

ICU plural categories vary by language. English uses `one` and `other`. Arabic uses six categories.

| Category | English Example | Arabic Example |
|----------|----------------|----------------|
| `zero` | — | 0 items |
| `one` | 1 item | 1 item |
| `two` | — | 2 items |
| `few` | — | 3-10 items |
| `many` | — | 11-99 items |
| `other` | 2+ items | 100+ items |

Always define at least `one` and `other`. Add additional categories per target locale requirements.

### Plural Example — Complete

```
// English
"transfer.count": "{count, plural, =0 {No transfers today} one {# transfer today} other {# transfers today}}"

// Arabic (all six forms)
"transfer.count": "{count, plural, zero {لا تحويلات اليوم} one {تحويل واحد اليوم} two {تحويلان اليوم} few {# تحويلات اليوم} many {# تحويلاً اليوم} other {# تحويل اليوم}}"
```

### Select Example — Account Type

```
"account.type.label": "{type, select, checking {Checking Account} savings {Savings Account} investment {Investment Account} other {Account}}"
```

### Nested Example — Gender + Plural

```
"activity.summary": "{gender, select,
  female {{count, plural, one {She made # transaction} other {She made # transactions}}}
  male {{count, plural, one {He made # transaction} other {He made # transactions}}}
  other {{count, plural, one {They made # transaction} other {They made # transactions}}}
}"
```

### Escaping Special Characters

| Character | Escape |
|-----------|--------|
| `{` | `'{'` |
| `}` | `'}'` |
| `'` | `''` |
| `#` (outside plural) | No escape needed |
| `#` (inside plural) | Represents the count value — do not escape |

## Resource File Templates

### Base Locale (en.json)

```json
{
  "_locale": "en",
  "_direction": "ltr",

  "common.appName": "Bank Services",
  "common.loading": "Loading...",
  "common.error.generic": "Something went wrong. Please try again.",
  "common.error.network": "Unable to connect. Check your internet connection.",
  "common.actions.cancel": "Cancel",
  "common.actions.confirm": "Confirm",
  "common.actions.retry": "Retry",
  "common.actions.save": "Save",
  "common.actions.delete": "Delete",

  "auth.login.title": "Sign In",
  "auth.login.username": "Username",
  "auth.login.password": "Password",
  "auth.login.submit": "Sign In",
  "auth.login.forgotPassword": "Forgot Password?",
  "auth.login.biometric": "Sign in with {biometricType}",

  "account.balance.label": "Account Balance",
  "account.balance.available": "Available Balance: {amount}",
  "account.balance.pending": "{count, plural, one {# pending transaction} other {# pending transactions}}",

  "transfer.title": "Transfer Funds",
  "transfer.amount.label": "Amount",
  "transfer.recipient.label": "Recipient",
  "transfer.confirmation.message": "Transfer {amount} to {recipient}?",
  "transfer.success": "Transfer of {amount} to {recipient} completed successfully.",
  "transfer.error.insufficientFunds": "Insufficient funds. Available balance: {available}.",
  "transfer.error.dailyLimit": "Daily transfer limit of {limit} exceeded."
}
```

### RTL Locale (fa.json)

```json
{
  "_locale": "fa",
  "_direction": "rtl",

  "common.appName": "خدمات بانکی",
  "common.loading": "در حال بارگذاری...",
  "common.error.generic": "مشکلی پیش آمد. لطفاً دوباره تلاش کنید.",
  "common.actions.cancel": "لغو",
  "common.actions.confirm": "تأیید",

  "account.balance.label": "موجودی حساب",
  "account.balance.available": "موجودی قابل برداشت: {amount}"
}
```

## Locale-Specific Formatting

### Date Formatting

| Locale | Short Date | Long Date | Relative |
|--------|-----------|-----------|----------|
| `en` | 03/27/2026 | March 27, 2026 | 2 days ago |
| `fa` | ۱۴۰۵/۰۱/۰۷ | ۷ فروردین ۱۴۰۵ | ۲ روز پیش |
| `ar` | ٢٧/٠٣/٢٠٢٦ | ٢٧ مارس ٢٠٢٦ | منذ يومين |
| `de` | 27.03.2026 | 27. März 2026 | vor 2 Tagen |
| `fr` | 27/03/2026 | 27 mars 2026 | il y a 2 jours |

### Number Formatting

| Locale | Number | Grouping | Decimal |
|--------|--------|----------|---------|
| `en` | 1,234,567.89 | `,` | `.` |
| `fa` | ۱٬۲۳۴٬۵۶۷٫۸۹ | `٬` | `٫` |
| `ar` | ١٬٢٣٤٬٥٦٧٫٨٩ | `٬` | `٫` |
| `de` | 1.234.567,89 | `.` | `,` |
| `fr` | 1 234 567,89 | ` ` (narrow no-break space) | `,` |

### Currency Formatting

| Locale | Format | Example |
|--------|--------|---------|
| `en` | `$1,234.56` | Symbol before, period decimal |
| `fa` | `۱٬۲۳۴٫۵۶ ﷼` | Symbol after, Persian digits |
| `ar` | `١٬٢٣٤٫٥٦ ر.س` | Symbol after, Arabic digits |
| `de` | `1.234,56 €` | Symbol after, comma decimal |
| `fr` | `1 234,56 €` | Symbol after, space grouping |

Always use the currency code from the data (e.g., `USD`, `IRR`, `EUR`). Never hardcode currency symbols.

## RTL Implementation Guide

### Directional Icons

Icons that imply direction must be mirrored in RTL contexts:

| Icon | Mirror in RTL? | Reason |
|------|----------------|--------|
| Arrow forward/back | Yes | Indicates navigation direction |
| Chevron left/right | Yes | Indicates navigation direction |
| Send | Yes | Implies direction of action |
| Reply / Forward (email) | Yes | Implies direction |
| Search | No | Universal symbol |
| Settings/gear | No | Universal symbol |
| Close/X | No | Universal symbol |
| Checkmark | No | Universal symbol |
| Plus/minus | No | Mathematical symbols |
| Trash/delete | No | Universal symbol |

### Bidirectional Text Handling

When mixing LTR and RTL content (e.g., English product names in Arabic text), wrap the embedded text with Unicode bidi isolates:

| Character | Code Point | Purpose |
|-----------|-----------|---------|
| LRI | U+2066 | Left-to-right isolate |
| RLI | U+2067 | Right-to-left isolate |
| PDI | U+2069 | Pop directional isolate |

Example: In an Arabic sentence containing an English brand name, wrap the English text with LRI...PDI to prevent it from disrupting the Arabic flow.

### Layout Mirroring Checklist

- [ ] All `left`/`right` padding/margin replaced with `start`/`end`
- [ ] Text alignment uses `start`/`end` instead of `left`/`right`
- [ ] Directional icons mirrored via icon theme or conditional logic
- [ ] Progress bars and sliders use locale-aware direction
- [ ] Swipe gestures reversed where directional
- [ ] Tab order follows reading direction
- [ ] Charts with directional axes flip appropriately
- [ ] Phone numbers and numeric fields remain LTR (universal convention)
- [ ] Text input fields support mixed-direction entry

## Pseudo-Localization

### What It Catches

| Issue | Pseudo-Loc Signal |
|-------|-------------------|
| Hardcoded string | Appears without pseudo markers |
| Text overflow | Expanded pseudo text breaks layout |
| Concatenation | Fragments appear independently |
| Missing placeholder | Placeholder name shown literally |
| Fixed-width container | Pseudo text clips or overflows |

### Pseudo-Locale Configuration

```
// Pseudo-locale transforms:
// 1. Wrap: [brackets] around every string
// 2. Expand: pad by ~40% with extra characters
// 3. Accent: replace ASCII with accented equivalents (a→á, e→é)
// 4. Mirror: optionally swap to RTL for layout testing

// Example:
// Original: "Account Balance"
// Pseudo:   "[Àççöüñţ ßáláñçé~~~~~~~~~~~~]"
```

## Translation Workflow

| Step | Owner | Tool/Process |
|------|-------|-------------|
| 1. Extract strings | Developer | i18n extraction CLI |
| 2. Upload to TMS | CI pipeline | Automated on merge to `develop` |
| 3. Translate | Translation team | Translation Management System |
| 4. Review | Native speaker + developer | TMS review workflow |
| 5. Download | CI pipeline | Automated; creates PR with updated locale files |
| 6. Verify | QA | Visual review in app; screenshot comparison |
| 7. Release | Release manager | Included in next release cycle |

### Translation Context Guidelines

Always provide context for translators:

```json
{
  "account.balance.available": {
    "value": "Available Balance: {amount}",
    "description": "Shown below the total balance on account overview. {amount} is a formatted currency value.",
    "maxLength": 50,
    "screenshot": "screenshots/account-balance.png"
  }
}
```

| Context Field | Required | Purpose |
|---------------|----------|---------|
| `description` | Yes | Where the string appears; what placeholders contain |
| `maxLength` | If constrained | Prevents overflow in fixed-width UI elements |
| `screenshot` | Recommended | Visual context for translators |
| `pluralContext` | If plural | Explains what is being counted |
