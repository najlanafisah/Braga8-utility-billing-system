import 'dart:ui';
import 'package:braga8_mobile/views/widgets/app_header.dart';
import 'package:braga8_mobile/views/widgets/main_layouts.dart';
import 'package:flutter/material.dart';
import 'package:braga8_mobile/ApiService.dart';
import 'package:braga8_mobile/views/meter_input/input_reading_screen.dart';
import 'package:braga8_mobile/data/models/tenant_model.dart';
import 'package:braga8_mobile/components/image_container_proof_component.dart';
import 'package:braga8_mobile/core/app_colors.dart';

class DetailUnitScreen extends StatefulWidget {
  final String shopName;
  final Unit unit;
  final VoidCallback? onBack;

  const DetailUnitScreen({
    super.key,
    required this.shopName,
    required this.unit,
    this.onBack,
  });

  @override
  State<DetailUnitScreen> createState() => _DetailUnitScreenState();
}

class _DetailUnitScreenState extends State<DetailUnitScreen>
    with SingleTickerProviderStateMixin {
  String selectedCategory = "Electric";
  late Unit currentUnit;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  static const _orange = AppColors.primaryOrange;
  Color get _orangeDim => _orange.withValues(alpha: .18);
  Color get _orangeBorder => _orange.withValues(alpha: .45);
  Color get _glass => Colors.white.withValues(alpha: .05);
  Color get _glassBorder => Colors.white.withValues(alpha: .12);

  AnimationController? _animController;
  Animation<double>? _fadeAnim;

  bool _canEdit(bool isElectric) {
    final status = isElectric
        ? currentUnit.elecStatus
        : currentUnit.waterStatus;
    return status != 'checked'; // allow edit if pending, rejected, or null
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController!,
      curve: Curves.easeOut,
    );
    _animController!.forward();
    currentUnit = widget.unit;

    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshData());
  }

  @override
  void dispose() {
    _animController?.dispose();
    super.dispose();
  }

  Future<void> _refreshData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final tenants = await _apiService.fetchUnitsSummary();
      for (var tenant in tenants) {
        try {
          final updatedUnit = tenant.units.firstWhere(
            (u) => u.id == currentUnit.id,
          );
          if (mounted) setState(() => currentUnit = updatedUnit);
          break;
        } catch (_) {
          continue;
        }
      }
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

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final normalized = raw.replaceFirstMapped(
        RegExp(r'(\.\d{3})\d+'),
        (m) => m.group(1)!,
      );
      final dt = DateTime.parse(normalized).toLocal();
      // Manual format as guaranteed fallback — no locale dependency
      const months = [
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
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      return '$h:$m, $d ${months[dt.month]} ${dt.year}';
    } catch (e) {
      debugPrint('_formatDate error: $e  raw: $raw');
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String apiImageUrl =
    "${ApiService().dio.options.baseUrl.replaceAll('/api', '')}/api/meter-photo/";
    final bool isElectric = selectedCategory == "Electric";

    final String? readingValue = isElectric
        ? currentUnit.elecReadingValue
        : currentUnit.waterReadingValue;
    final String? recordedDate = isElectric
        ? currentUnit.elecRecordedAt
        : currentUnit.waterRecordedAt;
    final String? currentLocation = isElectric
        ? (currentUnit.elecLocationAddress ?? currentUnit.locationAddress)
        : (currentUnit.waterLocationAddress ?? currentUnit.locationAddress);
    final String? rawPath = isElectric
        ? currentUnit.elecPhotoPath
        : currentUnit.waterPhotoPath;
    final String? currentPhotoUrl = (rawPath != null && rawPath.isNotEmpty)
        ? "$apiImageUrl${rawPath.split('/').last}"
        : null;
    final String? prevRawPath = isElectric
        ? currentUnit.prevElecPhotoPath
        : currentUnit.prevWaterPhotoPath;
    final String? prevPhotoUrl = (prevRawPath != null && prevRawPath.isNotEmpty)
        ? "$apiImageUrl${prevRawPath.split('/').last}"
        : null;
    final bool hasData = readingValue != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,

      body: MainLayout(
        child: SafeArea(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: _orange))
              : FadeTransition(
                  opacity: _fadeAnim ?? const AlwaysStoppedAnimation(1.0),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppHeader(
                          title: "Detail unit ${currentUnit.unitNumber}",
                          titleIcon: Icons.store_rounded,
                          onBack: widget.onBack,
                          trailing: GestureDetector(
                            onTap: () => _refreshData(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .07),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .12),
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
                        const SizedBox(height: 10),
                        _buildUnitInfoCard(),

                        const SizedBox(height: 20),

                        _buildCategorySwitcher(isElectric),

                        const SizedBox(height: 24),

                        if (!hasData)
                          _buildEmptyState(isElectric)
                        else ...[
                          _buildReadingCard(isElectric, readingValue),
                          const SizedBox(height: 20),
                          _buildSectionLabel(
                            Icons.photo_library_rounded,
                            "Foto Bukti Meter",
                          ),
                          const SizedBox(height: 12),
                          ImageContainerProofComponent(
                            currentImageUrl: currentPhotoUrl,
                            previousImageUrl: prevPhotoUrl,
                          ),
                          const SizedBox(height: 20),
                          _buildSectionLabel(
                            Icons.info_outline_rounded,
                            "Metadata Entri",
                          ),
                          const SizedBox(height: 12),
                          _buildMetadataCard(recordedDate, currentLocation),
                        ],

                        const SizedBox(height: 32),

                        if (!hasData)
                          _buildPrimaryButton(
                            icon: Icons.add_circle_outline_rounded,
                            label: "Input Bacaan Baru",
                            onTap: () async {
                              final result =
                                  await Navigator.pushNamed(
                                    context,
                                    '/input-reading',
                                    arguments: {
                                      'unit': currentUnit,
                                      'category': selectedCategory,
                                      'isEdit': false,
                                    },
                                  ).then((result) {
                                    if (result == true) _refreshData();
                                  });

                              if (result == true) _refreshData();
                            },
                          )
                        else if (_canEdit(isElectric))
                          _buildPrimaryButton(
                            icon: Icons.edit_rounded,
                            label: "Edit Bacaan Meter",
                            onTap: () async {
                              final String? initialValue =
                                  selectedCategory == "Electric"
                                  ? currentUnit.elecReadingValue
                                  : currentUnit.waterReadingValue;
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => InputReadingScreen(
                                    unit: currentUnit,
                                    category: selectedCategory,
                                    isEdit: true,
                                    initialValue: initialValue,
                                  ),
                                ),
                              );
                              if (result == true) _refreshData();
                            },
                          )
                        else
                          _buildStatusLockedButton(isElectric),
                        const SizedBox(height: 10),

                        _buildSecondaryButton(
                          icon: Icons.history_rounded,
                          label: "Lihat Riwayat Bacaan",
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/meter-history',
                            arguments: {
                              'unitId': currentUnit.id,
                              'unitNumber': currentUnit.unitNumber,
                              'unit': currentUnit,
                            },
                          ).then((_) => _refreshData()),
                        ),

                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildUnitInfoCard() {
    return _glassCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _orangeDim,
              shape: BoxShape.circle,
              border: Border.all(color: _orangeBorder, width: 1.5),
            ),
            child: Icon(Icons.store_rounded, color: _orange, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.shopName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  "Unit ${currentUnit.unitNumber}  ·  Lantai ${currentUnit.floor}",
                  style: const TextStyle(fontSize: 13, color: Colors.white54),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _statusDot(
                currentUnit.isElecChecked,
                Icons.bolt_rounded,
                "Listrik",
              ),
              const SizedBox(height: 6),
              _statusDot(
                currentUnit.isWaterChecked,
                Icons.water_drop_rounded,
                "Air",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusDot(bool active, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: active ? Colors.white54 : Colors.white24,
          ),
        ),
        const SizedBox(width: 5),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? Colors.greenAccent : Colors.white24,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySwitcher(bool isElectric) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Icon(Icons.touch_app_rounded, size: 14, color: _orange),
              const SizedBox(width: 6),
              Text(
                "Pilih jenis meter yang ingin dilihat",
                style: TextStyle(
                  fontSize: 12,
                  color: _orange.withValues(alpha: .8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: _glass,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _glassBorder),
              ),
              child: Row(
                children: [
                  _categoryTab(
                    label: "Listrik",
                    icon: Icons.bolt_rounded,
                    isActive: isElectric,
                    meterNo: currentUnit.electricMeterNumber ?? "Tidak ada",
                    hasData: currentUnit.isElecChecked,
                    onTap: () => setState(() => selectedCategory = "Electric"),
                  ),
                  const SizedBox(width: 5),
                  _categoryTab(
                    label: "Air",
                    icon: Icons.water_drop_rounded,
                    isActive: !isElectric,
                    meterNo: currentUnit.waterMeterNumber ?? "Tidak ada",
                    hasData: currentUnit.isWaterChecked,
                    onTap: () => setState(() => selectedCategory = "Water"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _categoryTab({
    required String label,
    required IconData icon,
    required bool isActive,
    required String meterNo,
    required bool hasData,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: isActive ? _orangeDim : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? _orangeBorder : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isActive ? _orange : Colors.white38,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isActive ? _orange : Colors.white38,
                    ),
                  ),
                  const Spacer(),
                  // Data status dot
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: hasData ? Colors.greenAccent : Colors.white24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                meterNo,
                style: TextStyle(
                  fontSize: 11,
                  color: isActive ? Colors.white54 : Colors.white24,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                hasData ? "Data tersedia" : "Belum ada data",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: hasData
                      ? Colors.greenAccent.withValues(alpha: .8)
                      : Colors.white24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReadingCard(bool isElectric, String readingValue) {
    return _glassCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _orangeDim,
                  shape: BoxShape.circle,
                  border: Border.all(color: _orangeBorder, width: 1.2),
                ),
                child: Icon(
                  isElectric ? Icons.bolt_rounded : Icons.water_drop_rounded,
                  color: _orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isElectric
                        ? "Bacaan Meter Listrik Saat Ini"
                        : "Bacaan Meter Air Saat Ini",
                    style: const TextStyle(fontSize: 12, color: Colors.white54),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isElectric ? "$readingValue kWh" : "$readingValue m³",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _orange,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isElectric) {
    return _glassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: Column(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: _orangeDim,
                  shape: BoxShape.circle,
                  border: Border.all(color: _orangeBorder, width: 1.5),
                ),
                child: Icon(
                  Icons.add_a_photo_outlined,
                  size: 32,
                  color: _orange,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Belum Ada Data",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isElectric
                    ? "Belum ada bacaan meter listrik untuk unit ini."
                    : "Belum ada bacaan meter air untuk unit ini.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.white38),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataCard(String? date, String? location) {
    return _glassCard(
      child: Column(
        children: [
          _metaRow(
            Icons.calendar_today_rounded,
            "Tanggal Input",
            _formatDate(date),
          ), // <-- wrap di sini
          const SizedBox(height: 12),
          _metaRow(Icons.location_on_outlined, "Lokasi", location ?? '-'),
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _orange),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.white38),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(IconData icon, String title) {
    return Row(
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
  }

  Widget _buildPrimaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _orange.withValues(alpha: .28),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: _orangeBorder, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white54, size: 18),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(color: _glassBorder, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

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

  Widget _buildStatusLockedButton(bool isElectric) {
    final status = isElectric
        ? currentUnit.elecStatus
        : currentUnit.waterStatus;
    final isRejected = status == 'rejected';

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: isRejected
            ? () async {
                final String? initialValue = isElectric
                    ? currentUnit.elecReadingValue
                    : currentUnit.waterReadingValue;
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InputReadingScreen(
                      unit: currentUnit,
                      category: selectedCategory,
                      isEdit: true,
                      initialValue: initialValue,
                    ),
                  ),
                );
                if (result == true) _refreshData();
              }
            : null,
        icon: Icon(
          isRejected ? Icons.build_rounded : Icons.lock_rounded,
          color: isRejected ? Colors.white : Colors.white38,
          size: 20,
        ),
        label: Text(
          isRejected ? "Perbaiki Data" : "Terverifikasi — Tidak Bisa Diedit",
          style: TextStyle(
            color: isRejected ? Colors.white : Colors.white38,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isRejected
              ? Colors.redAccent.withValues(alpha: .25)
              : Colors.white.withValues(alpha: .05),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: BorderSide(
            color: isRejected
                ? Colors.redAccent.withValues(alpha: .5)
                : Colors.white.withValues(alpha: .1),
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
