import 'package:detector_de_madera/models/data.dart';
import 'package:hive/hive.dart';

import 'package:hive/hive.dart';

class DetectedDiseaseAdapter extends TypeAdapter<DetectedDisease> {
  @override
  final typeId = 0;

  @override
  DetectedDisease read(BinaryReader reader) {
    return DetectedDisease(
      imagePath: reader.readString(),
      diseaseName: reader.readString(),
      diseasePrecautions: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, DetectedDisease obj) {
    writer.writeString(obj.imagePath);
    writer.writeString(obj.diseaseName);
    writer.writeString(obj.diseasePrecautions);
  }
}
