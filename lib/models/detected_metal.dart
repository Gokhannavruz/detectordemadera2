import 'package:detector_de_madera/screens/gold_detector.dart';

class DetectedMetal {
  final double magneticIntensity;
  final DateTime detectionTime;
  final bool isPremiumDetection;
  final MetalSize metalSize; // Added this line

  DetectedMetal({
    required this.magneticIntensity,
    required this.detectionTime,
    this.isPremiumDetection = false,
    this.metalSize = MetalSize.none, // Added a default value
  });

  Map toJson() => {
        'magneticIntensity': magneticIntensity,
        'detectionTime': detectionTime.toIso8601String(),
        'isPremiumDetection': isPremiumDetection,
        'metalSize': metalSize.index, // Store the enum index
      };

  factory DetectedMetal.fromJson(Map json) => DetectedMetal(
        magneticIntensity: json['magneticIntensity'],
        detectionTime: DateTime.parse(json['detectionTime']),
        isPremiumDetection: json['isPremiumDetection'] ?? false,
        metalSize: MetalSize
            .values[json['metalSize'] ?? 0], // Retrieve enum from index
      );
}
