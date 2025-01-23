import 'package:firebase_database/firebase_database.dart';


class Alert {
  final String id;
  final String message;
  final String timestamp;
  final bool isRead;

  Alert({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.isRead,
  });

  factory Alert.fromMap(String id, Map<dynamic, dynamic> data) {
    return Alert(
      id: id,
      message: data['error'] ?? 'No error',
      timestamp: data['timestamp'] ?? '',
      isRead: data['isRead'] ?? false,
    );
  }
}

class AlertsDownloader {
  final DatabaseReference _alertsRef = FirebaseDatabase.instance.ref('alerts');

  Future<List<Alert>> fetchAlerts() async {
    try {
      final snapshot = await _alertsRef.get();

      if (!snapshot.exists || snapshot.value == null) {
        print('No alerts found.');
        return [];
      }

      final data = snapshot.value as Map<dynamic, dynamic>;


      return data.entries
          .where((entry) => entry.value['isRead'] != true)
          .map((entry) => Alert.fromMap(entry.key, Map.from(entry.value)))
          .toList();
    } catch (e) {
      print('Error fetching alerts: $e');
      return [];
    }
  }
}