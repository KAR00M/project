import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../nurse/NurseMainPage.dart';

import '../patient/patient_main_page.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // Delay execution to avoid setState() during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserStatus();
    });
  }

  Future<void> _checkUserStatus() async {
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot userDoc =
        await _firestore.collection('users').doc(user.uid).get();

        // Explicitly cast `data()` to `Map<String, dynamic>` before accessing keys
        Map<String, dynamic>? userData =
        userDoc.data() as Map<String, dynamic>?;

        String? role = userData?['role']; // Now this is safe

        if (role == 'nurse') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>NurseMainPage()));
        } else if (role == 'patient') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> PatientMainPage()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>OnboardingScreen()));
        }
      } catch (e) {
        debugPrint("Error fetching user role: $e");
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>OnboardingScreen()));
      }
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>OnboardingScreen()));
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF638ECB),
      body: Center(
        child: Image.asset(
          'assets/splash.png',
          width: 200, // Adjusted size for better visibility
          height: 200,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
