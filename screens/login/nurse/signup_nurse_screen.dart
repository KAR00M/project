import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../widget/login_widget/custom_text_form_field.dart';
import './nurse_login_screen.dart';

class SignupNurseScreen extends StatefulWidget {
  @override
  _SignupNurseScreenState createState() => _SignupNurseScreenState();
}

class _SignupNurseScreenState extends State<SignupNurseScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController educationController = TextEditingController();
  final TextEditingController aboutController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? selectedLocation;
  String gender = "Male";
  bool isLoading = false;
  bool _obscurePassword = true;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'gender': gender,
        'location': selectedLocation ?? "Not specified",
        'experience': experienceController.text.trim(),
        'education': educationController.text.trim(),
        'about': aboutController.text.trim(),
        'role': 'nurse',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registration Successful'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => NurseLoginScreen()));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration Failed: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      appBar: AppBar(
        title: const Text(
          "Nurse Signup",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Text(
                      "Create Your Account",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      label: "Full Name",
                      controller: nameController,
                      prefixIcon: Icons.person,
                      validator: (value) => value!.isEmpty ? "Enter your name" : null,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: "Email",
                      controller: emailController,
                      prefixIcon: Icons.email,
                      validator: (value) =>
                      value!.isEmpty || !value.contains('@') ? "Enter valid email" : null,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: "Password",
                      controller: passwordController,
                      prefixIcon: Icons.lock,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) => value!.length < 6 ? "Password too short" : null,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: "Phone Number",
                      controller: phoneController,
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) => value!.isEmpty ? "Enter phone number" : null,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: "Years of Experience",
                      controller: experienceController,
                      prefixIcon: Icons.work,
                      keyboardType: TextInputType.number,
                      validator: (value) => value!.isEmpty ? "Enter years of experience" : null,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: "Education",
                      controller: educationController,
                      prefixIcon: Icons.school,
                      validator: (value) => value!.isEmpty ? "Enter your education" : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text("Gender: ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        Radio<String>(
                          value: "Male",
                          groupValue: gender,
                          onChanged: (value) => setState(() => gender = value!),
                        ),
                        const Text("Male"),
                        Radio<String>(
                          value: "Female",
                          groupValue: gender,
                          onChanged: (value) => setState(() => gender = value!),
                        ),
                        const Text("Female"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Location",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      value: selectedLocation,
                      items: ["Ghasham Rd", "Al Mohafaza", "Railway Services", "College of Agriculture"]
                          .map((location) => DropdownMenuItem(
                        value: location,
                        child: Text(location),
                      ))
                          .toList(),
                      onChanged: (value) => setState(() => selectedLocation = value),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: "About",
                      controller: aboutController,
                      prefixIcon: Icons.info,
                      maxLines: 4,
                      validator: (value) => value!.isEmpty ? "Write about yourself" : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isLoading ? null : _registerUser,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.blueAccent,
                        elevation: 3,
                      ),
                      child: isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : const Text(
                        "Sign Up",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
