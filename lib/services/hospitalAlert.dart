import 'dart:convert';
import 'dart:developer' as dev;

import 'package:dio/dio.dart';

/// AlertService wraps the network call that hits the
/// `/hospital-alert/send` endpoint and now prints rich
/// debug information so you can inspect the outgoing
/// payload *and* the backend response.
class AlertService {
  final Dio _dio;

  AlertService({required String baseUrl})
      : _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
    headers: {"Content-Type": "application/json"},
  ));

  /// Sends an SOS payload to the backend and logs all details.
  Future<bool> sendHospitalAlert({
    required String userId,
    required double latitude,
    required double longitude,
    required Map<String, dynamic> userDetails,
    required List<Map<String, dynamic>> emergencyContacts,
  }) async {
    // ─── Build payload ───────────────────────────────────────
    final payload = {
      "userId": userId,
      "location": {
        "type": "Point",
        "coordinates": [longitude, latitude], // [lng, lat]
      },
      "userDetails": userDetails,
      "emergencyContacts": emergencyContacts,
    };

    // Log the outgoing payload as pretty JSON
    dev.log(
      '🚀 [AlertService] Sending hospital alert payload =>\n${const JsonEncoder.withIndent('  ').convert(payload)}',
      name: 'AlertService',
    );

    try {
      final response = await _dio.post('/hospital-alert/send', data: payload);

      dev.log('✅ [AlertService] Response status: ${response.statusCode}',
          name: 'AlertService');
      dev.log('✅ [AlertService] Response body: ${jsonEncode(response.data)}',
          name: 'AlertService');

      return response.statusCode == 201 && response.data['success'] == true;
    } on DioException catch (e) {
      // Log rich error info
      dev.log('❌ [AlertService] Dio error: ${e.message}',
          name: 'AlertService', error: e);
      if (e.response != null) {
        dev.log('❌ [AlertService] Backend response: ${e.response!.data}',
            name: 'AlertService');
      }
      return false;
    } catch (e, s) {
      dev.log('❌ [AlertService] Unexpected error: $e',
          name: 'AlertService', stackTrace: s);
      return false;
    }
  }
}
