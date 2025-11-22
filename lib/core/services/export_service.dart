import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '/features/mood_detection/data/models/mood_session.dart';

class ExportService {
  /// Export mood data as JSON
  static Future<File> exportAsJSON(List<MoodSession> sessions) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
        '${directory.path}/mood_data_${DateTime.now().millisecondsSinceEpoch}.json');

    final jsonData = {
      'export_date': DateTime.now().toIso8601String(),
      'total_sessions': sessions.length,
      'sessions': sessions.map((session) => session.toJson()).toList(),
    };

    await file.writeAsString(jsonEncode(jsonData));
    return file;
  }

  /// Export mood data as CSV
  static Future<File> exportAsCSV(List<MoodSession> sessions) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
        '${directory.path}/mood_data_${DateTime.now().millisecondsSinceEpoch}.csv');

    final csvContent = StringBuffer();

    // Headers
    csvContent.writeln('Date,Time,Emotion,Confidence,Analysis Type');

    // Data rows
    for (final session in sessions) {
      final date = session.timestamp.toLocal();
      csvContent.writeln(
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')},'
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')},'
          '${session.dominantEmotion},'
          '${(session.confidence * 100).toStringAsFixed(1)}%,'
          '${session.analysisType}');
    }

    await file.writeAsString(csvContent.toString());
    return file;
  }

  /// Export mood statistics summary
  static Future<File> exportStatsSummary(
    List<MoodSession> sessions,
    Map<String, int> statistics,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
        '${directory.path}/mood_summary_${DateTime.now().millisecondsSinceEpoch}.txt');

    final content = StringBuffer();
    content.writeln('=== MOOD ANALYSIS SUMMARY ===');
    content.writeln('Generated: ${DateTime.now().toLocal()}');
    content.writeln('Total Sessions: ${sessions.length}');
    content.writeln('');

    // Time range
    if (sessions.isNotEmpty) {
      sessions.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      content.writeln(
          'Date Range: ${sessions.first.timestamp.toLocal().toString().split(' ')[0]} to ${sessions.last.timestamp.toLocal().toString().split(' ')[0]}');
      content.writeln('');
    }

    // Emotion breakdown
    content.writeln('=== EMOTION BREAKDOWN ===');
    final sortedStats = statistics.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedStats) {
      final percentage = sessions.isNotEmpty
          ? ((entry.value / sessions.length) * 100).toStringAsFixed(1)
          : '0.0';
      content.writeln('${entry.key}: ${entry.value} sessions (${percentage}%)');
    }

    content.writeln('');
    content.writeln('=== ANALYSIS TYPES ===');
    final analysisTypes = <String, int>{};
    for (final session in sessions) {
      analysisTypes[session.analysisType] =
          (analysisTypes[session.analysisType] ?? 0) + 1;
    }

    for (final entry in analysisTypes.entries) {
      content.writeln('${entry.key}: ${entry.value} sessions');
    }

    await file.writeAsString(content.toString());
    return file;
  }

  /// Share exported file
  static Future<void> shareFile(File file, String title) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: title,
    );
  }

  /// Get export file size
  static Future<String> getFileSize(File file) async {
    final bytes = await file.length();
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Clean up old export files
  static Future<void> cleanupOldExports({int keepDays = 7}) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cutoffDate = DateTime.now().subtract(Duration(days: keepDays));

      await for (final entity in directory.list()) {
        if (entity is File) {
          final fileName = entity.path.split('/').last;
          if (fileName.startsWith('mood_') &&
              (fileName.endsWith('.json') ||
                  fileName.endsWith('.csv') ||
                  fileName.endsWith('.txt'))) {
            final stat = await entity.stat();
            if (stat.modified.isBefore(cutoffDate)) {
              await entity.delete();
            }
          }
        }
      }
    } catch (e) {
      print('Error cleaning up exports: $e');
    }
  }

  /// Validate export data
  static bool validateExportData(List<MoodSession> sessions) {
    if (sessions.isEmpty) return false;

    for (final session in sessions) {
      if (session.dominantEmotion.isEmpty ||
          session.confidence < 0 ||
          session.confidence > 1) {
        return false;
      }
    }

    return true;
  }
}
