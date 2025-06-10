import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../login/nurse/nurse_login_screen.dart';
import 'EditNurseProfilePage.dart';

class NurseProfilePage extends StatefulWidget {
  @override
  _NurseProfilePageState createState() => _NurseProfilePageState();
}

class _NurseProfilePageState extends State<NurseProfilePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String name = "N/A",
      phone = "N/A",
      email = "N/A",
      experience = "N/A",
      education = "Not Provided",
      location = "Not Provided",
      gender = "Not Specified",
      about = "No details available.";

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      DocumentSnapshot userDoc =
      await _firestore.collection("users").doc(currentUser.uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data() as Map<String, dynamic>;

        if (mounted) {
          setState(() {
            name = data["name"]?.toString() ?? "N/A";
            phone = data["phone"]?.toString() ?? "N/A";
            email = data["email"]?.toString() ?? "N/A";
            experience = data["experience"]?.toString() ?? "N/A";
            education = data["education"]?.toString() ?? "Not Provided";
            location = data["location"]?.toString() ?? "Not Provided";
            gender = data["gender"]?.toString() ?? "Not Specified";
            about = data["about"]?.toString() ?? "No details available.";
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.edit, size: 27, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditNurseProfilePage(
                    currentData: {
                      "name": name,
                      "phone": phone,
                      "email": email,
                      "experience": experience,
                      "education": education,
                      "location": location,
                      "gender": gender,
                      "about": about,
                    },
                  ),
                ),
              ).then((_) => fetchUserData()); // Refresh after edit
            },
          ),
          IconButton(
            onPressed: () async {
              await logout();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => NurseLoginScreen()));
            },
            icon: Icon(Icons.logout, size: 27, color: Colors.white),
          ),
        ],

        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color.fromARGB(255, 33, 117, 105),Color.fromARGB(255, 33, 117, 105)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        title: const Text(
          "Nurse Profile",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileCard(),
          const SizedBox(height: 20),
          _buildSectionTitle("About Me"),
          _buildInfoText(about),
          const SizedBox(height: 20),
          _buildInfoCard(Icons.phone, "Phone", phone),
          _buildInfoCard(Icons.email, "Email", email),
          _buildInfoCard(Icons.school, "Education", education),
          _buildInfoCard(Icons.location_on, "Location", location),
          _buildInfoCard(Icons.person, "Gender", gender),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.5),
                    blurRadius: 10,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage("assets/nurse_avatar.jpg"),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "Experience: $experience",
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Color.fromARGB(255, 6, 108, 82), size: 30),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              Text(
                text,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInfoText(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.justify,
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      ),
    );
  }
}
