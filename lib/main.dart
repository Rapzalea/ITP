import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; 
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

void main() {
  runApp(const NFCScannerApp());
}

class NFCScannerApp extends StatelessWidget {
  const NFCScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TapReceipt',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: Colors.black87),
        ),
      ),
      home: const MainNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// -----------------------------------------------------------------------------
// MAIN NAVIGATION & STATE 
// -----------------------------------------------------------------------------
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _scans = [];

  @override
  void initState() {
    super.initState();
    _loadSavedScans(); 
  }

  Future<void> _loadSavedScans() async {
    final prefs = await SharedPreferences.getInstance();
    final String? scansJson = prefs.getString('saved_scans_data');

    if (scansJson != null) {
      final List<dynamic> decodedData = jsonDecode(scansJson);
      setState(() {
        _scans = decodedData.map((item) => Map<String, dynamic>.from(item)).toList();
      });
    }
  }

  Future<void> _saveScansToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(_scans);
    await prefs.setString('saved_scans_data', encodedData);
  }

  void _deleteScan(int index) {
    setState(() {
      _scans.removeAt(index);
    });
    _saveScansToStorage(); 
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeTab(onScanPressed: () => _startScanFlow(context)),
      DashboardTab(
        scans: _scans, 
        onDelete: _deleteScan,
      ),
      CategoriesTab(scans: _scans),
    ];

    return Scaffold(
      extendBody: false,
      appBar: AppBar(
        title: const Text('TapReceipt'),
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildNavItem(Icons.home_rounded, 'Home', 0),
                    _buildNavItem(Icons.receipt_long_rounded, 'Scans', 1),
                    _buildNavItem(Icons.location_on_rounded, 'Locations', 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 85,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? Colors.blueAccent : Colors.grey.shade400),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(
                fontSize: 12, 
                color: isSelected ? Colors.blueAccent : Colors.grey.shade400,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _startScanFlow(BuildContext context) async {
    final newScan = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScanningFlowScreen()),
    );

    if (newScan != null && newScan is Map<String, dynamic>) {
      setState(() {
        _scans.insert(0, newScan); 
        _currentIndex = 1;         
      });
      _saveScansToStorage(); 
    }
  }
}

// -----------------------------------------------------------------------------
// HOME TAB
// -----------------------------------------------------------------------------
class HomeTab extends StatelessWidget {
  final VoidCallback onScanPressed;
  const HomeTab({super.key, required this.onScanPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onScanPressed,
            child: Container(
              width: 200,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blueAccent, Colors.lightBlueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withValues(alpha: 0.4), 
                    blurRadius: 15, 
                    offset: const Offset(0, 8),
                  )
                ]
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.nfc, size: 50, color: Colors.white),
                  SizedBox(height: 8),
                  Text('Scan Receipt', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Tap to Scan', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// DASHBOARD TAB
// -----------------------------------------------------------------------------
class DashboardTab extends StatelessWidget {
  final List<Map<String, dynamic>> scans;
  final Function(int) onDelete; 

  const DashboardTab({
    super.key, 
    required this.scans, 
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (scans.isEmpty) {
      return const Center(
        child: Text('No recent scans.\nTap the NFC icon to add one!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
      );
    }

    double totalSpending = scans.fold(0, (sum, item) => sum + (item['amount'] as double));

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text('Dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Spending', style: TextStyle(color: Colors.grey, fontSize: 14)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text('\$${totalSpending.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                  foregroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Export'),
              )
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Recent Scans', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        
        ...scans.asMap().entries.map((entry) {
          int index = entry.key;
          var scan = entry.value;
          final List<dynamic> items = scan['items'] ?? [];
          
          return Dismissible(
            key: ObjectKey(scan), 
            direction: DismissDirection.endToStart, 
            background: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.only(right: 20.0),
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete, color: Colors.white, size: 28),
            ),
            onDismissed: (direction) {
              onDelete(index); 
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${scan['place']} receipt deleted'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: ExpansionTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.storefront, color: Colors.blueAccent, size: 20),
                ),
                title: Text(scan['place'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${scan['date']} • ${scan['category'] ?? 'General'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                trailing: Container(
                  constraints: const BoxConstraints(maxWidth: 100),
                  alignment: Alignment.centerRight,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text('\$${(scan['amount'] as double).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                shape: const Border(), 
                children: [
                  if (items.isNotEmpty) const Divider(height: 1),
                  ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(left: 72.0, right: 16.0, top: 8.0, bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(child: Text('${item['qty']}x ${item['name']}', style: const TextStyle(fontSize: 14, color: Colors.black87))),
                        const SizedBox(width: 16),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 80),
                          alignment: Alignment.centerRight,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text('\$${item['total'].toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: Colors.black87)),
                          ),
                        ),
                      ],
                    ),
                  )),
                  if (scan['subtotal'] != null || scan['gstAmount'] != null) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.only(left: 72.0, right: 16.0, top: 8.0, bottom: 8.0),
                      child: Column(
                        children: [
                          if (scan['subtotal'] != null)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal', style: TextStyle(fontSize: 14, color: Colors.grey)),
                                Text('\$${(scan['subtotal'] as double).toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                              ],
                            ),
                          if (scan['gstAmount'] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('GST (${(scan['gstRate'] as num?)?.toStringAsFixed(1) ?? '?'}%)', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                  Text('\$${(scan['gstAmount'] as double).toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// CATEGORIES TAB 
// -----------------------------------------------------------------------------
class CategoriesTab extends StatelessWidget {
  final List<Map<String, dynamic>> scans;
  const CategoriesTab({super.key, required this.scans});

  @override
  Widget build(BuildContext context) {
    if (scans.isEmpty) {
      return const Center(child: Text('No locations visited yet.', style: TextStyle(color: Colors.grey)));
    }

    final Map<String, List<Map<String, dynamic>>> groupedScans = {};
    for (var scan in scans) {
      final place = scan['place'] as String;
      if (!groupedScans.containsKey(place)) {
        groupedScans[place] = [];
      }
      groupedScans[place]!.add(scan);
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text('Spending by Location', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...groupedScans.entries.map((entry) {
          final placeName = entry.key;
          final locationScans = entry.value;
          final locationTotal = locationScans.fold(0.0, (sum, item) => sum + (item['amount'] as double));

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: ExpansionTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.place, color: Colors.indigo, size: 20),
              ),
              title: Text(placeName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${locationScans.length} visit(s)', style: const TextStyle(color: Colors.grey)),
              trailing: Container(
                constraints: const BoxConstraints(maxWidth: 100),
                alignment: Alignment.centerRight,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Text('\$${locationTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              shape: const Border(),
              children: locationScans.map((scan) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 32.0),
                title: Text(scan['date'], style: const TextStyle(fontSize: 14)),
                trailing: Container(
                  constraints: const BoxConstraints(maxWidth: 80),
                  alignment: Alignment.centerRight,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text('\$${(scan['amount'] as double).toStringAsFixed(2)}'),
                  ),
                ),
              )).toList(),
            ),
          );
        }),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// SCANNING FLOW (Updated for Physical NFC)
// -----------------------------------------------------------------------------
class ScanningFlowScreen extends StatefulWidget {
  const ScanningFlowScreen({super.key});

  @override
  State<ScanningFlowScreen> createState() => _ScanningFlowScreenState();
}

class _ScanningFlowScreenState extends State<ScanningFlowScreen> {
  int _step = 2;
  
  late String _scannedPlace;
  late double _scannedAmount;
  late String _scannedDate;
  late List<Map<String, dynamic>> _scannedItems;
  double? _scannedGstRate;
  double? _scannedGstAmount;
  double? _scannedSubtotal;

  @override
  void initState() {
    super.initState();
    _startRealNfcScan();
  }

  @override
  void dispose() {
    NfcManager.instance.stopSession();
    super.dispose();
  }

  void _startRealNfcScan() async {
    // FIX 4: Updated availability check
    NfcAvailability availability = await NfcManager.instance.checkAvailability();
    
    if (availability != NfcAvailability.enabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NFC is not available. Please use Simulate Scan.')),
      );
      return;
    }

    NfcManager.instance.startSession(
      // FIX 1: Explicitly defining polling options
      pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693}, 
      onDiscovered: (NfcTag tag) async {
        setState(() => _step = 3);
        
        try {
          var ndef = Ndef.from(tag); 
          if (ndef == null || ndef.cachedMessage == null) {
            throw Exception('Tag is empty or not NDEF formatted.');
          }
          
          String fullJson = '';
          for (var record in ndef.cachedMessage!.records) {
            List<int> payloadBytes = record.payload;
            if (payloadBytes.isEmpty) continue;

            // Properly check if it's a Text record (TNF=1, Type='T')
            bool isTextRecord = record.typeNameFormat.index == 1 &&
                                record.type.length == 1 &&
                                record.type.first == 0x54; // 0x54 is 'T'

            if (isTextRecord) {
              int languageCodeLength = payloadBytes[0] & 0x3F; 
              int textOffset = 1 + languageCodeLength;
              if (textOffset < payloadBytes.length) {
                fullJson += utf8.decode(payloadBytes.sublist(textOffset), allowMalformed: true);
              }
            } else {
              // For MIME records (like application/json), there is no language code prefix
              fullJson += utf8.decode(payloadBytes, allowMalformed: true);
            }
          }

          // Sanitize the string: obliterate any hidden control chars, line breaks, or null terminators
          String cleanJson = fullJson.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '');
          
          Map<String, dynamic> tagData;
          try {
            tagData = jsonDecode(cleanJson);
          } catch (e) {
            throw Exception('Invalid receipt data on tag. Please try scanning a valid receipt tag.');
          }

          _scannedPlace = tagData['shop_name'] ?? tagData['place'] ?? 'Unknown Location';
          _scannedAmount = (tagData['final_total'] as num?)?.toDouble() ?? (tagData['amount'] as num?)?.toDouble() ?? 0.0;
          _scannedGstRate = (tagData['gst_rate'] as num?)?.toDouble();
          _scannedGstAmount = (tagData['gst_amount'] as num?)?.toDouble();
          _scannedSubtotal = (tagData['subtotal'] as num?)?.toDouble();
          if (_scannedAmount < 0) {
            throw Exception('Receipt amount cannot be negative.');
          }
          
          String datePart = tagData['date'] ?? DateFormat('MMM dd, yyyy').format(DateTime.now());
          String timePart = tagData['time'] ?? DateFormat('hh:mm a').format(DateTime.now());
          _scannedDate = tagData.containsKey('time') ? '$datePart • $timePart' : datePart;
          
          if (tagData['products'] != null) {
            _scannedItems = (tagData['products'] as List).map((p) {
              double total = (p['total'] as num).toDouble();
              if (total < 0) throw Exception('Item total cannot be negative.');
              return {
                'name': p['name'],
                'qty': p['quantity'],
                'total': total,
              };
            }).toList();
          } else if (tagData['items'] != null) {
            _scannedItems = List<Map<String, dynamic>>.from(tagData['items']);
          } else {
            _scannedItems = [];
          }

          setState(() => _step = 4);
          
          NfcManager.instance.stopSession();

          if (!mounted) return;
          
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConfirmCategorizeScreen(
                place: _scannedPlace,
                amount: _scannedAmount,
                date: _scannedDate,
                items: _scannedItems, 
                gstRate: _scannedGstRate,
                gstAmount: _scannedGstAmount,
                subtotal: _scannedSubtotal,
              ),
            ),
          );

          if (mounted) {
            Navigator.pop(context, result);
          }
        } catch (e) {
          NfcManager.instance.stopSession(); 
          if (!mounted) return;
          
          String errorMessage = e.toString();
          if (errorMessage.startsWith('Exception: ')) {
            errorMessage = errorMessage.substring(11);
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
          Navigator.pop(context);
        }
      },
    );
  }

  void _simulateScan() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (_) {}

    setState(() => _step = 4);
    if (!mounted) return;
    
    // Simulate parsing the same data
    _scannedPlace = "Simulated Shop";
    _scannedAmount = 10.68;
    _scannedDate = "10/07/2026";
    _scannedItems = [
      {"name": "Milk", "price": 3.5, "quantity": 2, "total": 7.0},
      {"name": "Bread", "price": 2.8, "quantity": 1, "total": 2.8}
    ];
    _scannedSubtotal = 9.8;
    _scannedGstRate = 9.0;
    _scannedGstAmount = 0.88;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmCategorizeScreen(
          place: _scannedPlace,
          amount: _scannedAmount,
          date: _scannedDate,
          items: _scannedItems, 
          gstRate: _scannedGstRate,
          gstAmount: _scannedGstAmount,
          subtotal: _scannedSubtotal,
        ),
      ),
    );

    if (mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanning...', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_step == 2) ...[
                const Icon(Icons.contactless, size: 100, color: Colors.grey),
                const SizedBox(height: 24),
                const Text('Approach NFC Tag', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _simulateScan,
                  child: const Text('Simulate Scan'),
                ),
              ] else if (_step == 3) ...[
                const Icon(Icons.waves, size: 100, color: Colors.blue),
                const SizedBox(height: 24),
                const Text('Detecting Receipt Data...', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const LinearProgressIndicator(),
              ] else if (_step == 4) ...[
                const SizedBox(width: 40, height: 40, child: CircularProgressIndicator()),
                const SizedBox(height: 24),
                const Text('Syncing & Digitalizing...', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Merchant', style: TextStyle(fontSize: 16)),
                      Text(_scannedPlace, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('\$${_scannedAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// CONFIRM CATEGORIZE 
// -----------------------------------------------------------------------------
class ConfirmCategorizeScreen extends StatefulWidget {
  final String place;
  final double amount;
  final String date;
  final List<Map<String, dynamic>> items; 
  final double? gstRate;
  final double? gstAmount;
  final double? subtotal;

  const ConfirmCategorizeScreen({
    super.key, 
    required this.place, 
    required this.amount,
    required this.date,
    required this.items,
    this.gstRate,
    this.gstAmount,
    this.subtotal,
  });

  @override
  State<ConfirmCategorizeScreen> createState() => _ConfirmCategorizeScreenState();
}

class _ConfirmCategorizeScreenState extends State<ConfirmCategorizeScreen> {
  String _selectedCategory = 'Food & Drink';
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.0;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey)),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Saved!', style: TextStyle(color: Colors.green)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F9F9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.place.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 4.0),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ITEMS', style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.0)),
                      Text('${widget.items.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('DATE', style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.0)),
                      Text(widget.date.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildDashedLine(),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      SizedBox(width: 30, child: Text('QTY', style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.0))),
                      Expanded(child: Text('ITEM', style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.0))),
                      Text('AMT', style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.0)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...widget.items.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 30, 
                            child: Text('${item['qty']}', style: const TextStyle(fontSize: 14, color: Colors.grey))
                          ),
                          Expanded(
                            child: Text('${item['name']}'.toUpperCase(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))
                          ),
                          const SizedBox(width: 8),
                          Text('\$${item['total'].toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                  _buildDashedLine(),
                  const SizedBox(height: 16),
                  if (widget.subtotal != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('SUBTOTAL', style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.0)),
                          Text('\$${widget.subtotal!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  if (widget.gstAmount != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('GST (${widget.gstRate?.toStringAsFixed(1) ?? '?'}%)', style: const TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.0)),
                          Text('\$${widget.gstAmount!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  Container(height: 1, color: Colors.black),
                  const SizedBox(height: 2),
                  Container(height: 2, color: Colors.black),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                      Text('\$${widget.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(40, (index) {
                      final weights = [1.0, 2.0, 3.0, 1.0, 4.0, 1.0, 2.0];
                      return Container(
                        margin: const EdgeInsets.only(right: 2),
                        width: weights[index % weights.length],
                        height: 40,
                        color: Colors.black87,
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  const Center(child: Text('REVIEWED BY YOU', style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 2.0))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Categorize', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  items: ['Food & Drink', 'Transport', 'Office Supplies', 'General']
                      .map((String value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ))
                      .toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedCategory = newValue!;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Add a note', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'Optional note...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.deepPurple.shade50, 
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                final Map<String, dynamic> newScanMap = {
                  'place': widget.place,
                  'amount': widget.amount,
                  'date': widget.date, 
                  'category': _selectedCategory, 
                  'note': _noteController.text,  
                  'items': widget.items, 
                  'gstRate': widget.gstRate,
                  'gstAmount': widget.gstAmount,
                  'subtotal': widget.subtotal,
                };
                
                Navigator.pop(context, newScanMap);
              },
              child: const Text('Save & Categorize', style: TextStyle(fontSize: 18, color: Colors.deepPurple)),
            )
          ],
        ),
      ),
      ),
    );
  }
}