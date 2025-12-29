import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class UserViewReservationPage extends StatelessWidget {
  final String reservationId;

  const UserViewReservationPage({super.key, required this.reservationId});

  // 🌸 THEME COLORS
  static const Color bgLight = Color(0xFFFCE4EC);
  static const Color primaryPink = Color(0xFFF06292);
  static const Color darkPink = Color(0xFF880E4F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: primaryPink,
        elevation: 0,
        title: const Text('Reservation Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/reservations'),
        ),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('reservations')
            .doc(reservationId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Reservation not found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          // Date Formatting
          final timestamp = data['eventDate'] as Timestamp?;
          final dateStr = timestamp != null
              ? DateFormat('EEEE, dd MMMM yyyy').format(timestamp.toDate())
              : 'N/A';
          final timeStr = timestamp != null
              ? DateFormat('hh:mm a').format(timestamp.toDate())
              : 'N/A';

          // Customizations List
          final List<dynamic> selectedCustoms = data['selectedCustomizations'] ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- CUSTOMER SECTION ---
                      _buildHeader('Customer Info', Icons.person_outline),
                      _buildDetailItem('Full Name', data['customerName']),
                      _buildDetailItem('Email', data['customerEmail']),

                      const Divider(height: 40),

                      // --- EVENT SECTION ---
                      _buildHeader('Event Details', Icons.restaurant_menu),
                      _buildDetailItem('Package', data['packageName']),
                      _buildDetailItem('Date', dateStr),
                      _buildDetailItem('Time', timeStr),
                      _buildDetailItem('Guests', '${data['guests']} Pax'),

                      const Divider(height: 40),

                      // --- CUSTOMIZATIONS SECTION ---
                      _buildHeader('Customizations (Add-ons)', Icons.auto_awesome),
                      const SizedBox(height: 8),
                      if (selectedCustoms.isEmpty)
                        const Text("No add-ons selected", style: TextStyle(color: Colors.grey, fontSize: 13))
                      else
                        ...selectedCustoms.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("• ${item['name']}", style: const TextStyle(fontSize: 14)),
                              Text("RM ${item['price']}", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                            ],
                          ),
                        )).toList(),

                      const Divider(height: 40),

                      // --- PAYMENT SUMMARY ---
                      _buildHeader('Payment Summary', Icons.receipt_long),
                      _buildDetailItem('Price per Guest', 'RM ${data['pricePerGuest']}'),
                      _buildDetailItem('Customization Total', 'RM ${data['customizationTotal']}'),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(
                            'RM ${data['totalPrice'].toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: primaryPink,
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 40),

                      // --- STATUS SECTION ---
                      _buildHeader('Current Status', Icons.info_outline),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getStatusColor(data['status']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          (data['status'] ?? 'Pending').toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(data['status']),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: darkPink, size: 22),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: darkPink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, dynamic value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          Flexible(
            child: Text(
              value?.toString() ?? 'N/A',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Confirmed': return Colors.green;
      case 'Cancelled': return Colors.red;
      default: return Colors.orange;
    }
  }
}