import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:calorie_calculator/screens/edit_profile_screen.dart'; // ตรวจสอบว่ามีไฟล์นี้อยู่จริง

/// หน้าจอแสดงโปรไฟล์ของผู้ใช้
/// แสดงข้อมูลส่วนตัวและรูปโปรไฟล์ พร้อมปุ่มสำหรับแก้ไขและออกจากระบบ
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? _userProfileData;
  bool _isLoading = true; // สถานะการโหลดข้อมูลโปรไฟล์

  @override
  void initState() {
    super.initState();
    // โหลดข้อมูลโปรไฟล์เมื่อ Widget ถูกสร้างขึ้น
    _loadUserProfileData();
  }

  /// ฟังก์ชันสำหรับโหลดข้อมูลโปรไฟล์จาก Firestore
  Future<void> _loadUserProfileData() async {
    if (user != null) {
      setState(() {
        _isLoading = true; // เริ่มสถานะโหลด
      });
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _userProfileData = userDoc.data() as Map<String, dynamic>?;
          });
        } else {
          // หากไม่มีข้อมูลใน Firestore (อาจเป็นผู้ใช้เก่าที่เพิ่งอัปเดตระบบ)
          setState(() {
            _userProfileData = {}; // กำหนดเป็น Map ว่าง เพื่อไม่ให้ค้างในสถานะโหลด
          });
        }
      } catch (e) {
        print("Error loading user profile data: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูลโปรไฟล์')),
          );
          setState(() {
            _userProfileData = {}; // หยุดโหลดและแสดงค่าว่าง
          });
        }
      } finally {
        setState(() {
          _isLoading = false; // หยุดสถานะโหลด
        });
      }
    } else {
      setState(() {
        _isLoading = false; // ไม่ได้ล็อกอิน ไม่จำเป็นต้องโหลด
      });
    }
  }

  /// ฟังก์ชันสำหรับนำทางไปยังหน้าแก้ไขโปรไฟล์
  /// และโหลดข้อมูลโปรไฟล์ใหม่เมื่อกลับมา
  Future<void> _navigateToEditProfile() async {
    if (_isLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กำลังโหลดข้อมูลโปรไฟล์ กรุณารอสักครู่...')),
      );
      return;
    }

    // ส่งข้อมูลโปรไฟล์ปัจจุบันไปให้หน้าแก้ไข และรอผลลัพธ์ (การกลับมา)
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          initialProfileData: _userProfileData ?? {}, // ส่ง Map ว่างถ้าเป็น null
        ),
      ),
    );
    // เมื่อกลับมาจาก EditProfileScreen ให้โหลดข้อมูลโปรไฟล์ใหม่เพื่ออัปเดต UI
    _loadUserProfileData();
  }

  @override
  Widget build(BuildContext context) {
    // ดึงสีจาก Theme ที่กำหนดใน main.dart
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color accentColor = Theme.of(context).colorScheme.secondary;
    final Color scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;

    // กรณีผู้ใช้ไม่ได้ล็อกอิน
    if (user == null) {
      return Scaffold(
        backgroundColor: scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('โปรไฟล์'),
          centerTitle: true,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off_outlined, size: 80, color: primaryColor.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'คุณไม่ได้ล็อกอิน กรุณาเข้าสู่ระบบเพื่อดูโปรไฟล์',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // สำหรับผู้ใช้ที่ล็อกอินแล้ว
    final String displayUsername = _userProfileData?['username'] ?? 'ผู้ใช้';
    final String displayEmail = user?.email ?? 'ไม่ได้ระบุ';
    // ดึง URL รูปโปรไฟล์
    final String? profileImageUrl = _userProfileData?['profileImageUrl'] as String?;

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('โปรไฟล์ของฉัน'),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor)) // แสดง Loading indicator
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ส่วนแสดงรูปโปรไฟล์
                  GestureDetector(
                    onTap: _navigateToEditProfile, // แตะเพื่อไปหน้าแก้ไขโปรไฟล์
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: primaryColor.withOpacity(0.7),
                          backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                              ? NetworkImage(profileImageUrl) as ImageProvider<Object>? // ใช้ NetworkImage หากมี URL
                              : null,
                          child: profileImageUrl == null || profileImageUrl.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Colors.white,
                                )
                              : null, // แสดงไอคอนเริ่มต้นหากไม่มีรูป
                        ),
                        // ปุ่มแก้ไขรูปโปรไฟล์
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            backgroundColor: accentColor,
                            radius: 20,
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // ข้อความทักทายผู้ใช้
                  Text(
                    'สวัสดี, $displayUsername!',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: primaryColor.withOpacity(0.8)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  // แสดงข้อมูลโปรไฟล์ หรือข้อความว่าไม่มีข้อมูล
                  _userProfileData == null || _userProfileData!.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: Column(
                            children: [
                              Icon(Icons.info_outline, size: 60, color: accentColor),
                              const SizedBox(height: 10),
                              Text(
                                'ไม่มีข้อมูลโปรไฟล์\nโปรดแก้ไขโปรไฟล์ของคุณเพื่อเพิ่มข้อมูล',
                                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            _buildProfileInfoCard(
                              context,
                              label: 'อายุ',
                              value: (_userProfileData!['age'] ?? 'ไม่ได้ระบุ').toString() + ' ปี',
                              icon: Icons.cake,
                            ),
                            _buildProfileInfoCard(
                              context,
                              label: 'เพศ',
                              value: _userProfileData!['gender'] ?? 'ไม่ได้ระบุ',
                              icon: Icons.wc,
                            ),
                            _buildProfileInfoCard(
                               context,
                               label: 'น้ำหนัก',
                               // แก้ไขโดยการแปลงเป็น num? -> toDouble()
                               value: ((_userProfileData!['weight'] as num?)?.toDouble().toStringAsFixed(1) ?? 'ไม่ได้ระบุ') + ' kg',
                               icon: Icons.fitness_center,
                            ),
                            _buildProfileInfoCard(
                             context,
                             label: 'ส่วนสูง',
                            // แก้ไขโดยการแปลงเป็น num? -> toDouble()
                            value: ((_userProfileData!['height'] as num?)?.toDouble().toStringAsFixed(1) ?? 'ไม่ได้ระบุ') + ' cm',
                            icon: Icons.height,
                            ),
                            // แสดงอีเมลแยกต่างหาก
                            _buildProfileInfoCard(
                              context,
                              label: 'อีเมล',
                              value: displayEmail,
                              icon: Icons.email,
                            ),
                          ],
                        ),
                  const SizedBox(height: 30),
                  // ปุ่มแก้ไขโปรไฟล์
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _navigateToEditProfile,
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text('แก้ไขโปรไฟล์', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // ปุ่มออกจากระบบ
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        FirebaseAuth.instance.signOut();
                        // ป๊อปทุก Route จนถึง Route แรก (หน้าล็อกอิน/หน้าแรกหลังออกจากระบบ)
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      icon: Icon(Icons.logout, color: accentColor),
                      label: Text('ออกจากระบบ', style: TextStyle(color: accentColor)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: accentColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Helper method สำหรับสร้าง Card แสดงข้อมูลโปรไฟล์
  Widget _buildProfileInfoCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final Color primaryColor = Theme.of(context).primaryColor;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: primaryColor, size: 28),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}