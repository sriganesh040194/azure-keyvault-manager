import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF0078D4);
  static const Color secondaryColor = Color(0xFF107C10);
  static const Color errorColor = Color(0xFFD13438);
  static const Color warningColor = Color(0xFFFF8C00);
  static const Color successColor = Color(0xFF107C10);
  
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF1E1E1E);
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: surfaceColor,
        error: errorColor,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: backgroundLight,
        foregroundColor: Colors.black87,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: surfaceColor,
        selectedIconTheme: IconThemeData(
          color: primaryColor,
          size: 24,
        ),
        unselectedIconTheme: IconThemeData(
          color: Colors.grey,
          size: 24,
        ),
        selectedLabelTextStyle: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: Colors.grey,
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
        dataRowMinHeight: 48,
        dataRowMaxHeight: 64,
        columnSpacing: 24,
        horizontalMargin: 16,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[100],
        selectedColor: primaryColor.withOpacity(0.2),
        labelStyle: const TextStyle(fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        surface: const Color(0xFF2D2D2D),
        error: errorColor,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: backgroundDark,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: const Color(0xFF2D2D2D),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: const Color(0xFF3D3D3D),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Color(0xFF2D2D2D),
        selectedIconTheme: IconThemeData(
          color: primaryColor,
          size: 24,
        ),
        unselectedIconTheme: IconThemeData(
          color: Colors.grey,
          size: 24,
        ),
        selectedLabelTextStyle: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: Colors.grey,
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(const Color(0xFF3D3D3D)),
        dataRowMinHeight: 48,
        dataRowMaxHeight: 64,
        columnSpacing: 24,
        horizontalMargin: 16,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF3D3D3D),
        selectedColor: primaryColor.withOpacity(0.3),
        labelStyle: const TextStyle(fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class AppIcons {
  static const IconData keyVault = Symbols.key;
  static const IconData secret = Symbols.password;
  static const IconData key = Symbols.vpn_key;
  static const IconData certificate = Icons.verified;
  static const IconData dashboard = Symbols.dashboard;
  static const IconData settings = Symbols.settings;
  static const IconData security = Symbols.security;
  static const IconData audit = Symbols.history;
  static const IconData add = Symbols.add;
  static const IconData edit = Symbols.edit;
  static const IconData delete = Symbols.delete;
  static const IconData refresh = Symbols.refresh;
  static const IconData copy = Symbols.content_copy;
  static const IconData download = Symbols.download;
  static const IconData upload = Symbols.upload;
  static const IconData visibility = Symbols.visibility;
  static const IconData visibilityOff = Symbols.visibility_off;
  static const IconData warning = Symbols.warning;
  static const IconData error = Symbols.error;
  static const IconData success = Symbols.check_circle;
  static const IconData info = Symbols.info;
  static const IconData search = Symbols.search;
  static const IconData filter = Symbols.filter_list;
  static const IconData sort = Symbols.sort;
  static const IconData more = Symbols.more_vert;
  static const IconData close = Symbols.close;
  static const IconData menu = Symbols.menu;
  static const IconData logout = Symbols.logout;
  static const IconData account = Symbols.account_circle;
  static const IconData login = Symbols.login;
  static const IconData terminal = Symbols.terminal;
  static const IconData link = Symbols.link;
  static const IconData openInNew = Symbols.open_in_new;
  static const IconData timer = Symbols.timer;
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppBorderRadius {
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double xxl = 24.0;
}