import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:scrum_poker/shared/services/base_services.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthServices extends BaseServices {
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

  Future<User?> signInWithJira() async {
    final ulr = '${baseUrl}/start?redirectUri=http://localhost:1010/';

    launchUrl(Uri.parse(ulr), webOnlyWindowName: '_self');
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
