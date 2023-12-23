import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:orders_dev/Providers/notification_provider.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:orders_dev/Screens/about_app_info_screen.dart';
import 'package:orders_dev/Screens/captain_screen_10.dart';

import 'package:orders_dev/Screens/chef_to_cook_11.dart';
import 'package:orders_dev/Screens/chef_to_cook_12.dart';
import 'package:orders_dev/Screens/choosing_chef_specialities_screen_2.dart';
import 'package:orders_dev/Screens/edit_menu_base_options.dart';
import 'package:orders_dev/Screens/inventory_chef_specialities.dart';
import 'package:orders_dev/Screens/inventory_chef_specialities_2.dart';
import 'package:orders_dev/Screens/main_settings_screen.dart';
import 'package:orders_dev/Screens/main_settings_screen_2.dart';
import 'package:orders_dev/Screens/main_settings_screen_3.dart';
import 'package:orders_dev/Screens/order_history_5.dart';
import 'package:orders_dev/Screens/statistics_page.dart';

import 'package:orders_dev/Screens/user_profiles_screen_2.dart';

import 'package:orders_dev/constants.dart';
import 'package:orders_dev/main.dart';
import 'package:orders_dev/services/firestore_services.dart';
import 'package:orders_dev/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';
import 'captain_screen_6.dart';


//ThisIsTheScreenWhereTheUserChoosesWhetherToBeChefOrCaptain
//WeAlsoGiveSideBarForOtherOptionsForTheUser
class ChefOrCaptainWithSeparateRestaurantInfo extends StatelessWidget {
  final String hotelName;
  final String userNumber;
  final List<String> menuTitles;
  final List<String> entireMenuItems;
  final List<num> entireMenuPrice;
  final List<Map<String, dynamic>> allMenuItems;
  final Map<String, dynamic> currentUserProfileMap;

  const ChefOrCaptainWithSeparateRestaurantInfo(
      {Key? key,
        required this.hotelName,
        required this.userNumber,
        required this.menuTitles,
        required this.entireMenuItems,
        required this.entireMenuPrice,
        required this.allMenuItems,
        required this.currentUserProfileMap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
//    BuildContext scaffoldContext = context;
    //WeHaveFirstEmptyListForChefWontCook
    List<String> chefWontCook = [];
    //ThisIsBoolToCheckInternet
    bool hasInternet = true;
    bool hasBackgroundPermissions = true;
    bool locationPermissionAccepted = true;
    bool isNotificationPermissionGranted = true;
    // FlutterBackground.initialize();
    NotificationService().initNotification();

    Future<void> notificationPermissionChecker() async {
      PermissionStatus? statusNotification =
      await Permission.notification.request();

      isNotificationPermissionGranted =
          statusNotification == PermissionStatus.granted;
      if (!isNotificationPermissionGranted) {
        NotificationService().showNotification(
            title: 'Orders', body: 'Requesting Your Permission');
      }
    }

//     void chefWontCookMethod() async {
// //WithTheUserNumberWeGoToThatDocInFireStoreAndThereWhatTheyWon'tCookIsStored
// //As key-False, WeStoreTheKeysAloneInChefWontCookListWithTheHelpOfForLoop
//       chefWontCook = [];
//
//       await FirebaseFirestore.instance
//           .collection(hotelName)
//           .doc('users')
//           .collection('users')
//           .doc(userNumber)
//           .get()
//           .then((DocumentSnapshot doc) {
//         final chefWontCookData = doc.data() as Map<String, dynamic>;
//         for (var wontCookItem in chefWontCookData.keys) {
//           chefWontCook.add(wontCookItem);
//         }
//
//         // ...
//       }, onError: (e) {});
//
// //OnceWeHaveTheListReady,WeCallTheChefScreen-It'sInputBeing
// //ChefWontCookListAndHotelName
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => ChefToCookWithRunningOrders(
//             hotelName: hotelName,
//             currentUserProfileMap: currentUserProfileMap,
//           ),
//         ),
//       );
//       EasyLoading.dismiss();
//     }

    return WillPopScope(
      onWillPop: () async {
//ToExitTheApp
        exit(0);
      },
      child: FlutterEasyLoading(
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: kAppBarBackgroundColor,
//AppbarTextIsChooseRole
            title: Text(
              'Choose Your Role',
              style: kAppBarTextStyle,
            ),
//CenterTitleForGettingTheTitleInMiddle
            centerTitle: true,

            iconTheme: const IconThemeData(color: Colors.black87),
            //iconThemeIsToChangeTheColorOfIconInAppBar
          ),
//drawer-navigationDrawer IsForTheFunctionForSidebar
//InputsWillBeHotelName,EntireMenuItems,MenuTitles and UserNumber
          drawer: NavigationDrawer(
            hotelName: hotelName,
            entireMenuItems: entireMenuItems,
            menuTitles: menuTitles,
            items: allMenuItems,
            userNumber: userNumber,
            currentUserProfileMap: currentUserProfileMap,
          ),
          body: UpgradeAlert(
            upgrader: Upgrader(
              canDismissDialog: true,
              durationUntilAlertAgain: Duration(seconds: 30),
              shouldPopScope: () => true,
            ),
            child: Center(
//WeHaveTwoTextButtonsToChooseEither Captain/Cook
              child: Container(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      //ContainerMainlyForTheDecorationOfTheButton
                      //LinearGradientInsideBoxDecorationToGiveColorGradientOfBlue
                      Container(
                        height: 250.0,
                        width: 250.0,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [
                                Colors.blue.shade700,
                                Colors.blue.shade900
                              ]),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        //WeHaveBuilderInsideForGivingTheSnackBarLater
                        //OnPressed-usingInternetConnectionCheckerPackageDownloadedFromInternet,,
                        //WeCheckInternetConnection
                        //IfConnectionIsThere,WeNavigateToCaptainScreenWithTheInputsBelow
                        child: Builder(builder: (context) {
                          return TextButton(
                              onPressed: () async {
                                EasyLoading.show(status: '');
                                notificationPermissionChecker();

                                hasInternet = await InternetConnectionChecker()
                                    .hasConnection;
                                if (hasInternet) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CaptainScreenEachItemCheck(
                                            hotelName: hotelName,
                                            menuTitles: menuTitles,
                                            entireMenuItems: entireMenuItems,
                                            entireMenuPrice: entireMenuPrice,
                                          ),
                                    ),
                                  );
                                  EasyLoading.dismiss();
                                } else {
                                  EasyLoading.dismiss();
//IfNoInternet,WeShowSnackBar/ToastMessageWithTheMessage-YouAreOffline
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'You are Offline',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: kSnackbarMessageSize),
                                      ),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
//TheTextButtonTextWillBe "I Am Captain"
                              child: const Text(
                                "Captain",
                                style: TextStyle(
                                    fontSize: 30.0, color: Colors.white),
                              ));
                        }),
                      ),
                      SizedBox(
                        height: 20.0,
                      ),
                      //TheSecondButtonIsForTheChef
                      Container(
                        //ContainerIsMainlyForYellowColorGradientDecoration&BorderRadius
                        height: 250.0,
                        width: 250.0,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [
                                Colors.yellow.shade700,
                                Colors.yellow.shade900
                              ]),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
//WeAreMainlyHavingThisBuilderSoThatWeCanPutTheSnackBarLater
                        child: Builder(builder: (context) {
//OnceWePressTextButtonFirstWeCheckInternet,IfItsThere,
//WeCallThe "chefwontCook" MethodToNavigateToTheChefScreen
                          return TextButton(
                              onPressed: () async {
                                EasyLoading.show(status: '');
                                hasInternet = await InternetConnectionChecker()
                                    .hasConnection;
                                if (hasInternet) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ChefToCookPrinterAlign(
                                            hotelName: hotelName,
                                            currentUserProfileMap:
                                            currentUserProfileMap,
                                          ),
                                    ),
                                  );
                                  EasyLoading.dismiss();
                                } else {
                                  EasyLoading.dismiss();

                                  //IfInternetIsNotThere,WeCallThe SnackBar ToSay TheyAreOffline
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'You are Offline',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: kSnackbarMessageSize),
                                      ),
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }
                              },
//TheTextToBeDisplayedInTheButton
                              child: const Text(
                                "Chef",
                                style: TextStyle(
                                    fontSize: 30.0, color: Colors.white),
                              ));
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

//ThisFunctionIsTheSidebarWhichWeAccessWhenWeClickTheSideButtonInTheAppbar
class NavigationDrawer extends StatelessWidget {
  final String hotelName;
  final List<String> entireMenuItems;
  final List<String> menuTitles;
  final List<Map<String, dynamic>> items;
  final String userNumber;
  final Map<String, dynamic> currentUserProfileMap;

  const NavigationDrawer({
    Key? key,
    required this.hotelName,
    required this.entireMenuItems,
    required this.menuTitles,
    required this.items,
    required this.userNumber,
    required this.currentUserProfileMap,
  }) : super(key: key);


  @override
  Widget build(BuildContext context) => Drawer(
//WeHaveColumnInsideSingleChildScrollViewSoThatWeCanScrollTheColumn
    child: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          //WeHaveHeaderForSideBarAndMenuInsideSideBar
          buildHeader(context),
          buildMenuItems(context),
        ],
      ),
    ),
  );

  Widget buildHeader(BuildContext context) => Container(
      color: Colors.green,
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
//MediaQuery(IThink)IsToAlignAccordingToTheDeviceTheAppIsBeingUsed
//WePutTheAppNameInHeader
      child: ListTile(
          tileColor: Colors.green,
          title: Text(
            '      Orders',
            style: GoogleFonts.openSans(
                textStyle: TextStyle(
                    fontSize: 30.0,
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold)),
          )));
  //ToConvertDynamicListToStringList


  Widget buildMenuItems(BuildContext context) => Column(
    //ThisIsTheContentsOfTheSideBarUnderTheHeader
    children: [
      //FirstIsOrderHistoryWithAnIcon.ClickToGoToOrderHistoryPage-Input-hotelName
      ListTile(
        leading: const Icon(IconData(0xe043, fontFamily: 'MaterialIcons')),
        title: Text(json.decode(Provider.of<PrinterAndOtherDetailsProvider>(
            context,
            listen: false)
            .restaurantInfoDataFromClass)['hotelname']),
        subtitle: Text('${currentUserProfileMap[hotelName]['username']}'),
      ),
      const Divider(color: Colors.black54),
      (currentUserProfileMap[hotelName]['admin'] ||
          json.decode(Provider.of<PrinterAndOtherDetailsProvider>(
              context,
              listen: false)
              .allUserProfilesFromClass)[
          Provider.of<PrinterAndOtherDetailsProvider>(context,
              listen: false)
              .currentUserPhoneNumberFromClass]['privileges']['3'])
          ? ListTile(
        leading: const Icon(
            IconData(0xf072b, fontFamily: 'MaterialIcons')),
        title: Text('Order History'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (Buildcontext) => OrderHistoryWithExtraItems(
                      hotelName: hotelName)));
        },
      )
          : SizedBox.shrink(),
//NextIsStatisticsWithAnIcon.ClickToGoToOrderStatisticsPage-Input-hotelName
      (currentUserProfileMap[hotelName]['admin'] ||
          json.decode(Provider.of<PrinterAndOtherDetailsProvider>(
              context,
              listen: false)
              .allUserProfilesFromClass)[
          Provider.of<PrinterAndOtherDetailsProvider>(context,
              listen: false)
              .currentUserPhoneNumberFromClass]['privileges']['2'])
          ? ListTile(
        leading:
        const Icon(IconData(0xeebc, fontFamily: 'MaterialIcons')),
        title: Text('Statistics Reports'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (Buildcontext) =>
                      StatisticsPage(hotelName: hotelName)));
        },
      )
          : SizedBox.shrink(),
      (currentUserProfileMap[hotelName]['admin'] ||
          json.decode(Provider.of<PrinterAndOtherDetailsProvider>(
              context,
              listen: false)
              .allUserProfilesFromClass)[
          Provider.of<PrinterAndOtherDetailsProvider>(context,
              listen: false)
              .currentUserPhoneNumberFromClass]['privileges']['3'] ||
          json.decode(Provider.of<PrinterAndOtherDetailsProvider>(
              context,
              listen: false)
              .allUserProfilesFromClass)[
          Provider.of<PrinterAndOtherDetailsProvider>(context,
              listen: false)
              .currentUserPhoneNumberFromClass]['privileges']['2'])
          ? Divider(color: Colors.black54)
          : SizedBox.shrink(),
//nextIsAnOptionToRemoveOptionsThatAreOverInTheKitchen
//InputsAreMenuItems,Titles,hotelName and
//Finally AnOptionCalledInventoryOrChefSelection
//Basically,WeAreUsingTheSameClassToGiveItemAvailabilityAndChefSpecialities
//ByGiving "true" toInventoryAndChefSpecialities,WeSayWeWantInventoryPage
      (currentUserProfileMap[hotelName]['admin'] ||
          json.decode(Provider.of<PrinterAndOtherDetailsProvider>(
              context,
              listen: false)
              .allUserProfilesFromClass)[
          Provider.of<PrinterAndOtherDetailsProvider>(context,
              listen: false)
              .currentUserPhoneNumberFromClass]['privileges']['6'])
          ? ListTile(
        leading:
        const Icon(IconData(0xf823, fontFamily: 'MaterialIcons')),
        title: Text('Item Availability'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (Buildcontext) =>
                      InventoryOrChefSpecialitiesWithFCM(
                        hotelName: hotelName,
                        inventoryOrChefSelection: true,
                        allMenuItems: items,
                      )));
        },
      )
          : SizedBox.shrink(),
      (currentUserProfileMap[hotelName]['admin'] ||
          json.decode(Provider.of<PrinterAndOtherDetailsProvider>(
              context,
              listen: false)
              .allUserProfilesFromClass)[
          Provider.of<PrinterAndOtherDetailsProvider>(context,
              listen: false)
              .currentUserPhoneNumberFromClass]['privileges']['5'])
          ? ListTile(
        leading: const Icon(
            IconData(0xf04b3, fontFamily: 'MaterialIcons')),
        title: Text('Chef Specialities'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (Buildcontext) => ChefSpecialities(
                    hotelName: hotelName,
                    currentUserProfileMap: currentUserProfileMap,
                    items: items,
                  )));
        },
      )
          : SizedBox.shrink(),
//EditMenuOptions
      (currentUserProfileMap[hotelName]['admin'] ||
          json.decode(Provider.of<PrinterAndOtherDetailsProvider>(
              context,
              listen: false)
              .allUserProfilesFromClass)[
          Provider.of<PrinterAndOtherDetailsProvider>(context,
              listen: false)
              .currentUserPhoneNumberFromClass]['privileges']['7'])
          ? ListTile(
        leading: const Icon(Icons.edit_note_rounded),
        title: Text('Restaurant Info & Menu'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (Buildcontext) => EditMenuBaseOptions(
                    hotelName: hotelName,
                  )));
        },
      )
          : SizedBox.shrink(),
//FinalDividerLine
      (currentUserProfileMap[hotelName]['admin'] ||
          json.decode(Provider.of<PrinterAndOtherDetailsProvider>(
              context,
              listen: false)
              .allUserProfilesFromClass)[
          Provider.of<PrinterAndOtherDetailsProvider>(context,
              listen: false)
              .currentUserPhoneNumberFromClass]['privileges']['7'] ||
          json.decode(Provider.of<PrinterAndOtherDetailsProvider>(
              context,
              listen: false)
              .allUserProfilesFromClass)[
          Provider.of<PrinterAndOtherDetailsProvider>(context,
              listen: false)
              .currentUserPhoneNumberFromClass]['privileges']['5'] ||
          json.decode(Provider.of<PrinterAndOtherDetailsProvider>(
              context,
              listen: false)
              .allUserProfilesFromClass)[
          Provider.of<PrinterAndOtherDetailsProvider>(context,
              listen: false)
              .currentUserPhoneNumberFromClass]['privileges']['6'])
          ? Divider(color: Colors.black54)
          : SizedBox.shrink(),
      ListTile(
        leading: Icon(Icons.settings),
        title: Text('Settings'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context,
              MaterialPageRoute(builder: (BuildContext) => MainSettingsForPrinter()));
        },
      ),
      const Divider(color: Colors.black54),
      (currentUserProfileMap[hotelName]['admin'] ||
          json.decode(Provider.of<PrinterAndOtherDetailsProvider>(
              context,
              listen: false)
              .allUserProfilesFromClass)[
          Provider.of<PrinterAndOtherDetailsProvider>(context,
              listen: false)
              .currentUserPhoneNumberFromClass]['privileges']['4'])
          ? ListTile(
        leading: Icon(Icons.supervised_user_circle_outlined),
        title: Text('User Profiles'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext) => UserProfilesWithEdit(
                    hotelName: hotelName,
                    currentUserProfileMap: currentUserProfileMap,
                  )));
        },
      )
          : SizedBox.shrink(),
      (currentUserProfileMap[hotelName]['admin'] ||
          json.decode(Provider.of<PrinterAndOtherDetailsProvider>(
              context,
              listen: false)
              .allUserProfilesFromClass)[
          Provider.of<PrinterAndOtherDetailsProvider>(context,
              listen: false)
              .currentUserPhoneNumberFromClass]['privileges']['4'])
          ? Divider(color: Colors.black54)
          : SizedBox.shrink(),

      ListTile(
        leading: const Icon(IconData(0xe043, fontFamily: 'MaterialIcons')),
        title: Text('Sign Out'),
//WeUseFireBaseAuthToSignOut
//WithNavigatorWeReplaceThePageToLoginPage
        onTap: () async {
          //ToConvertDynamicListToStringList
          List<String> dynamicTokensToStringToken() {
            List<String> tokensList = [];
            Map<String, dynamic> allUsersTokenMap = json.decode(
                Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                    .allUserTokensFromClass);
            for (var tokens in allUsersTokenMap.values) {
              tokensList.add(tokens.toString());
            }
            return tokensList;
          }
          FireStoreDeleteTokenAloneFromRestaurant(restaurantDatabaseName: hotelName,userPhoneNumber: Provider.of<PrinterAndOtherDetailsProvider>(context,listen: false).currentUserPhoneNumberFromClass).deleteTokenFromRestaurant();
          Provider.of<PrinterAndOtherDetailsProvider>(context,
              listen: false)
              .restaurantChosenByUser('');
          Provider.of<PrinterAndOtherDetailsProvider>(context,
              listen: false)
              .chefVideoInstructionLookedOrNot(false);
          Provider.of<PrinterAndOtherDetailsProvider>(context,
              listen: false)
              .captainInsideTableVideoInstructionLookedOrNot(false);
          Provider.of<PrinterAndOtherDetailsProvider>(context,
              listen: false)
              .restaurantChosenByUser('');
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
          await FirebaseAuth.instance.signOut();
          Phoenix.rebirth(context);
          // Navigator.pushReplacement(context,
          //     MaterialPageRoute(builder: (Buildcontext) => LoginPage()));
        },
      ),
      //AboutPageForAppDetails
      ListTile(
        leading: const Icon(IconData(0xe33c, fontFamily: 'MaterialIcons')),
//IfUserNumberIsSeven,FontWeightBoldWithBigSizeOrSmallFontSmallSize
        title: Text('About'),
//WeAllowOnTapAndGoToChefSpecialitiesOnlyIfUserNumberIs7(WhichIsTheCurrentUser),
//orIfItIs1,WhichIsTheOwner
        onTap: () {
          Navigator.pop(context);
          Navigator.push(context,
              MaterialPageRoute(builder: (Buildcontext) => AboutAppInfo()));
        },
      ),
    ],
  );
}
