import 'dart:ui';
import 'package:braga8_mobile/data/models/invoice_model.dart';
import 'package:braga8_mobile/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// ENTRY POINT — call this instead of showDialog
// ---------------------------------------------------------------------------

/// Shows the payment confirmation as a bottom sheet.
/// Returns `true` if the user confirmed, `false`/`null` if cancelled.
Future<bool?> showPaymentConfirmModal(
  BuildContext context,
  Invoice invoice,
) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PaymentConfirmSheet(invoice: invoice),
  );
}

// ---------------------------------------------------------------------------
// SHEET
// ---------------------------------------------------------------------------

class _PaymentConfirmSheet extends StatefulWidget {
  final Invoice invoice;
  const _PaymentConfirmSheet({required this.invoice});

  @override
  State<_PaymentConfirmSheet> createState() => _PaymentConfirmSheetState();
}

class _PaymentConfirmSheetState extends State<_PaymentConfirmSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  static const _orange = AppColors.primaryOrange;

  String _rupiah(double amount) => NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(amount);

  String _fmtDate(DateTime d) =>
      DateFormat('dd MMMM yyyy', 'id_ID').format(d);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 36,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ─────────────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // ── Icon ────────────────────────────────────────────────────
              ScaleTransition(
                scale: _pulseAnim,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _orange.withOpacity(0.25),
                        _orange.withOpacity(0.08),
                      ],
                    ),
                    border: Border.all(
                      color: _orange.withOpacity(0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.payment_rounded,
                    color: _orange,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Title ───────────────────────────────────────────────────
              const Text(
                'Konfirmasi Pembayaran',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Pastikan detail tagihan benar sebelum melanjutkan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),

              // ── Invoice detail card ──────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.10),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        _infoRow(
                          icon: Icons.receipt_long_outlined,
                          label: 'No. Invoice',
                          value: inv.invoiceNumber,
                        ),
                        _divider(),
                        _infoRow(
                          icon: Icons.door_front_door_outlined,
                          label: 'Unit',
                          value: inv.unitNumber,
                        ),
                        _divider(),
                        _infoRow(
                          icon: Icons.calendar_month_outlined,
                          label: 'Periode',
                          value:
                              '${_fmtDate(inv.billingPeriodStart)} –\n${_fmtDate(inv.billingPeriodEnd)}',
                          valueAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Total amount highlight ───────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _orange.withOpacity(0.18),
                      Colors.deepOrange.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _orange.withOpacity(0.35),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          color: _orange.withOpacity(0.8),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Total Tagihan',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _rupiah(inv.totalAmount),
                      style: TextStyle(
                        color: _orange,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Action buttons ───────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _sheetButton(
                      label: 'Batal',
                      icon: Icons.close,
                      color: Colors.white54,
                      onTap: () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _sheetButton(
                      label: 'Bayar',
                      icon: Icons.check_rounded,
                      color: _orange,
                      filled: true,
                      onTap: () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    TextAlign valueAlign = TextAlign.right,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: _orange.withOpacity(0.7)),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: valueAlign,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(
        color: Colors.white.withOpacity(0.07),
        height: 1,
      );

  Widget _sheetButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool filled = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: filled ? color.withOpacity(0.2) : color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withOpacity(filled ? 0.45 : 0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}