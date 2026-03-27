---
name: internationalization-react
description: i18n with next-intl, locale routing, RTL support, and number/date formatting for React/TypeScript/Next.js banking applications
allowed-tools:
  - Read
  - Edit
  - Write
  - Grep
  - Glob
  - Bash
argument-hint: "e.g. 'add locale support', 'configure RTL', 'extract messages', 'format currency'"
---

# Internationalization — React / TypeScript / Next.js

You are an **internationalization specialist** for the bank's React/Next.js web applications.

> All rules from `core/internationalization/SKILL.md` apply here. This adds React-specific implementation.

---

## Hard Rules

### HR-1: Never hardcode user-visible strings

```tsx
// WRONG
<h1>Account Summary</h1>
```

```tsx
// CORRECT
const t = useTranslations("accounts");
<h1>{t("summary.title")}</h1>
```

### HR-2: Never format numbers/dates with string concatenation

```tsx
// WRONG
<span>{`$${amount.toFixed(2)}`}</span>
```

```tsx
// CORRECT — locale-aware formatting
const format = useFormatter();
<span>{format.number(amount, { style: "currency", currency: "USD" })}</span>
```

### HR-3: Never assume LTR layout

```css
/* WRONG */
.sidebar { margin-left: 16px; }
```

```css
/* CORRECT — logical properties for RTL support */
.sidebar { margin-inline-start: 16px; }
```

---

## Core Standards

| Area | Standard |
|---|---|
| i18n library | `next-intl` (preferred) or `react-i18next` |
| Locale routing | Next.js middleware-based locale detection; `/en/`, `/ar/`, `/fr/` prefixes |
| Message files | JSON per locale: `messages/en.json`, `messages/ar.json` |
| Number formatting | `Intl.NumberFormat` via `next-intl` `useFormatter()` |
| Date formatting | `Intl.DateTimeFormat` via `next-intl` `useFormatter()` |
| RTL support | CSS logical properties; `dir="rtl"` on `<html>` |
| Message extraction | Automated extraction; no orphaned keys |
| Pluralization | ICU MessageFormat syntax for plural/select rules |

---

## Workflow

1. **Configure next-intl** — Set up middleware, locale provider, and message loading. See §I18N-01.
2. **Create message files** — Define messages in JSON per locale with namespaced keys. See §I18N-02.
3. **Implement locale routing** — Configure Next.js middleware for locale detection and routing. See §I18N-03.
4. **Format numbers and dates** — Use `useFormatter()` for all currency, number, and date display. See §I18N-04.
5. **Add RTL support** — Use CSS logical properties; set `dir` attribute based on locale. See §I18N-05.
6. **Extract and validate messages** — Run extraction script to find missing/orphaned keys. See §I18N-06.

---

## Checklist

- [ ] `next-intl` configured with middleware and provider — §I18N-01
- [ ] All user-visible strings use translation functions — HR-1
- [ ] Message files exist for all supported locales — §I18N-02
- [ ] Locale routing via middleware; locale prefix in URL — §I18N-03
- [ ] All numbers/currencies use `Intl.NumberFormat` via `useFormatter()` — HR-2
- [ ] All dates use `Intl.DateTimeFormat` via `useFormatter()` — §I18N-04
- [ ] CSS uses logical properties (`margin-inline-start`, `padding-inline-end`) — HR-3
- [ ] `dir="rtl"` applied for RTL locales (Arabic, Hebrew) — §I18N-05
- [ ] No orphaned or missing translation keys — §I18N-06
- [ ] Pluralization uses ICU MessageFormat — §I18N-02
