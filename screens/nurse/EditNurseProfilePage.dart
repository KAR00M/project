import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditNurseProfilePage extends StatefulWidget {
  final Map<String, String> currentData;
  const EditNurseProfilePage({required this.currentData});

  @override
  State<EditNurseProfilePage> createState() => _EditNurseProfilePageState();
}

class _EditNurseProfilePageState extends State<EditNurseProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late TextEditingController nameController;
  late TextEditingController phoneController;
  late TextEditingController experienceController;
  late TextEditingController educationController;
  late TextEditingController locationController;
  late TextEditingController genderController;
  late TextEditingController aboutController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.currentData["name"]);
    phoneController = TextEditingController(text: widget.currentData["phone"]);
    experienceController = TextEditingController(text: widget.currentData["experience"]);
    educationController = TextEditingController(text: widget.currentData["education"]);
    locationController = TextEditingController(text: widget.currentData["location"]);
    genderController = TextEditingController(text: widget.currentData["gender"]);
    aboutController = TextEditingController(text: widget.currentData["about"]);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection("users").doc(user.uid).update({
      "name": nameController.text,
      "phone": phoneController.text,
      "experience": experienceController.text,
      "education": educationController.text,
      "location": locationController.text,
      "gender": genderController.text,
      "about": aboutController.text,
    });

    Navigator.pop(context); // Go back after saving
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField("Name", nameController),
              _buildTextField("Phone", phoneController),
              _buildTextField("Experience", experienceController),
              _buildTextField("Education", educationController),
              _buildTextField("Location", locationController),
              _buildTextField("Gender", genderController),
              _buildTextField("About", aboutController, maxLines: 3),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveChanges,
                child: Text("Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
