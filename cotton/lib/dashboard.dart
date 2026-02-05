import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'commonstyle.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<Map<String, dynamic>> todayList = [];
  double cybridHigh = 0;
  double cybridMedium = 0;
  double cybridLow = 0;
  double cybridTotal = 0;

  double normalHigh = 0;
  double normalMedium = 0;
  double normalLow = 0;
  double normalTotal = 0;

  double totalAmount = 0;

  @override
  void initState() {
    super.initState();
    loadLocalData();
  }

  // 🔹 LOAD DATA FROM LOCAL STORAGE
  Future<void> loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('today_load_list');

    if (data != null) {
      final List<Map<String, dynamic>> loadedList =
          List<Map<String, dynamic>>.from(json.decode(data));

      final status = calculateStatus(loadedList);

      setState(() {
        cybridHigh = status["cybridHigh"];
        cybridMedium = status["cybridMedium"];
        cybridLow = status["cybridLow"];
        cybridTotal = status["cybridTotal"];

        normalHigh = status["normalHigh"];
        normalMedium = status["normalMedium"];
        normalLow = status["normalLow"];
        normalTotal = status["normalTotal"];

        totalAmount = status["totalAmount"];
      });
    }
  }

  Map<String, dynamic> calculateStatus(List<Map<String, dynamic>> list) {
    double cybridHigh = 0, cybridMedium = 0, cybridLow = 0;
    double normalHigh = 0, normalMedium = 0, normalLow = 0;
    double totalAmount = 0;

    for (var item in list) {
      final cotton = item["cotton"];
      final quality = item["quality"];
      final kg = double.tryParse(item["kg"].toString()) ?? 0;
      final amount = (item["amount"] ?? 0).toDouble();

      totalAmount += amount;

      /// CYBRID
      if (cotton.contains("Cybrid")) {
        if (quality == "High") cybridHigh += kg;
        if (quality == "Medium") cybridMedium += kg;
        if (quality == "Low") cybridLow += kg;
      }

      /// NORMAL
      if (cotton.contains("Normal")) {
        if (quality == "High") normalHigh += kg;
        if (quality == "Medium") normalMedium += kg;
        if (quality == "Low") normalLow += kg;
      }
    }

    return {
      "cybridHigh": cybridHigh,
      "cybridMedium": cybridMedium,
      "cybridLow": cybridLow,
      "cybridTotal": cybridHigh + cybridMedium + cybridLow,

      "normalHigh": normalHigh,
      "normalMedium": normalMedium,
      "normalLow": normalLow,
      "normalTotal": normalHigh + normalMedium + normalLow,

      "totalAmount": totalAmount,
    };
  }

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
              singleStatusCard(
                title: sectionTitle(context, "Today Status"),
                totalAmount: totalAmount.toStringAsFixed(0),

                cybridHigh: "${cybridHigh.toStringAsFixed(0)} Kg",
                cybridMedium: "${cybridMedium.toStringAsFixed(0)} Kg",
                cybridLow: "${cybridLow.toStringAsFixed(0)} Kg",
                cybridTotal: "${cybridTotal.toStringAsFixed(0)} Kg",

                normalHigh: "${normalHigh.toStringAsFixed(0)} Kg",
                normalMedium: "${normalMedium.toStringAsFixed(0)} Kg",
                normalLow: "${normalLow.toStringAsFixed(0)} Kg",
                normalTotal: "${normalTotal.toStringAsFixed(0)} Kg",
              ),

              const SizedBox(height: 12),

              singleStatusCard(
                title: sectionTitle(context, "Current Status"),
                totalAmount: "54876",
                cybridHigh: "60 Kg",
                cybridMedium: "40 Kg",
                cybridLow: "20 Kg",
                cybridTotal: "120 Kg",
                normalHigh: "30 Kg",
                normalMedium: "40 Kg",
                normalLow: "20 Kg",
                normalTotal: "90 Kg",
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
  static Widget singleStatusCard({
    required Widget title,
    // Cybrid
    required String totalAmount,
    required String cybridHigh,
    required String cybridMedium,
    required String cybridLow,
    required String cybridTotal,

    // Normal
    required String normalHigh,
    required String normalMedium,
    required String normalLow,
    required String normalTotal,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
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
              title,
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text("₹ $totalAmount", style: textstyle),
              ),
             
            ],
          ),
         
          /// COLUMN TITLES
          Row(
            children: const [
              SizedBox(width: 90),
              Expanded(
                child: Text(
                  "Cybrid",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text(
                  "Normal",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(height: 5),

          /// HIGH
          _statusRow(
            label: "High",
            cybridValue: cybridHigh,
            normalValue: normalHigh,
            color: Colors.green,
          ),

          /// MEDIUM
          _statusRow(
            label: "Medium",
            cybridValue: cybridMedium,
            normalValue: normalMedium,
            color: Colors.orange,
          ),

          /// LOW
          _statusRow(
            label: "Low",
            cybridValue: cybridLow,
            normalValue: normalLow,
            color: Colors.blueGrey,
          ),

          const Divider(height: 5),

          /// TOTAL
          _statusRow(
            label: "Total",
            cybridValue: cybridTotal,
            normalValue: normalTotal,
            color: Colors.blue,
            isBold: true,
          ),
        ],
      ),
    );
  }

  static Widget _statusRow({
    required String label,
    required String cybridValue,
    required String normalValue,
    required Color color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              cybridValue,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              normalValue,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
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
}
