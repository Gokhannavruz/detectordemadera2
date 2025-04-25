import 'package:detector_de_madera/src/components/native_dialog.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:detector_de_madera/src/model/singletons_data.dart';
import 'package:detector_de_madera/src/rvncat_constant.dart';
import 'package:detector_de_madera/src/views/subscriptionterms_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class Paywall extends StatefulWidget {
  final Offering offering;

  const Paywall({Key? key, required this.offering}) : super(key: key);

  @override
  _PaywallState createState() => _PaywallState();
}

class _PaywallState extends State<Paywall> {
  int? _selectedPackageIndex = 1;
  late List<Package> _sortedPackages;

  @override
  void initState() {
    super.initState();
    _sortedPackages = List<Package>.from(widget.offering.availablePackages);
    _sortPackages();
  }

  void _sortPackages() {
    _sortedPackages.sort((a, b) {
      return _getPackagePriority(a.packageType) -
          _getPackagePriority(b.packageType);
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Stack(
                children: [
                  Image.asset(
                    'assets/images/detectpaywall.jpg', // Replace with your image path
                    height: MediaQuery.of(context).size.height * 0.4,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                  Positioned(
                    top: 40,
                    left: 16,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  Positioned(
                    top: 150,
                    left: 16,
                    right: 16,
                    child: Column(
                      children: [
                        Text(
                          'METAL DETECTOR PRO',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: Column(
                  children: [
                    _buildFeatureRow('UNLIMITED Metal Signal Scanning'),
                    _buildFeatureRow('Advanced Signal Detection Technology'),
                    _buildFeatureRow('Save signals to your device'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _sortedPackages.map((pkg) {
                  int index = _sortedPackages.indexOf(pkg);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPackageIndex = index;
                      });
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width / 3 - 20,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 12),
                      decoration: BoxDecoration(
                        color: _selectedPackageIndex == index
                            ? Colors.blue[50]
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedPackageIndex == index
                              ? Colors.blue
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getSubscriptionType(pkg),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pkg.storeProduct.priceString,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          if (_getSavingsText(pkg).isNotEmpty)
                            Text(
                              _getSavingsText(pkg),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.green,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ElevatedButton(
                  onPressed:
                      _selectedPackageIndex != null ? _subscribeNow : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Subscribe Now',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildSubscriptionInfoText(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SubscriptionTermsPage(
                            packages: _sortedPackages, // Paketleri gönder
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'Subscription terms',
                      style: TextStyle(
                        color: Color.fromARGB(255, 94, 94, 94),
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Add subscription info text
  Widget _buildSubscriptionInfoText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Text(
            'Auto-renewable subscription info:',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            '• Subscription automatically renews unless auto-renew is turned off at least 24-hours before the end of the current period\n'
            '• Account will be charged for renewal within 24-hours prior to the end of the current period\n'
            '• Subscriptions may be managed by the user in Account Settings',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _subscribeNow() async {
    try {
      CustomerInfo customerInfo = await Purchases.purchasePackage(
        _sortedPackages[_selectedPackageIndex!],
      );
      EntitlementInfo? entitlement =
          customerInfo.entitlements.all[entitlementID];
      appData.entitlementIsActive = entitlement?.isActive ?? false;

      if (entitlement?.isActive ?? false) {
        // Başarılı satın alma sonrası işlemler
        await _handleSuccessfulPurchase();
        Navigator.of(context).pop(); // Paywall'ı kapat
      }
    } catch (e) {
      print('Purchase error: $e');
      await showDialog(
        context: context,
        builder: (BuildContext context) => ShowDialogToDismiss(
            title: "Purchase Error",
            content:
                "There was an error processing your purchase. Please try again.",
            buttonText: 'OK'),
      );
    }
  }

  Future<void> _handleSuccessfulPurchase() async {
    try {
      // Kullanıcı tercihlerini güncelle
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isPremium', true);

      // Ana ekrana başarılı mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Premium subscription activated successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Uygulama durumunu güncelle
      setState(() {
        appData.entitlementIsActive = true;
      });
    } catch (e) {
      print('Error handling successful purchase: $e');
    }
  }

  String _getSubscriptionType(Package package) {
    switch (package.packageType) {
      case PackageType.weekly:
        return 'Weekly';
      case PackageType.monthly:
        return 'Monthly';
      case PackageType.annual:
        return 'Annually';
      default:
        return 'Unknown';
    }
  }

  String _getSavingsText(Package package) {
    if (package.packageType == PackageType.weekly) return '';

    double weeklyPrice = _sortedPackages
        .firstWhere((p) => p.packageType == PackageType.weekly)
        .storeProduct
        .price;
    double packagePrice = package.storeProduct.price;

    int weeks;
    switch (package.packageType) {
      case PackageType.monthly:
        weeks = 4;
        break;
      case PackageType.annual:
        weeks = 52;
        break;
      default:
        weeks = 0;
    }

    double totalWeeklyPrice = weeklyPrice * weeks;
    double savings = totalWeeklyPrice - packagePrice;
    double savingsPercentage = (savings / totalWeeklyPrice) * 100;

    return 'Save ${savingsPercentage.toStringAsFixed(0)}%';
  }
}
