import 'package:flutter/material.dart';

class AppTheme {
  // Calming Blue/Green Color Palette
  static const primaryBlue = Color(0xFF4A90E2);
  static const secondaryTeal = Color(0xFF4ECDC4);
  static const lightTeal = Color(0xFF7ED6DF);
  static const softGreen = Color(0xFF58D68D);
  static const backgroundColor = Color(0xFFF8FBFF);
  static const surfaceColor = Color(0xFFFFFFFF);
  static const onSurfaceLight = Color(0xFF1A1A1A);
  static const onSurfaceDark = Color(0xFFE8F4F8);
  
  static final ColorScheme _lightColorScheme = ColorScheme.fromSeed(
    seedColor: primaryBlue,
    brightness: Brightness.light,
    primary: primaryBlue,
    secondary: secondaryTeal,
    tertiary: softGreen,
    surface: surfaceColor,
    background: backgroundColor,
    onSurface: onSurfaceLight,
  );
  
  static final ColorScheme _darkColorScheme = ColorScheme.fromSeed(
    seedColor: primaryBlue,
    brightness: Brightness.dark,
    primary: lightTeal,
    secondary: secondaryTeal,
    tertiary: softGreen,
    surface: const Color(0xFF1A1A1A),
    background: const Color(0xFF121212),
    onSurface: onSurfaceDark,
  );
  
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _lightColorScheme,
    appBarTheme: AppBarTheme(
      backgroundColor: _lightColorScheme.surface,
      foregroundColor: _lightColorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: _lightColorScheme.onSurface,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _lightColorScheme.surface,
      indicatorColor: _lightColorScheme.primary.withOpacity(0.15),
      labelTextStyle: MaterialStateProperty.resolveWith<TextStyle>((states) {
        if (states.contains(MaterialState.selected)) {
          return TextStyle(color: _lightColorScheme.primary, fontSize: 12, fontWeight: FontWeight.w600);
        }
        return TextStyle(color: _lightColorScheme.onSurface.withOpacity(0.6), fontSize: 12);
      }),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _lightColorScheme.surface,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lightColorScheme.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _lightColorScheme.secondary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _darkColorScheme,
    appBarTheme: AppBarTheme(
      backgroundColor: _darkColorScheme.surface,
      foregroundColor: _darkColorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      titleTextStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: _darkColorScheme.onSurface,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _darkColorScheme.surface,
      indicatorColor: _darkColorScheme.primary.withOpacity(0.15),
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: _darkColorScheme.surface,
    ),
  );
}
