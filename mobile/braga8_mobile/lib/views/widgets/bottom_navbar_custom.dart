import 'dart:ui';

import 'package:flutter/material.dart';

class BottomNavbarCustom extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String role; // ← add this

  const BottomNavbarCustom({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.role, // ← add this
  });

  bool get _isPetugas => role.toLowerCase() == 'petugas';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
          borderRadius: BorderRadius.circular(40),
          image: const DecorationImage(
            image: AssetImage('assets/navbar-img.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(40),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _isPetugas
                      ? [
                          _navItem(0, Icons.home_filled, "Home"),
                          _navItem(1, Icons.speed, "Meter Input"),
                          _navItem(2, Icons.store_outlined, "Daftar Unit"),
                          _navItem(3, Icons.history, "History"),
                          _navItem(4, Icons.analytics, "Data Meter"),
                        ]
                      : [
                          _navItem(0, Icons.home_filled, "Home"),
                          _navItem(1, Icons.analytics, "Analytics"),
                          _navItem(2, Icons.receipt_long, "Invoices"),
                          _navItem(3, Icons.support_agent, "Care"),
                          _navItem(4, Icons.history, "History"),
                        ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final bool isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 20 : 12,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withAlpha(200) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? Colors.black87 : Colors.white.withAlpha(180),
              size: 24,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
