// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../services/user_service.dart';
import '../models/user_model.dart';
import 'main_screen_scaffold.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _positionController = TextEditingController();
  final _auth = auth.FirebaseAuth.instance;
  final _userService = UserService();

  bool _isLoading = false;
  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  // <<< START: ฟังก์ชันใหม่สำหรับรีเซ็ตรหัสผ่าน >>>
  Future<void> _showForgotPasswordDialog() async {
    final TextEditingController emailResetController = TextEditingController();
    final GlobalKey<FormState> resetFormKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('รีเซ็ตรหัสผ่าน', style: GoogleFonts.kanit()),
          content: Form(
            key: resetFormKey,
            child: TextFormField(
              controller: emailResetController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'กรุณากรอกอีเมล',
                hintText: 'example@email.com',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty ||
                    !value.contains('@')) {
                  return 'กรุณาใส่อีเมลที่ถูกต้อง';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('ยกเลิก', style: GoogleFonts.kanit()),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('ส่งอีเมล', style: GoogleFonts.kanit()),
              onPressed: () async {
                if (resetFormKey.currentState!.validate()) {
                  final email = emailResetController.text.trim();
                  try {
                    await _auth.sendPasswordResetEmail(email: email);
                    Navigator.of(context).pop(); // ปิด Dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'ส่งลิงก์รีเซ็ตรหัสผ่านไปที่ $email แล้ว',
                            style: GoogleFonts.kanit()),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } on auth.FirebaseAuthException catch (e) {
                    Navigator.of(context).pop(); // ปิด Dialog
                    String errorMessage = 'เกิดข้อผิดพลาด';
                    if (e.code == 'user-not-found') {
                      errorMessage = 'ไม่พบผู้ใช้สำหรับอีเมลนี้';
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(errorMessage, style: GoogleFonts.kanit()),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
  // <<< END: ฟังก์ชันใหม่สำหรับรีเซ็ตรหัสผ่าน >>>

  Future<void> _submitAuthForm() async {
    // ... (โค้ดส่วนนี้เหมือนเดิม)
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }
    _formKey.currentState?.save();

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // สมัครสมาชิก
        final auth.UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // บันทึกข้อมูลผู้ใช้เพิ่มเติมลงใน Firestore
        if (userCredential.user != null) {
          final newUser = User(
            id: userCredential.user!.uid,
            name: _nameController.text.trim(),
            position: _positionController.text.trim(),
            email: _emailController.text.trim(),
          );
          await _userService.addUser(newUser);
        }
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreenScaffold()),
        );
      }
    } on auth.FirebaseAuthException catch (e) {
      String errorMessage = 'เกิดข้อผิดพลาดในการยืนยันตัวตน';
      if (e.code == 'weak-password') {
        errorMessage = 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'อีเมลนี้ถูกใช้ในการสมัครสมาชิกแล้ว';
      } else if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        errorMessage = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'รหัสผ่านไม่ถูกต้อง';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'รูปแบบอีเมลไม่ถูกต้อง';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage, style: GoogleFonts.kanit()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 186, 226, 255),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ... (โค้ดส่วน TextFormField เหมือนเดิม)
                        Text(
                          _isLogin ? 'เข้าสู่ระบบ' : 'สมัครสมาชิก',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        if (!_isLogin) ...[
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'ชื่อ-นามสกุล',
                              prefixIcon: const Icon(Icons.person_outline),
                              filled: true,
                              fillColor: const Color(0xFFF0F2F5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณาใส่ชื่อ';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _positionController,
                            decoration: InputDecoration(
                              labelText: 'ตำแหน่ง',
                              prefixIcon: const Icon(Icons.badge_outlined),
                              filled: true,
                              fillColor: const Color(0xFFF0F2F5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'กรุณาใส่ตำแหน่ง';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'อีเมล',
                            prefixIcon: const Icon(Icons.email_outlined),
                            filled: true,
                            fillColor: const Color(0xFFF0F2F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                !value.contains('@')) {
                              return 'กรุณาใส่อีเมลที่ถูกต้อง';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'รหัสผ่าน',
                            prefixIcon: const Icon(Icons.lock_outline),
                            filled: true,
                            fillColor: const Color(0xFFF0F2F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                value.length < 6) {
                              return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        if (_isLogin)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              // <<< เปลี่ยน onPressed ให้เรียกใช้ฟังก์ชันใหม่ >>>
                              onPressed: _showForgotPasswordDialog,
                              child: Text(
                                'ลืมรหัสผ่าน?',
                                style: GoogleFonts.kanit(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else
                          ElevatedButton(
                            onPressed: _submitAuthForm,
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              _isLogin ? 'เข้าสู่ระบบ' : 'สมัครสมาชิก',
                              style: GoogleFonts.kanit(fontSize: 18),
                            ),
                          ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                            });
                          },
                          child: Text(
                            _isLogin
                                ? 'ยังไม่มีบัญชี? สมัครสมาชิก'
                                : 'มีบัญชีอยู่แล้ว? เข้าสู่ระบบ',
                            style: GoogleFonts.kanit(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
      margin: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/doctor.webp',
            height: 150,
            width: 150,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Text(
            'Patient Tracker',
            style: GoogleFonts.kanit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0D47A1),
            ),
          ),
          Text(
            'ติดตามข้อมูลผู้ป่วยของคุณได้อย่างง่ายดาย',
            style: GoogleFonts.kanit(
              fontSize: 16,
              color: const Color(0xFF0D47A1).withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}