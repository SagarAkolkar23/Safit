import 'package:flutter/material.dart';
import 'package:safit/Constant.dart';
import '../helper/alertHelper.dart';
import '../services/hospitalAlert.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late AlertHelper alertHelper;

  @override
  void initState() {
    super.initState();
    final alertService = AlertService(baseUrl: baseUrlMain);
    alertHelper = AlertHelper(alertService: alertService);
  }

  void _sendAlert(BuildContext context, String target) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🚨 SOS sent to $target'),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  Future<void> _sendHospitalAlert() async {
    final success = await alertHelper.sendAlertFromStorageAndLocation();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '🚨 Emergency alert sent to Hospitals!'
            : 'Failed to send emergency alert.'),
        backgroundColor: success ? Colors.green : Colors.red.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final red = Colors.red.shade700;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Emergency Dashboard'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.3),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.redAccent, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    EmergencyCard(
                      icon: Icons.local_hospital,
                      title: 'ALERT HOSPITALS',
                      subtitle: 'Send help request to nearby hospitals',
                      onPressed: _sendHospitalAlert,
                      color: Colors.pinkAccent,
                    ),
                    const SizedBox(height: 24),
                    EmergencyCard(
                      icon: Icons.local_police,
                      title: 'ALERT POLICE',
                      subtitle: 'Notify local police stations immediately',
                      onPressed: () => _sendAlert(context, 'Police Stations'),
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(height: 24),
                    EmergencyCard(
                      icon: Icons.local_fire_department,
                      title: 'ALERT FIRE FIGHTERS',
                      subtitle: 'Call fire department urgently',
                      onPressed: () => _sendAlert(context, 'Fire Fighters'),
                      color: Colors.deepOrangeAccent,
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

class EmergencyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final Color color;

  const EmergencyCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 12),
            Text(title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                )),
            const SizedBox(height: 4),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.sos, size: 24),
              label: const Text('SEND SOS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}
