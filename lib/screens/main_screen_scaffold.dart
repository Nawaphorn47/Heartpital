// lib/screens/main_screen_scaffold.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'notification_screen.dart';
import 'patient_list_screen.dart';
import 'setting_screen.dart';
import 'patient_dashboard_screen.dart';
import 'history_screen.dart';

class MainScreenScaffold extends StatefulWidget {
  const MainScreenScaffold({super.key});

  @override
  State<MainScreenScaffold> createState() => _MainScreenScaffoldState();
}

class _MainScreenScaffoldState extends State<MainScreenScaffold> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    PatientListScreen(),
    PatientDashboardScreen(),
    NotificationScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFBAE2FF),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomNavigationBar(
            elevation: 0,
            backgroundColor: Colors.white,
            items: <BottomNavigationBarItem>[
              _buildNavigationBarItem(Icons.people_alt_outlined, Icons.people_alt, 'ผู้ป่วย', 0),
              _buildNavigationBarItem(Icons.lock_clock_outlined, Icons.lock_clock, 'ตารางเวลา', 1),
              _buildNavigationBarItem(Icons.receipt_long_outlined, Icons.receipt_long, 'แจ้งเตือน', 2),
              _buildNavigationBarItem(Icons.history_outlined, Icons.history, 'ประวัติ', 3),
              _buildNavigationBarItem(Icons.settings_outlined, Icons.settings, 'ตั้งค่า', 4),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: const Color(0xFF0D47A1),
            unselectedItemColor: const Color(0xFF0D47A1).withOpacity(0.6),
            showUnselectedLabels: true,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: GoogleFonts.kanit(fontWeight: FontWeight.bold),
            unselectedLabelStyle: GoogleFonts.kanit(),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavigationBarItem(
      IconData icon, IconData activeIcon, String label, int index) {
    return BottomNavigationBarItem(
      icon: AnimatedScale(
        scale: _selectedIndex == index ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Icon(_selectedIndex == index ? activeIcon : icon),
      ),
      label: label,
    );
  }
}