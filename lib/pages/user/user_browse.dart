import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart'; // ✅ Added

class UserBrowsePage extends StatefulWidget {
  const UserBrowsePage({super.key});

  @override
  State<UserBrowsePage> createState() => _UserBrowsePageState();
}

class _UserBrowsePageState extends State<UserBrowsePage> {
  // 🌸 THEME
  static const Color bgLight = Color(0xFFFCE4EC);
  static const Color primaryPink = Color(0xFFF06292);
  static const Color darkPink = Color(0xFF880E4F);

  String searchQuery = '';
  String selectedMealType = 'All';

  final List<String> mealTypes = [
    'All',
    'Breakfast',
    'Lunch',
    'High Tea',
    'Dinner',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: bgLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: darkPink),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text(
          "Browse Packages",
          style: TextStyle(color: darkPink, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔍 SEARCH BAR
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) => setState(() => searchQuery = value),
                decoration: InputDecoration(
                  hintText: "Search packages...",
                  prefixIcon: const Icon(Icons.search, color: primaryPink),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // 🍽 MEAL TYPE FILTER
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedMealType,
                  isExpanded: true,
                  icon: const Icon(Icons.filter_list, color: primaryPink),
                  items: mealTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) => setState(() => selectedMealType = value!),
                ),
              ),
            ),

            // 📦 PACKAGE GRID
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('packages')
                    .where('isActive', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Center(child: Text("Error loading data"));
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Local Filtering logic
                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['packageName'] ?? '').toString().toLowerCase();
                    final mealType = (data['mealType'] ?? '').toString();

                    final matchesSearch = name.contains(searchQuery.toLowerCase());
                    final matchesMeal = selectedMealType == 'All' || mealType == selectedMealType;

                    return matchesSearch && matchesMeal;
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(child: Text("No matching packages found"));
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 300,
                      childAspectRatio: 0.7, // Adjusted for better image height
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final pkg = docs[index];
                      final data = pkg.data() as Map<String, dynamic>;

                      return _PackageCard(
                        name: data['packageName'] ?? 'Unnamed',
                        price: data['pricePerGuest'] ?? 0,
                        mealType: data['mealType'] ?? '',
                        imageUrl: data['imageUrl'] ?? '', // ✅ PASS URL
                        onTap: () => context.push('/user/package/${pkg.id}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= UPDATED PACKAGE CARD =================
class _PackageCard extends StatelessWidget {
  final String name;
  final num price;
  final String mealType;
  final String imageUrl; // ✅ Added
  final VoidCallback onTap;

  const _PackageCard({
    required this.name,
    required this.price,
    required this.mealType,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE SECTION
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFCE4EC),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: imageUrl.isEmpty
                          ? const Icon(Icons.restaurant_menu, size: 48, color: Color(0xFFF06292))
                          : CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                  // MEAL TYPE TAG
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        mealType,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF06292),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // TEXT SECTION
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF880E4F),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "RM ${price.toStringAsFixed(0)} / guest",
                    style: const TextStyle(
                      color: Color(0xFFF06292),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
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