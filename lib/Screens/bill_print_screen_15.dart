//LanUsbBluetoothIntegration

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:orders_dev/Methods/bottom_button.dart';
import 'package:orders_dev/Methods/usb_bluetooth_printer.dart';
import 'package:orders_dev/Providers/notification_provider.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:orders_dev/Screens/printer_roles_assigning.dart';
import 'package:orders_dev/constants.dart';
import 'package:orders_dev/services/firestore_services.dart';
import 'package:provider/provider.dart';
import 'package:modal_progress_hud_alt/modal_progress_hud_alt.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';

class BillPrintWithStatsCheck extends StatefulWidget {
  final String hotelName;
  // final String addedItemsSet;
  final List<String> itemsID;
  final String itemsFromThisDocumentInFirebaseDoc;

  const BillPrintWithStatsCheck({
    Key? key,
    required this.hotelName,
    // required this.addedItemsSet,
    required this.itemsID,
    required this.itemsFromThisDocumentInFirebaseDoc,
  }) : super(key: key);

  @override
  State<BillPrintWithStatsCheck> createState() =>
      _BillPrintWithStatsCheckState();
}

class _BillPrintWithStatsCheckState extends State<BillPrintWithStatsCheck> {
  final _fireStore = FirebaseFirestore.instance;
  String hotelNameAlone = '';
//SpinnerOrCircularProgressIndicatorWhenTryingToPrint
  bool showSpinner = false;
  String printerSize = '0';
//BooleanToControlPrintButtonTap
  bool tappedPrintButton = false;
//booleanToUnderstandThatBillHasBeenUpdatedInServer
  bool billUpdatedInServer = false;
  bool locationPermissionAccepted = true;
  //checkingBluetoothOnOrOff
  bool bluetoothOnTrueOrOffFalse = true;

  String customername = '';
  String customermobileNumber = '';
  String customeraddressline1 = '';
  String billYear = '';
  String billMonth = '';
  String billDay = '';
  String billHour = '';
  String billMinute = '';
  String billSecond = '';
  num startTimeOfThisTableOrParcelInNum = 0;
  List<Map<String, dynamic>> items = [];
  List<String> distinctItemNames = [];
  List<num> individualPriceOfOneDistinctItem = [];
  List<num> numberOfOneDistinctItem = [];
  List<num> totalPriceOfOneDistinctItem = [];
  num totalPriceOfAllItems = 0;
  num totalQuantityOfAllItems = 0;
  Map<String, dynamic> statisticsMap = HashMap();
  Map<String, dynamic> generalStatsMap = HashMap();
  Map<String, dynamic> menuIndividualItemsStatsMap = HashMap();
  Map<String, dynamic> extraIndividualItemsStatsMap = HashMap();
  Map<String, dynamic> mapEachCaptainOrdersTakenStatsMap = HashMap();

  List<String> arraySoldItemsCategoryArray = [];
  Map<String, dynamic> toCheckPastOrderHistoryMap = HashMap();
  Map<String, dynamic> printOrdersMap = HashMap();
  num discount = 0;
  String discountEnteredValue = '';
  bool discountValueClickedTruePercentageClickedFalse = true;
  TextEditingController _controller = TextEditingController();
  String orderHistoryDocID = '';
  String statisticsDocID = '';
  String printingDate = '';
  String tableorparcel = '';
  num tableorparcelnumber = 0;
  String parentOrChild = '';
  int serialNumber = 0;
  late StreamSubscription internetCheckerSubscription;
  bool pageHasInternet = true;
  bool thisIsParcelTrueElseFalse = false;
  bool gotSerialNumber = false;
  bool noItemsInTable = false;
  Map<String, dynamic> baseInfoFromServerMap = HashMap();
  Map<String, dynamic> itemsInOrderFromServerMap = HashMap();
  String tempChargeName = '';
  List<String> chargesNamesList = [
    'Parcel Charges',
    'Delivery Charges',
    'Other'
  ];
  num tempChargesPriceForEdit = 0;
  String tempChargesPriceForEditInString = '';
  Map<String, dynamic> extraChargesMapFromServer = {};
  String errorMessage = '';
  List<String> extraItemsToPrint = [];
  List<String> extraItemsPricesToPrint = [];
//StartOfNewVariablesForNewPrinterPackage
  var devices = <BluetoothPrinter>[];
  var _isBle = false;
  var _reconnect = false;
  var _isConnected = false;
  var printerManager = PrinterManager.instance;
  StreamSubscription<PrinterDevice>? _subscription;
  StreamSubscription<BTStatus>? _subscriptionBtStatus;
  StreamSubscription<USBStatus>? _subscriptionUsbStatus;
  BTStatus _currentStatus = BTStatus.none;
  // _currentUsbStatus is only supports on Android
  // ignore: unused_field
  USBStatus _currentUsbStatus = USBStatus.none;
  Map<String, dynamic> billingPrinterAssigningMap = HashMap();
  String billingPrinterRandomID = '';
  Map<String, dynamic> printerSavingMap = HashMap();
  Map<String, dynamic> billingPrinterCharacters = HashMap();
  List<int> billBytes = [];
  var billPrinterType = PrinterType.bluetooth;
  bool usbBillConnect = false;
  bool usbBillConnectTried = false;
  bool bluetoothBillConnect = false;
  bool bluetoothBillConnectTried = false;
  int printerConnectionSuccessCheckRandomNumber = 0;
  String orderStartTimeForCreatingDocId = '';
  bool paymentDoneClicked = false;
  bool orderIdCheckedWhenEnteringScreen = false;
  String firstCheckedOrderId = '';
  Map<String, dynamic> expensesSegregationMap = HashMap();
  List<String> paymentMethod = [];
  Map<int, dynamic> bottomBarPaymentClosingMap = HashMap();
  Map<String, dynamic> finalPaymentClosingMap = HashMap();
  Map<String, dynamic> finalCashierClosingMap = HashMap();
  num cashIncrementRequired = 0;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _streamSubscriptionForPrinting;
  List<String> finalNewPaymentMethod = []; //forAddingNewPaymentMethods
  List<String> paymentMethodsInThisPeriod =
      []; //thisIsForArrayUnionOfAllPaymentMethods
  int closingHour = 0;
  String statisticsYear = '';
  String statisticsMonth = '';
  String statisticsDay = '';
  StreamSubscription<QuerySnapshot>? _streamSubscriptionForThisMonthStatistics;
//MakingThisToGetCashIncrement
  num previousCashBalanceWhileIterating = -9999999;
  num dayIncrementWhileIterating = -1111111;
  int currentGeneratedIncrementRandomNumber = 0;
  num valueToIncrementInCashInCashBalance = 0;
  Map<String, dynamic> cancelledItemsInOrderFromServerMap = HashMap();
  Map<String, dynamic> subMasterBilledCancellationStats = HashMap();
  Map<String, dynamic> restaurantInfoMap = HashMap();
  bool streamSubscriptionForPrintingOnTrueOffFalse = false;
  bool serialNumberStreamCalled = false;
  //SecondaryPrintCheckSoThatWeDon'tCallPrintTwiceFromStream
//AndAtTheSameTimeWeCanUseTheSameStreamToGetDataForPaymentDoneAlso
  bool secondaryPrintButtonTapCheck = false;
  Map<String, dynamic> entireCashBalanceChangeSheet = HashMap();
  bool gotCashIncrementData = false;
  String orderHistoryChecked = 'checking';
  bool billUpdateTried = false;
  int closingCheckCounter = 0;
  List<int> paymentSorterList = [];

  @override
  void initState() {
    showSpinner = false;

    tappedPrintButton = false;
    secondaryPrintButtonTapCheck = false;
    paymentDoneClicked = false;
    gotSerialNumber = false;
    items = [];
    distinctItemNames = [];
    serialNumber = 0;
    orderIdCheckedWhenEnteringScreen = false;
    firstCheckedOrderId = '';
    bottomBarPaymentClosingMap = {};
    gotCashIncrementData = false;
    billUpdateTried = false;
    // TODO: implement initState

    requestLocationPermission();
    internetAvailabilityChecker();
    // subscription to listen change status of bluetooth connection
    _subscriptionBtStatus =
        PrinterManager.instance.stateBluetooth.listen((status) {
//OnlyIfBluetoothIsOnWeCanEvenGetIntoThisLoop
//IfBluetoothIsOffWeCanGiveShowMessageSomewhere
      bluetoothOnTrueOrOffFalse = true;
      _currentStatus = status;
      // print('Bluetooth status $status');

      if (status == BTStatus.connecting && !bluetoothBillConnect) {
        intermediateTimerBeforeCheckingBluetoothConnectionSuccess();
      }

      if (status == BTStatus.connected) {
        printerConnectionSuccessCheckRandomNumber = 0;
        if (bluetoothBillConnect) {
          printThroughBluetoothOrUsb();
        }
        setState(() {
          _isConnected = true;
        });
      }
      if (status == BTStatus.none) {
        printerConnectionSuccessCheckRandomNumber = 0;
        if (bluetoothBillConnect || bluetoothBillConnectTried) {
          printerManager.disconnect(type: PrinterType.bluetooth);
          showMethodCaller('Unable To Connect. Please Check Printer');
          bluetoothBillConnect = false;
          bluetoothBillConnectTried = false;
        }
        // showMethodCaller('Unable To Connect. Please Check Printer');
        setState(() {
          showSpinner = false;
          _isConnected = false;
          tappedPrintButton = false;
        });
      }
    });
    // subscription to listen change status of usb connection
    _subscriptionUsbStatus = PrinterManager.instance.stateUSB.listen((status) {
      // log(' ----------------- status usb $status ------------------ ');
      _currentUsbStatus = status;
      if (status == USBStatus.connected) {
        if (usbBillConnect) {
          printThroughBluetoothOrUsb();
        }
      } else if (status == USBStatus.none) {
        printerManager.disconnect(type: PrinterType.usb);
        if (usbBillConnect || usbBillConnectTried) {
          showMethodCaller('Unable To Connect. Please Check Printer');
          usbBillConnect = false;
          usbBillConnectTried = false;
        }
        setState(() {
          showSpinner = false;
          _isConnected = false;
          tappedPrintButton = false;
        });
      }
    });
    downloadingExpensesSegregation();

    super.initState();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscriptionBtStatus?.cancel();
    _subscriptionUsbStatus?.cancel();
    _streamSubscriptionForPrinting?.cancel();
    _streamSubscriptionForThisMonthStatistics?.cancel();
    super.dispose();
  }

//StatisticsStreamToCheckInternet
  void thisMonthStatisticsStreamToCheckInternet() {
    final thisMonthCollectionRef = FirebaseFirestore.instance
        .collection(
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .chosenRestaurantDatabaseFromClass)
        .doc('reports')
        .collection('monthlyReports')
        .where('midMonthMilliSecond',
            isEqualTo: DateTime(DateTime.now().year, DateTime.now().month, 15)
                .millisecondsSinceEpoch);
    _streamSubscriptionForThisMonthStatistics = thisMonthCollectionRef
        .snapshots()
        .listen((thisMonthStatisticsSnapshot) {
//ThisStreamIsSimplyToCheckWhetherInternetIsWorkingOrNot
//IfStreamSubscriptionIsNull,ItMeansThatThereIsNoInternet
//OnceDataIsUploadedWeCanCancelTheStream
    });
  }

  Future<void> cashBalanceWithQueriedMonthToLatestDataCheck(
      DateTime dateToQuery, int randomNumberForThisButtonPress) async {
    bool noPreviousCashBalanceDataInThisPeriod = false;
    Map<String, dynamic> tempEntireCashBalanceChangeSheet = {};
    bool gotSomeData = false;
    bool calledNextFunction = false;
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
        .collection(
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .chosenRestaurantDatabaseFromClass)
        .doc('reports')
        .collection('monthlyReports')
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
      for (var eachMonthDocument in queriedMonthToEndStatisticsSnapshot.docs) {
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
        Map<String, dynamic> changeOfEachMonthCashBalanceData = HashMap();
        int numberOfDaysInIteratingMonth = DateUtils.getDaysInMonth(
            eachMonthDocument['year'], eachMonthDocument['month']);
        for (int i = 1; i <= numberOfDaysInIteratingMonth; i++) {
          print('iterating thru each day');
          String dayAsString =
              i.toString().length > 1 ? i.toString() : '0${i.toString()}';
          if (DateTime(eachMonthDocument['year'], eachMonthDocument['month'], i)
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
          } else if (DateTime(
                      eachMonthDocument['year'], eachMonthDocument['month'], i)
                  .millisecondsSinceEpoch ==
              DateTime(dateToQuery.year, dateToQuery.month, dateToQuery.day)
                  .millisecondsSinceEpoch) {
//ThisMeansThisIsTheDayInWhichWeNeedToAdd
            if (iteratingMonthCashBalanceData.containsKey(dayAsString)) {
//ThisMeansTheDayAlreadyExistsAndWeOnlyHaveToAddTheIncrementsToDayIncrements
              gotToTheQueriedDate = true;
              previousCashBalanceWhileIterating = 0;
              dayIncrementWhileIterating = valueToIncrementInCashInCashBalance;
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
                gotToTheQueriedDate = true;
                //ThisMeansTheDayDoesntExistsAndWeNeedToAddPreviousCashBalanceAndThenDayIncrement
                previousCashBalanceWhileIterating =
                    previousCashBalanceWhileIterating +
                        dayIncrementWhileIterating;
                dayIncrementWhileIterating =
                    valueToIncrementInCashInCashBalance;
              }
            }
          } else if (DateTime(
                      eachMonthDocument['year'], eachMonthDocument['month'], i)
                  .millisecondsSinceEpoch >
              DateTime(dateToQuery.year, dateToQuery.month, dateToQuery.day)
                  .millisecondsSinceEpoch) {
            if (iteratingMonthCashBalanceData.containsKey(dayAsString)) {
//ThisMeansThatThisDayExistsAndWeNeedToIncrementPreviousCashBalanceAlone
              changeOfEachMonthCashBalanceData.addAll({
                dayAsString: {
                  'previousCashBalance':
                      FieldValue.increment(valueToIncrementInCashInCashBalance)
                }
              });
            }
          }
        }
        if (changeOfEachMonthCashBalanceData.isNotEmpty) {
          tempEntireCashBalanceChangeSheet
              .addAll({monthYearDocId: changeOfEachMonthCashBalanceData});
        }
        if (monthsCheckCounter ==
                queriedMonthToEndStatisticsSnapshot.docs.length &&
            gotToTheQueriedDate == false &&
            eachMonthDocument['midMonthMilliSecond'] <
                DateTime(dateToQuery.year, dateToQuery.month, 15)
                    .millisecondsSinceEpoch) {
//ThisMeansWeHaveReachedTheEndOfDocumentButTheQueriedDateDidn'tCome
          calledNextFunction = true;
          cashBalanceWithPreviousYearDataCheck(
              dateToQuery, randomNumberForThisButtonPress);
        }
      }
      if (tempEntireCashBalanceChangeSheet.isNotEmpty &&
              calledNextFunction ==
                  false && //thisWillCheckWhetherYearCheckWasCalled
              randomNumberForThisButtonPress ==
                  currentGeneratedIncrementRandomNumber &&
              gotToTheQueriedDate
//ThisWillCheckWhetherButtonWasPressedAgainAndThisIsOldInstance
          ) {
        entireCashBalanceChangeSheet = tempEntireCashBalanceChangeSheet;
        gotCashIncrementData = true;
        _streamSubscriptionForThisMonthStatistics?.cancel();
        currentGeneratedIncrementRandomNumber = 0;
        calledNextFunction = true;
//CallFunctionToDoTheOtherTasksOfIncrement
      } else if (tempEntireCashBalanceChangeSheet.isEmpty &&
          calledNextFunction ==
              false && //thisWillCheckWhetherYearCheckWasCalled
          randomNumberForThisButtonPress ==
              currentGeneratedIncrementRandomNumber &&
          gotToTheQueriedDate) {
        entireCashBalanceChangeSheet = tempEntireCashBalanceChangeSheet;
        _streamSubscriptionForThisMonthStatistics?.cancel();
        currentGeneratedIncrementRandomNumber = 0;
        calledNextFunction = true;
        gotCashIncrementData = true;
      }
    } else {
//ThisMeansNoDocumentsAreThereInThePastTwoMonthsAndWeWillBetterCheckForOneYear
      calledNextFunction = true;
      cashBalanceWithPreviousYearDataCheck(
          dateToQuery, randomNumberForThisButtonPress);
    }
  }

  void cashBalanceWithPreviousYearDataCheck(
      DateTime dateToQuery, int randomNumberForThisButtonPress) async {
    Map<String, dynamic> tempEntireCashBalanceChangeSheet = {};
    bool gotSomeData = false;
    bool calledNextFunction = false;
    bool gotToTheQueriedDate = false;
    Timer(Duration(seconds: 4), () {
      if (gotSomeData == false) {
        calledNextFunction = true;
        if (_streamSubscriptionForThisMonthStatistics == null) {
          currentGeneratedIncrementRandomNumber = 0;
          calledNextFunction = true;
          _streamSubscriptionForThisMonthStatistics?.cancel();
          show('Please Check Internet and Try Again');
          setState(() {
            showSpinner = false;
          });
        }
      }
    });
    num milliSecondsYearPreviousToPickedDate =
        DateTime(dateToQuery.year, dateToQuery.month, dateToQuery.day)
            .subtract(Duration(days: 380))
            .millisecondsSinceEpoch;
    final pastYearToNowCollectionRef = FirebaseFirestore.instance
        .collection(
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .chosenRestaurantDatabaseFromClass)
        .doc('reports')
        .collection('monthlyReports')
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
            dayIncrementWhileIterating = valueToIncrementInCashInCashBalance;
            gotToTheQueriedDate = true;
          } else {
            gotToTheQueriedDate = true;
            previousCashBalanceWhileIterating =
                previousCashBalanceWhileIterating + dayIncrementWhileIterating;
            dayIncrementWhileIterating = valueToIncrementInCashInCashBalance;
          }
        }

        Map<String, dynamic> iteratingMonthCashBalanceData =
            eachMonthDocument['cashBalanceData'];
        String monthYearDocId = eachMonthDocument.id;
        Map<String, dynamic> changeOfEachMonthCashBalanceData = HashMap();
        int numberOfDaysInIteratingMonth = DateUtils.getDaysInMonth(
            eachMonthDocument['year'], eachMonthDocument['month']);
        for (int i = 1; i <= numberOfDaysInIteratingMonth; i++) {
          String dayAsString =
              i.toString().length > 1 ? i.toString() : '0${i.toString()}';
          if (DateTime(eachMonthDocument['year'], eachMonthDocument['month'], i)
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
          } else if (DateTime(
                      eachMonthDocument['year'], eachMonthDocument['month'], i)
                  .millisecondsSinceEpoch ==
              DateTime(dateToQuery.year, dateToQuery.month, dateToQuery.day)
                  .millisecondsSinceEpoch) {
//ThisMeansThisIsTheDayInWhichWeNeedToAdd
            if (iteratingMonthCashBalanceData.containsKey(dayAsString)) {
//ThisMeansTheDayAlreadyExistsAndWeOnlyHaveToAddTheIncrementsToDayIncrements
              gotToTheQueriedDate = true;
              previousCashBalanceWhileIterating = 0;
              dayIncrementWhileIterating = valueToIncrementInCashInCashBalance;
            } else {
              print('came into this loop 45');
//ThisMeansTheDayDoesntExistsAndWeNeedToAddPreviousCashBalanceAndThenDayIncrement
              if (previousCashBalanceWhileIterating == -9999999 &&
                  dayIncrementWhileIterating == -1111111) {
                gotToTheQueriedDate = true;
                print('came into this loop 46');
//ThisMeansThatWeHaven'tGotPreviousCashBalanceTillNow.So,WeNeedToPutTheCashBalance
//ForThatDayAsZeroAndJustDoDayIncrementsFromThere
                previousCashBalanceWhileIterating = 0;
                dayIncrementWhileIterating =
                    valueToIncrementInCashInCashBalance;
              } else {
                gotToTheQueriedDate = true;
                previousCashBalanceWhileIterating =
                    previousCashBalanceWhileIterating +
                        dayIncrementWhileIterating;
                dayIncrementWhileIterating =
                    valueToIncrementInCashInCashBalance;
              }
            }
          } else if (DateTime(
                      eachMonthDocument['year'], eachMonthDocument['month'], i)
                  .millisecondsSinceEpoch >
              DateTime(dateToQuery.year, dateToQuery.month, dateToQuery.day)
                  .millisecondsSinceEpoch) {
            if (iteratingMonthCashBalanceData.containsKey(dayAsString)) {
//ThisMeansThatThisDayExistsAndWeNeedToIncrementPreviousCashBalanceAlone
              changeOfEachMonthCashBalanceData.addAll({
                dayAsString: {
                  'previousCashBalance':
                      FieldValue.increment(valueToIncrementInCashInCashBalance)
                }
              });
            }
          }
        }
        if (changeOfEachMonthCashBalanceData.isNotEmpty) {
          tempEntireCashBalanceChangeSheet
              .addAll({monthYearDocId: changeOfEachMonthCashBalanceData});
        }
        if (monthsCheckCounter == pastYearToNowStatisticsSnapshot.docs.length &&
            gotToTheQueriedDate == false &&
            eachMonthDocument['midMonthMilliSecond'] <
                DateTime(dateToQuery.year, dateToQuery.month, 15)
                    .millisecondsSinceEpoch) {
//ThisMeansItsLastDocumentAndStillQueriedDateIsNotThere
//AndTheLastDocumentIsLesserMonthThanQueriedMonth
          if (previousCashBalanceWhileIterating == -9999999 &&
              dayIncrementWhileIterating == -1111111) {
//ThisMeansTheFirstDocumentItselfIsBiggerThanTheDateWeHaveToRegister
//So,WeHaveToAddFirstDocumentOurselvesForThatMonth
            previousCashBalanceWhileIterating = 0;
            dayIncrementWhileIterating = valueToIncrementInCashInCashBalance;
            gotToTheQueriedDate = true;
          } else {
            gotToTheQueriedDate = true;
            previousCashBalanceWhileIterating =
                previousCashBalanceWhileIterating + dayIncrementWhileIterating;
            dayIncrementWhileIterating = valueToIncrementInCashInCashBalance;
          }
        }
      }
      if (tempEntireCashBalanceChangeSheet.isNotEmpty &&
              randomNumberForThisButtonPress ==
                  currentGeneratedIncrementRandomNumber &&
              calledNextFunction == false &&
              gotToTheQueriedDate
//CheckingWhetherWeGotTheDataOnTime
          ) {
//ThisMeansWeCanUpdateIncrementsAsBatch
        entireCashBalanceChangeSheet = tempEntireCashBalanceChangeSheet;
        _streamSubscriptionForThisMonthStatistics?.cancel();
        currentGeneratedIncrementRandomNumber = 0;
        calledNextFunction = true;
        gotCashIncrementData = true;
//CallFunctionToDoTheOtherTasksOfIncrement
      } else if (tempEntireCashBalanceChangeSheet.isEmpty &&
          randomNumberForThisButtonPress ==
              currentGeneratedIncrementRandomNumber &&
          calledNextFunction == false &&
          gotToTheQueriedDate) {
        entireCashBalanceChangeSheet = tempEntireCashBalanceChangeSheet;
        _streamSubscriptionForThisMonthStatistics?.cancel();
        currentGeneratedIncrementRandomNumber = 0;
        calledNextFunction = true;
        gotCashIncrementData = true;
      }
    } else {
      if (_streamSubscriptionForThisMonthStatistics != null &&
          randomNumberForThisButtonPress ==
              currentGeneratedIncrementRandomNumber &&
          calledNextFunction == false) {
//ThisMeansNoDocumentsAreThereInThePastOneYear.MostProbablyNewRestaurant
//WeWillPutNewDataHere.SinceStreamSubscriptionIsNotNullWeCanConfirm
// ThatTheLackOfDataIsn'tBecauseOfInternet
        previousCashBalanceWhileIterating = 0;
        dayIncrementWhileIterating = 0;
        _streamSubscriptionForThisMonthStatistics?.cancel();
        currentGeneratedIncrementRandomNumber = 0;
        calledNextFunction = true;
        gotCashIncrementData = true;
      }
    }
  }

//WeNeedThisMethodToDownloadThePaymentMethodsFromExpensesSegregation
  Future<void> downloadingExpensesSegregation() async {
    int lastExpensesLocallySavedSegregationTime =
        Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .expensesSegregationDeviceSavedTimestampFromClass;
    int expensesSegregationTimeInServer = json.decode(
        Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .restaurantInfoDataFromClass)['updateTimes']['expensesSegregation'];

    if ((Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                    .expensesSegregationMapFromClass ==
                '{}') ||
            (expensesSegregationTimeInServer >
                lastExpensesLocallySavedSegregationTime)
//ThisMeansThereIsNewUpdateToTheData
        ) {
      final expensesSegregationQuery = await FirebaseFirestore.instance
          .collection(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .chosenRestaurantDatabaseFromClass)
          .doc('expensesSegregation')
          .get();
      expensesSegregationMap = expensesSegregationQuery.data()!;
      Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
          .expensesSegregationTimeStampSaving(expensesSegregationTimeInServer,
              json.encode(expensesSegregationMap));
      paymentMethodFromExpensesSegregationData();
    } else {
      expensesSegregationMap = json.decode(
          Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .expensesSegregationMapFromClass);
      paymentMethodFromExpensesSegregationData();
    }
  }

  void paymentMethodFromExpensesSegregationData() {
//ExpensesPaidByMethod
    Map<String, dynamic> tempPaymentMethodMap =
        expensesSegregationMap['paymentMethod'];

    List<String> tempPaymentMethodList = tempPaymentMethodMap.isNotEmpty
        ? tempPaymentMethodMap.values.toList().cast<String>()
        : [];
    tempPaymentMethodList.sort();
    paymentMethod.clear();
    paymentMethod.add('Choose');
    paymentMethod.addAll(tempPaymentMethodList);
    paymentMethod.add('New');
//IfOthersIsClickedWeShouldGiveThemTheTextBox

    setState(() {});
  }

  void intermediateTimerBeforeCheckingBluetoothConnectionSuccess() {
    Timer(Duration(seconds: 2), () {
//SometimesTheBluetoothStreamTakesSometimeToRegisterWhetherOrNot
//BluetoothisConnected.OnSuchOccasionThisTimerCallingBecomesNecessity
//ThisMeansPrinterHasn'tConnectedIn2Seconds.OnlyThenWeCallForCheckingAfter5Seconds
      if (!bluetoothBillConnect) {
        int randomNumberGenerationForThisAttempt =
            (1000000 + Random().nextInt(9999999 - 1000000));
        printerConnectionSuccessCheckRandomNumber =
            randomNumberGenerationForThisAttempt;
        timerForCheckingBluetoothConnectionSuccess(
            randomNumberGenerationForThisAttempt);
      }
    });
  }

  void timerForCheckingBluetoothConnectionSuccess(
      int randomNumberForPrintingConnectionCheck) {
    Timer(Duration(seconds: 6), () {
      if (randomNumberForPrintingConnectionCheck ==
          printerConnectionSuccessCheckRandomNumber) {
        printerManager.disconnect(type: PrinterType.bluetooth);
        showMethodCallerWithShowSpinnerOffForBluetooth(
            'Unable to connect. Please check Printer');
      }
    });
  }

  void internetAvailabilityChecker() async {
    if (pageHasInternet) {
      var netAvailableTrueElseFalse =
          await InternetConnectionChecker().hasConnection;
      setState(() {
        pageHasInternet = netAvailableTrueElseFalse;
      });
    }
    Timer? _timerToCheckInternet;
    int _everySecondForInternetChecking = 0;
    _timerToCheckInternet =
        Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_everySecondForInternetChecking < 2) {
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
      }
    });
  }

//ThisFunctionInput-Map-StringKey:StringValue
// FunctionOutput-Map-StringValue:List[keysThatHadTheSameValue]
//Eg:Input:{'1':'A','2':'B','3':'A'}. Output:{'A':['1','3'],'B':['2']}
  Map<String, List<String>> convertMap(Map<String, String> originalMap) {
    final resultMap = <String, List<String>>{};
    for (var key in originalMap.keys) {
      final value = originalMap[key];
      resultMap[value.toString()] = resultMap[value.toString()] ??=
          []; // Initialize empty list if key doesn't exist
      resultMap[value]!.add(key);
    }
    return resultMap;
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

  void makingDistinctItemsList() {
    items = [];
    generalStatsMap = {};
    menuIndividualItemsStatsMap = {};
    extraIndividualItemsStatsMap = {};
    arraySoldItemsCategoryArray = [];
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
      billHour =
          now.hour < 10 ? '0${now.hour.toString()}' : '${now.hour.toString()}';
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
    if (baseInfoFromServerMap['extraCharges'] != null) {
      extraChargesMapFromServer = baseInfoFromServerMap['extraCharges'];
    }
    discountEnteredValue = baseInfoFromServerMap['discountEnteredValue'];
    discountValueClickedTruePercentageClickedFalse =
        baseInfoFromServerMap['discountValueTruePercentageFalse'];
    // String timecustomercametoseatTomakeOrderId =
    //     baseInfoFromServerMap['startTime'];
    // if (timecustomercametoseatTomakeOrderId.length < 8) {
    //   for (int i = timecustomercametoseatTomakeOrderId.length; i < 8; i++) {
    //     timecustomercametoseatTomakeOrderId =
    //         '0' + timecustomercametoseatTomakeOrderId;
    //   }
    // }
    startTimeOfThisTableOrParcelInNum =
        num.parse(baseInfoFromServerMap['startTime'].toString());
    orderStartTimeForCreatingDocId = baseInfoFromServerMap['startTime'];
    if (orderStartTimeForCreatingDocId.length < 8) {
      for (int i = orderStartTimeForCreatingDocId.length; i < 8; i++) {
        orderStartTimeForCreatingDocId = '0' + orderStartTimeForCreatingDocId;
      }
    }

    printOrdersMap = {};
    statisticsMap = {};
    toCheckPastOrderHistoryMap = {};
    orderHistoryDocID =
        '${billYear}${billMonth}${billDay}${orderStartTimeForCreatingDocId}';
    statisticsDocID = '$billYear*$billMonth*$billDay';
    printingDate =
        '${billDay}/${billMonth}/${billYear} at ${billHour}:${billMinute}';
    //InThePrintOrdersMap(HashMap),FirstWeSaveKeyAs "DateOfOrder"&ValueAs,,
//year/Month/Day At Hour:Minute
    printOrdersMap.addAll({
      ' Date of Order  :':
          '$billYear/$billMonth/$billDay at $billHour:$billMinute'
    });

    Map<String, dynamic> mapToAddIntoItems = {};
    tableorparcel = baseInfoFromServerMap['tableOrParcel'];

    if (baseInfoFromServerMap['tableOrParcel'] == 'Parcel') {
      thisIsParcelTrueElseFalse = true;
      statisticsMap.addAll({'numberofparcel': FieldValue.increment(1)});
      generalStatsMap.addAll({'numberofparcel': FieldValue.increment(1)});
      statisticsMap.addAll({'totalnumberoforders': FieldValue.increment(1)});
      generalStatsMap.addAll({'totalnumberoforders': FieldValue.increment(1)});
    } else {
      thisIsParcelTrueElseFalse = false;
//ElseIfItIsTable,WeAddParcelNumbers0&TotalNumberOfOrdersAdd1InStatisticsMap
      statisticsMap.addAll({'numberofparcel': FieldValue.increment(0)});
      generalStatsMap.addAll({'numberofparcel': FieldValue.increment(0)});
      statisticsMap.addAll({'totalnumberoforders': FieldValue.increment(1)});
      generalStatsMap.addAll({'totalnumberoforders': FieldValue.increment(1)});
    }
    tableorparcelnumber =
        num.parse(baseInfoFromServerMap['tableOrParcelNumber']);
    num timecustomercametoseat = num.parse(baseInfoFromServerMap['startTime']);
    if (baseInfoFromServerMap['customerName'] != '') {
      customername = baseInfoFromServerMap['customerName'];
    }
    if (baseInfoFromServerMap['customerMobileNumber'] != '') {
      customermobileNumber = baseInfoFromServerMap['customerMobileNumber'];
    }
    if (baseInfoFromServerMap['customerAddress'] != '') {
      customeraddressline1 = baseInfoFromServerMap['customerAddress'];
    }
    if (baseInfoFromServerMap['parentOrChild'] != 'parent') {
      parentOrChild = baseInfoFromServerMap['parentOrChild'];
    }

    if (baseInfoFromServerMap['serialNumber'] != 'noSerialYet') {
      serialNumber = num.parse(baseInfoFromServerMap['serialNumber']).toInt();
      gotSerialNumber = true;
      streamSubscriptionForPrintingOnTrueOffFalse = false;
      _streamSubscriptionForPrinting?.cancel();
    } else if (serialNumberStreamCalled == false) {
//thisMeansSerialNumberIsNotThereAndWeNeedToCallStreamForPrinting
//thisWillCheckWhetherSerialNumberIsNotThereAndWeHaven'tCalledStreamYet
      documentStatisticsRegistryDateMaker();
      serialNumberStreamForPrinting();
      serialNumberStreamCalled = true;
    }
//ThisIsToCheckPaymentDoneMapIsAvailableOrNot
    bool billClosureTimeForAtleastOnePersonAvailable = false;
    if (baseInfoFromServerMap['billClosingPhoneOrderIdWithTime'] != null) {
      Map<String, dynamic> billClosureCheckMap =
          baseInfoFromServerMap['billClosingPhoneOrderIdWithTime'];

      if (billClosureCheckMap.isNotEmpty) {
        billClosureCheckMap.forEach((key, value) {
          if (value['timeOfClosure'] != null) {
            billClosureTimeForAtleastOnePersonAvailable = true;
          }
        });
      }
    }

//ThisIsToCheckPaymentDoneMapIsAvailableOrNot
    totalQuantityOfAllItems = 0;

    itemsInOrderFromServerMap.forEach((key, value) {
      mapToAddIntoItems = {};
      mapToAddIntoItems['tableorparcel'] = tableorparcel;
      mapToAddIntoItems['parentOrChild'] = parentOrChild;
      mapToAddIntoItems['tableorparcelnumber'] = tableorparcelnumber;
      mapToAddIntoItems['timecustomercametoseat'] = timecustomercametoseat;
      // widget.itemsID.add(setSplit[i]);
      mapToAddIntoItems['eachiteminorderid'] = key;
      // if (!distinctItemNames.contains(value['itemName'])) {
      //   distinctItemNames.add(value['itemName']);
      // }
      mapToAddIntoItems['item'] = value['itemName'];
      mapToAddIntoItems['priceofeach'] = value['itemPrice'];
      mapToAddIntoItems['number'] = value['numberOfItem'];
      totalQuantityOfAllItems += value['numberOfItem'];
      mapToAddIntoItems['timeoforder'] = num.parse(value['orderTakingTime']);
      mapToAddIntoItems['statusoforder'] = value['itemStatus'];
      mapToAddIntoItems['commentsForTheItem'] = value['itemComment'];
      mapToAddIntoItems['chefKotStatus'] = value['chefKOT'];
      mapToAddIntoItems['ticketNumberOfItem'] = value['ticketNumberOfItem'];
      mapToAddIntoItems['captainPhoneNumber'] = value['captainPhoneNumber'];
      mapToAddIntoItems['captainName'] = value['captainName'];
      mapToAddIntoItems['itemBelongsToDoc'] =
          widget.itemsFromThisDocumentInFirebaseDoc;
      items.add(mapToAddIntoItems);
    });
    items.sort((a, b) => (a['timeoforder']).compareTo(b['timeoforder']));
    distinctItemNames = [];
    mapEachCaptainOrdersTakenStatsMap = {};
    Map<String, String> ticketPhoneNumberMap = HashMap();
    for (var eachItem in items) {
      //ThisLoopIsToMakeTicket-PhoneNumberMap
      if (!ticketPhoneNumberMap.containsKey(eachItem['ticketNumberOfItem'])) {
        ticketPhoneNumberMap.addAll(
            {eachItem['ticketNumberOfItem']: eachItem['captainPhoneNumber']});
      }
//ThisLoopIsToMakeDistinctItemNames
      if (!distinctItemNames.contains(eachItem['item'])) {
        distinctItemNames.add(eachItem['item']);
      }
    }
//MakingMapForEachUser-UserPhoneNumberToTicketsMap
    Map<String, List<String>> userToTicketsMap =
        convertMap(ticketPhoneNumberMap);

    userToTicketsMap.forEach((key, value) {
//ByThisWeGoThroughEachUser
      List<String> allTicketsTheUserTook = value;
      num numberOfTicketsTaken = 0;
      Map<String, dynamic> tempItemsForUserStatsMap = HashMap();
//WeGoThroughEachUser,GoThroughEachTicketAndMakeStatsMapOutOfIt
      for (var eachTicket in allTicketsTheUserTook) {
//WeGoThroughEachTicket,CheckItemsInEachTicketAndAddToList
        numberOfTicketsTaken++;
        for (var eachItem in items) {
          if (eachItem['ticketNumberOfItem'] == eachTicket) {
//ThisMeansItemBelongsToThatTicket
            if (tempItemsForUserStatsMap.containsKey(eachItem['item'])) {
//WeUpdateTheMapToTheNewValue
              tempItemsForUserStatsMap[eachItem['item']] = {
                'numberOfUnits': tempItemsForUserStatsMap[eachItem['item']]
                        ['numberOfUnits'] +
                    eachItem['number'],
                'totalAmountOfEachItem':
                    ((tempItemsForUserStatsMap[eachItem['item']]
                            ['totalAmountOfEachItem']) +
                        (eachItem['priceofeach'] * eachItem['number']))
              };
            } else {
//ThisIsIfIncrementMapDoesntHaveTheItem
              tempItemsForUserStatsMap.addAll({
                eachItem['item']: {
                  'numberOfUnits': eachItem['number'],
                  'totalAmountOfEachItem':
                      (eachItem['priceofeach'] * eachItem['number'])
                }
              });
            }
          }
        }
      }

//FinallyAllTheMapsWeHaveMadeShouldBeConvertedToIncrementAndSaved
      Map<String, dynamic> tempCaptainItemsSoldStatsMap =
          updateMapWithIncrements(tempItemsForUserStatsMap);
      mapEachCaptainOrdersTakenStatsMap.addAll({
        key: {
          'ticketsAndTableStats': {
            'numberOfTicketsTaken': FieldValue.increment(numberOfTicketsTaken),
            'numberOfTablesTaken': FieldValue.increment(1),
          },
          'itemsOrderTakenStats': tempCaptainItemsSoldStatsMap
        }
      });
    });

    individualPriceOfOneDistinctItem = [];
    numberOfOneDistinctItem = [];
    totalPriceOfOneDistinctItem = [];

    for (var distinctItemName in distinctItemNames) {
      num individualPriceOfOneDistinctItemForAddingIntoList = 0;
      num numberOfTicketsOfEachItemForAddingIntoStats = 0;
      num numberOfEachDistinctItemForAddingIntoList = 0;
      num totalPriceOfEachDistinctItemForAddingIntoList = 0;

      for (var eachItem in items) {
        if (distinctItemName == eachItem['item']) {
//FirstWeMakeSimpleCalculationForEachTicket
          individualPriceOfOneDistinctItemForAddingIntoList =
              eachItem['priceofeach'];
          numberOfTicketsOfEachItemForAddingIntoStats += 1;
          numberOfEachDistinctItemForAddingIntoList += eachItem['number'];
          totalPriceOfEachDistinctItemForAddingIntoList +=
              (eachItem['priceofeach'] * eachItem['number']);
        }
      }
//CulminationOfThisMapWillBeMadeIntoEachSoldItemStatsMap
      Map<String, dynamic> tempIndividualMenuItemSoldStatMap = HashMap();
      if (individualPriceOfOneDistinctItemForAddingIntoList != 0) {
        individualPriceOfOneDistinctItem
            .add(individualPriceOfOneDistinctItemForAddingIntoList);
      }
      if (numberOfEachDistinctItemForAddingIntoList != 0) {
        toCheckPastOrderHistoryMap.addAll(
            {distinctItemName: numberOfEachDistinctItemForAddingIntoList});
        statisticsMap.addAll({
          distinctItemName:
              FieldValue.increment(numberOfEachDistinctItemForAddingIntoList)
        });

        tempIndividualMenuItemSoldStatMap.addAll({
          'numberOfTickets':
              FieldValue.increment(numberOfTicketsOfEachItemForAddingIntoStats)
        });

        tempIndividualMenuItemSoldStatMap.addAll({
          'numberOfUnits':
              FieldValue.increment(numberOfEachDistinctItemForAddingIntoList)
        });
        numberOfOneDistinctItem.add(numberOfEachDistinctItemForAddingIntoList);
      }
      if (totalPriceOfEachDistinctItemForAddingIntoList != 0) {
        totalPriceOfOneDistinctItem
            .add(totalPriceOfEachDistinctItemForAddingIntoList);
        tempIndividualMenuItemSoldStatMap.addAll({
          'totalAmountOfEachItem': FieldValue.increment(
              totalPriceOfEachDistinctItemForAddingIntoList)
        });
        if (json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                    listen: false)
                .restaurantInfoDataFromClass)['cgst'] !=
            0) {
//ThisMeansThereIsCgstAndWeNeedToIncrementCgst
          tempIndividualMenuItemSoldStatMap.addAll({
            'cgstAmountOfEachItem': FieldValue.increment(num.parse(
                ((totalPriceOfEachDistinctItemForAddingIntoList) *
                        (json.decode(
                                Provider.of<PrinterAndOtherDetailsProvider>(
                                        context,
                                        listen: false)
                                    .restaurantInfoDataFromClass)['cgst'] /
                            100))
                    .toStringAsFixed(2)))
          });
        } else {
//ThisMeansThereIsNoCgstInTheHotel
          tempIndividualMenuItemSoldStatMap
              .addAll({'cgstAmountOfEachItem': FieldValue.increment(0)});
        }
        if (json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                    listen: false)
                .restaurantInfoDataFromClass)['sgst'] !=
            0) {
//ThisMeansThereIsCgstAndWeNeedToIncrementCgst
          tempIndividualMenuItemSoldStatMap.addAll({
            'sgstAmountOfEachItem': FieldValue.increment(num.parse(
                ((totalPriceOfEachDistinctItemForAddingIntoList) *
                        (json.decode(
                                Provider.of<PrinterAndOtherDetailsProvider>(
                                        context,
                                        listen: false)
                                    .restaurantInfoDataFromClass)['sgst'] /
                            100))
                    .toStringAsFixed(2)))
          });
        } else {
//ThisMeansThereIsNoCgstInTheHotel
          tempIndividualMenuItemSoldStatMap
              .addAll({'sgstAmountOfEachItem': FieldValue.increment(0)});
        }
//NowThatOneItemMapIsCompletedWeAddItWithItemNameIntoIndividualItemsStatsMap
//AndInTheArrayOfItems
        arraySoldItemsCategoryArray.add(distinctItemName);
        menuIndividualItemsStatsMap
            .addAll({distinctItemName: tempIndividualMenuItemSoldStatMap});
      }
//ThisIsToPutAllTheItemsInThePrintOrdersMap
      if (printOrdersMap.length < 10) {
        printOrdersMap.addAll({
          '0${printOrdersMap.length} . ${distinctItemName} x ${individualPriceOfOneDistinctItemForAddingIntoList.toString()} x ${numberOfEachDistinctItemForAddingIntoList.toString()} = ':
              (totalPriceOfEachDistinctItemForAddingIntoList).toString()
        });
      } else {
//ifNumberMoreThan9,WeDon'tNeedTheAdditionOf 0 at First
        printOrdersMap.addAll({
          '${printOrdersMap.length} . ${distinctItemName} x ${individualPriceOfOneDistinctItemForAddingIntoList} x  ${numberOfEachDistinctItemForAddingIntoList} = ':
              (totalPriceOfEachDistinctItemForAddingIntoList).toString()
        });
      }
    }
    totalPriceOfAllItems =
        (totalPriceOfOneDistinctItem.reduce((a, b) => a + b));
//AddingExtraItemChargesWithTotalPrice
    String extraItemsNames = '*';
    String extraItemsNumbers = '*';
    String tempExtraParcelCharge = '';
    String tempExtraDeliveryCharge = '';
    extraItemsToPrint = [];
    extraItemsPricesToPrint = [];
    if (extraChargesMapFromServer.isNotEmpty) {
      num extrasCounter = 941;

      extraChargesMapFromServer.forEach((key, value) {
//AddingExtraChargesToStatisticsMap
        if (key != 'Delivery Charges' && key != 'Parcel Charges') {
          arraySoldItemsCategoryArray.add(key);
          extraIndividualItemsStatsMap.addAll({
            key: {
              'numberOfUnits': FieldValue.increment(0),
              'totalAmountOfEachItem': FieldValue.increment(value),
              'cgstAmountOfEachItem': json.decode(
                          Provider.of<PrinterAndOtherDetailsProvider>(context,
                                  listen: false)
                              .restaurantInfoDataFromClass)['cgst'] ==
                      0
                  ? FieldValue.increment(0)
                  : FieldValue.increment(num.parse(((value) *
                          (json.decode(
                                  Provider.of<PrinterAndOtherDetailsProvider>(
                                          context,
                                          listen: false)
                                      .restaurantInfoDataFromClass)['cgst'] /
                              100))
                      .toStringAsFixed(2))),
              'sgstAmountOfEachItem': json.decode(
                          Provider.of<PrinterAndOtherDetailsProvider>(context,
                                  listen: false)
                              .restaurantInfoDataFromClass)['sgst'] ==
                      0
                  ? FieldValue.increment(0)
                  : FieldValue.increment(num.parse(((value) *
                          (json.decode(
                                  Provider.of<PrinterAndOtherDetailsProvider>(
                                          context,
                                          listen: false)
                                      .restaurantInfoDataFromClass)['sgst'] /
                              100))
                      .toStringAsFixed(2))),
            }
          });
          printOrdersMap
              .addAll({'${extrasCounter.toString()}*$key': value.toString()});
          extraItemsToPrint.add(key);
          extraItemsPricesToPrint.add(value.toString());
          extrasCounter++;
          extraItemsNames += '$key*';
          extraItemsNumbers += '${value.toString()}*';
        } else if (key == 'Parcel Charges') {
          arraySoldItemsCategoryArray.add(key);
          generalStatsMap.addAll({key: FieldValue.increment(value)});
          printOrdersMap.addAll({'971*$key': value.toString()});
          tempExtraParcelCharge = value.toString();
        } else if (key == 'Delivery Charges') {
          arraySoldItemsCategoryArray.add(key);
          generalStatsMap.addAll({key: FieldValue.increment(value)});
          printOrdersMap.addAll({'973*$key': value.toString()});
          tempExtraDeliveryCharge = value.toString();
        }
//OrderHistoryIsNotAnIncrementalValueLikeStatistics
//SoOnlyStatisticsIsAddedAsIncrementalValue

        toCheckPastOrderHistoryMap.addAll({key: value});
        statisticsMap.addAll({key: FieldValue.increment(value)});
        totalPriceOfAllItems += value;
      });
    }
    if (tempExtraParcelCharge != '') {
      extraItemsNames += 'Parcel Charges*';
      extraItemsNumbers += '$tempExtraParcelCharge*';
      extraItemsToPrint.add('Parcel Charges');
      extraItemsPricesToPrint.add(tempExtraParcelCharge);
    }
    if (tempExtraDeliveryCharge != '') {
      extraItemsNames += 'Delivery Charges*';
      extraItemsNumbers += '$tempExtraDeliveryCharge*';
      extraItemsToPrint.add('Delivery Charges');
      extraItemsPricesToPrint.add(tempExtraDeliveryCharge);
    }
    if (extraItemsNames != '*') {
      printOrdersMap.addAll({'extraItemsDistinctNames': extraItemsNames});
    }
    if (extraItemsNumbers != '*') {
      printOrdersMap.addAll({'extraItemsDistinctNumbers': extraItemsNumbers});
    }

    if (discountValueClickedTruePercentageClickedFalse) {
      if (discountEnteredValue != '') {
        discount = num.parse(discountEnteredValue);
      } else {
        discount = 0;
      }
    } else {
      if (discountEnteredValue != '') {
        discount = num.parse(
            (totalPriceOfAllItems * (num.parse(discountEnteredValue) / 100))
                .toStringAsFixed(2));
      } else {
        discount = 0;
      }
    }
    //thisWillHelpForTakingOneParticularDay'sOrdersAloneInTheFuture
    if (cancelledItemsInOrderFromServerMap.isNotEmpty) {
      allItemsCancellingUpdateInServer();
    }

    // printOrdersMap.addAll({'Total = ': (totalPriceOfAllItems.toString())});

    // cgstCalculatedForBillFunction();
    // sgstCalculatedForBillFunction();
    if (baseInfoFromServerMap['billClosingPhoneOrderIdWithTime'] != null &&
        paymentDoneClicked &&
        billClosureTimeForAtleastOnePersonAvailable) {
      print('came inside step 1');
//WithBillClosureCheckMapWeEnsureTheDataOfWhoClosedIsThere
      paymentDoneClicked = false;
      // Timer(Duration(milliseconds: 500), () {
      checkingDocumentIdAlreadyExistsInOrderHistory();
      // });
    }
  }

  List<Map<String, dynamic>> cancelledMapsForServerUpdate() {
    List<Map<String, dynamic>> cancellingUpdateMapsList = [];
    Map<String, dynamic> tempAllCancelledItems =
        cancelledItemsInOrderFromServerMap;
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
              'totalAmount': tempIndividualItemsRejected[value['itemName']]
                      ['totalAmountOfIndividualItems'] +
                  (value['numberOfItem'] * value['itemPrice'])
            };
          } else {
            tempIndividualItemsRejected.addAll({
              value['itemName']: {
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
                value['itemName']: {
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
        } else {
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

  void allItemsCancellingUpdateInServer() {
    List<Map<String, dynamic>> cancellationUpdateMaps =
        cancelledMapsForServerUpdate();

    Map<String, dynamic> itemCancellationMap = cancellationUpdateMaps[0];
    Map<String, dynamic> captainCancellationMap = cancellationUpdateMaps[1];
    Map<String, dynamic> chefRejectionMap = cancellationUpdateMaps[2];
    Map<String, dynamic> cancelledItemsInOrder = cancellationUpdateMaps[3];

    Map<String, dynamic> itemCancellationMapForServerUpdate = HashMap();
    itemCancellationMap.forEach((key, value) {
      List<dynamic> tempNumberOfTimes = value['numberOfTimes'];
      List<dynamic> tempNumberOfItems = value['numberOfItems'];
      List<dynamic> tempTotalAmount = value['totalAmount'];
      List<num> numberOfTimes =
          tempNumberOfTimes.map((e) => num.parse(e.toString())).toList();
      List<num> numberOfItems =
          tempNumberOfItems.map((e) => num.parse(e.toString())).toList();
      List<num> totalAmount =
          tempTotalAmount.map((e) => num.parse(e.toString())).toList();

      itemCancellationMapForServerUpdate.addAll({
        key: {
          'numberOfTimes':
              FieldValue.increment(numberOfTimes.reduce((a, b) => a + b)),
          'numberOfItems':
              FieldValue.increment(numberOfItems.reduce((a, b) => a + b)),
          'totalAmount':
              FieldValue.increment(totalAmount.reduce((a, b) => a + b)),
        }
      });
    });
    Map<String, dynamic> captainCancellationMapForServerUpdate = HashMap();
    if (captainCancellationMap.isNotEmpty) {
      captainCancellationMap.forEach((key, value) {
        List<dynamic> tempNumberOfTimes = value['numberOfTimes'];
        List<dynamic> tempNumberOfItems = value['numberOfItems'];
        List<dynamic> tempTotalAmount = value['totalAmount'];
        Map<String, dynamic> tempIndividualItemsCancelled =
            value['individualItemsCancelled'];
        List<num> numberOfTimes =
            tempNumberOfTimes.map((e) => num.parse(e.toString())).toList();
        List<num> numberOfItems =
            tempNumberOfItems.map((e) => num.parse(e.toString())).toList();
        List<num> totalAmount =
            tempTotalAmount.map((e) => num.parse(e.toString())).toList();
        captainCancellationMapForServerUpdate.addAll({
          key: {
            'numberOfTimes':
                FieldValue.increment(numberOfTimes.reduce((a, b) => a + b)),
            'numberOfItems':
                FieldValue.increment(numberOfItems.reduce((a, b) => a + b)),
            'totalAmount':
                FieldValue.increment(totalAmount.reduce((a, b) => a + b)),
            'individualItemsCancelled':
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
        List<num> numberOfTimes =
            tempNumberOfTimes.map((e) => num.parse(e.toString())).toList();
        List<num> numberOfItems =
            tempNumberOfItems.map((e) => num.parse(e.toString())).toList();
        List<num> totalAmount =
            tempTotalAmount.map((e) => num.parse(e.toString())).toList();
        chefRejectionMapForServerUpdate.addAll({
          key: {
            'numberOfTimes':
                FieldValue.increment(numberOfTimes.reduce((a, b) => a + b)),
            'numberOfItems':
                FieldValue.increment(numberOfItems.reduce((a, b) => a + b)),
            'totalAmount':
                FieldValue.increment(totalAmount.reduce((a, b) => a + b)),
            'individualItemsRejected':
                updateMapWithIncrements(tempIndividualItemsRejected)
          }
        });
      });
    }

    printOrdersMap.addAll({'cancelledItemsInOrder': cancelledItemsInOrder});
    print('cancelledItemsInOrder1');
    print(printOrdersMap['cancelledItemsInOrder']);
    subMasterBilledCancellationStats = {};
    subMasterBilledCancellationStats.addAll({
      'mapCancelledIndividualItemsStats': itemCancellationMapForServerUpdate
    });
    if (captainCancellationMapForServerUpdate.isNotEmpty) {
      subMasterBilledCancellationStats.addAll(
          {'mapCancellingCaptainStats': captainCancellationMapForServerUpdate});
    }
    if (chefRejectionMapForServerUpdate.isNotEmpty) {
      subMasterBilledCancellationStats
          .addAll({'mapRejectingChefStats': chefRejectionMapForServerUpdate});
    }
  }

  void checkingDocumentIdAlreadyExistsInOrderHistory() async {
    try {
      final docIdCheckSnapshot = await FirebaseFirestore.instance
          .collection(widget.hotelName)
          .doc('salesBills')
          .collection(statisticsYear)
          .doc(statisticsMonth)
          .collection(statisticsDay)
          .doc(orderHistoryDocID)
          .get()
          .timeout(Duration(seconds: 5));
      if (docIdCheckSnapshot == null || !docIdCheckSnapshot.exists) {
        if (!noItemsInTable) {
          print('came inside step 4');
          Map<String, dynamic> tableClosureCheckMap =
              baseInfoFromServerMap['billClosingPhoneOrderIdWithTime'];
          if (tableClosureCheckMap.isNotEmpty) {
            String keyPhoneNumberOfUserWhoClosedFirst = '';
            Timestamp firstTimeOfClosure = Timestamp.fromDate(DateTime(5000));
            tableClosureCheckMap.forEach((key, value) {
              if (value['timeOfClosure'] != null) {
                if ((firstTimeOfClosure.compareTo(value['timeOfClosure']) ==
                        1) &&
                    value['endingOrderId'] == orderStartTimeForCreatingDocId) {
//WeCheckWhetherEndIdAndStartOrderIdAreSameAlongWithLesserTime
//ThisIsToStopMixUpOfTables...
// ...WhereSlowNetPhoneAccidentallySendsOldEndOrderIdToNewOrder
                  keyPhoneNumberOfUserWhoClosedFirst = key;
                  firstTimeOfClosure = value['timeOfClosure'];
                }
              }
            });

            if (keyPhoneNumberOfUserWhoClosedFirst != '') {
//ThisMeansSomeBodyHasClosedTheTableAlready
              if (keyPhoneNumberOfUserWhoClosedFirst ==
                  Provider.of<PrinterAndOtherDetailsProvider>(context,
                          listen: false)
                      .currentUserPhoneNumberFromClass) {
//ThisMeansThisUserIsClosingTheTable
                orderHistoryChecked = 'closeBill';

                // serverUpdateOfBill();
              } else {
//ThisMeansSomebodyOtherThanThisUserIsClosingTheTable
                screenPopOutTimerAfterServerUpdate();
              }
            }
          }
        } else {
//ThisMeansWeNeedToDeleteTheSerialNumber
//ThatWeHadSentToStatisticsBecauseTheTableIsAlreadyClosed
          Map<String, dynamic> tempSerialInStatisticsMap = HashMap();
          tempSerialInStatisticsMap
              .addAll({orderHistoryDocID: FieldValue.delete()});
          FirebaseFirestore.instance
              .collection(widget.hotelName)
              .doc('reports')
              .collection('dailyReports')
              .doc(statisticsYear)
              .collection(statisticsMonth)
              .doc(statisticsDay)
              .set({'statisticsDocumentIdMap': tempSerialInStatisticsMap},
                  SetOptions(merge: true));
        }
      } else {
//ThisMeansThatBillAlreadyExists.WeNeedToThrowAlertDialogBoxAndCloseTheBill

      }
    } catch (e) {
      if (serialNumber == 0) {
        // ThisMeansThatTheDataHasNotReachedTheServer
        Map<String, dynamic> tempSerialInStatisticsMap = HashMap();
        tempSerialInStatisticsMap.addAll({
          orderHistoryDocID: {
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .currentUserPhoneNumberFromClass: FieldValue.delete()
          }
        });
        FirebaseFirestore.instance
            .collection(widget.hotelName)
            .doc('reports')
            .collection('dailyReports')
            .doc(statisticsYear)
            .collection(statisticsMonth)
            .doc(statisticsDay)
            .set({'statisticsDocumentIdMap': tempSerialInStatisticsMap},
                SetOptions(merge: true));
      }
      clearingCurrentUserBillingTime();
    }
  }

  void clearingCurrentUserBillingTime() {
    setState(() {
      showSpinner = false;
    });

    show('Please Check Internet Connection and Try Again');

    Map<String, dynamic> tempBaseInfoMap = HashMap();
    tempBaseInfoMap.addAll({
      'billClosingPhoneOrderIdWithTime': {
        Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .currentUserPhoneNumberFromClass: FieldValue.delete()
      }
    });

    Map<String, dynamic> tempMasterMap = HashMap();
    tempMasterMap.addAll({'baseInfoMap': tempBaseInfoMap});

    FireStoreAddOrderInRunningOrderFolder(
            hotelName: widget.hotelName,
            seatingNumber: widget.itemsFromThisDocumentInFirebaseDoc,
            ordersMap: tempMasterMap)
        .addOrder();
  }

  void timerForNullifyingSerialNumberTimeStampDataInServer() {
    Timer(Duration(seconds: 5), () {
      if (gotSerialNumber == false) {
        secondaryPrintButtonTapCheck = false;
//thisMeansThatEvenAfterSevenSecondsWeHaven'tGotTheSerialNumber
//ThisMeansWeHaventGotTheDataEvenAfter5Seconds
        //ThisMeansThatTheDataHasNotReachedTheServer
        Map<String, dynamic> tempSerialInStatisticsMap = HashMap();
        tempSerialInStatisticsMap.addAll({
          orderHistoryDocID: {
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .currentUserPhoneNumberFromClass: FieldValue.delete()
          }
        });
        FirebaseFirestore.instance
            .collection(widget.hotelName)
            .doc('reports')
            .collection('dailyReports')
            .doc(statisticsYear)
            .collection(statisticsMonth)
            .doc(statisticsDay)
            .set({'statisticsDocumentIdMap': tempSerialInStatisticsMap},
                SetOptions(merge: true));
        setState(() {
          showSpinner = false;
          tappedPrintButton = false;
        });
        show('Please check Internet & Reprint bill');
      }
    });
  }

  num totalPriceAfterDiscountOfBill() {
    // totalPriceAfterDiscount= totalPriceOfAllItems - discount;
    return totalPriceOfAllItems - discount;
  }

  num cgstCalculatedForBillFunction() {
    // setState(() {
    if (discount == 0) {
      return num.parse((totalPriceOfAllItems *
              (json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                          listen: false)
                      .restaurantInfoDataFromClass)['cgst'] /
                  100))
          .toStringAsFixed(2));
    } else {
      // cgstCalculatedForBill =
      //     (totalPriceOfAllItems - discount) * (widget.cgstPercentage / 100);

      return num.parse(((totalPriceOfAllItems - discount) *
              (json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                          listen: false)
                      .restaurantInfoDataFromClass)['cgst'] /
                  100))
          .toStringAsFixed(2));
    }
    // });
    // print('cgstCalculatedForBill');
    // print(cgstCalculatedForBill);

    // setState(() {});
  }

  num sgstCalculatedForBillFunction() {
    // setState(() {
    if (discount == 0) {
      return num.parse((totalPriceOfAllItems *
              (json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                          listen: false)
                      .restaurantInfoDataFromClass)['sgst'] /
                  100))
          .toStringAsFixed(2));
    } else {
      return num.parse(((totalPriceOfAllItems - discount) *
              (json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                          listen: false)
                      .restaurantInfoDataFromClass)['sgst'] /
                  100))
          .toStringAsFixed(2));
    }
  }

  num totalBillWithTaxes() {
    // print((totalPriceOfAllItems -
    //     discount +
    //     cgstCalculatedForBillFunction() +
    //     sgstCalculatedForBillFunction())
    //     .toStringAsFixed(2));
    return num.parse((totalPriceOfAllItems -
            discount +
            cgstCalculatedForBillFunction() +
            sgstCalculatedForBillFunction())
        .toStringAsFixed(2));
  }

  String roundOff() {
    num roundOffValue = (totalBillWithTaxes().round()) - totalBillWithTaxes();
    if (roundOffValue > 0) {
      return '+${roundOffValue.toStringAsFixed(2)}';
    } else if (roundOffValue < 0) {
      return '${roundOffValue.toStringAsFixed(2)}';
    } else {
      return '0';
    }
  }

  String totalBillWithTaxesAsString() {
    return (totalBillWithTaxes()).round().toStringAsFixed(2);
  }

  void showMethodCaller(String showMessage) {
    show(showMessage);
  }

  void showMethodCallerWithShowSpinnerOffForBluetooth(String showMessage) {
    show(showMessage);
    setState(() {
      showSpinner = false;
      bluetoothBillConnect = false;
      bluetoothBillConnectTried = false;
      _isConnected = false;
      tappedPrintButton = false;
    });
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

  void errorAlertDialogBox() async {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Center(
            child: Text(
          'ERROR!',
          style: TextStyle(color: Colors.red),
        )),
        content: Text('${errorMessage}'),
        actions: [
          ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK')),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void chargesAddBottomBar() {
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext buildContext) {
          return StatefulBuilder(builder: (context, setStateSB) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 10),
                    Text('Add Charges', style: TextStyle(fontSize: 30)),
                    SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(30)),
                      width: 200,
                      height: 50,
                      // height: 200,
                      child: Center(
                        child: DropdownButtonFormField(
                          decoration: InputDecoration.collapsed(hintText: ''),
                          isExpanded: true,
                          // underline: Container(),
                          dropdownColor: Colors.green,
                          value: chargesNamesList[0],
                          onChanged: (value) {
                            if (value.toString() != 'Other') {
                              setStateSB(() {
                                tempChargeName = value.toString();
                              });
                            } else {
                              setStateSB(() {
                                tempChargeName = '';
                              });
                            }
                          },
                          items: chargesNamesList.map((title) {
//DropDownMenuItemWillHaveOneByOneItems,WePutThatAsList
//ValueWillBeEachTitle
                            return DropdownMenuItem(
                              alignment: Alignment.center,
                              child: Text(title,
                                  style: const TextStyle(
                                      fontSize: 15, color: Colors.white)),
                              value: title,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Visibility(
                      visible: tempChargeName == '' ? true : false,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Name of Charges',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 15),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: tempChargeName == '' ? true : false,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        child: TextField(
                          maxLength: 40,
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (value) {
                            tempChargeName = value;
                          },
                          decoration:
                              // kTextFieldInputDecoration,
                              InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  hintText: 'Enter Charges',
                                  hintStyle: TextStyle(color: Colors.grey),
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(10)),
                                      borderSide:
                                          BorderSide(color: Colors.green)),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(10)),
                                      borderSide:
                                          BorderSide(color: Colors.green))),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Price',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 15),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(8),
                      child: TextField(
                        maxLength: 10,
                        controller: _controller,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        onChanged: (value) {
                          tempChargesPriceForEditInString = value;
                        },
                        decoration:
                            // kTextFieldInputDecoration,
                            InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                hintText: 'Enter Price',
                                hintStyle: TextStyle(color: Colors.grey),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)),
                                    borderSide:
                                        BorderSide(color: Colors.green)),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(10)),
                                    borderSide:
                                        BorderSide(color: Colors.green))),
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Colors.orangeAccent),
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('Cancel')),
                        ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Colors.green),
                            ),
                            onPressed: () {
                              if (tempChargeName == '') {
                                errorMessage =
                                    'Please enter Name of the Charge';
                                errorAlertDialogBox();
                              } else if (tempChargesPriceForEditInString ==
                                  '') {
                                errorMessage =
                                    'Please enter Price of the Charge';
                                errorAlertDialogBox();
                              } else {
                                tempChargesPriceForEdit =
                                    num.parse(tempChargesPriceForEditInString);
                                Map<String, dynamic> extrasMap = {
                                  tempChargeName: tempChargesPriceForEdit
                                };
                                Map<String, dynamic> masterOrderMapToServer =
                                    HashMap();
                                masterOrderMapToServer.addAll({
                                  'baseInfoMap': {'extraCharges': extrasMap}
                                });
                                FireStoreAddOrderInRunningOrderFolder(
                                        hotelName: widget.hotelName,
                                        seatingNumber: widget
                                            .itemsFromThisDocumentInFirebaseDoc,
                                        ordersMap: masterOrderMapToServer)
                                    .addOrder();

                                Navigator.pop(context);
                              }
                            },
                            child: Text('Add'))
                      ],
                    )
                  ],
                ),
              ),
            );
          });
        });
  }

  void existingExtraChargesBottomBar() {
    List<Map<String, dynamic>> tempExtraChargesList = [];
//ThisIsToShowDeliveryChargesAlwaysAtTheEnd
    num tempDeliveryCharges = -999;
//ThisIsToShowParcelChargesAlwaysAtTheEnd
    num tempParcelCharges = -999;
    extraChargesMapFromServer.forEach((key, value) {
      if (key != 'Delivery Charges' && key != 'Parcel Charges') {
        tempExtraChargesList
            .add({'extraChargesName': key, 'extraChargesPrice': value});
      } else if (key == 'Delivery Charges') {
        tempDeliveryCharges = value;
      } else if (key == 'Parcel Charges') {
        tempParcelCharges = value;
      }
    });
    if (tempParcelCharges != -999) {
      tempExtraChargesList.insert(tempExtraChargesList.length, {
        'extraChargesName': 'Parcel Charges',
        'extraChargesPrice': tempParcelCharges
      });
      tempParcelCharges = -999;
    }
    if (tempDeliveryCharges != -999) {
      tempExtraChargesList.insert(tempExtraChargesList.length, {
        'extraChargesName': 'Delivery Charges',
        'extraChargesPrice': tempDeliveryCharges
      });
      tempDeliveryCharges = -999;
    }
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext buildContext) {
          return StatefulBuilder(builder: (context, setStateSB) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 10),
                Text('Extra Charges', style: TextStyle(fontSize: 30)),
                SizedBox(height: 20),
                Flexible(
                    child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: tempExtraChargesList.length,
                        itemBuilder: (context, index) {
                          final extraChargeName =
                              tempExtraChargesList[index]['extraChargesName'];
                          final extraChargePrice =
                              tempExtraChargesList[index]['extraChargesPrice'];
                          return ListTile(
                            title: Text(extraChargeName),
                            subtitle:
                                Text('Price: ${extraChargePrice.toString()}'),
                            trailing: IconButton(
                                icon: Icon(Icons.remove, color: Colors.red),
                                onPressed: () {
                                  Map<String, dynamic> extrasMap = {
                                    extraChargeName: FieldValue.delete()
                                  };
                                  Map<String, dynamic> masterOrderMapToServer =
                                      HashMap();
                                  masterOrderMapToServer.addAll({
                                    'baseInfoMap': {'extraCharges': extrasMap}
                                  });
                                  FireStoreAddOrderInRunningOrderFolder(
                                          hotelName: widget.hotelName,
                                          seatingNumber: widget
                                              .itemsFromThisDocumentInFirebaseDoc,
                                          ordersMap: masterOrderMapToServer)
                                      .addOrder();
                                  setStateSB(() {
                                    tempExtraChargesList.removeAt(index);
                                    if (tempExtraChargesList.isEmpty) {
                                      Navigator.pop(context);
                                    }
                                  });
                                }),
                          );
                        })),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(
                              Colors.orangeAccent),
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
                          Navigator.pop(context);
                          tempChargeName = chargesNamesList[0];
                          tempChargesPriceForEditInString = '';
                          _controller.clear();
                          chargesAddBottomBar();
                        },
                        child: Text('Add'))
                  ],
                )
              ],
            );
          });
        });
  }

  Widget extraChargesInMainScreen() {
    List<Map<String, dynamic>> tempExtraChargesList = [];
//ThisIsToShowDeliveryChargesAlwaysAtTheEnd
    num tempDeliveryCharges = -999;
//ThisIsToShowParcelChargesAlwaysAtTheEnd
    num tempParcelCharges = -999;
    extraChargesMapFromServer.forEach((key, value) {
      if (key != 'Delivery Charges' && key != 'Parcel Charges') {
        tempExtraChargesList
            .add({'extraChargesName': key, 'extraChargesPrice': value});
      } else if (key == 'Delivery Charges') {
        tempDeliveryCharges = value;
      } else if (key == 'Parcel Charges') {
        tempParcelCharges = value;
      }
    });
    if (tempParcelCharges != -999) {
      tempExtraChargesList.insert(tempExtraChargesList.length, {
        'extraChargesName': 'Parcel Charges',
        'extraChargesPrice': tempParcelCharges
      });
      tempParcelCharges = -999;
    }
    if (tempDeliveryCharges != -999) {
      tempExtraChargesList.insert(tempExtraChargesList.length, {
        'extraChargesName': 'Delivery Charges',
        'extraChargesPrice': tempDeliveryCharges
      });
      tempDeliveryCharges = -999;
    }
    return Container(
        child: ListView.builder(
            shrinkWrap: true,
            itemCount: tempExtraChargesList.length,
            itemBuilder: (context, index) {
              final extraChargeName =
                  tempExtraChargesList[index]['extraChargesName'];
              final extraChargePrice =
                  tempExtraChargesList[index]['extraChargesPrice'];
              return ListTile(
                title: Text(extraChargeName, style: TextStyle(fontSize: 18)),
                trailing: Text('${extraChargePrice.toString()}',
                    style: TextStyle(fontSize: 18)),
              );
            }));
  }

  void startOfCallForPrintingBill() {
    if (tappedPrintButton == false) {
      tappedPrintButton = true;
      if (Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .billingAssignedPrinterFromClass !=
          '{}') {
        billingPrinterAssigningMap = json.decode(
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .billingAssignedPrinterFromClass);
        billingPrinterAssigningMap.forEach((key, value) {
          billingPrinterRandomID = key;
        });
        printerSavingMap = json.decode(
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .savedPrintersFromClass);
        printerSavingMap.forEach((key, value) {
          if (key == billingPrinterRandomID) {
            billingPrinterCharacters = value;
          }
        });
      }

      printBytesGenerator();
    }
  }

  void printBytesGenerator() async {
    if (showSpinner == false) {
      setState(() {
        showSpinner = true;
      });
    }
    billBytes = [];
    final profile = await CapabilityProfile.load();
    final generator = billingPrinterCharacters['printerSize'] == '80'
        ? Generator(PaperSize.mm80, profile)
        : Generator(PaperSize.mm58, profile);
    if (billingPrinterCharacters['spacesAboveBill'] != '0') {
      for (int i = 0;
          i < num.parse(billingPrinterCharacters['spacesAboveBill']);
          i++) {
        billBytes += generator.text(" ");
      }
    }

    if (billingPrinterCharacters['printerSize'] == '80') {
      billBytes += generator.text(
          "${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['hotelname']}",
          styles: PosStyles(
              height: PosTextSize.size2,
              width: PosTextSize.size2,
              align: PosAlign.center));
      if (json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .restaurantInfoDataFromClass)['addressline1'] !=
          '') {
        billBytes += generator.text(
            "${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['addressline1']}",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.center));
      }
      if (json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .restaurantInfoDataFromClass)['addressline2'] !=
          '') {
        billBytes += generator.text(
            "${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['addressline2']}",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.center));
      }
      if (json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .restaurantInfoDataFromClass)['addressline3'] !=
          '') {
        billBytes += generator.text(
            "${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['addressline3']}",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.center));
      }
      if (json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .restaurantInfoDataFromClass)['gstcode'] !=
          '') {
        billBytes += generator.text(
            "GSTIN: ${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['gstcode']}",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.center));
      }
      if (json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .restaurantInfoDataFromClass)['phonenumber'] !=
          '') {
        billBytes += generator.text(
            "PH: ${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['phonenumber']}",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.center));
      }
      billBytes += generator.text(
          "-----------------------------------------------",
          styles: PosStyles(
              height: PosTextSize.size1,
              width: PosTextSize.size1,
              align: PosAlign.center));

      if (json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .restaurantInfoDataFromClass)['cgst'] >
          0) {
        billBytes += generator.text("TAX INVOICE",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.center));
      }
      billBytes += generator.text(" ");
      billBytes += generator.text("ORDER DATE:${printingDate}",
          styles: PosStyles(
              height: PosTextSize.size1,
              width: PosTextSize.size1,
              align: PosAlign.center));
      billBytes += generator.text(
          "-----------------------------------------------",
          styles: PosStyles(
              height: PosTextSize.size1,
              width: PosTextSize.size1,
              align: PosAlign.center));

      if (customername != '' || customermobileNumber != '') {
        String customerPrintingName =
            customername != '' ? 'Customer: ${customername}' : '';
        String customerPrintingMobile =
            customermobileNumber != '' ? 'Phone: ${customermobileNumber}' : '';
        if (customername != '') {
          billBytes += generator.text("$customerPrintingName",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.left));
        }
        if (customermobileNumber != '') {
          billBytes += generator.text("$customerPrintingMobile",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.left));
        }
      }
      if (customeraddressline1 != '') {
        billBytes += generator.text("Address: ${customeraddressline1}",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.left));
      }
      if (customername != '' ||
          customermobileNumber != '' ||
          customeraddressline1 != '') {
        billBytes += generator.text(
            "-----------------------------------------------",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.center));
      }
      billBytes += generator.row([
        PosColumn(
          text: "TOTAL NO. OF ITEMS:${distinctItemNames.length}",
          width: 6,
          styles: PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          text: "Qty:$totalQuantityOfAllItems",
          width: 6,
          styles: PosStyles(align: PosAlign.right),
        ),
      ]);
      if (thisIsParcelTrueElseFalse) {
        billBytes += generator.row([
          PosColumn(
            text: "BILL NO:${orderHistoryDocID.substring(0, 14)}",
            width: 6,
            styles: PosStyles(align: PosAlign.left),
          ),
          PosColumn(
            text:
                "TYPE:TAKE-AWAY:${tableorparcel}:${tableorparcelnumber}${parentOrChild}",
            width: 6,
            styles: PosStyles(align: PosAlign.right),
          ),
        ]);
      } else {
        billBytes += generator.row([
          PosColumn(
            text: "BILL NO:${orderHistoryDocID.substring(0, 14)}",
            width: 6,
            styles: PosStyles(align: PosAlign.left),
          ),
          PosColumn(
            text:
                "TYPE:DINE-IN:${tableorparcel}:${tableorparcelnumber}${parentOrChild}",
            width: 6,
            styles: PosStyles(align: PosAlign.right),
          ),
        ]);
      }
      billBytes += generator.text(" Sl.No: ${serialNumber.toString()}",
          styles: PosStyles(
              height: PosTextSize.size2,
              width: PosTextSize.size2,
              align: PosAlign.left));
      billBytes += generator.text(
          "-----------------------------------------------",
          styles: PosStyles(
              height: PosTextSize.size1,
              width: PosTextSize.size1,
              align: PosAlign.center));
      billBytes += generator.row([
        PosColumn(
          text: "Item Name",
          width: 6,
        ),
        PosColumn(
          text: "Price",
          width: 2,
        ),
        PosColumn(
          text: "Qty",
          width: 2,
        ),
        PosColumn(
          text: "Amount",
          width: 2,
        ),
      ]);
      billBytes += generator.text(
          "-----------------------------------------------",
          styles: PosStyles(
              height: PosTextSize.size1,
              width: PosTextSize.size1,
              align: PosAlign.center));

      for (int i = 0; i < distinctItemNames.length; i++) {
        if ((' '.allMatches(distinctItemNames[i]).length >= 2)) {
          String firstName = '';
          String secondName = '';
          String thirdName = '';
          final longItemNameSplit = distinctItemNames[i].split(' ');
          for (int i = 0; i < longItemNameSplit.length; i++) {
            if (i == 0) {
              firstName = longItemNameSplit[i];
            }
            if (i == 1) {
              firstName += ' ${longItemNameSplit[i]}';
            }
            if (i == 2) {
              secondName += '${longItemNameSplit[i]} ';
            }
            if (i == 3) {
              secondName += '${longItemNameSplit[i]}';
            }
            if (i > 3) {
              thirdName += '${longItemNameSplit[i]} ';
            }
          }
          billBytes += generator.row([
            PosColumn(
              text: "$firstName",
              width: 6,
            ),
            PosColumn(
              text: "${individualPriceOfOneDistinctItem[i]}",
              width: 2,
            ),
            PosColumn(
              text: "${numberOfOneDistinctItem[i]}",
              width: 2,
            ),
            PosColumn(
              text: "${totalPriceOfOneDistinctItem[i]}",
              width: 2,
            ),
          ]);
          billBytes += generator.row([
            PosColumn(
              text: "  $secondName",
              width: 6,
            ),
            PosColumn(
              text: " ",
              width: 2,
            ),
            PosColumn(
              text: " ",
              width: 2,
            ),
            PosColumn(
              text: " ",
              width: 2,
            ),
          ]);

          if (thirdName != '') {
            billBytes += generator.row([
              PosColumn(
                text: "  $thirdName",
                width: 6,
              ),
              PosColumn(
                text: " ",
                width: 2,
              ),
              PosColumn(
                text: " ",
                width: 2,
              ),
              PosColumn(
                text: " ",
                width: 2,
              ),
            ]);
          }
        } else {
          billBytes += generator.row([
            PosColumn(
              text: "${distinctItemNames[i]}",
              width: 6,
            ),
            PosColumn(
              text: "${individualPriceOfOneDistinctItem[i]}",
              width: 2,
            ),
            PosColumn(
              text: "${numberOfOneDistinctItem[i]}",
              width: 2,
            ),
            PosColumn(
              text: "${totalPriceOfOneDistinctItem[i]}",
              width: 2,
            ),
          ]);
        }
      }

      if (extraItemsToPrint.isNotEmpty) {
        for (int l = 0; l < extraItemsToPrint.length; l++) {
          billBytes += generator.row([
            PosColumn(
              text: "${extraItemsToPrint[l]}",
              width: 6,
            ),
            PosColumn(
              text: " ",
              width: 2,
            ),
            PosColumn(
              text: " ",
              width: 2,
            ),
            PosColumn(
              text: "${extraItemsPricesToPrint[l]}",
              width: 2,
            ),
          ]);
        }
      }

      billBytes += generator.text(
          "-----------------------------------------------",
          styles: PosStyles(
              height: PosTextSize.size1,
              width: PosTextSize.size1,
              align: PosAlign.center));
      if (discount != 0) {
        if (discountValueClickedTruePercentageClickedFalse) {
          billBytes += generator.text("Discount : ${discount}    ",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.right));
        } else {
          billBytes += generator.text(
              "Discount ${discountEnteredValue}% : ${discount}    ",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.right));
        }

        billBytes += generator.text(
            "-----------------------------------------------",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.center));
      }
      if (json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .restaurantInfoDataFromClass)['cgst'] >
          0) {
        billBytes += generator.text(
            "Sub-Total: ${totalPriceOfAllItems - discount}    ",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.right));
      }
      if (json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .restaurantInfoDataFromClass)['cgst'] >
          0) {
        billBytes += generator.text(
            "CGST @ ${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['cgst']}%: ${cgstCalculatedForBillFunction()}   ",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.right));
      }
      if (json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .restaurantInfoDataFromClass)['sgst'] >
          0) {
        billBytes += generator.text(
            "SGST @ ${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['sgst']}%: ${sgstCalculatedForBillFunction()}   ",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.right));
        billBytes += generator.text(
            "-----------------------------------------------",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.center));
      } else {
        billBytes += generator.text(" ");
      }
      if (roundOff() != '0') {
        billBytes += generator.text("Round Off: ${roundOff()}",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.right));
      }
      billBytes += generator.text(
          "GRAND TOTAL: ${totalBillWithTaxesAsString()}",
          styles: PosStyles(
              height: PosTextSize.size2,
              width: PosTextSize.size2,
              align: PosAlign.right));
      billBytes += generator.text(
          "-----------------------------------------------",
          styles: PosStyles(
              height: PosTextSize.size1,
              width: PosTextSize.size1,
              align: PosAlign.center));
      Map<String, dynamic> restaurantInfoData = json.decode(
          Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .restaurantInfoDataFromClass);
      String consumeWithinHours = '';
      if (restaurantInfoData.containsKey('parcelConsumptionHours')) {
        consumeWithinHours = restaurantInfoData['parcelConsumptionHours']
            ['mapParcelConsumptionHoursMap']['hours'];
      }
      if (thisIsParcelTrueElseFalse &&
          consumeWithinHours != '' &&
          consumeWithinHours != '0') {
        billBytes += generator.text(
            "Note:Consume Within $consumeWithinHours Hours",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.center));

        billBytes += generator.text(" ");
      }
      if (restaurantInfoData.containsKey('footerNotes')) {
        Map<String, dynamic> footerNotes =
            restaurantInfoData['footerNotes']['mapFooterNotesMap'];
        if (footerNotes.isNotEmpty) {
          footerNotes.forEach((key, value) {
            billBytes += generator.text("${value['footerString']}",
                styles: PosStyles(
                    height: PosTextSize.size1,
                    width: PosTextSize.size1,
                    align: PosAlign.center));

            ;
          });
        }
      }
    } else if (billingPrinterCharacters['printerSize'] == '58') {
      billBytes += generator.text(
          "${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['hotelname']}",
          styles: PosStyles(
              height: PosTextSize.size2,
              width: PosTextSize.size2,
              align: PosAlign.center));

      if (json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .restaurantInfoDataFromClass)['addressline1'] !=
          '') {
        billBytes += generator.text(
            "${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['addressline1']}",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.center));
      }
      if (json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .restaurantInfoDataFromClass)['addressline2'] !=
          '') {
        billBytes += generator.text(
            "${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['addressline2']}",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.center));
      }
      if (json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .restaurantInfoDataFromClass)['addressline3'] !=
          '') {
        billBytes += generator.text(
            "${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['addressline3']}",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.center));
      }
      if (json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .restaurantInfoDataFromClass)['gstcode'] !=
          '') {
        billBytes += generator.text(
            "GSTIN: ${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['gstcode']}",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.center));
      }
      if (json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .restaurantInfoDataFromClass)['phonenumber'] !=
          '') {
        billBytes += generator.text(
            "PH: ${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['phonenumber']}",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.center));
      }
      billBytes += generator.text("-------------------------------",
          styles: PosStyles(
              height: PosTextSize.size1,
              width: PosTextSize.size1,
              align: PosAlign.center));

      if (json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .restaurantInfoDataFromClass)['cgst'] >
          0) {
        billBytes += generator.text("TAX INVOICE",
            styles: PosStyles(align: PosAlign.center));
      }
      billBytes += generator.text("ORDER DATE: ${printingDate}",
          styles: PosStyles(align: PosAlign.center));

      billBytes += generator.text("-------------------------------",
          styles: PosStyles(
              height: PosTextSize.size1,
              width: PosTextSize.size1,
              align: PosAlign.center));
      if (customername != '' || customermobileNumber != '') {
        String customerPrintingName =
            customername != '' ? 'Customer: ${customername}' : '';
        String customerPrintingMobile =
            customermobileNumber != '' ? 'Phone: ${customermobileNumber}' : '';
        if (customername != '') {
          billBytes += generator.text("$customerPrintingName",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.left));
        }
        if (customermobileNumber != '') {
          billBytes += generator.text("$customerPrintingMobile",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.left));
        }
      }
      if (customeraddressline1 != '') {
        billBytes += generator.text("Address: ${customeraddressline1}",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.left));
      }
      if (customername != '' ||
          customermobileNumber != '' ||
          customeraddressline1 != '') {
        billBytes += generator.text("-------------------------------",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.center));
      }

      billBytes += generator.text(" ");
      billBytes += generator.text(
          "TOTAL NO. OF ITEMS:${distinctItemNames.length}    Qty:$totalQuantityOfAllItems",
          styles: PosStyles(
              height: PosTextSize.size1,
              width: PosTextSize.size1,
              align: PosAlign.left));

      billBytes += generator.text(
          "BILL NO: ${orderHistoryDocID.substring(0, 14)}",
          styles: PosStyles(
              height: PosTextSize.size1,
              width: PosTextSize.size1,
              align: PosAlign.left));
      if (thisIsParcelTrueElseFalse) {
        billBytes += generator.text(
            "TYPE: TAKE-AWAY : ${tableorparcel}:${tableorparcelnumber}${parentOrChild}",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.left));
      } else {
        billBytes += generator.text(
            "TYPE: DINE-IN : ${tableorparcel}:${tableorparcelnumber}${parentOrChild}",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.left));
      }
      billBytes += generator.text("Sl.No: ${serialNumber.toString()}",
          styles: PosStyles(
              height: PosTextSize.size2,
              width: PosTextSize.size2,
              align: PosAlign.left));
      billBytes += generator.text("-------------------------------",
          styles: PosStyles(
              height: PosTextSize.size1,
              width: PosTextSize.size1,
              align: PosAlign.center));
      billBytes += generator.row([
        PosColumn(
          text: "Item Name",
          styles: PosStyles(align: PosAlign.left),
          width: 8,
        ),
        PosColumn(
          text: "Amount",
          styles: PosStyles(align: PosAlign.right),
          width: 4,
        ),
      ]);
      billBytes += generator.text("-------------------------------",
          styles: PosStyles(
              height: PosTextSize.size1,
              width: PosTextSize.size1,
              align: PosAlign.center));

      for (int i = 0; i < distinctItemNames.length; i++) {
        billBytes += generator.text("${distinctItemNames[i]}",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.left));
        billBytes += generator.row([
          PosColumn(
            text:
                "${individualPriceOfOneDistinctItem[i]} x ${numberOfOneDistinctItem[i]}",
            width: 8,
            styles: PosStyles(align: PosAlign.center),
          ),
          PosColumn(
            text: "${totalPriceOfOneDistinctItem[i]}",
            width: 4,
            styles: PosStyles(align: PosAlign.right),
          ),
        ]);
      }
      billBytes += generator.text(" ");

      if (extraItemsToPrint.isNotEmpty) {
        for (int l = 0; l < extraItemsToPrint.length; l++) {
          billBytes += generator.row([
            PosColumn(
              text: "${extraItemsToPrint[l]}",
              width: 8,
            ),
            PosColumn(
              text: "${extraItemsPricesToPrint[l]}",
              width: 4,
              styles: PosStyles(align: PosAlign.right),
            ),
          ]);
        }
      }
      billBytes += generator.text("-------------------------------",
          styles: PosStyles(
              height: PosTextSize.size1,
              width: PosTextSize.size1,
              align: PosAlign.center));
      if (discount != 0) {
        if (discountValueClickedTruePercentageClickedFalse) {
          billBytes += generator.text("Discount : ${discount} ",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.right));
        } else {
          billBytes += generator.text(
              "Discount ${discountEnteredValue}% : ${discount} ",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.right));
        }
        billBytes += generator.text("-------------------------------",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.center));
      }
      if (json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .restaurantInfoDataFromClass)['cgst'] >
          0) {
        billBytes += generator.text(
            "Sub-Total : ${totalPriceOfAllItems - discount}",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.right));
      }
      if (json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .restaurantInfoDataFromClass)['cgst'] >
          0) {
        billBytes += generator.text(
            "CGST @ ${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['cgst']}% : ${cgstCalculatedForBillFunction()}",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.right));
      }
      if (json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .restaurantInfoDataFromClass)['sgst'] >
          0) {
        billBytes += generator.text(
            "SGST @ ${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['sgst']}% : ${sgstCalculatedForBillFunction()}",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.right));
        billBytes += generator.text("-------------------------------",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.center));
      } else {
        billBytes += generator.text(" ");
      }
      if (roundOff() != '0') {
        billBytes += generator.text("Round Off: ${roundOff()}",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.right));
      }
      billBytes += generator.row([
        PosColumn(
            width: 6,
            text: "GRAND TOTAL:",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.right)),
        PosColumn(
            width: 6,
            text: "${totalBillWithTaxesAsString()}",
            styles: PosStyles(
                height: PosTextSize.size2,
                width: PosTextSize.size2,
                align: PosAlign.left)),
      ]);
      billBytes += generator.text("-------------------------------",
          styles: PosStyles(
              height: PosTextSize.size1,
              width: PosTextSize.size1,
              align: PosAlign.center));
      // billBytes += generator.text(
      //     "GRAND TOTAL: ${totalBillWithTaxesAsString()}",
      //     styles: PosStyles(
      //         height: PosTextSize.size1,
      //         width: PosTextSize.size1,
      //         align: PosAlign.right));
      Map<String, dynamic> restaurantInfoData = json.decode(
          Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .restaurantInfoDataFromClass);
      String consumeWithinHours = '';
      if (restaurantInfoData.containsKey('parcelConsumptionHours')) {
        consumeWithinHours = restaurantInfoData['parcelConsumptionHours']
            ['mapParcelConsumptionHoursMap']['hours'];
      }
      if (thisIsParcelTrueElseFalse &&
          consumeWithinHours != '' &&
          consumeWithinHours != '0') {
        billBytes += generator.text(
            "Note:Consume Within $consumeWithinHours Hours",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.left));

        billBytes += generator.text(" ");
      }
      if (restaurantInfoData.containsKey('footerNotes')) {
        Map<String, dynamic> footerNotes =
            restaurantInfoData['footerNotes']['mapFooterNotesMap'];
        if (footerNotes.isNotEmpty) {
          footerNotes.forEach((key, value) {
            billBytes += generator.text("${value['footerString']}",
                styles: PosStyles(
                    height: PosTextSize.size1,
                    width: PosTextSize.size1,
                    align: PosAlign.left));

            ;
          });
        }
      }
    }
    billBytes += generator.text(" ");
    billBytes += generator.text("Thank You!!! Visit Again!!!",
        styles: PosStyles(
            height: PosTextSize.size1,
            width: PosTextSize.size1,
            align: PosAlign.center));
    if (billingPrinterCharacters['spacesBelowBill'] != '0') {
      for (int i = 0;
          i < num.parse(billingPrinterCharacters['spacesBelowBill']);
          i++) {
        billBytes += generator.text(" ");
      }
    }
    billBytes += generator.cut();

    if (billingPrinterCharacters['printerBluetoothAddress'] != 'NA' ||
        billingPrinterCharacters['printerIPAddress'] != 'NA') {
      _connectDevice();
    } else {
//InCaseUsbPrinterIsNotConnected,WeDontHaveWayToConnect.Hence,WeScanAndThenGoIn
      _scanForUsb();
    }
  }

  _scanForUsb() async {
    bool addedUSBDeviceNotAvailable = true;
//UnlikeBluetoothWeDontHavePerfectAvailableOrNotFeedbackForUsb
//HenceMakingScanForUsbDeviceEveryTimePrintIsCalled
    devices.clear();
    _subscription =
        printerManager.discovery(type: PrinterType.usb).listen((device) {
      if (device.vendorId.toString() ==
          billingPrinterCharacters['printerUsbVendorID']) {
        addedUSBDeviceNotAvailable = false;
        _connectDevice();
      }
    });
    Timer(Duration(seconds: 2), () {
      if (addedUSBDeviceNotAvailable) {
        printerManager.disconnect(type: PrinterType.usb);
        setState(() {
          showSpinner = false;
          usbBillConnect = false;
          usbBillConnectTried = false;
          _isConnected = false;
          tappedPrintButton = false;
        });
        showMethodCaller(
            '${billingPrinterCharacters['printerName']} not found');
      }
    });
  }

  _connectDevice() async {
    billPrinterType = billingPrinterCharacters['printerUsbProductID'] != 'NA'
        ? PrinterType.usb
        : billingPrinterCharacters['printerBluetoothAddress'] != 'NA'
            ? PrinterType.bluetooth
            : PrinterType.network;
    _isConnected = false;
    setState(() {
      showSpinner = true;
    });
    switch (billPrinterType) {
      case PrinterType.usb:
        printerManager.disconnect(type: PrinterType.usb);
        usbBillConnectTried = true;
        await printerManager.connect(
            type: billPrinterType,
            model: UsbPrinterInput(
                name: billingPrinterCharacters['printerManufacturerDeviceName'],
                productId: billingPrinterCharacters['printerUsbProductID'],
                vendorId: billingPrinterCharacters['printerUsbVendorID']));
        usbBillConnect = true;
        _isConnected = true;
        setState(() {
          showSpinner = true;
        });
        break;
      case PrinterType.bluetooth:
        bluetoothBillConnectTried = true;
        bluetoothBillConnect = false;
        bluetoothOnTrueOrOffFalse = false;
        timerToCheckBluetoothOnOrOff();
        await printerManager.connect(
            type: billPrinterType,
            model: BluetoothPrinterInput(
                name: billingPrinterCharacters['printerManufacturerDeviceName'],
                address: billingPrinterCharacters['printerBluetoothAddress'],
                isBle: false,
                autoConnect: _reconnect));
        bluetoothBillConnect = true;
        break;
      case PrinterType.network:
        printWithNetworkPrinter();
        break;
      default:
    }

    setState(() {});
  }

  void timerToCheckBluetoothOnOrOff() {
//OnceWeAskToConnectThroughBluetoothWithinSecondsItGoesIntoStatus
//AndSaysBluetoothIsOn
//InCaseIfItIsn'tSayingHereWeCanShowToCheckBluetooth
    Timer(Duration(seconds: 1), () {
      if (!bluetoothOnTrueOrOffFalse) {
        printerManager.disconnect(type: PrinterType.bluetooth);
        showMethodCaller(
            'Please Check Bluetooth, Printer & try Printing Again');
        bluetoothBillConnect = false;
        bluetoothBillConnectTried = false;
        bluetoothOnTrueOrOffFalse = true;
//ChangingItToTrueInCaseTheyHaveTurnedOnWhyKeepItTurnedOff
        setState(() {
          showSpinner = false;
          _isConnected = false;
          tappedPrintButton = false;
        });
      }
    });
  }

  void printThroughBluetoothOrUsb() {
    printerManager.send(type: billPrinterType, bytes: billBytes);
    if (billPrinterType == PrinterType.bluetooth) {
      showMethodCaller('Print SUCCESS...Disconnecting...');
    }
    Timer(Duration(seconds: 1), () {
      disconnectBluetoothOrUsb();
    });
  }

  void disconnectBluetoothOrUsb() {
    printerManager.disconnect(type: billPrinterType);
    updateWhetherBillPrintedOnceOrNot();
    billPrinterType == PrinterType.bluetooth
        ? Timer(Duration(seconds: 2), () {
            setState(() {
              showSpinner = false;
              usbBillConnect = false;
              usbBillConnectTried = false;
              bluetoothBillConnect = false;
              bluetoothBillConnectTried = false;
              _isConnected = false;
              tappedPrintButton = false;
            });
          })
        : Timer(Duration(milliseconds: 500), () {
            setState(() {
              showSpinner = false;
              usbBillConnect = false;
              usbBillConnectTried = false;
              bluetoothBillConnect = false;
              bluetoothBillConnectTried = false;
              _isConnected = false;
              tappedPrintButton = false;
            });
          });
  }

  Future<void> printWithNetworkPrinter() async {
    final printer =
        PrinterNetworkManager(billingPrinterCharacters['printerIPAddress']);
    PosPrintResult connect = await printer.connect();
    if (connect == PosPrintResult.success) {
      PosPrintResult printing =
          await printer.printTicket(Uint8List.fromList(billBytes));
      printer.disconnect();
      setState(() {
        showSpinner = false;
        tappedPrintButton = false;
        _isConnected = false;
      });
      updateWhetherBillPrintedOnceOrNot();
    } else {
      setState(() {
        showSpinner = false;
        tappedPrintButton = false;
        _isConnected = false;
      });
      showMethodCaller('Unable To Connect. Please Check Printer');
    }
  }

  void updateWhetherBillPrintedOnceOrNot() {
//ThisIsCalledWhenPrintingIsDoneFirstTime
    if (baseInfoFromServerMap['billPrinted'] == false) {
      Map<String, dynamic> tempBaseInfoMap = HashMap();
      tempBaseInfoMap.addAll({'billPrinted': true});

      Map<String, dynamic> tempMasterMap = HashMap();
      tempMasterMap.addAll({'baseInfoMap': tempBaseInfoMap});

      FireStoreAddOrderInRunningOrderFolder(
              hotelName: widget.hotelName,
              seatingNumber: widget.itemsFromThisDocumentInFirebaseDoc,
              ordersMap: tempMasterMap)
          .addOrder();
    }
  }

  void requestLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;
    var status1 = await Permission.locationAlways.status;
    var status2 = await Permission.location.status;
    if (status.isDenied && status1.isDenied && status2.isDenied) {
      setState(() {
        locationPermissionAccepted = false;
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
                  // Permission.locationWhenInUse.request();
                  // Navigator.of(context, rootNavigator: true)
                  //     .pop();

                  // Navigator.pop(context);
                  // print('came till this pop2');
                  // Timer? _timer;
                  // int _everySecondInRequestPermissionLoop = 0;
                  // _timer = Timer.periodic(Duration(seconds: 1),
                  //         (_) async {
                  //       if (_everySecondInRequestPermissionLoop < 2) {
                  //         print(
                  //             'duration is $_everySecondInRequestPermissionLoop');
                  //         _everySecondInRequestPermissionLoop++;
                  //       } else {
                  //         _timer?.cancel();
                  //         print('came inside timer cancel loop1111');
                  //         setState(() {
                  //           locationPermissionAccepted = true;
                  //           // Permission.location.request();
                  //         });
                  //         // savedBluetoothPrinterConnect();
                  //         if (connectingPrinterAddressChefScreen !=
                  //             '') {
                  //           printerConnectionToLastSavedPrinter();
                  //         } else {
                  //           setState(() {
                  //             noNeedPrinterConnectionScreen = false;
                  //           });
                  //         }
                  //       }
                  //     });
                },
                child: Text('Ok'))
          ],
        ),
        barrierDismissible: false,
      );

      // showDialog(
      //   context: context,
      //   builder: (_) => AlertDialog(
      //     elevation: 24.0,
      //     backgroundColor: Colors.greenAccent,
      //     // shape: CircleBorder(),
      //     title: Text('Permission for Location Use'),
      //     content: Text(
      //         'Orders collects location data only to enable bluetooth printer. This information will not be used when the app is closed or not in use. Kindly allow location access when prompted'),
      //     actions: [
      //       TextButton(
      //           onPressed: () {
      //             Permission.locationWhenInUse.request();
      //             Navigator.pop(context);
      //             Timer? _timer;
      //             int _everySecondInRequestPermissionLoop = 0;
      //             _timer = Timer.periodic(Duration(seconds: 1), (_) async {
      //               if (_everySecondInRequestPermissionLoop < 2) {
      //                 print('duration is $_everySecondInRequestPermissionLoop');
      //                 _everySecondInRequestPermissionLoop++;
      //               } else {
      //                 print('came inside timer cancel loop1111');
      //                 setState(() {
      //                   locationPermissionAccepted = true;
      //                   // Permission.location.request();
      //                 });
      //                 // initBluetooth();
      //                 _timer?.cancel();
      //               }
      //             });
      //           },
      //           child: Text('Ok'))
      //     ],
      //   ),
      //   barrierDismissible: false,
      // );
    } else {
      setState(() {
        locationPermissionAccepted = true;
      });

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

  void serverUpdateOfBillVersionTwo() async {
    generalStatsMap.addAll({'totaldiscount': FieldValue.increment(discount)});
    generalStatsMap.addAll({
      'totalbillamounttoday': FieldValue.increment(totalBillWithTaxes().round())
    });

//IfBillHadAlreadyBeenPrintedSerialNumberNeedNotBeAdded
    generalStatsMap.addAll({'serialNumber': FieldValue.increment(1)});

    Map<String, dynamic> updatePrintOrdersMap = HashMap();
    updatePrintOrdersMap = printOrdersMap;
    updatePrintOrdersMap
        .addAll({'serialNumberForPrint': serialNumber.toString()});
    updatePrintOrdersMap.addAll({'serialNumberNum': serialNumber});
    updatePrintOrdersMap.addAll({
      'orderClosingCaptainPhone':
          Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .currentUserPhoneNumberFromClass
    });
    updatePrintOrdersMap.addAll({
      'orderClosingCaptainName': json.decode(
              Provider.of<PrinterAndOtherDetailsProvider>(context,
                      listen: false)
                  .allUserProfilesFromClass)[
          Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .currentUserPhoneNumberFromClass]['username']
    });

    if (itemsInOrderFromServerMap.isNotEmpty) {
      updatePrintOrdersMap
          .addAll({'billedItemsInOrder': itemsInOrderFromServerMap});
    }

    String addingZeroBeforeSerialNumber = '';
    for (int i = serialNumber.toString().length; i < 10; i++) {
      addingZeroBeforeSerialNumber += '0';
    }

    if (discount != 0) {
      if (discountValueClickedTruePercentageClickedFalse) {
        updatePrintOrdersMap.addAll({'981*Discount': discount.toString()});
      } else {
        updatePrintOrdersMap.addAll(
            {'981*Discount $discountEnteredValue%': discount.toString()});
      }
    }
    updatePrintOrdersMap
        .addAll({'985*Total': (totalPriceOfAllItems - discount).toString()});
    if (json.decode(
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .restaurantInfoDataFromClass)['cgst'] >
        0) {
      updatePrintOrdersMap.addAll({
        '989*CGST@${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['cgst']}%':
            (cgstCalculatedForBillFunction()).toString()
      });
    }
    if (json.decode(
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .restaurantInfoDataFromClass)['cgst'] >
        0) {
      updatePrintOrdersMap.addAll({
        '993*SGST@${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['cgst']}%':
            (sgstCalculatedForBillFunction()).toString()
      });
    }
    updatePrintOrdersMap.addAll({'995*Round Off': roundOff()});
    updatePrintOrdersMap.addAll({'roundOff': roundOff()});
    updatePrintOrdersMap
        .addAll({'997*Total Bill With Taxes': totalBillWithTaxesAsString()});
    String distinctItemsForPrint = '';
    String individualPriceOfEachDistinctItemForPrint = '';
    String numberOfEachDistinctItemForPrint = '';
    String priceOfEachDistinctItemWithoutTotalForPrint = '';
    //itIsWronglyAddingTotalAlsoToPriceOfEachDistinctItem.SoRemovingThatWithBelowVariable
    List<num> updatedPriceOfEachDistinctItemWithoutTotal =
        totalPriceOfOneDistinctItem;
    // updatedPriceOfEachDistinctItemWithoutTotal.removeLast();

    for (var distinctItem in distinctItemNames) {
      distinctItemsForPrint = distinctItemsForPrint + distinctItem;
      distinctItemsForPrint = distinctItemsForPrint + '*';
    }
    for (var individualPrice in individualPriceOfOneDistinctItem) {
      individualPriceOfEachDistinctItemForPrint =
          individualPriceOfEachDistinctItemForPrint +
              individualPrice.toString();
      individualPriceOfEachDistinctItemForPrint =
          individualPriceOfEachDistinctItemForPrint + '*';
    }
    for (var numberOfEachItem in numberOfOneDistinctItem) {
      numberOfEachDistinctItemForPrint =
          numberOfEachDistinctItemForPrint + numberOfEachItem.toString();
      numberOfEachDistinctItemForPrint = numberOfEachDistinctItemForPrint + '*';
    }
    for (var priceOfEachDistinctItem
        in updatedPriceOfEachDistinctItemWithoutTotal) {
      priceOfEachDistinctItemWithoutTotalForPrint =
          priceOfEachDistinctItemWithoutTotalForPrint +
              priceOfEachDistinctItem.toString();
      priceOfEachDistinctItemWithoutTotalForPrint =
          priceOfEachDistinctItemWithoutTotalForPrint + '*';
    }
    updatePrintOrdersMap.addAll({
      'hotelNameForPrint':
          '${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['hotelname']}'
    });
    updatePrintOrdersMap.addAll({
      'addressline1ForPrint':
          '${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['addressline1']}'
    });
    updatePrintOrdersMap.addAll({
      'addressline2ForPrint':
          '${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['addressline2']}'
    });
    updatePrintOrdersMap.addAll({
      'addressline3ForPrint':
          '${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['addressline3']}'
    });
    updatePrintOrdersMap.addAll({
      'gstcodeforprint':
          '${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['gstcode']}'
    });
    updatePrintOrdersMap.addAll({
      'phoneNumberForPrint':
          '${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['phonenumber']}'
    });
    updatePrintOrdersMap.addAll({'customerNameForPrint': '$customername'});
    updatePrintOrdersMap
        .addAll({'customerMobileForPrint': '${customermobileNumber}'});
    updatePrintOrdersMap
        .addAll({'customerAddressForPrint': '${customeraddressline1}'});
    updatePrintOrdersMap.addAll({'dateForPrint': '${printingDate}'});

    updatePrintOrdersMap
        .addAll({'totalNumberOfItemsForPrint': '${distinctItemNames.length}'});
    updatePrintOrdersMap.addAll({'billNumberForPrint': '${orderHistoryDocID}'});
    if (thisIsParcelTrueElseFalse) {
      updatePrintOrdersMap.addAll({
        'takeAwayOrDineInForPrint':
            'TYPE: TAKE-AWAY:${tableorparcel}:${tableorparcelnumber}${parentOrChild}'
      });
    } else {
      updatePrintOrdersMap.addAll({
        'takeAwayOrDineInForPrint':
            'TYPE: DINE-IN:${tableorparcel}:${tableorparcelnumber}${parentOrChild}'
      });
    }
    updatePrintOrdersMap
        .addAll({'distinctItemsForPrint': distinctItemsForPrint});
    updatePrintOrdersMap.addAll({
      'individualPriceOfEachDistinctItemForPrint':
          individualPriceOfEachDistinctItemForPrint
    });
    updatePrintOrdersMap.addAll(
        {'numberOfEachDistinctItemForPrint': numberOfEachDistinctItemForPrint});
    updatePrintOrdersMap.addAll({
      'priceOfEachDistinctItemWithoutTotalForPrint':
          priceOfEachDistinctItemWithoutTotalForPrint
    });
    updatePrintOrdersMap.addAll({'discount': discount.toString()});
    updatePrintOrdersMap
        .addAll({'discountEnteredValue': discountEnteredValue.toString()});
    updatePrintOrdersMap.addAll({
      'discountValueClickedTruePercentageClickedFalse':
          discountValueClickedTruePercentageClickedFalse.toString()
    });
    updatePrintOrdersMap
        .addAll({'totalQuantityForPrint': totalQuantityOfAllItems.toString()});
    updatePrintOrdersMap.addAll(
        {'subTotalForPrint': (totalPriceOfAllItems - discount).toString()});
    updatePrintOrdersMap.addAll({
      'cgstPercentageForPrint': json
          .decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .restaurantInfoDataFromClass)['cgst']
          .toString()
    });
    updatePrintOrdersMap.addAll(
        {'cgstCalculatedForPrint': cgstCalculatedForBillFunction().toString()});
    updatePrintOrdersMap.addAll({
      'sgstPercentageForPrint': json
          .decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .restaurantInfoDataFromClass)['cgst']
          .toString()
    });
    updatePrintOrdersMap.addAll(
        {'sgstCalculatedForPrint': sgstCalculatedForBillFunction().toString()});
    updatePrintOrdersMap
        .addAll({'grandTotalForPrint': totalBillWithTaxesAsString()});

    Map<String, dynamic> subMasterSalesIncomeStatistics = HashMap();
    subMasterSalesIncomeStatistics.addAll({
      'arraySoldItemsCategoryArray':
          FieldValue.arrayUnion(arraySoldItemsCategoryArray)
    });
    subMasterSalesIncomeStatistics.addAll({
      'mapEachCaptainOrdersTakenStatsMap': mapEachCaptainOrdersTakenStatsMap
    });
    subMasterSalesIncomeStatistics
        .addAll({'mapGeneralStatsMap': generalStatsMap});
    subMasterSalesIncomeStatistics
        .addAll({'menuIndividualItemsStatsMap': menuIndividualItemsStatsMap});
    subMasterSalesIncomeStatistics.addAll(
        {'mapExtraIndividualItemsStatsMap': extraIndividualItemsStatsMap});

    Map<String, dynamic> statisticsDailyStatisticsMap = {
      'day': num.parse(statisticsDay),
      'month': num.parse(statisticsMonth),
      'year': num.parse(statisticsYear),
      'statisticsDocumentIdMap': {orderHistoryDocID: FieldValue.delete()}
    };
    Map<String, dynamic> statisticsMonthlyStatisticsMap = {
      'month': num.parse(statisticsMonth),
      'year': num.parse(statisticsYear),
      'midMonthMilliSecond':
          DateTime(int.parse(statisticsYear), int.parse(statisticsMonth), 15)
              .millisecondsSinceEpoch,
      'cashBalanceData': {
        statisticsDay: {
          'dayIncrements': FieldValue.increment(dayIncrementWhileIterating),
          'previousCashBalance':
              FieldValue.increment(previousCashBalanceWhileIterating)
        }
      }
    };
    if (subMasterBilledCancellationStats.isNotEmpty) {
      statisticsDailyStatisticsMap.addAll(
          {'billedCancellationStats': subMasterBilledCancellationStats});
      statisticsMonthlyStatisticsMap.addAll(
          {'billedCancellationStats': subMasterBilledCancellationStats});
    }

    statisticsDailyStatisticsMap
        .addAll({'salesIncomeStats': subMasterSalesIncomeStatistics});
    statisticsMonthlyStatisticsMap
        .addAll({'salesIncomeStats': subMasterSalesIncomeStatistics});

    if (billUpdatedInServer == false) {
      billUpdatedInServer = true;
      FireStoreBillAndStatisticsInServerVersionTwo(
              hotelName: widget.hotelName,
              printOrdersMap: updatePrintOrdersMap,
              orderHistoryDocID: orderHistoryDocID,
              dailyStatisticsUpdateMap: statisticsDailyStatisticsMap,
              monthlyStatisticsUpdateMap: statisticsMonthlyStatisticsMap,
              entireCashBalanceChangeSheet: entireCashBalanceChangeSheet,
              year: statisticsYear,
              month: statisticsMonth,
              day: statisticsDay)
          .updateBillAndStatistics();

      orderHistoryDocID = '';
      updatePrintOrdersMap = {};
      statisticsMap = {};
      statisticsDocID = '';
      serialNumber = 0;
      toCheckPastOrderHistoryMap = {};

      FireStoreDeleteFinishedOrderInRunningOrders(
              hotelName: widget.hotelName,
              eachTableId: widget.itemsFromThisDocumentInFirebaseDoc)
          .deleteFinishedOrder();

//ToUpdateStatistics,WeGoThroughEachKeyAndUsingIncrementByFunction,We,,
//CanIncrementTheNumberThatIsAlreadyThereInTheServer
//ThisWillHelpToAddToTheStatisticsThat'sAlreadyThere
      int counterToDeleteTableOrParcelOrderFromFireStore = 1;
      // statisticsMap.forEach((key, value) {
      //   counterToDeleteTableOrParcelOrderFromFireStore++;
      //   double? incrementBy = statisticsMap[key]?.toDouble();
      //   FireStoreUpdateStatistics(
      //       hotelName: widget.hotelName,
      //       docID: statisticsDocID,
      //       incrementBy: incrementBy,
      //       key: key)
      //       .updateStatistics();
      //   if (counterToDeleteTableOrParcelOrderFromFireStore ==
      //       statisticsMap.length) {
      //     FireStoreDeleteFinishedOrderInPresentOrders(
      //         hotelName: widget.hotelName,
      //         eachItemId: widget.itemsFromThisDocumentInFirebaseDoc)
      //         .deleteFinishedOrder();
      //   }
      // });
      //ThenFinallyWeGoThroughEachItemIdAndDeleteItOutOfCurrentOrders
      // for (String eachItemId in widget.itemsID) {
      //   FireStoreDeleteFinishedOrder(
      //           hotelName: widget.hotelName, eachItemId: eachItemId)
      //       .deleteFinishedOrder();
      // }

    }
    screenPopOutTimerAfterServerUpdate();

    // int count = 0;
    // Navigator.of(context).popUntil((_) => count++ >= 2);
  }

  void serverUpdateOfBill() async {
    generalStatsMap.addAll({'totaldiscount': FieldValue.increment(discount)});
    statisticsMap.addAll({'totaldiscount': FieldValue.increment(discount)});
    generalStatsMap.addAll({
      'totalbillamounttoday': FieldValue.increment(totalBillWithTaxes().round())
    });
    statisticsMap.addAll({
      'totalbillamounttoday': FieldValue.increment(totalBillWithTaxes().round())
    });

//IfBillHadAlreadyBeenPrintedSerialNumberNeedNotBeAdded
    generalStatsMap.addAll({'serialNumber': FieldValue.increment(1)});
    statisticsMap.addAll({'serialNumber': FieldValue.increment(1)});
    statisticsMap.addAll({
      'statisticsDocumentIdMap': {orderHistoryDocID: FieldValue.delete()}
    });

    //  print(widget.printOrdersMap);
    Map<String, dynamic> updatePrintOrdersMap = HashMap();

    updatePrintOrdersMap = printOrdersMap;
    updatePrintOrdersMap
        .addAll({'serialNumberForPrint': serialNumber.toString()});
    printOrdersMap.addAll(
        {'serialNumberNum': num.parse(baseInfoFromServerMap['serialNumber'])});
    printOrdersMap.addAll({
      'orderClosingCaptainPhone':
          Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .currentUserPhoneNumberFromClass
    });
    printOrdersMap.addAll({
      'orderClosingCaptainName': json.decode(
              Provider.of<PrinterAndOtherDetailsProvider>(context,
                      listen: false)
                  .allUserProfilesFromClass)[
          Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .currentUserPhoneNumberFromClass]['username']
    });
    if (cancelledItemsInOrderFromServerMap.isNotEmpty) {
      printOrdersMap.addAll(cancelledItemsInOrderFromServerMap);
    }

    String addingZeroBeforeSerialNumber = '';
    for (int i = serialNumber.toString().length; i < 10; i++) {
      addingZeroBeforeSerialNumber += '0';
    }
    String dateOfOrderWithSerial =
        updatePrintOrdersMap[' Date of Order  :'].toString() +
            ' ' +
            addingZeroBeforeSerialNumber +
            serialNumber.toString() +
            ' as serial number';
    updatePrintOrdersMap[' Date of Order  :'] = dateOfOrderWithSerial;

    if (discount != 0) {
      if (discountValueClickedTruePercentageClickedFalse) {
        updatePrintOrdersMap.addAll({'981*Discount': discount.toString()});
      } else {
        updatePrintOrdersMap.addAll(
            {'981*Discount $discountEnteredValue%': discount.toString()});
      }
    }
    updatePrintOrdersMap
        .addAll({'985*Total': (totalPriceOfAllItems - discount).toString()});
    if (json.decode(
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .restaurantInfoDataFromClass)['cgst'] >
        0) {
      updatePrintOrdersMap.addAll({
        '989*CGST@${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['cgst']}%':
            (cgstCalculatedForBillFunction()).toString()
      });
    }
    if (json.decode(
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .restaurantInfoDataFromClass)['cgst'] >
        0) {
      updatePrintOrdersMap.addAll({
        '993*SGST@${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['cgst']}%':
            (sgstCalculatedForBillFunction()).toString()
      });
    }
    updatePrintOrdersMap.addAll({'995*Round Off': roundOff()});
    updatePrintOrdersMap.addAll({'roundOff': roundOff()});
    updatePrintOrdersMap
        .addAll({'997*Total Bill With Taxes': totalBillWithTaxesAsString()});
    String distinctItemsForPrint = '';
    String individualPriceOfEachDistinctItemForPrint = '';
    String numberOfEachDistinctItemForPrint = '';
    String priceOfEachDistinctItemWithoutTotalForPrint = '';
    //itIsWronglyAddingTotalAlsoToPriceOfEachDistinctItem.SoRemovingThatWithBelowVariable
    List<num> updatedPriceOfEachDistinctItemWithoutTotal =
        totalPriceOfOneDistinctItem;
    // updatedPriceOfEachDistinctItemWithoutTotal.removeLast();

    for (var distinctItem in distinctItemNames) {
      distinctItemsForPrint = distinctItemsForPrint + distinctItem;
      distinctItemsForPrint = distinctItemsForPrint + '*';
    }
    for (var individualPrice in individualPriceOfOneDistinctItem) {
      individualPriceOfEachDistinctItemForPrint =
          individualPriceOfEachDistinctItemForPrint +
              individualPrice.toString();
      individualPriceOfEachDistinctItemForPrint =
          individualPriceOfEachDistinctItemForPrint + '*';
    }
    for (var numberOfEachItem in numberOfOneDistinctItem) {
      numberOfEachDistinctItemForPrint =
          numberOfEachDistinctItemForPrint + numberOfEachItem.toString();
      numberOfEachDistinctItemForPrint = numberOfEachDistinctItemForPrint + '*';
    }
    for (var priceOfEachDistinctItem
        in updatedPriceOfEachDistinctItemWithoutTotal) {
      priceOfEachDistinctItemWithoutTotalForPrint =
          priceOfEachDistinctItemWithoutTotalForPrint +
              priceOfEachDistinctItem.toString();
      priceOfEachDistinctItemWithoutTotalForPrint =
          priceOfEachDistinctItemWithoutTotalForPrint + '*';
    }
    updatePrintOrdersMap.addAll({
      'hotelNameForPrint':
          '${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['hotelname']}'
    });
    updatePrintOrdersMap.addAll({
      'addressline1ForPrint':
          '${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['addressline1']}'
    });
    updatePrintOrdersMap.addAll({
      'addressline2ForPrint':
          '${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['addressline2']}'
    });
    updatePrintOrdersMap.addAll({
      'addressline3ForPrint':
          '${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['addressline3']}'
    });
    updatePrintOrdersMap.addAll({
      'gstcodeforprint':
          '${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['gstcode']}'
    });
    updatePrintOrdersMap.addAll({
      'phoneNumberForPrint':
          '${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['phonenumber']}'
    });
    updatePrintOrdersMap.addAll({'customerNameForPrint': '$customername'});
    updatePrintOrdersMap
        .addAll({'customerMobileForPrint': '${customermobileNumber}'});
    updatePrintOrdersMap
        .addAll({'customerAddressForPrint': '${customeraddressline1}'});
    updatePrintOrdersMap.addAll({'dateForPrint': '${printingDate}'});

    updatePrintOrdersMap
        .addAll({'totalNumberOfItemsForPrint': '${distinctItemNames.length}'});
    updatePrintOrdersMap.addAll({'billNumberForPrint': '${orderHistoryDocID}'});
    if (thisIsParcelTrueElseFalse) {
      updatePrintOrdersMap.addAll({
        'takeAwayOrDineInForPrint':
            'TYPE: TAKE-AWAY:${tableorparcel}:${tableorparcelnumber}${parentOrChild}'
      });
    } else {
      updatePrintOrdersMap.addAll({
        'takeAwayOrDineInForPrint':
            'TYPE: DINE-IN:${tableorparcel}:${tableorparcelnumber}${parentOrChild}'
      });
    }
    updatePrintOrdersMap
        .addAll({'distinctItemsForPrint': distinctItemsForPrint});
    updatePrintOrdersMap.addAll({
      'individualPriceOfEachDistinctItemForPrint':
          individualPriceOfEachDistinctItemForPrint
    });
    updatePrintOrdersMap.addAll(
        {'numberOfEachDistinctItemForPrint': numberOfEachDistinctItemForPrint});
    updatePrintOrdersMap.addAll({
      'priceOfEachDistinctItemWithoutTotalForPrint':
          priceOfEachDistinctItemWithoutTotalForPrint
    });
    updatePrintOrdersMap.addAll({'discount': discount.toString()});
    updatePrintOrdersMap
        .addAll({'discountEnteredValue': discountEnteredValue.toString()});
    updatePrintOrdersMap.addAll({
      'discountValueClickedTruePercentageClickedFalse':
          discountValueClickedTruePercentageClickedFalse.toString()
    });

    updatePrintOrdersMap
        .addAll({'totalQuantityForPrint': totalQuantityOfAllItems.toString()});

    updatePrintOrdersMap.addAll(
        {'subTotalForPrint': (totalPriceOfAllItems - discount).toString()});
    updatePrintOrdersMap.addAll({
      'cgstPercentageForPrint': json
          .decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .restaurantInfoDataFromClass)['cgst']
          .toString()
    });
    updatePrintOrdersMap.addAll(
        {'cgstCalculatedForPrint': cgstCalculatedForBillFunction().toString()});
    updatePrintOrdersMap.addAll({
      'sgstPercentageForPrint': json
          .decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .restaurantInfoDataFromClass)['cgst']
          .toString()
    });
    updatePrintOrdersMap.addAll(
        {'sgstCalculatedForPrint': sgstCalculatedForBillFunction().toString()});
    updatePrintOrdersMap
        .addAll({'grandTotalForPrint': totalBillWithTaxesAsString()});
    if (billUpdatedInServer == false) {
      billUpdatedInServer = true;
      // FireStoreBillAndStatisticsInServer(
      //         hotelName: widget.hotelName,
      //         orderHistoryDocID: orderHistoryDocID,
      //         printOrdersMap: updatePrintOrdersMap,
      //         statisticsDayUpdateMap: dailyStatisticsMap,
      //         year: billYear,
      //         month: billMonth,
      //         day: billDay)
      //     .updateBillAndStatistics();

      // FireStoreUpdateAndStatisticsWithBatch(
      //         hotelName: widget.hotelName,
      //         orderHistoryDocID: orderHistoryDocID,
      //         printOrdersMap: updatePrintOrdersMap,
      //         statisticsDocID: statisticsDocID,
      //         statisticsUpdateMap: statisticsMap)
      //     .updateBillAndStatistics();

      orderHistoryDocID = '';
      updatePrintOrdersMap = {};
      statisticsMap = {};
      statisticsDocID = '';
      serialNumber = 0;
      toCheckPastOrderHistoryMap = {};

      FireStoreDeleteFinishedOrderInRunningOrders(
              hotelName: widget.hotelName,
              eachTableId: widget.itemsFromThisDocumentInFirebaseDoc)
          .deleteFinishedOrder();

//ToUpdateStatistics,WeGoThroughEachKeyAndUsingIncrementByFunction,We,,
//CanIncrementTheNumberThatIsAlreadyThereInTheServer
//ThisWillHelpToAddToTheStatisticsThat'sAlreadyThere
      int counterToDeleteTableOrParcelOrderFromFireStore = 1;
      // statisticsMap.forEach((key, value) {
      //   counterToDeleteTableOrParcelOrderFromFireStore++;
      //   double? incrementBy = statisticsMap[key]?.toDouble();
      //   FireStoreUpdateStatistics(
      //       hotelName: widget.hotelName,
      //       docID: statisticsDocID,
      //       incrementBy: incrementBy,
      //       key: key)
      //       .updateStatistics();
      //   if (counterToDeleteTableOrParcelOrderFromFireStore ==
      //       statisticsMap.length) {
      //     FireStoreDeleteFinishedOrderInPresentOrders(
      //         hotelName: widget.hotelName,
      //         eachItemId: widget.itemsFromThisDocumentInFirebaseDoc)
      //         .deleteFinishedOrder();
      //   }
      // });
      //ThenFinallyWeGoThroughEachItemIdAndDeleteItOutOfCurrentOrders
      // for (String eachItemId in widget.itemsID) {
      //   FireStoreDeleteFinishedOrder(
      //           hotelName: widget.hotelName, eachItemId: eachItemId)
      //       .deleteFinishedOrder();
      // }

    }
    screenPopOutTimerAfterServerUpdate();

    // int count = 0;
    // Navigator.of(context).popUntil((_) => count++ >= 2);
  }

  void serialNumberUpdateInServerWhenPrintClickedFirstTime() {
    Map<String, dynamic> tempBaseInfoMap = HashMap();
    tempBaseInfoMap.addAll({'serialNumber': serialNumber.toString()});
    tempBaseInfoMap.addAll({'billDay': billDay.toString()});
    tempBaseInfoMap.addAll({'billHour': billHour.toString()});
    tempBaseInfoMap.addAll({'billMinute': billMinute.toString()});
    tempBaseInfoMap.addAll({'billMonth': billMonth.toString()});
    tempBaseInfoMap.addAll({'billSecond': billSecond.toString()});
    tempBaseInfoMap.addAll({'billYear': billYear.toString()});

    Map<String, dynamic> tempMasterMap = HashMap();
    tempMasterMap.addAll({'baseInfoMap': tempBaseInfoMap});

    FireStoreAddOrderInRunningOrderFolder(
            hotelName: widget.hotelName,
            seatingNumber: widget.itemsFromThisDocumentInFirebaseDoc,
            ordersMap: tempMasterMap)
        .addOrder();
  }

  void screenPopOutTimerAfterServerUpdate() {
    Timer? _timerToQuitScreen;
    _timerToQuitScreen = Timer(Duration(milliseconds: 500), () {
      if (parentOrChild == '') {
//PoppingTillCaptainScreen
//                         Navigator.pop(context);
        int count = 0;
        Navigator.of(context).popUntil((_) => count++ >= 2);
      } else {
        //PoppingTillCaptainScreen,ExtraOneScreenToPopIfNotParent
        int count = 0;
        Navigator.of(context).popUntil((_) => count++ >= 3);
      }
    });
  }

  void timerForClosingTableAfterDataReady() {
    Timer(Duration(milliseconds: 500), () {
      closingCheckCounter++;
      if (closingCheckCounter <= 14) {
        if (orderHistoryChecked == 'closeBill' &&
            gotCashIncrementData &&
            gotSerialNumber) {
          billUpdateTried = true;
          serverUpdateOfBillVersionTwo();
        } else {
          timerForClosingTableAfterDataReady();
        }
      } else {
        billUpdateTried = false;
        paymentDoneBillClosureDataNotReceived();
      }
    });
  }

  void paymentDoneBillClosureDataNotReceived() {
//ThisMeansThatWeHaveClickedPaymentDoneButTheDataFor
//BillClosureOnWhoClosedTheMapYetToBeReceivedBecauseOfPoorNet
//WeNeedStopThePaymentDoneIn5Seconds
    if (serialNumber == 0) {
      // ThisMeansThatTheDataHasNotReachedTheServer
      Map<String, dynamic> tempSerialInStatisticsMap = HashMap();
      tempSerialInStatisticsMap.addAll({
        orderHistoryDocID: {
          Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .currentUserPhoneNumberFromClass: FieldValue.delete()
        }
      });
      FirebaseFirestore.instance
          .collection(widget.hotelName)
          .doc('reports')
          .collection('dailyReports')
          .doc(statisticsYear)
          .collection(statisticsMonth)
          .doc(statisticsDay)
          .set({'statisticsDocumentIdMap': tempSerialInStatisticsMap},
              SetOptions(merge: true));
    }
    clearingCurrentUserBillingTime();
    setState(() {
      paymentDoneClicked = false;
      gotCashIncrementData = false;
    });
    Timer(Duration(seconds: 2), () {
      paymentClosingBottomBar(false);
    });
  }

//ThisIsTheBottomBarWeUseOnceThePaymentIsClicked
  void paymentClosingBottomBar(
      bool newlyCallingPaymentClosingMapTrueElseFalse) {
    if (newlyCallingPaymentClosingMapTrueElseFalse) {
      bottomBarPaymentClosingMap = {};
//ThisWillOnlyBeNeededIfMoreThanOnePaymentMethodIsNeededToCloseTheBill
      paymentSorterList = [];
//PaymentClosingMapKeysAreTheTimeInWhichThePaymentWasStarted
//ThisWillHelpToArrangeInBottomBarEveryTimeSplitPaymentIsClicked
      bottomBarPaymentClosingMap.addAll({
        DateTime.now().millisecondsSinceEpoch: {
//HereItWillBeChoosePaymentBecauseThatIsTheFirstValue
          'chosenPaymentMethod': paymentMethod.first,
          'amountSentInThisPaymentMethod': totalBillWithTaxes().round(),
          'addedPaymentMethod': '',
          'amountSentInThisPaymentMethodInString':
              totalBillWithTaxes().round().toString()
        }
      });
    }

    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext buildContext) {
          return StatefulBuilder(builder: (context, setStateSB) {
            return ModalProgressHUD(
              inAsyncCall: showSpinner,
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: bottomBarPaymentClosingMap.entries.map((entry) {
                      final paymentMethodTime = entry.key;
                      final Map<String, dynamic> paymentMethodValueMap =
                          entry.value;
                      String tempNewPaymentMethod = '';
                      String tempPaymentAmountInMethodAsString =
                          bottomBarPaymentClosingMap[paymentMethodTime]
                              ['amountSentInThisPaymentMethodInString'];
                      TextEditingController paymentAmountInMethodController =
                          TextEditingController(
                              text: tempPaymentAmountInMethodAsString);
                      paymentAmountInMethodController.selection =
                          TextSelection.collapsed(
                              offset: tempPaymentAmountInMethodAsString.length);

                      return Column(
                        children: [
                          SizedBox(height: 10),
                          Visibility(
                              visible:
                                  paymentSorterList.length > 1 ? true : false,
                              child: Text(
                                'Payment Method ${paymentSorterList.indexOf(paymentMethodTime) + 1}',
                                style: TextStyle(fontSize: 15),
                              )),
                          SizedBox(height: 10),
                          ListTile(
                            leading:
                                Text('Method', style: TextStyle(fontSize: 20)),
                            title: Container(
                              decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(30)),
                              width: 200,
                              height: 50,
                              // height: 200,
                              child: Center(
                                child: DropdownButtonFormField(
                                  decoration:
                                      InputDecoration.collapsed(hintText: ''),
                                  isExpanded: true,
                                  // underline: Container(),
                                  dropdownColor: Colors.green,
                                  value: paymentMethodValueMap[
                                      'chosenPaymentMethod'],
                                  onChanged: (value) {
                                    setStateSB(() {
                                      bottomBarPaymentClosingMap[
                                                  paymentMethodTime]
                                              ['chosenPaymentMethod'] =
                                          value.toString();
                                      if (value.toString() != 'New') {
                                        bottomBarPaymentClosingMap[
                                                paymentMethodTime]
                                            ['addedPaymentMethod'] = '';
                                        tempNewPaymentMethod = '';
                                      }
                                    });
                                  },
                                  items: paymentMethod.map((title) {
//DropDownMenuItemWillHaveOneByOneItems,WePutThatAsList
//ValueWillBeEachTitle
                                    return DropdownMenuItem(
                                      alignment: Alignment.center,
                                      child: Text(title,
                                          style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.white)),
                                      value: title,
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Visibility(
                            visible:
                                bottomBarPaymentClosingMap[paymentMethodTime]
                                            ['chosenPaymentMethod'] ==
                                        'New'
                                    ? true
                                    : false,
                            child: ListTile(
                              leading: Text('Method\nName',
                                  style: TextStyle(fontSize: 20)),
                              title: Container(
                                child: TextField(
                                  maxLength: 40,
                                  onChanged: (value) {
                                    tempNewPaymentMethod = value;
                                    setStateSB(() {
                                      bottomBarPaymentClosingMap[
                                                  paymentMethodTime]
                                              ['addedPaymentMethod'] =
                                          tempNewPaymentMethod;
                                    });
                                  },
                                  decoration:
                                      // kTextFieldInputDecoration,
                                      InputDecoration(
                                          filled: true,
                                          fillColor: Colors.white,
                                          hintText: 'Enter New Payment Method',
                                          hintStyle:
                                              TextStyle(color: Colors.grey),
                                          enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(10)),
                                              borderSide: BorderSide(
                                                  color: Colors.green)),
                                          focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(10)),
                                              borderSide: BorderSide(
                                                  color: Colors.green))),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          ListTile(
                            leading:
                                Text('Amount', style: TextStyle(fontSize: 20)),
                            title: Container(
                              child: TextField(
                                maxLength: 10,
                                controller: paymentAmountInMethodController,
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                onChanged: (value) {
                                  tempPaymentAmountInMethodAsString = value;
                                  bottomBarPaymentClosingMap[paymentMethodTime][
                                          'amountSentInThisPaymentMethodInString'] =
                                      tempPaymentAmountInMethodAsString;
                                },
                                decoration:
                                    // kTextFieldInputDecoration,
                                    InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        hintText: 'Enter Amount',
                                        hintStyle:
                                            TextStyle(color: Colors.grey),
                                        enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(10)),
                                            borderSide: BorderSide(
                                                color: Colors.green)),
                                        focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(10)),
                                            borderSide: BorderSide(
                                                color: Colors.green))),
                              ),
                            ),
                          ),
                          SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: paymentSorterList.length > 1
                                ? MainAxisAlignment.spaceEvenly
                                : MainAxisAlignment.center,
                            children: [
                              Visibility(
//WeWillHaveAccessToDeleteButtonOnlyIfMoreThanOnePaymentMethodIsThere
                                visible:
                                    paymentSorterList.length > 1 ? true : false,
                                child: ElevatedButton(
                                    style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all<Color>(
                                              Colors.red),
                                    ),
                                    onPressed: () {
//ToRemoveThePaymentMethodFromTheMap
                                      setStateSB(() {
                                        bottomBarPaymentClosingMap
                                            .remove(paymentMethodTime);
                                        paymentSorterList
                                            .remove(paymentMethodTime);
                                      });
                                    },
                                    child: Text('Delete')),
                              ),
                              ElevatedButton(
                                  style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                            Colors.green),
                                  ),
                                  onPressed: () {
//ThisIsToEnsureTheKeyboardCloses

                                    if (bottomBarPaymentClosingMap[
                                                paymentMethodTime]
                                            ['chosenPaymentMethod'] ==
                                        'Choose') {
                                      errorMessage =
                                          'Please Choose Payment Method';
                                      errorAlertDialogBox();
                                    } else if ((bottomBarPaymentClosingMap[
                                                    paymentMethodTime]
                                                ['chosenPaymentMethod'] ==
                                            'New') &&
                                        (bottomBarPaymentClosingMap[
                                                    paymentMethodTime]
                                                ['addedPaymentMethod'] ==
                                            '')) {
                                      errorMessage =
                                          'Please Enter The New Payment Method';
                                      errorAlertDialogBox();
                                    } else if ((bottomBarPaymentClosingMap[
                                                    paymentMethodTime][
                                                'amountSentInThisPaymentMethodInString'] ==
                                            '') ||
                                        (bottomBarPaymentClosingMap[
                                                    paymentMethodTime][
                                                'amountSentInThisPaymentMethodInString'] ==
                                            '0')) {
                                      errorMessage =
                                          'Please Enter The Amount for this Payment Method';
                                      errorAlertDialogBox();
                                    } else {
//WeNeedToCheckWhetherPaymentValueIsHigherThanTotalValue
                                      num totalAmountFromAllPaymentMethods = 0;
//ThisWillCalculateAllThePaymentsThatHasBeenEnteredTillNow
                                      bottomBarPaymentClosingMap
                                          .forEach((key, value) {
                                        totalAmountFromAllPaymentMethods +=
                                            num.parse(value[
                                                'amountSentInThisPaymentMethodInString']);
                                      });
                                      if (totalAmountFromAllPaymentMethods >
                                          totalBillWithTaxes().round()) {
                                        errorMessage =
                                            'Entered Amounts Higher than Bill. Please Check';
                                        errorAlertDialogBox();
                                      } else if (totalAmountFromAllPaymentMethods ==
                                          totalBillWithTaxes().round()) {
                                        errorMessage =
                                            'Entered Amounts Equal to Final Bill. Can\'t Split More';
                                        errorAlertDialogBox();
                                      } else {
//WeNeedToAddToThePaymentMethodListSoThatItComesInOrder
                                        if (!paymentSorterList
                                            .contains(paymentMethodTime)) {
//ThisWillEnsureWeWillOnlyAddInOrder
                                          paymentSorterList
                                              .add(paymentMethodTime);
                                        }
                                        int tempNextPaymentMethodTime =
                                            DateTime.now()
                                                .millisecondsSinceEpoch;
                                        paymentSorterList
                                            .add(tempNextPaymentMethodTime);
                                        bottomBarPaymentClosingMap.addAll({
                                          tempNextPaymentMethodTime: {
//HereItWillBeChoosePaymentBecauseThatIsTheFirstValue
                                            'chosenPaymentMethod':
                                                paymentMethod.first,
                                            'amountSentInThisPaymentMethod':
                                                (totalBillWithTaxes().round() -
                                                    totalAmountFromAllPaymentMethods),
                                            'addedPaymentMethod': '',
                                            'amountSentInThisPaymentMethodInString':
                                                (totalBillWithTaxes().round() -
                                                        totalAmountFromAllPaymentMethods)
                                                    .toString()
                                          }
                                        });
                                        setStateSB(() {});
                                      }
                                    }
                                  },
                                  child: Text('Split'))
                            ],
                          ),
                          Divider(thickness: 2),
                          ((paymentSorterList.isNotEmpty &&
                                      paymentSorterList.last ==
                                          paymentMethodTime) ||
                                  paymentSorterList.isEmpty)
                              ? Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: BottomButton(
                                            onTap: () {
                                              Navigator.pop(context);
                                            },
                                            buttonTitle: 'Cancel',
                                            buttonColor: Colors.orangeAccent),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: BottomButton(
                                            onTap: () async {
                                              bool hasInternet =
                                                  await InternetConnectionChecker()
                                                      .hasConnection;
                                              if (hasInternet) {
                                                bool paymentMethodNotChosen =
                                                    false;
                                                bool
                                                    paymentMethodValueNotGiven =
                                                    false;
                                                num totalAmountFromAllPaymentMethods =
                                                    0;
                                                bottomBarPaymentClosingMap
                                                    .forEach((key, value) {
                                                  if (value[
                                                          'chosenPaymentMethod'] ==
                                                      paymentMethod.first) {
//thisMeansTheyHaven'tChosenPaymentMethodSomewhere
                                                    paymentMethodNotChosen =
                                                        true;
                                                  }
                                                  if (value['amountSentInThisPaymentMethodInString'] ==
                                                          '0' ||
                                                      value['amountSentInThisPaymentMethodInString'] ==
                                                          '') {
                                                    paymentMethodValueNotGiven =
                                                        true;
                                                  } else {
                                                    totalAmountFromAllPaymentMethods +=
                                                        num.parse(value[
                                                            'amountSentInThisPaymentMethodInString']);
                                                  }
                                                });
                                                if (paymentMethodNotChosen) {
                                                  errorMessage =
                                                      'Please Choose Payment Method';
                                                  errorAlertDialogBox();
                                                } else if (paymentMethodValueNotGiven) {
                                                  errorMessage =
                                                      'Please Enter Value for all Payment Methods';
                                                  errorAlertDialogBox();
                                                } else if (totalAmountFromAllPaymentMethods !=
                                                    totalBillWithTaxes()
                                                        .round()) {
                                                  errorMessage =
                                                      'Payment Value and Bill Not Matching';
                                                  errorAlertDialogBox();
                                                } else {
//ThisMeansThereAreNoErrors
                                                  documentStatisticsRegistryDateMaker();
                                                  finalNewPaymentMethod = [];
                                                  finalPaymentClosingMap = {};
                                                  finalCashierClosingMap = {};
                                                  paymentMethodsInThisPeriod =
                                                      [];
                                                  gotCashIncrementData = false;

                                                  Map<String, dynamic>
                                                      tempFinalPaymentClosingMap =
                                                      HashMap();
                                                  valueToIncrementInCashInCashBalance =
                                                      0;
                                                  bottomBarPaymentClosingMap
                                                      .forEach((key, value) {
                                                    if (value[
                                                            'chosenPaymentMethod'] ==
                                                        'Cash Payment') {
                                                      valueToIncrementInCashInCashBalance +=
                                                          num.parse(value[
                                                              'amountSentInThisPaymentMethodInString']);
                                                    }
                                                    if (value[
                                                            'chosenPaymentMethod'] !=
                                                        'New') {
                                                      if (tempFinalPaymentClosingMap
                                                          .containsKey(value[
                                                              'chosenPaymentMethod'])) {
//ThisMeansTwoPeopleFromSameGroupPaidViaSamePaymentMethodButSeparately
                                                        tempFinalPaymentClosingMap[
                                                            value[
                                                                'chosenPaymentMethod']] = {
                                                          'totalAmount': tempFinalPaymentClosingMap[
                                                                      value[
                                                                          'chosenPaymentMethod']]
                                                                  [
                                                                  'totalAmount'] +
                                                              num.parse(value[
                                                                  'amountSentInThisPaymentMethodInString']),
                                                          'numberOfTimes':
                                                              tempFinalPaymentClosingMap[
                                                                          value[
                                                                              'chosenPaymentMethod']]
                                                                      [
                                                                      'numberOfTimes'] +
                                                                  1
                                                        };
                                                      } else {
                                                        paymentMethodsInThisPeriod
                                                            .add(value[
                                                                'chosenPaymentMethod']);
                                                        tempFinalPaymentClosingMap
                                                            .addAll({
                                                          value['chosenPaymentMethod']:
                                                              {
                                                            'totalAmount':
                                                                num.parse(value[
                                                                    'amountSentInThisPaymentMethodInString']),
                                                            'numberOfTimes': 1
                                                          }
                                                        });
                                                      }
                                                    } else {
                                                      if (!finalNewPaymentMethod
                                                              .contains(value[
                                                                  'addedPaymentMethod']) &&
                                                          !paymentMethod
                                                              .contains(value[
                                                                  'addedPaymentMethod'])) {
//OnlyIfItIsAbsolutelyNewPaymentMethod,ItWillBeAdded
                                                        finalNewPaymentMethod
                                                            .add(value[
                                                                'addedPaymentMethod']);
                                                      }
                                                      if (tempFinalPaymentClosingMap
                                                          .containsKey(value[
                                                              'addedPaymentMethod'])) {
//ThisMeansTwoPeopleFromSameGroupPaidViaSamePaymentMethodButSeparately
                                                        tempFinalPaymentClosingMap[
                                                            value[
                                                                'addedPaymentMethod']] = {
                                                          'totalAmount': tempFinalPaymentClosingMap[
                                                                      value[
                                                                          'addedPaymentMethod']]
                                                                  [
                                                                  'totalAmount'] +
                                                              num.parse(value[
                                                                  'amountSentInThisPaymentMethodInString']),
                                                          'numberOfTimes':
                                                              tempFinalPaymentClosingMap[
                                                                          value[
                                                                              'addedPaymentMethod']]
                                                                      [
                                                                      'numberOfTimes'] +
                                                                  1
                                                        };
                                                      } else {
                                                        tempFinalPaymentClosingMap
                                                            .addAll({
                                                          value['addedPaymentMethod']:
                                                              {
                                                            'totalAmount':
                                                                num.parse(value[
                                                                    'amountSentInThisPaymentMethodInString']),
                                                            'numberOfTimes': 1
                                                          }
                                                        });
                                                      }
                                                    }
                                                  });
                                                  currentGeneratedIncrementRandomNumber =
                                                      (1000000 +
                                                          Random().nextInt(
                                                              9999999 -
                                                                  1000000));
                                                  thisMonthStatisticsStreamToCheckInternet();
                                                  cashBalanceWithQueriedMonthToLatestDataCheck(
                                                      DateTime(
                                                          int.parse(
                                                              statisticsYear),
                                                          int.parse(
                                                              statisticsMonth),
                                                          int.parse(
                                                              statisticsDay)),
                                                      currentGeneratedIncrementRandomNumber);
                                                  if (finalNewPaymentMethod
                                                      .isNotEmpty) {
//ToAddNewPaymentMethodInServer
                                                    addingNewPaymentMethod();
                                                  }
                                                  tempFinalPaymentClosingMap
                                                      .forEach((key, value) {
                                                    finalPaymentClosingMap
                                                        .addAll({
                                                      key: {
                                                        'totalAmountInThisPaymentMethod':
                                                            FieldValue.increment(
                                                                value[
                                                                    'totalAmount']),
                                                        'numberOfTimesInThisPaymentMethod':
                                                            FieldValue.increment(
                                                                value[
                                                                    'numberOfTimes'])
                                                      }
                                                    });
                                                  });
//ThisIsFinalClosingMapForCashierAddingThePaymentMethodsForThisCashier
                                                  Map<String, dynamic>
                                                      tempFinalCashierClosingMap =
                                                      HashMap();
                                                  tempFinalCashierClosingMap
                                                      .addAll({
                                                    'numberOfOrdersClosed':
                                                        FieldValue.increment(1),
                                                    'totalAmountClosed':
                                                        FieldValue.increment(
                                                            totalBillWithTaxes()
                                                                .round()),
                                                    'paymentMethodStats':
                                                        finalPaymentClosingMap
                                                  });
                                                  finalCashierClosingMap.addAll(
                                                      finalPaymentClosingMap);
                                                  finalCashierClosingMap
                                                      .addAll({
                                                    'numberOfTablesClosed':
                                                        FieldValue.increment(1)
                                                  });
                                                  finalCashierClosingMap
                                                      .addAll({
                                                    Provider.of<PrinterAndOtherDetailsProvider>(
                                                                context,
                                                                listen: false)
                                                            .currentUserPhoneNumberFromClass:
                                                        tempFinalCashierClosingMap
                                                  });
                                                  setState(() {
                                                    showSpinner = true;
                                                  });
                                                  paymentDoneClicked = true;
                                                  orderHistoryChecked =
                                                      'checking';
                                                  billUpdateTried = false;
                                                  Map<String, dynamic>
                                                      tempBaseInfoMap =
                                                      HashMap();
                                                  tempBaseInfoMap.addAll({
                                                    'billClosingPhoneOrderIdWithTime':
                                                        {
                                                      Provider.of<PrinterAndOtherDetailsProvider>(
                                                              context,
                                                              listen: false)
                                                          .currentUserPhoneNumberFromClass: {
                                                        'timeOfClosure': FieldValue
                                                            .serverTimestamp(),
                                                        'endingOrderId':
                                                            orderStartTimeForCreatingDocId
                                                      }
                                                    }
                                                  });

                                                  Map<String, dynamic>
                                                      tempMasterMap = HashMap();
                                                  tempMasterMap.addAll({
                                                    'baseInfoMap':
                                                        tempBaseInfoMap
                                                  });

                                                  FireStoreAddOrderInRunningOrderFolder(
                                                          hotelName:
                                                              widget.hotelName,
                                                          seatingNumber: widget
                                                              .itemsFromThisDocumentInFirebaseDoc,
                                                          ordersMap:
                                                              tempMasterMap)
                                                      .addOrder();
                                                  if (serialNumber == 0) {
//ForMakingSerialNumberIfItIsNotThere
                                                    Map<String, dynamic>
                                                        tempSerialInStatisticsMap =
                                                        HashMap();
                                                    tempSerialInStatisticsMap
                                                        .addAll({
                                                      orderHistoryDocID: {
                                                        Provider.of<PrinterAndOtherDetailsProvider>(
                                                                context,
                                                                listen: false)
                                                            .currentUserPhoneNumberFromClass: {
                                                          'timeOfBilling':
                                                              FieldValue
                                                                  .serverTimestamp()
                                                        }
                                                      }
                                                    });
                                                    FirebaseFirestore.instance
                                                        .collection(
                                                            widget.hotelName)
                                                        .doc('reports')
                                                        .collection(
                                                            'dailyReports')
                                                        .doc(statisticsYear)
                                                        .collection(
                                                            statisticsMonth)
                                                        .doc(statisticsDay)
                                                        .set({
                                                      'statisticsDocumentIdMap':
                                                          tempSerialInStatisticsMap
                                                    }, SetOptions(merge: true));
                                                  }
                                                  closingCheckCounter = 0;
                                                  timerForClosingTableAfterDataReady();
                                                  Navigator.pop(context);
                                                }
                                              } else {
                                                show(
                                                    'Please Check Internet and Try Again');
                                              }
                                            },
                                            buttonTitle: 'Done',
                                            buttonColor: Colors.green),
                                      ),
                                    ),
                                  ],
                                )
                              : SizedBox.shrink(),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
          });
        });
  }

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

  void addingNewPaymentMethod() {
    final fcmProvider =
        Provider.of<NotificationProvider>(context, listen: false);
    //NewPaymentMethod
    Map<String, dynamic> tempPaymentMethodMap =
        expensesSegregationMap['paymentMethod'];
    num newPaymentMethodKey = 111111111;
    if (tempPaymentMethodMap.isNotEmpty) {
      List<num> currentPaymentMethodKey = [];
      tempPaymentMethodMap.forEach((key, value) {
        currentPaymentMethodKey.add(num.parse(key));
      });
      newPaymentMethodKey = currentPaymentMethodKey.reduce(max) + 1;
    }
//WeAreGettingTheMaxValueOfTheKeyWeHaveInCategoriesAndAddingItByOne
    //ThisIsForLocalUpdate
    Map<String, dynamic> tempExpensesSegregationUpdateMap = HashMap();
    for (var eachNewPaymentMethod in finalNewPaymentMethod) {
      tempPaymentMethodMap
          .addAll({newPaymentMethodKey.toString(): eachNewPaymentMethod});
      tempExpensesSegregationUpdateMap
          .addAll({newPaymentMethodKey.toString(): eachNewPaymentMethod});
      newPaymentMethodKey++;
    }
    expensesSegregationMap['paymentMethod'] = tempPaymentMethodMap;
//WeNeedToUpdateInServerNext
    int expensesUpdateTimeInMilliseconds =
        DateTime.now().millisecondsSinceEpoch;
    var batch = _fireStore.batch();
    var expensesPaymentMethodRef =
        _fireStore.collection(widget.hotelName).doc('expensesSegregation');
    var expensesDateUpdationRef =
        _fireStore.collection(widget.hotelName).doc('basicinfo');
    batch.set(
        expensesPaymentMethodRef,
        {'paymentMethod': tempExpensesSegregationUpdateMap},
        SetOptions(merge: true));
    batch.set(
        expensesDateUpdationRef,
        {
          'updateTimes': {
            'expensesSegregation': expensesUpdateTimeInMilliseconds
          }
        },
        SetOptions(merge: true));
    batch.commit();
    fcmProvider.sendNotification(
        token: dynamicTokensToStringToken(),
        title:
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .chosenRestaurantDatabaseFromClass,
        restaurantNameForNotification: json.decode(
                Provider.of<PrinterAndOtherDetailsProvider>(context,
                        listen: false)
                    .allUserProfilesFromClass)[
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .currentUserPhoneNumberFromClass]['restaurantName'],
        body: '*restaurantInfoUpdated*');
    Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
        .expensesSegregationTimeStampSaving(expensesUpdateTimeInMilliseconds,
            json.encode(expensesSegregationMap));
    paymentMethodFromExpensesSegregationData();
  }

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
      billHour =
          now.hour < 10 ? '0${now.hour.toString()}' : '${now.hour.toString()}';
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
        (DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day,
                closingHour))
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

  Future<void> serialNumberStreamForPrinting() async {
    streamSubscriptionForPrintingOnTrueOffFalse = true;
    final docRef = FirebaseFirestore.instance
        .collection(widget.hotelName)
        .doc('reports')
        .collection('dailyReports')
        .doc(statisticsYear)
        .collection(statisticsMonth)
        .doc(statisticsDay);

    _streamSubscriptionForPrinting =
        docRef.snapshots().listen((statisticsDataCheckSnapshot) {
      final statisticsData = statisticsDataCheckSnapshot.data();
      Map<String, dynamic> statisticsDocumentIdMap = HashMap();
      if (statisticsData != null &&
          statisticsData.containsKey('statisticsDocumentIdMap')) {
        statisticsDocumentIdMap = statisticsData!['statisticsDocumentIdMap'];
      }

      if (
          // !statisticsDocumentIdMap.containsKey(orderHistoryDocID) ||
          noItemsInTable) {
//ThisMeansThatTheBillHasAlreadyReachedTheServer
        Map<String, dynamic> tempSerialInStatisticsMap = HashMap();
        tempSerialInStatisticsMap
            .addAll({orderHistoryDocID: FieldValue.delete()});
        FirebaseFirestore.instance
            .collection(widget.hotelName)
            .doc('reports')
            .collection('dailyReports')
            .doc(statisticsYear)
            .collection(statisticsMonth)
            .doc(statisticsDay)
            .set({'statisticsDocumentIdMap': tempSerialInStatisticsMap},
                SetOptions(merge: true));
        if (statisticsData != null) {
          statisticsData.clear();
        }

        statisticsDataCheckSnapshot.data()!.clear();
        setState(() {
          showSpinner = true;
          tappedPrintButton = true;
        });
      } else if (statisticsDocumentIdMap.isNotEmpty &&
          statisticsDocumentIdMap.containsKey(orderHistoryDocID)) {
        Map<String, dynamic> thisTableData =
            statisticsDocumentIdMap[orderHistoryDocID];

        Timestamp timeThisTableWasBilled = Timestamp.fromDate(DateTime(5000));
        int numberOfOrdersBeforeThisTable = 0;
//GettingTheMinimumTimeAtWhichThisTableWasBilled
        thisTableData.forEach((key, value) {
          if (value['timeOfBilling'] != null) {
            if (timeThisTableWasBilled.compareTo(value['timeOfBilling']) == 1) {
//IfItIsOne,itMeansAsPerTimeStampComparision,ItIsInThPast
              timeThisTableWasBilled = value['timeOfBilling'];
            }
          }
        });

        if (Timestamp.fromDate(DateTime(5000))
                .compareTo(timeThisTableWasBilled) ==
            1) {
//ThisMeansThatThereWasAtLeastOneDataWithProperIdAndHence...
//...TimeThisTableWasBilledIsn'tInitialData
          if (statisticsDocumentIdMap.length > 1) {
//ThisMeansThereAreTablesBilledOtherThanThisTable
            statisticsDocumentIdMap.forEach((key, value) {
              Map<String, dynamic> timesOfEachOrder = value;
              if (key != orderHistoryDocID && timesOfEachOrder.isNotEmpty) {
//ToEnsureWeAren'tCheckingTheSameOrderAndAlsoCheckingIfAnyTableIsEmpty
//ThisUsuallyHappensIfBcozOfBadInternetWeHadDeletedTheMobileNumberForThatTable

                Timestamp billedTimeOfEachOrderOtherThanThisOrder =
                    Timestamp.fromDate(DateTime(5000));

                timesOfEachOrder.forEach((key, timeOfEachOrdervalue) {
                  if (billedTimeOfEachOrderOtherThanThisOrder
                          .compareTo(timeOfEachOrdervalue['timeOfBilling']) ==
                      1) {
                    billedTimeOfEachOrderOtherThanThisOrder =
                        timeOfEachOrdervalue['timeOfBilling'];
                  }
                });
                if (timeThisTableWasBilled
                        .compareTo(billedTimeOfEachOrderOtherThanThisOrder) ==
                    1) {
//ThisThatOrderWasBilledBeforeThisTable
                  numberOfOrdersBeforeThisTable++;
                }
              }
            });
          }
//stoppingRightHere.

          if (serialNumber == 0 && !noItemsInTable) {
            if (gotSerialNumber == false) {
              gotSerialNumber = true;
              Map<String,dynamic> tempSalesIncomeStats = HashMap();
              Map<String,dynamic> tempGeneralStats = HashMap();
              if(statisticsData!.containsKey('salesIncomeStats')){
                tempSalesIncomeStats = statisticsData['salesIncomeStats'];
                if(tempSalesIncomeStats.containsKey('mapGeneralStatsMap')){
                  tempGeneralStats = tempSalesIncomeStats['mapGeneralStatsMap'];
                }
              }

              // statisticsData = value.data();
              if (tempSalesIncomeStats.isEmpty || tempGeneralStats.isEmpty ||
                  !tempGeneralStats.containsKey('serialNumber')) {
                serialNumber = 1 + numberOfOrdersBeforeThisTable;
              } else {
                serialNumber = num.parse((statisticsData!['salesIncomeStats']
                                ['mapGeneralStatsMap']['serialNumber'])
                            .toString())
                        .toInt() +
                    1 +
                    numberOfOrdersBeforeThisTable;
              }
// //SinceSerialNumberIsZeroWeWillHaveToIncrementSerialNumberByOneAnyway
//               FireStoreUpdateStatisticsIndividualField(
//                       hotelName: widget.hotelName,
//                       docID: statisticsDocID,
//                       incrementBy: 1,
//                       key: 'serialNumber')
//                   .updateStatistics();
              if (statisticsData != null) {
                statisticsData.clear();
              }
              statisticsDataCheckSnapshot.data()!.clear();

              if (secondaryPrintButtonTapCheck) {
                secondaryPrintButtonTapCheck = false;
                serialNumberUpdateInServerWhenPrintClickedFirstTime();
                tappedPrintButton = false;
                startOfCallForPrintingBill();
              }
            }
          } else if (serialNumber != 0 && !noItemsInTable) {
            gotSerialNumber = true;
//ThisMeansWeRealisedSuddenlyWhenNetCameThatSerialNumberExists
//AndHenceCanStraightCall StartOfCallForPrintingBill
            if (secondaryPrintButtonTapCheck) {
              secondaryPrintButtonTapCheck = false;
              startOfCallForPrintingBill();
            }

            statisticsDataCheckSnapshot.data()!.clear();
            if (statisticsData != null) {
              statisticsData.clear();
            }
          }
//ThisMeansWeGotSerialNumberAndHenceWeCanCancelTheStream

          streamSubscriptionForPrintingOnTrueOffFalse = false;
          _streamSubscriptionForPrinting?.cancel();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget billItemsForDisplay() {
      return Container(
        width: 500,
        height: distinctItemNames.length * 60,
        child: ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            itemCount: distinctItemNames.length,
            itemBuilder: (context, index) {
              final itemName = distinctItemNames[index];
              final itemPrice = individualPriceOfOneDistinctItem[index];
              final numberOfEachItems = numberOfOneDistinctItem[index];
              final eachItemPrice = totalPriceOfOneDistinctItem[index];
              return ListTile(
                title: Text(
                    '${index + 1}.$itemName x $itemPrice x $numberOfEachItems =',
                    style: TextStyle(fontSize: 18.0)),
                trailing:
                    Text('$eachItemPrice', style: TextStyle(fontSize: 18.0)),
              );
            }),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (billUpdatedInServer || noItemsInTable) {
          int count = 0;
          Navigator.of(context).popUntil((_) => count++ >= 2);
        } else {
          Navigator.pop(context);
        }
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: kAppBarBackIconColor),
              onPressed: () async {
                if (billUpdatedInServer || noItemsInTable) {
                  int count = 0;
                  Navigator.of(context).popUntil((_) => count++ >= 2);
                } else {
                  Navigator.pop(context);
                }
              }),
          backgroundColor: kAppBarBackgroundColor,
          title: Text(
            'Final Bill - ${widget.itemsFromThisDocumentInFirebaseDoc}',
            style: kAppBarTextStyle,
          ),
          centerTitle: true,
          actions: <Widget>[
            IconButton(
                onPressed: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PrinterRolesAssigning()));
                },
                icon: Icon(
                  Icons.settings,
                  color: kAppBarBackIconColor,
                )),
            IconButton(
                onPressed: () {
                  screenPopOutTimerAfterServerUpdate();
                },
                icon: Icon(
                  Icons.close,
                  color: kAppBarBackIconColor,
                ))
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ModalProgressHUD(
//ThisIsToShowSpinnerOnceWeClickPrintButton
                inAsyncCall: showSpinner,
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection(widget.hotelName)
                        .doc('runningorders')
                        .collection('runningorders')
                        .doc(widget.itemsFromThisDocumentInFirebaseDoc)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
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
                          noItemsInTable = true;

                          return const Center(
                            child: Text(
                              'Bill\nClosed/Split/Moved',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 30),
                            ),
                          );
                        } else {
                          noItemsInTable = false;

                          var output = snapshot.data!.data();
                          baseInfoFromServerMap = output!['baseInfoMap'];
                          if (output.containsKey('cancelledItemsInOrder')) {
                            cancelledItemsInOrderFromServerMap =
                                output!['cancelledItemsInOrder'];
                          }
                          itemsInOrderFromServerMap =
                              output!['itemsInOrderMap'];
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
                          makingDistinctItemsList();

                          return noItemsInTable == false
                              ? Scaffold(
                                  body:
                                      buildBillDataScreen(billItemsForDisplay),
                                  floatingActionButton: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        width: 90,
                                        height: 75.0,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(1)),
                                        child: MaterialButton(
                                          color: Colors.white70,
                                          shape: CircleBorder(),
                                          child: const Text(
                                            'Charges',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black,
                                                fontWeight: FontWeight.w900),
                                          ),
                                          onPressed: () {
//shouldBeActiveOnlyWhenThereIsNoOtherImportantActivityLikePrintHappening
                                            if (!showSpinner) {
                                              if (extraChargesMapFromServer
                                                  .isEmpty) {
                                                tempChargeName =
                                                    chargesNamesList[0];
                                                tempChargesPriceForEditInString =
                                                    '';
                                                _controller.clear();
                                                chargesAddBottomBar();
                                              } else {
                                                existingExtraChargesBottomBar();
                                              }
                                            }
                                          },
                                        ),
                                      ),
                                      SizedBox(height: 20),
                                      Container(
                                        width: 90.0,
                                        height: 75.0,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(1)),
                                        child: MaterialButton(
                                          color: Colors.white70,
                                          shape: CircleBorder(),
                                          child: const Text(
                                            'Discount',
                                            style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.black,
                                                fontWeight: FontWeight.w900),
                                          ),
                                          onPressed: () {
//shouldBeActiveOnlyWhenThereIsNoOtherImportantActivityLikePrintHappening
                                            if (!showSpinner) {
                                              //onPressedWeAlreadyHaveAllTheBelowInputsAsThisScreenWasCalled
//WeGiveUnavailableItemsToEnsureWeDon'tShowItAndItemsAddedMap
//WillHaveTheItemNameAsKeyAndTheNumberAsValue
                                              String tempDiscountEnteredValue =
                                                  discountEnteredValue;
                                              bool
                                                  tempDiscountValueClickedTruePercentageClickedFalse =
                                                  discountValueClickedTruePercentageClickedFalse;
                                              _controller = TextEditingController(
                                                  text:
                                                      tempDiscountEnteredValue);

                                              showModalBottomSheet(
                                                  isScrollControlled: true,
                                                  context: context,
                                                  builder: (BuildContext
                                                      buildContext) {
                                                    return StatefulBuilder(
                                                        builder: (context,
                                                            setStateSB) {
                                                      return Padding(
                                                        padding: EdgeInsets.only(
                                                            bottom:
                                                                MediaQuery.of(
                                                                        context)
                                                                    .viewInsets
                                                                    .bottom),
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                Expanded(
                                                                  // width: double.infinity,
                                                                  child: ElevatedButton(
                                                                      style: ButtonStyle(
                                                                        backgroundColor: tempDiscountValueClickedTruePercentageClickedFalse
                                                                            ? MaterialStateProperty.all(Colors.grey)
                                                                            : MaterialStateProperty.all(Colors.green),
                                                                      ),
                                                                      onPressed: () {
                                                                        setStateSB(
                                                                            () {
                                                                          tempDiscountValueClickedTruePercentageClickedFalse =
                                                                              false;

                                                                          tempDiscountEnteredValue =
                                                                              '';
                                                                          _controller
                                                                              .clear();
                                                                        });
                                                                      },
                                                                      child: Text('Discount Percentage')),
                                                                ),
                                                                SizedBox(
                                                                    width: 10),
                                                                Expanded(
                                                                    // width: double.infinity,
                                                                    child: ElevatedButton(
                                                                        style: ButtonStyle(
                                                                          backgroundColor: tempDiscountValueClickedTruePercentageClickedFalse
                                                                              ? MaterialStateProperty.all(Colors.green)
                                                                              : MaterialStateProperty.all(Colors.grey),
                                                                        ),
                                                                        onPressed: () {
                                                                          setStateSB(
                                                                              () {
                                                                            tempDiscountValueClickedTruePercentageClickedFalse =
                                                                                true;
                                                                            tempDiscountEnteredValue =
                                                                                '';
                                                                            _controller.clear();
                                                                          });
                                                                        },
                                                                        child: Text('Discount Value'))),
                                                              ],
                                                            ),
                                                            Container(
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(20),
                                                              child: TextField(
                                                                maxLength: 250,
                                                                keyboardType: TextInputType
                                                                    .numberWithOptions(
                                                                        decimal:
                                                                            true),
                                                                controller:
                                                                    _controller,
                                                                // controller:
                                                                // TextEditingController(text: widget.itemsAddedComment[item]),
                                                                onChanged:
                                                                    (value) {
                                                                  tempDiscountEnteredValue =
                                                                      value;
                                                                },
                                                                decoration:
                                                                    // kTextFieldInputDecoration,
                                                                    InputDecoration(
                                                                        filled:
                                                                            true,
                                                                        fillColor: Colors
                                                                            .white,
                                                                        hintText: tempDiscountValueClickedTruePercentageClickedFalse
                                                                            ? 'Enter ₹'
                                                                            : 'Enter %',
                                                                        hintStyle: TextStyle(
                                                                            color: Colors
                                                                                .grey),
                                                                        enabledBorder: OutlineInputBorder(
                                                                            borderRadius: BorderRadius.all(Radius.circular(
                                                                                10)),
                                                                            borderSide: BorderSide(
                                                                                color: Colors
                                                                                    .green)),
                                                                        focusedBorder: OutlineInputBorder(
                                                                            borderRadius:
                                                                                BorderRadius.all(Radius.circular(10)),
                                                                            borderSide: BorderSide(color: Colors.green))),
                                                              ),
                                                            ),
                                                            ElevatedButton(
                                                                style:
                                                                    ButtonStyle(
                                                                  backgroundColor:
                                                                      MaterialStateProperty.all<
                                                                              Color>(
                                                                          Colors
                                                                              .green),
                                                                ),
                                                                onPressed: () {
                                                                  if (tempDiscountValueClickedTruePercentageClickedFalse) {
                                                                    setState(
                                                                        () {
                                                                      if (tempDiscountEnteredValue !=
                                                                          '') {
                                                                        discount =
                                                                            num.parse(tempDiscountEnteredValue);
                                                                      } else {
                                                                        discount =
                                                                            0;
                                                                      }
                                                                    });
                                                                  } else {
                                                                    setStateSB(
                                                                        () {
                                                                      if (tempDiscountEnteredValue !=
                                                                          '') {
                                                                        discount =
                                                                            num.parse((totalPriceOfAllItems * (num.parse(tempDiscountEnteredValue) / 100)).toStringAsFixed(2));
                                                                      } else {
                                                                        discount =
                                                                            0;
                                                                      }
                                                                    });
                                                                  }

                                                                  Map<String,
                                                                          dynamic>
                                                                      tempBaseInfoMapToServer =
                                                                      HashMap();
                                                                  tempBaseInfoMapToServer
                                                                      .addAll({
                                                                    'discountEnteredValue':
                                                                        tempDiscountEnteredValue
                                                                  });
                                                                  tempBaseInfoMapToServer
                                                                      .addAll({
                                                                    'discountValueTruePercentageFalse':
                                                                        tempDiscountValueClickedTruePercentageClickedFalse
                                                                  });
                                                                  Map<String,
                                                                          dynamic>
                                                                      tempMasterOrderMapToServer =
                                                                      HashMap();
                                                                  tempMasterOrderMapToServer
                                                                      .addAll({
                                                                    'baseInfoMap':
                                                                        tempBaseInfoMapToServer
                                                                  });

                                                                  FireStoreAddOrderInRunningOrderFolder(
                                                                          hotelName: widget
                                                                              .hotelName,
                                                                          seatingNumber: widget
                                                                              .itemsFromThisDocumentInFirebaseDoc,
                                                                          ordersMap:
                                                                              tempMasterOrderMapToServer)
                                                                      .addOrder();
                                                                  Navigator.pop(
                                                                      context);
                                                                },
                                                                child: Text(
                                                                    'Done'))
                                                          ],
                                                        ),
                                                      );
                                                    });
                                                  });
                                            }
                                          },
                                        ),
                                      )
                                    ],
                                  ),
                                  persistentFooterButtons: [
                                    Row(
                                      children: [
//                                         Visibility(
//                                           visible: json.decode(Provider.of<
//                                                           PrinterAndOtherDetailsProvider>(
//                                                       context,
//                                                       listen: false)
//                                                   .allUserProfilesFromClass)[Provider
//                                                       .of<PrinterAndOtherDetailsProvider>(
//                                                           context,
//                                                           listen: false)
//                                                   .currentUserPhoneNumberFromClass]
//                                               ['privileges']['9'],
//                                           child: Expanded(
//                                             child: BottomButton(
//                                               onTap: () async {
//                                                 if (showSpinner == false) {
//                                                   if (billUpdatedInServer ==
//                                                           false &&
//                                                       pageHasInternet) {
//                                                     paymentDoneClicked = true;
//                                                     setState(() {
//                                                       showSpinner = true;
//                                                     });
//
//                                                     Map<String, dynamic>
//                                                         tempBaseInfoMap =
//                                                         HashMap();
//                                                     tempBaseInfoMap.addAll({
//                                                       'billClosingPhoneOrderIdWithTime':
//                                                           {
//                                                         Provider.of<PrinterAndOtherDetailsProvider>(
//                                                                 context,
//                                                                 listen: false)
//                                                             .currentUserPhoneNumberFromClass: {
//                                                           'timeOfClosure':
//                                                               FieldValue
//                                                                   .serverTimestamp(),
//                                                           'endingOrderId':
//                                                               orderStartTimeForCreatingDocId
//                                                         }
//                                                       }
//                                                     });
//
//                                                     Map<String, dynamic>
//                                                         tempMasterMap =
//                                                         HashMap();
//                                                     tempMasterMap.addAll({
//                                                       'baseInfoMap':
//                                                           tempBaseInfoMap
//                                                     });
//
//                                                     FireStoreAddOrderInRunningOrderFolder(
//                                                             hotelName: widget
//                                                                 .hotelName,
//                                                             seatingNumber: widget
//                                                                 .itemsFromThisDocumentInFirebaseDoc,
//                                                             ordersMap:
//                                                                 tempMasterMap)
//                                                         .addOrder();
//                                                     if (serialNumber == 0) {
// //ForMakingSerialNumberIfItIsNotThere
//
//                                                       Map<String, dynamic>
//                                                           tempSerialInStatisticsMap =
//                                                           HashMap();
//                                                       tempSerialInStatisticsMap
//                                                           .addAll({
//                                                         orderHistoryDocID: {
//                                                           Provider.of<PrinterAndOtherDetailsProvider>(
//                                                                   context,
//                                                                   listen: false)
//                                                               .currentUserPhoneNumberFromClass: {
//                                                             'timeOfBilling':
//                                                                 FieldValue
//                                                                     .serverTimestamp()
//                                                           }
//                                                         }
//                                                       });
//                                                       FirebaseFirestore.instance
//                                                           .collection(
//                                                               widget.hotelName)
//                                                           .doc('reports')
//                                                           .collection(
//                                                               'dailyReports')
//                                                           .doc(tempYear)
//                                                           .collection(tempMonth)
//                                                           .doc(tempDay)
//                                                           .set(
//                                                               {
//                                                             'statisticsDocumentIdMap':
//                                                                 tempSerialInStatisticsMap
//                                                           },
//                                                               SetOptions(
//                                                                   merge: true));
//                                                       // FirebaseFirestore.instance
//                                                       //     .collection(
//                                                       //         widget.hotelName)
//                                                       //     .doc('statistics')
//                                                       //     .collection(
//                                                       //         'statistics')
//                                                       //     .doc(statisticsDocID)
//                                                       //     .set(
//                                                       //         {
//                                                       //       'statisticsDocumentIdMap':
//                                                       //           tempSerialInStatisticsMap
//                                                       //     },
//                                                       //         SetOptions(
//                                                       //             merge: true));
//                                                     }
//                                                     paymentDoneBillClosureDataNotReceived();
//                                                   }
//                                                 }
//                                               },
//                                               buttonTitle: 'Payment Done',
//                                               buttonColor: Colors.green,
//                                               // buttonWidth: double.infinity,
//                                             ),
//                                           ),
//                                         ),
                                        Visibility(
                                          visible: json.decode(Provider.of<
                                                          PrinterAndOtherDetailsProvider>(
                                                      context,
                                                      listen: false)
                                                  .allUserProfilesFromClass)[Provider
                                                      .of<PrinterAndOtherDetailsProvider>(
                                                          context,
                                                          listen: false)
                                                  .currentUserPhoneNumberFromClass]
                                              ['privileges']['9'],
                                          child: Expanded(
                                            child: BottomButton(
                                              onTap: () async {
                                                paymentClosingBottomBar(true);
                                              },
                                              buttonTitle: 'Payment',
                                              buttonColor: Colors.green,
                                              // buttonWidth: double.infinity,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Provider.of<PrinterAndOtherDetailsProvider>(
                                                        context,
                                                        listen: false)
                                                    .billingAssignedPrinterFromClass ==
                                                '{}'
                                            ? Visibility(
                                                visible: json.decode(Provider
                                                            .of<PrinterAndOtherDetailsProvider>(
                                                                context,
                                                                listen: false)
                                                        .allUserProfilesFromClass)[Provider
                                                            .of<PrinterAndOtherDetailsProvider>(
                                                                context,
                                                                listen: false)
                                                        .currentUserPhoneNumberFromClass]
                                                    ['privileges']['10'],
                                                child: Expanded(
//IfNoPrinterAddressWeWillSayWeNeedThePrinterSetUpScreen
                                                  child: BottomButton(
                                                    onTap: () async {
                                                      if (showSpinner ==
                                                          false) {
                                                        Navigator.pushReplacement(
                                                            context,
                                                            MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        PrinterRolesAssigning()));
                                                      }
                                                    },
                                                    buttonTitle:
                                                        'Assign Printer',
                                                    buttonColor: Colors.red,
                                                    // buttonWidth: double.infinity,
                                                  ),
                                                ),
                                              )
                                            : Visibility(
                                                visible: json.decode(Provider
                                                            .of<PrinterAndOtherDetailsProvider>(
                                                                context,
                                                                listen: false)
                                                        .allUserProfilesFromClass)[Provider
                                                            .of<PrinterAndOtherDetailsProvider>(
                                                                context,
                                                                listen: false)
                                                        .currentUserPhoneNumberFromClass]
                                                    ['privileges']['10'],
                                                child: Expanded(
                                                  child: BottomButton(
                                                    onTap: () async {
                                                      if (showSpinner ==
                                                          false) {
                                                        //ThisWayYouCan'tPrintAgainOnceBillHasBeenUpdatedInServer
//                               bluetoothPrint.state.listen((state) {
                                                        // print('state is $state');

                                                        if (tappedPrintButton ==
                                                                false &&
                                                            pageHasInternet) {
                                                          if (serialNumber !=
                                                              0) {
                                                            startOfCallForPrintingBill();
                                                          } else {
                                                            documentStatisticsRegistryDateMaker();
                                                            secondaryPrintButtonTapCheck =
                                                                true;
                                                            if (streamSubscriptionForPrintingOnTrueOffFalse ==
                                                                false) {
                                                              serialNumberStreamForPrinting();
                                                            }
                                                            Map<String, dynamic>
                                                                tempSerialInStatisticsMap =
                                                                HashMap();
                                                            tempSerialInStatisticsMap
                                                                .addAll({
                                                              orderHistoryDocID:
                                                                  {
                                                                Provider.of<PrinterAndOtherDetailsProvider>(
                                                                        context,
                                                                        listen:
                                                                            false)
                                                                    .currentUserPhoneNumberFromClass: {
                                                                  'timeOfBilling':
                                                                      FieldValue
                                                                          .serverTimestamp(),
                                                                }
                                                              }
                                                            });
                                                            FirebaseFirestore
                                                                .instance
                                                                .collection(widget
                                                                    .hotelName)
                                                                .doc('reports')
                                                                .collection(
                                                                    'dailyReports')
                                                                .doc(
                                                                    statisticsYear)
                                                                .collection(
                                                                    statisticsMonth)
                                                                .doc(
                                                                    statisticsDay)
                                                                .set(
                                                                    {
                                                                  'statisticsDocumentIdMap':
                                                                      tempSerialInStatisticsMap
                                                                },
                                                                    SetOptions(
                                                                        merge:
                                                                            true));
                                                            setState(() {
                                                              showSpinner =
                                                                  true;
                                                            });

                                                            Timer(
                                                                Duration(
                                                                    seconds: 1),
                                                                () {
                                                              timerForNullifyingSerialNumberTimeStampDataInServer();

                                                              // serialNumberStatisticsExistsOrNot();
                                                            });
                                                          }
                                                        }
                                                      }
                                                    },
                                                    buttonTitle: 'Print',
                                                    buttonColor:
                                                        Colors.orangeAccent,
                                                    // buttonWidth: double.infinity,
                                                  ),
                                                ),
                                              ),
                                      ],
                                    ),
                                  ],
                                )
                              : const Center(
                                  child: Text(
                                    'Bill\nClosed/Split/Moved',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 30),
                                  ),
                                );
                        }
                      } else {
                        return CircularProgressIndicator();
                      }
                    }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //TheMethodThatGivesTheBillDataWithWidgetsToTheScreen
  SingleChildScrollView buildBillDataScreen(Widget billItemsForDisplay()) {
    return SingleChildScrollView(
      physics: ScrollPhysics(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          pageHasInternet
              ? const SizedBox(
                  height: 30.0,
                )
              : Container(
                  width: double.infinity,
                  color: Colors.red,
                  child: const Center(
                    child: Text('You are Offline',
                        style: TextStyle(color: Colors.white, fontSize: 30.0)),
                  ),
                ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20.0,
              ),
              Text(
                'Order Date: $billDay-$billMonth-$billYear',
                style: TextStyle(fontSize: 20.0),
              ),
            ],
          ),
          Divider(
            thickness: 2,
            color: Colors.black,
          ),
          //returnItems(),
          billItemsForDisplay(),
          extraChargesMapFromServer.isNotEmpty
              ? Divider(
                  thickness: 2,
                  color: Colors.black,
                )
              : SizedBox.shrink(),
          extraChargesMapFromServer.isNotEmpty
              ? extraChargesInMainScreen()
              : SizedBox.shrink(),
          Divider(
            thickness: 2,
            color: Colors.black,
          ),
          discount != 0
              ? ListTile(
                  title: discountValueClickedTruePercentageClickedFalse
                      ? Text('Discount ₹', style: TextStyle(fontSize: 20.0))
                      : Text('Discount $discountEnteredValue % ',
                          style: TextStyle(fontSize: 20.0)),
                  trailing: Text('$discount', style: TextStyle(fontSize: 20.0)),
                )
              : SizedBox.shrink(),
          discount != 0
              ? Divider(
                  thickness: 2,
                  color: Colors.black,
                )
              : SizedBox.shrink(),
          json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                          listen: false)
                      .restaurantInfoDataFromClass)['cgst'] >
                  0
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('Sub-Total', style: TextStyle(fontSize: 25.0)),
                    Text('${totalPriceOfAllItems - discount}',
                        style: TextStyle(fontSize: 25.0))
                  ],
                )
              : SizedBox.shrink(),
          json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                          listen: false)
                      .restaurantInfoDataFromClass)['cgst'] >
                  0
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                        'CGST@ ${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['cgst']}%',
                        style: TextStyle(fontSize: 25.0)),
                    Text('${cgstCalculatedForBillFunction()}',
                        style: TextStyle(fontSize: 25.0))
                  ],
                )
              : SizedBox.shrink(),
          json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                          listen: false)
                      .restaurantInfoDataFromClass)['sgst'] >
                  0
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                        'SGST@ ${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['sgst']}%',
                        style: TextStyle(fontSize: 25.0)),
                    Text('${sgstCalculatedForBillFunction()}',
                        style: TextStyle(fontSize: 25.0))
                  ],
                )
              : SizedBox.shrink(),
          roundOff() != '0'
              ? Divider(
                  thickness: 2,
                  color: Colors.black,
                )
              : SizedBox.shrink(),
          roundOff() != '0'
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('Round Off', style: TextStyle(fontSize: 15.0)),
                    Text('${roundOff()}', style: TextStyle(fontSize: 15.0))
                  ],
                )
              : SizedBox.shrink(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Grand Total',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 30.0,
                  )),
              Text('${totalBillWithTaxesAsString()}',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 30.0,
                  )),
            ],
          ),
          SizedBox(height: 250)
        ],
      ),
    );
  }
}
