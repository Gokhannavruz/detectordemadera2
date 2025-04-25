import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

void main() {
  runApp(MetalDetectorMockApp());
}

class MetalDetectorMockApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PrecisionMetalDetectorMock(),
    );
  }
}

class PrecisionMetalDetectorMock extends StatefulWidget {
  const PrecisionMetalDetectorMock({Key? key}) : super(key: key);

  @override
  _PrecisionMetalDetectorMockState createState() =>
      _PrecisionMetalDetectorMockState();
}

class _PrecisionMetalDetectorMockState extends State<PrecisionMetalDetectorMock>
    with SingleTickerProviderStateMixin {
  // Mock detection states
  final List<MockDetectionState> _mockDetectionStates = [
    MockDetectionState(
      magneticIntensity: 12.5,
      metalSize: MetalSize.none,
      graphData: _generateMockGraphData(0, 20),
    ),
    MockDetectionState(
      magneticIntensity: 35.7,
      metalSize: MetalSize.small,
      graphData: _generateMockGraphData(20, 50),
    ),
    MockDetectionState(
      magneticIntensity: 65.3,
      metalSize: MetalSize.large,
      graphData: _generateMockGraphData(50, 80),
    )
  ];

  int _currentStateIndex = 0;

  // Color palette
  static const Color _primaryColor = Color(0xFF3A6EA5);
  static const Color _accentColor = Color(0xFF48C774);
  static const Color _warningColor = Color(0xFFFFC107);
  static const Color _dangerColor = Color(0xFFF14C4C);
  static const Color _backgroundColor = Color(0xFFF5F7FA);

  late AnimationController _animationController;
  late Animation<double> _intensityAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimationController();
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

  // Static method to generate mock graph data
  static List<FlSpot> _generateMockGraphData(double start, double end) {
    List<FlSpot> mockData = [];
    for (int i = 0; i < 100; i++) {
      // Generate slightly randomized data around a trend
      double noise = Random().nextDouble() * 5 - 2.5;
      double value = start + (end - start) * (i / 100) + noise;
      mockData.add(FlSpot(i.toDouble(), value));
    }
    return mockData;
  }

  void _cycleDetectionState() {
    setState(() {
      _currentStateIndex =
          (_currentStateIndex + 1) % _mockDetectionStates.length;
      _animationController.forward(from: 0);
    });
  }

  Color _getStatusColor(MetalSize metalSize) {
    switch (metalSize) {
      case MetalSize.large:
        return _dangerColor;
      case MetalSize.small:
        return _warningColor;
      case MetalSize.none:
      default:
        return _accentColor;
    }
  }

  String _getDetectionMessage(MetalSize metalSize) {
    switch (metalSize) {
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
  Widget build(BuildContext context) {
    final currentState = _mockDetectionStates[_currentStateIndex];

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: GestureDetector(
          onTap: _cycleDetectionState,
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildMagneticIntensityGauge(currentState),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildIntensityGraph(currentState),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tap to cycle through detection states',
                      style: TextStyle(
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'Metal Detector',
        style: TextStyle(
          color: _primaryColor,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
      actions: [
        // Show free detections if not subscribed

        IconButton(
          icon: Icon(
            Icons.volume_up,
            color: _primaryColor,
          ),
          onPressed: () {
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildMagneticIntensityGauge(MockDetectionState state) {
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
                _getDetectionMessage(state.metalSize),
                style: TextStyle(
                  color: _getStatusColor(state.metalSize),
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
                      value: min(state.magneticIntensity / 100, 1.0),
                      colorStart:
                          _getStatusColor(state.metalSize).withOpacity(0.5),
                      colorEnd: _getStatusColor(state.metalSize),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        state.magneticIntensity.toStringAsFixed(2),
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildIntensityGraph(MockDetectionState state) {
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
              spots: state.graphData,
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
            bottomTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

// Mock detection state class
class MockDetectionState {
  final double magneticIntensity;
  final MetalSize metalSize;
  final List<FlSpot> graphData;

  MockDetectionState({
    required this.magneticIntensity,
    required this.metalSize,
    required this.graphData,
  });
}

// Existing RadialGauge and MetalSize enum from the original code
enum MetalSize { none, small, large }

class RadialGauge extends StatelessWidget {
  final double value;
  final Color colorStart;
  final Color colorEnd;

  const RadialGauge({
    Key? key,
    required this.value,
    required this.colorStart,
    required this.colorEnd,
  }) : super(key: key);

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

    // Background circle
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Gradient fill
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
