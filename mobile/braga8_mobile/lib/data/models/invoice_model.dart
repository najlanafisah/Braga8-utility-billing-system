import 'package:flutter/material.dart';

class Invoice {
  final int id;
  final String invoiceNumber;
  final String unitNumber;
  final double totalAmount;
  final bool isPaid;
  final String status;
  final DateTime billingPeriodStart;
  final DateTime billingPeriodEnd;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.unitNumber,
    required this.totalAmount,
    required this.isPaid,
    required this.status,
    required this.billingPeriodStart,
    required this.billingPeriodEnd,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String? ?? 'unpaid';
    final isPaidFromStatus = status == 'paid';
    final isPaidFromFlag = (json['is_paid'] as bool?) ?? false;

    return Invoice(
      id: json['id'] as int,
      invoiceNumber: json['invoice_number'] as String? ?? '-',
      unitNumber: json['unit_number'] as String? ?? '-',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      status: status,
      isPaid: isPaidFromStatus || isPaidFromFlag,
      billingPeriodStart: json['billing_period_start'] != null
          ? DateTime.parse(json['billing_period_start'])
          : DateTime.now(),
      billingPeriodEnd: json['billing_period_end'] != null
          ? DateTime.parse(json['billing_period_end'])
          : DateTime.now(),
    );
  }

  Invoice copyWith({bool? isPaid, String? status}) => Invoice(
        id: id,
        invoiceNumber: invoiceNumber,
        unitNumber: unitNumber,
        totalAmount: totalAmount,
        isPaid: isPaid ?? this.isPaid,
        status: status ?? this.status,
        billingPeriodStart: billingPeriodStart,
        billingPeriodEnd: billingPeriodEnd,
      );
}

class InvoiceGroup {
  final int tenantId;
  final String tenantName;
  final List<Invoice> invoices;

  const InvoiceGroup({
    required this.tenantId,
    required this.tenantName,
    required this.invoices,
  });

  factory InvoiceGroup.fromJson(Map<String, dynamic> json) {
    debugPrint('InvoiceGroup keys: ${json.keys.toList()}');
    debugPrint('InvoiceGroup raw: $json');
    return InvoiceGroup(
      tenantId: json['tenant_id'] as int,
      tenantName: json['tenant_name'] as String? ?? '-',
      invoices: (json['invoices'] as List<dynamic>)
          .map((e) => Invoice.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}