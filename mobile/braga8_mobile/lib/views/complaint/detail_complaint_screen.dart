import 'dart:typed_data';
import 'dart:ui';
import 'package:braga8_mobile/ApiService.dart';
import 'package:braga8_mobile/data/models/complaint_model.dart';
import 'package:braga8_mobile/views/complaint/customer_care_screen.dart';
import 'package:braga8_mobile/views/complaint/edit_complaint_screen.dart';
import 'package:braga8_mobile/views/complaint/input_complaint_screen.dart';
import 'package:braga8_mobile/core/app_colors.dart';
import 'package:braga8_mobile/views/widgets/app_header.dart';
import 'package:braga8_mobile/views/widgets/main_layouts.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class DetailComplaintScreen extends StatefulWidget {
  final Complaint complaint;
  final VoidCallback? onBack;

  const DetailComplaintScreen({
    super.key,
    required this.complaint,
    this.onBack,
  });

  @override
  State<DetailComplaintScreen> createState() => _DetailComplaintScreenState();
}

class _DetailComplaintScreenState extends State<DetailComplaintScreen>
    with SingleTickerProviderStateMixin {
  // ── State ─────────────────────────────────────────────────────────────────────
  late Complaint _complaint;
  bool _isLoading = false;
  bool _imageExpanded = false;
  Uint8List? _imageBytes;

  // ── Services ──────────────────────────────────────────────────────────────────
  final ApiService _apiService = ApiService();

  // ── Animation ─────────────────────────────────────────────────────────────────
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  // ── Colors ────────────────────────────────────────────────────────────────────
  static const _orange = AppColors.primaryOrange;
  Color get _orangeDim => _orange.withOpacity(0.22);
  Color get _orangeBorder => _orange.withOpacity(0.45);
  Color get _glass => Colors.white.withOpacity(0.05);
  Color get _glassBorder => Colors.white.withOpacity(0.12);

  // ── Derived ───────────────────────────────────────────────────────────────────
  /// Edit is allowed only when the admin hasn't yet provided a solution
  bool get _canEdit =>
      (_complaint.solution == null || _complaint.solution!.trim().isEmpty) &&
      _complaint.status != 'resolved' &&
      _complaint.status != 'rejected';

  String get _imageFullUrl {
    final raw = _complaint.imageUrl ?? '';
    if (raw.isEmpty) return '';
    if (raw.startsWith('http')) return raw;
    final filename = raw.split('/').last;
    return 'https://bunkbed-deem-spew.ngrok-free.dev/api/complaint-image/$filename';
  }

  @override
  void initState() {
    super.initState();
    _complaint = widget.complaint;
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _refreshComplaint();
    _imageBytes != null
        ? Image.memory(_imageBytes!, fit: BoxFit.cover)
        : Container(
            color: _glass,
            child: Center(child: CircularProgressIndicator(color: _orange)),
          );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Refresh ───────────────────────────────────────────────────────────────────
  Future<void> _refreshComplaint() async {
    setState(() => _isLoading = true);
    try {
      // Fetch fresh complaint data from the API
      final fresh = await _apiService.fetchComplaintById(_complaint.id);
      debugPrint('IMAGE URL RAW: ${fresh.imageUrl}');
      debugPrint('IMAGE FULL URL: $_imageFullUrl');
      if (mounted) setState(() => _complaint = fresh);
    } catch (e) {
      // silently keep existing data on error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadImage() async {
    if (_imageFullUrl.isEmpty) return;
    try {
      final response = await _apiService.dio.get(
        _imageFullUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'ngrok-skip-browser-warning': 'true'},
        ),
      );
      if (mounted)
        setState(() => _imageBytes = Uint8List.fromList(response.data));
    } catch (e) {
      debugPrint('Image load error: $e');
    }
  }

  // ── Navigate to Edit ──────────────────────────────────────────────────────────
  Future<void> _openEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditComplaintScreen(complaint: _complaint),
      ),
    );
    _refreshComplaint();
  }

  // ── Snack ─────────────────────────────────────────────────────────────────────
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
                  Icon(
                    isError
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    color: isError ? Colors.redAccent : _orange,
                    size: 18,
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
            child: RefreshIndicator(
              color: _orange,
              backgroundColor: Colors.black87,
              onRefresh: _refreshComplaint,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ──────────────────────────────────────────
                    AppHeader(
                      title: "Detail Komplain",
                      titleIcon: Icons.report_problem_rounded,
                      onBack: () {
                        Navigator.pop(context);
                        widget.onBack?.call();
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isLoading)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _orange,
                                ),
                              ),
                            ),
                          _buildEditButton(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Status Badge ────────────────────────────────────
                    _buildStatusBadge(),

                    const SizedBox(height: 20),

                    // ── Title Card ──────────────────────────────────────
                    _buildInfoCard(
                      icon: Icons.report_problem_rounded,
                      label: "Judul Komplain",
                      child: Text(
                        _complaint.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Description Card ────────────────────────────────
                    _buildInfoCard(
                      icon: Icons.description_rounded,
                      label: "Keterangan",
                      child: Text(
                        _complaint.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Meta row (date) ─────────────────────────────────
                    if (_complaint.reportDate != null) _buildMetaRow(),

                    const SizedBox(height: 20),

                    // ── Photo ───────────────────────────────────────────
                    if (_imageFullUrl.isNotEmpty) ...[
                      _buildPhotoSection(),
                      const SizedBox(height: 14),
                    ],

                    // ── Solution Card ───────────────────────────────────
                    _buildSolutionCard(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Edit Button ───────────────────────────────────────────────────────────────
  Widget _buildEditButton() {
    return GestureDetector(
      onTap: _canEdit ? _openEdit : _showEditLockedSnack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: _canEdit ? _orangeDim : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _canEdit ? _orangeBorder : Colors.white24,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _canEdit ? Icons.edit_rounded : Icons.lock_rounded,
              size: 14,
              color: _canEdit ? _orange : Colors.white30,
            ),
            const SizedBox(width: 5),
            Text(
              "Edit",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _canEdit ? _orange : Colors.white30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditLockedSnack() {
    _showSnack(
      "Komplain tidak dapat diedit — admin telah memberikan solusi.",
      isError: true,
    );
  }

  // ── Status Badge ──────────────────────────────────────────────────────────────
  Widget _buildStatusBadge() {
    final cfg = _statusConfig(_complaint.status);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: cfg.color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cfg.color.withOpacity(0.45), width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(cfg.icon, size: 14, color: cfg.color),
              const SizedBox(width: 6),
              Text(
                cfg.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: cfg.color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Animated dot
        _PulseDot(color: cfg.color, active: _complaint.status == 'in_progress'),
      ],
    );
  }

  // ── Info Card ─────────────────────────────────────────────────────────────────
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _orange),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _orange,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildMetaRow() {
    // ── Parse & format the date ──────────────────────────────────────────
    String _formatDate(String? raw) {
      if (raw == null || raw.isEmpty) return '-';
      try {
        final dt = DateTime.parse(raw);
        const months = [
          'January',
          'February',
          'March',
          'April',
          'May',
          'June',
          'July',
          'August',
          'September',
          'October',
          'November',
          'December',
        ];
        return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
      } catch (_) {
        return raw; // fallback: show raw string if parsing fails
      }
    }

    return _glassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 14, color: _orange),
          const SizedBox(width: 8),
          const Text(
            "Tanggal Laporan",
            style: TextStyle(
              fontSize: 12,
              color: Colors.white54,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            _formatDate(_complaint.reportDate), // ← changed
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Photo Section ─────────────────────────────────────────────────────────────
  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.camera_alt_rounded, size: 16, color: _orange),
            const SizedBox(width: 6),
            Text(
              "Foto Bukti",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _orange,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => setState(() => _imageExpanded = !_imageExpanded),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: double.infinity,
            height: _imageExpanded ? 300 : 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _orangeBorder, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: _orange.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _imageFullUrl,
                    headers: const {
                      'ngrok-skip-browser-warning': 'true',
                      'Access-Control-Allow-Origin': '*',
                    },
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        color: _glass,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: _orange,
                            strokeWidth: 2,
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                      progress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      color: _glass,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_rounded,
                            color: Colors.white24,
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Gagal memuat foto",
                            style: TextStyle(
                              color: Colors.white24,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Expand hint overlay
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _imageExpanded
                            ? Icons.zoom_in_map_rounded
                            : Icons.zoom_out_map_rounded,
                        color: Colors.white70,
                        size: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Center(
          child: Text(
            _imageExpanded ? "Tap untuk perkecil" : "Tap untuk perbesar",
            style: const TextStyle(fontSize: 11, color: Colors.white24),
          ),
        ),
      ],
    );
  }

  // ── Solution Card ─────────────────────────────────────────────────────────────
  Widget _buildSolutionCard() {
    final hasSolution =
        _complaint.solution != null && _complaint.solution!.trim().isNotEmpty;

    return AnimatedSize(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      child: _glassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: hasSolution
                        ? Colors.green.withOpacity(0.15)
                        : _orangeDim,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasSolution
                        ? Icons.task_alt_rounded
                        : Icons.hourglass_empty_rounded,
                    size: 16,
                    color: hasSolution ? Colors.greenAccent : _orange,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  "Jawaban dari Admin",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: hasSolution ? Colors.greenAccent : Colors.white70,
                  ),
                ),
                const Spacer(),
                if (!hasSolution)
                  _PulseDot(color: _orange, active: true, size: 7),
              ],
            ),
            const SizedBox(height: 14),
            if (hasSolution)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                child: Text(
                  _complaint.solution!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _orangeDim.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _orangeBorder, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: _orange),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        "Komplain Anda sedang diproses. Solusi akan muncul di sini setelah admin merespons.",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // Pull-to-refresh hint
            if (!hasSolution) ...[
              const SizedBox(height: 10),
              Center(
                child: Text(
                  "Tarik ke bawah untuk memperbarui status",
                  style: const TextStyle(fontSize: 11, color: Colors.white24),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Glass Card ────────────────────────────────────────────────────────────────
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

  // ── Status Config ─────────────────────────────────────────────────────────────
  _StatusConfig _statusConfig(String status) {
    switch (status) {
      case 'in_progress':
        return _StatusConfig(
          color: Colors.blueAccent,
          icon: Icons.autorenew_rounded,
          label: "Sedang Diproses",
        );
      case 'resolved':
        return _StatusConfig(
          color: Colors.greenAccent,
          icon: Icons.check_circle_rounded,
          label: "Selesai",
        );
      case 'rejected':
        return _StatusConfig(
          color: Colors.redAccent,
          icon: Icons.cancel_rounded,
          label: "Ditolak",
        );
      default:
        return _StatusConfig(
          color: _orange,
          icon: Icons.schedule_rounded,
          label: "Menunggu",
        );
    }
  }
}

// ── Status Config Model ────────────────────────────────────────────────────────
class _StatusConfig {
  final Color color;
  final IconData icon;
  final String label;
  const _StatusConfig({
    required this.color,
    required this.icon,
    required this.label,
  });
}

// ── Pulsing Dot ───────────────────────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  final Color color;
  final bool active;
  final double size;
  const _PulseDot({required this.color, required this.active, this.size = 8});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _anim = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.active) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
