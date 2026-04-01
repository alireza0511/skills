# Accessibility — Flutter Reference

Flutter-specific accessibility patterns for mobile applications. See `skills/frontend/accessibility/flutter/SKILL.md` for core rules.

## Core Principle

**Avoid wrapping widgets with custom `Semantics` unless absolutely necessary.** Flutter's built-in widgets already provide correct semantic roles, states, and announcements. Wrapping them overrides framework behavior, risks duplicates, and adds maintenance burden.

Use custom `Semantics` only for:
- Custom-painted widgets (`CustomPaint`, `Canvas`)
- `MergeSemantics` composites (icon + text as one unit)
- Live regions (`Semantics(liveRegion: true)`)
- Excluding decorative elements (`ExcludeSemantics`)
- Custom sort order (`OrdinalSortKey`) as last resort

```dart
// JUSTIFIED — CustomPaint has zero built-in semantics
Semantics(
  label: 'Rating: 4 out of 5 stars',
  child: CustomPaint(painter: StarRatingPainter(rating: 4)),
)

// JUSTIFIED — decorative divider
ExcludeSemantics(child: Divider())

// JUSTIFIED — error must auto-announce
Semantics(liveRegion: true, child: Text(errorMessage))
```

## Anti-Patterns

Flag these during audit — wrapping built-in widgets with redundant `Semantics`:

```dart
// WRONG — ElevatedButton already announces as "Button"
Semantics(
  button: true,
  label: 'Submit',
  child: ElevatedButton(
    onPressed: _submit,
    child: Text('Submit'),
  ),
)

// WRONG — TextField already announces as "Text field"
Semantics(
  textField: true,
  label: 'Email',
  child: TextField(
    decoration: InputDecoration(labelText: 'Email'),
  ),
)

// WRONG — Radio already manages checked/unchecked state
Semantics(
  checked: isSelected,
  child: Radio<String>(value: 'a', groupValue: selected, onChanged: _onChanged),
)
```

## Hard Rules

### Never use GestureDetector for interactive elements

`GestureDetector` does NOT receive keyboard focus, Switch Access scanning, or Voice Access targeting.

```dart
// WRONG — unreachable via keyboard, switch, or voice
GestureDetector(onTap: _onTap, child: Text('Click me'))

// CORRECT — focusable, keyboard-activatable, scannable
InkWell(onTap: _onTap, child: Text('Click me'))
```

### Icon-only buttons must have tooltip or semanticLabel

```dart
// WRONG — no accessible name
IconButton(onPressed: _delete, icon: Icon(Icons.delete))

// CORRECT — tooltip serves as accessible name AND voice target
IconButton(onPressed: _delete, icon: Icon(Icons.delete), tooltip: 'Delete item')
```

### Images must be accessible or explicitly decorative

```dart
// WRONG — screen reader says nothing
Image.asset('assets/logo.png')

// CORRECT — meaningful image
Image.asset('assets/profile.png', semanticLabel: 'Profile photo of John Doe')

// CORRECT — decorative image
Image.asset('assets/wave.png', excludeFromSemantics: true)
```

### Never use ExcludeSemantics on non-decorative content

```dart
// CORRECT — decorative divider
ExcludeSemantics(child: Divider())

// WRONG — this icon conveys error state
ExcludeSemantics(child: Icon(Icons.error, color: Colors.red))
```

### Never wrap Text in fixed-height containers

```dart
// WRONG — clips at large font sizes
SizedBox(height: 48, child: Text('Clipped at 200%'))

// CORRECT — grows with text
ConstrainedBox(constraints: BoxConstraints(minHeight: 48), child: Text('Grows'))
```

## Accessibility Services

### Screen Readers

| `Semantics` Property | TalkBack | VoiceOver |
|----------------------|----------|-----------|
| `label` | Read as element name | Read as element name |
| `hint` | "Double tap to..." | "Double tap to..." |
| `button: true` | Appends "Button" | Appends "Button" |
| `header: true` | Appends "Heading" | Appends "Heading" |
| `textField: true` | "Edit box" | "Text field" |
| `enabled: false` | "Disabled" | "Dimmed" |
| `liveRegion: true` | Auto-announces changes | Auto-announces changes |
| `value` | Reads current value | Reads current value |

### Keyboard Navigation

| Action | Key |
|--------|-----|
| Move focus forward | Tab |
| Move focus backward | Shift+Tab |
| Activate button/link | Enter or Space |
| Toggle checkbox/switch | Space |
| Navigate radio group | Arrow keys |
| Dismiss dialog/sheet | Escape |

**Flutter requirements:**
- All interactive widgets must receive focus via Tab
- Focus indicator must be visible (never hide it)
- Focus must not get trapped — Escape must dismiss overlays
- Focus order must match visual layout
- Never use `GestureDetector` for interactive elements

### Voice Control

| Feature | Android (Voice Access) | iOS (Voice Control) |
|---------|----------------------|---------------------|
| Activate by label | "Tap [label]" | "Tap [label]" |
| Show numbers | "Show numbers" | "Show numbers" |
| Type text | "Type [text]" | "Type [text]" |

**Flutter requirements:**
- Every interactive element must have a visible label or accessible name
- Labels must be unique within the visible screen
- Icon-only buttons must have `semanticLabel` or `tooltip`

### Switch Access / Switch Control

**Flutter requirements:**
- All interactive widgets must appear in scan order
- Related elements grouped via `MergeSemantics`
- No time-limited interactions
- Keep focusable element count reasonable

```dart
// GOOD — MergeSemantics reduces scan targets
MergeSemantics(
  child: ListTile(
    leading: Icon(Icons.account_circle),
    title: Text('John Doe'),
    subtitle: Text('john@example.com'),
    onTap: _openProfile,
  ),
)
```

## Touch Targets

Minimum sizes:
- Android: 48x48 dp
- iOS: 44x44 pt
- Use 48 to satisfy both

```dart
ConstrainedBox(
  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
  child: /* existing widget */,
)
```

## Semantic Label Patterns

```dart
// Buttons — describe the action
semanticLabel: 'Submit payment of \$50.00'

// Inputs — describe what to enter
semanticLabel: 'Enter your email address'

// Radio — describe the option and group
semanticLabel: 'Select basic plan, option 1 of 3'

// Amount — include currency context
semanticLabel: 'Enter amount in US dollars'
```

## Focus & Navigation Order

Prefer fixing the widget order in the tree. Only use `OrdinalSortKey` as last resort.

```dart
// PREFERRED — natural tree order
Column(
  children: [
    Text('Form Title'),
    TextInput(/* email */),
    TextInput(/* password */),
    ElevatedButton(/* submit */),
  ],
)

// LAST RESORT — layout makes natural order impossible
Semantics(sortKey: OrdinalSortKey(0), child: Text('Form Title'))
```

## Display Accommodations

| Setting | Flutter API |
|---------|------------|
| Large text | `MediaQuery.textScaleFactor` — layouts must not clip |
| Bold text | `MediaQuery.boldText` |
| High contrast | `MediaQuery.highContrast` |
| Reduce motion | `MediaQuery.disableAnimations` |
| Reduce transparency | `MediaQuery.reduceTransparency` |

```dart
// Reduce motion
final reduceMotion = MediaQuery.of(context).disableAnimations;
final duration = reduceMotion ? Duration.zero : const Duration(milliseconds: 150);

// High contrast
final highContrast = MediaQuery.of(context).highContrast;
```

## Forms

Accessible form patterns for common workflows. Use Flutter's built-in form widgets — they provide correct semantic roles and validation announcements automatically.

```dart
// Accessible transfer form
Form(
  child: Column(
    children: [
      // Labeled input with error
      TextFormField(
        decoration: InputDecoration(
          labelText: 'Amount',
          errorText: amountError,
          hintText: 'Enter amount in dollars',
        ),
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        validator: (value) => value == null || value.isEmpty
            ? 'Amount is required' : null,
      ),

      // Error summary — announced via live region
      if (errors.isNotEmpty)
        Semantics(
          liveRegion: true,
          child: Text('${errors.length} errors found'),
        ),

      // Submit button
      ElevatedButton(
        onPressed: _review,
        child: Text('Review Transfer'),
      ),
    ],
  ),
)
```

**Key rules for forms:**
- Use `TextFormField` with `InputDecoration.labelText` — never rely on placeholder text alone
- Use `errorText` for inline validation errors — screen readers announce these automatically
- Use `Semantics(liveRegion: true)` for error summaries so they are announced immediately
- Group related fields in a `Column` to maintain natural focus order
- Provide `keyboardType` to show the appropriate keyboard for the input type

## Testing

### Manual Testing

| Test | Android (TalkBack) | iOS (VoiceOver) |
|------|-----|-----|
| Navigate elements | Swipe right through screen | Swipe right through screen |
| Activate buttons | Double-tap | Double-tap |
| Verify announcements | Each element reads name + role + state | Same |
| Keyboard: Tab through | Connect physical keyboard, Tab | Same |
| Keyboard: Activate | Enter or Space | Enter or Space |
| Voice: Activate by label | "Tap Submit" | "Tap Submit" |
| Large text | Settings > Font size > max | Settings > Dynamic Type > max |
| Reduce motion | Settings > Remove animations | Settings > Reduce Motion |

## Audit Report Format

```
## Flutter Accessibility Audit Report
**Level:** AA | **Platforms:** Android + iOS | **Date:** YYYY-MM-DD

### Summary
- CRITICAL: N issues
- MAJOR: N issues
- MINOR: N issues

### Findings

#### [CRITICAL] Missing semantic label on IconButton
**File:** lib/src/widgets/toolbar.dart:L42
**Issue:** Icon-only button has no tooltip or semanticLabel
**Affects:** Screen readers, Voice Access, Switch Access
**Fix:** Add `tooltip: 'Delete item'`
**WCAG:** 1.1.1 Non-text Content (A)

#### [MAJOR] GestureDetector not keyboard-accessible
**File:** lib/src/widgets/card.dart:L78
**Issue:** Card uses GestureDetector — not focusable via Tab
**Affects:** Keyboard users, Switch Access
**Fix:** Replace with InkWell
**WCAG:** 2.1.1 Keyboard (A)

### Passed Checks
- [✓] Touch targets meet 48dp minimum
- [✓] Focus indicators visible
- [✓] Reduce Motion respected
```

---

# Core Accessibility Reference

## WCAG Checklist

Full WCAG 2.1 AA success criteria most relevant to applications.

### Perceivable

| Criterion | ID | Requirement | Context |
|---|---|---|---|
| Non-text Content | 1.1.1 | Text alternative for all non-text content | Charts, logos, status icons, CAPTCHA alternatives |
| Captions | 1.2.2 | Captions for prerecorded audio/video | Tutorial videos, customer support recordings |
| Info and Relationships | 1.3.1 | Structure conveyed programmatically | Account tables, transaction lists, form groups |
| Meaningful Sequence | 1.3.2 | Reading order matches visual order | Multi-column layouts, dashboard widgets |
| Sensory Characteristics | 1.3.3 | Instructions not based solely on shape, size, location, sound | "Click the green button" is not sufficient |
| Orientation | 1.3.4 | Content not restricted to single orientation | App must work in both orientations |
| Input Purpose | 1.3.5 | Autocomplete attributes on common fields | Name, email, phone, address, card number |
| Use of Color | 1.4.1 | Color not sole means of conveying info | Transaction status, account health indicators |
| Contrast (Minimum) | 1.4.3 | 4.5:1 for normal text, 3:1 for large text | All text including balances, rates, disclaimers |
| Resize Text | 1.4.4 | Text resizable to 200% without loss | All pages, especially transaction tables |
| Reflow | 1.4.10 | No horizontal scroll at 320px width | Mobile-first layouts |
| Non-text Contrast | 1.4.11 | 3:1 for UI components and graphical objects | Buttons, input borders, chart elements |
| Text Spacing | 1.4.12 | Content readable with increased spacing | Line height 1.5x, letter spacing 0.12em |

### Operable

| Criterion | ID | Requirement | Context |
|---|---|---|---|
| Keyboard | 2.1.1 | All functionality via keyboard | Transfers, bill pay, account navigation |
| No Keyboard Trap | 2.1.2 | Focus can always be moved away | Modal dialogs, dropdown menus, date pickers |
| Timing Adjustable | 2.2.1 | Users can extend time limits | Time-limited actions must warn before expiry |
| Pause, Stop, Hide | 2.2.2 | User can control moving content | Auto-rotating promotions, live rate tickers |
| Skip Links | 2.4.1 | Bypass repeated content | "Skip to main content" on every page |
| Page Titled | 2.4.2 | Descriptive page titles | "Transfer Funds — MyBank" not just "MyBank" |
| Focus Order | 2.4.3 | Logical tab order | Form fields, action buttons, navigation |
| Link Purpose | 2.4.4 | Link text describes destination | "View January statement" not "Click here" |
| Multiple Ways | 2.4.5 | More than one way to find pages | Nav + search + sitemap |
| Headings and Labels | 2.4.6 | Descriptive headings and labels | "Recent Transactions" not "Section 3" |
| Focus Visible | 2.4.7 | Visible focus indicator | Minimum 2px outline, sufficient contrast |

### Understandable

| Criterion | ID | Requirement | Context |
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

| Criterion | ID | Requirement | Context |
|---|---|---|---|
| Parsing | 4.1.1 | Valid markup | No duplicate IDs, proper nesting |
| Name, Role, Value | 4.1.2 | All components expose name, role, value | Custom widgets must declare semantics |
| Status Messages | 4.1.3 | Status messages announced without focus change | Transaction confirmations, error alerts |

---

## ARIA Patterns

### Common UI Patterns

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

### Additional Considerations

- **Financial status colors**: Always pair with icon and text label (green checkmark + "Approved", red X + "Declined").
- **Charts and graphs**: Use patterns/textures in addition to color differentiation. Provide data table alternative.
- **Branded elements**: Brand colors must still meet contrast ratios. Request accessible palette from design team if needed.
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

### Common A11y Defects

| Defect | Impact | Fix |
|---|---|---|
| Balance not in live region | Screen reader users miss updates | Add live region with polite priority |
| Transaction table missing headers | Data is meaningless without context | Add proper header cells with scope |
| OTP modal doesn't trap focus | User tabs behind modal | Implement focus trap |
| Secure data revealed without warning | User unaware sensitive info will be shown | Inform user before hide/show exposes sensitive data |
| PDF statements inaccessible | Cannot read with assistive tech | Generate tagged PDFs or provide HTML alternative |
