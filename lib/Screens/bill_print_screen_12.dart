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
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:orders_dev/Screens/printer_roles_assigning.dart';
import 'package:orders_dev/constants.dart';
import 'package:orders_dev/services/firestore_services.dart';
import 'package:provider/provider.dart';
import 'package:modal_progress_hud_alt/modal_progress_hud_alt.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';

class BillPrintWithOrderHistoryDoubleCheck extends StatefulWidget {
  final String hotelName;
  // final String addedItemsSet;
  final List<String> itemsID;
  final String itemsFromThisDocumentInFirebaseDoc;

  const BillPrintWithOrderHistoryDoubleCheck({
    Key? key,
    required this.hotelName,
    // required this.addedItemsSet,
    required this.itemsID,
    required this.itemsFromThisDocumentInFirebaseDoc,
  }) : super(key: key);

  @override
  State<BillPrintWithOrderHistoryDoubleCheck> createState() =>
      _BillPrintWithOrderHistoryDoubleCheckState();
}

class _BillPrintWithOrderHistoryDoubleCheckState
    extends State<BillPrintWithOrderHistoryDoubleCheck> {
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
  String tempYear = '';
  String tempMonth = '';
  String tempDay = '';
  String tempHour = '';
  String tempMinute = '';
  String tempSecond = '';
  num startTimeOfThisTableOrParcelInNum = 0;
  List<Map<String, dynamic>> items = [];
  List<String> distinctItemNames = [];
  List<num> individualPriceOfOneDistinctItem = [];
  List<num> numberOfOneDistinctItem = [];
  List<num> totalPriceOfOneDistinctItem = [];
  num totalPriceOfAllItems = 0;
  num totalQuantityOfAllItems = 0;
  Map<String, dynamic> statisticsMap = HashMap();
  Map<String, dynamic> toCheckPastOrderHistoryMap = HashMap();
  Map<String, String> printOrdersMap = HashMap();

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
  String orderIdForCreatingDocId = '';

  bool paymentDoneClicked = false;
  bool orderIdCheckedWhenEnteringScreen = false;
  String firstCheckedOrderId = '';

  @override
  void initState() {
    showSpinner = false;

    tappedPrintButton = false;
    paymentDoneClicked = false;
    gotSerialNumber = false;
    items = [];
    distinctItemNames = [];
    serialNumber = 0;
    orderIdCheckedWhenEnteringScreen = false;
    firstCheckedOrderId = '';
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

    super.initState();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscriptionBtStatus?.cancel();
    _subscriptionUsbStatus?.cancel();
    super.dispose();
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

  void makingDistinctItemsList() {
    items = [];
    DateTime now = DateTime.now();
//WeEnsureWeTakeTheMonth,Day,Hour,MinuteAsString
//ifItIsLessThan10,WeSaveItWithZeroInTheFront
//ThisWillEnsure,ItIsAlwaysIn2Digits,AndWithoutPuttingItInTwoDigits,,
//ItWon'tComeInAscendingOrder
    if (baseInfoFromServerMap['billYear'] == '') {
      tempYear = now.year.toString();
    } else {
      tempYear = baseInfoFromServerMap['billYear'];
    }
    if (baseInfoFromServerMap['billMonth'] == '') {
      tempMonth = now.month < 10
          ? '0${now.month.toString()}'
          : '${now.month.toString()}';
    } else {
      tempMonth = baseInfoFromServerMap['billMonth'];
    }
    if (baseInfoFromServerMap['billDay'] == '') {
      tempDay =
          now.day < 10 ? '0${now.day.toString()}' : '${now.day.toString()}';
    } else {
      tempDay = baseInfoFromServerMap['billDay'];
    }
    if (baseInfoFromServerMap['billHour'] == '') {
      tempHour =
          now.hour < 10 ? '0${now.hour.toString()}' : '${now.hour.toString()}';
    } else {
      tempHour = baseInfoFromServerMap['billHour'];
    }
    if (baseInfoFromServerMap['billMinute'] == '') {
      tempMinute = now.minute < 10
          ? '0${now.minute.toString()}'
          : '${now.minute.toString()}';
    } else {
      tempMinute = baseInfoFromServerMap['billMinute'];
    }
    if (baseInfoFromServerMap['billSecond'] == '') {
      tempSecond = now.second < 10
          ? '0${now.second.toString()}'
          : '${now.second.toString()}';
    } else {
      tempSecond = baseInfoFromServerMap['billSecond'];
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
    orderIdForCreatingDocId = baseInfoFromServerMap['startTime'];
    if (orderIdForCreatingDocId.length < 8) {
      for (int i = orderIdForCreatingDocId.length; i < 8; i++) {
        orderIdForCreatingDocId = '0' + orderIdForCreatingDocId;
      }
    }
    // orderIdForCreatingDocId = baseInfoFromServerMap['orderID'];

    printOrdersMap = {};
    statisticsMap = {};
    toCheckPastOrderHistoryMap = {};
    orderHistoryDocID =
        '${tempYear}${tempMonth}${tempDay}${orderIdForCreatingDocId}';
    statisticsDocID = '$tempYear*$tempMonth*$tempDay';
    printingDate =
        '${tempDay}/${tempMonth}/${tempYear} at ${tempHour}:${tempMinute}';
    //InThePrintOrdersMap(HashMap),FirstWeSaveKeyAs "DateOfOrder"&ValueAs,,
//year/Month/Day At Hour:Minute
    printOrdersMap.addAll({
      ' Date of Order  :':
          '$tempYear/$tempMonth/$tempDay at $tempHour:$tempMinute'
    });

    Map<String, dynamic> mapToAddIntoItems = {};
    tableorparcel = baseInfoFromServerMap['tableOrParcel'];

    if (baseInfoFromServerMap['tableOrParcel'] == 'Parcel') {
      thisIsParcelTrueElseFalse = true;
      statisticsMap.addAll({'numberofparcel': FieldValue.increment(1)});
      statisticsMap.addAll({'totalnumberoforders': FieldValue.increment(1)});
    } else {
      thisIsParcelTrueElseFalse = false;
//ElseIfItIsTable,WeAddParcelNumbers0&TotalNumberOfOrdersAdd1InStatisticsMap
      statisticsMap.addAll({'numberofparcel': FieldValue.increment(0)});
      statisticsMap.addAll({'totalnumberoforders': FieldValue.increment(1)});
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
    }
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
      mapToAddIntoItems['itemBelongsToDoc'] =
          widget.itemsFromThisDocumentInFirebaseDoc;
      items.add(mapToAddIntoItems);
    });
    items.sort((a, b) => (a['timeoforder']).compareTo(b['timeoforder']));
    distinctItemNames = [];
    for (var eachItem in items) {
      if (!distinctItemNames.contains(eachItem['item'])) {
        distinctItemNames.add(eachItem['item']);
      }
    }

    individualPriceOfOneDistinctItem = [];
    numberOfOneDistinctItem = [];
    totalPriceOfOneDistinctItem = [];

    for (var distinctItemName in distinctItemNames) {
      num individualPriceOfOneDistinctItemForAddingIntoList = 0;
      num numberOfEachDistinctItemForAddingIntoList = 0;
      num totalPriceOfEachDistinctItemForAddingIntoList = 0;

      for (var eachItem in items) {
        if (distinctItemName == eachItem['item']) {
          individualPriceOfOneDistinctItemForAddingIntoList =
              eachItem['priceofeach'];
          numberOfEachDistinctItemForAddingIntoList += eachItem['number'];
          totalPriceOfEachDistinctItemForAddingIntoList +=
              (eachItem['priceofeach'] * eachItem['number']);
        }
      }
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
        numberOfOneDistinctItem.add(numberOfEachDistinctItemForAddingIntoList);
      }
      if (totalPriceOfEachDistinctItemForAddingIntoList != 0) {
        totalPriceOfOneDistinctItem
            .add(totalPriceOfEachDistinctItemForAddingIntoList);
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
          printOrdersMap
              .addAll({'${extrasCounter.toString()}*$key': value.toString()});
          extraItemsToPrint.add(key);
          extraItemsPricesToPrint.add(value.toString());
          extrasCounter++;
          extraItemsNames += '$key*';
          extraItemsNumbers += '${value.toString()}*';
        } else if (key == 'Parcel Charges') {
          printOrdersMap.addAll({'971*$key': value.toString()});
          tempExtraParcelCharge = value.toString();
        } else if (key == 'Delivery Charges') {
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
    printOrdersMap.addAll({'statisticsDocID': statisticsDocID});
    // printOrdersMap.addAll({'Total = ': (totalPriceOfAllItems.toString())});

    // cgstCalculatedForBillFunction();
    // sgstCalculatedForBillFunction();
    if (baseInfoFromServerMap['billClosingPhoneOrderIdWithTime'] != null &&
        paymentDoneClicked) {
      paymentDoneClicked = false;
      Timer(Duration(milliseconds: 500), () {
        checkingDocumentIdAlreadyExistsInOrderHistory();
      });
    }
  }

  Future<void> checkingDocumentIdAlreadyExistsInOrderHistory() async {
    try {
      final docIdCheckSnapshot = await FirebaseFirestore.instance
          .collection(widget.hotelName)
          .doc('orderhistory')
          .collection('orderhistory')
          .doc(orderHistoryDocID)
          .get()
          .timeout(Duration(seconds: 5));
      if (docIdCheckSnapshot == null || !docIdCheckSnapshot.exists) {
        if (!noItemsInTable) {
          Map<String, dynamic> tableClosureCheckMap =
              baseInfoFromServerMap['billClosingPhoneOrderIdWithTime'];
          if (tableClosureCheckMap.isNotEmpty) {
            String keyPhoneNumberOfUserWhoClosedFirst = '';
            Timestamp firstTimeOfClosure = Timestamp.fromDate(DateTime(5000));
            tableClosureCheckMap.forEach((key, value) {
              if (value['timeOfClosure'] != null) {
                if ((firstTimeOfClosure.compareTo(value['timeOfClosure']) ==
                        1) &&
                    value['endingOrderId'] == orderIdForCreatingDocId) {
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

                serverUpdateOfBill();
              } else {
//ThisMeansSomebodyOtherThanThisUserIsClosingTheTable

                screenPopOutTimerAfterServerUpdate();
              }
            } else {
              if (serialNumber == 0) {
                // ThisMeansThatTheDataHasNotReachedTheServer
                Map<String, dynamic> tempSerialInStatisticsMap = HashMap();
                tempSerialInStatisticsMap.addAll({
                  orderHistoryDocID: {
                    Provider.of<PrinterAndOtherDetailsProvider>(context,
                            listen: false)
                        .currentUserPhoneNumberFromClass: FieldValue.delete()
                  }
                });
                FirebaseFirestore.instance
                    .collection(widget.hotelName)
                    .doc('statistics')
                    .collection('statistics')
                    .doc(statisticsDocID)
                    .set({'statisticsDocumentIdMap': tempSerialInStatisticsMap},
                        SetOptions(merge: true));
              }
              clearingCurrentUserBillingTime();
            }
          } else {
            if (serialNumber == 0) {
              // ThisMeansThatTheDataHasNotReachedTheServer
              Map<String, dynamic> tempSerialInStatisticsMap = HashMap();
              tempSerialInStatisticsMap.addAll({
                orderHistoryDocID: {
                  Provider.of<PrinterAndOtherDetailsProvider>(context,
                          listen: false)
                      .currentUserPhoneNumberFromClass: FieldValue.delete()
                }
              });
              FirebaseFirestore.instance
                  .collection(widget.hotelName)
                  .doc('statistics')
                  .collection('statistics')
                  .doc(statisticsDocID)
                  .set({'statisticsDocumentIdMap': tempSerialInStatisticsMap},
                      SetOptions(merge: true));
            }
            clearingCurrentUserBillingTime();
          }
        } else {
          Map<String, dynamic> tempSerialInStatisticsMap = HashMap();
          tempSerialInStatisticsMap
              .addAll({orderHistoryDocID: FieldValue.delete()});
          FirebaseFirestore.instance
              .collection(widget.hotelName)
              .doc('statistics')
              .collection('statistics')
              .doc(statisticsDocID)
              .set({'statisticsDocumentIdMap': tempSerialInStatisticsMap},
                  SetOptions(merge: true));
        }
      } else {
        Map<String, dynamic> tableClosureCheckMap =
            baseInfoFromServerMap['billClosingPhoneOrderIdWithTime'];
        if (tableClosureCheckMap.isNotEmpty) {
          String keyPhoneNumberOfUserWhoClosedFirst = '';

          Timestamp firstTimeOfClosure = Timestamp.fromDate(DateTime(5000));
          tableClosureCheckMap.forEach((key, value) {
            if (value['timeOfClosure'] != null) {
              if ((firstTimeOfClosure.compareTo(value['timeOfClosure']) == 1) &&
                  value['endingOrderId'] == orderIdForCreatingDocId) {
//WeCheckWhetherEndIdAndStartOrderIdAreSameAlongWithLesserTime
//ThisIsToStopMixUpOfTables...
// ...WhereSlowNetPhoneAccidentallySendsOldEndOrderIdToNewOrder
                keyPhoneNumberOfUserWhoClosedFirst = key;
                firstTimeOfClosure = value['timeOfClosure'];
                print('timeOfClosure1');
                print(value['timeOfClosure']);
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

              if (!noItemsInTable) {
                Map<String, dynamic>? pastSavedDocument =
                    docIdCheckSnapshot.data();
                if (num.parse(
                        pastSavedDocument!['grandTotalForPrint'].toString()) >=
                    totalBillWithTaxes().round()) {
//ThisMeansThatTheOneInServerHasEitherMoreBillOrSameOrSameBillAsTheOneNow
//So,WeCanDeleteTheCurrentDocument

                  if (!noItemsInTable) {
//CheckToEnsureTableIsn'tClearedBySomeoneAndDefinitelyWeHaveToDeleteIt
                    orderHistoryDocID = '';
                    statisticsMap = {};

                    statisticsDocID = '';
                    serialNumber = 0;
                    toCheckPastOrderHistoryMap = {};

                    FireStoreDeleteFinishedOrderInRunningOrders(
                            hotelName: widget.hotelName,
                            eachTableId:
                                widget.itemsFromThisDocumentInFirebaseDoc)
                        .deleteFinishedOrder();
                    screenPopOutTimerAfterServerUpdate();
                  }
                } else {
//ThisMeansThisTableIsHigherThanLastTableAndHenceStatisticsNeedsRework
                  final splitOfItemNames =
                      pastSavedDocument['distinctItemsForPrint']
                          .toString()
                          .split('*');

                  final splitOfItemNumbers =
                      pastSavedDocument['numberOfEachDistinctItemForPrint']
                          .toString()
                          .split('*');

                  splitOfItemNames.removeLast();
                  splitOfItemNumbers.removeLast();
                  final splitOfExtraItemNames =
                      pastSavedDocument['extraItemsDistinctNames'] != null
                          ? pastSavedDocument['extraItemsDistinctNames']
                              .toString()
                              .split('*')
                          : [];

                  if (splitOfExtraItemNames.isNotEmpty) {
//ThisAlsoStartsWith*.SoWeNeedToRemoveFirstAndLast
                    splitOfExtraItemNames.removeAt(0);
                    splitOfExtraItemNames.removeLast();
                  }

                  final splitOfExtraItemsNumbers =
                      pastSavedDocument['extraItemsDistinctNumbers'] != null
                          ? pastSavedDocument['extraItemsDistinctNumbers']
                              .toString()
                              .split('*')
                          : [];
                  if (splitOfExtraItemsNumbers.isNotEmpty) {
                    splitOfExtraItemsNumbers.removeAt(0);
                    splitOfExtraItemsNumbers.removeLast();
                  }

                  for (var individualSplitItemName in splitOfItemNames) {
//FirstWeCheckWhetherSomeItemNeedsToBeTotallyRemovedFromStatistics...
// ...ThatWasAlreadyPutInTheOldOrderHistory
                    if (!toCheckPastOrderHistoryMap
                        .containsKey(individualSplitItemName)) {
//ThisMeansThereWasAnItemInOldMapButItIsntThereInNewMap
                      statisticsMap.addAll({
                        individualSplitItemName: FieldValue.increment(-1 *
                            (num.parse(splitOfItemNumbers[splitOfItemNames
                                .indexOf(individualSplitItemName)])))
                      });
                    }
                  }
                  if (splitOfExtraItemNames.isNotEmpty) {
                    for (var individualSplitExtraItemName
                        in splitOfExtraItemNames) {
                      if (!toCheckPastOrderHistoryMap
                          .containsKey(individualSplitExtraItemName)) {
//ThisMeansThereWasAnItemInOldMapButItIsntThereInNewMap
                        statisticsMap.addAll({
                          individualSplitExtraItemName: FieldValue.increment(
                              -1 *
                                  (num.parse(splitOfExtraItemsNumbers[
                                      splitOfExtraItemNames.indexOf(
                                          individualSplitExtraItemName)])))
                        });
                      }
                    }
                  }

                  toCheckPastOrderHistoryMap.forEach((key, value) {
//ThisMeansTheItemHasBeenAlreadyPutAsPartOfLastMapAndThusOnlyThe
//DifferenceBetweenTheLatestAndTheLastOneNeedsToBePut
                    if (splitOfItemNames.contains(key)) {
                      num lastOrderHistoryThisItemStat = num.parse(
                          splitOfItemNumbers[splitOfItemNames.indexOf(key)]);
                      statisticsMap[key] = FieldValue.increment(
                          value - lastOrderHistoryThisItemStat);
                    } else if (splitOfExtraItemNames.contains(key)) {
                      num lastOrderHistoryThisItemStat = num.parse(
                          splitOfExtraItemsNumbers[
                              splitOfExtraItemNames.indexOf(key)]);
                      statisticsMap[key] = FieldValue.increment(
                          value - lastOrderHistoryThisItemStat);
                    }
                  });
//WeNeedToCorrectTotalNumberOfOrdersAndDineInAndTakeAwayToo
                  statisticsMap['totalnumberoforders'] =
                      FieldValue.increment(0);
                  if (pastSavedDocument['takeAwayOrDineInForPrint']
                          .toString()
                          .contains('TAKE-AWAY') &&
                      thisIsParcelTrueElseFalse) {
//thisMeansThatAlreadyOneParcelHasBeenAdded.WeNeedNotAddAgain
                    statisticsMap['numberofparcel'] = FieldValue.increment(0);
                  } else if (pastSavedDocument['takeAwayOrDineInForPrint']
                          .toString()
                          .contains('TAKE-AWAY') &&
                      !thisIsParcelTrueElseFalse) {
//ThisMeansSomethingThatIsDineInHasBeenLastAddedAsParcel.WeNeedToReduceBy1
                    statisticsMap['numberofparcel'] = FieldValue.increment(-1);
                  }

//IncrementingOnlyTheDifferenceInDiscounts
                  statisticsMap.addAll({
                    'totaldiscount': FieldValue.increment(
                        discount - num.parse(pastSavedDocument['discount']))
                  });
//IncrementingOnlyTheDifferenceInTotalBill
                  statisticsMap.addAll({
                    'totalbillamounttoday': FieldValue.increment(
                        totalBillWithTaxes().round() -
                            num.parse(pastSavedDocument['grandTotalForPrint']))
                  });

////IfBillHadAlreadyBeenPrintedSerialNumberNeedNotBeAdded
////InTheLatestLogic,WeAreClosingSerialNumberOnlyAfter
////PaymentDoneIsClicked.So,WeDon'tHaveToDecrementSerialNumber...
//// ...AsPerBelowCommentedLogic
//                   if (num.parse(pastSavedDocument['serialNumberForPrint'].toString())
//                       .toInt() <
//                       serialNumber) {
// //ThisMeansWeHaveTakenNewSerialNumberAgain.SoWeReduceTheSerialNumber
//                     statisticsMap.addAll({'serialNumber': FieldValue.increment(-1)});
//                   } else {
//                     statisticsMap.addAll({'serialNumber': FieldValue.increment(0)});
//                   }

                  serialNumber = num.parse(
                          pastSavedDocument['serialNumberForPrint'].toString())
                      .toInt();
                  Map<String, dynamic> tempSerialInStatisticsMap = HashMap();
                  tempSerialInStatisticsMap
                      .addAll({orderHistoryDocID: FieldValue.delete()});
                  FirebaseFirestore.instance
                      .collection(widget.hotelName)
                      .doc('statistics')
                      .collection('statistics')
                      .doc(statisticsDocID)
                      .set({
                    'statisticsDocumentIdMap': tempSerialInStatisticsMap
                  }, SetOptions(merge: true));

//GivenThatThisIsCheckedWeCanGoAheadWithTheUpdate
                  if (!noItemsInTable) {
                    serverUpdateOfBillIfBillIdExistsInServer();
                  }
                }
              } else {
                Map<String, dynamic> tempSerialInStatisticsMap = HashMap();
                tempSerialInStatisticsMap
                    .addAll({orderHistoryDocID: FieldValue.delete()});
                FirebaseFirestore.instance
                    .collection(widget.hotelName)
                    .doc('statistics')
                    .collection('statistics')
                    .doc(statisticsDocID)
                    .set({'statisticsDocumentIdMap': tempSerialInStatisticsMap},
                        SetOptions(merge: true));
              }
            } else {
//ThisMeansSomebodyOtherThanThisUserIsClosingTheTable
              //ThisMeansThatTheDataHasReachedTheServer
              screenPopOutTimerAfterServerUpdate();
            }
          } else {
            if (serialNumber == 0) {
              // ThisMeansThatTheDataHasNotReachedTheServer
              Map<String, dynamic> tempSerialInStatisticsMap = HashMap();
              tempSerialInStatisticsMap.addAll({
                orderHistoryDocID: {
                  Provider.of<PrinterAndOtherDetailsProvider>(context,
                          listen: false)
                      .currentUserPhoneNumberFromClass: FieldValue.delete()
                }
              });
              FirebaseFirestore.instance
                  .collection(widget.hotelName)
                  .doc('statistics')
                  .collection('statistics')
                  .doc(statisticsDocID)
                  .set({'statisticsDocumentIdMap': tempSerialInStatisticsMap},
                      SetOptions(merge: true));
            }
            clearingCurrentUserBillingTime();
          }
        } else {
          if (serialNumber == 0) {
            // ThisMeansThatTheDataHasNotReachedTheServer
            Map<String, dynamic> tempSerialInStatisticsMap = HashMap();
            tempSerialInStatisticsMap.addAll({
              orderHistoryDocID: {
                Provider.of<PrinterAndOtherDetailsProvider>(context,
                        listen: false)
                    .currentUserPhoneNumberFromClass: FieldValue.delete()
              }
            });
            FirebaseFirestore.instance
                .collection(widget.hotelName)
                .doc('statistics')
                .collection('statistics')
                .doc(statisticsDocID)
                .set({'statisticsDocumentIdMap': tempSerialInStatisticsMap},
                    SetOptions(merge: true));
          }
          clearingCurrentUserBillingTime();
        }
      }
    } catch (e) {
      print('error correction');
      print(e.toString());
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
            .doc('statistics')
            .collection('statistics')
            .doc(statisticsDocID)
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
//
//   Future<void> functionToCloseTable() async {
// //ThisWillCheckWhetherTableCanBeClosedAndWillCloseItCompletely
//
//     try {
//       final docIdCheckSnapshot = await FirebaseFirestore.instance
//           .collection(widget.hotelName)
//           .doc('orderhistory')
//           .collection('orderhistory')
//           .doc(orderHistoryDocID)
//           .get()
//           .timeout(Duration(seconds: 5));
//
//       if (docIdCheckSnapshot == null || !docIdCheckSnapshot.exists) {
//         if (!noItemsInTable) {
//           serverUpdateOfBill();
//         }
//       } else {
//         if (!noItemsInTable) {
//           Map<String, dynamic>? pastSavedDocument = docIdCheckSnapshot.data();
//           if (num.parse(pastSavedDocument!['grandTotalForPrint'].toString()) >=
//               totalBillWithTaxes().round()) {
// //ThisMeansThatTheOneInServerHasEitherMoreBillOrSameOrSameBillAsTheOneNow
// //So,WeCanDeleteTheCurrentDocument
//
//             if (!noItemsInTable) {
// //CheckToEnsureTableIsn'tClearedBySomeoneAndDefinitelyWeHaveToDeleteIt
//               orderHistoryDocID = '';
//               statisticsMap = {};
//
//               statisticsDocID = '';
//               serialNumber = 0;
//               toCheckPastOrderHistoryMap = {};
//
//               FireStoreDeleteFinishedOrderInRunningOrders(
//                       hotelName: widget.hotelName,
//                       eachTableId: widget.itemsFromThisDocumentInFirebaseDoc)
//                   .deleteFinishedOrder();
//               screenPopOutTimerAfterServerUpdate();
//             }
//           } else {
// //ThisMeansThisTableIsHigherThanLastTableAndHenceStatisticsNeedsRework
//             final splitOfItemNames = pastSavedDocument['distinctItemsForPrint']
//                 .toString()
//                 .split('*');
//
//             final splitOfItemNumbers =
//                 pastSavedDocument['numberOfEachDistinctItemForPrint']
//                     .toString()
//                     .split('*');
//
//             splitOfItemNames.removeLast();
//             splitOfItemNumbers.removeLast();
//             final splitOfExtraItemNames =
//                 pastSavedDocument['extraItemsDistinctNames'] != null
//                     ? pastSavedDocument['extraItemsDistinctNames']
//                         .toString()
//                         .split('*')
//                     : [];
//
//             if (splitOfExtraItemNames.isNotEmpty) {
// //ThisAlsoStartsWith*.SoWeNeedToRemoveFirstAndLast
//               splitOfExtraItemNames.removeAt(0);
//               splitOfExtraItemNames.removeLast();
//             }
//
//             final splitOfExtraItemsNumbers =
//                 pastSavedDocument['extraItemsDistinctNumbers'] != null
//                     ? pastSavedDocument['extraItemsDistinctNumbers']
//                         .toString()
//                         .split('*')
//                     : [];
//             if (splitOfExtraItemsNumbers.isNotEmpty) {
//               splitOfExtraItemsNumbers.removeAt(0);
//               splitOfExtraItemsNumbers.removeLast();
//             }
//
//             for (var individualSplitItemName in splitOfItemNames) {
// //FirstWeCheckWhetherSomeItemNeedsToBeTotallyRemovedFromStatistics...
// // ...ThatWasAlreadyPutInTheOldOrderHistory
//               if (!toCheckPastOrderHistoryMap
//                   .containsKey(individualSplitItemName)) {
// //ThisMeansThereWasAnItemInOldMapButItIsntThereInNewMap
//                 statisticsMap.addAll({
//                   individualSplitItemName: FieldValue.increment(-1 *
//                       (num.parse(splitOfItemNumbers[
//                           splitOfItemNames.indexOf(individualSplitItemName)])))
//                 });
//               }
//             }
//             if (splitOfExtraItemNames.isNotEmpty) {
//               for (var individualSplitExtraItemName in splitOfExtraItemNames) {
//                 if (!toCheckPastOrderHistoryMap
//                     .containsKey(individualSplitExtraItemName)) {
// //ThisMeansThereWasAnItemInOldMapButItIsntThereInNewMap
//                   statisticsMap.addAll({
//                     individualSplitExtraItemName: FieldValue.increment(-1 *
//                         (num.parse(splitOfExtraItemsNumbers[
//                             splitOfExtraItemNames
//                                 .indexOf(individualSplitExtraItemName)])))
//                   });
//                 }
//               }
//             }
//
//             toCheckPastOrderHistoryMap.forEach((key, value) {
// //ThisMeansTheItemHasBeenAlreadyPutAsPartOfLastMapAndThusOnlyThe
// //DifferenceBetweenTheLatestAndTheLastOneNeedsToBePut
//               if (splitOfItemNames.contains(key)) {
//                 num lastOrderHistoryThisItemStat = num.parse(
//                     splitOfItemNumbers[splitOfItemNames.indexOf(key)]);
//                 statisticsMap[key] =
//                     FieldValue.increment(value - lastOrderHistoryThisItemStat);
//               } else if (splitOfExtraItemNames.contains(key)) {
//                 num lastOrderHistoryThisItemStat = num.parse(
//                     splitOfExtraItemsNumbers[
//                         splitOfExtraItemNames.indexOf(key)]);
//                 statisticsMap[key] =
//                     FieldValue.increment(value - lastOrderHistoryThisItemStat);
//               }
//             });
// //WeNeedToCorrectTotalNumberOfOrdersAndDineInAndTakeAwayToo
//             statisticsMap['totalnumberoforders'] = FieldValue.increment(0);
//             if (pastSavedDocument['takeAwayOrDineInForPrint']
//                     .toString()
//                     .contains('TAKE-AWAY') &&
//                 thisIsParcelTrueElseFalse) {
// //thisMeansThatAlreadyOneParcelHasBeenAdded.WeNeedNotAddAgain
//               statisticsMap['numberofparcel'] = FieldValue.increment(0);
//             } else if (pastSavedDocument['takeAwayOrDineInForPrint']
//                     .toString()
//                     .contains('TAKE-AWAY') &&
//                 !thisIsParcelTrueElseFalse) {
// //ThisMeansSomethingThatIsDineInHasBeenLastAddedAsParcel.WeNeedToReduceBy1
//               statisticsMap['numberofparcel'] = FieldValue.increment(-1);
//             }
//
// //IncrementingOnlyTheDifferenceInDiscounts
//             statisticsMap.addAll({
//               'totaldiscount': FieldValue.increment(
//                   discount - num.parse(pastSavedDocument['discount']))
//             });
// //IncrementingOnlyTheDifferenceInTotalBill
//             statisticsMap.addAll({
//               'totalbillamounttoday': FieldValue.increment(
//                   totalBillWithTaxes().round() -
//                       num.parse(pastSavedDocument['grandTotalForPrint']))
//             });
//
// //IfBillHadAlreadyBeenPrintedSerialNumberNeedNotBeAdded
//             if (num.parse(pastSavedDocument['serialNumberForPrint'].toString())
//                     .toInt() <
//                 serialNumber) {
// //ThisMeansWeHaveTakenNewSerialNumberAgain.SoWeReduceTheSerialNumber
//               statisticsMap.addAll({'serialNumber': FieldValue.increment(-1)});
//             } else {
//               statisticsMap.addAll({'serialNumber': FieldValue.increment(0)});
//             }
//
//             serialNumber =
//                 num.parse(pastSavedDocument['serialNumberForPrint'].toString())
//                     .toInt();
//
// //GivenThatThisIsCheckedWeCanGoAheadWithTheUpdate
//             if (!noItemsInTable) {
//               serverUpdateOfBillIfBillIdExistsInServer();
//             }
//           }
//         }
//       }
//     } catch (e) {
//       setState(() {
//         showSpinner = false;
//       });
//
//       show('Please Check Internet Connection and Try Again');
//
//       Map<String, dynamic> tempBaseInfoMap = HashMap();
//       tempBaseInfoMap.addAll({
//         'billClosingPhoneOrderIdWithTime': {
//           Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
//               .currentUserPhoneNumberFromClass: FieldValue.delete()
//         }
//       });
//
//       Map<String, dynamic> tempMasterMap = HashMap();
//       tempMasterMap.addAll({'baseInfoMap': tempBaseInfoMap});
//
//       FireStoreAddOrderInRunningOrderFolder(
//               hotelName: widget.hotelName,
//               seatingNumber: widget.itemsFromThisDocumentInFirebaseDoc,
//               ordersMap: tempMasterMap)
//           .addOrder();
//     }
//   }

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
      // billBytes += generator.text(
      //     "GRAND TOTAL: ${totalBillWithTaxesAsString()}",
      //     styles: PosStyles(
      //         height: PosTextSize.size1,
      //         width: PosTextSize.size1,
      //         align: PosAlign.right));
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

  void serverUpdateOfBill() async {
    if (serialNumber != 0) {
      statisticsMap.addAll({'totaldiscount': FieldValue.increment(discount)});
      statisticsMap.addAll({
        'totalbillamounttoday':
            FieldValue.increment(totalBillWithTaxes().round())
      });

//IfBillHadAlreadyBeenPrintedSerialNumberNeedNotBeAdded
      statisticsMap.addAll({'serialNumber': FieldValue.increment(1)});
      statisticsMap.addAll({
        'statisticsDocumentIdMap': {orderHistoryDocID: FieldValue.delete()}
      });

      //  print(widget.printOrdersMap);
      Map<String, String> updatePrintOrdersMap = HashMap();

      updatePrintOrdersMap = printOrdersMap;
      updatePrintOrdersMap
          .addAll({'serialNumberForPrint': serialNumber.toString()});
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
      if (json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .restaurantInfoDataFromClass)['cgst'] >
          0) {
        updatePrintOrdersMap.addAll({
          '989*CGST@${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['cgst']}%':
              (cgstCalculatedForBillFunction()).toString()
        });
      }
      if (json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
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
        numberOfEachDistinctItemForPrint =
            numberOfEachDistinctItemForPrint + '*';
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

      updatePrintOrdersMap.addAll(
          {'totalNumberOfItemsForPrint': '${distinctItemNames.length}'});
      updatePrintOrdersMap.addAll(
          {'billNumberForPrint': '${orderHistoryDocID.substring(0, 14)}'});
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
      updatePrintOrdersMap.addAll({
        'numberOfEachDistinctItemForPrint': numberOfEachDistinctItemForPrint
      });
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

      updatePrintOrdersMap.addAll(
          {'totalQuantityForPrint': totalQuantityOfAllItems.toString()});

      updatePrintOrdersMap.addAll(
          {'subTotalForPrint': (totalPriceOfAllItems - discount).toString()});
      updatePrintOrdersMap.addAll({
        'cgstPercentageForPrint': json
            .decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                    listen: false)
                .restaurantInfoDataFromClass)['cgst']
            .toString()
      });
      updatePrintOrdersMap.addAll({
        'cgstCalculatedForPrint': cgstCalculatedForBillFunction().toString()
      });
      updatePrintOrdersMap.addAll({
        'sgstPercentageForPrint': json
            .decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                    listen: false)
                .restaurantInfoDataFromClass)['cgst']
            .toString()
      });
      updatePrintOrdersMap.addAll({
        'sgstCalculatedForPrint': sgstCalculatedForBillFunction().toString()
      });
      updatePrintOrdersMap
          .addAll({'grandTotalForPrint': totalBillWithTaxesAsString()});
      if (billUpdatedInServer == false) {
        billUpdatedInServer = true;

        FireStoreUpdateAndStatisticsWithBatch(
                hotelName: widget.hotelName,
                orderHistoryDocID: orderHistoryDocID,
                printOrdersMap: updatePrintOrdersMap,
                statisticsDocID: statisticsDocID,
                statisticsUpdateMap: statisticsMap)
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
    } else {
      bool hasInternet = await InternetConnectionChecker().hasConnection;
      if (hasInternet) {
        Timer(Duration(seconds: 1), () {
          serverUpdateAfterSerialNumber();
        });
      } else {
        // ThisMeansThatTheDataHasNotReachedTheServer
        if (serialNumber == 0) {
          Map<String, dynamic> tempSerialInStatisticsMap = HashMap();
          tempSerialInStatisticsMap.addAll({
            orderHistoryDocID: {
              Provider.of<PrinterAndOtherDetailsProvider>(context,
                      listen: false)
                  .currentUserPhoneNumberFromClass: FieldValue.delete()
            }
          });
          FirebaseFirestore.instance
              .collection(widget.hotelName)
              .doc('statistics')
              .collection('statistics')
              .doc(statisticsDocID)
              .set({'statisticsDocumentIdMap': tempSerialInStatisticsMap},
                  SetOptions(merge: true));
        }
        setState(() {
          pageHasInternet = hasInternet;
          showSpinner = false;
        });
        show('You are Offline!\nPlease turn on Internet&Close bill');
      }
    }
    // int count = 0;
    // Navigator.of(context).popUntil((_) => count++ >= 2);
  }

  void serverUpdateOfBillIfBillIdExistsInServer() async {
    if (serialNumber != 0) {
      Map<String, String> updatePrintOrdersMap = HashMap();

      updatePrintOrdersMap = printOrdersMap;
      updatePrintOrdersMap
          .addAll({'serialNumberForPrint': serialNumber.toString()});
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
      if (json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .restaurantInfoDataFromClass)['cgst'] >
          0) {
        updatePrintOrdersMap.addAll({
          '989*CGST@${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['cgst']}%':
              (cgstCalculatedForBillFunction()).toString()
        });
      }
      if (json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
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
        numberOfEachDistinctItemForPrint =
            numberOfEachDistinctItemForPrint + '*';
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

      updatePrintOrdersMap.addAll(
          {'totalNumberOfItemsForPrint': '${distinctItemNames.length}'});
      updatePrintOrdersMap.addAll(
          {'billNumberForPrint': '${orderHistoryDocID.substring(0, 14)}'});
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
      updatePrintOrdersMap.addAll({
        'numberOfEachDistinctItemForPrint': numberOfEachDistinctItemForPrint
      });
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

      updatePrintOrdersMap.addAll(
          {'totalQuantityForPrint': totalQuantityOfAllItems.toString()});

      updatePrintOrdersMap.addAll(
          {'subTotalForPrint': (totalPriceOfAllItems - discount).toString()});
      updatePrintOrdersMap.addAll({
        'cgstPercentageForPrint': json
            .decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                    listen: false)
                .restaurantInfoDataFromClass)['cgst']
            .toString()
      });
      updatePrintOrdersMap.addAll({
        'cgstCalculatedForPrint': cgstCalculatedForBillFunction().toString()
      });
      updatePrintOrdersMap.addAll({
        'sgstPercentageForPrint': json
            .decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                    listen: false)
                .restaurantInfoDataFromClass)['cgst']
            .toString()
      });
      updatePrintOrdersMap.addAll({
        'sgstCalculatedForPrint': sgstCalculatedForBillFunction().toString()
      });
      updatePrintOrdersMap
          .addAll({'grandTotalForPrint': totalBillWithTaxesAsString()});

      statisticsMap.addAll({
        'statisticsDocumentIdMap': {orderHistoryDocID: FieldValue.delete()}
      });
      if (billUpdatedInServer == false) {
        billUpdatedInServer = true;

        FireStoreUpdateAndStatisticsWithBatchForAlreadyExistingBill(
                hotelName: widget.hotelName,
                orderHistoryDocID: orderHistoryDocID,
                printOrdersMap: updatePrintOrdersMap,
                statisticsDocID: statisticsDocID,
                statisticsUpdateMap: statisticsMap)
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
    } else {
      bool hasInternet = await InternetConnectionChecker().hasConnection;
      if (hasInternet) {
        serverUpdateAfterSerialNumber();
      } else {
        setState(() {
          pageHasInternet = hasInternet;
          showSpinner = false;
        });
        show('You are Offline!\nPlease turn on Internet&Close bill');
      }
    }
    // int count = 0;
    // Navigator.of(context).popUntil((_) => count++ >= 2);
  }

  void serialNumberStatisticsExistsOrNot() async {
    setState(() {
      showSpinner = true;
      tappedPrintButton = true;
    });
    bool hasInternet = await InternetConnectionChecker().hasConnection;
    if (hasInternet) {
      Map<String, dynamic>? statisticsData = {};
      try {
        final statisticsDataCheck = await FirebaseFirestore.instance
            .collection(widget.hotelName)
            .doc('statistics')
            .collection('statistics')
            .doc(statisticsDocID)
            .get()
            .timeout(Duration(seconds: 5));

        statisticsData = statisticsDataCheck.data();
        Map<String, dynamic> statisticsDocumentIdMap =
            statisticsData!['statisticsDocumentIdMap'];

        if (
            // !statisticsDocumentIdMap.containsKey(orderHistoryDocID) ||
            noItemsInTable) {
//ThisMeansThatTheDataHasReachedTheServer
          Map<String, dynamic> tempSerialInStatisticsMap = HashMap();
          tempSerialInStatisticsMap
              .addAll({orderHistoryDocID: FieldValue.delete()});
          FirebaseFirestore.instance
              .collection(widget.hotelName)
              .doc('statistics')
              .collection('statistics')
              .doc(statisticsDocID)
              .set({'statisticsDocumentIdMap': tempSerialInStatisticsMap},
                  SetOptions(merge: true));
          statisticsData.clear();
          statisticsDataCheck.data()!.clear();
          setState(() {
            showSpinner = true;
            tappedPrintButton = true;
          });
        } else {
          Map<String, dynamic> thisTableData =
              statisticsDocumentIdMap[orderHistoryDocID];
          // num timeThisTableWasBilled = 172800000;

          Timestamp timeThisTableWasBilled = Timestamp.fromDate(DateTime(5000));
          int numberOfOrdersBeforeThisTable = 0;
//GettingTheMinimumTimeAtWhichThisTableWasBilled
          thisTableData.forEach((key, value) {
            if (value['timeOfBilling'] != null) {
              if (timeThisTableWasBilled.compareTo(value['timeOfBilling']) ==
                  1) {
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

                // statisticsData = value.data();
                if (statisticsData == null ||
                    statisticsData!['serialNumber'] == null) {
                  serialNumber = 1 + numberOfOrdersBeforeThisTable;
                } else {
                  serialNumber =
                      num.parse((statisticsData!['serialNumber']).toString())
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
                statisticsData.clear();
                statisticsDataCheck.data()!.clear();

                serialNumberUpdateInServerWhenPrintClickedFirstTime();
                tappedPrintButton = false;
                startOfCallForPrintingBill();
              }
            } else if (serialNumber != 0 && !noItemsInTable) {
//ThisMeansWeRealisedSuddenlyWhenNetCameThatSerialNumberExists
//AndHenceCanStraightCall StartOfCallForPrintingBill
              startOfCallForPrintingBill();
              statisticsDataCheck.data()!.clear();
              statisticsData.clear();
            }
          } else {
            //ThisMeansThatTheDataHasNotReachedTheServer
            Map<String, dynamic> tempSerialInStatisticsMap = HashMap();
            tempSerialInStatisticsMap.addAll({
              orderHistoryDocID: {
                Provider.of<PrinterAndOtherDetailsProvider>(context,
                        listen: false)
                    .currentUserPhoneNumberFromClass: FieldValue.delete()
              }
            });
            FirebaseFirestore.instance
                .collection(widget.hotelName)
                .doc('statistics')
                .collection('statistics')
                .doc(statisticsDocID)
                .set({'statisticsDocumentIdMap': tempSerialInStatisticsMap},
                    SetOptions(merge: true));
            setState(() {
              pageHasInternet = hasInternet;
              showSpinner = false;
              tappedPrintButton = false;
            });
            show('Please check Internet & Reprint bill');
          }
        }
      } catch (e) {
        print('error Correction');
        print(e.toString());
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
            .doc('statistics')
            .collection('statistics')
            .doc(statisticsDocID)
            .set({'statisticsDocumentIdMap': tempSerialInStatisticsMap},
                SetOptions(merge: true));

        setState(() {
          pageHasInternet = hasInternet;
          showSpinner = false;
          tappedPrintButton = false;
        });
        show('Please check Internet & Reprint bill');
      }
    } else {
      //ThisMeansThatTheDataHasReachedTheServerLateAndWeNeedToDeleteIt
      Map<String, dynamic> tempSerialInStatisticsMap = HashMap();
      tempSerialInStatisticsMap.addAll({
        orderHistoryDocID: {
          Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .currentUserPhoneNumberFromClass: FieldValue.delete()
        }
      });
      FirebaseFirestore.instance
          .collection(widget.hotelName)
          .doc('statistics')
          .collection('statistics')
          .doc(statisticsDocID)
          .set({'statisticsDocumentIdMap': tempSerialInStatisticsMap},
              SetOptions(merge: true));
      setState(() {
        pageHasInternet = hasInternet;
        showSpinner = false;
        tappedPrintButton = false;
      });
      show('You are Offline!\nPlease turn on Internet&Reprint bill');
    }
  }

  Future<void> serverUpdateAfterSerialNumber() async {
    Map<String, dynamic>? statisticsData = {};
    try {
      final statisticsDataCheck = await FirebaseFirestore.instance
          .collection(widget.hotelName)
          .doc('statistics')
          .collection('statistics')
          .doc(statisticsDocID)
          .get()
          .timeout(Duration(seconds: 5));
      statisticsData = statisticsDataCheck.data();
      Map<String, dynamic> statisticsDocumentIdMap =
          statisticsData!['statisticsDocumentIdMap'];
      if (noItemsInTable) {
//ThisMeansThatTheDataHasReachedTheServer
        Map<String, dynamic> tempSerialInStatisticsMap = HashMap();
        tempSerialInStatisticsMap
            .addAll({orderHistoryDocID: FieldValue.delete()});
        FirebaseFirestore.instance
            .collection(widget.hotelName)
            .doc('statistics')
            .collection('statistics')
            .doc(statisticsDocID)
            .set({'statisticsDocumentIdMap': tempSerialInStatisticsMap},
                SetOptions(merge: true));
      } else {
        Map<String, dynamic> thisTableData =
            statisticsDocumentIdMap[orderHistoryDocID];
        Timestamp timeThisTableWasBilled = Timestamp.fromDate(DateTime(5000));
        int numberOfOrdersBeforeThisTable = 0;
//GettingTheMinimumTimeAtWhichThisTableWasBilled
        thisTableData.forEach((key, value) {
          if (value['timeOfBilling'] != null) {
            if (timeThisTableWasBilled.compareTo(value['timeOfBilling']) == 1) {
              print('timeOfBillingthisTable');
              print(value['timeOfBilling']);
              timeThisTableWasBilled = value['timeOfBilling'];
            }
          }
        });
        if (Timestamp.fromDate(DateTime(5000))
                .compareTo(timeThisTableWasBilled) ==
            1) {
//ThisMeansThereWasSomethingThatWasNotNullAndItWasRegistered
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
          if (serialNumber == 0 && !noItemsInTable) {
            if (gotSerialNumber == false) {
              gotSerialNumber = true;
              Map<String, dynamic>? statisticsData = statisticsDataCheck.data();

              if (statisticsData == null ||
                  statisticsData!['serialNumber'] == null) {
                serialNumber = 1 + numberOfOrdersBeforeThisTable;
              } else {
                serialNumber =
                    num.parse((statisticsData['serialNumber']).toString())
                            .toInt() +
                        1 +
                        numberOfOrdersBeforeThisTable;
              }
              statisticsData = {};
              statisticsDataCheck.data()!.clear();
              statisticsMap.addAll({'serialNumber': FieldValue.increment(1)});
              statisticsMap.addAll({
                'statisticsDocumentIdMap': {
                  orderHistoryDocID: FieldValue.delete()
                }
              });
              statisticsMap
                  .addAll({'totaldiscount': FieldValue.increment(discount)});
              statisticsMap.addAll({
                'totalbillamounttoday':
                    FieldValue.increment(totalBillWithTaxes().round())
              });

              //  print(widget.printOrdersMap);
              Map<String, String> updatePrintOrdersMap = HashMap();

              updatePrintOrdersMap = printOrdersMap;
              updatePrintOrdersMap
                  .addAll({'serialNumberForPrint': serialNumber.toString()});
//DoingThisToEnsure2ComesAfter1And10DoesntComeAfter1
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
//DoingThisToEnsureItComesInProperOrderInOrderHistory
              updatePrintOrdersMap[' Date of Order  :'] = dateOfOrderWithSerial;

              if (discount != 0) {
                if (discountValueClickedTruePercentageClickedFalse) {
                  updatePrintOrdersMap
                      .addAll({'981*Discount': discount.toString()});
                } else {
                  updatePrintOrdersMap.addAll({
                    '981*Discount $discountEnteredValue%': discount.toString()
                  });
                }
              }
              updatePrintOrdersMap.addAll(
                  {'985*Total': (totalPriceOfAllItems - discount).toString()});
              if (json.decode(Provider.of<PrinterAndOtherDetailsProvider>(
                          context,
                          listen: false)
                      .restaurantInfoDataFromClass)['cgst'] >
                  0) {
                updatePrintOrdersMap.addAll({
                  '989*CGST@${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['cgst']}%':
                      (cgstCalculatedForBillFunction()).toString()
                });
              }
              if (json.decode(Provider.of<PrinterAndOtherDetailsProvider>(
                          context,
                          listen: false)
                      .restaurantInfoDataFromClass)['sgst'] >
                  0) {
                updatePrintOrdersMap.addAll({
                  '993*SGST@${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).restaurantInfoDataFromClass)['sgst']}%':
                      (sgstCalculatedForBillFunction()).toString()
                });
              }
              updatePrintOrdersMap.addAll({'995*Round Off': roundOff()});
              updatePrintOrdersMap.addAll({'roundOff': roundOff()});
              updatePrintOrdersMap.addAll(
                  {'997*Total Bill With Taxes': totalBillWithTaxesAsString()});
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
                    numberOfEachDistinctItemForPrint +
                        numberOfEachItem.toString();
                numberOfEachDistinctItemForPrint =
                    numberOfEachDistinctItemForPrint + '*';
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
              updatePrintOrdersMap
                  .addAll({'customerNameForPrint': '$customername'});
              updatePrintOrdersMap.addAll(
                  {'customerMobileForPrint': '${customermobileNumber}'});
              updatePrintOrdersMap.addAll(
                  {'customerAddressForPrint': '${customeraddressline1}'});
              updatePrintOrdersMap.addAll({'dateForPrint': '${printingDate}'});

              updatePrintOrdersMap.addAll({
                'totalNumberOfItemsForPrint': '${distinctItemNames.length}'
              });
              updatePrintOrdersMap.addAll({
                'billNumberForPrint': '${orderHistoryDocID.substring(0, 14)}'
              });
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
              updatePrintOrdersMap.addAll({
                'numberOfEachDistinctItemForPrint':
                    numberOfEachDistinctItemForPrint
              });
              updatePrintOrdersMap.addAll({
                'priceOfEachDistinctItemWithoutTotalForPrint':
                    priceOfEachDistinctItemWithoutTotalForPrint
              });
              updatePrintOrdersMap.addAll({'discount': discount.toString()});
              updatePrintOrdersMap.addAll(
                  {'discountEnteredValue': discountEnteredValue.toString()});
              updatePrintOrdersMap.addAll({
                'discountValueClickedTruePercentageClickedFalse':
                    discountValueClickedTruePercentageClickedFalse.toString()
              });

              updatePrintOrdersMap.addAll({
                'totalQuantityForPrint': totalQuantityOfAllItems.toString()
              });

              updatePrintOrdersMap.addAll({
                'subTotalForPrint': (totalPriceOfAllItems - discount).toString()
              });
              updatePrintOrdersMap.addAll({
                'cgstPercentageForPrint': json
                    .decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                            listen: false)
                        .restaurantInfoDataFromClass)['cgst']
                    .toString()
              });
              updatePrintOrdersMap.addAll({
                'cgstCalculatedForPrint':
                    cgstCalculatedForBillFunction().toString()
              });
              updatePrintOrdersMap.addAll({
                'sgstPercentageForPrint': json
                    .decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                            listen: false)
                        .restaurantInfoDataFromClass)['sgst']
                    .toString()
              });
              updatePrintOrdersMap.addAll({
                'sgstCalculatedForPrint':
                    sgstCalculatedForBillFunction().toString()
              });
              updatePrintOrdersMap
                  .addAll({'grandTotalForPrint': totalBillWithTaxesAsString()});
              if (billUpdatedInServer == false) {
                billUpdatedInServer = true;
                FireStoreUpdateAndStatisticsWithBatch(
                        hotelName: widget.hotelName,
                        orderHistoryDocID: orderHistoryDocID,
                        printOrdersMap: updatePrintOrdersMap,
                        statisticsDocID: statisticsDocID,
                        statisticsUpdateMap: statisticsMap)
                    .updateBillAndStatistics();

                orderHistoryDocID = '';
                updatePrintOrdersMap = {};
                statisticsMap = {};
                statisticsDocID = '';
                serialNumber = 0;
                statisticsDataCheck.data()!.clear();
                statisticsData.clear();

                FireStoreDeleteFinishedOrderInRunningOrders(
                        hotelName: widget.hotelName,
                        eachTableId: widget.itemsFromThisDocumentInFirebaseDoc)
                    .deleteFinishedOrder();

//ToUpdateStatistics,WeGoThroughEachKeyAndUsingIncrementByFunction,We,,
//CanIncrementTheNumberThatIsAlreadyThereInTheServer
//ThisWillHelpToAddToTheStatisticsThat'sAlreadyThere

              }
              screenPopOutTimerAfterServerUpdate();
            }
          } else {
//ThisMeansThatWhenNetCameWeRealisedThereWasSerialNumber
            serverUpdateOfBill();
          }
        } else {
//ThisMeansNetIsn'tWorking
          // ThisMeansThatTheDataHasNotReachedTheServer
          if (serialNumber == 0) {
            Map<String, dynamic> tempSerialInStatisticsMap = HashMap();
            tempSerialInStatisticsMap.addAll({
              orderHistoryDocID: {
                Provider.of<PrinterAndOtherDetailsProvider>(context,
                        listen: false)
                    .currentUserPhoneNumberFromClass: FieldValue.delete()
              }
            });
            FirebaseFirestore.instance
                .collection(widget.hotelName)
                .doc('statistics')
                .collection('statistics')
                .doc(statisticsDocID)
                .set({'statisticsDocumentIdMap': tempSerialInStatisticsMap},
                    SetOptions(merge: true));
          }

          setState(() {
            showSpinner = false;
            tappedPrintButton = false;
          });
          show('Please check Internet & Close bill');
        }
      }
    } catch (e) {
      // ThisMeansThatTheDataHasNotReachedTheServer
      if (serialNumber == 0) {
        Map<String, dynamic> tempSerialInStatisticsMap = HashMap();
        tempSerialInStatisticsMap.addAll({
          orderHistoryDocID: {
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .currentUserPhoneNumberFromClass: FieldValue.delete()
          }
        });
        FirebaseFirestore.instance
            .collection(widget.hotelName)
            .doc('statistics')
            .collection('statistics')
            .doc(statisticsDocID)
            .set({'statisticsDocumentIdMap': tempSerialInStatisticsMap},
                SetOptions(merge: true));
      }
      setState(() {
        showSpinner = false;
        tappedPrintButton = false;
      });
      show('Please check Internet & Close bill');
    }
  }

  void serialNumberUpdateInServerWhenPrintClickedFirstTime() {
    Map<String, dynamic> tempBaseInfoMap = HashMap();
    tempBaseInfoMap.addAll({'serialNumber': serialNumber.toString()});
    tempBaseInfoMap.addAll({'billDay': tempDay.toString()});
    tempBaseInfoMap.addAll({'billHour': tempHour.toString()});
    tempBaseInfoMap.addAll({'billMinute': tempMinute.toString()});
    tempBaseInfoMap.addAll({'billMonth': tempMonth.toString()});
    tempBaseInfoMap.addAll({'billSecond': tempSecond.toString()});
    tempBaseInfoMap.addAll({'billYear': tempYear.toString()});

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
                                        Expanded(
                                          child: BottomButton(
                                            onTap: () async {
                                              if (showSpinner == false) {
                                                if (billUpdatedInServer ==
                                                        false &&
                                                    pageHasInternet) {
                                                  paymentDoneClicked = true;
                                                  setState(() {
                                                    showSpinner = true;
                                                  });

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
                                                            orderIdForCreatingDocId
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
                                                        .doc('statistics')
                                                        .collection(
                                                            'statistics')
                                                        .doc(statisticsDocID)
                                                        .set({
                                                      'statisticsDocumentIdMap':
                                                          tempSerialInStatisticsMap
                                                    }, SetOptions(merge: true));
                                                  }
                                                }
                                              }
                                            },
                                            buttonTitle: 'Payment Done',
                                            buttonColor: Colors.green,
                                            // buttonWidth: double.infinity,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Provider.of<PrinterAndOtherDetailsProvider>(
                                                        context,
                                                        listen: false)
                                                    .billingAssignedPrinterFromClass ==
                                                '{}'
                                            ? Expanded(
//IfNoPrinterAddressWeWillSayWeNeedThePrinterSetUpScreen
                                                child: BottomButton(
                                                  onTap: () async {
                                                    if (showSpinner == false) {
                                                      Navigator.pushReplacement(
                                                          context,
                                                          MaterialPageRoute(
                                                              builder: (context) =>
                                                                  PrinterRolesAssigning()));
                                                    }
                                                  },
                                                  buttonTitle: 'Assign Printer',
                                                  buttonColor: Colors.red,
                                                  // buttonWidth: double.infinity,
                                                ),
                                              )
                                            : Expanded(
                                                child: BottomButton(
                                                  onTap: () async {
                                                    if (showSpinner == false) {
                                                      //ThisWayYouCan'tPrintAgainOnceBillHasBeenUpdatedInServer
//                               bluetoothPrint.state.listen((state) {
                                                      // print('state is $state');

                                                      if (tappedPrintButton ==
                                                              false &&
                                                          pageHasInternet) {
                                                        if (serialNumber != 0) {
                                                          startOfCallForPrintingBill();
                                                        } else {
                                                          Map<String, dynamic>
                                                              tempSerialInStatisticsMap =
                                                              HashMap();
                                                          tempSerialInStatisticsMap
                                                              .addAll({
                                                            orderHistoryDocID: {
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
                                                              .doc('statistics')
                                                              .collection(
                                                                  'statistics')
                                                              .doc(
                                                                  statisticsDocID)
                                                              .set(
                                                                  {
                                                                'statisticsDocumentIdMap':
                                                                    tempSerialInStatisticsMap
                                                              },
                                                                  SetOptions(
                                                                      merge:
                                                                          true));
                                                          setState(() {
                                                            showSpinner = true;
                                                          });

                                                          Timer(
                                                              Duration(
                                                                  seconds: 1),
                                                              () {
                                                            serialNumberStatisticsExistsOrNot();
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
                'Order Date: $tempDay-$tempMonth-$tempYear',
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
          SizedBox(height: 100)
        ],
      ),
    );
  }
}
