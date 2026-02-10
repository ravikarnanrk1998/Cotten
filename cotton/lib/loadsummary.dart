import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'commonstyle.dart';

class LoadSummaryPage extends StatefulWidget {
  final double hybridKg;
  final double lowKg;
  final double mediumKg;
  final double highKg;

  const LoadSummaryPage({
    super.key,
    required this.hybridKg,
    required this.lowKg,
    required this.mediumKg,
    required this.highKg,
  });

  @override
  State<LoadSummaryPage> createState() => _LoadSummaryPageState();
}

class _LoadSummaryPageState extends State<LoadSummaryPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController hybridPriceController = TextEditingController();
  final TextEditingController lowPriceController = TextEditingController();
  final TextEditingController mediumPriceController = TextEditingController();
  final TextEditingController highPriceController = TextEditingController();

  double get hybridTotal =>
      widget.hybridKg * (double.tryParse(hybridPriceController.text) ?? 0);
  double get lowTotal =>
      widget.lowKg * (double.tryParse(lowPriceController.text) ?? 0);
  double get mediumTotal =>
      widget.mediumKg * (double.tryParse(mediumPriceController.text) ?? 0);
  double get highTotal =>
      widget.highKg * (double.tryParse(highPriceController.text) ?? 0);

  double get grandTotal => hybridTotal + lowTotal + mediumTotal + highTotal;

  Future<void> _handleFinalSubmit() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter Party / Load Name",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    // 1. Prepare Summary Item
    final summaryRecord = {
      "name": nameController.text.trim(),
      "date": DateFormat('dd MMM, yyyy').format(DateTime.now()),
      "totalAmount": grandTotal,
      "categories": {
        "hybrid": {
          "kg": widget.hybridKg,
          "price": double.tryParse(hybridPriceController.text) ?? 0,
          "total": hybridTotal,
        },
        "low": {
          "kg": widget.lowKg,
          "price": double.tryParse(lowPriceController.text) ?? 0,
          "total": lowTotal,
        },
        "medium": {
          "kg": widget.mediumKg,
          "price": double.tryParse(mediumPriceController.text) ?? 0,
          "total": mediumTotal,
        },
        "high": {
          "kg": widget.highKg,
          "price": double.tryParse(highPriceController.text) ?? 0,
          "total": highTotal,
        },
      },
    };

    // 2. Save to saved_summary_list
    String? existingData = prefs.getString('saved_summary_list');
    List<dynamic> summaryList = existingData != null
        ? json.decode(existingData)
        : [];
    summaryList.insert(0, summaryRecord);
    await prefs.setString('saved_summary_list', json.encode(summaryList));

    // 3. Clear current history (todayList)
    await prefs.remove('load_sent_list');

    // 4. Return to previous page with success flag
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  void _showSubmitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 10),
            Text("Warning"),
          ],
        ),
        content: Text("Are you sure you want to submit and clear history?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: graydarkcolorshade)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primerycolor),
            onPressed: () {
              Navigator.pop(context);
              _handleFinalSubmit();
            },
            child: Text("OK", style: TextStyle(color: whitecolor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: graycolorshade,
      appBar: AppBar(
        title: Text("Load Summary", style: appbarstyle),
        backgroundColor: primerycolor,
        iconTheme: IconThemeData(color: whitecolor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            // Name Input
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: whitecolor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: TextField(
                controller: nameController,
                style: inputtextstyle,
                decoration: InputDecoration(
                  labelText: "Party / Load Name",
                  labelStyle: inputtextstyle,
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person, color: primerycolor),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Summary List
            Container(
              decoration: BoxDecoration(
                color: whitecolor,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildHeader(),
                  _buildRow(
                    "Hybrid",
                    widget.hybridKg,
                    hybridPriceController,
                    hybridTotal,
                    bluecolor,
                  ),
                  _buildRow(
                    "Normal (Low)",
                    widget.lowKg,
                    lowPriceController,
                    lowTotal,
                    graydarkcolorshade,
                  ),
                  _buildRow(
                    "Normal (Med)",
                    widget.mediumKg,
                    mediumPriceController,
                    mediumTotal,
                    Colors.orange.shade800,
                  ),
                  _buildRow(
                    "Normal (High)",
                    widget.highKg,
                    highPriceController,
                    highTotal,
                    primerycolor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Grand Total
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primerycolor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Grand Total Amount", style: appbarstyle),
                  Text(
                    "₹${NumberFormat('#,##,###.##').format(grandTotal)}",
                    style: appbarstyle.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: redcolor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _showSubmitDialog,
                child: Text(
                  "SUBMIT",
                  style: appbarstyle.copyWith(fontSize: 18, letterSpacing: 1.2),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: primerycolor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              "Quality",
              style: TextStyle(fontWeight: FontWeight.bold, color: blackcolor),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                "Kg",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: blackcolor,
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
                  fontWeight: FontWeight.bold,
                  color: blackcolor,
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
                  fontWeight: FontWeight.bold,
                  color: blackcolor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    double kg,
    TextEditingController controller,
    double total,
    Color color,
  ) {
    if (kg <= 0) return SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                kg.toStringAsFixed(1),
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              alignment: Alignment.centerRight,
              child: Text(
                "₹${NumberFormat('#,##,###.##').format(total)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
