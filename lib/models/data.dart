import 'dart:convert';

class DetectedDisease {
  final String imagePath;
  final String diseaseName;
  final String diseasePrecautions;

  DetectedDisease({
    required this.imagePath,
    required this.diseaseName,
    required this.diseasePrecautions,
  });

  Map<String, dynamic> toMap() {
    return {
      'imagePath': imagePath,
      'diseaseName': diseaseName,
      'diseasePrecautions': diseasePrecautions,
    };
  }

  factory DetectedDisease.fromMap(Map<String, dynamic> map) {
    return DetectedDisease(
      imagePath: map['imagePath'],
      diseaseName: map['diseaseName'],
      diseasePrecautions: map['diseasePrecautions'],
    );
  }

  String toJson() => json.encode(toMap());

  factory DetectedDisease.fromJson(String source) =>
      DetectedDisease.fromMap(json.decode(source));
}
