import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  // ...original fields only...

  // ...remove image picker and upload logic...
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialController = TextEditingController();
  final _priceController = TextEditingController();
  final _qtyController = TextEditingController();
  final _licenseNameController = TextEditingController();
  final _licenseDescController = TextEditingController();
  final _licenseKeyController = TextEditingController();

  // Dates
  DateTime? _arriveDate;
  DateTime? _endDate;
  DateTime? _startDate;

  // Category
  String? _selectedCategory;

  final List<String> productTypes = [
    'คอม',
    'โน๊ตบุ๊ค',
    'จอมอนิเตอร์',
    'เมาส์',
    'คีย์บอร์ด',
    'License',
  ];

  Future<void> _saveProduct() async {
    final db = FirebaseDatabase.instance.ref();
    try {
      // ...remove image upload logic...
      if (_selectedCategory == "License") {
        final licenseRef = db.child("licenses").push();
        await licenseRef.set({
          "licenseName": _licenseNameController.text,
          "description": _licenseDescController.text,
          "key": _licenseKeyController.text,
          "startDate": _startDate != null
              ? "${_startDate!.day}/${_startDate!.month}/${_startDate!.year}"
              : "-",
          "endDate": _endDate != null
              ? "${_endDate!.day}/${_endDate!.month}/${_endDate!.year}"
              : "-",
          "createdAt": DateTime.now().toIso8601String(),
        });
      } else {
    final productRef = db.child("products").push();
    await productRef.set({
      "type": _selectedCategory ?? '-',
      "brand": _brandController.text,
      "model": _modelController.text,
    "serialNumber": _serialController.text,
      "price": _priceController.text,
      "arriveDate": _arriveDate != null
        ? "${_arriveDate!.day}/${_arriveDate!.month}/${_arriveDate!.year}"
        : "-",
      "endDate": _endDate != null
        ? "${_endDate!.day}/${_endDate!.month}/${_endDate!.year}"
        : "-",
      "createdAt": DateTime.now().toIso8601String(),
    });
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ บันทึกข้อมูลเรียบร้อย")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ เกิดข้อผิดพลาด: $e")),
      );
    }
  }

  Future<void> _pickDate(Function(DateTime) onPicked) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) onPicked(pickedDate);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return "${date.day}/${date.month}/${date.year}";
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    _priceController.dispose();
    _qtyController.dispose();
    _licenseNameController.dispose();
    _licenseDescController.dispose();
    _licenseKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("บันทึกข้อมูลสินค้า")),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
              // ...remove image picker and preview UI...
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(labelText: "ประเภทสินค้า"),
                items: productTypes
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
                validator: (value) => value == null ? "กรุณาเลือกประเภทสินค้า" : null,
              ),
              const SizedBox(height: 16),
              if (_selectedCategory == "License") ...[
                // License-specific fields
                TextFormField(
                  controller: _licenseNameController,
                  decoration: const InputDecoration(labelText: "ชื่อ License"),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกชื่อ License';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _licenseDescController,
                  decoration: const InputDecoration(labelText: "รายละเอียด"),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _licenseKeyController,
                  decoration: const InputDecoration(labelText: "Key"),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'กรุณากรอก Key';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  readOnly: true,
                  decoration: const InputDecoration(labelText: "วันที่เริ่มใช้งาน"),
                  controller: TextEditingController(text: _formatDate(_startDate)),
                  onTap: () => _pickDate((date) {
                    setState(() {
                      _startDate = date;
                    });
                  }),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  readOnly: true,
                  decoration: const InputDecoration(labelText: "วันหมดอายุ License"),
                  controller: TextEditingController(text: _formatDate(_endDate)),
                  onTap: () => _pickDate((date) {
                    setState(() {
                      _endDate = date;
                    });
                  }),
                ),
              ] else ...[
                // Non-license product fields
                TextFormField(
                  controller: _brandController,
                  decoration: const InputDecoration(labelText: "ยี่ห้อ (Brand)"),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _modelController,
                  decoration: const InputDecoration(labelText: "รุ่น (Model)"),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _serialController,
                  decoration: const InputDecoration(labelText: "Serial Number"),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: "ราคา"),
                  keyboardType: TextInputType.number,
                ),
                // quantity field removed as requested
                const SizedBox(height: 12),
                TextFormField(
                  readOnly: true,
                  decoration: const InputDecoration(labelText: "วันที่ของมาถึง / เริ่มใช้"),
                  controller: TextEditingController(text: _formatDate(_arriveDate)),
                  onTap: () => _pickDate((date) {
                    setState(() {
                      _arriveDate = date;
                    });
                  }),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  readOnly: true,
                  decoration: const InputDecoration(labelText: "วันหมดอายุอุปกรณ์"),
                  controller: TextEditingController(text: _formatDate(_endDate)),
                  onTap: () => _pickDate((date) {
                    setState(() {
                      _endDate = date;
                    });
                  }),
                ),
              ],
                                    const SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
                                          _saveProduct();
                                        }
                                      },
                                      icon: const Icon(Icons.save),
                                      label: const Text("บันทึกข้อมูล"),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                    }
