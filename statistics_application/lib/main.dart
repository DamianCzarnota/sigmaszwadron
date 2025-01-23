import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:googleapis/storage/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:fl_chart/fl_chart.dart';
import 'firebase_options.dart';
import 'gcp_service.dart';
import 'alert_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'firebase_options.dart'; 
import 'package:intl/intl.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MetricsHome(),
    );
  }
}

class AlertsScreen extends StatefulWidget {
  @override
  _AlertsScreenState createState() => _AlertsScreenState();
}

class MetricsHome extends StatefulWidget {
  @override
  _MetricsHomeState createState() => _MetricsHomeState();
}

class _MetricsHomeState extends State<MetricsHome> {
  int _selectedIndex = 0;
  bool _loadAlerts = false;
  bool _hasUnreadAlerts = false;

  // Handle tab selection
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Screens for each tab
  final List<Widget> _tabs = [
    StorageMetricsScreen(),
    AlertsScreen()
  ];

  void _checkForUnreadAlerts() async {
    final alerts = await AlertsDownloader().fetchAlerts(false);
    setState(() {
      _hasUnreadAlerts = alerts.isNotEmpty;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkForUnreadAlerts(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.storage),
            label: "Storage Metrics",
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(Icons.notifications),
                if (_hasUnreadAlerts) // Show red dot if there are unread alerts
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            label: 'Alerts',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped, // Call _checkForUnreadAlerts when switching to Alerts tab
      ),
    );
  }
}

class StorageMetricsScreen extends StatefulWidget {
  @override
  _StorageMetricsScreenState createState() => _StorageMetricsScreenState();
}



class _AlertsScreenState extends State<AlertsScreen> {
  final AlertsDownloader _alertsDownloader = AlertsDownloader();
  late Future<List<Alert>> _alertsFuture;
  bool _showReadAlerts = false;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  void _loadAlerts() {
    setState(() {
      _alertsFuture = _alertsDownloader.fetchAlerts(_showReadAlerts);
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Alerts'),
        actions: [
          Switch(
            value: _showReadAlerts,
            onChanged: (value) {
              setState(() {
                _showReadAlerts = value;
                _loadAlerts();
              });
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text("Show Read Alerts"),
          ),
        ],
      ),
      body: FutureBuilder<List<Alert>>(
        future: _alertsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading alerts.'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No alerts found.'));
          }

          // Filter alerts based on user preference
          final filteredAlerts = snapshot.data!
              .where((alert) => _showReadAlerts || !alert.isRead)
              .toList();

          return ListView.builder(
            itemCount: filteredAlerts.length,
            itemBuilder: (context, index) {
              final alert = filteredAlerts[index];

              return ListTile(
                title: Text(alert.message),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            
                    Text(
                      'Timestamp: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(alert.timestamp))}',
                      style: TextStyle(fontSize: 12),
                    ),
           
                    if (alert.isRead && alert.acknowledgeDate != null)
                      Text(
                        'Acknowledge Date: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.parse(alert.acknowledgeDate!))}',
                        style: TextStyle(fontSize: 12, color: Colors.green),
                      ),
                  ],
                ),
                trailing: alert.isRead
                    ? const Icon(Icons.check, color: Colors.green)
                    : IconButton(
                        icon: const Icon(Icons.mark_email_read),
                        onPressed: () async {
                          try {
                            await FirebaseDatabase.instance
                                .ref('alerts/${alert.id}')
                                .update({'isRead': true});
                            await FirebaseDatabase.instance
                                .ref('alerts/${alert.id}')
                                .update({
                                  'isRead': true,
                                  'acknowledgeDate': DateTime.now().toIso8601String(),
                                });
                            _loadAlerts();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error marking alert as read'),
                              ),
                            );
                          }
                        },
                      ),
              );
            },
          );
        },
      ),
    );
  }
}





class _StorageMetricsScreenState extends State<StorageMetricsScreen> {
  late Future<Map<String, dynamic>> _bucketMetrics;

  @override
  void initState() {
    super.initState();
    _bucketMetrics = _fetchMetrics();
  }

  Future<Map<String, dynamic>> _fetchMetrics() async {
    const bucketName = "sigmaszwadron.firebasestorage.app";
    const serviceAccountKeyPath = "service_account_key.json";

    final gcpService = GCPService(
      bucketName: bucketName,
      serviceAccountKeyPath: serviceAccountKeyPath,
    );

    return gcpService.fetchBucketMetrics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Storage Metrics"),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _bucketMetrics,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }
          final metrics = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildMetricCard(
                "Total Files",
                metrics['Total Files'].toString() ?? "N/A",
                Icons.storage,
                Colors.blue,
              ),
              _buildMetricCard(
                "Total Size",
                metrics['Total Size (MB)'].toString() + " MB" ?? "N/A",
                Icons.location_on,
                Colors.green,
              ),
              _buildMetricCard(
                "Largest File",
                metrics['Largest File (MB)'].toString() + " MB" ?? "N/A",
                Icons.class_,
                Colors.orange,
              ),
              _buildMetricCard(
                "Smallest File",
                metrics['Smallest File (MB)'].toString() + " MB" ?? "N/A",
                Icons.insert_drive_file,
                Colors.purple,
              ),
              _buildChartCard(
                "File Size Distribution",
                metrics['File Size Distribution'],
                 metrics['Total Files'],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 40, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
  Widget _buildChartCard(String title, Map<String, int> distribution, int numberOfFiles) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.pie_chart, size: 40, color: Colors.green),
            title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sections: distribution.entries.map((entry) {
                  final percentage = entry.value / numberOfFiles;
                  return PieChartSectionData(
                    value: percentage * 100,
                    title: "${entry.key}\n${(percentage * 100).toStringAsFixed(1)}%",
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StorageChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: 40,
            color: Colors.blue,
            title: "Images",
            radius: 50,
          ),
          PieChartSectionData(
            value: 30,
            color: Colors.green,
            title: "Videos",
            radius: 50,
          ),
          PieChartSectionData(
            value: 20,
            color: Colors.orange,
            title: "Documents",
            radius: 50,
          ),
          PieChartSectionData(
            value: 10,
            color: Colors.red,
            title: "Others",
            radius: 50,
          ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }
}
