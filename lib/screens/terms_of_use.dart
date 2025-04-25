import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TermsOfServicePage extends StatelessWidget {
  final String privacyPolicyUrl =
      "https://toolstoore.blogspot.com/2024/12/detector-de-madera-privacy-policy.html";
  final WebViewController _controller = WebViewController()
    ..loadRequest(Uri.parse(
        'https://toolstoore.blogspot.com/2024/12/detector-de-madera-terms-of-service-tos.html'));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Terms of Service'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('1. Acceptance of Terms'),
            _buildText(
                'By accessing or using Detector de Madera, you agree to be bound by these Terms of Service and our Privacy Policy. If you do not agree with any part of these terms, you must not use our services.'),
            SizedBox(height: 20),
            _buildSectionTitle('2. User Conduct'),
            _buildText('You agree not to use Detector de Madera to:\n\n'
                '- Post, upload, or share any content that is illegal, harmful, threatening, abusive, harassing, defamatory, vulgar, obscene, hateful, or otherwise objectionable.\n\n'
                '- Impersonate any person or entity or falsely state or otherwise misrepresent your affiliation with a person or entity.\n\n'
                '- Engage in any form of bullying, harassment, or intimidation.\n\n'
                '- Post or transmit any content that infringes any patent, trademark, trade secret, copyright, or other proprietary rights of any party.\n\n'
                '- Upload, post, or transmit any material that contains software viruses or any other computer code, files, or programs designed to interrupt, destroy, or limit the functionality of any computer software or hardware.'),
            SizedBox(height: 20),
            _buildSectionTitle('3. Content Moderation'),
            _buildText(
                'We reserve the right, but have no obligation, to monitor, edit, or remove any activity or content that we determine in our sole discretion violates these terms or is otherwise objectionable.'),
            SizedBox(height: 20),
            _buildSectionTitle('4. Reporting and Blocking'),
            _buildText(
                'Users can report offensive content or behavior by using the report feature within Detector de Madera. We will review and take appropriate action on reported content or users promptly. Users also have the ability to block other users to prevent further interaction.'),
            SizedBox(height: 20),
            _buildSectionTitle('5. Termination'),
            _buildText(
                'We reserve the right to terminate or suspend your account and access to Detector de Madera without notice if we determine, in our sole discretion, that you have violated these terms or engaged in any conduct that we consider inappropriate or harmful.'),
            SizedBox(height: 20),
            _buildSectionTitle('6. Changes to Terms'),
            _buildText(
                'We may revise these Terms of Service from time to time. The most current version will always be posted on our website. By continuing to use our services after changes are made, you agree to be bound by the revised terms.'),
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

class EulaPage extends StatelessWidget {
  final WebViewController _controller = WebViewController()
    ..loadRequest(Uri.parse(
        'https://toolstoore.blogspot.com/2024/12/detector-de-madera-terms-of-service-tos.html'));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Terms of Use'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
