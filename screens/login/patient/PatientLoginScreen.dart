import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_dialog/awesome_dialog.dart';

// Internal imports
import '../../nurse/NurseMainPage.dart';
import '../../patient/patient_main_page.dart';
import '../nurse/resetPassword.dart';
import 'PatientSignupScreen.dart';
import '../../../widget/login_widget/custom_button.dart';
import '../../../widget/login_widget/custom_text_form_field.dart';


class PatientLoginScreen extends StatefulWidget {


  @override
  _PatientLoginScreenState createState() => _PatientLoginScreenState();
}

class _PatientLoginScreenState extends State<PatientLoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Sign in with email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Fetch user role from Firestore
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
      if (userDoc.exists) {
        String role = userDoc['role'];

        // Navigate based on user role
        if (role == 'patient') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>PatientMainPage()));
        } else if (role == 'nurse') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>NurseMainPage()));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unknown user role')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User data not found')),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "An error occurred. Please try again.";
      if (e.code == 'user-not-found') {
        errorMessage = "No user found with this email.";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Incorrect password. Please try again.";
      } else if (e.code == 'network-request-failed') {
        errorMessage = "Network error. Please check your internet connection.";
      }

      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.topSlide,
        title: 'Login Failed',
        desc: errorMessage,
        btnOkOnPress: () {},
      ).show();
    } catch (e) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.topSlide,
        title: 'Error',
        desc: "An unexpected error occurred. Please try again.",
        btnOkOnPress: () {},
      ).show();
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Image Section
            Container(
              width: double.infinity,
              height: 250,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/welcom_photo.jpg"),
                  fit: BoxFit.cover,
                ),
              ),

            ),

            const SizedBox(height: 20),

            // Login Form Container
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sign In Text
                      const Text(
                        "SIGN IN",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF638ECB)),
                      ),
                      const SizedBox(height: 5),
                      const Text("Enter your details", style: TextStyle(color: Colors.grey)),

                      const SizedBox(height: 20),

                      // Email Field
                      CustomTextField(
                        label: "Email",
                        controller: emailController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter your email";
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return "Enter a valid email";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 15),

                      // Password Field
                      CustomTextField(
                        label: "Password",
                        controller: passwordController,
                        isPassword: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter your password";
                          }
                          if (value.length < 6) {
                            return "Password must be at least 6 characters";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 10),

                      // Forgot Password Button
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ForgetPasswordPage()),
                          );
                        },
                        child: const Text(
                          'Forgot your password?',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: CustomButton(
                          text: "SIGN IN",
                          onPressed: isLoading ? null : _signIn,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text("or", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF638ECB))),
            const SizedBox(height: 10),

            // Already have an account? Sign Up
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account?"),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context,MaterialPageRoute(builder: (context)=>PatientSignupScreen()) );
                    },
                    child: const Text(
                      "SIGN UP",
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}