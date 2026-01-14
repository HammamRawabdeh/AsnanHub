import 'package:asnan_hub/models/students.dart';
import 'package:asnan_hub/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class AuthService {
final FirebaseAuth _auth = FirebaseAuth.instance;

//patient
Future<UserModel?> getUserProfile() async {
  // 1. Get the current user's UID
  String? uid = FirebaseAuth.instance.currentUser?.uid;

  if (uid == null) {
    return null; // User not logged in
  }

  try {
    // 2. Fetch the document from the 'users' collection
    DocumentSnapshot userDoc = 
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    // 3. Check if it exists and read data
    if (userDoc.exists && userDoc.data() != null) {
      // Access fields using data() method which returns Map<String, dynamic>?
      final data = userDoc.data() as Map<String, dynamic>;
  
      return UserModel.fromMap(data);
    } else {
      return null;
    }
  } catch (e) {
    return null;
  }
}
//doctor student
Future<StudentUser?> getStudentProfile() async {
  String? uid = FirebaseAuth.instance.currentUser?.uid;

  //if the user is not logged in
  if (uid == null) {
    return null; 
  }

  try {
    // 2. Fetch the document from the 'students' collection
    DocumentSnapshot userDoc = 
        await FirebaseFirestore.instance.collection('students').doc(uid).get();

    // 3. Check if it exists and read data
    if (userDoc.exists && userDoc.data() != null) {
      // Access fields using data() method which returns Map<String, dynamic>?
      final data = userDoc.data() as Map<String, dynamic>;
  
      var user = StudentUser.fromMap(data);
      return user;
    } else {
      return null;
    }
  } catch (e) {
    return null;
  }
}

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


