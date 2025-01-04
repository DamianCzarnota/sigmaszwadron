import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:googleapis/storage/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:fl_chart/fl_chart.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:developer';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        cardTheme: CardTheme(
          elevation: 4,
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        ),
      ),
      home: MetricsPage(),
    );
  }
}

class MetricsPage extends StatefulWidget {
  @override
  _MetricsPageState createState() => _MetricsPageState();
}

class _MetricsPageState extends State<MetricsPage> {
  final String _bucketName = "sigmaszwadron.firebasestorage.app";
  final String _serviceAccountKeyPath = "assets/service_account_key.json";

  Map<String, dynamic> _metrics = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStorageMetrics();
  }

  Future<void> _fetchStorageMetrics() async {
    setState(() {
      _loading = true;
    });

    try {
      final credentials = ServiceAccountCredentials.fromJson(
        json.decode(await DefaultAssetBundle.of(context).loadString(_serviceAccountKeyPath)),
      );

      final client = await clientViaServiceAccount(
        credentials,
        [StorageApi.devstorageReadOnlyScope],
      );

      final storageApi = StorageApi(client);
      final objects = await storageApi.objects.list(_bucketName);

      if (objects.items == null || objects.items!.isEmpty) {
        setState(() {
          _metrics = {"Error": "No objects found in the bucket."};
          _loading = false;
        });
        return;
      }

      // Metrics calculation
      int totalFiles = objects.items!.length;
      double totalSize = 0;
      double largestSize = 0;
      double smallestSize = double.maxFinite;
      Map<String, int> sizeDistribution = {
        "0–1 MB": 0,
        "1–10 MB": 0,
        "10–100 MB": 0,
        ">100 MB": 0,
      };

      for (var obj in objects.items!) {
        double size = double.tryParse(obj.size ?? "0") ?? 0;
        totalSize += size;
        largestSize = size > largestSize ? size : largestSize;
        smallestSize = size < smallestSize ? size : smallestSize;
        if (size <= 1 * 1024 * 1024) {
          sizeDistribution["0–1 MB"] = sizeDistribution["0–1 MB"]! + 1;
        } else if (size <= 10 * 1024 * 1024) {
          sizeDistribution["1–10 MB"] = sizeDistribution["1–10 MB"]! + 1;
        } else if (size <= 100 * 1024 * 1024) {
          sizeDistribution["10–100 MB"] = sizeDistribution["10–100 MB"]! + 1;
        } else {
          sizeDistribution[">100 MB"] = sizeDistribution[">100 MB"]! + 1;
        }
      }

      setState(() {
        _metrics = {
          "Total Files": totalFiles,
          "Total Size (MB)": (totalSize / (1024 * 1024)).toStringAsFixed(2),
          "Largest File (MB)": (largestSize / (1024 * 1024)).toStringAsFixed(2),
          "Smallest File (MB)": (smallestSize / (1024 * 1024)).toStringAsFixed(2),
          "File Size Distribution": sizeDistribution,
        };
        _loading = false;
      });

      client.close();
    } catch (e) {
      setState(() {
        _metrics = {"Error": e.toString()};
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bucket Metrics"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchStorageMetrics,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _metrics.containsKey("Error")
              ? Center(child: Text(_metrics["Error"]))
              : ListView(
                  children: [
                    _buildMetricCard("Total Files", _metrics["Total Files"].toString(), Icons.folder),
                    _buildMetricCard("Total Size (MB)", _metrics["Total Size (MB)"], Icons.storage),
                    _buildMetricCard("Largest File (MB)", _metrics["Largest File (MB)"], Icons.file_present),
                    _buildMetricCard("Smallest File (MB)", _metrics["Smallest File (MB)"], Icons.file_copy),
                    _buildChartCard("File Size Distribution", _metrics["File Size Distribution"]),
                  ],
                ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon, size: 40, color: Colors.blue),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value, style: TextStyle(fontSize: 18)),
      ),
    );
  }

  Widget _buildChartCard(String title, Map<String, int> distribution) {
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
                  final percentage = entry.value / _metrics["Total Files"];
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
