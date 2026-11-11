import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_list/data/shopping_repository.dart';
import 'package:shopping_list/models/item_category.dart';

import 'helpers.dart';

void main() {
  late ShoppingRepository repo;

  setUp(() async => repo = await memoryRepository());

  test('add trims the name, clamps quantity and stores the item', () async {
    final added = await repo.add(
      name: '  Молоко ',
      category: ItemCategory.dairy,
      quantity: 0,
    );

    expect(added.name, 'Молоко');
    expect(added.quantity, 1);
    expect(added.isBought, isFalse);
    expect(repo.items, [added]);
  });

  test('ids are unique even for items added in the same instant', () async {
    final items = await Future.wait([
      for (var i = 0; i < 50; i++)
        repo.add(name: 'Товар $i', category: ItemCategory.other),
    ]);
    expect(items.map((i) => i.id).toSet(), hasLength(50));
    expect(repo.items, hasLength(50));
  });

  test('save updates an item in place', () async {
    final added = await repo.add(name: 'Хлеп', category: ItemCategory.other);
    await repo.save(
      added.copyWith(name: 'Хлеб', category: ItemCategory.bakery, quantity: 2),
    );

    final stored = repo.items.single;
    expect(stored.id, added.id);
    expect(stored.name, 'Хлеб');
    expect(stored.category, ItemCategory.bakery);
    expect(stored.quantity, 2);
  });

  test('toggleBought flips the flag both ways', () async {
    final added = await repo.add(name: 'Сыр', category: ItemCategory.dairy);

    await repo.toggleBought(added);
    expect(repo.items.single.isBought, isTrue);

    await repo.toggleBought(repo.items.single);
    expect(repo.items.single.isBought, isFalse);
  });

  test('delete removes the item, save brings it back (undo)', () async {
    final added = await repo.add(name: 'Чай', category: ItemCategory.grocery);

    await repo.delete(added);
    expect(repo.items, isEmpty);

    await repo.save(added);
    expect(repo.items, [added]);
  });

  test('clearBought removes only bought items and can be undone', () async {
    final milk = await repo.add(name: 'Молоко', category: ItemCategory.dairy);
    final bread = await repo.add(name: 'Хлеб', category: ItemCategory.bakery);
    await repo.toggleBought(milk);

    final removed = await repo.clearBought();
    expect(removed.map((i) => i.name), ['Молоко']);
    expect(repo.items, [bread]);

    await repo.restoreAll(removed);
    expect(repo.items.map((i) => i.name), containsAll(['Молоко', 'Хлеб']));
  });

  test('hideBought setting defaults to false and is stored', () async {
    expect(repo.hideBought, isFalse);
    await repo.setHideBought(true);
    expect(repo.hideBought, isTrue);
  });

  test('changes notifies listeners on item and setting writes', () async {
    var calls = 0;
    repo.changes.addListener(() => calls++);

    await repo.add(name: 'Вода', category: ItemCategory.drinks);
    await repo.setHideBought(true);

    expect(calls, 2);
  });
}
