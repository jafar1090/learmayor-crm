import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Premium Corporate Palette (Tailwind-inspired Slate & Blue) ---
  
  static const Color primary = Color(0xFF0F172A); // Slate 900
  static const Color primaryLight = Color(0xFF1E293B); // Slate 800
  static const Color primarySubtle = Color(0xFFF1F5F9); // Slate 100
  
  static const Color accent = Color(0xFF2563EB); // Blue 600
  static const Color accentLight = Color(0xFF3B82F6); // Blue 500
  static const Color accentSubtle = Color(0xFFEFF6FF); // Blue 50
  
  static const Color secondary = Color(0xFF6366F1); // Indigo 500
  
  // Semantic Colors (Clean & Modern)
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color successSubtle = Color(0xFFECFDF5); // Emerald 50
  
  static const Color error = Color(0xFFEF4444); // Red 500
  static const Color errorSubtle = Color(0xFFFEF2F2); // Red 50
  
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color warningSubtle = Color(0xFFFFFBEB); // Amber 50
  
  static const Color info = Color(0xFF0EA5E9); // Sky 500

  // Background & Surface
  static const Color background = Color(0xFFF8FAFC); // Slate 50
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color divider = Color(0xFFF1F5F9); // Slate 100
  
  // Text Colors
  static const Color textDark = Color(0xFF0F172A); // Slate 900
  static const Color textMid = Color(0xFF475569); // Slate 600
  static const Color textLight = Color(0xFF94A3B8); // Slate 400

  // --- Premium Effects Tokens ---
  
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.04),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get premiumShadow => [
    BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static LinearGradient get premiumGradient => const LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // --- ThemeData Generation ---

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        primary: primary,
        secondary: accent,
        surface: surface,
        background: background,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDark,
        onBackground: textDark,
        outline: border,
      ),
      scaffoldBackgroundColor: background,
      dividerColor: divider,
      
      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(color: textDark, fontWeight: FontWeight.bold, letterSpacing: -1.5, height: 1.1),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(color: textDark, fontWeight: FontWeight.bold, letterSpacing: -0.8, height: 1.2),
        titleLarge: baseTextTheme.titleLarge?.copyWith(color: textDark, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.2),
        titleMedium: baseTextTheme.titleMedium?.copyWith(color: textDark, fontWeight: FontWeight.w600, fontSize: 16),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: textDark, height: 1.6, fontSize: 16),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: textMid, height: 1.5, fontSize: 14),
        labelSmall: baseTextTheme.labelSmall?.copyWith(color: textLight, fontWeight: FontWeight.w600, letterSpacing: 0.5),
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textDark,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18, 
          fontWeight: FontWeight.bold, 
          color: textDark,
          letterSpacing: -0.5,
        ),
        iconTheme: const IconThemeData(color: textDark, size: 22),
      ),
      
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.3),
        ).copyWith(
          overlayColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.hovered)) return Colors.white.withOpacity(0.08);
            if (states.contains(MaterialState.pressed)) return Colors.white.withOpacity(0.12);
            return null;
          }),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textDark,
          side: const BorderSide(color: border, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: const TextStyle(color: textMid, fontSize: 14, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: textLight, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return accent;
          return Colors.transparent;
        }),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: border, width: 1.5),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return Colors.white;
          return textLight;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return accent;
          return border;
        }),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: divider,
        circularTrackColor: divider,
        refreshBackgroundColor: surface,
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: divider,
        thumbColor: Colors.white,
        overlayColor: accent.withOpacity(0.1),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8, elevation: 4),
        trackHeight: 4,
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: border),
        backgroundColor: Colors.white,
        selectedColor: accentSubtle,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDark),
        secondaryLabelStyle: const TextStyle(color: accent, fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
