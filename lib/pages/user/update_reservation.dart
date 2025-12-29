import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateReservationPage extends StatefulWidget {
  final String reservationId;

  const UpdateReservationPage({
    super.key,
    required this.reservationId,
  });

  @override
  State<UpdateReservationPage> createState() =>
      _UpdateReservationPageState();
}

class _UpdateReservationPageState extends State<UpdateReservationPage> {
  bool _loading = true;

  // THEME
  static const Color bgLight = Color(0xFFFCE4EC);
  static const Color primaryPink = Color(0xFFF06292);
  static const Color darkPink = Color(0xFF880E4F);

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  int guests = 1;
  String status = 'Pending';

  String packageName = '';
  double pricePerGuest = 0;

  // ===== CUSTOMIZATIONS =====
  List<Map<String, dynamic>> customizations = [];
  List<Map<String, dynamic>> selectedCustomizations = [];

  final reservationsRef =
  FirebaseFirestore.instance.collection('reservations');

  @override
  void initState() {
    super.initState();
    _loadReservation();
  }

  // ================= LOAD DATA =================
  Future<void> _loadReservation() async {
    // Load reservation
    final resDoc =
    await reservationsRef.doc(widget.reservationId).get();
    final data = resDoc.data()!;

    final DateTime dateTime =
    (data['eventDate'] as Timestamp).toDate();

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
      packageName = data['packageName'];
      pricePerGuest =
          (data['pricePerGuest'] as num).toDouble();

      selectedDate = DateTime(
        dateTime.year,
        dateTime.month,
        dateTime.day,
      );

      selectedTime =
          TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);

      guests = data['guests'];
      status = data['status'];

      selectedCustomizations =
      List<Map<String, dynamic>>.from(
          data['selectedCustomizations'] ?? []);

      _loading = false;
    });
  }

  // ================= PRICE =================
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

  // ================= SAVE =================
  Future<void> _saveChanges() async {
    await reservationsRef.doc(widget.reservationId).update({
      'eventDate': Timestamp.fromDate(combinedDateTime),
      'guests': guests,
      'selectedCustomizations': selectedCustomizations,
      'customizationTotal': customizationTotal,
      'totalPrice': grandTotal,
      'status': status,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reservation updated')),
    );

    context.go('/reservations');
  }

  // ================= CANCEL =================
  Future<void> _cancelReservation() async {
    await reservationsRef.doc(widget.reservationId).update({
      'status': 'Cancelled',
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reservation cancelled')),
    );

    context.go('/reservations');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
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
          'Update Reservation',
          style: TextStyle(color: darkPink),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // ===== PACKAGE =====
            Text(
              packageName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: darkPink,
              ),
            ),

            const SizedBox(height: 20),

            // ===== DATE =====
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Event Date'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPink,
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                    initialDate: selectedDate!,
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
                child: Text(
                  '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ===== TIME =====
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Event Time'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryPink,
                ),
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: selectedTime!,
                  );
                  if (picked != null) {
                    setState(() => selectedTime = picked);
                  }
                },
                child: Text(
                  selectedTime!.format(context),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ===== GUESTS =====
            Row(
              children: [
                const Text('No. Guests'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed:
                  guests > 1 ? () => setState(() => guests--) : null,
                ),
                Text('$guests'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() => guests++),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ===== CUSTOMIZATIONS =====
            const Text(
              'Customizations',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ...customizations.map((c) {
              final selected = selectedCustomizations
                  .any((x) => x['id'] == c['id']);

              return CheckboxListTile(
                title: Text('${c['name']} (RM ${c['price']})'),
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

            const Divider(height: 32),

            // ===== PRICE =====
            Text('Base Total: RM ${baseTotal.toStringAsFixed(0)}'),
            Text(
                'Customization: RM ${customizationTotal.toStringAsFixed(0)}'),
            const SizedBox(height: 6),
            Text(
              'TOTAL: RM ${grandTotal.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // ===== STATUS =====
            DropdownButtonFormField<String>(
              value: status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'Pending', child: Text('Pending')),
                DropdownMenuItem(
                    value: 'Confirmed', child: Text('Confirmed')),
              ],
              onChanged: (value) =>
                  setState(() => status = value!),
            ),

            const SizedBox(height: 30),

            // ===== SAVE =====
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPink,
                padding:
                const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _saveChanges,
              child: const Text(
                'SAVE CHANGES',
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 12),

            // ===== CANCEL =====
            TextButton(
              onPressed: _cancelReservation,
              child: const Text(
                'Cancel Reservation',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
