// lib/screens/setting_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/screens/theme_provider.dart';
import 'login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../services/user_service.dart';
import '../models/user_model.dart' as app_user;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final UserService _userService = UserService();
  app_user.User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // [OPTIMIZED] ปรับปรุงการดึงข้อมูลผู้ใช้
  Future<void> _loadUserData() async {
    final firebaseUser = auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      // ดึงข้อมูลผู้ใช้โดยตรงจาก ID ไม่ต้องดึงมาทั้งหมด
      final user = await _userService.getUserById(firebaseUser.uid);
      if (mounted) {
        setState(() {
          _currentUser = user;
        });
      }
    }
  }

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
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: const Color(0xFFBAE2FF),
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text('ตั้งค่า', style: GoogleFonts.kanit(color: const Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _currentUser == null
                  ? const Center(child: CircularProgressIndicator())
                  : _buildProfileHeader(_currentUser!),
              const SizedBox(height: 24),

              _buildSectionTitle('บัญชี', context),
              _buildSettingsTile(
                icon: Icons.logout,
                color: Colors.red,
                title: 'ออกจากระบบ',
                onTap: () => _showLogoutConfirmationDialog(context),
              ),
              const SizedBox(height: 24),
              
              _buildSectionTitle('ทั่วไป', context),
              _buildSettingsTile(
                icon: Icons.language_outlined,
                color: const Color(0xFF0D47A1),
                title: 'ภาษา',
                trailing: Text('ไทย', style: GoogleFonts.kanit(color: Colors.grey)),
                onTap: () {},
              ),
              const Divider(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(app_user.User user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          )
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF0D47A1).withOpacity(0.1),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
              style: GoogleFonts.kanit(
                color: const Color(0xFF0D47A1),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: GoogleFonts.kanit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  user.position,
                  style: GoogleFonts.kanit(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.kanit(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0D47A1),
        ),
      ),
    );
  }
  
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
    Color? color,
  }) {
    final itemColor = color ?? Theme.of(context).textTheme.bodyLarge?.color;

    return ListTile(
      leading: Icon(icon, color: itemColor),
      title: Text(title, style: GoogleFonts.kanit(color: itemColor)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}