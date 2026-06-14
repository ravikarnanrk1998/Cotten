import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'commonstyle.dart';
import 'firebase_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:esc_pos_utils_updated/esc_pos_utils_updated.dart';
import 'package:permission_handler/permission_handler.dart';

class InputData extends StatefulWidget {
  const InputData({super.key});

  @override
  State<InputData> createState() => _InputDataState();
}

class _InputDataState extends State<InputData> {
  final TextEditingController kgController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  List<BluetoothDevice> _printers = [];
  BluetoothDevice? _selectedPrinter;
  bool _isScanning = false;

  String selectedCotton = "Normal Cotton";
  String selectedQuality = "Medium";

  double totalAmount = 0;
  double totalKg = 0;

  late Stream<List<Map<String, dynamic>>> _loadsStream;
  List<double> kgList = [];

  @override
  void initState() {
    super.initState();
    _loadsStream = FirebaseService.getLoads();
    // Request permissions first, then start scanning
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
      // First, add already-bonded (paired) devices so they always appear
      final bonded = await FlutterBluePlus.bondedDevices;
      if (mounted) {
        setState(() {
          _printers = List.from(bonded);
        });
      }

      // Listen to scan results BEFORE starting scan
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

      // Start scan (non-awaited so listener catches events in real time)
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 6));
      await sub.cancel();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bluetooth scan failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      bytes += generator.text('--------------------------------');
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
        'No: 9578956063',
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
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
          width: 2,
          styles: const PosStyles(bold: true, align: PosAlign.center),
        ),
        PosColumn(
          text: 'TOTAL',
          width: 6,
          styles: const PosStyles(bold: true, align: PosAlign.right),
        ),
      ]);

      bytes += generator.row([
        PosColumn(
          text: '${kg.toStringAsFixed(2)} Kg',
          width: 4,
          styles: const PosStyles(
            align: PosAlign.left,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size1,
          ),
        ),
        PosColumn(
          text: '${price.toStringAsFixed(0)}',
          width: 2,
          styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size1,
          ),
        ),
        PosColumn(
          text: '${amount.toStringAsFixed(0)}',
          width: 6,
          styles: const PosStyles(
            align: PosAlign.right,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size1,
          ),
        ),
      ]);

      bytes += generator.text('--------------------------------');
      bytes += generator.row([
        PosColumn(
          text: 'TOTAL: Rs.',
          width: 8,
          styles: const PosStyles(
            bold: true,
            align: PosAlign.left,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
        ),

        PosColumn(
          text: '${amount.toStringAsFixed(0)}',
          width: 4,
          styles: const PosStyles(
            bold: true,
            align: PosAlign.right,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
        ),
      ]);
      bytes += generator.text('--------------------------------');
      final qrData =
          'Shop:Santhi Cotton Shop\nDate:${item['time']}\nTotal:${amount.toStringAsFixed(0)}';
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
        kgList.add(entryKg);
        totalKg += entryKg;
        kgController.clear();
      });
      calculateAmount();
    }
  }

  // 🔹 ADD ENTRY → SAVE TO FIREBASE
  void addEntry() async {
    final price = double.tryParse(priceController.text) ?? 0;
    if (totalKg <= 0 || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please add valid Kg and Price"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final entry = {
        "cotton": selectedCotton,
        "quality": selectedQuality,
        "kg": totalKg,
        "kg_list": kgList.map((e) => e.toString()).toList(),
        "price": priceController.text,
        "amount": totalAmount,
        "time": DateFormat('dd MMM, hh:mm a').format(DateTime.now()),
        "timestamp": DateTime.now().millisecondsSinceEpoch, // For sorting
      };

      await FirebaseService.addLoad(entry);

      if (mounted) {
        setState(() {
          // Clear text controllers
          kgController.clear();
          priceController.clear();

          // Reset numeric totals
          totalAmount = 0;
          totalKg = 0;
          kgList = [];

          // Reset dropdown selections to defaults
          selectedCotton = "Normal Cotton";
          selectedQuality = "Medium";
        });

        // Hides keyboard
        FocusScope.of(context).unfocus();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Entry Saved Successfully!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🔹 DELETE ENTRY FROM FIREBASE
  void deleteEntry(String id) async {
    try {
      await FirebaseService.deleteLoad(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error deleting: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🔹 SHOW PRINT DIALOG
  void _showPrintDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Text(
            "Print Receipt",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Printer Image Placeholder (User can replace with their asset)
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.grey.shade100,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  "https://m.media-amazon.com/images/I/61k1TqPzVFL._SL1500_.jpg", // Sample thermal printer image
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.print_disabled,
                    size: 80,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Printer Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isScanning
                          ? "Scanning for printers..."
                          : _printers.isEmpty
                          ? "No printers found"
                          : "Found ${_printers.length} device(s)",
                      style: TextStyle(
                        fontSize: 12,
                        color: _isScanning
                            ? Colors.blue
                            : _printers.isEmpty
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _isScanning
                          ? null
                          : () {
                              Navigator.pop(context);
                              _scanPrinters().then((_) {
                                if (mounted) _showPrintDialog(item);
                              });
                            },
                      icon: _isScanning
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, size: 18),
                      label: Text(_isScanning ? "Scanning..." : "Rescan"),
                    ),
                  ],
                ),
                if (_printers.isEmpty && !_isScanning)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      "Make sure Bluetooth is ON and printer is powered on.",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
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
                          setState(() {
                            _selectedPrinter = p;
                          });
                          Navigator.pop(context);
                          _showPrintDialog(item);
                        },
                      ),
                    ),
                  ),
              ],
            ),
            const Divider(height: 30),
            // Preview of what will be printed
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Cotton:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("${item['cotton']}"),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Weight:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("${item['kg']} Kg"),
              ],
            ),
            if (item['kg_list'] != null && (item['kg_list'] as List).isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    "(${(item['kg_list'] as List).join("+")})",
                    style: TextStyle(fontSize: 12, color: graydarkcolorshade),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close", style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _selectedPrinter == null
                      ? null
                      : () {
                          _printReceipt(_selectedPrinter!, item);
                          Navigator.pop(context);
                        },
                  child: Text(
                    _selectedPrinter == null ? "Select Printer" : "Print",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double totalTodayAmount(List<Map<String, dynamic>> list) {
    double total = 0;
    for (var item in list) {
      total += double.tryParse(item['amount'].toString()) ?? 0;
    }
    return total;
  }

  double totalHybridCottonQuality(List<Map<String, dynamic>> list) {
    double total = 0;
    for (var item in list) {
      String cotton = item['cotton']?.toString() ?? "";
      if (cotton.contains('Hybrid')) {
        total += double.tryParse(item['kg']?.toString() ?? "0") ?? 0;
      }
    }
    return total;
  }

  double totalKgByQuality(List<Map<String, dynamic>> list, String quality) {
    double total = 0;
    for (var item in list) {
      if (item['quality'] == quality && item['cotton'] == 'Normal Cotton') {
        total += double.tryParse(item['kg']?.toString() ?? "0") ?? 0;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text("Entry Data", style: appbarstyle),
        backgroundColor: primerycolor,
        iconTheme: IconThemeData(color: whitecolor),
      ),
      body: Stack(
        children: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _loadsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint("StreamBuilder Error: ${snapshot.error}");
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      "Firebase Error: ${snapshot.error}\n\nCheck your Rules and Internet.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final todayList = snapshot.data ?? [];
              // Sort by timestamp descending
              todayList.sort(
                (a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0),
              );

              return Container(
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
                                  key: ValueKey(selectedCotton),
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
                                    contentPadding: const EdgeInsets.symmetric(
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
                                  key: ValueKey(selectedQuality),
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
                                    contentPadding: const EdgeInsets.symmetric(
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
                                          contentPadding:
                                              const EdgeInsets.symmetric(
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
                                if (kgList.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: kgList.asMap().entries.map((
                                        entry,
                                      ) {
                                        return Chip(
                                          label: Text(
                                            "${entry.value} Kg",
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          onDeleted: () {
                                            setState(() {
                                              totalKg -= entry.value;
                                              kgList.removeAt(entry.key);
                                              calculateAmount();
                                            });
                                          },
                                          deleteIcon: const Icon(
                                            Icons.close,
                                            size: 14,
                                          ),
                                          backgroundColor: bluecolor.withAlpha(
                                            26,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                    border: const OutlineInputBorder(),
                                    labelStyle: inputtextstyle,
                                    suffixStyle: inputtextstyle,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 18,
                                    ),
                                    enabledBorder: const OutlineInputBorder(
                                      borderSide: BorderSide(width: 2),
                                    ),
                                  ),
                                  onChanged: (_) => calculateAmount(),
                                ),
                                const SizedBox(height: 12),

                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    sectionTitle(context, "Today List"),
                                    Text(
                                      "₹ ${totalTodayAmount(todayList).toStringAsFixed(2)}",
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        /// ---- HYBRID COTTON TOTAL ----
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Hybrid Cotton : ${totalHybridCottonQuality(todayList).toStringAsFixed(1)} Kg",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: bluecolor,
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
                                              "High : ${totalKgByQuality(todayList, 'High')} Kg",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: primerycolor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              "Medium : ${totalKgByQuality(todayList, 'Medium')} Kg",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: primerycolorshade,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              "Low : ${totalKgByQuality(todayList, 'Low')} Kg",
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
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final item = todayList[index];

                              return Card(
                                child: ListTile(
                                  leading: IconButton(
                                    icon: Icon(
                                      Icons.print,
                                      color: primerycolor,
                                    ),
                                    onPressed: () => _showPrintDialog(item),
                                  ),
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
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${item['kg']} Kg × ₹${item['price']} = ₹${item['amount']}",
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (item['kg_list'] != null &&
                                            (item['kg_list'] as List)
                                                .isNotEmpty)
                                          Text(
                                            "Wts: ${(item['kg_list'] as List).join("+")}",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: graydarkcolorshade,
                                            ),
                                          ),
                                        Text(
                                          "${item['time']}",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text("Delete Entry"),
                                            content: const Text(
                                              "Are you sure you want to delete this entry?",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text("Close"),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                  deleteEntry(item['id']);
                                                },
                                                child: const Text(
                                                  "OK",
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
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
              );
            },
          ),
        ],
      ),
    );
  }
}
