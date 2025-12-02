// ไฟล์หลักของแอปพลิเคชัน Calorie Calculator
// ทำหน้าที่เริ่มต้นแอป, ตั้งค่า Firebase, รวมถึงกำหนดธีมและโครงสร้างหลักของแอป

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // ไม่ได้ใช้ในไฟล์นี้โดยตรง
import 'package:calorie_calculator/firebase_options.dart';
import 'package:calorie_calculator/screens/auth_wrapper.dart';

// --- (ลบ import ของ sqflite และ shared_preferences ทั้งหมด) ---
// import 'package:sqflite/sqflite.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
// import 'package:sqflite_common_ffi/sqflite_ffi.dart';
// import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
// -----------------------------------------------------------

import 'package:provider/provider.dart'; // แพ็กเกจสำหรับจัดการสถานะ (State Management)
import 'package:calorie_calculator/providers/history_provider.dart';
import 'package:intl/date_symbol_data_local.dart'; // สำหรับการจัดการวันที่และเวลาตามแต่ละภาษา

// ฟังก์ชันหลักที่รันเมื่อแอปพลิเคชันเริ่มทำงาน
void main() async {
  // ตรวจสอบให้แน่ใจว่า WidgetsFlutterBinding พร้อมใช้งานก่อนการทำงานอื่นๆ
  WidgetsFlutterBinding.ensureInitialized();
  
  // เริ่มต้น Firebase ด้วยการตั้งค่าจากไฟล์ firebase_options.dart
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // เริ่มต้นข้อมูล locale สำหรับการจัดรูปแบบวันที่/เวลา
  await initializeDateFormatting('th', null);

  // (บล็อก sqflite ถูกลบไปแล้ว)

  // รันแอปพลิเคชัน MyApp
  runApp(
    ChangeNotifierProvider(
      create: (context) => HistoryProvider(),
      child: const MyApp(),
    ),
  );
}
// วิดเจ็ตหลักของแอป
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // กำหนดชุดสีหลักและสีเน้นสำหรับแอปพลิเคชัน
    const MaterialColor primaryAppColor = Colors.indigo;
    const MaterialColor accentAppColor = Colors.amber;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Calorie Calculator',
      // (โค้ด Theme ของคุณเหมือนเดิม ไม่ต้องแก้ไข)
      theme: ThemeData(
        primarySwatch: primaryAppColor,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: primaryAppColor,
          accentColor: accentAppColor,
        ).copyWith(secondary: accentAppColor),
        scaffoldBackgroundColor: primaryAppColor.shade50,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryAppColor,
          foregroundColor: Colors.white,
          elevation: 4, 
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryAppColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10), 
            ),
            elevation: 5,
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: accentAppColor,
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: accentAppColor,
            side: BorderSide(color: accentAppColor, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: primaryAppColor, width: 2),
          ),
          labelStyle: TextStyle(color: primaryAppColor.shade700),
          prefixIconColor: primaryAppColor,
          filled: true,
          fillColor: Colors.grey[50],
        ),
        cardTheme: const CardThemeData(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15)),
          ),
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}