import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'commonstyle.dart';

class PreviewsData extends StatefulWidget {
  const PreviewsData({super.key});

  @override
  State<PreviewsData> createState() => _PreviewsDataState();
}

class _PreviewsDataState extends State<PreviewsData> {
  List<Map<String, dynamic>> savedSummaries = [];
  List<Map<String, dynamic>> filteredSummaries = [];
  final Map<int, TextEditingController> paymentControllers = {};

  List<Map<String, dynamic>> allSavedSummaries = [];

  Future<void> loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Summaries
    final summaryData = prefs.getString('saved_summary_list');
    if (summaryData != null) {
      allSavedSummaries = List<Map<String, dynamic>>.from(
        json.decode(summaryData),
      );
      setState(() {
        filteredSummaries = allSavedSummaries.reversed.toList();
      });
    }
  }

  Future<void> saveUpdatedSummaries(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_summary_list', json.encode(list));
  }

  void addPayment(int index, String amountStr) async {
    double amount = double.tryParse(amountStr) ?? 0;
    if (amount <= 0) return;

    setState(() {
      final item = filteredSummaries[index];
      double currentPaid = (item['paid'] ?? 0).toDouble();
      item['paid'] = currentPaid + amount;
      paymentControllers[index]?.clear();
    });

    await saveUpdatedSummaries(allSavedSummaries);
  }

  @override
  void initState() {
    super.initState();
    loadLocalData();
  }

  Future<void> pickDate(BuildContext context) async {
    DateTime now = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: now,
    );

    if (pickedDate != null) {
      filterDataByDate(pickedDate);
    }
  }

  String formatDate(DateTime date) {
    return DateFormat('dd MMM').format(date);
  }

  String formatDateFull(DateTime date) {
    return DateFormat('dd MMM, yyyy').format(date);
  }

  void filterDataByDate(DateTime selectedDate) {
    final fullDateStr = formatDateFull(selectedDate);

    // Filter Summaries List
    final summariesList = allSavedSummaries.where((item) {
      return item['date'] == fullDateStr;
    }).toList();

    setState(() {
      filteredSummaries = summariesList.reversed.toList();
      paymentControllers.clear(); // Clear controllers when date changes
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text("Previews Load Sent", style: appbarstyle),
        backgroundColor: primerycolor,
        iconTheme: IconThemeData(color: whitecolor),
        actions: [
          IconButton(
            onPressed: () => pickDate(context),
            icon: Icon(Icons.date_range, size: 35),
          ),
          const SizedBox(width: 25),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 50),
        child: Container(
          height: MediaQuery.of(context).size.height,
          color: graycolorshade,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: CustomScrollView(
              slivers: [
                if (filteredSummaries.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return _summaryRow(index, filteredSummaries[index]);
                    }, childCount: filteredSummaries.length),
                  )
                else
                  SliverToBoxAdapter(
                    child: Container(
                      height: 200,
                      alignment: Alignment.center,
                      child: Text(
                        "No summaries found for this date.",
                        style: TextStyle(
                          color: graydarkcolorshade,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(int index, Map<String, dynamic> item) {
    if (!paymentControllers.containsKey(index)) {
      paymentControllers[index] = TextEditingController();
    }
    double totalAmount = (item['totalAmount'] ?? 0).toDouble();
    double paidAmount = (item['paid'] ?? 0).toDouble();
    double balanceAmount = totalAmount - paidAmount;

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
                double gKg =
                    double.tryParse(val['gross_kg']?.toString() ?? '') ?? 0;
                double ded =
                    double.tryParse(val['deduction']?.toString() ?? '') ?? 0;
                double net =
                    double.tryParse(val['kg']?.toString() ?? '') ?? (gKg - ded);
                return net > 0;
              })
              .map((entry) {
                String label = entry.key;
                var data = entry.value;
                double gKg =
                    double.tryParse(data['gross_kg']?.toString() ?? '') ?? 0;
                double ded =
                    double.tryParse(data['deduction']?.toString() ?? '') ?? 0;
                double net =
                    double.tryParse(data['kg']?.toString() ?? '') ??
                    (gKg - ded);
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (data.containsKey('gross_kg'))
                                Text(
                                  "${gKg.toStringAsFixed(1)} - ${ded.toStringAsFixed(1)}",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              Text(
                                "${net.toStringAsFixed(1)}",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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

          const Divider(height: 30),

          // Payment and Balance Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _amountColumn("Total Amount", totalAmount, primerycolor),
              _amountColumn("Paid", paidAmount, Colors.green),
              _amountColumn("Balance", balanceAmount, Colors.red, isBold: true),
            ],
          ),

          const SizedBox(height: 20),

          // Add Payment Input (Hide if balance is 0)
          if (balanceAmount > 0)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: paymentControllers[index],
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Add Payment (₹)",
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  onPressed: () =>
                      addPayment(index, paymentControllers[index]!.text),
                  child: const Text(
                    "ADD",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text(
                  "✅ FULL PAID",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _amountColumn(
    String label,
    double amount,
    Color color, {
    bool isBold = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          "₹${NumberFormat('#,##,###').format(amount)}",
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
            fontSize: isBold ? 18 : 15,
          ),
        ),
      ],
    );
  }
}
