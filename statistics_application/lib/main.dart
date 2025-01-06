import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:googleapis/storage/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:fl_chart/fl_chart.dart';
import 'firebase_options.dart';
import 'gcp_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
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

class MetricsHome extends StatefulWidget {
  @override
  _MetricsHomeState createState() => _MetricsHomeState();
}

class _MetricsHomeState extends State<MetricsHome> {
  int _selectedIndex = 0;

  // Handle tab selection
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Screens for each tab
  final List<Widget> _tabs = [
    StorageMetricsScreen(),
    //PerformanceMetricsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.storage),
            label: "Storage Metrics",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.speed),
            label: "Performance Metrics",
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class StorageMetricsScreen extends StatefulWidget {
  @override
  _StorageMetricsScreenState createState() => _StorageMetricsScreenState();
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
          print(metrics);
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

// class PerformanceMetricsScreen extends StatefulWidget {
//   @override
//   _PerformanceMetricsScreenState createState() =>
//       _PerformanceMetricsScreenState();
// }

// class _PerformanceMetricsScreenState extends State<PerformanceMetricsScreen> {
//   late Future<Map<String, dynamic>> _performanceMetrics;

//    void initState() {
//     super.initState();
//     _performanceMetrics = _fetchMetrics();
//     print(_performanceMetrics);
//   }

//   Future<Map<String, dynamic>> _fetchMetrics() async {
//     const bucketName = "sigmaszwadron.firebasestorage.app";
//     const serviceAccountKeyPath = "service_account_key.json";

//     final gcpService = GCPService(
//       bucketName: bucketName,
//       serviceAccountKeyPath: serviceAccountKeyPath,
//     );

//     return gcpService.fetchPerformanceMetrics();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Performance Metrics"),
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16.0),
//         children: [
//           _buildMetricCard(
//             "API Latency",
//             "ms",
//             Icons.timer,
//             Colors.orange,
//           ),
//           _buildMetricCard(
//             "Requests Per Second",
//             "mss",
//             Icons.network_check,
//             Colors.blue,
//           ),
//           _buildMetricCard(
//             "Error Rate",
//             "ms",
//             Icons.error_outline,
//             Colors.red,
//           ),
//           SizedBox(height: 20),
//           Text(
//             "Performance Over Time",
//             style: Theme.of(context).textTheme.headlineSmall,
//           ),
//           SizedBox(height: 200, child: PerformanceChart()),
//         ],
//       ),
//     );
//   }

//   Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
//     return Card(
//       child: ListTile(
//         leading: Icon(icon, size: 40, color: color),
//         title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//         subtitle: Text(value, style: const TextStyle(fontSize: 18)),
//       ),
//     );
//   }
// }

// class PerformanceChart extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return LineChart(
//       LineChartData(
//         lineBarsData: [
//           LineChartBarData(
//             isCurved: true,
//             spots: [
//               FlSpot(0, 200),
//               FlSpot(1, 180),
//               FlSpot(2, 220),
//               FlSpot(3, 160),
//               FlSpot(4, 200),
//             ],
//             barWidth: 4,
//             belowBarData: BarAreaData(show: false),
//           ),
//         ],
//         titlesData: FlTitlesData(
//           leftTitles: AxisTitles(
//             sideTitles: SideTitles(
//               showTitles: true,
//               interval: 50,
//               getTitlesWidget: (value, meta) {
//                 return Text(
//                   value.toString(),
//                   style: const TextStyle(fontSize: 10),
//                 );
//               },
//             ),
//           ),
//           bottomTitles: AxisTitles(
//             sideTitles: SideTitles(
//               showTitles: true,
//               interval: 1,
//               getTitlesWidget: (value, meta) {
//                 return Text(
//                   'Day ${value.toInt()}',
//                   style: const TextStyle(fontSize: 10),
//                 );
//               },
//             ),
//           ),
//         ),
//         gridData: FlGridData(show: true),
//       ),
//     );
//   }
// }