import 'dart:async';
import 'dart:math';

import 'package:capitals/domain/assemble.dart';
import 'package:capitals/keys.dart';
import 'package:capitals/ui/components/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:logging/logging.dart';

import 'test_main.dart' as test_app;
import 'package:capitals/main.dart' as app;

final testLogger = Logger('[Test]');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late final StreamSubscription loggerSub;

  setUpAll(() {
    loggerSub = testLogger.onRecord
        // ignore: avoid_print
        .listen((event) => print('${event.time}: $event'));
  });

  tearDownAll(() async => await loggerSub.cancel());

  // Сбрасываем контейнер getIt после каждого теста
  tearDown(() => getIt.reset());

  testWidgets(
      'When app started then items are loaded '
      'and appear on the screen', (tester) async {
    test_app.main();

    // Итерируемся по фреймам до тех пор,
    // пока в состоянии не появятся айтемы
    while (assemble.itemsLogic.state.items.isEmpty) {
      await tester.pump();
    }
    await tester.pumpTimes(50);

    // Проверяем наличие всех необходимых виджетов на экране
    expect(find.byKey(const ValueKey('Luanda')), findsOneWidget);
    expect(find.widgetWithText(InkResponse, 'True'), findsOneWidget);
    expect(find.widgetWithText(InkResponse, 'False'), findsOneWidget);
    expect(find.text('Is it Luanda?'), findsOneWidget);
    expect(find.text('Angola'), findsOneWidget);
    expect(find.widgetWithIcon(IconButton, Icons.nightlight_round),
        findsOneWidget);

    // Проверяем наличие виджетов с прогрессом (с волнами)
    // и убеждаемся, что прогресс равен 0
    final scoreProgress = find.byWidgetPredicate(
      (widget) =>
          widget.key == Keys.scoreProgressWave &&
          widget is ProgressWave &&
          widget.progress == 0,
    );
    expect(scoreProgress, findsOneWidget);
    final itemsProgress = find.byWidgetPredicate(
      (widget) =>
          widget.key == Keys.itemsProgressWave &&
          widget is ProgressWave &&
          widget.progress == 0,
    );
    expect(itemsProgress, findsOneWidget);

    await Future.delayed(const Duration(seconds: 3));
  });

  testWidgets('When drag cards then current item is updated', (tester) async {
    test_app.main();
    while (assemble.itemsLogic.state.items.isEmpty) {
      await tester.pump();
    }
    await tester.pumpTimes(50);

    final firstCard = find.byKey(const ValueKey('Luanda'));
    expect(firstCard, findsOneWidget);
    expect(find.widgetWithText(InkResponse, 'True'), findsOneWidget);
    expect(find.widgetWithText(InkResponse, 'False'), findsOneWidget);
    expect(find.text('Is it Luanda?'), findsOneWidget);
    expect(find.text('Angola'), findsOneWidget);
    expect(find.widgetWithIcon(IconButton, Icons.nightlight_round),
        findsOneWidget);
    var scoreProgress = find.byKey(Keys.scoreProgressWave);
    var scoreSize = tester.getSize(scoreProgress);
    expect(scoreProgress, findsOneWidget);
    var itemsProgress = find.byKey(Keys.itemsProgressWave);
    var itemsSize = tester.getSize(itemsProgress);
    expect(itemsProgress, findsOneWidget);

    // Делаем свайп влево
    await tester.timedDrag(
        firstCard, const Offset(100.0, 0.0), const Duration(seconds: 1));
    // И итерируемся по кадрам, чтобы виджет улетел
    await tester.pumpTimes(50);

    // Проверяем, что старой карточки уже нет, а виджеты обновились
    expect(firstCard, findsNothing);
    final secondCard = find.byKey(const ValueKey('Ankara'));
    expect(secondCard, findsOneWidget);
    expect(find.widgetWithText(InkResponse, 'True'), findsOneWidget);
    expect(find.widgetWithText(InkResponse, 'False'), findsOneWidget);
    expect(find.text('Is it Ankara?'), findsOneWidget);
    expect(find.text('Turkey'), findsOneWidget);
    expect(find.widgetWithIcon(IconButton, Icons.nightlight_round),
        findsOneWidget);

    // Проверяем, что прогресс очков и айтемов изменился
    scoreProgress = find.byKey(Keys.scoreProgressWave);
    expect(scoreProgress, findsOneWidget);
    var prevScoreSize = scoreSize;
    scoreSize = tester.getSize(scoreProgress);
    testLogger.info('Score size: prev=$prevScoreSize, crt=$scoreSize');
    expect(prevScoreSize.height < scoreSize.height, isTrue);
    itemsProgress = find.byKey(Keys.itemsProgressWave);
    expect(itemsProgress, findsOneWidget);
    var prevItemsSize = itemsSize;
    itemsSize = tester.getSize(itemsProgress);
    testLogger.info('Items size: prev=$prevItemsSize, crt=$itemsSize');
    expect(prevItemsSize.height < itemsSize.height, isTrue);

    await tester.timedDrag(
        secondCard, const Offset(-100.0, 0.0), const Duration(seconds: 1));
    await tester.pumpTimes(50);

    final thirdCard = find.byKey(const ValueKey('Tunis'));
    expect(firstCard, findsNothing);
    expect(secondCard, findsNothing);
    expect(thirdCard, findsOneWidget);
    expect(find.widgetWithText(InkResponse, 'True'), findsOneWidget);
    expect(find.widgetWithText(InkResponse, 'False'), findsOneWidget);
    expect(find.text('Is it Tunis?'), findsOneWidget);
    expect(find.text('Tunisia'), findsOneWidget);
    expect(find.widgetWithIcon(IconButton, Icons.nightlight_round),
        findsOneWidget);

    // Проверяем, что прогресс очков изменился в меньшую сторону,
    // потому что мы ответили неправильно
    scoreProgress = find.byKey(Keys.scoreProgressWave);
    expect(scoreProgress, findsOneWidget);
    prevScoreSize = scoreSize;
    scoreSize = tester.getSize(scoreProgress);
    testLogger.info('Score size: prev=$prevScoreSize, crt=$scoreSize');
    expect(prevScoreSize.height > scoreSize.height, isTrue);

    // При этом прогресс айтемов тоже изменился,
    // потому что до конца их осталось меньше
    itemsProgress = find.byKey(Keys.itemsProgressWave);
    expect(itemsProgress, findsOneWidget);
    prevItemsSize = itemsSize;
    itemsSize = tester.getSize(itemsProgress);
    testLogger.info('Items size: prev=$prevItemsSize, crt=$itemsSize');
    expect(prevItemsSize.height < itemsSize.height, isTrue);

    await tester.pumpTimes(50);

    await Future.delayed(const Duration(seconds: 3));
  });

  testWidgets('When tap True or False then current item is updated',
      (tester) async {
    // Делаем всё то же самое, что и в предыдущем тесте,
    // но проверяя тапы на кнопки True/False
    // и в другом порядке (сначала false, потом true)

    test_app.main();
    while (assemble.itemsLogic.state.items.isEmpty) {
      await tester.pump();
    }
    await tester.pumpTimes(50);

    final trueButton = find.widgetWithText(InkResponse, 'True');
    final falseButton = find.widgetWithText(InkResponse, 'False');

    final firstCard = find.byKey(const ValueKey('Luanda'));
    expect(firstCard, findsOneWidget);
    expect(trueButton, findsOneWidget);
    expect(falseButton, findsOneWidget);
    expect(find.text('Is it Luanda?'), findsOneWidget);
    expect(find.text('Angola'), findsOneWidget);
    expect(find.widgetWithIcon(IconButton, Icons.nightlight_round),
        findsOneWidget);
    var scoreProgress = find.byKey(Keys.scoreProgressWave);
    var scoreSize = tester.getSize(scoreProgress);
    expect(scoreProgress, findsOneWidget);
    var itemsProgress = find.byKey(Keys.itemsProgressWave);
    var itemsSize = tester.getSize(itemsProgress);
    expect(itemsProgress, findsOneWidget);

    await tester.tap(falseButton);
    await tester.pumpTimes(50);

    final secondCard = find.byKey(const ValueKey('Ankara'));
    expect(firstCard, findsNothing);
    expect(secondCard, findsOneWidget);
    expect(trueButton, findsOneWidget);
    expect(falseButton, findsOneWidget);
    expect(find.text('Is it Ankara?'), findsOneWidget);
    expect(find.text('Turkey'), findsOneWidget);
    expect(find.widgetWithIcon(IconButton, Icons.nightlight_round),
        findsOneWidget);

    scoreProgress = find.byKey(Keys.scoreProgressWave);
    expect(scoreProgress, findsOneWidget);
    var prevScoreSize = scoreSize;
    scoreSize = tester.getSize(scoreProgress);
    testLogger.info('Score size: prev=$prevScoreSize, crt=$scoreSize');
    expect(prevScoreSize.height == scoreSize.height, isTrue);
    itemsProgress = find.byKey(Keys.itemsProgressWave);
    expect(itemsProgress, findsOneWidget);
    var prevItemsSize = itemsSize;
    itemsSize = tester.getSize(itemsProgress);
    testLogger.info('Items size: prev=$prevItemsSize, crt=$itemsSize');
    expect(prevItemsSize.height < itemsSize.height, isTrue);

    await tester.tap(trueButton);
    await tester.pumpTimes(50);

    final thirdCard = find.byKey(const ValueKey('Tunis'));
    expect(firstCard, findsNothing);
    expect(secondCard, findsNothing);
    expect(thirdCard, findsOneWidget);
    expect(trueButton, findsOneWidget);
    expect(falseButton, findsOneWidget);
    expect(find.text('Is it Tunis?'), findsOneWidget);
    expect(find.text('Tunisia'), findsOneWidget);
    expect(find.widgetWithIcon(IconButton, Icons.nightlight_round),
        findsOneWidget);

    scoreProgress = find.byKey(Keys.scoreProgressWave);
    expect(scoreProgress, findsOneWidget);
    prevScoreSize = scoreSize;
    scoreSize = tester.getSize(scoreProgress);
    testLogger.info('Score size: prev=$prevScoreSize, crt=$scoreSize');
    expect(prevScoreSize.height < scoreSize.height, isTrue);
    itemsProgress = find.byKey(Keys.itemsProgressWave);
    expect(itemsProgress, findsOneWidget);
    prevItemsSize = itemsSize;
    itemsSize = tester.getSize(itemsProgress);
    testLogger.info('Items size: prev=$prevItemsSize, crt=$itemsSize');
    expect(prevItemsSize.height < itemsSize.height, isTrue);

    await tester.pumpTimes(50);

    await Future.delayed(const Duration(seconds: 3));
  });

  testWidgets('When full game completed then final score is shown',
      (tester) async {
    // Проходим полный флоу игры до экрана с результатами

    // Запускаем полностью продовое окружение
    app.main();
    while (assemble.itemsLogic.state.items.isEmpty) {
      await tester.pump();
    }
    await tester.pumpTimes(50);

    final random = Random();

    expect(find.byType(Headers), findsOneWidget);
    expect(find.byType(Controls), findsOneWidget);

    for (var i = 0; i < 29; i++) {
      final shouldDrag = random.nextBool();
      final guessTrue = random.nextBool();

      final card = find.byType(CapitalCard);
      if (shouldDrag) {
        // Делаем свайп влево
        await tester.timedDrag(
          card.last,
          Offset(guessTrue ? 100.0 : -100, 0.0),
          const Duration(milliseconds: 200),
        );
        // И итерируемся по кадрам, чтобы виджет улетел
      } else {
        await tester.tap(
            find.widgetWithText(InkResponse, guessTrue ? 'True' : 'False'));
      }
      await tester.pumpTimes(50);

      expect(card, findsWidgets);
      expect(find.byType(Headers), findsOneWidget);
      expect(find.byType(Controls), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.nightlight_round),
          findsOneWidget);

      testLogger.fine(
          '${assemble.itemsLogic.state.currentIndex}: ${assemble.itemsLogic.state.items.map((e) => e.original.capital)}');
    }

    // Угадываем последнюю карточку
    await tester.tap(find.widgetWithText(InkResponse, 'True'));
    await tester.pumpTimes(50);

    expect(find.byType(CapitalCard), findsNothing);
    expect(find.byType(Headers), findsNothing);
    expect(find.byType(Controls), findsNothing);
    final complete = find.byType(CompleteWidget);
    expect(complete, findsOneWidget);
    expect(find.text('Your result'), findsOneWidget);
    expect(find.byKey(Keys.scoreResult), findsOneWidget);
    expect(find.byKey(Keys.maxResult), findsOneWidget);

    await Future.delayed(const Duration(seconds: 3));

    // Тапаем по виджету завершения и проверяем, что игра началась заново
    await tester.tap(complete);
    await tester.pumpTimes(50);

    expect(complete, findsNothing);
    expect(find.byType(CapitalCard), findsWidgets);
    expect(find.byType(Headers), findsOneWidget);
    expect(find.byType(Controls), findsOneWidget);
    expect(find.widgetWithIcon(IconButton, Icons.nightlight_round),
        findsOneWidget);

    await Future.delayed(const Duration(seconds: 3));
  });

  testWidgets('Light/dark mode switching', (tester) async {
    app.main();

    await tester.pumpTimes(50);

    Element context() => tester.element(find.byType(Scaffold));

    expect(Theme.of(context()).brightness, Brightness.light);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.nightlight_round));
    await tester.pumpTimes(50);
    await Future.delayed(const Duration(seconds: 1));

    expect(Theme.of(context()).brightness, Brightness.dark);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.wb_sunny_outlined));
    await tester.pumpTimes(50);
    await Future.delayed(const Duration(seconds: 1));

    expect(Theme.of(context()).brightness, Brightness.light);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.nightlight_round));
    await tester.pumpTimes(50);
    await Future.delayed(const Duration(seconds: 1));

    expect(Theme.of(context()).brightness, Brightness.dark);

    await Future.delayed(const Duration(seconds: 3));
  });
}

extension TesterExt on WidgetTester {
  Future<void> pumpTimes(
    int times, [
    Duration? duration,
    EnginePhase phase = EnginePhase.sendSemanticsUpdate,
  ]) async {
    for (var i = 0; i < times; i++) {
      await pump(duration, phase);
    }
  }
}
