
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class AppointmentStatusScreen extends StatefulWidget {

  const AppointmentStatusScreen({Key? key}) : super(key: key);

  @override
  _AppointmentStatusScreenState createState() =>
      _AppointmentStatusScreenState();
}

class _AppointmentStatusScreenState extends State<AppointmentStatusScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot>? _appointmentsStream;
  bool isLoading = true;
  String? errorMessage;

  Future<void> _releaseTimeSlot(String nurseId, DateTime date, String time) async {
    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final availabilityDocId = '$nurseId-$formattedDate-$time';
      final availabilityDocRef = _firestore.collection('nurseAvailability').doc(availabilityDocId);

      // إذا كان الموعد محجوز، نعيد تعيين الوقت إلى متاح
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(availabilityDocRef);
        if (snapshot.exists) {
          // إعادة تعيين الوقت كمتاح
          transaction.update(availabilityDocRef, {'isAvailable': true});
        }
      });

      print('Released time slot: $availabilityDocId');
    } catch (e) {
      print('Error releasing time slot: $e');
    }
  }

  void _deleteEntireAppointment() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        // الحصول على جميع المواعيد الخاصة بالمستخدم
        final snapshot = await _firestore
            .collection('appointments')
            .where('userId', isEqualTo: userId)
            .get();

        // حذف جميع المواعيد
        for (var doc in snapshot.docs) {
          await doc.reference.delete();

          // بعد الحذف، قم بإعادة تعيين الوقت كمتاح للممرضة
          final data = doc.data() as Map<String, dynamic>;
          final nurseId = data['nurseId'];
          final date = data['date'].toDate();
          final time = data['time'];
          await _releaseTimeSlot(nurseId, date, time); // استدعاء الدالة لجعل الوقت متاحًا
        }

        // عرض رسالة النجاح فورًا بعد الحذف
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Appointments deleted successfully"),
            backgroundColor: Colors.red, // عرض الرسالة باللون الأحمر
          ),
        );
      }
    } catch (e) {
      // في حالة حدوث خطأ أثناء الحذف
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error deleting appointments: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  void _loadAppointments() {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        setState(() {
          _appointmentsStream = _firestore
              .collection('appointments')
              .where('patientId', isEqualTo: user.uid)
              .orderBy('createdAt', descending: true)
              .snapshots();
        });
      } else {
        setState(() {
          errorMessage = "User not authenticated";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load appointments: ${e.toString()}";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.amber;
      case 'confirmed':
        return Colors.green;
      case 'approved':
        return Color.fromARGB(255, 19, 227, 255);
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(Timestamp timestamp) {
    try {
      DateTime date = timestamp.toDate();
      return DateFormat('EEEE, MMM d, yyyy').format(date);
    } catch (e) {
      return "Invalid date";
    }
  }

  Widget _buildAppointmentCard(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final appointment = {
        ...data,
        'id': doc.id,
      };

      // طباعة البيانات للتأكد
      print("Fetched appointment data: $data");

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _getStatusColor(appointment['status'] ?? 'pending')
                    .withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Appointment with ${appointment['nurseName'] ?? 'Unknown Nurse'}",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment['status'] ?? 'pending'),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      (appointment['status'] ?? 'pending').toUpperCase(),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Appointment details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nurse Name
                  Row(
                    children: [
                      const Icon(Icons.person_pin, size: 18, color: Color.fromARGB(255, 138, 174, 224)),
                      const SizedBox(width: 8),
                      Text(
                        appointment['nurseName'] ?? "Unknown nurse",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 18, color: Color.fromARGB(255, 138, 174, 224)),
                      const SizedBox(width: 8),
                      Text(
                        appointment['nurseLocation'] ?? "Location not specified", // Display location
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Date
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: Color.fromARGB(255, 138, 174, 224)),
                      const SizedBox(width: 8),
                      Text(
                        appointment['date'] != null
                            ? _formatDate(appointment['date'])
                            : "Date not specified",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Time
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 18, color: Color.fromARGB(255, 138, 174, 224)),
                      const SizedBox(width: 8),
                      Text(
                        appointment['time'] ?? "Time not specified",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Services list
                  Text(
                    "Services:",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (appointment['services'] != null && appointment['services'] is List)
                          ...(appointment['services'] as List).map((service) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_outline, size: 16, color: Color.fromARGB(255, 138, 174, 224)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      service.toString(),
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList()
                        else
                          Text(
                            "No services specified",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Total cost
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total Cost:",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        appointment['totalCost'] != null
                            ? "${(appointment['totalCost'] as num).toStringAsFixed(2)} EGP"
                            : "Not specified",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color.fromARGB(255, 3, 36, 78),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight, // Align the button to the right
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red[400],
                      onPressed: () async {
                        try {
                          final confirm = await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Confirm Deletion"),
                              content: const Text("Are you sure you want to delete this appointment?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            // Get the appointment data first
                            final doc = await FirebaseFirestore.instance
                                .collection('appointments')
                                .doc(appointment['id'])
                                .get();

                            if (doc.exists) {
                              final data = doc.data()!;
                              final Timestamp timestamp = data['date'];
                              final DateTime date = timestamp.toDate();
                              final String time = data['time'];
                              final nurseId = data['nurseId']; // الحصول على معرف الممرضة

                              // Run a batch operation to update both collections
                              final batch = FirebaseFirestore.instance.batch();

                              // Update appointment status to rejected or cancelled
                              batch.update(doc.reference, {
                                'status': 'rejected',  // أو 'cancelled' حسب الحاجة
                                'updatedAt': FieldValue.serverTimestamp(),
                              });

                              // Commit the batch
                              await batch.commit();

                              // After the batch commit, release the time slot
                              await _releaseTimeSlot(nurseId, date, time); // استدعاء دالة إعادة تعيين الوقت

                              // Delete the appointment document from Firestore
                              await FirebaseFirestore.instance
                                  .collection('appointments')
                                  .doc(appointment['id'])
                                  .delete();

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Appointment deleted "),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Error deleting appointment: $e"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  )

                ],
              ),
            ),
          ],
        ),
      );
        } catch (e) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(
          "Error displaying appointment: ${e.toString()}",
          style: GoogleFonts.poppins(color: Colors.red.shade800),
        ),
      );
    }
  }

  Widget _buildActionButtons(Map<String, dynamic> appointment) {
    try {
      // Only show cancel button for pending appointments
      if ((appointment['status'] ?? '').toLowerCase() == 'pending') {
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _cancelAppointment(appointment['id']),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        );
      } else if ((appointment['status'] ?? '').toLowerCase() == 'confirmed') {
        // For confirmed appointments
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _cancelAppointment(appointment['id']),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to reschedule screen or show dialog
                  _showRescheduleDialog(appointment);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 138, 174, 224),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Reschedule",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        );
      } else if ((appointment['status'] ?? '').toLowerCase() == 'completed') {
        // For completed appointments
        return ElevatedButton(
          onPressed: () {
            // Navigate to review screen
            _navigateToReviewScreen(appointment);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromARGB(255, 138, 174, 224),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            "Write Review",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }

      // For cancelled or other status - no actions
      return const SizedBox.shrink();
    } catch (e) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade200),
        ),
        child: Text(
          "Error loading actions",
          style: GoogleFonts.poppins(
            color: Colors.amber.shade800,
            fontSize: 12,
          ),
        ),
      );
    }
  }

  void _cancelAppointment(String? appointmentId) {
    if (appointmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to cancel: appointment ID is missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Cancel Appointment",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          "Are you sure you want to cancel this appointment? This action cannot be undone.",
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "No",
              style: GoogleFonts.poppins(),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              try {
                await _firestore
                    .collection('appointments')
                    .doc(appointmentId)
                    .update({'status': 'cancelled'});

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Appointment cancelled successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to cancel: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(
              "Yes, Cancel",
              style: GoogleFonts.poppins(
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog(Map<String, dynamic> appointment) {
    // Implementation for reschedule dialog would go here
    // For now, just show a notification that the feature is coming soon
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reschedule feature coming soon'),
        backgroundColor: Color.fromARGB(255, 138, 174, 224),
      ),
    );
  }

  void _navigateToReviewScreen(Map<String, dynamic> appointment) {
    // Implementation for navigation to review screen
    // For now, just show a notification that the feature is coming soon
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Review feature coming soon'),
        backgroundColor: Color.fromARGB(255, 138, 174, 224),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            "No appointments yet",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Book an appointment with a nurse to see it here",
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Navigate to home or nurse list screen
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 3, 36, 78),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              "Book Now",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: Colors.red[400],
            onPressed: () {
              _deleteEntireAppointment();
            },
          ),
        ],
      ),
    );
  }


  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "Something went wrong",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Retry loading appointments
              setState(() {
                isLoading = true;
                errorMessage = null;
              });
              _loadAppointments();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 138, 174, 224),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              "Try Again",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentList(AsyncSnapshot<QuerySnapshot> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color.fromARGB(255, 138, 174, 224),
        ),
      );
    }

    if (snapshot.hasError) {
      return _buildErrorState("Error loading appointments: ${snapshot.error}");
    }

    if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: snapshot.data!.docs.length,
      itemBuilder: (context, index) {
        final doc = snapshot.data!.docs[index];
        return _buildAppointmentCard(doc);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          'My Appointments',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 3, 36, 78).withOpacity(0.85),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            color: Color.fromARGB(255, 213, 213, 213),
            onPressed: () {
              // Refresh appointments
              setState(() {
                isLoading = true;
                errorMessage = null;
              });
              _loadAppointments();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color.fromARGB(255, 255, 255, 255),
        ),
      )
          : errorMessage != null
          ? _buildErrorState(errorMessage!)
          : _auth.currentUser == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Please login to view your appointments",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to login screen
                // Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 138, 174, 224),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Go to Login",
                style: GoogleFonts.poppins(),
              ),
            ),
          ],
        ),
      )
          : StreamBuilder<QuerySnapshot>(
        stream: _appointmentsStream,
        builder: (context, snapshot) {
          return _buildAppointmentList(snapshot);
        },
      ),
    );
  }



  Widget _buildFilterOption(String label, bool isSelected) {
    return InkWell(
      onTap: () {
        // Toggle selection
        Navigator.pop(context);
        // Would implement filter logic here
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? Color.fromARGB(255, 138, 174, 224) : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: isSelected ? Color.fromARGB(255, 255, 255, 255) : Colors.white,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}