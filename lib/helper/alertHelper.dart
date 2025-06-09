import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/hospitalAlert.dart';

class AlertHelper {
  final AlertService alertService;

  AlertHelper({required this.alertService});

  Future<bool> sendAlertFromStorageAndLocation() async {
    try {
      // 1. Get user data from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString('user');
      if (userString == null || userString.isEmpty) {
        print('No user data found in local storage');
        return false;
      }
      final userData = jsonDecode(userString);

      final userId = userData['_id'];
      final userDetails = {
        "name": userData['name'] ?? '',
        "email": userData['email'] ?? '',
        "bloodGroup": userData['bloodGroup'] ?? '',
        "number": userData['number'] ?? '',
        "address": userData['address'] ?? '',
      };

      final List emergencyContactsRaw = userData['emergencyContacts'] ?? [];
      final emergencyContacts = emergencyContactsRaw
          .map<Map<String, dynamic>>((c) => {
        "name": c['name'] ?? '',
        "number": c['number'] ?? '',
        "relation": c['relation'] ?? '',
      })
          .toList();

      // 2. Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services are disabled.');
        return false;
      }

      // 3. Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permissions are permanently denied');
        return false;
      }

      // 4. Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 5. Send hospital alert with gathered data
      return await alertService.sendHospitalAlert(
        userId: userId,
        latitude: position.latitude,
        longitude: position.longitude,
        userDetails: userDetails,
        emergencyContacts: emergencyContacts,
      );
    } catch (e) {
      print('Error in sendAlertFromStorageAndLocation: $e');
      return false;
    }
  }
}