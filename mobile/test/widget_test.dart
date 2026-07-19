import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';

void main() {
  testWidgets('JelajahMY application starts successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const JelajahMyApp());

    expect(find.text('JelajahMY'), findsOneWidget);
  });
}
