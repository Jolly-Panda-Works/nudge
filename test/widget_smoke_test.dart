import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/app_info.dart';
import 'package:nudge/main.dart';

void main() {
  testWidgets('shell shows name and version without services', (tester) async {
    await tester.pumpWidget(const NudgeApp());
    expect(find.text('$appName v$appVersion'), findsOneWidget);
  });

  testWidgets('shell shows the startup error type', (tester) async {
    await tester.pumpWidget(const NudgeApp(startupError: 'StateError'));
    expect(find.text('Startup failed: StateError'), findsOneWidget);
  });
}
