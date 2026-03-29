# Accessibility — Reference

## WCAG Checklist

Full WCAG 2.1 AA success criteria most relevant to banking applications.

### Perceivable

| Criterion | ID | Requirement | Banking Context |
|---|---|---|---|
| Non-text Content | 1.1.1 | Text alternative for all non-text content | Charts, logos, status icons, CAPTCHA alternatives |
| Captions | 1.2.2 | Captions for prerecorded audio/video | Tutorial videos, customer support recordings |
| Info and Relationships | 1.3.1 | Structure conveyed programmatically | Account tables, transaction lists, form groups |
| Meaningful Sequence | 1.3.2 | Reading order matches visual order | Multi-column layouts, dashboard widgets |
| Sensory Characteristics | 1.3.3 | Instructions not based solely on shape, size, location, sound | "Click the green button" is not sufficient |
| Orientation | 1.3.4 | Content not restricted to single orientation | Mobile banking must work in both orientations |
| Input Purpose | 1.3.5 | Autocomplete attributes on common fields | Name, email, phone, address, card number |
| Use of Color | 1.4.1 | Color not sole means of conveying info | Transaction status, account health indicators |
| Contrast (Minimum) | 1.4.3 | 4.5:1 for normal text, 3:1 for large text | All text including balances, rates, disclaimers |
| Resize Text | 1.4.4 | Text resizable to 200% without loss | All pages, especially transaction tables |
| Reflow | 1.4.10 | No horizontal scroll at 320px width | Mobile-first banking layouts |
| Non-text Contrast | 1.4.11 | 3:1 for UI components and graphical objects | Buttons, input borders, chart elements |
| Text Spacing | 1.4.12 | Content readable with increased spacing | Line height 1.5x, letter spacing 0.12em |

### Operable

| Criterion | ID | Requirement | Banking Context |
|---|---|---|---|
| Keyboard | 2.1.1 | All functionality via keyboard | Transfers, bill pay, account navigation |
| No Keyboard Trap | 2.1.2 | Focus can always be moved away | Modal dialogs, dropdown menus, date pickers |
| Timing Adjustable | 2.2.1 | Users can extend time limits | Session timeout: 2-min warning, extend option |
| Pause, Stop, Hide | 2.2.2 | User can control moving content | Auto-rotating promotions, live rate tickers |
| Skip Links | 2.4.1 | Bypass repeated content | "Skip to main content" on every page |
| Page Titled | 2.4.2 | Descriptive page titles | "Transfer Funds — MyBank" not just "MyBank" |
| Focus Order | 2.4.3 | Logical tab order | Form fields, action buttons, navigation |
| Link Purpose | 2.4.4 | Link text describes destination | "View January statement" not "Click here" |
| Multiple Ways | 2.4.5 | More than one way to find pages | Nav + search + sitemap |
| Headings and Labels | 2.4.6 | Descriptive headings and labels | "Recent Transactions" not "Section 3" |
| Focus Visible | 2.4.7 | Visible focus indicator | Minimum 2px outline, sufficient contrast |

### Understandable

| Criterion | ID | Requirement | Banking Context |
|---|---|---|---|
| Language of Page | 3.1.1 | Default language declared | lang attribute on root element |
| Language of Parts | 3.1.2 | Language changes marked | Multilingual terms and conditions |
| On Focus | 3.2.1 | No context change on focus | Don't submit form on field focus |
| On Input | 3.2.2 | No unexpected context change on input | Warn before navigating away from form |
| Consistent Navigation | 3.2.3 | Nav order consistent across pages | Same header/sidebar on all authenticated pages |
| Error Identification | 3.3.1 | Errors identified and described | "Amount must be between $0.01 and $50,000" |
| Labels or Instructions | 3.3.2 | Labels for all inputs | Every form field has a visible label |
| Error Suggestion | 3.3.3 | Suggest corrections when possible | "Did you mean IBAN format: XX00..." |
| Error Prevention | 3.3.4 | Review step for financial/legal submissions | Confirmation page before transfers |

### Robust

| Criterion | ID | Requirement | Banking Context |
|---|---|---|---|
| Parsing | 4.1.1 | Valid markup | No duplicate IDs, proper nesting |
| Name, Role, Value | 4.1.2 | All components expose name, role, value | Custom widgets must declare semantics |
| Status Messages | 4.1.3 | Status messages announced without focus change | Transaction confirmations, error alerts |

---

## ARIA Patterns

### Common Banking UI Patterns

| Component | ARIA Pattern | Key Attributes |
|---|---|---|
| Account balance | Live region | `aria-live="polite"` on balance container |
| Transaction status | Status message | `role="status"` with descriptive text |
| Transfer confirmation | Alert dialog | `role="alertdialog"`, `aria-describedby` |
| Account selector | Combobox | `role="combobox"`, `aria-expanded`, `aria-activedescendant` |
| Transaction table | Data table | `role="table"`, proper `th` scope, `aria-sort` for sortable columns |
| Navigation menu | Navigation | `role="navigation"`, `aria-label` to distinguish multiple navs |
| Loading indicator | Status | `aria-busy="true"` on container, `role="status"` with "Loading..." text |
| Modal (OTP entry) | Dialog | `role="dialog"`, `aria-modal="true"`, trap focus, return focus on close |
| Tab panel (account views) | Tablist | `role="tablist"`, `role="tab"`, `aria-selected`, `role="tabpanel"` |
| Error summary | Alert | `role="alert"`, appears at top of form, links to each error field |
| Session warning | Alert dialog | `role="alertdialog"`, auto-focus, extend/logout options |

### Live Region Usage

| Scenario | `aria-live` Value | Rationale |
|---|---|---|
| Balance update | `polite` | Not urgent — wait for user idle |
| Transaction success | `polite` | Informational confirmation |
| Transaction failure | `assertive` | User must know immediately |
| Session expiry warning | `assertive` | Time-sensitive action required |
| Search results count | `polite` | Supplementary information |
| Rate/price update | `off` (manual announce) | Too frequent — announce on demand |

---

## Color Contrast

### Minimum Ratios (WCAG 2.1 AA)

| Element Type | Minimum Ratio | Example |
|---|---|---|
| Normal text (< 18pt / < 14pt bold) | 4.5:1 | Body copy, labels, table cells |
| Large text (>= 18pt / >= 14pt bold) | 3:1 | Headings, large buttons |
| UI components (borders, icons) | 3:1 | Input borders, toggle switches, chart lines |
| Focus indicators | 3:1 | Outline against adjacent colors |
| Disabled elements | No requirement | But must be distinguishable as disabled |

### Bank-Specific Considerations

- **Financial status colors**: Always pair with icon and text label (green checkmark + "Approved", red X + "Declined").
- **Charts and graphs**: Use patterns/textures in addition to color differentiation. Provide data table alternative.
- **Branded elements**: Bank brand colors must still meet contrast ratios. Request accessible palette from design team if needed.
- **Dark mode**: Maintain all contrast ratios in dark theme. Test independently.

---

## Form Accessibility

### Required Form Patterns

| Pattern | Implementation |
|---|---|
| Label association | Programmatic label linked to input — never placeholder-only |
| Required fields | Mark as required programmatically + visual indicator (not just asterisk without explanation) |
| Error display | Inline error below field + error summary at top; link field to error description |
| Field grouping | Group related fields (address, payment method) with a group label |
| Input format hint | Associate format example ("DD/MM/YYYY") with the field |
| Autocomplete | Use autocomplete attributes: `name`, `email`, `tel`, `cc-number`, `cc-exp` |
| Submit confirmation | Review page before final submission for financial transactions |

### Error Message Structure

```
error_summary:
    role: "alert"
    heading: "Please fix N errors before continuing"
    items:
        - link to field + error description

inline_error:
    linked to field via describedby
    invalid state: "true"
    message: "[Field name] — [what went wrong] — [how to fix]"
```

### Accessible Transfer Form Structure

```
form label="Fund Transfer"
  fieldset label="Transfer Details"

    label "From Account" → select (required, no autocomplete)

    label "To Account or IBAN" → input (required)
      hint: "Enter account number or IBAN"
      error: "Account number must be 10-34 characters"

    label "Amount" → input (required, decimal, autocomplete=transaction-amount)

  button "Review Transfer"
```

---

## Testing Methods

### Automated Testing

| Tool Category | Purpose | When to Run |
|---|---|---|
| Linter plugins | Catch a11y issues in markup/templates at dev time | Pre-commit, IDE |
| CI a11y scanner | Automated WCAG rule checking | Every PR, merge to main |
| Contrast checker | Validate color combinations | Design review, PR |

### Manual Testing Protocol

| Step | Method | Frequency |
|---|---|---|
| Keyboard navigation | Tab through all flows without mouse | Every PR with UI changes |
| Screen reader | Test with primary SR for target platform | Every feature, pre-release |
| Zoom to 200% | Verify no content loss or overlap | Every PR with layout changes |
| Reduced motion | Enable prefers-reduced-motion, verify | Every PR with animations |
| High contrast mode | Verify readability in OS high contrast | Pre-release |
| Mobile VoiceOver/TalkBack | Test on real devices | Pre-release |

### Screen Reader Priority by Platform

| Platform | Primary SR | Secondary SR |
|---|---|---|
| Web (Windows) | NVDA | JAWS |
| Web (macOS) | VoiceOver | — |
| iOS | VoiceOver | — |
| Android | TalkBack | — |

### Common Banking A11y Defects

| Defect | Impact | Fix |
|---|---|---|
| Balance not in live region | Screen reader users miss updates | Add live region with polite priority |
| Transaction table missing headers | Data is meaningless without context | Add proper header cells with scope |
| OTP modal doesn't trap focus | User tabs behind modal | Implement focus trap |
| Session timeout without warning | User loses work unexpectedly | 2-min warning dialog with extend option |
| PDF statements inaccessible | Cannot read with assistive tech | Generate tagged PDFs or provide HTML alternative |
