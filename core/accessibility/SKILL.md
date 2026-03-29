---
name: accessibility
description: Audit and fix accessibility issues against WCAG 2.1 AA and bank accessibility policy — supports Flutter, React, iOS, Android
allowed-tools: Read, Edit, Write, Glob, Grep, Bash
argument-hint: "[platform] [scope] — e.g. 'flutter', 'react forms', 'ios voiceover', 'android keyboard'"
---

# Accessibility Audit & Remediation

You are an accessibility expert for the bank's applications. When invoked, audit and fix accessibility issues against WCAG 2.1 AA and bank accessibility policy.

## Step 0 — Collect Context (MANDATORY)

Before any work, you MUST ask these three questions. Do not guess. Do not infer. Do not proceed until all are answered.

**Q1: Target type**
> "Is this a **mobile** app, a **web** app, or **both**?"

**Q2: Platform/framework**

| If target is | Ask |
|--------------|-----|
| Mobile | "Which framework: **Flutter**, **iOS native (Swift)**, or **Android native (Kotlin)**?" |
| Web | "Which framework: **React/Next.js**, or another?" |
| Both | Ask both questions above |

**Q3: Audit scope**
> "What should I audit: **full app**, **specific screen/page**, **specific component**, or **PR/diff changes only**?"

### After All Three Answers — Load References

| User's platform | Read this file | Also read |
|-----------------|----------------|-----------|
| Flutter | `core/accessibility/flutter/reference.md` | `core/accessibility/reference.md` |
| React / Next.js | `core/accessibility/react/reference.md` | `core/accessibility/reference.md` |
| iOS (Swift) | `core/accessibility/ios/reference.md` | `core/accessibility/reference.md` |
| Android (Kotlin) | `core/accessibility/android/reference.md` | `core/accessibility/reference.md` |

If both mobile + web, load all applicable references. **Do NOT proceed to Step 1 until references are loaded.**

## Section Navigation Guide

Use this table to find what you need in the loaded platform reference:

| Need | Section heading to read |
|------|-------------------------|
| Framework's a11y philosophy | `## Core Principle` |
| Code-level WRONG/CORRECT examples | `## Hard Rules` |
| Common mistakes to flag | `## Anti-Patterns` |
| Screen reader / assistive tech behavior | `## Accessibility Services` or `## <ScreenReader> Patterns` |
| Minimum tap/click target sizes | `## Touch Targets` |
| Labeling conventions for banking UI | `## Semantic Label Patterns` |
| Focus order implementation | `## Focus & Navigation Order` or `## Keyboard Navigation` |
| Accessible form implementation | `## Forms` or `## Accessible Forms` |
| Reduce motion / display accommodations | `## Reduce Motion` or `## Display Accommodations` |
| Automated + manual test patterns | `## Testing` |
| Report template | `## Audit Report Format` |

## Target Compliance

- **WCAG 2.1 AA is the required baseline.** All UI must pass Level A + AA.
- **WCAG 2.1 AAA is optional.** Only apply if the user explicitly requests it.

## Hard Rules

1. **Every interactive element must be keyboard-accessible.** Use native interactive elements — never attach tap/click handlers to non-interactive containers.
2. **Every non-text element must have a text alternative.** All images, icons, charts, and media need a descriptive label — or must be explicitly marked as decorative.
3. **Never use color alone to convey information.** Always pair color with an icon, label, or pattern.
4. **Never wrap text in fixed-size containers.** Text must scale to 200% without clipping. Use minimum-height constraints.
5. **Focus must not trigger context changes.** Receiving focus must never navigate, submit, or alter content.
6. **Interactive elements must have correct semantic roles.** Use platform-native components. Only add custom roles when no native element fits.
7. **Never hide meaningful content from assistive tech.** Only hide purely decorative elements.

## Core Standards

| Area | Standard | Level |
|------|----------|-------|
| Perceivable | Text alternatives for all non-text content | A |
| Perceivable | Color contrast 4.5:1 (text), 3:1 (large text/UI) | AA |
| Perceivable | Content reflows at 320px (web) / supports both orientations (mobile) | AA |
| Perceivable | Text scales to 200% without clipping | AA |
| Operable | All functionality via keyboard — no traps | A |
| Operable | Focus order matches visual/logical order | A |
| Operable | Visible focus indicator (3:1 contrast) | AA |
| Understandable | Page/screen language declared | A |
| Understandable | Error messages identify field and suggest fix | AA |
| Understandable | Labels for all inputs | A |
| Robust | Name, role, value exposed to assistive tech | A |
| Bank policy | Financial data readable by screen readers | Required |
| Bank policy | Transaction confirmations announced via live regions | Required |
| Bank policy | Session timeout: 2-min warning with extend option | Required |

For the full WCAG 2.1 AA checklist mapped to banking UI, read `core/accessibility/reference.md` § WCAG Checklist.

## Platform-Specific Considerations

| Platform | Key constraints |
|----------|----------------|
| **Flutter** | Prefer built-in widget semantics over custom Semantics wrappers. Never use GestureDetector for interactivity. Touch targets ≥ 48dp/44pt. Respect MediaQuery.disableAnimations. MergeSemantics for grouping. |
| **React** | Semantic HTML first — ARIA is fallback. No dangerouslySetInnerHTML without sanitization. Focus trap in modals. Skip link on every page. Landmarks required. Reflow at 320px. prefers-reduced-motion. |
| **iOS** | SwiftUI accessibility modifiers. Dynamic Type support — test at AX5. UIAccessibility.post for announcements. @ScaledMetric for custom sizes. Touch targets ≥ 44pt. |
| **Android** | Compose semantics {} block. Role on Modifier.clickable. LiveRegionMode.Assertive for errors. contentDescription on images. Touch targets ≥ 48dp. Respect animator duration scale. |

## Severity Classification

| Severity | Blocks access? | Example |
|----------|----------------|---------|
| **CRITICAL** | Yes — entirely | Missing semantics on interactive element, keyboard trap |
| **MAJOR** | Partially | Poor contrast, small touch targets, no focus indicator |
| **MINOR** | No — inconvenience | Suboptimal focus order, missing helper text |

## Workflow

1. **Collect context** — ask Q1, Q2, Q3 from Step 0. Stop until all answered.
2. **Load references** — read the platform reference + core reference per the table above.
3. **Identify scope** — list UI components to audit based on the user's scope answer.
4. **Audit semantics** — check against `## Hard Rules` in the platform reference.
5. **Audit keyboard/navigation** — all interactive paths, no traps, logical order.
6. **Audit visual** — contrast, text scaling, color independence.
7. **Audit assistive tech** — screen reader announcements, live regions, roles (use platform reference mappings).
8. **Remediate** — fix by severity (CRITICAL first), using code patterns from platform reference.
9. **Test** — write tests using patterns from `## Testing` in the platform reference.
10. **Report** — generate audit report using `## Audit Report Format` from the platform reference.

## Checklist

- [ ] Step 0 complete — target type, platform, and scope collected
- [ ] Platform reference and core reference loaded
- [ ] All interactive elements keyboard-accessible
- [ ] No keyboard/focus traps
- [ ] Visible focus indicator on every interactive element
- [ ] All images/icons have text alternatives or marked decorative
- [ ] Contrast meets AA: 4.5:1 text, 3:1 large text/UI
- [ ] Color never sole indicator of meaning
- [ ] Text scales to 200% without clipping
- [ ] Orientation/reflow requirement met per target type
- [ ] Form inputs have labels and error messages
- [ ] Dynamic content announced via live regions
- [ ] Session timeout: 2-min warning with extend option
- [ ] Reduced motion preference respected
- [ ] Touch/click targets meet platform minimum
- [ ] Tests written using platform reference patterns
- [ ] Audit report generated using platform reference template
