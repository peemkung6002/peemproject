import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'auth.dart';

class ReturnFormPage extends StatefulWidget {
  final String productId;
  final Map<String, dynamic> productData;

  const ReturnFormPage({Key? key, required this.productId, required this.productData}) : super(key: key);

  @override
  State<ReturnFormPage> createState() => _ReturnFormPageState();
}

class _ReturnFormPageState extends State<ReturnFormPage> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  int returnAmount = 1;
  String borrowerName = '';

  @override
  Widget build(BuildContext context) {
    final rawQuantity = widget.productData['quantity'];
    final availableQuantity = rawQuantity is int
        ? rawQuantity
        : int.tryParse(rawQuantity?.toString() ?? '0') ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text("คืนสินค้า")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text("ชื่อสินค้า: ${widget.productData['name'] ?? ''}"),
              Text("จำนวนคงเหลือ: $availableQuantity"),
              const SizedBox(height: 16),

              // ชื่อคนคืน
              TextFormField(
                decoration: const InputDecoration(labelText: "ชื่อคนคืน"),
                validator: (value) {
                  if (value == null || value.isEmpty) return "กรุณากรอกชื่อคนคืน";
                  return null;
                },
                onSaved: (value) => borrowerName = value!.trim(),
              ),
              const SizedBox(height: 16),

              // จำนวนที่จะคืน
              TextFormField(
                initialValue: '1',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "จำนวนที่จะคืน"),
                validator: (value) {
                  final num = int.tryParse(value ?? '');
                  if (num == null || num <= 0) return "กรุณากรอกจำนวนที่ถูกต้อง";
                  return null;
                },
                onSaved: (value) => returnAmount = int.parse(value!),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          setState(() => isLoading = true);

                          try {
                            final productRef = FirebaseDatabase.instance
                                .ref('borrowable_products/${widget.productId}');
                            final userId = _auth.currentUser!.uid;

                            // อัปเดต quantity
                            final newQuantity = availableQuantity + returnAmount;
                            await productRef.update({'quantity': newQuantity});

                            // บันทึก return history
                            await FirebaseDatabase.instance
                                .ref('return_history')
                                .push()
                                .set({
                              'userId': userId,
                              'productId': widget.productId,
                              'productName': widget.productData['name'],
                              'borrowerName': borrowerName,
                              'quantity': returnAmount,
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
    );
  }
}
