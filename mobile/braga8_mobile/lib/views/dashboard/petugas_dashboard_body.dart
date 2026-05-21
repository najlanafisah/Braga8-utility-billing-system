import 'package:braga8_mobile/ApiService.dart';
import 'package:braga8_mobile/core/app_colors.dart';
import 'package:braga8_mobile/views/dashboard/components/header_navbar.dart';
import 'package:braga8_mobile/views/dashboard/components/meter_progress_card.dart';
import 'package:braga8_mobile/views/dashboard/dashboard_screen.dart';
import 'package:braga8_mobile/views/dashboard/dashboard_shared_widgets.dart';
import 'package:braga8_mobile/views/widgets/main_layouts.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Petugas Dashboard Body — stateless, receives all data via props
// ---------------------------------------------------------------------------
class PetugasDashboardBody extends StatelessWidget {
  final ApiService api;
  final String token;
  final String role;
  final int totalMeters;
  final int readMeters;
  final int unreadCount;
  final bool isLoadingStats;
  final ValueChanged<int> onNavTap;
  final Future<void> Function() onRefresh;
  final void Function(BuildContext) onOpenNotifications;

  const PetugasDashboardBody({
    required this.api,
    required this.token,
    required this.role,
    required this.totalMeters,
    required this.readMeters,
    required this.unreadCount,
    required this.isLoadingStats,
    required this.onNavTap,
    required this.onRefresh,
    required this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: MainLayout(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.primaryOrange,
            onRefresh: onRefresh,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 10),
              children: [
                HeaderNavbar(
                  api: api,
                  token: token,
                  unreadCount: unreadCount,
                  onNotificationTap: () => onOpenNotifications(context),
                ),
                const SizedBox(height: 10),
                Text(
                  "Halo, ${(() {
                    String name = api.currentUser?['name'] ?? role;
                    if (name.isEmpty) return name;
                    return name[0].toUpperCase() + name.substring(1).toLowerCase();
                  })()}!",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Monitor entry progress bulan ini.",
                  style: TextStyle(color: Colors.white38, fontSize: 15),
                ),
                const SizedBox(height: 28),
                isLoadingStats
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.orange,
                            ),
                          ),
                        ),
                      )
                    : MeterProgressCard(
                        total: totalMeters,
                        read: readMeters,
                        period: _currentPeriod(),
                      ),
                const SizedBox(height: 35),
                _buildPetugasGrid(context),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _currentPeriod() {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  Widget _buildPetugasGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GridItem(
                'Meter Input',
                'assets/cardImage/meter-input-img.png',
                () => onNavTap(1),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GridItem(
                'Daftar Unit',
                'assets/cardImage/daftar-unit-img.png',
                () => onNavTap(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GridItem(
                'Log Aktivitas',
                'assets/cardImage/history-img.png',
                () => onNavTap(3),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GridItem(
                'Data Meter',
                'assets/cardImage/meter-analytics-img.png',
                () => onNavTap(4),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
