import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'NurseReservationControlPage.dart';

class NurseHomePage extends StatefulWidget {
  const NurseHomePage({super.key});

  @override
  _NurseHomePageState createState() => _NurseHomePageState();
}

class _NurseHomePageState extends State<NurseHomePage> {
  DateTime selectedDate = DateTime.now();
  final Color primaryColor = Colors.teal[700]!;
  final Color secondaryColor = Colors.teal[100]!;

  late String nurseId;


  @override
  void initState() {
    super.initState();
    nurseId = FirebaseAuth.instance.currentUser!.uid;
    print('Logged-in nurse UID: $nurseId');
  }

  void _changeDate(int days) {
    setState(() {
      selectedDate = selectedDate.add(Duration(days: days));
    });
  }

  // Helper method to release a time slot when deleting an appointment
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

  // Method to properly delete an appointment and release its time slot
  Future<void> _deleteAppointment(DocumentSnapshot doc) async {
    try {
      // Get appointment data
      final appointmentData = doc.data() as Map<String, dynamic>;
      final Timestamp timestamp = appointmentData['date'];
      final DateTime date = timestamp.toDate();
      final String time = appointmentData['time'] ?? '';

      // First delete the appointment
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(doc.id)
          .delete();

      // Then release the time slot
      if (time.isNotEmpty) {
        await _releaseTimeSlot(date, time);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Appointment deleted and time slot released"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      print('Error deleting appointment: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error deleting appointment: $error"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Patient Appointments',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            )),
        backgroundColor: primaryColor,
        centerTitle: true,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date selector card with improved styling
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor.withOpacity(0.8), primaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, size: 32),
                        color: Colors.white,
                        onPressed: () => _changeDate(-1),
                      ),
                      TextButton(
                        onPressed: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: primaryColor,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: Colors.black87,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (pickedDate != null) {
                            setState(() => selectedDate = pickedDate);
                          }
                        },
                        child: Column(
                          children: [
                            Text(
                              DateFormat('EEEE').format(selectedDate),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              DateFormat('MMM dd, yyyy').format(selectedDate),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, size: 32),
                        color: Colors.white,
                        onPressed: () => _changeDate(1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.calendar_today, color: primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Appointments for ${DateFormat('MMMM d, yyyy').format(selectedDate)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('appointments')
                    .where('nurseId', isEqualTo: nurseId)
                    .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                    .where('date', isLessThan: Timestamp.fromDate(endOfDay))
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    );
                  }

                  if (snapshot.hasError) {
                    return _buildErrorState();
                  }

                  final appointments = snapshot.data!.docs;

                  if (appointments.isEmpty) {
                    return _buildEmptyState();
                  }

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: MediaQuery.of(context).size.width - 32,
                          ),
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.resolveWith<Color>(
                                  (Set<MaterialState> states) => secondaryColor,
                            ),
                            columnSpacing: 20,
                            horizontalMargin: 16,
                            columns: const [
                              DataColumn(label: Text("No", style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text("Patient", style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text("Time", style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                              DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
                            ],
                            rows: appointments.asMap().entries.map((entry) {
                              int index = entry.key + 1;
                              var doc = entry.value;
                              return DataRow(
                                color: index % 2 == 0
                                    ? MaterialStateProperty.all<Color>(Colors.grey.withOpacity(0.1))
                                    : null,
                                cells: [
                                  DataCell(Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      index.toString(),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  )),
                                  DataCell(
                                    FutureBuilder<DocumentSnapshot>(
                                      future: FirebaseFirestore.instance.collection('users').doc(doc['patientId']).get(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Text("Loading...");
                                        } else if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                                          return const Text("Unknown");
                                        } else {
                                          final patientData = snapshot.data!.data() as Map<String, dynamic>;
                                          return Text(
                                            patientData['name'] ?? 'No name',
                                            style: const TextStyle(fontWeight: FontWeight.w500),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                  DataCell(Text(doc['time'] ?? '')),
                                  DataCell(_buildStatusBadge(doc['status'] ?? '')),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [


                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          tooltip: "Delete Appointment",
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text("Delete Appointment"),
                                                content: const Text("Are you sure you want to delete this appointment? This will release the time slot."),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, false),
                                                    child: const Text("Cancel"),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, true),
                                                    child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirm == true) {
                                              await _deleteAppointment(doc);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NurseReservationControlPage(),
            ),
          );
        },
        icon: const Icon(Icons.schedule, color: Color.fromARGB(
            255, 255, 255, 255)),
        label: const Text('Pending Requests',style:TextStyle(color: Colors.white),),
        backgroundColor: primaryColor,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    IconData iconData;

    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'approved':
        badgeColor = Colors.green;
        iconData = Icons.check_circle;
        break;
      case 'cancelled':
      case 'rejected':
        badgeColor = Colors.red;
        iconData = Icons.cancel;
        break;
      case 'pending':
        badgeColor = Colors.orange;
        iconData = Icons.pending;
        break;
      default:
        badgeColor = Colors.grey;
        iconData = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, color: badgeColor, size: 16),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: secondaryColor.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available,
              size: 80,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No appointments for today',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your schedule is clear for ${DateFormat('MMMM d').format(selectedDate)}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NurseReservationControlPage(),
                ),
              );
            },
            icon: const Icon(Icons.add_circle),
            label: const Text('Check Pending Requests'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Error loading appointments',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {}); // Refresh the page
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry' ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAppointmentDetails(DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info, color: primaryColor),
            const SizedBox(width: 8),
            const Text("Appointment Details"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(doc['patientId']).get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Text("Loading patient information...");
                  }
                  final patientData = snapshot.data!.data() as Map<String, dynamic>?;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem(
                        "Patient",
                        patientData?['name'] ?? 'Unknown',
                        Icons.person,
                      ),
                      if (patientData?['phone'] != null)
                        _buildDetailItem(
                          "Phone",
                          patientData!['phone'],
                          Icons.phone,
                        ),
                      const Divider(),
                    ],
                  );
                },
              ),
              _buildDetailItem(
                "Date",
                DateFormat('MMMM d, yyyy').format((doc['date'] as Timestamp).toDate()),
                Icons.calendar_today,
              ),
              _buildDetailItem(
                "Time",
                doc['time'] ?? 'Not specified',
                Icons.access_time,

              ),
              _buildDetailItem(
                "Status",
                doc['status'] ?? 'Not specified',
                Icons.info_outline,
              ),
              if (doc['notes'] != null && doc['notes'] != '')
                _buildDetailItem(
                  "Notes",
                  doc['notes'],
                  Icons.note,
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: TextStyle(color: primaryColor)),
          ),
          if (doc['status'] == 'approved' || doc['status'] == 'pending')
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Cancel Appointment"),
                    content: const Text("Are you sure you want to cancel this appointment? This will release the time slot."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("No"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Yes", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _deleteAppointment(doc);
                }
              },
              child: Text("Cancel Appointment", style: TextStyle(color: Colors.red)),
            ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}