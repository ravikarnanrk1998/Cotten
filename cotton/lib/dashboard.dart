import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'commonstyle.dart';
import 'firebase_service.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final Map<String, TextEditingController> paymentControllers = {};
  int _resetTimestamp = 0;

  @override
  void initState() {
    super.initState();
    _loadResetTimestamp();
  }

  Future<void> _loadResetTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _resetTimestamp = prefs.getInt('dashboard_reset_time') ?? 0;
    });
  }

  Future<void> handleFrontendReset() async {
    // confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Current Status?"),
        content: const Text(
          "This will reset the displayed values to zero. It will NOT delete data from the database.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Reset", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt('dashboard_reset_time', now);
      setState(() {
        _resetTimestamp = now;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Status reset. Future entries will show here."),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> deleteSummary(String id) async {
    try {
      await FirebaseService.deleteSummary(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void addPayment(
    String id,
    Map<String, dynamic> item,
    String amountStr,
  ) async {
    double amount = double.tryParse(amountStr) ?? 0;
    if (amount <= 0) return;

    try {
      double currentPaid =
          double.tryParse(item['paid']?.toString() ?? "0") ?? 0;
      await FirebaseService.updateSummary(id, {'paid': currentPaid + amount});
      paymentControllers[id]?.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Map<String, dynamic> calculateStatus(List<Map<String, dynamic>> list) {
    double hHigh = 0, hMed = 0, hLow = 0;
    double nHigh = 0, nMed = 0, nLow = 0;
    double totalAmt = 0;

    for (var item in list) {
      if (item.containsKey('categories')) {
        // Finalized Summary Record
        totalAmt += (item["totalAmount"] ?? 0).toDouble();
        Map<String, dynamic> cats = item['categories'] ?? {};

        cats.forEach((key, val) {
          double kg = (val["kg"] ?? 0).toDouble();
          if (kg <= 0) {
            double gKg = (val["gross_kg"] ?? 0).toDouble();
            double ded = (val["deduction"] ?? 0).toDouble();
            kg = gKg - ded;
          }

          if (key == "hybrid") {
            hHigh += kg;
          } else if (key == "high") {
            nHigh += kg;
          } else if (key == "medium") {
            nMed += kg;
          } else if (key == "low") {
            nLow += kg;
          }
        });
      } else {
        // Raw Load Entry
        String cotton = (item["cotton"] ?? "").toString();
        String quality = (item["quality"] ?? "").toString();
        double kg = double.tryParse(item["kg"]?.toString() ?? "0") ?? 0;
        double amount = double.tryParse(item["amount"]?.toString() ?? "0") ?? 0;

        totalAmt += amount;

        if (cotton.contains("Hybrid")) {
          if (quality == "High")
            hHigh += kg;
          else if (quality == "Medium")
            hMed += kg;
          else
            hLow += kg;
        } else if (cotton.contains("Normal")) {
          if (quality == "High")
            nHigh += kg;
          else if (quality == "Medium")
            nMed += kg;
          else
            nLow += kg;
        }
      }
    }

    return {
      "hybridHigh": hHigh,
      "hybridMedium": hMed,
      "hybridLow": hLow,
      "hybridTotal": hHigh + hMed + hLow,
      "normalHigh": nHigh,
      "normalMedium": nMed,
      "normalLow": nLow,
      "normalTotal": nHigh + nMed + nLow,
      "totalAmount": totalAmt,
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
        // actions: const [
        //   Padding(
        //     padding: EdgeInsets.only(right: 16),
        //     child: Icon(Icons.print_rounded, color: Colors.white),
        //   ),
        // ],
      ),
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height,
            color: graycolorshade,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 1. Current Status (Stream from loads, filtered by frontend reset time)
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: FirebaseService.getLoads(),
                    builder: (context, snapshot) {
                      final data = snapshot.data ?? [];
                      // Filter by frontend reset timestamp
                      final filteredData = data.where((item) {
                        final timestamp = item['timestamp'] as int? ?? 0;
                        return timestamp >= _resetTimestamp;
                      }).toList();

                      final status = calculateStatus(filteredData);
                      return _singleStatusCard(
                        title: sectionTitle(context, "Current Status"),
                        totalAmount: status["totalAmount"].toStringAsFixed(0),
                        hybridHigh:
                            "${status["hybridHigh"].toStringAsFixed(0)} Kg",
                        hybridMedium:
                            "${status["hybridMedium"].toStringAsFixed(0)} Kg",
                        hybridLow:
                            "${status["hybridLow"].toStringAsFixed(0)} Kg",
                        hybridTotal:
                            "${status["hybridTotal"].toStringAsFixed(0)} Kg",
                        normalHigh:
                            "${status["normalHigh"].toStringAsFixed(0)} Kg",
                        normalMedium:
                            "${status["normalMedium"].toStringAsFixed(0)} Kg",
                        normalLow:
                            "${status["normalLow"].toStringAsFixed(0)} Kg",
                        normalTotal:
                            "${status["normalTotal"].toStringAsFixed(0)} Kg",
                        onReset: handleFrontendReset,
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                  sectionTitle(context, "Total Load Status"),
                  const SizedBox(height: 10),

                  // 3. Saved Summaries (Stream from summaries)
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: FirebaseService.getSummaries(),
                    builder: (context, snapshot) {
                      final savedSummaries = snapshot.data ?? [];
                      if (savedSummaries.isEmpty) {
                        return Container(
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
                        );
                      }

                      final activeSummaries = savedSummaries.where((item) {
                        double total = (item['totalAmount'] ?? 0).toDouble();
                        double paid = (item['paid'] ?? 0).toDouble();
                        return (total - paid) > 0;
                      }).toList();

                      return Column(
                        children: activeSummaries.map((item) {
                          final id = item['id'] as String;
                          return _summaryRow(id, item);
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ===================== WIDGETS =====================
  Widget _singleStatusCard({
    required Widget title,
    required String totalAmount,
    required String hybridHigh,
    required String hybridMedium,
    required String hybridLow,
    required String hybridTotal,
    required String normalHigh,
    required String normalMedium,
    required String normalLow,
    required String normalTotal,
    VoidCallback? onReset,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  title,
                  if (onReset != null)
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: onReset,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Text("₹ $totalAmount", style: textstyle),
              ),
            ],
          ),
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
          _statusRow(
            label: "High",
            hybridValue: hybridHigh,
            normalValue: normalHigh,
            color: Colors.green,
          ),
          _statusRow(
            label: "Medium",
            hybridValue: hybridMedium,
            normalValue: normalMedium,
            color: Colors.orange,
          ),
          _statusRow(
            label: "Low",
            hybridValue: hybridLow,
            normalValue: normalLow,
            color: Colors.blueGrey,
          ),
          const Divider(height: 5),
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

  Widget _statusRow({
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

  Widget _summaryRow(String id, Map<String, dynamic> item) {
    if (!paymentControllers.containsKey(id)) {
      paymentControllers[id] = TextEditingController();
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _amountColumn("Total Amount", totalAmount, primerycolor),
              _amountColumn("Paid", paidAmount, Colors.green),
              _amountColumn("Balance", balanceAmount, Colors.red, isBold: true),
            ],
          ),
          const SizedBox(height: 20),
          if (balanceAmount > 0)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: paymentControllers[id],
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
                      addPayment(id, item, paymentControllers[id]!.text),
                  child: const Text(
                    "ADD",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => deleteSummary(id),
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
