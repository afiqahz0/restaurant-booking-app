import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart'; //

class PackageDetailPage extends StatelessWidget {
  final String packageId;

  const PackageDetailPage({
    super.key,
    required this.packageId,
  });

  // THEME
  static const Color bgPink = Color(0xFFFCE4EC);
  static const Color primaryPink = Color(0xFFF06292);
  static const Color burgundy = Color(0xFF880E4F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgPink,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Transparent to see the image
        elevation: 0,
        iconTheme: const IconThemeData(color: burgundy),
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('packages')
            .doc(packageId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Package not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String name = data['packageName'] ?? 'Package';
          final String description = data['description'] ?? '';
          final num price = data['pricePerGuest'] ?? 0;
          final String imageUrl = data['imageUrl'] ?? '';

          return Column(
            children: [
              // ================= HERO IMAGE =================
              Container(
                height: 300,
                width: double.infinity,
                decoration: const BoxDecoration(color: bgPink),
                child: imageUrl.isEmpty
                    ? const Icon(Icons.restaurant_menu, size: 100, color: primaryPink)
                    : CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.broken_image,
                    size: 100,
                    color: Colors.grey,
                  ),
                ),
              ),

              // ================= DETAILS CONTAINER =================
              Expanded(
                child: Container(
                  width: double.infinity,
                  // Pull the container up slightly to overlap the image
                  transform: Matrix4.translationValues(0, -30, 0),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: bgPink,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              data['mealType'] ?? 'Package',
                              style: const TextStyle(color: primaryPink, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            "ID: ${packageId.substring(0, 5)}...", // Shortened ID
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: burgundy,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        "RM ${price.toStringAsFixed(2)} / guest",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryPink,
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        "Description",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: burgundy,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            description,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ================= BOOK BUTTON =================
                      ElevatedButton(
                        onPressed: () => context.push('/login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: burgundy,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          "BOOK THIS NOW",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}