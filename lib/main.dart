import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:orders_dev/Providers/notification_provider.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:orders_dev/Screens/chefOrCaptain_3.dart';
import 'package:orders_dev/Screens/chefOrCaptain_5.dart';
import 'package:orders_dev/Screens/choose_restaurant_screen_1.dart';
import 'package:orders_dev/Screens/permissions_screen.dart';
import 'package:orders_dev/Screens/permissions_screen_3.dart';
import 'package:orders_dev/services/background_services.dart';
import 'package:orders_dev/services/firestore_services.dart';
import 'package:orders_dev/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'constants.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modal_progress_hud_alt/modal_progress_hud_alt.dart';
import 'package:pinput/pinput.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await Firebase.initializeApp();

  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('message in foreground in main screen');
    print(message.data);
  });

  NotificationService().initNotification();

  runApp(Phoenix(
    child: MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) => PrinterAndOtherDetailsProvider()),
      ChangeNotifierProvider(create: (_) => NotificationProvider()),
    ], child: MyApp()),
  ));
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  print('Handling a background message ${message.messageId}');

  if (message.data['body'].toString().split('*')[1] == 'newUserToken') {
    BackgroundCheck().saveTokenNumberUpdateInBackground(
        hotelNameOfMessage: message.data['title'].toString(),
        tokenUpdatedTrueNotedFalse: true);
  }

  if (message.data['body'].toString().split('*')[1] == 'userDeleted') {
    BackgroundCheck().saveUserDeletedInBackground(
        hotelNameOfMessage: message.data['title'].toString(),
        userDeletedTrueNotedFalse: true);
  }

  if (message.data['body'].toString().split('*')[1] == 'menuUpdated') {
    BackgroundCheck().saveMenuUpdateInBackground(
        hotelNameOfMessage: message.data['title'].toString(),
        menuUpdatedTrueNotedFalse: true);
  }

  if (message.data['body'].toString().split('*')[1] ==
      'restaurantInfoUpdated') {
    BackgroundCheck().saveRestaurantInfoUpdateInBackground(
        hotelNameOfMessage: message.data['title'].toString(),
        restaurantInfoUpdatedTrueNotedFalse: true);
  }

  if (message.data['body'].toString().split('*')[1] == 'userProfileEdited') {
    BackgroundCheck().saveProfileUpdateInBackground(
        hotelNameOfMessage: message.data['title'].toString(),
        profileUpdatedTrueNotedFalse: true);
  }

  // if (message.data['body'].toString().split('*')[1] ==
  //     'itemReadyRejectedCaptainAlert') {
  //   BackgroundCheck().captainAlertsCheckInBackground(
  //       hotelNameOfMessage: message.data['title'].toString());
  // }
  // if (message.data['body'].toString().split('*')[1] == 'newOrderForCook') {
  //   BackgroundCheck().chefAlertsCheckInBackground(
  //       hotelNameOfMessage: message.data['title'].toString());
  // }
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

class _LoginPageState extends State<LoginPage> with WidgetsBindingObserver {
  @override
  void initState() {
    // TODO: implement initState
    WidgetsBinding.instance.addObserver(this);
    getCurrentUser();
    // backgroundPermissionsCheck();
    requestLocationPermissionForBluetooth();
    notificationPermissionChecker();
    _obscureText = true;
    showSpinner = false;
    captchaVerificationScreen = false;

    //foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('message in foreground login screen');
      print(message.data);

      if (message.data['title'].toString() ==
              Provider.of<PrinterAndOtherDetailsProvider>(context,
                      listen: false)
                  .chosenRestaurantDatabaseFromClass &&
          message.data['body'].toString().split('*')[1] ==
              'userProfileEdited') {
        someUserProfileChanged();
      }

      if (message.data['title'].toString() ==
              Provider.of<PrinterAndOtherDetailsProvider>(context,
                      listen: false)
                  .chosenRestaurantDatabaseFromClass &&
          message.data['body'].toString().split('*')[1] == 'newUserToken') {
        someUserTokenUpdated();
      }
      if (message.data['title'].toString() ==
              Provider.of<PrinterAndOtherDetailsProvider>(context,
                      listen: false)
                  .chosenRestaurantDatabaseFromClass &&
          message.data['body'].toString().split('*')[1] == 'userDeleted') {
        Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .restaurantChosenByUser('');
        Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .chefVideoInstructionLookedOrNot(false);
        Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .captainInsideTableVideoInstructionLookedOrNot(false);
        Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .restaurantChosenByUser('');
        BackgroundCheck().saveUserDeletedInBackground(
            hotelNameOfMessage: message.data['title'].toString(),
            userDeletedTrueNotedFalse: false);
        FirebaseAuth.instance.signOut();
        Phoenix.rebirth(context);
      }
      if (message.data['title'].toString() ==
              Provider.of<PrinterAndOtherDetailsProvider>(context,
                      listen: false)
                  .chosenRestaurantDatabaseFromClass &&
          message.data['body'].toString().split('*')[1] == 'menuUpdated') {
        menuUpdated();
      }
      if (message.data['title'].toString() ==
              Provider.of<PrinterAndOtherDetailsProvider>(context,
                      listen: false)
                  .chosenRestaurantDatabaseFromClass &&
          message.data['body'].toString().split('*')[1] ==
              'restaurantInfoUpdated') {
        restaurantInfoUpdated();
      }
    });
    super.initState();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    // TODO: implement didChangeAppLifecycleState

    // if (state == AppLifecycleState.inactive ||
    //     state == AppLifecycleState.detached) return;

    final isBackground = state == AppLifecycleState.paused;
    final isBackground2 = state == AppLifecycleState.inactive;
    final isBackground3 = state == AppLifecycleState.detached;
    final isForeground = state == AppLifecycleState.resumed;

//WhenWeAreClosingTheApp
    if (isBackground3) {
//EnsuringThatWeAreRegisteringThatTheAppIsNotInChef/CaptainScreen
//       BackgroundCheck().saveInsideCaptainScreenChangingInBackground(
//           insideCaptainScreenTrueElseFalse: false);
      // BackgroundCheck().saveInsideChefScreenChangingInBackground(
      //     insideChefScreenTrueElseFalse: false);
    }

    if (isForeground) {
      if (await BackgroundCheck()
          .returnTokenNumberChangedFromBackgroundClass()) {
        someUserTokenUpdated();
      }
      if (await BackgroundCheck().returnProfileChangedFromBackgroundClass()) {
        someUserProfileChanged();
      }
      if (await BackgroundCheck().returnMenuChangedFromBackgroundClass()) {
        menuUpdated();
      }
      if (await BackgroundCheck()
          .returnRestaurantInfoChangedFromBackgroundClass()) {
        restaurantInfoUpdated();
      }
    }

    super.didChangeAppLifecycleState(state);
  }

  void someUserProfileChanged() async {
    final allUserProfileDetailsOfTheRestaurant = await FirebaseFirestore
        .instance
        .collection(
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .chosenRestaurantDatabaseFromClass)
        .doc('allUserProfiles')
        .get();
    if (allUserProfileDetailsOfTheRestaurant.data() != null) {
      allUserProfiles = allUserProfileDetailsOfTheRestaurant.data()!;
      Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
          .saveAllUserProfiles(json.encode(allUserProfiles));
      //EnsuringTheUsersAreStillExistingForKot
      downloadingPrinterDataAndAlsoCheckingExistenceOfUsersNeedingKot();
    }

    BackgroundCheck().saveProfileUpdateInBackground(
        hotelNameOfMessage:
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .chosenRestaurantDatabaseFromClass,
        profileUpdatedTrueNotedFalse: false);
  }

  void someUserTokenUpdated() async {
    final userTokensOfTheRestaurant = await FirebaseFirestore.instance
        .collection(
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .chosenRestaurantDatabaseFromClass)
        .doc('userMessagingTokens')
        .get();
    if (userTokensOfTheRestaurant.data() != null) {
      var allUserTokensTemp = userTokensOfTheRestaurant.data()!;
      Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
          .saveAllUserTokens(json.encode(allUserTokensTemp));
    }
    BackgroundCheck().saveTokenNumberUpdateInBackground(
        hotelNameOfMessage:
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .chosenRestaurantDatabaseFromClass,
        tokenUpdatedTrueNotedFalse: false);
  }

  void menuUpdated() async {
    items = [];
    List<String> temporaryOrderingString = [];
    List<num> temporaryOrderingNum = [];
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

    BackgroundCheck().saveMenuUpdateInBackground(
        hotelNameOfMessage:
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .chosenRestaurantDatabaseFromClass,
        menuUpdatedTrueNotedFalse: false);
  }

  void restaurantInfoUpdated() async {
    final tableQuery =
        await _fireStore.collection(hotelName).doc('basicinfo').get();

    Map<String, dynamic> restaurantInfoData = tableQuery.data()!;

    // if (tableQuery.data()!['updateTimes'] != null) {
    //   restaurantInfoData.remove('updateTimes');
    //   Map<String, dynamic> updateTimes = tableQuery.data()!['updateTimes'];
    //   Map<String, int> tempEachUpdateTime = HashMap();
    //   updateTimes.forEach((key, value) {
    //     Timestamp eachUpdateTimeStamp = value;
    //     tempEachUpdateTime
    //         .addAll({key: eachUpdateTimeStamp.millisecondsSinceEpoch});
    //   });
    //   restaurantInfoData.addAll({'updateTimes': tempEachUpdateTime});
    // }

    Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
        .saveRestaurantInfo(json.encode(restaurantInfoData));
    BackgroundCheck().saveRestaurantInfoUpdateInBackground(
        hotelNameOfMessage:
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .chosenRestaurantDatabaseFromClass,
        restaurantInfoUpdatedTrueNotedFalse: false);
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
  // bool hasBackgroundPermissions = true;
  bool locationPermissionAccepted = true;
  bool isNotificationPermissionGranted = true;
  String appVersion = '3.19.31';

  //WhatComesNextIsForAnotherPage
  List<String> menuTitles = ['Browse Menu'];

  List<String> entireMenuItems = [];

  List<num> entireMenuPrice = [];
  bool showSpinner = false;
  List<Map<String, dynamic>> items = []; //allItemsAsMap
  var receivedID = '';
  bool otpSent = false;
  bool manuallyOtpEntered = false;
  String userPhoneNumber = '';
  String otp = '';
  String token = '';
  Map<String, dynamic> currentUserCompleteProfile = {};
  Map<String, dynamic> allUserTokens = {};
  Map<String, dynamic> allUserProfiles = {};
  bool captchaVerificationScreen = false;

  Future<void> getToken(
      bool switchToChooseRestaurantScreenTrueElseFalse) async {
    final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
    await firebaseMessaging.getToken().then((value) {
      token = value.toString();
      if (switchToChooseRestaurantScreenTrueElseFalse) {
        setState(() {
          showSpinner = false;
          otpSent = false;
        });
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return ChooseRestaurant(
            userPhoneNumber: userPhoneNumber,
            token: token,
          );
        }));
        FlutterNativeSplash.remove();
      }
    });
  }

  Future show(
    String message, {
    Duration duration: const Duration(seconds: 3),
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

  // void backgroundPermissionsCheck() async {
  //   hasBackgroundPermissions = await FlutterBackground.hasPermissions;
  //   setState(() {
  //     hasBackgroundPermissions;
  //   });
  // }

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

  void getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
        if (user.email != null && user.email.toString() != '') {
          print(user.email);
          print(user.email.toString());
//loopWasMadeForMigrationFromEmailToPhoneNumber
          print('came inside signing out');
          await _auth.signOut();
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (Buildcontext) => LoginPage()));
          Phoenix.rebirth(context);
        } else {
          userPhoneNumber = user.phoneNumber.toString();
          if (userPhoneNumber != '') {
            getUserInfoBasics();
          }
        }

        // if (hotelName != '') {
        //   getHotelBasics();
        // }
      } else {
        FlutterNativeSplash.remove();
      }
    } catch (e) {
      //print(e);
    }
  }

  void verifyUserPhoneNumber(String phoneNumberForOtp) {
    manuallyOtpEntered = false;
    _auth.verifyPhoneNumber(
      phoneNumber: phoneNumberForOtp,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential).then(
              (value) => print('Logged In Successfully'),
            );
      },
      verificationFailed: (FirebaseAuthException e) {
        print('${e.toString()}');
        setState(() {
          print('captchaVerificationScreen3');
          captchaVerificationScreen = false;
          showSpinner = false;
          otpSent = false;
        });
        show('${e.code.toString()}');
      },
      codeSent: (String verificationId, int? resendToken) {
        setState(() {
          print('captchaVerificationScreen2');
          captchaVerificationScreen = false;
          showSpinner = false;
        });
        receivedID = verificationId;
        // otpFieldVisibility = true;
        // setState(() {});
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
    _auth.authStateChanges().listen((User? user) {
      if (user != null && (manuallyOtpEntered == false)) {
//ThisMeansThatTheUserHasHimselfEnteredTheOTP
        setState(() {
          showSpinner = true;
        });
        getUserInfoBasics();
      }
    });
  }

  Future<void> verifyOTPCode(String otp) async {
    manuallyOtpEntered = true;
    setState(() {
      showSpinner = true;
    });
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: receivedID,
        smsCode: otp,
      );
      await _auth.signInWithCredential(credential).then((value) {
        getUserInfoBasics();
      });
    } on FirebaseAuthException catch (error) {
      setState(() {
        showSpinner = false;
      });
      show(error.code.toString());
    }
  }

  void getUserInfoBasics() async {
    if (Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .chosenRestaurantDatabaseFromClass ==
        '') {
      getToken(false);
    }

    if (showSpinner == false) {
      setState(() {
        showSpinner = true;
      });
    }

    userNumber = '1';
//JustRegisteringThatWeAreNotInsideCaptainScreenInitially
//     BackgroundCheck().saveInsideCaptainScreenChangingInBackground(
//         insideCaptainScreenTrueElseFalse: false);
    // BackgroundCheck().saveInsideChefScreenChangingInBackground(
    //     insideChefScreenTrueElseFalse: false);

    String tempHotelName =
        Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .chosenRestaurantDatabaseFromClass;

    final userInfoQuery =
        await _fireStore.collection('loginDetails').doc(userPhoneNumber).get();

    if (userInfoQuery.data() == null) {
//ThisIsIfWeHaveNoRecordOfTheUserAndHeIsSigningInFirstTime
//WeGetHisTokenAndThenGoIntoRestaurantsSelectionPage
      getToken(true);
    } else {
//EntireProfileOfTheCurrentUser.
//WillBeUsefulInCaseWeHaveToSwitchRestaurantsToo
      currentUserCompleteProfile = userInfoQuery.data()!;
      currentUserCompleteProfile
          .addAll({'currentUserPhoneNumber': userPhoneNumber});
//tryingToSwitchToMapForRestaurants
//       List<dynamic> restaurantsUserHasAccess = userInfoQuery['restaurants'];
      List<String> restaurantsUserHasAccess = [];
      Map<String, dynamic> restaurantsList =
          userInfoQuery['restaurantDatabase'];
      restaurantsList.forEach((key, value) {
        restaurantsUserHasAccess.add(key.toString());
      });
      if (restaurantsUserHasAccess.length == 1) {
        hotelName = restaurantsUserHasAccess[0].toString();
        BackgroundCheck().saveHotelNameInBackground(hotelName);
        //ThisIsWhenSomeOneIsSigningInWithOTP(NotAutoSigningInAsCurrentUser)
//RememberThatWhenUserIsSigningInFirstTime,HisOwnTokenWontBeThereAlreadyInThe
//InTheUserInfoQuery.IfTheCurrentUser'sTokenIsAlsoNeededForTheSameCurrentUser
//EnsureToAddItToTheMapInUserInfoQuery

        if (token != '') {
          FireStoreUpdateUserToken(
                  userPhoneNumber: userPhoneNumber,
                  token: token,
                  hotelName: hotelName)
              .updateUserToken();
//ThisTokenAddingWillBeApplicableIfUserIsSigningInBecauseAtThatTime
//WeHaveAlreadyTakenUserDataFromFireStore(WhichShopOwnerWouldHaveMade)
//AndThatWouldntHaveToken
//SoWeSaveTheTokenHere
          currentUserCompleteProfile.addAll({'token': token});
        }
        getHotelBasics();
      } else if (restaurantsUserHasAccess.contains(
          Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .chosenRestaurantDatabaseFromClass)) {
        hotelName =
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .chosenRestaurantDatabaseFromClass;
        BackgroundCheck().saveHotelNameInBackground(hotelName);

        if (token != '') {
          FireStoreUpdateUserToken(
                  userPhoneNumber: userPhoneNumber,
                  token: token,
                  hotelName: hotelName)
              .updateUserToken();
//ThisTokenAddingWillBeApplicableIfUserIsSigningInBecauseAtThatTime
//WeHaveAlreadyTakenUserDataFromFireStore(WhichShopOwnerWouldHaveMade)
//AndThatWouldntHaveToken
//SoWeSaveTheTokenHere
          currentUserCompleteProfile.addAll({'token': token});
        }
        getHotelBasics();
      } else {
        setState(() {
          showSpinner = false;
          otpSent = false;
        });
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return ChooseRestaurant(
              userPhoneNumber: userPhoneNumber, token: token);
        }));
        FlutterNativeSplash.remove();
      }
    }
  }

  //ToConvertDynamicListToStringList
  List<String> dynamicTokensToStringToken() {
    List<String> tokensList = [];
    Map<String, dynamic> tempAllUserTokens = allUserTokens;
    tempAllUserTokens.remove(userPhoneNumber);
    for (var tokens in tempAllUserTokens.values) {
      tokensList.add(tokens.toString());
    }
    return tokensList;
  }

  void getHotelBasics() async {
    List<Map<String, dynamic>> items = [];
    //ForAddButtonSkipping
    num priceForTitles = -1;
    List<String> temporaryOrderingString = [];
    List<num> temporaryOrderingNum = [];

    final userTokensOfTheRestaurant =
        await _fireStore.collection(hotelName).doc('userMessagingTokens').get();
    if (userTokensOfTheRestaurant.data() != null) {
      allUserTokens = userTokensOfTheRestaurant.data()!;
      Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
          .saveAllUserTokens(json.encode(allUserTokens));
    }
//savingCurrentUserPhoneNumberInProvider
    Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
        .saveCurrentUserPhoneNumber(userPhoneNumber);

    final allUserProfileDetailsOfTheRestaurant =
        await _fireStore.collection(hotelName).doc('allUserProfiles').get();
    if (allUserProfileDetailsOfTheRestaurant.data() != null) {
      allUserProfiles = allUserProfileDetailsOfTheRestaurant.data()!;
      Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
          .saveAllUserProfiles(json.encode(allUserProfiles));
      downloadingPrinterDataAndAlsoCheckingExistenceOfUsersNeedingKot();
//ThisCanBeRemovedOnceWeAreSureAllUsersHaveUpdated
      removableOneOldPrinterToNewPrinterCopy();
    }

    final tableQuery =
        await _fireStore.collection(hotelName).doc('basicinfo').get();

    Map<String, dynamic> restaurantInfoData = tableQuery.data()!;
    numberOfTables = tableQuery.data()!['tables'];
    cgstPercentage = tableQuery.data()!['cgst'];
    sgstPercentage = tableQuery.data()!['sgst'];
    hotelNameForPrint = tableQuery.data()!['hotelname'];
    addressLine1ForPrint = tableQuery.data()!['addressline1'];
    addressLine2ForPrint = tableQuery.data()!['addressline2'];
    addressLine3ForPrint = tableQuery.data()!['addressline3'];
    phoneNumberForPrint = tableQuery.data()!['phonenumber'];
    gstCodeForPrint = tableQuery.data()!['gstcode'];
    // if (tableQuery.data()!['updateTimes'] != null) {
    //   restaurantInfoData.remove('updateTimes');
    //   Map<String, dynamic> updateTimes = tableQuery.data()!['updateTimes'];
    //   Map<String, int> tempEachUpdateTime = HashMap();
    //   updateTimes.forEach((key, value) {
    //     Timestamp eachUpdateTimeStamp = value;
    //     tempEachUpdateTime
    //         .addAll({key: eachUpdateTimeStamp.millisecondsSinceEpoch});
    //   });
    //   restaurantInfoData.addAll({'updateTimes': tempEachUpdateTime});
    // }

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
    if (Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .versionOfAppFromClass !=
        appVersion) {
      FireStoreUpdateAppVersion(
              userPhoneNumber: userPhoneNumber, version: appVersion)
          .updateAppVersion();
      Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
          .saveVersionOfApp(appVersion);
    }
    if (currentUserCompleteProfile[hotelName]['privileges']['30'] == true) {
      setState(() {
        showSpinner = false;
        otpSent = false;
      });
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return ChefOrCaptainWithSeparateRestaurantInfo(
          hotelName: hotelName,
          userNumber: userNumber,
          menuTitles: menuTitles,
          entireMenuItems: entireMenuItems,
          entireMenuPrice: entireMenuPrice,
          allMenuItems: items,
          currentUserProfileMap: currentUserCompleteProfile,
        );
      }));
    } else {
      setState(() {
        showSpinner = false;
        otpSent = false;
      });
      Navigator.push(context, MaterialPageRoute(builder: (context) {
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
    }

    if (token != '') {
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
        // hasBackgroundPermissions == false ||
        isNotificationPermissionGranted == false) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (BuildContext) => PermissionsWithNewPrinterPackage(
                    fromFirstScreenTrueElseFalse: true,
                  )));
    }
    FlutterNativeSplash.remove();
  }

  void downloadingPrinterDataAndAlsoCheckingExistenceOfUsersNeedingKot() {
    if (allUserProfiles[userPhoneNumber]['printerSavingMap'] != null) {
      Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
          .savingPrintersAddedByTheUser(
              allUserProfiles[userPhoneNumber]['printerSavingMap']);
    }
    if (allUserProfiles[userPhoneNumber]['billingPrinterAssigningMap'] !=
        null) {
      Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
          .savingBillingAssignedPrinterByTheUser(
              allUserProfiles[userPhoneNumber]['billingPrinterAssigningMap']);
    }
    if (allUserProfiles[userPhoneNumber]['chefPrinterAssigningMap'] != null) {
      Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
          .savingChefAssignedPrinterByTheUser(
              allUserProfiles[userPhoneNumber]['chefPrinterAssigningMap']);
    }
    if (allUserProfiles[userPhoneNumber]['kotPrinterAssigningMap'] != null) {
//IfNothingHasBeenAssignedForKotYet
      if (allUserProfiles[userPhoneNumber]['kotPrinterAssigningMap'] == '{}') {
        Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .savingKotAssignedPrinterByTheUser(
                allUserProfiles[userPhoneNumber]['kotPrinterAssigningMap']);
      } else {
//ifItHasBeenAssigned,WeNeedToCheckWhetherTheUsersStillExist
        Map<String, dynamic> kotPrinterAssigningMap = HashMap();
        bool usersAssignedToKotPrintersHaveChanged = false;
        Map<String, dynamic> tempKotPrinterAssigningMap = json
            .decode(allUserProfiles[userPhoneNumber]['kotPrinterAssigningMap']);
        tempKotPrinterAssigningMap.forEach((key, value) {
//keyIsPrinterIdHere
//ValuesContainsMap,AsOfNotOnlyOfUsersAndTheCopiesTheyNeed
          Map<String, dynamic> serverEachPrinterValueOfAllUsers =
              value['users'];
          Map<String, dynamic> eachPrinterMapToUpdateAfterCheck = HashMap();
//ToGetOnlyTheUserPhoneNumber
          List<dynamic> userPhoneNumbersThatNeedKot =
              serverEachPrinterValueOfAllUsers.keys.toList();
          for (var eachUserPhoneNumber in userPhoneNumbersThatNeedKot) {
            if (allUserProfiles.containsKey(eachUserPhoneNumber)) {
//ThisMeansThatTheUserStillExistsAndWeAddTheServerMapValueOfTheUserInTheBelowMap
              eachPrinterMapToUpdateAfterCheck.addAll(
                  {eachUserPhoneNumber: value['users'][eachUserPhoneNumber]});
            } else {
//IfUserIsNotExistingWeNeedToChangeTheDataInServerToo.HenceChangingBool
              usersAssignedToKotPrintersHaveChanged = true;
            }
          }
          kotPrinterAssigningMap.addAll({
            key: {'users': eachPrinterMapToUpdateAfterCheck}
          });
        });
        Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .savingKotAssignedPrinterByTheUser(
                json.encode(kotPrinterAssigningMap));
        if (usersAssignedToKotPrintersHaveChanged) {
//SinceUsersHaveChanged,WeWillNeedToUpdateInServer
          FireStorePrintersInformation(
                  userPhoneNumber: userPhoneNumber,
                  hotelName: hotelName,
                  printerMapKey: 'kotPrinterAssigningMap',
                  printerMapValue: json.encode(kotPrinterAssigningMap))
              .updatePrinterInfo();
        }
      }
    }
  }

  void removableOneOldPrinterToNewPrinterCopy() {
    if (Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .captainPrinterAddressFromClass !=
        '') {
//ThisMeansThereIsPrinterSavedAsPartOfOldSoftware
      Map<String, dynamic> printerSavingMap = {};
      String randomID = (10000 + Random().nextInt(99999 - 10000)).toString();
      Map<String, dynamic> tempPrinterMapForSaving = HashMap();
      tempPrinterMapForSaving.addAll({
        'printerRandomID': randomID,
        'printerName': 'Printer One',
        'printerManufacturerDeviceName':
            (Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                    .captainPrinterNameFromClass)
                .toString(),
        'printerType': 'Bluetooth',
        'printerBluetoothAddress':
            (Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                    .captainPrinterAddressFromClass)
                .toString(),
        'printerIPAddress': 'NA',
        'printerUsbVendorID': 'NA',
        'printerUsbProductID': 'NA',
        'printerSize':
            (Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                    .captainPrinterSizeFromClass)
                .toString(),
        'spacesAboveKOT': '0',
        'spacesBelowKOT': '0',
        'kotFontSize': 'Small',
        'spacesAboveBill': '0',
        'spacesBelowBill': '0',
        'billFontSize': 'Small',
        'spacesAboveDeliverySlip': '0',
        'spacesBelowDeliverySlip': '0',
        'deliverySlipFontSize': 'Small',
        'singleUserPrinter': false,
        'autoCutAfterKotPrint': true,
        'autoCutAfterChefPrint': true,
        'autoCutAfterBillPrint': true,
        'extraBool1': true,
        'extraBool2': true,
        'extraBool3': true,
        'extraBool4': true,
        'extraBool5': true,
        'extraBool6': false,
        'extraBool7': false,
        'extraBool8': false,
        'extraBool9': false,
        'extraBool10': false,
        'extraString1': 'true',
        'extraString2': 'true',
        'extraString3': 'true',
        'extraString4': 'true',
        'extraString5': 'true',
        'extraString6': 'false',
        'extraString7': 'false',
        'extraString8': 'false',
        'extraString9': 'false',
        'extraString10': 'false'
      });
      printerSavingMap.addAll({randomID: tempPrinterMapForSaving});
      Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
          .savingPrintersAddedByTheUser(jsonEncode(printerSavingMap));
      //savingTheChangeInPrinterSavingMapInServer
      FireStorePrintersInformation(
              userPhoneNumber: userPhoneNumber,
              hotelName: Provider.of<PrinterAndOtherDetailsProvider>(context,
                      listen: false)
                  .chosenRestaurantDatabaseFromClass,
              printerMapKey: 'printerSavingMap',
              printerMapValue: json.encode(printerSavingMap))
          .updatePrinterInfo();
//OnceSavedWeCanDeleteTheOldPrinter
      Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
          .addCaptainPrinter('', '', '0');
//WeNeedToAlsoAssignPrintersForBillingAndForKotAlongWithUsersWhoNeedIt
      Map<String, dynamic> kotPrinterAssigningMap = HashMap();
      Map<String, dynamic> billingPrinterAssigningMap = HashMap();
      Map<String, dynamic> usersWhoNeedKot = HashMap();
      allUserProfiles.forEach((key, value) {
        if (value['privileges']['8'] == true) {
          usersWhoNeedKot.addAll({
            key: {'copies': 1}
          });
        }
      });
      kotPrinterAssigningMap.addAll({
        randomID: {'users': usersWhoNeedKot}
      });
      Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
          .savingKotAssignedPrinterByTheUser(
              json.encode(kotPrinterAssigningMap));
      FireStorePrintersInformation(
              userPhoneNumber: userPhoneNumber,
              hotelName: Provider.of<PrinterAndOtherDetailsProvider>(context,
                      listen: false)
                  .chosenRestaurantDatabaseFromClass,
              printerMapKey: 'kotPrinterAssigningMap',
              printerMapValue: json.encode(kotPrinterAssigningMap))
          .updatePrinterInfo();
      billingPrinterAssigningMap.addAll({
        randomID: {'assigned': true, 'copies': 1}
      });
      Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
          .savingBillingAssignedPrinterByTheUser(
              json.encode(billingPrinterAssigningMap));
      FireStorePrintersInformation(
              userPhoneNumber: userPhoneNumber,
              hotelName: Provider.of<PrinterAndOtherDetailsProvider>(context,
                      listen: false)
                  .chosenRestaurantDatabaseFromClass,
              printerMapKey: 'billingPrinterAssigningMap',
              printerMapValue: json.encode(billingPrinterAssigningMap))
          .updatePrinterInfo();
    }
  }

  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void timerForTurningOffCaptchaScreen() {
    Timer timerToTurnOffCaptchaScreen = Timer(Duration(seconds: 10), () {
      print('turn off captcha');
      if (captchaVerificationScreen) {
        setState(() {
          captchaVerificationScreen = false;
          showSpinner = false;
        });
      }
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
        child: captchaVerificationScreen
            ? Center(
                child: Text(
                'DON\'T PRESS BACK BUTTON\n\nRedirecting you to browser for captcha Verification',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ))
            : Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 120.0),
                      Text(
                        !otpSent ? 'Phone Verification' : 'Please Enter OTP',
                        style: TextStyle(
                            fontSize: 30, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      !otpSent
                          ? Container(
                              padding: EdgeInsets.all(20),
                              // height: 55,
                              // decoration: BoxDecoration(
                              //   borderRadius: BorderRadius.circular(50.0),
                              //   border: Border.all(width: 1, color: Colors.green),
                              // ),
                              child: IntlPhoneField(
                                decoration: InputDecoration(
                                  labelText: 'Phone Number',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(50.0),
                                    borderSide: BorderSide(
                                        width: 1, color: Colors.green),
                                  ),
                                ),
                                initialCountryCode: 'IN',
                                onChanged: (phone) {
                                  userPhoneNumber = phone.completeNumber;
                                  // print(phone.completeNumber);
                                },
                              ))
                          : Container(
                              margin: EdgeInsets.all(20),
                              child: Pinput(
                                defaultPinTheme: kDefaultPinTheme,
                                length: 6,
                                showCursor: true,
                                onChanged: (value) {
                                  otp = value;
                                },
                              ),
                            ),
                      SizedBox(
                        height: 10,
                      ),
                      Visibility(
                        visible: !otpSent,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green.shade500,
                            borderRadius: BorderRadius.circular(50.0),
                          ),
                          height: 50.0,
                          width: 200.0,
                          child: TextButton(
                            onPressed: () async {
                              print(userPhoneNumber);
                              setState(() {
                                print('captchaVerificationScreen1');
                                captchaVerificationScreen = true;
                                showSpinner = true;
                                otpSent = true;
                              });
                              timerForTurningOffCaptchaScreen();
                              verifyUserPhoneNumber(userPhoneNumber);
                            },
                            child: const Text(
                              'Login',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 25.0, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 50),
                      Visibility(
                        visible: otpSent,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.green.shade500,
                            borderRadius: BorderRadius.circular(50.0),
                          ),
                          height: 50.0,
                          width: 200.0,
                          child: TextButton(
                            onPressed: () async {
                              verifyOTPCode(otp);
                            },
                            child: const Text(
                              'Verify',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 25.0, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      otpSent
                          ? TextButton(
                              onPressed: () {
                                setState(() {
                                  otpSent = false;
                                });
                              },
                              child: Text('Edit Phone Number ?',
                                  style: TextStyle(color: Colors.black)),
                            )
                          : SizedBox.shrink(),
                      otpSent
                          ? TextButton(
                              onPressed: () {
                                verifyUserPhoneNumber(userPhoneNumber);
                              },
                              child: Text('Resend OTP ?',
                                  style: TextStyle(color: Colors.black)),
                            )
                          : SizedBox.shrink()
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
