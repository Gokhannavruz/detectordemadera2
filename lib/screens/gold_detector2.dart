import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';

class GoldDetector extends StatefulWidget {
  const GoldDetector({Key? key}) : super(key: key);

  @override
  _GoldDetectorState createState() => _GoldDetectorState();
}

class _GoldDetectorState extends State<GoldDetector> {
  double _magneticIntensity = 0.0;
  double _baselineIntensity = 0.0;
  bool _isCalibrated = false;
  bool _isDetecting = false;
  List<StreamSubscription<dynamic>> _streamSubscriptions = [];

  // Hassasiyet için daha fazla ölçüm tutuyoruz
  final List<double> _recentMeasurements = [];
  final int _measurementCount = 20; // Arttırıldı

  // Sinyal işleme için değişkenler
  double _signalVariance = 0.0;
  double _signalPeak = 0.0;
  final double _detectionThreshold = 8.0; // Daha hassas eşik değeri
  final double _varianceThreshold = 2.0;

  @override
  void initState() {
    super.initState();
    _initSensors();
  }

  void _initSensors() {
    _streamSubscriptions.add(
      magnetometerEvents.listen(
        (MagnetometerEvent event) {
          double intensity = sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z,
          );

          if (mounted) {
            setState(() {
              _magneticIntensity = intensity;

              if (_recentMeasurements.length >= _measurementCount) {
                _recentMeasurements.removeAt(0);
              }
              _recentMeasurements.add(intensity);

              if (!_isCalibrated) {
                _baselineIntensity = _calculateAverage(_recentMeasurements);
                if (_recentMeasurements.length >= _measurementCount) {
                  _isCalibrated = true;
                }
              }

              _processSignal();
            });
          }
        },
        onError: (error) {
          debugPrint('Manyetometre hatası: $error');
        },
      ),
    );
  }

  void _processSignal() {
    if (!_isCalibrated || _recentMeasurements.length < _measurementCount)
      return;

    // Varyans hesapla
    double mean = _calculateAverage(_recentMeasurements);
    _signalVariance = _recentMeasurements
            .map((x) => pow(x - mean, 2))
            .reduce((a, b) => a + b) /
        _recentMeasurements.length;

    // Tepe değeri bul
    _signalPeak = _recentMeasurements.reduce(max);

    // Gelişmiş tespit algoritması
    double baselineDifference = (_magneticIntensity - _baselineIntensity).abs();
    bool significantChange = baselineDifference > _detectionThreshold;
    bool stableSignal = _signalVariance < _varianceThreshold;
    bool newIsDetecting = significantChange && stableSignal;

    if (newIsDetecting != _isDetecting) {
      setState(() {
        _isDetecting = newIsDetecting;
      });

      if (_isDetecting) {
        HapticFeedback.heavyImpact();
      }
    }
  }

  double _calculateAverage(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  void _recalibrate() {
    setState(() {
      _isCalibrated = false;
      _recentMeasurements.clear();
      _isDetecting = false;
      _signalVariance = 0.0;
      _signalPeak = 0.0;
    });
  }

  Color _getIntensityColor() {
    if (!_isCalibrated) return Colors.grey;
    if (_isDetecting) {
      // Sinyal gücüne göre renk tonu
      double intensity = (_magneticIntensity - _baselineIntensity).abs();
      double hue = (120 - (intensity * 2)).clamp(0, 120);
      return HSLColor.fromAHSL(1.0, hue, 1.0, 0.5).toColor();
    }
    return Colors.green;
  }

  String _getDetectionText() {
    if (!_isCalibrated) return 'Kalibrasyon Gerekli';
    if (!_isDetecting) return 'Metal Tespit Edilmedi';

    double intensity = (_magneticIntensity - _baselineIntensity).abs();
    if (intensity > 20) return 'Güçlü Metal Sinyali!';
    if (intensity > 15) return 'Orta Seviye Metal Sinyali';
    return 'Zayıf Metal Sinyali';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metal Dedektörü'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _recalibrate,
            tooltip: 'Yeniden Kalibre Et',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getIntensityColor(),
                boxShadow: [
                  BoxShadow(
                    color: _getIntensityColor().withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isDetecting ? Icons.warning : Icons.check_circle,
                      color: Colors.white,
                      size: 50,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _getDetectionText(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kalibrasyon:'),
                        Text(
                          _isCalibrated ? 'Tamamlandı' : 'Devam Ediyor...',
                          style: TextStyle(
                            color: _isCalibrated ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Manyetik Şiddet:'),
                        Text(
                          '${_magneticIntensity.toStringAsFixed(1)} µT',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Sinyal Kararlılığı:'),
                        Text(
                          '${(100 - _signalVariance).clamp(0, 100).toStringAsFixed(1)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Cihazı yavaşça hareket ettirin. Sinyal kararlılığı yüksek olduğunda '
                've renk değişimi gözlendiğinde metal varlığı tespit edilmiş olabilir.\n\n'
                'Not: Bu uygulama kesin sonuç vermez, sadece deneysel amaçlıdır.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
