import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frenchvanilla/main.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const FrenchVanillaApp());

    expect(find.widgetWithText(AppBar, 'Rules'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));
  });
}
