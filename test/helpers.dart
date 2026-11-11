import 'dart:typed_data';

import 'package:hive_ce/hive_ce.dart';
import 'package:shopping_list/data/shopping_repository.dart';
import 'package:shopping_list/models/shopping_item.dart';

int _boxCounter = 0;

/// A repository over fresh in-memory boxes: real Hive, no disk.
Future<ShoppingRepository> memoryRepository() async {
  ShoppingRepository.registerAdapters();
  final n = _boxCounter++;
  return ShoppingRepository(
    await Hive.openBox<ShoppingItem>('items_$n', bytes: Uint8List(0)),
    await Hive.openBox<dynamic>('settings_$n', bytes: Uint8List(0)),
  );
}
