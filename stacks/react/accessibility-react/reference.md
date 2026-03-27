# Accessibility — React / Next.js Reference

## §A11Y-01: Semantic HTML Patterns

### Page Layout

```tsx
// app/dashboard/layout.tsx
export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <>
      <a href="#main-content" className="skip-link">
        Skip to main content
      </a>
      <header role="banner">
        <nav aria-label="Primary navigation">
          <ul>
            <li><a href="/dashboard" aria-current="page">Dashboard</a></li>
            <li><a href="/dashboard/accounts">Accounts</a></li>
            <li><a href="/dashboard/transfers">Transfers</a></li>
          </ul>
        </nav>
      </header>
      <main id="main-content" tabIndex={-1}>
        {children}
      </main>
      <footer role="contentinfo">
        <p>&copy; 2025 National Bank. All rights reserved.</p>
      </footer>
    </>
  );
}
```

### Data Table

```tsx
// components/TransactionTable/TransactionTable.tsx
interface Transaction {
  id: string;
  date: string;
  description: string;
  amount: number;
  balance: number;
}

export function TransactionTable({ transactions }: { transactions: Transaction[] }) {
  return (
    <table aria-label="Recent transactions">
      <caption className="sr-only">
        Transaction history for the current period
      </caption>
      <thead>
        <tr>
          <th scope="col">Date</th>
          <th scope="col">Description</th>
          <th scope="col" className="text-right">Amount</th>
          <th scope="col" className="text-right">Balance</th>
        </tr>
      </thead>
      <tbody>
        {transactions.map((txn) => (
          <tr key={txn.id}>
            <td>
              <time dateTime={txn.date}>
                {new Date(txn.date).toLocaleDateString()}
              </time>
            </td>
            <td>{txn.description}</td>
            <td className="text-right" aria-label={`Amount: ${txn.amount}`}>
              {formatCurrency(txn.amount)}
            </td>
            <td className="text-right" aria-label={`Balance: ${txn.balance}`}>
              {formatCurrency(txn.balance)}
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
```

---

## §A11Y-02: Skip Link Implementation

```tsx
// components/SkipLink/SkipLink.tsx
export function SkipLink() {
  return (
    <a
      href="#main-content"
      className="
        absolute left-[-9999px] top-2 z-50
        rounded bg-blue-900 px-4 py-2 text-white
        focus:left-2 focus:outline-2 focus:outline-offset-2
      "
    >
      Skip to main content
    </a>
  );
}
```

```css
/* Alternative CSS approach */
.skip-link {
  position: absolute;
  left: -9999px;
  top: 0.5rem;
  z-index: 9999;
  padding: 0.5rem 1rem;
  background: #003366;
  color: #ffffff;
  border-radius: 4px;
  text-decoration: none;
}

.skip-link:focus {
  left: 0.5rem;
  outline: 2px solid #005fcc;
  outline-offset: 2px;
}
```

---

## §A11Y-03: Focus Management

### FocusTrap for Modals

```tsx
// components/Modal/Modal.tsx
"use client";

import { useEffect, useRef, useCallback } from "react";
import { createPortal } from "react-dom";

interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  children: React.ReactNode;
}

export function Modal({ isOpen, onClose, title, children }: ModalProps) {
  const dialogRef = useRef<HTMLDialogElement>(null);
  const previousFocusRef = useRef<HTMLElement | null>(null);

  useEffect(() => {
    if (isOpen) {
      previousFocusRef.current = document.activeElement as HTMLElement;
      dialogRef.current?.showModal();
    } else {
      dialogRef.current?.close();
      previousFocusRef.current?.focus();
    }
  }, [isOpen]);

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    },
    [onClose]
  );

  if (!isOpen) return null;

  return createPortal(
    <dialog
      ref={dialogRef}
      aria-labelledby="modal-title"
      aria-modal="true"
      onKeyDown={handleKeyDown}
      className="modal-overlay"
    >
      <div role="document" className="modal-content">
        <header className="modal-header">
          <h2 id="modal-title">{title}</h2>
          <button
            type="button"
            onClick={onClose}
            aria-label="Close dialog"
          >
            &times;
          </button>
        </header>
        <div className="modal-body">{children}</div>
      </div>
    </dialog>,
    document.body
  );
}
```

### Focus Restore on Route Change

```tsx
// hooks/useFocusOnRouteChange.ts
"use client";

import { useEffect } from "react";
import { usePathname } from "next/navigation";

export function useFocusOnRouteChange() {
  const pathname = usePathname();

  useEffect(() => {
    const main = document.getElementById("main-content");
    if (main) {
      main.focus({ preventScroll: false });
    }
  }, [pathname]);
}
```

---

## §A11Y-04: Live Regions

### Toast Notification with aria-live

```tsx
// components/Toast/Toast.tsx
"use client";

import { useEffect, useState } from "react";

interface ToastProps {
  message: string;
  type: "success" | "error" | "info";
  duration?: number;
  onDismiss: () => void;
}

export function Toast({ message, type, duration = 5000, onDismiss }: ToastProps) {
  const [isVisible, setIsVisible] = useState(true);

  useEffect(() => {
    const timer = setTimeout(() => {
      setIsVisible(false);
      onDismiss();
    }, duration);
    return () => clearTimeout(timer);
  }, [duration, onDismiss]);

  if (!isVisible) return null;

  return (
    <div
      role="status"
      aria-live="polite"
      aria-atomic="true"
      className={`toast toast-${type}`}
    >
      <p>{message}</p>
      <button
        type="button"
        onClick={onDismiss}
        aria-label="Dismiss notification"
      >
        &times;
      </button>
    </div>
  );
}
```

### Loading State Announcer

```tsx
// components/LoadingAnnouncer/LoadingAnnouncer.tsx
interface LoadingAnnouncerProps {
  isLoading: boolean;
  loadingMessage?: string;
  completedMessage?: string;
}

export function LoadingAnnouncer({
  isLoading,
  loadingMessage = "Loading content",
  completedMessage = "Content loaded",
}: LoadingAnnouncerProps) {
  return (
    <div aria-live="assertive" aria-atomic="true" className="sr-only">
      {isLoading ? loadingMessage : completedMessage}
    </div>
  );
}
```

---

## §A11Y-05: Keyboard Navigation Patterns

### Custom Dropdown with Arrow Key Navigation

```tsx
// components/AccountSelector/AccountSelector.tsx
"use client";

import { useState, useRef, useCallback } from "react";

interface Account {
  id: string;
  name: string;
}

interface AccountSelectorProps {
  accounts: Account[];
  onSelect: (id: string) => void;
  label: string;
}

export function AccountSelector({ accounts, onSelect, label }: AccountSelectorProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [activeIndex, setActiveIndex] = useState(-1);
  const listRef = useRef<HTMLUListElement>(null);

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      switch (e.key) {
        case "ArrowDown":
          e.preventDefault();
          setActiveIndex((prev) => Math.min(prev + 1, accounts.length - 1));
          break;
        case "ArrowUp":
          e.preventDefault();
          setActiveIndex((prev) => Math.max(prev - 1, 0));
          break;
        case "Enter":
        case " ":
          e.preventDefault();
          if (activeIndex >= 0) {
            onSelect(accounts[activeIndex].id);
            setIsOpen(false);
          }
          break;
        case "Escape":
          setIsOpen(false);
          break;
      }
    },
    [accounts, activeIndex, onSelect]
  );

  return (
    <div>
      <label id="selector-label">{label}</label>
      <button
        type="button"
        aria-haspopup="listbox"
        aria-expanded={isOpen}
        aria-labelledby="selector-label"
        onClick={() => setIsOpen(!isOpen)}
        onKeyDown={handleKeyDown}
      >
        Select account
      </button>
      {isOpen && (
        <ul
          ref={listRef}
          role="listbox"
          aria-labelledby="selector-label"
          tabIndex={-1}
          onKeyDown={handleKeyDown}
        >
          {accounts.map((account, index) => (
            <li
              key={account.id}
              role="option"
              aria-selected={index === activeIndex}
              onClick={() => {
                onSelect(account.id);
                setIsOpen(false);
              }}
            >
              {account.name}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
```

---

## §A11Y-06: Automated Accessibility Testing

### jest-axe Component Test

```tsx
// components/AccountCard/AccountCard.a11y.test.tsx
import { render } from "@testing-library/react";
import { axe, toHaveNoViolations } from "jest-axe";
import { describe, it, expect } from "vitest";
import { AccountCard } from "./AccountCard";

expect.extend(toHaveNoViolations);

describe("AccountCard accessibility", () => {
  it("has no a11y violations", async () => {
    const { container } = render(
      <AccountCard
        account={{
          id: "acc-001",
          name: "Checking Account",
          balance: 10000,
          currency: "USD",
          accountNumber: "1234567890",
        }}
      />
    );

    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });
});
```

### Playwright axe-core E2E Test

```ts
// e2e/a11y.spec.ts
import { test, expect } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";

test.describe("Accessibility audit", () => {
  test("dashboard has no a11y violations", async ({ page }) => {
    await page.goto("/dashboard");

    const results = await new AxeBuilder({ page })
      .withTags(["wcag2a", "wcag2aa", "wcag22aa"])
      .exclude(".third-party-widget")
      .analyze();

    expect(results.violations).toEqual([]);
  });

  test("transfer form has no a11y violations", async ({ page }) => {
    await page.goto("/dashboard/transfers/new");

    const results = await new AxeBuilder({ page })
      .withTags(["wcag2a", "wcag2aa"])
      .analyze();

    expect(results.violations).toEqual([]);
  });
});
```

---

## §A11Y-07: Color Contrast and Visual Standards

### Tailwind CSS Configuration for Accessible Palette

```ts
// tailwind.config.ts (excerpt — color tokens)
const colors = {
  primary: {
    DEFAULT: "#003366", // 12.5:1 on white — passes AAA
    light: "#005fcc",   // 5.2:1 on white — passes AA
    dark: "#001a33",    // 16.8:1 on white — passes AAA
  },
  danger: {
    DEFAULT: "#b91c1c", // 5.7:1 on white — passes AA
    dark: "#7f1d1d",    // 9.8:1 on white — passes AAA
  },
  success: {
    DEFAULT: "#166534", // 7.1:1 on white — passes AA
  },
  text: {
    primary: "#111827",   // 16:1 on white
    secondary: "#4b5563", // 5.9:1 on white — passes AA
  },
};
```

### Screen Reader Only Utility

```css
/* Tailwind already provides sr-only, but for custom CSS: */
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border-width: 0;
}
```
