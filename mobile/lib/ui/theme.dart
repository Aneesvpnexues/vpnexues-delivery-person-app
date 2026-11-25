import 'package:flutter/material.dart';

import 'design.dart';

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: C.green, brightness: Brightness.light).copyWith(
    primary: C.green,
    onPrimary: Colors.white,
    secondary: C.yellow,
    onSecondary: C.green,
    surface: Colors.white,
    onSurface: C.ink,
    error: C.danger,
    outline: C.line,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: C.bg,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: C.bg,
      foregroundColor: C.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w700, color: C.ink),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontFamily: 'Inter', color: C.ink),
      bodyLarge: TextStyle(fontFamily: 'Inter', color: C.ink),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: false,
      fillColor: Colors.transparent,
      isDense: true,
      contentPadding: EdgeInsets.zero,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
    ),
    dividerColor: C.line,
    snackBarTheme: SnackBarThemeData(
      backgroundColor: C.green,
      contentTextStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titleTextStyle: const TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: C.ink),
      contentTextStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, color: C.muted, height: 1.4),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: C.green,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: C.green,
        side: const BorderSide(color: C.green, width: 2),
        minimumSize: const Size.fromHeight(56),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: C.green,
        textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: C.green),
  );
}

ThemeData buildDarkTheme() {
  const background = Color(0xFF101812);
  const surface = Color(0xFF1B2720);
  const primary = Color(0xFF9BCB78);
  const textPrimary = Color(0xFFF1F5EF);
  const textSecondary = Color(0xFFB0BDB3);
  const border = Color(0xFF35443A);

  final scheme = ColorScheme.fromSeed(
    seedColor: C.green,
    brightness: Brightness.dark,
  ).copyWith(
    primary: primary,
    onPrimary: const Color(0xFF142018),
    secondary: C.yellow,
    onSecondary: const Color(0xFF142018),
    surface: surface,
    onSurface: textPrimary,
    error: const Color(0xFFFF7777),
    outline: border,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: background,
    cardColor: surface,
    dividerColor: border,

    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: textPrimary,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
    ),

    textTheme: const TextTheme(
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        color: textPrimary,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        color: textPrimary,
      ),
    ),

    inputDecorationTheme: const InputDecorationTheme(
      filled: false,
      fillColor: Colors.transparent,
      isDense: true,
      contentPadding: EdgeInsets.zero,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
    ),

    snackBarTheme: const SnackBarThemeData(
      backgroundColor: surface,
      contentTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        color: textPrimary,
      ),
      behavior: SnackBarBehavior.floating,
    ),

    dialogTheme: const DialogThemeData(
      backgroundColor: surface,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textPrimary,
      ),
      contentTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        color: textSecondary,
      ),
    ),

    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primary,
    ),
  );
}