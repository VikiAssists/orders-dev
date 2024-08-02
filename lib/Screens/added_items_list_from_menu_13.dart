import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:modal_progress_hud_alt/modal_progress_hud_alt.dart';
import 'package:orders_dev/Methods/bottom_button.dart';
import 'package:orders_dev/Methods/usb_bluetooth_printer.dart';
import 'package:orders_dev/Providers/notification_provider.dart';
import 'package:orders_dev/Screens/menu_page_add_items_6.dart';
import 'package:orders_dev/Screens/printer_roles_assigning.dart';
import 'package:orders_dev/constants.dart';
import 'package:orders_dev/services/firestore_services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';

class AddedItemsWithCaptainInfo extends StatefulWidget {
  //ThisIsTheScreenThatComesEveryTimeTheWaiterAddsItemsFromTheMenu,
  //AndClicksConfirmOrders
  //WeAreHavingMenuItems/prices/titles/UnavailableItemsAlsoAsInputBecause,
  //InCaseWeNeedToGoBackToMenu,ThisWillStraightAwayGiveTheInputsForTheMenu
  final String hotelName;
  final List<String> menuItems;
  final List<num> menuPrices;
  final List<String> menuTitles;
  final String tableOrParcel;
  final num tableOrParcelNumber;

  List<String> unavailableItems;
//ThisItemsAddedMapIsHashMapWhichContainsDataOnWhatAllAreTheItemsAddedAnd,,
//HowManyIsAdded
  Map<String, num> itemsAddedMap = HashMap();
  Map<String, String> itemsAddedComment = HashMap();
  Map<String, num> itemsAddedTime = HashMap();
  final String parentOrChild;
  final Map<String, dynamic> alreadyRunningTicketsMap;
  List<Map<String, dynamic>> printingSeparateItemsListAsPerChef = [];

  AddedItemsWithCaptainInfo(
      {required this.hotelName,
      required this.menuItems,
      required this.menuPrices,
      required this.menuTitles,
      required this.tableOrParcel,
      required this.tableOrParcelNumber,
      required this.itemsAddedMap,
      required this.itemsAddedComment,
      required this.itemsAddedTime,
      required this.unavailableItems,
      required this.parentOrChild,
      required this.alreadyRunningTicketsMap});

  @override
  _AddedItemsWithCaptainInfoState createState() =>
      _AddedItemsWithCaptainInfoState();
}

class _AddedItemsWithCaptainInfoState extends State<AddedItemsWithCaptainInfo> {
  //InThisList,InInitStateWeWillAddTheNameOfAllTheItemsThatHasBeenAdded
  List<String> nameOfItemsAdded = [];
//ThisIsTheStringToUpdateInPlaystore
  String itemsUpdaterString = '';

  //NumberOfHoursInTwoDaysMultipliedByMilliseconds
  bool locationPermissionAccepted = true;

  bool bluetoothOnTrueOrOffFalse = true;

  //BooleanToControlPrintButtonTap
  bool tappedPrintButton = false;
  //SpinnerOrCircularProgressIndicatorWhenTryingToPrint
  bool showSpinner = false;
  bool printingError = false;
  String localSlotNumber = '';
  String localTicketNumber = '';
  List<String> localKOTItemNames = [];
  List<num> localKOTNumberOfItems = [];
  List<String> localKOTItemComments = [];
  bool printingOver = true;
  int _everySecondForConnection = 0;
  String localItemsUpdaterString = '';
  num localChefStatus = 7;
  num localCaptainStatus = 7;
  String localSeatingNumber = '';
  String localPartOfTableOrParcel = '';
  String localPartOfTableOrParcelNumber = '';
  Map<String, dynamic> allUserProfile = HashMap();
  List<dynamic> allItemsFromMenuMap = [];
  List<Map<String, dynamic>> separateKOTForEachUserInEachPrinterMap = [];
  String ticketNumberUpdater = '1';
  List<int> kotBytes = [];
//ForNewPrinterPackage
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
  Map<String, dynamic> kotPrinterAssigningMap = HashMap();
  Map<String, dynamic> printerSavingMap = {}; //MapOfAllPrintersData
  List<Map<String, dynamic>> bytesForEachPrinter = [];
  List<Map<String, dynamic>> couldntConnectPrintersBytesForEachPrinter = [];
  List<int> indexesToRemove = [];

  Map<String, dynamic> kotPrinterCharacters = HashMap();
//MakingTwoVariablesCalledCurrentToEnsureThereIsNoMixUp
  List<int> currentPrintBytes = [];
  Map<String, dynamic> currentKotPrinterCharacters = HashMap();
  var kotPrinterType = PrinterType.bluetooth;
  bool usbKotConnect = false;
  bool usbKotConnectTried = false;
  bool bluetoothKotConnect = false;
  bool bluetoothKotConnectTried = false;
  int printerConnectionSuccessCheckRandomNumber = 0;

  //ThisIsTheButtonWeUseToAddItems.ItsInputIsItemNameOnly
  Widget addOrCounterButton(String item) {
    //ifItemNumberIsGreaterThanZero,itMeansSomeNumberHasBeenAddedAnd
    //InThatCaseWeGoIntoThisLoop
    //!markMeansWeAreCheckingIt'sNotNull.WeAlwaysPutItForNullSafety
    if (widget.itemsAddedMap[item]! > 0) {
      //ItWillReturnAContainerWithRow
      return Container(
        decoration: kMenuAddButtonDecoration,
        height: kMenuButtonHeight,
        width: kMenuButtonWidth,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            //itWillHaveMinusButton
            //EachTimeIt'sPressed,InItemsAddedMap,TheNumberIsReducedByOne
            //WithSetState
            IconButton(
                onPressed: () {
                  setState(() {
                    widget.itemsAddedMap[item] =
                        widget.itemsAddedMap[item]! - 1;
                  });
                },
                icon: const Icon(Icons.remove,
                    color: Colors.green, size: kAddMinusButtonIconSize)),
            Text(
              //Here,WeWillHaveTheNumberOfItemsThatHasBeenAddedTillNow
              widget.itemsAddedMap[item]!.toString(),
              style: kAddButtonNumberTextStyle,
            ),
            IconButton(
                //itWillHavePlusButton
                //EachTimeIt'sPressed,InItemsAddedMap,TheNumberIsAddedByOne
                //WithSetState
                onPressed: () {
                  setState(() {
                    widget.itemsAddedMap[item] =
                        widget.itemsAddedMap[item]! + 1;
                  });
                },
                icon: const Icon(Icons.add,
                    color: Colors.green, size: kAddMinusButtonIconSize))
          ],
        ),
      );
    } else {
      //ThisIsInCase,TheNumberOfItemsIsZero
      //InThatCase,WeOnlyHaveToShowAddButton
      //IfItIsPressedInItemsAddedMap,TheNumberIsAddedByOne
      //WithSetState
      return Container(
        decoration: kMenuAddButtonDecoration,
        height: kMenuButtonHeight,
        width: kMenuButtonWidth,
        child: TextButton(
            onPressed: () {
              setState(() {
                widget.itemsAddedMap[item] = widget.itemsAddedMap[item]! + 1;
              });
            },
            child: Text(
              'ADD',
              style: kAddButtonWordTextStyle,
            )),
      );
    }
  }

  @override
  void initState() {
    showSpinner = false;
    tappedPrintButton = false;
    printingError = false;
    requestLocationPermission();
    // TODO: implement initState
    //InInitStateItselfWeEnsureWeHaveTheNameOfAllTheItemsAddedSavedSeparately
    widget.itemsAddedMap.forEach((key, value) {
      nameOfItemsAdded.add(key);
    });
    itemsUpdaterString = '';

    _subscriptionBtStatus =
        PrinterManager.instance.stateBluetooth.listen((status) {
//OnlyIfBluetoothIsOnWeCanEvenGetIntoThisLoop
//IfBluetoothIsOffWeCanGiveShowMessageSomewhere
      bluetoothOnTrueOrOffFalse = true;
      _currentStatus = status;

      if (status == BTStatus.connecting && !bluetoothKotConnect) {
        intermediateTimerBeforeCheckingBluetoothConnectionSuccess();
      }

      if (status == BTStatus.connected) {
        printerConnectionSuccessCheckRandomNumber = 0;
        if (bluetoothKotConnect) {
          printThroughBluetoothOrUsb();
        }
        setState(() {
          _isConnected = true;
        });
      }
      if (status == BTStatus.none) {
        printerConnectionSuccessCheckRandomNumber = 0;
        if (bluetoothKotConnect || bluetoothKotConnectTried) {
          localKOTItemNames = [];
          localKOTNumberOfItems = [];
          localKOTItemComments = [];
          printerManager.disconnect(type: PrinterType.bluetooth);

          showMethodCaller('Unable To Connect. Please Check Printer');
          bluetoothKotConnect = false;
          bluetoothKotConnectTried = false;
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
        if (usbKotConnect) {
          printThroughBluetoothOrUsb();
        }
      } else if (status == USBStatus.none) {
        printerManager.disconnect(type: PrinterType.usb);
        if (usbKotConnect || usbKotConnectTried) {
          localKOTItemNames = [];
          localKOTNumberOfItems = [];
          localKOTItemComments = [];
          showMethodCaller('Unable To Connect. Please Check Printer');
          usbKotConnect = false;
          usbKotConnectTried = false;
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
      if (!bluetoothKotConnect) {
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

  void showMethodCaller(String showMessage) {
    show(showMessage);
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

  void showMethodCallerWithShowSpinnerOffForBluetooth(String showMessage) {
    show(showMessage);
    setState(() {
      showSpinner = false;
      bluetoothKotConnect = false;
      bluetoothKotConnectTried = false;
      _isConnected = false;
      tappedPrintButton = false;
    });
  }

  void errorAlertDialogBox(String errorMessage) async {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Center(
            child: Text(
          'Error!',
          style: TextStyle(color: Colors.red),
        )),
        content: Text(errorMessage),
        actions: [
          ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Ok')),
        ],
      ),
      barrierDismissible: false,
    );
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
                  print('location permission loop');
                  Navigator.pop(context);
                  setState(() {
                    locationPermissionAccepted = true;
                  });

                  print('came till this pop1');
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
      setState(() {
        locationPermissionAccepted = true;
      });
    }
  }

  void bytesGeneratorForKot() async {
    bytesForEachPrinter = [];
    String currentPrinterId = '';
    printerSavingMap = json.decode(
        Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .savedPrintersFromClass);

    List<String> itemNamesForEachPrinter = [];
    kotBytes = [];
    int counter = 0;

    for (var eachUserPrinting in separateKOTForEachUserInEachPrinterMap) {
      counter++;
      currentPrinterId = eachUserPrinting['printerId'];
      kotPrinterCharacters = printerSavingMap[currentPrinterId];
      localKOTItemNames = eachUserPrinting['printItemNames'];
      localKOTNumberOfItems = eachUserPrinting['printItemNumbers'];
      localKOTItemComments = eachUserPrinting['printItemComments'];
      var kotTextSize = kotPrinterCharacters['kotFontSize'] == 'Small'
          ? PosTextSize.size1
          : PosTextSize.size2;
      if (kotPrinterCharacters['printerSize'] == '80') {
        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm80, profile);

        if (kotPrinterCharacters['spacesAboveKOT'] != '0') {
          for (int i = 0;
              i < num.parse(kotPrinterCharacters['spacesAboveKOT']);
              i++) {
            kotBytes += generator.text(" ");
          }
        }
        kotBytes += generator.text("KOT : ${eachUserPrinting['slot']}",
            styles: PosStyles(
                height: PosTextSize.size2,
                width: PosTextSize.size2,
                align: PosAlign.center));
        kotBytes += generator.text(
            "Ticket Number : ${eachUserPrinting['ticketNumber']}",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.center));
        kotBytes += generator.text(
            "-----------------------------------------------",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.center));

        for (int i = 0; i < localKOTItemNames.length; i++) {
          itemNamesForEachPrinter.add(
              '${localKOTItemNames[i]} x ${localKOTNumberOfItems[i].toString()}');
          if (' '.allMatches(localKOTItemNames[i]).length >= 2) {
            String firstName = '';
            String secondName = '';
            final longItemNameSplit = localKOTItemNames[i].split(' ');
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
              if (i > 2) {
                secondName += '${longItemNameSplit[i]} ';
              }
            }
            kotBytes += generator.row([
              PosColumn(
                text: "$firstName",
                width: 10,
                styles: PosStyles(
                    align: PosAlign.left,
                    height: kotTextSize,
                    width: kotTextSize),
              ),
              PosColumn(
                text: "${localKOTNumberOfItems[i].toString()}",
                width: 2,
                styles: PosStyles(
                    align: PosAlign.right,
                    height: kotTextSize,
                    width: kotTextSize),
              ),
            ]);
            kotBytes += generator.row([
              PosColumn(
                text: "$secondName",
                width: 10,
                styles: PosStyles(
                    align: PosAlign.left,
                    height: kotTextSize,
                    width: kotTextSize),
              ),
              PosColumn(
                text: " ",
                width: 2,
                styles: PosStyles(
                    align: PosAlign.right,
                    height: kotTextSize,
                    width: kotTextSize),
              ),
            ]);
          } else {
            kotBytes += generator.row([
              PosColumn(
                text: "${localKOTItemNames[i]}",
                width: 10,
                styles: PosStyles(
                    align: PosAlign.left,
                    height: kotTextSize,
                    width: kotTextSize),
              ),
              PosColumn(
                text: "${localKOTNumberOfItems[i].toString()}",
                width: 2,
                styles: PosStyles(
                    align: PosAlign.right,
                    height: kotTextSize,
                    width: kotTextSize),
              ),
            ]);
          }
          if (localKOTItemComments[i] != 'nocomments') {
            kotBytes += generator.text(
                "     (Comment : ${localKOTItemComments[i]})",
                styles: PosStyles(
                    height: kotTextSize,
                    width: kotTextSize,
                    align: PosAlign.left));
          }
          kotBytes += generator.text(
              "-----------------------------------------------",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.center));
        }
        if (kotPrinterCharacters['spacesBelowKOT'] != 0) {
          for (int i = 0;
              i < num.parse(kotPrinterCharacters['spacesBelowKOT']);
              i++) {
            kotBytes += generator.text(" ");
          }
        }
        kotBytes += generator.cut();
      } else if (kotPrinterCharacters['printerSize'] == '58') {
        final profile = await CapabilityProfile.load();
        final generator = Generator(PaperSize.mm58, profile);
        if (kotPrinterCharacters['spacesAboveKOT'] != 0) {
          for (int i = 0;
              i < num.parse(kotPrinterCharacters['spacesAboveKOT']);
              i++) {
            kotBytes += generator.text(" ");
          }
        }
        kotBytes += generator.text("KOT : ${eachUserPrinting['slot']}",
            styles: PosStyles(
                height: PosTextSize.size2,
                width: PosTextSize.size2,
                align: PosAlign.center));
        kotBytes += generator.text(
            "Ticket Number : ${eachUserPrinting['ticketNumber']}",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.center));
        kotBytes += generator.text("-------------------------------",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.center));
        for (int i = 0; i < localKOTItemNames.length; i++) {
          itemNamesForEachPrinter.add(
              '${localKOTItemNames[i]} x ${localKOTNumberOfItems[i].toString()}');
          if ((' '.allMatches(localKOTItemNames[i]).length >= 2) ||
              localKOTItemNames[i].length > 14) {
            String firstName = '';
            String secondName = '';
            final longItemNameSplit = localKOTItemNames[i].split(' ');
            for (int i = 0; i < longItemNameSplit.length; i++) {
              if (i == 0) {
                firstName = longItemNameSplit[i];
              }

              if (i >= 1) {
                secondName += '${longItemNameSplit[i]} ';
              }
            }
            kotBytes += generator.row([
              PosColumn(
                text: "$firstName",
                width: 10,
                styles: PosStyles(
                    align: PosAlign.left,
                    height: kotTextSize,
                    width: kotTextSize),
              ),
              PosColumn(
                text: "${localKOTNumberOfItems[i].toString()}",
                width: 2,
                styles: PosStyles(
                    align: PosAlign.right,
                    height: kotTextSize,
                    width: kotTextSize),
              ),
            ]);
            kotBytes += generator.row([
              PosColumn(
                text: "$secondName",
                width: 10,
                styles: PosStyles(
                    align: PosAlign.left,
                    height: kotTextSize,
                    width: kotTextSize),
              ),
              PosColumn(
                text: " ",
                width: 2,
                styles: PosStyles(
                    align: PosAlign.right,
                    height: kotTextSize,
                    width: kotTextSize),
              ),
            ]);
          } else {
            kotBytes += generator.row([
              PosColumn(
                text: "${localKOTItemNames[i]}",
                width: 10,
                styles: PosStyles(
                    align: PosAlign.left,
                    height: kotTextSize,
                    width: kotTextSize),
              ),
              PosColumn(
                text: "${localKOTNumberOfItems[i].toString()}",
                width: 2,
                styles: PosStyles(
                    align: PosAlign.right,
                    height: kotTextSize,
                    width: kotTextSize),
              ),
            ]);
          }

          if (localKOTItemComments[i] != 'nocomments') {
            kotBytes += generator.text(
                "     (Comment : ${localKOTItemComments[i]})",
                styles: PosStyles(
                    height: kotTextSize,
                    width: kotTextSize,
                    align: PosAlign.left));
          }
          kotBytes += generator.text("-------------------------------",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.center));
        }
        if (kotPrinterCharacters['spacesBelowKOT'] != 0) {
          for (int i = 0;
              i < num.parse(kotPrinterCharacters['spacesBelowKOT']);
              i++) {
            kotBytes += generator.text(" ");
          }
        }
        kotBytes += generator.cut();
      }
      if (counter == separateKOTForEachUserInEachPrinterMap.length) {
//MeansThisIsTheLastItemInTheArray
        bytesForEachPrinter.add({
          'printerId': currentPrinterId,
          'kotBytesToPrint': kotBytes,
          'itemsInEachPrinter': itemNamesForEachPrinter
        });
        printCallForEachPrinter(0);
      } else if (currentPrinterId !=
          separateKOTForEachUserInEachPrinterMap[counter]['printerId']) {
//CheckingWhetherThisPrinterIDAndNextUserPrinterIDIsSame
//IfNotWeWillAddToTheBytesListHereAndMakeKotBytesEmpty
// SoThatItCanStartFreshForNextPrinter
        bytesForEachPrinter.add({
          'printerId': currentPrinterId,
          'kotBytesToPrint': kotBytes,
          'itemsInEachPrinter': itemNamesForEachPrinter
        });
        kotBytes = [];
        itemNamesForEachPrinter = [];
      }
    }

    print('end of inside Bytes Generator');
  }

  void printCallForEachPrinter(int indexInTheArray) {
    Map<String, dynamic> printerBytesMap = bytesForEachPrinter[indexInTheArray];
    String neededPrinterId = printerBytesMap['printerId'];
    currentPrintBytes = printerBytesMap['kotBytesToPrint'];
    currentKotPrinterCharacters = printerSavingMap[neededPrinterId];
    if (currentKotPrinterCharacters['printerBluetoothAddress'] != 'NA') {
      _connectDevice();
    } else if (currentKotPrinterCharacters['printerIPAddress'] != 'NA') {
//Currently,OnlyInLanPrinterWeCanProceedWithMoreThanOnePrinter
//SoThereAlonePassingTheIndexSoThatWeCanCheckWhetherAnyMorePrintersAreLeft
      if (showSpinner == false) {
        setState(() {
          showSpinner = true;
        });
      }
      if (kotPrinterAssigningMap.length == 1) {
        printWithSingleAssignedNetworkPrinter();
      } else {
        printWithMultipleNetworkPrinter(indexInTheArray);
      }
    } else {
//InCaseUsbPrinterIsNotConnected,WeDontHaveWayToFind.Hence,WeScanAndThenGoIn
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
          currentKotPrinterCharacters['printerUsbVendorID']) {
        addedUSBDeviceNotAvailable = false;
        _connectDevice();
      }
    });
    Timer(Duration(seconds: 2), () {
      if (addedUSBDeviceNotAvailable) {
        printerManager.disconnect(type: PrinterType.usb);
        setState(() {
          showSpinner = false;
          usbKotConnect = false;
          usbKotConnectTried = false;
          _isConnected = false;
          tappedPrintButton = false;
        });
        show('${currentKotPrinterCharacters['printerName']} not found');
      }
    });
  }

  _connectDevice() async {
    kotPrinterType = currentKotPrinterCharacters['printerUsbProductID'] != 'NA'
        ? PrinterType.usb
        : currentKotPrinterCharacters['printerBluetoothAddress'] != 'NA'
            ? PrinterType.bluetooth
            : PrinterType.network;
    _isConnected = false;
    setState(() {
      showSpinner = true;
    });
    switch (kotPrinterType) {
      case PrinterType.usb:
        printerManager.disconnect(type: PrinterType.usb);
        usbKotConnectTried = true;
        await printerManager.connect(
            type: kotPrinterType,
            model: UsbPrinterInput(
                name: currentKotPrinterCharacters[
                    'printerManufacturerDeviceName'],
                productId: currentKotPrinterCharacters['printerUsbProductID'],
                vendorId: currentKotPrinterCharacters['printerUsbVendorID']));
        usbKotConnect = true;
        _isConnected = true;
        setState(() {
          showSpinner = true;
        });
        break;
      case PrinterType.bluetooth:
        bluetoothKotConnectTried = true;
        bluetoothKotConnect = false;
        bluetoothOnTrueOrOffFalse = false;
        timerToCheckBluetoothOnOrOff();
        await printerManager.connect(
            type: kotPrinterType,
            model: BluetoothPrinterInput(
                name: currentKotPrinterCharacters[
                    'printerManufacturerDeviceName'],
                address: currentKotPrinterCharacters['printerBluetoothAddress'],
                isBle: false,
                autoConnect: _reconnect));
        bluetoothKotConnect = true;
        break;
      default:
    }

    setState(() {});
  }

  void timerToCheckBluetoothOnOrOff() {
    print('came inside timerToCheckBluetoothOnOrOff');
//OnceWeAskToConnectThroughBluetoothWithinSecondsItGoesIntoStatus
//AndSaysBluetoothIsOn
//InCaseIfItIsn'tSayingHereWeCanShowToCheckBluetooth
    Timer(Duration(seconds: 1), () {
      if (!bluetoothOnTrueOrOffFalse) {
        printerManager.disconnect(type: PrinterType.bluetooth);
        show('Please Check Bluetooth, Printer & try Printing Again');
        bluetoothKotConnect = false;
        bluetoothKotConnectTried = false;
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
    printerManager.send(type: kotPrinterType, bytes: currentPrintBytes);
    if (kotPrinterType == PrinterType.bluetooth) {
      showMethodCaller('Print SUCCESS...Disconnecting...');
    }
    Timer(Duration(seconds: 1), () {
      disconnectBluetoothOrUsb();
    });
  }

  void disconnectBluetoothOrUsb() {
    addRunningOrderToServer();
    printerManager.disconnect(type: kotPrinterType);
    kotPrinterType == PrinterType.bluetooth
        ? Timer(Duration(seconds: 2), () {
            localKOTItemNames = [];
            localKOTNumberOfItems = [];
            localKOTItemComments = [];
            setState(() {
              showSpinner = false;
              usbKotConnect = false;
              usbKotConnectTried = false;
              bluetoothKotConnect = false;
              bluetoothKotConnectTried = false;
              _isConnected = false;
              tappedPrintButton = false;
            });
            Navigator.pop(context);
          })
        : Timer(Duration(milliseconds: 500), () {
            localKOTItemNames = [];
            localKOTNumberOfItems = [];
            localKOTItemComments = [];
            setState(() {
              showSpinner = false;
              usbKotConnect = false;
              usbKotConnectTried = false;
              bluetoothKotConnect = false;
              bluetoothKotConnectTried = false;
              _isConnected = false;
              tappedPrintButton = false;
            });
            Navigator.pop(context);
          });
  }

  Future<void> printWithSingleAssignedNetworkPrinter() async {
    final printer =
        PrinterNetworkManager(currentKotPrinterCharacters['printerIPAddress']);
    PosPrintResult connect = await printer.connect();
    if (connect == PosPrintResult.success) {
      PosPrintResult printing =
          await printer.printTicket(Uint8List.fromList(currentPrintBytes));
      printer.disconnect();
      addRunningOrderToServer();
      Timer(Duration(seconds: 1), () {
        localKOTItemNames = [];
        localKOTNumberOfItems = [];
        localKOTItemComments = [];
      });
      setState(() {
        showSpinner = false;
        tappedPrintButton = false;
        _isConnected = false;
      });
      Navigator.pop(context);
    } else {
      localKOTItemNames = [];
      localKOTNumberOfItems = [];
      localKOTItemComments = [];
      setState(() {
        showSpinner = false;
        tappedPrintButton = false;
        _isConnected = false;
      });
      show(
          'Unable To Connect to ${currentKotPrinterCharacters['printerName']}. Please Check Printer');
    }
  }

  Future<void> printWithMultipleNetworkPrinter(
      int indexOfThisPrinterInArray) async {
    final printer =
        PrinterNetworkManager(currentKotPrinterCharacters['printerIPAddress']);
    PosPrintResult connect = await printer.connect();
    if (connect == PosPrintResult.success) {
      PosPrintResult printing =
          await printer.printTicket(Uint8List.fromList(currentPrintBytes));
      printer.disconnect();
      if ((indexOfThisPrinterInArray + 1) == bytesForEachPrinter.length) {
        setState(() {
          showSpinner = false;
          tappedPrintButton = false;
          _isConnected = false;
        });
        if (couldntConnectPrintersBytesForEachPrinter.isEmpty) {
          addRunningOrderToServer();
          Timer(Duration(seconds: 1), () {
            localKOTItemNames = [];
            localKOTNumberOfItems = [];
            localKOTItemComments = [];
            Navigator.pop(context);
          });
        } else {
          localKOTItemNames = [];
          localKOTNumberOfItems = [];
          localKOTItemComments = [];
          buildBottomSheetForFailedPrinters();
        }
      } else {
//NextPrinterCall
        printCallForEachPrinter(indexOfThisPrinterInArray + 1);
      }
    } else {
      if ((indexOfThisPrinterInArray + 1) < bytesForEachPrinter.length) {
        setState(() {
          showSpinner = false;
          tappedPrintButton = false;
          _isConnected = false;
        });
        show(
            'Unable To Connect to ${currentKotPrinterCharacters['printerName']}. Please Check Printer');
        couldntConnectPrintersBytesForEachPrinter
            .add(bytesForEachPrinter[indexOfThisPrinterInArray]);
//WeWillSayCantPrintForFirstPrinterAndCallForNextPrinterPrintInTwoSeconds
        Timer(Duration(seconds: 2), () {
          printCallForEachPrinter(indexOfThisPrinterInArray + 1);
        });
      } else {
//ThisMeansThisIsTheLastPrinter
        localKOTItemNames = [];
        localKOTNumberOfItems = [];
        localKOTItemComments = [];
        setState(() {
          showSpinner = false;
          tappedPrintButton = false;
          _isConnected = false;
        });
        couldntConnectPrintersBytesForEachPrinter
            .add(bytesForEachPrinter[indexOfThisPrinterInArray]);
        buildBottomSheetForFailedPrinters();
      }
    }
  }

  void printCallForEachCouldntConnectPrinter(int indexInTheArray) {
    if (indexInTheArray == 0) {
      indexesToRemove = [];
//ToEnsureTheListIsClearedBeforeStartingThePrint
    }
    Map<String, dynamic> printerBytesMap =
        couldntConnectPrintersBytesForEachPrinter[indexInTheArray];
    String neededPrinterId = printerBytesMap['printerId'];
    currentPrintBytes = printerBytesMap['kotBytesToPrint'];
    currentKotPrinterCharacters = printerSavingMap[neededPrinterId];

//Currently,OnlyInLanPrinterWeCanProceedWithMoreThanOnePrinter
//SoThereAlonePassingTheIndexSoThatWeCanCheckWhetherAnyMorePrintersAreLeft
    if (showSpinner == false) {
      setState(() {
        showSpinner = true;
      });
    }
    printWithMultipleNetworkPrinterFromFailedPrintingBottomSheet(
        indexInTheArray);
  }

  Future<void> printWithMultipleNetworkPrinterFromFailedPrintingBottomSheet(
      int indexOfThisPrinterInArray) async {
    final printer =
        PrinterNetworkManager(currentKotPrinterCharacters['printerIPAddress']);
    PosPrintResult connect = await printer.connect();
    if (connect == PosPrintResult.success) {
      PosPrintResult printing =
          await printer.printTicket(Uint8List.fromList(currentPrintBytes));
      printer.disconnect();
      setState(() {
        showSpinner = false;
        tappedPrintButton = false;
        _isConnected = false;
      });
      indexesToRemove.add(indexOfThisPrinterInArray);
      if (indexesToRemove.length ==
          couldntConnectPrintersBytesForEachPrinter.length) {
        addRunningOrderToServer();
        Timer(Duration(seconds: 1), () {
          localKOTItemNames = [];
          localKOTNumberOfItems = [];
          localKOTItemComments = [];
          int count = 0;
          Navigator.of(context).popUntil((_) => count++ >= 1);
        });
      } else if ((indexOfThisPrinterInArray + 1) ==
          couldntConnectPrintersBytesForEachPrinter.length) {
//ThisMeansAllThePrintersHadBeenChecked

        indexesToRemove.sort((b, a) => a.compareTo(b));
        for (int i = 0; i < indexesToRemove.length; i++) {
          couldntConnectPrintersBytesForEachPrinter
              .removeAt(indexesToRemove[i]);
        }
        buildBottomSheetForFailedPrinters();
      } else {
        printCallForEachCouldntConnectPrinter(indexOfThisPrinterInArray + 1);
      }
    } else {
//InCaseIfPrinterConnectionFailed
      if ((indexOfThisPrinterInArray + 1) <
          couldntConnectPrintersBytesForEachPrinter.length) {
        setState(() {
          showSpinner = false;
          tappedPrintButton = false;
          _isConnected = false;
        });
        show(
            'Unable To Connect to ${currentKotPrinterCharacters['printerName']}. Please Check Printer');
//WeWillSayCantPrintForFirstPrinterAndCallForNextPrinterPrintInTwoSeconds
        Timer(Duration(seconds: 2), () {
          printCallForEachCouldntConnectPrinter(indexOfThisPrinterInArray + 1);
        });
      } else {
//ThisMeansItsTheLastPrinterInTheArray
        setState(() {
          showSpinner = false;
          tappedPrintButton = false;
          _isConnected = false;
        });

        indexesToRemove.sort((b, a) => a.compareTo(b));
        for (int i = 0; i < indexesToRemove.length; i++) {
          couldntConnectPrintersBytesForEachPrinter
              .removeAt(indexesToRemove[i]);
        }
        buildBottomSheetForFailedPrinters();
      }
    }
  }

  void buildBottomSheetForFailedPrinters() {
    List<Widget> bottomSheetListViews = [];
    int indexCounter = -1;
    final ScrollController _controllerOne = ScrollController();

    for (var eachCouldntConnectPrinterMap
        in couldntConnectPrintersBytesForEachPrinter) {
      indexCounter++;
      String eachCouldntConnectPrinterId =
          eachCouldntConnectPrinterMap['printerId'];
      List<String> eachCouldntConnectPrinterItems =
          eachCouldntConnectPrinterMap['itemsInEachPrinter'];
      List<Widget> itemTextWidgets = [];
      for (var eachItem in eachCouldntConnectPrinterItems) {
        itemTextWidgets.add(Text(eachItem, textAlign: TextAlign.center));
      }
      bottomSheetListViews.add(SizedBox(height: 10));
      bottomSheetListViews.add(
        Text(
            'Couldn\'t Connect ${printerSavingMap[eachCouldntConnectPrinterId]['printerName']}',
            style: TextStyle(fontSize: 20, color: Colors.red)),
      );
      bottomSheetListViews.add(SizedBox(height: 10));
      bottomSheetListViews.add(Container(
        height: eachCouldntConnectPrinterItems.length < 10
            ? eachCouldntConnectPrinterItems.length * 15
            : 150,
        width: 300,
        child: Scrollbar(
          controller: _controllerOne,
          thumbVisibility: true,
          trackVisibility: true,
          child: ListView(
            children: [
              ...itemTextWidgets,
            ],
          ),
        ),
      ));
      bottomSheetListViews.add(
        ElevatedButton(
          style: ButtonStyle(
              backgroundColor:
                  MaterialStateProperty.all<Color>(Colors.orangeAccent)),
          onPressed: () async {
            setState(() {
              showSpinner = true;
            });
            final printer = PrinterNetworkManager(
                '${printerSavingMap[eachCouldntConnectPrinterId]['printerIPAddress']}');
            PosPrintResult connect = await printer.connect();
            if (connect == PosPrintResult.success) {
              PosPrintResult printing = await printer.printTicket(
                  Uint8List.fromList(
                      eachCouldntConnectPrinterMap['kotBytesToPrint']));
              printer.disconnect();
              localKOTItemNames = [];
              localKOTNumberOfItems = [];
              localKOTItemComments = [];

              setState(() {
                showSpinner = false;
                tappedPrintButton = false;
                _isConnected = false;
              });
              couldntConnectPrintersBytesForEachPrinter
                  .remove(eachCouldntConnectPrinterMap);
              if (couldntConnectPrintersBytesForEachPrinter.isEmpty) {
                addRunningOrderToServer();
                Timer(Duration(seconds: 1), () {
                  int count = 0;
                  Navigator.of(context).popUntil((_) => count++ >= 2);
                });
              } else {
                Navigator.pop(context);
                buildBottomSheetForFailedPrinters();
              }
            } else {
              localKOTItemNames = [];
              localKOTNumberOfItems = [];
              localKOTItemComments = [];
              setState(() {
                showSpinner = false;
                tappedPrintButton = false;
                _isConnected = false;
              });
              Navigator.pop(context);
              show(
                  'Unable To Connect to ${printerSavingMap[eachCouldntConnectPrinterId]['printerName']}. Please Check Printer');
              Timer(Duration(seconds: 2), () {
                buildBottomSheetForFailedPrinters();
              });
            }
          },
          child: Text('Retry Print'),
        ),
      );
      bottomSheetListViews.add(Divider(
        thickness: 3,
      ));
    }
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setStateSB) {
            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: [
                  SizedBox(height: 10),
                  ...bottomSheetListViews,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                          style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Colors.orangeAccent)),
                          onPressed: () {
                            Navigator.pop(context);
                            printCallForEachCouldntConnectPrinter(0);
                          },
                          child: Text('Retry All')),
                      ElevatedButton(
                          style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Colors.green)),
                          onPressed: () {
                            addRunningOrderToServer();
                            Timer(Duration(seconds: 1), () {
                              int count = 0;
                              Navigator.of(context)
                                  .popUntil((_) => count++ >= 2);
                            });
                          },
                          child: Text('Send Without Print'))
                    ],
                  )
                ],
              ),
            );
          });
        });
  }

  void addRunningOrderToServer() {
    bool atLeastOneItemIsThereToAdd = false;
    num tempMinValueNum = 172800000; //ItsTheNumberOfMillisecondsIntwoDays

    widget.itemsAddedMap.forEach((key, value) {
//InCaseInFinalKotScreenIfAllItemsHadBeenRemovedFromTheScreen
      if (widget.itemsAddedMap[key] != 0) {
        atLeastOneItemIsThereToAdd = true;
//HereWeCalculateTheStartTimeOfOrder
        if (widget.itemsAddedTime[key]! < tempMinValueNum) {
          tempMinValueNum = widget.itemsAddedTime[key]!;
        }
      }
    });
    if (atLeastOneItemIsThereToAdd) {
      final fcmProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      DateTime now = DateTime.now();

      Map<String, dynamic> masterOrderMapToServer = HashMap();
      Map<String, dynamic> baseInfoMap = HashMap();
      Map<String, dynamic> itemsInOrderMap = HashMap();
      Map<String, dynamic> tempItemAddingMap = HashMap();
      Map<String, dynamic> ticketsMap = HashMap();
      Map<String, dynamic> statusMap = HashMap();

      if (widget.alreadyRunningTicketsMap.isEmpty) {
        baseInfoMap.addAll({
//WeMake7DigitRandomIDForEachTable
          'orderID':
              ((1000000 + Random().nextInt(9999999 - 1000000)).toString())
        });
        baseInfoMap.addAll({'tableOrParcel': widget.tableOrParcel});
        baseInfoMap.addAll(
            {'tableOrParcelNumber': widget.tableOrParcelNumber.toString()});
        baseInfoMap.addAll({'startTime': (tempMinValueNum - 1000).toString()});
//WeReduceByOneSec,SoThatWeReduceTheTimeOfSmallestOfOrderLessThanOneSecToGetTheStartOfTable
        baseInfoMap.addAll({'customerName': ''});
        baseInfoMap.addAll({'customerMobileNumber': ''});
        baseInfoMap.addAll({'customerAddress': ''});
        baseInfoMap.addAll({'parentOrChild': widget.parentOrChild});
        baseInfoMap.addAll({'serialNumber': 'noSerialYet'});
        baseInfoMap.addAll({'discountEnteredValue': ''});
        baseInfoMap.addAll({'discountValueTruePercentageFalse': true});
        baseInfoMap.addAll({'billYear': ''});
        baseInfoMap.addAll({'billMonth': ''});
        baseInfoMap.addAll({'billDay': ''});
        baseInfoMap.addAll({'billHour': ''});
        baseInfoMap.addAll({'billMinute': ''});
        baseInfoMap.addAll({'billSecond': ''});
        baseInfoMap.addAll({'billPrinted': false});
        baseInfoMap.addAll({'billClosingPhoneOrderIdWithTime': {}});
        masterOrderMapToServer.addAll({'baseInfoMap': baseInfoMap});
        ticketsMap.addAll({
          Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .currentUserPhoneNumberFromClass: FieldValue.increment(1)
        });
        masterOrderMapToServer.addAll({'ticketsMap': ticketsMap});
        statusMap.addAll({'chefStatus': 9});
        statusMap.addAll({'captainStatus': 9});
        masterOrderMapToServer.addAll({'statusMap': statusMap});

        widget.itemsAddedMap.forEach((key, value) {
          tempItemAddingMap = {};
          String itemComment = 'noComment';
          num itemPrice = 0;
          String itemCategory = '';
//InCase,TheWaiterReducedItToZero,ThenWeShouldn'tAddItRight
          if (widget.itemsAddedMap[key] != 0) {
            final filteredItem = allItemsFromMenuMap
                .firstWhere((element) => element['itemName'] == key);
            itemPrice = filteredItem['price'];
            itemCategory = filteredItem['category'];
            tempItemAddingMap.addAll({'itemName': key});
            if (widget.itemsAddedComment[key] != '') {
              itemComment = widget.itemsAddedComment[key]!;
            }
            tempItemAddingMap.addAll({'itemComment': itemComment});
            tempItemAddingMap.addAll({'itemPrice': itemPrice});
            tempItemAddingMap.addAll({'itemCategory': itemCategory});
            tempItemAddingMap
                .addAll({'numberOfItem': widget.itemsAddedMap[key]});
            tempItemAddingMap.addAll(
                {'orderTakingTime': (widget.itemsAddedTime[key]).toString()});
            tempItemAddingMap.addAll({'itemStatus': 9});
            tempItemAddingMap.addAll({'chefKOT': 'chefkotnotyet'});
            tempItemAddingMap.addAll({'ticketNumberOfItem': '1'});
            tempItemAddingMap.addAll({'itemCancelled': 'false'});
            tempItemAddingMap.addAll({
              'captainPhoneNumber': Provider.of<PrinterAndOtherDetailsProvider>(
                      context,
                      listen: false)
                  .currentUserPhoneNumberFromClass
            });
            tempItemAddingMap.addAll({
              'captainName': json.decode(
                      Provider.of<PrinterAndOtherDetailsProvider>(context,
                              listen: false)
                          .allUserProfilesFromClass)[
                  Provider.of<PrinterAndOtherDetailsProvider>(context,
                          listen: false)
                      .currentUserPhoneNumberFromClass]['username']
            });
            tempItemAddingMap.addAll({'cancellingCaptainName': 'notCancelled'});
            tempItemAddingMap
                .addAll({'cancellingCaptainPhone': 'notCancelled'});
            tempItemAddingMap.addAll({'rejectingChefName': 'notRejected'});
            tempItemAddingMap.addAll({'rejectingChefPhone': 'notRejected'});
            //AddingItemWithRandomID
            itemsInOrderMap.addAll({
              (10000 + Random().nextInt(99999 - 10000)).toString():
                  tempItemAddingMap
            });
          }
        });
        masterOrderMapToServer.addAll({'itemsInOrderMap': itemsInOrderMap});
        masterOrderMapToServer
            .addAll({'partOfTableOrParcel': widget.tableOrParcel});
        masterOrderMapToServer.addAll({
          'partOfTableOrParcelNumber': widget.tableOrParcelNumber.toString()
        });
      } else {
        if (widget.alreadyRunningTicketsMap.isNotEmpty) {
          num tempTicketUpdater = 1;
          widget.alreadyRunningTicketsMap.forEach((key, value) {
            tempTicketUpdater += value;
          });
          ticketNumberUpdater = tempTicketUpdater.toString();
        }
        ticketsMap.addAll({
          Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .currentUserPhoneNumberFromClass: FieldValue.increment(1)
        });
        masterOrderMapToServer.addAll({'ticketsMap': ticketsMap});
        statusMap.addAll({'chefStatus': 9});
        masterOrderMapToServer.addAll({'statusMap': statusMap});
        widget.itemsAddedMap.forEach((key, value) {
          tempItemAddingMap = {};
          String itemComment = 'noComment';
          String itemCategory = '';
          num itemPrice = 0;
          if (widget.itemsAddedMap[key] != 0) {
            final filteredItem = allItemsFromMenuMap
                .firstWhere((element) => element['itemName'] == key);
            itemPrice = filteredItem['price'];
            itemCategory = filteredItem['category'];
            tempItemAddingMap.addAll({'itemName': key});
            if (widget.itemsAddedComment[key] != '') {
              itemComment = widget.itemsAddedComment[key]!;
            }
            tempItemAddingMap.addAll({'itemComment': itemComment});
            tempItemAddingMap.addAll({'itemPrice': itemPrice});
            tempItemAddingMap.addAll({'itemCategory': itemCategory});
            tempItemAddingMap
                .addAll({'numberOfItem': widget.itemsAddedMap[key]});
            tempItemAddingMap.addAll(
                {'orderTakingTime': (widget.itemsAddedTime[key]).toString()});
            tempItemAddingMap.addAll({'itemStatus': 9});
            tempItemAddingMap.addAll({'chefKOT': 'chefkotnotyet'});
            tempItemAddingMap
                .addAll({'ticketNumberOfItem': ticketNumberUpdater});
            tempItemAddingMap.addAll({'itemCancelled': 'false'});
            tempItemAddingMap.addAll({
              'captainPhoneNumber': Provider.of<PrinterAndOtherDetailsProvider>(
                      context,
                      listen: false)
                  .currentUserPhoneNumberFromClass
            });
            tempItemAddingMap.addAll({
              'captainName': json.decode(
                      Provider.of<PrinterAndOtherDetailsProvider>(context,
                              listen: false)
                          .allUserProfilesFromClass)[
                  Provider.of<PrinterAndOtherDetailsProvider>(context,
                          listen: false)
                      .currentUserPhoneNumberFromClass]['username']
            });
            tempItemAddingMap.addAll({'cancellingCaptainName': 'notCancelled'});
            tempItemAddingMap
                .addAll({'cancellingCaptainPhone': 'notCancelled'});
            tempItemAddingMap.addAll({'rejectingChefName': 'notRejected'});
            tempItemAddingMap.addAll({'rejectingChefPhone': 'notRejected'});
            //AddingItemWithRandomID
            itemsInOrderMap.addAll({
              (10000 + Random().nextInt(99999 - 10000)).toString():
                  tempItemAddingMap
            });
          }
        });
        masterOrderMapToServer.addAll({'itemsInOrderMap': itemsInOrderMap});
      }
      String seatingNumberForOrder = widget.parentOrChild == 'parent'
          ? '${widget.tableOrParcel}:${widget.tableOrParcelNumber}'
          : '${widget.tableOrParcel}:${widget.tableOrParcelNumber}${widget.parentOrChild}';
      FireStoreAddOrderInRunningOrderFolder(
              hotelName: widget.hotelName,
              seatingNumber: seatingNumberForOrder,
              ordersMap: masterOrderMapToServer)
          .addOrder();
      fcmProvider.sendNotification(
          token: dynamicTokensToStringToken(),
          title: widget.hotelName,
          restaurantNameForNotification: json.decode(
                  Provider.of<PrinterAndOtherDetailsProvider>(context,
                          listen: false)
                      .allUserProfilesFromClass)[
              Provider.of<PrinterAndOtherDetailsProvider>(context,
                      listen: false)
                  .currentUserPhoneNumberFromClass]['restaurantName'],
          body: '*newOrderForCook*');
    } else {
      show('Please Add Items');
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

  @override
  Widget build(BuildContext context) {
    allUserProfile = json.decode(
        Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .allUserProfilesFromClass);
    allItemsFromMenuMap = json.decode(
        Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .entireMenuFromClass);

    Widget commentsSection(BuildContext context, String item) {
      String commentForTheItem = widget.itemsAddedComment[item]!;
      return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              child: TextField(
                maxLength: 250,
                controller:
                    TextEditingController(text: widget.itemsAddedComment[item]),
                onChanged: (value) {
                  commentForTheItem = value;
                },
                decoration:
                    // kTextFieldInputDecoration,
                    InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Enter Comments',
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
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.green),
                ),
                onPressed: () {
                  setState(() {
                    widget.itemsAddedComment[item] = commentForTheItem;
                  });
                  Navigator.pop(context);
                },
                child: Text('Done'))
          ],
        ),
      );
    }
    //WillPopScopeIsForTheBackButtonInPhone.WeCanDecideWhatShouldHappen,
    //WhenBackButtonIsClicked
    //AndItCouldOnlyBeAsyncOnly.That'sTheRule

    return WillPopScope(
      onWillPop: () async {
        setState(() {
          showSpinner = false;

          tappedPrintButton = false;
          print('12 $tappedPrintButton');
        });

        int _everyMilliSecondBeforeGoingBack = 0;
        Timer? _timerAtBackButton;
        List<String> deletingItemsIfNotThere = [];
        _timerAtBackButton = Timer.periodic(Duration(milliseconds: 100), (_) {
          widget.itemsAddedMap.forEach((key, value) {
            if (widget.itemsAddedMap[key] == 0) {
              deletingItemsIfNotThere.add(key);
            }
          });
          //WeNeedThisStepOnlyIfTheWaiterHasMadeSomeItemZero
          //IfThereIsSomethingThat'sZero,
          //WeRemoveItFromItemsAddedMapWithTheBelowLoop
          if (deletingItemsIfNotThere.isNotEmpty) {
            for (var item in deletingItemsIfNotThere) {
              widget.itemsAddedMap.remove(item);
              widget.itemsAddedComment.remove(item);
              widget.itemsAddedTime.remove(item);
            }
          }
          // print('back timer is $_everyMilliSecondBeforeGoingBack');
          // return false;
          _everyMilliSecondBeforeGoingBack++;
          if (_everyMilliSecondBeforeGoingBack >= 4) {
            // print('back timer at cancel is $_everyMilliSecondBeforeGoingBack');
            _timerAtBackButton!.cancel();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MenuPageWithBackButtonUsage(
                  hotelName: widget.hotelName,
                  tableOrParcel: widget.tableOrParcel,
                  tableOrParcelNumber: widget.tableOrParcelNumber,
                  menuItems: widget.menuItems,
                  menuPrices: widget.menuPrices,
                  menuTitles: widget.menuTitles,
                  itemsAddedMapCalled: widget.itemsAddedMap,
                  itemsAddedCommentCalled: widget.itemsAddedComment,
                  itemsAddedTimeCalled: widget.itemsAddedTime,
                  parentOrChild: widget.parentOrChild,
                  alreadyRunningTicketsMap: widget.alreadyRunningTicketsMap,
                ),
              ),
            );
            print('back timer at true is is $_everyMilliSecondBeforeGoingBack');
            // return true;
            // Navigator.pop(context);
            // return true;

          }
        });
        //DuringConfirmOrdersTheCustomerMightSayTheyDon'tWantSomeItem,,
        //AndTheWaiterWillPressMinusAndBringItZero
        //InTheBelowStep,firstWeMakeAListOfAllItemsThatHasZero

        //SinceTheBackButtonHasBeenPressed,WeNeedToGoBackToTheMenu
        //TheInputWillBeBelow
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          //ThisIsTheBackButtonInTheAppBar
          //EveryFunctionInsideThisIsSameAsOnWillPopMethodMentionedAbove
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: kAppBarBackIconColor),
            onPressed: () {
              setState(() {
                showSpinner = false;

                tappedPrintButton = false;
                print('12 $tappedPrintButton');
              });

              int _everyMilliSecondBeforeGoingBack = 0;
              List<String> deletingItemsIfNotThere = [];
              Timer? _timerAtBackButton;
              _timerAtBackButton =
                  Timer.periodic(Duration(milliseconds: 100), (_) {
                widget.itemsAddedMap.forEach((key, value) {
                  if (widget.itemsAddedMap[key] == 0) {
                    deletingItemsIfNotThere.add(key);
                  }
                });
                //WeNeedThisStepOnlyIfTheWaiterHasMadeSomeItemZero
                //IfThereIsSomethingThat'sZero,
                //WeRemoveItFromItemsAddedMapWithTheBelowLoop
                if (deletingItemsIfNotThere.isNotEmpty) {
                  for (var item in deletingItemsIfNotThere) {
                    widget.itemsAddedMap.remove(item);
                  }
                }
                // print('back timer is $_everyMilliSecondBeforeGoingBack');
                // return false;
                _everyMilliSecondBeforeGoingBack++;
                if (_everyMilliSecondBeforeGoingBack >= 4) {
                  // print(
                  //     'back timer at cancel is $_everyMilliSecondBeforeGoingBack');
                  _timerAtBackButton!.cancel();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MenuPageWithBackButtonUsage(
                        hotelName: widget.hotelName,
                        tableOrParcel: widget.tableOrParcel,
                        tableOrParcelNumber: widget.tableOrParcelNumber,
                        menuItems: widget.menuItems,
                        menuPrices: widget.menuPrices,
                        menuTitles: widget.menuTitles,
                        itemsAddedMapCalled: widget.itemsAddedMap,
                        itemsAddedCommentCalled: widget.itemsAddedComment,
                        itemsAddedTimeCalled: widget.itemsAddedTime,
                        parentOrChild: widget.parentOrChild,
                        alreadyRunningTicketsMap:
                            widget.alreadyRunningTicketsMap,
                      ),
                    ),
                  );
                  print(
                      'back timer at true is is $_everyMilliSecondBeforeGoingBack');
                  // return true;
                  // Navigator.pop(context);
                  // return true;

                }
              });
            },
          ),
          backgroundColor: kAppBarBackgroundColor,
          //TitleOfAppbarWillBeWhetherItIsTableOrParcel
          // AndTheTable/ParcelNumber
          title: widget.parentOrChild == 'parent'
              ? Text(
                  'Items In ${widget.tableOrParcel} ${widget.tableOrParcelNumber.toString()}',
                  style: kAppBarTextStyle,
                )
              : Text(
                  'Items In ${widget.tableOrParcel} ${widget.tableOrParcelNumber.toString()}${widget.parentOrChild}',
                  style: kAppBarTextStyle,
                ),
          centerTitle: true,
          actions: <Widget>[
            IconButton(
                onPressed: () {
                  setState(() {
                    showSpinner = false;

                    tappedPrintButton = false;
                  });

                  int _everyMilliSecondBeforeGoingBack = 0;
                  List<String> deletingItemsIfNotThere = [];
                  Timer? _timerAtBackButton;
                  _timerAtBackButton =
                      Timer.periodic(Duration(milliseconds: 100), (_) {
                    widget.itemsAddedMap.forEach((key, value) {
                      if (widget.itemsAddedMap[key] == 0) {
                        deletingItemsIfNotThere.add(key);
                      }
                    });
                    //WeNeedThisStepOnlyIfTheWaiterHasMadeSomeItemZero
                    //IfThereIsSomethingThat'sZero,
                    //WeRemoveItFromItemsAddedMapWithTheBelowLoop
                    if (deletingItemsIfNotThere.isNotEmpty) {
                      for (var item in deletingItemsIfNotThere) {
                        widget.itemsAddedMap.remove(item);
                      }
                    }

                    _everyMilliSecondBeforeGoingBack++;
                    if (_everyMilliSecondBeforeGoingBack >= 4) {
                      _timerAtBackButton!.cancel();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MenuPageWithBackButtonUsage(
                            hotelName: widget.hotelName,
                            tableOrParcel: widget.tableOrParcel,
                            tableOrParcelNumber: widget.tableOrParcelNumber,
                            menuItems: widget.menuItems,
                            menuPrices: widget.menuPrices,
                            menuTitles: widget.menuTitles,
                            itemsAddedMapCalled: widget.itemsAddedMap,
                            itemsAddedCommentCalled: widget.itemsAddedComment,
                            itemsAddedTimeCalled: widget.itemsAddedTime,
                            parentOrChild: widget.parentOrChild,
                            alreadyRunningTicketsMap:
                                widget.alreadyRunningTicketsMap,
                          ),
                        ),
                      );
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PrinterRolesAssigning()));
                      print(
                          'back timer at true is is $_everyMilliSecondBeforeGoingBack');
                    }
                  });
                },
                icon: Icon(
                  Icons.settings,
                  color: kAppBarBackIconColor,
                ))
          ],
        ),
        //TheListViewWillHaveListTiles
        //EachListTilesWillHaveItemInTheLeftAnd
        //AddButtonInTheRight.TheButton'sInputWillBeItemNameAlone
        body: ModalProgressHUD(
          inAsyncCall: showSpinner,
          child: Container(
            child: ListView.builder(
                itemCount: widget.itemsAddedMap.length,
                itemBuilder: (context, index) {
                  final item = nameOfItemsAdded[index];
                  return Container(
                    // padding: EdgeInsets.all(8),
                    // decoration: BoxDecoration(
                    //     borderRadius: BorderRadius.circular(5),
                    //     border: Border.all(
                    //       color: Colors.black87,
                    //       width: 1.0,
                    //     )),
                    margin: EdgeInsets.fromLTRB(5, 5, 0, 5),
                    child: ListTile(
                      title: Row(
                        // mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(
                              icon: Icon(Icons.edit,
                                  size: 20, color: Colors.green),
                              onPressed: () {
                                showModalBottomSheet(
                                    isScrollControlled: true,
                                    context: context,
                                    builder: (context) {
                                      return commentsSection(context, item);
                                    });
                              }),
                          Expanded(
                            child: Text(item,
                                style: Theme.of(context).textTheme.headline6),
                          ),
                        ],
                      ),
                      trailing: addOrCounterButton(item),
                      subtitle: widget.itemsAddedComment[item] == ''
                          ? null
                          : Text(
                              widget.itemsAddedComment[item]!,
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black),
                            ),
                    ),
                  );
                }),
          ),
        ),
        persistentFooterButtons: [
          Row(
            children: [
              Provider.of<PrinterAndOtherDetailsProvider>(context)
                          .kotAssignedPrintersFromClass ==
                      '{}'
                  ? Expanded(
                      child: BottomButton(
                        buttonColor: kBottomContainerColour,
                        buttonWidth: double.infinity,
                        buttonTitle: 'Assign Printer',
                        onTap: () {
                          setState(() {
                            showSpinner = false;

                            tappedPrintButton = false;
                            print('12 $tappedPrintButton');
                          });

                          int _everyMilliSecondBeforeGoingBack = 0;
                          List<String> deletingItemsIfNotThere = [];
                          Timer? _timerAtBackButton;
                          _timerAtBackButton =
                              Timer.periodic(Duration(milliseconds: 100), (_) {
                            widget.itemsAddedMap.forEach((key, value) {
                              if (widget.itemsAddedMap[key] == 0) {
                                deletingItemsIfNotThere.add(key);
                              }
                            });
                            //WeNeedThisStepOnlyIfTheWaiterHasMadeSomeItemZero
                            //IfThereIsSomethingThat'sZero,
                            //WeRemoveItFromItemsAddedMapWithTheBelowLoop
                            if (deletingItemsIfNotThere.isNotEmpty) {
                              for (var item in deletingItemsIfNotThere) {
                                widget.itemsAddedMap.remove(item);
                              }
                            }
                            // print('back timer is $_everyMilliSecondBeforeGoingBack');
                            // return false;
                            _everyMilliSecondBeforeGoingBack++;
                            if (_everyMilliSecondBeforeGoingBack >= 4) {
                              // print(
                              //     'back timer at cancel is $_everyMilliSecondBeforeGoingBack');
                              _timerAtBackButton!.cancel();
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MenuPageWithBackButtonUsage(
                                    hotelName: widget.hotelName,
                                    tableOrParcel: widget.tableOrParcel,
                                    tableOrParcelNumber:
                                        widget.tableOrParcelNumber,
                                    menuItems: widget.menuItems,
                                    menuPrices: widget.menuPrices,
                                    menuTitles: widget.menuTitles,
                                    itemsAddedMapCalled: widget.itemsAddedMap,
                                    itemsAddedCommentCalled:
                                        widget.itemsAddedComment,
                                    itemsAddedTimeCalled: widget.itemsAddedTime,
                                    parentOrChild: widget.parentOrChild,
                                    alreadyRunningTicketsMap:
                                        widget.alreadyRunningTicketsMap,
                                  ),
                                ),
                              );
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          PrinterRolesAssigning()));
                              print(
                                  'back timer at true is is $_everyMilliSecondBeforeGoingBack');
                              // return true;
                              // Navigator.pop(context);
                              // return true;

                            }
                          });
                        },
                      ),
                    )
                  : Expanded(
                      child: BottomButton(
                        buttonColor: Colors.orangeAccent,
                        buttonWidth: double.infinity,
                        buttonTitle: 'Print KOT',
                        onTap: () {
                          couldntConnectPrintersBytesForEachPrinter = [];
                          print(
                              'from bottom button entry-tapped Print Button $tappedPrintButton');
                          bool atLeastOnItemIsThereToAdd = false;
                          widget.itemsAddedMap.forEach((key, value) {
//InCaseInFinalKotScreenIfAllItemsHadBeenRemovedFromTheScreen
                            if (widget.itemsAddedMap[key] != 0) {
                              atLeastOnItemIsThereToAdd = true;
                            }
                          });
                          if (atLeastOnItemIsThereToAdd) {
                            if (tappedPrintButton == false) {
                              tappedPrintButton = true;
                              if (widget.alreadyRunningTicketsMap.isNotEmpty) {
                                num tempTicketUpdater = 1;
                                widget.alreadyRunningTicketsMap
                                    .forEach((key, value) {
                                  tempTicketUpdater += value;
                                });
                                ticketNumberUpdater =
                                    tempTicketUpdater.toString();
                              }

                              itemsUpdaterString = '';
                              localKOTItemNames = [];
                              localKOTNumberOfItems = [];
                              localKOTItemComments = [];
                              localSlotNumber = widget.parentOrChild == 'parent'
                                  ? '${widget.tableOrParcel}:${widget.tableOrParcelNumber}'
                                  : '${widget.tableOrParcel}:${widget.tableOrParcelNumber}${widget.parentOrChild}';

                              localPartOfTableOrParcel = widget.tableOrParcel;
                              localPartOfTableOrParcelNumber =
                                  widget.tableOrParcelNumber.toString();
                              separateKOTForEachUserInEachPrinterMap = [];
                              kotPrinterAssigningMap = json.decode(
                                  Provider.of<PrinterAndOtherDetailsProvider>(
                                          context,
                                          listen: false)
                                      .kotAssignedPrintersFromClass);
                              kotPrinterAssigningMap
                                  .forEach((printerIdKey, value) {
                                //ListToHaveOnlyTheUserPhoneNumber
                                List<dynamic> usersForEachPrinter = [];
//ToGetTheArrayThatContainsTheMapOfAllUsers
                                Map<String, dynamic> eachPrinterValue =
                                    value['users'];
                                eachPrinterValue
                                    .forEach((keyIsEachUserPhoneNumber, value) {
                                  List<String> userWontCook = [];
                                  if (allUserProfile[keyIsEachUserPhoneNumber]
                                          ['wontCook'] !=
                                      null) {
                                    List<dynamic> tempUserWontCook =
                                        allUserProfile[keyIsEachUserPhoneNumber]
                                            ['wontCook'];
                                    userWontCook = tempUserWontCook
                                        .map((e) => e.toString())
                                        .toList();
                                  }
                                  Map<String, dynamic> eachUserPrinterMap =
                                      HashMap();
                                  List<String> printKOTItemNames = [];
                                  List<num> printKOTNumberOfItems = [];
                                  List<String> printKOTItemComments = [];
                                  widget.itemsAddedMap.forEach((key, value) {
                                    //toCheckWhetherTheUserNeedsAnIndividualPrint
                                    eachUserPrinterMap['slot'] =
                                        localSlotNumber;
                                    eachUserPrinterMap['ticketNumber'] =
                                        ticketNumberUpdater;
                                    String itemComment = 'nocomments';
                                    if (widget.itemsAddedMap[key] != 0 &&
                                        !userWontCook.contains(key)) {
                                      if (widget.itemsAddedComment[key] != '') {
                                        itemComment =
                                            widget.itemsAddedComment[key]!;
                                      }
                                      printKOTItemNames.add(key);
                                      printKOTNumberOfItems
                                          .add(widget.itemsAddedMap[key]!);
                                      printKOTItemComments.add(itemComment);
                                    }
                                  });
                                  if (printKOTItemNames.isNotEmpty) {
                                    eachUserPrinterMap.addAll(
                                        {'printItemNames': printKOTItemNames});
                                    eachUserPrinterMap.addAll({
                                      'printItemNumbers': printKOTNumberOfItems
                                    });
                                    eachUserPrinterMap.addAll({
                                      'printItemComments': printKOTItemComments
                                    });
                                    eachUserPrinterMap
                                        .addAll({'printerId': printerIdKey});
                                    separateKOTForEachUserInEachPrinterMap
                                        .addAll({eachUserPrinterMap});
                                  }
                                });
                              });

                              if (separateKOTForEachUserInEachPrinterMap
                                  .isNotEmpty) {
                                bytesGeneratorForKot();
                              } else {
                                errorAlertDialogBox(
                                    'Please assign users with Chef Specialities to Printer');
                              }
                            }
                          } else {
                            show('Please Add Items');
                          }
                        },
                      ),
                    ),
              SizedBox(width: 10),
              Expanded(
                child: BottomButton(
                  buttonColor: Colors.green,
                  buttonWidth: double.infinity,
                  buttonTitle: 'Add(No KOT)',
                  onTap: () {
                    addRunningOrderToServer();
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
