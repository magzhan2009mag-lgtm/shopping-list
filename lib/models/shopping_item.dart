import 'item_category.dart';

/// One line of the shopping list. Immutable: edits go through [copyWith]
/// and are written back to the box under the same [id].
class ShoppingItem {
  const ShoppingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.createdAt,
    this.quantity = 1,
    this.isBought = false,
  });

  final String id;
  final String name;
  final int quantity;
  final ItemCategory category;
  final bool isBought;
  final DateTime createdAt;

  ShoppingItem copyWith({
    String? name,
    int? quantity,
    ItemCategory? category,
    bool? isBought,
  }) {
    return ShoppingItem(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      isBought: isBought ?? this.isBought,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ShoppingItem &&
      other.id == id &&
      other.name == name &&
      other.quantity == quantity &&
      other.category == category &&
      other.isBought == isBought &&
      other.createdAt == createdAt;

  @override
  int get hashCode =>
      Object.hash(id, name, quantity, category, isBought, createdAt);

  @override
  String toString() =>
      'ShoppingItem($name ×$quantity, ${category.name}, bought: $isBought)';
}
