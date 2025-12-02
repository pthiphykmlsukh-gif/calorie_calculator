import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback showLoginPage;
  const RegisterScreen({super.key, required this.showLoginPage});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  String _gender = 'ชาย';
  String _weightGoal = 'คงที่'; // <<< เพิ่ม: ตัวแปรสำหรับเป้าหมายน้ำหนัก
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  // ฟังก์ชันสำหรับบันทึกรายละเอียดผู้ใช้เพิ่มเติมลง Firestore
  Future<void> addUserDetails(
    String uid, // User ID จาก Firebase Auth
    String username,
    int age,
    String gender,
    double weight,
    double height,
    String email,
    String weightGoal, // <<< เพิ่ม: รับค่าเป้าหมายน้ำหนัก
  ) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'username': username,
      'age': age,
      'gender': gender,
      'weight': weight,
      'height': height,
      'email': email,
      'weightGoal': weightGoal, // <<< เพิ่ม: บันทึกเป้าหมายน้ำหนัก
      'createdAt': Timestamp.now(), // เพิ่มเวลาที่สร้างบัญชี
    });
  }

  Future<void> signUp() async {
    setState(() {
      _errorMessage = null;
    });

    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      setState(() {
        _errorMessage = 'รหัสผ่านไม่ตรงกัน โปรดตรวจสอบอีกครั้ง';
      });
      return;
    }

    final String username = _usernameController.text.trim();
    final int? age = int.tryParse(_ageController.text.trim());
    final double? weight = double.tryParse(_weightController.text.trim());
    final double? height = double.tryParse(_heightController.text.trim());

    if (username.isEmpty || age == null || weight == null || height == null) {
      setState(() {
        _errorMessage = 'โปรดกรอกข้อมูลส่วนตัวให้ครบถ้วนและถูกต้อง (อายุ, น้ำหนัก, ส่วนสูง ต้องเป็นตัวเลข)';
      });
      return;
    }
    // <<< เพิ่ม: ตรวจสอบ weightGoal ว่ามีการเลือกค่าเริ่มต้นหรือไม่ (ในกรณีที่มีค่าว่าง)
    if (_weightGoal.isEmpty) {
        setState(() {
            _errorMessage = 'โปรดเลือกเป้าหมายน้ำหนักของคุณ';
        });
        return;
    }


    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await addUserDetails(
        userCredential.user!.uid, // ใช้ UID ของผู้ใช้ที่เพิ่งสร้าง
        username,
        age,
        _gender,
        weight,
        height,
        _emailController.text.trim(),
        _weightGoal, // <<< เพิ่ม: ส่งค่าเป้าหมายน้ำหนักไปบันทึก
      );

      // Show success message or navigate
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('สมัครสมาชิกสำเร็จสำหรับ ${userCredential.user!.email!}'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } on FirebaseAuthException catch (e) {
      print('Failed to register: $e');
      setState(() {
        if (e.code == 'weak-password') {
          _errorMessage = 'รหัสผ่านอ่อนเกินไป โปรดใช้รหัสผ่านที่แข็งแรงกว่านี้';
        } else if (e.code == 'email-already-in-use') {
          _errorMessage = 'อีเมลนี้ถูกใช้ไปแล้ว โปรดใช้อีเมลอื่น';
        } else if (e.code == 'invalid-email') {
          _errorMessage = 'รูปแบบอีเมลไม่ถูกต้อง';
        } else {
          _errorMessage = 'เกิดข้อผิดพลาดในการสมัครสมาชิก: ${e.message}';
        }
      });
    } catch (e) {
      print('An unexpected error occurred: $e');
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดที่ไม่คาดคิด: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color accentColor = Theme.of(context).colorScheme.secondary;
    final Color scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('สมัครสมาชิก'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'สร้างบัญชีใหม่',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
              ),
              const SizedBox(height: 30),
              // Username
              _buildTextField(
                controller: _usernameController,
                labelText: 'ชื่อผู้ใช้ (Username)',
                icon: Icons.person_outline,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
              // Email
              _buildTextField(
                controller: _emailController,
                labelText: 'อีเมล',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              // Password
              _buildTextField(
                controller: _passwordController,
                labelText: 'รหัสผ่าน',
                icon: Icons.lock,
                obscureText: true,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
              // Confirm Password
              _buildTextField(
                controller: _confirmPasswordController,
                labelText: 'ยืนยันรหัสผ่าน',
                icon: Icons.lock,
                obscureText: true,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
              // Age
              _buildTextField(
                controller: _ageController,
                labelText: 'อายุ (ปี)',
                icon: Icons.cake,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              // Weight
              _buildTextField(
                controller: _weightController,
                labelText: 'น้ำหนัก (กิโลกรัม)',
                icon: Icons.fitness_center,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              // Height
              _buildTextField(
                controller: _heightController,
                labelText: 'ส่วนสูง (เซนติเมตร)',
                icon: Icons.height,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              // Gender Dropdown
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: InputDecoration(
                  labelText: 'เพศ',
                  prefixIcon: const Icon(Icons.wc),
                  labelStyle: TextStyle(color: Colors.teal.shade700),
                ),
                items: ['ชาย', 'หญิง']
                    .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _gender = value!;
                  });
                },
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                iconEnabledColor: primaryColor,
              ),
              const SizedBox(height: 16), // <<< เพิ่ม: ช่องว่าง
              // <<< เพิ่ม: Dropdown สำหรับเป้าหมายน้ำหนัก
              DropdownButtonFormField<String>(
                value: _weightGoal,
                decoration: InputDecoration(
                  labelText: 'เป้าหมายน้ำหนัก',
                  prefixIcon: const Icon(Icons.track_changes), // ไอคอนที่สื่อถึงเป้าหมาย
                  labelStyle: TextStyle(color: Colors.teal.shade700),
                ),
                items: ['ลดน้ำหนัก', 'เพิ่มน้ำหนัก', 'คงที่']
                    .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _weightGoal = value!;
                  });
                },
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                iconEnabledColor: primaryColor,
              ),
              // >>> สิ้นสุดการเพิ่ม Dropdown สำหรับเป้าหมายน้ำหนัก
              const SizedBox(height: 24),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: signUp,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'สมัครสมาชิก',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'เป็นสมาชิกอยู่แล้วใช่ไหม?',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  TextButton(
                    onPressed: widget.showLoginPage,
                    child: Text(
                      'เข้าสู่ระบบ',
                      style: TextStyle(fontWeight: FontWeight.bold, color: accentColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method for consistent TextField styling
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
    );
  }
}