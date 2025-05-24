import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final authProvider = Provider<AuthNotifier>((ref) {
  return AuthNotifier();
});

class AuthNotifier {
  Future<User?> signIn(String email, String password) async {
    return await FirebaseService.signInWithEmailAndPassword(email, password);
  }

  Future<void> signOut() async {
    await FirebaseService.signOut();
  }

  User? get currentUser => FirebaseService.currentUser;
}
