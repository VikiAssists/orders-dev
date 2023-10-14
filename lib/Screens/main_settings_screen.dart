import 'package:flutter/material.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:orders_dev/Screens/permissions_screen.dart';
import 'package:orders_dev/Screens/permissions_screen_2.dart';
import 'package:orders_dev/Screens/printer_settings_screen.dart';
import 'package:orders_dev/Screens/searching_Connecting_Printer_Screen.dart';
import 'package:orders_dev/constants.dart';
import 'package:orders_dev/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class MainSettings extends StatelessWidget {
  const MainSettings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kAppBarBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: kAppBarBackIconColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Settings', style: kAppBarTextStyle),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Printer Settings',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 15),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            PrinterSettings(chefOrCaptain: 'Captain')));
              },
              child: Text(
                'Captain Printer Settings',
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            PrinterSettings(chefOrCaptain: 'Chef')));
              },
              child: Text(
                'Chef Printer Settings',
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Permissions',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 15),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                PermissionStatus? statusNotification =
                    await Permission.notification.request();

                bool isGranted = statusNotification == PermissionStatus.granted;
                if (!isGranted) {
                  NotificationService().showNotification(
                      title: 'Orders', body: 'Requesting Your Permission');
                }
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (BuildContext) => PermissionsWithAutoStart(
                              fromFirstScreenTrueElseFalse: false,
                            )));
              },
              child: Text(
                'App Permissions',
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
