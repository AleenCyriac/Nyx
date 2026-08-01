import 'package:flutter/material.dart';
import '../home_page.dart';
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


    print(response.statusCode);
    print(response.body);

    if (!mounted) return;

    if (response.statusCode == 200) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const HomePage(),
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
                         onPressed: login,
                         child: const Text("Login"),
                       ),
                     ),

                     const SizedBox(height: 20),

                     Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [

                         const Text("Don't have an account?"),

                         TextButton(
                           onPressed: widget.onSignUpPressed,
                           child: const Text("Create Account"),
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
