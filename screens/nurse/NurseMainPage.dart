import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import '../medicine/MedicationReminderPage.dart';
import 'nurse_homepage.dart';
import 'profile.dart';

class NurseMainPage extends StatefulWidget {
  const NurseMainPage({super.key});

  @override
  _NurseMainPageState createState() => _NurseMainPageState();
}

class _NurseMainPageState extends State<NurseMainPage> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _widgetOptions = [
    NurseHomePage(),
    MedicationReminderPage(backgroundColor: Color.fromARGB(255, 255, 255, 255),appBarColor: Color.fromARGB(
        255, 33, 117, 105)),
    NurseProfilePage(),
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 8,
              activeColor: isDarkMode ? Colors.white : Colors.teal[700]!,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              duration: const Duration(milliseconds: 300),
              tabBackgroundColor: isDarkMode ? Colors.grey[800]! : Colors.teal[50]!,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              tabs: [
                GButton(
                  icon: Icons.home_outlined,
                  text: 'Home',
                  iconActiveColor: isDarkMode ? Colors.white : Colors.teal[700],
                ),
                GButton(
                  icon: Icons.medical_services_outlined,
                  text: 'Reminders',
                  iconActiveColor: isDarkMode ? Colors.white : Colors.teal[700],
                ),
                GButton(
                  icon: Icons.person_outline,
                  text: 'Profile',
                  iconActiveColor: isDarkMode ? Colors.white : Colors.teal[700],
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