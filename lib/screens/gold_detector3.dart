import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:detector_de_madera/services/metal_detection_sevice.dart';
import 'package:detector_de_madera/src/components/native_dialog.dart';
import 'package:detector_de_madera/src/views/paywall.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../models/detected_metal.dart';

class GoldDetector extends StatefulWidget {
  const GoldDetector({Key? key}) : super(key: key);

  @override
  _GoldDetectorState createState() => _GoldDetectorState();
}

class _GoldDetectorState extends State<GoldDetector> {
  // Magnetic Sensing Variables
  double _magneticIntensity = 0.0;
  double _baselineIntensity = 0.0;
  bool _isCalibrated = false;
  bool _isDetecting = false;
  bool _isSoundEnabled = true;
  List<StreamSubscription<dynamic>> _streamSubscriptions = [];
  List<FlSpot> _graphData = [];
  final int _maxGraphPoints = 200;
  double _graphXCounter = 0;

  // Detection Logic Variables
  final List<double> _recentMeasurements = [];
  final int _measurementCount = 20;
  double _signalVariance = 0.0;
  final double _detectionThreshold = 8.0;
  final double _varianceThreshold = 2.0;

  // Subscription and Detection Tracking
  bool _isSubscribed = false;
  bool _isLoading = false;
  Offerings? _offerings;
  static const String _entitlementID = 'pro_metal_detection';

  // Services
  final AudioPlayer _audioPlayer = AudioPlayer();
  final MetalDetectionService _metalDetectionService = MetalDetectionService();

  @override
  void initState() {
    super.initState();
    _initSensors();
    _checkSubscriptionStatus();
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
              _updateGraphData(intensity);

              if (_recentMeasurements.length >= _measurementCount) {
                _recentMeasurements.removeAt(0);
              }
              _recentMeasurements.add(intensity);

              if (!_isCalibrated) {
                _baselineIntensity = _calculateAverage(_recentMeasurements);
                _calibrationProgress =
                    min(_recentMeasurements.length / _measurementCount, 1.0);

                if (_recentMeasurements.length >= _measurementCount) {
                  _isCalibrated = true;
                  _calibrationProgress = 1.0;
                }
              }

              _processSignal();
            });
          }
        },
        onError: (error) {
          debugPrint('Magnetometer error: $error');
        },
      ),
    );
  }

  // Subscription Status Check
  Future<void> _checkSubscriptionStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      setState(() {
        _isSubscribed =
            customerInfo.entitlements.all[_entitlementID]?.isActive ?? false;
        _isLoading = false;
      });

      // Fetch available offerings
      await _fetchOfferings();
    } on PlatformException catch (e) {
      setState(() {
        _isLoading = false;
      });
      await showDialog(
          context: context,
          builder: (BuildContext context) => ShowDialogToDismiss(
              title: "Error",
              content: e.message ?? "Unknown error",
              buttonText: 'OK'));
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      await showDialog(
          context: context,
          builder: (BuildContext context) => ShowDialogToDismiss(
              title: "Error",
              content: "An unexpected error occurred.",
              buttonText: 'OK'));
    }
  }

  // Fetch Available Subscription Offerings
  Future<void> _fetchOfferings() async {
    try {
      Offerings offerings = await Purchases.getOfferings();
      setState(() {
        _offerings = offerings;
      });
    } on PlatformException catch (e) {
      await showDialog(
          context: context,
          builder: (BuildContext context) => ShowDialogToDismiss(
              title: "Error",
              content: e.message ?? "Unknown error",
              buttonText: 'OK'));
    }
  }

  // Metal Detection Logic
  void _processSignal() async {
    if (!_isCalibrated || _recentMeasurements.length < _measurementCount)
      return;

    double mean = _calculateAverage(_recentMeasurements);
    _signalVariance = _recentMeasurements
            .map((x) => pow(x - mean, 2))
            .reduce((a, b) => a + b) /
        _recentMeasurements.length;

    double baselineDifference = (_magneticIntensity - _baselineIntensity).abs();
    bool significantChange = baselineDifference > _detectionThreshold;
    bool stableSignal = _signalVariance < _varianceThreshold;
    bool newIsDetecting = significantChange && stableSignal;

    if (newIsDetecting != _isDetecting) {
      setState(() {
        _isDetecting = newIsDetecting;
      });

      if (_isDetecting) {
        // Check if user can detect for free or is subscribed
        bool canDetectForFree = await _metalDetectionService.canDetectForFree();

        if (canDetectForFree || _isSubscribed) {
          // Save the detected metal
          final detectedMetal = DetectedMetal(
              magneticIntensity: _magneticIntensity,
              detectionTime: DateTime.now(),
              isPremiumDetection: _isSubscribed);

          await _metalDetectionService.saveDetectedMetal(detectedMetal);

          // Increment free detections if not subscribed
          if (!_isSubscribed) {
            await _metalDetectionService.incrementFreeDetections();
          }

          HapticFeedback.heavyImpact();
          _playDetectionSound();
        } else {
          // Redirect to subscription page
          _showSubscriptionPrompt();
        }
      }
    }
  }

  // Show Subscription Prompt
  void _showSubscriptionPrompt() async {
    // Stop detecting momentarily
    setState(() {
      _isDetecting = false;
    });

    if (_offerings == null || _offerings?.current == null) {
      await showDialog(
          context: context,
          builder: (BuildContext context) => ShowDialogToDismiss(
              title: "Detection Limit Reached",
              content:
                  "No subscription offerings available. Please try again later.",
              buttonText: 'OK'));
      return;
    }

    // Navigate to Paywall
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => Paywall(
                offering: _offerings!.current!,
              )),
    ).then((_) {
      // Recheck subscription status after returning from paywall
      _checkSubscriptionStatus();
    });
  }

  // Existing helper methods remain the same...
  Future<void> _playDetectionSound() async {
    if (_isSoundEnabled) {
      await _audioPlayer.play(AssetSource('metal_detection.mp3'));
    }
  }

  double _calculateAverage(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  // Calibration Progress Tracking
  double _calibrationProgress = 0.0;

  void _recalibrate() {
    setState(() {
      _isCalibrated = false;
      _recentMeasurements.clear();
      _isDetecting = false;
      _signalVariance = 0.0;
      _graphData.clear();
      _graphXCounter = 0;
      _calibrationProgress = 0.0;
    });
  }

  void _updateGraphData(double intensity) {
    _graphXCounter++;
    if (_graphData.length >= _maxGraphPoints) {
      _graphData.removeAt(0);
      // Shift X values to maintain continuous scrolling
      _graphData =
          _graphData.map((spot) => FlSpot(spot.x - 1, spot.y)).toList();
    }
    _graphData.add(FlSpot(_graphXCounter, intensity));
  }

  @override
  Widget build(BuildContext context) {
    // Improved normalization with dynamic range
    double maxPossibleIntensity = _baselineIntensity + 50;
    double normalizedIntensity = min(
        max(
            (_magneticIntensity - _baselineIntensity).abs() /
                maxPossibleIntensity,
            0),
        1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Metal Detector'),
        actions: [
          // Subscription Status Indicator
          IconButton(
            icon: Icon(
              _isSubscribed ? Icons.verified : Icons.workspace_premium,
              color: _isSubscribed ? Colors.green : Colors.black,
            ),
            onPressed: _checkSubscriptionStatus,
            tooltip: _isSubscribed
                ? 'Pro Subscription Active'
                : 'Subscribe for Unlimited Detections',
          ),
          // Sound Toggle
          IconButton(
            icon: Icon(_isSoundEnabled ? Icons.volume_up : Icons.volume_off),
            onPressed: () {
              setState(() {
                _isSoundEnabled = !_isSoundEnabled;
              });
            },
            tooltip: _isSoundEnabled ? 'Mute Sound' : 'Unmute Sound',
          ),
          // Recalibrate Button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _recalibrate,
            tooltip: 'Recalibrate',
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Center(
              child: SizedBox(
                width: 250,
                height: 250,
                child: CustomPaint(
                  painter: GaugePainter(
                    value: normalizedIntensity,
                    isDetecting: _isDetecting,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${_magneticIntensity.toStringAsFixed(1)} µT',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          !_isCalibrated
                              ? 'Calibration: ${(_calibrationProgress * 100).toStringAsFixed(0)}%'
                              : (_isDetecting ? 'Metal Detected!' : 'No Metal'),
                          style: TextStyle(
                            fontSize: 18,
                            color: _isDetecting
                                ? Colors.red
                                : (!_isCalibrated
                                    ? Colors.orange
                                    : Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Existing LineChart implementation remains the same
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: _graphData,
                      isCurved: true,
                      color: _isDetecting ? Colors.red : Colors.blue,
                      barWidth: 4,
                      isStrokeCapRound: true,
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  gridData: const FlGridData(show: true),
                  minX: max(0, _graphXCounter - _maxGraphPoints),
                  maxX: _graphXCounter,
                  minY: max(
                      0,
                      min(
                          _baselineIntensity - 10,
                          _graphData.isNotEmpty
                              ? _graphData.map((spot) => spot.y).reduce(min)
                              : _baselineIntensity)),
                  maxY: _baselineIntensity + 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    _audioPlayer.dispose();
    super.dispose();
  }
}

class GaugePainter extends CustomPainter {
  final double value;
  final bool isDetecting;

  GaugePainter({required this.value, required this.isDetecting});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final backgroundPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.4,
      2.2,
      false,
      backgroundPaint,
    );

    final valuePaint = Paint()
      ..color = isDetecting ? Colors.red : Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.4,
      2.2 * value,
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
