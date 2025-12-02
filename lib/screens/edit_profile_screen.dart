// ไฟล์: edit_profile_screen.dart (โค้ดที่ปรับปรุงและทำงานถูกต้อง)

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;

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

  XFile? _pickedXFile; 
  String? _profileImageUrl; 
  bool _isPhotoRemoved = false; // สถานะใหม่: ใช้ตรวจสอบว่าผู้ใช้ต้องการลบรูปหรือไม่

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.initialProfileData['username'] ?? '';
    _ageController.text = (widget.initialProfileData['age'] ?? '').toString();
    _weightController.text = (widget.initialProfileData['weight'] ?? '').toString();
    _heightController.text = (widget.initialProfileData['height'] ?? '').toString();
    _gender = widget.initialProfileData['gender'] ?? 'ชาย';
    _weightGoal = widget.initialProfileData['weightGoal'] ?? 'คงที่';
    _profileImageUrl = widget.initialProfileData['profileImageUrl'] as String?;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  // ฟังก์ชันสำหรับแสดง Dialog เพื่อเลือกรูป/ลบรูป (ใช้ Bottom Sheet แทน AlertDialog เพื่อความสวยงาม)
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final String? action = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('เลือกจากแกลเลอรี'),
                onTap: () => Navigator.of(context).pop('gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('ถ่ายรูปด้วยกล้อง'),
                onTap: () => Navigator.of(context).pop('camera'),
              ),
              // ปุ่มลบรูปจะแสดงถ้ามีรูปเดิมอยู่และยังไม่ได้กดลบ
              if ((_profileImageUrl != null && _profileImageUrl!.isNotEmpty) && !_isPhotoRemoved)
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('ลบรูปโปรไฟล์', style: TextStyle(color: Colors.red)),
                  onTap: () => Navigator.of(context).pop('remove'),
                ),
            ],
          ),
        );
      },
    );

    XFile? pickedFile;

    if (action == 'gallery') {
      pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    } else if (action == 'camera') {
      pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 75);
    } else if (action == 'remove') {
      setState(() {
        _pickedXFile = null;
        _profileImageUrl = null;
        _isPhotoRemoved = true;
      });
      return; 
    }

    if (pickedFile != null) {
      setState(() {
        _pickedXFile = pickedFile;
        _profileImageUrl = null; 
        _isPhotoRemoved = false; 
      });
    }
  }

  // ฟังก์ชันหลักสำหรับอัปเดตข้อมูลโปรไฟล์
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

    // ตรวจสอบความถูกต้องของข้อมูล
    final String username = _usernameController.text.trim();
    final int? age = int.tryParse(_ageController.text.trim());
    final double? weight = double.tryParse(_weightController.text.trim());
    final double? height = double.tryParse(_heightController.text.trim());

    if (username.isEmpty || age == null || weight == null || height == null || age <= 0 || weight <= 0 || height <= 0) {
      setState(() {
        _errorMessage = 'โปรดกรอกข้อมูลให้ครบถ้วนและถูกต้อง (อายุ, น้ำหนัก, ส่วนสูง ต้องเป็นตัวเลขมากกว่า 0)';
        _isLoading = false;
      });
      return;
    }

    String? newProfileImageUrl = _profileImageUrl; 

    try {
      // 1. จัดการรูปภาพ (เฉพาะกรณีที่มีการเลือกรูปใหม่หรือลบรูป)
      if (_pickedXFile != null) {
        // อัปโหลดรูปใหม่
        final storageRef = FirebaseStorage.instance.ref().child('user_profile_images').child('${user.uid}.jpg');

        // อัปโหลดตามแพลตฟอร์ม
        if (kIsWeb) {
          final bytes = await _pickedXFile!.readAsBytes();
          await storageRef.putData(bytes);
        } else {
          await storageRef.putFile(File(_pickedXFile!.path));
        }

        newProfileImageUrl = await storageRef.getDownloadURL();
        if (newProfileImageUrl.contains('?')) {
         // ถ้ามี, ให้ต่อท้ายด้วย &
          newProfileImageUrl = '$newProfileImageUrl&v=${DateTime.now().millisecondsSinceEpoch}';
        } else {
          // ถ้าไม่มี, ให้ต่อท้ายด้วย ?
          newProfileImageUrl = '$newProfileImageUrl?v=${DateTime.now().millisecondsSinceEpoch}';
       }

      } else if (_isPhotoRemoved) {
        // หากผู้ใช้กดลบรูป: พยายามลบไฟล์เก่าจาก Storage
        try {
            await FirebaseStorage.instance.ref().child('user_profile_images').child('${user.uid}.jpg').delete();
        } catch (e) {
            // หากเกิด Error unauthorized ที่นี่, ให้มั่นใจว่า Storage Rules ถูกตั้งค่าในขั้นตอนที่ 1
            print("Could not delete old profile image: $e");
        }
        newProfileImageUrl = null; // ตั้งค่า URL ใน Firestore เป็น null
      }
      
      // 2. เตรียมข้อมูลสำหรับ Firestore
      final Map<String, dynamic> updateData = {
        'username': username,
        'age': age,
        'gender': _gender,
        'weight': weight,
        'height': height,
        'weightGoal': _weightGoal,
        'profileImageUrl': newProfileImageUrl, 
        'updatedAt': Timestamp.now(),
      };

      // 3. อัปเดตข้อมูลใน Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(updateData, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('อัปเดตข้อมูลโปรไฟล์สำเร็จ!')),
        );
        Navigator.of(context).pop();
      }
    } on FirebaseException catch (e) {
      print("Error updating profile: $e");
      setState(() {
        // แสดงข้อผิดพลาดให้ผู้ใช้เห็น
        _errorMessage = 'เกิดข้อผิดพลาดในการอัปเดต: ${e.message}'; 
      });
    } catch (e) {
      print("An unexpected error occurred: $e");
      setState(() {
        _errorMessage = 'เกิดข้อผิดพลาดที่ไม่คาดคิด: $e';
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

    // Logic การแสดงรูป
    ImageProvider<Object>? imageProvider;
    if (_pickedXFile != null) {
      imageProvider = kIsWeb
          ? NetworkImage(_pickedXFile!.path) as ImageProvider<Object>
          : FileImage(File(_pickedXFile!.path));
    } else if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty && !_isPhotoRemoved) {
      imageProvider = NetworkImage(_profileImageUrl!);
    }
    
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

              // ส่วนแสดงรูปโปรไฟล์ (Layout เดิม)
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: primaryColor.withOpacity(0.7),
                      backgroundImage: imageProvider,
                      child: imageProvider == null
                          ? const Icon(
                              Icons.person,
                              size: 80,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        radius: 20,
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // ... (ส่วน TextField และ Dropdown ทั้งหมดที่ยังอยู่) ...
              // TextField ชื่อผู้ใช้
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'ชื่อผู้ใช้ (Username)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person_outline),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor.withOpacity(0.5))),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor)),
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
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor.withOpacity(0.5))),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor)),
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
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor.withOpacity(0.5))),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor)),
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
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor.withOpacity(0.5))),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              // Dropdown สำหรับเลือกเพศ
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: InputDecoration(
                  labelText: 'เพศ',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.wc),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor.withOpacity(0.5))),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor)),
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
              ),
              const SizedBox(height: 16),
              // Dropdown สำหรับเลือกเป้าหมายน้ำหนัก
              DropdownButtonFormField<String>(
                value: _weightGoal,
                decoration: InputDecoration(
                  labelText: 'เป้าหมายน้ำหนัก',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.track_changes),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor.withOpacity(0.5))),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor)),
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
              ),
              const SizedBox(height: 24),
              // แสดงข้อความแจ้งเตือนเมื่อเกิดข้อผิดพลาด
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              // ปุ่มบันทึก
              _isLoading
                  ? CircularProgressIndicator(color: primaryColor)
                  : ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        'บันทึกข้อมูล',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}