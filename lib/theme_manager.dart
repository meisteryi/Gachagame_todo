import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeType { current, classic }

class AppTheme {
  static final ValueNotifier<ThemeType> themeNotifier =
      ValueNotifier<ThemeType>(ThemeType.current);

  static const String _themePrefKey = 'selected_app_theme';

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themePrefKey);
    if (themeName != null) {
      if (themeName == 'classic') {
        themeNotifier.value = ThemeType.classic;
      } else {
        themeNotifier.value = ThemeType.current;
      }
    }
  }

  static Future<void> setTheme(ThemeType type) async {
    themeNotifier.value = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePrefKey, type == ThemeType.classic ? 'classic' : 'current');
  }

  static ThemeType get currentTheme => themeNotifier.value;

  // --- UI Colors ---

  static Color get borderColor =>
      currentTheme == ThemeType.current ? const Color(0xFF212123) : const Color(0xFF333333);

  static Color get panelBg =>
      currentTheme == ThemeType.current ? const Color(0xFFF2F0E5) : Colors.white;

  static Color get splashBg =>
      currentTheme == ThemeType.current ? const Color(0xFF68C2D3) : const Color(0xFFB4D8E7);

  static Color get themeSeed =>
      currentTheme == ThemeType.current ? const Color(0xFFCF8ACB) : const Color(0xFFFFB7B2);

  static Color get selectedTabBg =>
      currentTheme == ThemeType.current ? const Color(0xFF68C2D3) : const Color(0xFFFFF3B0);

  static Color get unselectedTabBg =>
      currentTheme == ThemeType.current ? const Color(0xFFF2F0E5) : const Color(0xFFEEEEEE);

  static Color get selectedTabText =>
      currentTheme == ThemeType.current ? const Color(0xFF212123) : Colors.black;

  static Color get unselectedTabText =>
      currentTheme == ThemeType.current ? const Color(0xFF868188) : const Color(0xFF757575);

  static Color get meatBg =>
      currentTheme == ThemeType.current ? const Color(0xFFE5CEB4) : const Color(0xFFFFDAB9);

  static Color get supplementBg =>
      currentTheme == ThemeType.current ? const Color(0xFF8AB060) : const Color(0xFFA8E6CF);

  static Color get coinBg =>
      currentTheme == ThemeType.current ? const Color(0xFFEDE19E) : const Color(0xFFFFD166);

  static Color get feedButtonColor =>
      currentTheme == ThemeType.current ? const Color(0xFFD3A068) : Colors.orangeAccent;

  static Color get supplementButtonColor =>
      currentTheme == ThemeType.current ? const Color(0xFFCF8ACB) : Colors.pinkAccent;

  static Color get categoryEditButtonColor =>
      currentTheme == ThemeType.current ? const Color(0xFFC2D368) : Colors.lightGreenAccent;

  static Color get addTodoButtonColor =>
      currentTheme == ThemeType.current ? const Color(0xFFEDE19E) : Colors.yellowAccent;

  static List<Color> get aquariumGradient => currentTheme == ThemeType.current
      ? [const Color(0xFFB1C1D3), const Color(0xFF68C2D3)]
      : [const Color(0xFF81D4FA), const Color(0xFF0288D1)];

  static Color get tankWaterBg => currentTheme == ThemeType.current
      ? const Color(0xFF68C2D3).withValues(alpha: 0.35)
      : Colors.lightBlueAccent.withValues(alpha: 0.15);

  static Color get milestoneCompletedBg =>
      currentTheme == ThemeType.current ? const Color(0xFFEDC8C4) : const Color(0xFFFFB7B2);

  static Color get weeklyMilestoneProgressBg =>
      currentTheme == ThemeType.current ? const Color(0xFFEDE19E) : const Color(0xFFFFDAB9);

  static Color get weeklyMilestoneClaimButtonBg =>
      currentTheme == ThemeType.current ? const Color(0xFFD3A068) : Colors.yellowAccent;

  static Color get fishGachaMachineBg =>
      currentTheme == ThemeType.current ? const Color(0xFFCF8ACB) : const Color(0xFFFFB7B2);

  static Color get seaweedGachaMachineBg =>
      currentTheme == ThemeType.current ? const Color(0xFF85CAC5) : const Color(0xFFB4D8E7);

  static Color get fishGachaButton1x =>
      currentTheme == ThemeType.current ? const Color(0xFFEDC8C4) : const Color(0xFFFFC6D3);

  static Color get seaweedGachaButton1x =>
      currentTheme == ThemeType.current ? const Color(0xFFA8D8B9) : const Color(0xFFA8E6CF);

  static Color get fishGachaButton10x =>
      currentTheme == ThemeType.current ? const Color(0xFFFFAAA5) : const Color(0xFFFFB7B2);

  static Color get seaweedGachaButton10x =>
      currentTheme == ThemeType.current ? const Color(0xFF85CAC5) : const Color(0xFFB4D8E7);

  // --- Category Colors ---

  static Map<String, Color> get defaultCategoryColors => currentTheme == ThemeType.current
      ? {
          '일상': const Color(0xFF8AB060),
          '공부': const Color(0xFF68C2D3),
          '운동': const Color(0xFFCF8ACB),
          '업무': const Color(0xFFD3A068),
        }
      : {
          '일상': Colors.greenAccent,
          '공부': Colors.lightBlueAccent,
          '운동': Colors.redAccent,
          '업무': Colors.orangeAccent,
        };

  static List<Color> get availableCategoryColors => currentTheme == ThemeType.current
      ? [
          const Color(0xFF8AB060),
          const Color(0xFFC2D368),
          const Color(0xFF68C2D3),
          const Color(0xFFCF8ACB),
          const Color(0xFF6A536E),
          const Color(0xFFD3A068),
          const Color(0xFFE5CEB4),
          const Color(0xFF4B80CA),
          const Color(0xFFEDE19E),
        ]
      : [
          Colors.greenAccent,
          Colors.lightBlueAccent,
          Colors.redAccent,
          Colors.orangeAccent,
          Colors.purpleAccent,
          Colors.pinkAccent,
          Colors.yellowAccent,
          Colors.tealAccent,
          Colors.cyanAccent,
        ];

  // --- Emojis color palette ---

  static Map<String, Color> get emojiColors => currentTheme == ThemeType.current
      ? {
          '.': Colors.transparent,
          'y': const Color(0xFFEDE19E),
          'w': const Color(0xFFF2F0E5),
          'o': const Color(0xFFD3A068),
          'b': const Color(0xFF4B80CA),
          'c': const Color(0xFF68C2D3),
          'd': const Color(0xFF352B42),
          'm': const Color(0xFFA77B5B),
          'r': const Color(0xFFB45252),
          'g': const Color(0xFF8AB060),
          'l': const Color(0xFFC2D368),
          'p': const Color(0xFFE5CEB4),
          'k': const Color(0xFF212123),
          't': const Color(0xFFB2B47E),
          's': const Color(0xFFB8B5B9),
        }
      : {
          '.': Colors.transparent,
          'y': Colors.yellowAccent,
          'w': Colors.white,
          'o': Colors.orangeAccent,
          'b': Colors.blueAccent,
          'c': Colors.lightBlueAccent,
          'd': Colors.brown[800]!,
          'm': Colors.brown[400]!,
          'r': Colors.redAccent,
          'g': Colors.green,
          'l': Colors.lightGreen,
          'p': Colors.yellow[700]!,
          'k': Colors.black,
          't': Colors.orange[200]!,
          's': Colors.grey,
        };

  // --- Capsule colors for slot machine ---
  static List<Color> get gachaCapsuleColors => currentTheme == ThemeType.current
      ? [
          const Color(0xFFCF8ACB),
          const Color(0xFFEDE19E),
          const Color(0xFF68C2D3),
          const Color(0xFF8AB060),
          const Color(0xFFEDC8C4),
          const Color(0xFFE5CEB4),
        ]
      : [
          const Color(0xFFFFB7B2),
          const Color(0xFFFFF3B0),
          const Color(0xFFB4D8E7),
          const Color(0xFFA8E6CF),
          const Color(0xFFFFC6D3),
          const Color(0xFFFFDAB9),
        ];

  // --- Dynamic Fish Colors ---

  static Map<String, Color> getFishColors(String type, int level) {
    Color c1 = Colors.orangeAccent;
    Color c2 = Colors.transparent;

    if (currentTheme == ThemeType.current) {
      // Current pastel palette
      if (type == 'goldfish') {
        c1 = const Color(0xFFCF8ACB);
      } else if (type == 'mackerel') {
        c1 = const Color(0xFF4B80CA);
        c2 = const Color(0xFFB8B5B9);
      } else if (type == 'shark') {
        c1 = const Color(0xFF646365);
        c2 = const Color(0xFFF2F0E5);
      } else if (type == 'whale') {
        c1 = const Color(0xFF43436A);
        c2 = const Color(0xFF68C2D3);
      } else if (type == 'betta') {
        c1 = const Color(0xFFCF8ACB);
        c2 = const Color(0xFF68C2D3);
      } else if (type == 'nemo') {
        c1 = const Color(0xFFD3A068);
        c2 = const Color(0xFFF2F0E5);
      } else if (type == 'guppy') {
        c1 = const Color(0xFF68C2D3);
        c2 = const Color(0xFFCF8ACB);
      } else if (type == 'axolotl') {
        c1 = const Color(0xFFE5CEB4);
        c2 = const Color(0xFFCF8ACB);
      } else if (type == 'tuna') {
        c1 = const Color(0xFF868188);
        c2 = const Color(0xFF646365);
      } else if (type == 'shrimp') {
        c1 = const Color(0xFFD3A068);
        c2 = const Color(0xFFE5CEB4);
      } else if (type == 'seahorse') {
        c1 = const Color(0xFFD3A068);
        c2 = const Color(0xFFA77B5B);
      } else if (type == 'turtle') {
        c1 = const Color(0xFF8AB060);
        c2 = const Color(0xFF212123);
      } else if (type == 'jellyfish') {
        c1 = const Color(0xFFE5CEB4);
        c2 = const Color(0xFF5F556A);
      } else if (type == 'stingray') {
        c1 = const Color(0xFF868188);
        c2 = const Color(0xFFB8B5B9);
      } else if (type == 'carp') {
        c1 = const Color(0xFFF2F0E5);
        c2 = const Color(0xFFCF8ACB);
      } else if (type == 'crab') {
        c1 = const Color(0xFFE5CEB4);
        c2 = const Color(0xFFCF8ACB);
      } else if (type == 'whale_shark') {
        c1 = const Color(0xFF646365);
        c2 = const Color(0xFFF2F0E5);
      } else if (type == 'electric_eel') {
        c1 = const Color(0xFF646365);
        c2 = const Color(0xFFEDE19E);
      } else if (type == 'salmon') {
        c1 = const Color(0xFFE5CEB4);
        c2 = const Color(0xFFB8B5B9);
      } else {
        c1 = const Color(0xFFD3A068);
      }

      if (level >= 5) {
        if (type == 'goldfish') {
          c1 = const Color(0xFFEDE19E);
          c2 = const Color(0xFFD3A068);
        } else if (type == 'mackerel') {
          c1 = const Color(0xFF68C2D3);
          c2 = const Color(0xFFCF8ACB);
        } else if (type == 'shark') {
          c1 = const Color(0xFF212123);
          c2 = const Color(0xFFF2F0E5);
        } else if (type == 'whale') {
          c1 = const Color(0xFF212123);
          c2 = const Color(0xFFCF8ACB);
        } else if (type == 'betta') {
          c1 = const Color(0xFFEDE19E);
          c2 = const Color(0xFFCF8ACB);
        } else if (type == 'nemo') {
          c1 = const Color(0xFFEDE19E);
          c2 = const Color(0xFF212123);
        } else if (type == 'guppy') {
          c1 = const Color(0xFFCF8ACB);
          c2 = const Color(0xFFEDE19E);
        } else if (type == 'axolotl') {
          c1 = const Color(0xFFEDE19E);
          c2 = const Color(0xFFCF8ACB);
        } else if (type == 'tuna') {
          c1 = const Color(0xFFF2F0E5);
          c2 = const Color(0xFF68C2D3);
        } else if (type == 'shrimp') {
          c1 = const Color(0xFFCF8ACB);
          c2 = const Color(0xFF4B80CA);
        } else if (type == 'seahorse') {
          c1 = const Color(0xFFEDE19E);
          c2 = const Color(0xFF4B80CA);
        } else if (type == 'turtle') {
          c1 = const Color(0xFFEDE19E);
          c2 = const Color(0xFFD3A068);
        } else if (type == 'jellyfish') {
          c1 = const Color(0xFFEDE19E);
          c2 = const Color(0xFF68C2D3);
        } else if (type == 'stingray') {
          c1 = const Color(0xFF4B80CA);
          c2 = const Color(0xFF68C2D3);
        } else if (type == 'carp') {
          c1 = const Color(0xFFD3A068);
          c2 = const Color(0xFF80493A);
        } else if (type == 'crab') {
          c1 = const Color(0xFFB45252);
          c2 = const Color(0xFFD3A068);
        } else if (type == 'whale_shark') {
          c1 = const Color(0xFF212123);
          c2 = const Color(0xFF68C2D3);
        } else if (type == 'electric_eel') {
          c1 = const Color(0xFF212123);
          c2 = const Color(0xFF68C2D3);
        } else if (type == 'salmon') {
          c1 = const Color(0xFFD3A068);
          c2 = const Color(0xFFF2F0E5);
        } else {
          c1 = const Color(0xFFEDE19E);
          c2 = const Color(0xFFD3A068);
        }
      }
    } else {
      // Classic vibrant retro colors
      if (type == 'goldfish') {
        c1 = Colors.redAccent;
      } else if (type == 'mackerel') {
        c1 = Colors.blue;
        c2 = Colors.grey[300]!;
      } else if (type == 'shark') {
        c1 = Colors.blueGrey[800]!;
        c2 = Colors.white;
      } else if (type == 'whale') {
        c1 = Colors.indigo[600]!;
        c2 = Colors.lightBlue[200]!;
      } else if (type == 'betta') {
        c1 = Colors.pinkAccent;
        c2 = Colors.cyanAccent;
      } else if (type == 'nemo') {
        c1 = Colors.deepOrange;
        c2 = Colors.white;
      } else if (type == 'guppy') {
        c1 = Colors.cyanAccent;
        c2 = Colors.purpleAccent;
      } else if (type == 'axolotl') {
        c1 = Colors.pink[200]!;
        c2 = Colors.pinkAccent;
      } else if (type == 'tuna') {
        c1 = Colors.blueGrey[300]!;
        c2 = Colors.indigo[800]!;
      } else if (type == 'shrimp') {
        c1 = Colors.deepOrangeAccent;
        c2 = Colors.orange[200]!;
      } else if (type == 'seahorse') {
        c1 = Colors.amber;
        c2 = Colors.orange;
      } else if (type == 'turtle') {
        c1 = Colors.green;
        c2 = Colors.brown[700]!;
      } else if (type == 'jellyfish') {
        c1 = Colors.pinkAccent[100]!;
        c2 = Colors.purpleAccent[100]!;
      } else if (type == 'stingray') {
        c1 = Colors.blueGrey;
        c2 = Colors.grey[400]!;
      } else if (type == 'carp') {
        c1 = Colors.white;
        c2 = Colors.redAccent;
      } else if (type == 'crab') {
        c1 = Colors.orangeAccent;
        c2 = Colors.redAccent;
      } else if (type == 'whale_shark') {
        c1 = const Color(0xFF1E3A8A);
        c2 = Colors.white;
      } else if (type == 'electric_eel') {
        c1 = const Color(0xFF2C3E50);
        c2 = Colors.yellowAccent;
      } else if (type == 'salmon') {
        c1 = const Color(0xFFFA8072);
        c2 = const Color(0xFFE2E8F0);
      } else {
        c1 = Colors.orangeAccent;
      }

      if (level >= 5) {
        if (type == 'goldfish') {
          c1 = Colors.amberAccent[400]!;
          c2 = Colors.deepOrangeAccent;
        } else if (type == 'mackerel') {
          c1 = Colors.cyanAccent;
          c2 = Colors.purpleAccent;
        } else if (type == 'shark') {
          c1 = const Color(0xFF0B132B);
          c2 = const Color(0xFFE0E1DD);
        } else if (type == 'whale') {
          c1 = Colors.purple[800]!;
          c2 = Colors.pinkAccent;
        } else if (type == 'betta') {
          c1 = Colors.amberAccent;
          c2 = Colors.deepPurpleAccent;
        } else if (type == 'nemo') {
          c1 = Colors.limeAccent;
          c2 = Colors.black;
        } else if (type == 'guppy') {
          c1 = Colors.redAccent;
          c2 = Colors.yellowAccent;
        } else if (type == 'axolotl') {
          c1 = Colors.yellow[300]!;
          c2 = Colors.redAccent;
        } else if (type == 'tuna') {
          c1 = Colors.grey[200]!;
          c2 = Colors.cyanAccent;
        } else if (type == 'shrimp') {
          c1 = Colors.cyan[200]!;
          c2 = Colors.blueAccent;
        } else if (type == 'seahorse') {
          c1 = Colors.lightGreenAccent;
          c2 = Colors.indigoAccent;
        } else if (type == 'turtle') {
          c1 = Colors.tealAccent;
          c2 = Colors.amber[800]!;
        } else if (type == 'jellyfish') {
          c1 = Colors.yellowAccent;
          c2 = Colors.cyanAccent;
        } else if (type == 'stingray') {
          c1 = Colors.indigoAccent;
          c2 = Colors.cyanAccent;
        } else if (type == 'carp') {
          c1 = const Color(0xFFFFD700);
          c2 = const Color(0xFFD32F2F);
        } else if (type == 'crab') {
          c1 = const Color(0xFFE63946);
          c2 = const Color(0xFFE5A93C);
        } else if (type == 'whale_shark') {
          c1 = const Color(0xFF0F172A);
          c2 = const Color(0xFF38BDF8);
        } else if (type == 'electric_eel') {
          c1 = const Color(0xFF1E293B);
          c2 = Colors.cyanAccent;
        } else if (type == 'salmon') {
          c1 = const Color(0xFFE07A5F);
          c2 = const Color(0xFFF1F5F9);
        } else {
          c1 = Colors.yellowAccent;
          c2 = Colors.deepOrangeAccent;
        }
      }
    }

    return {'c1': c1, 'c2': c2};
  }

  // --- Dynamic Seaweed Colors ---

  static Map<String, Color> getSeaweedColors(String type) {
    Color c1 = Colors.green;
    Color c2 = Colors.lightGreen;

    if (currentTheme == ThemeType.current) {
      if (type == 'red_algae') {
        c1 = const Color(0xFFB45252);
        c2 = const Color(0xFFCF8ACB);
      } else if (type == 'kelp') {
        c1 = const Color(0xFF646365);
        c2 = const Color(0xFF8AB060);
      } else if (type == 'coral') {
        c1 = const Color(0xFFCF8ACB);
        c2 = const Color(0xFF6A536E);
      } else if (type == 'anemone') {
        c1 = const Color(0xFF43436A);
        c2 = const Color(0xFF646365);
      } else if (type == 'purple_kelp') {
        c1 = const Color(0xFF646365);
        c2 = const Color(0xFF212123);
      } else if (type == 'short_grass') {
        c1 = const Color(0xFFEDE19E);
        c2 = const Color(0xFF8AB060);
      } else if (type == 'blue_coral') {
        c1 = const Color(0xFF4B80CA);
        c2 = const Color(0xFF68C2D3);
      } else if (type == 'tall_bamboo') {
        c1 = const Color(0xFFC2D368);
        c2 = const Color(0xFF8AB060);
      } else if (type == 'golden_leaf') {
        c1 = const Color(0xFFD3A068);
        c2 = const Color(0xFFA77B5B);
      } else {
        // green_algae (default)
        c1 = const Color(0xFF8AB060);
        c2 = const Color(0xFFC2D368);
      }
    } else {
      if (type == 'red_algae') {
        c1 = Colors.red;
        c2 = Colors.redAccent;
      } else if (type == 'kelp') {
        c1 = Colors.green[800]!;
        c2 = Colors.green[600]!;
      } else if (type == 'coral') {
        c1 = Colors.pinkAccent;
        c2 = Colors.pink;
      } else if (type == 'anemone') {
        c1 = Colors.purpleAccent;
        c2 = Colors.deepPurpleAccent;
      } else if (type == 'purple_kelp') {
        c1 = Colors.purple;
        c2 = Colors.deepPurple;
      } else if (type == 'short_grass') {
        c1 = Colors.lightGreenAccent;
        c2 = Colors.green;
      } else if (type == 'blue_coral') {
        c1 = Colors.blueAccent;
        c2 = Colors.lightBlue;
      } else if (type == 'tall_bamboo') {
        c1 = Colors.greenAccent;
        c2 = Colors.teal;
      } else if (type == 'golden_leaf') {
        c1 = Colors.amber;
        c2 = Colors.orange;
      } else {
        c1 = Colors.green;
        c2 = Colors.lightGreen;
      }
    }

    return {'c1': c1, 'c2': c2};
  }

  // --- Dynamic Decoration Palettes ---

  static List<Color> getDecorationPalette(String type) {
    if (currentTheme == ThemeType.current) {
      switch (type) {
        case 'ammonite':
          return [
            Colors.transparent,
            const Color(0xFFA77B5B),
            const Color(0xFFD3A068),
            const Color(0xFFF2F0E5),
            const Color(0xFF212123),
          ];
        case 'basalt':
          return [
            Colors.transparent,
            const Color(0xFF45444F),
            const Color(0xFFB8B5B9),
            const Color(0xFF868188),
            const Color(0xFF212123),
          ];
        case 'spongebob_house':
          return [
            Colors.transparent,
            const Color(0xFFD3A068),
            const Color(0xFF8AB060),
            const Color(0xFF212123),
            const Color(0xFFEDE19E),
          ];
        case 'sunken_ship':
        default:
          return [
            Colors.transparent,
            const Color(0xFF45444F),
            const Color(0xFFA77B5B),
            const Color(0xFF8AB060),
            const Color(0xFFD3A068),
            const Color(0xFF212123),
          ];
      }
    } else {
      switch (type) {
        case 'ammonite':
          return [
            Colors.transparent,
            const Color(0xFF5D3F1E),
            const Color(0xFFC69752),
            const Color(0xFFF3D299),
            const Color(0xFF3E2713),
          ];
        case 'basalt':
          return [
            Colors.transparent,
            const Color(0xFF2E2E3E),
            const Color(0xFF4E5066),
            const Color(0xFF7A7D9A),
            const Color(0xFF1B1B26),
          ];
        case 'spongebob_house':
          return [
            Colors.transparent,
            const Color(0xFFD4841A),
            const Color(0xFF2D8B18),
            const Color(0xFF8B4A00),
            const Color(0xFFF5DC60),
          ];
        case 'sunken_ship':
        default:
          return [
            Colors.transparent,
            const Color(0xFF3E2713),
            const Color(0xFF6B4527),
            const Color(0xFF2A483A),
            const Color(0xFF9E7047),
            const Color(0xFF1E1108),
          ];
      }
    }
  }

  // --- Dynamic shop deco item display color ---
  static Color getDecoShopColor(String type) {
    if (currentTheme == ThemeType.current) {
      switch (type) {
        case 'ammonite': return const Color(0xFFD3A068);
        case 'basalt': return const Color(0xFF45444F);
        case 'spongebob_house': return const Color(0xFFEDE19E);
        case 'sunken_ship':
        default:
          return const Color(0xFFA77B5B);
      }
    } else {
      switch (type) {
        case 'ammonite': return const Color(0xFFBF8C3A);
        case 'basalt': return const Color(0xFF606060);
        case 'spongebob_house': return const Color(0xFFD4841A);
        case 'sunken_ship':
        default:
          return const Color(0xFF8B6340);
      }
    }
  }
}
