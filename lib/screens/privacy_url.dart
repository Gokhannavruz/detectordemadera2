import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EulaPage extends StatelessWidget {
  final String privacyPolicyUrl =
      "https://toolstoore.blogspot.com/2024/12/detector-de-madera-terms-of-service-tos.html";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Detector de Madera EULA',
          style: TextStyle(color: Colors.black, fontSize: 17),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detector de Madera End User License Agreement (EULA)',
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
            SizedBox(height: 20),
            _buildSectionTitle('1. License Grant'),
            _buildText(
                'We grant you a limited, non-exclusive, non-transferable, revocable license to use Detector de Madera in accordance with these terms.'),
            SizedBox(height: 20),
            _buildSectionTitle('2. Restrictions'),
            _buildText('You may not:\n\n'
                '- Decompile, reverse engineer, disassemble, attempt to derive the source code of, or decrypt Detector de Madera.\n\n'
                '- Make any modification, adaptation, improvement, enhancement, translation, or derivative work from Detector de Madera.\n\n'
                '- Use Detector de Madera for any unlawful or illegal activity, or to facilitate any illegal activity.'),
            SizedBox(height: 20),
            _buildSectionTitle('3. User Content'),
            _buildText(
                'You are responsible for the content you post on or through Detector de Madera. By posting content, you grant us a worldwide, non-exclusive, royalty-free, transferable license to use, reproduce, distribute, prepare derivative works of, display, and perform that content in connection with the service.'),
            SizedBox(height: 20),
            _buildSectionTitle('4. No Tolerance for Objectionable Content'),
            _buildText(
                'There is zero tolerance for objectionable content or abusive users. Users found to be engaging in such activities will have their accounts terminated.'),
            SizedBox(height: 20),
            _buildSectionTitle('5. Termination'),
            _buildText(
                'We may terminate your access to Detector de Madera if you fail to comply with any of the terms and conditions of this EULA. Upon termination, you must cease all use of Detector de Madera and delete all copies of Detector de Madera from your devices.'),
            SizedBox(height: 20),
            _buildSectionTitle('6. Changes to EULA'),
            _buildText(
                'We may update this EULA from time to time. The most current version will always be available on our website. Your continued use of Detector de Madera after any updates indicates your acceptance of the new terms.'),
            SizedBox(height: 20),
            _buildSectionTitle('7. Contact Us'),
            _buildText(
                'If you have any questions about this EULA, please contact us at gkhnnavruz@gmail.com.'),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: Colors.blue,
                    onPrimary: Colors.white,
                  ),
                  onPressed: () async {
                    if (await canLaunch(privacyPolicyUrl)) {
                      await launch(privacyPolicyUrl);
                    } else {
                      throw 'Could not launch $privacyPolicyUrl';
                    }
                  },
                  child: Text('Open Term of Service in Browser',
                      style: TextStyle(fontSize: 13.0, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18.0,
        ),
      ),
    );
  }

  Widget _buildText(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 16.0),
    );
  }
}

class TermsOfServicePage extends StatelessWidget {
  final WebViewController _controller = WebViewController()
    ..loadRequest(Uri.parse(
        'https://toolstoore.blogspot.com/2024/12/detector-de-madera-privacy-policy.html'));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy Policy'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
