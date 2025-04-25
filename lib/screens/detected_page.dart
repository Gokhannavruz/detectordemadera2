import 'package:flutter/material.dart';
import 'package:detector_de_madera/models/detected_metal.dart';
import 'package:detector_de_madera/screens/gold_detector.dart';
import 'package:detector_de_madera/services/metal_detection_sevice.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetectedMetalsPage extends StatefulWidget {
  const DetectedMetalsPage({Key? key}) : super(key: key);

  @override
  _DetectedMetalsPageState createState() => _DetectedMetalsPageState();
}

class _DetectedMetalsPageState extends State<DetectedMetalsPage> {
  final MetalDetectionService _metalDetectionService = MetalDetectionService();
  List<DetectedMetal> _detectedMetals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetectedMetals();
  }

  Future<void> _loadDetectedMetals() async {
    setState(() {
      _isLoading = true;
    });
    final metals = await _metalDetectionService.getDetectedMetals();
    setState(() {
      _detectedMetals = metals.reversed.toList(); // Most recent first
      _isLoading = false;
    });
  }

  void _clearDetectedMetals() async {
    await _metalDetectionService.clearDetectedMetals();
    await _loadDetectedMetals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'History',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_detectedMetals.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep, color: Colors.red.shade700),
              onPressed: _showClearConfirmationDialog,
              tooltip: 'Clear All Detections',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Colors.blue.shade300,
        ),
      );
    }

    if (_detectedMetals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 100,
              color: Colors.grey.shade300,
            ),
            SizedBox(height: 16),
            Text(
              'No metals detected yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _detectedMetals.length,
      separatorBuilder: (context, index) => Divider(
        color: Colors.grey.shade200,
        height: 1,
      ),
      itemBuilder: (context, index) {
        final metal = _detectedMetals[index];
        return _buildMetalDetectionTile(metal);
      },
    );
  }

  Widget _buildMetalDetectionTile(DetectedMetal metal) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildMetalIntensityIndicator(metal),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${metal.metalSize.toString().split('.').last.toUpperCase()} METAL',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getMetalSizeColor(metal.metalSize),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${metal.magneticIntensity.toStringAsFixed(2)} µT',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _formatDateTime(metal.detectionTime),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetalIntensityIndicator(DetectedMetal metal) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _getMetalSizeColor(metal.metalSize).withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _getMetalSizeIcon(metal.metalSize),
        color: _getMetalSizeColor(metal.metalSize),
        size: 24,
      ),
    );
  }

  Color _getMetalSizeColor(MetalSize size) {
    switch (size) {
      case MetalSize.large:
        return Colors.red.shade700;
      case MetalSize.small:
        return Colors.orange.shade700;
      case MetalSize.none:
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _getMetalSizeIcon(MetalSize size) {
    switch (size) {
      case MetalSize.large:
        return Icons.all_out;
      case MetalSize.small:
        return Icons.adjust;
      case MetalSize.none:
      default:
        return Icons.remove_circle_outline;
    }
  }

  void _showClearConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Clear Detection History',
          ),
          content: Text(
            'Are you sure you want to clear all detected metals? This action cannot be undone.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
              ),
              child:
                  Text('Clear History', style: TextStyle(color: Colors.white)),
              onPressed: () {
                _clearDetectedMetals();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }
}
