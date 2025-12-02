// นำเข้าไลบรารีที่จำเป็น
import 'package:flutter/material.dart'; // ไลบรารีหลักของ Flutter สำหรับสร้าง UI
import 'package:calorie_calculator/data/predefined_foods.dart'; // import ฐานข้อมูลอาหารสำเร็จรูปของเรา

// คลาสหลักของหน้าจอค้นหาอาหาร เป็น StatefulWidget เพราะหน้าจอต้องมีการเปลี่ยนแปลงข้อมูล (รายการอาหาร) ตามที่ผู้ใช้พิมพ์
class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

// คลาส State ที่จัดการสถานะและ UI ของ FoodSearchScreen
class _FoodSearchScreenState extends State<FoodSearchScreen> {
  String _searchQuery = ''; // ตัวแปรสำหรับเก็บข้อความที่ผู้ใช้พิมพ์ในช่องค้นหา
  List<Map<String, dynamic>> _filteredFoods = []; // ตัวแปรสำหรับเก็บรายการอาหารที่ถูกกรองแล้ว

  @override
  void initState() {
    super.initState();
    _filteredFoods = predefinedFoods; // เมื่อหน้าจอเริ่มต้น ให้แสดงรายการอาหารทั้งหมดจาก predefinedFoods
  }

  // ฟังก์ชันสำหรับกรองรายการอาหารตามคำค้นหาที่ผู้ใช้ป้อน
  void _filterFoods(String query) {
    setState(() {
      _searchQuery = query; // อัปเดตตัวแปร _searchQuery
      if (query.isEmpty) {
        _filteredFoods = predefinedFoods; // ถ้าช่องค้นหาว่างเปล่า ให้แสดงอาหารทั้งหมด
      } else {
        // กรองรายการอาหารโดยใช้เมธอด where()
        _filteredFoods = predefinedFoods
            .where((food) =>
                // food['foodName'].toLowerCase().contains(query.toLowerCase())
                // ตรวจสอบว่าชื่ออาหาร (foodName) มีคำค้นหาอยู่หรือไม่ โดยแปลงเป็นตัวพิมพ์เล็กทั้งคู่เพื่อไม่ให้ Sensitive
                food['foodName'].toLowerCase().contains(query.toLowerCase()))
            .toList(); // แปลงผลลัพธ์ที่ได้กลับเป็น List
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ดึงสีที่กำหนดไว้ใน Theme ของแอป เพื่อให้ UI มีความสอดคล้องกัน
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color accentColor = Theme.of(context).colorScheme.secondary;
    final Color scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor, // กำหนดสีพื้นหลังของ Scaffold
      // ส่วนของ AppBar
      appBar: AppBar(
        title: const Text('ค้นหารายการอาหาร'),
        centerTitle: true,
      ),
      // ส่วนของเนื้อหาในหน้าจอ
      body: Column(
        children: [
          // แสดงข้อความหมายเหตุเกี่ยวกับค่าแคลอรี่ที่เป็นค่าประมาณ
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
            child: Text(
              '**หมายเหตุ:** ค่าแคลอรี่เป็นค่าประมาณการ อาจไม่แม่นยำ 100% ขึ้นอยู่กับส่วนผสมและวิธีการปรุงและปริมาณ',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // ช่องกรอกข้อมูลสำหรับค้นหาอาหาร
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration( // ใช้ InputDecoration สำหรับการปรับแต่งช่องกรอกข้อความ
                labelText: 'ค้นหาชื่ออาหาร',
                hintText: 'เช่น ผัดกะเพรา, ข้าวผัด',
                prefixIcon: Icon(Icons.search, color: primaryColor), // ไอคอนค้นหา
                border: OutlineInputBorder( // เพิ่มเส้นขอบรอบช่อง
                  borderRadius: BorderRadius.circular(10), // ทำให้ขอบมน
                ),
                focusedBorder: OutlineInputBorder( // เส้นขอบเมื่อช่องถูกเลือก
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: primaryColor, width: 2), // สีเส้นขอบเมื่อ focus
                ),
                labelStyle: TextStyle(color: primaryColor.withOpacity(0.7)),
                hintStyle: TextStyle(color: Colors.grey[500]),
              ),
              onChanged: _filterFoods, // เมื่อข้อความเปลี่ยน จะเรียกฟังก์ชัน _filterFoods
              cursorColor: primaryColor, // กำหนดสีของเคอร์เซอร์
            ),
          ),
          // ส่วนสำหรับแสดงรายการอาหารที่ค้นหาเจอ
          Expanded( // Expanded จะทำให้ ListView ใช้พื้นที่ที่เหลือทั้งหมด
            child: _filteredFoods.isEmpty
                ? Center(
                    // แสดงผลลัพธ์กรณีที่ไม่พบอาหารที่ค้นหา
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 80, color: primaryColor.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text(
                          'ไม่พบอาหารที่ค้นหา',
                          style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder( // แสดงผลลัพธ์เป็นรายการ List
                    itemCount: _filteredFoods.length,
                    itemBuilder: (context, index) {
                      final food = _filteredFoods[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          title: Text(
                            food['foodName'],
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          subtitle: Text(
                            '${food['calories'].toStringAsFixed(0)} Kcal (${food['unit']})',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          trailing: Icon(Icons.add_circle_outline, color: accentColor), // ไอคอนเพิ่มอาหาร
                          onTap: () {
                            // เมื่อผู้ใช้เลือกอาหาร ให้ส่งข้อมูลอาหารนั้นกลับไปยังหน้าจอก่อนหน้า
                            Navigator.pop(context, {
                              'foodName': food['foodName'],
                              'calories': food['calories'],
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}