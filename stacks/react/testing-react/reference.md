# Testing — React / Next.js Reference

## §TEST-01: Vitest Configuration

```ts
// vitest.config.ts
import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import tsconfigPaths from "vite-tsconfig-paths";

export default defineConfig({
  plugins: [react(), tsconfigPaths()],
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: ["./test/setup.ts"],
    include: ["**/*.test.{ts,tsx}"],
    coverage: {
      provider: "istanbul",
      reporter: ["text", "lcov", "json-summary"],
      thresholds: {
        statements: 80,
        branches: 80,
        functions: 80,
        lines: 80,
      },
      exclude: [
        "node_modules/",
        "test/",
        "**/*.d.ts",
        "**/*.config.{ts,js}",
        "**/types/**",
      ],
    },
  },
});
```

### Test Setup File

```ts
// test/setup.ts
import "@testing-library/jest-dom/vitest";
import { cleanup } from "@testing-library/react";
import { afterEach, beforeAll, afterAll } from "vitest";
import { server } from "./mocks/server";

beforeAll(() => server.listen({ onUnhandledRequest: "error" }));
afterEach(() => {
  cleanup();
  server.resetHandlers();
});
afterAll(() => server.close());
```

---

## §TEST-02: MSW Setup and API Mocking

### Server Setup

```ts
// test/mocks/server.ts
import { setupServer } from "msw/node";
import { handlers } from "./handlers";

export const server = setupServer(...handlers);
```

### Typed Request Handlers

```ts
// test/mocks/handlers.ts
import { http, HttpResponse } from "msw";
import type { Account, Transfer } from "@/types/api";

const mockAccounts: Account[] = [
  {
    id: "acc-001",
    accountNumber: "1234567890",
    name: "Operating Account",
    balance: 150_000.0,
    currency: "USD",
  },
  {
    id: "acc-002",
    accountNumber: "0987654321",
    name: "Savings Account",
    balance: 500_000.0,
    currency: "USD",
  },
];

const mockTransfers: Transfer[] = [
  {
    id: "txn-001",
    fromAccount: "1234567890",
    toAccount: "0987654321",
    amount: 5_000,
    currency: "USD",
    status: "completed",
    createdAt: "2025-01-15T10:30:00Z",
  },
];

export const handlers = [
  http.get("/api/accounts", () => {
    return HttpResponse.json(mockAccounts);
  }),

  http.get("/api/accounts/:id", ({ params }) => {
    const account = mockAccounts.find((a) => a.id === params.id);
    if (!account) return HttpResponse.json(null, { status: 404 });
    return HttpResponse.json(account);
  }),

  http.get("/api/transfers", () => {
    return HttpResponse.json(mockTransfers);
  }),

  http.post("/api/transfers", async ({ request }) => {
    const body = (await request.json()) as Partial<Transfer>;
    const newTransfer: Transfer = {
      id: `txn-${Date.now()}`,
      fromAccount: body.fromAccount!,
      toAccount: body.toAccount!,
      amount: body.amount!,
      currency: body.currency ?? "USD",
      status: "pending",
      createdAt: new Date().toISOString(),
    };
    return HttpResponse.json(newTransfer, { status: 201 });
  }),

  http.get("/api/auth/session", () => {
    return HttpResponse.json({
      user: { name: "Jane Banker", email: "jane@bank.com", role: "analyst" },
    });
  }),
];
```

### Error Handler Overrides for Tests

```ts
// test/mocks/error-handlers.ts
import { http, HttpResponse } from "msw";

export const networkErrorHandlers = [
  http.get("/api/accounts", () => {
    return HttpResponse.error();
  }),
];

export const serverErrorHandlers = [
  http.get("/api/accounts", () => {
    return HttpResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }),
];
```

---

## §TEST-03: Component Testing Patterns

### Basic Component Test

```tsx
// components/AccountCard/AccountCard.test.tsx
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, it, expect, vi } from "vitest";
import { AccountCard } from "./AccountCard";

const mockAccount = {
  id: "acc-001",
  accountNumber: "1234567890",
  name: "Operating Account",
  balance: 150_000.0,
  currency: "USD",
};

describe("AccountCard", () => {
  it("renders account details", () => {
    render(<AccountCard account={mockAccount} />);

    expect(screen.getByText("Operating Account")).toBeInTheDocument();
    expect(screen.getByText("$150,000.00")).toBeInTheDocument();
    expect(screen.getByText(/1234567890/)).toBeInTheDocument();
  });

  it("calls onSelect when clicked", async () => {
    const user = userEvent.setup();
    const onSelect = vi.fn();

    render(<AccountCard account={mockAccount} onSelect={onSelect} />);
    await user.click(screen.getByRole("button", { name: /select account/i }));

    expect(onSelect).toHaveBeenCalledWith("acc-001");
  });

  it("displays masked account number by default", () => {
    render(<AccountCard account={mockAccount} />);
    expect(screen.getByText(/\*\*\*\*7890/)).toBeInTheDocument();
  });
});
```

### Form Component Test

```tsx
// components/TransferForm/TransferForm.test.tsx
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, it, expect, vi } from "vitest";
import { TransferForm } from "./TransferForm";

describe("TransferForm", () => {
  it("submits valid transfer data", async () => {
    const user = userEvent.setup();
    const onSubmit = vi.fn();

    render(<TransferForm onSubmit={onSubmit} />);

    await user.type(
      screen.getByLabelText(/from account/i),
      "1234567890"
    );
    await user.type(
      screen.getByLabelText(/to account/i),
      "0987654321"
    );
    await user.type(screen.getByLabelText(/amount/i), "5000");
    await user.click(screen.getByRole("button", { name: /submit transfer/i }));

    await waitFor(() => {
      expect(onSubmit).toHaveBeenCalledWith({
        fromAccount: "1234567890",
        toAccount: "0987654321",
        amount: 5000,
      });
    });
  });

  it("displays validation error for invalid amount", async () => {
    const user = userEvent.setup();

    render(<TransferForm onSubmit={vi.fn()} />);

    await user.type(screen.getByLabelText(/amount/i), "-100");
    await user.click(screen.getByRole("button", { name: /submit transfer/i }));

    expect(
      await screen.findByText(/amount must be positive/i)
    ).toBeInTheDocument();
  });

  it("disables submit button while processing", async () => {
    const user = userEvent.setup();
    const onSubmit = vi.fn(() => new Promise((r) => setTimeout(r, 1000)));

    render(<TransferForm onSubmit={onSubmit} />);

    await user.type(screen.getByLabelText(/from account/i), "1234567890");
    await user.type(screen.getByLabelText(/to account/i), "0987654321");
    await user.type(screen.getByLabelText(/amount/i), "5000");
    await user.click(screen.getByRole("button", { name: /submit transfer/i }));

    expect(screen.getByRole("button", { name: /processing/i })).toBeDisabled();
  });
});
```

---

## §TEST-04: Custom Hook Testing

```tsx
// hooks/useAccounts.test.tsx
import { renderHook, waitFor } from "@testing-library/react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { describe, it, expect } from "vitest";
import { useAccounts } from "./useAccounts";
import type { ReactNode } from "react";

function createWrapper() {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });

  return function Wrapper({ children }: { children: ReactNode }) {
    return (
      <QueryClientProvider client={queryClient}>
        {children}
      </QueryClientProvider>
    );
  };
}

describe("useAccounts", () => {
  it("fetches and returns accounts", async () => {
    const { result } = renderHook(() => useAccounts(), {
      wrapper: createWrapper(),
    });

    await waitFor(() => expect(result.current.isSuccess).toBe(true));

    expect(result.current.data).toHaveLength(2);
    expect(result.current.data?.[0].name).toBe("Operating Account");
  });

  it("returns error state on failure", async () => {
    // Override with error handler in the test
    const { server } = await import("@/test/mocks/server");
    const { serverErrorHandlers } = await import("@/test/mocks/error-handlers");
    server.use(...serverErrorHandlers);

    const { result } = renderHook(() => useAccounts(), {
      wrapper: createWrapper(),
    });

    await waitFor(() => expect(result.current.isError).toBe(true));
  });
});
```

---

## §TEST-05: Playwright E2E Tests

### Playwright Configuration

```ts
// playwright.config.ts
import { defineConfig, devices } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  timeout: 30_000,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: [["html"], ["junit", { outputFile: "test-results/e2e.xml" }]],
  use: {
    baseURL: "http://localhost:3000",
    trace: "on-first-retry",
    screenshot: "only-on-failure",
  },
  projects: [
    { name: "chromium", use: { ...devices["Desktop Chrome"] } },
    { name: "firefox", use: { ...devices["Desktop Firefox"] } },
  ],
  webServer: {
    command: "npm run build && npm run start",
    port: 3000,
    reuseExistingServer: !process.env.CI,
  },
});
```

### Page Object Model

```ts
// e2e/pages/TransferPage.ts
import type { Page, Locator } from "@playwright/test";

export class TransferPage {
  readonly page: Page;
  readonly fromAccountInput: Locator;
  readonly toAccountInput: Locator;
  readonly amountInput: Locator;
  readonly submitButton: Locator;
  readonly successMessage: Locator;

  constructor(page: Page) {
    this.page = page;
    this.fromAccountInput = page.getByLabel(/from account/i);
    this.toAccountInput = page.getByLabel(/to account/i);
    this.amountInput = page.getByLabel(/amount/i);
    this.submitButton = page.getByRole("button", { name: /submit transfer/i });
    this.successMessage = page.getByRole("alert").filter({ hasText: /success/i });
  }

  async goto() {
    await this.page.goto("/dashboard/transfers/new");
  }

  async createTransfer(from: string, to: string, amount: string) {
    await this.fromAccountInput.fill(from);
    await this.toAccountInput.fill(to);
    await this.amountInput.fill(amount);
    await this.submitButton.click();
  }
}
```

### E2E Test

```ts
// e2e/transfer.spec.ts
import { test, expect } from "@playwright/test";
import { TransferPage } from "./pages/TransferPage";

test.describe("Fund Transfer", () => {
  test("should complete a domestic transfer", async ({ page }) => {
    const transferPage = new TransferPage(page);
    await transferPage.goto();

    await transferPage.createTransfer("1234567890", "0987654321", "5000");

    await expect(transferPage.successMessage).toBeVisible();
    await expect(page).toHaveURL(/\/dashboard\/transfers$/);
  });

  test("should show error for insufficient funds", async ({ page }) => {
    const transferPage = new TransferPage(page);
    await transferPage.goto();

    await transferPage.createTransfer("1234567890", "0987654321", "999999999");

    await expect(
      page.getByText(/insufficient funds/i)
    ).toBeVisible();
  });
});
```

---

## §TEST-06: Coverage Configuration and CI

### Coverage Scripts

```json
{
  "scripts": {
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage",
    "test:e2e": "playwright test",
    "test:e2e:ui": "playwright test --ui",
    "test:ci": "vitest run --coverage --reporter=junit --outputFile=test-results/unit.xml"
  }
}
```

### CI Coverage Gate

```yaml
# .github/workflows/test.yml (excerpt)
- name: Run unit tests with coverage
  run: npm run test:ci

- name: Check coverage thresholds
  run: |
    npx istanbul check-coverage \
      --statements 80 \
      --branches 80 \
      --functions 80 \
      --lines 80

- name: Run E2E tests
  run: npx playwright test
```
