import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class NurseDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> nurse;

  const NurseDetailsScreen({Key? key, required this.nurse}) : super(key: key);

  @override
  _NurseDetailsScreenState createState() => _NurseDetailsScreenState();
}

class _NurseDetailsScreenState extends State<NurseDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String selectedTime = '8:00 AM';
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  bool isCheckingAvailability = false;
  Map<String, bool> timeSlotAvailability = {};

  // Service pricing map
  final Map<String, double> servicePricing = {
    'Home Visit': 75.00,
    'Consultation': 50.00,
    'Wound Care': 65.00,
    'Injection': 40.00,
    'Blood Test': 55.00,
    'Medication Administration': 45.00,
    'Vital Signs Check': 35.00,
    'Physical Assessment': 60.00,
    'Catheter Care': 70.00,
    'Patient Education': 40.00,
  };

  // Selected services with a map to track selection
  Map<String, bool> selectedServices = {};
  double totalCost = 0.0;

  @override
  void initState() {
    super.initState();
    // Initialize all services as unselected
    servicePricing.forEach((service, price) {
      selectedServices[service] = false;
    });
    // Check availability for initial date when screen opens
    _checkAvailabilityForAllTimeSlots();
  }

  List<String> get availableTimeSlots {
    return [
      "8:00 AM", "9:00 AM", "10:00 AM", "11:00 AM",
      "1:00 PM", "2:00 PM", "3:00 PM", "4:00 PM", "5:00 PM"
    ];
  }

  // Calculate total cost based on selected services
  void _calculateTotalCost() {
    double total = 0.0;
    selectedServices.forEach((service, isSelected) {
      if (isSelected) {
        total += servicePricing[service] ?? 0.0;
      }
    });
    setState(() {
      totalCost = total;
    });
  }

  // Check availability for each time slot on the selected date
  Future<void> _checkAvailabilityForAllTimeSlots() async {
    setState(() {
      isCheckingAvailability = true;
    });

    try {
      Map<String, bool> availability = {};

      for (String time in availableTimeSlots) {
        bool isAvailable = await _checkNurseAvailability(widget.nurse['uid'], selectedDate, time);
        availability[time] = isAvailable;
      }

      setState(() {
        timeSlotAvailability = availability;

        // If current selected time is not available, select the first available time
        if (!timeSlotAvailability[selectedTime]!) {
          String? firstAvailableTime = availableTimeSlots.firstWhere(
                (time) => timeSlotAvailability[time] == true,
            orElse: () => selectedTime,
          );
          selectedTime = firstAvailableTime;
        }
      });
    } catch (e) {
      print('Error checking availability: $e');
    } finally {
      setState(() {
        isCheckingAvailability = false;
      });
    }
  }

  Future<bool> _checkNurseAvailability(String nurseId, DateTime date, String time) async {
    // Format date to match our storage format
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);

    // Check if there's an availability record for this time slot
    final availabilityDoc = await _firestore
        .collection('nurseAvailability')
        .doc('$nurseId-$formattedDate-$time')
        .get();

    // If record exists and shows unavailable, nurse is booked
    if (availabilityDoc.exists) {
      final data = availabilityDoc.data();
      return data?['isAvailable'] ?? true; // Default to available if field is missing
    }

    // If no record exists, nurse is available
    return true;
  }

  Future<void> _bookAppointment() async {
    // Check if at least one service is selected
    if (!selectedServices.containsValue(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one service'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final String? currentUserId = _auth.currentUser?.uid;

      if (currentUserId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login first'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      final availabilityDocId = '${widget.nurse['uid']}-$formattedDate-$selectedTime';
      final availabilityDocRef = _firestore.collection('nurseAvailability').doc(availabilityDocId);

      // Get list of selected services
      List<String> bookedServices = [];
      selectedServices.forEach((service, isSelected) {
        if (isSelected) {
          bookedServices.add(service);
        }
      });

      // Use a Firestore transaction to ensure atomic check & set
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(availabilityDocRef);

        if (snapshot.exists && snapshot.data()?['isAvailable'] == false) {
          throw Exception('This time slot has already been booked.');
        }

        // Set the slot as unavailable
        transaction.set(availabilityDocRef, {'isAvailable': false});

        // Add appointment
        transaction.set(_firestore.collection('appointments').doc(), {
          'nurseId': widget.nurse['uid'],
          'patientId': currentUserId,
          'nurseName': widget.nurse['name'],
          'nurseLocation': widget.nurse['location'], // Add nurse location here
          'services': bookedServices,
          'totalCost': totalCost,
          'time': selectedTime,
          'date': Timestamp.fromDate(selectedDate),
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment request sent successfully. Waiting for nurse approval.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      // Refresh availability to reflect changes
      _checkAvailabilityForAllTimeSlots();
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color.fromARGB(255, 138, 174, 224),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });

      // Check availability for the new date
      _checkAvailabilityForAllTimeSlots();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Nurse Details',
          style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white
          ),
        ),
        backgroundColor: Color.fromARGB(255, 3, 36, 78).withOpacity(0.85),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nurse Hero Image with gradient overlay
            SizedBox(height: 70,),
            Stack(
              children: [
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/nurse_avatar.jpg"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.nurse["name"] ?? 'Nurse',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "${widget.nurse["education"] ?? 'BSN'} • ${widget.nurse["experience"] ?? '0'} Years Experience",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Rating and Stats
            Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Color(0xFFF7ECFF),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStat(Icons.star, "4.9", "Rating"),
                  _divider(),
                  _buildStat(Icons.work_outline, "${widget.nurse["experience"] ?? '0'}", "Experience"),
                  _divider(),
                  _buildStat(Icons.people_outline, "120+", "Patients"),
                ],
              ),
            ),

            // About Section
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "About",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    widget.nurse["about"] ?? "Experienced nurse providing full medical care with a focus on patient comfort and professional service.",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),

                  SizedBox(height: 20),

                  // Nurse Info
                  Text(
                    "Information",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 10),
                  _infoTile(Icons.location_on_outlined, "Location", widget.nurse["location"] ?? "Not specified"),
                  _infoTile(Icons.school_outlined, "Education", widget.nurse["education"] ?? "BSN"),
                  _infoTile(Icons.person_outline, "Gender", widget.nurse["gender"] ?? "Not specified"),
                  _infoTile(Icons.phone_outlined, "Contact", widget.nurse["phone"] ?? "Not available"),

                  SizedBox(height: 30),

                  // Service Pricing Section
                  Text(
                    "Services & Pricing",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 15),

                  // Service selection with prices
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFF7ECFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Service",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Color.fromARGB(255, 138, 174, 224),
                              ),
                            ),
                            Text(
                              "Price",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: Color.fromARGB(255, 138, 174, 224),
                              ),
                            ),
                          ],
                        ),
                        Divider(color: Color.fromARGB(255, 190, 212, 241).withOpacity(0.2)),
                        ...servicePricing.entries.map((entry) => _buildServiceCheckbox(entry.key, entry.value)),

                        Divider(color: Color.fromARGB(255, 190, 212, 241).withOpacity(0.2)),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "${totalCost.toStringAsFixed(2)} EGP",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Color.fromARGB(255, 17, 67, 143),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),

                  // Booking Form Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Book Appointment",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isCheckingAvailability)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color.fromARGB(255, 138, 174, 224),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Time Selection with availability indicators
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFF7ECFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Select Time",
                        labelStyle: GoogleFonts.poppins(color: Color.fromARGB(255, 138, 174, 224)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.transparent),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.transparent),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Color.fromARGB(255, 138, 174, 224)),
                        ),
                        prefixIcon: Icon(Icons.access_time, color: Color.fromARGB(255, 138, 174, 224)),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      value: selectedTime,
                      style: GoogleFonts.poppins(),
                      dropdownColor: Color(0xFFF7ECFF),
                      items: availableTimeSlots.map((time) {
                        bool isAvailable = timeSlotAvailability[time] ?? true;

                        return DropdownMenuItem(
                          value: time,
                          enabled: isAvailable,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                time,
                                style: TextStyle(
                                    color: isAvailable ? Colors.black : Colors.grey.shade400
                                ),
                              ),
                              if (!isAvailable)
                                Text(
                                  "(Booked)",
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red.shade300,
                                      fontStyle: FontStyle.italic
                                  ),
                                )
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => selectedTime = value!),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Date Selection
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFFF7ECFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.transparent),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Color.fromARGB(255, 138, 174, 224)),
                          SizedBox(width: 10),
                          Text(
                            "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                            style: GoogleFonts.poppins(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 8),

                  // Small note about booking process
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      "Note: Appointments require nurse approval",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Book Now Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ElevatedButton(
                onPressed: isLoading || isCheckingAvailability ? null : _bookAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 3, 36, 78),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: Center(
                  child: isLoading || isCheckingAvailability
                      ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    "Book Now",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCheckbox(String service, double price) {
    return CheckboxListTile(
      title: Text(
        service,
        style: GoogleFonts.poppins(fontSize: 14),
      ),
      subtitle: Text(
        "Includes standard ${service.toLowerCase()} procedure",
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      secondary: Text(
        "${price.toStringAsFixed(2)}EGP",
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: Color.fromARGB(255, 138, 174, 224),
        ),
      ),
      activeColor: Color.fromARGB(255, 138, 174, 224),
      value: selectedServices[service] ?? false,
      onChanged: (bool? value) {
        setState(() {
          selectedServices[service] = value ?? false;
          _calculateTotalCost();
        });
      },
      dense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    );
  }

  Widget _buildStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Color.fromARGB(255, 138, 174, 224)),
        SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.withOpacity(0.3),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFF7ECFF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Color.fromARGB(255, 138, 174, 224), size: 20),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}