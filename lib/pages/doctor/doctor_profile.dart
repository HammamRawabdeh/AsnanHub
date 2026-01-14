import 'package:asnan_hub/models/students.dart';
import 'package:asnan_hub/models/user.dart';
import 'package:asnan_hub/services/auth_serrvice.dart';
import 'package:asnan_hub/widgets/profile_header.dart';
import 'package:asnan_hub/widgets/profile_info_card.dart';
import 'package:asnan_hub/widgets/student_profile_info_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:asnan_hub/pages/edit_profile.dart';

class DoctorProfile extends StatefulWidget {
  const DoctorProfile({super.key});

  @override
  State<DoctorProfile> createState() => _DoctorProfileState();
}

class _DoctorProfileState extends State<DoctorProfile> {
  StudentUser? studentUser;
  UserModel? patientUser;
  var authService = AuthService();
  bool loading = false;
  bool isStudent = true; // Default to student, will check both

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => loading = true);
    try {
      // First try to fetch student profile
      studentUser = await authService.getStudentProfile();
      
      // If not a student, try to fetch patient profile
      if (studentUser == null) {
        patientUser = await authService.getUserProfile();
        isStudent = false;
      } else {
        isStudent = true;
      }
    } catch (e) {
      print("Error fetching profile: $e");
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _handleSignOut() async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sign Out"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Sign Out"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (studentUser == null && patientUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Profile not found',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Please make sure you have completed your profile',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    // Determine which profile to show
    final String name;
    final String email;

    if (isStudent && studentUser != null) {
      name = studentUser!.name;
      email = studentUser!.email;
    } else if (patientUser != null) {
      name = patientUser!.name;
      email = patientUser!.email;
    } else {
      return Scaffold(
        body: Center(
          child: Text(
            'Profile data unavailable',
            style: theme.textTheme.titleLarge,
          ),
        ),
      );
    }

    return Scaffold(
  appBar: AppBar(
    title: const Text("My Profile"),
    actions: [
      IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () async {
          // Determine which user object to pass
          bool? updated = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditProfile(
                studentUser: studentUser, // Pass student if it exists
                patientUser: patientUser, // Pass patient as fallback
              ),
            ),
          );

          if (updated == true) {
            _fetchProfile(); // Refresh data
          }
        },
      ),
    ],
  ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            ProfileHeader(
              name: name,
              email: email,
            ),

            // Profile Information
            Padding(
              padding: const EdgeInsets.all(20),
              child: isStudent && studentUser != null
                  ? StudentProfileInfoCard(user: studentUser!)
                  : patientUser != null
                      ? ProfileInfoCard(user: patientUser!)
                      : const SizedBox.shrink(),
            ),

            // Sign Out Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _handleSignOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

