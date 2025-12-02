import 'package:calorie_calculator/screens/calorie_calculator_screen.dart';
import 'package:calorie_calculator/screens/history_screen.dart';
import 'package:calorie_calculator/screens/profile_screen.dart';
import 'package:flutter/material.dart';
// --- ลบ import guest_profile_screen.dart ออก ---
// import 'package:calorie_calculator/screens/guest_profile_screen.dart'; 

class MainScreen extends StatefulWidget {
  // --- ลบ isGuestMode ออก ---
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // --- แก้ไข _widgetOptions ---
  // เราไม่จำเป็นต้องใช้ initState() อีกต่อไป เพราะ List นี้เป็นค่าคงที่แล้ว
  static const List<Widget> _widgetOptions = <Widget>[
    CalorieCalculatorScreen(), // ไม่ต้องส่ง isGuestMode
    HistoryScreen(),           // ไม่ต้องส่ง isGuestMode
    ProfileScreen(),           // แสดง ProfileScreen จริงเสมอ
  ];

  // --- ลบ initState() ออก ---

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color accentColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      body: Center(
        // แก้ไขการเรียกใช้เป็น _widgetOptions (ตามที่เราตั้งชื่อไว้)
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: 'คำนวณ/บันทึก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'ประวัติ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'โปรไฟล์',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: accentColor, 
        unselectedItemColor: Colors.white70, 
        backgroundColor: primaryColor, 
        onTap: _onItemTapped,
        elevation: 8, 
        type: BottomNavigationBarType.fixed, 
      ),
    );
  }
}