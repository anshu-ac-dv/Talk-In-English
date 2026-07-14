import 'package:flutter_test/flutter_test.dart';
import 'package:speaking_app/main.dart';

void main() {
  testWidgets('shows login screen on launch', (WidgetTester tester) async {
    await tester.pumpWidget(const SpeakingApp());

    expect(find.text('Talk in English'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
