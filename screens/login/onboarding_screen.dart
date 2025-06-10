import 'package:flutter/material.dart';
import 'selection_screen.dart';


class OnboardingScreen extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(preferredSize: const Size.fromHeight(80),
          child: AppBar(
            backgroundColor: const Color(0xFF638ECB),
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight:Radius.circular(20) )
            ),
          ),),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            flex: 1,
            child: Image.asset(
              'assets/onBoarding_photo-removebg-preview.png',),
          ),
          Container(
            height: 300,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF638ECB),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20))
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Find Your Best Nursing\nServices",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Now it's easy to connect to help\nwhen you need",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 20,),
                    ElevatedButton(
                      onPressed: () =>  Navigator.push(context, MaterialPageRoute(builder: (context)=>SelectionScreen())),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('Get Started',
                        style: TextStyle(color: Color(0xFF638ECB),fontWeight: FontWeight.bold),),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
