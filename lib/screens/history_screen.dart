import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:calorie_calculator/providers/history_provider.dart';
import 'package:calorie_calculator/screens/auth_wrapper.dart';

/// หน้าจอสำหรับแสดงประวัติการคำนวณแคลอรี่และบันทึกอาหาร
// (ลบการรองรับโหมดแขกออก)
class HistoryScreen extends StatefulWidget {
  // --- ลบ isGuestMode ออกจาก Constructor ---
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedWeightGoal;
  final TextEditingController _customCalorieTargetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final historyProvider = Provider.of<HistoryProvider>(context, listen: false);
      setState(() {
        _selectedWeightGoal = historyProvider.weightGoal;
        if (historyProvider.userSetCalorieTarget != null) {
          _customCalorieTargetController.text = historyProvider.userSetCalorieTarget!.toStringAsFixed(0);
        } else {
          _customCalorieTargetController.clear();
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customCalorieTargetController.dispose();
    super.dispose();
  }

  // --- ฟังก์ชัน _showSetWeightGoalDialog ไม่มีการแก้ไข ---
  // (ยังคงทำงานเหมือนเดิมผ่าน historyProvider)
  void _showSetWeightGoalDialog(HistoryProvider historyProvider, Color primaryColor) {
    // ... โค้ดส่วนนี้เหมือนเดิม ...
    String? tempSelectedGoal = historyProvider.weightGoal;
    final TextEditingController tempCustomCalorieController = TextEditingController();
    if (historyProvider.userSetCalorieTarget != null) {
      tempCustomCalorieController.text = historyProvider.userSetCalorieTarget!.toStringAsFixed(0);
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('กำหนดเป้าหมายน้ำหนัก', style: TextStyle(color: primaryColor)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: tempSelectedGoal,
                      decoration: InputDecoration(
                        labelText: 'เป้าหมายน้ำหนัก',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.fitness_center, color: primaryColor),
                      ),
                      items: <String>['ลดน้ำหนัก', 'เพิ่มน้ำหนัก', 'คงที่', 'กำหนดเอง']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          tempSelectedGoal = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    if (tempSelectedGoal == 'กำหนดเอง')
                      TextFormField(
                        controller: tempCustomCalorieController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'เป้าหมายแคลอรี่ (Kcal)',
                          hintText: 'เช่น 1800',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: Icon(Icons.fastfood, color: primaryColor),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (tempSelectedGoal != null) {
                      double? customTarget;
                      if (tempSelectedGoal == 'กำหนดเอง') {
                        customTarget = double.tryParse(tempCustomCalorieController.text);
                        if (customTarget == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('กรุณาใส่เป้าหมายแคลอรี่ที่ถูกต้อง')),
                          );
                          return; 
                        }
                      }
                      await historyProvider.updateWeightGoalAndCalorieTarget(
                        tempSelectedGoal!,
                        customCalorieTarget: customTarget,
                      );
                      setState(() {
                        _selectedWeightGoal = tempSelectedGoal;
                        if (customTarget != null) {
                          _customCalorieTargetController.text = customTarget.toStringAsFixed(0);
                        } else {
                          _customCalorieTargetController.clear();
                        }
                      });
                      Navigator.of(context).pop(); 
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color accentColor = Theme.of(context).colorScheme.secondary;
    final Color scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;

    final user = FirebaseAuth.instance.currentUser;

    return Consumer<HistoryProvider>(
      builder: (context, historyProvider, child) {
        
        // --- แก้ไขเงื่อนไข ---
        // ตรวจสอบว่าผู้ใช้ไม่ได้ล็อกอิน (โดยไม่ต้องเช็ค isGuestMode)
        if (user == null) {
          return Scaffold(
            backgroundColor: scaffoldBackgroundColor,
            appBar: AppBar(
              title: const Text('ประวัติ'),
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
                    Icon(
                      Icons.person_off_outlined,
                      size: 80,
                      color: primaryColor.withOpacity(0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'กรุณาเข้าสู่ระบบเพื่อดูประวัติของคุณ',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        // กลับไปหน้า AuthWrapper เพื่อให้ระบบส่งไปหน้า Login
                         Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const AuthWrapper()), 
                          (Route<dynamic> route) => false,
                        );
                      },
                      icon: const Icon(Icons.login),
                      label: const Text('เข้าสู่ระบบ / ลงทะเบียน'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // แสดงหน้าจอหลักของประวัติ (เมื่อล็อกอินแล้ว)
        return Scaffold(
          backgroundColor: scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text('ประวัติของฉัน'),
            centerTitle: true,
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              indicatorColor: accentColor,
              indicatorWeight: 4,
              tabs: const [
                Tab(text: 'ประวัติคำนวณ'),
                Tab(text: 'บันทึกอาหาร'),
              ],
            ),
          ),
          body: historyProvider.isLoading
              ? Center(
                  child: CircularProgressIndicator(
                  color: primaryColor,
                ))
              : historyProvider.errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 80, color: Colors.redAccent),
                            const SizedBox(height: 16),
                            Text(
                              'เกิดข้อผิดพลาด: ${historyProvider.errorMessage!}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCalorieHistoryTab(historyProvider, primaryColor, accentColor),
                        _buildFoodEntriesTab(historyProvider.foodEntries, primaryColor, accentColor),
                      ],
                    ),
        );
      },
    );
  }

  /// สร้าง Widget สำหรับแสดงประวัติการคำนวณแคลอรี่ (Calorie History Tab)
  Widget _buildCalorieHistoryTab(HistoryProvider historyProvider, Color primaryColor, Color accentColor) {
    
    // --- ลบบล็อก if (widget.isGuestMode ...) ที่แสดงข้อความสำหรับแขกออก ---
    
    // (โค้ดที่เหลือส่วนใหญ่เหมือนเดิม)
    final double dailyTargetCalories = historyProvider.targetCalories ?? 2000.0;
    final double consumedCaloriesToday = historyProvider.currentDayConsumedCalories ?? 0.0;
    final String weightGoal = historyProvider.weightGoal ?? 'คงที่';

    Map<String, dynamic> latestHistory = {};
    if (historyProvider.calorieHistory.isNotEmpty) {
      latestHistory = historyProvider.calorieHistory.first;
    } else {
      latestHistory = {'bmr': null, 'tdee': null, 'createdAt': null, 'timestamp': null};
    }

    DateTime? latestDateTime;
    if (latestHistory['timestamp'] is String) {
      latestDateTime = DateTime.tryParse(latestHistory['timestamp']);
    } else if (latestHistory['createdAt'] is Timestamp) {
      latestDateTime = (latestHistory['createdAt'] as Timestamp).toDate();
    } else if (latestHistory['timestamp'] is int) {
      latestDateTime = DateTime.fromMillisecondsSinceEpoch(latestHistory['timestamp']);
    }

    final formattedLatestTimestamp = latestDateTime != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(latestDateTime)
        : 'ไม่มีข้อมูล';

    final double progress =
        dailyTargetCalories > 0 ? (consumedCaloriesToday / dailyTargetCalories).clamp(0.0, 1.0) : 0.0;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'สรุปประจำวัน',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const Divider(height: 24, thickness: 1),
                if (latestHistory['bmr'] != null && latestHistory['tdee'] != null) ...[
                  Text(
                    'การคำนวณ TDEE ล่าสุด: ${latestHistory['tdee']?.toStringAsFixed(2) ?? 'N/A'} Kcal',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'เมื่อ: $formattedLatestTimestamp',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                ],
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 150,
                        height: 150,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 12,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progress < 0.8
                                ? Colors.green 
                                : (progress < 0.9
                                    ? Colors.yellow[700] ?? Colors.yellow 
                                    : (progress < 1.0
                                        ? Colors.orange 
                                        : Colors.red)), 
                          ),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${consumedCaloriesToday.toStringAsFixed(0)} Kcal',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800]),
                          ),
                          Text(
                            'จาก ${dailyTargetCalories.toStringAsFixed(0)} Kcal',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            progress < 0.8
                                ? 'ยังกินได้อีกนะ!'
                                : (progress < 0.9
                                    ? 'กินได้อีกหน่อย!'
                                    : (progress < 1.0 ? 'พอได้แล้วละมั้ง' : 'เกินเป้าหมายแล้ว!')),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: progress < 0.8
                                  ? Colors.green
                                  : (progress < 0.9
                                      ? Colors.yellow[700] ?? Colors.yellow 
                                      : (progress < 1.0
                                          ? Colors.orange
                                          : Colors.red)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Icon(Icons.track_changes, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'เป้าหมายน้ำหนัก: ',
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    Text(
                      weightGoal,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: weightGoal == 'ลดน้ำหนัก'
                            ? Colors.redAccent
                            : (weightGoal == 'เพิ่มน้ำหนัก' ? Colors.blueAccent : Colors.green),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.edit, color: primaryColor),
                      onPressed: () => _showSetWeightGoalDialog(historyProvider, primaryColor),
                    ),
                  ],
                ),
                if (historyProvider.weightGoal == 'กำหนดเอง' && historyProvider.userSetCalorieTarget != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Icon(Icons.fastfood, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          'เป้าหมายแคลอรี่: ',
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                        Text(
                          '${historyProvider.userSetCalorieTarget!.toStringAsFixed(0)} Kcal',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'ประวัติการคำนวณที่ผ่านมา',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 12),
        if (historyProvider.calorieHistory.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'ไม่มีประวัติการคำนวณ TDEE/BMR.',
                style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...historyProvider.calorieHistory.map((history) {
            DateTime? dateTime;
            if (history['timestamp'] is String) {
              dateTime = DateTime.tryParse(history['timestamp']);
            } else if (history['createdAt'] is Timestamp) {
              dateTime = (history['createdAt'] as Timestamp).toDate();
            } else if (history['timestamp'] is int) {
              dateTime = DateTime.fromMillisecondsSinceEpoch(history['timestamp']);
            }
            final formattedTimestamp = dateTime != null
                ? DateFormat('dd/MM/yyyy HH:mm').format(dateTime)
                : 'วันที่ไม่ระบุ';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedTimestamp,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Divider(height: 16, thickness: 0.5),
                    _buildInfoRow(
                      icon: Icons.monitor_weight_outlined,
                      label: 'BMR',
                      value: '${history['bmr']?.toStringAsFixed(2) ?? 'N/A'} Kcal',
                      valueColor: primaryColor.withOpacity(0.8),
                    ),
                    const SizedBox(height: 6),
                    _buildInfoRow(
                      icon: Icons.directions_run_outlined,
                      label: 'TDEE',
                      value: '${history['tdee']?.toStringAsFixed(2) ?? 'N/A'} Kcal',
                      valueColor: accentColor.withOpacity(0.8),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
      ],
    );
  }

  // --- ฟังก์ชัน _buildFoodEntriesTab ไม่มีการแก้ไข ---
  // (ยังคงทำงานเหมือนเดิม)
  Widget _buildFoodEntriesTab(List<Map<String, dynamic>> foodEntries, Color primaryColor, Color accentColor) {
    if (foodEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fastfood, size: 80, color: primaryColor.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text(
              'ยังไม่มีรายการอาหารที่บันทึกไว้',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(
              'ลองบันทึกอาหารที่คุณกินวันนี้ดูสิ!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    final Map<String, List<Map<String, dynamic>>> groupedFoodEntries = {};
    for (var entry in foodEntries) {
      DateTime? dateTime;
      if (entry['timestamp'] is String) {
        dateTime = DateTime.tryParse(entry['timestamp']);
      } else if (entry['createdAt'] is Timestamp) {
        dateTime = (entry['createdAt'] as Timestamp).toDate();
      } else if (entry['timestamp'] is int) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(entry['timestamp']);
      }

      if (dateTime != null) {
        final dateKey = DateFormat('yyyy-MM-dd').format(dateTime);
        groupedFoodEntries.putIfAbsent(dateKey, () => []).add(entry);
      }
    }

    final List<String> sortedDates = groupedFoodEntries.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final dayEntries = groupedFoodEntries[dateKey]!;

        final double totalCaloriesForDay = dayEntries.fold(0.0, (sum, entry) {
          return sum + (entry['calories'] as num? ?? 0.0);
        });

        final displayDate = DateFormat('EEEE, dd MMMM yyyy', 'th').format(DateTime.parse(dateKey));

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 10.0),
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      displayDate,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    Text(
                      'รวม: ${totalCaloriesForDay.toStringAsFixed(2)} Kcal',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20, thickness: 1),
                ...dayEntries.map((food) {
                  DateTime? entryDateTime;
                  if (food['timestamp'] is String) {
                    entryDateTime = DateTime.tryParse(food['timestamp']);
                  } else if (food['createdAt'] is Timestamp) {
                    entryDateTime = (food['createdAt'] as Timestamp).toDate();
                  } else if (food['timestamp'] is int) {
                    entryDateTime = DateTime.fromMillisecondsSinceEpoch(food['timestamp']);
                  }
                  final formattedEntryTime =
                      entryDateTime != null ? DateFormat('HH:mm').format(entryDateTime) : 'ไม่ระบุเวลา';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.fiber_manual_record, size: 10, color: Colors.grey[500]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                food['foodName'] ?? 'N/A',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                                overflow: TextOverflow.ellipsis, 
                              ),
                              Text(
                                '$formattedEntryTime | ${food['calories']?.toStringAsFixed(2) ?? 'N/A'} Kcal',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- ฟังก์ชัน _buildInfoRow ไม่มีการแก้ไข ---
  // (ยังคงทำงานเหมือนเดิม)
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color valueColor,
    bool isFlexible = false, 
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              '$label:',
              style: TextStyle(fontSize: 15, color: Colors.grey[800]),
            ),
          ],
        ),
        isFlexible
            ? Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor),
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : Text(
                value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor),
              ),
      ],
    );
  }
}