import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'commonstyle.dart';
import 'loadsummary.dart';
import 'firebase_service.dart';

class LoadSendData extends StatefulWidget {
  const LoadSendData({super.key});

  @override
  State<LoadSendData> createState() => _LoadSendDataState();
}

class _LoadSendDataState extends State<LoadSendData> {
  final TextEditingController kgController = TextEditingController();

  String selectedCotton = "Normal Cotton";
  String selectedQuality = "Medium";

  void addEntry() async {
    final entryKg = double.tryParse(kgController.text) ?? 0;
    if (entryKg == 0) return;

    try {
      final entry = {
        "cotton": selectedCotton,
        "quality": selectedQuality,
        "kg": entryKg,
        "time": DateFormat('hh:mm a').format(DateTime.now()),
      };

      await FirebaseService.addLoadSent(entry);
      kgController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void deleteEntry(String id) async {
    try {
      await FirebaseService.deleteLoadSent(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  double calculateHybridKg(List<Map<String, dynamic>> list) {
    return list
        .where((e) => e['cotton'] == 'Hybrid Cotton')
        .fold(0, (sum, e) => sum + (double.tryParse(e['kg'].toString()) ?? 0));
  }

  double calculateQualityKg(List<Map<String, dynamic>> list, String quality) {
    return list
        .where((e) => e['cotton'] == 'Normal Cotton' && e['quality'] == quality)
        .fold(0, (sum, e) => sum + (double.tryParse(e['kg'].toString()) ?? 0));
  }

  List<double> getQualityKgList(
    List<Map<String, dynamic>> list,
    String? cotton,
    String? quality,
  ) {
    return list
        .where(
          (e) =>
              (cotton == null || e['cotton'] == cotton) &&
              (quality == null || e['quality'] == quality),
        )
        .map((e) => double.tryParse(e['kg'].toString()) ?? 0.0)
        .where((kg) => kg > 0)
        .toList();
  }

  String _todayDate() {
    final now = DateTime.now();
    return "${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}";
  }

  Widget _bagCountChip(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(
            "$count Bags",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
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
      width: 140,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: whitecolor,
        border: Border.all(color: graycolorshade),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
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
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 16,
                        color: Colors.red,
                      ),
                      onPressed: () => deleteEntry(item['id']),
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
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirebaseService.getLoadSent(),
            builder: (context, snapshot) {
              final currentList = snapshot.data ?? [];
              return GestureDetector(
                onTap: () async {
                  if (currentList.isEmpty) return;
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoadSummaryPage(
                        hybridKg: calculateHybridKg(currentList),
                        lowKg: calculateQualityKg(currentList, "Low"),
                        mediumKg: calculateQualityKg(currentList, "Medium"),
                        highKg: calculateQualityKg(currentList, "High"),
                        hybridList: getQualityKgList(
                          currentList,
                          "Hybrid Cotton",
                          null,
                        ),
                        lowList: getQualityKgList(
                          currentList,
                          "Normal Cotton",
                          "Low",
                        ),
                        mediumList: getQualityKgList(
                          currentList,
                          "Normal Cotton",
                          "Medium",
                        ),
                        highList: getQualityKgList(
                          currentList,
                          "Normal Cotton",
                          "High",
                        ),
                      ),
                    ),
                  );

                  if (result == true) {
                    try {
                      await FirebaseService.clearLoadSent();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Error: $e"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(width: 2, color: whitecolor),
                    color: redcolor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  child: Center(child: Text("Send", style: appbarstyle)),
                ),
              );
            },
          ),
          const SizedBox(width: 30),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirebaseService.getLoadSent(),
            builder: (context, snapshot) {
              final todayList = snapshot.data ?? [];
              return Container(
                height: MediaQuery.of(context).size.height,
                color: graycolorshade,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CustomScrollView(
                    slivers: [
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
                                  decoration: const InputDecoration(
                                    labelText: "Cotton Type",
                                    border: OutlineInputBorder(),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(width: 2),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 18,
                                    ),
                                  ),
                                  items: ["Hybrid Cotton", "Normal Cotton"]
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => selectedCotton = v!),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: selectedQuality,
                                  isDense: true,
                                  decoration: const InputDecoration(
                                    labelText: "Quality Type",
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
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e),
                                        ),
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
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: "Enter Kg",
                                          border: OutlineInputBorder(),
                                          enabledBorder: OutlineInputBorder(
                                            borderSide: BorderSide(width: 2),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
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
                                      height: 50,
                                      child: GestureDetector(
                                        onTap: addEntry,
                                        child: commonaddbutton(context, "Add"),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                sectiontextTitle(context, "Load Summary"),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: whitecolor,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      _tableCell(
                                        "Hybrid",
                                        "${calculateHybridKg(todayList).toStringAsFixed(1)} (${getQualityKgList(todayList, "Hybrid Cotton", null).length})",
                                        bluecolor,
                                      ),
                                      _tableCell(
                                        "High",
                                        "${calculateQualityKg(todayList, "High").toStringAsFixed(1)} (${getQualityKgList(todayList, "Normal Cotton", "High").length})",
                                        primerycolor,
                                      ),
                                      _tableCell(
                                        "Medium",
                                        "${calculateQualityKg(todayList, "Medium").toStringAsFixed(1)} (${getQualityKgList(todayList, "Normal Cotton", "Medium").length})",
                                        primerycolorshade,
                                      ),
                                      _tableCell(
                                        "Low",
                                        "${calculateQualityKg(todayList, "Low").toStringAsFixed(1)} (${getQualityKgList(todayList, "Normal Cotton", "Low").length})",
                                        graydarkcolorshade,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Simplified count view
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _bagCountChip(
                                      "Hybrid",
                                      getQualityKgList(
                                        todayList,
                                        "Hybrid Cotton",
                                        null,
                                      ).length,
                                      bluecolor,
                                    ),
                                    _bagCountChip(
                                      "High",
                                      getQualityKgList(
                                        todayList,
                                        "Normal Cotton",
                                        "High",
                                      ).length,
                                      primerycolor,
                                    ),
                                    _bagCountChip(
                                      "Medium",
                                      getQualityKgList(
                                        todayList,
                                        "Normal Cotton",
                                        "Medium",
                                      ).length,
                                      primerycolorshade,
                                    ),
                                    _bagCountChip(
                                      "Low",
                                      getQualityKgList(
                                        todayList,
                                        "Normal Cotton",
                                        "Low",
                                      ).length,
                                      graydarkcolorshade,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),
                      if (todayList.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (todayList.any(
                                        (e) => e['cotton'] == "Hybrid Cotton",
                                      ))
                                        _verticalEntriesTable(
                                          "Hybrid",
                                          todayList
                                              .where(
                                                (e) =>
                                                    e['cotton'] ==
                                                    "Hybrid Cotton",
                                              )
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
                                                    e['cotton'] ==
                                                        "Normal Cotton" &&
                                                    e['quality'] == "Low",
                                              )
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
                                                    e['cotton'] ==
                                                        "Normal Cotton" &&
                                                    e['quality'] == "Medium",
                                              )
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
                                                    e['cotton'] ==
                                                        "Normal Cotton" &&
                                                    e['quality'] == "High",
                                              )
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
              );
            },
          ),
        ],
      ),
    );
  }
}
