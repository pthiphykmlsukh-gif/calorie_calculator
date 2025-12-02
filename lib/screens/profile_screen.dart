import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:calorie_calculator/screens/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? _userProfileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfileData();
  }

  Future<void> _loadUserProfileData() async {
    if (user != null) {
      setState(() => _isLoading = true);
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
        if (userDoc.exists) {
          setState(() {
            _userProfileData = userDoc.data() as Map<String, dynamic>?;
          });
        } else {
          setState(() {
            _userProfileData = {};
          });
        }
      } catch (e) {
        print("Error: $e");
        if (mounted) setState(() => _userProfileData = {});
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToEditProfile() async {
    if (_isLoading) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          initialProfileData: _userProfileData ?? {},
        ),
      ),
    );
    _loadUserProfileData();
  }

  // --- ฟังก์ชันใหม่: จัดการเลือก ImageProvider ให้ถูกต้อง ---
  ImageProvider _getProfileImageProvider(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      // ถ้าไม่มีข้อมูล ให้ใช้ icon แทน (return null ให้ CircleAvatar จัดการ) แต่ในที่นี้เราจะ return asset default
      // หรือถ้าคุณอยากให้แสดง Icon Person เฉยๆ ให้ return null ที่ Logic ใน widget แทน
      // เพื่อความง่าย ผมจะให้มัน return null เพื่อให้ไปเข้าเงื่อนไข child: Icon ด้านล่าง
      throw Exception("No image path"); 
    }
    
    // 1. ถ้าเป็น URL (ระบบเก่า)
    if (imagePath.startsWith('http')) {
      return NetworkImage(imagePath);
    }
    // 2. ถ้าเป็น Asset path (ระบบใหม่)
    return AssetImage(imagePath);
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color accentColor = Theme.of(context).colorScheme.secondary;
    final Color scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;

    if (user == null) {
      return Scaffold(
        backgroundColor: scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('โปรไฟล์'), centerTitle: true, backgroundColor: primaryColor),
        body: const Center(child: Text('กรุณาเข้าสู่ระบบ')),
      );
    }

    final String displayUsername = _userProfileData?['username'] ?? 'ผู้ใช้';
    final String displayEmail = user?.email ?? 'ไม่ได้ระบุ';
    final String? profileImageUrl = _userProfileData?['profileImageUrl'] as String?;

    // Logic การแสดงรูป
    ImageProvider? imageProvider;
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      if (profileImageUrl.startsWith('http')) {
        imageProvider = NetworkImage(profileImageUrl);
      } else {
        imageProvider = AssetImage(profileImageUrl);
      }
    }

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('โปรไฟล์ของฉัน'),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _navigateToEditProfile,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: primaryColor.withOpacity(0.7),
                          backgroundImage: imageProvider, // ใช้ตัวแปรที่เราเช็คข้างบน
                          child: imageProvider == null
                              ? const Icon(Icons.person, size: 80, color: Colors.white)
                              : null,
                        ),
                        Positioned(
                          right: 0, bottom: 0,
                          child: CircleAvatar(
                            backgroundColor: accentColor,
                            radius: 20,
                            child: const Icon(Icons.edit, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'สวัสดี, $displayUsername!',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: primaryColor.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 30),
                  
                  // ส่วนแสดงข้อมูล (เหมือนเดิม)
                  _userProfileData == null || _userProfileData!.isEmpty
                      ? const Text('ไม่มีข้อมูลโปรไฟล์')
                      : Column(
                          children: [
                            _buildProfileInfoCard(context, label: 'อายุ', value: '${_userProfileData!['age'] ?? '-'} ปี', icon: Icons.cake),
                            _buildProfileInfoCard(context, label: 'เพศ', value: _userProfileData!['gender'] ?? '-', icon: Icons.wc),
                            _buildProfileInfoCard(context, label: 'น้ำหนัก', value: '${_userProfileData!['weight'] ?? '-'} kg', icon: Icons.fitness_center),
                            _buildProfileInfoCard(context, label: 'ส่วนสูง', value: '${_userProfileData!['height'] ?? '-'} cm', icon: Icons.height),
                            _buildProfileInfoCard(context, label: 'อีเมล', value: displayEmail, icon: Icons.email),
                          ],
                        ),
                  
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _navigateToEditProfile,
                      icon: const Icon(Icons.edit, color: Colors.white),
                      label: const Text('แก้ไขโปรไฟล์', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor, padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                         FirebaseAuth.instance.signOut();
                         Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      icon: Icon(Icons.logout, color: accentColor),
                      label: Text('ออกจากระบบ', style: TextStyle(color: accentColor)),
                      style: OutlinedButton.styleFrom(side: BorderSide(color: accentColor), padding: const EdgeInsets.symmetric(vertical: 12)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileInfoCard(BuildContext context, {required String label, required String value, required IconData icon}) {
    // ... (โค้ดเดิมส่วนนี้ถูกต้องแล้ว ไม่ต้องแก้) ...
    // ใส่ไว้เพื่อให้ Code สมบูรณ์ตอน Copy ไปวาง
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
                  Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 18, color: Colors.black87)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}