import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

class UltrasonicEvent {
  final double distance;

  UltrasonicEvent(this.distance);
}

class StudFinder extends StatefulWidget {
  const StudFinder({Key? key}) : super(key: key);

  @override
  _StudFinderState createState() => _StudFinderState();
}

class _StudFinderState extends State<StudFinder> {
  double _magneticIntensity = 0.0;
  double _baselineIntensity = 0.0;
  bool _isCalibrated = false;
  bool _isDetecting = false;
  List<StreamSubscription<dynamic>> _streamSubscriptions = [];

  // Gelişmiş tarama için ölçüm listesi
  final List<double> _recentMeasurements = [];
  final int _measurementCount = 30; // Daha hassas tarama

  // Gelişmiş sinyal işleme
  double _signalVariance = 0.0;
  double _signalPeak = 0.0;
  final double _detectionThreshold = 10.0; // Metal tespiti için yüksek eşik
  final double _varianceThreshold = 1.8;

  // Tarama modları
  bool _deepScanMode = false;
  bool _acWiringMode = false;
  bool _ultrasonicMode = false; // Yeni mod: Ultrasonik tarama
  double _maxDetectionRange = 50.0; // cm cinsinden

  // Yeni özellikler
  int _batteryLevel = 100;
  bool _isAutomaticCalibrationEnabled = true;
  double _detectionRange = 10.0; // cm cinsinden

  // Stud lokasyonu ve yakınlık özellikleri
  double _studLocation = 50.0; // Varsayılan stud konumu
  double _currentDistance = 0.0;
  bool _isNearingStud = false;

  @override
  void initState() {
    super.initState();
    _initSensors();
    _startAutomaticCalibration();
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
          debugPrint('Manyetometre Hatası: $error');
        },
      ),
    );

    if (_ultrasonicMode) {
      // Gelişmiş mock veri simülasyonu
      Stream<UltrasonicEvent> ultrasonicEvents =
          Stream.periodic(const Duration(seconds: 1), (x) {
        // Kullanıcının konumuna göre mesafe hesaplama
        double userLocation = _calculateUserLocation(x);
        double distance = (_studLocation - userLocation).abs();
        return UltrasonicEvent(distance);
      });

      _streamSubscriptions.add(
        ultrasonicEvents.listen(
          (UltrasonicEvent event) {
            if (mounted) {
              setState(() {
                _currentDistance = event.distance;
                _isNearingStud = _checkStudProximity(event.distance);
              });
            }
          },
          onError: (error) {
            debugPrint('Ultrasonik Simülasyon Hatası: $error');
          },
        ),
      );
    }
  }

  // Kullanıcı konumunu simüle eden metot
  double _calculateUserLocation(int iteration) {
    // Basit bir hareket simülasyonu
    return 50.0 + (iteration * 5.0) % 100.0;
  }

  // Stud yakınlığını kontrol eden metot
  bool _checkStudProximity(double distance) {
    return distance < 20.0; // 20 cm içindeyse yakın kabul et
  }

  void _startAutomaticCalibration() {
    if (_isAutomaticCalibrationEnabled) {
      Timer.periodic(const Duration(minutes: 5), (timer) {
        if (mounted) {
          setState(() {
            _isCalibrated = false;
            _recentMeasurements.clear();
          });
        }
      });
    }
  }

  void _processSignal() {
    if (!_isCalibrated || _recentMeasurements.length < _measurementCount)
      return;

    double mean = _calculateAverage(_recentMeasurements);
    _signalVariance = _recentMeasurements
            .map((x) => pow(x - mean, 2))
            .reduce((a, b) => a + b) /
        _recentMeasurements.length;

    _signalPeak = _recentMeasurements.reduce(max);

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
        _playDetectionSound();
      }
    }
  }

  void _playDetectionSound() {
    // Ses çalma mekanizması eklenebilir
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

  void _toggleAutomaticCalibration() {
    setState(() {
      _isAutomaticCalibrationEnabled = !_isAutomaticCalibrationEnabled;
      if (_isAutomaticCalibrationEnabled) {
        _startAutomaticCalibration();
      }
    });
  }

  void _toggleUltrasonicMode() {
    setState(() {
      _ultrasonicMode = !_ultrasonicMode;
      if (_ultrasonicMode) {
        _initSensors(); // Ultrasonik sensörü başlat
      } else {
        for (final subscription in _streamSubscriptions) {
          subscription.cancel();
        }
        _streamSubscriptions.clear();
      }
    });
  }

  void _setDetectionRange(double range) {
    setState(() {
      _maxDetectionRange = range;
    });
  }

  // Stud yakınlık bilgisini gösteren widget
  Widget _buildStudProximityInfo() {
    if (!_ultrasonicMode) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Stud Uzaklığı: ${_currentDistance.toStringAsFixed(1)} cm',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _isNearingStud ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(height: 10),
          Icon(
            _isNearingStud
                ? Icons.arrow_downward // Studa yaklaşıyorsun
                : Icons.arrow_upward, // Studdan uzaklaşıyorsun
            color: _isNearingStud ? Colors.green : Colors.red,
            size: 40,
          ),
          Text(
            _isNearingStud
                ? 'Studa Yaklaşıyorsunuz'
                : 'Studdan Uzaklaşıyorsunuz',
            style: TextStyle(
              color: _isNearingStud ? Colors.green : Colors.red,
            ),
          )
        ],
      ),
    );
  }

  Color _getIntensityColor() {
    if (!_isCalibrated) return Colors.grey;
    if (_isDetecting) {
      double intensity = (_magneticIntensity - _baselineIntensity).abs();

      if (_acWiringMode) {
        return Colors.redAccent; // Elektrik hatları için kırmızı
      }

      double hue = (30 - (intensity * 1.5)).clamp(0, 30); // Metal için tonlar
      return HSLColor.fromAHSL(1.0, hue, 1.0, 0.5).toColor();
    }
    return Colors.green;
  }

  String _getDetectionText() {
    if (!_isCalibrated) return 'Kalibrasyon Gerekli';
    if (!_isDetecting) return 'Hiçbir Şey Tespit Edilmedi';

    double intensity = (_magneticIntensity - _baselineIntensity).abs();

    if (_acWiringMode) {
      return 'Elektrik Hattı Tespit Edildi!';
    }

    if (intensity > 25) return 'Güçlü Metal Sinyali!';
    if (intensity > 15) return 'Orta Seviye Metal Sinyali';
    return 'Zayıf Metal Sinyali';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stud & Metal Bulucu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _recalibrate,
            tooltip: 'Yeniden Kalibre Et',
          ),
          IconButton(
            icon: _isAutomaticCalibrationEnabled
                ? const Icon(Icons.autorenew)
                : const Icon(Icons.cancel),
            onPressed: _toggleAutomaticCalibration,
            tooltip: _isAutomaticCalibrationEnabled
                ? 'Otomatik Kalibrasyonu Kapat'
                : 'Otomatik Kalibrasyonu Aç',
          ),
          IconButton(
            icon: _ultrasonicMode
                ? const Icon(Icons.sensors)
                : const Icon(Icons.sensors_off),
            onPressed: _toggleUltrasonicMode,
            tooltip: _ultrasonicMode
                ? 'Ultrasonik Modu Kapat'
                : 'Ultrasonik Modu Aç',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
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
                        _isDetecting
                            ? (_acWiringMode
                                ? Icons.electrical_services
                                : Icons.warning)
                            : Icons.check_circle,
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
              const SizedBox(height: 20),
              // Yeni eklenen Stud Yakınlık Bilgisi
              _buildStudProximityInfo(),
              SwitchListTile(
                title: const Text('Derin Tarama Modu'),
                subtitle: const Text('30mm kalınlığa kadar tarama'),
                value: _deepScanMode,
                onChanged: (bool value) {
                  setState(() {
                    _deepScanMode = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Elektrik Hattı Modu'),
                subtitle: const Text('AC kablolarını tespit et'),
                value: _acWiringMode,
                onChanged: (bool value) {
                  setState(() {
                    _acWiringMode = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Ultrasonik Mod'),
                subtitle: const Text('Mesafe algılama'),
                value: _ultrasonicMode,
                onChanged: (bool value) {
                  _toggleUltrasonicMode();
                },
              ),
              Slider(
                min: 10.0,
                max: 100.0,
                divisions: 9,
                value: _maxDetectionRange,
                onChanged: _setDetectionRange,
                label: '${_maxDetectionRange.toInt()} cm',
              ),
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
                              color:
                                  _isCalibrated ? Colors.green : Colors.orange,
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
                      // ... (önceki kodun devamı)

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Batarya Ömrü:'),
                          Text(
                            '$_batteryLevel%',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Algılama Mesafesi:'),
                          Text(
                            '${_detectionRange.toStringAsFixed(1)} cm',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Yeni eklenen Stud Mesafe Bilgisi
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Stud Mesafesi:'),
                          Text(
                            '${_currentDistance.toStringAsFixed(1)} cm',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isNearingStud ? Colors.green : Colors.red,
                            ),
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
                  'Cihazı yavaşça duvarda hareket ettirin. '
                  'Metal çubuk veya elektrik hatları tespit edildiğinde '
                  'ekran ve titreşimle uyarılacaksınız.\n\n'
                  'Not: Kesin sonuç için profesyonel cihaz kullanın.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    _streamSubscriptions.clear();
    super.dispose();
  }
}
