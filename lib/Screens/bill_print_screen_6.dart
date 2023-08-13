//BluetoothPrinterScreenWithNewBluetoothPackage

import 'dart:async';
import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:orders_dev/Methods/bottom_button.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:orders_dev/Screens/printer_settings_screen.dart';
import 'package:orders_dev/Screens/searching_Connecting_Printer_Screen.dart';
import 'package:orders_dev/constants.dart';
import 'package:orders_dev/services/firestore_services.dart';
import 'package:provider/provider.dart';
import 'package:modal_progress_hud_alt/modal_progress_hud_alt.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:orders_dev/Methods/printerenum.dart' as printerenum;

class BillPrintWithSerialNumber extends StatefulWidget {
  final String hotelName;
  final String addedItemsSet;
  final List<String> itemsID;
  final String itemsFromThisDocumentInFirebaseDoc;
  final num cgstPercentage;
  final num sgstPercentage;
  final String hotelNameForPrint;
  final String addressLine1ForPrint;
  final String addressLine2ForPrint;
  final String addressLine3ForPrint;
  final String phoneNumberForPrint;
  final String gstCodeForPrint;

  const BillPrintWithSerialNumber({
    Key? key,
    required this.hotelName,
    required this.addedItemsSet,
    required this.itemsID,
    required this.itemsFromThisDocumentInFirebaseDoc,
    required this.cgstPercentage,
    required this.sgstPercentage,
    required this.hotelNameForPrint,
    required this.addressLine1ForPrint,
    required this.addressLine2ForPrint,
    required this.addressLine3ForPrint,
    required this.phoneNumberForPrint,
    required this.gstCodeForPrint,
  }) : super(key: key);

  @override
  State<BillPrintWithSerialNumber> createState() =>
      _BillPrintWithSerialNumberState();
}

class _BillPrintWithSerialNumberState extends State<BillPrintWithSerialNumber> {
  bool _connected = false;
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  List<BluetoothDevice> _devices = [];
  List<BluetoothDevice> additionalDevices = [];
  BluetoothDevice? _device;
  int _everySecondForConnection = 0;
  //InCase,DeviceNotConnectingInFirstAttempt,WeCanTryThis
  bool disconnectAndConnectAttempted = false;
  String tips = 'no device connect';

  //makingSharedPreferencesFirstInstance
  //ThePrinterStringsWeNeedForSavingAndGettingDetails
  //BelowOneIsForSharedPreferences
  // late Future<String> _connectedPrinterSaving;

  //BoolToSwitchOn/OffThePrinterConnectionScreen
//   bool noNeedPrinterConnectionScreen = true;
// //BoolToSwitchOn/OffThePrinterSettingsScreen
//   bool noNeedprinterSettings = true;
  //VariableToMarkBluetoothIsConnectedOrNotToPrinter
  bool bluetoothConnected = false;
  bool bluetoothAlreadyConnected = false;
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
  bool printingOver = false;
  int _timerWorkingCheck = 0;
  bool printingError = false;
  String customername = '';
  String customermobileNumber = '';
  String customeraddressline1 = '';
  String tempYear = '';
  String tempMonth = '';
  String tempDay = '';
  String tempHour = '';
  String tempMinute = '';
  String tempSecond = '';
  List<Map<String, dynamic>> items = [];
  List<String> distinctItemNames = [];
  List<num> individualPriceOfOneDistinctItem = [];
  List<num> numberOfOneDistinctItem = [];
  List<num> totalPriceOfOneDistinctItem = [];
  num totalPriceOfAllItems = 0;
  num totalQuantityOfAllItems = 0;
  Map<String, num> statisticsMap = HashMap();
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

  Widget discountsSection() {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                // width: double.infinity,
                child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          discountValueClickedTruePercentageClickedFalse
                              ? MaterialStateProperty.all(Colors.grey)
                              : MaterialStateProperty.all(Colors.green),
                    ),
                    onPressed: () {
                      setState(() {
                        discountValueClickedTruePercentageClickedFalse = false;
                        discountEnteredValue = '';
                        _controller.clear();
                      });
                      Navigator.pop(context);
                      showModalBottomSheet(
                          isScrollControlled: true,
                          context: context,
                          builder: (context) {
                            return discountsSection();
                          });
                    },
                    child: Text('Discount Percentage')),
              ),
              SizedBox(width: 10),
              Expanded(
                  // width: double.infinity,
                  child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor:
                            discountValueClickedTruePercentageClickedFalse
                                ? MaterialStateProperty.all(Colors.green)
                                : MaterialStateProperty.all(Colors.grey),
                      ),
                      onPressed: () {
                        setState(() {
                          discountValueClickedTruePercentageClickedFalse = true;
                          discountEnteredValue = '';
                          _controller.clear();
                        });
                        Navigator.pop(context);
                        showModalBottomSheet(
                            isScrollControlled: true,
                            context: context,
                            builder: (context) {
                              return discountsSection();
                            });
                      },
                      child: Text('Discount Value'))),
            ],
          ),
          Container(
            padding: EdgeInsets.all(20),
            child: TextField(
              maxLength: 250,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              controller: _controller,
              // controller:
              // TextEditingController(text: widget.itemsAddedComment[item]),
              onChanged: (value) {
                discountEnteredValue = value;
              },
              decoration:
                  // kTextFieldInputDecoration,
                  InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: discountValueClickedTruePercentageClickedFalse
                          ? 'Enter ₹'
                          : 'Enter %',
                      hintStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(color: Colors.green)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(color: Colors.green))),
            ),
          ),
          ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
              ),
              onPressed: () {
                setState(() {
                  if (discountValueClickedTruePercentageClickedFalse) {
                    setState(() {
                      if (discountEnteredValue != '') {
                        discount = num.parse(discountEnteredValue);
                      } else {
                        discount = 0;
                      }
                    });
                  } else {
                    setState(() {
                      if (discountEnteredValue != '') {
                        discount = num.parse((totalPriceOfAllItems *
                                (num.parse(discountEnteredValue) / 100))
                            .toStringAsFixed(2));
                      } else {
                        discount = 0;
                      }
                    });
                  }
                });
                Navigator.pop(context);
              },
              child: Text('Done'))
        ],
      ),
    );
  }

  @override
  void initState() {
//InitiallyWeWantThisAllToBeFalse
    bluetoothConnected = false;
    bluetoothAlreadyConnected = false;
    disconnectAndConnectAttempted = false;
    showSpinner = false;
    printingOver = true;
    tappedPrintButton = false;
    printingError = false;
    print('inside initState');
    items = [];
    distinctItemNames = [];
    serialNumber = 0;
    // TODO: implement initState

    makingDistinctItemsList();
    requestLocationPermission();
    internetAvailabilityChecker();

    super.initState();
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
    DateTime now = DateTime.now();
//WeEnsureWeTakeTheMonth,Day,Hour,MinuteAsString
//ifItIsLessThan10,WeSaveItWithZeroInTheFront
//ThisWillEnsure,ItIsAlwaysIn2Digits,AndWithoutPuttingItInTwoDigits,,
//ItWon'tComeInAscendingOrder
    String tempYear = now.year.toString();
    String tempMonth =
        now.month < 10 ? '0${now.month.toString()}' : '${now.month.toString()}';
    String tempDay =
        now.day < 10 ? '0${now.day.toString()}' : '${now.day.toString()}';
    String tempHour =
        now.hour < 10 ? '0${now.hour.toString()}' : '${now.hour.toString()}';
    String tempMinute = now.minute < 10
        ? '0${now.minute.toString()}'
        : '${now.minute.toString()}';
    String tempSecond = now.second < 10
        ? '0${now.second.toString()}'
        : '${now.second.toString()}';

    orderHistoryDocID =
        '${tempYear}${tempMonth}${tempDay}${tempHour}${tempMinute}${tempSecond}';
    statisticsDocID = '$tempYear*$tempMonth*$tempDay';
    printingDate =
        '${tempDay}/${tempMonth}/${tempYear} at ${tempHour}:${tempMinute}';
    //InThePrintOrdersMap(HashMap),FirstWeSaveKeyAs "DateOfOrder"&ValueAs,,
//year/Month/Day At Hour:Minute
    printOrdersMap.addAll({
      ' Date of Order  :':
          '$tempYear/$tempMonth/$tempDay at $tempHour:$tempMinute'
    });
//thisWillHelpForTakingOneParticularDay'sOrdersAloneInTheFuture
    printOrdersMap.addAll({'statisticsDocID': statisticsDocID});

    Map<String, dynamic> mapToAddIntoItems = {};
    String eachItemFromEntireItemsString = '';
    String splitCheck = widget.addedItemsSet;
    final setSplit = splitCheck.split('*');
    setSplit.removeLast();
    tableorparcel = setSplit[0];

    if (setSplit[0] == 'Parcel') {
      statisticsMap.addAll({'numberofparcel': 1});
      statisticsMap.addAll({'totalnumberoforders': 1});
    } else {
//ElseIfItIsTable,WeAddParcelNumbers0&TotalNumberOfOrdersAdd1InStatisticsMap
      statisticsMap.addAll({'numberofparcel': 0});
      statisticsMap.addAll({'totalnumberoforders': 1});
    }
    tableorparcelnumber = num.parse(setSplit[1]);
    num timecustomercametoseat = num.parse(setSplit[2]);
    num ticketNumber = num.parse(setSplit[3]);
    if (setSplit[4] != 'customername') {
      customername = setSplit[4];
    }
    if (setSplit[5] != 'customermobileNumber') {
      customermobileNumber = setSplit[5];
    }
    if (setSplit[6] != 'customeraddressline1') {
      customeraddressline1 = setSplit[6];
    }
    if (setSplit[7] != 'parent') {
      parentOrChild = setSplit[7];
    }

    if (setSplit[8] != 'noSerialYet' && setSplit[8] != 'futureUse') {
      serialNumber = num.parse(setSplit[8]).toInt();
    }

    for (int i = 0; i < setSplit.length; i++) {
//thisWillEnsureWeSwitchedFromTableInfoToOrderInfo
      if ((i) > 14) {
        if ((i + 1) % 15 == 1) {
          mapToAddIntoItems = {};
          eachItemFromEntireItemsString = '';
          mapToAddIntoItems['tableorparcel'] = tableorparcel;
          mapToAddIntoItems['parentOrChild'] = parentOrChild;
          mapToAddIntoItems['tableorparcelnumber'] = tableorparcelnumber;
          mapToAddIntoItems['timecustomercametoseat'] = timecustomercametoseat;
          // widget.itemsID.add(setSplit[i]);
          mapToAddIntoItems['eachiteminorderid'] = setSplit[i];
          eachItemFromEntireItemsString += '${setSplit[i]}*';
        }
        if ((i + 1) % 15 == 2) {
          // widget.itemsName.add(setSplit[i]);
          if (!distinctItemNames.contains(setSplit[i])) {
            distinctItemNames.add(setSplit[i]);
          }
          mapToAddIntoItems['item'] = setSplit[i];
          eachItemFromEntireItemsString += '${setSplit[i]}*';
        }
        if ((i + 1) % 15 == 3) {
          // widget.itemsEachPrice.add(num.parse(setSplit[i]));
          mapToAddIntoItems['priceofeach'] = num.parse(setSplit[i]);
          eachItemFromEntireItemsString += '${setSplit[i]}*';
        }
        if ((i + 1) % 15 == 4) {
          // widget.itemsNumber.add(int.parse(setSplit[i]));
          mapToAddIntoItems['number'] = num.parse(setSplit[i]);
          totalQuantityOfAllItems += num.parse(setSplit[i]);
          eachItemFromEntireItemsString += '${setSplit[i]}*';
        }

        if ((i + 1) % 15 == 5) {
          mapToAddIntoItems['timeoforder'] = num.parse(setSplit[i]);
          eachItemFromEntireItemsString += '${setSplit[i]}*';
        }
        if ((i + 1) % 15 == 6) {
          // widget.itemsStatus.add(int.parse(setSplit[i]));
          mapToAddIntoItems['statusoforder'] = num.parse(setSplit[i]);
          // localItemsStatus.add(num.parse(setSplit[i]));
          eachItemFromEntireItemsString += '${setSplit[i]}*';
        }
        if ((i + 1) % 15 == 7) {
          mapToAddIntoItems['commentsForTheItem'] = setSplit[i];
          eachItemFromEntireItemsString += '${setSplit[i]}*';
        }
        if ((i + 1) % 15 == 8) {
          mapToAddIntoItems['chefKotStatus'] = setSplit[i];
          eachItemFromEntireItemsString += '${setSplit[i]}*';
        }
        if ((i + 1) % 15 == 9) {
          mapToAddIntoItems['ticketNumber'] = setSplit[i];
          mapToAddIntoItems['itemBelongsToDoc'] =
              widget.itemsFromThisDocumentInFirebaseDoc;
          mapToAddIntoItems['entireItemListBeforeSplitting'] = splitCheck;
          eachItemFromEntireItemsString = eachItemFromEntireItemsString +
              setSplit[i] +
              "*" +
              "futureUse*futureUse*futureUse*futureUse*futureUse*futureUse*";
          mapToAddIntoItems['eachItemFromEntireItemsString'] =
              eachItemFromEntireItemsString;
          items.add(mapToAddIntoItems);
        }
      }
    }
    // List<String> distinctItemNames=[];
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
        statisticsMap.addAll(
            {distinctItemName: numberOfEachDistinctItemForAddingIntoList});
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
    // printOrdersMap.addAll({'Total = ': (totalPriceOfAllItems.toString())});

    // cgstCalculatedForBillFunction();
    // sgstCalculatedForBillFunction();
  }

  num totalPriceAfterDiscountOfBill() {
    // totalPriceAfterDiscount= totalPriceOfAllItems - discount;
    return totalPriceOfAllItems - discount;
  }

  num cgstCalculatedForBillFunction() {
    // setState(() {
    if (discount == 0) {
      return num.parse((totalPriceOfAllItems * (widget.cgstPercentage / 100))
          .toStringAsFixed(2));
    } else {
      // cgstCalculatedForBill =
      //     (totalPriceOfAllItems - discount) * (widget.cgstPercentage / 100);

      return num.parse(
          ((totalPriceOfAllItems - discount) * (widget.cgstPercentage / 100))
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
      return num.parse((totalPriceOfAllItems * (widget.sgstPercentage / 100))
          .toStringAsFixed(2));
    } else {
      return num.parse(
          ((totalPriceOfAllItems - discount) * (widget.sgstPercentage / 100))
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

  //InBillWeNeedTheTotalNumberOfAllItemsTogether-SayAppam2,Dosa2MeansTotal4
  // String totalQuantity() {
  //   num totalOfTotalNumber = 0;
  //   for (int i = 0; i < widget.numberOfEachDistinctItem.length; i++) {
  //     totalOfTotalNumber =
  //         totalOfTotalNumber + widget.numberOfEachDistinctItem[i];
  //   }
  //   return totalOfTotalNumber.toString();
  // }

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

  void getAllPairedDevices() async {
    print('start of getAllPairedDevices');
    _devices = await bluetooth.getBondedDevices();
    if (_devices.isEmpty) {
      print('at the start paired devices is empty');
    } else {
      print('at the start paired devices is not empty');
    }
    additionalDevices = [];
    print('paired devices is not empty');
    _devices.forEach((printer) {
      print('address is ${printer.address}');
      additionalDevices.add(printer);
    });
//PuttingSetStateHereBecauseThePairedDevicesListIsComingEmptyAtTheStart
//SoTryingToUpdatePairedDevicesAsAndWhenItIsAdded
    setState(() {
      additionalDevices = _devices;
    });

    if (_devices.isEmpty) {
      print('at the end paired devices is empty');
    } else {
      print('at the end paired devices is not empty');
    }
    print('end of getAllPairedDevices');
  }

  void bluetoothStateChangeFunction() {
    bluetooth.onStateChanged().listen((state) {
      print('inside bluetoothStateChangeFunction');
      switch (state) {
        case BlueThermalPrinter.CONNECTED:
          setState(() {
            _connected = true;
            bluetoothOnTrueOrOffFalse = true;
            print("bluetooth device state: connected");
          });
          break;
        case BlueThermalPrinter.DISCONNECTED:
          if (_connected) {
            setState(() {
              _connected = false;
              bluetoothOnTrueOrOffFalse = true;
              print('disconnecting bluetooth');
            });
            print("bluetooth device state: disconnected");
          }
          break;
        case BlueThermalPrinter.DISCONNECT_REQUESTED:
          setState(() {
            _connected = false;
            bluetoothOnTrueOrOffFalse = true;
            print("bluetooth device state: disconnect requested");
          });
          break;
        case BlueThermalPrinter.STATE_TURNING_OFF:
          setState(() {
            _connected = false;
            bluetoothOnTrueOrOffFalse = false;
            print("bluetooth device state: bluetooth turning off");
          });
          break;
        case BlueThermalPrinter.STATE_OFF:
          setState(() {
            _connected = false;
            bluetoothOnTrueOrOffFalse = false;
            print("bluetooth device state: bluetooth off");
          });
          break;
        case BlueThermalPrinter.STATE_ON:
          setState(() {
            _connected = false;
            bluetoothOnTrueOrOffFalse = true;
            print("bluetooth device state: bluetooth on");
          });
          break;
        case BlueThermalPrinter.STATE_TURNING_ON:
          setState(() {
            _connected = false;
            bluetoothOnTrueOrOffFalse = true;
            print("bluetooth device state: bluetooth turning on");
          });
          break;
        case BlueThermalPrinter.ERROR:
          setState(() {
            _connected = false;
            bluetoothOnTrueOrOffFalse = true;
            print("bluetooth device state: error");
          });
          break;
        default:
          print("bluetooth device state: ${state.toString()}");
          break;
      }
    });
    // print('isConnected is true');
  }

  void startOfCallForPrintingBill() {
    if (tappedPrintButton == false) {
      print('came with false');
      tappedPrintButton = true;

      if (_connected == false) {
        printerConnectionToLastSavedPrinter();
      } else if (_connected == true) {
        // printBill();
        printThroughBluetooth();
        // if (billUpdatedInServer == false) {
        //   serverUpdateOfBill();
        // }
      }
    }
  }

  Future<void> printerConnectionToLastSavedPrinter() async {
    if (bluetoothOnTrueOrOffFalse == false) {
      print('cameInsideTheLoopprinterConnectionToLastSavedPrinter');
//ThisIfLoopWillEnsureWeDontCheckBluetoothOnOrOffAgainAndAgain
      bluetoothStateChangeFunction();
    }
    print('printerConnectionToLastSavedPrinter');
    // TODO here add a permission request using permission_handler
    // if (locationPermissionAccepted == false) {
    //   showDialog(
    //     context: context,
    //     builder: (BuildContext context) => AlertDialog(
    //       elevation: 24.0,
    //       // backgroundColor: Colors.greenAccent,
    //       // shape: CircleBorder(),
    //       title: Text('Permission for Location Use'),
    //       content: Text(
    //           'Orders App collects location data only to enable bluetooth printer. This information will not be used when the app is closed or not in use. Kindly allow location access when prompted'),
    //       actions: [
    //         TextButton(
    //             onPressed: () {
    //               Permission.locationWhenInUse.request();
    //               // Navigator.of(context, rootNavigator: true)
    //               //     .pop();
    //               Navigator.pop(context);
    //               print('came till this pop1');
    //               // Navigator.pop(context);
    //               // print('came till this pop2');
    //               Timer? _timer;
    //               int _everySecondInRequestPermissionLoop = 0;
    //               _timer = Timer.periodic(Duration(seconds: 1),
    //                       (_) async {
    //                     if (_everySecondInRequestPermissionLoop < 2) {
    //                       print(
    //                           'duration is $_everySecondInRequestPermissionLoop');
    //                       _everySecondInRequestPermissionLoop++;
    //                     } else {
    //                       _timer?.cancel();
    //                       print('came inside timer cancel loop1111');
    //                       setState(() {
    //                         locationPermissionAccepted = true;
    //                         // Permission.location.request();
    //                       });
    //                       // savedBluetoothPrinterConnect();
    //                       if (connectingPrinterAddressChefScreen !=
    //                           '') {
    //                         printerConnectionToLastSavedPrinter();
    //                       } else {
    //                         setState(() {
    //                           noNeedPrinterConnectionScreen = false;
    //                         });
    //                       }
    //                     }
    //                   });
    //             },
    //             child: Text('Ok'))
    //       ],
    //     ),
    //     barrierDismissible: false,
    //   );
    // }

    // if permission is not granted, kzaki's thermal print plugin will ask for location permission
    // which will invariably crash the app even if user agrees so we'd better ask it upfront

    // var statusLocation = Permission.location;
    // if (await statusLocation.isGranted != true) {
    //   await Permission.location.request();
    // }
    // if (await statusLocation.isGranted) {
    // ...
    // } else {
    // showDialogSayingThatThisPermissionIsRequired());
    // }
    if (bluetoothOnTrueOrOffFalse) {
      getAllPairedDevices();
      if (showSpinner == false) {
        setState(() {
          showSpinner = true;
        });
      }

      bool? isConnected = await bluetooth.isConnected;
      print(
          'printerConnectionToLastSavedPrinter start is connected value is $isConnected');
      bool printerPairedTrueYetToPairFalse = false;
      int devicesCount = 0;
      for (var device in _devices) {
        ++devicesCount;
        print('checking device addresses');
        if (device.address ==
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .captainPrinterAddressFromClass) {
          printerPairedTrueYetToPairFalse = true;
          print('checking for printer saved');
          var nowConnectingPrinter = device;
          _connect(nowConnectingPrinter);
        }
        if (devicesCount == _devices.length &&
            printerPairedTrueYetToPairFalse == false) {
          setState(() {
            printingOver = true;
            showSpinner = false;
            print('8 $tappedPrintButton');

            tappedPrintButton = false;
            print('9 $tappedPrintButton');
          });
          show('Couldn\'t Connect. Please check Printer');
        }
      }
    } else {
      show('Please Turn On Bluetooth');
    }

    // Timer? _timer;
    // int _everySecondForConnection = 0;
    // _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
    //   if (_everySecondForConnection <= 2) {
    //     print('timer printing time is $_everySecondForConnection');
    //     _everySecondForConnection++;
    //   } else {
    //     _timer?.cancel();
    //     _everySecondForConnection = 0;
    //     bluetooth.onStateChanged().listen((state) {
    //       print('inside state listen');
    //       switch (state) {
    //         case BlueThermalPrinter.CONNECTED:
    //           setState(() {
    //             _connected = true;
    //             printThroughBluetooth();
    //             print("bluetooth device state: connected");
    //           });
    //           break;
    //         case BlueThermalPrinter.DISCONNECTED:
    //           setState(() {
    //             _connected = false;
    //             print("bluetooth device state: disconnected");
    //           });
    //           break;
    //         case BlueThermalPrinter.DISCONNECT_REQUESTED:
    //           setState(() {
    //             _connected = false;
    //             print("bluetooth device state: disconnect requested");
    //           });
    //           break;
    //         case BlueThermalPrinter.STATE_TURNING_OFF:
    //           setState(() {
    //             _connected = false;
    //             print("bluetooth device state: bluetooth turning off");
    //           });
    //           break;
    //         case BlueThermalPrinter.STATE_OFF:
    //           setState(() {
    //             _connected = false;
    //             print("bluetooth device state: bluetooth off");
    //           });
    //           break;
    //         case BlueThermalPrinter.STATE_ON:
    //           setState(() {
    //             _connected = false;
    //             print("bluetooth device state: bluetooth on");
    //           });
    //           break;
    //         case BlueThermalPrinter.STATE_TURNING_ON:
    //           setState(() {
    //             _connected = false;
    //             print("bluetooth device state: bluetooth turning on");
    //           });
    //           break;
    //         case BlueThermalPrinter.ERROR:
    //           setState(() {
    //             _connected = false;
    //             print("bluetooth device state: error");
    //           });
    //           break;
    //         default:
    //           print(state);
    //           break;
    //       }
    //     });
    //   }
    // });

    if (!mounted) return;
    // setState(() {
    //   _devices = devices;
    // });

    // if (isConnected == true) {
    //   printThroughBluetooth();
    //   setState(() {
    //     _connected = true;
    //   });
    // }
  }

  void _connect(BluetoothDevice nowConnectingPrinter) {
    printingError = false;
    print('start of _Connect loop');
    if (nowConnectingPrinter != null) {
      print('device isnt null');

      bluetooth.isConnected.then((isConnected) {
        if (isConnected == false) {
          bluetooth.connect(nowConnectingPrinter!).catchError((error) {
            show('Couldn\'t Connect. Please check Printer');
            setState(() {
              printingError = true;
              _connected = false;
              showSpinner = false;
              printingOver = true;
              print('1 $tappedPrintButton');

              tappedPrintButton = false;
              print('2 $tappedPrintButton');
            });
            print('did not get connected2 inside _connect- ${_connected}');
          });
          setState(() => _connected = true);
          print('we are connected inside _connect- ${_connected}');
          intermediateFunctionToCallPrintThroughBluetooth();
        } else {
          print('need a dosconnection here1');

          int _everySecondHelpingToDisconnectBeforeConnectingAgain = 0;
          bluetooth.disconnect();
          setState(() => _connected = false);
          _everySecondForConnection = 0;

          if (disconnectAndConnectAttempted) {
            printingOver = true;
            print('need a dosconnection here2');
            setState(() {
              showSpinner = false;
              print('4 $tappedPrintButton');

              tappedPrintButton = false;
              print('5 $tappedPrintButton');
            });
          } else {
            print('need a dosconnection here3');
            Timer? _timerInDisconnectAndConnect;
            _timerInDisconnectAndConnect =
                Timer.periodic(const Duration(seconds: 1), (_) async {
              if (_everySecondHelpingToDisconnectBeforeConnectingAgain < 4) {
                _timerWorkingCheck++;
                print('timerWorkingCheck id $_timerWorkingCheck');
                _everySecondHelpingToDisconnectBeforeConnectingAgain++;
                print(
                    '_everySecondHelpingToDisconnectBeforeConnectingAgainInBillScreen $_everySecondHelpingToDisconnectBeforeConnectingAgain');
              } else {
                print('need a dosconnection here4');
                _timerInDisconnectAndConnect!.cancel;
                print('need a dosconnection here4');
                if (disconnectAndConnectAttempted == false) {
                  disconnectAndConnectAttempted = true;
                  printerConnectionToLastSavedPrinter();
                } else {
                  _timerInDisconnectAndConnect!.cancel();
                }
                _everySecondHelpingToDisconnectBeforeConnectingAgain = 0;
                printerConnectionToLastSavedPrinter();
                print(
                    'cancelling _everySecondHelpingToDisconnectBeforeConnectingAgain $_everySecondHelpingToDisconnectBeforeConnectingAgain');
                _timerWorkingCheck++;
                print('timerWorkingCheck id $_timerWorkingCheck');
              }
            });
          }
        }
      });
    } else {
      print('No device selected.');
    }
    print('end of _Connect loop');

    // bluetooth.onStateChanged().listen((state) {
    //   print('inside state listen');
    //   switch (state) {
    //     case BlueThermalPrinter.CONNECTED:
    //       setState(() {
    //         _connected = true;
    //         printThroughBluetooth();
    //         print("bluetooth device state: connected");
    //       });
    //       break;
    //     case BlueThermalPrinter.DISCONNECTED:
    //       setState(() {
    //         _connected = false;
    //         print("bluetooth device state: disconnected");
    //       });
    //       break;
    //     case BlueThermalPrinter.DISCONNECT_REQUESTED:
    //       setState(() {
    //         _connected = false;
    //         print("bluetooth device state: disconnect requested");
    //       });
    //       break;
    //     case BlueThermalPrinter.STATE_TURNING_OFF:
    //       setState(() {
    //         _connected = false;
    //         print("bluetooth device state: bluetooth turning off");
    //       });
    //       break;
    //     case BlueThermalPrinter.STATE_OFF:
    //       setState(() {
    //         _connected = false;
    //         print("bluetooth device state: bluetooth off");
    //       });
    //       break;
    //     case BlueThermalPrinter.STATE_ON:
    //       setState(() {
    //         _connected = false;
    //         print("bluetooth device state: bluetooth on");
    //       });
    //       break;
    //     case BlueThermalPrinter.STATE_TURNING_ON:
    //       setState(() {
    //         _connected = false;
    //         print("bluetooth device state: bluetooth turning on");
    //       });
    //       break;
    //     case BlueThermalPrinter.ERROR:
    //       setState(() {
    //         _connected = false;
    //         print("bluetooth device state: error");
    //       });
    //       break;
    //     default:
    //       print(state);
    //       break;
    //   }
    // });
  }

  void intermediateFunctionToCallPrintThroughBluetooth() {
    if (showSpinner == false) {
      setState(() {
        showSpinner = true;
      });
    }

    print('start of intermediateFunctionToCallPrintThroughBluetooth');
    Timer? _timer;
    _everySecondForConnection = 0;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_everySecondForConnection <= 3) {
        print('timer inside connect is $_everySecondForConnection');
        _everySecondForConnection++;
      } else {
        _timer!.cancel();
        if (_connected) {
          print('Inside intermediate- it is connected');
          // if (billUpdatedInServer == false) {
          //   serverUpdateOfBill();
          // }
          printThroughBluetooth();
        } else {
          printingOver = true;
          setState(() {
            showSpinner = false;
            print('6 $tappedPrintButton');

            tappedPrintButton = false;
            print('7 $tappedPrintButton');
          });
          print('unable to connect');
          // bluetooth.disconnect();
          // show('Couldnt Connect. Please check Printer');
        }
      }
    });
    print('end of intermediateFunctionToCallPrintThroughBluetooth');
  }

  void printThroughBluetooth() {
    Timer? _timerInPrintThroughBluetooth;
    int _everySecondPrintThroughBluetooth = 0;
    _timerInPrintThroughBluetooth =
        Timer.periodic(Duration(seconds: 1), (_) async {
      if (_everySecondPrintThroughBluetooth < 1) {
        _everySecondPrintThroughBluetooth++;
        print(
            '_everySecondPrintThroughBluetooth $_everySecondPrintThroughBluetooth');
      } else {
        _timerInPrintThroughBluetooth!.cancel();
        _everySecondPrintThroughBluetooth = 0;
        bluetoothDisconnectFunction();
      }
    });
    if (showSpinner == false) {
      setState(() {
        showSpinner = true;
      });
    }

    print('start of inside printThroughBluetooth');
    if (_connected) {
      bluetooth.isConnected.then((isConnected) {
//CurrentlyNotCaringWhether58mmOr80mm.WillChangeLater

        if (isConnected == true) {
          print('inside printThroughBluetooth-is connected is true here');
          // bluetooth.printNewLine();
          // if (localParcelReadyItemNames[0] != 'Printer Check') {
          //   bluetooth.printCustom(
          //       "Packed:${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year} at ${DateTime.now().hour}:${DateTime.now().minute}",
          //       printerenum.Size.medium.val,
          //       printerenum.Align.center.val);
          //   bluetooth.printNewLine();
          //   bluetooth.printNewLine();
          // }
          // if (localParcelReadyItemNames.length > 1) {
          if (Provider.of<PrinterAndOtherDetailsProvider>(context,
                      listen: false)
                  .captainPrinterSizeFromClass ==
              '80') {
            bluetooth.printCustom("${widget.hotelNameForPrint}",
                printerenum.Size.extraLarge.val, printerenum.Align.center.val);
            if (widget.addressLine1ForPrint != '') {
              bluetooth.printCustom("${widget.addressLine1ForPrint}",
                  printerenum.Size.medium.val, printerenum.Align.center.val);
            }
            if (widget.addressLine2ForPrint != '') {
              bluetooth.printCustom("${widget.addressLine2ForPrint}",
                  printerenum.Size.medium.val, printerenum.Align.center.val);
            }
            if (widget.addressLine3ForPrint != '') {
              bluetooth.printCustom("${widget.addressLine3ForPrint}",
                  printerenum.Size.medium.val, printerenum.Align.center.val);
            }
            if (widget.gstCodeForPrint != '') {
              bluetooth.printCustom("GSTIN: ${widget.gstCodeForPrint}",
                  printerenum.Size.bold.val, printerenum.Align.center.val);
            }
            if (widget.phoneNumberForPrint != '') {
              bluetooth.printCustom("PH: ${widget.phoneNumberForPrint}",
                  printerenum.Size.bold.val, printerenum.Align.center.val);
            }
            bluetooth.printCustom(
                "-----------------------------------------------",
                printerenum.Size.bold.val,
                printerenum.Align.center.val);

            if (widget.cgstPercentage > 0) {
              bluetooth.printCustom("TAX INVOICE", printerenum.Size.bold.val,
                  printerenum.Align.center.val);
            }
            bluetooth.printNewLine();
            // bluetooth.printNewLine();
            bluetooth.printCustom("ORDER DATE:${printingDate}",
                printerenum.Size.bold.val, printerenum.Align.center.val);
            bluetooth.printCustom(
                "-----------------------------------------------",
                printerenum.Size.bold.val,
                printerenum.Align.center.val);
            if (customername != '' || customermobileNumber != '') {
              String customerPrintingName =
                  customername != '' ? 'Customer: ${customername}' : '';
              String customerPrintingMobile = customermobileNumber != ''
                  ? 'Phone: ${customermobileNumber}'
                  : '';
              if (customername != '') {
                bluetooth.printCustom("$customerPrintingName",
                    printerenum.Size.medium.val, printerenum.Align.left.val);
              }
              if (customermobileNumber != '') {
                bluetooth.printCustom("$customerPrintingMobile",
                    printerenum.Size.medium.val, printerenum.Align.left.val);
              }
            }
            if (customeraddressline1 != '') {
              bluetooth.printCustom("Address: ${customeraddressline1}",
                  printerenum.Size.medium.val, printerenum.Align.left.val);
            }
            if (customername != '' ||
                customermobileNumber != '' ||
                customeraddressline1 != '') {
              bluetooth.printCustom(
                  "-----------------------------------------------",
                  printerenum.Size.bold.val,
                  printerenum.Align.center.val);
            }
            // bluetooth.printCustom(
            //     "TOTAL NO. OF ITEMS:${widget.distinctItems.length}    Qty:${totalQuantity()}",
            //     printerenum.Size.medium.val,
            //     printerenum.Align.left.val);
            bluetooth.printLeftRight(
                "TOTAL NO. OF ITEMS:${distinctItemNames.length}",
                "Qty:$totalQuantityOfAllItems",
                printerenum.Size.medium.val,
                format: "%-20s %20s %n");
            // bluetooth.printCustom("BILL NO: ${widget.orderHistoryDocID}",
            //     printerenum.Size.medium.val, printerenum.Align.left.val);
            if (statisticsMap['numberofparcel']! > 0) {
              bluetooth.printLeftRight(
                  "BILL NO:${orderHistoryDocID}",
                  "TYPE:TAKE-AWAY:${tableorparcel}:${tableorparcelnumber}${parentOrChild}",
                  printerenum.Size.bold.val,
                  format: "%-20s %20s %n");
              // bluetooth.printCustom("TYPE: TAKE-AWAY",
              //     printerenum.Size.medium.val, printerenum.Align.left.val);
            } else {
              bluetooth.printLeftRight(
                  "BILL NO:${orderHistoryDocID}",
                  "TYPE:DINE-IN:${tableorparcel}:${tableorparcelnumber}${parentOrChild}",
                  printerenum.Size.bold.val,
                  format: "%-20s %20s %n");
              // bluetooth.printCustom("TYPE: DINE-IN",
              //     printerenum.Size.medium.val, printerenum.Align.left.val);
            }
            bluetooth.printCustom(" Sl.No: ${serialNumber.toString()}",
                printerenum.Size.boldLarge.val, printerenum.Align.left.val);
            // bluetooth.printLeftRight(
            //     "   ",
            //     "Slot: ${tableorparcel}:${tableorparcelnumber}",
            //     printerenum.Size.medium.val,
            //     format: "%-20s %20s %n");
            bluetooth.printCustom(
                "-----------------------------------------------",
                printerenum.Size.bold.val,
                printerenum.Align.center.val);
            bluetooth.print4Column("Item Name", "Price", "Qty", "Amount",
                printerenum.Size.bold.val,
                format: "%-20s %7s %7s %10s %n");
            bluetooth.printCustom(
                "-----------------------------------------------",
                printerenum.Size.bold.val,
                printerenum.Align.center.val);
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
                bluetooth.print4Column(
                    "$firstName",
                    "${individualPriceOfOneDistinctItem[i]}",
                    "${numberOfOneDistinctItem[i]}",
                    "${totalPriceOfOneDistinctItem[i]}",
                    printerenum.Size.bold.val,
                    format: "%-20s %7s %7s %7s %n");
                bluetooth.print4Column(
                    "  $secondName", " ", " ", " ", printerenum.Size.bold.val,
                    format: "%-20s %7s %7s %7s %n");
                if (thirdName != '') {
                  bluetooth.print4Column(
                      "  $thirdName", " ", " ", " ", printerenum.Size.bold.val,
                      format: "%-20s %7s %7s %7s %n");
                }
              } else {
                bluetooth.print4Column(
                    "${distinctItemNames[i]}",
                    "${individualPriceOfOneDistinctItem[i]}",
                    "${numberOfOneDistinctItem[i]}",
                    "${totalPriceOfOneDistinctItem[i]}",
                    printerenum.Size.bold.val,
                    format: "%-20s %7s %7s %7s %n");
              }
            }
            bluetooth.printCustom(
                "-----------------------------------------------",
                printerenum.Size.bold.val,
                printerenum.Align.center.val);
            if (discount != 0) {
              if (discountValueClickedTruePercentageClickedFalse) {
                bluetooth.printCustom("Discount : ${discount}    ",
                    printerenum.Size.bold.val, printerenum.Align.right.val);
              } else {
                bluetooth.printCustom(
                    "Discount ${discountEnteredValue}% : ${discount}    ",
                    printerenum.Size.bold.val,
                    printerenum.Align.right.val);
              }

              bluetooth.printCustom(
                  "-----------------------------------------------",
                  printerenum.Size.bold.val,
                  printerenum.Align.center.val);
            }
            if (widget.cgstPercentage > 0) {
              // bluetooth.printCustom(
              //     "Sub-Total : ${totalPriceOfAllItems - discount}",
              //     printerenum.Size.medium.val,
              //     printerenum.Align.right.val);
              // bluetooth.printLeftRight(
              //     "                            Sub-Total :",
              //     "${totalPriceOfAllItems - discount}        ",
              //     printerenum.Size.bold.val);
              bluetooth.printCustom(
                  "Sub-Total: ${totalPriceOfAllItems - discount}    ",
                  printerenum.Size.bold.val,
                  printerenum.Align.right.val);
            }
            if (widget.cgstPercentage > 0) {
              bluetooth.printCustom(
                  "CGST @ ${widget.cgstPercentage}%: ${cgstCalculatedForBillFunction()}   ",
                  printerenum.Size.bold.val,
                  printerenum.Align.right.val);
            }
            if (widget.sgstPercentage > 0) {
              bluetooth.printCustom(
                  "SGST @ ${widget.sgstPercentage}%: ${sgstCalculatedForBillFunction()}   ",
                  printerenum.Size.bold.val,
                  printerenum.Align.right.val);

              bluetooth.printCustom(
                  "-----------------------------------------------",
                  printerenum.Size.bold.val,
                  printerenum.Align.center.val);
            } else {
              bluetooth.printNewLine();
            }
            if (roundOff() != '0') {
              bluetooth.printCustom("Round Off: ${roundOff()}",
                  printerenum.Size.bold.val, printerenum.Align.right.val);
            }

            bluetooth.printCustom(
                "GRAND TOTAL: ${totalBillWithTaxesAsString()}",
                printerenum.Size.boldLarge.val,
                printerenum.Align.right.val);
          } else if (Provider.of<PrinterAndOtherDetailsProvider>(context,
                      listen: false)
                  .captainPrinterSizeFromClass ==
              '58') {
            bluetooth.printCustom("${widget.hotelNameForPrint}",
                printerenum.Size.extraLarge.val, printerenum.Align.center.val);
            if (widget.addressLine1ForPrint != '') {
              bluetooth.printCustom("${widget.addressLine1ForPrint}",
                  printerenum.Size.medium.val, printerenum.Align.center.val);
            }
            if (widget.addressLine2ForPrint != '') {
              bluetooth.printCustom("${widget.addressLine2ForPrint}",
                  printerenum.Size.medium.val, printerenum.Align.center.val);
            }
            if (widget.addressLine3ForPrint != '') {
              bluetooth.printCustom("${widget.addressLine3ForPrint}",
                  printerenum.Size.medium.val, printerenum.Align.center.val);
            }
            if (widget.gstCodeForPrint != '') {
              bluetooth.printCustom("GSTIN: ${widget.gstCodeForPrint}",
                  printerenum.Size.bold.val, printerenum.Align.center.val);
            }
            if (widget.phoneNumberForPrint != '') {
              bluetooth.printCustom("PH: ${widget.phoneNumberForPrint}",
                  printerenum.Size.bold.val, printerenum.Align.center.val);
            }
            bluetooth.printCustom("-------------------------------",
                printerenum.Size.medium.val, printerenum.Align.center.val);
            if (widget.cgstPercentage > 0) {
              bluetooth.printCustom("TAX INVOICE", printerenum.Size.bold.val,
                  printerenum.Align.center.val);
            }
            // bluetooth.printNewLine();
            // bluetooth.printNewLine();
            bluetooth.printCustom(
                "ORDER DATE: ${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year} at ${DateTime.now().hour}:${DateTime.now().minute} ",
                printerenum.Size.medium.val,
                printerenum.Align.center.val);
            bluetooth.printCustom("-------------------------------",
                printerenum.Size.medium.val, printerenum.Align.center.val);
            if (customername != '' || customermobileNumber != '') {
              String customerPrintingName =
                  customername != '' ? 'Customer: ${customername}' : '';
              String customerPrintingMobile = customermobileNumber != ''
                  ? 'Phone: ${customermobileNumber}'
                  : '';
              if (customername != '') {
                bluetooth.printCustom("$customerPrintingName",
                    printerenum.Size.medium.val, printerenum.Align.left.val);
              }
              if (customermobileNumber != '') {
                bluetooth.printCustom("$customerPrintingMobile",
                    printerenum.Size.medium.val, printerenum.Align.left.val);
              }
            }
            if (customeraddressline1 != '') {
              bluetooth.printCustom("Address: ${customeraddressline1}",
                  printerenum.Size.medium.val, printerenum.Align.left.val);
            }
            if (customername != '' ||
                customermobileNumber != '' ||
                customeraddressline1 != '') {
              bluetooth.printCustom("-------------------------------",
                  printerenum.Size.medium.val, printerenum.Align.center.val);
            }

            // if (widget.customermobileNumber != '') {
            //   bluetooth.printCustom("${widget.customermobileNumber}",
            //       printerenum.Size.medium.val, printerenum.Align.center.val);
            // }
            bluetooth.printNewLine();
            bluetooth.printCustom(
                "TOTAL NO. OF ITEMS:${distinctItemNames.length}    Qty:$totalQuantityOfAllItems",
                printerenum.Size.medium.val,
                printerenum.Align.left.val);
            bluetooth.printCustom("BILL NO: ${orderHistoryDocID}",
                printerenum.Size.medium.val, printerenum.Align.left.val);
            if (statisticsMap['numberofparcel']! > 0) {
              bluetooth.printCustom(
                  "TYPE: TAKE-AWAY : ${tableorparcel}:${tableorparcelnumber}${parentOrChild}",
                  printerenum.Size.medium.val,
                  printerenum.Align.left.val);
            } else {
              bluetooth.printCustom(
                  "TYPE: DINE-IN : ${tableorparcel}:${tableorparcelnumber}${parentOrChild}",
                  printerenum.Size.medium.val,
                  printerenum.Align.left.val);
            }
            bluetooth.printCustom("Sl.No: ${serialNumber.toString()}",
                printerenum.Size.boldLarge.val, printerenum.Align.left.val);
            bluetooth.printCustom("-------------------------------",
                printerenum.Size.medium.val, printerenum.Align.center.val);
            bluetooth.printLeftRight(
                "Item Name", "Amount", printerenum.Size.medium.val);
            bluetooth.printCustom("-------------------------------",
                printerenum.Size.medium.val, printerenum.Align.center.val);

            for (int i = 0; i < distinctItemNames.length; i++) {
//ThisIsGood.CouldBePlanAorPlanB
//               bluetooth.print3Column(
//                   "${widget.distinctItems[i]}",
//                   "${widget.individualPriceOfEachDistinctItem[i]} x ${widget.numberOfEachDistinctItem[i]}",
//                   "${widget.priceOfEachDistinctItemWithoutTotal[i]}",
//                   printerenum.Size.medium.val,
//                   format: "%-20s %20s %14s %n");
//CouldBePlanB
              bluetooth.printCustom("${distinctItemNames[i]}",
                  printerenum.Size.medium.val, printerenum.Align.left.val);
              // bluetooth.printNewLine();
              bluetooth.printLeftRight(
                  "${individualPriceOfOneDistinctItem[i]} x ${numberOfOneDistinctItem[i]}",
                  "${totalPriceOfOneDistinctItem[i]}",
                  printerenum.Size.medium.val);
//CouldBePlanB
              // bluetooth.printCustom(
              //     "${widget.individualPriceOfEachDistinctItem[i]} x ${widget.numberOfEachDistinctItem[i]}                   ${widget.priceOfEachDistinctItemWithoutTotal[i]}",
              //     printerenum.Size.medium.val,
              //     printerenum.Align.right.val);
            }
            bluetooth.printCustom("-------------------------------",
                printerenum.Size.medium.val, printerenum.Align.center.val);
            // bluetooth.printCustom("TOTAL Qty: ${totalQuantity()}",
            //     printerenum.Size.medium.val, printerenum.Align.left.val);
            if (discount != 0) {
              if (discountValueClickedTruePercentageClickedFalse) {
                bluetooth.printCustom("Discount : ${discount} ",
                    printerenum.Size.medium.val, printerenum.Align.right.val);
              } else {
                bluetooth.printCustom(
                    "Discount ${discountEnteredValue}% : ${discount} ",
                    printerenum.Size.medium.val,
                    printerenum.Align.right.val);
              }

              bluetooth.printCustom("-------------------------------",
                  printerenum.Size.medium.val, printerenum.Align.center.val);
            }
            if (widget.cgstPercentage > 0) {
              bluetooth.printCustom(
                  "Sub-Total : ${totalPriceOfAllItems - discount}",
                  printerenum.Size.medium.val,
                  printerenum.Align.right.val);
              // bluetooth.printLeftRight(
              //     " ",
              //     "Sub-Total : ${widget.statisticsMap['totalbillamounttoday']}",
              //     printerenum.Size.medium.val,
              //     format: "%-5s %5s %n");
            }
            if (widget.cgstPercentage > 0) {
              bluetooth.printCustom(
                  "CGST @ ${widget.cgstPercentage}% : ${cgstCalculatedForBillFunction()}",
                  printerenum.Size.medium.val,
                  printerenum.Align.right.val);
              // bluetooth.printLeftRight(
              //     " ",
              //     "CGST @ ${widget.cgstPercentage}% : ${widget.cgstCalculated}",
              //     printerenum.Size.medium.val,
              //     format: "%-5s %5s %n");
            }
            if (widget.sgstPercentage > 0) {
              bluetooth.printCustom(
                  "SGST @ ${widget.sgstPercentage}% : ${sgstCalculatedForBillFunction()}",
                  printerenum.Size.medium.val,
                  printerenum.Align.right.val);
              // bluetooth.printLeftRight(
              //     " ",
              //     "SGST @ ${widget.sgstPercentage}% : ${widget.sgstCalculated}",
              //     printerenum.Size.medium.val,
              //     format: "%-5s %5s %n");
              bluetooth.printCustom("-------------------------------",
                  printerenum.Size.medium.val, printerenum.Align.center.val);
            } else {
              bluetooth.printNewLine();
            }
            if (roundOff() != '0') {
              bluetooth.printCustom("Round Off: ${roundOff()}",
                  printerenum.Size.medium.val, printerenum.Align.right.val);
            }
            bluetooth.printCustom(
                "GRAND TOTAL: ${totalBillWithTaxesAsString()}",
                printerenum.Size.boldLarge.val,
                printerenum.Align.right.val);
            // bluetooth.printLeftRight(
            //     " ",
            //     "GRAND TOTAL: ${widget.totalBillWithTaxes}",
            //     printerenum.Size.boldLarge.val,
            //     format: "%-5s %5s %n");
          }
          bluetooth.printNewLine();
          bluetooth.printCustom("Thank You!!! Visit Again!!!",
              printerenum.Size.bold.val, printerenum.Align.center.val);

          bluetooth.printNewLine();
          bluetooth.printNewLine();

          bluetooth
              .paperCut(); //some printer not supported (sometime making image not centered)
          //bluetooth.drawerPin2(); // or you can use bluetooth.drawerPin5();
        } else {
          printingOver = true;
          setState(() {
            showSpinner = false;

            tappedPrintButton = false;
            print('11 $tappedPrintButton');
          });
          // show('Couldnt Connect. Please check Printer');
        }
      });
    }
    // else {
    //   show('Couldnt Connect. Please check Printer');
    // }
    print('end of inside printThroughBluetooth');
  }

//FunctionToConnectToTheSavedBluetoothPrinter

  // void _disconnect() {
  //   Timer? _timer;
  //   int _everySecondForDisconnecting = 0;
  //   _everySecondForConnection = 0;
  //   _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
  //     if (_everySecondForDisconnecting < 2) {
  //       print('timer disconnect is $_everySecondForDisconnecting');
  //       _everySecondForDisconnecting++;
  //     } else {
  //       printingOver = false;
  //       bluetooth.disconnect();
  //       disconnectAndConnectAttempted = false;
  //       _timer!.cancel();
  //       _everySecondForDisconnecting = 0;
  //       print('bluetooth is disconnecting');
  //       print('came to showspinner false');
  //       setState(() {
  //         showSpinner = false;
  //         _connected = false;
  //       });
  //     }
  //   });
  // }

//FunctionToConnectToTheSavedBluetoothPrinter
//   Future<void> savedBluetoothPrinterConnect() async {
//     setState(() {
//       showSpinner = true;
//     });
//     bluetoothConnected = false;
//     bluetoothPrint.startScan(timeout: Duration(seconds: 7));
//     int confirmingPrinter = 0;
//     if (bluetoothConnected == false) {
//       bluetoothPrint.scanResults.listen((devices) async {
// //ThisIsForConnectingTheLastConnectedPrinter
//         devices.forEach((printer) async {
//           if (bluetoothConnected == false) {
//             print(
//                 'connecting printer address is $connectingPrinterAddressBillPrintScreen');
//             print('checking printer address is ${printer.address.toString()}');
//             if ((connectingPrinterAddressBillPrintScreen ==
//                     printer.address.toString()) &&
//                 (bluetoothConnected == false)) {
//               confirmingPrinter++;
//               if (confirmingPrinter > 1) {
//                 confirmingPrinter = 0;
//                 var nowConnectingPrinterInBillScreen = printer;
//                 print('came inside thhis loop');
//                 bluetoothConnected = true;
//                 await bluetoothPrint.connect(nowConnectingPrinterInBillScreen);
//                 // bluetoothPrint.stopScan();
//               }
//
//               // setState(() {
//               //   bluetoothConnected = true;
//               //   noNeedPrinterConnectionScreen = true;
//               // });
//             }
//           }
//         });
//       });
//     }
//
//     Timer? _timer;
//     int _everySecondInSavedBluetoothLoop = 0;
//     _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
//       //ItWillCheckWhetherTheVariableEveryThirtySecondsIsLessThan121,,
// //ThenItWillBeIncrementedBy1AndItWillAlsoCallTheFunctionWhichWillCheck,,
// //ForNewOrdersInTheBackground
// //IfItIsMoreThan120,ThenForOneHourThereHasNotBeenAnyOrder
// //AndHenceWeCancelTheTimer
//
//       if (_everySecondInSavedBluetoothLoop < 4) {
//         print(
//             'timer_everySecondInSavedBluetoothLoop time is $_everySecondInSavedBluetoothLoop');
//         _everySecondInSavedBluetoothLoop++;
//       } else {
//         _timer?.cancel();
//         print(
//             'timer _everySecondInSavedBluetoothLooptime at point is $_everySecondInSavedBluetoothLoop');
//
//         if (bluetoothConnected) {
//           print('inside bluetooth connected');
//           noNeedPrinterConnectionScreen = true;
//           //bluetoothPrint.stopScan();
//           printBill();
//           serverUpdateOfBill();
//         } else {
//           setState(() {
//             print('nfgehsfbnjshfs');
//             _connected = false;
//             tips = 'not yet connected';
//             noNeedPrinterConnectionScreen = false;
//             bluetoothConnected = false;
//             showSpinner = false;
//           });
//
//           // bluetoothPrint.state.listen((state) {
//           //   print('******************* cur device status: $state');
//           //
//           //   switch (state) {
//           //     case BluetoothPrint.CONNECTED:
//           //       setState(() {
//           //         print('is it connected here>?ghfghfghf');
//           //         _connected = true;
//           //         tips = 'connect success';
//           //         noNeedPrinterConnectionScreen = true;
//           //         printReceipt();
//           //         serverUpdateOfBill();
//           //         bluetoothConnected = true;
//           //       });
//           //       break;
//           //     case BluetoothPrint.DISCONNECTED:
//           //       setState(() {
//           //         print('fbsdbf sndfbdhjsdbsakjdn');
//           //         _connected = false;
//           //         tips = 'yet to connect';
//           //         noNeedPrinterConnectionScreen = false;
//           //         bluetoothConnected = false;
//           //       });
//           //       break;
//           //     default:
//           //       setState(() {
//           //         print('nfgehsfbnjshfs');
//           //         _connected = false;
//           //         tips = 'not yet connected';
//           //         noNeedPrinterConnectionScreen = false;
//           //         bluetoothConnected = false;
//           //       });
//           //       break;
//           //   }
//           // });
//         }
//
//         if (!mounted) return;
//       }
//     });
//   }

  void bluetoothDisconnectFunction() async {
//AlteredForNewBluetoothDisconnectFunctionToo
    bool onceDisconnected = false;
    _everySecondForConnection = 0;
    Timer? _timer;
    int _everySecond = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      //ItWillCheckWhetherTheVariableEveryThirtySecondsIsLessThan121,,
//ThenItWillBeIncrementedBy1AndItWillAlsoCallTheFunctionWhichWillCheck,,
//ForNewOrdersInTheBackground
//IfItIsMoreThan120,ThenForOneHourThereHasNotBeenAnyOrder
//AndHenceWeCancelTheTimer

      if (_everySecond < 1) {
        print('timer disconnect1 is $_everySecond');
        _everySecond++;
      } else {
        _everySecond++;
        print('timer disconnect2 time at cance point is $_everySecond');
        if (onceDisconnected == false) {
          bluetoothConnected = false;
          printingOver = false;
          bluetooth.disconnect();
          // bluetoothPrint.destroy();
          onceDisconnected = true;

          print('inside cancel 1');
        }
        if (_everySecond >= 3) {
          _timer!.cancel();
          if (showSpinner) {
            setState(() {
              showSpinner = false;
              printingOver = true;
              _connected = false;
              bluetoothConnected = false;
              bluetoothOnTrueOrOffFalse = true;
              print('disconnecting bluetooth');

              tappedPrintButton = false;
              print('10 $tappedPrintButton');
            });
          }

          _everySecond = 0;
          // if (printingError == false) {
          //   int count = 0;
          //   Navigator.of(context).popUntil((_) => count++ >= 2);
          // }
        }

        print('done with disconnect');

        //toCloseTheAppInCaseTheAppIsn'tOpenedForAnHour

      }
    });
  }

//   void printBill() {
//     if (showSpinner == false) {
//       setState(() {
//         showSpinner = true;
//       });
//     }
//     Timer? _timer;
//     int _everySecondForConnection = 0;
//     _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
//       //ItWillCheckWhetherTheVariableEveryThirtySecondsIsLessThan121,,
// //ThenItWillBeIncrementedBy1AndItWillAlsoCallTheFunctionWhichWillCheck,,
// //ForNewOrdersInTheBackground
// //IfItIsMoreThan120,ThenForOneHourThereHasNotBeenAnyOrder
// //AndHenceWeCancelTheTimer
//
//       if (_everySecondForConnection < 4) {
//         print(
//             'timer everysecond for connection time is $_everySecondForConnection');
//         _everySecondForConnection++;
//       } else {
//         _timer?.cancel();
//         print(
//             'timer time at connect point is point is $_everySecondForConnection');
//         print('connected at bottom button is ${_connected}');
//         Map<String, dynamic> config = Map();
//         List<LineText> printList = [];
//         if (connectingPrinterSizeBillPrintScreen == '80') {
//           print('came inside 80mm loop');
//           printList.add(LineText(
//             type: LineText.TYPE_TEXT,
//             content: '${widget.hotelNameForPrint}',
//             weight: 1,
//             height: 1,
//             align: LineText.ALIGN_CENTER,
//             linefeed: 1,
//           ));
//           if (widget.addressLine1ForPrint != '') {
//             printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: '${widget.addressLine1ForPrint}',
//               weight: 1,
//               align: LineText.ALIGN_CENTER,
//               linefeed: 1,
//             ));
//           }
//           if (widget.addressLine2ForPrint != '') {
//             printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: '${widget.addressLine2ForPrint}',
//               weight: 1,
//               align: LineText.ALIGN_CENTER,
//               linefeed: 1,
//             ));
//           }
//           if (widget.addressLine3ForPrint != '') {
//             printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: '${widget.addressLine3ForPrint}',
//               weight: 1,
//               align: LineText.ALIGN_CENTER,
//               linefeed: 1,
//             ));
//           }
//           if (widget.phoneNumberForPrint != '') {
//             printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: '${widget.phoneNumberForPrint}',
//               weight: 1,
//               align: LineText.ALIGN_CENTER,
//               linefeed: 1,
//             ));
//           }
//           printList.add(LineText(linefeed: 1));
//           if (widget.cgstPercentage > 0) {
//             printList.add(
//               LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: 'TAX INVOICE',
//                 weight: 1,
//                 align: LineText.ALIGN_CENTER,
//                 linefeed: 1,
//                 //LineFeedIsGivenForLineBreaks
//               ),
//             );
//           }
//
//           // printList.add(
//           //   LineText(
//           //     type: LineText.TYPE_TEXT,
//           //     content: 'ORIGINAL',
//           //     weight: 1,
//           //     align: LineText.ALIGN_CENTER,
//           //     linefeed: 1,
//           //     //LineFeedIsGivenForLineBreaks
//           //   ),
//           // );
//
//           printList.add(
//             LineText(
//               type: LineText.TYPE_TEXT,
//               content:
//                   'ORDER DATE: ${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year} at ${DateTime.now().hour}:${DateTime.now().minute} ',
//               weight: 1,
//               align: LineText.ALIGN_CENTER,
//               linefeed: 1,
//               //LineFeedIsGivenForLineBreaks
//             ),
//           );
//           printList.add(LineText(linefeed: 1));
//           printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: 'TOTAL NO. OF ITEMS:',
//               weight: 1,
//               align: LineText.ALIGN_LEFT,
//               x: 0,
//               relativeX: 0,
//               linefeed: 0));
//           printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: '${widget.distinctItems.length}',
//               weight: 1,
//               // align: LineText.ALIGN_RIGHT,
//               align: LineText.ALIGN_LEFT,
//               x: 240,
//               relativeX: 0,
//               linefeed: 1));
//           printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: 'BILL NO: ${widget.orderHistoryDocID}',
//               weight: 1,
//               align: LineText.ALIGN_LEFT,
//               x: 0,
//               relativeX: 0,
//               linefeed: 0));
//           if (widget.statisticsMap['numberofparcel']! > 0) {
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: 'TYPE: TAKE-AWAY',
//                 weight: 1,
//                 align: LineText.ALIGN_LEFT,
//                 x: 350,
//                 relativeX: 0,
//                 linefeed: 1));
//           } else {
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: 'TYPE: DINE-IN',
//                 weight: 1,
//                 align: LineText.ALIGN_LEFT,
//                 x: 350,
//                 relativeX: 0,
//                 linefeed: 1));
//           }
//           printList.add(LineText(
//             type: LineText.TYPE_TEXT,
//             content: '------------------------------------------------',
//             weight: 1,
//             align: LineText.ALIGN_CENTER,
//             linefeed: 1,
//           ));
//           printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: 'ItemName',
//               weight: 1,
//               align: LineText.ALIGN_LEFT,
//               x: 5,
//               relativeX: 0,
//               linefeed: 0));
//           printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: 'Price',
//               weight: 1,
//               // align: LineText.ALIGN_RIGHT,
//               align: LineText.ALIGN_LEFT,
//               x: 320,
//               relativeX: 0,
//               linefeed: 0));
//           printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: 'Qty',
//               weight: 1,
//               // align: LineText.ALIGN_RIGHT,
//               align: LineText.ALIGN_LEFT,
//               x: 420,
//               relativeX: 0,
//               linefeed: 0));
//           printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: 'Amount',
//               weight: 1,
//               // align: LineText.ALIGN_RIGHT,
//               align: LineText.ALIGN_LEFT,
//               x: 500,
//               relativeX: 0,
//               linefeed: 1));
//           printList.add(LineText(
//             type: LineText.TYPE_TEXT,
//             content: '------------------------------------------------',
//             weight: 1,
//             align: LineText.ALIGN_CENTER,
//             linefeed: 1,
//           ));
//           for (int i = 0; i < widget.distinctItems.length; i++) {
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: '${widget.distinctItems[i]}',
//                 weight: 1,
//                 align: LineText.ALIGN_LEFT,
//                 x: 0,
//                 relativeX: 0,
//                 linefeed: 0));
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: '${widget.individualPriceOfEachDistinctItem[i]}',
//                 weight: 1,
//                 // align: LineText.ALIGN_RIGHT,
//                 align: LineText.ALIGN_LEFT,
//                 x: 340,
//                 relativeX: 0,
//                 linefeed: 0));
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: '${widget.numberOfEachDistinctItem[i]}',
//                 weight: 1,
//                 // align: LineText.ALIGN_RIGHT,
//                 align: LineText.ALIGN_LEFT,
//                 x: 430,
//                 relativeX: 0,
//                 linefeed: 0));
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: '${widget.priceOfEachDistinctItemWithoutTotal[i]}',
//                 weight: 1,
//                 // align: LineText.ALIGN_RIGHT,
//                 align: LineText.ALIGN_LEFT,
//                 x: 500,
//                 relativeX: 0,
//                 linefeed: 1));
//           }
//           printList.add(LineText(
//             type: LineText.TYPE_TEXT,
//             content: '------------------------------------------------',
//             weight: 1,
//             align: LineText.ALIGN_CENTER,
//             linefeed: 1,
//           ));
//           printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: 'TOTAL Qty :',
//               weight: 1,
//               align: LineText.ALIGN_LEFT,
//               x: 0,
//               relativeX: 0,
//               linefeed: 0));
//           printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: '${totalQuantity()}',
//               weight: 1,
//               // align: LineText.ALIGN_RIGHT,
//               align: LineText.ALIGN_LEFT,
//               x: 140,
//               relativeX: 0,
//               linefeed: 0));
//           if (widget.cgstPercentage > 0) {
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: 'Sub-Total :',
//                 weight: 1,
//                 // align: LineText.ALIGN_RIGHT,
//                 align: LineText.ALIGN_LEFT,
//                 x: 305,
//                 relativeX: 0,
//                 linefeed: 0));
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: '${widget.statisticsMap['totalbillamounttoday']}',
//                 weight: 1,
//                 // align: LineText.ALIGN_RIGHT,
//                 align: LineText.ALIGN_LEFT,
//                 x: 500,
//                 relativeX: 0,
//                 linefeed: 1));
//           }
//           if (widget.cgstPercentage > 0) {
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: 'CGST @ ${widget.cgstPercentage}% :',
//                 weight: 1,
//                 align: LineText.ALIGN_LEFT,
//                 x: 280,
//                 relativeX: 0,
//                 linefeed: 0));
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: '${widget.cgstCalculated}',
//                 weight: 1,
//                 // align: LineText.ALIGN_RIGHT,
//                 align: LineText.ALIGN_LEFT,
//                 x: 500,
//                 relativeX: 0,
//                 linefeed: 1));
//           }
//           if (widget.sgstPercentage > 0) {
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: 'SGST @ ${widget.sgstPercentage}% :',
//                 weight: 1,
//                 align: LineText.ALIGN_LEFT,
//                 x: 280,
//                 relativeX: 0,
//                 linefeed: 0));
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: '${widget.sgstCalculated}',
//                 weight: 1,
//                 // align: LineText.ALIGN_RIGHT,
//                 align: LineText.ALIGN_LEFT,
//                 x: 500,
//                 relativeX: 0,
//                 linefeed: 1));
//           } else {
//             printList.add(LineText(linefeed: 1));
//           }
//           printList.add(LineText(
//             type: LineText.TYPE_TEXT,
//             content: '------------------------------------------------',
//             weight: 1,
//             align: LineText.ALIGN_CENTER,
//             linefeed: 1,
//           ));
//           printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: 'GRAND TOTAL:',
//               weight: 1,
//               height: 2,
//               align: LineText.ALIGN_LEFT,
//               x: 250,
//               relativeX: 0,
//               linefeed: 0));
//           printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: '${widget.totalBillWithTaxes}',
//               weight: 1,
//               height: 2,
//               // align: LineText.ALIGN_RIGHT,
//               align: LineText.ALIGN_LEFT,
//               x: 480,
//               relativeX: 0,
//               linefeed: 1));
//
//           printList.add(LineText(linefeed: 1));
//           printList.add(LineText(linefeed: 1));
//           printList.add(LineText(linefeed: 1));
//           printList.add(LineText(linefeed: 1));
//           printList.add(LineText(linefeed: 1));
//         } else if (connectingPrinterSizeBillPrintScreen == '58') {
//           print('inside this 58m print loop');
//           printList.add(LineText(
//             type: LineText.TYPE_TEXT,
//             content: '$hotelNameAlone',
//             weight: 1,
//             height: 1,
//             align: LineText.ALIGN_CENTER,
//             linefeed: 1,
//           ));
//           if (widget.addressLine1ForPrint != '') {
//             printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: '${widget.addressLine1ForPrint}',
//               weight: 1,
//               align: LineText.ALIGN_CENTER,
//               linefeed: 1,
//             ));
//           }
//           if (widget.addressLine2ForPrint != '') {
//             printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: '${widget.addressLine2ForPrint}',
//               weight: 1,
//               align: LineText.ALIGN_CENTER,
//               linefeed: 1,
//             ));
//           }
//           if (widget.addressLine3ForPrint != '') {
//             printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: '${widget.addressLine3ForPrint}',
//               weight: 1,
//               align: LineText.ALIGN_CENTER,
//               linefeed: 1,
//             ));
//           }
//           if (widget.phoneNumberForPrint != '') {
//             printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: '${widget.phoneNumberForPrint}',
//               weight: 1,
//               align: LineText.ALIGN_CENTER,
//               linefeed: 1,
//             ));
//           }
//           printList.add(LineText(linefeed: 1));
//           if (widget.cgstPercentage > 0) {
//             printList.add(
//               LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: 'TAX INVOICE',
//                 weight: 1,
//                 align: LineText.ALIGN_CENTER,
//                 linefeed: 1,
//                 //LineFeedIsGivenForLineBreaks
//               ),
//             );
//           }
//           // printList.add(
//           //   LineText(
//           //     type: LineText.TYPE_TEXT,
//           //     content: 'ORIGINAL',
//           //     weight: 1,
//           //     align: LineText.ALIGN_CENTER,
//           //     linefeed: 1,
//           //     //LineFeedIsGivenForLineBreaks
//           //   ),
//           // );
//
//           printList.add(
//             LineText(
//               type: LineText.TYPE_TEXT,
//               content:
//                   'ORDER DATE: ${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year} at ${DateTime.now().hour}:${DateTime.now().minute} ',
//               weight: 1,
//               align: LineText.ALIGN_CENTER,
//               linefeed: 1,
//               //LineFeedIsGivenForLineBreaks
//             ),
//           );
//           printList.add(LineText(linefeed: 1));
//           printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: 'TOTAL NO. OF ITEMS:',
//               weight: 1,
//               align: LineText.ALIGN_LEFT,
//               x: 0,
//               relativeX: 0,
//               linefeed: 0));
//           printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: '${widget.distinctItems.length}',
//               weight: 1,
//               // align: LineText.ALIGN_RIGHT,
//               align: LineText.ALIGN_LEFT,
//               x: 230,
//               relativeX: 0,
//               linefeed: 1));
//           printList.add(LineText(linefeed: 1));
//           printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: 'BILL NO: ${widget.orderHistoryDocID}',
//               weight: 1,
//               align: LineText.ALIGN_LEFT,
//               x: 0,
//               relativeX: 0,
//               linefeed: 1));
//           if (widget.statisticsMap['numberofparcel']! > 0) {
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: 'TYPE: TAKE-AWAY',
//                 weight: 1,
//                 align: LineText.ALIGN_LEFT,
//                 x: 0,
//                 relativeX: 0,
//                 linefeed: 1));
//           } else {
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: 'TYPE: DINE-IN',
//                 weight: 1,
//                 align: LineText.ALIGN_LEFT,
//                 x: 0,
//                 relativeX: 0,
//                 linefeed: 1));
//           }
//           printList.add(LineText(
//             type: LineText.TYPE_TEXT,
//             content: '-------------------------------',
//             weight: 1,
//             align: LineText.ALIGN_CENTER,
//             linefeed: 1,
//           ));
//           printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: 'ItemName',
//               weight: 1,
//               align: LineText.ALIGN_LEFT,
//               x: 0,
//               relativeX: 0,
//               linefeed: 0));
//           printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: 'Amount',
//               weight: 1,
//               // align: LineText.ALIGN_RIGHT,
//               align: LineText.ALIGN_LEFT,
//               x: 300,
//               relativeX: 0,
//               linefeed: 1));
//           printList.add(LineText(
//             type: LineText.TYPE_TEXT,
//             content: '-------------------------------',
//             weight: 1,
//             align: LineText.ALIGN_CENTER,
//             linefeed: 1,
//           ));
//           for (int i = 0; i < widget.distinctItems.length; i++) {
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: '${widget.distinctItems[i]}',
//                 weight: 1,
//                 align: LineText.ALIGN_LEFT,
//                 x: 0,
//                 relativeX: 0,
//                 linefeed: 1));
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content:
//                     '${widget.individualPriceOfEachDistinctItem[i]} x ${widget.numberOfEachDistinctItem[i]}',
//                 weight: 1,
//                 // align: LineText.ALIGN_RIGHT,
//                 align: LineText.ALIGN_LEFT,
//                 x: 0,
//                 relativeX: 0,
//                 linefeed: 0));
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: '${widget.priceOfEachDistinctItemWithoutTotal[i]}',
//                 weight: 1,
//                 // align: LineText.ALIGN_RIGHT,
//                 align: LineText.ALIGN_LEFT,
//                 x: 320,
//                 relativeX: 0,
//                 linefeed: 1));
//           }
//           printList.add(LineText(
//             type: LineText.TYPE_TEXT,
//             content: '--------------------------------',
//             weight: 1,
//             align: LineText.ALIGN_CENTER,
//             linefeed: 1,
//           ));
//           printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: 'TOTAL Qty:',
//               weight: 1,
//               align: LineText.ALIGN_LEFT,
//               x: 0,
//               relativeX: 0,
//               linefeed: 0));
//           printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: '${totalQuantity()}',
//               weight: 1,
//               // align: LineText.ALIGN_RIGHT,
//               align: LineText.ALIGN_LEFT,
//               x: 120,
//               relativeX: 0,
//               linefeed: 0));
//           if (widget.cgstPercentage > 0) {
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: 'Sub-Total :',
//                 weight: 1,
//                 // align: LineText.ALIGN_RIGHT,
//                 align: LineText.ALIGN_LEFT,
//                 x: 155,
//                 relativeX: 0,
//                 linefeed: 0));
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: '${widget.statisticsMap['totalbillamounttoday']}',
//                 weight: 1,
//                 // align: LineText.ALIGN_RIGHT,
//                 align: LineText.ALIGN_LEFT,
//                 x: 310,
//                 relativeX: 0,
//                 linefeed: 1));
//           }
//           if (widget.cgstPercentage > 0) {
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: 'CGST @ ${widget.cgstPercentage}% :',
//                 weight: 1,
//                 align: LineText.ALIGN_LEFT,
//                 x: 130,
//                 relativeX: 0,
//                 linefeed: 0));
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: '${widget.cgstCalculated}',
//                 weight: 1,
//                 // align: LineText.ALIGN_RIGHT,
//                 align: LineText.ALIGN_LEFT,
//                 x: 310,
//                 relativeX: 0,
//                 linefeed: 1));
//           }
//           if (widget.sgstPercentage > 0) {
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: 'SGST @ ${widget.sgstPercentage}% :',
//                 weight: 1,
//                 align: LineText.ALIGN_LEFT,
//                 x: 130,
//                 relativeX: 0,
//                 linefeed: 0));
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: '${widget.sgstCalculated}',
//                 weight: 1,
//                 // align: LineText.ALIGN_RIGHT,
//                 align: LineText.ALIGN_LEFT,
//                 x: 310,
//                 relativeX: 0,
//                 linefeed: 1));
//           } else {
//             printList.add(LineText(linefeed: 1));
//           }
//           printList.add(LineText(
//             type: LineText.TYPE_TEXT,
//             content: '--------------------------------',
//             weight: 1,
//             align: LineText.ALIGN_CENTER,
//             linefeed: 1,
//           ));
//           printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: 'GRAND TOTAL:',
//               weight: 1,
//               height: 2,
//               align: LineText.ALIGN_LEFT,
//               x: 140,
//               relativeX: 0,
//               linefeed: 0));
//           printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: '${widget.totalBillWithTaxes}',
//               weight: 1,
//               height: 2,
//               // align: LineText.ALIGN_RIGHT,
//               align: LineText.ALIGN_LEFT,
//               x: 300,
//               relativeX: 0,
//               linefeed: 1));
//
//           printList.add(LineText(linefeed: 1));
//           printList.add(LineText(linefeed: 1));
//           printList.add(LineText(linefeed: 1));
//         }
//
//         // setState(() {
//         //   showSpinner = false;
//         // });
//
//         await blue//   void printBill() {
// //     if (showSpinner == false) {
// //       setState(() {
// //         showSpinner = true;
// //       });
// //     }
// //     Timer? _timer;
// //     int _everySecondForConnection = 0;
// //     _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
// //       //ItWillCheckWhetherTheVariableEveryThirtySecondsIsLessThan121,,
// // //ThenItWillBeIncrementedBy1AndItWillAlsoCallTheFunctionWhichWillCheck,,
// // //ForNewOrdersInTheBackground
// // //IfItIsMoreThan120,ThenForOneHourThereHasNotBeenAnyOrder
// // //AndHenceWeCancelTheTimer
// //
// //       if (_everySecondForConnection < 4) {
// //         print(
// //             'timer everysecond for connection time is $_everySecondForConnection');
// //         _everySecondForConnection++;
// //       } else {
// //         _timer?.cancel();
// //         print(
// //             'timer time at connect point is point is $_everySecondForConnection');
// //         print('connected at bottom button is ${_connected}');
// //         Map<String, dynamic> config = Map();
// //         List<LineText> printList = [];
// //         if (connectingPrinterSizeBillPrintScreen == '80') {
// //           print('came inside 80mm loop');
// //           printList.add(LineText(
// //             type: LineText.TYPE_TEXT,
// //             content: '${widget.hotelNameForPrint}',
// //             weight: 1,
// //             height: 1,
// //             align: LineText.ALIGN_CENTER,
// //             linefeed: 1,
// //           ));
// //           if (widget.addressLine1ForPrint != '') {
// //             printList.add(LineText(
// //               type: LineText.TYPE_TEXT,
// //               content: '${widget.addressLine1ForPrint}',
// //               weight: 1,
// //               align: LineText.ALIGN_CENTER,
// //               linefeed: 1,
// //             ));
// //           }
// //           if (widget.addressLine2ForPrint != '') {
// //             printList.add(LineText(
// //               type: LineText.TYPE_TEXT,
// //               content: '${widget.addressLine2ForPrint}',
// //               weight: 1,
// //               align: LineText.ALIGN_CENTER,
// //               linefeed: 1,
// //             ));
// //           }
// //           if (widget.addressLine3ForPrint != '') {
// //             printList.add(LineText(
// //               type: LineText.TYPE_TEXT,
// //               content: '${widget.addressLine3ForPrint}',
// //               weight: 1,
// //               align: LineText.ALIGN_CENTER,
// //               linefeed: 1,
// //             ));
// //           }
// //           if (widget.phoneNumberForPrint != '') {
// //             printList.add(LineText(
// //               type: LineText.TYPE_TEXT,
// //               content: '${widget.phoneNumberForPrint}',
// //               weight: 1,
// //               align: LineText.ALIGN_CENTER,
// //               linefeed: 1,
// //             ));
// //           }
// //           printList.add(LineText(linefeed: 1));
// //           if (widget.cgstPercentage > 0) {
// //             printList.add(
// //               LineText(
// //                 type: LineText.TYPE_TEXT,
// //                 content: 'TAX INVOICE',
// //                 weight: 1,
// //                 align: LineText.ALIGN_CENTER,
// //                 linefeed: 1,
// //                 //LineFeedIsGivenForLineBreaks
// //               ),
// //             );
// //           }
// //
// //           // printList.add(
// //           //   LineText(
// //           //     type: LineText.TYPE_TEXT,
// //           //     content: 'ORIGINAL',
// //           //     weight: 1,
// //           //     align: LineText.ALIGN_CENTER,
// //           //     linefeed: 1,
// //           //     //LineFeedIsGivenForLineBreaks
// //           //   ),
// //           // );
// //
// //           printList.add(
// //             LineText(
// //               type: LineText.TYPE_TEXT,
// //               content:
// //                   'ORDER DATE: ${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year} at ${DateTime.now().hour}:${DateTime.now().minute} ',
// //               weight: 1,
// //               align: LineText.ALIGN_CENTER,
// //               linefeed: 1,
// //               //LineFeedIsGivenForLineBreaks
// //             ),
// //           );
// //           printList.add(LineText(linefeed: 1));
// //           printList.add(LineText(
// //               type: LineText.TYPE_TEXT,
// //               content: 'TOTAL NO. OF ITEMS:',
// //               weight: 1,
// //               align: LineText.ALIGN_LEFT,
// //               x: 0,
// //               relativeX: 0,
// //               linefeed: 0));
// //           printList.add(LineText(
// //               type: LineText.TYPE_TEXT,
// //               content: '${widget.distinctItems.length}',
// //               weight: 1,
// //               // align: LineText.ALIGN_RIGHT,
// //               align: LineText.ALIGN_LEFT,
// //               x: 240,
// //               relativeX: 0,
// //               linefeed: 1));
// //           printList.add(LineText(
// //               type: LineText.TYPE_TEXT,
// //               content: 'BILL NO: ${widget.orderHistoryDocID}',
// //               weight: 1,
// //               align: LineText.ALIGN_LEFT,
// //               x: 0,
// //               relativeX: 0,
// //               linefeed: 0));
// //           if (widget.statisticsMap['numberofparcel']! > 0) {
// //             printList.add(LineText(
// //                 type: LineText.TYPE_TEXT,
// //                 content: 'TYPE: TAKE-AWAY',
// //                 weight: 1,
// //                 align: LineText.ALIGN_LEFT,
// //                 x: 350,
// //                 relativeX: 0,
// //                 linefeed: 1));
// //           } else {
// //             printList.add(LineText(
// //                 type: LineText.TYPE_TEXT,
// //                 content: 'TYPE: DINE-IN',
// //                 weight: 1,
// //                 align: LineText.ALIGN_LEFT,
// //                 x: 350,
// //                 relativeX: 0,
// //                 linefeed: 1));
// //           }
// //           printList.add(LineText(
// //             type: LineText.TYPE_TEXT,
// //             content: '------------------------------------------------',
// //             weight: 1,
// //             align: LineText.ALIGN_CENTER,
// //             linefeed: 1,
// //           ));
// //           printList.add(LineText(
// //               type: LineText.TYPE_TEXT,
// //               content: 'ItemName',
// //               weight: 1,
// //               align: LineText.ALIGN_LEFT,
// //               x: 5,
// //               relativeX: 0,
// //               linefeed: 0));
// //           printList.add(LineText(
// //               type: LineText.TYPE_TEXT,
// //               content: 'Price',
// //               weight: 1,
// //               // align: LineText.ALIGN_RIGHT,
// //               align: LineText.ALIGN_LEFT,
// //               x: 320,
// //               relativeX: 0,
// //               linefeed: 0));
// //           printList.add(LineText(
// //               type: LineText.TYPE_TEXT,
// //               content: 'Qty',
// //               weight: 1,
// //               // align: LineText.ALIGN_RIGHT,
// //               align: LineText.ALIGN_LEFT,
// //               x: 420,
// //               relativeX: 0,
// //               linefeed: 0));
// //           printList.add(LineText(
// //               type: LineText.TYPE_TEXT,
// //               content: 'Amount',
// //               weight: 1,
// //               // align: LineText.ALIGN_RIGHT,
// //               align: LineText.ALIGN_LEFT,
// //               x: 500,
// //               relativeX: 0,
// //               linefeed: 1));
// //           printList.add(LineText(
// //             type: LineText.TYPE_TEXT,
// //             content: '------------------------------------------------',
// //             weight: 1,
// //             align: LineText.ALIGN_CENTER,
// //             linefeed: 1,
// //           ));
// //           for (int i = 0; i < widget.distinctItems.length; i++) {
// //             printList.add(LineText(
// //                 type: LineText.TYPE_TEXT,
// //                 content: '${widget.distinctItems[i]}',
// //                 weight: 1,
// //                 align: LineText.ALIGN_LEFT,
// //                 x: 0,
// //                 relativeX: 0,
// //                 linefeed: 0));
// //             printList.add(LineText(
// //                 type: LineText.TYPE_TEXT,
// //                 content: '${widget.individualPriceOfEachDistinctItem[i]}',
// //                 weight: 1,
// //                 // align: LineText.ALIGN_RIGHT,
// //                 align: LineText.ALIGN_LEFT,
// //                 x: 340,
// //                 relativeX: 0,
// //                 linefeed: 0));
// //             printList.add(LineText(
// //                 type: LineText.TYPE_TEXT,
// //                 content: '${widget.numberOfEachDistinctItem[i]}',
// //                 weight: 1,
// //                 // align: LineText.ALIGN_RIGHT,
// //                 align: LineText.ALIGN_LEFT,
// //                 x: 430,
// //                 relativeX: 0,
// //                 linefeed: 0));
// //             printList.add(LineText(
// //                 type: LineText.TYPE_TEXT,
// //                 content: '${widget.priceOfEachDistinctItemWithoutTotal[i]}',
// //                 weight: 1,
// //                 // align: LineText.ALIGN_RIGHT,
// //                 align: LineText.ALIGN_LEFT,
// //                 x: 500,
// //                 relativeX: 0,
// //                 linefeed: 1));
// //           }
// //           printList.add(LineText(
// //             type: LineText.TYPE_TEXT,
// //             content: '------------------------------------------------',
// //             weight: 1,
// //             align: LineText.ALIGN_CENTER,
// //             linefeed: 1,
// //           ));
// //           printList.add(LineText(
// //               type: LineText.TYPE_TEXT,
// //               content: 'TOTAL Qty :',
// //               weight: 1,
// //               align: LineText.ALIGN_LEFT,
// //               x: 0,
// //               relativeX: 0,
// //               linefeed: 0));
// //           printList.add(LineText(
// //               type: LineText.TYPE_TEXT,
// //               content: '${totalQuantity()}',
// //               weight: 1,
// //               // align: LineText.ALIGN_RIGHT,
// //               align: LineText.ALIGN_LEFT,
// //               x: 140,
// //               relativeX: 0,
// //               linefeed: 0));
// //           if (widget.cgstPercentage > 0) {
// //             printList.add(LineText(
// //                 type: LineText.TYPE_TEXT,
// //                 content: 'Sub-Total :',
// //                 weight: 1,
// //                 // align: LineText.ALIGN_RIGHT,
// //                 align: LineText.ALIGN_LEFT,
// //                 x: 305,
// //                 relativeX: 0,
// //                 linefeed: 0));
// //             printList.add(LineText(
// //                 type: LineText.TYPE_TEXT,
// //                 content: '${widget.statisticsMap['totalbillamounttoday']}',
// //                 weight: 1,
// //                 // align: LineText.ALIGN_RIGHT,
// //                 align: LineText.ALIGN_LEFT,
// //                 x: 500,
// //                 relativeX: 0,
// //                 linefeed: 1));
// //           }
// //           if (widget.cgstPercentage > 0) {
// //             printList.add(LineText(
// //                 type: LineText.TYPE_TEXT,
// //                 content: 'CGST @ ${widget.cgstPercentage}% :',
// //                 weight: 1,
// //                 align: LineText.ALIGN_LEFT,
// //                 x: 280,
// //                 relativeX: 0,
// //                 linefeed: 0));
// //             printList.add(LineText(
// //                 type: LineText.TYPE_TEXT,
// //                 content: '${widget.cgstCalculated}',
// //                 weight: 1,
// //                 // align: LineText.ALIGN_RIGHT,
// //                 align: LineText.ALIGN_LEFT,
// //                 x: 500,
// //                 relativeX: 0,
// //                 linefeed: 1));
// //           }
// //           if (widget.sgstPercentage > 0) {
// //             printList.add(LineText(
// //                 type: LineText.TYPE_TEXT,
// //                 content: 'SGST @ ${widget.sgstPercentage}% :',
// //                 weight: 1,
// //                 align: LineText.ALIGN_LEFT,
// //                 x: 280,
// //                 relativeX: 0,
// //                 linefeed: 0));
// //             printList.add(LineText(
// //                 type: LineText.TYPE_TEXT,
// //                 content: '${widget.sgstCalculated}',
// //                 weight: 1,
// //                 // align: LineText.ALIGN_RIGHT,
// //                 align: LineText.ALIGN_LEFT,
// //                 x: 500,
// //                 relativeX: 0,
// //                 linefeed: 1));
// //           } else {
// //             printList.add(LineText(linefeed: 1));
// //           }
// //           printList.add(LineText(
// //             type: LineText.TYPE_TEXT,
// //             content: '------------------------------------------------',
// //             weight: 1,
// //             align: LineText.ALIGN_CENTER,
// //             linefeed: 1,
// //           ));
// //           printList.add(LineText(
// //               type: LineText.TYPE_TEXT,
// //               content: 'GRAND TOTAL:',
// //               weight: 1,
// //               height: 2,
// //               align: LineText.ALIGN_LEFT,
// //               x: 250,
// //               relativeX: 0,
// //               linefeed: 0));
// //           printList.add(LineText(
// //               type: LineText.TYPE_TEXT,
// //               content: '${widget.totalBillWithTaxes}',
// //               weight: 1,
// //               height: 2,
// //               // align: LineText.ALIGN_RIGHT,
// //               align: LineText.ALIGN_LEFT,
// //               x: 480,
// //               relativeX: 0,
// //               linefeed: 1));
// //
// //           printList.add(LineText(linefeed: 1));
// //           printList.add(LineText(linefeed: 1));
// //           printList.add(LineText(linefeed: 1));
// //           printList.add(LineText(linefeed: 1));
// //           printList.add(LineText(linefeed: 1));
// //         } else if (connectingPrinterSizeBillPrintScreen == '58') {
// //           print('inside this 58m print loop');
// //           printList.add(LineText(
// //             type: LineText.TYPE_TEXT,
// //             content: '$hotelNameAlone',
// //             weight: 1,
// //             height: 1,
// //             align: LineText.ALIGN_CENTER,
// //             linefeed: 1,
// //           ));
// //           if (widget.addressLine1ForPrint != '') {
// //             printList.add(LineText(
// //               type: LineText.TYPE_TEXT,
// //               content: '${widget.addressLine1ForPrint}',
// //               weight: 1,
// //               align: LineText.ALIGN_CENTER,
// //               linefeed: 1,
// //             ));
// //           }
// //           if (widget.addressLine2ForPrint != '') {
// //             printList.add(LineText(
// //               type: LineText.TYPE_TEXT,
// //               content: '${widget.addressLine2ForPrint}',
// //               weight: 1,
// //               align: LineText.ALIGN_CENTER,
// //               linefeed: 1,
// //             ));
// //           }
// //           if (widget.addressLine3ForPrint != '') {
// //             printList.add(LineText(
// //               type: LineText.TYPE_TEXT,
// //               content: '${widget.addressLine3ForPrint}',
// //               weight: 1,
// //               align: LineText.ALIGN_CENTER,
// //               linefeed: 1,
// //             ));
// //           }
// //           if (widget.phoneNumberForPrint != '') {
// //             printList.add(LineText(
// //               type: LineText.TYPE_TEXT,
// //               content: '${widget.phoneNumberForPrint}',
// //               weight: 1,
// //               align: LineText.ALIGN_CENTER,
// //               linefeed: 1,
// //             ));
// //           }
// //           printList.add(LineText(linefeed: 1));
// //           if (widget.cgstPercentage > 0) {
// //             printList.add(
// //               LineText(
// //                 type: LineText.TYPE_TEXT,
// //                 content: 'TAX INVOICE',
// //                 weight: 1,
// //                 align: LineText.ALIGN_CENTER,
// //                 linefeed: 1,
// //                 //LineFeedIsGivenForLineBreaks
// //               ),
// //             );
// //           }
// //           // printList.add(
// //           //   LineText(
// //           //     type: LineText.TYPE_TEXT,
// //           //     content: 'ORIGINAL',
// //           //     weight: 1,
// //           //     align: LineText.ALIGN_CENTER,
// //           //     linefeed: 1,
// //           //     //LineFeedIsGivenForLineBreaks
// //           //   ),
// //           // );
// //
// //           printList.add(
// //             LineText(
// //               type: LineText.TYPE_TEXT,
// //               content:
// //                   'ORDER DATE: ${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year} at ${DateTime.now().hour}:${DateTime.now().minute} ',
// //               weight: 1,
// //               align: LineText.ALIGN_CENTER,
// //               linefeed: 1,
// //               //LineFeedIsGivenForLineBreaks
// //             ),
// //           );
// //           printList.add(LineText(linefeed: 1));
// //           printList.add(LineText(
// //               type: LineText.TYPE_TEXT,
// //               content: 'TOTAL NO. OF ITEMS:',
// //               weight: 1,
// //               align: LineText.ALIGN_LEFT,
// //               x: 0,
// //               relativeX: 0,
// //               linefeed: 0));
// //           printList.add(LineText(
// //               type: LineText.TYPE_TEXT,
// //               content: '${widget.distinctItems.length}',
// //               weight: 1,
// //               // align: LineText.ALIGN_RIGHT,
// //               align: LineText.ALIGN_LEFT,
// //               x: 230,
// //               relativeX: 0,
// //               linefeed: 1));
// //           printList.add(LineText(linefeed: 1));
// //           printList.add(LineText(
// //               type: LineText.TYPE_TEXT,
// //               content: 'BILL NO: ${widget.orderHistoryDocID}',
// //               weight: 1,
// //               align: LineText.ALIGN_LEFT,
// //               x: 0,
// //               relativeX: 0,
// //               linefeed: 1));
// //           if (widget.statisticsMap['numberofparcel']! > 0) {
// //             printList.add(LineText(
// //                 type: LineText.TYPE_TEXT,
// //                 content: 'TYPE: TAKE-AWAY',
// //                 weight: 1,
// //                 align: LineText.ALIGN_LEFT,
// //                 x: 0,
// //                 relativeX: 0,
// //                 linefeed: 1));
// //           } else {
// //             printList.add(LineText(
// //                 type: LineText.TYPE_TEXT,
// //                 content: 'TYPE: DINE-IN',
// //                 weight: 1,
// //                 align: LineText.ALIGN_LEFT,
// //                 x: 0,
// //                 relativeX: 0,
// //                 linefeed: 1));
// //           }
// //           printList.add(LineText(
// //             type: LineText.TYPE_TEXT,
// //             content: '-------------------------------',
// //             weight: 1,
// //             align: LineText.ALIGN_CENTER,
// //             linefeed: 1,
// //           ));
// //           printList.add(LineText(
// //               type: LineText.TYPE_TEXT,
// //               content: 'ItemName',
// //               weight: 1,
// //               align: LineText.ALIGN_LEFT,
// //               x: 0,
// //               relativeX: 0,
// //               linefeed: 0));
// //           printList.add(LineText(
// //               type: LineText.TYPE_TEXT,
// //               content: 'Amount',
// //               weight: 1,
// //               // align: LineText.ALIGN_RIGHT,
// //               align: LineText.ALIGN_LEFT,
// //               x: 300,
// //               relativeX: 0,
// //               linefeed: 1));
// //           printList.add(LineText(
// //             type: LineText.TYPE_TEXT,
// //             content: '-------------------------------',
// //             weight: 1,
// //             align: LineText.ALIGN_CENTER,
// //             linefeed: 1,
// //           ));
// //           for (int i = 0; i < widget.distinctItems.length; i++) {
// //             printList.add(LineText(
// //                 type: LineText.TYPE_TEXT,
// //                 content: '${widget.distinctItems[i]}',
// //                 weight: 1,
// //                 align: LineText.ALIGN_LEFT,
// //                 x: 0,
// //                 relativeX: 0,
// //                 linefeed: 1));
// //             printList.add(LineText(
// //                 type: LineText.TYPE_TEXT,
// //                 content:
// //                     '${widget.individualPriceOfEachDistinctItem[i]} x ${widget.numberOfEachDistinctItem[i]}',
// //                 weight: 1,
// //                 // align: LineText.ALIGN_RIGHT,
// //                 align: LineText.ALIGN_LEFT,
// //                 x: 0,
// //                 relativeX: 0,
// //                 linefeed: 0));
// //             printList.add(LineText(
// //                 type: LineText.TYPE_TEXT,
// //                 content: '${widget.priceOfEachDistinctItemWithoutTotal[i]}',
// //                 weight: 1,
// //                 // align: LineText.ALIGN_RIGHT,
// //                 align: LineText.ALIGN_LEFT,
// //                 x: 320,
// //                 relativeX: 0,
// //                 linefeed: 1));
// //           }
// //           printList.add(LineText(
// //             type: LineText.TYPE_TEXT,
// //             content: '--------------------------------',
// //             weight: 1,
// //             align: LineText.ALIGN_CENTER,
// //             linefeed: 1,
// //           ));
// //           printList.add(LineText(
// //               type: LineText.TYPE_TEXT,
// //               content: 'TOTAL Qty:',
// //               weight: 1,
// //               align: LineText.ALIGN_LEFT,
// //               x: 0,
// //               relativeX: 0,
// //               linefeed: 0));
// //           printList.add(LineText(
// //               type: LineText.TYPE_TEXT,
// //               content: '${totalQuantity()}',
// //               weight: 1,
// //               // align: LineText.ALIGN_RIGHT,
// //               align: LineText.ALIGN_LEFT,
// //               x: 120,
// //               relativeX: 0,
// //               linefeed: 0));
// //           if (widget.cgstPercentage > 0) {
// //             printList.add(LineText(
// //                 type: LineText.TYPE_TEXT,
// //                 content: 'Sub-Total :',
// //                 weight: 1,
// //                 // align: LineText.ALIGN_RIGHT,
// //                 align: LineText.ALIGN_LEFT,
// //                 x: 155,
// //                 relativeX: 0,
// //                 linefeed: 0));
// //             printList.add(LineText(
// //                 type: LineText.TYPE_TEXT,
// //                 content: '${widget.statisticsMap['totalbillamounttoday']}',
// //                 weight: 1,
// //                 // align: LineText.ALIGN_RIGHT,
// //                 align: LineText.ALIGN_LEFT,
// //                 x: 310,
// //                 relativeX: 0,
// //                 linefeed: 1));
// //           }
// //           if (widget.cgstPercentage > 0) {
// //             printList.add(LineText(
// //                 type: LineText.TYPE_TEXT,
// //                 content: 'CGST @ ${widget.cgstPercentage}% :',
// //                 weight: 1,
// //                 align: LineText.ALIGN_LEFT,
// //                 x: 130,
// //                 relativeX: 0,
// //                 linefeed: 0));
// //             printList.add(LineText(
// //                 type: LineText.TYPE_TEXT,
// //                 content: '${widget.cgstCalculated}',
// //                 weight: 1,
// //                 // align: LineText.ALIGN_RIGHT,
// //                 align: LineText.ALIGN_LEFT,
// //                 x: 310,
// //                 relativeX: 0,
// //                 linefeed: 1));
// //           }
// //           if (widget.sgstPercentage > 0) {
// //             printList.add(LineText(
// //                 type: LineText.TYPE_TEXT,
// //                 content: 'SGST @ ${widget.sgstPercentage}% :',
// //                 weight: 1,
// //                 align: LineText.ALIGN_LEFT,
// //                 x: 130,
// //                 relativeX: 0,
// //                 linefeed: 0));
// //             printList.add(LineText(
// //                 type: LineText.TYPE_TEXT,
// //                 content: '${widget.sgstCalculated}',
// //                 weight: 1,
// //                 // align: LineText.ALIGN_RIGHT,
// //                 align: LineText.ALIGN_LEFT,
// //                 x: 310,
// //                 relativeX: 0,
// //                 linefeed: 1));
// //           } else {
// //             printList.add(LineText(linefeed: 1));
// //           }
// //           printList.add(LineText(
// //             type: LineText.TYPE_TEXT,
// //             content: '--------------------------------',
// //             weight: 1,
// //             align: LineText.ALIGN_CENTER,
// //             linefeed: 1,
// //           ));
// //           printList.add(LineText(
// //               type: LineText.TYPE_TEXT,
// //               content: 'GRAND TOTAL:',
// //               weight: 1,
// //               height: 2,
// //               align: LineText.ALIGN_LEFT,
// //               x: 140,
// //               relativeX: 0,
// //               linefeed: 0));
// //           printList.add(LineText(
// //               type: LineText.TYPE_TEXT,
// //               content: '${widget.totalBillWithTaxes}',
// //               weight: 1,
// //               height: 2,
// //               // align: LineText.ALIGN_RIGHT,
// //               align: LineText.ALIGN_LEFT,
// //               x: 300,
// //               relativeX: 0,
// //               linefeed: 1));
// //
// //           printList.add(LineText(linefeed: 1));
// //           printList.add(LineText(linefeed: 1));
// //           printList.add(LineText(linefeed: 1));
// //         }
// //
// //         // setState(() {
// //         //   showSpinner = false;
// //         // });
// //
// //         await bluetoothPrint.printReceipt(config, printList);
// //         print('calling disconnect here');
// //         // tappedPrintButton = false;
// //         bluetoothDisconnectFunction();
// //       }
// //     });
// //   }toothPrint.printReceipt(config, printList);
//         print('calling disconnect here');
//         // tappedPrintButton = false;
//         bluetoothDisconnectFunction();
//       }
//     });
//   }

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
                  getAllPairedDevices();
                  print('location permission loop');
                  bluetoothStateChangeFunction();
                  Navigator.pop(context);
                  setState(() {
                    locationPermissionAccepted = true;
                  });
                  // Permission.locationWhenInUse.request();
                  // Navigator.of(context, rootNavigator: true)
                  //     .pop();

                  print('came till this pop1');
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
      print('came into alertdialog loop4');
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
      getAllPairedDevices();
      print('location permission loop2');
      bluetoothStateChangeFunction();
      print('location permission already accepted');
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
      statisticsMap.addAll({'totaldiscount': discount});
      statisticsMap
          .addAll({'totalbillamounttoday': totalBillWithTaxes().round()});

//IfBillHadAlreadyBeenPrintedSerialNumberNeedNotBeAdded
      statisticsMap.addAll({'serialNumber': 0});

      //  print(widget.printOrdersMap);
      Map<String, String> updatePrintOrdersMap = HashMap();

      updatePrintOrdersMap = printOrdersMap;
      updatePrintOrdersMap
          .addAll({'serialNumberForPrint': serialNumber.toString()});

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
      if (widget.cgstPercentage > 0) {
        updatePrintOrdersMap.addAll({
          '989*CGST@${widget.cgstPercentage}%':
              (cgstCalculatedForBillFunction()).toString()
        });
      }
      if (widget.sgstPercentage > 0) {
        updatePrintOrdersMap.addAll({
          '993*SGST@${widget.sgstPercentage}%':
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
      updatePrintOrdersMap
          .addAll({'hotelNameForPrint': '${widget.hotelNameForPrint}'});
      updatePrintOrdersMap
          .addAll({'addressline1ForPrint': '${widget.addressLine1ForPrint}'});
      updatePrintOrdersMap
          .addAll({'addressline2ForPrint': '${widget.addressLine2ForPrint}'});
      updatePrintOrdersMap
          .addAll({'addressline3ForPrint': '${widget.addressLine3ForPrint}'});
      updatePrintOrdersMap
          .addAll({'phoneNumberForPrint': '${widget.phoneNumberForPrint}'});
      updatePrintOrdersMap.addAll({'customerNameForPrint': '$customername'});
      updatePrintOrdersMap
          .addAll({'customerMobileForPrint': '${customermobileNumber}'});
      updatePrintOrdersMap
          .addAll({'customerAddressForPrint': '${customeraddressline1}'});
      updatePrintOrdersMap.addAll({'dateForPrint': '${printingDate}'});

      updatePrintOrdersMap.addAll(
          {'totalNumberOfItemsForPrint': '${distinctItemNames.length}'});
      updatePrintOrdersMap
          .addAll({'billNumberForPrint': '${orderHistoryDocID}'});
      if (statisticsMap['numberofparcel']! > 0) {
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
      updatePrintOrdersMap
          .addAll({'cgstPercentageForPrint': widget.cgstPercentage.toString()});
      updatePrintOrdersMap.addAll({
        'cgstCalculatedForPrint': cgstCalculatedForBillFunction().toString()
      });
      updatePrintOrdersMap
          .addAll({'sgstPercentageForPrint': widget.sgstPercentage.toString()});
      updatePrintOrdersMap.addAll({
        'sgstCalculatedForPrint': sgstCalculatedForBillFunction().toString()
      });
      updatePrintOrdersMap
          .addAll({'grandTotalForPrint': totalBillWithTaxesAsString()});

      //WithThisUpdateBill,itWillPutPrintOrdersMapAsMapItselfInServer
      FireStoreUpdateBill(
              hotelName: widget.hotelName,
              orderHistoryDocID: orderHistoryDocID,
              //        printOrdersMap: widget.printOrdersMap
              printOrdersMap: updatePrintOrdersMap)
          .updateBill();
//ToUpdateStatistics,WeGoThroughEachKeyAndUsingIncrementByFunction,We,,
//CanIncrementTheNumberThatIsAlreadyThereInTheServer
//ThisWillHelpToAddToTheStatisticsThat'sAlreadyThere
      int counterToDeleteTableOrParcelOrderFromFireStore = 1;
      statisticsMap.forEach((key, value) {
        counterToDeleteTableOrParcelOrderFromFireStore++;
        double? incrementBy = statisticsMap[key]?.toDouble();
        FireStoreUpdateStatistics(
                hotelName: widget.hotelName,
                docID: statisticsDocID,
                incrementBy: incrementBy,
                key: key)
            .updateStatistics();
        if (counterToDeleteTableOrParcelOrderFromFireStore ==
            statisticsMap.length) {
          FireStoreDeleteFinishedOrderInPresentOrders(
                  hotelName: widget.hotelName,
                  eachItemId: widget.itemsFromThisDocumentInFirebaseDoc)
              .deleteFinishedOrder();
        }
      });
      //ThenFinallyWeGoThroughEachItemIdAndDeleteItOutOfCurrentOrders
      // for (String eachItemId in widget.itemsID) {
      //   FireStoreDeleteFinishedOrder(
      //           hotelName: widget.hotelName, eachItemId: eachItemId)
      //       .deleteFinishedOrder();
      // }
      billUpdatedInServer = true;
      screenPopOutTimerAfterServerUpdate();
    } else {
      bool hasInternet = await InternetConnectionChecker().hasConnection;
      if (hasInternet) {
        serverUpdateAfterSerialNumber();
      } else {
        setState(() {
          pageHasInternet = hasInternet;
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

      FirebaseFirestore.instance
          .collection(widget.hotelName)
          .doc('statistics')
          .collection('statistics')
          .doc(statisticsDocID)
          .get()
          .then((value) {
        statisticsData = value.data();
        if (statisticsData == null || statisticsData!['serialNumber'] == null) {
          serialNumber = 1;
        } else {
          serialNumber =
              num.parse((statisticsData!['serialNumber']).toString()).toInt() +
                  1;
        }
//SinceSerialNumberIsZeroWeWillHaveToIncrementSerialNumberByOneAnyway
        FireStoreUpdateStatistics(
                hotelName: widget.hotelName,
                docID: statisticsDocID,
                incrementBy: 1,
                key: 'serialNumber')
            .updateStatistics();

        serialNumberUpdateInServerWhenPrintClickedFirstTime();
        tappedPrintButton = false;
        startOfCallForPrintingBill();
      });
    } else {
      setState(() {
        pageHasInternet = hasInternet;
        showSpinner = false;
        tappedPrintButton = false;
      });
      show('You are Offline!\nPlease turn on Internet&Reprint bill');
    }
  }

  void serverUpdateAfterSerialNumber() {
    final statisticsDocCheck = FirebaseFirestore.instance
        .collection(widget.hotelName)
        .doc('statistics')
        .collection('statistics')
        .doc(statisticsDocID)
        .get()
        .then((value) {
      Map<String, dynamic>? statisticsData = value.data();
      if (statisticsData == null || statisticsData!['serialNumber'] == null) {
        serialNumber = 1;
      } else {
        serialNumber =
            num.parse((statisticsData['serialNumber']).toString()).toInt() + 1;
      }
      statisticsMap.addAll({'serialNumber': 1});
      statisticsMap.addAll({'totaldiscount': discount});
      statisticsMap
          .addAll({'totalbillamounttoday': totalBillWithTaxes().round()});

      //  print(widget.printOrdersMap);
      Map<String, String> updatePrintOrdersMap = HashMap();

      updatePrintOrdersMap = printOrdersMap;
      updatePrintOrdersMap
          .addAll({'serialNumberForPrint': serialNumber.toString()});

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
      if (widget.cgstPercentage > 0) {
        updatePrintOrdersMap.addAll({
          '989*CGST@${widget.cgstPercentage}%':
              (cgstCalculatedForBillFunction()).toString()
        });
      }
      if (widget.sgstPercentage > 0) {
        updatePrintOrdersMap.addAll({
          '993*SGST@${widget.sgstPercentage}%':
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
      updatePrintOrdersMap
          .addAll({'hotelNameForPrint': '${widget.hotelNameForPrint}'});
      updatePrintOrdersMap
          .addAll({'addressline1ForPrint': '${widget.addressLine1ForPrint}'});
      updatePrintOrdersMap
          .addAll({'addressline2ForPrint': '${widget.addressLine2ForPrint}'});
      updatePrintOrdersMap
          .addAll({'addressline3ForPrint': '${widget.addressLine3ForPrint}'});
      updatePrintOrdersMap
          .addAll({'phoneNumberForPrint': '${widget.phoneNumberForPrint}'});
      updatePrintOrdersMap.addAll({'customerNameForPrint': '$customername'});
      updatePrintOrdersMap
          .addAll({'customerMobileForPrint': '${customermobileNumber}'});
      updatePrintOrdersMap
          .addAll({'customerAddressForPrint': '${customeraddressline1}'});
      updatePrintOrdersMap.addAll({'dateForPrint': '${printingDate}'});

      updatePrintOrdersMap.addAll(
          {'totalNumberOfItemsForPrint': '${distinctItemNames.length}'});
      updatePrintOrdersMap
          .addAll({'billNumberForPrint': '${orderHistoryDocID}'});
      if (statisticsMap['numberofparcel']! > 0) {
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
      updatePrintOrdersMap
          .addAll({'cgstPercentageForPrint': widget.cgstPercentage.toString()});
      updatePrintOrdersMap.addAll({
        'cgstCalculatedForPrint': cgstCalculatedForBillFunction().toString()
      });
      updatePrintOrdersMap
          .addAll({'sgstPercentageForPrint': widget.sgstPercentage.toString()});
      updatePrintOrdersMap.addAll({
        'sgstCalculatedForPrint': sgstCalculatedForBillFunction().toString()
      });
      updatePrintOrdersMap
          .addAll({'grandTotalForPrint': totalBillWithTaxesAsString()});

      //WithThisUpdateBill,itWillPutPrintOrdersMapAsMapItselfInServer
      FireStoreUpdateBill(
              hotelName: widget.hotelName,
              orderHistoryDocID: orderHistoryDocID,
              //        printOrdersMap: widget.printOrdersMap
              printOrdersMap: updatePrintOrdersMap)
          .updateBill();
//ToUpdateStatistics,WeGoThroughEachKeyAndUsingIncrementByFunction,We,,
//CanIncrementTheNumberThatIsAlreadyThereInTheServer
//ThisWillHelpToAddToTheStatisticsThat'sAlreadyThere
      int counterToDeleteTableOrParcelOrderFromFireStore = 1;
      print(statisticsMap.length);
      statisticsMap.forEach((key, value) {
        counterToDeleteTableOrParcelOrderFromFireStore++;
        double? incrementBy = statisticsMap[key]?.toDouble();
        FireStoreUpdateStatistics(
                hotelName: widget.hotelName,
                docID: statisticsDocID,
                incrementBy: incrementBy,
                key: key)
            .updateStatistics();
        if (counterToDeleteTableOrParcelOrderFromFireStore ==
            statisticsMap.length) {
          FireStoreDeleteFinishedOrderInPresentOrders(
                  hotelName: widget.hotelName,
                  eachItemId: widget.itemsFromThisDocumentInFirebaseDoc)
              .deleteFinishedOrder();
        }
      });
      //ThenFinallyWeGoThroughEachItemIdAndDeleteItOutOfCurrentOrders
      // for (String eachItemId in widget.itemsID) {
      //   FireStoreDeleteFinishedOrder(
      //           hotelName: widget.hotelName, eachItemId: eachItemId)
      //       .deleteFinishedOrder();
      // }
      billUpdatedInServer = true;
      screenPopOutTimerAfterServerUpdate();
    });
  }

  void serialNumberUpdateInServerWhenPrintClickedFirstTime() {
    String splitCheck = widget.addedItemsSet;
    final serialNumberSetSplit = splitCheck.split('*');
    serialNumberSetSplit[8] = serialNumber.toString();

    String tempSerialNumberUpdaterString = '';
    for (int i = 0; i < serialNumberSetSplit.length - 1; i++) {
      tempSerialNumberUpdaterString += '${serialNumberSetSplit[i]}*';
    }

    FireStoreUpdateSerialNumber(
            hotelName: widget.hotelName,
            itemsUpdaterString: tempSerialNumberUpdaterString,
            seatingNumber: widget.itemsFromThisDocumentInFirebaseDoc)
        .updateSerialNumber();
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
        if (billUpdatedInServer) {
          if (bluetoothConnected) {
            bluetooth.disconnect();
            _everySecondForConnection = 0;
            setState(() {
              showSpinner = false;
              printingOver = true;

              tappedPrintButton = false;
              print('12 $tappedPrintButton');

              _connected = false;
            });
          }

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
                if (billUpdatedInServer) {
                  if (bluetoothConnected) {
                    bluetooth.disconnect();
                    _everySecondForConnection = 0;
                    setState(() {
                      showSpinner = false;
                      printingOver = true;

                      tappedPrintButton = false;
                      print('13 $tappedPrintButton');

                      _connected = false;
                    });
                  }
                  int count = 0;
                  Navigator.of(context).popUntil((_) => count++ >= 2);
                } else {
                  Navigator.pop(context);
                }
              }),
          backgroundColor: kAppBarBackgroundColor,
          title: Text(
            'Final Bill - ${tableorparcel}:${tableorparcelnumber}${parentOrChild} ',
            style: kAppBarTextStyle,
          ),
          centerTitle: true,
          actions: <Widget>[
            IconButton(
                onPressed: () {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              PrinterSettings(chefOrCaptain: 'Captain')));
                },
                icon: Icon(
                  Icons.settings,
                  color: kAppBarBackIconColor,
                ))
          ],
        ),
        body: ModalProgressHUD(
//ThisIsToShowSpinnerOnceWeClickPrintButton
          inAsyncCall: showSpinner,
          child: buildBillDataScreen(billItemsForDisplay),
        ),
        floatingActionButton: Container(
          width: 75.0,
          height: 75.0,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(1)),
          child: FloatingActionButton(
            backgroundColor: Colors.white70,
            child: const Text(
              'Discount',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
            ),
            onPressed: () {
//shouldBeActiveOnlyWhenThereIsNoOtherImportantActivityLikePrintHappening
              if (!showSpinner) {
                //onPressedWeAlreadyHaveAllTheBelowInputsAsThisScreenWasCalled
//WeGiveUnavailableItemsToEnsureWeDon'tShowItAndItemsAddedMap
//WillHaveTheItemNameAsKeyAndTheNumberAsValue
                _controller = TextEditingController(text: discountEnteredValue);
                showModalBottomSheet(
                    isScrollControlled: true,
                    context: context,
                    builder: (context) {
                      return discountsSection();
                    });
              }
            },
          ),
        ),
        persistentFooterButtons: [
          Row(
            children: [
              Expanded(
                child: BottomButton(
                  onTap: () {
                    if (showSpinner == false) {
                      if (billUpdatedInServer == false && pageHasInternet) {
                        serverUpdateOfBill();
                      }
                    }
                  },
                  buttonTitle: 'Payment Done',
                  buttonColor: Colors.green,
                  // buttonWidth: double.infinity,
                ),
              ),
              SizedBox(width: 10),
              Provider.of<PrinterAndOtherDetailsProvider>(context)
                          .captainPrinterAddressFromClass ==
                      ''
                  ? Expanded(
//IfNoPrinterAddressWeWillSayWeNeedThePrinterSetUpScreen
                      child: BottomButton(
                        onTap: () async {
                          disconnectAndConnectAttempted = false;
                          // tappedPrintButton = true;
                          print(
                              'from bottom button 1 entry-tapped Print Button $tappedPrintButton');

                          bluetoothStateChangeFunction();

                          if (bluetoothOnTrueOrOffFalse) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        SearchingConnectingPrinter(
                                            chefOrCaptain: 'Captain')));
                            // getAllPairedDevices();
                            // setState(() {
                            //   noNeedPrinterConnectionScreen = false;
                            // });
                            print('nknsjkdndjsndsjk');
                          } else if (bluetoothOnTrueOrOffFalse == false &&
                              tappedPrintButton == false &&
                              _connected == false) {
//HereOnlyBluetoothIsTheIssue HenceTappedPrintButtonCanBeFalseItself
                            tappedPrintButton = false;
                            print('14 $tappedPrintButton');

                            const snackBar = SnackBar(
                              content: Text(
                                'Please Turn On Bluetooth!',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 30),
                              ),
                            );

// Find the ScaffoldMessenger in the widget tree
// and use it to show a SnackBar.
                            ScaffoldMessenger.of(context)
                                .showSnackBar(snackBar);
                          }
                        },
                        buttonTitle: 'Print',
                        buttonColor: Colors.red,
                        // buttonWidth: double.infinity,
                      ),
                    )
                  : Expanded(
                      child: BottomButton(
                        onTap: () async {
                          disconnectAndConnectAttempted = false;
                          if (tappedPrintButton == false) {
                            bluetoothStateChangeFunction();
                          }

                          //ThisWayYouCan'tPrintAgainOnceBillHasBeenUpdatedInServer
//                               bluetoothPrint.state.listen((state) {
                          // print('state is $state');
                          print('tapped button state is $tappedPrintButton');
                          if (bluetoothOnTrueOrOffFalse &&
                              tappedPrintButton == false &&
                              pageHasInternet) {
                            if (serialNumber != 0) {
                              startOfCallForPrintingBill();
                            } else {
                              serialNumberStatisticsExistsOrNot();
                            }
                          } else if (bluetoothOnTrueOrOffFalse == false &&
                              tappedPrintButton == false &&
                              _connected == false) {
//HereOnlyBluetoothIsTheIssue HenceTappedPrintButtonCanBeFalseItself
                            tappedPrintButton = false;
                            print('14 $tappedPrintButton');

                            const snackBar = SnackBar(
                              content: Text(
                                'Please Turn On Bluetooth!',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 30),
                              ),
                            );

// Find the ScaffoldMessenger in the widget tree
// and use it to show a SnackBar.
                            ScaffoldMessenger.of(context)
                                .showSnackBar(snackBar);
                          }
                        },
                        buttonTitle: 'Print',
                        buttonColor: Colors.orangeAccent,
                        // buttonWidth: double.infinity,
                      ),
                    ),
            ],
          ),
        ],
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
                'Order Date: ${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}',
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
          widget.cgstPercentage > 0
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('Sub-Total', style: TextStyle(fontSize: 25.0)),
                    Text('${totalPriceOfAllItems - discount}',
                        style: TextStyle(fontSize: 25.0))
                  ],
                )
              : SizedBox.shrink(),
          widget.cgstPercentage > 0
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('CGST@ ${widget.cgstPercentage}%',
                        style: TextStyle(fontSize: 25.0)),
                    Text('${cgstCalculatedForBillFunction()}',
                        style: TextStyle(fontSize: 25.0))
                  ],
                )
              : SizedBox.shrink(),
          widget.sgstPercentage > 0
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text('SGST@ ${widget.sgstPercentage}%',
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
                  ))
            ],
          )
        ],
      ),
    );
  }
}
