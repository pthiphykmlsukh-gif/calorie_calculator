import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ตัด image_picker, firebase_storage, dart:io ออก เพราะไม่ได้ใช้แล้ว

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> initialProfileData;
  const EditProfileScreen({Key? key, required this.initialProfileData}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _usernameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  String _gender = 'ชาย';
  String _weightGoal = 'คงที่';

  String? _errorMessage;
  bool _isLoading = false;

  // ตัวแปรเก็บ path ของรูปที่เลือก (จะเป็น URL หรือ Asset Path ก็ได้)
  String? _selectedProfileImage; 

  // สร้างรายชื่อรูปภาพที่มีใน assets (1 ถึง 12)
  final List<String> _avatarAssets = List.generate(
    12, 
    (index) => 'assets/images/profile_picture_${index + 1}.png'
  );

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.initialProfileData['username'] ?? '';
    _ageController.text = (widget.initialProfileData['age'] ?? '').toString();
    _weightController.text = (widget.initialProfileData['weight'] ?? '').toString();
    _heightController.text = (widget.initialProfileData['height'] ?? '').toString();
    _gender = widget.initialProfileData['gender'] ?? 'ชาย';
    _weightGoal = widget.initialProfileData['weightGoal'] ?? 'คงที่';
    _selectedProfileImage = widget.initialProfileData['profileImageUrl'] as String?;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  // ฟังก์ชันแสดง Dialog ให้เลือกรูป Avatar
  void _showAvatarSelection() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 400, // กำหนดความสูง
          child: Column(
            children: [
              const Text(
                'เลือกรูปโปรไฟล์',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, // แถวละ 4 รูป
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _avatarAssets.length,
                  itemBuilder: (context, index) {
                    final assetPath = _avatarAssets[index];
                    final isSelected = _selectedProfileImage == assetPath;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedProfileImage = assetPath;
                        });
                        Navigator.pop(context); // ปิด Dialog หลังเลือก
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isSelected 
                              ? Border.all(color: Theme.of(context).primaryColor, width: 3)
                              : null,
                        ),
                        child: CircleAvatar(
                          backgroundImage: AssetImage(assetPath),
                          backgroundColor: Colors.grey[200],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ฟังก์ชัน Helper เพื่อดูว่ารูปเป็น Web หรือ Asset
  ImageProvider _getImageProvider(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return const AssetImage('assets/images/profile_picture_1.png'); // รูป Default ถ้าไม่มีค่า
    }
    if (imagePath.startsWith('http')) {
      return NetworkImage(imagePath); // รูปเก่าจาก Firebase Storage (ถ้ามี)
    }
    return AssetImage(imagePath); // รูปจาก Assets
  }

  Future<void> _updateProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'คุณไม่ได้ล็อกอิน โปรดลองใหม่อีกครั้ง';
        _isLoading = false;
      });
      return;
    }

    final String username = _usernameController.text.trim();
    final int? age = int.tryParse(_ageController.text.trim());
    final double? weight = double.tryParse(_weightController.text.trim());
    final double? height = double.tryParse(_heightController.text.trim());

    if (username.isEmpty || age == null || weight == null || height == null || age <= 0 || weight <= 0 || height <= 0) {
      setState(() {
        _errorMessage = 'โปรดกรอกข้อมูลให้ครบถ้วนและถูกต้อง';
        _isLoading = false;
      });
      return;
    }

    try {
      // เตรียมข้อมูลสำหรับ Firestore
      // หมายเหตุ: เราเก็บ String path ของรูปตรงๆ เลย ไม่ต้องอัปโหลด
      final Map<String, dynamic> updateData = {
        'username': username,
        'age': age,
        'gender': _gender,
        'weight': weight,
        'height': height,
        'weightGoal': _weightGoal,
        'profileImageUrl': _selectedProfileImage, // บันทึก Path หรือ URL ที่เลือก
        'updatedAt': Timestamp.now(),
      };

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(updateData, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปเดตข้อมูลโปรไฟล์สำเร็จ!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      print("Error updating profile: $e");
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาด: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขโปรไฟล์'),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'แก้ไขข้อมูลส่วนตัวของคุณ',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // ส่วนแสดงรูปโปรไฟล์
              GestureDetector(
                onTap: _showAvatarSelection, // กดแล้วเปิดรายการรูป
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: primaryColor.withOpacity(0.2),
                      // ใช้ Helper function แสดงรูป
                      backgroundImage: _getImageProvider(_selectedProfileImage),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        radius: 20,
                        child: const Icon(
                          Icons.edit, // เปลี่ยนไอคอนเป็นรูปดินสอ/แก้ไข
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text("แตะที่รูปเพื่อเปลี่ยน", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),

              // TextField ชื่อผู้ใช้
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'ชื่อผู้ใช้ (Username)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              // TextField อายุ
              TextField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: 'อายุ (ปี)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.cake),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              // TextField น้ำหนัก
              TextField(
                controller: _weightController,
                decoration: InputDecoration(
                  labelText: 'น้ำหนัก (กิโลกรัม)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.fitness_center),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              // TextField ส่วนสูง
              TextField(
                controller: _heightController,
                decoration: InputDecoration(
                  labelText: 'ส่วนสูง (เซนติเมตร)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.height),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              // Dropdown เพศ
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: InputDecoration(
                  labelText: 'เพศ',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.wc),
                ),
                items: ['ชาย', 'หญิง'].map((label) => DropdownMenuItem(value: label, child: Text(label))).toList(),
                onChanged: (value) => setState(() => _gender = value!),
              ),
              const SizedBox(height: 16),
              // Dropdown เป้าหมาย
              DropdownButtonFormField<String>(
                value: _weightGoal,
                decoration: InputDecoration(
                  labelText: 'เป้าหมายน้ำหนัก',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.track_changes),
                ),
                items: ['ลดน้ำหนัก', 'เพิ่มน้ำหนัก', 'คงที่'].map((label) => DropdownMenuItem(value: label, child: Text(label))).toList(),
                onChanged: (value) => setState(() => _weightGoal = value!),
              ),
              const SizedBox(height: 24),
              
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                ),
                
              _isLoading
                  ? CircularProgressIndicator(color: primaryColor)
                  : ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('บันทึกข้อมูล', style: TextStyle(fontSize: 18)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}