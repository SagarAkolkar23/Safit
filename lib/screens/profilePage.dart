import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  Future<void> _loadUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    debugPrint('User string from prefs: $userString');

    if (userString != null && userString.isNotEmpty) {
      try {
        final decoded = jsonDecode(userString);
        setState(() {
          userData = decoded;
        });
      } catch (e) {
        debugPrint('Error decoding user JSON: $e');
        _redirectToLogin();
      }
    } else {
      debugPrint('No user data found, redirecting to login.');
      _redirectToLogin();
    }
  }

  void _redirectToLogin() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(fontSize: 18, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContacts(List<dynamic>? contacts) {
    if (contacts == null || contacts.isEmpty) {
      return const Text('No emergency contacts available.',
          style: TextStyle(fontSize: 16, color: Colors.black54));
    }

    return Column(
      children: contacts.map((contact) {
        final name = contact['name'] ?? 'N/A';
        final number = contact['number'] ?? 'N/A';
        final relation = contact['relation'] ?? 'N/A';

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.contact_phone, color: Colors.red),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Relation: $relation\nPhone: $number'),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final red = Colors.red.shade700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: red,
      ),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: red,
              child: Text(
                (userData!['name'] != null && userData!['name'].isNotEmpty)
                    ? userData!['name'][0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  fontSize: 48,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // User Basic Info
            _buildInfoRow('Name', userData!['name']),
            _buildInfoRow('Email', userData!['email']),
            _buildInfoRow('User ID', userData!['_id']),
            _buildInfoRow('Phone Number', userData!['number']),
            _buildInfoRow('Blood Group', userData!['bloodGroup']),
            _buildInfoRow('Address', userData!['address']),
            const SizedBox(height: 24),

            // Emergency Contacts Section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Emergency Contacts',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: red),
              ),
            ),
            const SizedBox(height: 12),
            _buildEmergencyContacts(userData!['emergencyContacts']),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 20),
                ),
                onPressed: _logout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
