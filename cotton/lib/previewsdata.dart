import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'commonstyle.dart';
import 'firebase_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:esc_pos_utils_updated/esc_pos_utils_updated.dart';
import 'package:permission_handler/permission_handler.dart';

class PreviewsData extends StatefulWidget {
  const PreviewsData({super.key});

  @override
  State<PreviewsData> createState() => _PreviewsDataState();
}

class _PreviewsDataState extends State<PreviewsData> {
  DateTime? selectedDate;
  final Map<String, TextEditingController> paymentControllers = {};
  List<BluetoothDevice> _printers = [];
  BluetoothDevice? _selectedPrinter;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _requestPermission().then((_) => _scanPrinters());
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  Future<void> _scanPrinters() async {
    if (_isScanning) return;
    if (mounted) {
      setState(() {
        _isScanning = true;
        _printers = [];
      });
    }

    try {
      final bonded = await FlutterBluePlus.bondedDevices;
      if (mounted) {
        setState(() {
          _printers = List.from(bonded);
        });
      }

      final sub = FlutterBluePlus.scanResults.listen((results) {
        if (mounted) {
          setState(() {
            final existing = _printers.map((d) => d.remoteId).toSet();
            for (final r in results) {
              if (!existing.contains(r.device.remoteId)) {
                _printers.add(r.device);
                existing.add(r.device.remoteId);
              }
            }
          });
        }
      });

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
      await sub.cancel();
    } catch (e) {
      debugPrint("Scan error: $e");
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> pickDate(BuildContext context) async {
    DateTime now = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
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
      double currentPaid = (item['paid'] ?? 0).toDouble();
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

  void deleteSummary(String id) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text("Previews Load Sent", style: appbarstyle),
        backgroundColor: primerycolor,
        iconTheme: IconThemeData(color: whitecolor),
        actions: [
          if (selectedDate != null)
            IconButton(
              onPressed: () => setState(() => selectedDate = null),
              icon: const Icon(Icons.clear_all, size: 30),
            ),
          IconButton(
            onPressed: () => pickDate(context),
            icon: const Icon(Icons.date_range, size: 35),
          ),
          const SizedBox(width: 25),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: FirebaseService.getSummaries(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allSummaries = snapshot.data ?? [];
              List<Map<String, dynamic>> displayList = allSummaries;

              if (selectedDate != null) {
                String dateStr = DateFormat(
                  'dd MMM, yyyy',
                ).format(selectedDate!);
                displayList = allSummaries
                    .where((item) => item['date'] == dateStr)
                    .toList();
              }

              // Sort by timestamp if available, else by index
              displayList.sort(
                (a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0),
              );

              return Container(
                height: MediaQuery.of(context).size.height,
                color: graycolorshade,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: CustomScrollView(
                    slivers: [
                      if (displayList.isNotEmpty)
                        SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final item = displayList[index];
                            final id = item['id'] as String;
                            return _summaryRow(id, item);
                          }, childCount: displayList.length),
                        )
                      else
                        SliverFillRemaining(
                          child: Center(
                            child: Text(
                              "No summaries found for this date.",
                              style: TextStyle(
                                color: graydarkcolorshade,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
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

  Widget _summaryRow(String id, Map<String, dynamic> item) {
    if (!paymentControllers.containsKey(id)) {
      paymentControllers[id] = TextEditingController();
    }
    double totalAmount = (item['totalAmount'] ?? 0).toDouble();
    double paidAmount = (item['paid'] ?? 0).toDouble();
    double balanceAmount = totalAmount - paidAmount;

    // Helper to print category breakdown if it exists
    void addCategoryToReceipt(
      Generator generator,
      List<int> bytes,
      String typeLabel,
      String qualityLabel,
      Map<String, dynamic> data,
    ) {
      double gKg = double.tryParse(data['gross_kg']?.toString() ?? '0') ?? 0;
      if (gKg <= 0) return;

      double ded = double.tryParse(data['deduction']?.toString() ?? '0') ?? 0;
      double net =
          double.tryParse(data['kg']?.toString() ?? '0') ?? (gKg - ded);
      double price = double.tryParse(data['price']?.toString() ?? '0') ?? 0;
      double total = double.tryParse(data['total']?.toString() ?? '0') ?? 0;

      // Print Summary Row
      bytes.addAll(
        generator.row([
          PosColumn(
            text: '$typeLabel\n$qualityLabel',
            width: 4,
            styles: const PosStyles(bold: true),
          ),
          PosColumn(
            text:
                '${gKg.toStringAsFixed(1)}-${ded.toStringAsFixed(1)}\nNet:${net.toStringAsFixed(1)}',
            width: 4,
            styles: const PosStyles(align: PosAlign.center),
          ),
          PosColumn(
            text: price.toStringAsFixed(0),
            width: 2,
            styles: const PosStyles(align: PosAlign.center),
          ),
          PosColumn(
            text: total.toStringAsFixed(0),
            width: 2,
            styles: const PosStyles(align: PosAlign.right, bold: true),
          ),
        ]),
      );
      bytes.addAll(generator.text('- - - - - - - - - - - - - - - -'));
    }

    void addDetailedBagsToReceipt(
      Generator generator,
      List<int> bytes,
      String title,
      Map<String, dynamic> data,
    ) {
      if (data['kg_list'] == null || (data['kg_list'] as List).isEmpty) return;
      List weights = data['kg_list'] as List;

      bytes.addAll(
        generator.text(
          title,
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            reverse: true,
          ),
        ),
      );
      bytes.addAll(
        generator.row([
          PosColumn(
            text: 'Bags',
            width: 6,
            styles: const PosStyles(bold: true, align: PosAlign.center),
          ),
          PosColumn(
            text: 'Kg',
            width: 6,
            styles: const PosStyles(bold: true, align: PosAlign.center),
          ),
        ]),
      );

      for (int i = 0; i < weights.length; i++) {
        bytes.addAll(
          generator.row([
            PosColumn(
              text: '${i + 1}',
              width: 6,
              styles: const PosStyles(align: PosAlign.center),
            ),
            PosColumn(
              text: '${weights[i]}',
              width: 6,
              styles: const PosStyles(align: PosAlign.center),
            ),
          ]),
        );
      }
      bytes.addAll(generator.text('--------------------------------'));
    }

    Future<void> _printReceipt(
      BluetoothDevice printer,
      Map<String, dynamic> item,
    ) async {
      try {
        await printer.connect(timeout: const Duration(seconds: 10));
        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm58, profile);
        List<int> bytes = [];

        bytes.addAll(generator.setGlobalCodeTable('CP1252'));
        bytes.addAll(
          generator.text(
            'Santhi Cotton Shop',
            styles: const PosStyles(
              bold: true,
              height: PosTextSize.size1,
              width: PosTextSize.size1,
              align: PosAlign.center,
            ),
          ),
        );
        bytes.addAll(
          generator.text(
            'Mobile No: 9578956063',
            styles: const PosStyles(
              align: PosAlign.center,
              height: PosTextSize.size2,
              width: PosTextSize.size2,
            ),
          ),
        );
        bytes.addAll(generator.text('--------------------------------'));

        bytes.addAll(generator.text('Party: ${item['name'] ?? 'Unknown'}'));
        bytes.addAll(generator.text('Date: ${item['date'] ?? ''}'));
        bytes.addAll(generator.text('--------------------------------'));

        bytes.addAll(
          generator.row([
            PosColumn(
              text: 'Qual',
              width: 4,
              styles: const PosStyles(bold: true),
            ),
            PosColumn(
              text: 'Grs-Ded/Net',
              width: 4,
              styles: const PosStyles(bold: true, align: PosAlign.center),
            ),
            PosColumn(
              text: 'Pric',
              width: 2,
              styles: const PosStyles(bold: true, align: PosAlign.center),
            ),
            PosColumn(
              text: 'Total',
              width: 2,
              styles: const PosStyles(bold: true, align: PosAlign.right),
            ),
          ]),
        );
        bytes.addAll(generator.text('--------------------------------'));

        final Map<String, dynamic> categories = item['categories'] != null
            ? Map<String, dynamic>.from(item['categories'])
            : {};

        if (categories.containsKey('high')) {
          addCategoryToReceipt(
            generator,
            bytes,
            'Normal',
            'High',
            Map<String, dynamic>.from(categories['high']),
          );
        }
        if (categories.containsKey('hybrid')) {
          addCategoryToReceipt(
            generator,
            bytes,
            'Hybrid',
            'Cotton',
            Map<String, dynamic>.from(categories['hybrid']),
          );
        }
        if (categories.containsKey('low')) {
          addCategoryToReceipt(
            generator,
            bytes,
            'Normal',
            'Low',
            Map<String, dynamic>.from(categories['low']),
          );
        }
        if (categories.containsKey('medium')) {
          addCategoryToReceipt(
            generator,
            bytes,
            'Normal',
            'Medium',
            Map<String, dynamic>.from(categories['medium']),
          );
        }

        bytes.addAll(generator.feed(1));
        bytes.addAll(
          generator.text(
            'DETAILED BAG WEIGHTS',
            styles: const PosStyles(bold: true, align: PosAlign.center),
          ),
        );
        bytes.addAll(generator.text('================================'));

        if (categories.containsKey('hybrid')) {
          addDetailedBagsToReceipt(
            generator,
            bytes,
            'HYBRID COTTON',
            Map<String, dynamic>.from(categories['hybrid']),
          );
        }
        if (categories.containsKey('high')) {
          addDetailedBagsToReceipt(
            generator,
            bytes,
            'NORMAL (HIGH)',
            Map<String, dynamic>.from(categories['high']),
          );
        }
        if (categories.containsKey('medium')) {
          addDetailedBagsToReceipt(
            generator,
            bytes,
            'NORMAL (MEDIUM)',
            Map<String, dynamic>.from(categories['medium']),
          );
        }
        if (categories.containsKey('low')) {
          addDetailedBagsToReceipt(
            generator,
            bytes,
            'NORMAL (LOW)',
            Map<String, dynamic>.from(categories['low']),
          );
        }

        bytes.addAll(
          generator.text(
            'GRAND TOTAL: Rs. ${totalAmount.toStringAsFixed(2)}',
            styles: const PosStyles(
              bold: true,
              align: PosAlign.right,
              height: PosTextSize.size2,
              width: PosTextSize.size2,
            ),
          ),
        );
        bytes.addAll(
          generator.text(
            'PAID: Rs. ${paidAmount.toStringAsFixed(2)}',
            styles: const PosStyles(align: PosAlign.right),
          ),
        );
        bytes.addAll(
          generator.text(
            'BALANCE: Rs. ${balanceAmount.toStringAsFixed(2)}',
            styles: const PosStyles(
              bold: true,
              align: PosAlign.right,
              height: PosTextSize.size2,
              width: PosTextSize.size2,
            ),
          ),
        );

        bytes.addAll(generator.text('--------------------------------'));
        bytes.addAll(
          generator.text(
            'Thank you for coming!',
            styles: const PosStyles(align: PosAlign.center),
          ),
        );
        bytes.addAll(generator.feed(3));
        bytes.addAll(generator.cut());

        // ---------------- BLE SEND LOGIC ----------------
        await printer.requestMtu(512);
        final services = await printer.discoverServices();
        BluetoothCharacteristic? printChar;

        outer:
        for (final service in services) {
          for (final char in service.characteristics) {
            if (char.properties.write || char.properties.writeWithoutResponse) {
              printChar = char;
              break outer;
            }
          }
        }

        if (printChar == null) {
          throw Exception("No writable characteristic found.");
        }

        const chunkSize = 120;
        for (int i = 0; i < bytes.length; i += chunkSize) {
          final end = (i + chunkSize < bytes.length)
              ? i + chunkSize
              : bytes.length;
          final bool useWithoutResponse = !printChar.properties.write;

          await printChar.write(
            bytes.sublist(i, end),
            withoutResponse: useWithoutResponse,
          );
          await Future.delayed(const Duration(milliseconds: 50));
        }

        await Future.delayed(const Duration(milliseconds: 500));
        await printer.disconnect();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Printed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Print failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    void _showPrintDialog(Map<String, dynamic> item) {
      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Select Bluetooth Printer"),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isScanning) const LinearProgressIndicator(),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        setDialogState(() => _isScanning = true);
                        _scanPrinters().then(
                          (_) => setDialogState(() => _isScanning = false),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text("Scan for Printers"),
                    ),
                    const Divider(),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _printers.length,
                        itemBuilder: (context, index) {
                          final printer = _printers[index];
                          return ListTile(
                            title: Text(printer.platformName),
                            subtitle: Text(printer.remoteId.toString()),
                            trailing:
                                _selectedPrinter?.remoteId == printer.remoteId
                                ? const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : null,
                            onTap: () {
                              setDialogState(() => _selectedPrinter = printer);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: _selectedPrinter == null
                      ? null
                      : () {
                          _printReceipt(_selectedPrinter!, item);
                          Navigator.pop(context);
                        },
                  child: const Text(
                    "Print",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    void showFullHistoryDialog() {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          insetPadding: const EdgeInsets.all(10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${item['name']} History",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item['categories']?['hybrid']?['kg_list'] != null &&
                      (item['categories']['hybrid']['kg_list'] as List)
                          .isNotEmpty)
                    _verticalSummaryTable(
                      "Hybrid",
                      item['categories']['hybrid']['kg_list'],
                      bluecolor,
                    ),
                  if (item['categories']?['low']?['kg_list'] != null &&
                      (item['categories']['low']['kg_list'] as List).isNotEmpty)
                    _verticalSummaryTable(
                      "Low",
                      item['categories']['low']['kg_list'],
                      graydarkcolorshade,
                    ),
                  if (item['categories']?['medium']?['kg_list'] != null &&
                      (item['categories']['medium']['kg_list'] as List)
                          .isNotEmpty)
                    _verticalSummaryTable(
                      "Medium",
                      item['categories']['medium']['kg_list'],
                      Colors.orange.shade800,
                    ),
                  if (item['categories']?['high']?['kg_list'] != null &&
                      (item['categories']['high']['kg_list'] as List)
                          .isNotEmpty)
                    _verticalSummaryTable(
                      "High",
                      item['categories']['high']['kg_list'],
                      primerycolor,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
              Row(
                children: [
                  Text(
                    item['name'] ?? "Unknown",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: showFullHistoryDialog,
                    child: Icon(Icons.visibility, color: bluecolor, size: 25),
                  ),
                  const SizedBox(width: 15),
                  GestureDetector(
                    onTap: () => _showPrintDialog(item),
                    child: const Icon(
                      Icons.print,
                      color: Colors.green,
                      size: 25,
                    ),
                  ),
                ],
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
                  icon: const Icon(Icons.delete, color: Colors.red),
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
          "₹ ${NumberFormat('#,##,###').format(amount)}",
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: color,
            fontSize: isBold ? 18 : 15,
          ),
        ),
      ],
    );
  }

  Widget _verticalSummaryTable(
    String title,
    List<dynamic> weights,
    Color color,
  ) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: whitecolor,
        border: Border.all(color: graycolorshade),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
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
                Expanded(
                  child: Center(
                    child: Text(
                      "Bags",
                      style: TextStyle(
                        color: blackcolor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      "Kg",
                      style: TextStyle(
                        color: blackcolor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(weights.length, (index) {
            return Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Colors.black12)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        "${index + 1}",
                        style: TextStyle(fontSize: 12, color: blackcolor),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "${weights[index]}",
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
