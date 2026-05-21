import 'package:braga8_mobile/ApiService.dart';
import 'package:braga8_mobile/views/payments/payment_logs_screen.dart';
import 'package:braga8_mobile/core/app_colors.dart';
import 'package:braga8_mobile/views/dashboard/components/header_navbar.dart';
import 'package:braga8_mobile/views/dashboard/components/invoice_status_card.dart';
import 'package:braga8_mobile/views/dashboard/dashboard_screen.dart';
import 'package:braga8_mobile/views/dashboard/dashboard_shared_widgets.dart';
import 'package:braga8_mobile/views/widgets/main_layouts.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Tenant Dashboard Body — stateless, receives all data via props
// ---------------------------------------------------------------------------
class TenantDashboardBody extends StatelessWidget {
  final ApiService api;
  final String token;
  final String role;
  final int unreadCount;
  final double invoiceTotal;
  final bool invoicePaid;
  final String? invoiceNumber;
  final ValueChanged<int> onNavTap;
  final void Function(BuildContext) onOpenNotifications;

  const TenantDashboardBody({
    required this.api,
    required this.token,
    required this.role,
    required this.unreadCount,
    required this.onNavTap,
    required this.onOpenNotifications,
    required this.invoiceTotal,
    required this.invoicePaid,
    this.invoiceNumber,
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
            onRefresh: () async {},
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
                  "Halo, Tim ${(() {
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
                  "Pantau penggunaan utilitas Anda.",
                  style: TextStyle(color: Colors.white38, fontSize: 15),
                ),
                const SizedBox(height: 28),
                InvoiceStatusCard(
                  totalAmount: invoiceTotal,
                  isPaid: invoicePaid,
                  invoiceNumber: invoiceNumber,
                  period: _currentPeriod(),
                ),
                const SizedBox(height: 35),
                _buildTenantGrid(context),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTenantGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GridItem(
                'Analitik Meter',
                'assets/cardImage/meter-analytics-img.png',
                () => onNavTap(1),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GridItem(
                'Invoices',
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
                'Riwayat Pembayaran',
                'assets/cardImage/payment-card-img.png',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentLogsScreen(api: api),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: GridItem(
                'Customer Care',
                'assets/cardImage/customer-service-img.png',
                () => onNavTap(3),
              ),
            ),
          ],
        ),
      ],
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
}
