import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import 'commonstyle.dart';
import 'inputdata.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primerycolor,
        elevation: 0,
        title: Row(
          children: [
            Image.asset("assets/image/cotton2.png", width: 60),
            SizedBox(width: 8),
            Text("Santhi Cotton Shop", style: appbardashbordstyle),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.print_rounded, color: Colors.white),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// LOAD STATUS
            sectionTitle(context, "Load Status",),

            Row(
              children: [
                _statusCard("Today Kg", "380 Kg", "₹ 210,135"),
                const SizedBox(width: 12),
                _statusCard("Total Kg", "12,480 Kg", "₹ 6,411,255"),
              ],
            ),

            const SizedBox(height: 24),

            sectionTitle(context, "Total Load Status",),

            _tableHeader(),
            _tableRow("Ravi", "24 Apr", "200", "150", "₹105k", "₹94k", "+10k"),
            _tableRow("Aman", "23 Apr", "280", "200", "₹140k", "₹126k", "+14k"),
            _tableRow(
              "Rahul",
              "22 Apr",
              "320",
              "260",
              "₹168k",
              "₹155k",
              "+13k",
            ),
          ],
        ),
      ),

      /// BOTTOM NAVIGATION
      bottomNavigationBar: CurvedNavigationBar(
        index: _currentIndex,
        height: 65,
        color: primerycolor,
        backgroundColor: Colors.white,
        buttonBackgroundColor: primerycolor,
        animationDuration: const Duration(milliseconds: 400),
        items: const [
          Icon(Icons.input, size: 26, color: Colors.white),
          Icon(Icons.table_view_outlined, size: 26, color: Colors.white),
          Icon(Icons.analytics, size: 26, color: Colors.white),
          Icon(Icons.local_shipping, size: 26, color: Colors.white),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          // Optional navigation logic

          switch (index) {
            case 0:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const InputData()),
              );
              break;
            case 1:
              // Load Send
              break;
            case 2:
              // Reports
              break;
            case 3:
              // Profile
              break;
          }
        },
      ),
    );
  }

  /// ===================== WIDGETS =====================

  static Widget _statusCard(String title, String kg, String amount) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _boxDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.yellow,
              ),
            ),
            const SizedBox(height: 8),
            Text(kg, style: const TextStyle(fontSize: 18, color: Colors.white)),
            const SizedBox(height: 6),
            Text(
              amount,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Name"),
          Text("Date"),
          Text("In"),
          Text("Out"),
          Text("Spend"),
          Text("Return"),
          Text("P/L"),
        ],
      ),
    );
  }

  static Widget _tableRow(
    String n,
    String d,
    String i,
    String o,
    String s,
    String r,
    String p,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(n),
          Text(d),
          Text(i),
          Text(o),
          Text(s),
          Text(r),
          Text(p, style: TextStyle(color: primerycolor)),
        ],
      ),
    );
  }

  static BoxDecoration _boxDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(colors: [Colors.teal, primerycolor]),

      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
      ],
    );
  }
}

Widget revealedContainer({required Widget child}) => Expanded(child: child);
