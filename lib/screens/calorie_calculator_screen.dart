// ไฟล์นี้เป็นหน้าจอหลักสำหรับคำนวณปริมาณแคลอรี่ที่ต้องการต่อวัน (TDEE)
// และบันทึกรายการอาหารที่ผู้ใช้ทาน โดยเรียกใช้ HistoryProvider

import 'package:flutter/material.dart';
// --- ลบ import ที่ไม่จำเป็นออก ---
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:calorie_calculator/services/local_database_helper.dart';
// ------------------------------------
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:calorie_calculator/providers/history_provider.dart';
import 'package:calorie_calculator/screens/food_search_screen.dart';

class CalorieCalculatorScreen extends StatefulWidget {
  // --- ลบ isGuestMode ออก ---
  const CalorieCalculatorScreen({super.key});

  @override
  State<CalorieCalculatorScreen> createState() => _CalorieCalculatorScreenState();
}

class _CalorieCalculatorScreenState extends State<CalorieCalculatorScreen> {
  final _formKeyTDEE = GlobalKey<FormState>();
  final _formKeyFood = GlobalKey<FormState>();

  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  String _gender = 'ชาย';
  String _activityLevel = 'ไม่ออกกำลังกายเลย';
  double? _bmr;
  double? _tdee;
  String? _errorMessage;

  final _foodNameController = TextEditingController();
  final _foodCaloriesController = TextEditingController();

  // --- ลบ LocalDatabaseHelper ออก ---
  // final LocalDatabaseHelper _localDbHelper = LocalDatabaseHelper();

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _foodNameController.dispose();
    _foodCaloriesController.dispose();
    super.dispose();
  }

  // เมธอดสำหรับคำนวณ BMR และ TDEE
  void _calculateCalories() {
    if (!_formKeyTDEE.currentState!.validate()) {
      return;
    }

    setState(() {
      _errorMessage = null;
      _bmr = null;
      _tdee = null;
    });

    final int? age = int.tryParse(_ageController.text.trim());
    final double? weight = double.tryParse(_weightController.text.trim());
    final double? height = double.tryParse(_heightController.text.trim());

    if (age == null || weight == null || height == null || age <= 0 || weight <= 0 || height <= 0) {
      setState(() {
        _errorMessage = 'โปรดกรอกข้อมูล อายุ, น้ำหนัก, ส่วนสูง ให้ถูกต้อง (ต้องเป็นตัวเลขมากกว่า 0)';
      });
      return;
    }

    double calculatedBMR;
    if (_gender == 'ชาย') {
      calculatedBMR = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      calculatedBMR = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    double calculatedTDEE;
    switch (_activityLevel) {
      case 'ไม่ออกกำลังกายเลย':
        calculatedTDEE = calculatedBMR * 1.2;
        break;
      case 'ออกกำลังกายเล็กน้อย (1-3 วัน/สัปดาห์)':
        calculatedTDEE = calculatedBMR * 1.375;
        break;
      case 'ออกกำลังกายปานกลาง (3-5 วัน/สัปดาห์)':
        calculatedTDEE = calculatedBMR * 1.55;
        break;
      case 'ออกกำลังกายหนัก (6-7 วัน/สัปดาห์)':
        calculatedTDEE = calculatedBMR * 1.725;
        break;
      case 'ออกกำลังกายหนักมาก (ทุกวัน/งานใช้แรงงาน)':
        calculatedTDEE = calculatedBMR * 1.9;
        break;
      default:
        calculatedTDEE = calculatedBMR * 1.2;
    }

    setState(() {
      _bmr = calculatedBMR;
      _tdee = calculatedTDEE;
    });

    // บันทึกประวัติการคำนวณ
    _saveCalculationHistory();
  }

  // --- แก้ไข _saveCalculationHistory() ---
  // เมธอดสำหรับบันทึกประวัติการคำนวณ TDEE (ผ่าน Provider)
  Future<void> _saveCalculationHistory() async {
    if (_bmr == null || _tdee == null) return;

    // --- ลบ if (widget.isGuestMode) { ... } และ else { ... } ทั้งหมด ---
    // เปลี่ยนมาเรียกใช้ Provider ที่เราแก้ไขแล้วแทน
    try {
      final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
      
      // เรียกใช้เมธอดจาก Provider
      await historyProvider.addCalorieHistory(
        bmr: _bmr!,
        tdee: _tdee!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกประวัติการคำนวณสำเร็จ!')),
        );
      }
    } catch (e) {
      print('Error saving calorie history via Provider: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกประวัติการคำนวณไม่ได้: $e')),
        );
      }
    }
    // ไม่จำเป็นต้องเรียก loadHistoryData() ที่นี่
    // เพราะ addCalorieHistory() ใน Provider จะเรียกให้เอง
  }

  // --- แก้ไข _saveFoodEntry() ---
  // เมธอดสำหรับบันทึกรายการอาหาร (ผ่าน Provider)
  Future<void> _saveFoodEntry() async {
    if (!_formKeyFood.currentState!.validate()) {
      return;
    }

    final String foodName = _foodNameController.text.trim();
    final double? calories = double.tryParse(_foodCaloriesController.text.trim());

    if (foodName.isEmpty || calories == null || calories <= 0) {
      setState(() {
        _errorMessage = 'โปรดกรอกชื่ออาหารและแคลอรี่ให้ถูกต้อง (ต้องเป็นตัวเลขมากกว่า 0)';
      });
      return;
    }
    setState(() {
      _errorMessage = null;
    });

    // --- ลบ if (widget.isGuestMode) { ... } และ else { ... } ทั้งหมด ---
    // เปลี่ยนมาเรียกใช้ Provider
    try {
      final historyProvider = Provider.of<HistoryProvider>(context, listen: false);

      // เรียกใช้เมธอดจาก Provider
      await historyProvider.addFoodEntry(
        foodName: foodName,
        calories: calories,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกรายการอาหารสำเร็จ!')),
        );
        _foodNameController.clear();
        _foodCaloriesController.clear();
      }
    } catch (e) {
      print('Error saving food entry via Provider: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกรายการอาหารไม่ได้: $e')),
        );
      }
    }
    // ไม่จำเป็นต้องเรียก loadHistoryData() ที่นี่
    // เพราะ addFoodEntry() ใน Provider จะเรียกให้เอง
  }

  // เมธอดสำหรับนำทางไปยังหน้า FoodSearchScreen (ไม่เปลี่ยนแปลง)
  Future<void> _navigateToFoodSearch() async {
    final selectedFood = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FoodSearchScreen()),
    );

    if (selectedFood != null && selectedFood is Map<String, dynamic>) {
      setState(() {
        _foodNameController.text = selectedFood['foodName'];
        _foodCaloriesController.text = selectedFood['calories'].toString();
      });
    }
  }

  // --- build() และ Helper Widgets (ไม่เปลี่ยนแปลง) ---
  // (โค้ดส่วน UI ที่เหลือของคุณดีอยู่แล้วครับ)
  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color accentColor = Theme.of(context).colorScheme.secondary;
    final Color scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor, 
      appBar: AppBar(
        title: const Text('คำนวณแคลอรี่และบันทึกอาหาร'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- TDEE Calculator Section ---
            Card(
              margin: const EdgeInsets.only(bottom: 25),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKeyTDEE,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'คำนวณ TDEE (Total Daily Energy Expenditure)',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryColor, 
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'กรอกข้อมูลส่วนตัวเพื่อคำนวณปริมาณแคลอรี่ที่ร่างกายต้องการต่อวัน',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 25),
                      _buildTextField(
                        context, 
                        controller: _ageController,
                        labelText: 'อายุ (ปี)',
                        icon: Icons.cake,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'โปรดกรอกอายุ';
                          }
                          if (int.tryParse(value)! <= 0) {
                            return 'อายุต้องมากกว่า 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        context, 
                        controller: _weightController,
                        labelText: 'น้ำหนัก (กิโลกรัม)',
                        icon: Icons.fitness_center,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'โปรดกรอกน้ำหนัก';
                          }
                          if (double.tryParse(value)! <= 0) {
                            return 'น้ำหนักต้องมากกว่า 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        context, 
                        controller: _heightController,
                        labelText: 'ส่วนสูง (เซนติเมตร)',
                        icon: Icons.height,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'โปรดกรอกส่วนสูง';
                          }
                          if (double.tryParse(value)! <= 0) {
                            return 'ส่วนสูงต้องมากกว่า 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDropdownField<String>(
                        context, 
                        value: _gender,
                        labelText: 'เพศ',
                        icon: Icons.wc,
                        items: ['ชาย', 'หญิง'],
                        onChanged: (value) {
                          setState(() {
                            _gender = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildDropdownField<String>(
                        context, 
                        value: _activityLevel,
                        labelText: 'ระดับกิจกรรม',
                        icon: Icons.run_circle_outlined,
                        items: const [
                          'ไม่ออกกำลังกายเลย',
                          'ออกกำลังกายเล็กน้อย (1-2 วัน/สัปดาห์)',
                          'ออกกำลังกายปานกลาง (3-5 วัน/สัปดาห์)',
                          'ออกกำลังกายหนัก (6-7 วัน/สัปดาห์)',
                          'ออกกำลังกายหนักมาก (ทุกวัน/งานใช้แรงงาน)',
                        ],
                        onChanged: (value) {
                          setState(() {
                            _activityLevel = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 25),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 15.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ElevatedButton.icon(
                        onPressed: _calculateCalories,
                        icon: const Icon(Icons.calculate),
                        label: const Text('คำนวณ TDEE'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 55),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_bmr != null && _tdee != null)
                        _buildResultDisplay(primaryColor, accentColor), 
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Divider(height: 50, thickness: 1.5, color: Colors.grey[300]),
            ),

            // --- Food Entry Section ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKeyFood,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'บันทึกรายการอาหารที่ทาน',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: primaryColor, 
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'เพิ่มอาหารที่ทานในแต่ละวันเพื่อติดตามแคลอรี่ หรือค้นหาจากรายการ',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 25),
                      _buildTextField(
                        context, 
                        controller: _foodNameController,
                        labelText: 'ชื่ออาหาร',
                        icon: Icons.restaurant_menu,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'โปรดกรอกชื่ออาหาร';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        context, 
                        controller: _foodCaloriesController,
                        labelText: 'แคลอรี่ (Kcal)',
                        icon: Icons.local_fire_department,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'โปรดกรอกแคลอรี่';
                          }
                          if (double.tryParse(value)! <= 0) {
                            return 'แคลอรี่ต้องมากกว่า 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 25),
                      ElevatedButton.icon(
                        onPressed: _navigateToFoodSearch,
                        icon: const Icon(Icons.search),
                        label: const Text('ค้นหาและเลือกอาหาร'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 55),
                          backgroundColor: accentColor, 
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _saveFoodEntry,
                        icon: const Icon(Icons.save),
                        label: const Text('บันทึกอาหาร'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 55),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // (Helper Widgets: _buildTextField, _buildDropdownField, _buildResultDisplay ไม่เปลี่ยนแปลง)
  Widget _buildTextField(BuildContext context, {
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final Color primaryColor = Theme.of(context).primaryColor;
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: primaryColor), 
      ),
      keyboardType: keyboardType,
      validator: validator,
      cursorColor: primaryColor, 
    );
  }

  Widget _buildDropdownField<T>(BuildContext context, {
    required T value,
    required String labelText,
    required IconData icon,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    final Color primaryColor = Theme.of(context).primaryColor;
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: primaryColor), 
      ),
      items: items
          .map((label) => DropdownMenuItem(
                value: label,
                child: Text(label.toString()),
              ))
          .toList(),
      onChanged: onChanged,
      style: const TextStyle(color: Colors.black87, fontSize: 16), 
      iconEnabledColor: primaryColor, 
    );
  }

  Widget _buildResultDisplay(Color tdeeDisplayColor, Color bmrDisplayColor) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tdeeDisplayColor.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tdeeDisplayColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: tdeeDisplayColor.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BMR:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text(
                '${_bmr!.toStringAsFixed(2)} Kcal',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: bmrDisplayColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TDEE:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text(
                '${_tdee!.toStringAsFixed(2)} Kcal',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: tdeeDisplayColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}