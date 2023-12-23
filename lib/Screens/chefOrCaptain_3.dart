import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:orders_dev/Screens/about_app_info_screen.dart';
import 'package:orders_dev/Screens/chef_to_cook_8.dart';
import 'package:orders_dev/Screens/choosing_chef_specialities_screen.dart';
import 'package:orders_dev/Screens/edit_menu_base_options.dart';
import 'package:orders_dev/Screens/inventory_chef_specialities.dart';
import 'package:orders_dev/Screens/main_settings_screen.dart';
import 'package:orders_dev/Screens/order_history_5.dart';
import 'package:orders_dev/Screens/statistics_page.dart';
import 'package:orders_dev/constants.dart';
import 'package:orders_dev/main.dart';
import 'package:orders_dev/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';
import 'captain_screen_6.dart';

//ThisIsTheScreenWhereTheUserChoosesWhetherToBeChefOrCaptain
//WeAlsoGiveSideBarForOtherOptionsForTheUser
class ChefOrCaptainDeleteTillEnd extends StatelessWidget {
  final String hotelName;
  final String userNumber;
  final List<String> menuTitles;
  final List<String> entireMenuItems;
  final List<num> entireMenuPrice;
  final num numberOfTables;
  final num cgstPercentage;
  final num sgstPercentage;
  final String hotelNameForPrint;
  final String addressLine1ForPrint;
  final String addressLine2ForPrint;
  final String addressLine3ForPrint;
  final String phoneNumberForPrint;
  final String gstCodeForPrint;

  const ChefOrCaptainDeleteTillEnd(
      {Key? key,
      required this.hotelName,
      required this.userNumber,
      required this.menuTitles,
      required this.entireMenuItems,
      required this.entireMenuPrice,
      required this.numberOfTables,
      required this.cgstPercentage,
      required this.sgstPercentage,
      required this.hotelNameForPrint,
      required this.addressLine1ForPrint,
      required this.addressLine2ForPrint,
      required this.addressLine3ForPrint,
      required this.phoneNumberForPrint,
      required this.gstCodeForPrint})
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

    void chefWontCookMethod() async {
//WithTheUserNumberWeGoToThatDocInFireStoreAndThereWhatTheyWon'tCookIsStored
//As key-False, WeStoreTheKeysAloneInChefWontCookListWithTheHelpOfForLoop
      chefWontCook = [];

      await FirebaseFirestore.instance
          .collection(hotelName)
          .doc('users')
          .collection('users')
          .doc(userNumber)
          .get()
          .then((DocumentSnapshot doc) {
        final chefWontCookData = doc.data() as Map<String, dynamic>;
        for (var wontCookItem in chefWontCookData.keys) {
          chefWontCook.add(wontCookItem);
        }

        // ...
      }, onError: (e) {});

//OnceWeHaveTheListReady,WeCallTheChefScreen-It'sInputBeing
//ChefWontCookListAndHotelName
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChefToCookPrintAlignment(
            hotelName: hotelName,
            chefSpecialities: chefWontCook,
          ),
        ),
      );
      EasyLoading.dismiss();
    }

    return MaterialApp(
      home: FlutterEasyLoading(
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
            userNumber: userNumber,
            hotelNameForPrint: hotelNameForPrint,
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
                                          CaptainScreenTileChange(
                                        hotelName: hotelName,
                                        numberOfTables: numberOfTables,
                                        menuTitles: menuTitles,
                                        entireMenuItems: entireMenuItems,
                                        entireMenuPrice: entireMenuPrice,
                                        cgstPercentage: cgstPercentage,
                                        sgstPercentage: sgstPercentage,
                                        hotelNameForPrint: hotelNameForPrint,
                                        addressLine1ForPrint:
                                            addressLine1ForPrint,
                                        addressLine2ForPrint:
                                            addressLine2ForPrint,
                                        addressLine3ForPrint:
                                            addressLine3ForPrint,
                                        phoneNumberForPrint:
                                            phoneNumberForPrint,
                                        gstCodeForPrint: gstCodeForPrint,
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
                                  chefWontCookMethod();
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
  final String userNumber;
  final String hotelNameForPrint;

  const NavigationDrawer(
      {Key? key,
      required this.hotelName,
      required this.entireMenuItems,
      required this.menuTitles,
      required this.userNumber,
      required this.hotelNameForPrint})
      : super(key: key);

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

  Widget buildMenuItems(BuildContext context) => Column(
        //ThisIsTheContentsOfTheSideBarUnderTheHeader
        children: [
          //FirstIsOrderHistoryWithAnIcon.ClickToGoToOrderHistoryPage-Input-hotelName
          ListTile(
            leading: const Icon(IconData(0xe043, fontFamily: 'MaterialIcons')),
            title: Text(hotelNameForPrint),
            subtitle: Text('${hotelName}_$userNumber'),
          ),
          const Divider(color: Colors.black54),
          ListTile(
            leading: const Icon(IconData(0xf072b, fontFamily: 'MaterialIcons')),
            title: Text('Order History'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (Buildcontext) =>
                          OrderHistoryWithExtraItems(hotelName: hotelName)));
            },
          ),
//NextIsStatisticsWithAnIcon.ClickToGoToOrderStatisticsPage-Input-hotelName
          userNumber == '1'
              ? ListTile(
                  leading:
                      const Icon(IconData(0xeebc, fontFamily: 'MaterialIcons')),
                  title: Text('Statistics Reports'),
                  onTap: () {
                    if (userNumber == '1') {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (Buildcontext) =>
                                  StatisticsPage(hotelName: hotelName)));
                    }
                  },
                )
              : SizedBox.shrink(),
          const Divider(color: Colors.black54),
//nextIsAnOptionToRemoveOptionsThatAreOverInTheKitchen
//InputsAreMenuItems,Titles,hotelName and
//Finally AnOptionCalledInventoryOrChefSelection
//Basically,WeAreUsingTheSameClassToGiveItemAvailabilityAndChefSpecialities
//ByGiving "true" toInventoryAndChefSpecialities,WeSayWeWantInventoryPage
          ListTile(
            leading: const Icon(IconData(0xf823, fontFamily: 'MaterialIcons')),
            title: Text('Item Availability'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (Buildcontext) => InventoryOrChefSpecialities(
                            entireMenuItems: entireMenuItems,
                            entireTitles: menuTitles,
                            hotelName: hotelName,
                            inventoryOrChefSelection: true,
                          )));
            },
          ),
          //DividerLineBecauseWeAreGoingToChefSpecialities
          // userNumber != '1'
          //     ? const Divider(color: Colors.black54)
          //     : SizedBox.shrink(),
          userNumber == '1'
              ? ListTile(
                  leading: const Icon(
                      IconData(0xf04b3, fontFamily: 'MaterialIcons')),
                  title: Text('Chef Specialities'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (Buildcontext) =>
                                ChoosingChefForSpecialities(
                                  entireMenuItems: entireMenuItems,
                                  menuTitles: menuTitles,
                                  hotelName: hotelName,
                                )));
                  },
                )
              : SizedBox.shrink(),
//EditMenuOptions
          userNumber == '1'
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
          const Divider(color: Colors.black54),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (BuildContext) => MainSettings()));
            },
          ),
          const Divider(color: Colors.black54),

          ListTile(
            leading: const Icon(IconData(0xe043, fontFamily: 'MaterialIcons')),
            title: Text('Sign Out'),
//WeUseFireBaseAuthToSignOut
//WithNavigatorWeReplaceThePageToLoginPage
            onTap: () async {
              Provider.of<PrinterAndOtherDetailsProvider>(context,
                      listen: false)
                  .chefVideoInstructionLookedOrNot(false);
              Provider.of<PrinterAndOtherDetailsProvider>(context,
                      listen: false)
                  .captainInsideTableVideoInstructionLookedOrNot(false);
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (Buildcontext) => LoginPage()));
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
