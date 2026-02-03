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
      setState(() {
        todayList = List<Map<String, dynamic>>.from(json.decode(data));
      });
    }
  }

  // 🔹 SAVE DATA TO LOCAL STORAGE
  Future<void> saveLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('today_load_list', json.encode(todayList));
  }

  void calculateAmount() {
    final kg = double.tryParse(kgController.text) ?? 0;
    final price = double.tryParse(priceController.text) ?? 0;

    setState(() {
      totalAmount = kg * price;
    });
  }

  // 🔹 ADD ENTRY → SAVE → SHOW BELOW LIST
  void addEntry() {
    if (kgController.text.isEmpty || priceController.text.isEmpty) return;

    final entry = {
      "cotton": selectedCotton,
      "quality": selectedQuality,
      "kg": kgController.text,
      "price": priceController.text,
      "amount": totalAmount,
      "time": DateFormat('dd MMM, hh:mm a').format(DateTime.now()),
    };

    setState(() {
      todayList.insert(0, entry);
      kgController.clear();
      priceController.clear();
      totalAmount = 0;
    });

    saveLocalData();
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

  double totalCybridCottonQuality() {
    double total = 0;

    for (var item in todayList) {
      if (item['cotton'] == 'Cybrid Cotton') {
        total += double.tryParse(item['kg'].toString()) ?? 0;
      }
    }
    return total;
  }

  double totalKgByQuality(String quality) {
    double total = 0;

    for (var item in todayList) {
      if (item['quality'] == quality) {
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
          Container(decoration: BoxDecoration(
            border: Border.all(width: 2,color: whitecolor),
            borderRadius: BorderRadiusDirectional.circular(5)
          ), child: Padding(
            padding: const EdgeInsets.only(top: 2.0,bottom: 2.0,left: 15,right: 15),
            child: Text(todayList.length.toString(),style: appbarstyle,),
          )),
          SizedBox(width: 30,)
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
                          decoration: const InputDecoration(
                            labelText: "Cotton Type",
                            border: OutlineInputBorder(),
                          ),
                          items: ["Cybrid Cotton", "Normal Cotton"]
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
                          decoration: const InputDecoration(
                            labelText: "Quality Type",
                            border: OutlineInputBorder(),
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

                        TextField(
                          controller: kgController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Enter Kg",
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => calculateAmount(),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Enter Price",
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => calculateAmount(),
                        ),
                        const SizedBox(height: 16),

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
                        const SizedBox(height: 16),

                        SizedBox(
                          width: 125,
                          height: 62,
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
                                    /// LEFT: Cybrid Cotton Total
                                    Text(
                                      "Cybrid Cotton : ${totalCybridCottonQuality().toStringAsFixed(1)} Kg",
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
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
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
