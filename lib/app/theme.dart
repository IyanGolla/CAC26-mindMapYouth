import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Warm paper, coral actions, leafy green accents.
const coral = Color(0xFFF47C48);
const _onCoral = Color(0xFF2A1A12);
const leafGreen = Color(0xFF6E9B52);
const leafGreenDark = Color(0xFF3F6B3A);

/// System serif for headings, so no font is downloaded at runtime.
String get serifFamily =>
    defaultTargetPlatform == TargetPlatform.iOS ? 'Georgia' : 'serif';

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(seedColor: coral, brightness: brightness)
      .copyWith(
    // Used for text, icons and outlines, so it is darker than the button coral.
    primary: dark ? const Color(0xFFFFB692) : const Color(0xFFA23E12),
    onPrimary: dark ? const Color(0xFF3A1708) : Colors.white,
    primaryContainer: dark ? const Color(0xFF6B3218) : const Color(0xFFF9CDB6),
    onPrimaryContainer: dark ? const Color(0xFFFFDBCB) : const Color(0xFF3A1D0E),
    secondaryContainer: dark ? const Color(0xFF55402F) : const Color(0xFFF7D9C4),
    onSecondaryContainer: dark ? const Color(0xFFFBE3D3) : const Color(0xFF2A1A12),
    tertiary: dark ? const Color(0xFFA9D18E) : leafGreenDark,
    surface: dark ? const Color(0xFF2A221C) : const Color(0xFFEDE3D0),
    onSurface: dark ? const Color(0xFFF1E6D6) : const Color(0xFF2A211B),
    onSurfaceVariant: dark ? const Color(0xFFD8C8B4) : const Color(0xFF4F4338),
    surfaceContainerLowest: dark ? const Color(0xFF211A15) : const Color(0xFFFBF6EC),
    surfaceContainerLow: dark ? const Color(0xFF2F2620) : const Color(0xFFF6EFE1),
    surfaceContainer: dark ? const Color(0xFF342B24) : const Color(0xFFF3EBDB),
    surfaceContainerHigh: dark ? const Color(0xFF3A3028) : const Color(0xFFF6EFE1),
    surfaceContainerHighest: dark ? const Color(0xFF453A31) : const Color(0xFFE4D8C2),
    outline: dark ? const Color(0xFFB7A692) : const Color(0xFF4A3D32),
    outlineVariant: dark ? const Color(0xFF5A4C40) : const Color(0xFFCDBFA8),
    inverseSurface: dark ? const Color(0xFFF1E6D6) : const Color(0xFF2A211B),
    onInverseSurface: dark ? const Color(0xFF2A221C) : const Color(0xFFF6EFE1),
  );

  final base = Typography.material2021(colorScheme: scheme);
  final text = (dark ? base.white : base.black)
      .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  TextStyle? serif(TextStyle? s) => s?.copyWith(
        fontFamily: serifFamily,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      );

  // Typography styles carry no size until ThemeData merges them, so set one.
  final barTitle = TextStyle(
    fontFamily: serifFamily,
    fontWeight: FontWeight.w700,
    fontSize: 22,
    color: scheme.onSurface,
  );

  const pill = StadiumBorder();
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: scheme.surface,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    textTheme: text.copyWith(
      headlineMedium: serif(text.headlineMedium),
      headlineSmall: serif(text.headlineSmall),
      titleLarge: serif(text.titleLarge),
      bodyMedium: text.bodyMedium?.copyWith(fontSize: 16),
      bodyLarge: text.bodyLarge?.copyWith(fontSize: 17),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleTextStyle: barTitle,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerHigh,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: coral,
        foregroundColor: _onCoral,
        minimumSize: const Size(48, 52),
        shape: pill,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 52),
        shape: pill,
        side: BorderSide(color: scheme.outline),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      contentPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(28)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(color: scheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: pill,
      side: BorderSide(color: scheme.outline),
      backgroundColor: Colors.transparent,
      selectedColor: scheme.secondaryContainer,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerHighest,
      surfaceTintColor: Colors.transparent,
      indicatorColor: coral,
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? _onCoral
                : scheme.onSurfaceVariant,
          )),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: barTitle,
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant),
  );
}

/// Softer fill for secondary actions (the filled-button theme is coral).
ButtonStyle tonalButtonStyle(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return FilledButton.styleFrom(
    backgroundColor: scheme.secondaryContainer,
    foregroundColor: scheme.onSecondaryContainer,
  );
}

/// The one high-contrast action in the app: reaching a person now.
ButtonStyle crisisButtonStyle(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return FilledButton.styleFrom(
    backgroundColor: dark ? const Color(0xFFFFB4AB) : const Color(0xFFA3201A),
    foregroundColor: dark ? const Color(0xFF690005) : Colors.white,
    minimumSize: const Size(48, 56),
    shape: const StadiumBorder(),
    textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
  );
}
