import 'dart:ui';
import 'package:braga8_mobile/ApiService.dart';
import 'package:braga8_mobile/data/models/meter_reading_model.dart';
import 'package:braga8_mobile/data/models/tenant_model.dart';
import 'package:braga8_mobile/core/app_colors.dart';
import 'package:braga8_mobile/views/meter_input/input_reading_screen.dart';
import 'package:braga8_mobile/views/widgets/app_header.dart';
import 'package:braga8_mobile/views/widgets/main_layouts.dart';
import 'package:braga8_mobile/views/widgets/page_header.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MeterAnalyticsScreen extends StatelessWidget {
  final String userRole;
  final Tenant? tenant;
  final VoidCallback? onBack;

  const MeterAnalyticsScreen({
    super.key,
    required this.userRole,
    this.tenant,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    if (userRole == 'petugas') {
      return _PetugasAnalyticsScreen(onBack: onBack);
    } else {
      return _TenantAnalyticsScreen(tenant: tenant!, onBack: onBack);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Helpers & Constants
// ─────────────────────────────────────────────────────────────────────────────
const _orange = AppColors.primaryOrange;


String? _buildPhotoUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return path;
  return 'http://172.16.4.22:8000/storage/$path';
}

String _formatDate(String? raw) {
  if (raw == null) return '-';
  try {
    return DateFormat(
      'dd MMM yyyy, HH:mm',
    ).format(DateTime.parse(raw).toLocal());
  } catch (_) {
    return raw;
  }
}

String _formatMonth(String? raw) {
  if (raw == null) return '-';
  try {
    return DateFormat('MMMM yyyy').format(DateTime.parse(raw).toLocal());
  } catch (_) {
    return raw;
  }
}

List<DateTime> _extractAvailableMonths(List<MeterReadingHistory> readings) {
  final Set<String> uniqueMonths = {};
  final List<DateTime> months = [];
  for (final r in readings) {
    if (r.recordedAt == null) continue;
    try {
      final dt = DateTime.parse(r.recordedAt!).toLocal();
      final key = '${dt.year}-${dt.month}';
      if (uniqueMonths.add(key)) {
        months.add(DateTime(dt.year, dt.month, 1));
      }
    } catch (_) {}
  }
  months.sort((a, b) => b.compareTo(a));
  return months;
}

bool _readingMatchesMonth(MeterReadingHistory r, DateTime? month) {
  if (month == null) return true;
  if (r.recordedAt == null) return false;
  try {
    final dt = DateTime.parse(r.recordedAt!).toLocal();
    return dt.year == month.year && dt.month == month.month;
  } catch (_) {
    return false;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PETUGAS VIEW
// ─────────────────────────────────────────────────────────────────────────────
class _PetugasAnalyticsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const _PetugasAnalyticsScreen({this.onBack});

  @override
  State<_PetugasAnalyticsScreen> createState() =>
      _PetugasAnalyticsScreenState();
}

class _PetugasAnalyticsScreenState extends State<_PetugasAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();

  late Future<List<Tenant>> _futureTenants;
  late Future<List<MeterReadingHistory>> _futureGlobalReadings;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  Set<String> _selectedFloors = {};
  String _categoryFilter = 'Semua';
  String _statusFilter = 'all';
  DateTime? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _futureTenants = Future.value([]);
    _futureGlobalReadings = Future.value([]);
    _refreshData();
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _refreshData() {
    setState(() {
      _futureTenants = _api.fetchUnitsSummary();
      _futureGlobalReadings = _api.fetchAllReadings();
    });
    _animController.reset();
    _animController.forward();
  }

  List<String> _allFloors(List<Tenant> tenants) {
    final floors = <String>{};
    for (final t in tenants) {
      for (final u in t.units) {
        if (u.floor.isNotEmpty && u.floor != '-') floors.add(u.floor);
      }
    }
    return floors.toList()..sort();
  }

  List<_UnitEntry> _filtered(List<Tenant> tenants) {
    final result = <_UnitEntry>[];
    for (final t in tenants) {
      for (final u in t.units) {
        if (_selectedFloors.isNotEmpty && !_selectedFloors.contains(u.floor)) {
          continue;
        }
        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          if (!t.name.toLowerCase().contains(q) &&
              !u.unitNumber.toLowerCase().contains(q) &&
              !u.floor.toLowerCase().contains(q))
            continue;
        }
        result.add(_UnitEntry(tenant: t, unit: u));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: MainLayout(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: FutureBuilder<List<Tenant>>(
              future: _futureTenants,
              builder: (ctx, snapTenants) {
                return FutureBuilder<List<MeterReadingHistory>>(
                  future: _futureGlobalReadings,
                  builder: (ctx, snapReadings) {
                    final tenants = snapTenants.data ?? [];
                    final globalReadings = snapReadings.data ?? [];
                    final entries = _filtered(tenants);
                    final availableMonths = _extractAvailableMonths(
                      globalReadings,
                    );

                    return CustomScrollView(
                      physics: const ClampingScrollPhysics(),
                      slivers: [
                        const SliverToBoxAdapter(child: SizedBox(height: 12)),

                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: AppHeader(
                              title: "Analitik Meter",
                              titleIcon: Icons.bar_chart_rounded,
                              onBack: widget.onBack,
                              trailing: GestureDetector(
                                onTap: _refreshData,
                                child: _refreshButton(),
                              ),
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 10)),

                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            child: PageHeader(
                              title: "Riwayat Meteran",
                              subtitle: "Braga8 Analytic Meter Data",
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 14)),

                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Expanded(child: _buildSearchBar()),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () => _showFilterModal(
                                    tenants,
                                    _allFloors(tenants),
                                    availableMonths,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 10,
                                        sigmaY: 10,
                                      ),
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: _orange.withOpacity(0.28),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: _orange.withOpacity(0.45),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.tune_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 10)),

                        // ── Active filter chips
                        if (_selectedFloors.isNotEmpty ||
                            _statusFilter != 'all' ||
                            _categoryFilter != 'Semua' ||
                            _selectedMonth != null)
                          SliverToBoxAdapter(child: _buildActiveFilterChips()),

                        // ── Loading / Error / Empty / List
                        if (snapTenants.connectionState ==
                            ConnectionState.waiting)
                          SliverFillRemaining(
                            child: Center(
                              child: CircularProgressIndicator(color: _orange),
                            ),
                          )
                        else if (snapTenants.hasError)
                          SliverFillRemaining(
                            child: _buildErrorState(_refreshData),
                          )
                        else if (entries.isEmpty)
                          SliverFillRemaining(child: _buildEmptyState())
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) => _PetugasUnitSection(
                                  entry: entries[i],
                                  categoryFilter: _categoryFilter,
                                  statusFilter: _statusFilter,
                                  selectedMonth: _selectedMonth,
                                  onRefresh: _refreshData,
                                ),
                                childCount: entries.length,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: "Cari unit, tenant, lantai...",
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white38,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          ..._selectedFloors.map(
            (f) => _activeChip(
              "Lantai $f",
              () => setState(() => _selectedFloors.remove(f)),
            ),
          ),
          if (_statusFilter != 'all')
            _activeChip(
              _statusFilter == 'checked'
                  ? 'Terverifikasi'
                  : _statusFilter == 'rejected'
                  ? 'Ditolak'
                  : 'Menunggu',
              () => setState(() => _statusFilter = 'all'),
            ),
          if (_categoryFilter != 'Semua')
            _activeChip(
              _categoryFilter,
              () => setState(() => _categoryFilter = 'Semua'),
            ),
          if (_selectedMonth != null)
            _activeChip(
              DateFormat('MMM yyyy').format(_selectedMonth!),
              () => setState(() => _selectedMonth = null),
            ),
        ],
      ),
    );
  }

  Widget _activeChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 6, top: 5, bottom: 5),
      decoration: BoxDecoration(
        color: _orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _orange.withOpacity(0.3)),
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
            child: const Icon(
              Icons.close_rounded,
              size: 15,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterModal(
    List<Tenant> tenants,
    List<String> floors,
    List<DateTime> availableMonths,
  ) {
    Set<String> tempFloors = Set.from(_selectedFloors);
    String tempStatus = _statusFilter;
    String tempCategory = _categoryFilter;
    DateTime? tempMonth = _selectedMonth;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => ClipRRect(
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1.5,
                ),
              ),
              child: SingleChildScrollView(
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
                          "Filter Data",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        TextButton(
                          onPressed: () => setSheet(() {
                            tempFloors.clear();
                            tempStatus = 'all';
                            tempCategory = 'Semua';
                            tempMonth = null;
                          }),
                          child: const Text(
                            "Reset",
                            style: TextStyle(
                              color: Color.fromARGB(173, 255, 255, 255),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _sheetSectionHeader("Lantai"),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: floors.map((f) {
                        final sel = tempFloors.contains(f);
                        return _filterChip(
                          label: f,
                          isSelected: sel,
                          onTap: () => setSheet(
                            () =>
                                sel ? tempFloors.remove(f) : tempFloors.add(f),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    _sheetSectionHeader("Kategori"),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: ["Semua", "Listrik", "Air"].map((label) {
                        return _filterChip(
                          label: label,
                          isSelected: tempCategory == label,
                          onTap: () => setSheet(() => tempCategory = label),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    _sheetSectionHeader("Bulan"),
                    const SizedBox(height: 10),
                    if (availableMonths.isEmpty)
                      const Text(
                        "Belum ada data",
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      )
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _filterChip(
                            label: "Semua",
                            isSelected: tempMonth == null,
                            onTap: () => setSheet(() => tempMonth = null),
                          ),
                          ...availableMonths.map((month) {
                            final isActive =
                                tempMonth != null &&
                                tempMonth!.year == month.year &&
                                tempMonth!.month == month.month;
                            return _filterChip(
                              label: DateFormat('MMM yyyy').format(month),
                              isSelected: isActive,
                              onTap: () => setSheet(() => tempMonth = month),
                            );
                          }),
                        ],
                      ),
                    const SizedBox(height: 24),
                    _sheetSectionHeader("Status"),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _filterChip(
                          label: 'Semua',
                          isSelected: tempStatus == 'all',
                          onTap: () => setSheet(() => tempStatus = 'all'),
                        ),
                        _filterChip(
                          label: 'Terverifikasi',
                          isSelected: tempStatus == 'checked',
                          onTap: () => setSheet(() => tempStatus = 'checked'),
                        ),
                        _filterChip(
                          label: 'Menunggu',
                          isSelected: tempStatus == 'pending',
                          onTap: () => setSheet(() => tempStatus = 'pending'),
                        ),
                        _filterChip(
                          label: 'Ditolak',
                          isSelected: tempStatus == 'rejected',
                          onTap: () => setSheet(() => tempStatus = 'rejected'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedFloors = tempFloors;
                            _statusFilter = tempStatus;
                            _categoryFilter = tempCategory;
                            _selectedMonth = tempMonth;
                          });
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _orange.withOpacity(0.3),
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                            width: 0.9,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 20),
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Per-unit accordion section for Petugas
// ─────────────────────────────────────────────────────────────────────────────
class _PetugasUnitSection extends StatefulWidget {
  final _UnitEntry entry;
  final String categoryFilter;
  final String statusFilter;
  final DateTime? selectedMonth;
  final VoidCallback onRefresh;

  const _PetugasUnitSection({
    required this.entry,
    required this.categoryFilter,
    required this.statusFilter,
    required this.selectedMonth,
    required this.onRefresh,
  });

  @override
  State<_PetugasUnitSection> createState() => _PetugasUnitSectionState();
}

class _PetugasUnitSectionState extends State<_PetugasUnitSection> {
  final ApiService _api = ApiService();
  late Future<List<MeterReadingHistory>> _futureReadings;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _futureReadings = _api.fetchReadingHistory(widget.entry.unit.id);
  }

  List<MeterReadingHistory> _applyFilters(List<MeterReadingHistory> all) {
    return all.where((r) {
      if (widget.categoryFilter == 'Listrik' && !r.isElectric) return false;
      if (widget.categoryFilter == 'Air' && r.isElectric) return false;
      if (widget.statusFilter == 'checked' && r.status != 'checked')
        return false;
      if (widget.statusFilter == 'rejected' && r.status != 'rejected')
        return false;
      if (widget.statusFilter == 'pending' &&
          (r.status == 'checked' || r.status == 'rejected'))
        return false;
      if (!_readingMatchesMonth(r, widget.selectedMonth)) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
          ),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _orange.withOpacity(0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _orange.withOpacity(0.45),
                            width: 1.2,
                          ),
                        ),
                        child: Icon(
                          Icons.store_rounded,
                          color: _orange,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.entry.tenant.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "Unit ${widget.entry.unit.unitNumber}  · ${widget.entry.unit.floor}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          _statusDot(
                            widget.entry.unit.isElecChecked,
                            Icons.bolt_rounded,
                          ),
                          const SizedBox(width: 8),
                          _statusDot(
                            widget.entry.unit.isWaterChecked,
                            Icons.water_drop_rounded,
                          ),
                          const SizedBox(width: 8),
                          AnimatedRotation(
                            turns: _expanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white38,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                child: _expanded
                    ? FutureBuilder<List<MeterReadingHistory>>(
                        future: _futureReadings,
                        builder: (ctx, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return Padding(
                              padding: const EdgeInsets.all(20),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: _orange,
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }
                          if (snap.hasError) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                "Gagal memuat data",
                                style: TextStyle(
                                  color: Colors.redAccent.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          final filtered = _applyFilters(snap.data ?? []);
                          if (filtered.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.03),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.08),
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    "Tidak ada data untuk filter ini",
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            child: Column(
                              children: filtered
                                  .map(
                                    (r) => _ReadingCard(
                                      reading: r,
                                      unit: widget.entry.unit,
                                      onRefresh: () => setState(() {
                                        _futureReadings = _api
                                            .fetchReadingHistory(
                                              widget.entry.unit.id,
                                            );
                                      }),
                                    ),
                                  )
                                  .toList(),
                            ),
                          );
                        },
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusDot(bool active, IconData icon) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: active
            ? Colors.greenAccent.withOpacity(0.15)
            : Colors.white.withOpacity(0.05),
        shape: BoxShape.circle,
        border: Border.all(
          color: active
              ? Colors.greenAccent.withOpacity(0.4)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Icon(
        icon,
        size: 13,
        color: active ? Colors.greenAccent : Colors.white24,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TENANT VIEW
// ─────────────────────────────────────────────────────────────────────────────
class _TenantAnalyticsScreen extends StatefulWidget {
  final Tenant tenant;
  final VoidCallback? onBack;

  const _TenantAnalyticsScreen({required this.tenant, this.onBack});

  @override
  State<_TenantAnalyticsScreen> createState() => _TenantAnalyticsScreenState();
}

class _TenantAnalyticsScreenState extends State<_TenantAnalyticsScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  final ApiService _api = ApiService();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  int _selectedUnitIndex = 0;
  String _categoryFilter = 'Semua';
  DateTime? _selectedMonth;
  late Future<List<MeterReadingHistory>> _futureReadings;

  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    print('DEBUG units count: ${widget.tenant.units.length}');
    print('DEBUG tenant name: ${widget.tenant.name}');
    _futureReadings = widget.tenant.units.isNotEmpty
        ? _api.fetchReadingHistory(widget.tenant.units[0].id)
        : Future.value([]);
    _animController.forward();
  }

  @override
  void didUpdateWidget(_TenantAnalyticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tenant.units.isEmpty && widget.tenant.units.isNotEmpty) {
      setState(() {
        _futureReadings = _api.fetchReadingHistory(widget.tenant.units[0].id);
      });
    }
  }
  

  @override
  void dispose() {
    _animController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _loadReadings() {
    if (widget.tenant.units.isEmpty) {
      _futureReadings = Future.value([]);
      return;
    }
    _futureReadings = _api.fetchReadingHistory(
      widget.tenant.units[_selectedUnitIndex].id,
    );
  }

  void _switchUnit(int index) {
    setState(() {
      _selectedUnitIndex = index;
      _loadReadings();
    });
    _animController.reset();
    _animController.forward();
  }

  void _refreshData() {
    setState(() => _loadReadings());
    _animController.reset();
    _animController.forward();
  }

  List<MeterReadingHistory> _applyFilters(List<MeterReadingHistory> all) {
    return all.where((r) {
      if (_categoryFilter == 'Listrik' && !r.isElectric) return false;
      if (_categoryFilter == 'Air' && r.isElectric) return false;
      if (!_readingMatchesMonth(r, _selectedMonth)) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchMeter = r.meterNumber?.toLowerCase().contains(q) ?? false;
        final matchValue = r.readingValue.toString().contains(q);
        final matchAddress =
            r.locationAddress?.toLowerCase().contains(q) ?? false;
        if (!matchMeter && !matchValue && !matchAddress) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final units = widget.tenant.units;
    final hasMultipleUnits = units.length > 1;
    final currentUnit = units.isNotEmpty ? units[_selectedUnitIndex] : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: MainLayout(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: FutureBuilder<List<MeterReadingHistory>>(
              future: units.isEmpty ? null : _futureReadings,
              builder: (ctx, snap) {
                final allData = snap.data ?? [];
                final filtered = _applyFilters(allData);
                final availableMonths = _extractAvailableMonths(allData);

                final grouped = <String, List<MeterReadingHistory>>{};
                for (final r in filtered) {
                  grouped
                      .putIfAbsent(_formatMonth(r.recordedAt), () => [])
                      .add(r);
                }

                return CustomScrollView(
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: AppHeader(
                          title: "Data Meter Tenant",
                          titleIcon: Icons.electric_meter_rounded,
                          onBack: widget.onBack,
                          trailing: GestureDetector(
                            onTap: _refreshData,
                            child: _refreshButton(),
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: PageHeader(
                          title: "Riwayat Meteran",
                          subtitle: "Braga8 Analytic Meter Data",
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 14)),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildTenantBanner(),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    if (hasMultipleUnits) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildUnitSwitcher(units),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 10)),
                    ],

                    // ── Search + Filter button row
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(child: _buildSearchBar()),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => _showFilterModal(allData),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 10,
                                    sigmaY: 10,
                                  ),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: _orange.withOpacity(0.28),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: _orange.withOpacity(0.45),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.tune_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 8)),

                    if (_categoryFilter != 'Semua' || _selectedMonth != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (_categoryFilter != 'Semua')
                              _activeFilterChip(
                                _categoryFilter,
                                () => setState(() => _categoryFilter = 'Semua'),
                              ),
                            if (_selectedMonth != null)
                              _activeFilterChip(
                                DateFormat('MMM yyyy').format(_selectedMonth!),
                                () => setState(() => _selectedMonth = null),
                              ),
                          ],
                        ),
                      ),
                    ),

                    if (units.isEmpty)
                      SliverFillRemaining(child: _buildEmptyState())
                    else if (snap.connectionState == ConnectionState.waiting)
                      SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(color: _orange),
                        ),
                      )
                    else if (snap.hasError)
                      SliverFillRemaining(child: _buildErrorState(_refreshData))
                    else if (filtered.isEmpty)
                      SliverFillRemaining(child: _buildEmptyState())
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((ctx, i) {
                            final month = grouped.keys.elementAt(i);
                            final readings = grouped[month]!;
                            return _buildMonthGroup(
                              month,
                              readings,
                              currentUnit,
                            );
                          }, childCount: grouped.length),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _activeFilterChip(String label, VoidCallback onRemove) {
  return Container(
    padding: const EdgeInsets.only(left: 10, right: 6, top: 5, bottom: 5),
    decoration: BoxDecoration(
      color: _orange.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _orange.withOpacity(0.3)),
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
          child: const Icon(Icons.close_rounded, size: 15, color: Colors.orange),
        ),
      ],
    ),
  );
}

  Widget _buildTenantBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _orange.withOpacity(0.18),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _orange.withOpacity(0.45),
                    width: 1.2,
                  ),
                ),
                child: Icon(Icons.store_rounded, color: _orange, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.tenant.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "${widget.tenant.units.length} unit terdaftar",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white54,
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

  Widget _buildUnitSwitcher(List<Unit> units) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
          ),
          child: Row(
            children: units.asMap().entries.map((e) {
              final isActive = e.key == _selectedUnitIndex;
              final u = e.value;
              return Expanded(
                child: GestureDetector(
                  onTap: () => _switchUnit(e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? _orange.withOpacity(0.18)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive
                            ? _orange.withOpacity(0.45)
                            : Colors.transparent,
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Unit ${u.unitNumber}",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isActive ? _orange : Colors.white38,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Lt. ${u.floor}",
                          style: TextStyle(
                            fontSize: 11,
                            color: isActive ? Colors.white54 : Colors.white24,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              const Icon(Icons.search_rounded, color: Colors.white38, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: "Cari nomor meter, nilai, alamat...",
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white38,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthGroup(
    String month,
    List<MeterReadingHistory> readings,
    Unit? unit,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
          child: Text(
            month.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.3),
              letterSpacing: 1.2,
            ),
          ),
        ),
        ...readings.map(
          (r) => _ReadingCard(reading: r, unit: unit, onRefresh: _refreshData),
        ),
      ],
    );
  }

  void _showFilterModal(List<MeterReadingHistory> allReadings) {
    String tempCategory = _categoryFilter;
    DateTime? tempMonth = _selectedMonth;
    final months = _extractAvailableMonths(allReadings);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => ClipRRect(
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
                        "Filter Data",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      TextButton(
                        onPressed: () => setSheet(() {
                          tempCategory = 'Semua';
                          tempMonth = null;
                        }),
                        child: const Text(
                          "Reset",
                          style: TextStyle(
                            color: Color.fromARGB(173, 255, 255, 255),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sheetSectionHeader("Kategori"),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: ["Semua", "Listrik", "Air"].map((label) {
                      return _filterChip(
                        label: label,
                        isSelected: tempCategory == label,
                        onTap: () => setSheet(() => tempCategory = label),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  _sheetSectionHeader("Bulan"),
                  const SizedBox(height: 10),
                  if (months.isEmpty)
                    const Text(
                      "Belum ada data",
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    )
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _filterChip(
                          label: "Semua",
                          isSelected: tempMonth == null,
                          onTap: () => setSheet(() => tempMonth = null),
                        ),
                        ...months.map((month) {
                          final isActive =
                              tempMonth != null &&
                              tempMonth!.year == month.year &&
                              tempMonth!.month == month.month;
                          return _filterChip(
                            label: DateFormat('MMM yyyy').format(month),
                            isSelected: isActive,
                            onTap: () => setSheet(() => tempMonth = month),
                          );
                        }),
                      ],
                    ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _categoryFilter = tempCategory;
                          _selectedMonth = tempMonth;
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange.withOpacity(0.3),
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.2),
                          width: 0.9,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 20),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Reading Card
// ─────────────────────────────────────────────────────────────────────────────
class _ReadingCard extends StatelessWidget {
  final MeterReadingHistory reading;
  final Unit? unit;
  final VoidCallback onRefresh;

  const _ReadingCard({
    required this.reading,
    required this.unit,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final r = reading;
    final photoUrl = _buildPhotoUrl(r.photoPath);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: r.status == 'rejected'
                  ? Colors.redAccent.withOpacity(0.5)
                  : Colors.white.withOpacity(0.12),
              width: r.status == 'rejected' ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: photoUrl != null
                        ? Image.network(
                            photoUrl,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            headers: const {
                              'ngrok-skip-browser-warning': 'true',
                            },
                            errorBuilder: (_, __, ___) =>
                                _photoPlaceholder(context),
                          )
                        : _photoPlaceholder(context),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildTypeBadge(r),
                            const SizedBox(width: 6),
                            _buildStatusBadge(r),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          r.isElectric
                              ? "${r.readingValue} kWh"
                              : "${r.readingValue} m³",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: _orange,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 5),
                        _metaRow(
                          Icons.schedule_rounded,
                          _formatDate(r.recordedAt),
                        ),
                        if (r.meterNumber != null)
                          _metaRow(Icons.speed_rounded, r.meterNumber!),
                        if (r.locationAddress != null &&
                            r.locationAddress!.isNotEmpty)
                          _metaRow(
                            Icons.location_on_outlined,
                            r.locationAddress!,
                            maxLines: 2,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (r.status == 'rejected') ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: Colors.redAccent,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Data ditolak admin. Silakan perbaiki dan kirim ulang.",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (unit == null) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InputReadingScreen(
                            unit: unit!,
                            category: r.isElectric ? "Electric" : "Water",
                            isEdit: true,
                            initialValue: r.readingValue,
                          ),
                        ),
                      ).then((_) => onRefresh());
                    },
                    icon: const Icon(
                      Icons.build_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Perbaiki Data",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.25),
                      elevation: 0,
                      side: BorderSide(
                        color: Colors.redAccent.withOpacity(0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared smaller widgets & helpers
// ─────────────────────────────────────────────────────────────────────────────
Widget _buildTypeBadge(MeterReadingHistory r) {
  final isElec = r.isElectric;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: isElec
          ? Colors.amber.withOpacity(0.15)
          : Colors.cyan.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isElec
            ? Colors.amber.withOpacity(0.35)
            : Colors.cyan.withOpacity(0.3),
        width: 1,
      ),
    ),
    child: Text(
      isElec ? "⚡ Listrik" : "💧 Air",
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: isElec ? Colors.amber : Colors.cyan,
      ),
    ),
  );
}

Widget _buildStatusBadge(MeterReadingHistory r) {
  if (r.status == 'checked') {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.35), width: 1),
      ),
      child: const Text(
        "✓ Terverifikasi",
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.green,
        ),
      ),
    );
  } else if (r.status == 'rejected') {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.redAccent.withOpacity(0.35), width: 1),
      ),
      child: const Text(
        "✗ Ditolak",
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.redAccent,
        ),
      ),
    );
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.orange.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.orange.withOpacity(0.35), width: 1),
    ),
    child: const Text(
      "⏳ Menunggu",
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.orange,
      ),
    ),
  );
}

Widget _metaRow(IconData icon, String text, {int maxLines = 1}) {
  return Padding(
    padding: const EdgeInsets.only(top: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: Colors.white38),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11, color: Colors.white38),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

Widget _photoPlaceholder(BuildContext context) {
  return Container(
    width: 64,
    height: 64,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
    ),
    child: const Icon(
      Icons.image_not_supported_outlined,
      color: Colors.white24,
      size: 26,
    ),
  );
}

Widget _refreshButton() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.07),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
    ),
    child: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
  );
}

Widget _buildEmptyState() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _orange.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: _orange.withOpacity(0.4), width: 1.5),
          ),
          child: Icon(Icons.bar_chart_rounded, size: 32, color: _orange),
        ),
        const SizedBox(height: 16),
        const Text(
          "Tidak Ada Data",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Tidak ada data yang cocok dengan filter ini.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.white38),
        ),
      ],
    ),
  );
}

Widget _buildErrorState(VoidCallback onRetry) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.white24),
        const SizedBox(height: 14),
        const Text(
          "Gagal memuat data",
          style: TextStyle(
            color: Colors.white54,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _orange.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _orange.withOpacity(0.45)),
            ),
            child: Text(
              "Coba Lagi",
              style: TextStyle(color: _orange, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _sheetSectionHeader(String title) {
  return Text(
    title,
    style: const TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 15,
      color: Colors.white70,
      letterSpacing: 0.2,
    ),
  );
}

Widget _filterChip({
  required String label,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Data class helper
// ─────────────────────────────────────────────────────────────────────────────
class _UnitEntry {
  final Tenant tenant;
  final Unit unit;
  const _UnitEntry({required this.tenant, required this.unit});
}
