# Security — React / Next.js Reference

## §SEC-01: NextAuth.js Configuration

```ts
// app/api/auth/[...nextauth]/route.ts
import NextAuth from "next-auth";
import type { NextAuthConfig } from "next-auth";

export const authConfig: NextAuthConfig = {
  providers: [
    {
      id: "bank-idp",
      name: "Bank Identity Provider",
      type: "oidc",
      issuer: process.env.OIDC_ISSUER_URL, // server-only
      clientId: process.env.OIDC_CLIENT_ID,
      clientSecret: process.env.OIDC_CLIENT_SECRET,
      authorization: { params: { scope: "openid profile email roles" } },
      profile(profile) {
        return {
          id: profile.sub,
          name: profile.name,
          email: profile.email,
          role: profile.role,
        };
      },
    },
  ],
  session: {
    strategy: "jwt",
    maxAge: 15 * 60, // 15 minutes for banking
  },
  callbacks: {
    async jwt({ token, account, profile }) {
      if (account && profile) {
        token.role = profile.role;
        token.employeeId = profile.sub;
      }
      return token;
    },
    async session({ session, token }) {
      session.user.role = token.role as string;
      session.user.employeeId = token.employeeId as string;
      return session;
    },
    async authorized({ auth, request }) {
      const isLoggedIn = !!auth?.user;
      const isProtected = !request.nextUrl.pathname.startsWith("/public");
      if (isProtected && !isLoggedIn) return false;
      return true;
    },
  },
  pages: {
    signIn: "/auth/signin",
    error: "/auth/error",
  },
};

const handler = NextAuth(authConfig);
export { handler as GET, handler as POST };
```

### Session Type Extension

```ts
// types/next-auth.d.ts
import "next-auth";

declare module "next-auth" {
  interface Session {
    user: {
      id: string;
      name: string;
      email: string;
      role: string;
      employeeId: string;
    };
  }
}
```

---

## §SEC-02: Content Security Policy Headers

```ts
// next.config.ts
import type { NextConfig } from "next";

const cspHeader = `
  default-src 'self';
  script-src 'self' 'nonce-{NONCE}';
  style-src 'self' 'nonce-{NONCE}';
  img-src 'self' data: https://cdn.bank.com;
  font-src 'self' https://fonts.bank.com;
  connect-src 'self' https://api.bank.com;
  frame-ancestors 'none';
  base-uri 'self';
  form-action 'self';
  upgrade-insecure-requests;
`.replace(/\n/g, "");

const nextConfig: NextConfig = {
  async headers() {
    return [
      {
        source: "/(.*)",
        headers: [
          { key: "Content-Security-Policy", value: cspHeader },
          { key: "X-Frame-Options", value: "DENY" },
          { key: "X-Content-Type-Options", value: "nosniff" },
          { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
          { key: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=()" },
          {
            key: "Strict-Transport-Security",
            value: "max-age=63072000; includeSubDomains; preload",
          },
        ],
      },
    ];
  },
};

export default nextConfig;
```

### CSP Nonce Middleware

```ts
// middleware.ts
import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import crypto from "crypto";

export function middleware(request: NextRequest) {
  const nonce = crypto.randomBytes(16).toString("base64");
  const response = NextResponse.next();

  const csp = response.headers.get("Content-Security-Policy") ?? "";
  response.headers.set(
    "Content-Security-Policy",
    csp.replace(/{NONCE}/g, nonce)
  );
  response.headers.set("x-nonce", nonce);

  return response;
}
```

---

## §SEC-03: CSRF Token Implementation

```ts
// lib/csrf.ts
import { randomBytes, createHmac } from "crypto";

const CSRF_SECRET = process.env.CSRF_SECRET!;

export function generateCsrfToken(sessionId: string): string {
  const salt = randomBytes(16).toString("hex");
  const hmac = createHmac("sha256", CSRF_SECRET)
    .update(`${sessionId}:${salt}`)
    .digest("hex");
  return `${salt}:${hmac}`;
}

export function validateCsrfToken(
  token: string,
  sessionId: string
): boolean {
  const [salt, hmac] = token.split(":");
  if (!salt || !hmac) return false;
  const expected = createHmac("sha256", CSRF_SECRET)
    .update(`${sessionId}:${salt}`)
    .digest("hex");
  return hmac === expected;
}
```

### CSRF Middleware for Route Handlers

```ts
// middleware/csrf.ts
import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { validateCsrfToken } from "@/lib/csrf";

const MUTATING_METHODS = new Set(["POST", "PUT", "DELETE", "PATCH"]);

export function csrfMiddleware(request: NextRequest): NextResponse | null {
  if (!MUTATING_METHODS.has(request.method)) return null;

  const csrfToken = request.headers.get("x-csrf-token");
  const sessionId = request.cookies.get("session-id")?.value;

  if (!csrfToken || !sessionId || !validateCsrfToken(csrfToken, sessionId)) {
    return NextResponse.json(
      { error: "Invalid CSRF token" },
      { status: 403 }
    );
  }

  return null;
}
```

---

## §SEC-04: Secure Cookie Configuration

```ts
// lib/cookies.ts
import { cookies } from "next/headers";
import type { ResponseCookie } from "next/dist/compiled/@edge-runtime/cookies";

const SECURE_DEFAULTS: Partial<ResponseCookie> = {
  httpOnly: true,
  secure: true,
  sameSite: "strict",
  path: "/",
  maxAge: 15 * 60, // 15 minutes
};

export async function setSecureCookie(
  name: string,
  value: string,
  overrides?: Partial<ResponseCookie>
): Promise<void> {
  const cookieStore = await cookies();
  cookieStore.set(name, value, { ...SECURE_DEFAULTS, ...overrides });
}

export async function clearSecureCookie(name: string): Promise<void> {
  const cookieStore = await cookies();
  cookieStore.delete(name);
}
```

---

## §SEC-05: Zod Validation on Route Handlers and Server Actions

### Route Handler Example

```ts
// app/api/transfers/route.ts
import { NextResponse } from "next/server";
import { z } from "zod";

const TransferSchema = z.object({
  fromAccount: z.string().regex(/^\d{10}$/, "Invalid account number"),
  toAccount: z.string().regex(/^\d{10}$/, "Invalid account number"),
  amount: z.number().positive().max(1_000_000),
  currency: z.enum(["USD", "EUR", "GBP"]),
  reference: z.string().max(140).optional(),
});

export type TransferRequest = z.infer<typeof TransferSchema>;

export async function POST(request: Request) {
  const raw = await request.json();
  const result = TransferSchema.safeParse(raw);

  if (!result.success) {
    return NextResponse.json(
      { error: "Validation failed", details: result.error.flatten() },
      { status: 400 }
    );
  }

  const transfer = result.data;
  // ... process transfer
  return NextResponse.json({ status: "accepted" }, { status: 202 });
}
```

### Server Action Example

```ts
// app/actions/transfer.ts
"use server";

import { z } from "zod";
import { auth } from "@/lib/auth";
import { revalidatePath } from "next/cache";

const TransferActionSchema = z.object({
  fromAccount: z.string().regex(/^\d{10}$/),
  toAccount: z.string().regex(/^\d{10}$/),
  amount: z.number().positive().max(1_000_000),
});

export async function createTransfer(formData: FormData) {
  const session = await auth();
  if (!session) throw new Error("Unauthorized");

  const parsed = TransferActionSchema.safeParse({
    fromAccount: formData.get("fromAccount"),
    toAccount: formData.get("toAccount"),
    amount: Number(formData.get("amount")),
  });

  if (!parsed.success) {
    return { error: parsed.error.flatten() };
  }

  // ... execute transfer
  revalidatePath("/dashboard/transfers");
  return { success: true };
}
```

---

## §SEC-06: Dependency Audit and Environment Variable Safety

### npm Audit CI Script

```json
// package.json (scripts section)
{
  "scripts": {
    "audit:check": "npm audit --audit-level=high --omit=dev",
    "audit:fix": "npm audit fix",
    "env:check": "node scripts/check-env.mjs"
  }
}
```

### Environment Variable Checker

```ts
// scripts/check-env.mjs
import { readFileSync, readdirSync, statSync } from "fs";
import { join } from "path";

const FORBIDDEN_PATTERNS = [
  /NEXT_PUBLIC_.*SECRET/i,
  /NEXT_PUBLIC_.*KEY/i,
  /NEXT_PUBLIC_.*TOKEN/i,
  /NEXT_PUBLIC_.*PASSWORD/i,
];

function scanFile(filePath) {
  const content = readFileSync(filePath, "utf-8");
  const lines = content.split("\n");

  lines.forEach((line, i) => {
    FORBIDDEN_PATTERNS.forEach((pattern) => {
      if (pattern.test(line)) {
        console.error(`VIOLATION: ${filePath}:${i + 1} — secret exposed with NEXT_PUBLIC_ prefix`);
        process.exitCode = 1;
      }
    });
  });
}

function walk(dir) {
  for (const entry of readdirSync(dir)) {
    if (entry === "node_modules" || entry === ".next") continue;
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) walk(full);
    else if (/\.(ts|tsx|js|jsx|env)$/.test(entry)) scanFile(full);
  }
}

walk(".");
```

---

## §SEC-07: Security Integration Tests

```ts
// __tests__/security/headers.test.ts
import { describe, it, expect } from "vitest";

describe("Security Headers", () => {
  it("should return CSP header", async () => {
    const res = await fetch("http://localhost:3000/");
    const csp = res.headers.get("content-security-policy");

    expect(csp).toBeDefined();
    expect(csp).not.toContain("unsafe-inline");
    expect(csp).not.toContain("unsafe-eval");
    expect(csp).toContain("frame-ancestors 'none'");
  });

  it("should return HSTS header", async () => {
    const res = await fetch("http://localhost:3000/");
    const hsts = res.headers.get("strict-transport-security");
    expect(hsts).toContain("max-age=63072000");
  });

  it("should reject request without CSRF token", async () => {
    const res = await fetch("http://localhost:3000/api/transfers", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ amount: 100 }),
    });
    expect(res.status).toBe(403);
  });
});

// __tests__/security/auth.test.ts
import { describe, it, expect } from "vitest";

describe("Authentication", () => {
  it("should redirect unauthenticated users to sign-in", async () => {
    const res = await fetch("http://localhost:3000/dashboard", {
      redirect: "manual",
    });
    expect(res.status).toBe(307);
    expect(res.headers.get("location")).toContain("/auth/signin");
  });

  it("should not expose session token in response body", async () => {
    const res = await fetch("http://localhost:3000/api/auth/session");
    const body = await res.json();
    expect(body).not.toHaveProperty("accessToken");
    expect(body).not.toHaveProperty("refreshToken");
  });
});
```
