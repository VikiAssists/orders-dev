import 'dart:collection';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:modal_progress_hud_alt/modal_progress_hud_alt.dart';
import 'package:orders_dev/Providers/notification_provider.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:orders_dev/Screens/chefOrCaptain_5.dart';
import 'package:orders_dev/Screens/permissions_screen.dart';
import 'package:orders_dev/constants.dart';
import 'package:orders_dev/services/background_services.dart';
import 'package:orders_dev/services/firestore_services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class ChooseRestaurant extends StatefulWidget {
  final String userPhoneNumber;
  final String token;
  const ChooseRestaurant(
      {Key? key, required this.userPhoneNumber, required this.token})
      : super(key: key);

  @override
  State<ChooseRestaurant> createState() => _ChooseRestaurantState();
}

class _ChooseRestaurantState extends State<ChooseRestaurant> {
  final _fireStore = FirebaseFirestore.instance;
  List<String> restaurantsNamesToChoose = ['Choose Restaurant'];
  List<String> restaurantsDatabases = [];
  Map<String, dynamic> restaurantNamesDatabase = HashMap();
  String chosenRestaurant = 'Choose Restaurant';

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
  Map<String, dynamic> currentUserCompleteProfile = {};
  Map<String, dynamic> allUserTokens = {};
  Map<String, dynamic> allUserProfiles = {};
  String appVersion = '3.6';

  @override
  void initState() {
    backgroundPermissionsCheck();
    requestLocationPermissionForBluetooth();
    notificationPermissionChecker();
    showSpinner = false;

    // TODO: implement initState
    super.initState();
  }

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

  //ToConvertDynamicListToStringList
  List<String> dynamicTokensToStringToken() {
    List<String> tokensList = [];
    Map<String, dynamic> tempAllUserTokens = allUserTokens;
    tempAllUserTokens.remove(widget.userPhoneNumber);
    for (var tokens in tempAllUserTokens.values) {
      tokensList.add(tokens.toString());
    }
    return tokensList;
  }

  void getHotelBasics(String hotelName) async {
    List<Map<String, dynamic>> items = [];
    //ForAddButtonSkipping
    num priceForTitles = -1;
    List<String> temporaryOrderingString = [];
    List<num> temporaryOrderingNum = [];
    //JustRegisteringThatWeAreNotInsideCaptainScreenInitially
    BackgroundCheck().saveInsideCaptainScreenChangingInBackground(
        insideCaptainScreenTrueElseFalse: false);
    BackgroundCheck().saveInsideChefScreenChangingInBackground(
        insideChefScreenTrueElseFalse: false);

    final userTokensOfTheRestaurant =
        await _fireStore.collection(hotelName).doc('userMessagingTokens').get();
    if (userTokensOfTheRestaurant.data() != null) {
      allUserTokens = userTokensOfTheRestaurant.data()!;
      Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
          .saveAllUserTokens(json.encode(allUserTokens));
    }
//savingCurrentUserPhoneNumberInProvider
    Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
        .saveCurrentUserPhoneNumber(widget.userPhoneNumber);
    final allUserProfileDetailsOfTheRestaurant =
        await _fireStore.collection(hotelName).doc('allUserProfiles').get();
    if (allUserProfileDetailsOfTheRestaurant.data() != null) {
      allUserProfiles = allUserProfileDetailsOfTheRestaurant.data()!;
      Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
          .saveAllUserProfiles(json.encode(allUserProfiles));
    }

    final tableQuery =
        await _fireStore.collection(hotelName).doc('basicinfo').get();

    Map<String, dynamic> restaurantInfoData = tableQuery.data()!;

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

    Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
        .saveRestaurantInfo(json.encode(restaurantInfoData));

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
    num totalNumberInItemsList =
        menuItems.docs.length + menuBase.data()!.length;
    num totalNumberOfItemsCounter = 0;

    for (num key in temporaryOrderingNum) {
//ThisIsToHaveTheMenuTitlesAlongWithTheMenu
      menuTitles.add(menuBase[key.toString()]);
      entireMenuItems.add(menuBase[key.toString()]);
      entireMenuPrice.add(priceForTitles);
      String currentCategory = menuBase[key.toString()];
      items.add({
        'itemName': menuBase[key.toString()],
        'price': -1,
        'variety': key,
        'category': 'title',
      });
      totalNumberOfItemsCounter++;

      for (var menuItem in menuItems.docs) {
//HereIsTheSpotWhereInsteadOfMenuBase[key],,IfWeJustUseKeyWithVarietyNumber,
//WeCanStraightAwayUseVarietyNumberAlone
        if (menuItem['variety'] == key) {
          entireMenuItems.add(menuItem.id);
          entireMenuPrice.add(menuItem['price']);
          items.add({
            'itemName': menuItem.id,
            'price': menuItem['price'],
            'variety': menuItem['variety'],
            'category': currentCategory,
          });
          totalNumberOfItemsCounter++;
        }
      }
      //checkingWhetherWeHaveGotItAll
      if (totalNumberOfItemsCounter == totalNumberInItemsList) {
        Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .savingEntireMenuFromMap(json.encode(items));
      }
    }
    if (widget.token != '') {
      currentUserCompleteProfile.addAll({'token': widget.token});
    }
    if (Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .versionOfAppFromClass !=
        appVersion) {
      FireStoreUpdateAppVersion(
              userPhoneNumber: widget.userPhoneNumber, version: appVersion)
          .updateAppVersion();
      Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
          .saveVersionOfApp(appVersion);
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
      return ChefOrCaptainWithSeparateRestaurantInfo(
        hotelName: hotelName,
        userNumber: '1',
        menuTitles: menuTitles,
        entireMenuItems: entireMenuItems,
        entireMenuPrice: entireMenuPrice,
        allMenuItems: items,
        currentUserProfileMap: currentUserCompleteProfile,
      );
    }));
//JustTryingToSeparateItWithSomethingSoThatThereIsAGapBetweenPushingTheTwoScreens
    if (widget.token != '') {
      print('came inside token update');
      FireStoreUpdateUserToken(
              userPhoneNumber: widget.userPhoneNumber,
              token: widget.token,
              hotelName: hotelName)
          .updateUserToken();

      final fcmProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      fcmProvider.sendNotification(
          token: dynamicTokensToStringToken(),
          title: hotelName,
          restaurantNameForNotification: json.decode(
                  Provider.of<PrinterAndOtherDetailsProvider>(context,
                          listen: false)
                      .allUserProfilesFromClass)[
              Provider.of<PrinterAndOtherDetailsProvider>(context,
                      listen: false)
                  .currentUserPhoneNumberFromClass]['restaurantName'],
          body: '*newUserToken*');
    }
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
  }

  Future show(
    String message, {
    Duration duration: const Duration(seconds: 2),
  }) async {
    await new Future.delayed(new Duration(milliseconds: 100));
    ScaffoldMessenger.of(context).showSnackBar(
      //   behavior: SnackBarBehavior.floating,
      //   margin: EdgeInsets.only(bottom: 400.0, right: 20, left: 20),
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: kSnackbarMessageSize),
        ),
        duration: duration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: kAppBarBackIconColor),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Phoenix.rebirth(context);
              ;
            }),
        backgroundColor: kAppBarBackgroundColor,
        centerTitle: true,
        title: Text(
          'Choose Restaurant',
          style: kAppBarTextStyle,
        ),
      ),
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    child: StreamBuilder<
                            DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('loginDetails')
                            .doc(widget.userPhoneNumber)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
//IfConnectionStateIsWaiting,ThenWePutTheRotatingCircleThatShowsLoadingInTheCenter
                            return const Center(
                              child: CircularProgressIndicator(
                                backgroundColor: Colors.lightBlueAccent,
                              ),
                            );
                          } else if (snapshot.hasError) {
                            //IfThereIsAnError,WeCaptureTheErrorAndPutItInThePage
                            return Center(
                              child: Text(snapshot.error.toString()),
                            );
                          } else if (snapshot.hasData) {
                            if (snapshot.data!.data() == null) {
                              print('came inside null');
                              return const Center(
                                child: Text(
                                  'No Restaurants',
                                  style: TextStyle(fontSize: 30),
                                ),
                              );
                            } else {
                              restaurantsNamesToChoose = ['Choose Restaurant'];
                              restaurantsDatabases = [];
                              restaurantNamesDatabase = {};

                              var output = snapshot.data!.data();
                              currentUserCompleteProfile = output!;
                              currentUserCompleteProfile.addAll({
                                'currentUserPhoneNumber': widget.userPhoneNumber
                              });

                              List<dynamic> restaurantsDatabasesDynamic =
                                  output!['restaurants'];

                              for (var restaurantDatabase
                                  in restaurantsDatabasesDynamic) {
                                restaurantsDatabases
                                    .add(restaurantDatabase.toString());
                                restaurantsNamesToChoose.add(
                                    output[restaurantDatabase]['restaurantName']
                                        .toString());
                                restaurantNamesDatabase.addAll({
                                  output[restaurantDatabase]['restaurantName']
                                      .toString(): restaurantDatabase.toString()
                                });
                              }
                              return Container(
                                alignment: Alignment.center,
                                margin: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    color: Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(10)),
                                width: double.infinity,
                                height: 50,
                                child: DropdownButtonFormField(
                                  decoration:
                                      InputDecoration.collapsed(hintText: ''),
                                  isExpanded: true,
                                  // underline: Container(),
                                  dropdownColor: Colors.green,
                                  value: chosenRestaurant,
                                  onChanged: (value) {
                                    chosenRestaurant = value.toString();
                                  },
                                  items: restaurantsNamesToChoose
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Center(
                                        child: Text(
                                          value,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontSize: 20,
                                              color: Colors.black),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            }
                          } else {
                            return CircularProgressIndicator();
                          }
                        })),
                SizedBox(height: 50),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.green.shade500,
                    borderRadius: BorderRadius.circular(50.0),
                  ),
                  height: 50.0,
                  width: 200.0,
                  child: TextButton(
                    onPressed: () async {
                      if (chosenRestaurant != 'Choose Restaurant') {
                        String hotelName =
                            restaurantNamesDatabase[chosenRestaurant];
                        Provider.of<PrinterAndOtherDetailsProvider>(context,
                                listen: false)
                            .restaurantChosenByUser(hotelName);
                        getHotelBasics(hotelName);
                        setState(() {
                          showSpinner = true;
                        });
                      } else {
                        show('Please Choose a Restaurant');
                      }
                    },
                    child: const Text(
                      'Enter',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 25.0, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
