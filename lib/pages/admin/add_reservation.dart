import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddReservationPage extends StatefulWidget {
  const AddReservationPage({super.key});

  @override
  State<AddReservationPage> createState() => _AddReservationPageState();
}

class _AddReservationPageState extends State<AddReservationPage> {
  bool _showMenu = false;
  bool _loading = true;

  // THEME
  static const Color bgLight = Color(0xFFFCE4EC);
  static const Color primaryPink = Color(0xFFF06292);
  static const Color darkPink = Color(0xFF880E4F);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  int guests = 1;
  String status = 'Pending';

  // ===== PACKAGES =====
  List<Map<String, dynamic>> packages = [];
  Map<String, dynamic>? selectedPackage;

  // ===== CUSTOMIZATIONS =====
  List<Map<String, dynamic>> customizations = [];
  List<Map<String, dynamic>> selectedCustomizations = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ================= LOAD DATA =================
  Future<void> _loadData() async {
    final pkgSnap = await FirebaseFirestore.instance
        .collection('packages')
        .where('isActive', isEqualTo: true)
        .get();

    final cusSnap = await FirebaseFirestore.instance
        .collection('customizations')
        .where('isActive', isEqualTo: true)
        .get();

    packages = pkgSnap.docs.map((doc) {
      return {
        'id': doc.id,
        'name': doc['packageName'],
        'price': (doc['pricePerGuest'] as num).toDouble(),
      };
    }).toList();

    customizations = cusSnap.docs.map((doc) {
      return {
        'id': doc.id,
        'name': doc['name'],
        'price': (doc['price'] as num).toDouble(),
      };
    }).toList();

    if (packages.isNotEmpty) {
      selectedPackage = packages.first;
    }

    setState(() => _loading = false);
  }

  // ================= PRICE CALC =================
  double get baseTotal {
    if (selectedPackage == null) return 0;
    return guests * (selectedPackage!['price'] as double);
  }

  double get customizationTotal {
    return selectedCustomizations.fold(
      0,
          (sum, c) => sum + (c['price'] as double),
    );
  }

  double get grandTotal => baseTotal + customizationTotal;

  // ================= DATE + TIME =================
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
  Future<void> _saveReservation() async {
    if (selectedDate == null ||
        selectedTime == null ||
        selectedPackage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('reservations').add({
      'customerName': nameController.text.trim(),
      'customerEmail': emailController.text.trim(),

      'packageId': selectedPackage!['id'],
      'packageName': selectedPackage!['name'],
      'pricePerGuest': selectedPackage!['price'],
      'guests': guests,

      'selectedCustomizations': selectedCustomizations,
      'customizationTotal': customizationTotal,

      'totalPrice': grandTotal,
      'eventDate': Timestamp.fromDate(combinedDateTime),
      'status': status,
      'createdAt': Timestamp.now(),
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reservation added')),
    );

    context.go('/admin/reservations');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,

      appBar: AppBar(
        backgroundColor: primaryPink,
        title: const Text('ADMIN | Add Reservation'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => setState(() => _showMenu = !_showMenu),
        ),
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                const Text(
                  'ADD RESERVATION',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkPink,
                  ),
                ),
                const SizedBox(height: 20),

                // ===== CUSTOMER =====
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Customer Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // ===== PACKAGE =====
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: selectedPackage,
                  decoration: const InputDecoration(
                    labelText: 'Select Package',
                    border: OutlineInputBorder(),
                  ),
                  items: packages.map((pkg) {
                    return DropdownMenuItem(
                      value: pkg,
                      child: Text(pkg['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedPackage = value);
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
                    title:
                    Text('${c['name']} (RM ${c['price']})'),
                    value: selected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          selectedCustomizations.add(c);
                        } else {
                          selectedCustomizations.removeWhere(
                                  (x) => x['id'] == c['id']);
                        }
                      });
                    },
                  );
                }),

                const Divider(height: 32),

                // ===== EVENT DATE =====
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Event Date'),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPink),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                        initialDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    child: Text(
                      selectedDate == null
                          ? 'Select Date'
                          : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                    ),
                  ),
                ),

                // ===== EVENT TIME =====
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Event Time'),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPink),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setState(() => selectedTime = picked);
                      }
                    },
                    child: Text(
                      selectedTime == null
                          ? 'Select Time'
                          : selectedTime!.format(context),
                    ),
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
                      onPressed: () => setState(() => guests++),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ===== PRICE SUMMARY =====
                Text(
                    'Base Total: RM ${baseTotal.toStringAsFixed(0)}'),
                Text(
                    'Customization: RM ${customizationTotal.toStringAsFixed(0)}'),
                const SizedBox(height: 6),
                Text(
                  'TOTAL: RM ${grandTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
                    DropdownMenuItem(
                        value: 'Pending',
                        child: Text('Pending')),
                    DropdownMenuItem(
                        value: 'Confirmed',
                        child: Text('Confirmed')),
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
                  onPressed: _saveReservation,
                  child: const Text(
                    'SAVE RESERVATION',
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
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      _NavItem('Dashboard', Icons.dashboard,
                          onTap: () =>
                              context.go('/admin')),
                      _NavItem('Manage Packages',
                          Icons.restaurant_menu,
                          onTap: () =>
                              context.go('/admin/packages')),
                      _NavItem('Manage Users', Icons.people,
                          onTap: () =>
                              context.go('/admin/users')),
                      _NavItem('Manage Reservations',
                          Icons.event,
                          active: true,
                          onTap: () => context
                              .go('/admin/reservations')),
                      const Divider(color: Colors.white54),
                      _NavItem('Logout', Icons.logout,
                          onTap: () =>
                              context.go('/login')),
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

  const _NavItem(this.title, this.icon,
      {this.active = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
    );
  }
}
