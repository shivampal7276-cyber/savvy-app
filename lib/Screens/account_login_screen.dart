import 'package:flutter/material.dart';

import 'signup_screen.dart'; // Make sure import path matches your project structure

import 'home_screen.dart'; // Make sure import path matches your project structure
import '../services/auth_session.dart';



class LoginScreen extends StatefulWidget {

  final bool returnResultOnSuccess;

  const LoginScreen({super.key, this.returnResultOnSuccess = false});



  @override

  State<LoginScreen> createState() => _LoginScreenState();

}



class _LoginScreenState extends State<LoginScreen> {

  bool _obscurePassword = true;

  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInLocally() async {
    final email = _emailController.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email) || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email and password to continue.')),
      );
      return;
    }
    // Restore the name entered at signup when this email has a local demo
    // profile. The password is never persisted or verified by a server.
    final name = await AuthSession.demoProfileName(email) ?? email.split('@').first;
    await AuthSession.save(email: email, name: name);
    if (!mounted) return;
    if (widget.returnResultOnSuccess) {
      Navigator.pop(context, true);
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => HomeScreen(
        userName: name,
        userEmail: email,
        successMessage: 'You have successfully logged in.',
      )),
      (_) => false,
    );
  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xff040A1C), // Savyyk dark theme background

      body: SafeArea(

        child: SingleChildScrollView(

          child: Column(

            children: [

// Top Bar with Back Arrow and "Don't have an account? Get Started"

              Padding(

                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

                child: Row(

                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [

// Back Button

                    GestureDetector(

                      onTap: () => Navigator.pop(context),

                      child: Container(

                        padding: const EdgeInsets.all(10),

                        decoration: BoxDecoration(

                          color: Colors.black.withValues(alpha: 0.15),

                          shape: BoxShape.circle,

                        ),

                        child: const Icon(

                          Icons.arrow_back_ios_new_rounded,

                          color: Colors.white,

                          size: 16,

                        ),

                      ),

                    ),

// Don't have an account? Get Started

                    Row(

                      children: [

                        const Text(

                          "Don't have an account?",

                          style: TextStyle(

                            color: Colors.white,

                            fontSize: 13,

                          ),

                        ),

                        TextButton(

                          onPressed: () {

                            Navigator.pushReplacement(

                              context,

                              MaterialPageRoute(builder: (_) => SignUpScreen(returnResultOnSuccess: widget.returnResultOnSuccess)),

                            );

                          },

                          child: const Text(

                            "Get Started",

                            style: TextStyle(

                              color: Colors.white,

                              fontSize: 13,

                              fontWeight: FontWeight.bold,

                            ),

                          ),

                        ),

                      ],

                    ),

                  ],

                ),

              ),

              const SizedBox(height: 10),



// Main Dark Authentication Card Box

              Container(

                margin: const EdgeInsets.all(20),

                padding: const EdgeInsets.all(24),

                decoration: BoxDecoration(

                  color: const Color(0xff09101D), // Dark background card

                  borderRadius: BorderRadius.circular(30),

                  border: Border.all(color: Colors.white12),

                ),

                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  children: [

// Title

                    const Text(

                      "Welcome Back",

                      style: TextStyle(

                        color: Colors.white,

                        fontSize: 26,

                        fontWeight: FontWeight.bold,

                        letterSpacing: -0.5,

                      ),

                    ),

                    const SizedBox(height: 6),

// Subtitle

                    const Text(

                      "Enter your details below",

                      style: TextStyle(

                        color: Colors.white54,

                        fontSize: 13,

                      ),

                    ),

                    const SizedBox(height: 8),

                    const Text(

                      "Local demo sign-in only; a verified authentication server is not connected.",

                      textAlign: TextAlign.center,

                      style: TextStyle(color: Colors.white38, fontSize: 11),

                    ),

                    const SizedBox(height: 24),



// Email Field

                    TextField(

                      controller: _emailController,

                      style: const TextStyle(color: Colors.white),

                      decoration: InputDecoration(

                        labelText: "Email Address",

                        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),

                        filled: true,

                        fillColor: const Color(0xff111B3C),

                        border: OutlineInputBorder(

                          borderRadius: BorderRadius.circular(16),

                          borderSide: BorderSide.none,

                        ),

                      ),

                    ),

                    const SizedBox(height: 16),



// Password Field

                    TextField(

                      controller: _passwordController,

                      obscureText: _obscurePassword,

                      style: const TextStyle(color: Colors.white),

                      decoration: InputDecoration(

                        labelText: "Password",

                        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),

                        filled: true,

                        fillColor: const Color(0xff111B3C),

                        border: OutlineInputBorder(

                          borderRadius: BorderRadius.circular(16),

                          borderSide: BorderSide.none,

                        ),

                        suffixIcon: IconButton(

                          icon: Icon(

                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,

                            color: Colors.white54,

                            size: 20,

                          ),

                          onPressed: () {

                            setState(() {

                              _obscurePassword = !_obscurePassword;

                            });

                          },

                        ),

                      ),

                    ),

                    const SizedBox(height: 20),



// Sign In Button (Savyyk cyan gradient)

                    Container(

                      width: double.infinity,

                      height: 52,

                      decoration: BoxDecoration(

                        gradient: const LinearGradient(

                          colors: [Color(0xff2F7BFF), Color(0xff24D6FF)],

                        ),

                        borderRadius: BorderRadius.circular(26),

                      ),

                      child: ElevatedButton(

                        onPressed: _signInLocally,

                        style: ElevatedButton.styleFrom(

                          backgroundColor: Colors.transparent,

                          shadowColor: Colors.transparent,

                          shape: RoundedRectangleBorder(

                            borderRadius: BorderRadius.circular(26),

                          ),

                        ),

                        child: const Text(

                          "Sign in",

                          style: TextStyle(

                            color: Colors.white,

                            fontSize: 16,

                            fontWeight: FontWeight.bold,

                          ),

                        ),

                      ),

                    ),

                    const SizedBox(height: 14),



// Forgot Your Password?

                    TextButton(

                      onPressed: () {

// Add forgot password logic here

                      },

                      child: const Text(

                        "Forgot your password?",

                        style: TextStyle(

                          color: Color(0xff24D6FF),

                          fontWeight: FontWeight.bold,

                          fontSize: 13,

                        ),

                      ),

                    ),

                    const SizedBox(height: 14),



// Divider "Or sign in with"

                    Row(

                      children: const [

                        Expanded(child: Divider(color: Colors.white24)),

                        Padding(

                          padding: EdgeInsets.symmetric(horizontal: 12),

                          child: Text(

                            "Or sign in with",

                            style: TextStyle(color: Colors.white54, fontSize: 12),

                          ),

                        ),

                        Expanded(child: Divider(color: Colors.white24)),

                      ],

                    ),

                    const SizedBox(height: 18),



// Google Sign-in Button

                    SizedBox(

                      width: double.infinity,

                      height: 52,

                      child: ElevatedButton(

                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Google sign-in needs Firebase Authentication setup before it can be used.')),
                        ),

                        style: ElevatedButton.styleFrom(

                          backgroundColor: const Color(0xff2F7BFF),

                          shape: RoundedRectangleBorder(

                            borderRadius: BorderRadius.circular(26),

                          ),

                        ),

                        child: Row(

                          mainAxisAlignment: MainAxisAlignment.center,

                          children: const [

                            Text(

                              "G",

                              style: TextStyle(

                                fontSize: 18,

                                fontWeight: FontWeight.bold,

                                color: Colors.white,

                              ),

                            ),

                            SizedBox(width: 12),

                            Text(

                              "Sign in with Google",

                              style: TextStyle(

                                color: Colors.white,

                                fontSize: 15,

                                fontWeight: FontWeight.w600,

                              ),

                            ),

                          ],

                        ),

                      ),

                    ),

                    const SizedBox(height: 12),



// Apple Continue Button

                    SizedBox(

                      width: double.infinity,

                      height: 52,

                      child: ElevatedButton.icon(

                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Apple sign-in is not connected yet.')),
                        ),

                        icon: const Icon(Icons.apple, color: Colors.white, size: 22),

                        label: const Text(

                          "Continue with Apple",

                          style: TextStyle(

                            color: Colors.white,

                            fontSize: 15,

                            fontWeight: FontWeight.w600,

                          ),

                        ),

                        style: ElevatedButton.styleFrom(

                          backgroundColor: Colors.black,

                          shape: RoundedRectangleBorder(

                            borderRadius: BorderRadius.circular(26),

                          ),

                          side: const BorderSide(color: Colors.white12),

                        ),

                      ),

                    ),

                  ],

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

}





class AccountAuthScreen extends StatelessWidget {

  const AccountAuthScreen({super.key});



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xff040A1C), // Savyyk dark theme background

      body: SafeArea(

        child: Column(

          children: [

// Top Bar with Back Arrow Button

            Padding(

              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

              child: Row(

                children: [

                  GestureDetector(

                    onTap: () => Navigator.pop(context),

                    child: Container(

                      padding: const EdgeInsets.all(10),

                      decoration: BoxDecoration(

                        color: Colors.black.withValues(alpha: 0.15),

                        shape: BoxShape.circle,

                      ),

                      child: const Icon(

                        Icons.arrow_back_ios_new_rounded,

                        color: Colors.white,

                        size: 16,

                      ),

                    ),

                  ),

                ],

              ),

            ),

            const Spacer(flex: 1),



// Logo Image Container

            Container(

              width: 95,

              height: 95,

              padding: const EdgeInsets.all(12),

              decoration: BoxDecoration(

                color: Colors.white,

                borderRadius: BorderRadius.circular(24),

                boxShadow: [

                  BoxShadow(

                    color: Colors.black.withValues(alpha: 0.1),

                    blurRadius: 20,

                    offset: const Offset(0, 10),

                  ),

                ],

              ),

              child: ClipRRect(

                borderRadius: BorderRadius.circular(16),

                child: Image.asset(

                  'assets/images/logo.png',

                  fit: BoxFit.contain,

                ),

              ),

            ),

            const SizedBox(height: 24),



// Title & Subtitle Text

            const Text(

              "Save with focus.",

              style: TextStyle(

                color: Colors.white,

                fontSize: 28,

                fontWeight: FontWeight.bold,

                letterSpacing: -0.5,

              ),

            ),

            const SizedBox(height: 8),

            const Padding(

              padding: EdgeInsets.symmetric(horizontal: 32),

              child: Text(

                "Track shared goals, sync progress, and keep every contribution in one calm workspace.",

                textAlign: TextAlign.center,

                style: TextStyle(

                  color: Colors.white70,

                  fontSize: 13,

                  height: 1.4,

                ),

              ),

            ),

            const Spacer(flex: 2),



// Bottom Dark Authentication Card Box (Only Sign In & Create Account)

            Container(

              margin: const EdgeInsets.all(20),

              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(

                color: const Color(0xff0A1128),

                borderRadius: BorderRadius.circular(30),

                border: Border.all(color: Colors.white12),

              ),

              child: Column(

                mainAxisSize: MainAxisSize.min,

                children: [

// Sign In Button (Savyyk cyan gradient) -> Navigates to Login Screen

                  Container(

                    width: double.infinity,

                    height: 52,

                    decoration: BoxDecoration(

                      gradient: const LinearGradient(

                        colors: [Color(0xff2F7BFF), Color(0xff24D6FF)],

                      ),

                      borderRadius: BorderRadius.circular(26),

                    ),

                    child: ElevatedButton(

                      onPressed: () {

                        Navigator.push(

                          context,

                          MaterialPageRoute(builder: (_) => const LoginScreen()),

                        );

                      },

                      style: ElevatedButton.styleFrom(

                        backgroundColor: Colors.transparent,

                        shadowColor: Colors.transparent,

                        shape: RoundedRectangleBorder(

                          borderRadius: BorderRadius.circular(26),

                        ),

                      ),

                      child: const Text(

                        "Sign in",

                        style: TextStyle(

                          color: Colors.white,

                          fontSize: 16,

                          fontWeight: FontWeight.bold,

                        ),

                      ),

                    ),

                  ),

                  const SizedBox(height: 12),



// Create an account Button -> Navigates to Signup Screen

                  Container(

                    width: double.infinity,

                    height: 52,

                    decoration: BoxDecoration(

                      color: const Color(0xff111B3C),

                      borderRadius: BorderRadius.circular(26),

                      border: Border.all(color: Colors.white12),

                    ),

                    child: TextButton(

                      onPressed: () {

                        Navigator.push(

                          context,

                          MaterialPageRoute(builder: (_) => const SignUpScreen()),

                        );

                      },

                      style: TextButton.styleFrom(

                        shape: RoundedRectangleBorder(

                          borderRadius: BorderRadius.circular(26),

                        ),

                      ),

                      child: const Text(

                        "Create an account",

                        style: TextStyle(

                          color: Color(0xff24D6FF),

                          fontSize: 16,

                          fontWeight: FontWeight.bold,

                        ),

                      ),

                    ),

                  ),

                ],

              ),

            ),

          ],

        ),

      ),

    );

  }

}

