import 'package:flutter/material.dart';
import 'commonstyle.dart';
class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
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

      body: Container(
        height: MediaQuery.of(context).size.height,
        color: graycolorshade,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              sectionTitle(context, "Today Status"),
              statusCard(
                title: "Cybrid Cotton",
                totalKg: "120.5 Kg",
                highKg: "60.0 Kg",
                mediumKg: "40.0 Kg",
                lowKg: "20.5 Kg",
              ),
              const SizedBox(height: 24),
              statusCard(
                title: "Normal Cotton",
                totalKg: "120.5 Kg",
                highKg: "60.0 Kg",
                mediumKg: "40.0 Kg",
                lowKg: "20.5 Kg",
              ),

              const SizedBox(height: 24),

               sectionTitle(context, "Current Status"),
              statusCard(
                title: "Cybrid Cotton",
                totalKg: "120.5 Kg",
                highKg: "60.0 Kg",
                mediumKg: "40.0 Kg",
                lowKg: "20.5 Kg",
              ),
              const SizedBox(height: 24),
              statusCard(
                title: "Normal Cotton",
                totalKg: "120.5 Kg",
                highKg: "60.0 Kg",
                mediumKg: "40.0 Kg",
                lowKg: "20.5 Kg",
              ),

              const SizedBox(height: 24),

              sectionTitle(context, "Total Load Status"),

              _tableHeader(),
              _tableRow(
                "Ravi",
                "24 Apr",
                "200",
                "150",
                "₹105k",
                "₹94k",
                "+10k",
              ),
              _tableRow(
                "Aman",
                "23 Apr",
                "280",
                "200",
                "₹140k",
                "₹126k",
                "+14k",
              ),
              _tableRow(
                "Rahul",
                "22 Apr",
                "320",
                "260",
                "₹168k",
                "₹155k",
                "+13k",
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),

      /// BOTTOM NAVIGATION
    );
  }

  /// ===================== WIDGETS =====================

  static Widget statusCard({
    required String title,
    required String totalKg,
    required String highKg,
    required String mediumKg,
    required String lowKg,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                 
                  SizedBox(width: 10,),
                  Text(
                    title,
                    style: commontitelstyle,
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  Text(
                    totalKg,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          /// STATUS ROW
          Row(
            children: [
              _smallStatusCard(
                label: "High",
                value: highKg,
                color: Colors.green,
              ),
              _smallStatusCard(
                label: "Medium",
                value: mediumKg,
                color: Colors.orange,
              ),
              _smallStatusCard(
                label: "Low",
                value: lowKg,
                color: Colors.blueGrey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _smallStatusCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(1)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
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
