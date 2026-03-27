# Documentation — React / Next.js Reference

## §DOC-01: Props Interface Documentation

### Complete Props Example

```tsx
// components/ui/Button/Button.tsx

/**
 * Visual style variant for the button.
 * - `primary` — Main call-to-action (e.g., "Submit Transfer")
 * - `secondary` — Secondary actions (e.g., "Cancel")
 * - `danger` — Destructive actions (e.g., "Delete Account")
 * - `ghost` — Minimal emphasis (e.g., inline links)
 */
type ButtonVariant = "primary" | "secondary" | "danger" | "ghost";

/** Size options following the bank's design system spacing scale. */
type ButtonSize = "sm" | "md" | "lg";

/**
 * Props for the {@link Button} component.
 *
 * @example
 * ```tsx
 * <Button variant="primary" size="md" onClick={handleSubmit}>
 *   Submit Transfer
 * </Button>
 * ```
 */
interface ButtonProps {
  /** Button content — text or icon+text combination. */
  children: React.ReactNode;
  /** Visual style variant. @default "primary" */
  variant?: ButtonVariant;
  /** Button size following design system scale. @default "md" */
  size?: ButtonSize;
  /** HTML button type attribute. @default "button" */
  type?: "button" | "submit" | "reset";
  /** Whether the button is in a disabled state. @default false */
  disabled?: boolean;
  /** Whether to show a loading spinner and disable interaction. @default false */
  isLoading?: boolean;
  /** Accessible label when `children` is icon-only. */
  "aria-label"?: string;
  /** Click handler. Not called when `disabled` or `isLoading` is true. */
  onClick?: (event: React.MouseEvent<HTMLButtonElement>) => void;
  /** Additional CSS class names. */
  className?: string;
}
```

### Complex Domain Props

```tsx
// components/features/transfers/TransferForm.tsx

/** Currency codes supported by the bank's transfer system. */
type SupportedCurrency = "USD" | "EUR" | "GBP" | "CHF" | "JPY";

/**
 * Props for the {@link TransferForm} component.
 *
 * Renders a multi-step form for initiating fund transfers between accounts.
 * Validates input against daily limits and account balances before submission.
 */
interface TransferFormProps {
  /** List of accounts available as transfer source. */
  sourceAccounts: Account[];
  /** Pre-selected source account ID (e.g., from account detail page). */
  defaultFromAccount?: string;
  /** Maximum transfer amount allowed per transaction. */
  maxAmount: number;
  /** Daily remaining transfer allowance. */
  dailyRemaining: number;
  /** Supported currencies for this transfer type. */
  currencies: SupportedCurrency[];
  /**
   * Callback fired on successful form submission.
   * @param data - Validated transfer request data.
   * @returns Promise that resolves when the transfer is accepted.
   */
  onSubmit: (data: TransferRequest) => Promise<void>;
  /** Callback fired when user cancels the transfer. */
  onCancel: () => void;
}
```

---

## §DOC-02: Component TSDoc

```tsx
// components/ui/Card/Card.tsx

/**
 * Container component for displaying grouped content with consistent
 * padding, borders, and optional header/footer sections.
 *
 * Used throughout the banking dashboard for account cards, transaction
 * summaries, and notification panels.
 *
 * @example
 * ```tsx
 * <Card title="Account Balance" variant="elevated">
 *   <CurrencyDisplay amount={150000} currency="USD" />
 * </Card>
 * ```
 *
 * @example
 * ```tsx
 * // With footer actions
 * <Card
 *   title="Pending Transfers"
 *   footer={<Button variant="ghost">View All</Button>}
 * >
 *   <TransferList transfers={pending} />
 * </Card>
 * ```
 *
 * @see {@link CardProps} for full prop documentation.
 */
export function Card({ title, children, footer, variant = "default" }: CardProps) {
  return (
    <section className={`card card-${variant}`}>
      {title && <h3 className="card-title">{title}</h3>}
      <div className="card-body">{children}</div>
      {footer && <footer className="card-footer">{footer}</footer>}
    </section>
  );
}
```

---

## §DOC-03: Storybook Stories

### Button Stories

```tsx
// components/ui/Button/Button.stories.tsx
import type { Meta, StoryObj } from "@storybook/react";
import { fn } from "@storybook/test";
import { Button } from "./Button";

const meta = {
  title: "UI/Button",
  component: Button,
  tags: ["autodocs"],
  parameters: {
    docs: {
      description: {
        component:
          "Primary interactive element for triggering actions. Follows the bank's design system for consistent styling across all applications.",
      },
    },
  },
  argTypes: {
    variant: {
      control: "select",
      options: ["primary", "secondary", "danger", "ghost"],
      description: "Visual style variant",
    },
    size: {
      control: "select",
      options: ["sm", "md", "lg"],
      description: "Button size",
    },
    isLoading: {
      control: "boolean",
      description: "Shows loading spinner",
    },
    disabled: {
      control: "boolean",
    },
  },
  args: {
    onClick: fn(),
  },
} satisfies Meta<typeof Button>;

export default meta;
type Story = StoryObj<typeof meta>;

/** Default primary button used for main call-to-action. */
export const Primary: Story = {
  args: {
    children: "Submit Transfer",
    variant: "primary",
    size: "md",
  },
};

/** Secondary button for non-primary actions like "Cancel". */
export const Secondary: Story = {
  args: {
    children: "Cancel",
    variant: "secondary",
  },
};

/** Danger variant for destructive actions that require confirmation. */
export const Danger: Story = {
  args: {
    children: "Delete Account",
    variant: "danger",
  },
};

/** Loading state shown during form submission or async operations. */
export const Loading: Story = {
  args: {
    children: "Processing...",
    isLoading: true,
  },
};

/** Disabled state when preconditions are not met. */
export const Disabled: Story = {
  args: {
    children: "Submit",
    disabled: true,
  },
};

/** All sizes side by side for visual comparison. */
export const Sizes: Story = {
  render: () => (
    <div style={{ display: "flex", gap: "1rem", alignItems: "center" }}>
      <Button size="sm">Small</Button>
      <Button size="md">Medium</Button>
      <Button size="lg">Large</Button>
    </div>
  ),
};
```

### Complex Component Story

```tsx
// components/features/accounts/AccountCard.stories.tsx
import type { Meta, StoryObj } from "@storybook/react";
import { AccountCard } from "./AccountCard";

const meta = {
  title: "Features/Accounts/AccountCard",
  component: AccountCard,
  tags: ["autodocs"],
  decorators: [
    (Story) => (
      <div style={{ maxWidth: 400 }}>
        <Story />
      </div>
    ),
  ],
} satisfies Meta<typeof AccountCard>;

export default meta;
type Story = StoryObj<typeof meta>;

export const CheckingAccount: Story = {
  args: {
    account: {
      id: "acc-001",
      name: "Operating Account",
      accountNumber: "1234567890",
      balance: 150_000.0,
      currency: "USD",
      type: "checking",
    },
  },
};

export const NegativeBalance: Story = {
  args: {
    account: {
      id: "acc-003",
      name: "Overdraft Account",
      accountNumber: "5555555555",
      balance: -2_500.0,
      currency: "USD",
      type: "checking",
    },
  },
};

export const ZeroBalance: Story = {
  args: {
    account: {
      id: "acc-004",
      name: "New Account",
      accountNumber: "9999999999",
      balance: 0,
      currency: "USD",
      type: "savings",
    },
  },
};
```

---

## §DOC-04: Feature README Template

```markdown
<!-- components/features/transfers/README.md -->

# Transfers Feature

## Purpose

Manages fund transfer initiation, confirmation, and history display for the
online banking dashboard. Supports domestic (ACH) and wire transfers.

## Architecture

- **TransferForm** — Multi-step form with validation (client component)
- **TransferHistory** — Paginated list of past transfers (server component)
- **TransferConfirmation** — Review and confirm modal (client component)

## Dependencies

| Dependency | Purpose |
|---|---|
| `@tanstack/react-query` | Server state management for transfer list |
| `zod` | Form input validation |
| `react-error-boundary` | Error isolation for transfer section |

## Usage

```tsx
import { TransferForm } from "@/components/features/transfers";

<TransferForm
  sourceAccounts={accounts}
  maxAmount={100_000}
  dailyRemaining={50_000}
  currencies={["USD", "EUR"]}
  onSubmit={handleTransfer}
  onCancel={handleCancel}
/>
```

## State Management

Transfer form state is local (React `useState`). Transfer history uses
TanStack Query with the `transferKeys.list()` query key. Invalidation
happens automatically after successful transfer submission.

## Testing

- Unit tests: `TransferForm.test.tsx`, `TransferHistory.test.tsx`
- E2E: `e2e/transfer.spec.ts` (Playwright)
- Coverage target: 85% for this feature
```

---

## §DOC-05: Route Handler Documentation

```ts
// app/api/transfers/route.ts

/**
 * Transfer API Route Handler.
 *
 * @remarks
 * Requires authentication via NextAuth.js session.
 * All requests are validated with Zod before processing.
 *
 * @example GET /api/transfers?status=pending&page=1&limit=20
 * @example POST /api/transfers { fromAccount, toAccount, amount, currency }
 */

/**
 * List transfers for the authenticated user.
 *
 * @param request - Incoming request with optional query params:
 *   - `status` — Filter by transfer status ("pending" | "completed" | "failed")
 *   - `page` — Page number (default: 1)
 *   - `limit` — Items per page (default: 20, max: 100)
 *
 * @returns JSON array of {@link Transfer} objects with pagination metadata.
 *
 * @example Response 200
 * ```json
 * {
 *   "data": [{ "id": "txn-001", "amount": 5000, "status": "completed" }],
 *   "pagination": { "page": 1, "limit": 20, "total": 42 }
 * }
 * ```
 */
export async function GET(request: Request) {
  // ...
}

/**
 * Create a new fund transfer.
 *
 * @param request - JSON body matching {@link TransferRequest}:
 *   - `fromAccount` — Source account number (10 digits)
 *   - `toAccount` — Destination account number (10 digits)
 *   - `amount` — Transfer amount (positive, max 1,000,000)
 *   - `currency` — ISO 4217 currency code
 *
 * @returns 202 Accepted with the created {@link Transfer} object.
 * @throws 400 — Validation error
 * @throws 401 — Not authenticated
 * @throws 422 — Business rule violation (insufficient funds, limit exceeded)
 */
export async function POST(request: Request) {
  // ...
}
```
