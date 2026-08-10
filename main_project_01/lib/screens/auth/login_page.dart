import 'package:flutter/material.dart';
import '../homepage/home_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  final VoidCallback onSignUpPressed;

  const LoginPage({super.key, required this.onSignUpPressed });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>{
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final Color primaryBlue = const Color(0xFF003087);
  final Color backgroundBlue = const Color(0xFFDCE7FA);
  bool _obscurePassword = true;
@override
void dispose(){
  _emailController.dispose();
  _passwordController.dispose();
  super.dispose();
}

  Future<void> login() async {
  try {
    final response = await http.post(
      Uri.parse("http://localhost:3000/login"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": _emailController.text.trim(),
        "password": _passwordController.text.trim(),
      }),
    );
    final data = jsonDecode(response.body);


    if (!mounted) return;

    if (response.statusCode == 200) {
      final int userId = data["userid"]["id"];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(userId: userId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid email or password"),
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
                  color: Colors.black.withOpacity(.15),
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
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: primaryBlue,
                          child: const Icon(
                            Icons.chat_bubble_outline,
                            size: 100,
                            color: Colors.white,
                          ),
                        );
                      },
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
                        Icon(
                          Icons.chat_bubble,
                          size: 50,
                          color: primaryBlue,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Welcome Back",
                          style: TextStyle(
                            fontFamily: "PublicSans",
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Login to continue chatting.",
                          style: TextStyle(
                            fontFamily: "PublicSans",
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 22),

                        _buildTextField(
                          controller: _emailController,
                          label: "Email",
                        ),
                        const SizedBox(height: 14),

                        _buildTextField(
                          controller: _passwordController,
                          label: "Password",
                          isPassword: true,
                          obscure: _obscurePassword,
                          onToggle: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                        ),

                        const SizedBox(height: 4),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: primaryBlue,
                                fontFamily: "PublicSans",
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Login",
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
                              "Don't have an account?",
                              style: TextStyle(
                                fontFamily: "PublicSans",
                                fontSize: 13,
                              ),
                            ),
                            TextButton(
                              onPressed: widget.onSignUpPressed,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                "Create Account",
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
