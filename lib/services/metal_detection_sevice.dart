import 'dart:convert';
import 'package:detector_de_madera/models/detected_metal.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MetalDetectionService {
  static const String _metalDetectionsKey = 'detected_metals';
  static const String _freeDetectionsKey = 'free_detections';
  static const String _lastResetDateKey = 'last_reset_date';
  static const int _maxFreeDetections = 5; // Free daily detections

  Future<List<DetectedMetal>> getDetectedMetals() async {
    final prefs = await SharedPreferences.getInstance();
    final metalsList = prefs.getStringList(_metalDetectionsKey) ?? [];
    return metalsList
        .map((metalJson) => DetectedMetal.fromJson(json.decode(metalJson)))
        .toList();
  }

  Future<void> saveDetectedMetal(DetectedMetal metal) async {
    final prefs = await SharedPreferences.getInstance();

    // Get current list of detections
    final metalsList = prefs.getStringList(_metalDetectionsKey) ?? [];

    // Add new metal to the list
    metalsList.add(json.encode(metal.toJson()));

    // Save updated list
    await prefs.setStringList(_metalDetectionsKey, metalsList);
  }

  Future<bool> canDetectForFree() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if we need to reset free detections
    final lastResetDateString = prefs.getString(_lastResetDateKey);
    final now = DateTime.now();

    if (lastResetDateString == null ||
        !_isSameDay(DateTime.parse(lastResetDateString), now)) {
      // Reset free detections if it's a new day
      await prefs.setInt(_freeDetectionsKey, 0);
      await prefs.setString(_lastResetDateKey, now.toIso8601String());
    }

    // Get current free detections
    int freeDetections = prefs.getInt(_freeDetectionsKey) ?? 0;

    return freeDetections < _maxFreeDetections;
  }

  Future<void> incrementFreeDetections() async {
    final prefs = await SharedPreferences.getInstance();

    int freeDetections = prefs.getInt(_freeDetectionsKey) ?? 0;
    await prefs.setInt(_freeDetectionsKey, freeDetections + 1);
  }

  Future<void> clearDetectedMetals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_metalDetectionsKey);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
