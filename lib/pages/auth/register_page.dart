import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // ================= STATE =================
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _loading = false;
  String _selectedRole = 'Customer';

  // ================= CONTROLLERS =================
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();
  final TextEditingController _adminAuthController =
  TextEditingController();

  // ================= ADMIN SECURITY =================
  static const String ADMIN_AUTH_PASSWORD = "saythename";

  // ================= FIREBASE =================
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================= THEME =================
  final Color kBackgroundColor = const Color(0xFFFCE4EC);
  final Color kPrimaryDark = const Color(0xFF2C2C3E);
  final Color kAccentPink = const Color(0xFFEC407A);
  final Color kInputFill = Colors.white;

  // ================= REGISTER LOGIC =================
  Future<void> _register() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    // Admin authentication check
    if (_selectedRole == 'Admin' &&
        _adminAuthController.text.trim() != ADMIN_AUTH_PASSWORD) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid admin authentication password"),
        ),
      );
      return;
    }

    try {
      setState(() => _loading = true);

      // Firebase Auth
      final userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;

      // Firestore user record
      await _firestore.collection('users').doc(uid).set({
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole.toLowerCase(), // admin / customer
        'createdAt': Timestamp.now(),
      });

      // Redirect
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Registration successful! Please login."),
          ),
        );
        context.go('/login');
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Registration failed')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: kPrimaryDark),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Create Account",
          style: TextStyle(color: kPrimaryDark, fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "MAESTRO'S TABLE",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: kPrimaryDark,
                ),
              ),
              const SizedBox(height: 30),

              _buildLabel("Full Name"),
              _buildTextField(
                controller: _nameController,
                hint: "Full Name",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),

              _buildLabel("Email Address"),
              _buildTextField(
                controller: _emailController,
                hint: "email",
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 20),

              _buildLabel("Register as"),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: kInputFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    isExpanded: true,
                    icon: Icon(Icons.arrow_drop_down, color: kAccentPink),
                    items: const ['Customer', 'Admin']
                        .map(
                          (role) => DropdownMenuItem(
                        value: role,
                        child: Text(role),
                      ),
                    )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedRole = value!),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ADMIN AUTH FIELD
              if (_selectedRole == 'Admin') ...[
                _buildLabel("Admin Authentication Password"),
                TextField(
                  controller: _adminAuthController,
                  obscureText: true,
                  decoration: _inputDecoration(
                    "Enter admin authentication password",
                    Icons.security,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              _buildLabel("Password"),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: _inputDecoration(
                  "Enter password",
                  Icons.lock_outline,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _buildLabel("Confirm Password"),
              TextField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: _inputDecoration(
                  "Re-enter password",
                  Icons.lock_outline,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() =>
                    _isConfirmPasswordVisible =
                    !_isConfirmPasswordVisible),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _loading ? "Creating Account..." : "SIGN UP",
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Already have an account? ",
                      style: TextStyle(color: Colors.grey[600])),
                  GestureDetector(
                    onTap: () => context.push('/login'),
                    child: Text(
                      "Log In",
                      style: TextStyle(
                        color: kAccentPink,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= HELPERS =================
  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child:
    Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration(hint, icon),
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
