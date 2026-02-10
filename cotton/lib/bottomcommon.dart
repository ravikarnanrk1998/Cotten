import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import 'commonstyle.dart';
import 'currentdata.dart';
import 'dashboard.dart';
import 'inputdata.dart';
import 'loadsent.dart';
import 'previewsdata.dart';

class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    Dashboard(),
    InputData(),
    CurrectData(),
    PreviewsData(),
    LoadSendData(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // ⭐ REQUIRED FOR TRANSPARENT NAV
      backgroundColor: Colors.transparent,

      body: _pages[_currentIndex],

      bottomNavigationBar: CurvedNavigationBar(
        index: _currentIndex,
        height: 65,
        color: primerycolor,
        backgroundColor: Colors.transparent,
        buttonBackgroundColor: primerycolor,
        animationDuration: const Duration(milliseconds: 400),
        items: const [
          Icon(Icons.dashboard, color: Colors.white),
          Icon(Icons.input, color: Colors.white),
          Icon(Icons.stacked_bar_chart, color: Colors.white),
          Icon(Icons.analytics, color: Colors.white),
          Icon(Icons.local_shipping, color: Colors.white),
        ],
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
