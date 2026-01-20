import 'package:flutter/material.dart';
import '../constants/magic_colors.dart';

/// Enum representing the type of heart style rendering
enum HeartStyleType {
  solid,      // Single color heart
  gradient2,  // Two-color gradient
  gradient3,  // Three-color gradient
}

/// Model representing a heart style based on Magic: The Gathering color combinations
class HeartStyle {
  final String id;
  final String name;
  final HeartStyleType type;
  final List<Color> colors;

  const HeartStyle({
    required this.id,
    required this.name,
    required this.type,
    required this.colors,
  });

  // Mono-color hearts (5)
  factory HeartStyle.white() => const HeartStyle(
        id: 'white',
        name: 'White',
        type: HeartStyleType.solid,
        colors: [MagicColors.magicWhiteDark],
      );

  factory HeartStyle.blue() => const HeartStyle(
        id: 'blue',
        name: 'Blue',
        type: HeartStyleType.solid,
        colors: [MagicColors.magicBlueDark],
      );

  factory HeartStyle.black() => const HeartStyle(
        id: 'black',
        name: 'Black',
        type: HeartStyleType.solid,
        colors: [MagicColors.magicBlackDark],
      );

  factory HeartStyle.red() => const HeartStyle(
        id: 'red',
        name: 'Red',
        type: HeartStyleType.solid,
        colors: [MagicColors.magicRedDark],
      );

  factory HeartStyle.green() => const HeartStyle(
        id: 'green',
        name: 'Green',
        type: HeartStyleType.solid,
        colors: [MagicColors.magicGreenDark],
      );

  // Guild hearts (10 two-color combinations)
  factory HeartStyle.azorius() => const HeartStyle(
        id: 'azorius',
        name: 'Azorius',
        type: HeartStyleType.gradient2,
        colors: [MagicColors.magicWhiteDark, MagicColors.magicBlueDark],
      );

  factory HeartStyle.orzhov() => const HeartStyle(
        id: 'orzhov',
        name: 'Orzhov',
        type: HeartStyleType.gradient2,
        colors: [MagicColors.magicWhiteDark, MagicColors.magicBlackDark],
      );

  factory HeartStyle.izzet() => const HeartStyle(
        id: 'izzet',
        name: 'Izzet',
        type: HeartStyleType.gradient2,
        colors: [MagicColors.magicBlueDark, MagicColors.magicRedDark],
      );

  factory HeartStyle.dimir() => const HeartStyle(
        id: 'dimir',
        name: 'Dimir',
        type: HeartStyleType.gradient2,
        colors: [MagicColors.magicBlueDark, MagicColors.magicBlackDark],
      );

  factory HeartStyle.rakdos() => const HeartStyle(
        id: 'rakdos',
        name: 'Rakdos',
        type: HeartStyleType.gradient2,
        colors: [MagicColors.magicBlackDark, MagicColors.magicRedDark],
      );

  factory HeartStyle.golgari() => const HeartStyle(
        id: 'golgari',
        name: 'Golgari',
        type: HeartStyleType.gradient2,
        colors: [MagicColors.magicBlackDark, MagicColors.magicGreenDark],
      );

  factory HeartStyle.gruul() => const HeartStyle(
        id: 'gruul',
        name: 'Gruul',
        type: HeartStyleType.gradient2,
        colors: [MagicColors.magicRedDark, MagicColors.magicGreenDark],
      );

  factory HeartStyle.boros() => const HeartStyle(
        id: 'boros',
        name: 'Boros',
        type: HeartStyleType.gradient2,
        colors: [MagicColors.magicRedDark, MagicColors.magicWhiteDark],
      );

  factory HeartStyle.selesnya() => const HeartStyle(
        id: 'selesnya',
        name: 'Selesnya',
        type: HeartStyleType.gradient2,
        colors: [MagicColors.magicGreenDark, MagicColors.magicWhiteDark],
      );

  factory HeartStyle.simic() => const HeartStyle(
        id: 'simic',
        name: 'Simic',
        type: HeartStyleType.gradient2,
        colors: [MagicColors.magicGreenDark, MagicColors.magicBlueDark],
      );

  // Shard hearts (5 three-color combinations)
  factory HeartStyle.esper() => const HeartStyle(
        id: 'esper',
        name: 'Esper',
        type: HeartStyleType.gradient3,
        colors: [
          MagicColors.magicWhiteDark,
          MagicColors.magicBlueDark,
          MagicColors.magicBlackDark,
        ],
      );

  factory HeartStyle.grixis() => const HeartStyle(
        id: 'grixis',
        name: 'Grixis',
        type: HeartStyleType.gradient3,
        colors: [
          MagicColors.magicBlueDark,
          MagicColors.magicBlackDark,
          MagicColors.magicRedDark,
        ],
      );

  factory HeartStyle.jund() => const HeartStyle(
        id: 'jund',
        name: 'Jund',
        type: HeartStyleType.gradient3,
        colors: [
          MagicColors.magicBlackDark,
          MagicColors.magicRedDark,
          MagicColors.magicGreenDark,
        ],
      );

  factory HeartStyle.naya() => const HeartStyle(
        id: 'naya',
        name: 'Naya',
        type: HeartStyleType.gradient3,
        colors: [
          MagicColors.magicRedDark,
          MagicColors.magicGreenDark,
          MagicColors.magicWhiteDark,
        ],
      );

  factory HeartStyle.bant() => const HeartStyle(
        id: 'bant',
        name: 'Bant',
        type: HeartStyleType.gradient3,
        colors: [
          MagicColors.magicGreenDark,
          MagicColors.magicWhiteDark,
          MagicColors.magicBlueDark,
        ],
      );

  // Wedge hearts (5 three-color combinations)
  factory HeartStyle.abzan() => const HeartStyle(
        id: 'abzan',
        name: 'Abzan',
        type: HeartStyleType.gradient3,
        colors: [
          MagicColors.magicWhiteDark,
          MagicColors.magicBlackDark,
          MagicColors.magicGreenDark,
        ],
      );

  factory HeartStyle.jeskai() => const HeartStyle(
        id: 'jeskai',
        name: 'Jeskai',
        type: HeartStyleType.gradient3,
        colors: [
          MagicColors.magicBlueDark,
          MagicColors.magicRedDark,
          MagicColors.magicWhiteDark,
        ],
      );

  factory HeartStyle.sultai() => const HeartStyle(
        id: 'sultai',
        name: 'Sultai',
        type: HeartStyleType.gradient3,
        colors: [
          MagicColors.magicBlackDark,
          MagicColors.magicGreenDark,
          MagicColors.magicBlueDark,
        ],
      );

  factory HeartStyle.mardu() => const HeartStyle(
        id: 'mardu',
        name: 'Mardu',
        type: HeartStyleType.gradient3,
        colors: [
          MagicColors.magicRedDark,
          MagicColors.magicWhiteDark,
          MagicColors.magicBlackDark,
        ],
      );

  factory HeartStyle.temur() => const HeartStyle(
        id: 'temur',
        name: 'Temur',
        type: HeartStyleType.gradient3,
        colors: [
          MagicColors.magicGreenDark,
          MagicColors.magicBlueDark,
          MagicColors.magicRedDark,
        ],
      );

  // Special rainbow heart (default)
  factory HeartStyle.rainbow() => const HeartStyle(
        id: 'rainbow',
        name: 'Rainbow',
        type: HeartStyleType.gradient3,
        colors: [
          MagicColors.magicRedDark,
          Color(0xFFFFD700), // Yellow/Gold
          MagicColors.magicBlueDark,
        ],
      );

  /// Returns all available heart styles (25 Magic color combinations + 1 rainbow)
  static List<HeartStyle> getAllStyles() {
    return [
      // Mono-color (5)
      HeartStyle.white(),
      HeartStyle.blue(),
      HeartStyle.black(),
      HeartStyle.red(),
      HeartStyle.green(),

      // Guilds (10)
      HeartStyle.azorius(),
      HeartStyle.orzhov(),
      HeartStyle.izzet(),
      HeartStyle.dimir(),
      HeartStyle.rakdos(),
      HeartStyle.golgari(),
      HeartStyle.gruul(),
      HeartStyle.boros(),
      HeartStyle.selesnya(),
      HeartStyle.simic(),

      // Shards (5)
      HeartStyle.esper(),
      HeartStyle.grixis(),
      HeartStyle.jund(),
      HeartStyle.naya(),
      HeartStyle.bant(),

      // Wedges (5)
      HeartStyle.abzan(),
      HeartStyle.jeskai(),
      HeartStyle.sultai(),
      HeartStyle.mardu(),
      HeartStyle.temur(),

      // Special (1)
      HeartStyle.rainbow(),
    ];
  }
}
