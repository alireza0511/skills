# Architecture — React / Next.js Reference

## §ARCH-01: Feature Folder Structure

```
app/
├── (auth)/
│   ├── signin/
│   │   └── page.tsx
│   └── layout.tsx
├── dashboard/
│   ├── accounts/
│   │   ├── [id]/
│   │   │   ├── page.tsx
│   │   │   └── loading.tsx
│   │   ├── page.tsx
│   │   ├── loading.tsx
│   │   └── error.tsx
│   ├── transfers/
│   │   ├── new/
│   │   │   └── page.tsx
│   │   ├── page.tsx
│   │   └── error.tsx
│   ├── layout.tsx
│   ├── page.tsx
│   └── loading.tsx
├── api/
│   ├── accounts/
│   │   ├── route.ts
│   │   └── [id]/route.ts
│   ├── transfers/
│   │   └── route.ts
│   └── auth/
│       └── [...nextauth]/route.ts
├── layout.tsx
├── page.tsx
├── not-found.tsx
└── error.tsx
components/
├── ui/                    # Design system primitives
│   ├── Button/
│   │   ├── Button.tsx
│   │   ├── Button.test.tsx
│   │   └── index.ts
│   ├── Input/
│   ├── Card/
│   └── index.ts           # Barrel export for ui
├── features/              # Feature-specific compound components
│   ├── accounts/
│   │   ├── AccountCard.tsx
│   │   ├── AccountList.tsx
│   │   └── index.ts
│   └── transfers/
│       ├── TransferForm.tsx
│       ├── TransferHistory.tsx
│       └── index.ts
└── layout/                # App-level layout components
    ├── Header.tsx
    ├── Sidebar.tsx
    └── Footer.tsx
hooks/
├── useAccounts.ts
├── useTransfers.ts
└── useAuth.ts
lib/
├── domain/                # Business logic (pure functions)
│   ├── transfers.ts
│   ├── accounts.ts
│   └── validation.ts
├── api/                   # API client utilities
│   ├── client.ts
│   └── types.ts
├── auth.ts                # NextAuth config
└── utils.ts               # Generic utilities
types/
├── api.ts                 # API response/request types
├── domain.ts              # Domain entity types
└── next-auth.d.ts         # Module augmentations
```

---

## §ARCH-02: Server vs Client Component Decision

### Server Component (default)

```tsx
// app/dashboard/accounts/page.tsx
import { getAccounts } from "@/lib/api/accounts";
import { AccountList } from "@/components/features/accounts";

export default async function AccountsPage() {
  const accounts = await getAccounts();

  return (
    <section>
      <h1>Your Accounts</h1>
      <AccountList accounts={accounts} />
    </section>
  );
}
```

### Client Component (justified: uses hooks and event handlers)

```tsx
// components/features/transfers/TransferForm.tsx
"use client";

import { useState, useTransition } from "react";
import { createTransfer } from "@/app/actions/transfer";
import { Button, Input } from "@/components/ui";

export function TransferForm() {
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);

  function handleSubmit(formData: FormData) {
    startTransition(async () => {
      const result = await createTransfer(formData);
      if (result.error) setError(result.error.message);
    });
  }

  return (
    <form action={handleSubmit}>
      <Input label="From Account" name="fromAccount" required />
      <Input label="To Account" name="toAccount" required />
      <Input label="Amount" name="amount" type="number" required />
      {error && <p role="alert">{error}</p>}
      <Button type="submit" disabled={isPending}>
        {isPending ? "Processing..." : "Submit Transfer"}
      </Button>
    </form>
  );
}
```

### Composition Pattern: Server Parent, Client Child

```tsx
// app/dashboard/page.tsx (Server Component)
import { getAccounts } from "@/lib/api/accounts";
import { AccountDashboard } from "@/components/features/accounts/AccountDashboard";

export default async function DashboardPage() {
  const accounts = await getAccounts();

  // Pass server-fetched data to client component
  return <AccountDashboard initialAccounts={accounts} />;
}
```

---

## §ARCH-03: State Management

### Zustand Store (global UI state)

```ts
// stores/ui-store.ts
import { create } from "zustand";
import { devtools } from "zustand/middleware";

interface UIState {
  sidebarOpen: boolean;
  theme: "light" | "dark";
  toggleSidebar: () => void;
  setTheme: (theme: "light" | "dark") => void;
}

export const useUIStore = create<UIState>()(
  devtools(
    (set) => ({
      sidebarOpen: true,
      theme: "light",
      toggleSidebar: () =>
        set((state) => ({ sidebarOpen: !state.sidebarOpen })),
      setTheme: (theme) => set({ theme }),
    }),
    { name: "ui-store" }
  )
);
```

### TanStack Query (server state)

```tsx
// hooks/useAccounts.ts
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { apiClient } from "@/lib/api/client";
import type { Account, CreateAccountRequest } from "@/types/api";

export const accountKeys = {
  all: ["accounts"] as const,
  detail: (id: string) => ["accounts", id] as const,
};

export function useAccounts() {
  return useQuery({
    queryKey: accountKeys.all,
    queryFn: () => apiClient.get<Account[]>("/api/accounts"),
    staleTime: 30_000, // 30 seconds for banking data
  });
}

export function useAccount(id: string) {
  return useQuery({
    queryKey: accountKeys.detail(id),
    queryFn: () => apiClient.get<Account>(`/api/accounts/${id}`),
    enabled: !!id,
  });
}

export function useCreateTransfer() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: CreateAccountRequest) =>
      apiClient.post("/api/transfers", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: accountKeys.all });
    },
  });
}
```

### Query Client Provider

```tsx
// providers/QueryProvider.tsx
"use client";

import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { ReactQueryDevtools } from "@tanstack/react-query-devtools";
import { useState } from "react";

export function QueryProvider({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 60_000,
            retry: 2,
            refetchOnWindowFocus: false,
          },
        },
      })
  );

  return (
    <QueryClientProvider client={queryClient}>
      {children}
      {process.env.NODE_ENV === "development" && <ReactQueryDevtools />}
    </QueryClientProvider>
  );
}
```

---

## §ARCH-04: Domain Logic Extraction

```ts
// lib/domain/transfers.ts
import type { TransferRequest, TransferFee } from "@/types/domain";

const FEE_TIERS = [
  { maxAmount: 1_000, rate: 0 },
  { maxAmount: 10_000, rate: 0.0005 },
  { maxAmount: 100_000, rate: 0.001 },
  { maxAmount: Infinity, rate: 0.002 },
] as const;

export function calculateTransferFee(amount: number): TransferFee {
  const tier = FEE_TIERS.find((t) => amount <= t.maxAmount)!;
  const fee = Math.round(amount * tier.rate * 100) / 100;
  return { fee, rate: tier.rate, tier: tier.maxAmount };
}

export function validateTransferLimits(
  request: TransferRequest,
  dailyTotal: number,
  dailyLimit: number
): { valid: boolean; reason?: string } {
  if (request.amount <= 0) {
    return { valid: false, reason: "Amount must be positive" };
  }
  if (dailyTotal + request.amount > dailyLimit) {
    return { valid: false, reason: "Daily transfer limit exceeded" };
  }
  if (request.fromAccount === request.toAccount) {
    return { valid: false, reason: "Cannot transfer to same account" };
  }
  return { valid: true };
}
```

---

## §ARCH-05: API Route Handler Convention

```ts
// app/api/accounts/route.ts
import { NextResponse } from "next/server";
import { z } from "zod";
import { auth } from "@/lib/auth";
import { getAccountsByUser } from "@/lib/domain/accounts";

export async function GET() {
  const session = await auth();
  if (!session) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const accounts = await getAccountsByUser(session.user.employeeId);
  return NextResponse.json(accounts);
}

const CreateAccountSchema = z.object({
  name: z.string().min(1).max(100),
  type: z.enum(["checking", "savings", "investment"]),
  currency: z.enum(["USD", "EUR", "GBP"]),
});

export async function POST(request: Request) {
  const session = await auth();
  if (!session) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await request.json();
  const result = CreateAccountSchema.safeParse(body);

  if (!result.success) {
    return NextResponse.json(
      { error: "Validation failed", details: result.error.flatten() },
      { status: 400 }
    );
  }

  // ... create account
  return NextResponse.json({ id: "new-id" }, { status: 201 });
}
```

---

## §ARCH-06: TypeScript Configuration

```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": {
      "@/*": ["./*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```
