import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Legacy colors - keeping them for now so we don't break compilation immediately,
  // but they should be phased out from UI files.
  static const Color primaryMystic = Color(0xFF2D1B6B);
  static const Color secondaryMystic = Color(0xFF5A3E9F);
  static const Color saffronAccent = Color(0xFFFF9933);
  static const Color starWhite = Color(0xFFF0F2F5);
  static const Color cosmicBlack = Color(0xFF0D0814);

  // --- MODERN MATERIAL 3 THEMES ---

  static ThemeData get cosmicTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0B0C10),
      brightness: Brightness.dark,
      primary: const Color(0xFFD4AF37), // Metallic Gold
      onPrimary: Colors.black,
      secondary: const Color(0xFFF3E5AB), // Light Gold/Vanilla
      onSecondary: Colors.black,
      surface: const Color(0xFF111217), // Deep space/charcoal
      onSurface: const Color(0xFFE5E7EB), // Very legible off-white
      surfaceContainerHighest: const Color(0xFF1A1C23), // Cards
      onSurfaceVariant: const Color(0xFF9CA3AF), // Subtitles
      outline: const Color(0xFFD4AF37).withOpacity(0.3),
    );

    return _buildTheme(colorScheme);
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blueGrey,
      brightness: Brightness.dark,
      primary: const Color(0xFF00E5FF), // Cyan accent
      onPrimary: Colors.black,
      secondary: const Color(0xFFB388FF), // Purple accent
      onSecondary: Colors.black,
      surface: const Color(0xFF121212),
      onSurface: const Color(0xFFEEEEEE),
      surfaceContainerHighest: const Color(0xFF1E1E1E),
      onSurfaceVariant: const Color(0xFFB0B0B0),
    );

    return _buildTheme(colorScheme);
  }

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFD4AF37),
      brightness: Brightness.light,
      primary: const Color(0xFFB8860B), // Dark Goldenrod
      onPrimary: Colors.white,
      secondary: const Color(0xFF4B0082), // Indigo
      onSecondary: Colors.white,
      surface: const Color(0xFFF8FAFC),
      onSurface: const Color(0xFF0F172A),
      surfaceContainerHighest: Colors.white,
      onSurfaceVariant: const Color(0xFF475569),
    );

    return _buildTheme(colorScheme);
  }

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      primaryColor: colorScheme.primary,
      
      // Typography: Cinzel for headers, Inter for legible body
      textTheme: GoogleFonts.interTextTheme(
        ThemeData(brightness: colorScheme.brightness).textTheme
      ).copyWith(
        displayLarge: GoogleFonts.cinzel(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.cinzel(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 22),
        titleMedium: GoogleFonts.inter(color: colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge: GoogleFonts.inter(color: colorScheme.onSurface, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: colorScheme.onSurfaceVariant, fontSize: 14),
      ),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: colorScheme.primary),
        titleTextStyle: GoogleFonts.cinzel(
          color: colorScheme.primary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 6,
          shadowColor: colorScheme.primary.withOpacity(0.4),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),

      // Cards - Glassmorphism hint
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerHighest,
        elevation: 8,
        shadowColor: colorScheme.primary.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colorScheme.outline,
            width: 1,
          ),
        ),
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        labelStyle: GoogleFonts.inter(color: colorScheme.onSurfaceVariant),
        hintStyle: GoogleFonts.inter(color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        prefixIconColor: colorScheme.primary,
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
