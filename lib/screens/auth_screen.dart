// ไฟล์นี้ทำหน้าที่เป็นตัวจัดการหลัก (wrapper) สำหรับหน้าจอเข้าสู่ระบบและสมัครสมาชิก
// โดยจะสลับไปมาระหว่าง LoginScreen และ RegisterScreen ตามสถานะที่กำหนด

import 'package:flutter/material.dart';
import 'package:calorie_calculator/screens/login_screen.dart';
import 'package:calorie_calculator/screens/register_screen.dart';

class AuthScreen extends StatefulWidget {
  // onGuestLogin: ฟังก์ชันนี้ถูกส่งมาจากภายนอกเพื่อจัดการเมื่อผู้ใช้เลือกเข้าสู่ระบบแบบแขก
  final VoidCallback onGuestLogin; 
  const AuthScreen({Key? key, required this.onGuestLogin}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // showLoginPage: สถานะที่จะใช้กำหนดว่าจะแสดงหน้าจอไหน
  bool showLoginPage = true;

  // เมธอดสำหรับสลับสถานะระหว่างหน้า Login และ Register
  void toggleScreens() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      // ถ้า showLoginPage เป็นจริง ให้แสดงหน้า LoginScreen
      return LoginScreen(
        showRegisterPage: toggleScreens, // ส่งเมธอด toggleScreens เพื่อให้หน้า Login เรียกสลับไป Register
        onGuestLogin: widget.onGuestLogin, // ส่งฟังก์ชัน onGuestLogin ต่อไป
      );
    } else {
      // ถ้า showLoginPage เป็นเท็จ ให้แสดงหน้า RegisterScreen
      return RegisterScreen(
        showLoginPage: toggleScreens, // ส่งเมธอด toggleScreens เพื่อให้หน้า Register เรียกสลับไป Login
      );
    }
  }
}
