import 'package:flutter/material.dart';
import 'account_login_screen.dart'; // Correct login screen import
import 'signup_screen.dart';       // Correct signup screen import

class AccountAuthScreen extends StatelessWidget {
  final bool returnResultOnSuccess;

  const AccountAuthScreen({super.key, this.returnResultOnSuccess = false});

  Future<void> _openAuthFlow(BuildContext context, Widget screen) async {
    final authenticated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    if (returnResultOnSuccess && authenticated == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0A1128), // Savyyk dark theme background
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
                        color: Colors.white.withValues(alpha: 0.1),
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
                color: const Color(0xff111B3C),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
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
              "Save with Savvy.",
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

            // Bottom Dark Authentication Card Box
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xff111B3C),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sign In Button -> Navigates to AccountLoginScreen
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
                      onPressed: () => _openAuthFlow(
                        context,
                        LoginScreen(returnResultOnSuccess: returnResultOnSuccess),
                      ),
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

                  // Create an account Button -> Navigates to SignUpScreen
                  Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xff0A1128),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: TextButton(
                      onPressed: () => _openAuthFlow(
                        context,
                        SignUpScreen(returnResultOnSuccess: returnResultOnSuccess),
                      ),
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
