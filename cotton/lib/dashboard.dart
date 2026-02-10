import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'commonstyle.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  double totalAmount = 0;
  double hybridHigh = 0;
  double hybridMedium = 0;
  double hybridLow = 0;
  double hybridTotal = 0;

  double normalHigh = 0;
  double normalMedium = 0;
  double normalLow = 0;
  double normalTotal = 0;

  List<Map<String, dynamic>> savedSummaries = [];

  @override
  void initState() {
    super.initState();
    loadLocalData();
  }

  // 🔹 LOAD DATA FROM LOCAL STORAGE
  Future<void> loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();

    // Fetch Status data
    final data = prefs.getString('today_load_list');
    if (data != null) {
      final List<Map<String, dynamic>> loadedList =
          List<Map<String, dynamic>>.from(json.decode(data));

      final status = calculateStatus(loadedList);

      setState(() {
        hybridHigh = status["hybridHigh"];
        hybridMedium = status["hybridMedium"];
        hybridLow = status["hybridLow"];
        hybridTotal = status["hybridTotal"];

        normalHigh = status["normalHigh"];
        normalMedium = status["normalMedium"];
        normalLow = status["normalLow"];
        normalTotal = status["normalTotal"];

        totalAmount = status["totalAmount"];
      });
    }

    // Fetch Saved Summaries
    final savedData = prefs.getString('saved_summary_list');
    if (savedData != null) {
      setState(() {
        savedSummaries = List<Map<String, dynamic>>.from(
          json.decode(savedData),
        );
      });
    }
  }

  Future<void> deleteSummary(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedSummaries.removeAt(index);
    });
    await prefs.setString('saved_summary_list', json.encode(savedSummaries));
  }

  Map<String, dynamic> calculateStatus(List<Map<String, dynamic>> list) {
    double hybridHigh = 0, hybridMedium = 0, hybridLow = 0;
    double normalHigh = 0, normalMedium = 0, normalLow = 0;
    double totalAmount = 0;

    for (var item in list) {
      final cotton = item["cotton"];
      final quality = item["quality"];
      final kg = double.tryParse(item["kg"].toString()) ?? 0;
      final amount = (item["amount"] ?? 0).toDouble();

      totalAmount += amount;

      /// HYBRID
      if (cotton.contains("Hybrid")) {
        if (quality == "High") hybridHigh += kg;
        if (quality == "Medium") hybridMedium += kg;
        if (quality == "Low") hybridLow += kg;
      }

      /// NORMAL
      if (cotton.contains("Normal")) {
        if (quality == "High") normalHigh += kg;
        if (quality == "Medium") normalMedium += kg;
        if (quality == "Low") normalLow += kg;
      }
    }

    return {
      "hybridHigh": hybridHigh,
      "hybridMedium": hybridMedium,
      "hybridLow": hybridLow,
      "hybridTotal": hybridHigh + hybridMedium + hybridLow,

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

                hybridHigh: "${hybridHigh.toStringAsFixed(0)} Kg",
                hybridMedium: "${hybridMedium.toStringAsFixed(0)} Kg",
                hybridLow: "${hybridLow.toStringAsFixed(0)} Kg",
                hybridTotal: "${hybridTotal.toStringAsFixed(0)} Kg",

                normalHigh: "${normalHigh.toStringAsFixed(0)} Kg",
                normalMedium: "${normalMedium.toStringAsFixed(0)} Kg",
                normalLow: "${normalLow.toStringAsFixed(0)} Kg",
                normalTotal: "${normalTotal.toStringAsFixed(0)} Kg",
              ),

              const SizedBox(height: 12),

              singleStatusCard(
                title: sectionTitle(context, "Current Status"),
                totalAmount: "54876",
                hybridHigh: "60 Kg",
                hybridMedium: "40 Kg",
                hybridLow: "20 Kg",
                hybridTotal: "120 Kg",
                normalHigh: "30 Kg",
                normalMedium: "40 Kg",
                normalLow: "20 Kg",
                normalTotal: "90 Kg",
              ),

              const SizedBox(height: 24),

              sectionTitle(context, "Total Load Status"),
              const SizedBox(height: 10),

              if (savedSummaries.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text(
                      "No saved summaries found.",
                      style: TextStyle(
                        color: graydarkcolorshade,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              else
                ...List.generate(savedSummaries.length, (index) {
                  final item = savedSummaries[index];
                  return _summaryRow(index, item);
                }),
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
    // Hybrid
    required String totalAmount,
    required String hybridHigh,
    required String hybridMedium,
    required String hybridLow,
    required String hybridTotal,

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
                  "Hybrid",
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
            hybridValue: hybridHigh,
            normalValue: normalHigh,
            color: Colors.green,
          ),

          /// MEDIUM
          _statusRow(
            label: "Medium",
            hybridValue: hybridMedium,
            normalValue: normalMedium,
            color: Colors.orange,
          ),

          /// LOW
          _statusRow(
            label: "Low",
            hybridValue: hybridLow,
            normalValue: normalLow,
            color: Colors.blueGrey,
          ),

          const Divider(height: 5),

          /// TOTAL
          _statusRow(
            label: "Total",
            hybridValue: hybridTotal,
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
    required String hybridValue,
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
              hybridValue,
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

  Widget _summaryRow(int index, Map<String, dynamic> item) {
    Map<String, dynamic> categories = item['categories'] ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item['name'] ?? "Unknown",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Colors.black87,
                ),
              ),
              Text(
                item['date'] ?? "-",
                style: TextStyle(
                  color: graydarkcolorshade,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 1),

          // Details Table Header
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  "Type/Quality",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    "Kg",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text(
                    "Price",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Container(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Total",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),

          // Render each category breakdown
          ...categories.entries
              .where((e) {
                var val = e.value;
                return (val is Map) &&
                    (double.tryParse(val['kg'].toString()) ?? 0) > 0;
              })
              .map((entry) {
                String label = entry.key;
                var data = entry.value;
                String type = label == "hybrid" ? "Hybrid" : "Normal";
                String quality = label == "hybrid"
                    ? "Cotton"
                    : entry.key.replaceFirst(
                        entry.key[0],
                        entry.key[0].toUpperCase(),
                      );
                Color color = label == "hybrid"
                    ? bluecolor
                    : (label == "high"
                          ? primerycolor
                          : (label == "medium"
                                ? Colors.orange.shade800
                                : graydarkcolorshade));

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              type,
                              style: TextStyle(
                                fontSize: 12,
                                color: color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              quality,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Text(
                            "${data['kg']}",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Text(
                            "₹${data['price']}",
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Container(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "₹${NumberFormat('#,##,###').format(data['total'] ?? 0)}",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              })
              .toList(),

          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Grand Total Amount",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "₹${NumberFormat('#,##,###').format(item['totalAmount'] ?? 0)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primerycolor,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
