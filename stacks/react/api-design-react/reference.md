# API Design — React / Next.js Reference

## §API-01: Shared Zod Schemas

```ts
// lib/schemas/transfer.ts
import { z } from "zod";

/** Account number: exactly 10 digits. */
const AccountNumber = z.string().regex(/^\d{10}$/, "Must be a 10-digit account number");

/** Supported currencies for transfers. */
const Currency = z.enum(["USD", "EUR", "GBP", "CHF", "JPY"]);

/** Transfer status values. */
const TransferStatus = z.enum(["pending", "processing", "completed", "failed", "cancelled"]);

/** Schema for creating a new transfer. */
export const CreateTransferSchema = z.object({
  fromAccount: AccountNumber,
  toAccount: AccountNumber,
  amount: z.number().positive("Amount must be positive").max(1_000_000, "Exceeds maximum"),
  currency: Currency,
  reference: z.string().max(140).optional(),
});

/** Schema for listing transfers with pagination. */
export const ListTransfersQuerySchema = z.object({
  status: TransferStatus.optional(),
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  fromDate: z.coerce.date().optional(),
  toDate: z.coerce.date().optional(),
});

/** Schema for the transfer response object. */
export const TransferResponseSchema = z.object({
  id: z.string(),
  fromAccount: z.string(),
  toAccount: z.string(),
  amount: z.number(),
  currency: Currency,
  status: TransferStatus,
  reference: z.string().nullable(),
  fee: z.number(),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime(),
});

/** Derive TypeScript types from schemas. */
export type CreateTransferInput = z.infer<typeof CreateTransferSchema>;
export type ListTransfersQuery = z.infer<typeof ListTransfersQuerySchema>;
export type TransferResponse = z.infer<typeof TransferResponseSchema>;
```

### Account Schemas

```ts
// lib/schemas/account.ts
import { z } from "zod";

export const AccountSchema = z.object({
  id: z.string().uuid(),
  accountNumber: z.string().regex(/^\d{10}$/),
  name: z.string().min(1).max(100),
  type: z.enum(["checking", "savings", "investment"]),
  balance: z.number(),
  currency: z.enum(["USD", "EUR", "GBP"]),
  status: z.enum(["active", "frozen", "closed"]),
});

export const CreateAccountSchema = AccountSchema.pick({
  name: true,
  type: true,
  currency: true,
});

export type Account = z.infer<typeof AccountSchema>;
export type CreateAccountInput = z.infer<typeof CreateAccountSchema>;
```

---

## §API-02: Route Handler Patterns

### CRUD Route Handler

```ts
// app/api/transfers/route.ts
import { NextResponse } from "next/server";
import { auth } from "@/lib/auth";
import {
  CreateTransferSchema,
  ListTransfersQuerySchema,
} from "@/lib/schemas/transfer";
import { createTransfer, listTransfers } from "@/lib/domain/transfers";
import { successResponse, errorResponse, validationErrorResponse } from "@/lib/api/responses";

export async function GET(request: Request) {
  const session = await auth();
  if (!session) return errorResponse("UNAUTHORIZED", 401);

  const { searchParams } = new URL(request.url);
  const queryResult = ListTransfersQuerySchema.safeParse(
    Object.fromEntries(searchParams)
  );

  if (!queryResult.success) {
    return validationErrorResponse(queryResult.error);
  }

  const { data, pagination } = await listTransfers(
    session.user.id,
    queryResult.data
  );

  return successResponse({ data, pagination });
}

export async function POST(request: Request) {
  const session = await auth();
  if (!session) return errorResponse("UNAUTHORIZED", 401);

  const body = await request.json();
  const result = CreateTransferSchema.safeParse(body);

  if (!result.success) {
    return validationErrorResponse(result.error);
  }

  try {
    const transfer = await createTransfer(session.user.id, result.data);
    return successResponse(transfer, 201);
  } catch (error) {
    if (error instanceof AppError) {
      return errorResponse(error.code, error.statusCode, error.message);
    }
    throw error; // Let Next.js error handler catch unexpected errors
  }
}
```

### Dynamic Route Handler

```ts
// app/api/transfers/[id]/route.ts
import { NextResponse } from "next/server";
import { auth } from "@/lib/auth";
import { getTransferById, cancelTransfer } from "@/lib/domain/transfers";
import { successResponse, errorResponse } from "@/lib/api/responses";

interface RouteParams {
  params: Promise<{ id: string }>;
}

export async function GET(request: Request, { params }: RouteParams) {
  const session = await auth();
  if (!session) return errorResponse("UNAUTHORIZED", 401);

  const { id } = await params;
  const transfer = await getTransferById(id, session.user.id);

  if (!transfer) return errorResponse("NOT_FOUND", 404);

  return successResponse(transfer);
}

export async function DELETE(request: Request, { params }: RouteParams) {
  const session = await auth();
  if (!session) return errorResponse("UNAUTHORIZED", 401);

  const { id } = await params;

  try {
    await cancelTransfer(id, session.user.id);
    return new NextResponse(null, { status: 204 });
  } catch (error) {
    if (error instanceof AppError) {
      return errorResponse(error.code, error.statusCode, error.message);
    }
    throw error;
  }
}
```

---

## §API-03: Server Actions

### Validated Server Action

```ts
// app/actions/transfer.ts
"use server";

import { z } from "zod";
import { auth } from "@/lib/auth";
import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createTransfer } from "@/lib/domain/transfers";
import { CreateTransferSchema } from "@/lib/schemas/transfer";

/** Result type for server actions with typed success/error states. */
type ActionResult<T = void> =
  | { success: true; data: T }
  | { success: false; error: { code: string; message: string; fieldErrors?: Record<string, string[]> } };

export async function submitTransfer(
  _prevState: ActionResult | null,
  formData: FormData
): Promise<ActionResult<{ transferId: string }>> {
  const session = await auth();
  if (!session) {
    return {
      success: false,
      error: { code: "UNAUTHORIZED", message: "Please sign in" },
    };
  }

  const raw = {
    fromAccount: formData.get("fromAccount"),
    toAccount: formData.get("toAccount"),
    amount: Number(formData.get("amount")),
    currency: formData.get("currency"),
    reference: formData.get("reference") || undefined,
  };

  const result = CreateTransferSchema.safeParse(raw);
  if (!result.success) {
    return {
      success: false,
      error: {
        code: "VALIDATION_ERROR",
        message: "Please correct the form errors",
        fieldErrors: result.error.flatten().fieldErrors as Record<string, string[]>,
      },
    };
  }

  try {
    const transfer = await createTransfer(session.user.id, result.data);
    revalidatePath("/dashboard/transfers");
    return { success: true, data: { transferId: transfer.id } };
  } catch (error) {
    return {
      success: false,
      error: {
        code: error instanceof AppError ? error.code : "SERVER_ERROR",
        message: "Transfer could not be completed",
      },
    };
  }
}
```

### Using Server Action with useActionState

```tsx
// components/features/transfers/TransferForm.tsx
"use client";

import { useActionState } from "react";
import { submitTransfer } from "@/app/actions/transfer";

export function TransferForm() {
  const [state, formAction, isPending] = useActionState(submitTransfer, null);

  return (
    <form action={formAction}>
      <div>
        <label htmlFor="fromAccount">From Account</label>
        <input id="fromAccount" name="fromAccount" required />
        {state?.success === false && state.error.fieldErrors?.fromAccount && (
          <p role="alert" className="text-red-600">
            {state.error.fieldErrors.fromAccount[0]}
          </p>
        )}
      </div>

      <div>
        <label htmlFor="toAccount">To Account</label>
        <input id="toAccount" name="toAccount" required />
      </div>

      <div>
        <label htmlFor="amount">Amount</label>
        <input id="amount" name="amount" type="number" step="0.01" required />
      </div>

      <div>
        <label htmlFor="currency">Currency</label>
        <select id="currency" name="currency">
          <option value="USD">USD</option>
          <option value="EUR">EUR</option>
          <option value="GBP">GBP</option>
        </select>
      </div>

      {state?.success === false && (
        <p role="alert" className="text-red-600">{state.error.message}</p>
      )}

      {state?.success === true && (
        <p role="status" className="text-green-600">
          Transfer submitted (ID: {state.data.transferId})
        </p>
      )}

      <button type="submit" disabled={isPending}>
        {isPending ? "Processing..." : "Submit Transfer"}
      </button>
    </form>
  );
}
```

---

## §API-04: tRPC Setup (Optional)

### tRPC Server Configuration

```ts
// lib/trpc/init.ts
import { initTRPC, TRPCError } from "@trpc/server";
import superjson from "superjson";
import { auth } from "@/lib/auth";

const t = initTRPC.context<{ session: Awaited<ReturnType<typeof auth>> }>().create({
  transformer: superjson,
});

export const router = t.router;
export const publicProcedure = t.procedure;

export const protectedProcedure = t.procedure.use(async ({ ctx, next }) => {
  if (!ctx.session?.user) {
    throw new TRPCError({ code: "UNAUTHORIZED" });
  }
  return next({ ctx: { ...ctx, session: ctx.session } });
});
```

### tRPC Router

```ts
// lib/trpc/routers/transfer.ts
import { z } from "zod";
import { router, protectedProcedure } from "../init";
import { CreateTransferSchema } from "@/lib/schemas/transfer";
import { createTransfer, listTransfers } from "@/lib/domain/transfers";

export const transferRouter = router({
  list: protectedProcedure
    .input(
      z.object({
        page: z.number().default(1),
        limit: z.number().default(20),
        status: z.enum(["pending", "completed", "failed"]).optional(),
      })
    )
    .query(async ({ ctx, input }) => {
      return listTransfers(ctx.session.user.id, input);
    }),

  create: protectedProcedure
    .input(CreateTransferSchema)
    .mutation(async ({ ctx, input }) => {
      return createTransfer(ctx.session.user.id, input);
    }),
});
```

### tRPC Route Handler

```ts
// app/api/trpc/[trpc]/route.ts
import { fetchRequestHandler } from "@trpc/server/adapters/fetch";
import { appRouter } from "@/lib/trpc/routers";
import { auth } from "@/lib/auth";

const handler = (req: Request) =>
  fetchRequestHandler({
    endpoint: "/api/trpc",
    req,
    router: appRouter,
    createContext: async () => ({
      session: await auth(),
    }),
  });

export { handler as GET, handler as POST };
```

---

## §API-05: OpenAPI Client Generation

### Orval Configuration

```ts
// orval.config.ts
import { defineConfig } from "orval";

export default defineConfig({
  bankingApi: {
    input: {
      target: "./openapi/banking-api.yaml",
    },
    output: {
      target: "./lib/api/generated/banking-api.ts",
      client: "react-query",
      mode: "tags-split",
      override: {
        mutator: {
          path: "./lib/api/custom-fetch.ts",
          name: "customFetch",
        },
        query: {
          useQuery: true,
          useMutation: true,
        },
      },
    },
  },
});
```

### Custom Fetch for Generated Client

```ts
// lib/api/custom-fetch.ts
import { AppError, ErrorCode } from "@/lib/errors/base";

export const customFetch = async <T>(
  url: string,
  options: RequestInit
): Promise<T> => {
  const response = await fetch(url, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...options.headers,
    },
    credentials: "include",
  });

  if (!response.ok) {
    const body = await response.json().catch(() => ({}));
    throw new AppError(
      body.error?.code ?? ErrorCode.SERVER_ERROR,
      body.error?.message ?? "Request failed",
      { statusCode: response.status }
    );
  }

  return response.json();
};
```

```json
// package.json scripts
{
  "scripts": {
    "api:generate": "orval",
    "api:generate:watch": "orval --watch"
  }
}
```

---

## §API-06: Response Helpers

```ts
// lib/api/responses.ts
import { NextResponse } from "next/server";
import type { ZodError } from "zod";

interface ApiError {
  code: string;
  message: string;
  details?: unknown;
}

interface ApiResponse<T> {
  data?: T;
  error?: ApiError;
}

export function successResponse<T>(data: T, status = 200): NextResponse<ApiResponse<T>> {
  return NextResponse.json({ data }, { status });
}

export function errorResponse(
  code: string,
  status: number,
  message?: string
): NextResponse<ApiResponse<never>> {
  const defaultMessages: Record<string, string> = {
    UNAUTHORIZED: "Authentication required",
    FORBIDDEN: "Insufficient permissions",
    NOT_FOUND: "Resource not found",
    VALIDATION_ERROR: "Invalid input",
    SERVER_ERROR: "Internal server error",
  };

  return NextResponse.json(
    {
      error: {
        code,
        message: message ?? defaultMessages[code] ?? "An error occurred",
      },
    },
    { status }
  );
}

export function validationErrorResponse(zodError: ZodError): NextResponse<ApiResponse<never>> {
  return NextResponse.json(
    {
      error: {
        code: "VALIDATION_ERROR",
        message: "Request validation failed",
        details: zodError.flatten(),
      },
    },
    { status: 400 }
  );
}

export function paginatedResponse<T>(
  data: T[],
  pagination: { page: number; limit: number; total: number }
): NextResponse {
  return NextResponse.json({
    data,
    pagination: {
      ...pagination,
      totalPages: Math.ceil(pagination.total / pagination.limit),
      hasNext: pagination.page * pagination.limit < pagination.total,
    },
  });
}
```
