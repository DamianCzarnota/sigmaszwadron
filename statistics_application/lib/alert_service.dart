import 'package:firebase_database/firebase_database.dart';


class Alert {
  final String id;
  final String message;
  final String timestamp;
  final bool isRead;
  final String acknowledgeDate;

  Alert({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.isRead,
    required this.acknowledgeDate,
  });

  factory Alert.fromMap(String id, Map<dynamic, dynamic> data) {
    return Alert(
      id: id,
      message: data['error'] ?? 'No error',
      timestamp: data['timestamp'] ?? '',
      isRead: data['isRead'] ?? false,
      acknowledgeDate: data['acknowledgeDate'] ?? '',
    );
  }
}

class AlertsDownloader {
  final DatabaseReference _alertsRef = FirebaseDatabase.instance.ref('alerts');

  Future<List<Alert>> fetchAlerts(bool _showReadAlerts) async {
    try {
      final snapshot = await _alertsRef.get();

      if (!snapshot.exists || snapshot.value == null) {
        print('No alerts found.');
        return [];
      }

      final data = snapshot.value as Map<dynamic, dynamic>;


      return data.entries
          .where((entry) =>
              _showReadAlerts ||
              !(entry.value['isRead'] ?? false))
          .map((entry) => Alert.fromMap(entry.key, Map.from(entry.value)))
          .toList();
    } catch (e) {
      print('Error fetching alerts: $e');
      return [];
    }
  }
}