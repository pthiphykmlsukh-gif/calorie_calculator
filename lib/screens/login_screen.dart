import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// SharedPreferences ไม่ได้ถูกใช้งานในโค้ดนี้ คุณอาจลบออกได้
// import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback showRegisterPage;
  // --- ลบ onGuestLogin ออก ---
  // final VoidCallback onGuestLogin;

  const LoginPage({
    Key? key,
    required this.showRegisterPage,
    // --- ลบ onGuestLogin ออก ---
    // required this.onGuestLogin,
  }) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>(); 
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false; 

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    if (!_formKey.currentState!.validate()) {
      return; 
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true; 
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      print('Failed to sign in: $e');
      setState(() {
        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
          _errorMessage = 'อีเมลหรือรหัสผ่านไม่ถูกต้อง';
        } else if (e.code == 'invalid-email') {
          _errorMessage = 'รูปแบบอีเมลไม่ถูกต้อง';
        } else {
          _errorMessage = 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ: ${e.message}';
        }
      });
    } catch (e) {
      print('An unexpected error occurred: $e');
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดที่ไม่คาดคิด: $e';
      });
    } finally {
      setState(() {
        _isLoading = false; 
      });
    }
  }

  // --- ฟังก์ชัน _handleGuestLogin() ถูกลบไปแล้ว (ดีมากครับ) ---

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor, 
      appBar: AppBar(
        title: const Text('เข้าสู่ระบบ'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'images/app_icon.png', 
                width: 150, 
                height: 150, 
              ),
              const SizedBox(height: 20),
              Text(
                'ยินดีต้อนรับสู่ Calorie Calculator!', 
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryColor, 
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'เข้าสู่ระบบเพื่อติดตามแคลอรี่และสุขภาพของคุณ',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Login Form Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey, 
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _emailController,
                          labelText: 'อีเมล',
                          icon: Icons.email,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'โปรดกรอกอีเมล';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                              return 'รูปแบบอีเมลไม่ถูกต้อง';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _passwordController,
                          labelText: 'รหัสผ่าน',
                          icon: Icons.lock,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'โปรดกรอกรหัสผ่าน';
                            }
                            if (value.length < 6) {
                              return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
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
                          onPressed: _isLoading ? null : signIn, 
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.login), 
                          label: Text(
                            _isLoading ? 'กำลังเข้าสู่ระบบ...' : 'เข้าสู่ระบบ',
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 55),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 30), 

              Text(
                'ยังไม่มีบัญชีใช่ไหม?',
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10), 
              
              // ปุ่มสมัครสมาชิก (ทำงานปกติ)
              ElevatedButton.icon( 
                onPressed: widget.showRegisterPage, 
                icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
                label: const Text(
                  'สร้างบัญชีใหม่', 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 55), 
                  backgroundColor: Colors.indigo, 
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
              ),
              
              const SizedBox(height: 15),

            ], // End of Column children
          ),
        ),
      ),
    );
  }

  // _buildTextField (ไม่เปลี่ยนแปลง)
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false, 
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon), 
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
    );
  }
}