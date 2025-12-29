import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class BookingSuccessPage extends StatelessWidget {
  final String reservationId; // ✅ Only expect the ID

  const BookingSuccessPage({super.key, required this.reservationId});

  static const Color bgLight = Color(0xFFFCE4EC);
  static const Color primaryPink = Color(0xFFF06292);
  static const Color darkPink = Color(0xFF880E4F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      body: FutureBuilder<DocumentSnapshot>(
        // ✅ Fetch data directly from Firestore
        future: FirebaseFirestore.instance
            .collection('reservations')
            .doc(reservationId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Reservation not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final DateTime eventDate = (data['eventDate'] as Timestamp).toDate();

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 80),
                  const SizedBox(height: 16),
                  const Text(
                    "Booking Confirmed!",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: darkPink),
                  ),
                  const SizedBox(height: 30),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        _buildRow("Order ID", "#${reservationId.substring(0, 8)}"),
                        _buildRow("Package", data['packageName'] ?? ''),
                        _buildRow("Date", DateFormat('dd MMM yyyy').format(eventDate)),
                        _buildRow("Guests", "${data['guests']} Pax"),
                        const Divider(height: 30),
                        _buildRow(
                            "Total Paid",
                            "RM ${(data['totalPrice'] as num).toStringAsFixed(2)}",
                            isBold: true
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  ElevatedButton(
                    onPressed: () => context.go('/dashboard'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkPink,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text("BACK TO DASHBOARD", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: isBold ? primaryPink : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}