# Accessibility — React / Next.js Reference

React and Next.js accessibility patterns for the bank's web applications. See `core/accessibility/SKILL.md` for core rules.

## Core Principle — Semantic HTML First

**Use native HTML elements before reaching for ARIA.** Native elements (`<button>`, `<input>`, `<select>`, `<a>`, `<table>`) have built-in accessibility — keyboard behavior, screen reader roles, and focus management. ARIA is a fallback when no native element fits.

> **First rule of ARIA:** If you can use a native HTML element with built-in semantics, do that instead.

```tsx
// WRONG — div with ARIA bolted on
<div role="button" tabIndex={0} onClick={handleTransfer} onKeyDown={handleKey}>
  Send Money
</div>

// CORRECT — native button, fully accessible out of the box
<button type="button" onClick={handleTransfer}>
  Send Money
</button>
```

## Hard Rules — React-Specific

### Never use `dangerouslySetInnerHTML` without sanitization

```tsx
// WRONG — XSS risk AND screen reader may read raw markup
<div dangerouslySetInnerHTML={{ __html: userContent }} />

// CORRECT — sanitize with DOMPurify, ensure output is semantic
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userContent) }} />
```

### All `<img>` must have `alt` attribute

```tsx
// WRONG — no alt
<img src="/chart.png" />

// CORRECT — meaningful alt
<img src="/chart.png" alt="Account balance trend: $4,200 Jan to $5,100 Mar" />

// CORRECT — decorative
<img src="/decorative-wave.svg" alt="" role="presentation" />
```

### Interactive elements must be native or have full ARIA

```tsx
// WRONG — clickable div, no keyboard support
<div onClick={handleClick}>Click me</div>

// CORRECT — button
<button onClick={handleClick}>Click me</button>

// IF custom element is unavoidable (justify why):
<div
  role="button"
  tabIndex={0}
  onClick={handleClick}
  onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') handleClick(); }}
  aria-label="Click me"
>
  Click me
</div>
```

### Form inputs must have associated labels

```tsx
// WRONG — placeholder only
<input placeholder="Email" />

// CORRECT — visible label
<label htmlFor="email">Email</label>
<input id="email" type="email" autoComplete="email" />

// CORRECT — aria-label when visual label is not possible
<input aria-label="Search accounts" type="search" />
```

## ARIA Patterns for Banking Components

### Live Regions

| Scenario | Implementation |
|----------|---------------|
| Balance update | `<span aria-live="polite">{balance}</span>` |
| Transaction success | `<div role="status">Transfer complete</div>` |
| Transaction failure | `<div role="alert">Transfer failed: insufficient funds</div>` |
| Session warning | `<div role="alertdialog" aria-modal="true">` |
| Form error summary | `<div role="alert" aria-live="assertive">` |
| Search results count | `<span aria-live="polite">{count} results found</span>` |

### Modal Dialog

```tsx
// Accessible modal pattern
<div
  role="dialog"
  aria-modal="true"
  aria-labelledby="modal-title"
  aria-describedby="modal-description"
>
  <h2 id="modal-title">Confirm Transfer</h2>
  <p id="modal-description">
    You are about to transfer $500 to Account ending in 4523.
  </p>
  <button onClick={onConfirm}>Confirm</button>
  <button onClick={onCancel}>Cancel</button>
</div>
```

Requirements:
- Trap focus inside modal (use `FocusTrap` from `focus-trap-react`)
- Return focus to trigger element on close
- Close on Escape key
- Prevent background scroll

### Data Table (Transactions)

```tsx
<table aria-label="Recent transactions">
  <thead>
    <tr>
      <th scope="col">Date</th>
      <th scope="col">Description</th>
      <th scope="col" aria-sort="descending">Amount</th>
      <th scope="col">Status</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Mar 15, 2026</td>
      <td>Grocery Store</td>
      <td>-$45.00</td>
      <td>
        <span aria-label="Completed">
          <CheckIcon aria-hidden="true" /> Completed
        </span>
      </td>
    </tr>
  </tbody>
</table>
```

### Skip Link

```tsx
// First element inside <body>
<a href="#main-content" className="skip-link">
  Skip to main content
</a>

// CSS — visible only on focus
.skip-link {
  position: absolute;
  left: -9999px;
  &:focus {
    position: static;
    left: auto;
  }
}
```

## Keyboard Navigation — React

### Focus Management

```tsx
// Move focus after route change (Next.js App Router)
'use client';
import { useEffect, useRef } from 'react';
import { usePathname } from 'next/navigation';

export function FocusOnRouteChange() {
  const pathname = usePathname();
  const mainRef = useRef<HTMLElement>(null);

  useEffect(() => {
    mainRef.current?.focus();
  }, [pathname]);

  return <main ref={mainRef} tabIndex={-1} id="main-content">{children}</main>;
}
```

### Focus Trap for Modals

```tsx
import { FocusTrap } from 'focus-trap-react';

<FocusTrap>
  <div role="dialog" aria-modal="true" aria-labelledby="title">
    <h2 id="title">Confirm OTP</h2>
    <input aria-label="Enter OTP" autoFocus />
    <button>Verify</button>
    <button onClick={onClose}>Cancel</button>
  </div>
</FocusTrap>
```

### Keyboard Event Handling

```tsx
// Custom keyboard handler for non-native interactive elements
function handleKeyDown(e: React.KeyboardEvent) {
  switch (e.key) {
    case 'Enter':
    case ' ':
      e.preventDefault();
      handleAction();
      break;
    case 'Escape':
      handleClose();
      break;
  }
}
```

## Accessible Forms — React

### Error Handling Pattern

```tsx
<form aria-label="Fund Transfer" onSubmit={handleSubmit}>
  {errors.length > 0 && (
    <div role="alert" aria-live="assertive">
      <h3>Please fix {errors.length} error(s):</h3>
      <ul>
        {errors.map((err) => (
          <li key={err.field}>
            <a href={`#${err.field}`}>{err.message}</a>
          </li>
        ))}
      </ul>
    </div>
  )}

  <div>
    <label htmlFor="amount">Amount</label>
    <input
      id="amount"
      type="text"
      inputMode="decimal"
      aria-required="true"
      aria-invalid={!!errors.find((e) => e.field === 'amount')}
      aria-describedby="amount-error amount-hint"
      autoComplete="transaction-amount"
    />
    <span id="amount-hint">Enter amount between $0.01 and $50,000</span>
    {errors.find((e) => e.field === 'amount') && (
      <span id="amount-error" role="alert">
        {errors.find((e) => e.field === 'amount')?.message}
      </span>
    )}
  </div>

  <button type="submit">Review Transfer</button>
</form>
```

## Reduced Motion — React / CSS

```tsx
// React hook
const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

// CSS — disable animations when user prefers
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}

// Tailwind CSS
<div className="motion-safe:animate-fadeIn motion-reduce:animate-none">
```

## Next.js Specific

### Metadata for Accessibility

```tsx
// app/layout.tsx
export const metadata: Metadata = {
  title: { template: '%s — National Bank', default: 'National Bank' },
};

// Sets <html lang="en"> via Next.js
export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
```

### Landmarks

```tsx
// Proper landmark structure
<header role="banner">
  <nav aria-label="Primary navigation">{/* main nav */}</nav>
</header>

<main id="main-content" tabIndex={-1}>
  {children}
</main>

<aside aria-label="Account summary">
  {/* sidebar */}
</aside>

<footer role="contentinfo">
  {/* footer */}
</footer>
```

## Testing — React

### Automated: jest-axe

```tsx
import { render } from '@testing-library/react';
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

test('transfer form has no a11y violations', async () => {
  const { container } = render(<TransferForm />);
  const results = await axe(container);
  expect(results).toHaveNoViolations();
});
```

### Automated: Testing Library Queries

```tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

test('submit button is keyboard accessible', async () => {
  render(<TransferForm />);
  const button = screen.getByRole('button', { name: /submit/i });

  // Verify it's focusable
  await userEvent.tab();
  expect(button).toHaveFocus();

  // Verify keyboard activation
  await userEvent.keyboard('{Enter}');
  // assert submission occurred
});

test('error messages are announced', async () => {
  render(<TransferForm />);
  await userEvent.click(screen.getByRole('button', { name: /submit/i }));

  // Verify alert role
  expect(screen.getByRole('alert')).toBeInTheDocument();
});
```

### Playwright E2E Accessibility

```typescript
import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

test('transfer page passes a11y audit', async ({ page }) => {
  await page.goto('/transfer');
  const results = await new AxeBuilder({ page })
    .withTags(['wcag2a', 'wcag2aa'])
    .analyze();
  expect(results.violations).toEqual([]);
});
```

### Manual Testing Checklist

| Test | Method |
|------|--------|
| Keyboard: Tab through all | Tab without mouse, verify logical order |
| Keyboard: Activate elements | Enter/Space on buttons, links |
| Keyboard: Escape closes | Escape dismisses modals, dropdowns |
| Screen reader: NVDA/VoiceOver | Navigate entire page, verify announcements |
| Zoom: 200% browser zoom | No content loss, no horizontal scroll |
| Reduced motion | Enable `prefers-reduced-motion`, verify no animations |
| High contrast | Windows High Contrast mode, verify readability |

## Audit Report Format

```
## React/Next.js Accessibility Audit Report
**Level:** AA | **Framework:** Next.js 14 | **Date:** YYYY-MM-DD

### Summary
- CRITICAL: N issues
- MAJOR: N issues
- MINOR: N issues

### Findings

#### [CRITICAL] Clickable div not keyboard accessible
**File:** src/components/AccountCard.tsx:L32
**Issue:** `<div onClick>` without role, tabIndex, or keyboard handler
**Affects:** Keyboard users, screen readers
**Fix:** Replace with `<button>` or add role="button" + tabIndex + onKeyDown
**WCAG:** 2.1.1 Keyboard (A)

#### [MAJOR] Form input missing label
**File:** src/components/SearchBar.tsx:L15
**Issue:** `<input placeholder="Search">` with no `<label>` or `aria-label`
**Affects:** Screen readers, voice control users
**Fix:** Add `aria-label="Search accounts"`
**WCAG:** 1.3.1 Info and Relationships (A)

### Passed Checks
- [✓] Skip link present and functional
- [✓] Landmark regions defined
- [✓] Live regions for transaction status
```
