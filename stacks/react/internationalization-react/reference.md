# Internationalization — React / Next.js Reference

## §I18N-01: next-intl Configuration

### Plugin Setup

```ts
// next.config.ts
import createNextIntlPlugin from "next-intl/plugin";

const withNextIntl = createNextIntlPlugin("./i18n/request.ts");

const nextConfig = {
  // other Next.js config
};

export default withNextIntl(nextConfig);
```

### Request Configuration

```ts
// i18n/request.ts
import { getRequestConfig } from "next-intl/server";
import { routing } from "./routing";

export default getRequestConfig(async ({ requestLocale }) => {
  let locale = await requestLocale;

  if (!locale || !routing.locales.includes(locale as any)) {
    locale = routing.defaultLocale;
  }

  return {
    locale,
    messages: (await import(`../messages/${locale}.json`)).default,
  };
});
```

### Routing Configuration

```ts
// i18n/routing.ts
import { defineRouting } from "next-intl/routing";
import { createNavigation } from "next-intl/navigation";

export const routing = defineRouting({
  locales: ["en", "ar", "fr", "es", "zh"],
  defaultLocale: "en",
  localePrefix: "always",
});

export const { Link, redirect, usePathname, useRouter } =
  createNavigation(routing);
```

### Root Layout with Locale Provider

```tsx
// app/[locale]/layout.tsx
import { NextIntlClientProvider } from "next-intl";
import { getMessages, getTranslations } from "next-intl/server";
import { notFound } from "next/navigation";
import { routing } from "@/i18n/routing";

interface Props {
  children: React.ReactNode;
  params: Promise<{ locale: string }>;
}

export default async function LocaleLayout({ children, params }: Props) {
  const { locale } = await params;

  if (!routing.locales.includes(locale as any)) {
    notFound();
  }

  const messages = await getMessages();
  const dir = ["ar", "he"].includes(locale) ? "rtl" : "ltr";

  return (
    <html lang={locale} dir={dir}>
      <body>
        <NextIntlClientProvider messages={messages}>
          {children}
        </NextIntlClientProvider>
      </body>
    </html>
  );
}

export async function generateMetadata({ params }: Props) {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "metadata" });
  return { title: t("title") };
}
```

---

## §I18N-02: Message File Structure

### English Messages

```json
// messages/en.json
{
  "metadata": {
    "title": "National Bank — Online Banking"
  },
  "common": {
    "loading": "Loading...",
    "error": "An error occurred",
    "retry": "Try again",
    "cancel": "Cancel",
    "confirm": "Confirm",
    "save": "Save",
    "back": "Go back"
  },
  "accounts": {
    "summary": {
      "title": "Account Summary",
      "totalBalance": "Total Balance"
    },
    "types": {
      "checking": "Checking Account",
      "savings": "Savings Account",
      "investment": "Investment Account"
    },
    "transactionCount": "{count, plural, =0 {No transactions} one {1 transaction} other {{count} transactions}}"
  },
  "transfers": {
    "title": "Transfer Funds",
    "form": {
      "fromAccount": "From Account",
      "toAccount": "To Account",
      "amount": "Amount",
      "reference": "Reference (optional)",
      "submit": "Submit Transfer"
    },
    "confirmation": {
      "title": "Confirm Transfer",
      "message": "You are about to transfer {amount} from {from} to {to}.",
      "fee": "Transaction fee: {fee}"
    },
    "status": {
      "pending": "Pending",
      "completed": "Completed",
      "failed": "Failed"
    }
  },
  "auth": {
    "signIn": "Sign In",
    "signOut": "Sign Out",
    "sessionExpired": "Your session has expired. Please sign in again."
  }
}
```

### Arabic Messages (RTL)

```json
// messages/ar.json
{
  "metadata": {
    "title": "البنك الوطني — الخدمات المصرفية"
  },
  "common": {
    "loading": "جاري التحميل...",
    "error": "حدث خطأ",
    "retry": "حاول مرة أخرى",
    "cancel": "إلغاء",
    "confirm": "تأكيد",
    "save": "حفظ",
    "back": "رجوع"
  },
  "accounts": {
    "summary": {
      "title": "ملخص الحساب",
      "totalBalance": "الرصيد الإجمالي"
    },
    "types": {
      "checking": "حساب جاري",
      "savings": "حساب توفير",
      "investment": "حساب استثمار"
    },
    "transactionCount": "{count, plural, =0 {لا توجد معاملات} one {معاملة واحدة} two {معاملتان} few {{count} معاملات} many {{count} معاملة} other {{count} معاملة}}"
  },
  "transfers": {
    "title": "تحويل الأموال",
    "form": {
      "fromAccount": "من حساب",
      "toAccount": "إلى حساب",
      "amount": "المبلغ",
      "reference": "المرجع (اختياري)",
      "submit": "إرسال التحويل"
    }
  }
}
```

---

## §I18N-03: Locale Routing Middleware

```ts
// middleware.ts
import createMiddleware from "next-intl/middleware";
import { routing } from "./i18n/routing";

export default createMiddleware(routing);

export const config = {
  matcher: [
    // Match all pathnames except internals and static files
    "/((?!api|_next|_vercel|.*\\..*).*)",
  ],
};
```

---

## §I18N-04: Number and Date Formatting

### Currency Formatting Component

```tsx
// components/CurrencyDisplay.tsx
"use client";

import { useFormatter } from "next-intl";

interface CurrencyDisplayProps {
  amount: number;
  currency: string;
}

export function CurrencyDisplay({ amount, currency }: CurrencyDisplayProps) {
  const format = useFormatter();

  return (
    <span>
      {format.number(amount, {
        style: "currency",
        currency,
        minimumFractionDigits: 2,
        maximumFractionDigits: 2,
      })}
    </span>
  );
}
```

### Date Formatting Component

```tsx
// components/DateDisplay.tsx
"use client";

import { useFormatter } from "next-intl";

interface DateDisplayProps {
  date: string | Date;
  variant?: "short" | "long" | "relative";
}

export function DateDisplay({ date, variant = "short" }: DateDisplayProps) {
  const format = useFormatter();
  const dateObj = typeof date === "string" ? new Date(date) : date;

  if (variant === "relative") {
    return <time dateTime={dateObj.toISOString()}>{format.relativeTime(dateObj)}</time>;
  }

  const options: Intl.DateTimeFormatOptions =
    variant === "long"
      ? { year: "numeric", month: "long", day: "numeric", hour: "2-digit", minute: "2-digit" }
      : { year: "numeric", month: "short", day: "numeric" };

  return (
    <time dateTime={dateObj.toISOString()}>
      {format.dateTime(dateObj, options)}
    </time>
  );
}
```

### Server-Side Formatting

```ts
// lib/format.ts
import { getFormatter } from "next-intl/server";

export async function formatServerCurrency(amount: number, currency: string) {
  const format = await getFormatter();
  return format.number(amount, { style: "currency", currency });
}

export async function formatServerDate(date: Date) {
  const format = await getFormatter();
  return format.dateTime(date, { dateStyle: "medium" });
}
```

---

## §I18N-05: RTL Support

### CSS Logical Properties Reference

```css
/* Physical (WRONG for RTL) → Logical (CORRECT) */

/* Margins */
margin-left    → margin-inline-start
margin-right   → margin-inline-end

/* Padding */
padding-left   → padding-inline-start
padding-right  → padding-inline-end

/* Positioning */
left           → inset-inline-start
right          → inset-inline-end

/* Borders */
border-left    → border-inline-start
border-right   → border-inline-end

/* Text alignment */
text-align: left  → text-align: start
text-align: right → text-align: end

/* Flexbox — already supports RTL natively */
```

### Tailwind CSS RTL Configuration

```tsx
// components/Sidebar/Sidebar.tsx
export function Sidebar({ children }: { children: React.ReactNode }) {
  return (
    <aside className="
      fixed inset-y-0 inset-inline-start-0
      w-64 border-inline-end
      ps-4 pe-4
    ">
      {children}
    </aside>
  );
}
```

### Direction-Aware Icon Component

```tsx
// components/DirectionalIcon.tsx
"use client";

import { useLocale } from "next-intl";

interface DirectionalIconProps {
  ltrIcon: React.ReactNode;
  rtlIcon: React.ReactNode;
}

export function DirectionalIcon({ ltrIcon, rtlIcon }: DirectionalIconProps) {
  const locale = useLocale();
  const isRtl = ["ar", "he", "fa"].includes(locale);
  return <>{isRtl ? rtlIcon : ltrIcon}</>;
}
```

---

## §I18N-06: Message Extraction and Validation

### Extraction Script

```ts
// scripts/check-i18n.mts
import { readFileSync, readdirSync } from "fs";
import { join } from "path";

const MESSAGES_DIR = "./messages";
const locales = readdirSync(MESSAGES_DIR)
  .filter((f) => f.endsWith(".json"))
  .map((f) => f.replace(".json", ""));

const messages: Record<string, Record<string, unknown>> = {};
for (const locale of locales) {
  messages[locale] = JSON.parse(
    readFileSync(join(MESSAGES_DIR, `${locale}.json`), "utf-8")
  );
}

function getKeys(obj: Record<string, unknown>, prefix = ""): string[] {
  return Object.entries(obj).flatMap(([key, value]) => {
    const fullKey = prefix ? `${prefix}.${key}` : key;
    if (typeof value === "object" && value !== null) {
      return getKeys(value as Record<string, unknown>, fullKey);
    }
    return [fullKey];
  });
}

const baseLocale = "en";
const baseKeys = new Set(getKeys(messages[baseLocale]));

let hasErrors = false;

for (const locale of locales) {
  if (locale === baseLocale) continue;
  const localeKeys = new Set(getKeys(messages[locale]));

  for (const key of baseKeys) {
    if (!localeKeys.has(key)) {
      console.error(`MISSING: ${locale} is missing key "${key}"`);
      hasErrors = true;
    }
  }

  for (const key of localeKeys) {
    if (!baseKeys.has(key)) {
      console.warn(`ORPHANED: ${locale} has extra key "${key}"`);
    }
  }
}

if (hasErrors) process.exit(1);
console.log("All locale files are in sync.");
```

```json
{
  "scripts": {
    "i18n:check": "tsx scripts/check-i18n.mts"
  }
}
```
