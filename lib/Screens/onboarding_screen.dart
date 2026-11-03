import 'package:flutter/material.dart';
import '../Widgets/gradient_button.dart';
import 'login_screen.dart';
import 'home_screen.dart';   // Import your home screen

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff040A1C),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          const SizedBox(height: 10),
                          Container(
                            height: 280,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.withOpacity(.15),
                                  Colors.indigo.withOpacity(.05)
                                ],
                              ),
                            ),
                            child: Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  for (double size in [220, 160, 100])
                                    Container(
                                      width: size,
                                      height: size,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white12, width: 1),
                                      ),
                                    ),
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [Color(0xff28C6FF), Color(0xff5E6BFF)],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.cyan,
                                          blurRadius: 25,
                                          spreadRadius: 4,
                                        )
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text(
                                        "₹5",
                                        style: TextStyle(
                                            fontSize: 28, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 25),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Start with ₹5.\nSee where it goes.",
                              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 15),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "No minimum balance, no confusing charts.\nJust small amounts, saved on purpose,\ntoward things you actually want.",
                              style: TextStyle(color: Colors.white70, height: 1.5, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Column(
                        children: [
                          // Match Shivam's launch flow: Continue opens phone login.
                          GradientButton(
                            text: "Continue",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            },
                          ),
                          const SizedBox(height: 10),

                          // --- SKIP BUTTON OPENS HOME SCREEN DIRECTLY ---
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const HomeScreen()),
                              );
                            },
                            child: const Text(
                              "Skip",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
