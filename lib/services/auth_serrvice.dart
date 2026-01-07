import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
final FirebaseAuth _auth = FirebaseAuth.instance;

Future<UserCredential> signUp(String email, String password) async {
  try {
    var user = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return user;
  } on FirebaseAuthException catch (e) {
    throw e.message ?? "Sign up failed: ${e.code}";
  } catch (e) {
    throw "An unexpected error occurred: ${e.toString()}";
  }
}


Future<UserCredential> signIn(String email, String password) async {
  try {
    var user = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return user;
  } on FirebaseAuthException catch (e) {
    throw e.message ?? "Login failed: ${e.code}";
  } catch (e) {
    throw "An unexpected error occurred: ${e.toString()}";
  }
}
}


