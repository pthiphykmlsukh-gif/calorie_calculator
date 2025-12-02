import 'package:flutter/material.dart';
// --- ลบ LocalDatabaseHelper (SQLite) ออก ---
// import 'package:calorie_calculator/services/local_database_helper.dart'; 
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 

class HistoryProvider with ChangeNotifier {
  List<Map<String, dynamic>> _calorieHistory = []; 
  List<Map<String, dynamic>> _foodEntries = []; 
  bool _isLoading = false; 
  String? _errorMessage; 
  User? _currentUser; // ข้อมูลผู้ใช้ปัจจุบันที่ล็อกอินอยู่

  // --- ลบ _isGuestMode ออก ---
  // late bool _isGuestMode; 

  // ตัวแปรสำหรับเป้าหมายและข้อมูลสรุปแคลอรี่
  double? _targetCalories; 
  double? _currentDayConsumedCalories; 
  String? _weightGoal; 
  double? _userSetCalorieTarget; 

  // Getters (เหมือนเดิม)
  double? get targetCalories => _targetCalories;
  double? get currentDayConsumedCalories => _currentDayConsumedCalories;
  String? get weightGoal => _weightGoal;
  double? get userSetCalorieTarget => _userSetCalorieTarget;
  List<Map<String, dynamic>> get calorieHistory => _calorieHistory;
  List<Map<String, dynamic>> get foodEntries => _foodEntries;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // --- ลบ _localDbHelper ออก ---
  // final LocalDatabaseHelper _localDbHelper = LocalDatabaseHelper();

  // --- แก้ไข Constructor ---
  HistoryProvider() {
    // คอยฟังการเปลี่ยนแปลงสถานะการล็อกอิน
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _currentUser = user;
      if (user != null) {
        // ถ้าผู้ใช้ล็อกอิน ให้โหลดข้อมูล
        loadHistoryData();
      } else {
        // ถ้าผู้ใช้ล็อกเอาท์ ให้ล้างข้อมูล
        _clearDataOnLogout();
      }
    });

    // โหลดข้อมูลครั้งแรก (เผื่อผู้ใช้เปิดแอปมาแบบล็อกอินค้างไว้)
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      loadHistoryData();
    }
  }

  // --- ลบ updateGuestMode() ออก ---
  // void updateGuestMode(bool newGuestMode) { ... }

  // ฟังก์ชันสำหรับล้างข้อมูลเมื่อล็อกเอาท์
  void _clearDataOnLogout() {
    _calorieHistory = [];
    _foodEntries = [];
    _targetCalories = null;
    _currentDayConsumedCalories = null;
    _weightGoal = null;
    _userSetCalorieTarget = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  // --- แก้ไข loadHistoryData() ---
  Future<void> loadHistoryData() async {
    // ลบ {required bool isGuestMode} ออก
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); 

    try {
      // --- ลบ if (_isGuestMode) { ... } ทั้งหมด ---

      // --- เริ่มต้นด้วยตรรกะของโหมดล็อกอิน (เดิมอยู่ใน else) ---
      if (_currentUser == null) {
        _errorMessage = 'คุณไม่ได้ล็อกอิน.';
        _clearDataOnLogout(); // ใช้ฟังก์ชัน helper
        return;
      }

      // ดึงข้อมูลประวัติการคำนวณจาก Firestore
      QuerySnapshot calorieSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('calorie_history')
          .orderBy('createdAt', descending: true)
          .get();
      _calorieHistory = calorieSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      // ดึงข้อมูลรายการอาหารจาก Firestore
      QuerySnapshot foodSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('food_entries')
          .orderBy('createdAt', descending: true)
          .get();
      _foodEntries = foodSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      // ดึงข้อมูลโปรไฟล์ผู้ใช้จาก Firestore
      DocumentSnapshot userProfileDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();

      if (userProfileDoc.exists) {
        final userData = userProfileDoc.data() as Map<String, dynamic>?;
        if (userData != null) {
          _weightGoal = userData['weightGoal'] as String? ?? 'คงที่';
          _userSetCalorieTarget = (userData['userSetCalorieTarget'] as num?)?.toDouble();
        } else {
          _weightGoal = 'คงที่';
          _userSetCalorieTarget = null;
        }
      } else {
        _weightGoal = 'คงที่';
        _userSetCalorieTarget = null;
      }

      // คำนวณ TDEE ล่าสุดและแคลอรี่เป้าหมาย
      double? latestTdee;
      if (_calorieHistory.isNotEmpty) {
        latestTdee = (_calorieHistory.first['tdee'] as num?)?.toDouble();
      }
      _targetCalories = _calculateDailyCalorieTarget(latestTdee);
      _currentDayConsumedCalories = _calculateCurrentDayConsumedCalories(_foodEntries);

      print('HistoryProvider: User history loaded from Firestore.');
      
    } catch (e) {
      print("HistoryProvider Error loading history data: $e");
      _errorMessage = 'เกิดข้อผิดพลาดในการโหลดข้อมูล: $e';
      _clearDataOnLogout(); // ใช้ฟังก์ชัน helper
    } finally {
      _isLoading = false;
      notifyListeners(); 
    }
  }

  // _calculateDailyCalorieTarget (ไม่เปลี่ยนแปลง)
  double? _calculateDailyCalorieTarget(double? latestTdee) {
    if (_userSetCalorieTarget != null) {
      return _userSetCalorieTarget;
    }
    if (latestTdee == null) {
      return null;
    }
    switch (_weightGoal) {
      case 'ลดน้ำหนัก':
        return latestTdee - 300;
      case 'เพิ่มน้ำหนัก':
        return latestTdee + 300;
      case 'คงที่':
      default:
        return latestTdee;
    }
  }

  // --- แก้ไข updateWeightGoalAndCalorieTarget() ---
  Future<void> updateWeightGoalAndCalorieTarget(String goal, {double? customCalorieTarget}) async {
    
    // --- ลบ if (_isGuestMode) { ... } ทั้งหมด ---

    // --- เริ่มต้นด้วยตรรกะของโหมดล็อกอิน (เดิมอยู่ใน else) ---
    if (_currentUser == null) {
      _errorMessage = 'คุณไม่ได้ล็อกอิน, ไม่สามารถบันทึกเป้าหมายได้.';
      notifyListeners();
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .set({
        'weightGoal': goal,
        'userSetCalorieTarget': customCalorieTarget,
      }, SetOptions(merge: true));
      print('HistoryProvider: User weight goal updated to $goal with target $customCalorieTarget in Firestore.');
      
      // โหลดข้อมูลใหม่หลังจากอัปเดต
      await loadHistoryData(); 
    
    } catch (e) {
      _errorMessage = 'เกิดข้อผิดพลาดในการบันทึกเป้าหมาย: $e';
      print('HistoryProvider Error updating weight goal: $e');
    } finally {
      notifyListeners();
    }
  }

  // _calculateCurrentDayConsumedCalories (ไม่เปลี่ยนแปลง)
  double _calculateCurrentDayConsumedCalories(List<Map<String, dynamic>> foodEntries) {
    double total = 0.0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var entry in foodEntries) {
      DateTime? entryDateTime;
      if (entry['timestamp'] is String) {
        entryDateTime = DateTime.tryParse(entry['timestamp']);
      } else if (entry['createdAt'] is Timestamp) {
        entryDateTime = (entry['createdAt'] as Timestamp).toDate();
      } else if (entry['timestamp'] is int) {
        entryDateTime = DateTime.fromMillisecondsSinceEpoch(entry['timestamp']);
      }

      if (entryDateTime != null) {
        final entryDate = DateTime(entryDateTime.year, entryDateTime.month, entryDateTime.day);
        if (entryDate.isAtSameMomentAs(today)) {
          total += (entry['calories'] as num? ?? 0.0);
        }
      }
    }
    return total;
  }

  // --- ลบ _calculateGuestDailySummary() ออก ---
  // void _calculateGuestDailySummary() { ... }

  // --- ลบ clearGuestData() ออก ---
  // Future<void> clearGuestData() async { ... }

  // --- แก้ไข addCalorieHistory() ---
  Future<void> addCalorieHistory({
    required double bmr,
    required double tdee,
  }) async {
    final Map<String, dynamic> data = {
      'bmr': bmr,
      'tdee': tdee,
      'createdAt': FieldValue.serverTimestamp(), // Firestore timestamp
      'timestamp': DateTime.now().toIso8601String(), // Local timestamp
    };
    // --- ลบ if (_isGuestMode) { ... } ---

    // --- เริ่มต้นด้วยตรรกะของโหมดล็อกอิน (เดิมอยู่ใน else) ---
    if (_currentUser == null) {
      _errorMessage = 'คุณไม่ได้ล็อกอิน, ไม่สามารถบันทึกประวัติได้.';
      notifyListeners();
      return;
    }
    // หมายเหตุ: โค้ดเดิมของคุณลบ 'createdAt' ออกจาก data ก่อนส่งให้ Firestore
    // แต่จริงๆ แล้ว Firestore ควรใช้ 'createdAt' และ Local DB ควรใช้ 'timestamp'
    // ผมจะแก้ไขให้ถูกต้อง
    
    // สร้าง data สำหรับ Firestore
    final Map<String, dynamic> firestoreData = {
      'bmr': bmr,
      'tdee': tdee,
      'createdAt': FieldValue.serverTimestamp(),
      'timestamp': DateTime.now().toIso8601String(), // เก็บ timestamp ไว้ด้วยก็ดี
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('calorie_history')
        .add(firestoreData);

    await loadHistoryData(); // โหลดข้อมูลใหม่
  }

  // --- แก้ไข addFoodEntry() ---
  Future<void> addFoodEntry({
    required String foodName,
    required double calories,
  }) async {
    // --- ลบ if (_isGuestMode) { ... } ---

    // --- เริ่มต้นด้วยตรรกะของโหมดล็อกอิน (เดิมอยู่ใน else) ---
    if (_currentUser == null) {
      _errorMessage = 'คุณไม่ได้ล็อกอิน, ไม่สามารถบันทึกอาหารได้.';
      notifyListeners();
      return;
    }

    final Map<String, dynamic> firestoreData = {
      'foodName': foodName,
      'calories': calories,
      'createdAt': FieldValue.serverTimestamp(),
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('food_entries')
        .add(firestoreData);
    
    await loadHistoryData(); // โหลดข้อมูลใหม่
  }
}