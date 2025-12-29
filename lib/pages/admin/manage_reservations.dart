import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageReservationsPage extends StatefulWidget {
  const ManageReservationsPage({super.key});

  @override
  State<ManageReservationsPage> createState() =>
      _ManageReservationsPageState();
}

class _ManageReservationsPageState extends State<ManageReservationsPage> {
  bool _showMenu = false;
  String searchQuery = '';
  String selectedStatus = 'All';

  // THEME
  static const Color bgLight = Color(0xFFFCE4EC);
  static const Color primaryPink = Color(0xFFF06292);
  static const Color darkPink = Color(0xFF880E4F);

  final CollectionReference reservationsRef =
  FirebaseFirestore.instance.collection('reservations');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: primaryPink,
        title: const Text('ADMIN  |  Manage Reservations'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => setState(() => _showMenu = !_showMenu),
        ),
      ),

      // ================= BODY =================
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ALL RESERVATIONS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkPink,
                  ),
                ),
                const SizedBox(height: 16),

                // ===== SEARCH + ADD =====
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search customer name',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => searchQuery = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPink,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 16),
                      ),
                      onPressed: () {
                        context.go('/admin/reservations/add');
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ===== STATUS FILTER =====
                Wrap(
                  spacing: 10,
                  children: [
                    _statusChip('All', Colors.grey),
                    _statusChip('Pending', Colors.orange),
                    _statusChip('Confirmed', Colors.green),
                    _statusChip('Cancelled', Colors.red),
                  ],
                ),

                const SizedBox(height: 20),

                // ===== FIRESTORE LIST =====
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: reservationsRef
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Center(
                          child: Text('Error loading reservations'),
                        );
                      }

                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      final docs = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;

                        final name =
                        (data['customerName'] ?? '').toString();
                        final status =
                        (data['status'] ?? 'Pending').toString();

                        final matchesSearch = name
                            .toLowerCase()
                            .contains(searchQuery.toLowerCase());

                        final matchesStatus = selectedStatus == 'All'
                            ? true
                            : status == selectedStatus;

                        return matchesSearch && matchesStatus;
                      }).toList();

                      if (docs.isEmpty) {
                        return const Center(
                          child: Text('No reservations found'),
                        );
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data =
                          doc.data() as Map<String, dynamic>;

                          DateTime date;
                          final eventDate = data['eventDate'];

                          if (eventDate is Timestamp) {
                            date = eventDate.toDate();
                          } else {
                            date = DateTime.now();
                          }

                          return ReservationCard(
                            customer: data['customerName'] ?? '',
                            date: '${date.day}/${date.month}/${date.year}',
                            status: data['status'] ?? 'Pending',
                            onView: () {
                              // Navigate to the view page
                              context.go('/admin/reservations/view/${doc.id}');
                            },
                            onEdit: () {
                              context.go('/admin/reservations/edit/${doc.id}');
                            },
                            onCancel: () {
                              context.go('/admin/reservations/cancel/${doc.id}');
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // ===== SIDEBAR =====
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
                      _NavItem(
                        'Dashboard',
                        Icons.dashboard,
                        onTap: () => context.go('/admin'),
                      ),
                      _NavItem(
                        'Manage Packages',
                        Icons.restaurant_menu,
                        onTap: () => context.go('/admin/packages'),
                      ),
                      _NavItem(
                        'Manage Users',
                        Icons.people,
                        onTap: () => context.go('/admin/users'),
                      ),
                      _NavItem(
                        'Manage Reservations',
                        Icons.event,
                        active: true,
                        onTap: () =>
                            context.go('/admin/reservations'),
                      ),
                      const Divider(color: Colors.white54),
                      _NavItem(
                        'Logout',
                        Icons.logout,
                        onTap: () => context.go('/login'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===== STATUS CHIP =====
  Widget _statusChip(String label, Color color) {
    final isSelected = selectedStatus == label;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: color.withOpacity(0.2),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.black,
        fontWeight: FontWeight.bold,
      ),
      onSelected: (_) {
        setState(() => selectedStatus = label);
      },
    );
  }
}

// ================= RESERVATION CARD =================
class ReservationCard extends StatelessWidget {
  final String customer;
  final String date;
  final String status;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onCancel;

  const ReservationCard({
    super.key,
    required this.customer,
    required this.date,
    required this.status,
    required this.onView,
    required this.onEdit,
    required this.onCancel,
  });

  Color get statusColor {
    switch (status) {
      case 'Confirmed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.event, color: statusColor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customer, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(date),
                  const SizedBox(height: 6),
                  Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            //  ACTION ICONS
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.blue),
                  onPressed: onView,
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.pink),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: onCancel,
                ),
              ],
            ),
          ],
        ),
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
