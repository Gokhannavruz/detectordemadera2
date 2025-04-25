import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

class WoodDetector extends StatefulWidget {
  const WoodDetector({Key? key}) : super(key: key);

  @override
  _WoodDetectorState createState() => _WoodDetectorState();
}

class _WoodDetectorState extends State<WoodDetector> {
  double _accelerationIntensity = 0.0;
  double _baselineIntensity = 0.0;
  bool _isCalibrated = false;
  bool _isDetecting = false;
  List<StreamSubscription<dynamic>> _streamSubscriptions = [];

  // Sensitivity measurements
  final List<double> _recentMeasurements = [];
  final int _measurementCount = 20;

  // Signal processing variables
  double _signalVariance = 0.0;
  double _signalPeak = 0.0;
  final double _detectionThreshold = 5.0;
  final double _varianceThreshold = 1.5;

  @override
  void initState() {
    super.initState();
    _initSensors();
  }

  void _initSensors() {
    _streamSubscriptions.add(
      accelerometerEvents.listen(
        (AccelerometerEvent event) {
          double intensity = sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z,
          );

          if (mounted) {
            setState(() {
              _accelerationIntensity = intensity;

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
          debugPrint('Accelerometer error: $error');
        },
      ),
    );
  }

  void _processSignal() {
    if (!_isCalibrated || _recentMeasurements.length < _measurementCount)
      return;

    // Calculate variance
    double mean = _calculateAverage(_recentMeasurements);
    _signalVariance = _recentMeasurements
            .map((x) => pow(x - mean, 2))
            .reduce((a, b) => a + b) /
        _recentMeasurements.length;

    // Find peak value
    _signalPeak = _recentMeasurements.reduce(max);

    // Advanced detection algorithm
    double baselineDifference =
        (_accelerationIntensity - _baselineIntensity).abs();
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
      // Signal strength color tone
      double intensity = (_accelerationIntensity - _baselineIntensity).abs();
      double hue =
          (90 - (intensity * 2)).clamp(0, 90); // More brown/wood-like hues
      return HSLColor.fromAHSL(1.0, hue, 1.0, 0.5).toColor();
    }
    return Colors.green;
  }

  String _getDetectionText() {
    if (!_isCalibrated) return 'Calibration Required';
    if (!_isDetecting) return 'No Wood Detected';

    double intensity = (_accelerationIntensity - _baselineIntensity).abs();
    if (intensity > 15) return 'Strong Wood Signal!';
    if (intensity > 10) return 'Medium Wood Signal';
    return 'Weak Wood Signal';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wood Detector'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _recalibrate,
            tooltip: 'Recalibrate',
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
                      _isDetecting ? Icons.wb_sunny : Icons.check_circle,
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
                        const Text('Calibration:'),
                        Text(
                          _isCalibrated ? 'Completed' : 'In Progress...',
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
                        const Text('Acceleration Intensity:'),
                        Text(
                          '${_accelerationIntensity.toStringAsFixed(1)} m/s²',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Signal Stability:'),
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
                'Slowly move the device. When signal stability is high '
                'and color changes, wood material might be detected.\n\n'
                'Note: This app is experimental and not conclusive.',
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
