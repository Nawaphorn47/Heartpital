// lib/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme(bool isDarkMode) {
    _themeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // กำหนด ThemeData สำหรับ Light Theme
  static final ThemeData lightTheme = ThemeData(
    fontFamily: GoogleFonts.kanit().fontFamily,
    colorScheme: ColorScheme.light(
      primary: const Color(0xFF0D47A1), // สีน้ำเงินเข้ม
      primaryContainer: const Color(0xFFE3F2FD),
      secondary: const Color(0xFF43A047),
      onPrimary: Colors.white,
      background: const Color(0xFFF0F4F8),
      surface: Colors.white,
      onSurface: const Color(0xFF212121),
      error: const Color(0xFFD32F2F),
      onSecondary: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFFF0F4F8),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0D47A1),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData( // <-- แก้ไขตรงนี้
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFEFEFEF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: const Color(0xFF0D47A1), width: 2),
      ),
      labelStyle: GoogleFonts.kanit(color: const Color(0xFFB0B0B0)),
      hintStyle: GoogleFonts.kanit(color: const Color(0xFF888888)),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF0D47A1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: GoogleFonts.kanit(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF0D47A1),
        textStyle: GoogleFonts.kanit(fontSize: 16),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: const Color(0xFF0D47A1),
      unselectedItemColor: const Color(0xFF888888),
      backgroundColor: Colors.transparent,
      elevation: 0,
      selectedLabelStyle:
          GoogleFonts.kanit(fontWeight: FontWeight.bold, fontSize: 12),
      unselectedLabelStyle: GoogleFonts.kanit(fontSize: 12),
      type: BottomNavigationBarType.fixed,
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );

  // กำหนด ThemeData สำหรับ Dark Theme
  static final ThemeData darkTheme = ThemeData(
    fontFamily: GoogleFonts.kanit().fontFamily,
    colorScheme: ColorScheme.dark(
      primary: const Color(0xFF42A5F5), // สีน้ำเงินสว่างขึ้น
      primaryContainer: const Color(0xFF1E1E1E),
      secondary: const Color(0xFF66BB6A),
      onPrimary: Colors.black,
      background: const Color(0xFF121212),
      surface: const Color(0xFF1E1E1E),
      onSurface: Colors.white,
      error: const Color(0xFFCF6679),
      onSecondary: Colors.black,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData( // <-- แก้ไขตรงนี้
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: const Color(0xFF42A5F5), width: 2),
      ),
      labelStyle: GoogleFonts.kanit(color: Colors.grey.shade400),
      hintStyle: GoogleFonts.kanit(color: Colors.grey.shade500),
      contentPadding:
          const EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF42A5F5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: GoogleFonts.kanit(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF42A5F5),
        textStyle: GoogleFonts.kanit(fontSize: 16),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      selectedItemColor: const Color(0xFF42A5F5),
      unselectedItemColor: Colors.grey.shade400,
      backgroundColor: Colors.transparent,
      elevation: 0,
      selectedLabelStyle:
          GoogleFonts.kanit(fontWeight: FontWeight.bold, fontSize: 12),
      unselectedLabelStyle: GoogleFonts.kanit(fontSize: 12),
      type: BottomNavigationBarType.fixed,
    ),
    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: const Color(0xFF1E1E1E),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );
}