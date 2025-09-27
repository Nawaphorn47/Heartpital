// lib/screens/main_screen_scaffold.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'notification_screen.dart';
import 'patient_list_screen.dart';
import 'setting_screen.dart';
import 'patient_dashboard_screen.dart';

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
      backgroundColor: Colors.transparent,
      body: Container(
        // ใช้สีเดียวกับหน้า Login
        color: const Color(0xFFBAE2FF),
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white, // สีขาวสำหรับ BottomNavigationBar
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_outlined),
              activeIcon: Icon(Icons.people_alt),
              label: 'ผู้ป่วย',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.show_chart_outlined),
              activeIcon: Icon(Icons.show_chart),
              label: 'แดชบอร์ด',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'แจ้งเตือน',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'ตั้งค่า',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF0D47A1), // สีไอคอนเมื่อเลือก
          unselectedItemColor: const Color(0xFF0D47A1).withOpacity(0.6), // สีไอคอนเมื่อไม่ได้เลือก
          showUnselectedLabels: true,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.kanit(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.kanit(),
        ),
      ),
    );
  }
}