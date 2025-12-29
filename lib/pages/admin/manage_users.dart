import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  State<ManageUsersPage> createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  bool _showMenu = false;
  String _searchQuery = '';
  String _selectedRole = 'All'; // ✅ Added for role filter

  // 🌸 MATCH LOGIN / REGISTER THEME
  static const Color bgLight = Color(0xFFFCE4EC);
  static const Color primaryPink = Color(0xFFF06292);
  static const Color darkPink = Color(0xFF880E4F);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🔥 DELETE USER (Firestore only)
  Future<void> _deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user: $e')),
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
        title: const Text('ADMIN  |  Manage Users'),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ALL USERS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkPink,
                  ),
                ),
                const SizedBox(height: 16),

                // ===== SEARCH & FILTER ROW =====
                Row(
                  children: [
                    // SEARCH BAR
                    Expanded(
                      flex: 2,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search user...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() => _searchQuery = value.toLowerCase());
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    // ✅ ROLE FILTER DROPDOWN
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedRole,
                            isExpanded: true,
                            items: ['All', 'Admin', 'Customer']
                                .map((role) => DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            ))
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedRole = value!);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ===== USER LIST =====
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('users')
                        .orderBy('createdAt', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('No users found'),
                        );
                      }

                      // ✅ COMBINED FILTER: Search + Role
                      final users = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name =
                        (data['fullName'] ?? '').toString().toLowerCase();
                        final email =
                        (data['email'] ?? '').toString().toLowerCase();
                        final role =
                        (data['role'] ?? 'customer').toString().toLowerCase();

                        final matchesSearch = name.contains(_searchQuery) ||
                            email.contains(_searchQuery);

                        final matchesRole = _selectedRole == 'All' ||
                            role == _selectedRole.toLowerCase();

                        return matchesSearch && matchesRole;
                      }).toList();

                      if (users.isEmpty) {
                        return const Center(child: Text("No users match your criteria"));
                      }

                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final doc = users[index];
                          final data =
                          doc.data() as Map<String, dynamic>;

                          return UserCard(
                            name: data['fullName'] ?? '',
                            email: data['email'] ?? '',
                            role: data['role'] ?? 'customer',
                            onDelete: () {
                              _deleteUser(doc.id);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _NavItem(
                        'Dashboard',
                        Icons.dashboard,
                        onTap: () => context.go('/admin'),
                      ),
                      _NavItem(
                        'Manage Packages',
                        Icons.restaurant_menu,
                        onTap: () => context.go('/admin/packages'),
                      ),
                      _NavItem(
                        'Manage Users',
                        Icons.people,
                        active: true,
                        onTap: () => context.go('/admin/users'),
                      ),
                      _NavItem(
                        'Manage Reservations',
                        Icons.event,
                        onTap: () =>
                            context.go('/admin/reservations'),
                      ),
                      const Divider(color: Colors.white54),
                      _NavItem(
                        'Logout',
                        Icons.logout,
                        onTap: () => context.go('/login'),
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

// ================= USER CARD =================
class UserCard extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final VoidCallback onDelete;

  const UserCard({
    super.key,
    required this.name,
    required this.email,
    required this.role,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFCE4EC),
          child: Icon(
            Icons.person,
            color: role == 'admin'
                ? Colors.purple
                : const Color(0xFFF06292),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(email),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: Text(
                role.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              backgroundColor:
              role == 'admin' ? Colors.purple : Colors.grey,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: onDelete,
            ),
          ],
        ),
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
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: onTap,
    );
  }
}