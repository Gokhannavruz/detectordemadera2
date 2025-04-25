import 'package:audioplayers/audioplayers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:detector_de_madera/models/detected_metal.dart';
import 'package:detector_de_madera/services/metal_detection_sevice.dart';
import 'package:detector_de_madera/src/components/native_dialog.dart';
import 'package:detector_de_madera/src/model/singletons_data.dart';
import 'package:detector_de_madera/src/model/weather_data.dart';
import 'package:detector_de_madera/src/rvncat_constant.dart';
import 'package:detector_de_madera/src/views/paywall.dart';
import 'package:purchases_flutter/models/customer_info_wrapper.dart';
import 'package:purchases_flutter/models/offerings_wrapper.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class PrecisionMetalDetector extends StatefulWidget {
  const PrecisionMetalDetector({super.key});

  @override
  _PrecisionMetalDetectorState createState() => _PrecisionMetalDetectorState();
}

class _PrecisionMetalDetectorState extends State<PrecisionMetalDetector>
    with SingleTickerProviderStateMixin {
  double _magneticIntensity = 0.0;
  double _smoothedIntensity = 0.0;
  bool _isCalibrated = false;
  double _baselineIntensity = 0.0;
  bool _isSoundEnabled = true;
  bool _isSubscribed = false;
  bool _isLoading = false;
  Offerings? _offerings;
  // New variable to track free detections
  int _freeDetectionsRemaining = 3;
  final int _maxFreeDetections = 3;
  // Add these new variables
  DateTime? _lastDetectionTime;
  static const Duration _freeDetectionCooldown = Duration(seconds: 10);
  DateTime? _firstFreeDetectionTime;
  static const Duration _freeDetectionWindow = Duration(seconds: 10);

  // Gelişmiş renk paleti
  static const Color _primaryColor = Color(0xFF3A6EA5);
  static const Color _accentColor = Color(0xFF48C774);
  static const Color _warningColor = Color(0xFFFFC107);
  static const Color _dangerColor = Color(0xFFF14C4C);
  static const Color _backgroundColor = Color(0xFFF5F7FA);

  // Gelişmiş eşik değerleri
  static const double _smallMetalThreshold = 10.0;
  static const double _largeMetalThreshold = 50.0;

  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Gelişmiş grafik için dairesel arabellek
  final int _maxGraphPoints = 100;
  List<FlSpot> _graphData = [];
  MetalSize _detectedMetalSize = MetalSize.none;

  // Yumuşatma ve animasyon için gelişmiş kontroller
  late AnimationController _animationController;
  late Animation<double> _intensityAnimation;

  // Yumuşatma katsayısı
  final double _smoothingFactor = 0.2;

  // Metal Detection Service
  final MetalDetectionService _metalDetectionService = MetalDetectionService();

  @override
  void initState() {
    super.initState();
    _startMagnetometerTracking();
    _initializeAnimationController();
    _checkSubscriptionStatus();
    _loadFreeDetections();
    _fetchOfferings();
  }

  Future<void> _loadFreeDetections() async {
    int usedDetections = await FreeDetectionsManager.loadUsedDetections();
    setState(() {
      _freeDetectionsRemaining = _maxFreeDetections - usedDetections;
    });
  }

  Future<void> _checkSubscriptionStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      setState(() {
        _isSubscribed =
            customerInfo.entitlements.all[entitlementID]?.isActive ?? false;
        _isLoading = false;
      });
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

  void _initializeAnimationController() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _intensityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutQuad,
      ),
    );
  }

  void _startMagnetometerTracking() {
    _magnetometerSubscription =
        magnetometerEvents.listen((MagnetometerEvent event) {
      double intensity =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      setState(() {
        // Yumuşatılmış manyetik şiddet hesaplaması
        _smoothedIntensity = (_smoothingFactor * intensity) +
            ((1 - _smoothingFactor) *
                (_smoothedIntensity == 0 ? intensity : _smoothedIntensity));

        _magneticIntensity = _smoothedIntensity;
        _processMetalDetection(_magneticIntensity);
        _updateCircularGraphData(_magneticIntensity);
        _animationController.forward(from: 0);
      });
    });
  }

  void _processMetalDetection(double intensity) async {
    if (!_isCalibrated) {
      _baselineIntensity = intensity;
      _isCalibrated = true;
      return;
    }

    double deviation = (intensity - _baselineIntensity).abs();

    // Sadece metal tespit edildiğinde işlem yap
    if (deviation > _largeMetalThreshold) {
      _detectedMetalSize = MetalSize.large;
      await _handleMetalDetection(intensity, true);
    } else if (deviation > _smallMetalThreshold) {
      _detectedMetalSize = MetalSize.small;
      await _handleMetalDetection(intensity, false);
    } else {
      _detectedMetalSize = MetalSize.none;
      // Metal tespit edilmediyse hiçbir şey kaydetme
    }
  }

  Future<void> _handleMetalDetection(
      double intensity, bool isLargeMetal) async {
    // Ücretsiz kullanım penceresini kontrol et
    if (_firstFreeDetectionTime != null) {
      // Eğer 10 saniye içindeyse ve ücretsiz haklar tükenmişse
      if (DateTime.now().difference(_firstFreeDetectionTime!) <=
          _freeDetectionWindow) {
        // Metal tespiti yapabilir ama hakkından düşülmez
        final detectedMetal = DetectedMetal(
          magneticIntensity: intensity,
          detectionTime: DateTime.now(),
          isPremiumDetection: false, // Ücretsiz olarak işaretle
        );

        // save the detection if metal size is small, middle or large
        if (_detectedMetalSize != MetalSize.none) {
          await _metalDetectionService.saveDetectedMetal(detectedMetal);
        }
        _triggerDetectionFeedback();
        return;
      }
    }

    // Abonelik kontrolü
    if (!_isSubscribed) {
      // Ücretsiz tespitlerin kullanılabilirliğini kontrol et
      if (!await FreeDetectionsManager.areFreeDetectionsAvailable()) {
        // Ödeme ekranını göster
        perfomMagic();
        return;
      }

      // Kullanılan tespitleri kaydet
      int currentUsedDetections =
          await FreeDetectionsManager.loadUsedDetections();
      await FreeDetectionsManager.saveUsedDetections(currentUsedDetections + 1);

      // UI'ı güncelle
      setState(() {
        _freeDetectionsRemaining =
            _maxFreeDetections - (currentUsedDetections + 1);
        // İlk ücretsiz tespit zamanını kaydet
        _firstFreeDetectionTime = DateTime.now();
      });
    }

    // Metal tespiti nesnesini oluştur
    final detectedMetal = DetectedMetal(
      magneticIntensity: intensity,
      detectionTime: DateTime.now(),
      isPremiumDetection: !_isSubscribed,
      metalSize: _detectedMetalSize, // Add this line
    );

    // Tespiti kaydet
    if (_detectedMetalSize != MetalSize.none) {
      await _metalDetectionService.saveDetectedMetal(detectedMetal);
    }

    // Geri bildirim ver
    _triggerDetectionFeedback();
  }

  void _updateCircularGraphData(double intensity) {
    if (_graphData.length >= _maxGraphPoints) {
      _graphData.removeAt(0);
    }
    _graphData.add(FlSpot(_graphData.length.toDouble(), intensity));
  }

  void _triggerDetectionFeedback() {
    HapticFeedback.mediumImpact();
    _playDetectionSound();
  }

  Future<void> _playDetectionSound() async {
    if (_isSoundEnabled) {
      await _audioPlayer.play(AssetSource('metal_detection.mp3'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildMagneticIntensityGauge(),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildIntensityGraph(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modify the build method to show remaining free detections
  Widget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      // Premium butonu sadece abone olmayan kullanıcılara gösterilsin
      leading: !_isSubscribed
          ? IconButton(
              icon: Icon(
                Icons.workspace_premium,
                color: _primaryColor,
              ),
              onPressed: () => perfomMagic(),
            )
          : null,
      title: Text(
        'Metal Detector',
        style: TextStyle(
          color: _primaryColor,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isSoundEnabled ? Icons.volume_up : Icons.volume_off,
            color: _primaryColor,
          ),
          onPressed: () {
            setState(() {
              _isSoundEnabled = !_isSoundEnabled;
            });
          },
        ),
      ],
    );
  }

  Widget _buildMagneticIntensityGauge() {
    return AnimatedBuilder(
      animation: _intensityAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                _getDetectionMessage(),
                style: TextStyle(
                  color: _getStatusColor(),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: RadialGauge(
                      value: min(_magneticIntensity / 100, 1.0),
                      colorStart: _getStatusColor().withOpacity(0.5),
                      colorEnd: _getStatusColor(),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        _magneticIntensity.toStringAsFixed(2),
                        style: TextStyle(
                          color: _primaryColor,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Magnetic Intensity (µT)',
                        style: TextStyle(
                          color: _primaryColor.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Subscription status veya free credits gösterimi
              if (!_isSubscribed)
                Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.token,
                        size: 18,
                        color: _primaryColor,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Free Credits: $_freeDetectionsRemaining',
                        style: TextStyle(
                          color: _primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void perfomMagic() async {
    setState(() {
      _isLoading = true;
    });

    CustomerInfo customerInfo = await Purchases.getCustomerInfo();

    if (customerInfo.entitlements.all[entitlementID] != null &&
        customerInfo.entitlements.all[entitlementID]?.isActive == true) {
      appData.currentData = WeatherData.generateData();

      setState(() {
        _isLoading = false;
      });
    } else {
      Offerings? offerings;
      try {
        offerings = await Purchases.getOfferings();
      } on PlatformException catch (e) {
        await showDialog(
            context: context,
            builder: (BuildContext context) => ShowDialogToDismiss(
                title: "Error",
                content: e.message ?? "Unknown error",
                buttonText: 'OK'));
      }

      setState(() {
        _isLoading = false;
      });

      if (offerings == null || offerings.current == null) {
        // offerings are empty, show a message to your user
        await showDialog(
            context: context,
            builder: (BuildContext context) => ShowDialogToDismiss(
                title: "Error",
                content: "No offerings available",
                buttonText: 'OK'));
      } else {
        // current offering is available, show paywall
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Paywall(offering: offerings!.current!)),
        );
      }
    }
  }

  Widget _buildIntensityGraph() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: _graphData,
              isCurved: true,
              color: _primaryColor,
              barWidth: 4,
              belowBarData: BarAreaData(
                show: true,
                color: _primaryColor.withOpacity(0.2),
              ),
              dotData: FlDotData(
                show: false,
              ),
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(
                      color: _primaryColor.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  // Zamanı göster
                  DateTime graphTime =
                      DateTime.fromMillisecondsSinceEpoch(value.toInt() * 1000);
                  return Text(
                    '${graphTime.minute}:${graphTime.second.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: _primaryColor.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 10,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (_detectedMetalSize) {
      case MetalSize.large:
        return _dangerColor;
      case MetalSize.small:
        return _warningColor;
      case MetalSize.none:
      default:
        return _accentColor;
    }
  }

  String _getDetectionMessage() {
    switch (_detectedMetalSize) {
      case MetalSize.large:
        return 'Large Metal Detected!';
      case MetalSize.small:
        return 'Small Metal Detected!';
      case MetalSize.none:
      default:
        return 'No Metal Detected';
    }
  }

  @override
  void dispose() {
    _magnetometerSubscription?.cancel();
    _audioPlayer.dispose();
    _animationController.dispose();
    super.dispose();
  }
}

// Özel Radyal Gauge Widget'ı
class RadialGauge extends StatelessWidget {
  final double value;
  final Color colorStart;
  final Color colorEnd;

  const RadialGauge({
    super.key,
    required this.value,
    required this.colorStart,
    required this.colorEnd,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: RadialGaugePainter(
        value: value,
        colorStart: colorStart,
        colorEnd: colorEnd,
      ),
    );
  }
}

class RadialGaugePainter extends CustomPainter {
  final double value;
  final Color colorStart;
  final Color colorEnd;

  RadialGaugePainter({
    required this.value,
    required this.colorStart,
    required this.colorEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 20.0;

    // Arka plan dairesi
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Gradyan dolgu
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        colors: [colorStart, colorEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final sweepAngle = 360 * value;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -90 * (pi / 180),
      sweepAngle * (pi / 180),
      false,
      gradientPaint,
    );
  }

  @override
  bool shouldRepaint(covariant RadialGaugePainter oldDelegate) =>
      oldDelegate.value != value ||
      oldDelegate.colorStart != colorStart ||
      oldDelegate.colorEnd != colorEnd;
}

enum MetalSize { none, small, large }

class FreeDetectionsManager {
  static const String _freeDetectionsKey = 'total_free_detections';
  static const int _maxTotalFreeDetections = 3;

  // Save the number of free detections used
  static Future<void> saveUsedDetections(int usedDetections) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_freeDetectionsKey, usedDetections);
  }

  // Load the number of free detections used
  static Future<int> loadUsedDetections() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_freeDetectionsKey) ?? 0;
  }

  // Check if free detections are available
  static Future<bool> areFreeDetectionsAvailable() async {
    final usedDetections = await loadUsedDetections();
    return usedDetections < _maxTotalFreeDetections;
  }

  // Reset free detections (can be used when a new user starts or after a reset)
  static Future<void> resetFreeDetections() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_freeDetectionsKey);
  }
}
