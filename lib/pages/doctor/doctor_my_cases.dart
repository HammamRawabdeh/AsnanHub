import 'package:asnan_hub/models/students.dart';
import 'package:asnan_hub/services/auth_serrvice.dart';
import 'package:flutter/material.dart';

class DoctorMyCases extends StatefulWidget {
  const DoctorMyCases({super.key});

  @override
  State<DoctorMyCases> createState() => _DoctorMyCasesState();
}

class _DoctorMyCasesState extends State<DoctorMyCases> {
    StudentUser? user;
    AuthService authService = AuthService();

    Future<void> _fetchUser() async {
    try {
      user = await authService.getStudentProfile();
    } catch (e) {
      print("Error fetching user: $e");
    }
  }

  //fetch cases (firebase.collection('cases').where(doctorId == user.userId)&& state = bookeed or completed)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cases'),
      ),
      body: const Center(
        child: Text('My Cases - To be implemented'),

        
      ),
    );
  }
}

