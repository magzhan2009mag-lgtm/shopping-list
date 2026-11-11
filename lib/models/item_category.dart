import 'package:flutter/material.dart';

/// Store aisles. Persisted by [name], so reordering the enum is safe;
/// the declaration order is the order sections appear on screen.
enum ItemCategory {
  produce('Овощи и фрукты', Icons.eco_outlined, Color(0xFF43A047)),
  dairy('Молочное и яйца', Icons.egg_outlined, Color(0xFF1E88E5)),
  meat('Мясо и рыба', Icons.set_meal_outlined, Color(0xFFE53935)),
  bakery('Хлеб и выпечка', Icons.bakery_dining_outlined, Color(0xFFFB8C00)),
  grocery('Бакалея', Icons.rice_bowl_outlined, Color(0xFF8D6E63)),
  drinks('Напитки', Icons.local_drink_outlined, Color(0xFF3949AB)),
  sweets('Сладости', Icons.cookie_outlined, Color(0xFFD81B60)),
  household(
    'Бытовая химия',
    Icons.cleaning_services_outlined,
    Color(0xFF00897B),
  ),
  other('Другое', Icons.shopping_basket_outlined, Color(0xFF607D8B));

  const ItemCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  static ItemCategory fromName(String? name) => ItemCategory.values.firstWhere(
    (c) => c.name == name,
    orElse: () => ItemCategory.other,
  );
}

/// Word stems per category. A name matches when any of its words starts with
/// a stem, so "колбаса" doesn't hit "кола". Order matters: the first matching
/// category wins, which is why "зеленый чай" lands in grocery (checked before
/// produce) and "апельсиновый сок" in drinks.
const _stems = <ItemCategory, List<String>>{
  ItemCategory.household: [
    'порош',
    'мыл',
    'шампун',
    'зубн',
    'туалетн',
    'салфет',
    'губк',
    'средств',
    'гель',
    'отбелив',
    'освежит',
    'кондиционер',
    'фольг',
    'бумаг',
  ],
  ItemCategory.grocery: [
    'рис',
    'гречк',
    'макарон',
    'спагетт',
    'лапш',
    'мук',
    'сахар',
    'соль',
    'круп',
    'овсян',
    'хлопь',
    'подсолн',
    'растит',
    'оливк',
    'чай',
    'кофе',
    'специ',
    'соус',
    'кетчуп',
    'майонез',
    'горчиц',
    'консерв',
    'фасол',
    'горох',
    'чечевиц',
    'дрожж',
    'уксус',
  ],
  ItemCategory.dairy: [
    'молок',
    'молоч',
    'кефир',
    'сыр',
    'творог',
    'йогурт',
    'сметан',
    'сливочн',
    'сливк',
    'ряженк',
    'айран',
    'кумыс',
    'курт',
    'яйц',
    'яйко',
    'масло',
  ],
  ItemCategory.meat: [
    'мяс',
    'говяд',
    'говяж',
    'свинин',
    'баранин',
    'конин',
    'казы',
    'куриц',
    'курин',
    'окороч',
    'индейк',
    'фарш',
    'колбас',
    'сосиск',
    'сардельк',
    'ветчин',
    'печенк',
    'рыб',
    'лосос',
    'семг',
    'тунец',
    'креветк',
    'филе',
    'стейк',
  ],
  ItemCategory.drinks: [
    'вода',
    'воды',
    'минерал',
    'сок',
    'газиров',
    'лимонад',
    'кола',
    'компот',
    'морс',
    'квас',
    'энергетик',
  ],
  ItemCategory.produce: [
    'яблок',
    'яблоч',
    'банан',
    'помидор',
    'томат',
    'огур',
    'картоф',
    'картош',
    'морков',
    'лук',
    'капуст',
    'апельсин',
    'мандарин',
    'лимон',
    'груш',
    'виноград',
    'перец',
    'чеснок',
    'зелен',
    'укроп',
    'петруш',
    'кинз',
    'салат',
    'фрукт',
    'овощ',
    'ягод',
    'клубник',
    'авокадо',
    'кабач',
    'свекл',
    'баклажан',
    'гриб',
    'шампиньон',
    'арбуз',
    'дын',
  ],
  ItemCategory.bakery: [
    'хлеб',
    'батон',
    'булк',
    'булоч',
    'лаваш',
    'лепешк',
    'багет',
    'круассан',
    'пирог',
    'пирож',
    'баурсак',
    'тост',
  ],
  ItemCategory.sweets: [
    'шоколад',
    'конфет',
    'печенье',
    'печенья',
    'торт',
    'морожен',
    'вафл',
    'зефир',
    'мармелад',
    'пряник',
    'халв',
    'мед',
    'варень',
  ],
};

final _wordSplitter = RegExp(r'[^\p{L}]+', unicode: true);

/// Best guess of the aisle for a product name, or `null` if nothing matched.
ItemCategory? guessCategory(String name) {
  final words = name
      .toLowerCase()
      .replaceAll('ё', 'е')
      .split(_wordSplitter)
      .where((w) => w.isNotEmpty)
      .toList();
  if (words.isEmpty) return null;
  for (final MapEntry(key: category, value: stems) in _stems.entries) {
    if (words.any((w) => stems.any(w.startsWith))) return category;
  }
  return null;
}
