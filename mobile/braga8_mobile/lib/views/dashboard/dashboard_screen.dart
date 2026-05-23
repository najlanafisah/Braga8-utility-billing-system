import 'package:braga8_mobile/ApiService.dart';
import 'package:braga8_mobile/components/profile_modal.dart';
import 'package:braga8_mobile/views/complaint/customer_care_screen.dart';
import 'package:braga8_mobile/views/dashboard/petugas_dashboard_body.dart';
import 'package:braga8_mobile/views/dashboard/tenant_dashboard_body.dart';
import 'package:braga8_mobile/views/history/audit_log_screen.dart';
import 'package:braga8_mobile/views/daftar_unit/daftar_unit_screen.dart';
import 'package:braga8_mobile/components/notification_modal.dart';
import 'package:braga8_mobile/data/models/notification_model.dart';
import 'package:braga8_mobile/views/invoice/daftar_invoices_screen.dart';
import 'package:braga8_mobile/views/meter_analytics/meter_analytics_screen.dart';
import 'package:braga8_mobile/views/meter_input/input_reading_screen.dart';
import 'package:braga8_mobile/views/widgets/bottom_navbar_custom.dart';
import 'package:braga8_mobile/core/app_colors.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// DashboardScreen — StatefulWidget, owns nav + data state
// ---------------------------------------------------------------------------
class DashboardScreen extends StatefulWidget {
  final ApiService api;
  final String token;
  final String role;
  final int initialIndex;

  const DashboardScreen({
    super.key,
    required this.api,
    required this.token,
    required this.role,
    this.initialIndex = 0,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // --- Nav state ---
  late int _selectedIndex;

  // --- Dashboard data state ---
  int _totalMeters = 0;
  int _readMeters = 0;
  int _unreadCount = 0;
  bool _isLoadingStats = false;

  double _invoiceTotal = 0;
  bool _invoicePaid = false;
  String? _invoiceNumber;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _loadDashboardData(); // ← just call it directly

    if (widget.role.toLowerCase() == 'tenant') {
      widget.api.loadCurrentTenantUnits().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  void _onItemTapped(int index) {
    final bool isPetugas = widget.role.toLowerCase() == 'petugas';
    final int profileIndex = isPetugas ? 5 : -1; 

    if (index == profileIndex) {
      showProfileModal(context, widget.api, widget.role, widget.token);
      return;
    }

    setState(() => _selectedIndex = index);
  }

  Future<void> _fetchLatestPayment() async {
    try {
      final logs = await widget.api.fetchPaymentLogs();
      if (logs.isEmpty) return;

      final latest = logs.first;

      if (mounted) {
        setState(() {
          _invoiceTotal = (latest.amountPaid).toDouble();
          _invoicePaid = latest.status == 'verified';
          _invoiceNumber = latest.invoiceNumber;
        });
      }
    } catch (e) {
      debugPrint('Invoice fetch error: $e');
    }
  }

  Future<void> _loadDashboardData() async {
    await _fetchUnreadCount();
    if (widget.role.toLowerCase() == 'petugas') {
      await _fetchProgressData();
    } else {
      await _fetchLatestPayment();
    }
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final List<NotificationModel> list = await widget.api.getNotifications(
        widget.token,
      );
      if (mounted) {
        setState(() {
          _unreadCount = list.where((n) => n.readAt == null).length;
        });
      }
    } catch (e) {
      debugPrint("Gagal fetch notif count: $e");
    }
  }

  Future<void> _fetchProgressData() async {
    if (!mounted) return;
    setState(() => _isLoadingStats = true);
    try {
      final stats = await widget.api.getMonthlyStats(widget.token);
      if (mounted) {
        setState(() {
          _totalMeters = stats['total'] ?? 0;
          _readMeters = stats['readings'] ?? 0;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStats = false);
      debugPrint("Stats fetch error: $e");
    }
  }

  // -----------------------------------------------------------------------
  // NOTIFICATION CENTER
  // -----------------------------------------------------------------------
  void _openNotificationCenter(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryOrange),
      ),
    );
    try {
      final List<NotificationModel> list = await widget.api.getNotifications(
        widget.token,
      );
      if (!context.mounted) return;
      Navigator.pop(context);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => NotificationModal(
          notifications: list,
          token: widget.token,
          api: widget.api,
          onRefresh: () {
            Navigator.pop(context);
            _openNotificationCenter(context);
          },
        ),
      ).whenComplete(_fetchUnreadCount);
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // -----------------------------------------------------------------------
  // PAGES — built once, kept alive by IndexedStack
  // -----------------------------------------------------------------------

  List<Widget> get _pages {
    final bool isPetugas = widget.role.toLowerCase() == 'petugas';
    if (isPetugas) {
      return [
        PetugasDashboardBody(
          api: widget.api,
          token: widget.token,
          role: widget.role,
          totalMeters: _totalMeters,
          readMeters: _readMeters,
          unreadCount: _unreadCount,
          isLoadingStats: _isLoadingStats,
          onNavTap: _onItemTapped,
          onRefresh: _fetchProgressData,
          onOpenNotifications: _openNotificationCenter,
        ),
        InputReadingScreen(onBack: () => _onItemTapped(0)),
        DaftarUnitScreen(api: widget.api, onBack: () => _onItemTapped(0)),
        AuditLogScreen(onBack: () => _onItemTapped(0)),
        MeterAnalyticsScreen(userRole: 'petugas'),
      ];
    }
    return [
      TenantDashboardBody(
        api: widget.api,
        token: widget.token,
        role: widget.role,
        unreadCount: _unreadCount,
        invoiceTotal: _invoiceTotal,
        invoicePaid: _invoicePaid,
        invoiceNumber: _invoiceNumber,
        onNavTap: _onItemTapped,
        onOpenNotifications: _openNotificationCenter,
      ),
      MeterAnalyticsScreen(
        userRole: 'tenant',
        tenant: widget.api.currentTenant,
      ), // 1
      DaftarInvoicesScreen(api: widget.api), // 2
      CustomerCareListScreen(
        // 3
        onBack: () => _onItemTapped(0),
        api: widget.api,
        token: widget.token,
      ),
      AuditLogScreen(onBack: () => _onItemTapped(0)),
    ];
  }

  // -----------------------------------------------------------------------
  // BUILD
  // -----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.grey.shade50,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
        key: ValueKey(widget.api.currentTenant?.id),
      ),
      bottomNavigationBar: BottomNavbarCustom(
        role: widget.role,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  List<Widget> _buildStaticPages() {
    final bool isPetugas = widget.role.toLowerCase() == 'petugas';
    if (isPetugas) {
      return [
        InputReadingScreen(onBack: () => _onItemTapped(0)),
        DaftarUnitScreen(api: widget.api, onBack: () => _onItemTapped(0)),
        AuditLogScreen(onBack: () => _onItemTapped(0)),
        // CustomerCareListScreen(
        //   onBack: () => _onItemTapped(0),
        //   api: widget.api,
        //   token: widget.token,
        // ),
        MeterAnalyticsScreen(userRole: 'petugas'),
      ];
    }
    return [
      widget.api.currentTenant == null
          ? const Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: CircularProgressIndicator(color: Colors.orange),
              ),
            )
          : MeterAnalyticsScreen(
              userRole: 'tenant',
              tenant: widget.api.currentTenant,
              key: ValueKey(widget.api.currentTenant?.id),
            ),
      const Scaffold(body: Center(child: Text("Invoices"))),
      const Scaffold(body: Center(child: Text("Customer Care"))),
    ];
  }
}
