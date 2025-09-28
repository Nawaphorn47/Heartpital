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
          backgroundColor: const Color.fromARGB(255, 186, 226, 255),
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

  // Profile Header from the first redesign
  Widget _buildProfileHeader(app_user.User user) {
    return Padding(
      padding: const EdgeInsets.all(13.0),
      child: Card(
        elevation: 8.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                'assets/images/h4.jpg',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.7)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              SizedBox(
                height: 200,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: const Color(0xFF0D47A1).withOpacity(0.1),
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: GoogleFonts.kanit(
                            color: const Color(0xFF0D47A1),
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.name,
                      style: GoogleFonts.kanit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      user.position,
                      style: GoogleFonts.kanit(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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