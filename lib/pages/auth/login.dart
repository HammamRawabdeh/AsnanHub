import 'package:asnan_hub/extensions/snackbar_extension.dart';
import 'package:asnan_hub/pages/auth/signup.dart';
import 'package:asnan_hub/services/auth_serrvice.dart';
import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}


class _LoginState extends State<Login> {
  var authService = AuthService();
  bool _isLoading = false;

  void handleLogin() async {
    if (_isLoading) return; // Prevent multiple clicks
    
    setState(() {
      _isLoading = true;
    });

    try {
      var userCredentials = await authService.signUp(
        emailController.text.trim(),
        passwordController.text,
      );
      print("Signup successful ,${userCredentials}");
            
      context.showErrorSnackBar("Signup successful", Colors.green);
    } catch (ex) {
      
      String errorMessage = 'Signup failed. Please try again.';
      if (ex is String) {
        errorMessage = ex;
      } else if (ex.toString().isNotEmpty) {
        errorMessage = ex.toString();
      }
      
        context.showErrorSnackBar(errorMessage, Colors.red);

    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    var scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
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
              style: TextStyle(
                fontSize: 20,
                color: scheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 15),
            Text("connecting patients with students..."),

            SizedBox(height: 50),
            Text(
              "Signup",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            //Signup section
            TextFormField(
              controller: emailController,
              decoration: InputDecoration(labelText: "email")),
            SizedBox(height: 10),
            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: "Password")),

            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _isLoading ? null : handleLogin,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text("Signup"),
              ),
  
            ),

            SizedBox(height: 8,),
            Row(
              children: [
                 Text("dont have an account ? "),
                 InkWell(
                  onTap: (){
                    Navigator.of(context).push(MaterialPageRoute(builder: (builder)=> Signup()));
                  },
                  child: Text("Register" , style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: scheme.primary
              
                  ),),
                 )
              ],
            )
       
          ],
        ),
      ),
    );
  }
}
