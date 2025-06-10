import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:lastver/screens/patient/favourite_nurse_screen.dart';
import 'package:lastver/screens/patient/patient_home_page.dart';
import '../medicine/MedicationReminderPage.dart';
import 'AppointmentStatusScreen.dart';
import 'PatientProfileScreen.dart';


class PatientMainPage extends StatefulWidget {
  const PatientMainPage({super.key});

  @override
  _PatientMainPageState createState() => _PatientMainPageState();
}

class _PatientMainPageState extends State<PatientMainPage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _widgetOptions = [
    PatientHomePage(),
    AppointmentStatusScreen(),
    FavoriteNursesScreen(),
    MedicationReminderPage(backgroundColor: Colors.white,
      appBarColor: Color.fromARGB(255, 3, 36, 78),
      iconColor: Color.fromARGB(255, 3, 36, 78),
      textColor: Color.fromARGB(255, 0, 0, 0)),
    PatientProfileScreen(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Disable swipe
        children: _widgetOptions,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(0.1),
            )
          ],
          border: Border(
            top: BorderSide(
              color: Colors.grey.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 4,
              activeColor: isDarkMode ? Colors.white : Color.fromARGB(255, 3, 36, 78),
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              duration: const Duration(milliseconds: 300),
              tabBackgroundColor: isDarkMode ? Colors.grey[800]! : Color.fromARGB(255, 67, 132, 163),
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              tabs: [
                GButton(
                  icon: Icons.home_outlined,
                   text: 'Home',
                  iconActiveColor: isDarkMode ? Colors.white : Color.fromARGB(
                      255, 255, 255, 255),
                  textColor: Colors.white,
                ),
                GButton(
                  icon: Icons.app_registration_outlined,
                  text: 'Status',
                  iconActiveColor: isDarkMode ? Colors.white : Color.fromARGB(
                      255, 255, 255, 255),
                  textColor: Colors.white,
                ),
                GButton(
                  icon: Icons.favorite,
                  text: 'fav',
                  iconActiveColor: isDarkMode ? Colors.white : Color.fromARGB(
                      255, 255, 255, 255),
                  textColor: Colors.white,
                ),
                GButton(
                  icon: Icons.medical_services_outlined,
                  text: 'Reminders',
                  iconActiveColor: isDarkMode ? Colors.white : Color.fromARGB(
                      255, 255, 255, 255),
                  textColor: Colors.white,
                ),
                GButton(
                  icon: Icons.person_outline,
                  text: 'Profile',
                  iconActiveColor: isDarkMode ? Colors.white : Color.fromARGB(
                      255, 255, 255, 255),
                  textColor: Colors.white,
                ),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                setState(() {
                  _selectedIndex = index;
                  _pageController.jumpToPage(index);
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}