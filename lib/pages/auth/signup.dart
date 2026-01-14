import 'package:asnan_hub/extensions/snackbar_extension.dart';
import 'package:asnan_hub/models/students.dart';
import 'package:asnan_hub/models/user.dart';
import 'package:asnan_hub/models/user_role.dart';
import 'package:asnan_hub/pages/auth/login.dart';
import 'package:asnan_hub/pages/doctor/doctor_main.dart';
import 'package:asnan_hub/pages/patient/patient_main.dart';
import 'package:asnan_hub/services/auth_serrvice.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Signup extends StatefulWidget {
  final UserRole? role;

  const Signup({super.key, this.role});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController universityIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  int? year;
  String? gender;
  GlobalKey<FormState> formKey = GlobalKey();

  var authService = AuthService();
  bool _isLoading = false;
  bool _isObscured = true; //to track visibility

  void handleSignup() async {
    if (!formKey.currentState!.validate()) return;
    if (gender == null) {
      context.showErrorSnackBar("Please select gender", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1️⃣ Sign up the user in Firebase Auth
      var userCredential = await authService.signUp(
        emailController.text.trim(),
        passwordController.text,
      );

      final user = userCredential.user;
      if (user != null) {
        if (widget.role == UserRole.patient) {
          // 2️⃣ Create a user object
          UserModel newUser = UserModel(
            uid: user.uid,
            name: nameController.text.trim(),
            email: emailController.text.trim(),
            phone: phoneController.text.trim(),
            gender: gender!,
          );

          // 3️⃣ Save to Firestore

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(newUser.toMap());

          //navigate to main screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainPage()),
          );
        }
        //if the role is student
        else {
          // 2️⃣ Create a user object
          StudentUser newUser = StudentUser(
            uid: user.uid,
            name: nameController.text.trim(),
            email: emailController.text.trim(),
            phone: phoneController.text.trim(),
            universityId: universityIdController.text.trim(),
            gender: gender!,
            year: year!,
            casesCompleted: 0,
          );

          // 3️⃣ Save to Firestore

          await FirebaseFirestore.instance
              .collection('students')
              .doc(user.uid)
              .set(newUser.toMap());

          //navigate to main screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const StudentMainPage()),
          );
        }
        context.showErrorSnackBar("Signup successful", Colors.green);
      }
    } catch (e) {
      context.showErrorSnackBar(e.toString(), Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    universityIdController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //logo section
                SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 200, // slightly bigger than image
                    height: 200,
                    decoration: BoxDecoration(
                      color: scheme.secondary.withOpacity(
                        0.3,
                      ), // outer circle color
                      borderRadius: BorderRadius.circular(300),
                    ),
                    alignment: Alignment.center, // center the image inside
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo.png',
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),
                Text(
                  "AsnanHub",
                  style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 15),
                Text(
                  "connecting patients with students...",
                  style: Theme.of(context).textTheme.labelLarge,
                ),

                SizedBox(height: 50),
                Text(
                  "Signup",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                SizedBox(height: 20),

                //Signup section

                //usernmae
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: "Full Name"),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'This field is required';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                //email
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: "Email"),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),

                //phone number
                TextFormField(
                  controller: phoneController,
                  decoration: InputDecoration(labelText: "Phone Number"),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Phone number is required';
                    }
                    if (int.tryParse(value) == null || value.length < 10) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 10),

                //university Id (only for students)
                if (widget.role == UserRole.student)
                  TextFormField(
                    controller: universityIdController,
                    decoration: InputDecoration(labelText: "University Id"),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'University ID is required';
                      }
                      return null;
                    },
                  ),
                if (widget.role == UserRole.student) SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text("Male"),
                        value: "male",
                        groupValue: gender,
                        onChanged: (value) {
                          setState(() {
                            gender = value!;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text("Female"),
                        value: "female",
                        groupValue: gender,
                        onChanged: (value) {
                          setState(() {
                            gender = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                //gender
                SizedBox(height: 10),
                TextFormField(
                  controller: passwordController,
                  obscureText: _isObscured,
                  decoration: InputDecoration(
                    labelText: "Password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscured ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscured = !_isObscured;
                        });
                      },
                    ),
                  ),
                ),

                SizedBox(height: 10),
                //year
                if (widget.role == UserRole.student)
                  DropdownButtonFormField<int>(
                    value: year,
                    decoration: const InputDecoration(
                      labelText: "Year",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 4, child: Text("4th Year")),
                      DropdownMenuItem(value: 5, child: Text("5th Year")),
                    ],
                    onChanged: (value) {
                      // Save selected year
                      setState(() {
                        year = value!;
                      });
                      print("Selected year: $value");
                    },
                    validator: (value) {
                      if (value == null) return "Please select your year";
                      return null;
                    },
                  ),
                SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isLoading ? null : handleSignup,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text("Register"),
                  ),
                ),

                SizedBox(height: 8),
                Row(
                  children: [
                    Text("already have an account ? "),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (builder) => Login()),
                        );
                      },
                      child: Text(
                        "Login",
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
