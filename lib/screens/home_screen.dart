import 'package:flutter/material.dart';
import 'package:calorie_calculator/screens/main_screen.dart'; 

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // --- แก้ไขบรรทัดนี้ ---
      // ลบ (isGuestMode: false) ออก
      body: MainScreen(),
    );
  }
}