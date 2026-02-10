import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'commonstyle.dart';

class PreviewsData extends StatefulWidget {
  const PreviewsData({super.key});

  @override
  State<PreviewsData> createState() => _PreviewsDataState();
}

class _PreviewsDataState extends State<PreviewsData> {
  List<Map<String, dynamic>> todayList = [];
  final List<Map<String, dynamic>> dataList = [
    {
      "name": "Cotton A",
      "date": "05 Feb 2026",
      "inKg": 120,
      "outKg": 100,
      "spend": 50000,
      "return": 55000,
    },
    {
      "name": "Cotton B",
      "date": "04 Feb 2026",
      "inKg": 90,
      "outKg": 95,
      "spend": 42000,
      "return": 40000,
    },
  ];
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

  void filterDataByDate(DateTime selectedDate) {
    final selectedDateStr = formatDate(selectedDate);

    final filteredList = loadedList.where((item) {
      final timeStr = item['time']; // "04 Feb, 07:40 PM"
      final itemDate = timeStr.split(',')[0]; // "04 Feb"
      return itemDate == selectedDateStr;
    }).toList();

    setState(() {
      todayList = filteredList.reversed.toList();
    });
  }

  List<Map<String, dynamic>> loadedList = [];

  Future<void> loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('today_load_list');

    if (data != null) {
      loadedList = List<Map<String, dynamic>>.from(json.decode(data));

      setState(() {
        todayList = loadedList.reversed.toList(); // default show all
      });
    }
  }

  double totalTodayAmount() {
    double total = 0;

    for (var item in todayList) {
      total += double.tryParse(item['amount'].toString()) ?? 0;
    }
    return total;
  }

  bool sync = false;

  void syncfunction() {
    setState(() {
      if (sync == false) {
        sync = true;
      } else {
        sync = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text("Previews Data", style: appbarstyle),
        backgroundColor: primerycolor,
        iconTheme: IconThemeData(color: whitecolor),
        actions: [
          IconButton(
            onPressed: () => syncfunction(),
            icon: Icon(Icons.sync, size: 35),
          ),
          IconButton(
            onPressed: () => pickDate(context),
            icon: Icon(Icons.date_range, size: 35),
          ),
          SizedBox(width: 25),
        ],
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        color: graycolorshade,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: sync
              ? CustomScrollView(
                  slivers: [
                    SliverStickyHeader(
                      header: sectionTitle(context, "Out Load List"),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return dataCard(dataList[index]);
                        }, childCount: dataList.length),
                      ),
                    ),
                  ],
                )
              : CustomScrollView(
                  slivers: [
                    /// ---------------- FORM CARD ----------------
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  sectionTitle(context, "Previews Total List"),
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
                            ],
                          ),
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
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
                                      icon: Icon(
                                        Icons.print,
                                        color: primerycolor,
                                      ),
                                      onPressed: () {},
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

Widget dataCard(Map<String, dynamic> item) {
  final pl = profitLoss(item["spend"], item["return"]);

  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// NAME + DATE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(item["name"], style: inputtextstyle),
                  SizedBox(width: 5),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.print, color: primerycolor),
                  ),
                ],
              ),
              Text(item["date"], style: inputtextstyle2),
            ],
          ),

          const SizedBox(height: 12),

          /// KG DETAILS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoTile("In Kg", item["inKg"].toString()),
              _infoTile("Out Kg", item["outKg"].toString()),
            ],
          ),

          const SizedBox(height: 12),

          /// AMOUNT DETAILS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoTile("Spend", "₹${item["spend"]}"),
              _infoTile("Return", "₹${item["return"]}"),
            ],
          ),

          const Divider(height: 24),

          /// PROFIT / LOSS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Profit / Loss",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "₹$pl",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: pl >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _infoTile(String label, String value) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Colors.orange.shade600,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
    ],
  );
}

int profitLoss(int spend, int returned) {
  return returned - spend;
}
