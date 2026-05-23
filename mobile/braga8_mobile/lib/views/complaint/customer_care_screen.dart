import 'dart:ui';

import 'package:braga8_mobile/ApiService.dart';
import 'package:braga8_mobile/data/models/complaint_model.dart';
import 'package:braga8_mobile/views/complaint/detail_complaint_screen.dart';
import 'package:braga8_mobile/views/complaint/input_complaint_screen.dart';
import 'package:braga8_mobile/core/app_colors.dart';
import 'package:braga8_mobile/views/widgets/app_header.dart';
import 'package:braga8_mobile/views/widgets/custom_search_bar.dart';
import 'package:braga8_mobile/views/widgets/main_layouts.dart';
import 'package:braga8_mobile/views/widgets/page_header.dart';
import 'package:braga8_mobile/views/widgets/table_card.dart';
import 'package:flutter/material.dart';

class CustomerCareListScreen extends StatefulWidget {
  final ApiService api;
  final String token;
  final VoidCallback? onBack;

  const CustomerCareListScreen({
    super.key,
    required this.api,
    required this.token,
    this.onBack,
  });

  @override
  State<CustomerCareListScreen> createState() => _CustomerCareListScreenState();
}

class _CustomerCareListScreenState extends State<CustomerCareListScreen>
    with WidgetsBindingObserver {
  // ── State ─────────────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  List<Complaint> _complaints = [];
  bool _isLoading = false;

  String _searchQuery = '';
  String _statusFilter = 'all';

  static const _orange = AppColors.primaryOrange;
  static const int _maxTitleLength = 36;

  static const List<String> _bulan = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshData(); // single fetch on startup
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshData(silent: true);
  }

  // ── Data ──────────────────────────────────────────────────────────────────
  Future<void> _refreshData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final complaints = await widget.api.fetchComplaints(
        providedToken: widget.token,
      );
      if (mounted) setState(() => _complaints = complaints);
    } catch (e) {
      debugPrint("Gagal me-refresh data: $e");
      if (mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Gagal memperbarui data dari server"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Filter ────────────────────────────────────────────────────────────────
  List<Complaint> _getFiltered(List<Complaint> all) {
    return all.where((c) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!c.title.toLowerCase().contains(q)) return false;
      }
      if (_statusFilter != 'all' && c.status != _statusFilter) return false;
      return true;
    }).toList();
  }

  bool _isLocked(Complaint c) =>
      c.status == 'resolved' || c.status == 'rejected';

String _truncateTitle(String title) => title.length <= _maxTitleLength
    ? title
    : '${title.substring(0, _maxTitleLength)}…';

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day} ${_bulan[dt.month]} ${dt.year}';
    } catch (_) {
      try {
        final dt = DateTime.parse(raw.split(' ').first);
        return '${dt.day} ${_bulan[dt.month]} ${dt.year}';
      } catch (_) {
        return raw;
      }
    }
  }

  Future<void> _deleteComplaint(Complaint complaint) async {
  bool confirmed = false;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Icon + Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.3),
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(
                      Icons.delete_rounded,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    "Hapus Laporan",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              Divider(color: Colors.white.withOpacity(0.1)),
              const SizedBox(height: 16),

              // Complaint title preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.redAccent.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.report_problem_rounded,
                      color: Colors.redAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        complaint.title,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                "Laporan yang dihapus tidak dapat dikembalikan. Apakah Anda yakin?",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 28),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.close, color: Colors.white54, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "Batal",
                              style: TextStyle(
                                color: Colors.white54,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        confirmed = true;
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.redAccent.withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_rounded, color: Colors.redAccent, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "Hapus",
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  if (!confirmed) return;

  try {
    await widget.api.deleteComplaint(complaint.id);
    if (mounted) _showSnack("Komplain berhasil dihapus");
    _refreshData(silent: true);
  } catch (e) {
    if (mounted)
      _showSnack(e.toString().replaceFirst("Exception: ", ""), isError: true);
  }
}

  // ── Snackbar ──────────────────────────────────────────────────────────────
  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isError
                      ? Colors.redAccent.withOpacity(0.5)
                      : _orange.withOpacity(0.5),
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isError
                          ? Colors.redAccent.withOpacity(0.15)
                          : _orange.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isError
                          ? Icons.error_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      color: isError ? Colors.redAccent : _orange,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      msg,
                      style: TextStyle(
                        color: isError ? Colors.redAccent : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Filter Bottom Sheet ───────────────────────────────────────────────────
  void _showFilterModal() {
    String tempStatus = _statusFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Filter Pencarian",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            setSheetState(() => tempStatus = 'all'),
                        child: const Text(
                          "Reset",
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Status Komplain",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _filterChip(
                        label: "Semua",
                        isSelected: tempStatus == 'all',
                        onTap: () => setSheetState(() => tempStatus = 'all'),
                      ),
                      _filterChip(
                        label: "Belum Di Cek",
                        isSelected: tempStatus == 'pending',
                        onTap: () =>
                            setSheetState(() => tempStatus = 'pending'),
                      ),
                      _filterChip(
                        label: "Lagi Diproses",
                        isSelected: tempStatus == 'in_progress',
                        onTap: () =>
                            setSheetState(() => tempStatus = 'in_progress'),
                      ),
                      _filterChip(
                        label: "Sudah Solusi",
                        isSelected: tempStatus == 'resolved',
                        onTap: () =>
                            setSheetState(() => tempStatus = 'resolved'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _statusFilter = tempStatus);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange.withOpacity(0.3),
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                          width: 0.9,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Terapkan Filter",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Active filter pill ────────────────────────────────────────────────────
  Widget _buildActiveFilterBar() {
    if (_statusFilter == 'all') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _activeChip(
        _statusLabelText(_statusFilter),
        () => setState(() => _statusFilter = 'all'),
      ),
    );
  }

  Widget _activeChip(String label, VoidCallback onRemove) => Container(
    padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
    decoration: BoxDecoration(
      color: _orange.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _orange.withOpacity(0.3), width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onRemove,
          child: const Icon(Icons.close, size: 16, color: Colors.orange),
        ),
      ],
    ),
  );

  Widget _filterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? _orange.withOpacity(0.25)
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? _orange.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? _orange.withOpacity(0.9) : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 13,
        ),
      ),
    ),
  );

  // ── Status badge ──────────────────────────────────────────────────────────
  Widget _complaintStatusBadge(String status) {
    final cfg = _statusConfig(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cfg.border, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: cfg.dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            cfg.label,
            style: TextStyle(
              color: cfg.text,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _statusConfig(String status) {
    switch (status) {
      case 'in_progress':
        return _StatusConfig(
          label: "Diproses",
          bg: Colors.blue.withOpacity(0.15),
          border: Colors.blue.withOpacity(0.4),
          dot: Colors.blueAccent,
          text: Colors.blueAccent,
        );
      case 'resolved':
        return _StatusConfig(
          label: "Selesai",
          bg: Colors.green.withOpacity(0.15),
          border: Colors.green.withOpacity(0.4),
          dot: Colors.greenAccent,
          text: Colors.greenAccent,
        );
      case 'rejected':
        return _StatusConfig(
          label: "Ditolak",
          bg: Colors.red.withOpacity(0.15),
          border: Colors.red.withOpacity(0.4),
          dot: Colors.redAccent,
          text: Colors.redAccent,
        );
      default:
        return _StatusConfig(
          label: "Pending",
          bg: Colors.orange.withOpacity(0.15),
          border: Colors.orange.withOpacity(0.4),
          dot: Colors.orangeAccent,
          text: Colors.orangeAccent,
        );
    }
  }

  String _statusLabelText(String status) {
    switch (status) {
      case 'in_progress':
        return "Lagi Diproses";
      case 'resolved':
        return "Sudah Solusi";
      case 'rejected':
        return "Ditolak";
      default:
        return "Belum Di Cek";
    }
  }

  // ── Count bar + Add button in one row ─────────────────────────────────────
  Widget _buildCountAndAddRow(int total, int filtered) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_rounded,
                size: 15,
                color: _orange.withOpacity(0.8),
              ),
              const SizedBox(width: 8),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$filtered',
                      style: TextStyle(
                        color: _orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const TextSpan(
                      text: ' Total Laporan',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InputComplaintScreen(onBack: () {}),
            ),
          ).then((_) => _refreshData(silent: true)),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _orange.withOpacity(0.28),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.18),
                width: 0.9,
              ),
              boxShadow: [
                BoxShadow(
                  color: _orange.withOpacity(0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.add_rounded, color: Colors.white, size: 20),
                SizedBox(width: 6),
                Text(
                  "Laporkan Kendala",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  // ── Action button ─────────────────────────────────────────────────────────
  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
  }) {
    final disabled = onPressed == null;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: disabled
              ? Colors.white.withOpacity(0.04)
              : color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: disabled ? Colors.white12 : color.withOpacity(0.4),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: disabled ? Colors.white24 : color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: disabled ? Colors.white24 : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Single complaint card ─────────────────────────────────────────────────
  Widget _buildComplaintCard(Complaint c) {
    final locked = _isLocked(c);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: TableCard(
        prefix: "Laporan",
        suffixText: _formatDate(c.reportDate),
        main: _truncateTitle(c.title ?? '-'),
        columnWidths: const {
          0: FlexColumnWidth(2.8),
          1: FlexColumnWidth(1.6),
          2: FlexColumnWidth(3.5),
        },
        columns: const ["Keterangan", "Status", "Aksi"],
        data: [
          {'object': c},
        ],
        rowBuilder: (item) {
          final complaint = item['object'] as Complaint;
          return [
            // Keterangan
            Text(
              complaint.solution != null && complaint.solution!.isNotEmpty
                  ? complaint.solution!
                  : complaint.description,
              style: const TextStyle(color: Colors.white70, fontSize: 12.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            // Status
            _complaintStatusBadge(complaint.status),

            // Aksi
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _actionBtn(
                  label: "View",
                  icon: Icons.remove_red_eye_rounded,
                  color: Colors.grey,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetailComplaintScreen(
                        complaint: complaint,
                      ),
                    ),
                  ).then((_) => _refreshData(silent: true)),
                ),
                const SizedBox(width: 6),
                _actionBtn(
                  label: "Hapus",
                  icon: Icons.delete_rounded,
                  color: locked ? Colors.white24 : Colors.redAccent,
                  onPressed: locked ? null : () => _deleteComplaint(complaint),
                ),
              ],
            ),
          ];
        },
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final filtered = _getFiltered(_complaints);

    return Scaffold(
      body: MainLayout(
        child: SafeArea(
          bottom: false,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryOrange,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 15),

                      AppHeader(
                        title: "Customer Care",
                        titleIcon: Icons.support_agent_rounded,
                        onBack: widget.onBack,
                        trailing: GestureDetector(
                          onTap: () => _refreshData(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.refresh_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      const PageHeader(
                        title: "Pusat Bantuan",
                        subtitle: "Braga8 Customer Care",
                      ),
                      const SizedBox(height: 30),

                      // Search + Filter
                      Row(
                        children: [
                          Expanded(
                            child: CustomSearchBar(
                              controller: _searchController,
                              hintText: "Cari laporan...",
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v),
                              onSearchPressed: () => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _showFilterModal,
                            child: Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: _orange.withOpacity(0.3),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 0.8,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.tune,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _buildActiveFilterBar(),

                      _buildCountAndAddRow(_complaints.length, filtered.length),

                      if (filtered.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Text(
                              "Data tidak ditemukan",
                              style: TextStyle(color: Colors.white38),
                            ),
                          ),
                        )
                      else
                        ...filtered.map(_buildComplaintCard),

                      const SizedBox(height: 150),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Status config helper ──────────────────────────────────────────────────────
class _StatusConfig {
  final String label;
  final Color bg;
  final Color border;
  final Color dot;
  final Color text;

  const _StatusConfig({
    required this.label,
    required this.bg,
    required this.border,
    required this.dot,
    required this.text,
  });
}
