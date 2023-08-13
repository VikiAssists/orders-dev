import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:orders_dev/Screens/permissions_screen.dart';
import 'package:orders_dev/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'Screens/chefOrCaptain_3.dart';
import 'constants.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modal_progress_hud_alt/modal_progress_hud_alt.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp();
  NotificationService().initNotification();

  runApp(Phoenix(
    child: MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => PrinterAndOtherDetailsProvider())
    ], child: MyApp()),
  ));
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Orders',
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  void initState() {
    // TODO: implement initState
    getCurrentUser();
    backgroundPermissionsCheck();
    requestLocationPermissionForBluetooth();
    notificationPermissionChecker();
    _obscureText = true;
    showSpinner = false;
    // final androidConfig = FlutterBackgroundAndroidConfig(
    //   notificationTitle: "Orders",
    //   notificationText: "We are looking for updates",
    //   notificationImportance: AndroidNotificationImportance.Default,
    //   // notificationIcon: AndroidResource(name: 'background_icon', defType: 'drawable'), // Default is ic_launcher from folder mipmap
    // );
    // FlutterBackground.initialize();
    // // FlutterBackground.disableBackgroundExecution();

    super.initState();
  }

  final _fireStore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  late User loggedInUser;
  String hotelName = '';
  String userNumber = '';
  String username = '';
  String password = '';
  bool _obscureText = true;

  num numberOfTables = 0;
  num cgstPercentage = 0;
  num sgstPercentage = 0;
  String hotelNameForPrint = '';
  String addressLine1ForPrint = '';
  String addressLine2ForPrint = '';
  String addressLine3ForPrint = '';
  String phoneNumberForPrint = '';
  String gstCodeForPrint = '';
  bool hasBackgroundPermissions = true;
  bool locationPermissionAccepted = true;
  bool isNotificationPermissionGranted = true;

  //WhatComesNextIsForAnotherPage
  List<String> menuTitles = ['Browse Menu'];

  List<String> entireMenuItems = [];

  List<num> entireMenuPrice = [];
  bool showSpinner = false;
  List<Map<String, dynamic>> items = []; //allItemsAsMap

  void backgroundPermissionsCheck() async {
    hasBackgroundPermissions = await FlutterBackground.hasPermissions;
    setState(() {
      hasBackgroundPermissions;
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

  Future<void> notificationPermissionChecker() async {
    PermissionStatus? statusNotification =
        await Permission.notification.request();

    isNotificationPermissionGranted =
        statusNotification == PermissionStatus.granted;
    setState(() {
      isNotificationPermissionGranted;
    });
  }

  void getCurrentUser() {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
        String emailOfUser = loggedInUser.email.toString();
        final hotelNameSplit = emailOfUser.split('_');
        // final hotelNameLocationSplit = hotelNameSplit[0].toString().split('-');
        hotelName = hotelNameSplit[0];
        final userNumberSplit = hotelNameSplit[1].split('@');
        userNumber = userNumberSplit[0];
        if (hotelName != '') {
          getHotelBasics();
        }
      } else {
        FlutterNativeSplash.remove();
      }
    } catch (e) {
      //print(e);
    }
  }

  void getHotelBasics() async {
    //ForAddButtonSkipping
    num priceForTitles = -1;
    List<String> temporaryOrderingString = [];
    List<num> temporaryOrderingNum = [];

    final tableQuery =
        await _fireStore.collection(hotelName).doc('basicinfo').get();

//gettingAllDetailsFromDatabase

    cgstPercentage = tableQuery.data()!['cgst'];
    sgstPercentage = tableQuery.data()!['sgst'];
    hotelNameForPrint = tableQuery.data()!['hotelname'];
    numberOfTables = tableQuery.data()!['tables'];
    cgstPercentage = tableQuery.data()!['cgst'];
    sgstPercentage = tableQuery.data()!['sgst'];
    hotelNameForPrint = tableQuery.data()!['hotelname'];
    addressLine1ForPrint = tableQuery.data()!['addressline1'];
    addressLine2ForPrint = tableQuery.data()!['addressline2'];
    addressLine3ForPrint = tableQuery.data()!['addressline3'];
    phoneNumberForPrint = tableQuery.data()!['phonenumber'];
    gstCodeForPrint = tableQuery.data()!['gstcode'];

    //toGetMenuTitles
    final menuBase = await _fireStore.collection(hotelName).doc('menu').get();
//tryingToPutInOrder
    for (num i = 1; i <= menuBase.data()!.length; i++) {
      temporaryOrderingString.add('${i.toString()}');
      temporaryOrderingNum.add(i);
    }
    //toGetMenuItems
    final menuItems = await _fireStore
        .collection(hotelName)
        .doc('menu')
        .collection('menu')
        .get();

    for (num key in temporaryOrderingNum) {
//ThisIsToHaveTheMenuTitlesAlongWithTheMenu
      menuTitles.add(menuBase[key.toString()]);
      entireMenuItems.add(menuBase[key.toString()]);
      entireMenuPrice.add(priceForTitles);

      for (var menuItem in menuItems.docs) {
//HereIsTheSpotWhereInsteadOfMenuBase[key],,IfWeJustUseKeyWithVarietyNumber,
//WeCanStraightAwayUseVarietyNumberAlone
        if (menuItem['variety'] == key) {
          entireMenuItems.add(menuItem.id);
          entireMenuPrice.add(menuItem['price']);
        }
      }
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
      return ChefOrCaptainDeleteTillEnd(
        hotelName: hotelName,
        userNumber: userNumber,
        menuTitles: menuTitles,
        entireMenuItems: entireMenuItems,
        entireMenuPrice: entireMenuPrice,
        numberOfTables: numberOfTables,
        cgstPercentage: cgstPercentage,
        sgstPercentage: sgstPercentage,
        addressLine1ForPrint: addressLine1ForPrint,
        addressLine2ForPrint: addressLine2ForPrint,
        addressLine3ForPrint: addressLine3ForPrint,
        hotelNameForPrint: hotelNameForPrint,
        phoneNumberForPrint: phoneNumberForPrint,
        gstCodeForPrint: gstCodeForPrint,
      );
    }));
    if (locationPermissionAccepted == false ||
        hasBackgroundPermissions == false ||
        isNotificationPermissionGranted == false) {
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
      //   return ChefOrCaptain(
      //     hotelName: hotelName,
      //     userNumber: userNumber,
      //     menuTitles: menuTitles,
      //     entireMenuItems: entireMenuItems,
      //     entireMenuPrice: entireMenuPrice,
      //     numberOfTables: numberOfTables,
      //     cgstPercentage: cgstPercentage,
      //     sgstPercentage: sgstPercentage,
      //     addressLine1ForPrint: addressLine1ForPrint,
      //     addressLine2ForPrint: addressLine2ForPrint,
      //     addressLine3ForPrint: addressLine3ForPrint,
      //     hotelNameForPrint: hotelNameForPrint,
      //     phoneNumberForPrint: phoneNumberForPrint,
      //   );
      // }));
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (BuildContext) => PermissionsApproval(
                    fromFirstScreenTrueElseFalse: true,
                  )));
    }

    FlutterNativeSplash.remove();
  }

  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      //ThisWillHelpToAvoidKeyboardRenderingIssueWheneverKeyboardPopsUp
      appBar: AppBar(
        backgroundColor: kAppBarBackgroundColor,
        title: Center(
            child: Text(
          'Login',
          style: kAppBarTextStyle,
        )),
      ),
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 120.0),
                Container(
                    padding: EdgeInsets.all(20.0),
                    child: TextField(
                      controller: TextEditingController(text: username),
                      onChanged: (value) {
                        username = value;
                      },
                      style: TextStyle(color: Colors.white),
                      decoration: kTextFieldInputDecoration.copyWith(
                          hintText: 'Enter Username'),
                    )),
                Container(
                    padding: EdgeInsets.all(20.0),
                    child: TextField(
                      controller: TextEditingController(text: password),
                      obscureText: _obscureText,
                      onChanged: (value) {
                        password = value;
                      },
                      style: TextStyle(color: Colors.white),
                      decoration: kTextFieldInputDecoration.copyWith(
                          hintText: 'Enter Password'),
                    )),
                TextButton(
                    onPressed: _toggle,
                    child: Text(
                      _obscureText ? "Show Password" : "Hide Password",
                      style: TextStyle(fontSize: 15.0, color: Colors.black87),
                    )),
                SizedBox(
                  height: 10,
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green.shade500,
                    borderRadius: BorderRadius.circular(50.0),
                  ),
                  height: 70.0,
                  width: 140.0,
                  child: TextButton(
                    onPressed: () async {
                      setState(() {
                        showSpinner = true;
                      });
                      //toCloseKeyboardAutomaticallyOnceLoginButtonClicked
                      FocusManager.instance.primaryFocus?.unfocus();

                      String mailId = username + '@email.com';
                      try {
                        final user = await _auth.signInWithEmailAndPassword(
                            email: username + '@email.com', password: password);
                        if (user != null) {
                          String emailOfUser = user.user!.email.toString();
                          final hotelNameSplit = emailOfUser.split('_');
                          hotelName = hotelNameSplit[0];
                          final userNumberSplit = hotelNameSplit[1].split('@');
                          userNumber = userNumberSplit[0];
                          if (hotelName != '') {
                            getHotelBasics();
                          }
                        }
                      } on FirebaseAuthException catch (e) {
                        setState(() {
                          showSpinner = false;
                        });
                        final snackBar = SnackBar(
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.only(
                              bottom: 400.0, right: 20, left: 20),
                          content: Text(e.code.toString()),
                        );

                        // Find the ScaffoldMessenger in the widget tree
                        // and use it to show a SnackBar.
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      }
                    },
                    child: const Text(
                      'Login',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 25.0, color: Colors.white),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
