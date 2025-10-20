import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
// ...original imports only...

class EditPage extends StatefulWidget {
  final String itemKey;
  final Map<String, dynamic> itemData;
  final String itemType; // "สินค้า" หรือ "License"

  const EditPage({
    super.key,
    required this.itemKey,
    required this.itemData,
    required this.itemType,
  });

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  String? _uploadedImageUrl;
  DateTime? _arriveDate;
  DateTime? _endDate;
  DateTime? _licenseStartDate;
  DateTime? _licenseEndDate;

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return "${date.day}/${date.month}/${date.year}";
  }

  Future<void> _pickDate(DateTime? initialDate, Function(DateTime) onPicked) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) onPicked(pickedDate);
  }
  final _formKey = GlobalKey<FormState>();
  late DatabaseReference dbRef;

  // สำหรับ Product
  late TextEditingController nameController;
  late TextEditingController typeController;
  // custom type support removed; use typeController directly
  late TextEditingController brandController;
  late TextEditingController modelController;
  late TextEditingController serialController;
  late TextEditingController priceController;
  late TextEditingController quantityController;
  late TextEditingController arriveDateController;
  late TextEditingController endDateController;

  // สำหรับ License
  late TextEditingController licenseNameController;
  late TextEditingController startDateController;
  late TextEditingController licenseEndDateController;
  late TextEditingController licenseDescController;
  late TextEditingController licenseKeyController;

  @override
  void initState() {
    super.initState();
    dbRef = FirebaseDatabase.instance.ref(
        widget.itemType == "License" ? "licenses" : "products");

    // ✅ set ค่าเริ่มต้น
    nameController = TextEditingController(text: widget.itemData["name"] ?? "");
  typeController = TextEditingController(text: widget.itemData["type"] ?? "");
    brandController = TextEditingController(text: widget.itemData["brand"] ?? "");
    modelController = TextEditingController(text: widget.itemData["model"] ?? "");
  serialController = TextEditingController(text: widget.itemData["serialNumber"] ?? "");
  priceController = TextEditingController(text: widget.itemData["price"] ?? "");
    quantityController = TextEditingController(text: widget.itemData["quantity"] ?? "");
    arriveDateController = TextEditingController(text: widget.itemData["arriveDate"] ?? "");
    endDateController = TextEditingController(text: widget.itemData["endDate"] ?? "");

    licenseNameController = TextEditingController(text: widget.itemData["licenseName"] ?? "");
    startDateController = TextEditingController(text: widget.itemData["startDate"] ?? "");
    licenseEndDateController = TextEditingController(text: widget.itemData["endDate"] ?? "");
  licenseDescController = TextEditingController(text: widget.itemData["description"] ?? "");
    licenseKeyController = TextEditingController(text: widget.itemData["key"] ?? "");
    // no custom type handling here; keep typeController as-is
    // Parse existing date strings (dd/MM/yyyy) into DateTime so pickers can use them
    DateTime? tryParse(String? s) {
      if (s == null) return null;
      final trimmed = s.trim();
      if (trimmed.isEmpty) return null;
      try {
        final parts = trimmed.split('/');
        if (parts.length == 3) {
          final d = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final y = int.tryParse(parts[2]);
          if (d != null && m != null && y != null) return DateTime(y, m, d);
        }
        return DateTime.tryParse(trimmed);
      } catch (_) {
        return DateTime.tryParse(trimmed);
      }
    }

    _arriveDate = tryParse(arriveDateController.text);
    _endDate = tryParse(endDateController.text);
    _licenseStartDate = tryParse(startDateController.text);
    _licenseEndDate = tryParse(licenseEndDateController.text);
  }

  @override
  void dispose() {
    // ปิด controller
    nameController.dispose();
    typeController.dispose();
    brandController.dispose();
    modelController.dispose();
  serialController.dispose();
  priceController.dispose();
    quantityController.dispose();
    arriveDateController.dispose();
    endDateController.dispose();
    licenseNameController.dispose();
    startDateController.dispose();
    licenseEndDateController.dispose();
    licenseDescController.dispose();
    licenseKeyController.dispose();
  // custom controller disposed earlier removed
    super.dispose();
  }

  Future<void> _updateData() async {
    if (_formKey.currentState!.validate()) {
      Map<String, dynamic> updateData;

      if (widget.itemType == "License") {
        updateData = {
          "licenseName": licenseNameController.text,
          "startDate": startDateController.text,
          "endDate": licenseEndDateController.text,
          "description": licenseDescController.text,
          "key": licenseKeyController.text,
        };
          } else {
        updateData = {
          "name": nameController.text,
          "type": typeController.text.trim(),
          "brand": brandController.text,
          "model": modelController.text,
          "serialNumber": serialController.text,
          "price": priceController.text,
          "quantity": quantityController.text,
          "arriveDate": _arriveDate != null ? _formatDate(_arriveDate) : arriveDateController.text,
          "endDate": _endDate != null ? _formatDate(_endDate) : endDateController.text,
          "imageUrl": _uploadedImageUrl ?? widget.itemData['imageUrl'] ?? "",
        };
      }

      await dbRef.child(widget.itemKey).update(updateData);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("อัปเดตข้อมูลเรียบร้อย ✅")),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("แก้ไข${widget.itemType}"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: widget.itemType == "License"
              ? [
                    TextFormField(
                      controller: licenseNameController,
                      decoration: const InputDecoration(labelText: "ชื่อ License"),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: licenseDescController,
                      decoration: const InputDecoration(labelText: "รายละเอียด"),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: licenseKeyController,
                      decoration: const InputDecoration(labelText: "Key"),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      readOnly: true,
                      decoration: const InputDecoration(labelText: "วันที่เริ่มใช้"),
                      controller: TextEditingController(text: _licenseStartDate != null ? _formatDate(_licenseStartDate) : startDateController.text),
                      onTap: () => _pickDate(_licenseStartDate, (date) {
                        setState(() {
                          _licenseStartDate = date;
                          startDateController.text = _formatDate(date);
                        });
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      readOnly: true,
                      decoration: const InputDecoration(labelText: "วันหมดอายุ"),
                      controller: TextEditingController(text: _licenseEndDate != null ? _formatDate(_licenseEndDate) : licenseEndDateController.text),
                      onTap: () => _pickDate(_licenseEndDate, (date) {
                        setState(() {
                          _licenseEndDate = date;
                          licenseEndDateController.text = _formatDate(date);
                        });
                      }),
                    ),
                  ]
                : [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "ชื่อสินค้า"),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: typeController,
                      decoration: const InputDecoration(labelText: "ประเภท"),
                    ),
                    const SizedBox(height: 12),
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
                    TextFormField(
                      controller: serialController,
                      decoration: const InputDecoration(labelText: "Serial Number"),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: "ราคา"),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: quantityController,
                      decoration: const InputDecoration(labelText: "จำนวน"),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      readOnly: true,
                      decoration: const InputDecoration(labelText: "วันที่ของมาถึง / เริ่มใช้"),
                      controller: TextEditingController(text: _arriveDate != null ? _formatDate(_arriveDate) : arriveDateController.text),
                      onTap: () => _pickDate(_arriveDate, (date) {
                        setState(() {
                          _arriveDate = date;
                          arriveDateController.text = _formatDate(date);
                        });
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      readOnly: true,
                      decoration: const InputDecoration(labelText: "วันหมดอายุอุปกรณ์"),
                      controller: TextEditingController(text: _endDate != null ? _formatDate(_endDate) : endDateController.text),
                      onTap: () => _pickDate(_endDate, (date) {
                        setState(() {
                          _endDate = date;
                          endDateController.text = _formatDate(date);
                        });
                      }),
                    ),
                  ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _updateData,
        child: const Icon(Icons.save),
      ),
    );
  }
}
