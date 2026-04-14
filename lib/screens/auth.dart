import 'dart:io';
import 'package:chat_app/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
  final phone = TextEditingController();

  File? _selectedImage;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb 
            ? null 
            : 'io.supabase.flutter://google-auth',
      );
      
      // Note: The redirection and session handling is managed by Supabase.
      // After successful redirection back to the app, the Auth state change 
      // will be caught by the Supabase Auth listener (if set up in main.dart).
      // Profile sync logic should be handled in a listener or post-login check.
      
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red.shade400),
      );
    } catch (error) {
      if (kDebugMode) print(error);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google Sign-In failed"), backgroundColor: Colors.red.shade400),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    setState(() => _isLoading = true);

    final enteredEmail = email.text.trim();
    final enteredPassword = password.text.trim();
    final enteredName = name.text.trim();
    final enteredPhone = phone.text.trim();

    try {
      if (selectedTab == 0) {
        await supabase.auth.signInWithPassword(
          email: enteredEmail,
          password: enteredPassword,
        );
      } else {
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

        await supabase.storage.from('avatars').upload(
          imagePath,
          _selectedImage!,
          fileOptions: const FileOptions(upsert: true),
        );

        final imageUrl = supabase.storage.from('avatars').getPublicUrl(imagePath);

        await supabase.from('users').insert({
          'id': userId,
          'username': enteredName,
          'email': enteredEmail,
          'phone': enteredPhone.isNotEmpty ? enteredPhone : null,
          'image_url': imageUrl,
          'about': 'Hey there! I am using Chatify',
          'last_seen': DateTime.now().toIso8601String(),
        });

        if (signUpResponse.session == null) {
          await supabase.auth.signInWithPassword(
            email: enteredEmail,
            password: enteredPassword,
          );
        }
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.red.shade400,
        ),
      );
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
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(top: 60, bottom: 40),
              child: Column(
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Chatify",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedTab == 0 ? "Welcome back" : "Create an account",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Tab toggle
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _tabButton("Login", 0),
                              const SizedBox(width: 4),
                              _tabButton("Sign up", 1),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      selectedTab == 0 ? _buildLogin() : _buildSignup(),

                      const SizedBox(height: 32),
                      // Divider
                      SizedBox(
                        width: double.infinity,
                        child: Row(
                          children: [
                            Expanded(child: Divider(color: AppColors.border)),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "or continue with",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: AppColors.border)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Google Button
                      _googleButton(),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String text, int index) {
    final isSelected = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogin() {
    return Column(
      children: [
        _input("Email", email, false, Icons.email_rounded),
        const SizedBox(height: 16),
        _input("Password", password, obscure, Icons.lock_rounded, isPassword: true),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: const Text(
              "Forgot password?",
              style: TextStyle(
                color: AppColors.textPrimary, 
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
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
        const SizedBox(height: 32),
        _input("Full Name", name, false, Icons.person_rounded),
        const SizedBox(height: 16),
        _input("Email Address", email, false, Icons.email_rounded),
        const SizedBox(height: 16),
        _input("Phone (optional)", phone, false, Icons.phone_rounded),
        const SizedBox(height: 16),
        _input("Password", password, obscure, Icons.lock_rounded, isPassword: true),
        const SizedBox(height: 16),
        _input("Confirm Password", confirmPassword, obscureConfirm, Icons.lock_rounded, isPassword: true, isConfirm: true),
        const SizedBox(height: 32),
        _button("Create Account"),
      ],
    );
  }

  Widget _input(
    String label,
    TextEditingController controller,
    bool obscureText,
    IconData icon, {
    bool isPassword = false,
    bool isConfirm = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: label.contains("Email")
              ? TextInputType.emailAddress
              : label.contains("Phone")
                  ? TextInputType.phone
                  : TextInputType.text,
          validator: (value) {
            if (label.contains("optional")) return null;
            if (value == null || value.trim().isEmpty) {
              return "$label is required";
            }
            if (label == "Password" && value.length < 6) {
              return "Minimum 6 characters required";
            }
            if (isConfirm && value != password.text) {
              return "Passwords do not match";
            }
            return null;
          },
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: "Enter your ${label.toLowerCase()}",
            hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            prefixIcon: Icon(icon, color: AppColors.secondary, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isConfirm) {
                          obscureConfirm = !obscureConfirm;
                        } else {
                          obscure = !obscure;
                        }
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade200, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _button(String text) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
      ),
    );
  }

  Widget _googleButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _signInWithGoogle,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: AppColors.border),
          foregroundColor: AppColors.textPrimary,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
              height: 20,
              width: 20,
              errorBuilder: (_, __, ___) => const Icon(Icons.account_circle_rounded, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                "Continue with Google",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}