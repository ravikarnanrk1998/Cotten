import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'commonstyle.dart';
import 'firebase_service.dart';

class LoadSummaryPage extends StatefulWidget {
  final double hybridKg;
  final double lowKg;
  final double mediumKg;
  final double highKg;
  final List<double> hybridList;
  final List<double> lowList;
  final List<double> mediumList;
  final List<double> highList;

  const LoadSummaryPage({
    super.key,
    required this.hybridKg,
    required this.lowKg,
    required this.mediumKg,
    required this.highKg,
    required this.hybridList,
    required this.lowList,
    required this.mediumList,
    required this.highList,
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

  final TextEditingController hybridDedController = TextEditingController();
  final TextEditingController lowDedController = TextEditingController();
  final TextEditingController mediumDedController = TextEditingController();
  final TextEditingController highDedController = TextEditingController();

  double get hybridTotal {
    double netKg =
        widget.hybridKg - (double.tryParse(hybridDedController.text) ?? 0);
    return netKg * (double.tryParse(hybridPriceController.text) ?? 0);
  }

  double get lowTotal {
    double netKg = widget.lowKg - (double.tryParse(lowDedController.text) ?? 0);
    return netKg * (double.tryParse(lowPriceController.text) ?? 0);
  }

  double get mediumTotal {
    double netKg =
        widget.mediumKg - (double.tryParse(mediumDedController.text) ?? 0);
    return netKg * (double.tryParse(mediumPriceController.text) ?? 0);
  }

  double get highTotal {
    double netKg =
        widget.highKg - (double.tryParse(highDedController.text) ?? 0);
    return netKg * (double.tryParse(highPriceController.text) ?? 0);
  }

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

    final summaryRecord = {
      "name": nameController.text.trim(),
      "date": DateFormat('dd MMM, yyyy').format(DateTime.now()),
      "totalAmount": grandTotal,
      "paid": 0.0,
      "categories": {
        "hybrid": {
          "gross_kg": widget.hybridKg,
          "deduction": double.tryParse(hybridDedController.text) ?? 0,
          "price": double.tryParse(hybridPriceController.text) ?? 0,
          "total": hybridTotal,
          "kg_list": widget.hybridList.map((e) => e.toString()).toList(),
        },
        "low": {
          "gross_kg": widget.lowKg,
          "deduction": double.tryParse(lowDedController.text) ?? 0,
          "price": double.tryParse(lowPriceController.text) ?? 0,
          "total": lowTotal,
          "kg_list": widget.lowList.map((e) => e.toString()).toList(),
        },
        "medium": {
          "gross_kg": widget.mediumKg,
          "deduction": double.tryParse(mediumDedController.text) ?? 0,
          "price": double.tryParse(mediumPriceController.text) ?? 0,
          "total": mediumTotal,
          "kg_list": widget.mediumList.map((e) => e.toString()).toList(),
        },
        "high": {
          "gross_kg": widget.highKg,
          "deduction": double.tryParse(highDedController.text) ?? 0,
          "price": double.tryParse(highPriceController.text) ?? 0,
          "total": highTotal,
          "kg_list": widget.highList.map((e) => e.toString()).toList(),
        },
      },
    };

    try {
      await FirebaseService.addSummary(summaryRecord);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSubmitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 10),
            Text("Warning"),
          ],
        ),
        content: const Text(
          "Are you sure you want to submit and clear history?",
        ),
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
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
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person, color: primerycolor),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
                        hybridDedController,
                        hybridPriceController,
                        hybridTotal,
                        bluecolor,
                      ),
                      _buildRow(
                        "Normal (Low)",
                        widget.lowKg,
                        lowDedController,
                        lowPriceController,
                        lowTotal,
                        graydarkcolorshade,
                      ),
                      _buildRow(
                        "Normal (Med)",
                        widget.mediumKg,
                        mediumDedController,
                        mediumPriceController,
                        mediumTotal,
                        Colors.orange.shade800,
                      ),
                      _buildRow(
                        "Normal (High)",
                        widget.highKg,
                        highDedController,
                        highPriceController,
                        highTotal,
                        primerycolor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
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
                      style: appbarstyle.copyWith(
                        fontSize: 18,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
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
                "- Kg",
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
    TextEditingController dedController,
    TextEditingController priceController,
    double total,
    Color color,
  ) {
    if (kg <= 0) return const SizedBox.shrink();
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
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextField(
              controller: dedController,
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
            flex: 2,
            child: TextField(
              controller: priceController,
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
