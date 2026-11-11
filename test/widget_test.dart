import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_list/app.dart';
import 'package:shopping_list/data/shopping_repository.dart';
import 'package:shopping_list/models/item_category.dart';

import 'helpers.dart';

void main() {
  late ShoppingRepository repo;

  setUp(() async => repo = await memoryRepository());

  Future<void> launch(WidgetTester tester) async {
    await tester.pumpWidget(ShoppingListApp(repository: repo));
    await tester.pumpAndSettle();
  }

  ChoiceChip chip(WidgetTester tester, String label) =>
      tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label));

  testWidgets('shows the empty state', (tester) async {
    await launch(tester);
    expect(find.text('Список пуст'), findsOneWidget);
  });

  testWidgets('adds an item; category is guessed from the name', (
    tester,
  ) async {
    await launch(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Новый товар'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('item-name')), 'Кефир');
    await tester.pump();
    expect(chip(tester, 'Молочное и яйца').selected, isTrue);
    expect(find.text('подобрана по названию'), findsOneWidget);

    await tester.tap(find.byTooltip('Больше'));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Добавить'));
    await tester.pumpAndSettle();

    expect(find.text('Кефир'), findsOneWidget);
    expect(find.text('×2'), findsOneWidget);
    expect(find.text('Молочное и яйца'), findsOneWidget);
    expect(repo.items.single.category, ItemCategory.dairy);
    expect(repo.items.single.quantity, 2);
  });

  testWidgets('a hand-picked category is not overridden by typing', (
    tester,
  ) async {
    await launch(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Сладости'));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('item-name')), 'Молоко');
    await tester.pump();

    expect(chip(tester, 'Сладости').selected, isTrue);
    expect(chip(tester, 'Молочное и яйца').selected, isFalse);
  });

  testWidgets('add button is disabled for a blank name', (tester) async {
    await launch(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('item-name')), '   ');
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Добавить'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('tap toggles bought and updates progress', (tester) async {
    await repo.add(name: 'Хлеб', category: ItemCategory.bakery);
    await repo.add(name: 'Батон', category: ItemCategory.bakery);
    await launch(tester);
    expect(find.text('0 / 2'), findsOneWidget);

    await tester.tap(find.text('Хлеб'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 2'), findsOneWidget);
    expect(repo.items.firstWhere((i) => i.name == 'Хлеб').isBought, isTrue);
  });

  testWidgets('swipe right marks bought and keeps the row', (tester) async {
    await repo.add(name: 'Сыр', category: ItemCategory.dairy);
    await launch(tester);

    await tester.drag(find.text('Сыр'), const Offset(300, 0));
    await tester.pumpAndSettle();

    expect(find.text('Сыр'), findsOneWidget);
    expect(repo.items.single.isBought, isTrue);
  });

  testWidgets('swipe left deletes, and undo restores', (tester) async {
    await repo.add(name: 'Чай', category: ItemCategory.grocery);
    await launch(tester);

    await tester.drag(find.text('Чай'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Чай'), findsNothing);
    expect(repo.items, isEmpty);
    expect(find.text('«Чай» удалён'), findsOneWidget);

    await tester.tap(find.text('Отменить'));
    await tester.pumpAndSettle();

    expect(find.text('Чай'), findsOneWidget);
    expect(repo.items.single.name, 'Чай');
  });

  testWidgets('long press opens the editor and saves changes', (tester) async {
    await repo.add(name: 'Яблки', category: ItemCategory.other);
    await launch(tester);

    await tester.longPress(find.text('Яблки'));
    await tester.pumpAndSettle();
    expect(find.text('Изменить товар'), findsOneWidget);
    // Editing keeps the saved category rather than re-guessing it.
    expect(chip(tester, 'Другое').selected, isTrue);

    await tester.enterText(find.byKey(const Key('item-name')), 'Яблоки');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Овощи и фрукты'));
    await tester.tap(find.widgetWithText(FilledButton, 'Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Яблоки'), findsOneWidget);
    expect(find.text('Овощи и фрукты'), findsOneWidget);
    expect(repo.items.single.category, ItemCategory.produce);
  });

  testWidgets('hide bought, then clear bought with undo', (tester) async {
    final milk = await repo.add(name: 'Молоко', category: ItemCategory.dairy);
    await repo.add(name: 'Хлеб', category: ItemCategory.bakery);
    await repo.toggleBought(milk);
    await launch(tester);

    await tester.tap(find.byTooltip('Скрыть купленные'));
    await tester.pumpAndSettle();
    expect(find.text('Молоко'), findsNothing);
    expect(find.text('Молочное и яйца'), findsNothing);
    expect(repo.hideBought, isTrue);

    await tester.tap(find.byTooltip('Показать купленные'));
    await tester.pumpAndSettle();
    expect(find.text('Молоко'), findsOneWidget);

    await tester.tap(find.byTooltip('Удалить купленные'));
    await tester.pumpAndSettle();
    expect(find.text('Из списка уйдут 1 товар.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Удалить'));
    await tester.pumpAndSettle();

    expect(find.text('Молоко'), findsNothing);
    expect(repo.items.single.name, 'Хлеб');

    await tester.tap(find.text('Отменить'));
    await tester.pumpAndSettle();
    expect(find.text('Молоко'), findsOneWidget);
  });
}
