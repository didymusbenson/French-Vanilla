import 'package:flutter_test/flutter_test.dart';
import 'package:frenchvanilla/main.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const FrenchVanillaApp());

    expect(find.text('MTG Comprehensive Rules'), findsOneWidget);
  });
}
