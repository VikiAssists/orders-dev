import 'package:flutter/material.dart';
import 'package:orders_dev/Screens/privacy_policy.dart';
import 'package:orders_dev/constants.dart';

class AboutAppInfo extends StatelessWidget {
  // const ({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: kAppBarBackIconColor),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          backgroundColor: kAppBarBackgroundColor,
          title: const Text('About', style: kAppBarTextStyle),
        ),
        body: Column(
          children: [
            ListTile(
              title: Text('Privacy Policy'),
              trailing:
                  const Icon(IconData(0xe09e, fontFamily: 'MaterialIcons')),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (Buildcontext) => PrivacyPolicy()));
              },
            ),
            ListTile(
              title: Text('Version'),
              subtitle: Text('3.6.18'),
            ),
          ],
        ));
  }
}
