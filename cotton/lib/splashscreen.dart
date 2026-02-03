import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bottomcommon.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainContainer()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
               "assets/image/splashscreen.jpg",
              fit: BoxFit.cover,
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top:150),
              child: Text(
                'Santhi Cotton',
                style:  GoogleFonts.roboto(
                  color: Colors.grey.shade300,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 1,
                      color: Colors.brown,
                      offset: Offset(-3, 3),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
