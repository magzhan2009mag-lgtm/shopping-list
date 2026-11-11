import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:shopping_list/data/shopping_repository.dart';
import 'package:shopping_list/models/item_category.dart';
import 'package:shopping_list/models/shopping_item.dart';
import 'package:shopping_list/models/shopping_item_adapter.dart';
import 'package:shopping_list/utils/ru_plural.dart';

ShoppingItem item(
  String id, {
  ItemCategory category = ItemCategory.other,
  bool bought = false,
  int minute = 0,
}) => ShoppingItem(
  id: id,
  name: id,
  category: category,
  isBought: bought,
  createdAt: DateTime(2026, 1, 1, 12, minute),
);

void main() {
  group('guessCategory', () {
    test('matches common products by word stem', () {
      expect(guessCategory('Молоко 3,2%'), ItemCategory.dairy);
      expect(guessCategory('яйца'), ItemCategory.dairy);
      expect(guessCategory('Куриное филе'), ItemCategory.meat);
      expect(guessCategory('Бананы'), ItemCategory.produce);
      expect(guessCategory('Лепёшка'), ItemCategory.bakery);
      expect(guessCategory('Гречка'), ItemCategory.grocery);
      expect(guessCategory('Стиральный порошок'), ItemCategory.household);
      expect(guessCategory('Печенье'), ItemCategory.sweets);
    });

    test('resolves ambiguous names by category order', () {
      expect(guessCategory('Зелёный чай'), ItemCategory.grocery);
      expect(guessCategory('Апельсиновый сок'), ItemCategory.drinks);
      expect(guessCategory('Подсолнечное масло'), ItemCategory.grocery);
      expect(guessCategory('Сливочное масло'), ItemCategory.dairy);
      expect(guessCategory('Колбаса'), ItemCategory.meat);
      expect(guessCategory('Кола'), ItemCategory.drinks);
    });

    test('returns null when nothing matches', () {
      expect(guessCategory(''), isNull);
      expect(guessCategory('   '), isNull);
      expect(guessCategory('Батарейки AA'), isNull);
    });
  });

  test('ItemCategory.fromName falls back to other', () {
    expect(ItemCategory.fromName('dairy'), ItemCategory.dairy);
    expect(ItemCategory.fromName('removed_category'), ItemCategory.other);
    expect(ItemCategory.fromName(null), ItemCategory.other);
  });

  test('ruPlural', () {
    String f(int n) => ruPlural(n, 'товар', 'товара', 'товаров');
    expect([1, 2, 5, 11, 12, 21, 22, 25, 111, 101].map(f).toList(), [
      'товар', 'товара', 'товаров', 'товаров', 'товаров', //
      'товар', 'товара', 'товаров', 'товаров', 'товар',
    ]);
  });

  group('groupByCategory', () {
    test('orders groups by category and puts bought items last', () {
      final groups = groupByCategory([
        item('хлеб', category: ItemCategory.bakery),
        item('кефир', category: ItemCategory.dairy, bought: true, minute: 1),
        item('молоко', category: ItemCategory.dairy, minute: 2),
        item('сыр', category: ItemCategory.dairy, minute: 3),
      ]);

      expect(groups.map((g) => g.category), [
        ItemCategory.dairy,
        ItemCategory.bakery,
      ]);
      expect(groups.first.items.map((i) => i.id), ['молоко', 'сыр', 'кефир']);
      expect(groups.first.boughtCount, 1);
      expect(groups.first.remaining, 2);
    });

    test('hideBought hides bought items and fully bought groups', () {
      final groups = groupByCategory([
        item('хлеб', category: ItemCategory.bakery, bought: true),
        item('кефир', category: ItemCategory.dairy, bought: true),
        item('молоко', category: ItemCategory.dairy),
      ], hideBought: true);

      expect(groups, hasLength(1));
      expect(groups.single.visible.map((i) => i.id), ['молоко']);
      // The header still counts everything in the category.
      expect(groups.single.items, hasLength(2));
    });
  });

  test('adapter round-trips an item through a box on disk', () async {
    final dir = await Directory.systemTemp.createTemp('hive_test');
    addTearDown(() => dir.delete(recursive: true));
    Hive.init(dir.path);
    Hive.registerAdapter(ShoppingItemAdapter());

    final original = ShoppingItem(
      id: 'abc-1',
      name: 'Сыр «Российский»',
      quantity: 3,
      category: ItemCategory.dairy,
      isBought: true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1767225600123),
    );
    var box = await Hive.openBox<ShoppingItem>('items');
    await box.put(original.id, original);
    await box.close();

    box = await Hive.openBox<ShoppingItem>('items');
    expect(box.get('abc-1'), original);
    await Hive.close();
  });
}
