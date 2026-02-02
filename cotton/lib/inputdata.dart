import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text("Entry Data", style: appbarstyle),
        backgroundColor: primerycolor,
        iconTheme: IconThemeData(
          color:whitecolor, 
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        color: graycolorshade,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
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
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
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
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => selectedQuality = v!),
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

              const SizedBox(height: 20),
              if (todayList.isNotEmpty) sectionTitle(context, "Today List"),

              const SizedBox(height: 8),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: todayList.length,
                itemBuilder: (_, index) {
                  final item = todayList[index];

                  return Card(
                    child: ListTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${item['cotton']} - ${item['quality']}",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                      subtitle: Text(
                        "${item['kg']} Kg × ₹${item['price']} = ₹${item['amount']} \n${item['time']}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
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
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteEntry(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
