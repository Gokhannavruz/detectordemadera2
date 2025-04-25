import 'package:flutter/material.dart';
import 'package:purchases_flutter/models/package_wrapper.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionTermsPage extends StatelessWidget {
  final List<Package>? packages; // Paywall'dan gelen paketler

  const SubscriptionTermsPage({
    Key? key,
    this.packages,
  }) : super(key: key);

  Future<void> _launchURL(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Premium Features',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // App name text
            Padding(
              padding: EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                'Detector de Madera',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Premium özellikleri gösteren kart
            Container(
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3A6EA5), Color(0xFF4A8DD5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    Icons.workspace_premium,
                    size: 48,
                    color: Colors.white,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Premium Metal Detector',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildPremiumFeature(
                    icon: Icons.speed,
                    title: 'Advanced Detection',
                    description: 'High-precision metal detection technology',
                  ),
                  _buildPremiumFeature(
                    icon: Icons.all_inclusive, // infinite yerine all_inclusive
                    title: 'Unlimited Scans',
                    description: 'No restrictions on number of detections',
                  ),
                  _buildPremiumFeature(
                    icon: Icons.save_alt,
                    title: 'Save History',
                    description: 'Keep track of all your detections',
                  ),
                ],
              ),
            ),
            // Abonelik planları
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subscription Plans',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildSubscriptionPlans(),
                ],
              ),
            ),
            // Yasal bilgiler
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Legal Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildLegalText(),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildLegalButton(
                          'Privacy Policy',
                          () => _launchURL(
                              'https://toolstoore.blogspot.com/2024/12/detector-de-madera-privacy-policy.html'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildLegalButton(
                          'Terms of Use',
                          () => _launchURL(
                              'https://toolstoore.blogspot.com/2024/12/detector-de-madera-terms-of-service-tos.html'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionPlans() {
    if (packages == null || packages!.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Subscription information not available'),
        ),
      );
    }

    final sortedPackages = List<Package>.from(packages!)
      ..sort((a, b) =>
          _getPackagePriority(a.packageType) -
          _getPackagePriority(b.packageType));

    return Column(
      children:
          sortedPackages.map((package) => _buildPlanCard(package)).toList(),
    );
  }

  Widget _buildPlanCard(Package package) {
    bool isAnnual = package.packageType == PackageType.annual;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAnnual ? Color(0xFF3A6EA5) : Colors.grey[300]!,
          width: 2,
        ),
        color: isAnnual ? Color(0xFFEDF5FF) : Colors.white,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          _getPackageTypeString(package.packageType),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isAnnual ? Color(0xFF3A6EA5) : Colors.black87,
          ),
        ),
        subtitle: Text(
          'Billed ${package.packageType == PackageType.annual ? "annually" : "every " + _getPackagePeriod(package.packageType)}',
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              package.storeProduct.priceString,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isAnnual ? Color(0xFF3A6EA5) : Colors.black87,
              ),
            ),
            if (isAnnual)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(0xFF3A6EA5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'BEST VALUE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  int _getPackagePriority(PackageType packageType) {
    switch (packageType) {
      case PackageType.weekly:
        return 0;
      case PackageType.monthly:
        return 1;
      case PackageType.annual:
        return 2;
      default:
        return 3;
    }
  }

  String _getPackageTypeString(PackageType type) {
    switch (type) {
      case PackageType.weekly:
        return 'Weekly';
      case PackageType.monthly:
        return 'Monthly';
      case PackageType.annual:
        return 'Annual';
      default:
        return 'Unknown';
    }
  }

  String _getPackagePeriod(PackageType type) {
    switch (type) {
      case PackageType.weekly:
        return "week";
      case PackageType.monthly:
        return "month";
      case PackageType.annual:
        return "year";
      default:
        return "period";
    }
  }

  Widget _buildLegalText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detector de Madera - Premium Subscription',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Text(
          '• Subscription automatically renews unless auto-renew is turned off\n'
          '• Payment will be charged to your Apple ID account\n'
          '• Subscription automatically renews unless auto-renew is turned off at least 24 hours before the end of the current period\n'
          '• Account will be charged for renewal within 24 hours prior to the end of the current period',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLegalButton(String text, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 12),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Color(0xFF3A6EA5)),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Color(0xFF3A6EA5),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
