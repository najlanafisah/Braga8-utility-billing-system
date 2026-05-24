// lib/views/screens/payment_logs_screen.dart
//
// ── HOW TO USE ───────────────────────────────────────────────────────────────
// 1. Drop this file into lib/views/screens/
// 2. Add fetchPaymentLogs() to ApiService.dart (snippet at bottom of file)
// 3. Navigate to it:
//      Navigator.push(context, MaterialPageRoute(
//        builder: (_) => PaymentLogsScreen(api: apiService),
//      ));
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:typed_data';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:braga8_mobile/ApiService.dart';
import 'package:braga8_mobile/data/models/invoice_detail_model.dart';
import 'package:braga8_mobile/core/app_colors.dart';
import 'package:braga8_mobile/views/widgets/app_header.dart';
import 'package:braga8_mobile/views/widgets/main_layouts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

class PaymentLog {
  final int id;
  final int invoiceId;
  final String invoiceNumber;
  final String unitNumber;
  final double amountPaid;
  final String paidUsing;
  final String? bankRekening;
  final String? proofImgUrl;
  final String status; // 'pending' | 'verified' | 'rejected'
  final DateTime? paymentDate;
  final String? notes;

  const PaymentLog({
    required this.id,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.unitNumber,
    required this.amountPaid,
    required this.paidUsing,
    this.bankRekening,
    required this.status,
    this.paymentDate,
    this.notes,
    this.proofImgUrl,
  });

  factory PaymentLog.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v) => switch (v) {
      int i => i,
      String s => int.tryParse(s) ?? 0,
      _ => 0,
    };

    double parseDouble(dynamic v) => switch (v) {
      num n => n.toDouble(),
      String s => double.tryParse(s) ?? 0,
      _ => 0,
    };

    String? resolveImg(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      if (raw.startsWith('http')) return raw;
      return 'http://172.16.4.22:8000/storage/$raw';
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    final invoice = json['invoice'] as Map<String, dynamic>? ?? {};

    return PaymentLog(
      id: parseInt(json['id']),
      invoiceId: parseInt(json['invoice_id']),
      invoiceNumber: invoice['invoice_number']?.toString() ?? '-',
      unitNumber:
          invoice['unit_number']?.toString() ??
          invoice['unit']?['unit_number']?.toString() ??
          '-',
      amountPaid: parseDouble(json['amount_paid']),
      paidUsing: json['paid_using']?.toString() ?? '-',
      proofImgUrl: resolveImg(json['proof_img']?.toString()),
      bankRekening: json['bank_rekening']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      paymentDate: parseDate(json['payment_date']),
      notes: json['notes']?.toString(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NGROK IMAGE
// Works on both Flutter Web (Image.network, CORS handled by backend) and
// physical device (dio bytes, follows redirects with auth header).
// ─────────────────────────────────────────────────────────────────────────────
class _NgrokImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? height;
  final double? width;

  const _NgrokImage({
    required this.url,
    this.height,
  }) : width = null, fit = BoxFit.cover;

  @override
  Widget build(BuildContext context) {
    final h = height ?? 180.0;
    // Force https — the API returns http:// for ngrok URLs
    final safeUrl = url;


    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        safeUrl,
        fit: fit,
        height: h,
        width: width ?? double.infinity,
        headers: const {'ngrok-skip-browser-warning': 'true'},
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            height: h,
            width: double.infinity,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          height: h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .03),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Icon(Icons.broken_image_rounded, color: Colors.white24),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class PaymentLogsScreen extends StatefulWidget {
  final ApiService api;
  const PaymentLogsScreen({super.key, required this.api});

  @override
  State<PaymentLogsScreen> createState() => _PaymentLogsScreenState();
}

class _PaymentLogsScreenState extends State<PaymentLogsScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  List<PaymentLog> _logs = [];

  late TabController _tabController;
  static const _tabs = ['Semua', 'Menunggu', 'Terverifikasi', 'Ditolak'];
  static const _tabKeys = ['all', 'pending', 'verified', 'rejected'];

  static const _orange = AppColors.primaryOrange;
  Color get _glass => Colors.white.withValues(alpha: .05);
  Color get _glassBorder => Colors.white.withValues(alpha: .10);

  final _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Fetch ──────────────────────────────────────────────────────────────────
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _logs = await widget.api.fetchPaymentLogs();
      _logs.sort((a, b) {
        final da = a.paymentDate ?? DateTime(2000);
        final db = b.paymentDate ?? DateTime(2000);
        return db.compareTo(da);
      });
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loading = false);
  }

  List<PaymentLog> get _filtered {
    final key = _tabKeys[_tabController.index];
    if (key == 'all') return _logs;
    return _logs.where((l) => l.status == key).toList();
  }

  Map<String, List<PaymentLog>> _groupByMonth(List<PaymentLog> logs) {
    final map = <String, List<PaymentLog>>{};
    for (final log in logs) {
      final dt = log.paymentDate ?? DateTime(2000, 1);
      final key = DateFormat('MMMM yyyy', 'id_ID').format(dt);
      map.putIfAbsent(key, () => []).add(log);
    }
    return map;
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: MainLayout(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: AppHeader(
                  title: 'Log Pembayaran',
                  titleIcon: Icons.receipt_long_rounded,
                  onBack: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(height: 12),
              _buildTabBar(),
              const SizedBox(height: 4),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab Bar ────────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: _glass,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _glassBorder),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicator: BoxDecoration(
                color: _orange.withValues(alpha: .22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _orange.withValues(alpha: .5), width: 1),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              labelColor: _orange,
              unselectedLabelColor: Colors.white54,
              tabs: List.generate(_tabs.length, (idx) {
                final cnt = idx == 0
                    ? _logs.length
                    : _logs.where((l) => l.status == _tabKeys[idx]).length;
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_tabs[idx]),
                      if (cnt > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: idx == _tabController.index
                                ? _orange.withValues(alpha: .3)
                                : Colors.white.withValues(alpha: .08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$cnt',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: idx == _tabController.index
                                  ? _orange
                                  : Colors.white38,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: _orange, strokeWidth: 2.5),
      );
    }
    if (_error != null) return _buildError();
    final filtered = _filtered;
    if (filtered.isEmpty) return _buildEmpty();

    final grouped = _groupByMonth(filtered);
    return RefreshIndicator(
      color: _orange,
      backgroundColor: const Color(0xFF1C1A1E),
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: grouped.length,
        itemBuilder: (_, i) {
          final month = grouped.keys.elementAt(i);
          return _buildMonthSection(month, grouped[month]!);
        },
      ),
    );
  }

  // ── Month Section ──────────────────────────────────────────────────────────
  Widget _buildMonthSection(String month, List<PaymentLog> logs) {
    final total = logs.fold<double>(0, (s, l) => s + l.amountPaid);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 4),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: _orange,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                month.toUpperCase(),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: _orange,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                _rupiah.format(total),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
        ...logs.map((log) => _buildLogCard(log)),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Log Card ───────────────────────────────────────────────────────────────
  Widget _buildLogCard(PaymentLog log) {
    final sc = _statusColor(log.status);
    return GestureDetector(
      onTap: () => _openDetail(log),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _glass,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _glassBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: sc.withValues(alpha: .12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: sc.withValues(alpha: .35),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(_statusIcon(log.status), color: sc, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.invoiceNumber,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.meeting_room_rounded,
                              size: 11,
                              color: Colors.white38,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Unit ${log.unitNumber}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white38,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.payment_rounded,
                              size: 11,
                              color: Colors.white38,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                log.paidUsing,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white38,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (log.paymentDate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            DateFormat(
                              'd MMMM yyyy',
                              'id_ID',
                            ).format(log.paymentDate!),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white24,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _rupiah.format(log.amountPaid),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _orange,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: sc.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: sc.withValues(alpha: .3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _statusLabel(log.status),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: sc,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Colors.white24,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Open Detail ────────────────────────────────────────────────────────────
  void _openDetail(PaymentLog log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentDetailSheet(
        log: log,
        api: widget.api,
        rupiah: _rupiah,
        token: widget.api.token,
      ),
    );
  }

  // ── Empty / Error ──────────────────────────────────────────────────────────
  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _orange.withValues(alpha: .08),
            shape: BoxShape.circle,
            border: Border.all(color: _orange.withValues(alpha: .25), width: 1.5),
          ),
          child: Icon(
            Icons.receipt_long_rounded,
            color: _orange.withValues(alpha: .5),
            size: 32,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Belum ada riwayat pembayaran',
          style: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Pembayaran yang sudah dikirim\nakan muncul di sini.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white38, fontSize: 12.5),
        ),
      ],
    ),
  );

  Widget _buildError() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: Colors.redAccent,
          size: 40,
        ),
        const SizedBox(height: 12),
        Text(
          _error ?? 'Terjadi kesalahan',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Coba Lagi'),
          style: TextButton.styleFrom(foregroundColor: _orange),
        ),
      ],
    ),
  );

  Color _statusColor(String s) => switch (s) {
    'verified' => const Color(0xFF34D399),
    'rejected' => Colors.redAccent,
    _ => Colors.amber,
  };

  String _statusLabel(String s) => switch (s) {
    'verified' => 'Terverifikasi',
    'rejected' => 'Ditolak',
    _ => 'Menunggu',
  };

  IconData _statusIcon(String s) => switch (s) {
    'verified' => Icons.check_circle_rounded,
    'rejected' => Icons.cancel_rounded,
    _ => Icons.hourglass_top_rounded,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// DETAIL BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentDetailSheet extends StatefulWidget {
  final PaymentLog log;
  final ApiService api;
  final NumberFormat rupiah;
  final String? token;

  const _PaymentDetailSheet({
    required this.log,
    required this.api,
    required this.rupiah,
    this.token,
  });

  @override
  State<_PaymentDetailSheet> createState() => _PaymentDetailSheetState();
}

class _PaymentDetailSheetState extends State<_PaymentDetailSheet> {
  static const _orange = AppColors.primaryOrange;
  Color get _glass => Colors.white.withValues(alpha: .05);
  Color get _glassBorder => Colors.white.withValues(alpha: .10);

  // Pass ngrok header so images don't redirect to the browser warning page
  static const _imgHeaders = {'ngrok-skip-browser-warning': 'true'};

  InvoiceDetail? _detail;
  bool _loadingDetail = true;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final d = await widget.api.fetchInvoiceDetail(widget.log.invoiceId);
      if (mounted) setState(() => _detail = d);
    } catch (_) {
      // show basic payment info only — invoice detail optional
    }
    if (mounted) setState(() => _loadingDetail = false);
  }

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    final sc = _statusColor(log.status);

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      builder: (_, scrollCtrl) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF131115).withValues(alpha: .96),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(color: _glassBorder),
                left: BorderSide(color: _glassBorder),
                right: BorderSide(color: _glassBorder),
              ),
            ),
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // ── Header ─────────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: sc.withValues(alpha: .10),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: sc.withValues(alpha: .35),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(_statusIcon(log.status), color: sc, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log.invoiceNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _statusChip(log.status),
                              const SizedBox(width: 8),
                              Text(
                                'Unit ${log.unitNumber}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white38,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _glass,
                          shape: BoxShape.circle,
                          border: Border.all(color: _glassBorder),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Amount hero ─────────────────────────────────────────────
                _glassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 13,
                            color: _orange.withValues(alpha: .7),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Total Dibayar',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: .4),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.rupiah.format(log.amountPaid),
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: _orange,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Metadata ────────────────────────────────────────────────
                _glassCard(
                  child: Column(
                    children: [
                      _detailRow(
                        Icons.payment_rounded,
                        'Metode',
                        log.paidUsing,
                      ),
                      if (log.bankRekening != null) ...[
                        const Divider(color: Colors.white10, height: 20),
                        _detailRow(
                          Icons.numbers_rounded,
                          'No. Rekening',
                          log.bankRekening!,
                        ),
                      ],
                      const Divider(color: Colors.white10, height: 20),
                      _detailRow(
                        Icons.calendar_today_rounded,
                        'Tanggal Bayar',
                        log.paymentDate != null
                            ? DateFormat(
                                'd MMMM yyyy, HH:mm',
                                'id_ID',
                              ).format(log.paymentDate!)
                            : '-',
                      ),
                      if (log.notes != null && log.notes!.isNotEmpty) ...[
                        const Divider(color: Colors.white10, height: 20),
                        _detailRow(Icons.notes_rounded, 'Catatan', log.notes!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Proof photo ─────────────────────────────────────────────
                if (widget.log.proofImgUrl != null) ...[
                  _sectionTitle('Bukti Pembayaran', Icons.photo_rounded),
                  const SizedBox(height: 10),

                  _NgrokImage(url: widget.log.proofImgUrl!, height: 220),
                  const SizedBox(height: 14),
                ],
                // ── Invoice items ────────────────────────────────────────────
                _sectionTitle('Detail Invoice', Icons.receipt_long_rounded),
                const SizedBox(height: 10),

                if (_loadingDetail)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        color: _orange,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                else if (_detail != null && _detail!.items.isNotEmpty)
                  _glassCard(
                    child: Column(
                      children: [
                        ...List.generate(_detail!.items.length, (i) {
                          final item = _detail!.items[i];
                          return Column(
                            children: [
                              if (i > 0)
                                const Divider(
                                  color: Colors.white10,
                                  height: 20,
                                ),
                              Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: _orange.withValues(alpha: .1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${i + 1}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: _orange,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item.description,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.rupiah.format(item.amount),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _orange,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }),
                        const Divider(color: Colors.white24, height: 24),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Text(
                              widget.rupiah.format(
                                _detail!.items.fold<double>(
                                  0,
                                  (s, e) => s + e.amount,
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: _orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else
                  _glassCard(
                    child: const Center(
                      child: Text(
                        'Detail item tidak tersedia',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ),
                  ),

                // ── Meter photos ─────────────────────────────────────────────
                if (_detail != null && _detail!.meterPhotos.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _sectionTitle('Foto Meter', Icons.electric_meter_rounded),
                  const SizedBox(height: 10),
                  Column(
                    children: _detail!.meterPhotos
                        .map(
                          (mp) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildMeterPhotoCard(mp),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Meter Photo Card ───────────────────────────────────────────────────────

  Widget _buildMeterPhotoCard(MeterPhoto mp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 370,
          height: 220,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (mp.photoUrl != null)
                Image.network(
                  mp.photoUrl!,
                  headers: _imgHeaders,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: Colors.white.withValues(alpha: .04),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: _orange,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => _meterPlaceholder(mp),
                )
              else
                _meterPlaceholder(mp),
              // Gradient label overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 28, 10, 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: .82),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            mp.isElectric
                                ? Icons.electric_bolt_rounded
                                : Icons.water_drop_rounded,
                            size: 11,
                            color: mp.isElectric
                                ? Colors.amber
                                : Colors.lightBlue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            mp.isElectric ? 'Listrik' : 'Air',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: mp.isElectric
                                  ? Colors.amber
                                  : Colors.lightBlue,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        mp.readingValue,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (mp.recordedAt != null)
                        Text(
                          _shortDate(mp.recordedAt!),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white54,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _meterPlaceholder(MeterPhoto mp) => Container(
    color: Colors.white.withValues(alpha: .03),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          mp.isElectric
              ? Icons.electric_bolt_rounded
              : Icons.water_drop_rounded,
          color: mp.isElectric ? Colors.amber : Colors.lightBlue,
          size: 32,
        ),
        const SizedBox(height: 6),
        const Text(
          'Tidak ada foto',
          style: TextStyle(color: Colors.white24, fontSize: 11),
        ),
      ],
    ),
  );

  // ── Shared helpers ─────────────────────────────────────────────────────────
  Widget _glassCard({required Widget child, EdgeInsets? padding}) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        width: double.infinity,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _glass,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _glassBorder),
        ),
        child: child,
      ),
    ),
  );

  Widget _sectionTitle(String title, IconData icon) => Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Row(
      children: [
        Icon(icon, size: 16, color: _orange),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );

  Widget _detailRow(IconData icon, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: _orange.withValues(alpha: .7)),
      const SizedBox(width: 10),
      SizedBox(
        width: 90,
        child: Text(
          label,
          style: const TextStyle(fontSize: 12.5, color: Colors.white38),
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    ],
  );

  Widget _statusChip(String s) {
    final sc = _statusColor(s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: sc.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sc.withValues(alpha: .3)),
      ),
      child: Text(
        _statusLabel(s),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: sc),
      ),
    );
  }

  String _shortDate(String raw) {
    try {
      return DateFormat('d MMM yyyy', 'id_ID').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  Color _statusColor(String s) => switch (s) {
    'verified' => const Color(0xFF34D399),
    'rejected' => Colors.redAccent,
    _ => Colors.amber,
  };

  String _statusLabel(String s) => switch (s) {
    'verified' => 'Terverifikasi',
    'rejected' => 'Ditolak',
    _ => 'Menunggu',
  };

  IconData _statusIcon(String s) => switch (s) {
    'verified' => Icons.check_circle_rounded,
    'rejected' => Icons.cancel_rounded,
    _ => Icons.hourglass_top_rounded,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// PASTE THIS INTO ApiService.dart  (inside the ApiService class body)
// ─────────────────────────────────────────────────────────────────────────────
//
//  /// GET /api/payments
//  /// Returns all payments belonging to the authenticated user/tenant.
//  /// Backend must eager-load the invoice relation, e.g.:
//  ///   Payment::with('invoice.unit')->whereHas(...)->latest()->get()
//  Future<List<PaymentLog>> fetchPaymentLogs() async {
//    try {
//      final response = await dio.get('/payments', options: _authOptions());
//      final List raw = response.data['data'] ?? response.data;
//      return raw.map((e) => PaymentLog.fromJson(e as Map<String, dynamic>)).toList();
//    } on DioException catch (e) {
//      debugPrint('fetchPaymentLogs Error: ${e.response?.data}');
//      return [];
//    }
//  }
//
// ─────────────────────────────────────────────────────────────────────────────
