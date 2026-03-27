# Accessibility Flutter — Reference

## §Semantic-Labels

### Semantics Widget Patterns

```dart
// Simple semantic label on an image
Image.asset(
  'assets/bank_logo.png',
  semanticLabel: 'National Bank logo',
);

// Decorative image — exclude from screen readers
Semantics(
  excludeSemantics: true,
  child: Image.asset('assets/decorative_wave.png'),
);

// Custom widget with full semantics
Semantics(
  label: 'Transfer to Jane Doe, 1,500 dollars, pending',
  button: true,
  onTap: () => _navigateToDetail(transfer),
  child: TransferListTile(transfer: transfer),
);

// Value display with context
Semantics(
  label: 'Available balance',
  value: '12,500 dollars and 50 cents',
  child: Column(
    children: [
      Text('Available Balance', style: theme.labelSmall),
      Text('\$12,500.50', style: theme.headlineLarge),
    ],
  ),
);
```

### Label Conventions for Banking

| Widget | Semantic Label Pattern |
|---|---|
| Balance display | "Available balance: [amount] [currency]" |
| Transaction row | "[type] [amount] to/from [party], [status]" |
| Account card | "[account type] ending in [last4], balance [amount]" |
| Action button | Verb + object: "Transfer funds", "View statement" |
| Status icon | "[status] icon" — never just the icon name |
| Input field | Field purpose: "Recipient IBAN", "Transfer amount" |
| Error message | "Error: [specific guidance]" |

---

## §Touch-Targets

### Minimum Size Implementation

```dart
// Ensure minimum 48x48 touch target regardless of visual size
class AccessibleIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final String tooltip;

  const AccessibleIconButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
          child: Center(child: icon),
        ),
      ),
    );
  }
}
```

### Platform Minimums

| Platform | Minimum Size | Spacing Between Targets |
|---|---|---|
| Android (Material) | 48x48 dp | 8dp minimum |
| iOS (Cupertino) | 44x44 pt | 8pt minimum |
| Bank standard | 48x48 (both platforms) | 12dp minimum |

---

## §Focus-Management

### Focus Traversal Order

```dart
class TransferForm extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        children: [
          FocusTraversalOrder(
            order: const NumericFocusOrder(1),
            child: TextField(decoration: InputDecoration(labelText: 'From Account')),
          ),
          FocusTraversalOrder(
            order: const NumericFocusOrder(2),
            child: TextField(decoration: InputDecoration(labelText: 'Recipient IBAN')),
          ),
          FocusTraversalOrder(
            order: const NumericFocusOrder(3),
            child: TextField(decoration: InputDecoration(labelText: 'Amount')),
          ),
          FocusTraversalOrder(
            order: const NumericFocusOrder(4),
            child: ElevatedButton(
              onPressed: _submit,
              child: const Text('Send Transfer'),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Programmatic Focus Management

```dart
// Move focus to error field after validation failure
class _TransferFormState extends State<TransferForm> {
  final _amountFocus = FocusNode();
  final _recipientFocus = FocusNode();

  void _onSubmit() {
    final errors = _validate();
    if (errors.containsKey('amount')) {
      _amountFocus.requestFocus();
      // Announce error to screen reader
      SemanticsService.announce(
        'Amount error: ${errors['amount']}',
        TextDirection.ltr,
      );
    }
  }

  @override
  void dispose() {
    _amountFocus.dispose();
    _recipientFocus.dispose();
    super.dispose();
  }
}
```

---

## §Merge-Exclude

### MergeSemantics — Grouping Related Elements

```dart
// WRONG — screen reader announces each element separately:
// "Account icon", "Checking Account", "****4521", "$5,200.00"
Row(children: [
  Icon(Icons.account_balance),
  Text('Checking Account'),
  Text('****4521'),
  Text('\$5,200.00'),
]);

// CORRECT — single announcement:
// "Checking Account ending in 4521, balance $5,200.00"
MergeSemantics(
  child: Semantics(
    label: 'Checking Account ending in 4521, balance \$5,200.00',
    child: Row(children: [
      Icon(Icons.account_balance),
      Text('Checking Account'),
      Text('****4521'),
      Text('\$5,200.00'),
    ]),
  ),
);
```

### ExcludeSemantics — Rules

| Use Case | ExcludeSemantics? | Reason |
|---|---|---|
| Decorative background image | Yes | No information content |
| Decorative divider/border | Yes | Visual only |
| Redundant icon next to label | Yes | Label is sufficient |
| Financial data (balance, amount) | NEVER | Must be accessible |
| Status indicator | NEVER | Use semantic label instead |
| Loading animation | Yes (add separate label) | Announce "Loading" via Semantics |

---

## §Live-Regions

### Announcing Dynamic Content

```dart
// Announce balance update to screen readers
class BalanceDisplay extends StatefulWidget {
  @override
  _BalanceDisplayState createState() => _BalanceDisplayState();
}

class _BalanceDisplayState extends State<BalanceDisplay> {
  void _onBalanceUpdated(Balance newBalance) {
    setState(() => _balance = newBalance);
    // Announce the change
    SemanticsService.announce(
      'Balance updated: ${newBalance.formatted}',
      Directionality.of(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Current balance: ${_balance.formatted}',
      child: Text(_balance.formatted),
    );
  }
}

// Announce transaction result
void _onTransferComplete(TransferResult result) {
  final message = result.isSuccess
      ? 'Transfer of ${result.amount} completed successfully'
      : 'Transfer failed: ${result.errorMessage}';
  SemanticsService.announce(message, TextDirection.ltr);
}
```

---

## §Reduced-Motion

### Respecting disableAnimations

```dart
class AnimatedBalanceCounter extends StatelessWidget {
  final double amount;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    if (reduceMotion) {
      return Text(formatCurrency(amount));
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: amount),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, _) => Text(formatCurrency(value)),
    );
  }
}

// Page transitions — reduce or eliminate for motion-sensitive users
class AccessiblePageRoute<T> extends MaterialPageRoute<T> {
  @override
  Duration get transitionDuration {
    // Check during build — cannot access context here
    // Use a global setting or check in transitionsBuilder
    return super.transitionDuration;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.of(context).disableAnimations) {
      return child; // No animation
    }
    return super.buildTransitions(context, animation, secondaryAnimation, child);
  }
}
```

---

## §Contrast

### Theme Contrast Validation

| Element | Minimum Ratio | Example |
|---|---|---|
| Body text | 4.5:1 | `#333333` on `#FFFFFF` = 12.6:1 |
| Large text (>= 18sp bold) | 3:1 | `#666666` on `#FFFFFF` = 5.7:1 |
| UI components (borders, icons) | 3:1 | Button borders, input outlines |
| Disabled elements | Exempt | But should still be distinguishable |
| Placeholder text | 4.5:1 | Must meet ratio — not just decorative |

### Bank Theme Contrast Compliance

```dart
class BankColors {
  // Verified contrast ratios against white (#FFFFFF)
  static const primary = Color(0xFF1A5276);     // 8.9:1 — passes AA
  static const onPrimary = Color(0xFFFFFFFF);    // on primary: 8.9:1
  static const error = Color(0xFFB71C1C);        // 7.8:1 — passes AA
  static const textPrimary = Color(0xFF212121);  // 16.1:1 — passes AAA
  static const textSecondary = Color(0xFF424242);// 11.7:1 — passes AA
  // NEVER use these for text:
  // Color(0xFFBDBDBD) on white = 1.9:1 — FAILS
}
```

---

## §Screen-Reader-Testing

### Testing Procedure

| Step | TalkBack (Android) | VoiceOver (iOS) |
|---|---|---|
| Enable | Settings > Accessibility > TalkBack | Settings > Accessibility > VoiceOver |
| Navigate | Swipe right to move forward | Swipe right to move forward |
| Activate | Double-tap | Double-tap |
| Read all | Three-finger swipe up | Two-finger swipe down |
| Headings | Swipe up/down to change granularity | Rotor > Headings |

### Screen Reader Test Checklist per Screen

1. Enable screen reader and navigate to the screen
2. Swipe through every element — verify meaningful label on each
3. Verify reading order matches visual layout
4. Activate each interactive element — verify correct action
5. Verify dynamic updates are announced (balance changes, errors)
6. Verify no "unlabeled button" or "button" without context
7. Verify financial amounts include currency

---

## §Guideline-Tests

### Automated Accessibility Tests

```dart
void main() {
  group('Accessibility guidelines', () {
    final screens = <String, Widget>{
      'LoginScreen': const LoginScreen(),
      'DashboardScreen': const DashboardScreen(),
      'TransferScreen': const TransferScreen(),
      'AccountDetailScreen': AccountDetailScreen(accountId: 'test'),
      'StatementScreen': const StatementScreen(),
    };

    for (final entry in screens.entries) {
      testWidgets('${entry.key} meets Android tap target guideline',
          (tester) async {
        await tester.pumpWidget(MaterialApp(home: entry.value));
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      });

      testWidgets('${entry.key} meets iOS tap target guideline',
          (tester) async {
        await tester.pumpWidget(MaterialApp(home: entry.value));
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      });

      testWidgets('${entry.key} meets text contrast guideline',
          (tester) async {
        await tester.pumpWidget(MaterialApp(home: entry.value));
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(textContrastGuideline));
      });

      testWidgets('${entry.key} meets labelled tap target guideline',
          (tester) async {
        await tester.pumpWidget(MaterialApp(home: entry.value));
        await tester.pumpAndSettle();
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      });
    }
  });
}
```

### Headings

```dart
// Mark section headers for screen reader navigation
Semantics(
  header: true,
  child: Text('Recent Transactions', style: theme.headlineSmall),
);

// Heading hierarchy in a screen
// H1: Screen title (AppBar)
// H2: Section headers (e.g., "Recent Transactions", "Quick Actions")
// Do not skip levels (no H1 → H3)
```
