import 'package:flutter/material.dart';
import '../../widget/login_widget/custom_button.dart';
import 'patient/PatientLoginScreen.dart';
import './nurse/nurse_login_screen.dart';

class SelectionScreen extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 80),
          Image.asset(
            'assets/onBoarding_photo-removebg-preview.png',
            fit: BoxFit.cover,
            height: 250,
          ),
          const SizedBox(height: 40),
          const Text(
            "Sign As",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          // Buttons
          CustomButton(
            text: "Nurse",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context)=>NurseLoginScreen()));
            },
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: "Patient",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context)=>PatientLoginScreen()));
            },
          ),

        ],
      ),
    );
  }

}