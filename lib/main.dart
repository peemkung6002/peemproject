import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth.dart'; // นาเข้าไฟล์ที่ต้องการเรียกใช้จากหน้า 'auth.dart'
import 'signin_page.dart'; // นาเข้าไฟล์ที่ต้องการเรียกใช้จากหน้า 'signin_page.dart'
import 'home_page.dart'; // นาเข้าไฟล์ที่ต้องการเรียกใช้จากหน้า 'homepage_page.dart'
import 'profilesetup.dart';

// Method หลักที่ใช้รันแอป
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(options: FirebaseOptions(
        apiKey: "AIzaSyA05keBh2ZtTQdIbK73TlLxFvOlFm8WHfA",

        authDomain: "newprojectpeem.firebaseapp.com",

        databaseURL: "https://newprojectpeem-default-rtdb.firebaseio.com",

        projectId: "newprojectpeem",

        storageBucket: "newprojectpeem.firebasestorage.app",

        messagingSenderId: "362802266328",

        appId: "1:362802266328:web:e27e24c188299409f817ad",

        measurementId: "G-XXWPZ3B3GQ",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(MyApp());
}

// Class MyApp สาหรับการแสดงผลหน้าจอ
class MyApp extends StatelessWidget {
  MyApp({super.key});
  // ตรวจสอบ AuthService
  final AuthService _auth = AuthService();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, primary: Colors.green, secondary: Colors.grey),
        primaryColor: Colors.green,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green[700],
          iconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20.0),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.green[700]),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[200],
          contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0),
          border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade400)),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green.shade700)),
          labelStyle: TextStyle(color: Colors.green[700]),
        ),
      ),
      home: StreamBuilder(
        stream: _auth.authStateChanges, // ตรวจสอบการเชื่อมต่อ Stream
        builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return HomePage(); // ตรวจสอบว่ามี HomePage และทางานได้
          } else {
            return const LoginPage(); // ตรวจสอบว่ามี LoginPage และทางานได้
          }
        },
      ),
      routes: {
        LoginPage.routeName: (BuildContext context) => const LoginPage(),
        HomePage.routeName: (BuildContext context) => HomePage(),
        Profilesetup.routeName: (BuildContext context) => Profilesetup(),
      },
    );
  }
}
