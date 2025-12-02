// (Imports... เหมือนเดิม)
import 'package:calorie_calculator/screens/home_screen.dart'; 
import 'package:calorie_calculator/screens/login_screen.dart'; 
import 'package:calorie_calculator/screens/register_screen.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool showLoginPage = true;

  void toggleScreens() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        
        // --- (เพิ่มส่วนนี้) ---
        // 1. ตรวจสอบสถานะการเชื่อมต่อ (สำคัญมาก)
        if (snapshot.connectionState == ConnectionState.waiting) {
          // ถ้ากำลังรอข้อมูล ให้แสดงหน้า Loading
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        // -----------------------

        // 2. ตรวจสอบว่ามีข้อมูลผู้ใช้ (ล็อกอินแล้ว)
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        // 3. (ไม่มีข้อมูล) ผู้ใช้ยังไม่ได้ล็อกอิน
        else {
          if (showLoginPage) {
            return LoginPage( 
              showRegisterPage: toggleScreens,
            );
          } else {
            return RegisterScreen(showLoginPage: toggleScreens);
          }
        }
      },
    );
  }
}