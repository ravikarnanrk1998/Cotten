import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'commonstyle.dart';
import 'firebase_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:esc_pos_utils_updated/esc_pos_utils_updated.dart';
import 'package:permission_handler/permission_handler.dart';

class CurrectData extends StatefulWidget {
  const CurrectData({super.key});

  @override
  State<CurrectData> createState() => _CurrectDataState();
}

class _CurrectDataState extends State<CurrectData> {
  DateTime? selectedDate;
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
    setState(() {
      _isScanning = true;
      _printers = [];
    });

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

  Future<void> _printReceipt(
    BluetoothDevice printer,
    Map<String, dynamic> item,
  ) async {
    try {
      await printer.connect(timeout: const Duration(seconds: 10));

      final profile = await CapabilityProfile.load();
      final generator = Generator(PaperSize.mm58, profile);
      List<int> bytes = [];

      bytes += generator.setGlobalCodeTable('CP1252');
      bytes += generator.text(
        'Santhi Cotton Shop',
        styles: const PosStyles(
          bold: true,
          height: PosTextSize.size1,
          width: PosTextSize.size1,
          align: PosAlign.center,
        ),
      );
      bytes += generator.text(
        'Mobile No: 9578956063',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.text('--------------------------------');

      bytes += generator.text('Date: ${item['time'] ?? ''}');
      bytes += generator.text('Type: ${item['cotton']}');
      bytes += generator.text('Qual: ${item['quality']}');
      if (item['kg_list'] != null && (item['kg_list'] as List).isNotEmpty) {
        bytes += generator.text(
          'Wts: ${(item['kg_list'] as List).join("+")} Kg',
        );
      }
      bytes += generator.text('--------------------------------');

      final kg = double.tryParse(item['kg'].toString()) ?? 0;
      final price = double.tryParse(item['price'].toString()) ?? 0;
      final amount = double.tryParse(item['amount'].toString()) ?? 0;

      bytes += generator.row([
        PosColumn(
          text: 'WEIGHT',
          width: 4,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(
          text: 'RATE',
          width: 4,
          styles: const PosStyles(bold: true, align: PosAlign.center),
        ),
        PosColumn(
          text: 'TOTAL',
          width: 4,
          styles: const PosStyles(bold: true, align: PosAlign.right),
        ),
      ]);

      bytes += generator.row([
        PosColumn(text: '${kg.toStringAsFixed(2)} Kg', width: 4),
        PosColumn(
          text: '${price.toStringAsFixed(0)}',
          width: 4,
          styles: const PosStyles(align: PosAlign.center),
        ),
        PosColumn(
          text: '${amount.toStringAsFixed(2)}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);

      bytes += generator.text('--------------------------------');
      bytes += generator.text(
        'TOTAL: Rs. ${amount.toStringAsFixed(2)}',
        styles: const PosStyles(bold: true, align: PosAlign.right),
      );
      bytes += generator.text('--------------------------------');

      final qrData =
          'Shop:Santhi Cotton Shop\nDate:${item['time']}\nTotal:${amount.toStringAsFixed(2)}';
      bytes += generator.qrcode(qrData, align: PosAlign.center);
      bytes += generator.text(
        'Thank you for coming!',
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.feed(2);
      bytes += generator.cut();

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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Center(
              child: Text(
                "Print Receipt",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.grey.shade100,
                  ),
                  child: const Icon(Icons.print, size: 60, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isScanning
                              ? "Scanning..."
                              : _printers.isEmpty
                              ? "No printers"
                              : "${_printers.length} found",
                          style: TextStyle(
                            fontSize: 12,
                            color: _isScanning ? Colors.blue : Colors.green,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _isScanning
                              ? null
                              : () async {
                                  await _scanPrinters();
                                  setDialogState(() {});
                                },
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text("Rescan"),
                        ),
                      ],
                    ),
                    if (_printers.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<BluetoothDevice>(
                            isExpanded: true,
                            hint: const Text("Select Printer"),
                            value: _selectedPrinter,
                            items: _printers.map((p) {
                              return DropdownMenuItem(
                                value: p,
                                child: Text(
                                  p.platformName.isNotEmpty
                                      ? p.platformName
                                      : "Unknown (${p.remoteId})",
                                ),
                              );
                            }).toList(),
                            onChanged: (p) {
                              setDialogState(() {
                                _selectedPrinter = p;
                                _selectedPrinter = p;
                              });
                              setState(() {
                                _selectedPrinter = p;
                              });
                            },
                          ),
                        ),
                      ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [const Text("Weight:"), Text("${item['kg']} Kg")],
                ),
                if (item['kg_list'] != null &&
                    (item['kg_list'] as List).isNotEmpty)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "(${(item['kg_list'] as List).join("+")})",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Total:"),
                    Text(
                      "₹${item['amount']}",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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

  double totalAmount(List<Map<String, dynamic>> list) {
    double total = 0;
    for (var item in list) {
      total += double.tryParse(item['amount'].toString()) ?? 0;
    }
    return total;
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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirebaseService.getLoads(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allLoads = snapshot.data ?? [];

          List<Map<String, dynamic>> displayList = allLoads;

          if (selectedDate != null) {
            final start = DateTime(
              selectedDate!.year,
              selectedDate!.month,
              selectedDate!.day,
            ).millisecondsSinceEpoch;
            final end = start + 86400000;
            displayList = allLoads.where((item) {
              final ts = item['timestamp'] as int?;
              if (ts == null) return false;
              return ts >= start && ts < end;
            }).toList();
          }

          // Sort by timestamp descending
          displayList.sort(
            (a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0),
          );

          return Container(
            height: MediaQuery.of(context).size.height,
            color: graycolorshade,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  if (displayList.isNotEmpty)
                    SliverStickyHeader(
                      header: Container(
                        color: graycolorshade,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            sectionTitle(
                              context,
                              selectedDate == null
                                  ? "Previews Total List"
                                  : "List for ${DateFormat('dd MMM yyyy').format(selectedDate!)}",
                            ),
                            Text(
                              "₹ ${totalAmount(displayList).toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primerycolor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = displayList[index];
                          return Card(
                            child: ListTile(
                              title: Text(
                                "${item['cotton']} - ${item['quality']}",
                                style: TextStyle(
                                  fontSize: 15,
                                  color:
                                      (item['cotton'].toString().contains(
                                        "Hybrid",
                                      ))
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${item['kg']} Kg × ₹${item['price']} = ₹${item['amount']}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (item['kg_list'] != null &&
                                        (item['kg_list'] as List).isNotEmpty)
                                      Text(
                                        "Wts: ${(item['kg_list'] as List).join("+")}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: graydarkcolorshade,
                                        ),
                                      ),
                                    Text(
                                      "${item['time'] ?? ''}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
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
                                    onPressed: () => _showPrintDialog(item),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }, childCount: displayList.length),
                      ),
                    )
                  else
                    const SliverFillRemaining(
                      child: Center(
                        child: Text("No data found for this period."),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 60)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
