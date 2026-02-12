import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'commonstyle.dart';
import 'loadsummary.dart';

class LoadSendData extends StatefulWidget {
  const LoadSendData({super.key});

  @override
  State<LoadSendData> createState() => _LoadSendDataState();
}

class _LoadSendDataState extends State<LoadSendData> {
  final TextEditingController kgController = TextEditingController();

  String selectedCotton = "Normal Cotton";
  String selectedQuality = "Medium";

  List<Map<String, dynamic>> todayList = [];

  @override
  void initState() {
    super.initState();
    loadLocalData();
  }

  // 🔹 LOAD DATA FROM LOCAL STORAGE
  Future<void> loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('load_sent_list');

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
    prefs.setString('load_sent_list', json.encode(todayList));
  }

  void addEntry() {
    final entryKg = double.tryParse(kgController.text) ?? 0;
    if (entryKg == 0) return;

    final entry = {
      "cotton": selectedCotton,
      "quality": selectedQuality,
      "kg": entryKg,
      "time": DateFormat('hh:mm a').format(DateTime.now()),
      "id": DateTime.now().millisecondsSinceEpoch, // Unique ID for deletion
    };

    setState(() {
      todayList.insert(0, entry);
      kgController.clear();
    });

    saveLocalData();
  }

  // 🔹 DELETE ENTRY
  void deleteEntry(int id) {
    setState(() {
      todayList.removeWhere((item) => item['id'] == id);
    });
    saveLocalData();
  }

  double totalAllAmount() {
    return 0; // No amount here
  }

  double totalHybridCottonQuality() {
    double total = 0;
    for (var item in todayList) {
      if (item['cotton'] == 'Hybrid Cotton') {
        total += double.tryParse(item['kg'].toString()) ?? 0;
      }
    }
    return total;
  }

  double totalKgByQuality(String quality) {
    double total = 0;
    for (var item in todayList) {
      if (item['cotton'] == 'Normal Cotton' && item['quality'] == quality) {
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

  Widget _tableCell(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(border: Border.all(color: graycolorshade)),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: graydarkcolorshade,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tableHeaderCell(
    String title, {
    double? width,
    bool isExpanded = false,
  }) {
    Widget cell = Center(
      child: Text(
        title,
        style: TextStyle(
          color: whitecolor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );

    return isExpanded
        ? Expanded(child: cell)
        : SizedBox(width: width, child: cell);
  }

  Widget _tableBodyCell(
    String value,
    Color color, {
    double? width,
    bool isBold = false,
    bool isExpanded = false,
  }) {
    Widget cell = Center(
      child: Text(
        value,
        style: TextStyle(
          color: color,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );

    return isExpanded
        ? Expanded(child: cell)
        : SizedBox(width: width, child: cell);
  }

  Widget _verticalEntriesTable(
    String title,
    List<Map<String, dynamic>> items,
    Color color,
  ) {
    return Container(
      width: 140, // Increased width for better fit
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: whitecolor,
        border: Border.all(color: graycolorshade),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            color: graycolorshade.withOpacity(0.3),
            child: Row(
              children: [
                _tableHeaderCell("S.N", width: 40),
                _tableHeaderCell("Kg", isExpanded: true),
              ],
            ),
          ),
          if (items.isEmpty)
            Container(
              height: 100,
              alignment: Alignment.center,
              child: Text("-", style: TextStyle(color: graydarkcolorshade)),
            )
          else
            ...List.generate(items.length, (index) {
              final item = items[index];
              final sno = index + 1;
              return Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.black12)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    _tableBodyCell(sno.toString(), blackcolor, width: 40),
                    _tableBodyCell(
                      item['kg'].toString(),
                      color,
                      isExpanded: true,
                      isBold: true,
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  final Color orangeColor = Colors.orange.shade800;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text("Load Send Data", style: appbarstyle),
        backgroundColor: primerycolor,
        iconTheme: IconThemeData(color: whitecolor),
        actions: [
          GestureDetector(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LoadSummaryPage(
                    hybridKg: totalHybridCottonQuality(),
                    lowKg: totalKgByQuality("Low"),
                    mediumKg: totalKgByQuality("Medium"),
                    highKg: totalKgByQuality("High"),
                  ),
                ),
              );

              if (result == true) {
                setState(() {
                  todayList.clear();
                  selectedCotton = "Normal Cotton";
                  selectedQuality = "Medium";
                  kgController.clear();
                });
                await saveLocalData();
              }
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(width: 2, color: whitecolor),
                color: redcolor,
                borderRadius: BorderRadiusDirectional.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 5,
                  bottom: 5,
                  left: 15,
                  right: 15,
                ),
                child: Text("Send", style: appbarstyle),
              ),
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
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 18,
                                  ),
                                ),
                                onSubmitted: (_) => addEntry(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 80,
                              height: 60,
                              child: GestureDetector(
                                onTap: addEntry,
                                child: commonaddbutton(context, "Add"),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Summary Table Header
                        sectiontextTitle(context, "Load Summary"),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: whitecolor,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              _tableCell(
                                "Hybrid",
                                totalHybridCottonQuality().toStringAsFixed(1),
                                bluecolor,
                              ),
                              _tableCell(
                                "High",
                                totalKgByQuality("High").toStringAsFixed(1),
                                primerycolor,
                              ),
                              _tableCell(
                                "Medium",
                                totalKgByQuality("Medium").toStringAsFixed(1),
                                primerycolorshade,
                              ),
                              _tableCell(
                                "Low",
                                totalKgByQuality("Low").toStringAsFixed(1),
                                graydarkcolorshade,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              /// ---------------- QUAD-TABLE HISTORY ----------------
              if (todayList.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            sectionTitle(context, "Load History"),
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
                        const SizedBox(height: 15),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (todayList.any(
                                (e) => e['cotton'] == "Hybrid Cotton",
                              ))
                                _verticalEntriesTable(
                                  "Hybrid",
                                  todayList
                                      .where(
                                        (e) => e['cotton'] == "Hybrid Cotton",
                                      )
                                      .toList()
                                      .reversed
                                      .toList(),
                                  bluecolor,
                                ),
                              if (todayList.any(
                                (e) =>
                                    e['cotton'] == "Normal Cotton" &&
                                    e['quality'] == "Low",
                              ))
                                _verticalEntriesTable(
                                  "Low",
                                  todayList
                                      .where(
                                        (e) =>
                                            e['cotton'] == "Normal Cotton" &&
                                            e['quality'] == "Low",
                                      )
                                      .toList()
                                      .reversed
                                      .toList(),
                                  graydarkcolorshade,
                                ),
                              if (todayList.any(
                                (e) =>
                                    e['cotton'] == "Normal Cotton" &&
                                    e['quality'] == "Medium",
                              ))
                                _verticalEntriesTable(
                                  "Medium",
                                  todayList
                                      .where(
                                        (e) =>
                                            e['cotton'] == "Normal Cotton" &&
                                            e['quality'] == "Medium",
                                      )
                                      .toList()
                                      .reversed
                                      .toList(),
                                  orangeColor,
                                ),
                              if (todayList.any(
                                (e) =>
                                    e['cotton'] == "Normal Cotton" &&
                                    e['quality'] == "High",
                              ))
                                _verticalEntriesTable(
                                  "High",
                                  todayList
                                      .where(
                                        (e) =>
                                            e['cotton'] == "Normal Cotton" &&
                                            e['quality'] == "High",
                                      )
                                      .toList()
                                      .reversed
                                      .toList(),
                                  primerycolor,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
