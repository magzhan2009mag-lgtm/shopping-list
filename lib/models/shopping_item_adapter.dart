import 'package:hive_ce/hive_ce.dart';

import 'item_category.dart';
import 'shopping_item.dart';

/// Hand-written Hive adapter (no build_runner).
///
/// Layout: field count, then `index, value` pairs. Unknown indexes are
/// ignored and missing ones fall back to defaults, so fields can be added
/// later without migrating existing data. Never reuse an index.
class ShoppingItemAdapter extends TypeAdapter<ShoppingItem> {
  @override
  final int typeId = 0;

  static const _id = 0;
  static const _name = 1;
  static const _quantity = 2;
  static const _category = 3;
  static const _isBought = 4;
  static const _createdAt = 5;

  @override
  ShoppingItem read(BinaryReader reader) {
    final count = reader.readByte();
    final fields = <int, Object?>{
      for (var i = 0; i < count; i++) reader.readByte(): reader.read(),
    };
    return ShoppingItem(
      id: fields[_id] as String,
      name: fields[_name] as String,
      quantity: fields[_quantity] as int? ?? 1,
      category: ItemCategory.fromName(fields[_category] as String?),
      isBought: fields[_isBought] as bool? ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        fields[_createdAt] as int? ?? 0,
      ),
    );
  }

  @override
  void write(BinaryWriter writer, ShoppingItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(_id)
      ..write(obj.id)
      ..writeByte(_name)
      ..write(obj.name)
      ..writeByte(_quantity)
      ..write(obj.quantity)
      ..writeByte(_category)
      ..write(obj.category.name)
      ..writeByte(_isBought)
      ..write(obj.isBought)
      ..writeByte(_createdAt)
      ..write(obj.createdAt.millisecondsSinceEpoch);
  }
}
