import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth.dart';
import 'home_page.dart';
import 'profilesetup.dart';

class LoginPage extends StatefulWidget {
  static const String routeName = '/login';
  const LoginPage({super.key});
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _auth = AuthService();
  String _email = '';
  String _password = '';
  String _inviteCode = '';
  bool _isLoading = false;

  // change this to your desired invite code
  static const String requiredInviteCode = 'G@m100200';

  void _setLoading(bool value) {
    setState(() {
      _isLoading = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login / Sign Up')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your email';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Please enter a valid email';
                    return null;
                  },
                  onChanged: (value) => _email = value.trim(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your password';
                    if (value.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                  onChanged: (value) => _password = value.trim(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Invite Code (เฉพาะสมัครใหม่)'),
                  onChanged: (v) => _inviteCode = v.trim(),
                ),
                const SizedBox(height: 16),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;
                          _setLoading(true);
                          try {
                            final res = await _auth.signInWithEmailAndPassword(_email, _password);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เข้าสู่ระบบสำเร็จ')));
                            if (res != null) {
                              Navigator.of(context).pushNamedAndRemoveUntil(HomePage.routeName, (route) => false);
                            }
                          } on FirebaseAuthException catch (e) {
                            if (e.code == 'user-not-found') {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ไม่พบอีเมล์ของท่าน/ท่านกรอกอีเมล์ไม่ถูกต้อง')));
                            } else if (e.code == 'wrong-password') {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ท่านกรอกรหัสผ่านไม่ถูกต้อง')));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.message}')));
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e')));
                          } finally {
                            _setLoading(false);
                          }
                        },
                        child: const Text('Sign In'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (!_formKey.currentState!.validate()) return;

                          // require invite code before allowing sign up
                          if (_inviteCode != requiredInviteCode) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('รหัสสำหรับสมัครไม่ถูกต้อง')));
                            return;
                          }

                          _setLoading(true);
                          try {
                            final res = await _auth.registerWithEmailAndPassword(_email, _password);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ลงทะเบียนสำเร็จ')));
                            if (res != null) {
                              Navigator.of(context).pushNamedAndRemoveUntil(Profilesetup.routeName, (route) => false);
                            }
                          } on FirebaseAuthException catch (e) {
                            if (e.code == 'weak-password') {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('รหัสผ่านที่ระบุไม่ปลอดภัย')));
                            } else if (e.code == 'email-already-in-use') {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('อีเมล์นี้ถูกใช้ไปแล้ว')));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.message}')));
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign up failed: $e')));
                          } finally {
                            _setLoading(false);
                          }
                        },
                        child: const Text('Sign Up'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
