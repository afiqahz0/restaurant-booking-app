import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ManagePackagesPage extends StatefulWidget {
  const ManagePackagesPage({super.key});

  @override
  State<ManagePackagesPage> createState() => _ManagePackagesPageState();
}

class _ManagePackagesPageState extends State<ManagePackagesPage> {
  bool _showMenu = false;

  //  FILTER & SEARCH STATES
  String _selectedMealType = 'All';
  String _selectedStatus = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  static const Color bgLight = Color(0xFFFCE4EC);
  static const Color primaryPink = Color(0xFFF06292);
  static const Color darkPink = Color(0xFF880E4F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: primaryPink,
        title: const Text('ADMIN  |  Manage Packages'),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => setState(() => _showMenu = !_showMenu),
        ),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // HEADER & ADD BUTTON
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'MENU PACKAGES',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkPink,
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryPink,
                      ),
                      onPressed: () => context.go('/admin/packages/add'),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Package'),
                    ),
                  ],
                ),

                const SizedBox(height: 15),

                // SEARCH BAR
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Search by package name...",
                    prefixIcon: const Icon(Icons.search, color: primaryPink),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // FILTER SECTION
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedMealType,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: ['All', 'Breakfast', 'Lunch', 'High Tea', 'Dinner']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedMealType = val!),
                        ),
                      ),
                      const VerticalDivider(),
                      Expanded(
                        child: DropdownButton<String>(
                          value: _selectedStatus,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: ['All', 'Active', 'Hidden']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13))))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedStatus = val!),
                        ),
                      ),
                      const Icon(Icons.filter_list, color: primaryPink),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                // ===== FIRESTORE LIST =====
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('packages')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No packages found'));
                      }

                      // COMBINED FILTER & SEARCH LOGIC
                      final filteredDocs = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['packageName'] ?? '').toString().toLowerCase();

                        // Search Check
                        final matchesSearch = name.contains(_searchQuery);

                        // Meal Type check
                        final matchesMeal = _selectedMealType == 'All' ||
                            data['mealType'] == _selectedMealType;

                        // Status check
                        bool matchesStatus = true;
                        if (_selectedStatus == 'Active') matchesStatus = data['isActive'] == true;
                        if (_selectedStatus == 'Hidden') matchesStatus = data['isActive'] == false;

                        return matchesSearch && matchesMeal && matchesStatus;
                      }).toList();

                      if (filteredDocs.isEmpty) {
                        return const Center(child: Text('No matching results'));
                      }

                      return ListView(
                        children: filteredDocs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;

                          return PackageRowCard(
                            name: data['packageName'] ?? 'Unnamed',
                            imageUrl: data['imageUrl'] ?? '',
                            mealType: data['mealType'] ?? '-',
                            price: (data['pricePerGuest'] as num).toDouble(),
                            isActive: data['isActive'] ?? true,
                            onEdit: () {
                              context.go('/admin/packages/edit/${doc.id}');
                            },
                            onToggle: () async {
                              await FirebaseFirestore.instance
                                  .collection('packages')
                                  .doc(doc.id)
                                  .update({
                                'isActive': !(data['isActive'] ?? true),
                              });
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // SIDEBAR (Remains unchanged)
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
                      _NavItem('Dashboard', Icons.dashboard, onTap: () => context.go('/admin')),
                      _NavItem('Manage Packages', Icons.restaurant_menu, active: true, onTap: () => context.go('/admin/packages')),
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

// ================= CORRECTED PACKAGE CARD =================
class PackageRowCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String mealType;
  final double price;
  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onToggle;

  const PackageRowCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.mealType,
    required this.price,
    required this.isActive,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 90,
              height: 90,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFFCE4EC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: imageUrl.isEmpty
                  ? const Icon(Icons.restaurant_menu, size: 36, color: Color(0xFFF06292))
                  : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(mealType, style: const TextStyle(fontSize: 12, color: Color(0xFFF06292), fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text('RM ${price.toStringAsFixed(0)} / guest', style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green[50] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Hidden',
                      style: TextStyle(fontSize: 11, color: isActive ? Colors.green[700] : Colors.grey[700], fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent), onPressed: onEdit),
                IconButton(
                  icon: Icon(isActive ? Icons.visibility : Icons.visibility_off, color: isActive ? const Color(0xFFF06292) : Colors.grey),
                  onPressed: onToggle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// SideNavItem code remains same as before...
class _NavItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _NavItem(this.title, this.icon, {this.active = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: TextStyle(color: Colors.white, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      onTap: onTap,
    );
  }
}