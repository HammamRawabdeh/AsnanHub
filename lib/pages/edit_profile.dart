import 'package:asnan_hub/models/students.dart';
import 'package:asnan_hub/models/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditProfile extends StatefulWidget {
  final UserModel? patientUser;
  final StudentUser? studentUser;

  const EditProfile({super.key, this.patientUser, this.studentUser});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController universityIdController;
  
  String? selectedGender;
  int? selectedYear;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill the data based on who is logged in
    if (widget.studentUser != null) {
      nameController = TextEditingController(text: widget.studentUser!.name);
      phoneController = TextEditingController(text: widget.studentUser!.phone);
      emailController = TextEditingController(text: widget.studentUser!.email);
      universityIdController = TextEditingController(text: widget.studentUser!.universityId);
      selectedGender = widget.studentUser!.gender;
      selectedYear = widget.studentUser!.year;
    } else {
      nameController = TextEditingController(text: widget.patientUser!.name);
      phoneController = TextEditingController(text: widget.patientUser!.phone);
      emailController = TextEditingController(text: widget.patientUser!.email);
      universityIdController = TextEditingController(); // Not used for patient
      selectedGender = widget.patientUser!.gender;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    universityIdController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      String uid;
      String collection;
      Map<String, dynamic> updateData = {
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(), // Note: This updates DB only, not Auth login
        'gender': selectedGender,
      };

      if (widget.studentUser != null) {
        uid = widget.studentUser!.uid;
        collection = 'students';
        // Add student-specific fields
        updateData['universityId'] = universityIdController.text.trim();
        updateData['year'] = selectedYear;
        // NOTE: We deliberately do NOT include 'casesCompleted' here
      } else {
        uid = widget.patientUser!.uid;
        collection = 'users';
      }

      // Update Firestore
      await FirebaseFirestore.instance.collection(collection).doc(uid).update(updateData);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true); // Return "true" to signal a refresh is needed
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = widget.studentUser != null;

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 1. Name
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person)),
                validator: (v) => v!.isEmpty ? "Name is required" : null,
              ),
              const SizedBox(height: 15),

              // 2. Email (Editable in DB, but add warning)
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email", 
                  prefixIcon: Icon(Icons.email),
                  helperText: "Note: Changing this won't change your login email",
                ),
                validator: (v) => v!.isEmpty ? "Email is required" : null,
              ),
              const SizedBox(height: 15),

              // 3. Phone
              TextFormField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone", prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? "Phone is required" : null,
              ),
              const SizedBox(height: 15),

              // 4. Student Specific Fields
              if (isStudent) ...[
                TextFormField(
                  controller: universityIdController,
                  decoration: const InputDecoration(labelText: "University ID", prefixIcon: Icon(Icons.badge)),
                  validator: (v) => v!.isEmpty ? "ID is required" : null,
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<int>(
                  value: selectedYear,
                  decoration: const InputDecoration(labelText: "Year", prefixIcon: Icon(Icons.school)),
                  items: const [
                    DropdownMenuItem(value: 4, child: Text("4th Year")),
                    DropdownMenuItem(value: 5, child: Text("5th Year")),
                  ],
                  onChanged: (val) => setState(() => selectedYear = val),
                ),
                const SizedBox(height: 15),
              ],

              // 5. Gender
              DropdownButtonFormField<String>(
                value: selectedGender,
                decoration: const InputDecoration(labelText: "Gender", prefixIcon: Icon(Icons.wc)),
                items: const [
                  DropdownMenuItem(value: "male", child: Text("Male")),
                  DropdownMenuItem(value: "female", child: Text("Female")),
                ],
                onChanged: (val) => setState(() => selectedGender = val),
              ),

              const SizedBox(height: 30),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Save Changes"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}