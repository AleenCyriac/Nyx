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

  /*final Color primaryBlue = const Color(0xFF003087);
  final Color backgroundBlue = const Color(0xFFDCE7FA);*/

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
      body: SafeArea(
        child: Align(
          alignment: Alignment.center,
          child: SizedBox(
            width: 500,
            child: Padding(
              padding:  EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble, size:80),
                  const SizedBox(height: 20),
                  const Text("Hybrid chat", style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,), ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _userNameController,
                    decoration: const InputDecoration(
                      labelText: "Username",
                      border: OutlineInputBorder(),

                    ),
                  ),

                  const SizedBox(height: 10),
                  TextField(
                    controller: _phoneNoController,
                    decoration: const InputDecoration(
                      labelText: "Phone Number",
                      border: OutlineInputBorder(),

                    ),
                  ),

                  const SizedBox(height: 10),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),

                    ),
                  ),

                  const SizedBox(height: 10),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: "Password",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  TextField(
                    controller:  _passwordCheckerController ,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: "Confirm Password",
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text("Forgot Password?"),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:signup,
                      child: const Text("Sign up"),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      const Text("Already have an account?"),

                      TextButton(
                        onPressed: widget.onLoginPressed,
                        child: const Text("Log into Account"),
                      ),

                    ],
                  ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
