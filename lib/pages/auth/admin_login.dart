import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  bool _isPasswordVisible = false;
  bool _loading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 🌸 THEME
  final Color kBackgroundColor = const Color(0xFFFCE4EC);
  final Color kPrimaryPink = const Color(0xFFF06292);
  final Color kPrimaryDark = const Color(0xFF880E4F);
  final Color kInputFill = Colors.white;

  Future<void> _adminLogin() async {
    try {
      setState(() => _loading = true);

      // 1️⃣ Firebase Auth login
      final credential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = credential.user!.uid;

      // 2️⃣ Fetch user role from Firestore
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        await _auth.signOut();
        throw 'Account not found.';
      }

      final role = userDoc['role'];

      // 3️⃣ Check admin role
      if (role != 'admin') {
        await _auth.signOut();
        throw 'Access denied. Admins only.';
      }

      // 4️⃣ Go to admin dashboard
      if (mounted) {
        context.go('/admin');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: kPrimaryPink),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Admin Login",
          style: TextStyle(
            color: kPrimaryPink,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "ADMIN ACCESS",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: kPrimaryDark,
                ),
              ),
              const SizedBox(height: 40),

              // EMAIL
              const Text("Email", style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: _inputDecoration("admin@email.com", Icons.email),
              ),
              const SizedBox(height: 24),

              // PASSWORD
              const Text("Password", style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: _inputDecoration("Enter password", Icons.lock).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                      color: Colors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // LOGIN BUTTON
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _loading ? null : _adminLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryPink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _loading ? "Checking..." : "LOGIN AS ADMIN",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // BACK TO USER LOGIN
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  "Back to User Login",
                  style: TextStyle(color: kPrimaryDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.grey),
      hintText: hint,
      filled: true,
      fillColor: kInputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
    );
  }
}
