import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

// Add this extension method to capitalize strings
extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return '${this[0].toUpperCase()}${this.substring(1)}';
  }
}

class NurseReservationControlPage extends StatefulWidget {
  const NurseReservationControlPage({Key? key}) : super(key: key);

  @override
  _NurseReservationControlPageState createState() => _NurseReservationControlPageState();
}

class _NurseReservationControlPageState extends State<NurseReservationControlPage> with SingleTickerProviderStateMixin {
  final String nurseId = FirebaseAuth.instance.currentUser!.uid;
  final Color primaryColor = Color.fromARGB(255, 33, 117, 105);
  final Color secondaryColor = Color(0xFFF7ECFF);

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Manage Appointments',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            )
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentList('pending'),
          _buildAppointmentList('approved'),
          _buildAppointmentList('rejected'),
        ],
      ),
    );
  }

  Widget _buildAppointmentList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('nurseId', isEqualTo: nurseId)
          .where('status', isEqualTo: status)
          .orderBy('date')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: primaryColor),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading appointments',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        final appointments = snapshot.data!.docs;

        if (appointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == 'pending' ? Icons.hourglass_empty :
                  status == 'approved' ? Icons.check_circle_outline :
                  Icons.cancel_outlined,
                  size: 60,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'No ${status} appointments',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final appointment = appointments[index];
            final appointmentData = appointment.data() as Map<String, dynamic>;
            final Timestamp timestamp = appointmentData['date'];
            final DateTime date = timestamp.toDate();
            final String formattedDate = DateFormat('MMM dd, yyyy').format(date);
            final String time = appointmentData['time'] ?? 'No time specified';
            final String service = appointmentData['service'] ?? 'Consultation';
            final String appointmentId = appointment.id;

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: secondaryColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.medical_services, color: primaryColor),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            service,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: status == 'pending' ? Colors.amber[100] :
                            status == 'approved' ? Colors.green[100] : Colors.red[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status.capitalize(),
                            style: GoogleFonts.poppins(
                              color: status == 'pending' ? Colors.amber[800] :
                              status == 'approved' ? Colors.green[800] : Colors.red[800],
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(appointmentData['patientId'])
                              .get(),
                          builder: (context, userSnapshot) {
                            if (userSnapshot.connectionState == ConnectionState.waiting) {
                              return const Text("Loading patient info...");
                            }

                            if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
                              return _appointmentInfoRow(Icons.person, 'Patient', 'Unknown patient');
                            }

                            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _appointmentInfoRow(Icons.person, 'Patient', userData['name'] ?? 'No name'),
                                if (userData['phone'] != null)
                                  _appointmentInfoRow(Icons.phone, 'Phone', userData['phone']),
                                _appointmentInfoRow(Icons.location_on, 'Location', appointment['nurseLocation'] ?? 'Not specified'),
                              ],
                            );
                          },
                        ),

                        // 👇 التعديلات الجديدة هنا
                        _appointmentInfoRow(Icons.calendar_today, 'Date', formattedDate),
                        _appointmentInfoRow(Icons.access_time, 'Time', time),
                        if (appointmentData['services'] != null && appointmentData['services'] is List)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
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
                                  children: (appointmentData['services'] as List).map<Widget>((service) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.check_circle_outline, size: 16, color: Color.fromARGB(
                                              255, 27, 221, 169)),
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
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),



                        // التكلفة + بقية الأكشنز تحتها
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
                                color: Color.fromARGB(255, 33, 117, 105),
                              ),
                            ),
                          ],
                        ),
                        if (status == 'pending')
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () {
                                    _rejectAppointment(appointmentId);
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                  ),
                                  child: Text(
                                    'Reject',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () {
                                    _approveAppointment(appointmentId);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                  ),
                                  child: Text(
                                    'Approve',
                                    style: GoogleFonts.poppins(color: Color.fromARGB(255, 255, 255, 255)),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (status == 'approved')
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    _cancelAppointment(appointmentId);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                  ),
                                  child: Text(
                                    'Cancel Appointment',
                                    style: GoogleFonts.poppins(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (status == 'rejected')
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    _deleteAppointment(appointmentId);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.grey,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                  ),
                                  child: Text(
                                    'Delete',
                                    style: GoogleFonts.poppins(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _appointmentInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to release a time slot
  Future<void> _releaseTimeSlot(DateTime date, String time) async {
    final String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    final String availabilityDocId = '$nurseId-$formattedDate-$time';

    try {
      await FirebaseFirestore.instance
          .collection('nurseAvailability')
          .doc(availabilityDocId)
          .set({
        'nurseId': nurseId,
        'date': formattedDate,
        'time': time,
        'isAvailable': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Time slot released: $availabilityDocId');
    } catch (error) {
      print('Error releasing time slot: $error');
      throw error;
    }
  }

  void _approveAppointment(String appointmentId) {
    FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .update({
      'status': 'approved',
      'updatedAt': FieldValue.serverTimestamp(),
    }).then((_) {
      // We don't need to change availability when approving
      // since the slot should remain unavailable
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment approved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve appointment: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _rejectAppointment(String appointmentId) {
    // First, get the appointment details to identify the time slot
    FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .get()
        .then((doc) {
      if (doc.exists) {
        final appointmentData = doc.data() as Map<String, dynamic>;
        final Timestamp timestamp = appointmentData['date'];
        final DateTime date = timestamp.toDate();
        final String time = appointmentData['time'];

        // Run a batch operation to update both collections
        final batch = FirebaseFirestore.instance.batch();

        // Update appointment status
        batch.update(doc.reference, {
          'status': 'rejected',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Commit the batch
        return batch.commit().then((_) {
          // After the batch commit, release the time slot
          return _releaseTimeSlot(date, time);
        });
      }
      return null;
    })
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment rejected and time slot released'),
          backgroundColor: Colors.orange,
        ),
      );
    })
        .catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject appointment: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _cancelAppointment(String appointmentId) {
    // First, get the appointment details to identify the time slot
    FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .get()
        .then((doc) {
      if (doc.exists) {
        final appointmentData = doc.data() as Map<String, dynamic>;
        final Timestamp timestamp = appointmentData['date'];
        final DateTime date = timestamp.toDate();
        final String time = appointmentData['time'];

        // Run a batch operation to update both collections
        final batch = FirebaseFirestore.instance.batch();

        // Update appointment status to rejected
        batch.update(doc.reference, {
          'status': 'rejected',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Commit the batch
        return batch.commit().then((_) {
          // After the batch commit, release the time slot
          return _releaseTimeSlot(date, time);
        });
      }
      return null;
    })
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment cancelled and time slot released'),
          backgroundColor: Colors.blue,
        ),
      );
    })
        .catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to cancel appointment: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _deleteAppointment(String appointmentId) {
    // First, get the appointment details to identify the time slot
    FirebaseFirestore.instance
        .collection('appointments')
        .doc(appointmentId)
        .get()
        .then((doc) {
      if (doc.exists) {
        final appointmentData = doc.data() as Map<String, dynamic>;
        final Timestamp timestamp = appointmentData['date'];
        final DateTime date = timestamp.toDate();
        final String time = appointmentData['time'];

        // Delete the appointment
        return doc.reference.delete().then((_) {
          // After deletion, release the time slot
          return _releaseTimeSlot(date, time);
        });
      }
      return null;
    })
        .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment deleted and time slot released'),
          backgroundColor: Colors.grey,
        ),
      );
    })
        .catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete appointment: $error'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }
}