# Accessibility — Flutter Reference

Flutter-specific accessibility patterns for the bank's mobile applications. See `core/accessibility/SKILL.md` for core rules.

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

Accessible form patterns for banking workflows. Use Flutter's built-in form widgets — they provide correct semantic roles and validation announcements automatically.

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

### Automated Widget Tests

```dart
testWidgets('widget meets accessibility guidelines', (tester) async {
  final handle = tester.ensureSemantics();
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: MyWidget())));

  // Check semantic labels
  expect(find.bySemanticsLabel('Expected label'), findsOneWidget);

  // Check touch target size
  final size = tester.getSize(find.byType(MyWidget));
  expect(size.width, greaterThanOrEqualTo(48));
  expect(size.height, greaterThanOrEqualTo(48));

  // Built-in guidelines
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));

  handle.dispose();
});
```

### Built-in Guidelines

| Guideline | Checks |
|-----------|--------|
| `androidTapTargetGuideline` | Touch targets >= 48x48 dp |
| `iOSTapTargetGuideline` | Touch targets >= 44x44 pt |
| `labeledTapTargetGuideline` | All tappable elements have semantic labels |
| `textContrastGuideline` | Text contrast meets WCAG 2 AA (4.5:1) |

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
