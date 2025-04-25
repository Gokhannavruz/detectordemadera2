import 'dart:io';

import 'package:detector_de_madera/screens/apple_mockup.dart';
import 'package:detector_de_madera/screens/example_detected.dart';
import 'package:detector_de_madera/src/model/singletons_data.dart';
import 'package:flutter/material.dart';
import 'package:detector_de_madera/screens/detected_page.dart';
import 'package:detector_de_madera/screens/detector_screen.dart';
import 'package:detector_de_madera/screens/gold_detector.dart';
import 'package:detector_de_madera/screens/new_stud_finder.dart';
import 'package:detector_de_madera/screens/onboarding_page.dart';
import 'package:detector_de_madera/screens/settings.dart';
import 'package:detector_de_madera/screens/wood_detector.dart';
import 'package:detector_de_madera/src/rvncat_constant.dart';
import 'package:detector_de_madera/store_config.dart';
import 'package:purchases_flutter/models/purchases_configuration.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
// SettingsPage veya eklemek istediğiniz diğer sayfalar.

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isIOS || Platform.isMacOS) {
    StoreConfig(
      store: Store.appStore,
      apiKey: appleApiKey,
    );
  } else if (Platform.isAndroid) {
    const useAmazon = bool.fromEnvironment("amazon");
    StoreConfig(
      store: useAmazon ? Store.amazon : Store.playStore,
      apiKey: useAmazon ? amazonApiKey : googleApiKey,
    );
  }

  await _configureSDK();

  runApp(const MyApp());
}

Future<void> _configureSDK() async {
  await Purchases.setLogLevel(LogLevel.debug);

  PurchasesConfiguration configuration;
  if (StoreConfig.isForAmazonAppstore()) {
    configuration = AmazonConfiguration(StoreConfig.instance.apiKey)
      ..appUserID = null
      ..observerMode = false; // Observer modu kapalı
  } else if (StoreConfig.isForAppleStore() || StoreConfig.isForGooglePlay()) {
    configuration = PurchasesConfiguration(StoreConfig.instance.apiKey)
      ..appUserID = null
      ..observerMode = false; // Observer modu kapalı
  } else {
    throw Exception("Unsupported store configuration");
  }

  await Purchases.configure(configuration);
  await _checkInitialSubscriptionStatus(); // Başlangıç durumu kontrolü
}

Future<void> _checkInitialSubscriptionStatus() async {
  try {
    final CustomerInfo customerInfo = await Purchases.getCustomerInfo();
    final entitlement = customerInfo.entitlements.all[entitlementID];
    appData.entitlementIsActive = entitlement?.isActive ?? false;

    // Yerel depolamayı güncelle
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPremium', entitlement?.isActive ?? false);
  } catch (e) {
    print('Error checking initial subscription status: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Detector de Madera',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightGreenAccent),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
    PrecisionMetalDetector(),
    DetectedMetalsPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            backgroundColor: Colors.white,
            icon: Icon(Icons.home),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings', // Yeni eklenen Settings itemi
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.black54, // Seçili olmayan öğelerin rengi
        onTap: _onItemTapped,
      ),
    );
  }
}
