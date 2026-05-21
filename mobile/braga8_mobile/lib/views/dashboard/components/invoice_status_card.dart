import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:braga8_mobile/core/app_colors.dart';
import 'package:braga8_mobile/core/app_theme.dart';

class InvoiceStatusCard extends StatelessWidget {
  final double totalAmount;
  final bool isPaid;
  final String? invoiceNumber;
  final String period;

  const InvoiceStatusCard({
    super.key,
    required this.totalAmount,
    required this.isPaid,
    required this.period,
    this.invoiceNumber,
  });

  @override
  Widget build(BuildContext context) {
    final rupiah = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.white40.withOpacity(0.6),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // ── Background Image (same as MeterProgressCard) ──────────────
            Positioned.fill(
              child: Image.asset(
                'assets/images/progress-bg.png',
                fit: BoxFit.cover,
              ),
            ),

            // ── Content ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header Row ────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Tagihan Bulan Ini",
                        style: AppTextStyles.subtitle.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      // ── Status Badge (Paid / Unpaid) ──────────────────────
                      _buildStatusBadge(),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Amount ────────────────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        rupiah.format(totalAmount),
                        style: AppTextStyles.title.copyWith(
                          fontSize: 32,
                          height: 1,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryOrange,
                        ),
                      ),
                    ],
                  ),

                  // ── Invoice number if provided ────────────────────────────
                  if (invoiceNumber != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      invoiceNumber!,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white38,
                        fontSize: 12,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ── Footer ─────────────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusLabel(
                        isPaid ? "Sudah Dibayar" : "Belum Dibayar",
                      ),
                      Text(
                        period,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.white60,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Status Badge (top-right) ─────────────────────────────────────────────
  Widget _buildStatusBadge() {
    final color = isPaid ? const Color(0xFF34D399) : Colors.amber;
    final label = isPaid ? 'Lunas' : 'Belum Lunas';
    final icon = isPaid ? Icons.check_circle_rounded : Icons.hourglass_top_rounded;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 11, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Footer status dot + label ────────────────────────────────────────────
  Widget _buildStatusLabel(String text) {
    final color = isPaid ? const Color(0xFF34D399) : Colors.amber;
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.white60,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}