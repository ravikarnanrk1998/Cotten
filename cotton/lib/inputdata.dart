import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'commonstyle.dart';

class InputData extends StatefulWidget {
  const InputData({super.key});

  @override
  State<InputData> createState() => _InputDataState();
}

class _InputDataState extends State<InputData> {
  final TextEditingController kgController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  String selectedCotton = "Normal Cotton";
  String selectedQuality = "Medium";

  double totalAmount = 0;
  double totalKg = 0;
  List<Map<String, dynamic>> todayList = [];

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

      setState(() {
        todayList = loadedList.reversed.toList();
      });
    }
  }

  // 🔹 SAVE DATA TO LOCAL STORAGE
  Future<void> saveLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('today_load_list', json.encode(todayList));
  }

  void calculateAmount() {
    final price = double.tryParse(priceController.text) ?? 0;

    setState(() {
      totalAmount = totalKg * price;
    });
  }

  void addKgToTotal() {
    final entryKg = double.tryParse(kgController.text) ?? 0;
    if (entryKg > 0) {
      setState(() {
        totalKg += entryKg;
        kgController.clear();
      });
      calculateAmount();
    }
  }

  // 🔹 ADD ENTRY → SAVE → SHOW BELOW LIST
  void addEntry() {
    if (totalKg == 0 || priceController.text.isEmpty) return;

    final entry = {
      "cotton": selectedCotton,
      "quality": selectedQuality,
      "kg": totalKg,
      "price": priceController.text,
      "amount": totalAmount,
      "time": DateFormat('dd MMM, hh:mm a').format(DateTime.now()),
    };

    setState(() {
      todayList.insert(0, entry);
      kgController.clear();
      priceController.clear();
      totalAmount = 0;
      totalKg = 0;
    });

    saveLocalData();
    updateCurrentStatus(entry);
  }

  Future<void> updateCurrentStatus(Map<String, dynamic> entry) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('current_status_data');
    Map<String, dynamic> status = data != null ? json.decode(data) : {};

    double kg = (entry["kg"] ?? 0).toDouble();
    double amount = (entry["amount"] ?? 0).toDouble();
    String cotton = entry["cotton"];
    String quality = entry["quality"];

    status["totalAmount"] = (status["totalAmount"] ?? 0) + amount;

    if (cotton.contains("Hybrid")) {
      status["hybridTotal"] = (status["hybridTotal"] ?? 0) + kg;
      if (quality == "High")
        status["hybridHigh"] = (status["hybridHigh"] ?? 0) + kg;
      if (quality == "Medium")
        status["hybridMedium"] = (status["hybridMedium"] ?? 0) + kg;
      if (quality == "Low")
        status["hybridLow"] = (status["hybridLow"] ?? 0) + kg;
    } else if (cotton.contains("Normal")) {
      status["normalTotal"] = (status["normalTotal"] ?? 0) + kg;
      if (quality == "High")
        status["normalHigh"] = (status["normalHigh"] ?? 0) + kg;
      if (quality == "Medium")
        status["normalMedium"] = (status["normalMedium"] ?? 0) + kg;
      if (quality == "Low")
        status["normalLow"] = (status["normalLow"] ?? 0) + kg;
    }

    await prefs.setString('current_status_data', json.encode(status));
  }

  // 🔹 DELETE ENTRY
  void deleteEntry(int index) {
    setState(() {
      todayList.removeAt(index);
    });
    saveLocalData();
  }

  double totalTodayAmount() {
    double total = 0;

    for (var item in todayList) {
      total += double.tryParse(item['amount'].toString()) ?? 0;
    }
    return total;
  }

  double totalHybridCottonQuality() {
    double total = 0;

    for (var item in todayList) {
      if (item['cotton'].contains('Hybrid')) {
        total += double.tryParse(item['kg'].toString()) ?? 0;
      }
    }
    return total;
  }

  double totalKgByQuality(String quality) {
    double total = 0;

    for (var item in todayList) {
      if (item['quality'] == quality && item['cotton'] == 'Normal Cotton') {
        total += double.tryParse(item['kg'].toString()) ?? 0;
      }
    }
    return total;
  }

  String _todayDate() {
    final now = DateTime.now();
    return "${now.day.toString().padLeft(2, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text("Entry Data", style: appbarstyle),
        backgroundColor: primerycolor,
        iconTheme: IconThemeData(color: whitecolor),
        actions: [
          Container(
            decoration: BoxDecoration(
              border: Border.all(width: 2, color: whitecolor),
              borderRadius: BorderRadiusDirectional.circular(5),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                top: 2.0,
                bottom: 2.0,
                left: 15,
                right: 15,
              ),
              child: Text(todayList.length.toString(), style: appbarstyle),
            ),
          ),
          SizedBox(width: 30),
        ],
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        color: graycolorshade,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CustomScrollView(
            slivers: [
              /// ---------------- FORM CARD ----------------
              SliverToBoxAdapter(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: whitecolor,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedCotton,
                          isDense: true,
                          decoration: InputDecoration(
                            labelText: "Cotton Type",
                            labelStyle: inputtextstyle,
                            suffixStyle: inputtextstyle,
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 18, // ⭐ reduce height here
                            ),
                          ),
                          items: ["Hybrid Cotton", "Normal Cotton"]
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => selectedCotton = v!),
                        ),
                        const SizedBox(height: 12),

                        DropdownButtonFormField<String>(
                          value: selectedQuality,
                          isDense: true,
                          decoration: InputDecoration(
                            labelText: "Quality Type",
                            labelStyle: inputtextstyle,
                            suffixStyle: inputtextstyle,
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 18,
                            ),
                          ),
                          items: ["High", "Medium", "Low"]
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => selectedQuality = v!),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: kgController,
                                style: inputtextstyle,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: "Enter Kg",
                                  labelStyle: inputtextstyle,
                                  suffixStyle: inputtextstyle,
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(width: 2),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 18,
                                  ),
                                ),
                                onSubmitted: (_) => addKgToTotal(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 80,
                              height: 45,
                              child: GestureDetector(
                                onTap: addKgToTotal,
                                child: commonaddbutton(context, "Add"),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            sectiontextTitle(context, "Total Kg"),
                            Text(
                              "${totalKg.toStringAsFixed(2)} Kg",
                              style: TextStyle(
                                fontSize: 18,
                                color: bluecolor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: priceController,
                          style: inputtextstyle,

                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Enter Price",
                            border: OutlineInputBorder(),
                            labelStyle: inputtextstyle,
                            suffixStyle: inputtextstyle,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 18,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(width: 2),
                            ),
                          ),
                          onChanged: (_) => calculateAmount(),
                        ),
                        const SizedBox(height: 12),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            sectiontextTitle(context, "Total Amount"),
                            Text(
                              "₹ ${totalAmount.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 18,
                                color: primerycolor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        SizedBox(
                          width: 100,
                          height: 40,
                          child: GestureDetector(
                            onTap: addEntry,
                            child: commonbutton(context, "Save"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              /// ---------------- STICKY HEADER + LIST ----------------
              if (todayList.isNotEmpty)
                SliverStickyHeader(
                  header: Container(
                    color: graycolorshade,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            sectionTitle(context, "Today List"),
                            Text(
                              "₹ ${totalTodayAmount().toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primerycolor,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// ---- CYBRID COTTON TOTAL ----
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    /// LEFT: Hybrid Cotton Total
                                    Text(
                                      "Hybrid Cotton : ${totalHybridCottonQuality().toStringAsFixed(1)} Kg",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: bluecolor,
                                      ),
                                    ),

                                    /// RIGHT: Today Date
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: bluecolor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        _todayDate(),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: blackcolor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),
                                const Divider(height: 1),

                                const SizedBox(height: 8),

                                /// ---- QUALITY WISE TOTAL ----
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "High : ${totalKgByQuality('High')} Kg",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: primerycolor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      "Medium : ${totalKgByQuality('Medium')} Kg",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: primerycolorshade,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      "Low : ${totalKgByQuality('Low')} Kg",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: graydarkcolorshade,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = todayList[index];

                      return Card(
                        child: ListTile(
                          title: Text(
                            "${item['cotton']} - ${item['quality']}",
                            style: TextStyle(
                              fontSize: 15,
                              color: (item['cotton'] == "Hybrid Cotton")
                                  ? bluecolor
                                  : (item['quality'] == "High")
                                  ? primerycolor
                                  : (item['quality'] == "Medium")
                                  ? primerycolorshade
                                  : graydarkcolorshade,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              "${item['kg']} Kg × ₹${item['price']} = ₹${item['amount']}\n${item['time']}",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.print, color: primerycolor),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => deleteEntry(index),
                              ),
                            ],
                          ),
                        ),
                      );
                    }, childCount: todayList.length),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 60)),
            ],
          ),
        ),
      ),
    );
  }
}
