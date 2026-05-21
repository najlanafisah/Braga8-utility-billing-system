import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:braga8_mobile/views/payments/payment_logs_screen.dart';
import 'package:braga8_mobile/views/payments/payment_sucess_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:braga8_mobile/ApiService.dart';
import 'package:braga8_mobile/data/models/invoice_model.dart';
import 'package:braga8_mobile/core/app_colors.dart';
import 'package:braga8_mobile/views/widgets/app_header.dart';
import 'package:braga8_mobile/views/widgets/main_layouts.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// Payment method model
// ---------------------------------------------------------------------------
class _PaymentMethod {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _PaymentMethod({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

const List<_PaymentMethod> _kPaymentMethods = [
  _PaymentMethod(
    id: 'transfer_bca',
    label: 'BCA Transfer',
    subtitle: 'Bank Central Asia',
    icon: Icons.account_balance_rounded,
    color: Color(0xFF005BAA),
  ),
  _PaymentMethod(
    id: 'transfer_mandiri',
    label: 'Mandiri Transfer',
    subtitle: 'Bank Mandiri',
    icon: Icons.account_balance_rounded,
    color: Color(0xFF003087),
  ),
  _PaymentMethod(
    id: 'transfer_bni',
    label: 'BNI Transfer',
    subtitle: 'Bank Negara Indonesia',
    icon: Icons.account_balance_rounded,
    color: Color(0xFFFF6200),
  ),
  _PaymentMethod(
    id: 'transfer_bri',
    label: 'BRI Transfer',
    subtitle: 'Bank Rakyat Indonesia',
    icon: Icons.account_balance_rounded,
    color: Color(0xFF00529B),
  ),
  _PaymentMethod(
    id: 'gopay',
    label: 'GoPay',
    subtitle: 'Dompet Digital Gojek',
    icon: Icons.account_balance_wallet_rounded,
    color: Color(0xFF00AED6),
  ),
  _PaymentMethod(
    id: 'ovo',
    label: 'OVO',
    subtitle: 'Dompet Digital OVO',
    icon: Icons.account_balance_wallet_rounded,
    color: Color(0xFF4C3494),
  ),
  _PaymentMethod(
    id: 'dana',
    label: 'DANA',
    subtitle: 'Dompet Digital DANA',
    icon: Icons.account_balance_wallet_rounded,
    color: Color(0xFF118EEA),
  ),
  _PaymentMethod(
    id: 'shopeepay',
    label: 'ShopeePay',
    subtitle: 'Dompet Digital Shopee',
    icon: Icons.account_balance_wallet_rounded,
    color: Color(0xFFEE4D2D),
  ),
  _PaymentMethod(
    id: 'qris',
    label: 'QRIS',
    subtitle: 'Scan QR Code',
    icon: Icons.qr_code_rounded,
    color: Color(0xFF2D9B46),
  ),
  _PaymentMethod(
    id: 'cash',
    label: 'Tunai',
    subtitle: 'Pembayaran Langsung',
    icon: Icons.payments_rounded,
    color: Color(0xFF43A047),
  ),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class InputPaymentScreen extends StatefulWidget {
  final Invoice invoice;
  final ApiService api;
  final VoidCallback? onSuccess;

  const InputPaymentScreen({
    super.key,
    required this.invoice,
    required this.api,
    this.onSuccess,
  });

  @override
  State<InputPaymentScreen> createState() => _InputPaymentScreenState();
}

class _InputPaymentScreenState extends State<InputPaymentScreen>
    with SingleTickerProviderStateMixin {
  // ── Form ──────────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  // ── State ─────────────────────────────────────────────────────────────────────
  _PaymentMethod? _selectedMethod;
  XFile? _proofXFile;
  Uint8List? _proofBytes;
  bool _isSubmitting = false;

  // ── Services ──────────────────────────────────────────────────────────────────
  final _picker = ImagePicker();

  // ── Animation ─────────────────────────────────────────────────────────────────
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // ── Theme ─────────────────────────────────────────────────────────────────────
  static const _orange = AppColors.primaryOrange;
  Color get _orangeDim => _orange.withOpacity(0.22);
  Color get _orangeBorder => _orange.withOpacity(0.45);
  Color get _glass => Colors.white.withOpacity(0.05);
  Color get _glassBorder => Colors.white.withOpacity(0.12);

  // ── Helpers ───────────────────────────────────────────────────────────────────
  String get _rupiahTotal => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(widget.invoice.totalAmount);

  int get _filledSteps {
    int n = 0;
    // step 1 — total is always shown
    n++;
    if (_selectedMethod != null) n++;
    if (_proofXFile != null) n++;
    return n;
  }

  double get _progress => _filledSteps / 3;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ── Photo ─────────────────────────────────────────────────────────────────────
  Future<void> _pickProofPhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;
      final bytes = await image.readAsBytes();
      setState(() {
        _proofXFile = image;
        _proofBytes = bytes;
      });
    } catch (e) {
      _showSnack("Gagal memilih foto: $e", isError: true);
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMethod == null) {
      _showSnack("Pilih metode pembayaran terlebih dahulu", isError: true);
      return;
    }

    if (_proofXFile == null) {
      _showSnack("Foto bukti pembayaran wajib diupload", isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final success = await widget.api.submitPayment(
        invoiceId: widget.invoice.id,
        amountPaid: widget.invoice.totalAmount,
        paidUsing: _selectedMethod!.label,
        proofPhoto: _proofXFile!,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted && success) {
        widget.onSuccess?.call();
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentSuccessScreen(
              invoiceNumber: widget.invoice.invoiceNumber,
              amountPaid: _rupiahTotal,
              onBack: () => Navigator.pop(context),
              onViewLogs: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentLogsScreen(api: widget.api),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted)
        _showSnack(e.toString().replaceFirst("Exception: ", ""), isError: true);
    }

    if (mounted) setState(() => _isSubmitting = false);
  }

  // ── Snack ─────────────────────────────────────────────────────────────────────
  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
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

  // ── BUILD ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: MainLayout(
        child: SafeArea(
          bottom: false,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppHeader(
                      title: "Input Pembayaran",
                      titleIcon: Icons.payment_rounded,
                      onBack: () => Navigator.pop(context),
                    ),
                    const SizedBox(height: 10),
                    _buildProgressBar(),
                    const SizedBox(height: 20),

                    // Invoice summary chip
                    _buildInvoiceChip(),
                    const SizedBox(height: 28),

                    // ── STEP 1: Total ─────────────────────────────────────
                    _buildSectionLabel(
                      "1",
                      "Total Pembayaran",
                      Icons.receipt_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildTotalCard(),

                    // ── STEP 2: Payment Method ────────────────────────────
                    const SizedBox(height: 28),
                    _buildSectionLabel(
                      "2",
                      "Metode Pembayaran",
                      Icons.account_balance_wallet_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildMethodGrid(),

                    // ── STEP 3: Notes ──────────────────────────────────────
                    const SizedBox(height: 28),
                    _buildSectionLabel(
                      "3",
                      "Keterangan (Opsional)",
                      Icons.notes_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildNotesField(),

                    // ── STEP 4: Proof Photo ───────────────────────────────
                    const SizedBox(height: 28),
                    _buildSectionLabel(
                      "4",
                      "Foto Bukti Pembayaran",
                      Icons.add_a_photo_rounded,
                    ),
                    const SizedBox(height: 12),
                    _buildPhotoContainer(),

                    const SizedBox(height: 40),
                    _buildSubmitButton(),
                    const SizedBox(height: 12),
                    _buildCancelButton(),
                    const SizedBox(height: 5),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Progress Bar ──────────────────────────────────────────────────────────────
  Widget _buildProgressBar() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Kelengkapan Data",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              Text(
                "${(_progress * 100).toInt()}%",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 6,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(_orange),
            ),
          ),
        ],
      ),
    );
  }

  // ── Invoice Chip ──────────────────────────────────────────────────────────────
  Widget _buildInvoiceChip() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _orange.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _orangeBorder, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.receipt_long_rounded, size: 16, color: _orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.invoice.invoiceNumber,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _orange,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Unit ${widget.invoice.unitNumber}",
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section Label ─────────────────────────────────────────────────────────────
  Widget _buildSectionLabel(String step, String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _orangeDim,
            shape: BoxShape.circle,
            border: Border.all(color: _orangeBorder, width: 1.5),
          ),
          child: Center(
            child: Text(
              step,
              style: TextStyle(
                color: _orange,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, size: 18, color: _orange),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // ── Total Card ────────────────────────────────────────────────────────────────
  Widget _buildTotalCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _orange.withOpacity(0.14),
                Colors.deepOrange.withOpacity(0.06),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _orangeBorder, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 14,
                    color: _orange.withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Jumlah yang harus dibayar",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.45),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _rupiahTotal,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: _orange,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_rounded,
                      size: 11,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      "Jumlah tetap sesuai invoice",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.amber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Method Grid ───────────────────────────────────────────────────────────────
  // ── Method Dropdown ───────────────────────────────────────────────────────────
  Widget _buildMethodGrid() {
    return _glassCard(
      padding: EdgeInsets.zero,
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<String>(
          value: _selectedMethod?.id,
          isExpanded: true,
          dropdownColor: const Color(0xFF1C1A1E),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: _orange),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: InputBorder.none,
            hintText: "Pilih metode pembayaran...",
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
            prefixIcon: Icon(
              _selectedMethod != null
                  ? _selectedMethod!.icon
                  : Icons.account_balance_wallet_rounded,
              color: _selectedMethod != null ? _selectedMethod!.color : _orange,
              size: 20,
            ),
          ),
          items: _kPaymentMethods.map((method) {
            return DropdownMenuItem<String>(
              value: method.id,
              child: Row(
                children: [
                  Icon(method.icon, size: 18, color: method.color),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        method.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        method.subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
          selectedItemBuilder: (context) => _kPaymentMethods.map((method) {
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                method.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (String? val) {
            if (val == null) return;
            setState(() {
              _selectedMethod = _kPaymentMethods.firstWhere((m) => m.id == val);
            });
          },
        ),
      ),
    );
  }

  // ── Notes Field ───────────────────────────────────────────────────────────────
  Widget _buildNotesField() {
    return _glassCard(
      padding: EdgeInsets.zero,
      child: TextFormField(
        controller: _notesController,
        maxLines: 3,
        maxLength: 200,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
          hintText: "Tambah keterangan jika diperlukan... (opsional)",
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8, top: 12),
            child: Icon(Icons.edit_note_rounded, color: _orange, size: 22),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          counterStyle: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ),
    );
  }

  // ── Photo Container ───────────────────────────────────────────────────────────
  Widget _buildPhotoContainer() {
    final bool hasPhoto = _proofXFile != null;

    return GestureDetector(
      onTap: _pickProofPhoto,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: hasPhoto ? 220 : 175,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasPhoto ? _orangeBorder : _glassBorder,
            width: hasPhoto ? 1.8 : 1.0,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
          boxShadow: hasPhoto
              ? [
                  BoxShadow(
                    color: _orange.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: hasPhoto
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    // Photo preview
                    _proofBytes != null
                        ? Image.memory(_proofBytes!, fit: BoxFit.cover)
                        : Image.file(
                            File(_proofXFile!.path),
                            fit: BoxFit.cover,
                          ),

                    // Retake overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.72),
                            ],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.photo_library_rounded,
                              color: _orange,
                              size: 15,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Ganti Foto",
                              style: TextStyle(
                                color: _orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Badge
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, color: Colors.white, size: 11),
                            SizedBox(width: 4),
                            Text(
                              "Foto Baru",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              // Empty state
              : BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    color: _glass,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: _orangeDim,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _orangeBorder,
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            Icons.photo_library_rounded,
                            color: _orange,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          "Pilih Foto Bukti Pembayaran",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Tap untuk membuka galeri",
                          style: TextStyle(fontSize: 12, color: Colors.white38),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _orangeDim,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _orangeBorder, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.photo_library_rounded,
                                size: 13,
                                color: _orange,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "Galeri",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _orange,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
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

  // ── Submit Button ─────────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: _orange.withOpacity(0.3),
          disabledBackgroundColor: Colors.white10,
          padding: const EdgeInsets.symmetric(vertical: 22),
          elevation: 0,
          side: BorderSide(color: _glassBorder, width: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Kirim Bukti Pembayaran",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Cancel Button ─────────────────────────────────────────────────────────────
  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 22),
          side: BorderSide(color: _glassBorder, width: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          "Batal",
          style: TextStyle(
            color: Colors.white54,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // ── Glass Card Helper ─────────────────────────────────────────────────────────
  Widget _glassCard({required Widget child, EdgeInsets? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
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
}
