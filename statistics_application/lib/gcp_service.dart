import 'dart:convert';
import 'dart:io';
import 'package:googleapis/storage/v1.dart';
import 'package:googleapis/monitoring/v3.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter/services.dart' show rootBundle;


class GCPService {
  final String bucketName;
  final String serviceAccountKeyPath;

  GCPService({
    required this.bucketName,
    required this.serviceAccountKeyPath,
  });

  Future<String> loadServiceAccountKey(String assetPath) async {
    return await rootBundle.loadString(assetPath);
  }
  Future<Map<String, dynamic>> fetchBucketMetrics() async {
    try {
      // Authenticate using the service account
    

      final client = await clientViaServiceAccount(
        ServiceAccountCredentials.fromJson( await loadServiceAccountKey(serviceAccountKeyPath)),
        [StorageApi.devstorageReadOnlyScope],
      );

      final storageApi = StorageApi(client);
      final objects = await storageApi.objects.list(bucketName);


      if (objects.items == null || objects.items!.isEmpty) {
        return {
          "name": "Unknown",
          "location": "Unknown",
          "storageClass": "Unknown",
          "totalObjects": 0,
          "size": "Unknown",
        };
      }

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

      final metrics = {
        "Total Files": totalFiles,
        "Total Size (MB)": (totalSize / (1024 * 1024)).toStringAsFixed(2),
        "Largest File (MB)": (largestSize / (1024 * 1024)).toStringAsFixed(2),
        "Smallest File (MB)": (smallestSize / (1024 * 1024)).toStringAsFixed(2),
        "File Size Distribution": sizeDistribution,
      };

      return metrics;
    } catch (e) {
      print("Error fetching bucket metrics: $e");

      // Return default fallback in case of error
      return {
        "Total Files": 0,
        "Total Size (MB)": "0.00",
        "Largest File (MB)": "0.00",
        "Smallest File (MB)": "0.00",
        "File Size Distribution": {
          "0–1 MB": 0,
          "1–10 MB": 0,
          "10–100 MB": 0,
          ">100 MB": 0,
        },
      };
    }
  }

  // Future<Map<String, dynamic>> fetchPerformanceMetrics() async {
  //   try {
  //     // Load service account credentials
  //     final serviceAccountKey = loadServiceAccountKey(serviceAccountKeyPath);
  //     final client = await clientViaServiceAccount(
  //       ServiceAccountCredentials.fromJson(serviceAccountKey),
  //       [MonitoringApi.cloudPlatformScope],
  //     );

  //     final monitoringApi = MonitoringApi(client);
  //     final projectId = 'sigmaszwadron';
  //     // Define time range for metrics (last 24 hours)
  //     final now = DateTime.now().toUtc();
  //     final startTime = now.subtract(Duration(hours: 24)).toIso8601String();
  //     final endTime = now.toIso8601String();

  //     // Fetch read operations
  //     final readOps = await _fetchMetric(
  //       monitoringApi,
  //       projectId,
  //       'storage.googleapis.com/storage/object/read_requests_count',
  //       startTime,
  //       endTime,
  //     );

  //     // Fetch write operations
  //     final writeOps = await _fetchMetric(
  //       monitoringApi,
  //       projectId,
  //       'storage.googleapis.com/storage/object/write_requests_count',
  //       startTime,
  //       endTime,
  //     );

  //     // Fetch latency
  //     final latency = await _fetchMetric(
  //       monitoringApi,
  //       projectId,
  //       'storage.googleapis.com/storage/object/latency',
  //       startTime,
  //       endTime,
  //     );

  //     // Fetch bandwidth usage
  //     final bandwidth = await _fetchMetric(
  //       monitoringApi,
  //       projectId,
  //       'storage.googleapis.com/storage/network/received_bytes_count',
  //       startTime,
  //       endTime,
  //     );

  //     // Return metrics
  //     return {
  //       "Read Operations": readOps,
  //       "Write Operations": writeOps,
  //       "Latency (ms)": latency,
  //       "Bandwidth (MB)": (bandwidth / (1024 * 1024)).toStringAsFixed(2),
  //     };
  //   } catch (e) {
  //     print("Error fetching performance metrics: $e");
  //     return {
  //       "Read Operations": "Unknown",
  //       "Write Operations": "Unknown",
  //       "Latency (ms)": "Unknown",
  //       "Bandwidth (MB)": "Unknown",
  //     };
  //   }
  // }

  // Future<double> _fetchMetric(
  //   MonitoringApi api,
  //   String projectId,
  //   String metricType,
  //   String startTime,
  //   String endTime,
  // ) async {
  //   final request = ListTimeSeriesRequest(
  //     filter: 'metric.type = "$metricType"',
  //     interval: TimeInterval(
  //       startTime: startTime,
  //       endTime: endTime,
  //     ),
  //     view: 'FULL',
  //   );

  //   final response = await api.projects.timeSeries.list(
  //     'projects/$projectId',
  //     request.filter!,
  //     intervalStartTime: request.interval!.startTime!,
  //     intervalEndTime: request.interval!.endTime!,
  //     view: request.view!,
  //   );

  //   if (response.timeSeries == null || response.timeSeries!.isEmpty) {
  //     return 0.0;
  //   }

  //   // Aggregate metric values
  //   double total = 0.0;
  //   for (var series in response.timeSeries!) {
  //     for (var point in series.points!) {
  //       total += point.value!.doubleValue ?? 0.0;
  //     }
  //   }

  //   return total;
  // }

}
