import 'dart:ui';

import 'package:braga8_mobile/ApiService.dart';
import 'package:braga8_mobile/data/models/invoice_model.dart';
import 'package:braga8_mobile/core/app_colors.dart';
import 'package:braga8_mobile/views/invoice/detail_invoices_screen.dart';
import 'package:braga8_mobile/views/payments/input_payment_screen.dart';
import 'package:braga8_mobile/views/widgets/app_header.dart';
import 'package:braga8_mobile/views/widgets/custom_search_bar.dart';
import 'package:braga8_mobile/views/widgets/main_layouts.dart';
import 'package:braga8_mobile/views/widgets/page_header.dart';
import 'package:braga8_mobile/views/widgets/table_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String _formatRupiah(double amount) {
  return NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(amount);
}

String _billingMonth(DateTime date) =>
    DateFormat('MMMM yyyy', 'id_ID').format(date);

class DaftarInvoicesScreen extends StatefulWidget {
  final ApiService api;
  final VoidCallback? onBack;
  const DaftarInvoicesScreen({super.key, required this.api, this.onBack});

  @override
  State<DaftarInvoicesScreen> createState() => _DaftarInvoicesScreenState();
}

class _DaftarInvoicesScreenState extends State<DaftarInvoicesScreen>
    with WidgetsBindingObserver {
  late Future<List<InvoiceGroup>> _invoiceData;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _statusFilter = 'all';
  Set<String> _selectedMonths = {}; 

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadData();
  }

  void _loadData() {
    setState(() {
      _invoiceData = widget.api.fetchInvoicesSummary();
    });
  }

  List<String> _allMonths(List<InvoiceGroup> groups) {
    final months = <String>{};
    for (final g in groups) {
      for (final inv in g.invoices) {
        months.add(DateFormat('yyyy-MM').format(inv.billingPeriodStart));
      }
    }
    final sorted = months.toList()..sort((a, b) => b.compareTo(a));
    return sorted;
  }

  List<MapEntry<InvoiceGroup, List<Invoice>>> _getFilteredData(
    List<InvoiceGroup> groups,
  ) {
    final result = <MapEntry<InvoiceGroup, List<Invoice>>>[];

    for (final group in groups) {
      final q = _searchQuery.toLowerCase().trim();
      
      final isTenantMatch = _searchQuery.isNotEmpty && group.tenantName.toLowerCase().contains(q);

      final filteredInvoices = group.invoices.where((inv) {
        if (_selectedMonths.isNotEmpty) {
          final monthKey = DateFormat('yyyy-MM').format(inv.billingPeriodStart);
          if (!_selectedMonths.contains(monthKey)) return false;
        }
        
        if (_statusFilter == 'paid' && !inv.isPaid) return false;
        if (_statusFilter == 'unpaid' && inv.isPaid) return false;

        if (q.isNotEmpty) {
          if (isTenantMatch) return true;

          final isInvoiceMatch = inv.invoiceNumber.toLowerCase().contains(q);
          final isUnitMatch = inv.unitNumber.toLowerCase().contains(q);
          
          return isInvoiceMatch || isUnitMatch;
        }

        return true;
      }).toList();

      if (filteredInvoices.isNotEmpty) {
        result.add(MapEntry(group, filteredInvoices));
      }
    }
    return result;
  }

  void _showFilterModal(List<InvoiceGroup> groups) {
    final months = _allMonths(groups);
    Set<String> tempMonths = Set.from(_selectedMonths);
    String tempStatus = _statusFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color.fromARGB(0, 60, 60, 60),
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
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ModalDragHandle(),
                  _ModalTitle(
                    onReset: () => setSheetState(() {
                      tempMonths.clear();
                      tempStatus = 'all';
                    }),
                  ),
                  const SizedBox(height: 16),
                  _FilterSectionHeader(title: 'Status Pembayaran'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _FilterChip(
                        label: 'Semua',
                        isSelected: tempStatus == 'all',
                        onTap: () => setSheetState(() => tempStatus = 'all'),
                      ),
                      _FilterChip(
                        label: 'Sudah Terbayar',
                        isSelected: tempStatus == 'paid',
                        onTap: () => setSheetState(() => tempStatus = 'paid'),
                      ),
                      _FilterChip(
                        label: 'Belum Bayar',
                        isSelected: tempStatus == 'unpaid',
                        onTap: () => setSheetState(() => tempStatus = 'unpaid'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _FilterSectionHeader(title: 'Bulan Tagihan'),
                  const SizedBox(height: 12),
                  if (months.isEmpty)
                    const Text(
                      'Tidak ada data bulan.',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    )
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: months.map((m) {
                        final label = DateFormat(
                          'MMM yyyy',
                          'id_ID',
                        ).format(DateTime.parse('$m-01'));
                        final isSelected = tempMonths.contains(m);
                        return _FilterChip(
                          label: label,
                          isSelected: isSelected,
                          onTap: () => setSheetState(() {
                            isSelected
                                ? tempMonths.remove(m)
                                : tempMonths.add(m);
                          }),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 40),
                  _ApplyButton(
                    onPressed: () {
                      setState(() {
                        _selectedMonths = tempMonths;
                        _statusFilter = tempStatus;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilterBar() {
    final hasMonth = _selectedMonths.isNotEmpty;
    final hasStatus = _statusFilter != 'all';

    if (!hasMonth && !hasStatus) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ..._selectedMonths.map((m) {
            final label = DateFormat(
              'MMM yyyy',
              'id_ID',
            ).format(DateTime.parse('$m-01'));
            return _ActiveChip(
              label: label,
              onRemove: () => setState(() => _selectedMonths.remove(m)),
            );
          }),
          if (hasStatus)
            _ActiveChip(
              label: _statusFilter == 'paid' ? 'Sudah Terbayar' : 'Belum Bayar',
              onRemove: () => setState(() => _statusFilter = 'all'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MainLayout(
        child: SafeArea(
          bottom: false,
          child: FutureBuilder<List<InvoiceGroup>>(
            future: _invoiceData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryOrange,
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Gagal memuat data: ${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                );
              }

              final allGroups = snapshot.data ?? [];
              final filteredData = _getFilteredData(allGroups);

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 15),
                    AppHeader(
                      title: 'Daftar Invoice',
                      titleIcon: Icons.receipt_long_outlined,
                      onBack: widget.onBack,
                    ),
                    const SizedBox(height: 16),
                    const PageHeader(
                      title: 'Daftar Invoice',
                      subtitle: 'Braga8 Utility Billing Management',
                    ),
                    const SizedBox(height: 30),

                    // Search + Filter Row
                    Row(
                      children: [
                        Expanded(
                          child: CustomSearchBar(
                            controller: _searchController,
                            hintText: 'Cari Invoice..',
                            onChanged: (v) => setState(() => _searchQuery = v),
                            onSearchPressed: () => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _FilterIconButton(
                          onTap: () => _showFilterModal(allGroups),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    _buildActiveFilterBar(),

                    if (filteredData.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Text(
                            'Data tidak ditemukan',
                            style: TextStyle(color: Colors.white38),
                          ),
                        ),
                      )
                    else
                      ...filteredData.map((entry) {
                        final group = entry.key;
                        final invoices = entry.value;

                        // Group invoices by billing month for card display
                        final byMonth = <String, List<Invoice>>{};
                        for (final inv in invoices) {
                          final key = DateFormat(
                            'yyyy-MM',
                          ).format(inv.billingPeriodStart);
                          byMonth.putIfAbsent(key, () => []).add(inv);
                        }

                        return Column(
                          children: byMonth.entries.map((monthEntry) {
                            final monthDate = DateTime.parse(
                              '${monthEntry.key}-01',
                            );
                            final monthLabel = _billingMonth(monthDate);
                            final monthInvoices = monthEntry.value;
                            final invoiceNumber =
                                monthInvoices.first.invoiceNumber;

                            return TableCard(
                              prefix: group.tenantName,
                              main: monthLabel,
                              suffixText: '${monthInvoices.length} Unit',

                              columnWidths: const {
                                0: FlexColumnWidth(3.8),
                                1: FlexColumnWidth(2.2),
                                2: FlexColumnWidth(3.5),
                              },
                              columns: const ['Unit', 'Total', 'Tindakan'],
                              data: monthInvoices
                                  .map((inv) => {'object': inv})
                                  .toList(),
                              rowBuilder: (item) {
                                final inv = item['object'] as Invoice;
                                return [
                                  // Column 0 - Unit
                                  SizedBox(
                                    width: 80,
                                    child: Text(
                                      inv.unitNumber,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12.5,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),

                                  // Column 1 - Total
                                  SizedBox(
                                    width: 110,
                                    child: Text(
                                      _formatRupiah(inv.totalAmount),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12.5,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      _actionBtn(
                                        label: "Detail",
                                        icon: Icons.remove_red_eye_rounded,
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => DetailInvoiceScreen(
                                                api: widget
                                                    .api, // Pass the api from the current widget
                                                invoice:
                                                    inv, // Pass the invoice from the row
                                              ),
                                            ),
                                          ).then((_) => _loadData());
                                        },
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      _actionBtn(
                                        label: inv.isPaid ? "Lunas" : "Bayar",
                                        icon: inv.isPaid
                                            ? Icons.check_circle_outline
                                            : Icons.payment,
                                        color: inv.isPaid
                                            ? Colors.green.withValues(alpha: .9)
                                            : AppColors.primaryOrange
                                                  .withValues(alpha: .9),

                                        onPressed: inv.isPaid
                                            ? null
                                            : () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        InputPaymentScreen(
                                                          invoice: inv,
                                                          api: widget.api,
                                                          onSuccess: () {},
                                                        ),
                                                  ),
                                                ).then((_) => _loadData());
                                              },
                                      ),
                                    ],
                                  ),
                                ];
                              },
                            );
                          }).toList(),
                        );
                      }),
                    const SizedBox(height: 80),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

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
            ? Colors.white.withValues(alpha: .04)
            : color.withValues(alpha: .15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: disabled ? Colors.white12 : color.withValues(alpha: .4),
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

class _ModalDragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 40,
      height: 5,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(10),
      ),
    ),
  );
}

class _ModalTitle extends StatelessWidget {
  final VoidCallback onReset;
  const _ModalTitle({required this.onReset});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Text(
        'Filter Pencarian',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
      TextButton(
        onPressed: onReset,
        child: const Text(
          'Reset',
          style: TextStyle(color: Color.fromARGB(173, 255, 255, 255)),
        ),
      ),
    ],
  );
}

class _FilterSectionHeader extends StatelessWidget {
  final String title;
  const _FilterSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: const TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 15,
      color: Colors.white70,
      letterSpacing: 0.2,
    ),
  );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primaryOrange.withValues(alpha: .25)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.primaryOrange.withValues(alpha: .5)
              : Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? AppColors.primaryOrange.withValues(alpha: .8)
              : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 13,
        ),
      ),
    ),
  );
}

class _ApplyButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _ApplyButton({required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryOrange.withValues(alpha: .3),
        foregroundColor: Colors.white,
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.2),
          width: 0.9,
        ),
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      child: const Text(
        'Terapkan Filter',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
  );
}

class _ActiveChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _ActiveChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
    decoration: BoxDecoration(
      color: AppColors.primaryOrange.withValues(alpha: .15),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: AppColors.primaryOrange.withValues(alpha: .3),
        width: 1,
      ),
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
}

class _FilterIconButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FilterIconButton({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: AppColors.primaryOrange.withValues(alpha: 0.3),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 0.8,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.tune, color: Colors.white, size: 22),
    ),
  );
}

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  const _SmallIconButton({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onPressed,
    child: Container(
      height: 36,
      width: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    ),
  );
}
