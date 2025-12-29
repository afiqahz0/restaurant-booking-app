import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _showMenu = false;

  // MATCH THEME
  static const Color bgLight = Color(0xFFFCE4EC);
  static const Color primaryPink = Color(0xFFF06292);
  static const Color darkPink = Color(0xFF880E4F);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // HELPER FOR STATUS COLORS
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      case 'Pending':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: primaryPink,
        title: const Text('ADMIN DASHBOARD'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            setState(() => _showMenu = !_showMenu);
          },
        ),
      ),

      // ================= BODY =================
      body: Stack(
        children: [
          // ===== MAIN CONTENT =====
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                // ===== SUMMARY CARDS =====
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Packages',
                        icon: Icons.restaurant_menu,
                        stream: _firestore.collection('packages').snapshots(),
                        onTap: () => context.go('/admin/packages'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Reservations',
                        icon: Icons.event,
                        stream: _firestore.collection('reservations').snapshots(),
                        onTap: () => context.go('/admin/reservations'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        title: 'Users',
                        icon: Icons.people,
                        stream: _firestore.collection('users').snapshots(),
                        onTap: () => context.go('/admin/users'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // ===== RECENT RESERVATIONS =====
                const Text(
                  'Recent Reservations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkPink,
                  ),
                ),
                const SizedBox(height: 12),

                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('reservations')
                      .orderBy('createdAt', descending: true)
                      .limit(5)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final reservations = snapshot.data!.docs;

                    if (reservations.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No reservations yet'),
                        ),
                      );
                    }

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reservations.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final doc = reservations[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final String status = data['status'] ?? 'Pending';

                          return ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: bgLight,
                              child: Icon(Icons.event, color: primaryPink, size: 20),
                            ),
                            title: Text(
                              data['customerName'] ?? 'Unknown',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              status,
                              style: TextStyle(
                                color: _getStatusColor(status), //
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/admin/reservations'),
                    icon: const Icon(Icons.list),
                    label: const Text('VIEW ALL RESERVATIONS'),
                    style: OutlinedButton.styleFrom(foregroundColor: darkPink),
                  ),
                ),
              ],
            ),
          ),

          // ===== SIDEBAR NAV =====
          if (_showMenu)
            Positioned(
              top: 0, bottom: 0, left: 0,
              child: Container(
                width: 220,
                color: primaryPink,
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _NavItem('Dashboard', Icons.dashboard, active: true, onTap: () => context.go('/admin')),
                      _NavItem('Manage Packages', Icons.restaurant_menu, onTap: () => context.go('/admin/packages')),
                      _NavItem('Manage Users', Icons.people, onTap: () => context.go('/admin/users')),
                      _NavItem('Manage Reservations', Icons.event, onTap: () => context.go('/admin/reservations')),
                      const Divider(color: Colors.white54),
                      _NavItem('Logout', Icons.logout, onTap: () => context.go('/login')),
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

// ================= STAT CARD =================
class _StatCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Stream<QuerySnapshot> stream;
  final VoidCallback onTap;

  static const Color primaryPink = Color(0xFFF06292);

  const _StatCard({
    required this.title,
    required this.icon,
    required this.stream,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;

        return GestureDetector(
          onTap: onTap,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
              child: Column(
                children: [
                  Icon(icon, size: 28, color: primaryPink),
                  const SizedBox(height: 8),
                  Text(
                    count.toString(),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ================= SIDEBAR ITEM =================
class _NavItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _NavItem(this.title, this.icon, {this.active = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white, size: 22),
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