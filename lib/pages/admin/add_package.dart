import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AddPackagePage extends StatefulWidget {
  const AddPackagePage({super.key});

  @override
  State<AddPackagePage> createState() => _AddPackagePageState();
}

class _AddPackagePageState extends State<AddPackagePage> {
  bool _loading = false;

  // THEME
  final Color bgLight = const Color(0xFFFCE4EC);
  final Color primaryPink = const Color(0xFFF06292);
  final Color darkPink = const Color(0xFF880E4F);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // MEAL TYPE
  String selectedMealType = 'Breakfast';
  final List<String> mealTypes = [
    'Breakfast',
    'Lunch',
    'High Tea',
    'Dinner',
  ];

  // ================= SAVE PACKAGE =================
  Future<void> _savePackage() async {
    if (nameController.text.isEmpty ||
        descController.text.isEmpty ||
        priceController.text.isEmpty ||
        imageUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      setState(() => _loading = true);

      await firestore.collection('packages').add({
        'packageName': nameController.text.trim(),
        'description': descController.text.trim(),
        'pricePerGuest': double.parse(priceController.text.trim()),
        'mealType': selectedMealType,
        'imageUrl': imageUrlController.text.trim(),
        'isActive': true,
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Package added successfully')),
      );

      context.go('/admin/packages');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add package: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,

      appBar: AppBar(
        backgroundColor: primaryPink,
        title: const Text('ADMIN | Add Menu Package'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/packages'),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              'ADD NEW PACKAGE',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkPink,
              ),
            ),
            const SizedBox(height: 20),

// IMAGE PREVIEW
            Container(
              height: 160,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: imageUrlController.text.trim().isEmpty
                  ? Center(
                child: Icon(Icons.image, size: 60, color: Colors.grey[400]),
              )
                  : CachedNetworkImage(
                imageUrl: imageUrlController.text.trim(),
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.red),
                    Text("Invalid Image URL", style: TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // IMAGE URL INPUT
            TextField(
              controller: imageUrlController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Image URL (Public)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Package Name',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price / Guest (RM)',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: selectedMealType,
              decoration: const InputDecoration(
                labelText: 'Meal Type',
                border: OutlineInputBorder(),
              ),
              items: mealTypes
                  .map(
                    (type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                ),
              )
                  .toList(),
              onChanged: (value) =>
                  setState(() => selectedMealType = value!),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPink,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _loading ? null : _savePackage,
              child: Text(
                _loading ? 'Saving...' : 'SAVE PACKAGE',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
