import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lastver/screens/login/selection_screen.dart';

import 'nurse_booking.dart'; // Update this import path as needed

class FavoriteNursesScreen extends StatefulWidget {
  const FavoriteNursesScreen({Key? key}) : super(key: key);

  @override
  _FavoriteNursesScreenState createState() => _FavoriteNursesScreenState();
}

class _FavoriteNursesScreenState extends State<FavoriteNursesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<QuerySnapshot> _favoritesStream;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId != null) {
      _favoritesStream = _firestore
          .collection('favorites')
          .where('patientId', isEqualTo: currentUserId)
          .snapshots();
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _removeFromFavorites(String favoriteId) async {
    try {
      await _firestore.collection('favorites').doc(favoriteId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nurse removed from favorites'),
          backgroundColor: Color.fromARGB(255, 138, 174, 224),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing nurse: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_auth.currentUser == null) {
      return _buildNotLoggedInView();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Favorite Nurses',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 3, 36, 78),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color.fromARGB(255, 138, 174, 224)))
          : StreamBuilder<QuerySnapshot>(
        stream: _favoritesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color.fromARGB(255, 138, 174, 224)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: GoogleFonts.poppins(),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyFavorites();
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 80),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final favoriteDoc = snapshot.data!.docs[index];
              final favoriteData = favoriteDoc.data() as Map<String, dynamic>;
              final favoriteId = favoriteDoc.id;
              final nurseData = favoriteData['nurseData'] as Map<String, dynamic>;

              return _buildFavoriteNurseCard(nurseData, favoriteId);
            },
          );
        },
      ),
    );
  }

  Widget _buildFavoriteNurseCard(Map<String, dynamic> nurse, String favoriteId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7ECFF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile with gradient border effect
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF9258FF), Color(0xFFBEA9F0)],
                ),
              ),
              padding: const EdgeInsets.all(2),
              child: const CircleAvatar(
                radius: 38,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage("assets/nurse_avatar.jpg"),
              ),
            ),
            const SizedBox(width: 14),

            // Nurse Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nurse["name"] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.work_outline, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        "سنة خبرة ${nurse["experience"] ?? '0'}",
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        nurse["location"] ?? '',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            ),

            // View & Remove Section
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Remove button
                IconButton(
                  onPressed: () => _removeFromFavorites(favoriteId),
                  icon: const Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 24,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 8),
                // View button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NurseDetailsScreen(nurse: nurse),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 53, 130, 248),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    textStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  child: const Text("View"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFavorites() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No favorite nurses yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add nurses to your favorites list\nby tapping the heart icon',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotLoggedInView() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Favorite Nurses',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 3, 36, 78),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Please Log In',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You need to be logged in\nto view your favorite nurses',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate to login screen
                // Replace with your login screen route
                Navigator.push(context, MaterialPageRoute(builder: (context) => SelectionScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 138, 174, 224),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                textStyle: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              child: const Text("Log In"),
            ),
          ],
        ),
      ),
    );
  }
}