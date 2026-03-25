import 'package:flutter_test/flutter_test.dart';
import 'package:campus_connect/main.dart';

void main() {
  testWidgets('App starts without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const CampusConnectApp());
    // Verify the app renders
    expect(find.byType(CampusConnectApp), findsOneWidget);
  });
}
