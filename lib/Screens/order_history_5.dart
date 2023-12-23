import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:orders_dev/Methods/eac_order_history_widget.dart';
import 'package:orders_dev/constants.dart';
import 'package:paginate_firestore/paginate_firestore.dart';
import 'package:modal_progress_hud_alt/modal_progress_hud_alt.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:orders_dev/Methods/printerenum.dart' as printerenum;
import 'package:permission_handler/permission_handler.dart';
import 'package:orders_dev/Screens/printer_settings_screen.dart';
import 'package:orders_dev/Screens/searching_Connecting_Printer_Screen.dart';
import 'package:provider/provider.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';

class OrderHistoryWithExtraItems extends StatefulWidget {
  //ScreenWhereWeShowTheBillsTillNow
  final String hotelName;

  const OrderHistoryWithExtraItems({Key? key, required this.hotelName})
      : super(key: key);

  @override
  State<OrderHistoryWithExtraItems> createState() =>
      _OrderHistoryWithExtraItemsState();
}

class _OrderHistoryWithExtraItemsState
    extends State<OrderHistoryWithExtraItems> {
  // BluetoothPrint bluetoothPrint = BluetoothPrint.instance;
  bool _connected = false;
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  List<BluetoothDevice> _devices = [];
  List<BluetoothDevice> additionalDevices = [];
  BluetoothDevice? _device;
  bool bluetoothOnTrueOrOffFalse = true;
  String tips = 'no device connect';

  //ThePrinterStringsWeNeedForSavingAndGettingDetails
  //BelowOneIsForSharedPreferences
  late Future<String> _connectedPrinterSaving;

//VariableToMarkBluetoothIsConnectedOrNotToPrinter
  bool bluetoothConnected = false;
  bool bluetoothAlreadyConnected = false;
  bool disconnectAndConnectAttempted = false;
  int _everySecondForConnection = 0;
  // String hotelNameAlone = '';
//SpinnerOrCircularProgressIndicatorWhenTryingToPrint
  bool showSpinner = false;
  String printerSize = '0';
  //ToGetAllItemsOutsideForPrint

  bool locationPermissionAccepted = true;
  int _timerWorkingCheck = 0;
  bool printingOver = false;
  int _everyThirtySeconds = 0;
  String localhotelNameForPrint = '';
  String localaddressLine1ForPrint = '';
  String localaddressLine2ForPrint = '';
  String localaddressLine3ForPrint = '';
  String localphoneNumberForPrint = '';
  String localCustomerNameForPrint = '';
  String localCustomerMobileForPrint = '';
  String localCustomerAddressForPrint = '';
  String localSerialNumberForPrint = '';

//ThisWillEnsureCanCheckWhetherThisDataHadBeenPutInMail
  String localdateForPrint = '';
  String localtotalNumberOfItemsForPrint = '';
  String localbillNumberForPrint = '';
  String localtakeAwayOrDineInForPrint = '';
  String localdistinctItemsForPrint = '';
  String localindividualPriceOfEachDistinctItemForPrint = '';
  String localnumberOfEachDistinctItemForPrint = '';
  String localpriceOfEachDistinctItemWithoutTotalForPrint = '';
  String localtotalQuantityForPrint = '';
  String localExtraItemsDistinctNamesForPrint = '';
  String localExtraItemsDistinctNumbersForPrint = '';
  String localDiscountForPrint = '';
  String localDiscountEnteredValue = '';
  String localDiscountValueClickedTruePercentageClickedFalse = '';
  String localsubTotalForPrint = '';
  String localcgstPercentageForPrint = '';
  String localcgstCalculatedForPrint = '';
  String localsgstPercentageForPrint = '';
  String localsgstCalculatedForPrint = '';
  String localroundOff = '';
  String localgrandTotalForPrint = '';
  late StreamSubscription internetCheckerSubscription;
  bool pageHasInternet = true;

  @override
  void initState() {
//InitiallyWeWantThisAllToBeFalse
    bluetoothConnected = false;
    bluetoothAlreadyConnected = false;
    disconnectAndConnectAttempted = false;
    showSpinner = false;
    _everyThirtySeconds = 0;

    // TODO: implement initState
//ReadCounterToGetFromSharedPreferencesTheSavedPrinterDetails

    requestLocationPermission();
    internetAvailabilityChecker();
    super.initState();
  }

  Future show(
    String message, {
    Duration duration: const Duration(seconds: 3),
  }) async {
    await new Future.delayed(new Duration(milliseconds: 100));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 30),
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
          setState(() {
            _connected = false;
            bluetoothOnTrueOrOffFalse = true;
            print("bluetooth device state: disconnected");
          });
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

  void _connect(BluetoothDevice nowConnectingPrinter) {
    print('start of _Connect loop');
    if (nowConnectingPrinter != null) {
      print('device isnt null');

      bluetooth.isConnected.then((isConnected) {
        print('isCOnnected 11 is $isConnected');
        print('came inside bluetooth trying to connect');
        if (isConnected == false) {
          bluetooth.connect(nowConnectingPrinter!).catchError((error) {
            print('did not get connected1 inside _connect- ${_connected}');
            show('Couldn\'t Connect. Please check Printer');
            setState(() {
              _connected = false;
              showSpinner = false;
            });
            print('did not get connected2 inside _connect- ${_connected}');
          });
          setState(() {
            _connected = true;
          });
          print('we are connected inside _connect- ${_connected}');
          intermediateFunctionToCallPrintThroughBluetooth();
        } else {
          Timer? _timerInDisconnectAndConnect;
          int _everySecondHelpingToDisconnectBeforeConnectingAgain = 0;
          print(
              'disconnect and connect attempted1 $disconnectAndConnectAttempted');

          print('isCOnnected 1 is $isConnected');
          print('need a dosconnection here1');
          bluetooth.disconnect();
          setState(() {
            _connected = false;
          });
          _everySecondForConnection = 0;

          if (disconnectAndConnectAttempted) {
            _timerInDisconnectAndConnect!.cancel();
            print('isCOnnected 2 is $isConnected');
            print('need a dosconnection here2');
            print(
                'disconnect and connect attempted2 $disconnectAndConnectAttempted');
            setState(() {
              showSpinner = false;
            });
          } else {
            print('isCOnnected 3 is $isConnected');
            print('need a dosconnection here3');
            print(
                'disconnect and connect attempted3 $disconnectAndConnectAttempted');
            _timerInDisconnectAndConnect =
                Timer.periodic(const Duration(seconds: 1), (_) async {
              if (_everySecondHelpingToDisconnectBeforeConnectingAgain < 4) {
                _timerWorkingCheck++;
                print('timerWorkingCheck id $_timerWorkingCheck');
                _everySecondHelpingToDisconnectBeforeConnectingAgain++;
                print('isCOnnected 8 is $isConnected');
                print(
                    '_everySecondHelpingToDisconnectBeforeConnectingAgainInOrderHistory $_everySecondHelpingToDisconnectBeforeConnectingAgain');
              } else {
                _everySecondHelpingToDisconnectBeforeConnectingAgain = 0;
                _timerInDisconnectAndConnect!.cancel;
                print('need a dosconnection here4');
                if (disconnectAndConnectAttempted == false) {
                  disconnectAndConnectAttempted = true;
                  printerConnectionToLastSavedPrinter();
                } else {
                  _timerInDisconnectAndConnect.cancel();
                }

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
  }

  void intermediateFunctionToCallPrintThroughBluetooth() {
    if (showSpinner == false) {
      setState(() {
        showSpinner = true;
      });
    }

    print('start of intermediateFunctionToCallPrintThroughBluetooth');
    Timer? _timerInsideIntermediateFunctionToCallPrintThroughBluetooth;
    _everySecondForConnection = 0;

    _timerInsideIntermediateFunctionToCallPrintThroughBluetooth =
        Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_everySecondForConnection <= 2) {
        print('timer inside connect 1 is $_everySecondForConnection');
        _everySecondForConnection++;
      } else {
        _timerInsideIntermediateFunctionToCallPrintThroughBluetooth!.cancel();
        if (_connected) {
          print('timer inside connect 2 is $_everySecondForConnection');
          print('Inside intermediate- it is connected');
          printThroughBluetooth(
              localhotelNameForPrint,
              localaddressLine1ForPrint,
              localaddressLine2ForPrint,
              localaddressLine3ForPrint,
              localphoneNumberForPrint,
              localCustomerNameForPrint,
              localCustomerMobileForPrint,
              localCustomerAddressForPrint,
              localSerialNumberForPrint,
              localdateForPrint,
              localtotalNumberOfItemsForPrint,
              localbillNumberForPrint,
              localtakeAwayOrDineInForPrint,
              localdistinctItemsForPrint,
              localindividualPriceOfEachDistinctItemForPrint,
              localnumberOfEachDistinctItemForPrint,
              localpriceOfEachDistinctItemWithoutTotalForPrint,
              localtotalQuantityForPrint,
              localExtraItemsDistinctNamesForPrint,
              localExtraItemsDistinctNumbersForPrint,
              localDiscountForPrint,
              localDiscountEnteredValue,
              localDiscountValueClickedTruePercentageClickedFalse,
              localsubTotalForPrint,
              localcgstPercentageForPrint,
              localcgstCalculatedForPrint,
              localsgstPercentageForPrint,
              localsgstCalculatedForPrint,
              localroundOff,
              localgrandTotalForPrint);
        } else {
          setState(() {
            showSpinner = false;
          });
          print('unable to connect');
          // bluetooth.disconnect();
          // show('Couldnt Connect. Please check Printer');
        }
      }
    });
    print('end of intermediateFunctionToCallPrintThroughBluetooth');
  }

  //FunctionToConnectToTheSavedBluetoothPrinter
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
            showSpinner = false;
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

//   Future<void> savedBluetoothPrinterConnect() async {
//     //BoolToHelpStopScanning
//     bool notScannedDevicesOnce = true;
// //SpinnerForCircularProgressIndicatorOnceWeClickPrint
//     setState(() {
//       showSpinner = true;
//     });
// //bluetoothConnectedIsFalse
//     //  bluetoothConnected = false;
// //StartScanToCheckForBluetoothDevices
//     bluetoothPrint.startScan(timeout: Duration(seconds: 7));
// //DuringScan,manyTimes,AtFirst,ItShowsLastConnectedPrinter
// //SoWeUseTheBelowVariableToCheckWhetherTheSavedPrinterIsThere
//     int confirmingPrinter = 0;
//
//     bluetoothPrint.scanResults.listen((devices) async {
// //ThisIsForConnectingTheLastConnectedPrinter
//       devices.forEach((printer) async {
//         if (notScannedDevicesOnce) {
//           //WeGoThroughEachPrinter
//           print(
//               'connecting printer address is $connectingPrinterAddressOrderHistoryScreen');
//           print('checking printer address is ${printer.address.toString()}');
// //WeCheckAddressOfSavedPrinter&ConnectingPrinter
// //IfTheAddressIsSame&BluetoothIsYetToBeConnected
//           if (connectingPrinterAddressOrderHistoryScreen ==
//               printer.address.toString()) {
//             print('came almost inside confirming printer address loop');
// //WeKeepAddingThePrinterConfirmingVariableToEnsureThatPrinterIsThere
//             confirmingPrinter++;
//             if (confirmingPrinter > 1) {
//               var nowConnectingPrinterInOrderHistoryScreen = printer;
//               bluetoothPrint.stopScan();
//               if (bluetoothAlreadyConnected == false) {
// //WhenWeAreConnectingPrinterForTheFirstTime
//                 await bluetoothPrint
//                     .connect(nowConnectingPrinterInOrderHistoryScreen);
//                 notScannedDevicesOnce = false;
// //IfMoreThanOncePrinterIsConfirmed,WeStoreThePrinterVariable&Connect
//
//                 print('came inside thhis loop $confirmingPrinter');
//                 bluetoothConnected = true;
// //WeChangeTheConfirmingVariableBackToZero
//                 confirmingPrinter = 0;
//               } else {
//                 print('fbdhgbdhbfdbfhjf');
//                 notScannedDevicesOnce = false;
//                 confirmingPrinter = 0;
//                 printBill(
//                     localhotelNameForPrint,
//                     localaddressLine1ForPrint,
//                     localaddressLine2ForPrint,
//                     localaddressLine3ForPrint,
//                     localphoneNumberForPrint,
//                     localdateForPrint,
//                     localtotalNumberOfItemsForPrint,
//                     localbillNumberForPrint,
//                     localtakeAwayOrDineInForPrint,
//                     localdistinctItemsForPrint,
//                     localindividualPriceOfEachDistinctItemForPrint,
//                     localnumberOfEachDistinctItemForPrint,
//                     localpriceOfEachDistinctItemWithoutTotalForPrint,
//                     localtotalQuantityForPrint,
//                     localsubTotalForPrint,
//                     localcgstPercentageForPrint,
//                     localcgstCalculatedForPrint,
//                     localsgstPercentageForPrint,
//                     localsgstCalculatedForPrint,
//                     localgrandTotalForPrint);
//               }
//             }
//           }
//         }
//       });
//     });
//     if (bluetoothAlreadyConnected == false) {
//       //BluetoothNeedsSomeTimesToConnect,HenceTimer
//       Timer? _timer;
//       int _everySecondInSavedBluetoothLoop = 0;
//       _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
//         //WeIncreaseVariableEverySecond&After3Seconds,CancelTheTimer
// //AndHenceWeCancelTheTimer
//
//         if (_everySecondInSavedBluetoothLoop < 5) {
//           print(
//               'timer_everySecondInSavedBluetoothLoop time is $_everySecondInSavedBluetoothLoop');
//           _everySecondInSavedBluetoothLoop++;
//         } else {
// //WeCancelTheTimer
//           _timer?.cancel();
//           print(
//               'timer _everySecondInSavedBluetoothLooptime at cance point is $_everySecondInSavedBluetoothLoop');
// //IfBluetoothConnected,WeDon'tNeedPrinterConnectionScreen
//           if (bluetoothConnected) {
//             print('inside bluetooth connected chhfvgjbh');
//             noNeedPrinterConnectionScreen = true;
//             bluetoothAlreadyConnected = true;
//             // bluetoothPrint.stopScan();
// //WeCanThenCallForPrinterToPrintTheParcelItems
//             printBill(
//                 localhotelNameForPrint,
//                 localaddressLine1ForPrint,
//                 localaddressLine2ForPrint,
//                 localaddressLine3ForPrint,
//                 localphoneNumberForPrint,
//                 localdateForPrint,
//                 localtotalNumberOfItemsForPrint,
//                 localbillNumberForPrint,
//                 localtakeAwayOrDineInForPrint,
//                 localdistinctItemsForPrint,
//                 localindividualPriceOfEachDistinctItemForPrint,
//                 localnumberOfEachDistinctItemForPrint,
//                 localpriceOfEachDistinctItemWithoutTotalForPrint,
//                 localtotalQuantityForPrint,
//                 localsubTotalForPrint,
//                 localcgstPercentageForPrint,
//                 localcgstCalculatedForPrint,
//                 localsgstPercentageForPrint,
//                 localsgstCalculatedForPrint,
//                 localgrandTotalForPrint);
//           } else {
//             setState(() {
//               print('nfgehsfbnjshfs');
//               //_connected = false;
//               tips = 'not yet connected';
// //IfBluetoothConnectedIsFalse,WeCallForPrinterConnectionScreenToCheckForPrinters
//               noNeedPrinterConnectionScreen = false;
//               bluetoothConnected = false;
//               bluetoothAlreadyConnected = false;
// //WeDon'tNeedSpinnerEither
//               showSpinner = false;
//             });
//           }
//
//           if (!mounted) return;
//         }
//       });
//     }
//   }

  void bluetoothDisconnectFunction() async {
//alteringThisFunctionFromBluetoothPrintPackageToBlueThermalPrinterPackage
    bool onceDisconnected = false;
    _everySecondForConnection = 0;
    Timer? _timer;
    int _everySecond = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
//TimerIsForAllowingForThePrintToFinish
      if (_everySecond < 2) {
        print('timer time at disconnect is $_everySecond');
        _everySecond++;
      } else {
        _timer?.cancel();
        print('timer time at cance point is $_everySecond');
        if (onceDisconnected == false) {
          bluetoothConnected = false;
          printingOver = false;
          bluetooth.disconnect();
          // bluetoothPrint.destroy();
          onceDisconnected = true;
          // bluetoothPrint.disconnect();
          // bluetoothPrint.destroy();
          bluetoothAlreadyConnected = false;
          print('inside cancel 1');
        }
        //bluetoothPrint.disconnect();
        setState(() {
          showSpinner = false;
          _connected = false;
          bluetoothConnected = false;
          //bluetoothConnected = false;
        });
        localhotelNameForPrint = '';
        localaddressLine1ForPrint = '';
        localaddressLine2ForPrint = '';
        localaddressLine3ForPrint = '';
        localphoneNumberForPrint = '';
        localCustomerNameForPrint = '';
        localCustomerMobileForPrint = '';
        localCustomerAddressForPrint = '';

//ThisWillEnsureCanCheckWhetherThisDataHadBeenPutInMail
        localdateForPrint = '';
        localtotalNumberOfItemsForPrint = '';
        localbillNumberForPrint = '';
        localtakeAwayOrDineInForPrint = '';
        localdistinctItemsForPrint = '';
        localindividualPriceOfEachDistinctItemForPrint = '';
        localExtraItemsDistinctNamesForPrint = '';
        localExtraItemsDistinctNumbersForPrint = '';
        localnumberOfEachDistinctItemForPrint = '';
        localpriceOfEachDistinctItemWithoutTotalForPrint = '';
        localtotalQuantityForPrint = '';
        localDiscountForPrint = '';
        localDiscountEnteredValue = '';
        localDiscountValueClickedTruePercentageClickedFalse = '';
        localsubTotalForPrint = '';
        localcgstPercentageForPrint = '';
        localcgstCalculatedForPrint = '';
        localsgstPercentageForPrint = '';
        localsgstCalculatedForPrint = '';
        localroundOff = '';
        localgrandTotalForPrint = '';

        //toCloseTheAppInCaseTheAppIsn'tOpenedForAnHour
      }
    });
    print('done with disconnect');
    bluetooth.isConnected.then((isConnected) {
      if (isConnected == true) {
        print('this Is IsConnected after Disconnect $isConnected');
      } else {
        print('else this Is IsConnected after Disconnect $isConnected');
      }
    });
  }

  void printThroughBluetooth(
    String hotelNameForPrint,
    String addressLine1ForPrint,
    String addressLine2ForPrint,
    String addressLine3ForPrint,
    String phoneNumberForPrint,
    String customerNameForPrint,
    String customerMobileForPrint,
    String customerAddressForPrint,
    String serialNumberForPrint,
    String dateForPrint,
    String totalNumberOfItemsForPrint,
    String billNumberForPrint,
    String takeAwayOrDineInForPrint,
    String distinctItemsForPrint,
    String individualPriceOfEachDistinctItemForPrint,
    String numberOfEachDistinctItemForPrint,
    String priceOfEachDistinctItemWithoutTotalForPrint,
    String totalQuantityForPrint,
    String extraItemsNamesForPrint,
    String extraItemsNumbersForPrint,
    String discountForPrint,
    String discountEnteredValue,
    String discountValueClickedTruePercentageClickedFalse,
    String subTotalForPrint,
    String cgstPercentageForPrint,
    String cgstCalculatedForPrint,
    String sgstPercentageForPrint,
    String sgstCalculatedForPrint,
    String roundOffForPrint,
    String grandTotalForPrint,
  ) {
    final distinctItems = distinctItemsForPrint.split('*');
    final individualPriceOfEachDistinctItem =
        individualPriceOfEachDistinctItemForPrint.split('*');
    final numberOfEachDistinctItem =
        numberOfEachDistinctItemForPrint.split('*');
    final priceOfEachDistinctItemWithoutTotal =
        priceOfEachDistinctItemWithoutTotalForPrint.split('*');
    final distinctExtraItems = extraItemsNamesForPrint.split('*');
    final distinctExtraItemsNumbers = extraItemsNumbersForPrint.split('*');
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

    // List<String> localParcelReadyItemNames = ['Aaaaaaa', 'Bbbbbb', 'Ccccccc'];
    // List<num> localParcelReadyNumberOfItems = [1, 2, 3];
    if (showSpinner == false) {
      setState(() {
        showSpinner = true;
      });
    }

    print('start of inside printThroughBluetooth');
    if (_connected) {
      bluetooth.isConnected.then((isConnected) {
//CurrentlyNotCaringWhether58mmOr80mm.WillChangeLater
        print('came inside bluetooth isConnected');
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
          if (localhotelNameForPrint != '') {
            if (Provider.of<PrinterAndOtherDetailsProvider>(context,
                        listen: false)
                    .captainPrinterSizeFromClass ==
                '80') {
              bluetooth.printCustom(
                  "$hotelNameForPrint",
                  printerenum.Size.extraLarge.val,
                  printerenum.Align.center.val);
              if (addressLine1ForPrint != '') {
                bluetooth.printCustom("${addressLine1ForPrint}",
                    printerenum.Size.medium.val, printerenum.Align.center.val);
              }
              if (addressLine2ForPrint != '') {
                bluetooth.printCustom("${addressLine2ForPrint}",
                    printerenum.Size.medium.val, printerenum.Align.center.val);
              }
              if (addressLine3ForPrint != '') {
                bluetooth.printCustom("${addressLine3ForPrint}",
                    printerenum.Size.medium.val, printerenum.Align.center.val);
              }
              if (phoneNumberForPrint != '') {
                bluetooth.printCustom("${phoneNumberForPrint}",
                    printerenum.Size.medium.val, printerenum.Align.center.val);
              }
              bluetooth.printCustom(
                  "-----------------------------------------------",
                  printerenum.Size.bold.val,
                  printerenum.Align.center.val);
              if (cgstPercentageForPrint != '0') {
                bluetooth.printCustom("TAX INVOICE", printerenum.Size.bold.val,
                    printerenum.Align.center.val);
              }
              bluetooth.printNewLine();
              // bluetooth.printNewLine();
              bluetooth.printCustom("ORDER DATE: $dateForPrint ",
                  printerenum.Size.bold.val, printerenum.Align.center.val);
              bluetooth.printCustom(
                  "-----------------------------------------------",
                  printerenum.Size.bold.val,
                  printerenum.Align.center.val);
              if (customerNameForPrint != '' || customerMobileForPrint != '') {
                String customerPrintingName = customerNameForPrint != ''
                    ? 'Customer: ${customerNameForPrint}'
                    : '';
                String customerPrintingMobile = customerMobileForPrint != ''
                    ? 'Phone: ${customerMobileForPrint}'
                    : '';
                if (customerNameForPrint != '') {
                  bluetooth.printCustom("$customerPrintingName",
                      printerenum.Size.medium.val, printerenum.Align.left.val);
                }
                if (customerMobileForPrint != '') {
                  bluetooth.printCustom("$customerPrintingMobile",
                      printerenum.Size.medium.val, printerenum.Align.left.val);
                }
              }
              if (customerAddressForPrint != '') {
                bluetooth.printCustom("Address: ${customerAddressForPrint}",
                    printerenum.Size.medium.val, printerenum.Align.left.val);
              }
              if (customerNameForPrint != '' ||
                  customerMobileForPrint != '' ||
                  customerAddressForPrint != '') {
                bluetooth.printCustom(
                    "-----------------------------------------------",
                    printerenum.Size.bold.val,
                    printerenum.Align.center.val);
              }
              bluetooth.printLeftRight(
                  "TOTAL NO. OF ITEMS:${totalNumberOfItemsForPrint}",
                  "Qty:${totalQuantityForPrint}",
                  printerenum.Size.medium.val,
                  format: "%-20s %20s %n");
              // bluetooth.printCustom("BILL NO: ${widget.orderHistoryDocID}",
              //     printerenum.Size.medium.val, printerenum.Align.left.val);
              bluetooth.printLeftRight("BILL NO: ${billNumberForPrint}",
                  "$takeAwayOrDineInForPrint", printerenum.Size.bold.val,
                  format: "%-20s %20s %n");
              if (serialNumberForPrint != '') {
                bluetooth.printCustom(" Sl.No: ${serialNumberForPrint}",
                    printerenum.Size.boldLarge.val, printerenum.Align.left.val);
              }
              // if (widget.statisticsMap['numberofparcel']! > 0) {
              //   bluetooth.printLeftRight("BILL NO: ${billNumberForPrint}",
              //       "$takeAwayOrDineInForPrint", printerenum.Size.medium.val,
              //       format: "%-20s %20s %n");
              //   // bluetooth.printCustom("TYPE: TAKE-AWAY",
              //   //     printerenum.Size.medium.val, printerenum.Align.left.val);
              // } else {
              //   bluetooth.printLeftRight("BILL NO: ${billNumberForPrint}",
              //       "TYPE: DINE-IN", printerenum.Size.medium.val,
              //       format: "%-20s %20s %n");
              //   // bluetooth.printCustom("TYPE: DINE-IN",
              //   //     printerenum.Size.medium.val, printerenum.Align.left.val);
              // }
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
              for (int i = 0; i < distinctItems.length - 1; i++) {
                if ((' '.allMatches(distinctItems[i]).length >= 2)) {
                  String firstName = '';
                  String secondName = '';
                  String thirdName = '';
                  final longItemNameSplit = distinctItems[i].split(' ');
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
                      "${individualPriceOfEachDistinctItem[i]}",
                      "${numberOfEachDistinctItem[i]}",
                      "${priceOfEachDistinctItemWithoutTotal[i]}",
                      printerenum.Size.bold.val,
                      format: "%-20s %7s %7s %7s %n");
                  bluetooth.print4Column(
                      "  $secondName", " ", " ", " ", printerenum.Size.bold.val,
                      format: "%-20s %7s %7s %7s %n");
                  if (thirdName != '') {
                    bluetooth.print4Column("  $thirdName", " ", " ", " ",
                        printerenum.Size.bold.val,
                        format: "%-20s %7s %7s %7s %n");
                  }
                } else {
                  bluetooth.print4Column(
                      "${distinctItems[i]}",
                      "${individualPriceOfEachDistinctItem[i]}",
                      "${numberOfEachDistinctItem[i]}",
                      "${priceOfEachDistinctItemWithoutTotal[i]}",
                      printerenum.Size.bold.val,
                      format: "%-20s %7s %7s %7s %n");
                }
              }
              if (distinctExtraItems.isNotEmpty) {
                for (int l = 0; l < distinctExtraItems.length; l++) {
                  bluetooth.print4Column(
                      "${distinctExtraItems[l]}",
                      " ",
                      " ",
                      "${distinctExtraItemsNumbers[l]}",
                      printerenum.Size.bold.val,
                      format: "%-20s %7s %7s %7s %n");
                }
              }
              bluetooth.printCustom(
                  "-----------------------------------------------",
                  printerenum.Size.bold.val,
                  printerenum.Align.center.val);
              if (discountForPrint != '0') {
                if (discountValueClickedTruePercentageClickedFalse == 'true') {
                  bluetooth.printCustom("Discount : ${discountForPrint}",
                      printerenum.Size.bold.val, printerenum.Align.right.val);
                } else {
                  bluetooth.printCustom(
                      "Discount ${discountEnteredValue}% : ${discountForPrint}",
                      printerenum.Size.bold.val,
                      printerenum.Align.right.val);
                }

                bluetooth.printCustom(
                    "-----------------------------------------------",
                    printerenum.Size.bold.val,
                    printerenum.Align.center.val);
              }
              if (cgstPercentageForPrint != '0') {
                bluetooth.printCustom("Sub-Total : $subTotalForPrint",
                    printerenum.Size.bold.val, printerenum.Align.right.val);
              }
              if (cgstPercentageForPrint != '0') {
                bluetooth.printCustom(
                    "CGST @ ${cgstPercentageForPrint}% : ${cgstCalculatedForPrint}",
                    printerenum.Size.bold.val,
                    printerenum.Align.right.val);
              }
              if (sgstPercentageForPrint != '0') {
                bluetooth.printCustom(
                    "SGST @ ${sgstPercentageForPrint}% : ${sgstCalculatedForPrint}",
                    printerenum.Size.bold.val,
                    printerenum.Align.right.val);
                bluetooth.printCustom(
                    "-----------------------------------------------",
                    printerenum.Size.bold.val,
                    printerenum.Align.center.val);
              } else {
                bluetooth.printNewLine();
              }
              if (roundOffForPrint != '0') {
                bluetooth.printCustom("Round Off: ${roundOffForPrint}",
                    printerenum.Size.bold.val, printerenum.Align.right.val);
              }
              bluetooth.printCustom("GRAND TOTAL: ${grandTotalForPrint}",
                  printerenum.Size.boldLarge.val, printerenum.Align.right.val);
            } else if (Provider.of<PrinterAndOtherDetailsProvider>(context,
                        listen: false)
                    .captainPrinterSizeFromClass ==
                '58') {
              bluetooth.printCustom(
                  "$hotelNameForPrint",
                  printerenum.Size.extraLarge.val,
                  printerenum.Align.center.val);
              if (addressLine1ForPrint != '') {
                bluetooth.printCustom("${addressLine1ForPrint}",
                    printerenum.Size.medium.val, printerenum.Align.center.val);
              }
              if (addressLine2ForPrint != '') {
                bluetooth.printCustom("${addressLine2ForPrint}",
                    printerenum.Size.medium.val, printerenum.Align.center.val);
              }
              if (addressLine3ForPrint != '') {
                bluetooth.printCustom("${addressLine3ForPrint}",
                    printerenum.Size.medium.val, printerenum.Align.center.val);
              }
              if (phoneNumberForPrint != '') {
                bluetooth.printCustom("${phoneNumberForPrint}",
                    printerenum.Size.medium.val, printerenum.Align.center.val);
              }
              if (cgstPercentageForPrint != '0') {
                bluetooth.printCustom("TAX INVOICE", printerenum.Size.bold.val,
                    printerenum.Align.center.val);
              }
              // bluetooth.printNewLine();
              // bluetooth.printNewLine();
              bluetooth.printCustom("ORDER DATE: $dateForPrint ",
                  printerenum.Size.medium.val, printerenum.Align.center.val);
              bluetooth.printCustom("-------------------------------",
                  printerenum.Size.medium.val, printerenum.Align.center.val);
              if (customerNameForPrint != '' || customerMobileForPrint != '') {
                String customerPrintingName = customerNameForPrint != ''
                    ? 'Customer: ${customerNameForPrint}'
                    : '';
                String customerPrintingMobile = customerMobileForPrint != ''
                    ? 'Phone: ${customerMobileForPrint}'
                    : '';
                if (customerNameForPrint != '') {
                  bluetooth.printCustom("$customerPrintingName",
                      printerenum.Size.medium.val, printerenum.Align.left.val);
                }
                if (customerMobileForPrint != '') {
                  bluetooth.printCustom("$customerPrintingMobile",
                      printerenum.Size.medium.val, printerenum.Align.left.val);
                }
              }
              if (customerAddressForPrint != '') {
                bluetooth.printCustom("Address: ${customerAddressForPrint}",
                    printerenum.Size.medium.val, printerenum.Align.left.val);
              }
              if (customerNameForPrint != '' ||
                  customerMobileForPrint != '' ||
                  customerAddressForPrint != '') {
                bluetooth.printCustom("-------------------------------",
                    printerenum.Size.medium.val, printerenum.Align.center.val);
              }

              bluetooth.printCustom(
                  "TOTAL NO. OF ITEMS:${totalNumberOfItemsForPrint}    Qty:${totalQuantityForPrint}",
                  printerenum.Size.medium.val,
                  printerenum.Align.left.val);
              bluetooth.printCustom("BILL NO: ${billNumberForPrint}",
                  printerenum.Size.medium.val, printerenum.Align.left.val);
              bluetooth.printCustom("$takeAwayOrDineInForPrint",
                  printerenum.Size.medium.val, printerenum.Align.left.val);
              if (serialNumberForPrint != '') {
                bluetooth.printCustom("Sl.No: ${serialNumberForPrint}",
                    printerenum.Size.boldLarge.val, printerenum.Align.left.val);
              }
              bluetooth.printCustom("-------------------------------",
                  printerenum.Size.medium.val, printerenum.Align.center.val);
              bluetooth.printLeftRight(
                  "Item Name", "Amount", printerenum.Size.medium.val);
              bluetooth.printCustom("-------------------------------",
                  printerenum.Size.medium.val, printerenum.Align.center.val);

              for (int i = 0; i < distinctItems.length - 1; i++) {
//ThisIsGood.CouldBePlanAorPlanB
//               bluetooth.print3Column(
//                   "${widget.distinctItems[i]}",
//                   "${widget.individualPriceOfEachDistinctItem[i]} x ${widget.numberOfEachDistinctItem[i]}",
//                   "${widget.priceOfEachDistinctItemWithoutTotal[i]}",
//                   printerenum.Size.medium.val,
//                   format: "%-20s %20s %14s %n");
//CouldBePlanB
                bluetooth.printCustom("${distinctItems[i]}",
                    printerenum.Size.medium.val, printerenum.Align.left.val);
                bluetooth.printLeftRight(
                    "${individualPriceOfEachDistinctItem[i]} x ${numberOfEachDistinctItem[i]}",
                    "${priceOfEachDistinctItemWithoutTotal[i]}",
                    printerenum.Size.medium.val);
//CouldBePlanB
                // bluetooth.printCustom(
                //     "${widget.individualPriceOfEachDistinctItem[i]} x ${widget.numberOfEachDistinctItem[i]}                   ${widget.priceOfEachDistinctItemWithoutTotal[i]}",
                //     printerenum.Size.medium.val,
                //     printerenum.Align.right.val);
              }
              if (distinctExtraItems.isNotEmpty) {
                for (int l = 0; l < distinctExtraItems.length; l++) {
                  bluetooth.printLeftRight(
                      distinctExtraItems[l],
                      distinctExtraItemsNumbers[l],
                      printerenum.Size.medium.val);
                }
              }
              bluetooth.printCustom("-------------------------------",
                  printerenum.Size.medium.val, printerenum.Align.center.val);
              // bluetooth.printCustom("TOTAL Qty: ${totalQuantity()}",
              //     printerenum.Size.medium.val, printerenum.Align.left.val);
              if (discountForPrint != '0') {
                if (discountValueClickedTruePercentageClickedFalse == 'true') {
                  bluetooth.printCustom("Discount : ${discountForPrint} ",
                      printerenum.Size.medium.val, printerenum.Align.right.val);
                } else {
                  bluetooth.printCustom(
                      "Discount ${discountEnteredValue}% : ${discountForPrint} ",
                      printerenum.Size.medium.val,
                      printerenum.Align.right.val);
                }

                bluetooth.printCustom("-------------------------------",
                    printerenum.Size.medium.val, printerenum.Align.center.val);
              }
              if (cgstPercentageForPrint != '0') {
                bluetooth.printCustom("Sub-Total : ${subTotalForPrint}",
                    printerenum.Size.medium.val, printerenum.Align.right.val);
              }
              if (cgstPercentageForPrint != '0') {
                bluetooth.printCustom(
                    "CGST @ ${cgstPercentageForPrint}% : ${cgstCalculatedForPrint}",
                    printerenum.Size.medium.val,
                    printerenum.Align.right.val);
              }
              if (sgstPercentageForPrint != '0') {
                bluetooth.printCustom(
                    "SGST @ ${sgstPercentageForPrint}% : ${sgstCalculatedForPrint}",
                    printerenum.Size.medium.val,
                    printerenum.Align.right.val);
                bluetooth.printCustom("-------------------------------",
                    printerenum.Size.medium.val, printerenum.Align.center.val);
              } else {
                bluetooth.printNewLine();
              }
              if (roundOffForPrint != '0') {
                bluetooth.printCustom("Round Off: ${roundOffForPrint}",
                    printerenum.Size.medium.val, printerenum.Align.right.val);
              }
              bluetooth.printCustom("GRAND TOTAL: ${grandTotalForPrint}",
                  printerenum.Size.boldLarge.val, printerenum.Align.right.val);
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
            bluetooth.printNewLine();
            bluetooth.printCustom("Printer Check", printerenum.Size.medium.val,
                printerenum.Align.center.val);
            bluetooth.printNewLine();
            bluetooth.printNewLine();
            bluetooth.paperCut();
          }
        } else {
          setState(() {
            showSpinner = false;
          });
          // show('Couldn\'t Connect. Please check Printer');
        }
      });
    }
    // else {
    //   show('Couldnt Connect. Please check Printer');
    // }
    print('end of inside printThroughBluetooth');
  }

//   void printBill(
//     String hotelNameForPrint,
//     String addressLine1ForPrint,
//     String addressLine2ForPrint,
//     String addressLine3ForPrint,
//     String phoneNumberForPrint,
//     String dateForPrint,
//     String totalNumberOfItemsForPrint,
//     String billNumberForPrint,
//     String takeAwayOrDineInForPrint,
//     String distinctItemsForPrint,
//     String individualPriceOfEachDistinctItemForPrint,
//     String numberOfEachDistinctItemForPrint,
//     String priceOfEachDistinctItemWithoutTotalForPrint,
//     String totalQuantityForPrint,
//     String subTotalForPrint,
//     String cgstPercentageForPrint,
//     String cgstCalculatedForPrint,
//     String sgstPercentageForPrint,
//     String sgstCalculatedForPrint,
//     String grandTotalForPrint,
//   ) {
//     setState(() {
//       showSpinner = true;
//     });
//     final distinctItems = distinctItemsForPrint.split('*');
//     final individualPriceOfEachDistinctItem =
//         individualPriceOfEachDistinctItemForPrint.split('*');
//     final numberOfEachDistinctItem =
//         numberOfEachDistinctItemForPrint.split('*');
//     final priceOfEachDistinctItemWithoutTotal =
//         priceOfEachDistinctItemWithoutTotalForPrint.split('*');
//
//     Timer? _timer;
//     int _everySecondForConnection = 0;
//     _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
//       //ItWillCheckWhetherTheVariableEveryThirtySecondsIsLessThan121,,
// //ThenItWillBeIncrementedBy1AndItWillAlsoCallTheFunctionWhichWillCheck,,
// //ForNewOrdersInTheBackground
// //IfItIsMoreThan120,ThenForOneHourThereHasNotBeenAnyOrder
// //AndHenceWeCancelTheTimer
//
//       if (_everySecondForConnection < 3) {
//         print('timer printing time is $_everySecondForConnection');
//         _everySecondForConnection++;
//       } else {
//         _timer?.cancel();
//         print(
//             'timer printing time at connect point is point is $_everySecondForConnection');
//         Map<String, dynamic> config = Map();
//         List<LineText> printList = [];
//         if (connectingPrinterSizeOrderHistoryScreen == '80') {
//           printList.add(LineText(
//             type: LineText.TYPE_TEXT,
//             content: '$hotelNameForPrint',
//             weight: 1,
//             height: 1,
//             align: LineText.ALIGN_CENTER,
//             linefeed: 1,
//           ));
//           if (addressLine1ForPrint != '') {
//             printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: '${addressLine1ForPrint}',
//               weight: 1,
//               align: LineText.ALIGN_CENTER,
//               linefeed: 1,
//             ));
//           }
//           if (addressLine2ForPrint != '') {
//             printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: '${addressLine2ForPrint}',
//               weight: 1,
//               align: LineText.ALIGN_CENTER,
//               linefeed: 1,
//             ));
//           }
//           if (addressLine3ForPrint != '') {
//             printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: '${addressLine3ForPrint}',
//               weight: 1,
//               align: LineText.ALIGN_CENTER,
//               linefeed: 1,
//             ));
//           }
//           if (phoneNumberForPrint != '') {
//             printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: '${phoneNumberForPrint}',
//               weight: 1,
//               align: LineText.ALIGN_CENTER,
//               linefeed: 1,
//             ));
//           }
//           printList.add(LineText(linefeed: 1));
//           if (cgstPercentageForPrint != '0') {
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
//           //     content: 'DUPLICATE',
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
//               content: 'ORDER DATE: $dateForPrint ',
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
//               content: '$totalNumberOfItemsForPrint',
//               weight: 1,
//               // align: LineText.ALIGN_RIGHT,
//               align: LineText.ALIGN_LEFT,
//               x: 240,
//               relativeX: 0,
//               linefeed: 1));
//           printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: 'BILL NO: $billNumberForPrint',
//               weight: 1,
//               align: LineText.ALIGN_LEFT,
//               x: 0,
//               relativeX: 0,
//               linefeed: 0));
//           printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: '$takeAwayOrDineInForPrint',
//               weight: 1,
//               align: LineText.ALIGN_LEFT,
//               x: 350,
//               relativeX: 0,
//               linefeed: 1));
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
//           for (int i = 0; i < distinctItems.length - 1; i++) {
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: '${distinctItems[i]}',
//                 weight: 1,
//                 align: LineText.ALIGN_LEFT,
//                 x: 0,
//                 relativeX: 0,
//                 linefeed: 0));
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: '${individualPriceOfEachDistinctItem[i]}',
//                 weight: 1,
//                 // align: LineText.ALIGN_RIGHT,
//                 align: LineText.ALIGN_LEFT,
//                 x: 340,
//                 relativeX: 0,
//                 linefeed: 0));
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: '${numberOfEachDistinctItem[i]}',
//                 weight: 1,
//                 // align: LineText.ALIGN_RIGHT,
//                 align: LineText.ALIGN_LEFT,
//                 x: 430,
//                 relativeX: 0,
//                 linefeed: 0));
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: '${priceOfEachDistinctItemWithoutTotal[i]}',
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
//               content: '$totalQuantityForPrint',
//               weight: 1,
//               // align: LineText.ALIGN_RIGHT,
//               align: LineText.ALIGN_LEFT,
//               x: 140,
//               relativeX: 0,
//               linefeed: 0));
//           if (cgstPercentageForPrint != '0') {
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
//                 content: '$subTotalForPrint',
//                 weight: 1,
//                 // align: LineText.ALIGN_RIGHT,
//                 align: LineText.ALIGN_LEFT,
//                 x: 500,
//                 relativeX: 0,
//                 linefeed: 1));
//           }
//           if (cgstPercentageForPrint != '0') {
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: 'CGST @ $cgstPercentageForPrint% :',
//                 weight: 1,
//                 align: LineText.ALIGN_LEFT,
//                 x: 280,
//                 relativeX: 0,
//                 linefeed: 0));
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: '$cgstCalculatedForPrint',
//                 weight: 1,
//                 // align: LineText.ALIGN_RIGHT,
//                 align: LineText.ALIGN_LEFT,
//                 x: 500,
//                 relativeX: 0,
//                 linefeed: 1));
//           }
//           if (sgstPercentageForPrint != '0') {
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: 'SGST @ $sgstPercentageForPrint% :',
//                 weight: 1,
//                 align: LineText.ALIGN_LEFT,
//                 x: 280,
//                 relativeX: 0,
//                 linefeed: 0));
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: '$sgstCalculatedForPrint',
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
//               content: '$grandTotalForPrint',
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
//         } else if (connectingPrinterSizeOrderHistoryScreen == '58') {
//           print('inside this 58m print loop');
//           printList.add(LineText(
//             type: LineText.TYPE_TEXT,
//             content: '$hotelNameForPrint',
//             weight: 1,
//             height: 1,
//             align: LineText.ALIGN_CENTER,
//             linefeed: 1,
//           ));
//           if (addressLine1ForPrint != '') {
//             printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: '${addressLine1ForPrint}',
//               weight: 1,
//               align: LineText.ALIGN_CENTER,
//               linefeed: 1,
//             ));
//           }
//           if (addressLine2ForPrint != '') {
//             printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: '${addressLine2ForPrint}',
//               weight: 1,
//               align: LineText.ALIGN_CENTER,
//               linefeed: 1,
//             ));
//           }
//           if (addressLine3ForPrint != '') {
//             printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: '${addressLine3ForPrint}',
//               weight: 1,
//               align: LineText.ALIGN_CENTER,
//               linefeed: 1,
//             ));
//           }
//           if (phoneNumberForPrint != '') {
//             printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: '${phoneNumberForPrint}',
//               weight: 1,
//               align: LineText.ALIGN_CENTER,
//               linefeed: 1,
//             ));
//           }
//           printList.add(LineText(linefeed: 1));
//           if (cgstPercentageForPrint != '0') {
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
//           //     content: 'DUPLICATE',
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
//               content: 'ORDER DATE: $dateForPrint ',
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
//               content: '$totalNumberOfItemsForPrint',
//               weight: 1,
//               // align: LineText.ALIGN_RIGHT,
//               align: LineText.ALIGN_LEFT,
//               x: 230,
//               relativeX: 0,
//               linefeed: 1));
//           printList.add(LineText(linefeed: 1));
//           printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: 'BILL NO: $billNumberForPrint',
//               weight: 1,
//               align: LineText.ALIGN_LEFT,
//               x: 0,
//               relativeX: 0,
//               linefeed: 1));
//
//           printList.add(LineText(
//               type: LineText.TYPE_TEXT,
//               content: '$takeAwayOrDineInForPrint',
//               weight: 1,
//               align: LineText.ALIGN_LEFT,
//               x: 0,
//               relativeX: 0,
//               linefeed: 1));
//
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
//           for (int i = 0; i < distinctItems.length - 1; i++) {
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: '${distinctItems[i]}',
//                 weight: 1,
//                 align: LineText.ALIGN_LEFT,
//                 x: 0,
//                 relativeX: 0,
//                 linefeed: 1));
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content:
//                     '${individualPriceOfEachDistinctItem[i]} x ${numberOfEachDistinctItem[i]}',
//                 weight: 1,
//                 // align: LineText.ALIGN_RIGHT,
//                 align: LineText.ALIGN_LEFT,
//                 x: 0,
//                 relativeX: 0,
//                 linefeed: 0));
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: '${priceOfEachDistinctItemWithoutTotal[i]}',
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
//               content: '${totalQuantityForPrint}',
//               weight: 1,
//               // align: LineText.ALIGN_RIGHT,
//               align: LineText.ALIGN_LEFT,
//               x: 120,
//               relativeX: 0,
//               linefeed: 0));
//           if (cgstPercentageForPrint != '0') {
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
//                 content: '$subTotalForPrint',
//                 weight: 1,
//                 // align: LineText.ALIGN_RIGHT,
//                 align: LineText.ALIGN_LEFT,
//                 x: 310,
//                 relativeX: 0,
//                 linefeed: 1));
//           }
//           if (cgstPercentageForPrint != '0') {
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: 'CGST @ $cgstPercentageForPrint% :',
//                 weight: 1,
//                 align: LineText.ALIGN_LEFT,
//                 x: 130,
//                 relativeX: 0,
//                 linefeed: 0));
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: '$cgstCalculatedForPrint',
//                 weight: 1,
//                 // align: LineText.ALIGN_RIGHT,
//                 align: LineText.ALIGN_LEFT,
//                 x: 310,
//                 relativeX: 0,
//                 linefeed: 1));
//           }
//           if (sgstPercentageForPrint != '0') {
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: 'SGST @ $sgstPercentageForPrint% :',
//                 weight: 1,
//                 align: LineText.ALIGN_LEFT,
//                 x: 130,
//                 relativeX: 0,
//                 linefeed: 0));
//             printList.add(LineText(
//                 type: LineText.TYPE_TEXT,
//                 content: '$sgstCalculatedForPrint',
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
//               content: '$grandTotalForPrint',
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
//         setState(() {
//           showSpinner = false;
//         });
//
//         await bluetoothPrint.printReceipt(config, printList);
//         localhotelNameForPrint = '';
//         localaddressLine1ForPrint = '';
//         localaddressLine2ForPrint = '';
//         localaddressLine3ForPrint = '';
//         localphoneNumberForPrint = '';
//         localdateForPrint = '';
//         localtotalNumberOfItemsForPrint = '';
//         localbillNumberForPrint = '';
//         localtakeAwayOrDineInForPrint = '';
//         localdistinctItemsForPrint = '';
//         localindividualPriceOfEachDistinctItemForPrint = '';
//         localnumberOfEachDistinctItemForPrint = '';
//         localpriceOfEachDistinctItemWithoutTotalForPrint = '';
//         localtotalQuantityForPrint = '';
//         localsubTotalForPrint = '';
//         localcgstPercentageForPrint = '';
//         localcgstCalculatedForPrint = '';
//         localsgstPercentageForPrint = '';
//         localsgstCalculatedForPrint = '';
//         localgrandTotalForPrint = '';
//         //  bluetoothDisconnectFunction();
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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      //WillPopScopeIsForTheBackButtonOfThePhone
      onWillPop: () async {
        if (bluetoothConnected) {
          await bluetooth.disconnect();
          _everySecondForConnection = 0;
          bluetoothConnected = false;
          bluetoothAlreadyConnected = false;
          Timer? _timer;
          int _everySecondForDisconnectOnBackButton = 0;
          _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
            _everySecondForDisconnectOnBackButton++;

            if (_everySecondForDisconnectOnBackButton >= 1) {
              _timer!.cancel();
              _everySecondForDisconnectOnBackButton = 0;
              Navigator.pop(context);
            }
          });
        } else {
          Navigator.pop(context);
        }
        return false;

        print('inside phone bacl button');
//IfBluetoothConnectedDuringBackButtonPressed,ItShouldBeDisconnected
      },
      child: Scaffold(
        backgroundColor: Colors.blueGrey,
        // (noNeedprinterSettings && noNeedPrinterConnectionScreen)
        //     ? Colors.blueGrey
        //     : null,
        appBar: AppBar(
          leading: IconButton(
              //ThisBackButtonInAppbarToPopOutOfTheScreen
              icon: const Icon(Icons.arrow_back, color: kAppBarBackIconColor),
              onPressed: () async {
                if (bluetoothConnected) {
                  await bluetooth.disconnect();
                  _everySecondForConnection = 0;
                  bluetoothConnected = false;
                  bluetoothAlreadyConnected = false;
                  Timer? _timer;
                  int _everySecondForDisconnectOnBackButton = 0;
                  _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
                    _everySecondForDisconnectOnBackButton++;

                    if (_everySecondForDisconnectOnBackButton >= 1) {
                      _timer!.cancel();
                      _everySecondForDisconnectOnBackButton = 0;
                      Navigator.pop(context);
                    }
                  });
                } else {
                  Navigator.pop(context);
                }
              }),
          backgroundColor: kAppBarBackgroundColor,
          title: const Text(
            'A Snap Of Bills',
            style: kAppBarTextStyle,
          ),
          centerTitle: true,
          actions: <Widget>[
            IconButton(
                onPressed: () {
                  Navigator.push(
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
          inAsyncCall: showSpinner,
          child: Scrollbar(
            //ScrollbarIsTheSideScrollButtonWhichHelpsToScrollFurtherInScreen
            thumbVisibility: true,
            //ThumbVisibilityTrueToHaveTheScrollThumbAlwaysVisible
            //paginationIsWidgetFromFireStore.HelpsToDownloadDataFromFirestore,
            //AsTheUserScrollsDown.WeCanLimitToHowManyNeedsToBeDownloaded
            //ThisWidgetIsPackageFromNetFlutterLibrary
            //MostCodesBelowTakenRightFromTheExampleProvidedInPackage
            child: PaginateFirestore(
              // Use SliverAppBar in header to make it sticky
              header: const SliverToBoxAdapter(
                  child: SizedBox(
                height: 10.0,
              )),
              footer: const SliverToBoxAdapter(
                  child: SizedBox(
                height: 10.0,
              )),
              // item builder type is compulsory.
              itemBuilderType:
                  PaginateBuilderType.listView, //Change types accordingly
              itemBuilder: (context, documentSnapshots, index) {
                final data = documentSnapshots[index].data() as Map?;
                final printData = documentSnapshots[index].data() as Map?;

                //EachBillWillBeListTile
                //ifDataNull-ErrorInData
                //ElseWeUseTheCustomClassWeCreated-EachOrderHistory,
                //ItIsContainerWhichContainsEachBillArrangedInsideIt
                //InputOfEachOrderHistoryIsDataOfEachBill&IdOfEachDocumentSnapshot
                return ListTile(
                  onLongPress: () {
                    localhotelNameForPrint = '';
                    localdateForPrint = '';
                    localtotalNumberOfItemsForPrint = '';
                    localbillNumberForPrint = '';
                    localtakeAwayOrDineInForPrint = '';
                    localdistinctItemsForPrint = '';
                    localindividualPriceOfEachDistinctItemForPrint = '';
                    localnumberOfEachDistinctItemForPrint = '';
                    localpriceOfEachDistinctItemWithoutTotalForPrint = '';
                    localtotalQuantityForPrint = '';
                    localExtraItemsDistinctNamesForPrint = '';
                    localExtraItemsDistinctNumbersForPrint = '';
                    localDiscountForPrint = '';
                    localDiscountEnteredValue = '';
                    localDiscountValueClickedTruePercentageClickedFalse = '';
                    localsubTotalForPrint = '';
                    localcgstPercentageForPrint = '';
                    localcgstCalculatedForPrint = '';
                    localsgstPercentageForPrint = '';
                    localsgstCalculatedForPrint = '';
                    localroundOff = '';
                    localgrandTotalForPrint = '';
                    localhotelNameForPrint = '';
                    localaddressLine1ForPrint = '';
                    localaddressLine2ForPrint = '';
                    localaddressLine3ForPrint = '';
                    localphoneNumberForPrint = '';
                    localCustomerNameForPrint = '';
                    localCustomerMobileForPrint = '';
                    localCustomerAddressForPrint = '';
                    localSerialNumberForPrint = '';
                    localhotelNameForPrint = printData!['hotelNameForPrint'];
                    localdateForPrint = printData!['dateForPrint'];
                    localphoneNumberForPrint =
                        printData!['phoneNumberForPrint'];
                    localaddressLine1ForPrint =
                        printData!['addressline1ForPrint'];
                    localaddressLine2ForPrint =
                        printData!['addressline2ForPrint'];
                    localaddressLine3ForPrint =
                        printData!['addressline3ForPrint'];
                    if (printData!['customerNameForPrint'] != null) {
                      localCustomerNameForPrint =
                          printData!['customerNameForPrint'];
                    }
                    if (printData!['customerMobileForPrint'] != null) {
                      localCustomerMobileForPrint =
                          printData!['customerMobileForPrint'];
                    }
                    if (printData!['customerAddressForPrint'] != null) {
                      localCustomerAddressForPrint =
                          printData!['customerAddressForPrint'];
                    }
                    if (printData!['serialNumberForPrint'] != null) {
                      localSerialNumberForPrint =
                          printData!['serialNumberForPrint'];
                    }
                    localtotalNumberOfItemsForPrint =
                        printData!['totalNumberOfItemsForPrint'];
                    localbillNumberForPrint = printData!['billNumberForPrint'];
                    localtakeAwayOrDineInForPrint =
                        printData!['takeAwayOrDineInForPrint'];
                    localdistinctItemsForPrint =
                        printData!['distinctItemsForPrint'];
                    localindividualPriceOfEachDistinctItemForPrint =
                        printData!['individualPriceOfEachDistinctItemForPrint'];
                    localnumberOfEachDistinctItemForPrint =
                        printData!['numberOfEachDistinctItemForPrint'];
                    localpriceOfEachDistinctItemWithoutTotalForPrint =
                        printData![
                            'priceOfEachDistinctItemWithoutTotalForPrint'];
                    localtotalQuantityForPrint =
                        printData!['totalQuantityForPrint'];
                    if (printData!['extraItemsDistinctNames'] != null) {
                      localExtraItemsDistinctNamesForPrint =
                          printData!['extraItemsDistinctNames'];
                    }
                    if (printData!['extraItemsDistinctNumbers'] != null) {
                      localExtraItemsDistinctNumbersForPrint =
                          printData!['extraItemsDistinctNumbers'];
                    }

                    localDiscountForPrint = printData!['discount'];
                    localDiscountEnteredValue =
                        printData!['discountEnteredValue'];
                    localDiscountValueClickedTruePercentageClickedFalse =
                        printData![
                            'discountValueClickedTruePercentageClickedFalse'];
                    localsubTotalForPrint = printData!['subTotalForPrint'];
                    localcgstPercentageForPrint =
                        printData!['cgstPercentageForPrint'];
                    localcgstCalculatedForPrint =
                        printData!['cgstCalculatedForPrint'];
                    localsgstPercentageForPrint =
                        printData!['sgstPercentageForPrint'];
                    localsgstCalculatedForPrint =
                        printData!['sgstCalculatedForPrint'];
                    localroundOff = printData!['roundOff'];
                    localgrandTotalForPrint = printData!['grandTotalForPrint'];
                    // bluetoothPrint.startScan(
                    //     timeout: Duration(seconds: 2));
                    // int bluetoothOnOrOffState = 11;
                    // bluetoothPrint.state.listen((state) {
                    //   bluetoothOnOrOffState = state;
                    // });
                    bluetoothStateChangeFunction();
                    showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return buildBottomSheetForPrint(context);
                        });
                    //  print('the date is ${data![' Date of Order  :']}');
                  },
                  title: data == null
                      ? const Text('Error in data')
                      : EachOrderHistory(
                          eachOrderMap: data,
                          eachOrderId: documentSnapshots[index].id),
                );
              },
              // orderBy is compulsory to enable pagination
              query: FirebaseFirestore.instance
                  .collection(widget.hotelName)
                  .doc('orderhistory')
                  .collection('orderhistory')
                  .orderBy(' Date of Order  :', descending: true),
              itemsPerPage: 5,
              // to fetch real-time data
              isLive: true,
            ),
          ),
        ),
        persistentFooterButtons: [
          pageHasInternet
              ? SizedBox.shrink()
              : Container(
                  color: Colors.red,
                  child: Center(
                    child: Text('You are Offline',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 30.0)),
                  ),
                ),
        ],
      ),
    );
  }

  Widget buildBottomSheetForPrint(BuildContext context) {
    print('localhotelNameForPrint $localhotelNameForPrint');
    return localhotelNameForPrint == ''
        ? Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text('Bill Not Available For Print'),
          )
        : Provider.of<PrinterAndOtherDetailsProvider>(context)
                    .captainPrinterAddressFromClass ==
                ''
            ? Container(
                padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                // width: 300.0,
                child: TextButton.icon(
                  icon: Icon(Icons.print),
                  label: Text(
                    'Add Printer',
                  ),
                  style: TextButton.styleFrom(
                      primary: Colors.white, backgroundColor: Colors.green),
                  onPressed: () async {
                    if (bluetoothOnTrueOrOffFalse) {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SearchingConnectingPrinter(
                                  chefOrCaptain: 'Captain')));
                    } else {
                      Navigator.pop(context);

                      show('Please Turn On Bluetooth');
                    }
                  },
                ),
              )
            : Container(
                padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                // width: 300.0,
                child: TextButton.icon(
                  icon: Icon(Icons.print),
                  label: bluetoothOnTrueOrOffFalse
                      ? Text(
                          'Print',
                        )
                      : Text(
                          'Turn Bluetooth On To Print',
                        ),
                  style: TextButton.styleFrom(
                      primary: Colors.white, backgroundColor: Colors.green),
                  onPressed: () async {
                    disconnectAndConnectAttempted = false;
                    if (bluetoothOnTrueOrOffFalse) {
                      printerConnectionToLastSavedPrinter();
                      Navigator.pop(context);
                    } else {
                      Navigator.pop(context);
                      show('Please Turn On Bluetooth');
                    }
                  },
                ),
              );
    ;
  }
}
