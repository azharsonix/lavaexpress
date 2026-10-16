import 'package:flutter/material.dart';

/// Tema de LavaExpress (claro y oscuro).
/// Paleta neutra con un solo color de acento, bordes finos y esquinas moderadas.
class AppTheme {
  /// Azul institucional (logotipo).
  static const semilla = Color(0xFF1D4ED8);

  /// Azul marino de la marca: fondos de fotos y degradados.
  static const marino = Color(0xFF0B1F4D);

  /// Acento agua (detalles de la marca, nunca para texto sobre blanco).
  static const agua = Color(0xFF38BDF8);

  /// Tipografía de la marca (assets/fuentes).
  static const fuente = 'Jakarta';

  /// Radio estándar de tarjetas, botones y campos.
  static const radio = 8.0;

  // Paleta base: azul de acento sobre grises "slate".
  static ThemeData claro() => _construir(
    ColorScheme.fromSeed(seedColor: semilla, brightness: Brightness.light).copyWith(
      primary: const Color(0xFF2563EB),
      onPrimary: Colors.white,
      error: const Color(0xFFDC2626),
      errorContainer: const Color(0xFFFEE2E2),
      onErrorContainer: const Color(0xFF7F1D1D),
      surface: Colors.white,
      onSurface: const Color(0xFF0F172A),
      onSurfaceVariant: const Color(0xFF64748B),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFF8FAFC),
      surfaceContainer: const Color(0xFFF1F5F9),
      surfaceContainerHigh: const Color(0xFFE9EEF4),
      surfaceContainerHighest: const Color(0xFFE2E8F0),
      outline: const Color(0xFF94A3B8),
      outlineVariant: const Color(0xFFE2E8F0),
      inverseSurface: const Color(0xFF1E293B),
      onInverseSurface: const Color(0xFFF1F5F9),
    ),
    fondo: const Color(0xFFF1F5F9),
  );

  static ThemeData oscuro() => _construir(
    ColorScheme.fromSeed(seedColor: semilla, brightness: Brightness.dark).copyWith(
      primary: const Color(0xFF3B82F6),
      onPrimary: Colors.white,
      error: const Color(0xFFF87171),
      errorContainer: const Color(0xFF450A0A),
      onErrorContainer: const Color(0xFFFECACA),
      surface: const Color(0xFF111827),
      onSurface: const Color(0xFFE2E8F0),
      onSurfaceVariant: const Color(0xFF94A3B8),
      surfaceContainerLowest: const Color(0xFF0B1120),
      surfaceContainerLow: const Color(0xFF151E2E),
      surfaceContainer: const Color(0xFF1A2333),
      surfaceContainerHigh: const Color(0xFF1E293B),
      surfaceContainerHighest: const Color(0xFF273449),
      outline: const Color(0xFF475569),
      outlineVariant: const Color(0xFF1F2A3C),
      inverseSurface: const Color(0xFFE2E8F0),
      onInverseSurface: const Color(0xFF0F172A),
    ),
    fondo: const Color(0xFF0B1120),
  );

  static ThemeData _construir(ColorScheme s, {required Color fondo}) {
    final base = ThemeData(colorScheme: s, useMaterial3: true, fontFamily: fuente);
    final texto = base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
      titleLarge: base.textTheme.titleLarge?.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: base.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelMedium: base.textTheme.labelMedium?.copyWith(letterSpacing: 0.2),
    );
    final redondeo = BorderRadius.circular(radio);
    final borde = BorderSide(color: s.outlineVariant);

    return base.copyWith(
      textTheme: texto,
      scaffoldBackgroundColor: fondo,
      dividerTheme: DividerThemeData(color: s.outlineVariant, space: 1, thickness: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: s.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        shape: Border(bottom: borde),
        titleTextStyle: TextStyle(fontFamily: fuente, fontSize: 18, fontWeight: FontWeight.w600, color: s.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: s.surface,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: redondeo, side: borde),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: s.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: redondeo,
          borderSide: BorderSide(color: s.outline.withValues(alpha: 0.6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: redondeo,
          borderSide: BorderSide(color: s.outline.withValues(alpha: 0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: redondeo,
          borderSide: BorderSide(color: s.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: redondeo,
          borderSide: BorderSide(color: s.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: redondeo,
          borderSide: BorderSide(color: s.error, width: 1.5),
        ),
        prefixIconColor: s.onSurfaceVariant,
        suffixIconColor: s.onSurfaceVariant,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: redondeo),
          textStyle: const TextStyle(fontFamily: fuente, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          foregroundColor: s.onSurface,
          side: BorderSide(color: s.outline.withValues(alpha: 0.6)),
          shape: RoundedRectangleBorder(borderRadius: redondeo),
          textStyle: const TextStyle(fontFamily: fuente, fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: redondeo),
          textStyle: const TextStyle(fontFamily: fuente, fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: redondeo)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 1,
        highlightElevation: 2,
        backgroundColor: s.primary,
        foregroundColor: s.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: redondeo),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        elevation: 0,
        backgroundColor: s.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: s.primary.withValues(alpha: 0.1),
        indicatorShape: RoundedRectangleBorder(borderRadius: redondeo),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontFamily: fuente, fontSize: 12, fontWeight: FontWeight.w500, color: s.onSurface),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: s.surface,
        indicatorColor: s.primary.withValues(alpha: 0.1),
        indicatorShape: RoundedRectangleBorder(borderRadius: redondeo),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide(color: s.outlineVariant),
        backgroundColor: s.surface,
        selectedColor: s.primary.withValues(alpha: 0.1),
        labelStyle: TextStyle(fontFamily: fuente, fontSize: 13, fontWeight: FontWeight.w500, color: s.onSurface),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: redondeo),
          side: BorderSide(color: s.outline.withValues(alpha: 0.6)),
          selectedBackgroundColor: s.primary.withValues(alpha: 0.1),
          selectedForegroundColor: s.primary,
        ),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(s.surface),
        constraints: const BoxConstraints(minHeight: 44),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: redondeo)),
        side: WidgetStatePropertyAll(BorderSide(color: s.outline.withValues(alpha: 0.6))),
      ),
      listTileTheme: ListTileThemeData(iconColor: s.onSurfaceVariant),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: redondeo),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: s.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: s.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(linearTrackColor: s.surfaceContainerHighest),
    );
  }
}
