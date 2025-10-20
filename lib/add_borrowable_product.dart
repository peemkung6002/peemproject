import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
// ...original imports only...

class AddBorrowableProductPage extends StatefulWidget {
  const AddBorrowableProductPage({Key? key}) : super(key: key);

  @override
  State<AddBorrowableProductPage> createState() => _AddBorrowableProductPageState();
}

class _AddBorrowableProductPageState extends State<AddBorrowableProductPage> {
  // ...original fields only...

  // ...remove image picker and upload logic...
  final DatabaseReference borrowableRef = FirebaseDatabase.instance.ref().child("borrowable_products");

  final TextEditingController nameController = TextEditingController();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController totalController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final total = int.tryParse(totalController.text.trim()) ?? 0;
      await borrowableRef.push().set({
        "name": nameController.text.trim(),
        "type": typeController.text.trim(),
        "brand": brandController.text.trim(),
        "model": modelController.text.trim(),
        // store the configured maximum and set initial available quantity to that value
        "total": total,
        "quantity": total,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("บันทึกสินค้าสำหรับยืมเรียบร้อย")));
      nameController.clear();
      typeController.clear();
      brandController.clear();
      modelController.clear();
      totalController.clear();
      // ...remove image state reset...
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("เพิ่มสินค้าสำหรับยืม")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "ชื่อสินค้า"),
                validator: (v) => v == null || v.isEmpty ? "กรุณากรอกชื่อสินค้า" : null,
              ),
              const SizedBox(height: 12),
              // ...remove image picker and preview UI...
              TextFormField(
                controller: typeController,
                decoration: const InputDecoration(labelText: "ประเภท"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: brandController,
                decoration: const InputDecoration(labelText: "ยี่ห้อ"),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: modelController,
                decoration: const InputDecoration(labelText: "รุ่น"),
              ),
              const SizedBox(height: 12),
              // serial removed per request
              const SizedBox(height: 12),
              TextFormField(
                controller: totalController,
                decoration: const InputDecoration(labelText: "จำนวนทั้งหมด (max)"),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return "กรุณากรอกจำนวนทั้งหมด";
                  if (int.tryParse(v) == null) return "กรุณากรอกตัวเลขที่ถูกต้อง";
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProduct,
                child: const Text("บันทึกสินค้า"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
