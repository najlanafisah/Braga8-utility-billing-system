import 'dart:ui';
import 'package:braga8_mobile/ApiService.dart';
import 'package:braga8_mobile/data/models/invoice_model.dart';
import 'package:braga8_mobile/data/models/invoice_detail_model.dart';
import 'package:braga8_mobile/core/app_colors.dart';
import 'package:braga8_mobile/views/invoice/components/invoice_modal.dart';
import 'package:braga8_mobile/views/invoice/export_excel_function.dart';
import 'package:braga8_mobile/views/widgets/app_header.dart';
import 'package:braga8_mobile/views/widgets/main_layouts.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:braga8_mobile/views/payments/input_payment_screen.dart';
import 'package:braga8_mobile/utilities/file_saver.dart';

// ---------------------------------------------------------------------------
// HELPERS
// ---------------------------------------------------------------------------

String _rupiah(double amount) => NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
).format(amount);

String _fmtDate(DateTime d) => DateFormat('dd MMMM yyyy', 'id_ID').format(d);

// ---------------------------------------------------------------------------
// SCREEN
// ---------------------------------------------------------------------------

class DetailInvoiceScreen extends StatefulWidget {
  final ApiService api;
  final Invoice invoice;

  const DetailInvoiceScreen({
    super.key,
    required this.api,
    required this.invoice,
  });

  @override
  State<DetailInvoiceScreen> createState() => _DetailInvoiceScreenState();
}

class _DetailInvoiceScreenState extends State<DetailInvoiceScreen>
    with SingleTickerProviderStateMixin {
  late Future<InvoiceDetail> _detailFuture;

  /// Cached detail so export button can access .items outside FutureBuilder scope.
  InvoiceDetail? _loadedDetail;

  /// Local copy of the invoice — refreshed when we re-fetch.
  Invoice? _invoiceState;
  Invoice get _invoice => _invoiceState ?? widget.invoice;

  /// True once the user has submitted a payment proof (pending verification).
  bool _paymentPending = false;

  bool _exportingExcel = false;
  bool _paying = false;

  AnimationController? _animController;
  Animation<double>? _fadeAnim;

  // ── theme shortcuts ──────────────────────────────────────────────────────
  static const _orange = AppColors.primaryOrange;
  Color get _orangeDim => _orange.withOpacity(0.15);
  Color get _orangeBorder => _orange.withOpacity(0.40);
  Color get _glass => Colors.white.withOpacity(0.05);
  Color get _glassBorder => Colors.white.withOpacity(0.10);

  // ---------------------------------------------------------------------------
  // LIFECYCLE
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController!,
      curve: Curves.easeOut,
    );
    _animController!.forward();

    // ✅ Initialize immediately so FutureBuilder never sees an uninitialized late field
    _detailFuture = widget.api.fetchInvoiceDetail(widget.invoice.id);
    _fetchData(); // this will reassign it, but now the first frame is safe
  }

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // DATA FETCHING — called on init AND on refresh button tap
  // ---------------------------------------------------------------------------

  /// Fetches both the fresh invoice header (status) AND its detail items/photos.
  /// Exposed so the AppHeader refresh button can call it directly.
  void _fetchData() {
    final newFuture = widget.api.fetchInvoiceDetail(_invoice.id).then((detail) {
      if (mounted) setState(() => _loadedDetail = detail);
      return detail;
    });

    // ✅ Assign immediately — don't wait for the summary call
    setState(() {
      _loadedDetail = null;
      _detailFuture = newFuture;
    });

    widget.api
        .fetchInvoicesSummary()
        .then((groups) {
          if (!mounted) return;
          for (final group in groups) {
            for (final inv in group.invoices) {
              if (inv.id == widget.invoice.id) {
                debugPrint(
                  '✅ Found invoice ${inv.id}, isPaid=${inv.isPaid}, status=${inv.status}',
                );
                setState(() {
                  _invoiceState = inv;
                  if (inv.isPaid) {
                    _paymentPending = false;
                  } else if (inv.status == 'unpaid') {
                    // Payment was deleted or rejected — reset the pending flag
                    _paymentPending = false;
                  }
                });
                return;
              }
            }
          }
          debugPrint(
            '❌ Invoice ${widget.invoice.id} NOT found in summary response',
          );
        })
        .catchError((e) {
          debugPrint('❌ fetchInvoicesSummary error: $e');
        });
  }

  // ---------------------------------------------------------------------------
  // PAY NOW — show confirmation modal first, then navigate to payment screen
  // ---------------------------------------------------------------------------

  Future<void> _payNow() async {
    // Step 1: Show the confirmation bottom-sheet modal.
    final confirmed = await showPaymentConfirmModal(context, _invoice);
    if (confirmed != true || !mounted) return;

    // Step 2: Navigate to the payment proof input screen.
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => InputPaymentScreen(
          invoice: _invoice,
          api: widget.api,
          onSuccess: () {},
        ),
      ),
    );

    // Step 3: Payment proof submitted — status is now "pending" on the backend.
    // Show a local pending badge without marking as fully paid.
    if (result == true && mounted) {
      setState(() => _paymentPending = true);
      // Also pop back to the list so it can refresh its own state.
      Navigator.pop(context, true);
    }
  }

  // ---------------------------------------------------------------------------
  // SNACK
  // ---------------------------------------------------------------------------

  void _showSnack(String msg, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: color.withOpacity(0.88),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(msg, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final inv = _invoice;

    return Scaffold(
      body: MainLayout(
        child: SafeArea(
          bottom: false,
          child: FutureBuilder<InvoiceDetail>(
            future: _detailFuture,
            builder: (context, snap) {
              final isLoading = snap.connectionState == ConnectionState.waiting;
              final hasError = snap.hasError;
              final detail = snap.data;

              if (hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Gagal memuat detail invoice.\n${snap.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white54),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () => setState(() => _fetchData()),
                          icon: const Icon(
                            Icons.refresh,
                            color: AppColors.primaryOrange,
                          ),
                          label: const Text(
                            'Coba Lagi',
                            style: TextStyle(color: AppColors.primaryOrange),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: _orange.withOpacity(0.4)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return FadeTransition(
                opacity: _fadeAnim ?? const AlwaysStoppedAnimation(1.0),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 15),

                            // ── APP HEADER with refresh trailing ──────────
                            AppHeader(
                              title: 'Detail Invoice',
                              titleIcon: Icons.receipt_long_outlined,
                              onBack: () => Navigator.pop(context),
                              trailing: GestureDetector(
                                onTap: () => _fetchData(),
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
                            const SizedBox(height: 24),

                            _buildSummaryCard(inv),
                            const SizedBox(height: 20),

                            _sectionLabel(
                              Icons.calendar_month_outlined,
                              'Periode Tagihan',
                            ),
                            const SizedBox(height: 12),
                            _buildPeriodCard(inv),
                            const SizedBox(height: 20),

                            _sectionLabel(
                              Icons.list_alt_rounded,
                              'Rincian Tarif',
                            ),
                            const SizedBox(height: 12),
                            isLoading
                                ? _buildLoadingCard()
                                : _buildTariffTable(detail?.items ?? []),
                            const SizedBox(height: 20),

                            _sectionLabel(
                              Icons.water_drop_outlined,
                              'Foto Meteran Air',
                            ),
                            const SizedBox(height: 12),
                            isLoading
                                ? _buildLoadingCard()
                                : _buildPhotoSection(
                                    photos: detail?.meterPhotos ?? [],
                                    filterElectric: false,
                                  ),
                            const SizedBox(height: 20),

                            _sectionLabel(
                              Icons.bolt_outlined,
                              'Foto Meteran Listrik',
                            ),
                            const SizedBox(height: 12),
                            isLoading
                                ? _buildLoadingCard()
                                : _buildPhotoSection(
                                    photos: detail?.meterPhotos ?? [],
                                    filterElectric: true,
                                  ),
                            const SizedBox(height: 24),

                            _buildExportButton(),
                            const SizedBox(height: 28),
                          ],
                        ),
                      ),
                    ),

                    // ── FOOTER ─────────────────────────────────────────────
                    _buildFooter(inv),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // LOADING CARD
  // ---------------------------------------------------------------------------

  Widget _buildLoadingCard() {
    return _glassCard(
      child: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: CircularProgressIndicator(
            color: AppColors.primaryOrange,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION LABEL
  // ---------------------------------------------------------------------------

  Widget _sectionLabel(IconData icon, String title) => Row(
    children: [
      Icon(icon, size: 16, color: _orange),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      ),
    ],
  );

  // ---------------------------------------------------------------------------
  // GLASS CARD
  // ---------------------------------------------------------------------------

  Widget _glassCard({required Widget child, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _glass,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _glassBorder, width: 1),
          ),
          child: child,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SUMMARY CARD
  // ---------------------------------------------------------------------------

  Widget _buildSummaryCard(Invoice inv) {
    final isPaid = inv.isPaid;
    final isPending = _paymentPending && !isPaid;

    // Determine card accent based on status
    final Color accentColor = isPaid
        ? Colors.green
        : isPending
        ? Colors.amber
        : _orange;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPaid
                  ? [
                      Colors.green.withOpacity(0.16),
                      Colors.teal.withOpacity(0.08),
                    ]
                  : isPending
                  ? [
                      Colors.amber.withOpacity(0.16),
                      Colors.orange.withOpacity(0.07),
                    ]
                  : [
                      _orange.withOpacity(0.16),
                      Colors.deepOrange.withOpacity(0.07),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accentColor.withOpacity(0.28),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    color: isPaid
                        ? Colors.greenAccent
                        : isPending
                        ? Colors.amber
                        : _orange,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      inv.invoiceNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusPill(isPaid: isPaid, isPending: isPending),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Unit ${inv.unitNumber}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Divider(
                  color: Colors.white.withOpacity(0.08),
                  height: 1,
                ),
              ),
              Text(
                'Total Pembayaran',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 11,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _rupiah(inv.totalAmount),
                style: TextStyle(
                  color: isPaid
                      ? Colors.greenAccent
                      : isPending
                      ? Colors.amber
                      : _orange,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PERIOD CARD
  // ---------------------------------------------------------------------------

  Widget _buildPeriodCard(Invoice inv) {
    return _glassCard(
      child: Row(
        children: [
          Expanded(
            child: _periodCol(
              label: 'Mulai',
              value: _fmtDate(inv.billingPeriodStart),
              icon: Icons.calendar_today_outlined,
            ),
          ),
          Container(
            width: 1,
            height: 44,
            color: Colors.white.withOpacity(0.08),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(
            child: _periodCol(
              label: 'Selesai',
              value: _fmtDate(inv.billingPeriodEnd),
              icon: Icons.event_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodCol({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: _orange),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.4),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TARIFF TABLE
  // ---------------------------------------------------------------------------

  Widget _buildTariffTable(List<InvoiceItem> items) {
    if (items.isEmpty) {
      return _glassCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text(
              'Rincian tarif tidak tersedia',
              style: TextStyle(
                color: Colors.white.withOpacity(0.3),
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }

    return _glassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Komponen',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.4),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  'Jumlah',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.4),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Item rows
          ...items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            final item = e.value;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _iconForItem(item.description),
                        size: 14,
                        color: _colorForItem(
                          item.description,
                        ).withOpacity(0.85),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      Text(
                        _rupiah(item.amount),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Divider(
                    color: Colors.white.withOpacity(0.06),
                    height: 1,
                    indent: 42,
                    endIndent: 16,
                  ),
              ],
            );
          }),

          // Total row
          Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: _orangeDim,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _orangeBorder, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 16,
                  color: _orange.withOpacity(0.8),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'TOTAL',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                Text(
                  _rupiah(_invoice.totalAmount),
                  style: TextStyle(
                    color: _orange,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForItem(String desc) {
    final d = desc.toLowerCase();
    if (d.contains('air')) return Icons.water_drop_outlined;
    if (d.contains('listrik') && d.contains('pemakaian'))
      return Icons.bolt_outlined;
    if (d.contains('beban')) return Icons.electrical_services_outlined;
    if (d.contains('trafo')) return Icons.build_outlined;
    if (d.contains('admin')) return Icons.admin_panel_settings_outlined;
    if (d.contains('materai')) return Icons.local_post_office_outlined;
    if (d.contains('ppn') || d.contains('%')) return Icons.percent_rounded;
    if (d.contains('pembulatan')) return Icons.tune_rounded;
    return Icons.more_horiz_rounded;
  }

  Color _colorForItem(String desc) {
    final d = desc.toLowerCase();
    if (d.contains('air')) return Colors.lightBlueAccent;
    if (d.contains('listrik') && d.contains('pemakaian'))
      return Colors.amberAccent;
    if (d.contains('beban')) return Colors.orangeAccent;
    if (d.contains('trafo')) return Colors.blueGrey;
    if (d.contains('admin')) return Colors.purpleAccent;
    if (d.contains('materai')) return Colors.redAccent;
    if (d.contains('ppn') || d.contains('%')) return Colors.tealAccent;
    if (d.contains('pembulatan')) return Colors.white30;
    return Colors.white38;
  }

  // ---------------------------------------------------------------------------
  // PHOTO SECTION
  // ---------------------------------------------------------------------------

  Widget _buildPhotoSection({
    required List<MeterPhoto> photos,
    required bool filterElectric,
  }) {
    final filtered = photos
        .where((p) => p.isElectric == filterElectric)
        .toList();

    if (filtered.isEmpty) {
      return _glassCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white.withOpacity(0.2),
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  'Belum ada foto meteran',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.28),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: filtered
          .map(
            (photo) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _MeterPhotoCard(photo: photo),
            ),
          )
          .toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // EXPORT BUTTON
  // ---------------------------------------------------------------------------

  Widget _buildExportButton() {
    final ready = _loadedDetail != null && !_exportingExcel;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: ready
            ? () async {
                setState(() => _exportingExcel = true);
                await exportInvoiceExcel(
                  context: context,
                  api: widget.api,
                  // Pass the refreshed invoice so the exported status
                  // reflects the latest value fetched from the backend.
                  invoice: _invoice,
                  items: _loadedDetail!.items,
                );
                if (mounted) setState(() => _exportingExcel = false);
              }
            : null,
        icon: _exportingExcel
            ? const SizedBox(
                width: 16,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white38,
                ),
              )
            : const Icon(
                Icons.table_chart_outlined,
                size: 18,
                color: Colors.greenAccent,
              ),
        label: Text(
          _exportingExcel
              ? 'Mengekspor...'
              : _loadedDetail == null
              ? 'Memuat...'
              : 'Export Excel',
          style: TextStyle(
            color: ready ? Colors.greenAccent : Colors.white38,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: ready
                ? Colors.greenAccent.withOpacity(0.38)
                : Colors.white12,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FOOTER
  // ---------------------------------------------------------------------------

  Widget _buildFooter(Invoice inv) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        30 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.07))),
      ),
      child: inv.isPaid
          ? _paidBadge()
          : _paymentPending
          ? _pendingBadge()
          : _payButton(),
    );
  }

  Widget _payButton() {
    return GestureDetector(
      onTap: _paying ? null : _payNow,
      child: Opacity(
        opacity: _paying ? 0.7 : 1.0,
        child: Container(
          height: 55,
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            gradient: const RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [Color(0xFF1A1A1A), Color(0xFF808080)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7A4A2D).withOpacity(0.5),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: const Color(0xFFFA6C2A).withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 77, 36, 15),
              borderRadius: BorderRadius.circular(14.5),
            ),
            alignment: Alignment.center,
            child: _paying
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.payment_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Bayar Sekarang',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  /// Shown while payment proof is submitted but not yet verified by admin.
  Widget _pendingBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withOpacity(0.28)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_top_rounded, color: Colors.amber, size: 20),
          SizedBox(width: 10),
          Text(
            'Menunggu Verifikasi Admin',
            style: TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  /// Shown once admin has verified the payment (invoice.isPaid == true).
  Widget _paidBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withOpacity(0.28)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
          SizedBox(width: 10),
          Text(
            'Invoice Sudah Terbayar',
            style: TextStyle(
              color: Colors.greenAccent,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// METER PHOTO CARD
// ---------------------------------------------------------------------------

class _MeterPhotoCard extends StatelessWidget {
  final MeterPhoto photo;
  const _MeterPhotoCard({required this.photo});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.09)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: photo.photoUrl != null
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              _FullScreenPhoto(url: photo.photoUrl!),
                        ),
                      )
                    : null,
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: photo.photoUrl != null
                      ? Image.network(
                          photo.photoUrl!,
                          fit: BoxFit.cover,
                          headers: const {'ngrok-skip-browser-warning': 'true'},
                          loadingBuilder: (_, child, progress) =>
                              progress == null
                              ? child
                              : const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.primaryOrange,
                                    strokeWidth: 2,
                                  ),
                                ),
                          errorBuilder: (_, __, ___) => _PhotoError(),
                        )
                      : _PhotoError(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MeterTypeChip(isElectric: photo.isElectric),
                    const SizedBox(height: 10),
                    _MetaRow(
                      icon: Icons.speed_outlined,
                      label: 'Angka Meter',
                      value:
                          '${photo.readingValue} ${photo.isElectric ? 'kWh' : 'm³'}',
                    ),
                    if (photo.recordedAt != null) ...[
                      const SizedBox(height: 5),
                      _MetaRow(
                        icon: Icons.schedule_outlined,
                        label: 'Dicatat',
                        value: photo.recordedAt!,
                      ),
                    ],
                  ],
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
// SMALL WIDGETS
// ---------------------------------------------------------------------------

class _StatusPill extends StatelessWidget {
  final bool isPaid;
  final bool isPending;
  const _StatusPill({required this.isPaid, this.isPending = false});

  @override
  Widget build(BuildContext context) {
    final Color bg = isPaid
        ? Colors.green.withOpacity(0.18)
        : isPending
        ? Colors.amber.withOpacity(0.18)
        : Colors.redAccent.withOpacity(0.14);

    final Color border = isPaid
        ? Colors.green.withOpacity(0.38)
        : isPending
        ? Colors.amber.withOpacity(0.38)
        : Colors.redAccent.withOpacity(0.32);

    final Color textColor = isPaid
        ? Colors.greenAccent
        : isPending
        ? Colors.amber
        : Colors.redAccent;

    final String label = isPaid
        ? 'Lunas'
        : isPending
        ? 'Menunggu'
        : 'Belum Lunas';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _MeterTypeChip extends StatelessWidget {
  final bool isElectric;
  const _MeterTypeChip({required this.isElectric});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: isElectric
          ? Colors.amberAccent.withOpacity(0.14)
          : Colors.lightBlueAccent.withOpacity(0.14),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isElectric
            ? Colors.amberAccent.withOpacity(0.28)
            : Colors.lightBlueAccent.withOpacity(0.28),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isElectric ? Icons.bolt : Icons.water_drop_outlined,
          size: 12,
          color: isElectric ? Colors.amberAccent : Colors.lightBlueAccent,
        ),
        const SizedBox(width: 4),
        Text(
          isElectric ? 'Listrik' : 'Air',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isElectric ? Colors.amberAccent : Colors.lightBlueAccent,
          ),
        ),
      ],
    ),
  );
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int maxLines;
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 13, color: Colors.white30),
      const SizedBox(width: 6),
      Text(
        '$label: ',
        style: const TextStyle(color: Colors.white38, fontSize: 12),
      ),
      Expanded(
        child: Text(
          value,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ),
    ],
  );
}

class _PhotoError extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.white.withOpacity(0.03),
    child: const Center(
      child: Icon(Icons.broken_image_outlined, color: Colors.white24, size: 36),
    ),
  );
}

// ---------------------------------------------------------------------------
// FULL SCREEN PHOTO VIEWER
// ---------------------------------------------------------------------------

class _FullScreenPhoto extends StatelessWidget {
  final String url;
  const _FullScreenPhoto({required this.url});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    body: Center(
      child: InteractiveViewer(
        child: Image.network(
          url,
          headers: const {'ngrok-skip-browser-warning': 'true'},
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Icon(
            Icons.broken_image_outlined,
            color: Colors.white30,
            size: 60,
          ),
        ),
      ),
    ),
  );
}
