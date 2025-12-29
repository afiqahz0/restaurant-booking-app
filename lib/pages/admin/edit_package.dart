import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart'; //

class EditPackagePage extends StatefulWidget {
  final String packageId;

  const EditPackagePage({
    super.key,
    required this.packageId,
  });

  @override
  State<EditPackagePage> createState() => _EditPackagePageState();
}

class _EditPackagePageState extends State<EditPackagePage> {
  bool _loading = true;
  bool _isSaving = false;

  // THEME
  static const Color primaryPink = Color(0xFFF06292);
  static const Color bgLight = Color(0xFFFCE4EC);
  static const Color darkText = Color(0xFF880E4F);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController imageUrlController = TextEditingController();

  // MEAL TYPE
  String selectedMealType = 'Breakfast';
  final List<String> mealTypes = [
    'Breakfast',
    'Lunch',
    'High Tea',
    'Dinner',
  ];

  @override
  void initState() {
    super.initState();
    _loadPackage();
  }

  // ================= LOAD PACKAGE =================
  Future<void> _loadPackage() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('packages')
          .doc(widget.packageId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          nameController.text = data['packageName'] ?? '';
          descController.text = data['description'] ?? '';
          priceController.text = (data['pricePerGuest'] ?? '').toString();
          imageUrlController.text = data['imageUrl'] ?? ''; //
          selectedMealType = data['mealType'] ?? 'Breakfast';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load package')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  // ================= UPDATE PACKAGE =================
  Future<void> _updatePackage() async {
    if (nameController.text.isEmpty ||
        descController.text.isEmpty ||
        priceController.text.isEmpty ||
        imageUrlController.text.isEmpty) { //
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      setState(() => _isSaving = true);
      await FirebaseFirestore.instance
          .collection('packages')
          .doc(widget.packageId)
          .update({
        'packageName': nameController.text.trim(),
        'description': descController.text.trim(),
        'pricePerGuest': double.parse(priceController.text.trim()),
        'imageUrl': imageUrlController.text.trim(), //
        'mealType': selectedMealType,
        'updatedAt': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Package updated successfully')),
        );
        context.go('/admin/packages');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update package')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: primaryPink,
        title: const Text('ADMIN | Edit Package'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin/packages'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'EDIT PACKAGE DETAILS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),
            const SizedBox(height: 20),

            // 🖼 IMAGE PREVIEW (Consistent with Add Page)
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  )
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrlController.text.trim().isEmpty
                  ? Center(
                child: Icon(Icons.image,
                    size: 60, color: Colors.grey[400]),
              )
                  : CachedNetworkImage(
                imageUrl: imageUrlController.text.trim(),
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) =>
                const Icon(Icons.broken_image, color: Colors.red),
              ),
            ),
            const SizedBox(height: 16),

            // IMAGE URL INPUT
            TextField(
              controller: imageUrlController,
              onChanged: (value) => setState(() {}), // Refresh preview
              decoration: const InputDecoration(
                labelText: 'Image URL',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // PACKAGE NAME
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Package Name',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // DESCRIPTION
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // PRICE & MEAL TYPE ROW
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Price (RM)',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedMealType,
                    decoration: const InputDecoration(
                      labelText: 'Meal Type',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: mealTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => selectedMealType = value!),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // UPDATE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkText,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isSaving ? null : _updatePackage,
                child: Text(
                  _isSaving ? 'SAVING CHANGES...' : 'UPDATE PACKAGE',
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}