import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/item_category.dart';
import '../models/shopping_item.dart';
import '../models/shopping_item_adapter.dart';

/// All reads and writes of the list go through here; widgets never touch
/// Hive directly. Every write lands in the box immediately, and the UI
/// rebuilds from [changes].
class ShoppingRepository {
  ShoppingRepository(this._items, this._settings);

  static const itemsBoxName = 'shopping_items';
  static const settingsBoxName = 'settings';
  static const _hideBoughtKey = 'hide_bought';

  final Box<ShoppingItem> _items;
  final Box<dynamic> _settings;

  /// Registers the adapter and opens both boxes from disk (IndexedDB on web).
  static Future<ShoppingRepository> open() async {
    await Hive.initFlutter();
    registerAdapters();
    return ShoppingRepository(
      await Hive.openBox<ShoppingItem>(itemsBoxName),
      await Hive.openBox<dynamic>(settingsBoxName),
    );
  }

  static void registerAdapters() {
    final adapter = ShoppingItemAdapter();
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  }

  /// Fires on any change to the items or the settings.
  late final Listenable changes = Listenable.merge([
    _items.listenable(),
    _settings.listenable(),
  ]);

  List<ShoppingItem> get items => _items.values.toList(growable: false);

  bool get hideBought =>
      _settings.get(_hideBoughtKey, defaultValue: false) as bool;

  Future<void> setHideBought(bool value) =>
      _settings.put(_hideBoughtKey, value);

  // ---- CRUD ----------------------------------------------------------------

  Future<ShoppingItem> add({
    required String name,
    required ItemCategory category,
    int quantity = 1,
  }) async {
    final item = ShoppingItem(
      id: _newId(),
      name: name.trim(),
      quantity: quantity.clamp(1, 999),
      category: category,
      createdAt: DateTime.now(),
    );
    await _items.put(item.id, item);
    return item;
  }

  /// Saves an edited item (same id). Also used to undo a delete.
  Future<void> save(ShoppingItem item) => _items.put(item.id, item);

  Future<void> toggleBought(ShoppingItem item) =>
      save(item.copyWith(isBought: !item.isBought));

  Future<void> delete(ShoppingItem item) => _items.delete(item.id);

  /// Removes every bought item and returns them so the caller can offer undo.
  Future<List<ShoppingItem>> clearBought() async {
    final bought = _items.values.where((i) => i.isBought).toList();
    await _items.deleteAll(bought.map((i) => i.id));
    return bought;
  }

  Future<void> restoreAll(Iterable<ShoppingItem> items) =>
      _items.putAll({for (final i in items) i.id: i});

  static int _seq = 0;

  // Hive string keys must be ASCII and ≤ 255 chars. Time + counter is unique
  // within a device, which is all a local list needs.
  static String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '-${(_seq++).toRadixString(36)}';
}

/// One category's items, sorted for display: still-to-buy first (in the
/// order they were added), bought ones sink to the bottom.
@immutable
class CategoryGroup {
  const CategoryGroup(this.category, this.items, {this.hideBought = false});

  final ItemCategory category;

  /// Every item in the category, including bought ones even when hidden,
  /// so the header can still show "2/5".
  final List<ShoppingItem> items;
  final bool hideBought;

  List<ShoppingItem> get visible =>
      hideBought ? items.where((i) => !i.isBought).toList() : items;

  int get boughtCount => items.where((i) => i.isBought).length;
  int get remaining => items.length - boughtCount;
}

/// Splits [items] into groups in [ItemCategory] declaration order.
/// With [hideBought], categories with nothing left to buy are left out.
List<CategoryGroup> groupByCategory(
  Iterable<ShoppingItem> items, {
  bool hideBought = false,
}) {
  final byCategory = <ItemCategory, List<ShoppingItem>>{};
  for (final item in items) {
    byCategory.putIfAbsent(item.category, () => []).add(item);
  }
  return [
    for (final category in ItemCategory.values)
      if (byCategory[category] case final list?)
        if (!hideBought || list.any((i) => !i.isBought))
          CategoryGroup(
            category,
            list..sort(_displayOrder),
            hideBought: hideBought,
          ),
  ];
}

int _displayOrder(ShoppingItem a, ShoppingItem b) {
  if (a.isBought != b.isBought) return a.isBought ? 1 : -1;
  final byTime = a.createdAt.compareTo(b.createdAt);
  return byTime != 0 ? byTime : a.id.compareTo(b.id);
}
