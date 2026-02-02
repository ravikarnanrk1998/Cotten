import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Color primerycolor = Colors.green;
Color whitecolor = Colors.white;
Color blackcolor = Colors.black;
Color primerycolorshade = Colors.green.shade900;
Color graycolorshade = Colors.grey.shade300;

TextStyle appbardashbordstyle = GoogleFonts.lobster(
  color: Colors.white,
  fontWeight: FontWeight.w300,
  fontSize: 25,
);

TextStyle appbarstyle = GoogleFonts.roboto(
  color: Colors.white,
  fontWeight: FontWeight.w500,
  fontSize: 25,
);

Widget sectionTitle(BuildContext context, String title) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(width: 4, color: primerycolorshade)),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primerycolor,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget sectiontextTitle(BuildContext context, String title) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: blackcolor,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget commonbutton(BuildContext context, String title) {
  return SizedBox(
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadiusDirectional.circular(10),
        color: primerycolor,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(Icons.add_task,color: whitecolor,size: 30,),
              Text(
                title,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w500,
                  color: whitecolor,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
