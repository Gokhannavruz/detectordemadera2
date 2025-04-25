import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';

class MetalDetector extends StatefulWidget {
  const MetalDetector({Key? key}) : super(key: key);

  @override
  _MetalDetectorState createState() => _MetalDetectorState();
}

class _MetalDetectorState extends State<MetalDetector> {
  // Sensor data
  double _magneticIntensity = 0.0;
  double _baselineIntensity = 0.0;
  bool _isCalibrated = false;
  bool _isDetecting = false;
  List<StreamSubscription<dynamic>> _streamSubscriptions = [];

  // List to hold last 10 measurements
  final List<double> _recentMeasurements = [];
  final int _measurementCount = 10;

  @override
  void initState() {
    super.initState();
    _initSensors();
  }

  void _initSensors() {
    // Start listening to magnetometer events
    _streamSubscriptions.add(
      magnetometerEvents.listen(
        (MagnetometerEvent event) {
          // Calculate magnetic field intensity (vector sum of x, y, z components)
          double intensity = sqrt(
            event.x * event.x + event.y * event.y + event.z * event.z,
          );

          if (mounted) {
            setState(() {
              _magneticIntensity = intensity;

              // Update recent measurements
              if (_recentMeasurements.length >= _measurementCount) {
                _recentMeasurements.removeAt(0);
              }
              _recentMeasurements.add(intensity);

              // If not calibrated, use current value as baseline
              if (!_isCalibrated) {
                _baselineIntensity = _calculateAverage(_recentMeasurements);
                if (_recentMeasurements.length >= _measurementCount) {
                  _isCalibrated = true;
                }
              }

              // Detect wood/metal
              _detectMaterial();
            });
          }
        },
        onError: (error) {
          debugPrint('Error reading magnetometer: $error');
        },
      ),
    );
  }

  double _calculateAverage(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  void _detectMaterial() {
    if (!_isCalibrated) return;

    double difference = (_magneticIntensity - _baselineIntensity).abs();
    bool newIsDetecting = difference > 15.0; // Threshold value

    if (newIsDetecting != _isDetecting) {
      setState(() {
        _isDetecting = newIsDetecting;
      });

      if (_isDetecting) {
        HapticFeedback.heavyImpact(); // Provide haptic feedback
      }
    }
  }

  void _recalibrate() {
    setState(() {
      _isCalibrated = false;
      _recentMeasurements.clear();
      _isDetecting = false;
    });
  }

  Color _getIntensityColor() {
    if (!_isCalibrated) return Colors.grey;
    return _isDetecting ? Colors.red : Colors.green;
  }

  @override
  void dispose() {
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    super.dispose();
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
            // Detector indicator
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
                      _isDetecting ? 'Material Detected!' : 'Clear',
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

            // Status information
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
                          _isCalibrated ? 'Complete' : 'In Progress...',
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
                        const Text('Magnetic Intensity:'),
                        Text(
                          '${_magneticIntensity.toStringAsFixed(1)} µT',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Usage instructions
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Move the phone close to the surface and scan slowly. '
                'Red color and vibration indicate material detection.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
