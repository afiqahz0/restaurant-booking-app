import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MyReservationPage extends StatelessWidget {
  const MyReservationPage({super.key});

  static const Color bgLight = Color(0xFFFCE4EC);
  static const Color primaryPink = Color(0xFFF06292);
  static const Color darkPink = Color(0xFF880E4F);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        title: const Text(
          "My Reservations",
          style: TextStyle(
            color: darkPink,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: darkPink),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservations')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text("Error loading reservations"),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "No reservations found",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final DateTime date = (data['eventDate'] as Timestamp).toDate();

              return _ReservationCard(
                reservationId: doc.id,
                title: data['packageName'] ?? '',
                date: DateFormat('dd MMM yyyy').format(date),
                status: data['status'] ?? 'Pending',
              );
            },
          );
        },
      ),
    );
  }
}

// ================= RESERVATION CARD =================

class _ReservationCard extends StatelessWidget {
  static const Color primaryPink = Color(0xFFF06292);

  final String reservationId;
  final String title;
  final String date;
  final String status;

  const _ReservationCard({
    required this.reservationId,
    required this.title,
    required this.date,
    required this.status,
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // --- HEADER: STATUS + ID ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  "#${reservationId.substring(0, 6)}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // --- INFO: TITLE + DATE ---
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE4EC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: primaryPink,
                ),
              ),
              title: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(date),
            ),

            const Divider(height: 24),

            // --- ACTIONS: VIEW & EDIT ---
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // VIEW DETAILS BUTTON
                TextButton.icon(
                  onPressed: () {
                    context.go('/user/reservations/view/$reservationId');
                  },
                  icon: const Icon(Icons.visibility, size: 18, color: Colors.blue),
                  label: const Text(
                    "View Details",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),

                // EDIT BUTTON (Hidden if cancelled)
                if (status != 'Cancelled') ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () {
                      context.push('/reservations/edit/$reservationId');
                    },
                    icon: const Icon(Icons.edit, size: 18, color: primaryPink),
                    label: const Text(
                      "Edit",
                      style: TextStyle(color: primaryPink),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}