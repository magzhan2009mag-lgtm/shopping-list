import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/shopping_repository.dart';
import 'screens/home_screen.dart';

class ShoppingListApp extends StatelessWidget {
  const ShoppingListApp({super.key, required this.repository});

  final ShoppingRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Список покупок',
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: HomeScreen(repository: repository),
    );
  }
}

ThemeData _theme(Brightness brightness) {
  final light = brightness == Brightness.light;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E7D4F),
        brightness: brightness,
      ).copyWith(
        surface: light ? const Color(0xFFF5F3EC) : const Color(0xFF141613),
        surfaceContainerLowest: light ? Colors.white : const Color(0xFF1D201C),
      );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
    ),
    chipTheme: const ChipThemeData(showCheckmark: false),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
    ),
  );
}
