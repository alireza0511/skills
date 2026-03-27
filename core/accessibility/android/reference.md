# Accessibility — Android / Kotlin Reference

Android accessibility patterns for the bank's native Android applications. See `core/accessibility/SKILL.md` for core rules.

## Core Principle — Use Material Components and Compose Semantics

Material Design 3 components and Jetpack Compose semantics provide built-in accessibility. Configure them before building custom solutions.

```kotlin
// PREFERRED — Material3 button is fully accessible
Button(onClick = { submitPayment() }) {
    Text("Submit Payment")
}
// Already: focusable, TalkBack reads "Submit Payment, Button", activatable via double-tap

// ONLY IF CUSTOM — add semantics manually
Canvas(modifier = Modifier.semantics {
    contentDescription = "Account balance: $5,100"
}) { /* custom drawing */ }
```

## Hard Rules — Android-Specific

### All images must have contentDescription or be marked decorative

```kotlin
// WRONG — TalkBack reads nothing or reads "Image"
Image(painter = painterResource(R.drawable.chart), contentDescription = null)

// CORRECT — meaningful description
Image(
    painter = painterResource(R.drawable.chart),
    contentDescription = "Account balance trend: $4,200 Jan to $5,100 Mar"
)

// CORRECT — decorative
Image(
    painter = painterResource(R.drawable.wave),
    contentDescription = null,
    modifier = Modifier.semantics { invisibleToUser() }
)
```

### Never use clickable modifier without semantics

```kotlin
// WRONG — clickable but TalkBack doesn't know it's a button
Box(modifier = Modifier.clickable { onTransfer() }) {
    Text("Transfer")
}

// CORRECT — role declared
Box(
    modifier = Modifier
        .clickable(onClick = onTransfer, role = Role.Button)
        .semantics { contentDescription = "Transfer funds" }
) {
    Text("Transfer")
}

// PREFERRED — use Material component
Button(onClick = onTransfer) { Text("Transfer") }
```

### Custom views must declare semantics

```kotlin
// WRONG — custom composable with no semantics
@Composable
fun BalanceCard(balance: String) {
    Column { Text(balance) }
}

// CORRECT — merged semantics for TalkBack
@Composable
fun BalanceCard(balance: String) {
    Column(modifier = Modifier.semantics(mergeDescendants = true) {
        contentDescription = "Current balance: $balance"
    }) { Text(balance) }
}
```

## TalkBack Patterns

### Navigation Gestures

| Gesture | Action |
|---------|--------|
| Swipe right | Move to next element |
| Swipe left | Move to previous element |
| Double-tap | Activate element |
| Two-finger swipe | Scroll |
| Two-finger swipe down-then-left | Back / Escape |
| Three-finger swipe up | Read all from top |

### Compose Semantics Properties

| Property | Purpose |
|----------|---------|
| `contentDescription` | Name read by TalkBack |
| `role` | `Role.Button`, `Role.Checkbox`, `Role.Tab`, etc. |
| `stateDescription` | Current state ("Selected", "Expanded") |
| `heading()` | Mark as heading for navigation |
| `liveRegion` | `LiveRegionMode.Polite` or `.Assertive` |
| `invisibleToUser()` | Hide from TalkBack (decorative only) |
| `mergeDescendants = true` | Group children into one TalkBack element |
| `traversalIndex` | Override reading order (use sparingly) |
| `customActions` | Additional actions via TalkBack menu |
| `disabled()` | Mark as disabled — TalkBack announces "Disabled" |

### Element Grouping

```kotlin
// Group related info into one TalkBack element
Row(modifier = Modifier.semantics(mergeDescendants = true) {}) {
    Icon(Icons.Default.AccountBalance, contentDescription = null)
    Column {
        Text("Savings Account")
        Text("$5,100.00")
    }
}
// TalkBack reads: "Savings Account, $5,100.00"
```

### Live Regions — Announcements

```kotlin
// Polite — announced when TalkBack is idle
Text(
    text = "Balance: $balance",
    modifier = Modifier.semantics {
        liveRegion = LiveRegionMode.Polite
    }
)

// Assertive — interrupts current announcement
if (showError) {
    Text(
        text = errorMessage,
        modifier = Modifier.semantics {
            liveRegion = LiveRegionMode.Assertive
        }
    )
}

// Programmatic announcement (View system)
view.announceForAccessibility("Transfer of $500 completed successfully")
```

## Font Scaling

```kotlin
// CORRECT — scales with system font size
Text("Account Balance", style = MaterialTheme.typography.headlineSmall)

// WRONG — fixed size, ignores font settings
Text("Account Balance", fontSize = 18.sp) // sp scales BUT...
// Better to use MaterialTheme typography tokens

// CORRECT — respect max scaling for layout-critical text
Text(
    "Balance",
    style = MaterialTheme.typography.bodyLarge,
    maxLines = 2,
    overflow = TextOverflow.Ellipsis // graceful degradation
)
```

### Testing Font Sizes

| Setting | Scale | Test Priority |
|---------|-------|---------------|
| Default | 1.0x | Baseline |
| Large | 1.15x | Required |
| Largest | 1.3x | Required |
| Font size accessibility (200%) | 2.0x | Required |

Verify at 200%:
- No text truncation without ellipsis
- Scrollable if overflow
- Touch targets still accessible

## Reduce Motion

```kotlin
// Check system setting
val reduceMotion = LocalContext.current.let {
    val resolver = it.contentResolver
    Settings.Global.getFloat(resolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f) == 0f
}

// Compose — respect reduce motion
val animationDuration = if (reduceMotion) 0 else 300

AnimatedVisibility(
    visible = expanded,
    enter = if (reduceMotion) EnterTransition.None else fadeIn(tween(300)),
    exit = if (reduceMotion) ExitTransition.None else fadeOut(tween(300))
)
```

## Touch Targets

Minimum: **48x48 dp** (Material Design guidelines).

```kotlin
// Ensure minimum touch target
IconButton(onClick = onDelete) {
    Icon(Icons.Default.Delete, contentDescription = "Delete transaction")
}
// IconButton already enforces 48dp minimum

// For custom elements
Box(
    modifier = Modifier
        .sizeIn(minWidth = 48.dp, minHeight = 48.dp)
        .clickable(onClick = action, role = Role.Button)
)
```

## Forms — Accessible Pattern

```kotlin
@Composable
fun TransferForm() {
    Column {
        // Labeled input
        OutlinedTextField(
            value = amount,
            onValueChange = { amount = it },
            label = { Text("Amount") },
            isError = amountError != null,
            supportingText = amountError?.let { { Text(it) } },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
            modifier = Modifier.semantics {
                if (amountError != null) error(amountError!!)
            }
        )

        // Error summary — announced immediately
        if (errors.isNotEmpty()) {
            Text(
                text = "${errors.size} errors found",
                modifier = Modifier.semantics {
                    liveRegion = LiveRegionMode.Assertive
                    heading()
                }
            )
            errors.forEach { error ->
                Text("• ${error.message}")
            }
        }

        Button(
            onClick = { review() },
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Review Transfer")
        }
    }
}
```

## View System Accessibility (Legacy XML)

```xml
<!-- Accessible button -->
<Button
    android:id="@+id/btnSubmit"
    android:text="Submit Payment"
    android:contentDescription="Submit payment of $500"
    android:minWidth="48dp"
    android:minHeight="48dp" />

<!-- Decorative image -->
<ImageView
    android:src="@drawable/decorative"
    android:importantForAccessibility="no" />

<!-- Labeled input -->
<com.google.android.material.textfield.TextInputLayout
    android:hint="Account Number"
    app:errorEnabled="true">
    <com.google.android.material.textfield.TextInputEditText
        android:inputType="number"
        android:autofillHints="username" />
</com.google.android.material.textfield.TextInputLayout>
```

## Testing — Android

### Compose UI Testing

```kotlin
@Test
fun balanceCard_isAccessible() {
    composeTestRule.setContent {
        BalanceCard(balance = "$5,100.00")
    }

    // Verify content description
    composeTestRule
        .onNodeWithContentDescription("Current balance: $5,100.00")
        .assertExists()

    // Verify touch target size
    composeTestRule
        .onNodeWithContentDescription("Delete transaction")
        .assertTouchHeightIsAtLeast(48.dp)
        .assertTouchWidthIsAtLeast(48.dp)
}

@Test
fun transferForm_announcesErrors() {
    composeTestRule.setContent { TransferForm() }

    // Submit empty form
    composeTestRule.onNodeWithText("Review Transfer").performClick()

    // Verify error has live region
    composeTestRule
        .onNodeWithText("1 errors found")
        .assertExists()
        .assert(hasLiveRegion())
}
```

### Accessibility Scanner

Use Google's **Accessibility Scanner** app on physical device:
1. Install from Play Store
2. Enable in Settings > Accessibility
3. Navigate through the app
4. Review suggestions for touch target, contrast, labels

### Manual Testing

| Test | Method |
|------|--------|
| TalkBack navigation | Settings > Accessibility > TalkBack. Swipe through all elements |
| TalkBack activation | Double-tap on buttons, inputs |
| Voice Access | Settings > Accessibility > Voice Access. Say "Tap Submit" |
| Switch Access | Settings > Accessibility > Switch Access. Scan all elements |
| Font size max | Settings > Display > Font size > largest |
| Bold text | Settings > Accessibility > Bold text |
| Remove animations | Settings > Accessibility > Remove animations |
| High contrast | Settings > Accessibility > High contrast text |
| Color correction | Settings > Accessibility > Color correction |

## Audit Report Format

```
## Android Accessibility Audit Report
**Level:** AA | **Framework:** Jetpack Compose / View | **Date:** YYYY-MM-DD

### Summary
- CRITICAL: N issues
- MAJOR: N issues
- MINOR: N issues

### Findings

#### [CRITICAL] Clickable Box without role or contentDescription
**File:** ui/components/AccountCard.kt:L35
**Issue:** Modifier.clickable without Role.Button, no contentDescription
**Affects:** TalkBack users cannot identify or activate
**Fix:** Add role = Role.Button and contentDescription
**WCAG:** 4.1.2 Name, Role, Value (A)

#### [MAJOR] Fixed text size ignores system font scaling
**File:** ui/components/TransactionRow.kt:L48
**Issue:** fontSize = 14.sp without MaterialTheme typography
**Affects:** Users with large font settings
**Fix:** Use MaterialTheme.typography.bodyMedium
**WCAG:** 1.4.4 Resize Text (AA)

### Passed Checks
- [✓] All buttons have contentDescription
- [✓] Touch targets meet 48dp minimum
- [✓] Live regions on balance updates
- [✓] Remove animations respected
```
