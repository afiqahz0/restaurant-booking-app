import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditReservationPage extends StatefulWidget {
  final String reservationId;

  const EditReservationPage({
    super.key,
    required this.reservationId,
  });

  @override
  State<EditReservationPage> createState() =>
      _EditReservationPageState();
}

class _EditReservationPageState extends State<EditReservationPage> {
  bool _showMenu = false;
  bool _loading = true;

  // 🌸 THEME
  static const Color bgLight = Color(0xFFFCE4EC);
  static const Color primaryPink = Color(0xFFF06292);
  static const Color darkPink = Color(0xFF880E4F);

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  int guests = 1;
  String status = 'Pending';

  String? selectedPackageId;
  String? selectedPackageName;
  double pricePerGuest = 0;

  // ===== DATA =====
  List<Map<String, dynamic>> packages = [];
  List<Map<String, dynamic>> customizations = [];
  List<Map<String, dynamic>> selectedCustomizations = [];

  final reservationsRef =
  FirebaseFirestore.instance.collection('reservations');
  final packagesRef =
  FirebaseFirestore.instance.collection('packages');
  final customizationsRef =
  FirebaseFirestore.instance.collection('customizations');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ================= LOAD DATA =================
  Future<void> _loadData() async {
    // Load packages
    final pkgSnapshot = await packagesRef.get();
    packages = pkgSnapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'name': doc['packageName'],
        'price': (doc['pricePerGuest'] as num).toDouble(),
      };
    }).toList();

    // Load customizations
    final cusSnapshot = await customizationsRef
        .where('isActive', isEqualTo: true)
        .get();

    customizations = cusSnapshot.docs.map((doc) {
      return {
        'id': doc.id,
        'name': doc['name'],
        'price': (doc['price'] as num).toDouble(),
      };
    }).toList();

    // Load reservation
    final resDoc =
    await reservationsRef.doc(widget.reservationId).get();
    final data = resDoc.data()!;

    final DateTime eventDateTime =
    (data['eventDate'] as Timestamp).toDate();

    setState(() {
      selectedPackageId = data['packageId'];
      selectedPackageName = data['packageName'];
      pricePerGuest =
          (data['pricePerGuest'] as num).toDouble();

      guests = data['guests'];
      status = data['status'];

      selectedDate = DateTime(
        eventDateTime.year,
        eventDateTime.month,
        eventDateTime.day,
      );

      selectedTime =
          TimeOfDay(hour: eventDateTime.hour, minute: eventDateTime.minute);

      selectedCustomizations =
      List<Map<String, dynamic>>.from(
          data['selectedCustomizations'] ?? []);

      _loading = false;
    });
  }

  // ================= PRICE CALC =================
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
      'packageId': selectedPackageId,
      'packageName': selectedPackageName,
      'pricePerGuest': pricePerGuest,
      'guests': guests,

      'selectedCustomizations': selectedCustomizations,
      'customizationTotal': customizationTotal,

      'totalPrice': grandTotal,
      'eventDate': Timestamp.fromDate(combinedDateTime),
      'status': status,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reservation updated')),
    );

    context.go('/admin/reservations');
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
        backgroundColor: primaryPink,
        title: const Text('ADMIN | Edit Reservation'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () =>
              setState(() => _showMenu = !_showMenu),
        ),
      ),

      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                const Text(
                  'EDIT RESERVATION',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkPink,
                  ),
                ),
                const SizedBox(height: 20),

                // ===== PACKAGE =====
                DropdownButtonFormField<String>(
                  value: selectedPackageId,
                  decoration: const InputDecoration(
                    labelText: 'Package',
                    border: OutlineInputBorder(),
                  ),
                  items: packages.map((pkg) {
                    return DropdownMenuItem<String>(
                      value: pkg['id'],
                      child: Text(pkg['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    final pkg =
                    packages.firstWhere((p) => p['id'] == value);
                    setState(() {
                      selectedPackageId = value;
                      selectedPackageName = pkg['name'];
                      pricePerGuest = pkg['price'];
                    });
                  },
                ),

                const SizedBox(height: 16),

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

                // ===== EVENT DATE =====
                ListTile(
                  title: const Text('Event Date'),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPink),
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

                // ===== EVENT TIME =====
                ListTile(
                  title: const Text('Event Time'),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPink),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime!,
                      );
                      if (picked != null) {
                        setState(() => selectedTime = picked);
                      }
                    },
                    child: Text(selectedTime!.format(context)),
                  ),
                ),

                const SizedBox(height: 16),

                // ===== GUESTS =====
                Row(
                  children: [
                    const Text('Guests'),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: guests > 1
                          ? () => setState(() => guests--)
                          : null,
                    ),
                    Text('$guests'),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () =>
                          setState(() => guests++),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ===== PRICE SUMMARY =====
                Text('Base Total: RM ${baseTotal.toStringAsFixed(0)}'),
                Text('Customization: RM ${customizationTotal.toStringAsFixed(0)}'),
                const SizedBox(height: 6),
                Text(
                  'TOTAL: RM ${grandTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                // ===== STATUS =====
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'Confirmed', child: Text('Confirmed')),
                    DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                  ],
                  onChanged: (value) =>
                      setState(() => status = value!),
                ),

                const SizedBox(height: 30),

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
              ],
            ),
          ),

          if (_showMenu)
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              child: Container(
                width: 220,
                color: primaryPink,
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _NavItem('Dashboard', Icons.dashboard,
                          onTap: () => context.go('/admin')),
                      _NavItem('Manage Packages', Icons.restaurant_menu,
                          onTap: () => context.go('/admin/packages')),
                      _NavItem('Manage Users', Icons.people,
                          onTap: () => context.go('/admin/users')),
                      _NavItem('Manage Reservations', Icons.event,
                          active: true,
                          onTap: () =>
                              context.go('/admin/reservations')),
                      const Divider(color: Colors.white54),
                      _NavItem('Logout', Icons.logout,
                          onTap: () => context.go('/login')),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ================= SIDEBAR ITEM =================
class _NavItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _NavItem(
      this.title,
      this.icon, {
        this.active = false,
        required this.onTap,
      });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight:
          active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
    );
  }
}
