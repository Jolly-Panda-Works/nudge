import 'package:flutter_test/flutter_test.dart';
import 'package:unified_inbox/main.dart';

void main() {
  testWidgets('app shell renders', (tester) async {
    await tester.pumpWidget(const UnifiedInboxApp());
    expect(find.text('Unified Inbox - scaffold'), findsOneWidget);
  });
}
