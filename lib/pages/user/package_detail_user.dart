import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserPackageDetailPage extends StatelessWidget {
  final String packageId;

  const UserPackageDetailPage({
    super.key,
    required this.packageId,
  });

  static const Color bgLight = Color(0xFFFCE4EC);
  static const Color primaryPink = Color(0xFFF06292);
  static const Color darkPink = Color(0xFF880E4F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      extendBodyBehindAppBar: true,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: CircleAvatar(
            backgroundColor: Colors.black26,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('packages')
            .doc(packageId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Package not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String imageUrl = data['imageUrl'] ?? '';

          return Column(
            children: [
              Container(
                height: 320,
                width: double.infinity,
                decoration: const BoxDecoration(color: bgLight),
                child: imageUrl.isEmpty
                    ? const Center(
                  child: Icon(Icons.restaurant_menu, size: 100, color: primaryPink),
                )
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

              Expanded(
                child: Container(
                  width: double.infinity,
                  transform: Matrix4.translationValues(0, -30, 0),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(35),
                      topRight: Radius.circular(35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: bgLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              data['mealType'] ?? 'Package',
                              style: const TextStyle(
                                color: primaryPink,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            "RM ${data['pricePerGuest']} / guest",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: primaryPink,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Text(
                        data['packageName'] ?? 'Package Name',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: darkPink,
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        "About this package",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            data['description'] ?? 'No description available.',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                              height: 1.6,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      ElevatedButton(
                        onPressed: () {
                          context.push('/booking/$packageId');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkPink,
                          minimumSize: const Size(double.infinity, 60),
                          elevation: 4,
                          shadowColor: darkPink.withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          "PROCEED TO BOOKING",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1.1,
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