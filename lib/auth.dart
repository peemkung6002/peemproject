import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// UI/navigation removed from service; callers handle navigation and snackbars

class AuthService {
  // ประกาศตัวแปร _auth ให้สามารถเรียกใช้เมธอดและพร็อพเพอร์ตีสำคัญของ FirebaseAuth ได้
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password (no UI operations here)
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Sign out (no UI operations here)
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Check if user is authenticated
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Method for showing Snackbar
  void showSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
