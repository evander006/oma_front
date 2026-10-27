import 'package:flutter_test/flutter_test.dart';
import 'package:oma/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Home shows turnkey hero and new tabs', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(OmaApp(prefs: prefs));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Ремонт под ключ'), findsWidgets);
    expect(find.text('Рассчитать стоимость'), findsWidgets);
    expect(find.text('Главная'), findsWidgets);
    expect(find.text('Услуги'), findsWidgets);
    expect(find.text('Мои проекты'), findsWidgets);
    expect(find.text('Профиль'), findsWidgets);
  });

  testWidgets('Bottom nav opens services hub', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(OmaApp(prefs: prefs));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Услуги').last);
    await tester.pumpAndSettle();

    expect(find.text('Отдельные работы'), findsOneWidget);
  });
}
