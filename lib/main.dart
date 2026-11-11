import 'package:flutter/material.dart';

import 'app.dart';
import 'data/shopping_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await ShoppingRepository.open();
  runApp(ShoppingListApp(repository: repository));
}
