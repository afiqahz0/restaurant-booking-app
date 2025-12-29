import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart'; // ✅ Added

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  // 🌸 THEME COLORS
  final Color kBackgroundColor = const Color(0xFFFCE4EC);
  final Color kPrimaryColor = const Color(0xFFF06292);
  final Color kTextColor = const Color(0xFF880E4F);
  final Color kCardColor = Colors.white;

  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      drawer: _buildDrawer(context),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: kPrimaryColor),
        title: Text(
          "Maestro’s Table",
          style: TextStyle(
            color: kPrimaryColor,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== GREETING =====
            Text(
              "Welcome back 👋",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),

            const SizedBox(height: 20),

            _buildMyReservationBox(context),

            const SizedBox(height: 30),

            // ===== AVAILABLE PACKAGES HEADER =====
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Available Packages",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kTextColor,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/browse'),
                  child: Text(
                    "See All",
                    style: TextStyle(
                      color: kPrimaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ===== PACKAGES GRID (LIMIT 2) =====
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('packages')
                  .where('isActive', isEqualTo: true)
                  .limit(4)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text("No packages available");
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final pkg = snapshot.data!.docs[index];
                    final data = pkg.data() as Map<String, dynamic>;

                    return _PackageCard(
                      name: data['packageName'] ?? 'Package',
                      price: data['pricePerGuest'] ?? 0,
                      imageUrl: data['imageUrl'] ?? '', // ✅ PASS IMAGE URL
                      onTap: () {
                        context.push('/user/package/${pkg.id}');
                      },
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ================= MY RESERVATION BOX (UNCHANGED) =================
  Widget _buildMyReservationBox(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('reservations')
              .where('userId', isEqualTo: user?.uid)
              .snapshots(),
          builder: (context, snapshot) {
            final count = snapshot.hasData ? snapshot.data!.docs.length : 0;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "My Reservations",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$count reservation(s)",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => context.push('/reservations'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("View"),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ================= DRAWER (UNCHANGED) =================
  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: kCardColor,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: kPrimaryColor),
            accountName: Text(user?.displayName ?? "User",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(user?.email ?? ""),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFFF06292)),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home, color: kPrimaryColor),
            title: const Text("Home"),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(Icons.restaurant_menu, color: kPrimaryColor),
            title: const Text("Browse Menu"),
            onTap: () {
              Navigator.pop(context);
              context.push('/browse');
            },
          ),
          ListTile(
            leading: Icon(Icons.history, color: kPrimaryColor),
            title: const Text("My Reservations"),
            onTap: () {
              Navigator.pop(context);
              context.push('/reservations');
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              FirebaseAuth.instance.signOut();
              context.go('/login');
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ================= UPDATED PACKAGE CARD =================
class _PackageCard extends StatelessWidget {
  final String name;
  final num price;
  final String imageUrl; // ✅ Added
  final VoidCallback onTap;

  const _PackageCard({
    required this.name,
    required this.price,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE4EC),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: imageUrl.isEmpty
                      ? const Icon(Icons.restaurant_menu, size: 40, color: Color(0xFFF06292))
                      : CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.broken_image,
                      size: 30,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "RM $price / guest",
                    style: const TextStyle(
                      color: Color(0xFFF06292),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}