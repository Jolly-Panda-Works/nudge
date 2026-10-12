import 'package:flutter_test/flutter_test.dart';
import 'package:nudge/app_info.dart';
import 'package:nudge/main.dart';

void main() {
  testWidgets('app shell shows name and version', (tester) async {
    await tester.pumpWidget(const NudgeApp());
    expect(find.text('$appName v$appVersion'), findsOneWidget);
  });
}
