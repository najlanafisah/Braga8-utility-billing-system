import 'dart:convert';
import 'package:braga8_mobile/data/models/audit_log_model.dart';
import 'package:braga8_mobile/data/models/complaint_model.dart';
import 'package:braga8_mobile/data/models/invoice_detail_model.dart';
import 'package:braga8_mobile/data/models/invoice_model.dart';
import 'package:braga8_mobile/data/models/meter_reading_model.dart';
import 'package:braga8_mobile/data/models/tenant_model.dart';
import 'package:braga8_mobile/data/models/notification_model.dart';
import 'package:braga8_mobile/views/payments/payment_logs_screen.dart';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as _dio;

int unreadNotificationsCount = 0;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService({String? token}) {
    if (token != null) _instance.token = token;
    return _instance;
  }
  ApiService._internal();

  String? token;
  Map<String, dynamic>? currentUser;
  Tenant? currentTenant;

  static const String _baseUrl = 'https://untie-exfoliate-petunia.ngrok-free.dev';

  final Dio dio =
      Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'ngrok-skip-browser-warning': 'true',
            },
          ),
        )
        ..interceptors.add(
          LogInterceptor(responseBody: true, requestBody: true, error: true),
        );

  Options _authOptions([String? providedToken]) {
    final effectiveToken = (providedToken ?? token ?? "").trim();
    return Options(headers: {'Authorization': 'Bearer $effectiveToken'});
  }

  // --- AUTHENTICATION ---

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );
      if (response.data != null && response.data['token'] != null) {
        token = response.data['token'];
        currentUser = response.data['user'];

        // Try both common structures
        final tenantJson = response.data['user']?['tenant_details'];
        if (tenantJson != null) {
          currentTenant = Tenant.fromJson(tenantJson as Map<String, dynamic>);
        }
      }
      final tenantJson = response.data['user']?['tenant_details'];
      if (tenantJson != null) {
        currentTenant = Tenant.fromJson(tenantJson as Map<String, dynamic>);
      }
      return response.data;
    } on DioException catch (e) {
      print('Login Error: ${e.response?.data}');
      return null;
    }
  }

  Future<void> loadCurrentTenantUnits() async {
    if (currentTenant == null) return;
    try {
      final tenants = await fetchUnitsSummary();
      final match = tenants.where((t) => t.id == currentTenant!.id).firstOrNull;
      if (match != null) {
        currentTenant = Tenant(
          id: currentTenant!.id,
          name: currentTenant!.name,
          units: match.units,
        );
      }
    } catch (_) {}
  }

  Future<void> logout(String providedToken) async {
    try {
      await dio.post('/logout', options: _authOptions(providedToken));
      currentUser = null;
      currentTenant = null; // ← add this
      token = null;
    } catch (e) {
      print('Logout Error: $e');
    }
  }

  // --- TENANT & PROFILE ---

  Future<List<dynamic>> getTenants(String providedToken) async {
    try {
      final response = await dio.get(
        '/tenants',
        options: _authOptions(providedToken),
      );
      return response.data is List
          ? response.data
          : (response.data['data'] ?? []);
    } catch (e) {
      print('Fetch Tenants Error: $e');
      return [];
    }
  }

  Future<bool> updateProfile(
    Map<String, dynamic> data,
    String providedToken,
  ) async {
    try {
      final response = await dio.post(
        '/profile/update',
        data: data,
        options: _authOptions(providedToken),
      );
      if (response.statusCode == 200) {
        currentUser = response.data['user'];
        return true;
      }
      return false;
    } on DioException catch (e) {
      print("Update Profile Error: ${e.response?.data}");
      return false;
    }
  }

  // --- NOTIFICATIONS ---

  Future<List<NotificationModel>> getNotifications(String providedToken) async {
    try {
      final response = await dio.get(
        '/notifications',
        options: _authOptions(providedToken),
      );
      final List rawData = response.data['data']['data'] ?? [];
      return rawData.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      print('Fetch Notifications Error: $e');
      return [];
    }
  }

  Future<bool> markAsRead(int id, String providedToken) async {
    try {
      final response = await dio.patch(
        '/notifications/$id/read',
        options: _authOptions(providedToken),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Mark Read Error: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(int id, String providedToken) async {
    try {
      final response = await dio.delete(
        '/notifications/$id',
        options: _authOptions(providedToken),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Delete Notification Error: $e');
      return false;
    }
  }

  // --- METER STATS ---

  Future<Map<String, dynamic>> getMonthlyStats(String providedToken) async {
    try {
      final response = await dio.get(
        '/meter-progress',
        options: _authOptions(providedToken),
      );
      return response.data;
    } on DioException catch (e) {
      print('Fetch Stats Error: ${e.response?.data}');
      return {'total': 0, 'readings': 0, 'percentage': 0};
    }
  }

  // --- UNITS ---

  Future<List<Tenant>> fetchUnitsSummary() async {
    try {
      final response = await dio.get('/units/summary', options: _authOptions());
      print("RAW DATA FROM SERVER: ${response.data}"); // <--- LIHAT DI CONSOLE
      final List data = response.data;
      return data.map((t) => Tenant.fromJson(t)).toList();
    } catch (e) {
      throw Exception('Failed to load units');
    }
  }

  // --- LOCATION ---

  Future<Position> determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    return await Geolocator.getCurrentPosition();
  }

  // --- AUDIT LOGS ---

  Future<AuditLogResponse> fetchLogs(int page) async {
    try {
      final response = await dio.get(
        '/audit-logs',
        queryParameters: {'page': page},
        options: _authOptions(),
      );
      if (response.statusCode == 200)
        return AuditLogResponse.fromJson(response.data);
      throw Exception('Failed to load audit logs');
    } on DioException catch (e) {
      print('Fetch Logs Error: ${e.response?.data}');
      throw Exception('Network error while fetching logs');
    }
  }

  // --- METER READINGS ---

  Future<bool> updateReading({
    required int readingId,
    required String newValue,
    String? description,
  }) async {
    try {
      final response = await dio.put(
        '/readings/$readingId',
        data: {'reading_value': newValue, 'description': description},
        options: _authOptions(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Update Reading Error: $e');
      return false;
    }
  }

  /// Kirim data meter reading ke Laravel.
  ///
  /// STRATEGI: selalu pakai JSON + Base64 untuk foto.
  /// Tidak ada lagi kIsWeb branch — Base64 works di web DAN mobile.
  /// Laravel decode Base64 via injectBase64Photo() di controller.
  Future<bool> submitMeterReading(
    Map<String, dynamic> data,
    XFile? image, {
    bool isEdit = false,
    int? readingId,
    required int unitId,
    required int meterId, // Gunakan parameter ini
  }) async {
    try {
      final String path = isEdit ? '/readings/$readingId' : '/readings';
      final Map<String, dynamic> payload = Map.from(data);

      // KUNCI PERBAIKAN:
      payload['meter_id'] = meterId; // ID dari tabel utility_meters
      payload['unit_id'] = unitId; // ID dari tabel units

      if (isEdit) payload['_method'] = 'PUT';

      if (image != null) {
        final bytes = await image.readAsBytes();
        final ext = image.name.split('.').last.toLowerCase();
        final mime = (ext == 'png') ? 'image/png' : 'image/jpeg';
        payload['photo_base64'] = 'data:$mime;base64,${base64Encode(bytes)}';
      }

      final response = await dio.post(
        path,
        data: payload,
        options: _authOptions(),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      debugPrint('DETAIL ERROR: ${jsonEncode(e.response?.data)}');
      final serverMessage = e.response?.data?['message'];
      if (serverMessage != null) throw Exception(serverMessage);
      return false;
    }
  }

  Future<List<MeterReadingHistory>> fetchReadingHistory(int unitId) async {
    try {
      final response = await dio.get(
        '/units/$unitId/readings',
        options: _authOptions(),
      );
      final List data = response.data as List;
      return data.map((e) => MeterReadingHistory.fromJson(e)).toList();
    } on DioException catch (e) {
      debugPrint('Fetch History Error: ${e.response?.data}');
      throw Exception('Failed to load reading history');
    }
  }

  // Add this to ApiService.dart
  Future<List<MeterReadingHistory>> fetchAllReadings() async {
    try {
      final response = await dio.get('/readings', options: _authOptions());
      final List data = response.data;
      return data.map((e) => MeterReadingHistory.fromJson(e)).toList();
    } catch (e) {
      return []; // Return empty if it fails
    }
  }

  Future<Object?> getBillingSummary(String token) async {}

  Future<bool> clearAllNotifications(String providedToken) async {
    try {
      final response = await dio.delete(
        '/notifications',
        options: _authOptions(providedToken),
      );
      print('Clear All Status: ${response.statusCode}');
      print('Clear All Response: ${response.data}');
      return response.statusCode == 200;
    } on DioException catch (e) {
      print('Clear All Error Status: ${e.response?.statusCode}');
      print('Clear All Error Body: ${e.response?.data}');
      return false;
    }
  }

  Future<bool> markAllAsRead(String providedToken) async {
    try {
      final response = await dio.patch(
        '/notifications/read-all',
        options: _authOptions(providedToken),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Mark All Read Error: $e');
      return false;
    }
  }

  void setCurrentUser(Map<String, dynamic> user) {
    currentUser = user;
  }

  // ── Complaints ────────────────────────────────────────────────────────────────

  /// GET /api/complaints
  Future<List<Complaint>> fetchComplaints({String? providedToken}) async {
    if (providedToken != null && providedToken.isNotEmpty) {
      token = providedToken;
    }
    try {
      final response = await dio.get('/complaints', options: _authOptions());
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data
          .map((e) => Complaint.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?;
      throw Exception(msg ?? "Gagal memuat daftar komplain");
    }
  }

  Future<Complaint> fetchComplaintById(int id) async {
    try {
      final response = await dio.get('/complaints', options: _authOptions());
      final List<dynamic> data = response.data['data'] ?? response.data;
      return data
          .map((e) => Complaint.fromJson(e as Map<String, dynamic>))
          .firstWhere((c) => c.id == id);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?;
      throw Exception(msg ?? "Gagal memuat komplain");
    }
  }

  /// POST /api/complaints  (create)
  /// POST /api/complaints/{id} + _method=PUT (edit)

  Future<bool> submitComplaint(
    Map<String, dynamic> payload,
    XFile? photo, {
    bool isEdit = false,
    int? complaintId,
    String? providedToken,
  }) async {
    try {
      final Map<String, dynamic> formMap = {...payload};

      if (isEdit) formMap['_method'] = 'PUT';

      if (photo != null) {
        // Sama seperti submitMeterReading — pakai Base64 agar konsisten
        final bytes = await photo.readAsBytes();
        final ext = photo.name.split('.').last.toLowerCase();
        final mime = (ext == 'png') ? 'image/png' : 'image/jpeg';
        formMap['photo_base64'] = 'data:$mime;base64,${base64Encode(bytes)}';
      }

      final String path = isEdit ? '/complaints/$complaintId' : '/complaints';

      final response = await dio.post(
        path,
        data: formMap,
        options: _authOptions(),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      debugPrint('Submit Complaint Error: ${jsonEncode(e.response?.data)}');
      final msg = e.response?.data?['message'] as String?;
      throw Exception(msg ?? "Gagal menyimpan komplain");
    }
  }

  /// DELETE /api/complaints/{id}
  Future<void> deleteComplaint(int id) async {
    try {
      final response = await dio.delete(
        '/complaints/${id.toString()}', // explicit stringify
        options: _authOptions(),
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        final msg = response.data?['message'] as String?;
        throw Exception(msg ?? "Gagal menghapus komplain");
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?;
      throw Exception(msg ?? "Gagal menghapus komplain");
    }
  }

  Future<List<InvoiceGroup>> fetchInvoicesSummary() async {
    try {
      final response = await dio.get(
        '/invoices/summary',
        options: _authOptions(),
      );
      final List<dynamic> data = response.data['data'];

      // Debug: parse one by one to find the culprit
      final result = <InvoiceGroup>[];
      for (int i = 0; i < data.length; i++) {
        try {
          result.add(InvoiceGroup.fromJson(data[i]));
        } catch (e) {
          debugPrint('❌ Failed at group index $i: ${data[i]}');
          debugPrint('Error: $e');
        }
      }
      return result;
    } on DioException catch (e) {
      debugPrint('Fetch Invoices Error: ${e.response?.data}');
      throw Exception('Gagal memuat daftar invoice: ${e.response?.statusCode}');
    }
  }

  /// Marks an invoice as paid (creates a verified payment record).
  Future<void> markInvoicePaid(int invoiceId) async {
    try {
      final response = await dio.post(
        '/invoices/$invoiceId/pay',
        options: _authOptions(),
      );
      if (response.statusCode != 200) {
        throw Exception('Gagal memproses pembayaran: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] as String?;
      throw Exception(msg ?? 'Gagal memproses pembayaran');
    }
  }

  Future<Map<String, dynamic>?> getTenantProfile(String providedToken) async {
    try {
      final response = await dio.get(
        '/tenant/profile',
        options: _authOptions(providedToken),
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } on DioException catch (e) {
      print('getTenantProfile Error: ${e.response?.data}');
      return null; // returns null instead of throwing — so _fetchTenantDetails won't error
    }
  }

  Future<InvoiceDetail> fetchInvoiceDetail(int invoiceId) async {
    try {
      final response = await dio.get(
        '/invoices/$invoiceId/detail',
        options: _authOptions(),
      );
      return InvoiceDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      debugPrint('Fetch Invoice Detail Error: ${e.response?.data}');
      throw Exception('Gagal memuat detail invoice: ${e.response?.statusCode}');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // ADD THIS METHOD inside your ApiService class (ApiService.dart)
  // ─────────────────────────────────────────────────────────────────────────────

  // Required import at top of ApiService.dart (already present in your file):
  // import 'package:camera/camera.dart';   ← for XFile
  // import 'dart:convert';                 ← for base64Encode

  /// POST /api/payments
  ///
  /// Submits a payment proof for the given [invoiceId].
  /// The backend stores it as a [pending] payment awaiting admin verification.
  ///
  /// Payload mirrors the `payments` table schema:
  ///   invoice_id, amount_paid, payment_date, paid_using, proof_img (Base64),
  ///   notes (nullable)
  Future<bool> submitPayment({
    required int invoiceId,
    required double amountPaid,
    required String paidUsing,
    required XFile proofPhoto,
    String? notes,
  }) async {
    try {
      // Encode photo to Base64 (same strategy as submitMeterReading)
      final bytes = await proofPhoto.readAsBytes();
      final ext = proofPhoto.name.split('.').last.toLowerCase();
      final mime = (ext == 'png') ? 'image/png' : 'image/jpeg';
      final base64Photo = 'data:$mime;base64,${base64Encode(bytes)}';

      final Map<String, dynamic> payload = {
        'invoice_id': invoiceId,
        'amount_paid': amountPaid,
        'payment_date': DateTime.now().toIso8601String(),
        'paid_using': paidUsing,
        'proof_base64': base64Photo,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final response = await dio.post(
        '/payments',
        data: payload,
        options: _authOptions(),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      debugPrint('submitPayment Error: ${jsonEncode(e.response?.data)}');
      final msg = e.response?.data?['message'] as String?;
      throw Exception(msg ?? 'Gagal mengirim bukti pembayaran');
    }
  }

  Future<List<PaymentLog>> fetchPaymentLogs() async {
    try {
      final response = await dio.get('/payments', options: _authOptions());
      final List raw = response.data['data'] ?? response.data;
      return raw
          .map((e) => PaymentLog.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      debugPrint('fetchPaymentLogs Error: ${e.response?.data}');
      return [];
    }
  }
}
