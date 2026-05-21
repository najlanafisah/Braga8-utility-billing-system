import 'package:braga8_mobile/ApiService.dart';
import 'package:braga8_mobile/components/profile_modal.dart';
import 'package:braga8_mobile/core/app_colors.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Grid menu item card
// ---------------------------------------------------------------------------
class GridItem extends StatelessWidget {
  final String label;
  final String imagePath;
  final VoidCallback onTap;
  final double height;

  const GridItem(this.label, this.imagePath, this.onTap, {this.height = 160});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.primaryOrange.withAlpha(4),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -70,
                bottom: -80,
                child: Image.asset(imagePath, width: 240, fit: BoxFit.contain),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom navigation bar
// ---------------------------------------------------------------------------
class BottomNav extends StatelessWidget {
  final int currentIndex;
  final bool isPetugas;
  final ValueChanged<int> onTap;

  const BottomNav({
    required this.currentIndex,
    required this.isPetugas,
    required this.onTap,
  });

  static const _petugasItems = [
    (Icons.home_filled, 'Home'),
    (Icons.speed, 'Meter'),
    (Icons.domain, 'Units'),
    (Icons.history, 'History'),
    (Icons.person, 'Profile'),
    (Icons.analytics, 'Data Meter'),
  ];

  static const _tenantItems = [
    (Icons.home_filled, 'Home'),
    (Icons.bar_chart, 'Analytics'),
    (Icons.receipt_long, 'Invoice'),
    (Icons.support_agent, 'Care'),
  ];

  @override
  Widget build(BuildContext context) {
    final items = isPetugas ? _petugasItems : _tenantItems;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          image: const DecorationImage(
            image: AssetImage('assets/navbar-img.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (i) {
            final (icon, label) = items[i];
            return NavItem(
              index: i,
              icon: icon,
              label: label,
              isActive: currentIndex == i,
              onTap: onTap,
            );
          }),
        ),
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final String label;
  final bool isActive;
  final ValueChanged<int> onTap;

  const NavItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  static const _orange = Color(0xFFFF6B35);

  @override
  Widget build(BuildContext context) {
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
              color: isActive ? _orange : Colors.white.withAlpha(180),
              size: 24,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: _orange,
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

// ---------------------------------------------------------------------------
// Profile page tab
// ---------------------------------------------------------------------------
class ProfilePage extends StatefulWidget {
  final ApiService api;
  final String role;
  final String token;

  const ProfilePage({
    required this.api,
    required this.role,
    required this.token,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _modalShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_modalShown) {
      _modalShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted)
          showProfileModal(context, widget.api, widget.role, widget.token);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
