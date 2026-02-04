import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'commonstyle.dart';

class CurrectData extends StatefulWidget {
  const CurrectData({super.key});

  @override
  State<CurrectData> createState() => _CurrectDataState();
}

class _CurrectDataState extends State<CurrectData> {
  List<Map<String, dynamic>> todayList = [];

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
      lastDate: now, // ❌ future dates disabled
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text("Current Data", style: appbarstyle),
        backgroundColor: primerycolor,
        iconTheme: IconThemeData(color: whitecolor),
        actions: [
          IconButton(onPressed:() => pickDate(context), icon: Icon(Icons.date_range,size: 35,)),
        SizedBox(width: 25),
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
                            sectionTitle(context, "Current Total List"),
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
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = todayList[index];

                      return Card(
                        child: ListTile(
                          title: Text(
                            "${item['cotton']} - ${item['quality']}",
                            style: TextStyle(
                              fontSize: 15,
                              color: (item['cotton'] == "Cybrid Cotton")
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
