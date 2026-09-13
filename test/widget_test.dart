import 'package:flutter_test/flutter_test.dart';
import 'package:aichat/app/app.dart';

void main() {
  testWidgets('app boots', (tester) async {
    await tester.pumpWidget(const AiChatApp());
    await tester.pumpAndSettle();
    expect(find.text('Universal AI Client'), findsWidgets);
  });
}
