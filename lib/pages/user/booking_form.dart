import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingFormPage extends StatefulWidget {
  final String packageId;

  const BookingFormPage({
    super.key,
    required this.packageId,
  });

  @override
  State<BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends State<BookingFormPage> {
  // THEME
  static const Color bgLight = Color(0xFFFCE4EC);
  static const Color primaryPink = Color(0xFFF06292);
  static const Color darkPink = Color(0xFF880E4F);

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _guestController =
  TextEditingController(text: '1');

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  bool loading = true;

  // ===== PACKAGE =====
  String packageName = '';
  double pricePerGuest = 0;

  // ===== USER =====
  String customerName = '';

  // ===== CUSTOMIZATIONS =====
  List<Map<String, dynamic>> customizations = [];
  List<Map<String, dynamic>> selectedCustomizations = [];

  int get guests => int.tryParse(_guestController.text) ?? 1;

  double get baseTotal => guests * pricePerGuest;

  double get customizationTotal {
    return selectedCustomizations.fold(
      0,
          (sum, c) => sum + (c['price'] as double),
    );
  }

  double get grandTotal => baseTotal + customizationTotal;

  DateTime get combinedDateTime {
    return DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ================= LOAD PACKAGE + USER + CUSTOMIZATION =================
  Future<void> _loadData() async {
    try {
      // Load package
      final pkgDoc = await FirebaseFirestore.instance
          .collection('packages')
          .doc(widget.packageId)
          .get();

      if (!pkgDoc.exists) return;

      final pkgData = pkgDoc.data()!;

      // Load user
      final user = FirebaseAuth.instance.currentUser;
      String name = 'Customer';

      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          name = userDoc.data()!['fullName'] ?? 'Customer';
        }
      }

      // Load customizations
      final cusSnap = await FirebaseFirestore.instance
          .collection('customizations')
          .where('isActive', isEqualTo: true)
          .get();

      customizations = cusSnap.docs.map((doc) {
        return {
          'id': doc.id,
          'name': doc['name'],
          'price': (doc['price'] as num).toDouble(),
        };
      }).toList();

      setState(() {
        packageName = pkgData['packageName'];
        pricePerGuest = (pkgData['pricePerGuest'] as num).toDouble();
        customerName = name;
        loading = false;
      });
    } catch (e) {
      debugPrint("Error loading data: $e");
    }
  }

  // ================= DATE =================
  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      initialDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // ================= TIME =================
  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  // ================= CONFIRM =================
  Future<void> _confirmBooking() async {
    if (selectedDate == null || selectedTime == null || guests < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    final docRef = FirebaseFirestore.instance.collection('reservations').doc();


      await docRef.set({
        'reservationId': docRef.id,
        'userId': user?.uid,
        'customerName': customerName,
        'customerEmail': user?.email ?? '',
        'packageId': widget.packageId,
        'packageName': packageName,
        'pricePerGuest': pricePerGuest,
        'guests': guests,
        'selectedCustomizations': selectedCustomizations,
        'customizationTotal': customizationTotal,
        'totalPrice': grandTotal,
        'eventDate': Timestamp.fromDate(combinedDateTime),
        'status': 'Pending',
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;


      context.go('/booking/success/${docRef.id}');

  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: darkPink),
        title: const Text(
          "Booking Details",
          style: TextStyle(color: darkPink),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Text(
              packageName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: darkPink,
              ),
            ),
            const SizedBox(height: 20),

            // ===== DATE =====
            const Text("Event Date"),
            const SizedBox(height: 6),
            TextField(
              controller: _dateController,
              readOnly: true,
              onTap: _selectDate,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.calendar_today),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 16),

            // ===== TIME =====
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text("Event Time"),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryPink),
                onPressed: _selectTime,
                child: Text(
                  selectedTime == null
                      ? 'Select Time'
                      : selectedTime!.format(context),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ===== GUESTS =====
            const Text("Number of Guests"),
            const SizedBox(height: 6),
            TextField(
              controller: _guestController,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.people),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 20),

            // ===== CUSTOMIZATIONS =====
            if (customizations.isNotEmpty) ...[
              const Text(
                "Customizations",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...customizations.map((c) {
                final selected =
                selectedCustomizations.any((x) => x['id'] == c['id']);

                return CheckboxListTile(
                  activeColor: primaryPink,
                  title: Text('${c['name']} (+RM ${c['price']})'),
                  value: selected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        selectedCustomizations.add(c);
                      } else {
                        selectedCustomizations
                            .removeWhere((x) => x['id'] == c['id']);
                      }
                    });
                  },
                );
              }),
            ],

            const Divider(height: 32),

            // ===== PRICE SUMMARY =====
            _priceRow('Base Total', 'RM ${baseTotal.toStringAsFixed(2)}'),
            _priceRow('Customization',
                'RM ${customizationTotal.toStringAsFixed(2)}'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'RM ${grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryPink,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _confirmBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: darkPink,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "CONFIRM BOOKING",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}