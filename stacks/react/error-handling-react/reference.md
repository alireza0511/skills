# Error Handling — React / Next.js Reference

## §ERR-01: Typed Error Classes

```ts
// lib/errors/base.ts
export enum ErrorCode {
  // Auth errors
  UNAUTHORIZED = "UNAUTHORIZED",
  SESSION_EXPIRED = "SESSION_EXPIRED",
  FORBIDDEN = "FORBIDDEN",

  // Transfer errors
  INSUFFICIENT_FUNDS = "INSUFFICIENT_FUNDS",
  DAILY_LIMIT_EXCEEDED = "DAILY_LIMIT_EXCEEDED",
  INVALID_ACCOUNT = "INVALID_ACCOUNT",
  TRANSFER_FAILED = "TRANSFER_FAILED",

  // Generic
  VALIDATION_ERROR = "VALIDATION_ERROR",
  NOT_FOUND = "NOT_FOUND",
  NETWORK_ERROR = "NETWORK_ERROR",
  SERVER_ERROR = "SERVER_ERROR",
  TIMEOUT = "TIMEOUT",
}

export class AppError extends Error {
  readonly code: ErrorCode;
  readonly statusCode: number;
  readonly context: Record<string, unknown>;
  readonly isRetryable: boolean;

  constructor(
    code: ErrorCode,
    message: string,
    options: {
      statusCode?: number;
      context?: Record<string, unknown>;
      isRetryable?: boolean;
      cause?: Error;
    } = {}
  ) {
    super(message, { cause: options.cause });
    this.name = "AppError";
    this.code = code;
    this.statusCode = options.statusCode ?? 500;
    this.context = options.context ?? {};
    this.isRetryable = options.isRetryable ?? false;
  }
}

export class TransferError extends AppError {
  constructor(
    code: ErrorCode,
    context: Record<string, unknown>,
    cause?: Error
  ) {
    const messages: Record<string, string> = {
      [ErrorCode.INSUFFICIENT_FUNDS]: "Insufficient funds for this transfer",
      [ErrorCode.DAILY_LIMIT_EXCEEDED]: "Daily transfer limit exceeded",
      [ErrorCode.INVALID_ACCOUNT]: "Invalid account specified",
      [ErrorCode.TRANSFER_FAILED]: "Transfer could not be completed",
    };

    super(code, messages[code] ?? "Transfer error", {
      statusCode: code === ErrorCode.INSUFFICIENT_FUNDS ? 422 : 400,
      context,
      isRetryable: code === ErrorCode.TRANSFER_FAILED,
      cause,
    });
    this.name = "TransferError";
  }
}

export class NetworkError extends AppError {
  constructor(cause?: Error) {
    super(ErrorCode.NETWORK_ERROR, "Network connection failed", {
      statusCode: 0,
      isRetryable: true,
      cause,
    });
    this.name = "NetworkError";
  }
}
```

### User-Friendly Message Mapping

```ts
// lib/errors/messages.ts
import { ErrorCode } from "./base";

const USER_MESSAGES: Record<ErrorCode, string> = {
  [ErrorCode.UNAUTHORIZED]: "Please sign in to continue.",
  [ErrorCode.SESSION_EXPIRED]: "Your session has expired. Please sign in again.",
  [ErrorCode.FORBIDDEN]: "You do not have permission to perform this action.",
  [ErrorCode.INSUFFICIENT_FUNDS]: "Insufficient funds in the selected account.",
  [ErrorCode.DAILY_LIMIT_EXCEEDED]: "You have reached your daily transfer limit.",
  [ErrorCode.INVALID_ACCOUNT]: "The specified account could not be found.",
  [ErrorCode.TRANSFER_FAILED]: "Unable to complete the transfer. Please try again.",
  [ErrorCode.VALIDATION_ERROR]: "Please check your input and try again.",
  [ErrorCode.NOT_FOUND]: "The requested resource was not found.",
  [ErrorCode.NETWORK_ERROR]: "Unable to connect. Please check your internet connection.",
  [ErrorCode.SERVER_ERROR]: "Something went wrong. Please try again later.",
  [ErrorCode.TIMEOUT]: "The request timed out. Please try again.",
};

export function getUserFriendlyMessage(code: ErrorCode): string {
  return USER_MESSAGES[code] ?? "An unexpected error occurred. Please try again.";
}

export function toUserMessage(error: unknown): string {
  if (error instanceof AppError) {
    return getUserFriendlyMessage(error.code);
  }
  return "An unexpected error occurred. Please try again.";
}
```

---

## §ERR-02: Error Boundary Patterns

### Per-Feature Error Boundary

```tsx
// components/ErrorBoundary/FeatureErrorBoundary.tsx
"use client";

import { ErrorBoundary, type FallbackProps } from "react-error-boundary";
import * as Sentry from "@sentry/nextjs";
import { logger } from "@/lib/observability/logger";

interface Props {
  feature: string;
  children: React.ReactNode;
}

function ErrorFallback({ error, resetErrorBoundary }: FallbackProps) {
  return (
    <div role="alert" className="rounded border border-red-200 bg-red-50 p-6">
      <h3 className="font-semibold text-red-800">Something went wrong</h3>
      <p className="mt-2 text-sm text-red-600">
        We encountered an error loading this section.
      </p>
      <button
        type="button"
        onClick={resetErrorBoundary}
        className="mt-4 rounded bg-red-600 px-4 py-2 text-sm text-white"
      >
        Try Again
      </button>
    </div>
  );
}

export function FeatureErrorBoundary({ feature, children }: Props) {
  return (
    <ErrorBoundary
      FallbackComponent={ErrorFallback}
      onError={(error, info) => {
        logger.error(`Error in ${feature}`, {
          error: error.message,
          componentStack: info.componentStack,
        });
        Sentry.captureException(error, { tags: { feature } });
      }}
    >
      {children}
    </ErrorBoundary>
  );
}
```

### Dashboard Layout with Boundaries

```tsx
// app/dashboard/page.tsx
import { FeatureErrorBoundary } from "@/components/ErrorBoundary/FeatureErrorBoundary";
import { AccountSummary } from "@/components/features/accounts/AccountSummary";
import { RecentTransfers } from "@/components/features/transfers/RecentTransfers";
import { QuickActions } from "@/components/features/QuickActions";

export default function DashboardPage() {
  return (
    <div className="grid gap-6">
      <FeatureErrorBoundary feature="account-summary">
        <AccountSummary />
      </FeatureErrorBoundary>

      <FeatureErrorBoundary feature="recent-transfers">
        <RecentTransfers />
      </FeatureErrorBoundary>

      <FeatureErrorBoundary feature="quick-actions">
        <QuickActions />
      </FeatureErrorBoundary>
    </div>
  );
}
```

---

## §ERR-03: Error Pages

### Route Error Page

```tsx
// app/dashboard/error.tsx
"use client";

import { useEffect } from "react";
import * as Sentry from "@sentry/nextjs";

interface Props {
  error: Error & { digest?: string };
  reset: () => void;
}

export default function DashboardError({ error, reset }: Props) {
  useEffect(() => {
    Sentry.captureException(error);
  }, [error]);

  return (
    <div className="flex min-h-[60vh] flex-col items-center justify-center">
      <h2 className="text-2xl font-bold">Unable to load dashboard</h2>
      <p className="mt-2 text-gray-600">
        We encountered an unexpected error. Please try again.
      </p>
      {error.digest && (
        <p className="mt-1 text-xs text-gray-400">Reference: {error.digest}</p>
      )}
      <div className="mt-6 flex gap-4">
        <button type="button" onClick={reset} className="btn-primary">
          Try Again
        </button>
        <a href="/dashboard" className="btn-secondary">
          Go to Dashboard
        </a>
      </div>
    </div>
  );
}
```

### Not Found Page

```tsx
// app/not-found.tsx
import Link from "next/link";

export default function NotFound() {
  return (
    <div className="flex min-h-[60vh] flex-col items-center justify-center">
      <h2 className="text-2xl font-bold">Page Not Found</h2>
      <p className="mt-2 text-gray-600">
        The page you are looking for does not exist or has been moved.
      </p>
      <Link href="/dashboard" className="mt-6 btn-primary">
        Return to Dashboard
      </Link>
    </div>
  );
}
```

### Dynamic Not Found

```tsx
// app/dashboard/accounts/[id]/page.tsx
import { notFound } from "next/navigation";
import { getAccount } from "@/lib/api/accounts";

export default async function AccountPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const account = await getAccount(id);

  if (!account) {
    notFound();
  }

  return <AccountDetail account={account} />;
}
```

---

## §ERR-04: API Client Error Handling

```ts
// lib/api/client.ts
import { AppError, NetworkError, ErrorCode } from "@/lib/errors/base";

interface ApiResponse<T> {
  data: T;
  error?: { code: string; message: string; details?: unknown };
}

class ApiClient {
  private baseUrl: string;

  constructor(baseUrl = "") {
    this.baseUrl = baseUrl;
  }

  async request<T>(path: string, options: RequestInit = {}): Promise<T> {
    let response: Response;

    try {
      response = await fetch(`${this.baseUrl}${path}`, {
        ...options,
        headers: {
          "Content-Type": "application/json",
          ...options.headers,
        },
      });
    } catch (error) {
      throw new NetworkError(error instanceof Error ? error : undefined);
    }

    if (!response.ok) {
      const body = await response.json().catch(() => ({}));
      const code = this.mapStatusToErrorCode(response.status, body.error?.code);

      throw new AppError(code, body.error?.message ?? "Request failed", {
        statusCode: response.status,
        context: { path, details: body.error?.details },
        isRetryable: response.status >= 500,
      });
    }

    return response.json();
  }

  private mapStatusToErrorCode(status: number, serverCode?: string): ErrorCode {
    if (serverCode && Object.values(ErrorCode).includes(serverCode as ErrorCode)) {
      return serverCode as ErrorCode;
    }

    switch (status) {
      case 401: return ErrorCode.UNAUTHORIZED;
      case 403: return ErrorCode.FORBIDDEN;
      case 404: return ErrorCode.NOT_FOUND;
      case 422: return ErrorCode.VALIDATION_ERROR;
      default:  return ErrorCode.SERVER_ERROR;
    }
  }

  get<T>(path: string) { return this.request<T>(path); }

  post<T>(path: string, data: unknown) {
    return this.request<T>(path, {
      method: "POST",
      body: JSON.stringify(data),
    });
  }

  put<T>(path: string, data: unknown) {
    return this.request<T>(path, {
      method: "PUT",
      body: JSON.stringify(data),
    });
  }

  delete<T>(path: string) {
    return this.request<T>(path, { method: "DELETE" });
  }
}

export const apiClient = new ApiClient();
```

---

## §ERR-05: Toast Notification System

```tsx
// components/Toast/ToastProvider.tsx
"use client";

import { createContext, useCallback, useContext, useState } from "react";

interface Toast {
  id: string;
  message: string;
  type: "success" | "error" | "warning" | "info";
  duration?: number;
}

interface ToastContextValue {
  toasts: Toast[];
  addToast: (toast: Omit<Toast, "id">) => void;
  removeToast: (id: string) => void;
}

const ToastContext = createContext<ToastContextValue | null>(null);

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([]);

  const addToast = useCallback((toast: Omit<Toast, "id">) => {
    const id = crypto.randomUUID();
    setToasts((prev) => [...prev, { ...toast, id }]);

    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== id));
    }, toast.duration ?? 5000);
  }, []);

  const removeToast = useCallback((id: string) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  }, []);

  return (
    <ToastContext.Provider value={{ toasts, addToast, removeToast }}>
      {children}
      <div aria-live="polite" className="fixed bottom-4 right-4 z-50 space-y-2">
        {toasts.map((toast) => (
          <div
            key={toast.id}
            role="status"
            className={`toast toast-${toast.type}`}
          >
            <p>{toast.message}</p>
            <button
              type="button"
              onClick={() => removeToast(toast.id)}
              aria-label="Dismiss"
            >
              &times;
            </button>
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

export function useToast() {
  const context = useContext(ToastContext);
  if (!context) throw new Error("useToast must be used within ToastProvider");
  return context;
}
```

---

## §ERR-06: Retry with Exponential Backoff

```ts
// lib/retry.ts
interface RetryOptions {
  maxRetries?: number;
  baseDelay?: number;
  maxDelay?: number;
  shouldRetry?: (error: unknown) => boolean;
}

export async function withRetry<T>(
  fn: () => Promise<T>,
  options: RetryOptions = {}
): Promise<T> {
  const {
    maxRetries = 3,
    baseDelay = 1000,
    maxDelay = 10_000,
    shouldRetry = defaultShouldRetry,
  } = options;

  let lastError: unknown;

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;

      if (attempt === maxRetries || !shouldRetry(error)) {
        throw error;
      }

      const delay = Math.min(baseDelay * 2 ** attempt, maxDelay);
      const jitter = delay * (0.5 + Math.random() * 0.5);
      await new Promise((resolve) => setTimeout(resolve, jitter));
    }
  }

  throw lastError;
}

function defaultShouldRetry(error: unknown): boolean {
  if (error instanceof AppError) {
    return error.isRetryable;
  }
  // Retry network errors
  if (error instanceof TypeError && error.message === "Failed to fetch") {
    return true;
  }
  return false;
}
```

### Usage in React Query

```ts
// hooks/useTransferMutation.ts
import { useMutation } from "@tanstack/react-query";
import { withRetry } from "@/lib/retry";
import { apiClient } from "@/lib/api/client";
import { useToast } from "@/components/Toast/ToastProvider";
import { toUserMessage } from "@/lib/errors/messages";

export function useTransferMutation() {
  const { addToast } = useToast();

  return useMutation({
    mutationFn: (data: TransferRequest) =>
      withRetry(() => apiClient.post("/api/transfers", data), {
        maxRetries: 2,
      }),
    onSuccess: () => {
      addToast({ type: "success", message: "Transfer submitted successfully." });
    },
    onError: (error) => {
      addToast({ type: "error", message: toUserMessage(error) });
    },
  });
}
```
