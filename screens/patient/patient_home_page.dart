import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../widget/NurseCard.dart';

class PatientHomePage extends StatefulWidget {
  @override
  _PatientHomePageState createState() => _PatientHomePageState();
}

class _PatientHomePageState extends State<PatientHomePage> {
  final Stream<QuerySnapshot> nurseStream = FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'nurse')
      .snapshots();

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F2FF),
      body: SafeArea(
        child: Column(
          children: [
            // Header with gradient and shadow
            Container(
              padding: const EdgeInsets.all(20),
              margin: EdgeInsets.fromLTRB(
                MediaQuery.of(context).size.width * 0.02,
                MediaQuery.of(context).size.height * 0.01,
                MediaQuery.of(context).size.width * 0.025,
                MediaQuery.of(context).size.height * 0.015,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF395886), Color(0xFF395886)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(255, 53, 130, 248).withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Adjust font size and padding for smaller screens
                  double textScaleFactor = constraints.maxWidth < 600 ? 1.0 : 1.2;
                  double headerFontSize = constraints.maxWidth < 600 ? 22 : 24;
                  double subHeaderFontSize = constraints.maxWidth < 600 ? 14 : 16;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "🌟 Our Best Nurses",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: headerFontSize * textScaleFactor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Top-rated nurses available near you",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: subHeaderFontSize * textScaleFactor,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search a Nurse",
                  prefixIcon: Icon(Icons.search, color: Color.fromARGB(255, 138, 174, 224)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: GoogleFonts.poppins(),
              ),
            ),
            const SizedBox(height: 12),

            // Nurse List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: nurseStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading data'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  // Filter nurses based on search query
                  final filteredDocs = docs.where((doc) {
                    final nurse = doc.data() as Map<String, dynamic>;
                    final name = nurse['name']?.toString().toLowerCase() ?? '';
                    return name.contains(_searchQuery);
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return const Center(child: Text('No nurses found'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 16),
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final nurse = filteredDocs[index].data() as Map<String, dynamic>;
                      return NurseCard(nurse: nurse);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
