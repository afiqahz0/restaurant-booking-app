import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CancelReservationPage extends StatefulWidget {
  final String reservationId;

  const CancelReservationPage({
    super.key,
    required this.reservationId,
  });

  @override
  State<CancelReservationPage> createState() =>
      _CancelReservationPageState();
}

class _CancelReservationPageState
    extends State<CancelReservationPage> {
  bool _showMenu = false;
  bool _loading = false;

  // 🌸 THEME (match login/register)
  static const Color bgLight = Color(0xFFFCE4EC);
  static const Color primaryPink = Color(0xFFF06292);

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // 🔥 DELETE RESERVATION
  Future<void> _cancelReservation() async {
    try {
      setState(() => _loading = true);

      await _firestore
          .collection('reservations')
          .doc(widget.reservationId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reservation deleted successfully'),
        ),
      );

      context.go('/admin/reservations');
    } catch (e) {
      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete reservation: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: primaryPink,
        title: const Text('ADMIN  |  Delete Reservation'),
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
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 48,
                        color: Colors.redAccent,
                      ),
                      const SizedBox(height: 16),

                      Text(
                        'Are you sure you want to delete\nReservation #${widget.reservationId}?',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'This action cannot be undone.',
                        style: TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              Colors.redAccent,
                            ),
                            onPressed:
                            _loading ? null : _cancelReservation,
                            child: Text(
                              _loading
                                  ? 'Deleting...'
                                  : 'Confirm Delete',
                            ),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton(
                            onPressed: () {
                              context.go('/admin/reservations');
                            },
                            child: const Text('Back'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ===== SIDEBAR OVERLAY =====
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
                      _NavItem(
                        'Dashboard',
                        Icons.dashboard,
                        onTap: () =>
                            context.go('/admin'),
                      ),
                      _NavItem(
                        'Manage Menu',
                        Icons.restaurant_menu,
                        onTap: () =>
                            context.go('/admin/packages'),
                      ),
                      _NavItem(
                        'Manage Users',
                        Icons.people,
                        onTap: () =>
                            context.go('/admin/users'),
                      ),
                      _NavItem(
                        'Manage Reservations',
                        Icons.event,
                        active: true,
                        onTap: () => context
                            .go('/admin/reservations'),
                      ),
                      const Divider(
                          color: Colors.white54),
                      _NavItem(
                        'Logout',
                        Icons.logout,
                        onTap: () =>
                            context.go('/login'),
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
