import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:oma/app/router/app_routes.dart';
import 'package:oma/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> skipLaunchIntro(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(find.text('Пропустить'));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Home shows turnkey hero and new tabs', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(OmaApp(prefs: prefs));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await skipLaunchIntro(tester);

    expect(find.text('Ремонт под ключ'), findsWidgets);
    expect(find.text('Дом, в котором хорошо'), findsOneWidget);
    expect(find.text('Главная'), findsWidgets);
    expect(find.text('Услуги'), findsWidgets);
    expect(find.text('Мои проекты'), findsWidgets);
    expect(find.text('Профиль'), findsWidgets);
  });

  testWidgets('Services opens the masters catalog', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(OmaApp(prefs: prefs));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await skipLaunchIntro(tester);

    await tester.tap(find.text('Услуги').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Найти мастера'));
    await tester.pumpAndSettle();

    expect(find.text('Найдите исполнителя под задачу'), findsOneWidget);
  });

  testWidgets('Opening passport from 3D does not duplicate Navigator keys',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(OmaApp(prefs: prefs));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await skipLaunchIntro(tester);

    // Room3dScreen is a root-level route, while the home passport belongs to
    // the Profile StatefulShellBranch. This reproduces that exact transition.
    GoRouter.of(tester.element(find.text('Главная').last))
        .go(AppRoutes.property3dPath('1'));
    await tester.pumpAndSettle();

    expect(find.text('Технический паспорт жилья'), findsOneWidget);
    await tester.tap(find.text('Технический паспорт жилья'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // No object exists in the mock data: the passport's empty state confirms
    // the correct nested route was entered instead of crashing.
    expect(find.text('Объект не найден'), findsOneWidget);
  });

  testWidgets('Bottom nav opens services hub', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(OmaApp(prefs: prefs));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await skipLaunchIntro(tester);

    await tester.tap(find.text('Услуги').last);
    await tester.pumpAndSettle();

    expect(find.text('Отдельные работы'), findsOneWidget);
  });
}
