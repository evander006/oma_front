import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oma/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Home shows OMA DOM entry', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(OmaApp(prefs: prefs));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.scrollUntilVisible(
      find.textContaining('ОМА ДОМ'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.textContaining('ОМА ДОМ'), findsOneWidget);
    expect(find.text('Акции и предложения'), findsOneWidget);
    expect(find.text('Главная'), findsWidgets);
  });
}
