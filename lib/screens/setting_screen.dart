import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/screens/theme_provider.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _showLogoutConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('ยืนยันการออกจากระบบ', style: GoogleFonts.kanit()),
          content: Text('คุณต้องการออกจากระบบใช่หรือไม่?', style: GoogleFonts.kanit()),
          actions: <Widget>[
            TextButton(
              child: Text('ยกเลิก', style: GoogleFonts.kanit()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('ออกจากระบบ', style: GoogleFonts.kanit(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          backgroundColor: Colors.transparent, // ทำให้โปร่งใส
          appBar: AppBar(
            backgroundColor: const Color(0xFFBAE2FF),
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text('ตั้งค่า', style: GoogleFonts.kanit(color: const Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSectionTitle('ทั่วไป', context),
              /*ListTile(
                leading: Icon(
                  themeProvider.themeMode == ThemeMode.dark
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                ),
               // title: Text('โหมดกลางคืน', style: GoogleFonts.kanit()),
                trailing: Switch(
                  value: themeProvider.themeMode == ThemeMode.dark,
                  onChanged: (value) {
                    themeProvider.toggleTheme(value);
                  },
                ),
              ),*/
              const Divider(),
              ListTile(
                leading: const Icon(Icons.language_outlined, color: Color(0xFF0D47A1)),
                title: Text('ภาษา', style: GoogleFonts.kanit()),
                trailing: Text('ไทย', style: GoogleFonts.kanit(color: Colors.grey)),
                onTap: () {
                  // TODO: เพิ่มฟังก์ชันเปลี่ยนภาษาในอนาคต
                },
              ),
              
              const SizedBox(height: 24),

              _buildSectionTitle('บัญชี', context),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text('ออกจากระบบ', style: GoogleFonts.kanit(color: Colors.red)),
                onTap: () {
                  _showLogoutConfirmationDialog(context);
                },
              ),
              const Divider(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.kanit(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0D47A1), // ใช้สีหลัก
        ),
      ),
    );
  }
}