import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:modal_progress_hud_alt/modal_progress_hud_alt.dart';
import 'package:orders_dev/Methods/bottom_button.dart';
import 'package:orders_dev/Providers/notification_provider.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';

import 'package:orders_dev/Screens/bill_print_screen_12.dart';
import 'package:orders_dev/Screens/bill_print_screen_14.dart';
import 'package:orders_dev/Screens/bill_print_screen_15.dart';
import 'package:orders_dev/Screens/bill_print_screen_16.dart';
import 'package:orders_dev/Screens/bill_print_screen_17.dart';

import 'package:orders_dev/Screens/menu_page_add_items_6.dart';
import 'package:orders_dev/Screens/tableOrParcelSplit_3.dart';
import 'package:orders_dev/constants.dart';
import 'package:orders_dev/services/firestore_services.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

enum _MenuValues { split, move, deliveredAll }

//ThisIsTheScreenIfTheWaiterClicksOnAnyTable/Parcel
//ItWillShowHimAllItemsThatHaveBeenOrderedTillNow
//AndHeWillHaveOptionToAddMenuOrHeCanGoForBillPrintScreen
class ItemsWithCancelRegister extends StatefulWidget {
//WhenWeClickOnATable/Parcel,WeWillDownloadAllTheBelowDataFromFireStore,
//AndInputToThisClass
  final String hotelName;
  final List<String> menuItems;
  final List<num> menuPrices;
  final List<String> menuTitles;
  final List<String> itemsID;
  final List<String> itemsName;
  final List<int> itemsNumber;
  final List<int> itemsStatus;
  final List<num> itemsEachPrice;
  final List<String> itemsBelongsToDoc;
  final String itemsFromDoc;
  final String tableOrParcel;
  final num tableOrParcelNumber;

  const ItemsWithCancelRegister(
      {Key? key,
      required this.hotelName,
      required this.menuItems,
      required this.menuPrices,
      required this.menuTitles,
      required this.itemsID,
      required this.itemsName,
      required this.itemsNumber,
      required this.itemsStatus,
      required this.itemsEachPrice,
      required this.itemsBelongsToDoc,
      required this.itemsFromDoc,
      required this.tableOrParcel,
      required this.tableOrParcelNumber})
      : super(key: key);

  @override
  State<ItemsWithCancelRegister> createState() =>
      _ItemsWithCancelRegisterState();
}

class _ItemsWithCancelRegisterState extends State<ItemsWithCancelRegister>
    with WidgetsBindingObserver {
//KeepingInitialStateOfAllItemsDeliveredAsFalse
  final _fireStore = FirebaseFirestore.instance;
  late StreamSubscription internetCheckerSubscription;
  bool pageHasInternet = true;
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> rejectedItems = [];
  List<Map<String, dynamic>> readyItems = [];
  List<Map<String, dynamic>> acceptedItems = [];
  List<Map<String, dynamic>> nonAcceptedItems = [];
  List<Map<String, dynamic>> deliveredItems = [];
  List<Map<String, dynamic>> otherItems = [];

  Map<String, dynamic> baseInfoFromServerMap = HashMap();
  Map<String, dynamic> itemsInOrderFromServerMap = HashMap();
  Map<String, dynamic> cancelledItemsInOrderFromServerMap = HashMap();
  Map<String, dynamic> statusFromServerMap = HashMap();
  Map<String, dynamic> ticketsFromServerMap = HashMap();
  String partOfTableOrParcelFromMap = '';
  String partOfTableOrParcelNumberFromMap = '';

  String parentOrChild = '';
  num chefStatusForSplit = 0;
  num captainStatusForSplit = 0;
  bool splitPressed = false;
  bool movePressed = false;
  List<String> tablesToMoveTo = ['Select'];
  List<String> parcelsToMoveTo = ['Select'];
  bool tableClickedTrueParcelClickedFalse = true;
  String tableOrParcelToMoveTo = 'Select';
  List<String> tablesAlreadyOccupied = [];
  List<String> parcelsAlreadyOccupied = [];
  List<Map<String, dynamic>> presentTablesParcelsOccupied = [];
  late VideoPlayerController _videoController;
  bool noItemsInTable = false;
  bool deliveredStatus = true;
  bool orderIdCheckedWhenEnteringScreen = false;
  String firstCheckedOrderId = '';
  Map<String, dynamic> restaurantInfoMap = HashMap();
  StreamSubscription<QuerySnapshot>? _streamSubscriptionForThisMonth;
  int closingHour = 0;
  String statisticsYear = '';
  String statisticsMonth = '';
  String statisticsDay = '';
  String lastItemIdForCancelling = '';
  num lastItemStatusForCancelling = 0;
  num previousCashBalanceWhileIterating = -9999999;
  num dayIncrementWhileIterating = -1111111;
  int currentGeneratedIncrementRandomNumber = 0;
  bool showSpinner = false;
  String billYear = '';
  String billMonth = '';
  String billDay = '';
  String billHour = '';
  String billMinute = '';
  String billSecond = '';

  @override
  void initState() {
//WeAreMakingThisVariableSimplyToGetTheProviderValueOnce.FirstTimeItWillBeInitialValue
//IfWeDontHaveThisFirstTimeTaking,TheVideoWillPlayAgainAndAgain
//EverytimeSomeoneGets
    bool tempProviderInitialize =
        Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .captainInsideTableInstructionsVideoPlayedFromClass;
    // TODO: implement initState
//toEnsureVideoIsn'tCalledIfThereAreNoItems
//WeDoThisSoThatInstructionScreenWontOverflowIntoMenuScreen
//AsInCaseOfEmptyTablesInCaptainScreen,WeAdd ItemsScreenAndMenuScreenOneAfterAnother
    if (widget.itemsID.isNotEmpty) {
      _videoController = VideoPlayerController.asset(
          'assets/videos/captain_delivered_cancel_tutorial.mp4');
      // _videoController.initialize().then((value) => _videoController.play());
      // _videoController.initialize();
      buildCaptainInTableInstructionAlertDialogWidgetWithTimer();
    }

    //ThisIsTheStreamWhichWillKeepCheckingOnTheStatusOfInternet
    //ItWillKeepLookingForStatusChangeAndWillUpdateThe hasInternet Variable
    internetAvailabilityChecker();
    // localItemsStatus = [];
    // // localItemsStatus = widget.itemsStatus;
    // // itemsDeliveredOrNotStatusChecker();
    splitPressed = false;
    movePressed = false;
    orderIdCheckedWhenEnteringScreen = false;
    firstCheckedOrderId = '';
    showSpinner = false;

    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _streamSubscriptionForThisMonth?.cancel();
    super.dispose();
  }

  //ThisIsToCheckAppLifeCycleStateWhetherItIsInForegroundOrBackground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // TODO: implement didChangeAppLifecycleState

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) return;

    final isBackground = state == AppLifecycleState.paused;
    final isForeground = state == AppLifecycleState.resumed;

    if (isForeground) {
      setState(() {
        pageHasInternet = true;
      });
      internetAvailabilityChecker();
    }

    super.didChangeAppLifecycleState(state);
  }

  Future show(
    String message, {
    Duration duration: const Duration(seconds: 2),
  }) async {
    await new Future.delayed(new Duration(milliseconds: 100));
    ScaffoldMessenger.of(context).showSnackBar(
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

  void internetAvailabilityChecker() {
    Timer? _timerToCheckInternet;
    int _everySecondForInternetChecking = 0;
    ;
    _timerToCheckInternet =
        Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_everySecondForInternetChecking < 5) {
        _everySecondForInternetChecking++;
        print(
            '_everySecondForInternetChecking $_everySecondForInternetChecking');
      } else {
        internetCheckerSubscription =
            InternetConnectionChecker().onStatusChange.listen((status) {
          final hasInternet = status == InternetConnectionStatus.connected;
//WeSetStateOfPageHasInternet
          if (pageHasInternet != hasInternet) {
            setState(() {
              pageHasInternet = hasInternet;
            });
          }
        });
        _timerToCheckInternet!.cancel();
        _everySecondForInternetChecking = 0;
        print(
            '_everySecondForInternetChecking $_everySecondForInternetChecking');
      }
    });
  }

//Giving500msTimerToCheckWhetherThatInitializingTimeHelpsIt
//InSomeMobilesItWasntPlayingAndBlankScreenWasGettingReturned
//HenceThisStrategyTryOut.
  void buildCaptainInTableInstructionAlertDialogWidgetWithTimer() async {
    print('start of 2 seconds');
    Timer _videoPlayTimer;
    _videoController.initialize();
    _videoPlayTimer = Timer(Duration(milliseconds: 1000), () async {
      print('after 2 seconds');
      await Future(() {
        if (Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .captainInsideTableInstructionsVideoPlayedFromClass ==
            false) {
          _videoController
              .initialize()
              .then((value) => _videoController.play());
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              backgroundColor: Colors.transparent.withOpacity(0.5),
              // elevation: 24.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              content: Container(
                  // height: 400,
                  // width: 100,
                  child: AspectRatio(
                      aspectRatio: _videoController.value.aspectRatio,
                      child: VideoPlayer(_videoController))),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.grey),
                          shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30))),
                          // RoundedRectangleBorder(
                          //   borderRadius: BorderRadius.circular(10),
                          // ),
                        ),
                        onPressed: () {
                          _videoController.play();
                        },
                        child: Padding(
                          // padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                          padding: const EdgeInsets.all(20.0),
                          child: Text('Replay'),
                        )),
                    // SizedBox(width: 20),
                    ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.green),
                          shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50))),
                        ),
                        onPressed: () {
                          Provider.of<PrinterAndOtherDetailsProvider>(context,
                                  listen: false)
                              .captainInsideTableVideoInstructionLookedOrNot(
                                  true);

                          Navigator.pop(context);
                        },
                        child: Padding(
                          // padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                          padding: const EdgeInsets.all(20.0),
                          child: Text('  OK  '),
                        ))
                  ],
                ),
              ],
            ),
            barrierDismissible: false,
          );
        }
      });
    });
  }

  //ConvertingAMapFromNormalValueToValueOfFieldValueToIncrements
//SoThatItCanBeSentToFireStore
  Map<String, dynamic> updateMapWithIncrements(Map<String, dynamic> map) {
    final updatedMap = Map<String, dynamic>.from(map);
    updatedMap.updateAll((key, value) {
      if (value is Map<String, dynamic>) {
        value.updateAll((subKey, subValue) {
          if (subValue is num) {
            return FieldValue.increment(subValue); // Apply increment directly
          } else {
            return subValue; // Return unchanged values
          }
        });
      }
      return value; // Return unchanged values for non-map entries
    });
    return updatedMap;
  }

  @override
  Widget build(BuildContext innerContext) {
    final fcmProvider =
        Provider.of<NotificationProvider>(context, listen: false);
//namingItAsInnerContextBecauseUnlessInnerContextIsMentioned
//AfterTakingAlertDialog,ItIsntClosingUnlessExactInnerContextIsMentioned
    num cgstCalculated = 0;
    num sgstCalculated = 0;
    num totalBillWithTaxes = 0;
    String customername = '';
    String customermobileNumber = '';
    String customeraddressline1 = '';
    TextEditingController _controller = TextEditingController();

    void documentStatisticsRegistryDateMaker() {
      DateTime now = DateTime.now();
//WeEnsureWeTakeTheMonth,Day,Hour,MinuteAsString
//ifItIsLessThan10,WeSaveItWithZeroInTheFront
//ThisWillEnsure,ItIsAlwaysIn2Digits,AndWithoutPuttingItInTwoDigits,,
//ItWon'tComeInAscendingOrder
      if (baseInfoFromServerMap['billYear'] == '') {
        billYear = now.year.toString();
      } else {
//thisMeansThatWeHavePutItInServerWithThisYearWhilePrinting
        billYear = baseInfoFromServerMap['billYear'];
      }
      if (baseInfoFromServerMap['billMonth'] == '') {
        billMonth = now.month < 10
            ? '0${now.month.toString()}'
            : '${now.month.toString()}';
      } else {
        billMonth = baseInfoFromServerMap['billMonth'];
      }
      if (baseInfoFromServerMap['billDay'] == '') {
        billDay =
            now.day < 10 ? '0${now.day.toString()}' : '${now.day.toString()}';
      } else {
        billDay = baseInfoFromServerMap['billDay'];
      }
      if (baseInfoFromServerMap['billHour'] == '') {
        billHour = now.hour < 10
            ? '0${now.hour.toString()}'
            : '${now.hour.toString()}';
      } else {
        billHour = baseInfoFromServerMap['billHour'];
      }
      if (baseInfoFromServerMap['billMinute'] == '') {
        billMinute = now.minute < 10
            ? '0${now.minute.toString()}'
            : '${now.minute.toString()}';
      } else {
        billMinute = baseInfoFromServerMap['billMinute'];
      }
      if (baseInfoFromServerMap['billSecond'] == '') {
        billSecond = now.second < 10
            ? '0${now.second.toString()}'
            : '${now.second.toString()}';
      } else {
        billSecond = baseInfoFromServerMap['billSecond'];
      }

//ThisCouldBeEitherNowTimeOrPrintedTime
      DateTime dateTimeFromBaseInfo = DateTime(
          int.parse(billYear),
          int.parse(billMonth),
          int.parse(billDay),
          int.parse(billHour),
          int.parse(billMinute),
          int.parse(billSecond));

      closingHour = 0;
      statisticsYear = '';
      statisticsMonth = '';
      statisticsDay = '';

      restaurantInfoMap = json.decode(
          Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .restaurantInfoDataFromClass);
      if (restaurantInfoMap.containsKey('restaurantClosingHour')) {
        String tempClosingHour = restaurantInfoMap['restaurantClosingHour'];
        if (tempClosingHour.substring(0, 2) != '12') {
//TwelveIsAnywayZeroOnly
          closingHour = int.parse(tempClosingHour.substring(0, 2));
        }
      }
      if (dateTimeFromBaseInfo.millisecondsSinceEpoch >=
          (DateTime(DateTime.now().year, DateTime.now().month,
                  DateTime.now().day, closingHour))
              .millisecondsSinceEpoch) {
//WeAreCheckingWhetherItIsGreaterThanTheClosingTime
        statisticsYear = billYear;
        statisticsMonth = billMonth;
        statisticsDay = billDay;
      } else {
//ThisMeansTheBillShouldGoIntoYesterday
        if (dateTimeFromBaseInfo.millisecondsSinceEpoch >=
            DateTime(dateTimeFromBaseInfo.year, dateTimeFromBaseInfo.month,
                    dateTimeFromBaseInfo.day, closingHour)
                .millisecondsSinceEpoch) {
//thisMeansOnTheBilledDateItsHigherThanClosingHourAndHenceAgain
//ThatDayIsStatisticsYearMonthDay
          statisticsYear = billYear;
          statisticsMonth = billMonth;
          statisticsDay = billDay;
        } else {
//TheDocumentShouldBePreviousDayInTheBilledDate
        }
        DateTime yesterdayToBilledDay = DateTime(dateTimeFromBaseInfo.year,
                dateTimeFromBaseInfo.month, dateTimeFromBaseInfo.day)
            .subtract(Duration(days: 1));
        statisticsYear = yesterdayToBilledDay.year.toString();
        statisticsMonth = yesterdayToBilledDay.month.toString().length > 1
            ? yesterdayToBilledDay.month.toString()
            : '0${yesterdayToBilledDay.month.toString()}';
        statisticsDay = yesterdayToBilledDay.day.toString().length > 1
            ? yesterdayToBilledDay.day.toString()
            : '0${yesterdayToBilledDay.day.toString()}';
      }
    }

    List<String> dynamicTokensToStringToken() {
      Map<String, dynamic> allUserTokensMap = json.decode(
          Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .allUserTokensFromClass);

      List<String> tokensList = [];
      for (var tokens in allUserTokensMap.values) {
        tokensList.add(tokens.toString());
      }
      return tokensList;
    }

    void userInfoUpdaterInFireStore() {
      Map<String, dynamic> masterOrderMapToServer = HashMap();
      Map<String, dynamic> tempBasicInfoMap = HashMap();
      tempBasicInfoMap.addAll({'customerName': customername});
      tempBasicInfoMap.addAll({'customerMobileNumber': customermobileNumber});
      tempBasicInfoMap.addAll({'customerAddress': customeraddressline1});
      masterOrderMapToServer.addAll({'baseInfoMap': tempBasicInfoMap});
      FireStoreAddOrderInRunningOrderFolder(
              hotelName: widget.hotelName,
              seatingNumber: widget.itemsFromDoc,
              ordersMap: masterOrderMapToServer)
          .addOrder();
    }

    Widget buildUserInfoWidget() {
      return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Text('Customer name',
                    style: TextStyle(
                        fontWeight: FontWeight.w500, color: Colors.green)),
              ),
              Container(
                padding: EdgeInsets.all(10),
                child: TextField(
                  maxLength: 100,
                  controller: TextEditingController(text: customername),
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) {
                    customername = value;
                  },
                  decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Enter Username',
                          hintStyle: TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: Colors.green)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: Colors.green))),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: Text('Mobile Number', style: userInfoTextStyle),
              ),
              Container(
                padding: EdgeInsets.all(10),
                child: TextField(
                  maxLength: 20,
                  keyboardType: TextInputType.phone,
                  // controller: TextEditingController(text: customermobileNumber),
//ToUseNumberInputKeyboard,youNeedToDeclareControllerInsideStatefulWidgetItself
                  controller: _controller,
                  onChanged: (value) {
                    customermobileNumber = value.toString();
                  },
                  decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Enter Mobile Number',
                          hintStyle: TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: Colors.green)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: Colors.green))),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: Text('Address', style: userInfoTextStyle),
              ),
              Container(
                padding: EdgeInsets.all(10),
                child: TextField(
                  maxLength: 250,
                  controller: TextEditingController(text: customeraddressline1),
                  onChanged: (value) {
                    customeraddressline1 = value;
                  },
                  decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Enter Address',
                          hintStyle: TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: Colors.green)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: Colors.green))),
                ),
              ),
              Center(
                child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.green),
                    ),
                    onPressed: () {
                      userInfoUpdaterInFireStore();
                      Navigator.pop(context);
                    },
                    child: Text('Done')),
              )
            ],
          ),
        ),
      );
    }

    List<DropdownMenuItem<String>> getTableDropDownMenuItem() {
      List<DropdownMenuItem<String>> dropDownMenuItems = [
        DropdownMenuItem(
            child: Center(
              child: Text('Select',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
            ),
            value: 'Select')
      ];
      for (int i = 1;
          i <=
              (((json.decode(Provider.of<PrinterAndOtherDetailsProvider>(
                                      context,
                                      listen: false)
                                  .restaurantInfoDataFromClass)['tables'] +
                              4) ~/
                          4) +
                      1) *
                  4;
          i++) {
        if (!((widget.tableOrParcel == 'Table') &&
            (widget.tableOrParcelNumber == i))) {
          var newItem = DropdownMenuItem(
            child: Center(
              child: Text(i.toString(),
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: tablesAlreadyOccupied.contains(i.toString())
                          ? Colors.red
                          : Colors.black)),
            ),
            value: i.toString(),
          );
          dropDownMenuItems.add(newItem);
        }
      }
      return dropDownMenuItems;
    }

    List<DropdownMenuItem<String>> getParcelDropDownMenuItem() {
      List<DropdownMenuItem<String>> dropDownMenuItems = [
        DropdownMenuItem(
            child: Center(
              child: Text('Select',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
            ),
            value: 'Select')
      ];
      for (int i = 1;
          i <=
              (((json.decode(Provider.of<PrinterAndOtherDetailsProvider>(
                                      context,
                                      listen: false)
                                  .restaurantInfoDataFromClass)['tables'] +
                              4) ~/
                          4) +
                      1) *
                  4;
          i++) {
        if (!((widget.tableOrParcel == 'Parcel') &&
            (widget.tableOrParcelNumber == i))) {
          var newItem = DropdownMenuItem(
            child: Container(
                alignment: Alignment.centerLeft,
                child: Center(
                  child: Text(i.toString(),
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: parcelsAlreadyOccupied.contains(i.toString())
                              ? Colors.red
                              : Colors.black)),
                )),
            value: i.toString(),
          );
          dropDownMenuItems.add(newItem);
        }
      }
      return dropDownMenuItems;
    }

    void buildMoveTableOrParcelAlertDialogWidget() {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          elevation: 24.0,
          // backgroundColor: Colors.greenAccent,
          // shape: CircleBorder(),
          title: Column(
            children: [
              Center(
                  child: Text(
                'Move To',
                style: TextStyle(fontSize: 30.0),
              )),
              SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(width: 10),
                  Expanded(
                    // width: double.infinity,
                    child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: tableClickedTrueParcelClickedFalse
                              ? MaterialStateProperty.all(Colors.grey)
                              : MaterialStateProperty.all(Colors.green),
                        ),
                        onPressed: () {
                          setState(() {
                            tableClickedTrueParcelClickedFalse = false;
                            tableOrParcelToMoveTo = 'Select';
                          });
                          Navigator.pop(context);
                          buildMoveTableOrParcelAlertDialogWidget();
                        },
                        child: Text('Parcels')),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                      // width: double.infinity,
                      child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: tableClickedTrueParcelClickedFalse
                                ? MaterialStateProperty.all(Colors.green)
                                : MaterialStateProperty.all(Colors.grey),
                          ),
                          onPressed: () {
                            setState(() {
                              tableClickedTrueParcelClickedFalse = true;
                              tableOrParcelToMoveTo = 'Select';
                            });
                            Navigator.pop(context);
                            buildMoveTableOrParcelAlertDialogWidget();
                          },
                          child: Text('Tables'))),
                  SizedBox(width: 10)
                ],
              ),
              SizedBox(height: 10),
            ],
          ),
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            // width: 5,
            decoration: BoxDecoration(
                color: tableClickedTrueParcelClickedFalse
                    ? Colors.brown.shade100
                    : Colors.blueGrey,
//                Theme.of(context).primaryColor
                borderRadius: BorderRadius.circular(30)),
//WeHaveDropDownButtonInside
//UnderlineWillBeContainer
//InitiallyWhenWeOpen,TheValueAlwaysWillBe 0-BrowseMenu
//OnClicked,ItWillCheckTheValueOfThatItem&ScrollToThatIndex
            child: DropdownButtonFormField<String>(
              isDense: true,
              isExpanded: true,
              // underline: Container(),
              decoration: InputDecoration.collapsed(hintText: ''),
              dropdownColor: Colors.white,
              value: tableOrParcelToMoveTo,
              onChanged: (value) {
                setState(() {
                  tableOrParcelToMoveTo = value.toString();
                });
              },
              items: tableClickedTrueParcelClickedFalse
                  ? getTableDropDownMenuItem()
                  : getParcelDropDownMenuItem(),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.grey),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Cancel')),
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.green),
                    ),
                    onPressed: () {
                      if (noItemsInTable) {
                        Navigator.pop(innerContext);
                      } else {
                        //ThisIsIfAnyTableorParcelWasIndeedSelected
                        if (tableOrParcelToMoveTo != 'Select') {
                          print('inside select');
                          setState(() {
                            movePressed = true;
                          });

//ThisWillCloseTheDialogBox
                          Navigator.pop(context);
//ThisWillCloseTheEntireItemsScreen
                          Navigator.pop(innerContext);
// ThisIsIfWeAreMovingToTable
                          if (tableClickedTrueParcelClickedFalse) {
//ThisIsIfThereIsAlreadySomeoneSitingInTheTable
                            if (tablesAlreadyOccupied
                                .contains(tableOrParcelToMoveTo)) {
//ThisIsTheMapInServerThatNeedsToBeMoved
                              Map<String, dynamic>
                                  alreadyPresentOrderToBeMoved = HashMap();
                              String
                                  lastStringOfIDOfAlreadyPresentOrderToBeMoved =
                                  '';
                              for (var eachPresentTablesParcelsOccupied
                                  in presentTablesParcelsOccupied) {
                                if (eachPresentTablesParcelsOccupied[
                                            'partOfTableOrParcel'] ==
                                        'Table' &&
                                    eachPresentTablesParcelsOccupied[
                                            'partOfTableOrParcelNumber'] ==
                                        tableOrParcelToMoveTo) {
//NoMatterHowManyItemsAreThereWithThisTableAndParcelNumber
//WhenItComesInOrder,WeOnlyNeedTheLastOne.
//So,NotMakingList.SimplyStoringItAllInOneMapOnly
                                  alreadyPresentOrderToBeMoved['baseInfoMap'] =
                                      eachPresentTablesParcelsOccupied[
                                          'baseInfoMap'];
                                  alreadyPresentOrderToBeMoved[
                                          'itemsInOrderMap'] =
                                      eachPresentTablesParcelsOccupied[
                                          'itemsInOrderMap'];
                                  alreadyPresentOrderToBeMoved['statusMap'] =
                                      eachPresentTablesParcelsOccupied[
                                          'statusMap'];
                                  alreadyPresentOrderToBeMoved['ticketsMap'] =
                                      eachPresentTablesParcelsOccupied[
                                          'ticketsMap'];
                                  alreadyPresentOrderToBeMoved[
                                          'partOfTableOrParcel'] =
                                      eachPresentTablesParcelsOccupied[
                                          'partOfTableOrParcel'];
                                  alreadyPresentOrderToBeMoved[
                                          'partOfTableOrParcelNumber'] =
                                      eachPresentTablesParcelsOccupied[
                                          'partOfTableOrParcelNumber'];
                                  alreadyPresentOrderToBeMoved[
                                          'presentOccupiedTablesParcelsID'] =
                                      eachPresentTablesParcelsOccupied[
                                          'presentOccupiedTablesParcelsID'];
                                  lastStringOfIDOfAlreadyPresentOrderToBeMoved =
                                      eachPresentTablesParcelsOccupied[
                                              'presentOccupiedTablesParcelsID']
                                          .toString()[eachPresentTablesParcelsOccupied[
                                                  'presentOccupiedTablesParcelsID']
                                              .toString()
                                              .length -
                                          1];
                                }
                              }
//TrueMeansLastCharOfDocNameIsLetter...
// ...WeAreMovingToATable/ParcelThatWasAlreadySplit
                              if (lastStringOfIDOfAlreadyPresentOrderToBeMoved
                                  .contains(RegExp(r'[A-Z]'))) {
//WeAreEnsuringThatTheUpdateIsMadeAsTheNextAlphabetInTheAlreadyPresentTable
//AndAlsoEnsuringTableNumberIsChanged
                                Map<String, dynamic> tempBaseInfoMap =
                                    baseInfoFromServerMap;
                                tempBaseInfoMap['tableOrParcel'] = 'Table';
                                tempBaseInfoMap['tableOrParcelNumber'] =
                                    tableOrParcelToMoveTo;
                                tempBaseInfoMap['parentOrChild'] =
                                    String.fromCharCode(
                                        (lastStringOfIDOfAlreadyPresentOrderToBeMoved
                                                .codeUnitAt(0)) +
                                            1);
                                Map<String, dynamic> tempMasterUpdaterMap =
                                    HashMap();
                                tempMasterUpdaterMap
                                    .addAll({'baseInfoMap': tempBaseInfoMap});
                                tempMasterUpdaterMap.addAll({
                                  'itemsInOrderMap': itemsInOrderFromServerMap
                                });
                                tempMasterUpdaterMap.addAll({
                                  'cancelledItemsInOrder':
                                      cancelledItemsInOrderFromServerMap
                                });
                                tempMasterUpdaterMap
                                    .addAll({'statusMap': statusFromServerMap});
                                tempMasterUpdaterMap.addAll(
                                    {'ticketsMap': ticketsFromServerMap});
                                tempMasterUpdaterMap
                                    .addAll({'partOfTableOrParcel': 'Table'});
                                tempMasterUpdaterMap.addAll({
                                  'partOfTableOrParcelNumber':
                                      tableOrParcelToMoveTo
                                });
                                FireStoreAddOrderInRunningOrderFolder(
                                        hotelName: widget.hotelName,
                                        seatingNumber:
                                            'Table:${tableOrParcelToMoveTo}${String.fromCharCode((lastStringOfIDOfAlreadyPresentOrderToBeMoved.codeUnitAt(0)) + 1)}',
                                        ordersMap: tempMasterUpdaterMap)
                                    .addOrder();

                                FireStoreDeleteFinishedOrderInRunningOrders(
                                        hotelName: widget.hotelName,
                                        eachTableId: widget.itemsFromDoc)
                                    .deleteFinishedOrder();
                              } else {
//WeAreMovingToTableWhichIsYetToBeSplitted
//First,StoringThatATableWithAAsThoughItWasSplit

                                alreadyPresentOrderToBeMoved['baseInfoMap']
                                    ['parentOrChild'] = 'A';
                                Map<String, dynamic> tempMasterUpdaterMap =
                                    HashMap();
                                tempMasterUpdaterMap.addAll({
                                  'baseInfoMap': alreadyPresentOrderToBeMoved[
                                      'baseInfoMap']
                                });
                                tempMasterUpdaterMap.addAll({
                                  'itemsInOrderMap':
                                      alreadyPresentOrderToBeMoved[
                                          'itemsInOrderMap']
                                });
                                tempMasterUpdaterMap.addAll({
                                  'statusMap':
                                      alreadyPresentOrderToBeMoved['statusMap']
                                });
                                tempMasterUpdaterMap.addAll({
                                  'ticketsMap':
                                      alreadyPresentOrderToBeMoved['ticketsMap']
                                });
                                tempMasterUpdaterMap
                                    .addAll({'partOfTableOrParcel': 'Table'});
                                tempMasterUpdaterMap.addAll({
                                  'partOfTableOrParcelNumber':
                                      tableOrParcelToMoveTo
                                });
                                FireStoreAddOrderInRunningOrderFolder(
                                        hotelName: widget.hotelName,
                                        seatingNumber:
                                            'Table:${tableOrParcelToMoveTo}A',
                                        ordersMap: tempMasterUpdaterMap)
                                    .addOrder();

//WeNeedToDeleteTheOrderBeforeWeHadResavedItAsSplitOne
                                FireStoreDeleteFinishedOrderInRunningOrders(
                                        hotelName: widget.hotelName,
                                        eachTableId: alreadyPresentOrderToBeMoved[
                                            'presentOccupiedTablesParcelsID'])
                                    .deleteFinishedOrder();
                                // Navigator.pop(context);
                                // Navigator.pop(innerContext);

                                Map<String, dynamic> tempBaseInfoMap =
                                    baseInfoFromServerMap;
                                tempBaseInfoMap['tableOrParcel'] = 'Table';
                                tempBaseInfoMap['tableOrParcelNumber'] =
                                    tableOrParcelToMoveTo;
                                tempBaseInfoMap['parentOrChild'] = 'B';
                                Map<String, dynamic>
                                    tempSecondMasterUpdaterMap = HashMap();
                                tempSecondMasterUpdaterMap
                                    .addAll({'baseInfoMap': tempBaseInfoMap});
                                tempSecondMasterUpdaterMap.addAll({
                                  'itemsInOrderMap': itemsInOrderFromServerMap
                                });
                                tempSecondMasterUpdaterMap.addAll({
                                  'cancelledItemsInOrder':
                                      cancelledItemsInOrderFromServerMap
                                });
                                tempSecondMasterUpdaterMap
                                    .addAll({'statusMap': statusFromServerMap});
                                tempSecondMasterUpdaterMap.addAll(
                                    {'ticketsMap': ticketsFromServerMap});
                                tempSecondMasterUpdaterMap
                                    .addAll({'partOfTableOrParcel': 'Table'});
                                tempSecondMasterUpdaterMap.addAll({
                                  'partOfTableOrParcelNumber':
                                      tableOrParcelToMoveTo
                                });

                                FireStoreAddOrderInRunningOrderFolder(
                                        hotelName: widget.hotelName,
                                        seatingNumber:
                                            'Table:${tableOrParcelToMoveTo}B',
                                        ordersMap: tempSecondMasterUpdaterMap)
                                    .addOrder();

                                FireStoreDeleteFinishedOrderInRunningOrders(
                                        hotelName: widget.hotelName,
                                        eachTableId: widget.itemsFromDoc)
                                    .deleteFinishedOrder();
                              }
                            } else {
//IfThereIsNoOneSittingInTheTableAlready
//IfTheOrderWeAremovingIsFromAnAlreadySplitTable,
//ItShouldBeEnsured,ItIsMovedAsAParentToTheNoOneOccupiedTable
                              Map<String, dynamic> tempBaseInfoMap =
                                  baseInfoFromServerMap;
                              tempBaseInfoMap['tableOrParcel'] = 'Table';
                              tempBaseInfoMap['tableOrParcelNumber'] =
                                  tableOrParcelToMoveTo;
                              tempBaseInfoMap['parentOrChild'] = 'parent';
                              Map<String, dynamic> tempSecondMasterUpdaterMap =
                                  HashMap();
                              tempSecondMasterUpdaterMap
                                  .addAll({'baseInfoMap': tempBaseInfoMap});
                              tempSecondMasterUpdaterMap.addAll({
                                'itemsInOrderMap': itemsInOrderFromServerMap
                              });
                              tempSecondMasterUpdaterMap.addAll({
                                'cancelledItemsInOrder':
                                    cancelledItemsInOrderFromServerMap
                              });

                              tempSecondMasterUpdaterMap
                                  .addAll({'statusMap': statusFromServerMap});
                              tempSecondMasterUpdaterMap
                                  .addAll({'ticketsMap': ticketsFromServerMap});
                              tempSecondMasterUpdaterMap
                                  .addAll({'partOfTableOrParcel': 'Table'});
                              tempSecondMasterUpdaterMap.addAll({
                                'partOfTableOrParcelNumber':
                                    tableOrParcelToMoveTo
                              });

                              FireStoreAddOrderInRunningOrderFolder(
                                      hotelName: widget.hotelName,
                                      seatingNumber:
                                          'Table:${tableOrParcelToMoveTo}',
                                      ordersMap: tempSecondMasterUpdaterMap)
                                  .addOrder();

//deletingTheOrderFromOldPlaceInServer

                              FireStoreDeleteFinishedOrderInRunningOrders(
                                      hotelName: widget.hotelName,
                                      eachTableId: widget.itemsFromDoc)
                                  .deleteFinishedOrder();
                            }
                          } else {
//ThisIsIfWeAreMovingToParcel
                            //ThisIsIfThereIsAlreadySomeoneSitingInTheParcel
                            if (parcelsAlreadyOccupied
                                .contains(tableOrParcelToMoveTo)) {
//ThisIsTheMapInServerThatNeedsToBeMoved
                              Map<String, dynamic>
                                  alreadyPresentOrderToBeMoved = HashMap();
                              String
                                  lastStringOfIDOfAlreadyPresentOrderToBeMoved =
                                  '';
                              for (var eachPresentTablesParcelsOccupied
                                  in presentTablesParcelsOccupied) {
                                if (eachPresentTablesParcelsOccupied[
                                            'partOfTableOrParcel'] ==
                                        'Parcel' &&
                                    eachPresentTablesParcelsOccupied[
                                            'partOfTableOrParcelNumber'] ==
                                        tableOrParcelToMoveTo) {
//NoMatterHowManyItemsAreThereWithThisTableAndParcelNumber
//WhenItComesInOrder,WeOnlyNeedTheLastOne.
//So,NotMakingList.SimplyStoringItAllInOneMapOnly
                                  alreadyPresentOrderToBeMoved['baseInfoMap'] =
                                      eachPresentTablesParcelsOccupied[
                                          'baseInfoMap'];
                                  alreadyPresentOrderToBeMoved[
                                          'itemsInOrderMap'] =
                                      eachPresentTablesParcelsOccupied[
                                          'itemsInOrderMap'];
                                  alreadyPresentOrderToBeMoved['statusMap'] =
                                      eachPresentTablesParcelsOccupied[
                                          'statusMap'];
                                  alreadyPresentOrderToBeMoved['ticketsMap'] =
                                      eachPresentTablesParcelsOccupied[
                                          'ticketsMap'];
                                  alreadyPresentOrderToBeMoved[
                                          'partOfTableOrParcel'] =
                                      eachPresentTablesParcelsOccupied[
                                          'partOfTableOrParcel'];
                                  alreadyPresentOrderToBeMoved[
                                          'partOfTableOrParcelNumber'] =
                                      eachPresentTablesParcelsOccupied[
                                          'partOfTableOrParcelNumber'];
                                  alreadyPresentOrderToBeMoved[
                                          'presentOccupiedTablesParcelsID'] =
                                      eachPresentTablesParcelsOccupied[
                                          'presentOccupiedTablesParcelsID'];
                                  lastStringOfIDOfAlreadyPresentOrderToBeMoved =
                                      eachPresentTablesParcelsOccupied[
                                              'presentOccupiedTablesParcelsID']
                                          .toString()[eachPresentTablesParcelsOccupied[
                                                  'presentOccupiedTablesParcelsID']
                                              .toString()
                                              .length -
                                          1];
                                }
                              }
//TrueMeansWeAreMovingToATable/ParcelThatWasAlreadySplit
                              if (lastStringOfIDOfAlreadyPresentOrderToBeMoved
                                  .contains(RegExp(r'[A-Z]'))) {
//WeAreEnsuringThatTheUpdateIsMadeAsTheNextAlphabetInTheAlreadyPresentParcel
//AndAlsoEnsuringTableNumberIsChanged
                                Map<String, dynamic> tempBaseInfoMap =
                                    baseInfoFromServerMap;
                                tempBaseInfoMap['tableOrParcel'] = 'Parcel';
                                tempBaseInfoMap['tableOrParcelNumber'] =
                                    tableOrParcelToMoveTo;
                                tempBaseInfoMap['parentOrChild'] =
                                    String.fromCharCode(
                                        (lastStringOfIDOfAlreadyPresentOrderToBeMoved
                                                .codeUnitAt(0)) +
                                            1);
                                Map<String, dynamic> tempMasterUpdaterMap =
                                    HashMap();
                                tempMasterUpdaterMap
                                    .addAll({'baseInfoMap': tempBaseInfoMap});
                                tempMasterUpdaterMap.addAll({
                                  'itemsInOrderMap': itemsInOrderFromServerMap
                                });
                                tempMasterUpdaterMap.addAll({
                                  'cancelledItemsInOrder':
                                      cancelledItemsInOrderFromServerMap
                                });
                                tempMasterUpdaterMap
                                    .addAll({'statusMap': statusFromServerMap});
                                tempMasterUpdaterMap.addAll(
                                    {'ticketsMap': ticketsFromServerMap});
                                tempMasterUpdaterMap
                                    .addAll({'partOfTableOrParcel': 'Parcel'});
                                tempMasterUpdaterMap.addAll({
                                  'partOfTableOrParcelNumber':
                                      tableOrParcelToMoveTo
                                });
                                FireStoreAddOrderInRunningOrderFolder(
                                        hotelName: widget.hotelName,
                                        seatingNumber:
                                            'Parcel:${tableOrParcelToMoveTo}${String.fromCharCode((lastStringOfIDOfAlreadyPresentOrderToBeMoved.codeUnitAt(0)) + 1)}',
                                        ordersMap: tempMasterUpdaterMap)
                                    .addOrder();

                                FireStoreDeleteFinishedOrderInRunningOrders(
                                        hotelName: widget.hotelName,
                                        eachTableId: widget.itemsFromDoc)
                                    .deleteFinishedOrder();
                              } else {
//WeAreMovingToTableWhichIsYetToBeSplitted
//First,StoringThatATableWithAAsThoughItWasSplit

                                alreadyPresentOrderToBeMoved['baseInfoMap']
                                    ['parentOrChild'] = 'A';
                                Map<String, dynamic> tempMasterUpdaterMap =
                                    HashMap();
                                tempMasterUpdaterMap.addAll({
                                  'baseInfoMap': alreadyPresentOrderToBeMoved[
                                      'baseInfoMap']
                                });
                                tempMasterUpdaterMap.addAll({
                                  'itemsInOrderMap':
                                      alreadyPresentOrderToBeMoved[
                                          'itemsInOrderMap']
                                });
                                tempMasterUpdaterMap.addAll({
                                  'statusMap':
                                      alreadyPresentOrderToBeMoved['statusMap']
                                });
                                tempMasterUpdaterMap.addAll({
                                  'ticketsMap':
                                      alreadyPresentOrderToBeMoved['ticketsMap']
                                });
                                tempMasterUpdaterMap
                                    .addAll({'partOfTableOrParcel': 'Parcel'});
                                tempMasterUpdaterMap.addAll({
                                  'partOfTableOrParcelNumber':
                                      tableOrParcelToMoveTo
                                });
                                FireStoreAddOrderInRunningOrderFolder(
                                        hotelName: widget.hotelName,
                                        seatingNumber:
                                            'Parcel:${tableOrParcelToMoveTo}A',
                                        ordersMap: tempMasterUpdaterMap)
                                    .addOrder();

//WeNeedToDeleteTheOrderBeforeWeHadResavedItAsSplitOne
                                FireStoreDeleteFinishedOrderInRunningOrders(
                                        hotelName: widget.hotelName,
                                        eachTableId: alreadyPresentOrderToBeMoved[
                                            'presentOccupiedTablesParcelsID'])
                                    .deleteFinishedOrder();
                                // Navigator.pop(context);
                                // Navigator.pop(innerContext);

                                Map<String, dynamic> tempBaseInfoMap =
                                    baseInfoFromServerMap;
                                tempBaseInfoMap['tableOrParcel'] = 'Parcel';
                                tempBaseInfoMap['tableOrParcelNumber'] =
                                    tableOrParcelToMoveTo;
                                tempBaseInfoMap['parentOrChild'] = 'B';
                                Map<String, dynamic>
                                    tempSecondMasterUpdaterMap = HashMap();
                                tempSecondMasterUpdaterMap
                                    .addAll({'baseInfoMap': tempBaseInfoMap});
                                tempSecondMasterUpdaterMap.addAll({
                                  'itemsInOrderMap': itemsInOrderFromServerMap
                                });
                                tempSecondMasterUpdaterMap.addAll({
                                  'cancelledItemsInOrder':
                                      cancelledItemsInOrderFromServerMap
                                });

                                tempSecondMasterUpdaterMap
                                    .addAll({'statusMap': statusFromServerMap});
                                tempSecondMasterUpdaterMap.addAll(
                                    {'ticketsMap': ticketsFromServerMap});
                                tempSecondMasterUpdaterMap
                                    .addAll({'partOfTableOrParcel': 'Parcel'});
                                tempSecondMasterUpdaterMap.addAll({
                                  'partOfTableOrParcelNumber':
                                      tableOrParcelToMoveTo
                                });

                                FireStoreAddOrderInRunningOrderFolder(
                                        hotelName: widget.hotelName,
                                        seatingNumber:
                                            'Parcel:${tableOrParcelToMoveTo}B',
                                        ordersMap: tempSecondMasterUpdaterMap)
                                    .addOrder();

                                FireStoreDeleteFinishedOrderInRunningOrders(
                                        hotelName: widget.hotelName,
                                        eachTableId: widget.itemsFromDoc)
                                    .deleteFinishedOrder();
                              }
                            } else {
//IfThereIsNoOneSittingInTheTableAlready
//IfTheOrderWeAremovingIsFromAnAlreadySplitTable,
//ItShouldBeEnsured,ItIsMovedAsAParentToTheNoOneOccupiedTable
                              // Navigator.pop(context);
                              // Navigator.pop(innerContext);

                              Map<String, dynamic> tempBaseInfoMap =
                                  baseInfoFromServerMap;
                              tempBaseInfoMap['tableOrParcel'] = 'Parcel';
                              tempBaseInfoMap['tableOrParcelNumber'] =
                                  tableOrParcelToMoveTo;
                              tempBaseInfoMap['parentOrChild'] = 'parent';
                              Map<String, dynamic> tempSecondMasterUpdaterMap =
                                  HashMap();
                              tempSecondMasterUpdaterMap
                                  .addAll({'baseInfoMap': tempBaseInfoMap});
                              tempSecondMasterUpdaterMap.addAll({
                                'itemsInOrderMap': itemsInOrderFromServerMap
                              });
                              tempSecondMasterUpdaterMap.addAll({
                                'cancelledItemsInOrder':
                                    cancelledItemsInOrderFromServerMap
                              });
                              tempSecondMasterUpdaterMap
                                  .addAll({'statusMap': statusFromServerMap});
                              tempSecondMasterUpdaterMap
                                  .addAll({'ticketsMap': ticketsFromServerMap});
                              tempSecondMasterUpdaterMap
                                  .addAll({'partOfTableOrParcel': 'Parcel'});
                              tempSecondMasterUpdaterMap.addAll({
                                'partOfTableOrParcelNumber':
                                    tableOrParcelToMoveTo
                              });

                              FireStoreAddOrderInRunningOrderFolder(
                                      hotelName: widget.hotelName,
                                      seatingNumber:
                                          'Parcel:${tableOrParcelToMoveTo}',
                                      ordersMap: tempSecondMasterUpdaterMap)
                                  .addOrder();
                              FireStoreDeleteFinishedOrderInRunningOrders(
                                      hotelName: widget.hotelName,
                                      eachTableId: widget.itemsFromDoc)
                                  .deleteFinishedOrder();
                            }
                          }
                        } else {
                          Navigator.pop(context);
                        }
                      }
                    },
                    child: Text('Move'))
              ],
            ),
          ],
        ),
        barrierDismissible: false,
      );
    }

    String billIdOfThisOrder() {
      DateTime now = DateTime.now();

      if (baseInfoFromServerMap['billYear'] == '') {
        billYear = now.year.toString();
      } else {
        billYear = baseInfoFromServerMap['billYear'];
      }
      if (baseInfoFromServerMap['billMonth'] == '') {
        billMonth = now.month < 10
            ? '0${now.month.toString()}'
            : '${now.month.toString()}';
      } else {
        billMonth = baseInfoFromServerMap['billMonth'];
      }
      if (baseInfoFromServerMap['billDay'] == '') {
        billDay =
            now.day < 10 ? '0${now.day.toString()}' : '${now.day.toString()}';
      } else {
        billDay = baseInfoFromServerMap['billDay'];
      }
      if (baseInfoFromServerMap['billHour'] == '') {
        billHour = now.hour < 10
            ? '0${now.hour.toString()}'
            : '${now.hour.toString()}';
      } else {
        billHour = baseInfoFromServerMap['billHour'];
      }
      if (baseInfoFromServerMap['billMinute'] == '') {
        billMinute = now.minute < 10
            ? '0${now.minute.toString()}'
            : '${now.minute.toString()}';
      } else {
        billMinute = baseInfoFromServerMap['billMinute'];
      }
      if (baseInfoFromServerMap['billSecond'] == '') {
        billSecond = now.second < 10
            ? '0${now.second.toString()}'
            : '${now.second.toString()}';
      } else {
        billSecond = baseInfoFromServerMap['billSecond'];
      }
      String orderStartTimeForCreatingDocId =
          baseInfoFromServerMap['startTime'];
      if (orderStartTimeForCreatingDocId.length < 8) {
        for (int i = orderStartTimeForCreatingDocId.length; i < 8; i++) {
          orderStartTimeForCreatingDocId = '0' + orderStartTimeForCreatingDocId;
        }
      }
      return '${billYear}${billMonth}${billDay}${orderStartTimeForCreatingDocId}';
    }

    void splitTableOrParcel() async {
      if (noItemsInTable) {
        Navigator.pop(context);
      } else {
        try {
          documentStatisticsRegistryDateMaker();
          final docIdCheckSnapshot = await FirebaseFirestore.instance
              .collection(widget.hotelName)
              .doc('salesBills')
              .collection(statisticsYear)
              .doc(statisticsMonth)
              .collection(statisticsDay)
              .doc(billIdOfThisOrder())
              .get()
              .timeout(Duration(seconds: 5));
          if (docIdCheckSnapshot == null || !docIdCheckSnapshot.exists) {
            setState(() {
              splitPressed = true;
            });
            if (parentOrChild == 'parent') {
              Map<String, dynamic> tempBaseInfoMap = baseInfoFromServerMap;
              tempBaseInfoMap['parentOrChild'] = 'A';
              Map<String, dynamic> tempSecondMasterUpdaterMap = HashMap();
              tempSecondMasterUpdaterMap
                  .addAll({'baseInfoMap': tempBaseInfoMap});
              tempSecondMasterUpdaterMap
                  .addAll({'itemsInOrderMap': itemsInOrderFromServerMap});
              tempSecondMasterUpdaterMap.addAll({
                'cancelledItemsInOrder': cancelledItemsInOrderFromServerMap
              });
              tempSecondMasterUpdaterMap
                  .addAll({'statusMap': statusFromServerMap});
              tempSecondMasterUpdaterMap
                  .addAll({'ticketsMap': ticketsFromServerMap});
              tempSecondMasterUpdaterMap
                  .addAll({'partOfTableOrParcel': partOfTableOrParcelFromMap});
              tempSecondMasterUpdaterMap.addAll({
                'partOfTableOrParcelNumber': partOfTableOrParcelNumberFromMap
              });

              FireStoreAddOrderInRunningOrderFolder(
                      hotelName: widget.hotelName,
                      seatingNumber:
                          '${widget.tableOrParcel}:${widget.tableOrParcelNumber}A',
                      ordersMap: tempSecondMasterUpdaterMap)
                  .addOrder();

              // Navigator.pop(context);

              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => TableOrParcelSplitWithRunningOrders(
                            hotelName: widget.hotelName,
                            partOfTableOrParcel: widget.tableOrParcel,
                            partOfTableOrParcelNumber:
                                widget.tableOrParcelNumber.toString(),
                            menuItems: widget.menuItems,
                            menuTitles: widget.menuTitles,
                            menuPrices: widget.menuPrices,
                          )));

              FireStoreDeleteFinishedOrderInRunningOrders(
                      hotelName: widget.hotelName,
                      eachTableId: widget.itemsFromDoc)
                  .deleteFinishedOrder();
            } else {
              // int count = 0;
              // Navigator.of(context)
              //     .popUntil((_) => count++ >= 2);
              Navigator.pop(context);
            }
          } else {
//thisMeansTableAlreadyClosedButExistingInThisUserPhoneForSomeReason
            show('Bill Already Closed. Kindly Check');
          }
        } catch (e) {
          show('Please check Internet. Unable to reach server');
        }
      }
    }

    void moveTableOrParcel() async {
      try {
        documentStatisticsRegistryDateMaker();

        final docIdCheckSnapshot = await FirebaseFirestore.instance
            .collection(widget.hotelName)
            .doc('salesBills')
            .collection(statisticsYear)
            .doc(statisticsMonth)
            .collection(statisticsDay)
            .doc(billIdOfThisOrder())
            .get()
            .timeout(Duration(seconds: 5));
        if (docIdCheckSnapshot == null || !docIdCheckSnapshot.exists) {
          final tablesParcelsOccupied = await FirebaseFirestore.instance
              .collection(widget.hotelName)
              .doc('runningorders')
              .collection('runningorders')
              .get();
          presentTablesParcelsOccupied = [];
          Map<String, dynamic> mapToAddPresentTablesParcels = {};
          for (var eachTableParcelOccupied in tablesParcelsOccupied.docs) {
            mapToAddPresentTablesParcels['baseInfoMap'] =
                eachTableParcelOccupied['baseInfoMap'];
            mapToAddPresentTablesParcels['itemsInOrderMap'] =
                eachTableParcelOccupied['itemsInOrderMap'];
            mapToAddPresentTablesParcels['statusMap'] =
                eachTableParcelOccupied['statusMap'];
            mapToAddPresentTablesParcels['ticketsMap'] =
                eachTableParcelOccupied['ticketsMap'];
            mapToAddPresentTablesParcels['partOfTableOrParcel'] =
                eachTableParcelOccupied['partOfTableOrParcel'];
            mapToAddPresentTablesParcels['partOfTableOrParcelNumber'] =
                eachTableParcelOccupied['partOfTableOrParcelNumber'];
            mapToAddPresentTablesParcels['presentOccupiedTablesParcelsID'] =
                eachTableParcelOccupied.id;

            if (eachTableParcelOccupied['partOfTableOrParcel'] == 'Table') {
              tablesAlreadyOccupied
                  .add(eachTableParcelOccupied['partOfTableOrParcelNumber']);
            }
            if (eachTableParcelOccupied['partOfTableOrParcel'] == 'Parcel') {
              parcelsAlreadyOccupied
                  .add(eachTableParcelOccupied['partOfTableOrParcelNumber']);
            }
            presentTablesParcelsOccupied.insert(
                presentTablesParcelsOccupied.length,
                mapToAddPresentTablesParcels);
            mapToAddPresentTablesParcels = {};
          }

          // Navigator.pop(context);

          buildMoveTableOrParcelAlertDialogWidget();
        } else {
//thisMeansTableAlreadyClosedButExistingInThisUserPhoneForSomeReason
          show('Bill Already Closed. Kindly Check');
        }
      } catch (e) {
        show('Please check Internet. Unable to reach server');
      }
    }

    List<Map<String, dynamic>> cancelledMapsForServerUpdate(
        String lastItemId, num lastItemStatus) {
      List<Map<String, dynamic>> cancellingUpdateMapsList = [];
      Map<String, dynamic> tempAllCancelledItems =
          cancelledItemsInOrderFromServerMap;
      Map<String, dynamic> tempItemMapForCancel =
          itemsInOrderFromServerMap[lastItemId];
      if (lastItemStatus != 11) {
        tempItemMapForCancel['cancellingCaptainName'] = json.decode(
                Provider.of<PrinterAndOtherDetailsProvider>(context,
                        listen: false)
                    .allUserProfilesFromClass)[
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .currentUserPhoneNumberFromClass]['username'];
        tempItemMapForCancel['cancellingCaptainPhone'] =
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .currentUserPhoneNumberFromClass;
      }
      tempAllCancelledItems.addAll({lastItemId: tempItemMapForCancel});
      Map<String, dynamic> captainCancellationMap = HashMap();
      Map<String, dynamic> chefRejectionMap = HashMap();
      Map<String, dynamic> itemsCancellationMap = HashMap();

      tempAllCancelledItems.forEach((key, value) {
        if (itemsCancellationMap.containsKey(value['itemName'])) {
          itemsCancellationMap[value['itemName']]!['numberOfTimes']!.add(1);
          itemsCancellationMap[value['itemName']]!['numberOfItems']!
              .add(value['numberOfItem']);
          itemsCancellationMap[value['itemName']]!['totalAmount']!
              .add(value['numberOfItem'] * value['itemPrice']);
        } else {
          itemsCancellationMap.addAll({
            value['itemName']: {
              'numberOfTimes': [1],
              'numberOfItems': [value['numberOfItem']],
              'totalAmount': [value['numberOfItem'] * value['itemPrice']]
            },
          });
        }

        if (value['rejectingChefPhone'] != 'notRejected') {
//thisMeansItsRejectedByChefAndHenceCancelledByCaptain
          if (chefRejectionMap.containsKey(value['rejectingChefPhone'])) {
            final tempIndividualItemsRejected =
                chefRejectionMap[value['rejectingChefPhone']]
                    ['individualItemsRejected'];
            if (tempIndividualItemsRejected.containsKey(value['itemName'])) {
              tempIndividualItemsRejected[value['itemName']] = {
                'numberOfIndividualItems':
                    tempIndividualItemsRejected[value['itemName']]
                            ['numberOfIndividualItems'] +
                        value['numberOfItem'],
                'totalAmountOfIndividualItems': tempIndividualItemsRejected[value['itemName']]
                        ['totalAmountOfIndividualItems'] +
                    (value['numberOfItem'] * value['itemPrice'])
              };
            } else {
              tempIndividualItemsRejected.addAll({
                value['itemName'].toString(): {
                  'numberOfIndividualItems': value['numberOfItem'],
                  'totalAmountOfIndividualItems':
                      value['numberOfItem'] * value['itemPrice']
                }
              });
            }

            chefRejectionMap[value['rejectingChefPhone']]!['numberOfTimes']!
                .add(1);
            chefRejectionMap[value['rejectingChefPhone']]!['numberOfItems']!
                .add(value['numberOfItem']);
            chefRejectionMap[value['rejectingChefPhone']]!['totalAmount']!
                .add(value['numberOfItem'] * value['itemPrice']);
            chefRejectionMap[value['rejectingChefPhone']]
                ['individualItemsRejected'] = tempIndividualItemsRejected;
          } else {
            chefRejectionMap.addAll({
              value['rejectingChefPhone']: {
                'numberOfTimes': [1],
                'numberOfItems': [value['numberOfItem']],
                'totalAmount': [value['numberOfItem'] * value['itemPrice']],
                'individualItemsRejected': {
                  value['itemName'].toString(): {
                    'numberOfIndividualItems': value['numberOfItem'],
                    'totalAmountOfIndividualItems':
                        value['numberOfItem'] * value['itemPrice']
                  }
                }
              },
            });
          }
        } else {
          if (captainCancellationMap
              .containsKey(value['cancellingCaptainPhone'])) {
//ThisMapToCreateWhatAllItemsEachCaptainCancelled
            final tempIndividualItemsCancelled =
                captainCancellationMap[value['cancellingCaptainPhone']]
                    ['individualItemsCancelled'];
            if (tempIndividualItemsCancelled.containsKey(value['itemName'])) {
              tempIndividualItemsCancelled[value['itemName']] = {
                'numberOfIndividualItems':
                    tempIndividualItemsCancelled[value['itemName']]
                            ['numberOfIndividualItems'] +
                        value['numberOfItem'],
                'totalAmountOfIndividualItems':
                    tempIndividualItemsCancelled[value['itemName']]
                            ['totalAmountOfIndividualItems'] +
                        (value['numberOfItem'] * value['itemPrice'])
              };
            } else {
              tempIndividualItemsCancelled.addAll({
                value['itemName'].toString(): {
                  'numberOfIndividualItems': value['numberOfItem'],
                  'totalAmountOfIndividualItems':
                      value['numberOfItem'] * value['itemPrice']
                }
              });
            }
            captainCancellationMap[value['cancellingCaptainPhone']]![
                    'numberOfTimes']!
                .add(1);
            captainCancellationMap[value['cancellingCaptainPhone']]![
                    'numberOfItems']!
                .add(value['numberOfItem']);
            captainCancellationMap[value['cancellingCaptainPhone']]![
                    'totalAmount']!
                .add(value['numberOfItem'] * value['itemPrice']);
            captainCancellationMap[value['cancellingCaptainPhone']]
                ['individualItemsCancelled'] = tempIndividualItemsCancelled;
          } else
          {
            captainCancellationMap.addAll({
              value['cancellingCaptainPhone']: {
                'numberOfTimes': [1],
                'numberOfItems': [value['numberOfItem']],
                'totalAmount': [value['numberOfItem'] * value['itemPrice']],
                'individualItemsCancelled': {
                  value['itemName'].toString(): {
                    'numberOfIndividualItems': value['numberOfItem'],
                    'totalAmountOfIndividualItems':
                        value['numberOfItem'] * value['itemPrice']
                  }
                }
              },
            });
          }
        }
      });

      cancellingUpdateMapsList.add(itemsCancellationMap);
      cancellingUpdateMapsList.add(captainCancellationMap);
      cancellingUpdateMapsList.add(chefRejectionMap);
      cancellingUpdateMapsList.add(tempAllCancelledItems);
      return cancellingUpdateMapsList;
    }

    Future<void> allItemsCancellingUpdateInServer(
        String lastItemId, num lastItemStatus) async {
      bool hasInternet = await InternetConnectionChecker().hasConnection;

      if (hasInternet) {
        if (noItemsInTable) {
          Navigator.pop(context);
        } else {
          List<Map<String, dynamic>> cancellationUpdateMaps =
              cancelledMapsForServerUpdate(lastItemId, lastItemStatus);
          Map<String, dynamic> printOrdersMap = HashMap();

          //ThisMeansItsAnPrintedBill
          if (baseInfoFromServerMap['serialNumber'] != 'noSerialYet') {
            try {
              documentStatisticsRegistryDateMaker();
              final docIdCheckSnapshot = await FirebaseFirestore.instance
                  .collection(widget.hotelName)
                  .doc('salesBills')
                  .collection(statisticsYear)
                  .doc(statisticsMonth)
                  .collection(statisticsDay)
                  .doc(billIdOfThisOrder())
                  .get()
                  .timeout(Duration(seconds: 5));
              if (docIdCheckSnapshot == null || !docIdCheckSnapshot.exists) {
                printOrdersMap.addAll({
                  ' Date of Order  :':
                      '$billYear/$billMonth/$billDay at ${DateTime.now().hour.toString()}:${DateTime.now().minute.toString()}'
                });
                Map<String, dynamic> itemCancellationMap =
                    cancellationUpdateMaps[0];
                Map<String, dynamic> captainCancellationMap =
                    cancellationUpdateMaps[1];
                Map<String, dynamic> chefRejectionMap =
                    cancellationUpdateMaps[2];
                Map<String, dynamic> cancelledItemsInOrder =
                    cancellationUpdateMaps[3];

                Map<String, dynamic> itemCancellationMapForServerUpdate =
                    HashMap();
                itemCancellationMap.forEach((key, value) {
                  List<dynamic> tempNumberOfTimes = value['numberOfTimes'];
                  List<dynamic> tempNumberOfItems = value['numberOfItems'];
                  List<dynamic> tempTotalAmount = value['totalAmount'];
                  List<num> numberOfTimes = tempNumberOfTimes
                      .map((e) => num.parse(e.toString()))
                      .toList();
                  List<num> numberOfItems = tempNumberOfItems
                      .map((e) => num.parse(e.toString()))
                      .toList();
                  List<num> totalAmount = tempTotalAmount
                      .map((e) => num.parse(e.toString()))
                      .toList();

                  if (printOrdersMap.length < 10) {
                    printOrdersMap.addAll({
                      '0${printOrdersMap.length} . $key x ${numberOfItems.reduce((a, b) => a + b).toString()} = ':
                          'Cancelled'
                    });
                  } else {
//ifNumberMoreThan9,WeDon'tNeedTheAdditionOf 0 at First
                    printOrdersMap.addAll({
                      '${printOrdersMap.length} . $key x ${numberOfItems.reduce((a, b) => a + b).toString()} = ':
                          'Cancelled'
                    });
                  }

                  itemCancellationMapForServerUpdate.addAll({
//NTC-NumberOfTimesCancelled
//NIC-numberOfItemsCancelled
//TAC-totalCancelledAmount
                    key: {
                      'NTC': FieldValue.increment(
                          numberOfTimes.reduce((a, b) => a + b)),
                      'NIC': FieldValue.increment(
                          numberOfItems.reduce((a, b) => a + b)),
                      'TAC': FieldValue.increment(
                          totalAmount.reduce((a, b) => a + b)),
                    }
                  });
                });
                Map<String, dynamic> captainCancellationMapForServerUpdate =
                    HashMap();
                if (captainCancellationMap.isNotEmpty) {
                  captainCancellationMap.forEach((key, value) {
                    List<dynamic> tempNumberOfTimes = value['numberOfTimes'];
                    List<dynamic> tempNumberOfItems = value['numberOfItems'];
                    List<dynamic> tempTotalAmount = value['totalAmount'];
                    Map<String, dynamic> tempIndividualItemsCancelled =
                        value['individualItemsCancelled'];
                    List<num> numberOfTimes = tempNumberOfTimes
                        .map((e) => num.parse(e.toString()))
                        .toList();
                    List<num> numberOfItems = tempNumberOfItems
                        .map((e) => num.parse(e.toString()))
                        .toList();
                    List<num> totalAmount = tempTotalAmount
                        .map((e) => num.parse(e.toString()))
                        .toList();
                    captainCancellationMapForServerUpdate.addAll({
//TCC-TimesCaptain/ChefCancelled
//NCC-NumberOfItemsCaptain/ChefCancelled
//ACC-TotalAmountCaptain/ChefCancelled
//IICC-IndividualItemsCaptain/ChefCancelled
                      key: {
                        'TCC': FieldValue.increment(
                            numberOfTimes.reduce((a, b) => a + b)),
                        'NCC': FieldValue.increment(
                            numberOfItems.reduce((a, b) => a + b)),
                        'ACC': FieldValue.increment(
                            totalAmount.reduce((a, b) => a + b)),
                        'IICC': updateMapWithIncrements(
                            tempIndividualItemsCancelled)
                      }
                    });
                  });
                }
                Map<String, dynamic> chefRejectionMapForServerUpdate =
                    HashMap();
                if (chefRejectionMap.isNotEmpty) {
                  chefRejectionMap.forEach((key, value) {
                    List<dynamic> tempNumberOfTimes = value['numberOfTimes'];
                    List<dynamic> tempNumberOfItems = value['numberOfItems'];
                    List<dynamic> tempTotalAmount = value['totalAmount'];
                    Map<String, dynamic> tempIndividualItemsRejected =
                        value['individualItemsRejected'];
                    List<num> numberOfTimes = tempNumberOfTimes
                        .map((e) => num.parse(e.toString()))
                        .toList();
                    List<num> numberOfItems = tempNumberOfItems
                        .map((e) => num.parse(e.toString()))
                        .toList();
                    List<num> totalAmount = tempTotalAmount
                        .map((e) => num.parse(e.toString()))
                        .toList();
                    chefRejectionMapForServerUpdate.addAll({
//TCR-TimesCaptain/ChefRejected
//NCR-NumberOfItemsCaptain/ChefRejected
//ACR-TotalAmountCaptain/ChefRejected
//IICR-IndividualItemsCaptain/ChefRejected
                      key: {
                        'TCR': FieldValue.increment(
                            numberOfTimes.reduce((a, b) => a + b)),
                        'NCR': FieldValue.increment(
                            numberOfItems.reduce((a, b) => a + b)),
                        'ACR': FieldValue.increment(
                            totalAmount.reduce((a, b) => a + b)),
                        'IICR':
                            updateMapWithIncrements(tempIndividualItemsRejected)
                      }
                    });
                  });
                }
                printOrdersMap.addAll({
                  'serialNumberForPrint':
                      'Cancelled:${baseInfoFromServerMap['serialNumber']}'
                });
                printOrdersMap.addAll({
                  'serialNumberNum':
                      num.parse(baseInfoFromServerMap['serialNumber'])
                });
                printOrdersMap.addAll({
                  'dateForPrint':
                      '${billDay}/${billMonth}/${billYear} at ${billHour}:${billMinute}'
                });

                printOrdersMap.addAll({
                  'orderClosingCaptainPhone':
                      Provider.of<PrinterAndOtherDetailsProvider>(context,
                              listen: false)
                          .currentUserPhoneNumberFromClass
                });
                printOrdersMap.addAll({
                  'orderClosingCaptainName': json.decode(
                          Provider.of<PrinterAndOtherDetailsProvider>(context,
                                  listen: false)
                              .allUserProfilesFromClass)[
                      Provider.of<PrinterAndOtherDetailsProvider>(context,
                              listen: false)
                          .currentUserPhoneNumberFromClass]['username']
                });
                printOrdersMap
                    .addAll({'cancelledItemsInOrder': cancelledItemsInOrder});
                if (baseInfoFromServerMap['tableOrParcel'] == 'Table') {
                  if (baseInfoFromServerMap['parentOrChild'] == 'parent') {
                    printOrdersMap.addAll({
                      'takeAwayOrDineInForPrint':
                          'TYPE: DINE-IN:${baseInfoFromServerMap['tableOrParcel']}:${baseInfoFromServerMap['tableOrParcelNumber']}'
                    });
                  } else {
                    printOrdersMap.addAll({
                      'takeAwayOrDineInForPrint':
                          'TYPE: DINE-IN:${baseInfoFromServerMap['tableOrParcel']}:${baseInfoFromServerMap['tableOrParcelNumber']}${baseInfoFromServerMap['parentOrChild']}'
                    });
                  }
                } else if (baseInfoFromServerMap['tableOrParcel'] == 'Parcel') {
                  if (baseInfoFromServerMap['parentOrChild'] == 'parent') {
                    printOrdersMap.addAll({
                      'takeAwayOrDineInForPrint':
                          'TYPE: TAKE-AWAY:${baseInfoFromServerMap['tableOrParcel']}:${baseInfoFromServerMap['tableOrParcelNumber']}'
                    });
                  } else {
                    printOrdersMap.addAll({
                      'takeAwayOrDineInForPrint':
                          'TYPE: TAKE-AWAY:${baseInfoFromServerMap['tableOrParcel']}:${baseInfoFromServerMap['tableOrParcelNumber']}${baseInfoFromServerMap['parentOrChild']}'
                    });
                  }
                }
                printOrdersMap
                    .addAll({'billNumberForPrint': billIdOfThisOrder()});
                Map<String, dynamic> subMasterCancellationStats = HashMap();
                subMasterCancellationStats.addAll({
                  'mapCancelledIndividualItemsStats':
                      itemCancellationMapForServerUpdate
                });
                if (captainCancellationMapForServerUpdate.isNotEmpty) {
                  subMasterCancellationStats.addAll({
                    'mapCancellingCaptainStats':
                        captainCancellationMapForServerUpdate
                  });
                }
                if (chefRejectionMapForServerUpdate.isNotEmpty) {
                  subMasterCancellationStats.addAll({
                    'mapRejectingChefStats': chefRejectionMapForServerUpdate
                  });
                }
                Map<String, dynamic> statisticsDailyGeneralStatsMap = {
                  'day': num.parse(statisticsDay),
                  'month': num.parse(statisticsMonth),
                  'year': num.parse(statisticsYear)
                };
                Map<String, dynamic> statisticsMonthlyGeneralStatsMap = {
                  'month': num.parse(statisticsMonth),
                  'year': num.parse(statisticsYear),
                  'midMonthMilliSecond': DateTime(int.parse(statisticsYear),
                          int.parse(statisticsMonth), 15)
                      .millisecondsSinceEpoch
                };
                statisticsDailyGeneralStatsMap.addAll(
                    {'billedCancellationStats': subMasterCancellationStats});
                statisticsMonthlyGeneralStatsMap.addAll(
                    {'billedCancellationStats': subMasterCancellationStats});
                //
                // FireStoreBillAndStatisticsInServerVersionTwo(
                //         hotelName: widget.hotelName,
                //         dailyStatisticsUpdateMap: statisticsDailyExpensesMap,
                //         monthlyStatisticsUpdateMap:
                //             statisticsMonthlyExpensesMap,
                //         entireCashBalanceChangeSheet: {},
                //         day: statisticsDay,
                //         month: statisticsMonth,
                //         year: statisticsYear,
                //         orderHistoryDocID: billIdOfThisOrder(),
                //         printOrdersMap: printOrdersMap)
                //     .updateBillAndStatistics();

                FireStoreBillAndStatisticsInServerVersionThree(
                        hotelName: widget.hotelName,
                        dailyGeneralStatisticsUpdateMap:
                            statisticsDailyGeneralStatsMap,
                        monthlyGeneralStatisticsUpdateMap:
                            statisticsMonthlyGeneralStatsMap,
                        dailyIndividualItemsStatisticsUpdateMap: {},
                        monthlyIndividualItemsStatisticsUpdateMap: {},
                        dailyCaptainStatisticsUpdateMap: {},
                        monthlyCaptainStatisticsUpdateMap: {},
                        entireCashBalanceChangeSheet: {},
                        versionOneStatisticsUpdateMap: {},
                        day: statisticsDay,
                        month: statisticsMonth,
                        year: statisticsYear,
                        orderHistoryDocID: billIdOfThisOrder(),
                        printOrdersMap: printOrdersMap)
                    .updateBillAndStatistics();

                setState(() {
                  showSpinner = false;
                });
//AfterUpdateWeCanDeleteTable
                FireStoreDeleteFinishedOrderInRunningOrders(
                        hotelName: widget.hotelName,
                        eachTableId: widget.itemsFromDoc)
                    .deleteFinishedOrder();
                Navigator.pop(context);
              } else {
                setState(() {
                  showSpinner = false;
                });
//ThisMeansItWasAlreadyPutInServer.SoWeAreSimplyDeletingThisTable
                FireStoreDeleteFinishedOrderInRunningOrders(
                        hotelName: widget.hotelName,
                        eachTableId: widget.itemsFromDoc)
                    .deleteFinishedOrder();
                Navigator.pop(context);
              }
            } catch (e) {
              show('Please Check Internet and Try Again');
            }
          }
          else {
            Map<String, dynamic> itemCancellationMap =
                cancellationUpdateMaps[0];
            Map<String, dynamic> captainCancellationMap =
                cancellationUpdateMaps[1];
            Map<String, dynamic> chefRejectionMap = cancellationUpdateMaps[2];
            print('captainCancellationMap');
            print(captainCancellationMap);
            print('chefRejectionMap');
            print(chefRejectionMap);
            Map<String, dynamic> itemCancellationMapForServerUpdate = HashMap();
            itemCancellationMap.forEach((key, value) {
              List<dynamic> tempNumberOfTimes = value['numberOfTimes'];
              List<dynamic> tempNumberOfItems = value['numberOfItems'];
              List<dynamic> tempTotalAmount = value['totalAmount'];
              List<num> numberOfTimes = tempNumberOfTimes
                  .map((e) => num.parse(e.toString()))
                  .toList();
              List<num> numberOfItems = tempNumberOfItems
                  .map((e) => num.parse(e.toString()))
                  .toList();
              List<num> totalAmount =
                  tempTotalAmount.map((e) => num.parse(e.toString())).toList();

              itemCancellationMapForServerUpdate.addAll({
                key: {
//NTC-NumberOfTimesCancelled
//NIC-numberOfItemsCancelled
//TAC-totalCancelledAmount
                  'NTC': FieldValue.increment(
                      numberOfTimes.reduce((a, b) => a + b)),
                  'NIC': FieldValue.increment(
                      numberOfItems.reduce((a, b) => a + b)),
                  'TAC':
                      FieldValue.increment(totalAmount.reduce((a, b) => a + b)),
                }
              });
            });
            Map<String, dynamic> captainCancellationMapForServerUpdate =
                HashMap();
            if (captainCancellationMap.isNotEmpty) {
              captainCancellationMap.forEach((key, value) {
                List<dynamic> tempNumberOfTimes = value['numberOfTimes'];
                List<dynamic> tempNumberOfItems = value['numberOfItems'];
                List<dynamic> tempTotalAmount = value['totalAmount'];
                Map<String, dynamic> tempIndividualItemsCancelled =
                    value['individualItemsCancelled'];
                List<num> numberOfTimes = tempNumberOfTimes
                    .map((e) => num.parse(e.toString()))
                    .toList();
                List<num> numberOfItems = tempNumberOfItems
                    .map((e) => num.parse(e.toString()))
                    .toList();
                List<num> totalAmount = tempTotalAmount
                    .map((e) => num.parse(e.toString()))
                    .toList();

                captainCancellationMapForServerUpdate.addAll({
//TCC-TimesCaptain/ChefCancelled
//NCC-NumberOfItemsCaptain/ChefCancelled
//ACC-TotalAmountCaptain/ChefCancelled
//IICC-IndividualItemsCaptain/ChefCancelled
                  key: {
                    'TCC': FieldValue.increment(
                        numberOfTimes.reduce((a, b) => a + b)),
                    'NCC': FieldValue.increment(
                        numberOfItems.reduce((a, b) => a + b)),
                    'ACC': FieldValue.increment(
                        totalAmount.reduce((a, b) => a + b)),
                    'IICC':
                        updateMapWithIncrements(tempIndividualItemsCancelled)
                  }
                });
              });
            }
            Map<String, dynamic> chefRejectionMapForServerUpdate = HashMap();
            if (chefRejectionMap.isNotEmpty) {
              chefRejectionMap.forEach((key, value) {
                List<dynamic> tempNumberOfTimes = value['numberOfTimes'];
                List<dynamic> tempNumberOfItems = value['numberOfItems'];
                List<dynamic> tempTotalAmount = value['totalAmount'];
                Map<String, dynamic> tempIndividualItemsRejected =
                value['individualItemsRejected'];
                List<num> numberOfTimes = tempNumberOfTimes
                    .map((e) => num.parse(e.toString()))
                    .toList();
                List<num> numberOfItems = tempNumberOfItems
                    .map((e) => num.parse(e.toString()))
                    .toList();
                List<num> totalAmount = tempTotalAmount
                    .map((e) => num.parse(e.toString()))
                    .toList();
                chefRejectionMapForServerUpdate.addAll({
//TCR-TimesCaptain/ChefRejected
//NCR-NumberOfItemsCaptain/ChefRejected
//ACR-TotalAmountCaptain/ChefRejected
//IICR-IndividualItemsCaptain/ChefRejected
                  key: {
                    'TCR': FieldValue.increment(
                        numberOfTimes.reduce((a, b) => a + b)),
                    'NCR': FieldValue.increment(
                        numberOfItems.reduce((a, b) => a + b)),
                    'ACR': FieldValue.increment(
                        totalAmount.reduce((a, b) => a + b)),
                    'IICR': updateMapWithIncrements(tempIndividualItemsRejected)
                  }
                });
              });
            }

            Map<String, dynamic> subMasterCancellationStats = HashMap();
            subMasterCancellationStats.addAll({
              'mapCancelledIndividualItemsStats':
                  itemCancellationMapForServerUpdate
            });
            if (captainCancellationMapForServerUpdate.isNotEmpty) {
              subMasterCancellationStats.addAll({
                'mapCancellingCaptainStats':
                    captainCancellationMapForServerUpdate
              });
            }
            if (chefRejectionMapForServerUpdate.isNotEmpty) {
              subMasterCancellationStats.addAll(
                  {'mapRejectingChefStats': chefRejectionMapForServerUpdate});
            }
            Map<String, dynamic> statisticsDailyGeneralStatsMap = {
              'day': num.parse(statisticsDay),
              'month': num.parse(statisticsMonth),
              'year': num.parse(statisticsYear)
            };
            Map<String, dynamic> statisticsMonthlyGeneralStatsMap = {
              'month': num.parse(statisticsMonth),
              'year': num.parse(statisticsYear),
              'midMonthMilliSecond': DateTime(
                      int.parse(statisticsYear), int.parse(statisticsMonth), 15)
                  .millisecondsSinceEpoch
            };
            statisticsDailyGeneralStatsMap.addAll(
                {'nonBilledCancellationStats': subMasterCancellationStats});
            statisticsMonthlyGeneralStatsMap.addAll(
                {'nonBilledCancellationStats': subMasterCancellationStats});

            FireStoreBillAndStatisticsInServerVersionThree(
                    hotelName: widget.hotelName,
                    dailyGeneralStatisticsUpdateMap:
                        statisticsDailyGeneralStatsMap,
                    monthlyGeneralStatisticsUpdateMap:
                        statisticsMonthlyGeneralStatsMap,
                    dailyIndividualItemsStatisticsUpdateMap: {},
                    monthlyIndividualItemsStatisticsUpdateMap: {},
                    dailyCaptainStatisticsUpdateMap: {},
                    monthlyCaptainStatisticsUpdateMap: {},
                    entireCashBalanceChangeSheet: {},
                    versionOneStatisticsUpdateMap: {},
                    day: statisticsDay,
                    month: statisticsMonth,
                    year: statisticsYear,
                    orderHistoryDocID: '',
                    printOrdersMap: printOrdersMap)
                .updateBillAndStatistics();
            setState(() {
              showSpinner = false;
            });
//AfterUpdateWeCanDeleteTable
            FireStoreDeleteFinishedOrderInRunningOrders(
                    hotelName: widget.hotelName,
                    eachTableId: widget.itemsFromDoc)
                .deleteFinishedOrder();
            Navigator.pop(context);
          }
        }
      } else {
        setState(() {
          showSpinner = false;
        });
        show('Please Check Internet and Try Again');
      }
    }

    void cashBalanceDataToServer(
        DateTime dateToAdd, num previousCash, num dayIncrement) {
      String yearForIncrementing = dateToAdd.year.toString();
      String monthForIncrementing = dateToAdd.month.toString().length > 1
          ? dateToAdd.month.toString()
          : '0${dateToAdd.month.toString()}';
      String dayForIncrementing = dateToAdd.day.toString().length > 1
          ? dateToAdd.day.toString()
          : '0${dateToAdd.day.toString()}';
      Map<String, dynamic> firstIncrementData = {
        'cashBalanceData': {
          dayForIncrementing: {
            'previousCashBalance': FieldValue.increment(previousCash),
            'dayIncrements': FieldValue.increment(dayIncrement)
          }
        }
      };
      Map<String, dynamic> masterMonthMap = {
        'year': dateToAdd.year,
        'month': dateToAdd.month,
        'midMonthMilliSecond':
            DateTime(dateToAdd.year, dateToAdd.month, 15).millisecondsSinceEpoch
      };
      masterMonthMap.addAll(firstIncrementData);
      _fireStore
          .collection(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .chosenRestaurantDatabaseFromClass)
          .doc('reports')
          .collection('monthlyCashBalanceReports')
          .doc('$yearForIncrementing*$monthForIncrementing')
          .set(masterMonthMap, SetOptions(merge: true));
    }

    void thisMonthStatisticsStreamToCheckInternet() {
      final thisMonthCollectionRef = FirebaseFirestore.instance
          .collection(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .chosenRestaurantDatabaseFromClass)
          .doc('reports')
          .collection('monthlyCashBalanceReports')
          .where('midMonthMilliSecond',
              isEqualTo: DateTime(DateTime.now().year, DateTime.now().month, 15)
                  .millisecondsSinceEpoch);
      _streamSubscriptionForThisMonth = thisMonthCollectionRef
          .snapshots()
          .listen((thisMonthStatisticsSnapshot) {
//ThisStreamIsSimplyToCheckWhetherInternetIsWorkingOrNot
//IfStreamSubscriptionIsNull,ItMeansThatThereIsNoInternet
//OnceDataIsUploadedWeCanCancelTheStream
      });
    }

    void cashBalanceWithPreviousYearDataCheck(
        DateTime dateToQuery, int randomNumberForThisButtonPress) async {
      bool gotSomeData = false;
      bool calledNextFunction = false;
      bool gotCancellingIncrements = false;
      bool gotToTheQueriedDate = false;
      Timer(Duration(seconds: 5), () {
        if (gotSomeData == false) {
          calledNextFunction = true;
          if (_streamSubscriptionForThisMonth == null) {
            setState(() {
              showSpinner = false;
            });
            currentGeneratedIncrementRandomNumber = 0;
            calledNextFunction = true;
            gotCancellingIncrements = false;
            _streamSubscriptionForThisMonth?.cancel();
            show('Please Check Internet and Try Again');
          }
        }
      });
      num milliSecondsYearPreviousToPickedDate =
          DateTime(dateToQuery.year, dateToQuery.month, dateToQuery.day)
              .subtract(Duration(days: 365))
              .millisecondsSinceEpoch;

      final pastYearToNowCollectionRef = FirebaseFirestore.instance
          .collection(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .chosenRestaurantDatabaseFromClass)
          .doc('reports')
          .collection('monthlyCashBalanceReports')
          .where('midMonthMilliSecond',
              isGreaterThan: milliSecondsYearPreviousToPickedDate)
          .orderBy('midMonthMilliSecond', descending: false);
//WantInAscendingOrderSoThatWeCanCheckPreviousDayBalanceWhileIterating
      final pastYearToNowStatisticsSnapshot =
          await pastYearToNowCollectionRef.get();
      if (pastYearToNowStatisticsSnapshot.docs.length >= 1) {
        gotSomeData = true;
        int monthsCheckCounter = 0;
        previousCashBalanceWhileIterating = -9999999;
        dayIncrementWhileIterating = -1111111;
        for (var eachMonthDocument in pastYearToNowStatisticsSnapshot.docs) {
          monthsCheckCounter++;

//SoThatWeCheckOnlyTheFirstDocumentTimePeriod
          if (eachMonthDocument['midMonthMilliSecond'] >
                  DateTime(dateToQuery.year, dateToQuery.month, 15)
                      .millisecondsSinceEpoch &&
              gotToTheQueriedDate == false) {
            if (previousCashBalanceWhileIterating == -9999999 &&
                dayIncrementWhileIterating == -1111111) {
//ThisMeansTheFirstDocumentItselfIsBiggerThanTheDateWeHaveToRegister
//So,WeHaveToAddFirstDocumentOurselvesForThatMonth
              previousCashBalanceWhileIterating = 0;
              dayIncrementWhileIterating = 0;
              gotCancellingIncrements = true;
              gotToTheQueriedDate = true;
            } else {
              gotCancellingIncrements = true;
              gotToTheQueriedDate = true;
              previousCashBalanceWhileIterating =
                  previousCashBalanceWhileIterating +
                      dayIncrementWhileIterating;
              dayIncrementWhileIterating = 0;
            }
            cashBalanceDataToServer(dateToQuery,
                previousCashBalanceWhileIterating, dayIncrementWhileIterating);
          }

          Map<String, dynamic> iteratingMonthCashBalanceData =
              eachMonthDocument['cashBalanceData'];
          int numberOfDaysInIteratingMonth = DateUtils.getDaysInMonth(
              eachMonthDocument['year'], eachMonthDocument['month']);
          for (int i = 1; i <= numberOfDaysInIteratingMonth; i++) {
            String dayAsString =
                i.toString().length > 1 ? i.toString() : '0${i.toString()}';
            if (DateTime(eachMonthDocument['year'], eachMonthDocument['month'],
                        i)
                    .millisecondsSinceEpoch <
                DateTime(dateToQuery.year, dateToQuery.month, dateToQuery.day)
                    .millisecondsSinceEpoch) {
//ThisMeansItsADayBeforeTheDayOfQuery
              if (iteratingMonthCashBalanceData.containsKey(dayAsString)) {
                previousCashBalanceWhileIterating =
                    iteratingMonthCashBalanceData[dayAsString]
                        ['previousCashBalance'];
                dayIncrementWhileIterating =
                    iteratingMonthCashBalanceData[dayAsString]['dayIncrements'];
              }
            } else if (DateTime(eachMonthDocument['year'],
                        eachMonthDocument['month'], i)
                    .millisecondsSinceEpoch ==
                DateTime(dateToQuery.year, dateToQuery.month, dateToQuery.day)
                    .millisecondsSinceEpoch) {
//ThisMeansThisIsTheDayInWhichWeNeedToAdd
              if (iteratingMonthCashBalanceData.containsKey(dayAsString)) {
//ThisMeansTheDayAlreadyExistsAndWeDontHaveToIncrementAnything
                gotToTheQueriedDate = true;
                previousCashBalanceWhileIterating = 0;
                dayIncrementWhileIterating = 0;
                gotCancellingIncrements = true;
              } else {
//ThisMeansTheDayDoesntExistsAndWeNeedToAddPreviousCashBalanceAndThenDayIncrement
                if (previousCashBalanceWhileIterating == -9999999 &&
                    dayIncrementWhileIterating == -1111111) {
//ThisMeansThatWeHaven'tGotPreviousCashBalanceTillNow.So,WeNeedToPutTheCashBalance
//ForThatDayAsZeroAndJustDoDayIncrementsFromThere
                  gotToTheQueriedDate = true;
                  previousCashBalanceWhileIterating = 0;
                  dayIncrementWhileIterating = 0;
                  gotCancellingIncrements = true;
                } else {
//thisMeansTheDayDoesn'tExistAndThereIsPreviousCashBalanceDataToRegister
                  previousCashBalanceWhileIterating =
                      previousCashBalanceWhileIterating +
                          dayIncrementWhileIterating;
                  dayIncrementWhileIterating = 0;
                  gotCancellingIncrements = true;
                  gotToTheQueriedDate = true;
                }
                cashBalanceDataToServer(
                    dateToQuery,
                    previousCashBalanceWhileIterating,
                    dayIncrementWhileIterating);
              }
            }
          }
          if (monthsCheckCounter ==
                  pastYearToNowStatisticsSnapshot.docs.length &&
              gotToTheQueriedDate == false &&
              eachMonthDocument['midMonthMilliSecond'] <
                  DateTime(dateToQuery.year, dateToQuery.month, 15)
                      .millisecondsSinceEpoch) {
            if (previousCashBalanceWhileIterating == -9999999 &&
                dayIncrementWhileIterating == -1111111) {
              //ThisMeansTheFirstDocumentItselfIsBiggerThanTheDateWeHaveToRegister
//So,WeHaveToAddFirstDocumentOurselvesForThatMonth
              previousCashBalanceWhileIterating = 0;
              dayIncrementWhileIterating = 0;
              gotToTheQueriedDate = true;
              gotCancellingIncrements = true;
            } else {
              gotCancellingIncrements = true;
              gotToTheQueriedDate = true;
              previousCashBalanceWhileIterating =
                  previousCashBalanceWhileIterating +
                      dayIncrementWhileIterating;
              dayIncrementWhileIterating = 0;
            }
            cashBalanceDataToServer(dateToQuery,
                previousCashBalanceWhileIterating, dayIncrementWhileIterating);
          }
        }
        if (gotCancellingIncrements &&
                randomNumberForThisButtonPress ==
                    currentGeneratedIncrementRandomNumber &&
                calledNextFunction == false
//CheckingWhetherWeGotTheDataOnTime
            ) {
          _streamSubscriptionForThisMonth?.cancel();
          currentGeneratedIncrementRandomNumber = 0;
          calledNextFunction = true;
//CallFunctionToDoTheOtherTasksOfIncrement
          print('callingFromhere3');
          allItemsCancellingUpdateInServer(
              lastItemIdForCancelling, lastItemStatusForCancelling);
        }
      } else {
        if (_streamSubscriptionForThisMonth != null &&
            randomNumberForThisButtonPress ==
                currentGeneratedIncrementRandomNumber &&
            calledNextFunction == false) {
//ThisMeansNoDocumentsAreThereInThePastOneYear.MostProbablyNewRestaurant
//WeWillPutNewDataHere.SinceStreamSubscriptionIsNotNullWeCanConfirm
// ThatTheLackOfDataIsn'tBecauseOfInternet
          previousCashBalanceWhileIterating = 0;
          dayIncrementWhileIterating = 0;
          cashBalanceDataToServer(dateToQuery,
              previousCashBalanceWhileIterating, dayIncrementWhileIterating);
          _streamSubscriptionForThisMonth?.cancel();
          currentGeneratedIncrementRandomNumber = 0;
          calledNextFunction = true;
          allItemsCancellingUpdateInServer(
              lastItemIdForCancelling, lastItemStatusForCancelling);
        }
      }
    }

    Future<void> cashBalanceWithQueriedMonthToLatestDataCheck(
        DateTime dateToQuery, int randomNumberForThisButtonPress) async {
      bool noPreviousCashBalanceDataInThisPeriod = false;
      bool gotSomeData = false;
      bool calledNextFunction = false;
      bool gotCancellingIncrements = false;
      bool gotToTheQueriedDate = false;
      Timer(Duration(seconds: 2), () {
        if (gotSomeData == false) {
          calledNextFunction = true;
          cashBalanceWithPreviousYearDataCheck(
              dateToQuery, randomNumberForThisButtonPress);
        }
      });
      num milliSecondsPickedDateMonth =
          DateTime(dateToQuery.year, dateToQuery.month, 15)
              .millisecondsSinceEpoch;
      final queriedMonthToEndCollectionRef = FirebaseFirestore.instance
          .collection(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .chosenRestaurantDatabaseFromClass)
          .doc('reports')
          .collection('monthlyCashBalanceReports')
          .where('midMonthMilliSecond',
              isGreaterThanOrEqualTo: milliSecondsPickedDateMonth)
          .orderBy('midMonthMilliSecond', descending: false);

//WantInAscendingOrderSoThatWeCanCheckPreviousDayBalanceWhileIterating
      final queriedMonthToEndStatisticsSnapshot =
          await queriedMonthToEndCollectionRef.get();
      if (queriedMonthToEndStatisticsSnapshot.docs.length >= 1) {
        print('entered Inside month');
        gotSomeData = true;
        int monthsCheckCounter = 0;
        previousCashBalanceWhileIterating = -9999999;
        dayIncrementWhileIterating = -1111111;
        for (var eachMonthDocument
            in queriedMonthToEndStatisticsSnapshot.docs) {
          monthsCheckCounter++;

//SoThatWeCheckOnlyTheFirstDocumentTimePeriod
          if (eachMonthDocument['midMonthMilliSecond'] >
                  DateTime(dateToQuery.year, dateToQuery.month, 15)
                      .millisecondsSinceEpoch &&
              gotToTheQueriedDate == false) {
//ThisMeansTheFirstDocumentItselfIsBiggerThanTheDateWeHaveToRegister
//WeNeedToCheckTheYearFunctionThen
            print('came Into exiting loop2');
            noPreviousCashBalanceDataInThisPeriod = true;
            calledNextFunction = true;
            cashBalanceWithPreviousYearDataCheck(
                dateToQuery, randomNumberForThisButtonPress);
          }

          print('iterating thru each doc');
          Map<String, dynamic> iteratingMonthCashBalanceData =
              eachMonthDocument['cashBalanceData'];
          String monthYearDocId = eachMonthDocument.id;
          int numberOfDaysInIteratingMonth = DateUtils.getDaysInMonth(
              eachMonthDocument['year'], eachMonthDocument['month']);
          for (int i = 1; i <= numberOfDaysInIteratingMonth; i++) {
            print('iterating thru each day');
            String dayAsString =
                i.toString().length > 1 ? i.toString() : '0${i.toString()}';
            if (DateTime(eachMonthDocument['year'], eachMonthDocument['month'],
                        i)
                    .millisecondsSinceEpoch <
                DateTime(dateToQuery.year, dateToQuery.month, dateToQuery.day)
                    .millisecondsSinceEpoch) {
//ThisMeansItsADayBeforeTheDayOfQuery
              if (iteratingMonthCashBalanceData.containsKey(dayAsString)) {
                previousCashBalanceWhileIterating =
                    iteratingMonthCashBalanceData[dayAsString]
                        ['previousCashBalance'];
                dayIncrementWhileIterating =
                    iteratingMonthCashBalanceData[dayAsString]['dayIncrements'];
              }
            } else if (DateTime(eachMonthDocument['year'],
                        eachMonthDocument['month'], i)
                    .millisecondsSinceEpoch ==
                DateTime(dateToQuery.year, dateToQuery.month, dateToQuery.day)
                    .millisecondsSinceEpoch) {
//ThisMeansThisIsTheDayInWhichWeNeedToAdd
              if (iteratingMonthCashBalanceData.containsKey(dayAsString)) {
                gotToTheQueriedDate = true;
//ThisMeansTheDayAlreadyExistsAndWeOnlyHaveToAddTheIncrementsToDayIncrements
                print('came Inside this called 2');
                previousCashBalanceWhileIterating = 0;
                dayIncrementWhileIterating = 0;
                gotCancellingIncrements = true;
              } else {
                if (previousCashBalanceWhileIterating == -9999999 &&
                    dayIncrementWhileIterating == -1111111) {
//ThisMeansThatWeHaven'tGotPreviousCashBalanceTillNow.WeCanSimplyExitTheLoop
                  print('came Into exiting loop 1');
                  noPreviousCashBalanceDataInThisPeriod = true;
                  calledNextFunction = true;
                  cashBalanceWithPreviousYearDataCheck(
                      dateToQuery, randomNumberForThisButtonPress);
                } else {
                  //ThisMeansTheDayDoesn'tExistsAnd
                  // WeNeedToAddPreviousCashBalanceAndThenDayIncrement
                  gotToTheQueriedDate = true;
                  previousCashBalanceWhileIterating =
                      previousCashBalanceWhileIterating +
                          dayIncrementWhileIterating;
                  dayIncrementWhileIterating = 0;
                  gotCancellingIncrements = true;
                  cashBalanceDataToServer(
                      dateToQuery,
                      previousCashBalanceWhileIterating,
                      dayIncrementWhileIterating);
                }
              }
            }
          }
          if (monthsCheckCounter ==
                  queriedMonthToEndStatisticsSnapshot.docs.length &&
              gotToTheQueriedDate == false) {
//ThisMeansWeHaveReachedTheEndOfDocumentButTheQueriedDateDidn'tCome
            calledNextFunction = true;
            cashBalanceWithPreviousYearDataCheck(
                dateToQuery, randomNumberForThisButtonPress);
          }
        }

        if (gotCancellingIncrements &&
                calledNextFunction ==
                    false && //thisWillCheckWhetherYearCheckWasCalled
                randomNumberForThisButtonPress ==
                    currentGeneratedIncrementRandomNumber
//ThisWillCheckWhetherButtonWasPressedAgainAndThisIsOldInstance
            ) {
//ThisMeansWeCanUpdateIncrementsAsBatch
          print('came Inside this called 1');

          _streamSubscriptionForThisMonth?.cancel();
          currentGeneratedIncrementRandomNumber = 0;
          calledNextFunction = true;
//CallFunctionToDoTheOtherTasksOfIncrement
          allItemsCancellingUpdateInServer(
              lastItemIdForCancelling, lastItemStatusForCancelling);
        }
      } else {
//ThisMeansNoDocumentsAreThereInThePastTwoMonthsAndWeWillBetterCheckForOneYear
        calledNextFunction = true;
        cashBalanceWithPreviousYearDataCheck(
            dateToQuery, randomNumberForThisButtonPress);
      }
      print('came Inside this called 11');
    }

    void deliveredAllAlertDialogBox() async {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Center(
              child: Text(
            'Confirm Served!',
            style: TextStyle(color: Colors.red),
          )),
          content: Text('Press Yes if all items are Served'),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.red),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('No')),
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.green),
                    ),
                    onPressed: () {
                      if (noItemsInTable) {
                        Navigator.pop(context);
                      } else {
                        Map<String, dynamic> tempItemsInOrderMap =
                            itemsInOrderFromServerMap;
                        Map<String, dynamic> tempChangedItemsInOrderMap =
                            HashMap();
                        tempItemsInOrderMap.forEach((key, value) {
                          if (value['itemStatus'] != 11) {
                            tempChangedItemsInOrderMap.addAll({
                              key: {'itemStatus': 3}
                            });
                          }
                        });
                        Map<String, dynamic> tempMasterOrderMap = HashMap();
                        tempMasterOrderMap.addAll({
                          'statusMap': {'captainStatus': 3, 'chefStatus': 7}
                        });
                        tempMasterOrderMap.addAll(
                            {'itemsInOrderMap': tempChangedItemsInOrderMap});
                        FireStoreAddOrderInRunningOrderFolder(
                                hotelName: widget.hotelName,
                                seatingNumber: widget.itemsFromDoc,
                                ordersMap: tempMasterOrderMap)
                            .addOrder();

                        Navigator.pop(context);
                        // Navigator.pop(context);
                      }
                    },
                    child: Text('Yes')),
              ],
            ),
          ],
        ),
        barrierDismissible: false,
      );
    }

    return WillPopScope(
      onWillPop: () async {
        print('here will pop items');
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
//TheBackIconButtonInAppBarWillPopTheScreenOut
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: kAppBarBackIconColor),
              onPressed: () async {
                Navigator.pop(context);
              }),
          backgroundColor: kAppBarBackgroundColor,
//WithTheTable/ParcelNumber,WeInputTheHeadingAccordingly
          title: Text(
            ' ${widget.itemsFromDoc}',
            style: kAppBarTextStyle,
          ),

          centerTitle: true,
          actions: <Widget>[
            IconButton(
                onPressed: () {
                  Provider.of<PrinterAndOtherDetailsProvider>(context,
                          listen: false)
                      .captainInsideTableVideoInstructionLookedOrNot(false);

                  buildCaptainInTableInstructionAlertDialogWidgetWithTimer();

                  // _videoController.play();
                },
                icon: Icon(
                  Icons.help,
                  color: kAppBarBackIconColor,
                )),
            PopupMenuButton<_MenuValues>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: kAppBarBackIconColor),
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  child: Text(
                    'Split',
                    style: kMenuBarPopUpMenuButtonTextStyle,
                  ),
                  value: _MenuValues.split,
                ),
                PopupMenuItem(
                  child: Text(
                    'Move',
                    style: kMenuBarPopUpMenuButtonTextStyle,
                  ),
                  value: _MenuValues.move,
                ),
                PopupMenuItem(
                  child: Text(
                    'Served All',
                    style: kMenuBarPopUpMenuButtonTextStyle,
                  ),
                  value: _MenuValues.deliveredAll,
                ),
              ],
              onSelected: (value) {
                switch (value) {
                  case _MenuValues.split:
                    splitTableOrParcel();
                    break;
                  case _MenuValues.move:
                    moveTableOrParcel();
                    break;
                  case _MenuValues.deliveredAll:
                    deliveredAllAlertDialogBox();
                    break;
                }
              },
            )
          ],
        ),
        body: ModalProgressHUD(
          inAsyncCall: showSpinner,
          child: Column(
            children: [
              pageHasInternet
                  ? const SizedBox.shrink()
                  : Container(
                      width: double.infinity,
                      color: Colors.red,
                      child: const Center(
                        child: Text('You are Offline',
                            style:
                                TextStyle(color: Colors.white, fontSize: 30.0)),
                      ),
                    ),
              (splitPressed || movePressed)
                  ? Expanded(child: Center(child: CircularProgressIndicator()))
                  : Expanded(
                      child: StreamBuilder<
                              DocumentSnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection(widget.hotelName)
                              .doc('runningorders')
                              .collection('runningorders')
                              .doc(widget.itemsFromDoc)
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
                                noItemsInTable = true;

                                return const Center(
                                  child: Text(
                                    'Table\nClosed/Split/Moved',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 30),
                                  ),
                                );
                              } else {
                                noItemsInTable = false;
                                deliveredStatus = true;
                                items = [];
                                rejectedItems = [];
                                readyItems = [];
                                acceptedItems = [];
                                nonAcceptedItems = [];
                                deliveredItems = [];
                                otherItems = [];
//RemakingTheEntireListPassedIntoThisPageEachTimeStreamBuilderRebuildsIt
                                widget.itemsID.clear();
                                widget.itemsName.clear();
                                widget.itemsNumber.clear();
                                widget.itemsStatus.clear();
                                widget.itemsEachPrice.clear();

                                Map<String, dynamic> mapToAddIntoItems = {};
                                var output = snapshot.data!.data();

                                baseInfoFromServerMap = output!['baseInfoMap'];
                                itemsInOrderFromServerMap =
                                    output!['itemsInOrderMap'];
                                if (output
                                    .containsKey('cancelledItemsInOrder')) {
                                  cancelledItemsInOrderFromServerMap =
                                      output!['cancelledItemsInOrder'];
                                }
                                if (orderIdCheckedWhenEnteringScreen == false) {
                                  orderIdCheckedWhenEnteringScreen = true;
                                  firstCheckedOrderId =
                                      baseInfoFromServerMap['orderID'];
                                }
                                if (firstCheckedOrderId ==
                                    baseInfoFromServerMap['orderID']) {
                                  noItemsInTable = false;
                                } else {
                                  noItemsInTable = true;
                                }
                                statusFromServerMap = output!['statusMap'];
                                ticketsFromServerMap = output!['ticketsMap'];
                                partOfTableOrParcelFromMap =
                                    output!['partOfTableOrParcel'];
                                partOfTableOrParcelNumberFromMap =
                                    output!['partOfTableOrParcelNumber'];
                                chefStatusForSplit =
                                    statusFromServerMap['chefStatus'];
                                captainStatusForSplit =
                                    statusFromServerMap['captainStatus'];
                                String tableorparcel =
                                    baseInfoFromServerMap['tableOrParcel'];
                                num tableorparcelnumber = num.parse(
                                    baseInfoFromServerMap[
                                        'tableOrParcelNumber']);
                                num timecustomercametoseat = num.parse(
                                    baseInfoFromServerMap['startTime']);
                                customername =
                                    baseInfoFromServerMap['customerName'];
                                customermobileNumber = baseInfoFromServerMap[
                                    'customerMobileNumber'];
                                customeraddressline1 =
                                    baseInfoFromServerMap['customerAddress'];
                                parentOrChild =
                                    baseInfoFromServerMap['parentOrChild'];

                                itemsInOrderFromServerMap.forEach((key, value) {
//ThisWillEnsureWeDontTakeCancelledItemsIntoTheList
                                  if (value['itemCancelled'] == 'false') {
                                    mapToAddIntoItems = {};
                                    mapToAddIntoItems['tableorparcel'] =
                                        tableorparcel;
                                    mapToAddIntoItems['tableorparcelnumber'] =
                                        tableorparcelnumber;
                                    mapToAddIntoItems[
                                            'timecustomercametoseat'] =
                                        timecustomercametoseat;
                                    widget.itemsID.add(key);
                                    mapToAddIntoItems['eachiteminorderid'] =
                                        key;
                                    widget.itemsName.add(value['itemName']);
                                    mapToAddIntoItems['item'] =
                                        value['itemName'];
                                    widget.itemsEachPrice
                                        .add(value['itemPrice']);
                                    mapToAddIntoItems['priceofeach'] =
                                        value['itemPrice'];
                                    widget.itemsNumber.add(int.parse(
                                        value['numberOfItem'].toString()));
                                    mapToAddIntoItems['number'] =
                                        value['numberOfItem'];
                                    mapToAddIntoItems['timeoforder'] =
                                        num.parse(value['orderTakingTime']);
                                    widget.itemsStatus.add(int.parse(
                                        value['itemStatus'].toString()));
                                    mapToAddIntoItems['statusoforder'] =
                                        value['itemStatus'];
                                    if (value['itemStatus'] != 3) {
                                      deliveredStatus = false;
                                    }

                                    mapToAddIntoItems['commentsForTheItem'] =
                                        value['itemComment'];
                                    mapToAddIntoItems['chefKotStatus'] =
                                        value['chefKOT'];
                                    mapToAddIntoItems['itemBelongsToDoc'] =
                                        widget.itemsFromDoc;
                                    if (value['itemStatus'] == 11) {
                                      rejectedItems.add(mapToAddIntoItems);
                                      rejectedItems.sort((a, b) =>
                                          (a['timeoforder'])
                                              .compareTo(b['timeoforder']));
                                    } else if (value['itemStatus'] == 10) {
                                      readyItems.add(mapToAddIntoItems);
                                      readyItems.sort((a, b) =>
                                          (a['timeoforder'])
                                              .compareTo(b['timeoforder']));
                                    } else if (value['itemStatus'] == 9) {
                                      nonAcceptedItems.add(mapToAddIntoItems);

                                      nonAcceptedItems.sort((a, b) =>
                                          (a['timeoforder'])
                                              .compareTo(b['timeoforder']));
                                    } else if (value['itemStatus'] == 7) {
                                      acceptedItems.add(mapToAddIntoItems);
                                      acceptedItems.sort((a, b) =>
                                          (a['timeoforder'])
                                              .compareTo(b['timeoforder']));
                                    } else if (value['itemStatus'] == 3) {
                                      deliveredItems.add(mapToAddIntoItems);
                                      deliveredItems.sort((a, b) =>
                                          (a['timeoforder'])
                                              .compareTo(b['timeoforder']));
                                    } else {
                                      otherItems.add(mapToAddIntoItems);
                                      otherItems.sort((a, b) =>
                                          (a['timeoforder'])
                                              .compareTo(b['timeoforder']));
                                    }
                                  }
                                });
                                items.addAll(rejectedItems);
                                items.addAll(readyItems);
                                items.addAll(nonAcceptedItems);
                                items.addAll(acceptedItems);
                                items.addAll(otherItems);
                                items.addAll(deliveredItems);

                                return noItemsInTable == false
                                    ? Scaffold(
                                        body: Column(
                                          children: [
                                            Expanded(
                                                child:
                                                    SlidableAutoCloseBehavior(
                                              closeWhenOpened: true,
                                              child: ListView.builder(
                                                  itemCount: items.length,
                                                  itemBuilder:
                                                      (context, index) {
//WeGoThroughAllTheItemsAndItemsNumberList
//IDAndStatusIsForActionsWeCanDoWithSlidableInFireStore
                                                    final itemName =
                                                        items[index]['item'];
                                                    final itemNumber =
                                                        items[index]['number'];
                                                    final itemID = items[index]
                                                        ['eachiteminorderid'];
                                                    final itemStatus =
                                                        items[index]
                                                            ['statusoforder'];
                                                    final itemBelongsToDoc =
                                                        items[index][
                                                            'itemBelongsToDoc'];
                                                    final commentsForTheItem =
                                                        items[index][
                                                            'commentsForTheItem'];
                                                    return Slidable(
//SlidablePackageFromNetHelpsToSlideAndGetOptions
//AmongTheManyAnimationOptionsForSliding,WeChooseScrollMotion
                                                        endActionPane:
                                                            ActionPane(
//endActionPaneIsForOptionsInRightSide
                                                          motion:
                                                              const ScrollMotion(),
                                                          children: [
                                                            SlidableAction(
//IfItemStatusIs11,ItMeansChefHasRejectedTheOrder
//SoWeDeleteItInFireStoreWithFireStoreServices
                                                              onPressed:
                                                                  (BuildContext
                                                                      context) {
                                                                setState(() {
                                                                  if (itemStatus !=
                                                                      3) {
//IfStatusIsNot3,itMeansTheItemHasNotYetBeenPickedUpByTheWaiter
//WeGiveHimTheOptionToClickPickedUpByUpdatingStatusTo3
                                                                    Map<String,
                                                                            dynamic>
                                                                        tempMapToUpdateStatus =
                                                                        {
                                                                      'itemStatus':
                                                                          3
                                                                    };
                                                                    Map<String,
                                                                            dynamic>
                                                                        masterOrderMapToServer =
                                                                        HashMap();
                                                                    masterOrderMapToServer
                                                                        .addAll({
                                                                      'statusMap':
                                                                          {
                                                                        'captainStatus':
                                                                            3,
                                                                        'chefStatus':
                                                                            7
                                                                      }
                                                                    });
                                                                    masterOrderMapToServer
                                                                        .addAll({
                                                                      'itemsInOrderMap':
                                                                          {
                                                                        itemID:
                                                                            tempMapToUpdateStatus
                                                                      }
                                                                    });
//MeansThatAnItemIsDelivered

                                                                    FireStoreAddOrderInRunningOrderFolder(
                                                                            hotelName: widget
                                                                                .hotelName,
                                                                            seatingNumber:
                                                                                itemBelongsToDoc,
                                                                            ordersMap:
                                                                                masterOrderMapToServer)
                                                                        .addOrder();
                                                                  }
                                                                });
                                                              },
//WeKeepBackgroundColorOfSlidableOptionAsPerStatus,
//ifStatus11(Rejected)-Red,If3(Delivered)-DarkGreen,Else-LightGreen
                                                              backgroundColor: itemStatus ==
                                                                      11
                                                                  ? Colors.white
                                                                  : itemStatus ==
                                                                          3
                                                                      ? Colors
                                                                          .green
                                                                          .shade900
                                                                      : Colors
                                                                          .green
                                                                          .shade500,
//iconAsPerStatus,11(Rejected)-deleteIcon,
//if3(AlreadyDelivered)-DoubleTick
//Else(DeliveredNow)-SingleTick
                                                              icon: itemStatus ==
                                                                      11
                                                                  ? null
                                                                  : itemStatus ==
                                                                          3
                                                                      ? const IconData(
                                                                          0xefe5,
                                                                          fontFamily:
                                                                              'MaterialIcons')
                                                                      : const IconData(
                                                                          0xe1f8,
                                                                          fontFamily:
                                                                              'MaterialIcons'),
//labelAsPerStatus,11(Rejected)-delete,
//if3(AlreadyDelivered)-Already Delivered
//Else(DeliveredNow)-Delivered
                                                              label: itemStatus ==
                                                                      11
                                                                  ? ' '
                                                                  : itemStatus ==
                                                                          3
                                                                      ? 'Already Served'
                                                                      : 'Served',
                                                            ),
                                                          ],
                                                        ),
//StartActionPaneIsForLeftSideSlideOptions
                                                        startActionPane:
                                                            ActionPane(
                                                          motion:
                                                              const ScrollMotion(),
                                                          children: [
                                                            Visibility(
//OnlyIfUserHasCancellationAccessHeWillBeAbleToCancel
                                                              visible: json.decode(Provider.of<
                                                                          PrinterAndOtherDetailsProvider>(
                                                                      context,
                                                                      listen:
                                                                          false)
                                                                  .allUserProfilesFromClass)[Provider.of<
                                                                          PrinterAndOtherDetailsProvider>(
                                                                      context,
                                                                      listen:
                                                                          false)
                                                                  .currentUserPhoneNumberFromClass]['privileges']['11'],
                                                              child:
                                                                  SlidableAction(
//WaiterCanDeleteItAnyTimeInCaseTheCustomerSaysTheyDon'tWant
//WeRemoveItOutOfTheListsToo
                                                                      onPressed:
                                                                          (BuildContext
                                                                              context) {
                                                                        setState(
                                                                            () {
//IfItemIsAccepted/Ready-WeNeedToIntimateTheChef
                                                                          if (items.length ==
                                                                              1) {
                                                                            showSpinner =
                                                                                true;
                                                                            documentStatisticsRegistryDateMaker();
                                                                            currentGeneratedIncrementRandomNumber =
                                                                                (1000000 + Random().nextInt(9999999 - 1000000));

                                                                            lastItemIdForCancelling =
                                                                                itemID;
                                                                            lastItemStatusForCancelling =
                                                                                itemStatus;
                                                                            thisMonthStatisticsStreamToCheckInternet();
                                                                            cashBalanceWithQueriedMonthToLatestDataCheck(DateTime(int.parse(statisticsYear), int.parse(statisticsMonth), int.parse(statisticsDay)),
                                                                                currentGeneratedIncrementRandomNumber);
                                                                          } else if (itemStatus == 7 ||
                                                                              itemStatus == 10) {
//ThisIsForMakingCancellationMap
//WeWillPutItInBothCancellationMapAndOriginalMap
//OriginalMapIsForChefToSeeWhileCancellationMapIsForDoingCancellation
                                                                            Map<String, dynamic>
                                                                                tempItemMapForCancel =
                                                                                itemsInOrderFromServerMap[itemID];
                                                                            tempItemMapForCancel['cancellingCaptainName'] =
                                                                                json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).allUserProfilesFromClass)[Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).currentUserPhoneNumberFromClass]['username'];
                                                                            tempItemMapForCancel['cancellingCaptainPhone'] =
                                                                                Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).currentUserPhoneNumberFromClass;

//ThisMeansTheTheItemHasBeenAccepted/ReadyByCook.WeNeedToInformCookTo...
// ...stopGettingItReady
//IfStatusIsNot3,itMeansTheItemHasNotYetBeenPickedUpByTheWaiter
//WeGiveHimTheOptionToClickPickedUpByUpdatingStatusTo3
//letTheStatusOfCaptainCancelledItemBe12
                                                                            Map<String, dynamic>
                                                                                tempMapToUpdateStatus =
                                                                                HashMap();
                                                                            if (itemStatus ==
                                                                                7) {
                                                                              tempMapToUpdateStatus.addAll({
                                                                                'itemCancelled': 'acceptedToDelete',
                                                                              });
                                                                            } else if (itemStatus ==
                                                                                10) {
                                                                              tempMapToUpdateStatus.addAll({
                                                                                'itemCancelled': 'readyToDelete'
                                                                              });
                                                                            }
                                                                            tempMapToUpdateStatus.addAll({
                                                                              'itemStatus': 9
                                                                            });

                                                                            tempMapToUpdateStatus.addAll({
                                                                              'chefKOT': 'chefkotnotyet'
                                                                            });

                                                                            Map<String, dynamic>
                                                                                masterOrderMapToServer =
                                                                                HashMap();
                                                                            masterOrderMapToServer.addAll({
                                                                              'itemsInOrderMap': {
                                                                                itemID: tempMapToUpdateStatus
                                                                              },
                                                                            });
                                                                            masterOrderMapToServer.addAll({
                                                                              'statusMap': {
                                                                                'chefStatus': 9
                                                                              }
                                                                            });
                                                                            masterOrderMapToServer.addAll({
                                                                              'cancelledItemsInOrder': {
                                                                                itemID: tempItemMapForCancel
                                                                              }
                                                                            });
                                                                            FireStoreAddOrderInRunningOrderFolder(hotelName: widget.hotelName, seatingNumber: itemBelongsToDoc, ordersMap: masterOrderMapToServer).addOrder();
                                                                            fcmProvider.sendNotification(
                                                                                token: dynamicTokensToStringToken(),
                                                                                title: widget.hotelName,
                                                                                restaurantNameForNotification: json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).allUserProfilesFromClass)[Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).currentUserPhoneNumberFromClass]['restaurantName'],
                                                                                body: '*newOrderForCook*');
                                                                          } else {
                                                                            Map<String, dynamic>
                                                                                tempItemMapForCancel =
                                                                                itemsInOrderFromServerMap[itemID];
//ifItIs11,It'sAnRejectedItemAndTheChefNameWillBeAlreadyThereInTheRejectedList
//SoWeDontNeedToChangeCaptain
//IfItIsNot11,itHasNotBeenAcceptedByChefYet.
//WeCanStraightAwayPutItInCancelledOrdersList
                                                                            if (itemStatus !=
                                                                                11) {
                                                                              tempItemMapForCancel['cancellingCaptainName'] = json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).allUserProfilesFromClass)[Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).currentUserPhoneNumberFromClass]['username'];
                                                                              tempItemMapForCancel['cancellingCaptainPhone'] = Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).currentUserPhoneNumberFromClass;
                                                                            }
//deletingAnNonAccepted/RejectedItemFromTheListOfItems

                                                                            Map<String, dynamic>
                                                                                masterOrderMapToServer =
                                                                                HashMap();
//ToDeleted
                                                                            masterOrderMapToServer.addAll({
                                                                              'itemsInOrderMap': {
                                                                                itemID: FieldValue.delete()
                                                                              },
                                                                            });
//InCaseItIsRejectedItem,WeNeedToRegisterThatTheCaptainHasSeenIt
                                                                            masterOrderMapToServer.addAll({
                                                                              'statusMap': {
                                                                                'captainStatus': 7
                                                                              },
                                                                            });
                                                                            masterOrderMapToServer.addAll({
                                                                              'cancelledItemsInOrder': {
                                                                                itemID: tempItemMapForCancel
                                                                              }
                                                                            });

                                                                            FireStoreAddOrderInRunningOrderFolder(hotelName: widget.hotelName, seatingNumber: itemBelongsToDoc, ordersMap: masterOrderMapToServer).addOrder();
                                                                          }
                                                                        });
                                                                      },
//IfAlreadyDelivered(Status 3)-GreenColor,Else-Red
                                                                      backgroundColor:
                                                                          Colors
                                                                              .red
                                                                              .shade500,
//IfAlreadyDelivered(Status 3)-DoubleTick,Else-DeleteIcon
                                                                      icon: Icons
                                                                          .close,
//IfAlreadyDelivered(Status 3)-Already Delivered,Else-Delete as label
                                                                      label:
                                                                          'Cancel'),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Container(
//thisContainerWillHaveTheListTile,WithBorderRadius
                                                          //margin: EdgeInsets.fromLTRB(5, 5, 5, 5),
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        5),
                                                            border: Border.all(
                                                              color: Colors
                                                                  .black87,
                                                              width: 1.0,
                                                            ),
//ContainerColor-Status11(Rejected)-Red,10(ReadyWithChef)-Green,
//3-AlreadyDelivered-LightBlue
                                                            color: itemStatus ==
                                                                    11
                                                                ? Colors.red
                                                                : itemStatus ==
                                                                        10
                                                                    ? Colors
                                                                        .green
                                                                    : itemStatus ==
                                                                            7
                                                                        ? Colors
                                                                            .orangeAccent
                                                                        : itemStatus ==
                                                                                3
                                                                            ? Colors.lightBlueAccent
                                                                            : null,
                                                          ),
                                                          child: ListTile(
//ListTileWillHaveItemNameInLeftAndNumberInRight
                                                            title: Text(
                                                                itemName,
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        28.0)),
                                                            trailing: Text(
                                                                itemNumber
                                                                    .toString(),
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        28.0)),
                                                            subtitle:
                                                                commentsForTheItem ==
                                                                        'noComment'
                                                                    ? null
                                                                    : Text(
                                                                        commentsForTheItem,
                                                                        style: TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.w500,
                                                                            color: Colors.black),
                                                                      ),
                                                          ),
                                                        ));
                                                  }),
                                            )),
                                            Padding(
                                              padding: const EdgeInsets.all(10),
                                              child: BottomButton(
                                                  buttonWidth: double.infinity,
                                                  buttonColor: (deliveredStatus &&
                                                          !noItemsInTable)
                                                      ? kBottomContainerColour
                                                      : Colors.grey,
                                                  onTap: () {
//OnlyIfAllItemAreDelivered,WeGoForwardWithPrint
                                                    if (deliveredStatus &&
                                                        !noItemsInTable) {
                                                      Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                              builder: (context) =>
                                                                  BillScreenWithNewBottomButton(
                                                                    hotelName:
                                                                        widget
                                                                            .hotelName,
                                                                    // addedItemsSet:
                                                                    //     addedItemsSet,
                                                                    itemsID: widget
                                                                        .itemsID,
                                                                    itemsFromThisDocumentInFirebaseDoc:
                                                                        widget
                                                                            .itemsFromDoc,
                                                                  )));

//WeGiveThePrintOrdersMap,navigatingToPrintScreen,WhereItWillBeDisplayedAsBill
//                 Navigator.pushReplacement(
//                     context,
//                     MaterialPageRoute(
//                         builder: (context) => FinalBillScreen(
//                               eachOrderMap: printOrdersMap,
//                             )));
                                                    } else if (noItemsInTable) {
                                                      Navigator.pop(context);
                                                    }
                                                  },
//ButtonTitleWillBePrint
                                                  buttonTitle: 'Confirm Bill'),
                                            )
                                          ],
                                        ),
                                        //inDownRight,WeHaveFloatingActionButton,
//ThisWillBeContainerAndWillBeInRoundShape
                                        floatingActionButton: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          children: [
                                            Container(
                                              width: 75.0,
                                              height: 75.0,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(1),
                                                // border: Border.all(
                                                //   color: Colors.black87,
                                                //   width: 0.2,
                                                // )
                                              ),
                                              child: MaterialButton(
                                                color: Colors.white70,
                                                onPressed: () {
                                                  _controller =
                                                      TextEditingController(
                                                          text:
                                                              customermobileNumber);
                                                  showModalBottomSheet(
                                                      isScrollControlled: true,
                                                      context: context,
                                                      builder: (context) {
                                                        return buildUserInfoWidget();
                                                      });
                                                },
                                                shape: CircleBorder(

                                                    // side: BorderSide(
                                                    //     // width: 2,
                                                    //     // color: Colors.red,
                                                    //     // style: BorderStyle.solid,
                                                    //     )
                                                    ),
                                                child: const Icon(
                                                  IconData(0xe043,
                                                      fontFamily:
                                                          'MaterialIcons'),
                                                  size: 35,
                                                ),
                                              ),
                                            ),
                                            SizedBox(height: 10),
                                            Container(
                                              width: 75.0,
                                              height: 75.0,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(1),
//            border: Border.all(
//          color: Colors.black87,
//          width: 0.2,
//        )
                                              ),
//FloatingActionButtonNameWillBeMenu
                                              child: FloatingActionButton(
                                                backgroundColor: Colors.white70,
                                                child: const Text(
                                                  'Menu',
                                                  style: TextStyle(
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.w900),
                                                ),
                                                onPressed: () {
//onPressedWeAlreadyHaveAllTheBelowInputsAsThisScreenWasCalled
//WeGiveUnavailableItemsToEnsureWeDon'tShowItAndItemsAddedMap
//WillHaveTheItemNameAsKeyAndTheNumberAsValue
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          MenuPageWithBackButtonUsage(
                                                        hotelName:
                                                            widget.hotelName,
                                                        tableOrParcel: widget
                                                            .tableOrParcel,
                                                        tableOrParcelNumber: widget
                                                            .tableOrParcelNumber,
                                                        parentOrChild:
                                                            parentOrChild,
                                                        menuItems:
                                                            widget.menuItems,
                                                        menuPrices:
                                                            widget.menuPrices,
                                                        menuTitles:
                                                            widget.menuTitles,
                                                        itemsAddedMapCalled: {},
                                                        itemsAddedCommentCalled: {},
                                                        itemsAddedTimeCalled: {},
                                                        alreadyRunningTicketsMap:
                                                            ticketsFromServerMap,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            SizedBox(height: 100),
                                          ],
                                        ),
                                      )
                                    : const Center(
                                        child: Text(
                                          'Table\nClosed/Split/Moved',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 30),
                                        ),
                                      );
                              }
                            } else {
                              return CircularProgressIndicator();
                            }
                          })),
            ],
          ),
        ),
      ),
    );
  }
}
