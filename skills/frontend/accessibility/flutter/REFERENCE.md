# Accessibility — Flutter Reference

Flutter-specific accessibility patterns for mobile applications. See `skills/frontend/accessibility/flutter/SKILL.md` for core rules.

## Core Principle

**Avoid wrapping widgets with custom `Semantics` unless absolutely necessary.** Flutter's built-in widgets already provide correct semantic roles, states, and announcements.

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

| Widget | Why wrapping is wrong | Built-in behavior |
|--------|----------------------|-------------------|
| `ElevatedButton` | Already announces as "Button" | Provides role, label from child `Text` |
| `TextField` + `InputDecoration.labelText` | Already announces as "Text field" | Reads label, hint, error automatically |
| `Radio` / `Checkbox` / `Switch` | Already manages checked/unchecked state | Announces state changes |
| `Slider` | Already announces value and range | Reads current value, min, max |
| `DropdownButton` | Already announces selected value | Reads selection state |

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

### Voice Control

| Feature | Android (Voice Access) | iOS (Voice Control) |
|---------|----------------------|---------------------|
| Activate by label | "Tap [label]" | "Tap [label]" |
| Show numbers | "Show numbers" | "Show numbers" |
| Type text | "Type [text]" | "Type [text]" |

### Switch Access / Switch Control

- All interactive widgets must appear in scan order
- Related elements grouped via `MergeSemantics`
- No time-limited interactions

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

Minimum sizes: 48x48 dp (Android), 44x44 pt (iOS). Use 48 to satisfy both.

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
```

## Forms

Use Flutter's built-in form widgets — they provide correct semantic roles and validation announcements automatically.

```dart
// Accessible form
Form(
  child: Column(
    children: [
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

      ElevatedButton(onPressed: _review, child: Text('Review Transfer')),
    ],
  ),
)
```

| Pattern | Requirement |
|---------|-------------|
| Label association | Use `InputDecoration.labelText` — never placeholder-only |
| Required fields | Mark programmatically + visual indicator |
| Error display | `errorText` for inline errors + `Semantics(liveRegion: true)` for summary |
| Field grouping | Group related fields in `Column` for natural focus order |
| Input type | Provide `keyboardType` for the appropriate keyboard |
| Submit confirmation | Review page before final submission for financial transactions |

Error message format: `"[Field name] — [what went wrong] — [how to fix]"`

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

### Common A11y Defects

| Defect | Fix |
|--------|-----|
| Balance not in live region | Add `Semantics(liveRegion: true)` |
| Table missing headers | Add proper header cells with scope |
| Modal doesn't trap focus | Implement focus trap |
| Secure data revealed without warning | Inform user before exposing sensitive data |
| PDF statements inaccessible | Generate tagged PDFs or provide HTML alternative |

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

### Passed Checks
- [✓] Touch targets meet 48dp minimum
- [✓] Focus indicators visible
- [✓] Reduce Motion respected
```

---

## WCAG Checklist

Key WCAG 2.1 AA success criteria for Flutter apps. For the full spec, see [WCAG 2.1](https://www.w3.org/TR/WCAG21/).

| ID | Criterion | Requirement |
|---|---|---|
| 1.1.1 | Non-text Content | Text alternative for all non-text content |
| 1.3.1 | Info and Relationships | Structure conveyed programmatically |
| 1.3.2 | Meaningful Sequence | Reading order matches visual order |
| 1.3.4 | Orientation | Content not restricted to single orientation |
| 1.4.1 | Use of Color | Color not sole means of conveying info |
| 1.4.3 | Contrast (Minimum) | 4.5:1 normal text, 3:1 large text |
| 1.4.4 | Resize Text | Text resizable to 200% without loss |
| 1.4.11 | Non-text Contrast | 3:1 for UI components and graphics |
| 2.1.1 | Keyboard | All functionality via keyboard |
| 2.1.2 | No Keyboard Trap | Focus can always be moved away |
| 2.4.3 | Focus Order | Logical tab order |
| 2.4.7 | Focus Visible | Visible focus indicator |
| 3.2.1 | On Focus | No context change on focus |
| 3.3.1 | Error Identification | Errors identified and described |
| 3.3.2 | Labels or Instructions | Labels for all inputs |
| 3.3.4 | Error Prevention | Review step for financial/legal submissions |
| 4.1.2 | Name, Role, Value | All components expose name, role, value |
| 4.1.3 | Status Messages | Status messages announced without focus change |
