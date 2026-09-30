import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class UpdateService {
  final Dio _dio = Dio();
  final String _githubRepo = 'mryogeshkumargit/JyotishCosmic';

  /// Compares dotted versions ("v1.2.10" > "1.2.9"). Build suffixes (+n) are ignored.
  static bool isNewer(String candidate, String current) {
    List<int> parse(String v) => v
        .replaceFirst(RegExp(r'^[vV]'), '')
        .split('+')
        .first
        .split('-')
        .first
        .split('.')
        .map((p) => int.tryParse(p) ?? 0)
        .toList();
    final a = parse(candidate), b = parse(current);
    for (int i = 0; i < 3; i++) {
      final x = i < a.length ? a[i] : 0, y = i < b.length ? b[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }

  /// Checks GitHub for a release newer than [currentVersion].
  /// Returns a Map with 'tag' and 'url' if one is available, or null if not.
  Future<Map<String, String>?> checkUpdate(String currentVersion) async {
    try {
      final url = 'https://api.github.com/repos/$_githubRepo/releases/latest';
      _dio.options.connectTimeout = const Duration(seconds: 10);
      
      final response = await _dio.get(url);
      
      if (response.statusCode == 200) {
        final data = response.data;
        final tagName = data['tag_name'] as String;
        if (!isNewer(tagName, currentVersion)) return null;
        final assets = data['assets'] as List<dynamic>;
        
        for (var asset in assets) {
          final name = asset['name'] as String;
          if (name.endsWith('.apk')) {
            return {
              'tag': tagName,
              'url': asset['browser_download_url'] as String,
            };
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('GitHub update check error: $e');
      return null;
    }
  }

  /// Downloads the APK from the provided URL and installs it.
  Future<bool> downloadAndInstallUpdate(
    String downloadUrl, 
    Function(int received, int total) onProgress
  ) async {
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/update.apk';
      
      // Delete old file if exists
      final file = File(savePath);
      if (await file.exists()) {
        await file.delete();
      }

      // Download file
      _dio.options.connectTimeout = const Duration(seconds: 15);
      _dio.options.receiveTimeout = const Duration(minutes: 5);
      
      await _dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: onProgress,
      );

      // Trigger installation
      final result = await OpenFile.open(savePath);
      return result.type == ResultType.done;
    } catch (e) {
      debugPrint('Update error: $e');
      return false;
    }
  }
}
