import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState ();
}

class _AuthScreenState extends State<AuthScreen> {
  int selectedTab = 0;
  bool obscure = true;
  bool obscureConfirm = true;

  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final name = TextEditingController();

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

                /// Logo
                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.chat_bubble,
                      color: Colors.white, size: 36),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Chatify",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Connect instantly with your friends",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 40),

                /// Card Container
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [

                      /// Segmented Control
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            _buildTab("Login", 0),
                            _buildTab("Create Account", 1),
                          ],
                        ),
                      ),

                      const SizedBox(height: 35),

                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: selectedTab == 0
                            ? _buildLogin()
                            : _buildSignup(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String text, int index) {
    bool isSelected = selectedTab == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogin() {
    return Column(
      key: const ValueKey("login"),
      children: [
        _input("Email", email, false),
        const SizedBox(height: 20),
        _input("Password", password, obscure,
            suffix: IconButton(
              icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => obscure = !obscure),
            )),
        const SizedBox(height: 30),
        _button("Login"),
      ],
    );
  }

  Widget _buildSignup() {
    return Column(
      key: const ValueKey("signup"),
      children: [
        _input("Full Name", name, false),
        const SizedBox(height: 20),
        _input("Email", email, false),
        const SizedBox(height: 20),
        _input("Password", password, obscure,
            suffix: IconButton(
              icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => obscure = !obscure),
            )),
        const SizedBox(height: 20),
        _input("Confirm Password", confirmPassword, obscureConfirm,
            suffix: IconButton(
              icon: Icon(obscureConfirm
                  ? Icons.visibility_off
                  : Icons.visibility),
              onPressed: () =>
                  setState(() => obscureConfirm = !obscureConfirm),
            )),
        const SizedBox(height: 30),
        _button("Create Account"),
      ],
    );
  }

  Widget _input(String label, TextEditingController controller,
      bool obscureText,
      {Widget? suffix}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        suffixIcon: suffix,
      ),
    );
  }

  Widget _button(String text) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.white),
        ),
      ),
    );
  }
}