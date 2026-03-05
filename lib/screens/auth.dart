import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/user_image_picker.dart';

final supabase = Supabase.instance.client;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  int selectedTab = 0;
  bool obscure = true;
  bool obscureConfirm = true;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();

  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final name = TextEditingController();

  File? _selectedImage;

  Future<void> _submit() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    setState(() => _isLoading = true);

    final enteredEmail = email.text.trim();
    final enteredPassword = password.text.trim();
    final enteredName = name.text.trim();

    try {
      if (selectedTab == 0) {
        // LOGIN
        await supabase.auth.signInWithPassword(
          email: enteredEmail,
          password: enteredPassword,
        );
      } else {
        // SIGNUP

        if (_selectedImage == null) {
          throw Exception("Please select a profile image.");
        }

        final signUpResponse = await supabase.auth.signUp(
          email: enteredEmail,
          password: enteredPassword,
        );

        if (signUpResponse.user == null) {
          throw Exception("Signup failed");
        }

        final userId = signUpResponse.user!.id;

final imagePath = "$userId.jpg";

await supabase.storage
    .from('avatars')
    .upload(
      imagePath,
      _selectedImage!,
      fileOptions: const FileOptions(upsert: true),
    );

final imageUrl =
    supabase.storage.from('avatars').getPublicUrl(imagePath);

await supabase.from('users').insert({
  'id': userId,
  'username': enteredName,
  'email': enteredEmail,
  'image_url': imageUrl,
});

        debugPrint("User row inserted. Now signing in...");

        // Sign in AFTER data is committed — this triggers navigation
        if (signUpResponse.session == null) {
          await supabase.auth.signInWithPassword(
            email: enteredEmail,
            password: enteredPassword,
          );
        }
      }
    } on AuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }

    if (!mounted) return;

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),

                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.chat_bubble,
                    color: Colors.white,
                    size: 36,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Chatify",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 40),

                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () =>
                                    setState(() => selectedTab = 0),
                                style: TextButton.styleFrom(
                                  backgroundColor: selectedTab == 0
                                      ? Colors.black
                                      : Colors.transparent,
                                ),
                                child: Text(
                                  "Login",
                                  style: TextStyle(
                                    color: selectedTab == 0
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: TextButton(
                                onPressed: () =>
                                    setState(() => selectedTab = 1),
                                style: TextButton.styleFrom(
                                  backgroundColor: selectedTab == 1
                                      ? Colors.black
                                      : Colors.transparent,
                                ),
                                child: Text(
                                  "Sign up",
                                  style: TextStyle(
                                    color: selectedTab == 1
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        selectedTab == 0 ? _buildLogin() : _buildSignup(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogin() {
    return Column(
      children: [
        _input("Email", email, false),
        const SizedBox(height: 20),
        _input("Password", password, obscure),
        const SizedBox(height: 30),
        _button("Login"),
      ],
    );
  }

  Widget _buildSignup() {
    return Column(
      children: [
        UserImagePicker(
          onPickImage: (pickedImage) {
            _selectedImage = pickedImage;
          },
        ),

        const SizedBox(height: 20),

        _input("Email", email, false),

        const SizedBox(height: 20),

        _input("Name", name, false),

        const SizedBox(height: 20),

        _input("Password", password, obscure),

        const SizedBox(height: 20),

        _input("Confirm Password", confirmPassword, obscureConfirm),

        const SizedBox(height: 30),

        _button("Create Account"),
      ],
    );
  }

  Widget _input(
    String label,
    TextEditingController controller,
    bool obscureText,
  ) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "$label is required";
        }

        if (label == "Password" && value.length < 6) {
          return "Minimum 6 characters required";
        }

        if (label == "Confirm Password" && value != password.text) {
          return "Passwords do not match";
        }

        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _button(String text) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}