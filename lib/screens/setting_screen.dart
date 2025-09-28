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

  Future<void> _loadUserData() async {
    final firebaseUser = auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
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
          backgroundColor: const Color.fromARGB(255, 172, 215, 255).withOpacity(0.5),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF0F4F8),
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text('ตั้งค่า', style: GoogleFonts.kanit(color: const Color(0xFF0D47A1), fontWeight: FontWeight.bold, fontSize: 24)),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              _currentUser == null
                  ? const Center(child: CircularProgressIndicator())
                  : _buildProfileHeader(_currentUser!),
              const SizedBox(height: 24),

              _buildSectionTitle('บัญชี', context),
              _buildSettingsCard(
                children: [
                   _buildSettingsTile(
                    icon: Icons.logout,
                    color: Colors.red.shade700,
                    title: 'ออกจากระบบ',
                    onTap: () => _showLogoutConfirmationDialog(context),
                  ),
                ]
              ),
              const SizedBox(height: 24),
              
              _buildSectionTitle('ทั่วไป', context),
              _buildSettingsCard(
                children: [
                  _buildSettingsTile(
                    icon: Icons.language_outlined,
                    color: const Color(0xFF0D47A1),
                    title: 'ภาษา',
                    trailing: Text('ไทย', style: GoogleFonts.kanit(color: Colors.grey.shade600)),
                    onTap: () {},
                  ),
                ]
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(app_user.User user) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color.fromARGB(255, 231, 245, 255),
              const Color.fromARGB(255, 194, 225, 255),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: 50,
                color: const Color(0xFF0D47A1).withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: GoogleFonts.kanit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0D47A1),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.position,
              style: GoogleFonts.kanit(
                fontSize: 16,
                color: const Color(0xFF0D47A1).withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title,
        style: GoogleFonts.kanit(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade800,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: children,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (itemColor ?? Colors.grey).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: itemColor),
      ),
      title: Text(title, style: GoogleFonts.kanit(fontWeight: FontWeight.w600)),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}