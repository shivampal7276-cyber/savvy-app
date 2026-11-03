import 'package:flutter/material.dart';

class SavvyBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const SavvyBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // SafeArea ensures it floats above the device's system gesture bar
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // <--- Lifts it up from the bottom edge
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xff0E162F), // Slightly elevated card background color
          borderRadius: BorderRadius.circular(30), // <--- Floating rounded pill shape
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)), // Subtle border all around
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.home_rounded,
              label: "Home",
              isSelected: currentIndex == 0,
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.savings_rounded,
              useLogo: true,
              label: "Goals",
              isSelected: currentIndex == 1,
            ),
            _buildNavItem(
              index: 2,
              icon: Icons.sync_rounded,
              label: "History",
              isSelected: currentIndex == 2,
              hasNotification: true,
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.pie_chart_rounded,
              label: "Analytics",
              isSelected: currentIndex == 3,
            ),
            _buildNavItem(
              index: 4,
              icon: Icons.person_rounded,
              label: "Profile",
              isSelected: currentIndex == 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    bool hasNotification = false,
    bool useLogo = false,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 14 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff1C2A57) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                if (useLogo)
                  Image.asset(
                    'assets/images/logo.png',
                    width: 22,
                    height: 22,
                    fit: BoxFit.contain,
                  )
                else
                  Icon(
                    icon,
                    color: isSelected ? Colors.cyanAccent : Colors.white54,
                    size: 22,
                  ),
                if (hasNotification && !isSelected)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}