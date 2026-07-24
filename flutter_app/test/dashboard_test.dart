import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vanix/screens/dashboard_screen.dart';
import 'package:vanix/state/app_state.dart';

bool _hasText(WidgetTester tester, String needle) {
  for (final e in find.byType(RichText).evaluate()) {
    if ((e.widget as RichText).text.toPlainText().contains(needle)) return true;
  }
  for (final e in find.byType(Text).evaluate()) {
    if (((e.widget as Text).data ?? '').contains(needle)) return true;
  }
  return false;
}

void main() {
  testWidgets('Owner dashboard renders (light) with no exceptions/overflow', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: DashboardScreen(appState: AppState()..setLanguage('en'))));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(_hasText(tester, 'MyBovine'), isTrue);
    // Farm Status stat cards
    expect(find.text('Total Cattle'), findsOneWidget);
    expect(find.text('Cows Pregnant'), findsOneWidget);
    expect(find.text('Cows in Heat'), findsOneWidget);
    // AI Chat Bot banner
    expect(_hasText(tester, 'AI Chat Bot'), isTrue);
    // Owner-only Needs Attention rows
    expect(find.text('NEEDS ATTENTION'), findsOneWidget);
    expect(_hasText(tester, 'Pending Approvals'), isTrue);
    expect(_hasText(tester, 'Milking Sessions Missed'), isTrue);
    expect(_hasText(tester, 'Critical Alerts'), isTrue);
    expect(find.text('View All ›'), findsNWidgets(3));
    // Today/This-week tabs are `display:none` in the HTML — must not render
    expect(find.text('Today'), findsNothing);
    expect(find.text('This Week'), findsNothing);
    // Cows in Fever / Cows in Heat rows
    expect(find.text('COWS IN FEVER'), findsOneWidget);
    expect(find.text('COWS IN HEAT'), findsOneWidget);
    expect(_hasText(tester, 'Gauri'), isTrue);
    expect(_hasText(tester, 'Lakshmi'), isTrue);
    // scroll to Updates section
    await tester.dragUntilVisible(
      find.textContaining('Bhoori'),
      find.byType(Scrollable).first,
      const Offset(0, -300),
    );
    await tester.pump();
    expect(_hasText(tester, 'Bhoori'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Owner dashboard renders (dark) with no exceptions', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: DashboardScreen(appState: AppState()..setLanguage('en')..toggleDark())));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(_hasText(tester, 'MyBovine'), isTrue);
  });

  testWidgets('Manager (multi-farm) dashboard shows Milking/Critical/Contact Vet block', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final appState = AppState()..setLanguage('en');
    appState.cyclePersona(); // owner -> manager (multi-farm)
    await tester.pumpWidget(MaterialApp(home: DashboardScreen(appState: appState)));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(_hasText(tester, 'Milking (Morning)'), isTrue);
    expect(_hasText(tester, 'Critical Alerts'), isTrue);
    expect(_hasText(tester, 'Contact Vet'), isTrue);
    // Owner-only Needs Attention rows must not appear for Manager
    expect(_hasText(tester, 'Pending Approvals'), isFalse);
    // Cows in Fever / Cows in Heat still shown to Manager
    expect(find.text('COWS IN FEVER'), findsOneWidget);
    expect(find.text('COWS IN HEAT'), findsOneWidget);
  });

  testWidgets('Manager (single-farm) dashboard shows plain farm-name label', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final appState = AppState()..setLanguage('en');
    appState.cyclePersona(); // owner -> manager (multi-farm)
    appState.cyclePersona(); // manager (multi-farm) -> manager (single-farm)
    await tester.pumpWidget(MaterialApp(home: DashboardScreen(appState: appState)));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(appState.isManager, isTrue);
    expect(appState.isSingleFarm, isTrue);
    // All-Farms dropdown chevron must not render for a single-farm Manager
    expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
  });
}
