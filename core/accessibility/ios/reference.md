# Accessibility — iOS / Swift Reference

iOS accessibility patterns for the bank's native iOS applications. See `core/accessibility/SKILL.md` for core rules.

## Core Principle

UIKit and SwiftUI controls have built-in accessibility traits, labels, and behaviors. Configure them before creating custom accessibility implementations.

```swift
// PREFERRED — SwiftUI built-in accessibility
Button("Submit Payment") { submitPayment() }
// Already: focusable, VoiceOver reads "Submit Payment, Button", activatable via double-tap

// ONLY IF CUSTOM — add traits manually
Image("chart")
    .accessibilityLabel("Account balance trend: $4,200 in Jan to $5,100 in Mar")
```

## Hard Rules

### All images must have accessibilityLabel or be marked decorative

```swift
// WRONG — VoiceOver reads filename
Image("balance_chart")

// CORRECT — meaningful label
Image("balance_chart")
    .accessibilityLabel("Account balance trend: $4,200 Jan to $5,100 Mar")

// CORRECT — decorative
Image("decorative_wave")
    .accessibilityHidden(true)
```

### Never disable VoiceOver on interactive elements

```swift
// WRONG — hides tappable element from VoiceOver
Button("Transfer") { transfer() }
    .accessibilityHidden(true)

// CORRECT — always expose interactive elements
Button("Transfer") { transfer() }
    .accessibilityLabel("Transfer funds")
```

### Custom views must declare accessibility traits

```swift
// WRONG — custom view with no traits
struct BalanceCard: View {
    var body: some View {
        VStack { /* ... */ }
    }
}

// CORRECT — appropriate traits declared
struct BalanceCard: View {
    var body: some View {
        VStack { /* ... */ }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Current balance: $5,100.00")
    }
}
```

## Anti-Patterns

Common iOS accessibility anti-patterns to avoid:

- Using `.accessibilityHidden(true)` on content that conveys meaning
- Setting fixed font sizes with `.font(.system(size:))` instead of text styles
- Forgetting to set `accessibilityLabel` on Image views
- Using custom gesture recognizers without VoiceOver alternatives
- Not grouping related content with `.accessibilityElement(children: .combine)`

```swift
// WRONG — hides meaningful error indicator from VoiceOver
Image(systemName: "exclamationmark.triangle")
    .foregroundColor(.red)
    .accessibilityHidden(true)

// CORRECT — expose with proper label
Image(systemName: "exclamationmark.triangle")
    .foregroundColor(.red)
    .accessibilityLabel("Warning")

// WRONG — fixed size ignores Dynamic Type
Text("Balance")
    .font(.system(size: 16))

// CORRECT — scales with Dynamic Type
Text("Balance")
    .font(.body)

// WRONG — custom gesture with no VoiceOver alternative
view.onLongPressGesture { showDetails() }

// CORRECT — provide custom action for VoiceOver
view.accessibilityAction(named: "Show Details") { showDetails() }
    .onLongPressGesture { showDetails() }

// WRONG — related content not grouped
VStack {
    Text("Savings")    // VoiceOver: "Savings"
    Text("$5,100")     // VoiceOver: "$5,100" (separate focus)
}

// CORRECT — grouped for single focus
VStack {
    Text("Savings")
    Text("$5,100")
}
.accessibilityElement(children: .combine)
// VoiceOver: "Savings, $5,100"
```

## VoiceOver Patterns

### Navigation Gestures

| Gesture | Action |
|---------|--------|
| Swipe right | Move to next element |
| Swipe left | Move to previous element |
| Double-tap | Activate element |
| Three-finger swipe | Scroll |
| Two-finger scrub (Z) | Go back / Escape |
| Two-finger swipe down | Read all from current position |

### SwiftUI Accessibility Modifiers

| Modifier | Purpose |
|----------|---------|
| `.accessibilityLabel(_:)` | Name read by VoiceOver |
| `.accessibilityHint(_:)` | Additional context ("Double tap to transfer") |
| `.accessibilityValue(_:)` | Current value for sliders, progress |
| `.accessibilityAddTraits(_:)` | Add roles: `.isButton`, `.isHeader`, `.isLink` |
| `.accessibilityRemoveTraits(_:)` | Remove default traits |
| `.accessibilityHidden(_:)` | Hide from VoiceOver (decorative only) |
| `.accessibilityElement(children:)` | `.combine`, `.contain`, or `.ignore` |
| `.accessibilitySortPriority(_:)` | Override reading order (higher = read first) |
| `.accessibilityAction(_:)` | Custom actions (swipe up/down menu) |

### Element Grouping

```swift
// Group related info into one VoiceOver element
HStack {
    Image(systemName: "dollarsign.circle")
    VStack(alignment: .leading) {
        Text("Savings Account")
        Text("$5,100.00")
    }
}
.accessibilityElement(children: .combine)
// VoiceOver reads: "Savings Account, $5,100.00"

// OR — custom label for better announcement
.accessibilityElement(children: .ignore)
.accessibilityLabel("Savings Account, balance $5,100.00")
```

### Live Announcements

```swift
// Announce dynamic changes to VoiceOver
func transferCompleted() {
    // Post announcement — VoiceOver reads this immediately
    UIAccessibility.post(
        notification: .announcement,
        argument: "Transfer of $500 completed successfully"
    )
}

// Screen change — VoiceOver resets focus
func navigateToConfirmation() {
    // ... navigate
    UIAccessibility.post(notification: .screenChanged, argument: nil)
}

// Layout change — VoiceOver updates without resetting
func showErrorBanner() {
    errorVisible = true
    UIAccessibility.post(notification: .layoutChanged, argument: errorLabel)
}
```

## Dynamic Type

> **Note:** SKILL.md may reference this section as "Display Accommodations".

```swift
// CORRECT — respects Dynamic Type automatically
Text("Account Balance")
    .font(.headline) // Scales with system settings

// WRONG — fixed font size, ignores Dynamic Type
Text("Account Balance")
    .font(.system(size: 18))

// CORRECT — custom size that scales
@ScaledMetric var iconSize: CGFloat = 24
Image(systemName: "bell")
    .frame(width: iconSize, height: iconSize)
```

### Testing Dynamic Type

| Size Category | Scale | Test Priority |
|---------------|-------|---------------|
| Default | 1.0x | Baseline |
| xxxLarge | ~1.4x | Required |
| AX5 (Accessibility Extra Extra Extra Large) | ~3.1x | Required |

Verify at AX5:
- No text truncation or clipping
- Scroll if needed but no content loss
- Touch targets still reachable

## Reduce Motion

```swift
// Check user preference
@Environment(\.accessibilityReduceMotion) var reduceMotion

var body: some View {
    content
        .animation(reduceMotion ? nil : .easeInOut, value: isExpanded)
}

// UIKit
if UIAccessibility.isReduceMotionEnabled {
    // Skip animation, apply final state immediately
}
```

## Touch Targets

Minimum: **44x44 points** (Apple HIG).

```swift
// Ensure minimum tap area even for small visual elements
Button(action: action) {
    Image(systemName: "xmark")
        .frame(width: 16, height: 16) // Visual size
}
.frame(minWidth: 44, minHeight: 44) // Touch target
```

## Semantic Label Patterns

iOS-specific labeling conventions for common UI elements:

```swift
// Buttons — describe the action
Button("Transfer") { ... }
    .accessibilityLabel("Transfer $500 to Savings Account")

// Inputs — describe what to enter
TextField("Amount", text: $amount)
    .accessibilityLabel("Transfer amount in US dollars")

// Status — include full context
Image(systemName: "checkmark.circle.fill")
    .accessibilityLabel("Transaction status: Completed")

// Amounts — include currency
Text("$5,100.00")
    .accessibilityLabel("Balance: five thousand one hundred dollars")
```

## Focus & Navigation Order

```swift
// PREFERRED — natural view order matches reading order
VStack {
    Text("Transfer Funds").accessibilityAddTraits(.isHeader)
    TextField("From Account", text: $from)
    TextField("To Account", text: $to)
    TextField("Amount", text: $amount)
    Button("Review Transfer") { review() }
}

// Override reading order when layout doesn't match logical order
HStack {
    sidebar.accessibilitySortPriority(0)  // Read second
    mainContent.accessibilitySortPriority(1)  // Read first (higher = first)
}
```

## Forms

```swift
Form {
    Section("Transfer Details") {
        TextField("From Account", text: $fromAccount)
            .accessibilityLabel("From Account")
            .textContentType(.name)

        TextField("Amount", text: $amount)
            .accessibilityLabel("Transfer amount in dollars")
            .keyboardType(.decimalPad)
            .accessibilityValue(amount.isEmpty ? "Empty" : "$\(amount)")

        if let error = amountError {
            Text(error)
                .foregroundColor(.red)
                .accessibilityLabel("Error: \(error)")
                .accessibilityAddTraits(.isStaticText)
        }
    }

    Button("Review Transfer") { review() }
        .accessibilityHint("Double tap to review transfer details before submitting")
}
```

## UIKit Accessibility (Legacy)

```swift
// Setting accessibility on UIKit views
button.accessibilityLabel = "Submit payment"
button.accessibilityHint = "Double tap to submit your payment"
button.accessibilityTraits = .button

// Custom view
class BalanceView: UIView {
    override var isAccessibilityElement: Bool {
        get { true }
        set { }
    }
    override var accessibilityLabel: String? {
        get { "Current balance: \(formattedBalance)" }
        set { }
    }
    override var accessibilityTraits: UIAccessibilityTraits {
        get { .staticText }
        set { }
    }
}
```

## Testing

### XCTest Accessibility Audit (Xcode 15+)

```swift
func testAccessibility() throws {
    let app = XCUIApplication()
    app.launch()

    // Automated WCAG audit
    try app.performAccessibilityAudit()

    // Audit specific categories
    try app.performAccessibilityAudit(for: [
        .dynamicType,
        .contrast,
        .sufficientElementDescription,
        .hitRegion
    ])
}
```

### Manual Testing

| Test | Method |
|------|--------|
| VoiceOver navigation | Settings > Accessibility > VoiceOver. Swipe through all elements |
| VoiceOver activation | Double-tap on buttons, links, inputs |
| Voice Control | Settings > Accessibility > Voice Control. Say "Tap Submit" |
| Switch Control | Settings > Accessibility > Switch Control. Scan all elements |
| Dynamic Type max | Settings > Display > Text Size > max slider |
| Bold Text | Settings > Display > Bold Text |
| Reduce Motion | Settings > Accessibility > Motion > Reduce Motion |
| Increase Contrast | Settings > Accessibility > Display > Increase Contrast |

## Audit Report Format

```
## iOS Accessibility Audit Report
**Level:** AA | **Framework:** SwiftUI / UIKit | **Date:** YYYY-MM-DD

### Summary
- CRITICAL: N issues
- MAJOR: N issues
- MINOR: N issues

### Findings

#### [CRITICAL] Custom view not accessible to VoiceOver
**File:** Sources/Views/BalanceCard.swift:L25
**Issue:** Custom view has no accessibilityLabel or traits
**Affects:** VoiceOver users cannot read balance
**Fix:** Add .accessibilityElement(children: .combine) or custom label
**WCAG:** 4.1.2 Name, Role, Value (A)

#### [MAJOR] Fixed font size ignores Dynamic Type
**File:** Sources/Views/TransactionRow.swift:L42
**Issue:** .font(.system(size: 14)) doesn't scale
**Affects:** Users with large text settings
**Fix:** Use .font(.body) or @ScaledMetric
**WCAG:** 1.4.4 Resize Text (AA)

### Passed Checks
- [✓] All buttons have accessibilityLabel
- [✓] Touch targets meet 44pt minimum
- [✓] Reduce Motion respected
```
