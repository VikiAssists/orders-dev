import 'dart:async';

import 'package:auto_start_flutter/auto_start_flutter.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:app_settings/app_settings.dart';
import 'package:orders_dev/constants.dart';
import 'package:orders_dev/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionsWithAutoStart extends StatefulWidget {
  final bool fromFirstScreenTrueElseFalse;

  const PermissionsWithAutoStart({
    Key? key,
    required this.fromFirstScreenTrueElseFalse,
  }) : super(key: key);

  @override
  State<PermissionsWithAutoStart> createState() =>
      _PermissionsWithAutoStartState();
}

class _PermissionsWithAutoStartState extends State<PermissionsWithAutoStart> {
  bool hasBackgroundPermissions = true;
  bool locationPermissionAccepted = false;
  bool isNotificationPermissionGranted = false;
  bool autoStartPermission = false;

  void backgroundPermissionsCheck() async {
    hasBackgroundPermissions = await FlutterBackground.hasPermissions;
    setState(() {
      hasBackgroundPermissions;
    });
  }

  void backgroundPermissionsCheckTimer() {
    Timer? _timer;
    int _everySecForBackground = 0;
    _timer = Timer.periodic(Duration(seconds: 1), (_) async {
      if (_everySecForBackground < 10) {
        print('_everySecForBackground $_everySecForBackground');
        _everySecForBackground++;
      } else {
        _timer!.cancel();
        backgroundPermissionsCheck();
      }
    });
  }

  void requestLocationPermissionForBluetooth() async {
    var status = await Permission.locationWhenInUse.status;
    var status1 = await Permission.locationAlways.status;
    var status2 = await Permission.location.status;
    if (status.isDenied && status1.isDenied && status2.isDenied) {
      setState(() {
        locationPermissionAccepted = false;
      });

      print('came into alertdialog loop4');
    } else {
      // bluetoothStateChangeFunction();
      // getAllPairedDevices();
      print('location permission already accepted');
      setState(() {
        locationPermissionAccepted = true;
      });
      // FlutterBackground.initialize();

      // initBluetooth();
    }
    if (status.isGranted) {
      print('location when in use');
    } else {
      print('location when not in use');
    }
    if (status1.isGranted) {
      print('location always');
    } else {
      print('location when not always');
    }
    if (status2.isGranted) {
      print('just location');
    } else {
      print('location when not location');
    }
    print('location permission is $locationPermissionAccepted');
  }

  void requestLocationPermissionForBluetoothTimer() {
    Timer? _timer;
    int _everySecForLocation = 0;
    _timer = Timer.periodic(Duration(seconds: 1), (_) async {
      if (_everySecForLocation < 10) {
        print('_everySecForBackground $_everySecForLocation');
        _everySecForLocation++;
      } else {
        _timer!.cancel();
        requestLocationPermissionForBluetooth();
      }
    });
  }

  Future<void> notificationPermissionChecker() async {
    PermissionStatus? statusNotification =
        await Permission.notification.request();

    isNotificationPermissionGranted =
        statusNotification == PermissionStatus.granted;
    setState(() {
      isNotificationPermissionGranted;
    });
  }

  void notificationPermissionCheckerTimer() {
    Timer? _timer;
    int _everySecForNotification = 0;
    _timer = Timer.periodic(Duration(seconds: 1), (_) async {
      if (_everySecForNotification < 10) {
        print('_everySecForBackground $_everySecForNotification');
        _everySecForNotification++;
      } else {
        _timer!.cancel();
        notificationPermissionChecker();
      }
    });
  }

  void notificationPermissionCheckerTimerFourSec() {
    Timer? _timer;
    int _everySecForNotification = 0;
    _timer = Timer.periodic(Duration(seconds: 1), (_) async {
      if (_everySecForNotification < 4) {
        print('_everySecForBackground $_everySecForNotification');
        _everySecForNotification++;
      } else {
        _timer!.cancel();
        notificationPermissionChecker();
      }
    });
  }

  Future<void> initAutoStart() async {
    try {
      //check auto-start availability.
      var autoStartTest = await (isAutoStartAvailable as Future<bool?>);
      if (autoStartTest == true) {
        setState(() {
          autoStartPermission = true;
        });
      }

      print('autoStartTest');
      print(autoStartTest);
      print(autoStartPermission);
      //if available then navigate to auto-start setting page.
      // if (autoStartTest) await getAutoStartPermission();
    } on PlatformException catch (e) {
      print('inside exception');
      print(e);
    }
    if (!mounted) return;
  }

  @override
  void initState() {
    // TODO: implement initState
    initAutoStart();
    backgroundPermissionsCheck();
    requestLocationPermissionForBluetooth();
    notificationPermissionChecker();
    notificationPermissionCheckerTimerFourSec();
    alertDialogForPermissionsScreenTimerOneSec();

    super.initState();
  }

  // Future<void> alertDialogForPermissionsScreen() async {
  //   bool fromFirstScreenTrueOrFalse = widget.fromFirstScreenTrueElseFalse;
  //   if (widget.fromFirstScreenTrueElseFalse) {
  //     print('came in123');
  //     DDialog(
  //       context: context,
  //       builder: (BuildContext context) => AlertDialog(
  //         elevation: 24.0,
  //         // backgroundColor: Colors.greenAccent,
  //         // shape: CircleBorder(),
  //         title: Text('Permissions'),
  //         content: Text(
  //             'Orders App needs some permissions for smooth functioning. Press Yes to go to the Permission Screen'),
  //         actions: [
  //           Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //             children: [
  //               ElevatedButton(
  //                 style: ButtonStyle(
  //                   backgroundColor:
  //                       MaterialStateProperty.all<Color>(Colors.grey),
  //                 ),
  //                 child: Text('No'),
  //                 onPressed: () {
  //                   int count = 0;
  //                   Navigator.of(context).popUntil((_) => count++ >= 2);
  //                 },
  //               ),
  //               ElevatedButton(
  //                 style: ButtonStyle(
  //                   backgroundColor:
  //                       MaterialStateProperty.all<Color>(Colors.green),
  //                 ),
  //                 child: Text('Yes'),
  //                 onPressed: () async {
  //                   Navigator.pop(context);
  //                   PermissionStatus? statusNotification =
  //                       await Permission.notification.request();
  //
  //                   bool isGranted =
  //                       statusNotification == PermissionStatus.granted;
  //                   if (!isGranted) {
  //                     NotificationService().showNotification(
  //                         title: 'Orders', body: 'Requesting Your Permission');
  //                   }
  //                 },
  //               ),
  //             ],
  //           )
  //         ],
  //       ),
  //       barrierDismissible: false,
  //     );
  //   }
  // }

  void alertDialogForPermissionsScreenTimerOneSec() {
    Timer? _timer;
    int _everySecForAlert = 0;
    _timer = Timer.periodic(Duration(milliseconds: 500), (_) async {
      if (_everySecForAlert < 1) {
        print('_everySecForBackground $_everySecForAlert');
        _everySecForAlert++;
      } else {
        _timer!.cancel();
        // notificationPermissionChecker();
        if (widget.fromFirstScreenTrueElseFalse) {
          print('came in123');
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              elevation: 24.0,
              // backgroundColor: Colors.greenAccent,
              // shape: CircleBorder(),
              title: Text('Permissions'),
              content: Text(
                  'Orders App needs some permissions for smooth functioning. Press Yes to continue in Permission Screen'),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.grey),
                      ),
                      child: Text('No'),
                      onPressed: () {
                        // Navigator.pop(context);
                        // Navigator.pop(context);
                        int count = 0;
                        Navigator.of(context).popUntil((_) => count++ >= 2);
                      },
                    ),
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.green),
                      ),
                      child: Text('Yes'),
                      onPressed: () async {
                        Navigator.pop(context);
                        PermissionStatus? statusNotification =
                            await Permission.notification.request();

                        bool isGranted =
                            statusNotification == PermissionStatus.granted;
                        if (!isGranted) {
                          NotificationService().showNotification(
                              title: 'Orders',
                              body: 'Requesting Your Permission');
                          notificationPermissionCheckerTimerFourSec();
                        }
                      },
                    ),
                  ],
                )
              ],
            ),
            barrierDismissible: false,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kAppBarBackgroundColor,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kAppBarBackIconColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Permissions',
          style: kAppBarTextStyle,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 10),
            ListTile(
              // tileColor: hasBackgroundPermissions ? Colors.green : Colors.red,
              leading: const Icon(Icons.battery_charging_full_rounded),
              title: Text(
                'Battery Settings',
                style: Theme.of(context).textTheme.headline6,
              ),
              subtitle: Text(
                'Please Remove Battery Restrictions to check for new customer orders in background state',
                style: TextStyle(fontSize: 15),
              ),
              trailing: Switch(
                value: hasBackgroundPermissions,
                activeColor: Colors.green,
                onChanged: (bool changedValue) {
                  if (hasBackgroundPermissions == false) {
                    setState(() {
                      hasBackgroundPermissions = changedValue;
                    });
                    FlutterBackground.initialize();
                    backgroundPermissionsCheckTimer();
                  }
                },
              ),
            ),
            const Divider(color: Colors.black54),
            ListTile(
              leading: const Icon(Icons.circle_notifications_rounded),
              title: Text(
                'Notification Permissions',
                style: Theme.of(context).textTheme.headline6,
              ),
              subtitle: Text(
                'Please allow Orders to update you with customer order notifications',
                style: TextStyle(fontSize: 15),
              ),
              trailing: Switch(
                value: isNotificationPermissionGranted,
                activeColor: Colors.green,
                onChanged: (bool changedValue) {
                  if (isNotificationPermissionGranted == false) {
                    setState(() {
                      isNotificationPermissionGranted = changedValue;
                    });
                    AppSettings.openNotificationSettings();
                    notificationPermissionCheckerTimer();
                  }
                },
              ),
              // onTap: () {
              //   if (!isGranted) {
              //     NotificationService().showNotification(
              //         title: 'Orders',
              //         body: 'Requesting Your Permission for Notification');
              //   }
              // },
            ),

            const Divider(color: Colors.black54),
            ListTile(
              // tileColor:
              //     locationPermissionAccepted ? Colors.green : Colors.red,
              leading: const Icon(Icons.add_location_alt_rounded),
              title: Text(
                'Bluetooth Printer Settings',
                style: Theme.of(context).textTheme.headline6,
              ),
              subtitle: Text(
                'Please allow location permission to allow Orders App to access bluetooth Printer',
                style: TextStyle(fontSize: 15),
              ),
              trailing: Switch(
                value: locationPermissionAccepted,
                activeColor: Colors.green,
                onChanged: (bool changedValue) {
                  if (locationPermissionAccepted == false) {
                    setState(() {
                      locationPermissionAccepted = true;
                    });
                    showDialog(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        elevation: 24.0,
                        // backgroundColor: Colors.greenAccent,
                        // shape: CircleBorder(),
                        title: Text('Permission for Location Use'),
                        content: Text(
                            'Orders App collects location data only to connect and print through a bluetooth printer even when the app is in background. This information will not be collected when the app is closed. This information will not be used for any advertisement purposes. Kindly allow location access when prompted'),
                        actions: [
                          TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() {
                                  locationPermissionAccepted = true;
                                });
                                BlueThermalPrinter bluetooth =
                                    BlueThermalPrinter.instance;
                                // await bluetooth.getBondedDevices();
                                bluetooth.getBondedDevices();
                                requestLocationPermissionForBluetoothTimer();
                                print('came till this pop1');
                              },
                              child: Text('Ok'))
                        ],
                      ),
                      barrierDismissible: false,
                    );
                  }
                  // requestLocationPermissionForBluetoothTimer();
                },
              ),
              // onTap: () {
              //   showDialog(
              //     context: context,
              //     builder: (BuildContext context) => AlertDialog(
              //       elevation: 24.0,
              //       // backgroundColor: Colors.greenAccent,
              //       // shape: CircleBorder(),
              //       title: Text('Permission for Location Use'),
              //       content: Text(
              //           'Orders App collects location data only to connect and print through a bluetooth printer even when the app is in background. This information will not be collected when the app is closed. This information will not be used for any advertisement purposes. Kindly allow location access when prompted'),
              //       actions: [
              //         TextButton(
              //             onPressed: () {
              //               Navigator.pop(context);
              //               setState(() {
              //                 locationPermissionAccepted = true;
              //               });
              //               BlueThermalPrinter bluetooth =
              //                   BlueThermalPrinter.instance;
              //               // await bluetooth.getBondedDevices();
              //               bluetooth.getBondedDevices();
              //
              //               print('came till this pop1');
              //             },
              //             child: Text('Ok'))
              //       ],
              //     ),
              //     barrierDismissible: false,
              //   );
              // },
            ),
            const Divider(color: Colors.black54),
            autoStartPermission
                ? ListTile(
                    // tileColor:
                    //     locationPermissionAccepted ? Colors.green : Colors.red,
                    leading: const Icon(Icons.start_rounded),
                    title: Text(
                      'Auto-Start Settings',
                      style: Theme.of(context).textTheme.headline6,
                    ),
                    subtitle: Text(
                      'Please TAP and enable Auto-Start permission\nPlease note that this feature will not be available in some devices',
                      style: TextStyle(fontSize: 15),
                    ),
                    onTap: () async {
                      print('tapped This');
                      await getAutoStartPermission();
                    },
                  )
                : SizedBox.shrink(),
            autoStartPermission
                ? const Divider(color: Colors.black54)
                : SizedBox.shrink(),
            // ListTile(
            //   leading: const Icon(Icons.mail_lock),
            //   title: Text(
            //     'Tap to Allow Lock Screen Notifications',
            //     style: Theme.of(context).textTheme.headline6,
            //   ),
            //   subtitle: Text(
            //       'Please allow Orders to show customer order notifications on lock screen',
            //       style: TextStyle(fontSize: 15)),
            //   onTap: () {
            //     AppSettings.openNotificationSettings();
            //   },
            // ),
            // const Divider(color: Colors.black54),
          ],
        ),
      ),
      persistentFooterButtons: [
        Center(
          child: Text(
              '             To revert the permissions, please go to \n mobile Settings --> Apps --> Orders --> Permissions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              )),
        )
      ],
    );
  }
}
