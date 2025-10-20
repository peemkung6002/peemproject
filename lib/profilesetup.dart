import 'package:flutter/material.dart';
// image picking and storage removed per request
import 'package:firebase_database/firebase_database.dart';
// removed unused imports after disabling image upload
import 'auth.dart';
import 'home_page.dart';

class Profilesetup extends StatefulWidget {
  static const String routeName = '/profilesetup';
  @override
  State<Profilesetup> createState() => _ProfilesetupState();
}

class _ProfilesetupState extends State<Profilesetup> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _username = TextEditingController();
  final TextEditingController _phoneNumber = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  // image fields removed
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final prefix = ['นาย', 'นาง', 'นางสาว'];
  String? _selectedPrefix;
  DateTime? birthdayDate;

  Future<void> pickProductionDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: birthdayDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        birthdayDate = pickedDate;
        _birthDateController.text =
            "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      });
    }
  }

  Future<void> _uploadProfile(String uid) async {
    try {
      await _dbRef.child('user/$uid').set({
        'prefix': _selectedPrefix ?? '',
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        'username': _username.text.trim(),
        'phoneNumber': _phoneNumber.text.trim(),
        'birthDate': birthdayDate?.toIso8601String() ?? '',
        'profileComplete': true,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error uploading profile: $e')));
    }
  }

  void _submitForm() async {
    final user = AuthService().currentUser;
    if (_formKey.currentState!.validate() && user != null) {
      _formKey.currentState!.save();
      await _uploadProfile(user.uid);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, HomePage.routeName);
    }
  }

  // image picking removed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ตั้งค่าโปรไฟล์')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              // profile image UI removed per request
              DropdownButtonFormField<String>(
                value: _selectedPrefix,
                decoration: InputDecoration(labelText: 'คำนำหน้า (Prefix)'),
                items: prefix
                    .map((category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPrefix = value!;
                  });
                },
              ),
              TextFormField(
                controller: _firstName,
                decoration: InputDecoration(labelText: 'ชื่อ (First Name)'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'กรุณากรอกชื่อ' : null,
              ),
              TextFormField(
                controller: _lastName,
                decoration: InputDecoration(labelText: 'นามสกุล (Last Name)'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'กรุณากรอกนามสกุล' : null,
              ),
              TextFormField(
                controller: _username,
                decoration: InputDecoration(labelText: 'ชื่อผู้ใช้ (Username)'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'กรุณากรอกชื่อผู้ใช้' : null,
              ),
              TextFormField(
                controller: _phoneNumber,
                decoration: InputDecoration(labelText: 'เบอร์โทรศัพท์'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'กรุณากรอกเบอร์โทร' : null,
              ),
              TextFormField(
                controller: _birthDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'วันเกิด (BirthDay)',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => pickProductionDate(context),
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'กรุณาเลือกวันเกิด' : null,
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: Text('บันทึก'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
