# 🧪 Belong on the Spectrum: Comprehensive Automated & Manual Testing Guide (`automated_testing.md`)

> **Authoritative Testing Standard for Belong on the Spectrum / Refuge**  
> **Applies to**: Web, Mobile (Android/iOS), Desktop, and CI/CD  
> **Testing Pillars**: Solitary & Sociable Widget Tests · BDD Gherkin · Patrol Finders · Maestro Real-Device Automation  

---

## 🎯 1. Testing Philosophy & Architecture

Belong on the Spectrum is built for neurodivergent adults, which makes UX regressions (jarring animations, accidental sound chimes, red urgency badges, broken deep links) critical bugs rather than mere styling defects.

Our testing architecture follows modern pragmatic testing standards (drawing from Martin Fowler and **Tide Financial's** sociable testing principles):

```
                        ▲
                       / \
                      /   \    Maestro Real-Device Flows (.maestro/*.yaml)
                     / E2E \   Real hardware (Google Pixel) & Android Emulator
                    /-------\
                   /  BDD    \  Patrol Native Integration Tests ($.native)
                  /   Native  \ OS notification shade, system permissions
                 /-------------\
                /  Sociable     \  Sociable Widget Tests (patrolWidgetTest / $)
               /   Widget Tests  \ Multi-widget integration, actual screen transitions
              /-------------------\
             /   Solitary Widget   \ Solitary Widget Tests (testWidgets)
            /     Component Tests   \ Isolated widget contracts & mock callbacks
           /-------------------------\
          /        Unit Tests         \ Pure domain logic, timestamps, models
         /_____________________________\ (Only where business math/logic warrants)
```

### The Three Cardinal Testing Rules:
1. **Unit tests strictly where logic exists**: Do not unit-test pass-through DTOs or boilerplate getters. Focus unit tests on complex domain logic (e.g., author initials parsing with messy qualifiers, relative timestamp calculations, regex parsers).
2. **Solitary vs. Sociable Widget Testing**:
   - **Solitary (Isolated)**: Tests a single widget component in a controlled harness with mock providers. Ideal for testing edge-case error states, disabled action buttons, and individual callback dispatches.
   - **Sociable (Integrated)**: Tests screens and widgets working *together* without mocking internal widget seams (e.g. tapping a notification card inside `RefugeHomeScreen` and verifying that the bottom navigation bar switches to `Msgs` and opens the conversation thread).
3. **No Flaky Delays (`sleep()` / hardcoded `Future.delayed`)**:
   - Use `$.pumpAndSettle()` or Patrol's `$(selector).waitUntilExists()` and `$(selector).waitUntilVisible()` to wait for asynchronous state transitions safely.

---

## 🏗️ 2. Directory Structure

```
refuge/
├── .maestro/                                   # Declarative E2E flows (Mobile & Web)
│   ├── full_notifications_journey.yaml
│   ├── notification_deep_link_flow.yaml
│   └── direct_messages_flow.yaml
├── test/
│   ├── features/                               # BDD & Feature tests
│   │   ├── full_notifications_feature.txt      # Gherkin human-readable specs
│   │   ├── notifications/
│   │   │   ├── belong_notifications_test.dart  # Solitary domain & component tests
│   │   │   └── notification_deep_linking_test.dart # Sociable & solitary deep link tests
│   │   ├── messages/
│   │   └── reflections/
│   ├── unit/                                   # Domain & utility unit tests
│   └── widget/                                 # Component-level widget tests
├── integration_test/                           # Native device integration tests
│   └── notifications_native_patrol_test.dart   # Patrol native shade driving
└── docs/
    ├── automated_testing.md                    # This document
    ├── llm_automated_testing.md                # Token-efficient guide for LLMs
    └── manual_testing/                         # Manual sensory audit checklists
        ├── sensory_audit_checklist.md
        └── notification_matrix.md
```

---

## 🧩 3. Writing Sociable & Solitary Widget Tests with `patrol_finders`

### A. Solitary Component Test Pattern
Use when validating individual widget contracts in isolation:

```dart
testWidgets('Tapping notification card dispatches onNavigate callback', (tester) async {
  NotificationNavigationTarget? captured;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CalmNotificationsView(
          onNavigate: (target) => captured = target,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('notification_list_tile_notif-dm-1')));
  await tester.pumpAndSettle();

  expect(captured?.tab, BelongBottomTab.msgs);
  expect(captured?.conversationId, 'thread-marty');
});
```

### B. Sociable Integration Test Pattern (The Tide Financial Model)
Use when validating end-to-end screen navigation and real state handoffs:

```dart
patrolWidgetTest(
  'Sociable: Tapping notification in history navigates home screen to DM conversation',
  ($) async {
    // 1. Configure standard phone dimensions
    $.tester.view.devicePixelRatio = 1.0;
    $.tester.view.physicalSize = const Size(1080, 2400);
    addTearDown(() {
      $.tester.view.resetPhysicalSize();
      $.tester.view.resetDevicePixelRatio();
    });

    // 2. Pump full home screen with in-memory repository
    await $.pumpWidget(
      ProviderScope(
        overrides: [
          postRepositoryProvider.overrideWithValue(LocalPostRepository(isDevMode: true)),
        ],
        child: const MaterialApp(home: RefugeHomeScreen()),
      ),
    );
    await $.pumpAndSettle();

    // 3. Switch to notifications
    await $(const Key('bottom_nav_icon_notifications')).tap();
    await $.pumpAndSettle();

    // 4. Tap DM card
    await $(const Key('notification_list_tile_notif-dm-1')).tap();
    await $.pumpAndSettle();

    // 5. Assert sociable result across widgets:
    //    Bottom bar moved to Msgs, conversation thread opened, reply field present
    expect($('Welcome to Belong!'), findsWidgets);
    expect($('Type a calm reply...'), findsOneWidget);
  },
);
```

---

## 📱 4. Maestro Device Automation

Maestro drives our physical Google Pixels (`56091JEBF14039`, `58221JEBF20835`) and `emulator-5554` without needing brittle selector code:

### Declarative Notification Flow Example (`.maestro/notification_deep_link_flow.yaml`):

```yaml
appId: com.belongonthespectrum.sanctuary
name: "Notification Deep Link Flow"
---
- launchApp:
    clearState: false

- tapOn:
    id: "bottom_nav_icon_notifications"
- assertVisible: "Notifications"

- tapOn:
    id: "notification_list_tile_notif-dm-1"

- assertVisible: "Marty & Community Team"
- assertVisible: "Welcome to Belong!"

- tapOn:
    id: "bottom_nav_icon_notifications"
- tapOn:
    id: "notification_list_tile_notif-mention-1"

- assertVisible:
    id: "belong_bottom_nav_bar"
```

---

## 📋 5. Manual Testing Home & Sensory Audit Checklist

Located in `docs/manual_testing/`:
- **Sensory Audit**: Verify that high contrast mode meets WCAG AAA, notification badges use soothing forest green (`#2E6B56`) or contrast yellow (never red), and audio playback loops without sudden pop or volume jumps.
- **Physical Device Matrix**: Validate performance across physical Pixels and low-end Android emulator targets.
