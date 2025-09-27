// lib/screens/main_screen_scaffold.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'patient_list_screen.dart';
import 'patient_dashboard_screen.dart';
import 'notification_screen.dart';
import 'setting_screen.dart';
import 'schedule_screen.dart';

class MainScreenScaffold extends StatefulWidget {
  const MainScreenScaffold({super.key});

  @override
  State<MainScreenScaffold> createState() => _MainScreenScaffoldState();
}

class _MainScreenScaffoldState extends State<MainScreenScaffold> {
  int _selectedIndex = 0;

  // [FIX] ลบ const ออกจากตรงนี้
  static final List<Widget> _widgetOptions = <Widget>[
    const PatientDashboardScreen(),
    const PatientListScreen(),
    const ScheduleScreen(),
    const NotificationScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/hospital2.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'ภาพรวม'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'ผู้ป่วย'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'ตาราง'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'แจ้งเตือน'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'ตั้งค่า'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 12, 59, 133),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        showUnselectedLabels: true,
        selectedLabelStyle: GoogleFonts.kanit(),
        unselectedLabelStyle: GoogleFonts.kanit(),
      ),
    );
  }
}