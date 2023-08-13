import 'package:flutter/material.dart';
import 'package:orders_dev/constants.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicy extends StatelessWidget {
  // const ({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String _text =
        'By using the app, you have by default agreed to the privacy policy.\n\nYou can find our privacy policy in the link https://raw.githubusercontent.com/VikiAssists/innovassist-orders-privacy/main/privacy-policy.md';

    final Uri _url = Uri.parse(
        'https://raw.githubusercontent.com/VikiAssists/innovassist-orders-privacy/main/privacy-policy.md');

    Future<void> _launchUrl() async {
      if (!await launchUrl(_url)) {
        throw Exception('Could not launch $_url');
      }
    }

    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: kAppBarBackIconColor),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          backgroundColor: kAppBarBackgroundColor,
          title: const Text('Privacy Policy', style: kAppBarTextStyle),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(10, 50, 8, 10),
          child: Column(
            children: [
              Center(
                child: Text(
                  'By using the app, you have by default agreed to the privacy policy. Kindly go through our policy by clicking the below button',
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: 20),
                ),
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.green.shade500),
                  ),
                  onPressed: () {
                    _launchUrl();
                  },
                  child: Text('Privacy Policy')),
            ],
          ),
        ));
  }
}
