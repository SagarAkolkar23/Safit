import 'package:flutter/services.dart';
import 'package:safit/helper/alertHelper.dart';
import 'package:safit/services/hospitalAlert.dart';   // ⬅️ one canonical path
import 'package:safit/Constant.dart';                 // keep casing consistent

// Singleton AlertHelper that uses the same AlertService type
final _alertHelper =
AlertHelper(alertService: AlertService(baseUrl: baseUrlMain));

Future<void> triggerDistress() async {
  print('🔔 triggerDistress called'); // Debug log
  final ok = await _alertHelper.sendAlertFromStorageAndLocation();
  if (ok) {
    print('✅ Distress signal sent successfully');
  } else {
    print('❌ Distress send FAILED');
  }
}

void registerDistressChannel() {
  const MethodChannel channel = MethodChannel('distress_channel');
  channel.setMethodCallHandler((call) async {
    print('📲 MethodChannel received call: ${call.method}'); // Debug log
    if (call.method == 'triggerDistress') {
      await triggerDistress();
    } else {
      print('⚠️ Method not implemented: ${call.method}');
    }
  });
  print('🔌 Distress channel registered');
}