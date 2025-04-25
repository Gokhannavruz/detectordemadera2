import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:detector_de_madera/screens/privacy_url.dart';
import 'package:detector_de_madera/screens/terms_of_use.dart';
import 'package:detector_de_madera/src/components/native_dialog.dart';
import 'package:detector_de_madera/src/model/singletons_data.dart';
import 'package:detector_de_madera/src/model/weather_data.dart';
import 'package:detector_de_madera/src/rvncat_constant.dart';
import 'package:detector_de_madera/src/views/paywall.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  void _initializeUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (appData.appUserID == null || appData.appUserID.isEmpty) {
        String newUserID = Uuid().v4();
        await Purchases.logIn(newUserID);
        appData.appUserID = await Purchases.appUserID;
      }
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
  }

  void _restore() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Purchases.restorePurchases();
      appData.appUserID = await Purchases.appUserID;
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Settings'),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: ModalProgressHUD(
        inAsyncCall: _isLoading,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                color: appData.entitlementIsActive
                    ? Color.fromARGB(255, 19, 161, 26) // Yeşil renk
                    : Color.fromARGB(
                        255, 19, 161, 26), // Kartın arka plan rengi
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.all(16.0),
                      title: Text(
                        'Subscription Status',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        appData.entitlementIsActive
                            ? 'Enjoy unlimited metal detections!'
                            : 'You are not a premium user. Get premium to access all features.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: appData.entitlementIsActive ? 16 : 14,
                        ),
                      ),
                      trailing: appData.entitlementIsActive
                          ? Icon(Icons.check_circle,
                              color: Colors.white, size: 32)
                          : ElevatedButton(
                              onPressed: () {
                                perfomMagic();
                              },
                              style: ElevatedButton.styleFrom(
                                primary: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text('Get Premium'),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            SettingsSection(
              title: 'SUBSCRIPTION',
              tiles: [
                SettingsTile(
                  title: 'Restore Purchase',
                  onTap: () {
                    _restore();
                  },
                ),
              ],
            ),
            SettingsSection(
              title: 'TERMS & PRIVACY',
              tiles: [
                SettingsTile(
                    title: 'Privacy Policy',
                    onTap: () async {
                      final privacyUrl =
                          'https://toolstoore.blogspot.com/2024/12/detector-de-madera-privacy-policy.html';
                      if (!await launchUrl(Uri.parse(privacyUrl))) {
                        throw Exception('Could not launch $privacyUrl');
                      }
                    }),
                SettingsTile(
                    title: 'Terms of Use',
                    onTap: () async {
                      final termsUrl =
                          'https://toolstoore.blogspot.com/2024/12/detector-de-madera-terms-of-service-tos.html';
                      if (!await launchUrl(Uri.parse(termsUrl))) {
                        throw Exception('Could not launch $termsUrl');
                      }
                    }),
              ],
            ),
          ],
        ),
      ),
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
}

class SettingsSection extends StatelessWidget {
  final String title;
  final List<SettingsTile> tiles;

  SettingsSection({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.black54,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...tiles,
        Divider(color: Colors.black26),
      ],
    );
  }
}

class SettingsTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  SettingsTile({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title, style: TextStyle(color: Colors.black)),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.black54),
      onTap: onTap,
    );
  }
}
