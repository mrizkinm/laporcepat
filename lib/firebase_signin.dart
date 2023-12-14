import 'package:firebase_auth/firebase_auth.dart';

class FirebaseSignin {
  Future<void> signInWithEmailAndPassword() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'laporcepat@gmail.com',
        password: '123456',
      );
    } catch (e) {
      print("Error during sign in: $e");
    }
  }
}
