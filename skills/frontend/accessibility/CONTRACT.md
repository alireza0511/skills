# Skill Contract — Accessibility

## Identity

- **Name:** accessibility
- **Version:** 1.0.0
- **One-liner:** Audit and fix accessibility issues against WCAG 2.1 AA and accessibility policy
- **framework:** flutter, react
- **Target type:** ios, android, web browser

## What the LLM Must Ask the User First

- Is this a mobile app, a web app, or both?
- Which framework/platform: Flutter, React/Next.js?
- What is the audit scope: full app, specific screen/page, specific component, or PR/diff changes only?

## Hard Rules

- Every interactive element must be keyboard-accessible — use native interactive elements, never attach handlers to non-interactive containers
- Every non-text element must have a text alternative or be explicitly marked decorative
- Never use color alone to convey information — always pair with icon, label, or pattern
- Never wrap text in fixed-size containers — must scale to 200% without clipping
- Focus must not trigger context changes — actions require explicit user activation
- Interactive elements must have correct semantic roles — use platform-native components
- Never hide meaningful content from assistive tech — only hide purely decorative elements

## Standards

- WCAG 2.1 AA is the required baseline (Level A + AA)
- Color contrast: 4.5:1 for text, 3:1 for large text and UI components
- All functionality available via keyboard with no traps
- Focus order matches visual/logical order with visible focus indicator (3:1 contrast)
- Page/screen language declared
- Error messages identify the field and suggest a fix
- All form inputs have labels
- Name, role, value exposed to assistive tech
- Policy: financial data must be screen-reader readable
- Policy: transaction confirmations announced via live regions
- Policy: before announcing secure data, inform the user that the hide/show button will reveal sensitive information

## Platform-Specific Notes

### Flutter
- Prefer built-in widget semantics over custom Semantics wrappers
- Never use GestureDetector for interactive elements — use InkWell or Material widgets
- Touch targets minimum 48dp (Android) / 44pt (iOS)
- Respect MediaQuery.disableAnimations for reduce motion
- MergeSemantics for grouping related content
- ExcludeSemantics only for decorative elements

### React
- Semantic HTML first — ARIA is a fallback, not the default
- Never use dangerouslySetInnerHTML without sanitization
- Focus trap required in all modals (focus-trap-react)
- Skip link to main content on every page
- Landmark regions: header, nav, main, footer
- Content must reflow at 320px without horizontal scroll
- prefers-reduced-motion CSS media query for animations

## Workflow

1. Collect context — ask the three mandatory questions, do not proceed without answers
2. Load the correct platform reference file based on user answers
3. Identify scope — list UI components to audit based on user's scope answer
4. Audit semantics — check against hard rules using platform reference patterns
5. Audit keyboard/navigation — verify all interactive paths, no traps, logical order
6. Audit visual — contrast ratios, text scaling, color independence
7. Audit assistive tech — screen reader announcements, live regions, roles
8. Remediate — fix by severity (CRITICAL > MAJOR > MINOR) using platform reference code patterns
9. Write tests and generate audit report using platform reference templates

## Checklist

- [ ] Three context questions asked and answered
- [ ] Platform reference loaded
- [ ] All interactive elements keyboard-accessible
- [ ] No keyboard/focus traps
- [ ] Visible focus indicator on every interactive element
- [ ] All images/icons have text alternatives or marked decorative
- [ ] Contrast meets AA thresholds
- [ ] Color never sole indicator of meaning
- [ ] Text scales to 200% without clipping
- [ ] Orientation/reflow requirements met
- [ ] Form inputs have labels and error messages
- [ ] Dynamic content announced via live regions
- [ ] Reduced motion preference respected
- [ ] Touch/click targets meet platform minimum
- [ ] Tests written
- [ ] Audit report generated

## Reference Sections Needed

### Per-Platform (flutter/REFERENCE.md, react/REFERENCE.md, etc.)

Each platform REFERENCE.md includes the core WCAG checklist, ARIA patterns, color contrast requirements, form accessibility patterns, and testing methodology — plus platform-specific content:
- Core principle — framework's built-in accessibility approach and when to customize
- Hard rules with WRONG/CORRECT code examples specific to the framework
- Anti-patterns to flag during audit
- Assistive tech mapping (screen reader gestures, announcements, property-to-behavior mapping)
- Touch/click target implementation patterns
- Semantic label/description patterns for UI (buttons, inputs, amounts, radio groups)
- Focus and navigation order implementation
- Form accessibility patterns
- Reduce motion / display accommodation implementation
- Automated test code patterns (framework-specific test library)
- Manual testing checklist per assistive tech service
- Audit report template
