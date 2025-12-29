import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _loading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // THEME
  final Color kBackgroundColor = const Color(0xFFFCE4EC);
  final Color kPrimaryPink = const Color(0xFFF06292);
  final Color kPrimaryDark = const Color(0xFF880E4F);
  final Color kInputFill = Colors.white;

  Future<void> _login() async {
    try {
      setState(() => _loading = true);

      // 1️⃣ Firebase Auth login
      final credential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = credential.user!.uid;

      // 2️⃣ Fetch user role from Firestore
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Account not registered',
        );
      }

      final role = doc['role'];

      // 🚫 BLOCK ADMIN LOGIN HERE
      if (role != 'customer') {
        await _auth.signOut();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This account is not a user account. Please use Admin Login.',
            ),
          ),
        );
        return;
      }

      // ✅ USER ONLY
      if (mounted) {
        context.go('/dashboard');
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';

      if (e.code == 'user-not-found') {
        message = 'Account not registered. Please sign up first.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
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
          onPressed: () => context.go('/'),
        ),
        title: Text(
          "Maestro's Table",
          style: TextStyle(color: kPrimaryPink, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => context.push('/register'),
            child: Text("Sign Up",
                style: TextStyle(
                    color: kPrimaryPink, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "LOGIN",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: kPrimaryDark,
                ),
              ),
              const SizedBox(height: 40),

              const Text("Email Address"),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: _inputDecoration("Enter your email", Icons.email),
              ),

              const SizedBox(height: 24),
              const Text("Password"),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: _inputDecoration(
                  "Enter your password",
                  Icons.lock,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryPink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _loading ? "Logging in..." : "LOG IN",
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: TextButton(
                  onPressed: () {
                    context.push('/admin-login');
                  },
                  child: Text(
                    "Login as Admin",
                    style: TextStyle(
                      color: kPrimaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  GestureDetector(
                    onTap: () => context.push('/register'),
                    child: Text(
                      "Sign Up",
                      style: TextStyle(
                        color: kPrimaryPink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              )
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
