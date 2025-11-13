// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// Import your main app and your app state
import 'package:clear_view/main.dart';
import 'package:clear_view/state/app_state.dart';

void main() {
  // This is a new test that works for your *real* app
  testWidgets('Clear View app smoke test', (WidgetTester tester) async {
    // Build our app, wrapped in the Provider it needs to run
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => AppState(),
        child: ClearViewApp(),
      ),
    );

    // Wait for any animations/futures (like the initial weather fetch)
    // to settle. Using pumpAndSettle is important.
    await tester.pumpAndSettle();

    // Verify that the "Home" tab label from the BottomNavigationBar is visible.
    expect(find.text('Home'), findsOneWidget);

    // Verify that the "Forecast" tab label is also visible.
    expect(find.text('Forecast'), findsOneWidget);

    // Verify that the search bar's hint text from the HomePage is on screen.
    // This confirms the HomePage has loaded.
    expect(find.text('Search for a city...'), findsOneWidget);
  });
}