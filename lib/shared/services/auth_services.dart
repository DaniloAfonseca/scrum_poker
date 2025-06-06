import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthServices {
  final auth = FirebaseAuth.instance;

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await auth.signInWithEmailAndPassword(email: email, password: password);

      return userCredential.user;
    } catch (e) {
      if (kDebugMode) {
        print('Error signing in: $e');
      }
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
    }
  }
}
