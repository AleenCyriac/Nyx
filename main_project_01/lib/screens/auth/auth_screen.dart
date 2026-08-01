import 'package:flutter/material.dart';

import 'login_page.dart';
import 'signup_page.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
final PageController _pageController = PageController();

@override
void dispose() {
  _pageController.dispose();
  super.dispose();
}

void goToSignUp(){
  _pageController.animateToPage(
    1,
    duration:const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  );
}

void goToLogin() {
  _pageController.animateToPage(
    0,
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller:_pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          LoginPage(onSignUpPressed: goToSignUp),
          SignupPage(onLoginPressed: goToLogin),
        ],
        )
    );
  }
}