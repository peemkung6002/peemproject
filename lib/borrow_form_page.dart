import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'auth.dart';

class BorrowFormPage extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> productData;

  const BorrowFormPage({Key? key, required this.productId, required this.productData}) : super(key: key);

  @override
  State<BorrowFormPage> createState() => _BorrowFormPageState();
}

class _BorrowFormPageState extends State<BorrowFormPage> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  int borrowAmount = 1;
  String borrowerName = '';
  String details = '';
  DateTime? borrowDate;
  DateTime? expectedReturnDate;

  // เลือกวันที่
  Future<void> _pickDate(BuildContext context, bool isBorrowDate) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        if (isBorrowDate) {
          borrowDate = picked;
        } else {
          expectedReturnDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawQuantity = widget.productData['quantity'];
    final availableQuantity = rawQuantity is int
        ? rawQuantity
        : int.tryParse(rawQuantity?.toString() ?? '0') ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text("ยืมสินค้า")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text("ชื่อสินค้า: ${widget.productData['name'] ?? ''}"),
                Text("จำนวนคงเหลือ: $availableQuantity"),
                const SizedBox(height: 16),

                // ชื่อคนยืม
                TextFormField(
                  decoration: const InputDecoration(labelText: "ชื่อคนยืม"),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "กรุณากรอกชื่อคนยืม";
                    return null;
                  },
                  onSaved: (value) => borrowerName = value!.trim(),
                ),
                const SizedBox(height: 16),

                // จำนวนที่จะยืม
                TextFormField(
                  initialValue: '1',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "จำนวนที่จะยืม"),
                  validator: (value) {
                    final num = int.tryParse(value ?? '');
                    if (num == null || num <= 0) return "กรุณากรอกจำนวนที่ถูกต้อง";
                    if (num > availableQuantity) return "จำนวนเกินสินค้าคงเหลือ";
                    return null;
                  },
                  onSaved: (value) => borrowAmount = int.parse(value!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: "รายละเอียด (เช่น ใช้ที่ไหน)"),
                  onSaved: (value) => details = value?.trim() ?? '',
                ),
                const SizedBox(height: 24),
                const SizedBox(height: 24),

                // วันที่ยืม
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        borrowDate != null
                            ? "วันที่ยืม: ${borrowDate!.toLocal().toString().split(' ')[0]}"
                            : "เลือกวันที่ยืม",
                      ),
                    ),
                    TextButton(
                      onPressed: () => _pickDate(context, true),
                      child: const Text("เลือกวันที่"),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // วันที่จะคืน
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        expectedReturnDate != null
                            ? "วันที่จะคืน: ${expectedReturnDate!.toLocal().toString().split(' ')[0]}"
                            : "เลือกวันที่จะคืน",
                      ),
                    ),
                    TextButton(
                      onPressed: () => _pickDate(context, false),
                      child: const Text("เลือกวันที่"),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            if (borrowDate == null || expectedReturnDate == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text("กรุณาเลือกวันที่ยืมและวันที่คืน")));
                              return;
                            }

                            _formKey.currentState!.save();
                            setState(() => isLoading = true);

                            try {
                              final productRef = FirebaseDatabase.instance
                                  .ref('borrowable_products/${widget.productId}');
                              final userId = _auth.currentUser!.uid;

                              // อัปเดต quantity
                              final newQuantity = availableQuantity - borrowAmount;
                              await productRef.update({'quantity': newQuantity});

                              // บันทึก borrow history
                              await FirebaseDatabase.instance
                                  .ref('borrow_history')
                                  .push()
                                  .set({
                                'userId': userId,
                                'productId': widget.productId,
                                'productName': widget.productData['name'],
                                'borrowerName': borrowerName,
                                'details': details,
                                'borrowDate': borrowDate!.toIso8601String(),
                                'expectedReturnDate': expectedReturnDate!.toIso8601String(),
                                'quantity': borrowAmount,
                                'timestamp': ServerValue.timestamp,
                              });

                              Navigator.pop(context);
                            } catch (e) {
                              setState(() => isLoading = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
                            }
                          }
                        },
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("ยืนยัน"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
