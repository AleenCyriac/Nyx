import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignupPage extends StatefulWidget {
  final VoidCallback onLoginPressed;

  const SignupPage({super.key, required this.onLoginPressed });

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>{
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordCheckerController = TextEditingController();
  final TextEditingController _phoneNoController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final Color primaryBlue = const Color(0xFF003087);
  final Color backgroundBlue = const Color(0xFFDCE7FA);

  @override
  void dispose(){
    _userNameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _passwordCheckerController.dispose();
    _phoneNoController.dispose();
    super.dispose();
  }
  Future<void> signup() async {
    try {
      final response = await http.post(
        Uri.parse("http://localhost:3000/signup"),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
          "name": _userNameController.text.trim(),
          "conform_password":  _passwordCheckerController.text.trim(),
          "phone_no": _phoneNoController.text.trim(),
        }),
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Signup successful"),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"]),
          ),
        );
      }
    }
    catch(e){
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 850,
            height: 560,
            decoration: BoxDecoration(
              color: backgroundBlue,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// LEFT SIDE IMAGE
                Expanded(
                  flex: 1,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      bottomLeft: Radius.circular(24),
                    ),
                    child: Image.asset(
                      "assets/images/signup.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                /// RIGHT SIDE FORM
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 28,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Create Your Account",
                          style: TextStyle(
                            fontFamily: "PublicSans",
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Start chatting instantly.",
                          style: TextStyle(
                            fontFamily: "PublicSans",
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 18),

                        _buildTextField(
                          controller: _userNameController,
                          label: "UserName",
                        ),
                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _phoneNoController,
                          label: "Phone number",
                        ),
                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _emailController,
                          label: "Email",
                        ),
                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _passwordController,
                          label: "Password",
                          isPassword: true,
                          obscure: _obscurePassword,
                          onToggle: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                        ),
                        const SizedBox(height: 12),

                        _buildTextField(
                          controller: _passwordCheckerController,
                          label: "Confirm Password",
                          isPassword: true,
                          obscure: _obscureConfirmPassword,
                          onToggle: () => setState(() =>
                          _obscureConfirmPassword =
                          !_obscureConfirmPassword),
                        ),
                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: signup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(
                                fontFamily: "PublicSans",
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Already have an account?",
                              style: TextStyle(
                                fontFamily: "PublicSans",
                                fontSize: 13,
                              ),
                            ),
                            TextButton(
                              onPressed: widget.onLoginPressed,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                "Log In",
                                style: TextStyle(
                                  color: primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: "PublicSans",
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggle,
  }) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscure : false,
        style: const TextStyle(
          fontFamily: "PublicSans",
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          labelStyle: TextStyle(
            color: primaryBlue,
            fontFamily: "PublicSans",
            fontSize: 13,
          ),
          floatingLabelStyle:
          TextStyle(color: primaryBlue, fontFamily: "PublicSans"),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryBlue),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryBlue, width: 2),
          ),
          suffixIcon: isPassword
              ? IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: primaryBlue,
              size: 20,
            ),
            onPressed: onToggle,
          )
              : null,
        ),
      ),
    );
  }
}