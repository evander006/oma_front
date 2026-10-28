import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oma/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> mount(
    WidgetTester tester, {
    Map<String, Object> initialValues = const {},
  }) async {
    SharedPreferences.setMockInitialValues(initialValues);
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(OmaApp(prefs: prefs));
    await tester.pumpAndSettle();
    return prefs;
  }

  testWidgets('guest can advance and swipe, then start at existing home',
      (tester) async {
    await mount(tester);

    expect(find.text('Всё о вашем доме — в одном месте'), findsOneWidget);
    expect(find.text('Пропустить'), findsOneWidget);

    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();
    expect(find.text('Представьте свой дом в 3D'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Нашли идею? Найдите товар'), findsOneWidget);

    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();
    expect(find.text('Помощь специалиста — рядом'), findsOneWidget);
    expect(find.text('Начать'), findsOneWidget);
    expect(find.text('Пропустить'), findsOneWidget);

    await tester.tap(find.text('Начать'));
    await tester.pumpAndSettle();

    expect(find.text('Дом, в котором хорошо'), findsOneWidget);
    expect(find.text('Пропустить'), findsNothing);
  });

  testWidgets('skip preserves preferences, does not restart during navigation',
      (tester) async {
    final prefs = await mount(
      tester,
      initialValues: {'registered': true, 'oma_session_token': 'test-token'},
    );
    await tester.tap(find.text('Пропустить'));
    await tester.pumpAndSettle();

    expect(find.text('Дом, в котором хорошо'), findsOneWidget);
    expect(prefs.getBool('registered'), isTrue);
    expect(prefs.getString('oma_session_token'), 'test-token');
    expect(prefs.containsKey('hasSeenOnboarding'), isFalse);

    await tester.tap(find.text('Каталог').last);
    await tester.pumpAndSettle();
    expect(find.text('Пропустить'), findsNothing);

    // Mounting a new root represents a fresh process launch: onboarding
    // must reappear even though the same user preferences are retained.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(OmaApp(prefs: prefs));
    await tester.pumpAndSettle();
    expect(find.text('Всё о вашем доме — в одном месте'), findsOneWidget);
    expect(prefs.getString('oma_session_token'), 'test-token');
  });

  testWidgets('introduction is scroll-safe on a compact phone',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await mount(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Далее'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
