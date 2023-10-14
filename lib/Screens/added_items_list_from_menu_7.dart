import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_alt/modal_progress_hud_alt.dart';
import 'package:orders_dev/Methods/bottom_button.dart';
import 'package:orders_dev/Providers/notification_provider.dart';
import 'package:orders_dev/Screens/menu_page_add_items_3.dart';
import 'package:orders_dev/Screens/menu_page_add_items_4.dart';
import 'package:orders_dev/Screens/printer_settings_screen.dart';
import 'package:orders_dev/Screens/searching_Connecting_Printer_Screen.dart';
import 'package:orders_dev/constants.dart';
import 'package:orders_dev/services/firestore_services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:orders_dev/Methods/printerenum.dart' as printerenum;
import 'package:provider/provider.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';

class AddedItemsWithRunningOrders extends StatefulWidget {
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
  final String parentOrChild;
  final Map<String, dynamic> alreadyRunningTicketsMap;
  List<Map<String, dynamic>> printingSeparateItemsListAsPerChef = [];

  AddedItemsWithRunningOrders(
      {required this.hotelName,
      required this.menuItems,
      required this.menuPrices,
      required this.menuTitles,
      required this.tableOrParcel,
      required this.tableOrParcelNumber,
      required this.itemsAddedMap,
      required this.itemsAddedComment,
      required this.unavailableItems,
      required this.parentOrChild,
      required this.alreadyRunningTicketsMap});

  @override
  _AddedItemsWithRunningOrdersState createState() =>
      _AddedItemsWithRunningOrdersState();
}

class _AddedItemsWithRunningOrdersState
    extends State<AddedItemsWithRunningOrders> {
  //InThisList,InInitStateWeWillAddTheNameOfAllTheItemsThatHasBeenAdded
  List<String> nameOfItemsAdded = [];
//ThisIsTheStringToUpdateInPlaystore
  String itemsUpdaterString = '';
  bool locationPermissionAccepted = true;
  bool _connected = false;
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  bool bluetoothOnTrueOrOffFalse = true;

  List<BluetoothDevice> _devices = [];
  List<BluetoothDevice> additionalDevices = [];
  bool bluetoothConnected = false;
  bool bluetoothAlreadyConnected = false;
  bool disconnectAndConnectAttempted = false;
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
  List<Map<String, dynamic>> separateKOTForEachUserPrintMap = [];
  String ticketNumberUpdater = '1';

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
    bluetooth.disconnect();
    bluetoothConnected = false;
    bluetoothAlreadyConnected = false;
    disconnectAndConnectAttempted = false;
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
    super.initState();
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

  Future<void> printerConnectionToLastSavedPrinterForKOT() async {
    printingOver = false;
    print('123');
    if (showSpinner == false) {
      setState(() {
        showSpinner = true;
      });
    }

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
          _connectForKOTPrint(nowConnectingPrinter);
        }
        if (devicesCount == _devices.length &&
            printerPairedTrueYetToPairFalse == false) {
          tappedPrintButton = false;
          setState(() {
            showSpinner = false;
          });
          print('came from here1');
          show('Couldn\'t Connect. Please check Printerrrs');
          printingOver = true;
        }
      }
    } else {
      show('Please Turn On Bluetooth');
    }

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

  void _connectForKOTPrint(BluetoothDevice nowConnectingPrinter) {
    bool timerForStartOfPrinting;
    print('start of _Connect loop');
    if (nowConnectingPrinter != null) {
      print('device isnt null');

      bluetooth.isConnected.then((isConnected) {
        print('came inside bluetooth trying to connect');
        if (isConnected == false) {
          bluetooth.connect(nowConnectingPrinter!).catchError((error) {
            print('did not get connected1 inside _connect- ${_connected}');
            show('Couldn\'t Connect. Please check Printer');

            printingOver = true;
            tappedPrintButton = false;
            setState(() {
              _connected = false;
              showSpinner = false;
            });
            print('did not get connected2 inside _connect- ${_connected}');
          });
          setState(() => _connected = true);
          print('we are connected inside _connect- ${_connected}');
          intermediateFunctionToCallPrintForKOT();
        } else {
          int _everySecondHelpingToDisconnectBeforeConnectingAgain = 0;
          show('Please check printer and try connecting again');
          bluetooth.disconnect();
          setState(() {
            _connected = false;
            showSpinner = false;
          });
          printingOver = true;
          tappedPrintButton = false;
          _everySecondForConnection = 0;

          if (disconnectAndConnectAttempted) {
            tappedPrintButton = false;
            setState(() {
              showSpinner = false;
            });
          }
          // else {
          //   Timer? _timerInDisconnectAndConnect;
          //   _timerInDisconnectAndConnect =
          //       Timer.periodic(const Duration(seconds: 1), (_) async {
          //     if (_everySecondHelpingToDisconnectBeforeConnectingAgain < 4) {
          //       _everySecondHelpingToDisconnectBeforeConnectingAgain++;
          //       print(
          //           '_everySecondHelpingToDisconnectBeforeConnectingAgainInChefScreen $_everySecondHelpingToDisconnectBeforeConnectingAgain');
          //     } else {
          //       _timerInDisconnectAndConnect!.cancel;
          //       print('need a dosconnection here4');
          //       if (disconnectAndConnectAttempted == false) {
          //         disconnectAndConnectAttempted = true;
          //         printerConnectionToLastSavedPrinterForKOT();
          //       } else {
          //         _timerInDisconnectAndConnect!.cancel();
          //       }
          //       _everySecondHelpingToDisconnectBeforeConnectingAgain = 0;
          //       printerConnectionToLastSavedPrinterForKOT();
          //       print(
          //           'cancelling _everySecondHelpingToDisconnectBeforeConnectingAgain $_everySecondHelpingToDisconnectBeforeConnectingAgain');
          //     }
          //   });
          // }
        }
      });
    } else {
      print('No device selected.');
    }
    print('end of _Connect loop');
  }

  void intermediateFunctionToCallPrintForKOT() {
    if (showSpinner == false) {
      setState(() {
        showSpinner = true;
      });
    }

    print('start of intermediateFunctionToCallPrintThroughBluetooth');
    Timer? _timer;
    _everySecondForConnection = 0;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_everySecondForConnection <= 2) {
        print('timer inside connect is $_everySecondForConnection');
        _everySecondForConnection++;
        // if (localKOTItemNames.isEmpty) {
        //   localKOTItemNames.add('Printer Check');
        //   localKOTNumberOfItems.add(1);
        //   localKOTItemComments.add(' ');
        // }
      } else {
        if (_connected) {
          print('Inside intermediate- it is connected');
          printKOTThroughBluetoothForSeparateUser();
        } else {
          tappedPrintButton = false;
          setState(() {
            showSpinner = false;
          });
          print('unable to connect');
          // bluetooth.disconnect();
          // show('Couldnt Connect. Please check Printer');
        }
        _timer!.cancel();
      }
    });
    print('end of intermediateFunctionToCallPrintThroughBluetooth');
  }

  void printKOTThroughBluetooth() {
    print('start of inside printThroughBluetooth');
    if (_connected) {
      bluetooth.isConnected.then((isConnected) {
        print('came inside bluetooth isConnected');
        if (isConnected == true) {
          print('inside printThroughBluetooth-is connected is true here');
          // bluetooth.printNewLine();
          if (Provider.of<PrinterAndOtherDetailsProvider>(context,
                      listen: false)
                  .captainPrinterSizeFromClass ==
              '80') {
            bluetooth.printNewLine();
            bluetooth.printNewLine();
            bluetooth.printNewLine();
            bluetooth.printNewLine();

            bluetooth.printCustom(
              "KOT : ${localSlotNumber}",
              printerenum.Size.boldMedium.val,
              printerenum.Align.center.val,
            );
            bluetooth.printCustom(
              "Ticket Number : ${localTicketNumber}",
              printerenum.Size.bold.val,
              printerenum.Align.center.val,
            );
            bluetooth.printCustom(
                "-----------------------------------------------",
                printerenum.Size.bold.val,
                printerenum.Align.center.val);

            for (int i = 0; i < localKOTItemNames.length; i++) {
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
                bluetooth.printLeftRight(
                    "$firstName",
                    "${localKOTNumberOfItems[i].toString()}",
                    printerenum.Size.bold.val,
                    format: "%-30s %10s %n");
                bluetooth.printLeftRight(
                    "$secondName", "", printerenum.Size.bold.val,
                    format: "%-30s %10s %n");
              } else {
                bluetooth.printLeftRight(
                    "${localKOTItemNames[i]}",
                    "${localKOTNumberOfItems[i].toString()}",
                    printerenum.Size.bold.val,
                    format: "%-30s %10s %n");
              }
              if (localKOTItemComments[i] != 'nocomments') {
                bluetooth.printCustom(
                    "     (Comment : ${localKOTItemComments[i]})",
                    printerenum.Size.bold.val,
                    printerenum.Align.left.val);
              }
              bluetooth.printCustom(
                  "-----------------------------------------------",
                  printerenum.Size.bold.val,
                  printerenum.Align.center.val);
              // bluetooth.printNewLine();

              if (i == (localKOTItemNames.length - 1)) {
                _disconnectForKOTPrint();
              }
            }
          } else if (Provider.of<PrinterAndOtherDetailsProvider>(context,
                      listen: false)
                  .captainPrinterSizeFromClass ==
              '58') {
            bluetooth.printNewLine();
            bluetooth.printNewLine();
            bluetooth.printNewLine();
            bluetooth.printNewLine();
            bluetooth.printCustom(
              "KOT : ${localSlotNumber}",
              printerenum.Size.boldMedium.val,
              printerenum.Align.center.val,
            );
            bluetooth.printCustom(
              "Ticket Number : ${localTicketNumber}",
              printerenum.Size.bold.val,
              printerenum.Align.center.val,
            );

            bluetooth.printCustom("-------------------------------",
                printerenum.Size.medium.val, printerenum.Align.center.val);
            for (int i = 0; i < localKOTItemNames.length; i++) {
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
                bluetooth.printLeftRight(
                    "$firstName",
                    "${localKOTNumberOfItems[i].toString()}",
                    printerenum.Size.bold.val);
                bluetooth.printCustom("$secondName", printerenum.Size.bold.val,
                    printerenum.Align.left.val);
              } else {
                bluetooth.printLeftRight(
                    "${localKOTItemNames[i]}",
                    "${localKOTNumberOfItems[i].toString()}",
                    printerenum.Size.bold.val);
              }

              if (localKOTItemComments[i] != 'nocomments') {
                bluetooth.printCustom(
                    "     (Comment : ${localKOTItemComments[i]})",
                    printerenum.Size.bold.val,
                    printerenum.Align.left.val);
              }
              bluetooth.printCustom("-------------------------------",
                  printerenum.Size.medium.val, printerenum.Align.center.val);
              //ToAccessDisconnectWhenWeArePrintingParcel
              if (i == (localKOTItemNames.length - 1)) {
                _disconnectForKOTPrint();
              }
            }
          }

          // bluetooth.printNewLine();
          // bluetooth.printNewLine();

          bluetooth
              .paperCut(); //some printer not supported (sometime making image not centered)
          //bluetooth.drawerPin2(); // or you can use bluetooth.drawerPin5();
        } else {
          tappedPrintButton = false;
          setState(() {
            showSpinner = false;
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

  void printKOTThroughBluetoothForSeparateUser() {
    print('start of inside printThroughBluetooth');
    if (_connected) {
      bluetooth.isConnected.then((isConnected) {
        print('came inside bluetooth isConnected');
        if (isConnected == true) {
          if (localKOTItemNames.isNotEmpty) {}
          print('inside printThroughBluetooth-is connected is true here');
          // bluetooth.printNewLine();
          num numberOfUsersLength = 0;
          for (var eachUserPrinting in separateKOTForEachUserPrintMap) {
            bluetooth.paperCut();
            numberOfUsersLength++;
            print('kotNames');
            print(eachUserPrinting['printKOTItemNames']);
            localKOTItemNames = eachUserPrinting['printItemNames'];
            localKOTNumberOfItems = eachUserPrinting['printItemNumbers'];
            localKOTItemComments = eachUserPrinting['printItemComments'];
            if (Provider.of<PrinterAndOtherDetailsProvider>(context,
                        listen: false)
                    .captainPrinterSizeFromClass ==
                '80') {
              bluetooth.printNewLine();
              bluetooth.printNewLine();
              bluetooth.printNewLine();
              bluetooth.printNewLine();
              bluetooth.printCustom(
                "KOT : ${eachUserPrinting['slot']}",
                printerenum.Size.boldMedium.val,
                printerenum.Align.center.val,
              );
              bluetooth.printCustom(
                "Ticket Number : ${eachUserPrinting['ticketNumber']}",
                printerenum.Size.bold.val,
                printerenum.Align.center.val,
              );
              bluetooth.printCustom(
                  "-----------------------------------------------",
                  printerenum.Size.bold.val,
                  printerenum.Align.center.val);

              for (int i = 0; i < localKOTItemNames.length; i++) {
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
                  bluetooth.printLeftRight(
                      "$firstName",
                      "${localKOTNumberOfItems[i].toString()}",
                      printerenum.Size.bold.val,
                      format: "%-30s %10s %n");
                  bluetooth.printLeftRight(
                      "$secondName", "", printerenum.Size.bold.val,
                      format: "%-30s %10s %n");
                } else {
                  bluetooth.printLeftRight(
                      "${localKOTItemNames[i]}",
                      "${localKOTNumberOfItems[i].toString()}",
                      printerenum.Size.bold.val,
                      format: "%-30s %10s %n");
                }
                if (localKOTItemComments[i] != 'nocomments') {
                  bluetooth.printCustom(
                      "     (Comment : ${localKOTItemComments[i]})",
                      printerenum.Size.bold.val,
                      printerenum.Align.left.val);
                }
                bluetooth.printCustom(
                    "-----------------------------------------------",
                    printerenum.Size.bold.val,
                    printerenum.Align.center.val);
                // bluetooth.printNewLine();
              }
            } else if (Provider.of<PrinterAndOtherDetailsProvider>(context,
                        listen: false)
                    .captainPrinterSizeFromClass ==
                '58') {
              bluetooth.printNewLine();
              bluetooth.printNewLine();
              bluetooth.printNewLine();
              bluetooth.printNewLine();
              bluetooth.printCustom(
                "KOT : ${eachUserPrinting['slot']}",
                printerenum.Size.boldMedium.val,
                printerenum.Align.center.val,
              );
              bluetooth.printCustom(
                "Ticket Number : ${eachUserPrinting['ticketNumber']}",
                printerenum.Size.bold.val,
                printerenum.Align.center.val,
              );

              bluetooth.printCustom("-------------------------------",
                  printerenum.Size.medium.val, printerenum.Align.center.val);
              for (int i = 0; i < localKOTItemNames.length; i++) {
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
                  bluetooth.printLeftRight(
                      "$firstName",
                      "${localKOTNumberOfItems[i].toString()}",
                      printerenum.Size.bold.val);
                  bluetooth.printCustom("$secondName",
                      printerenum.Size.bold.val, printerenum.Align.left.val);
                } else {
                  bluetooth.printLeftRight(
                      "${localKOTItemNames[i]}",
                      "${localKOTNumberOfItems[i].toString()}",
                      printerenum.Size.bold.val);
                }

                if (localKOTItemComments[i] != 'nocomments') {
                  bluetooth.printCustom(
                      "     (Comment : ${localKOTItemComments[i]})",
                      printerenum.Size.bold.val,
                      printerenum.Align.left.val);
                }
                bluetooth.printCustom("-------------------------------",
                    printerenum.Size.medium.val, printerenum.Align.center.val);
              }
            }
            if (numberOfUsersLength == separateKOTForEachUserPrintMap.length) {
              _disconnectForKOTPrint();
            }
          }

          // bluetooth.printNewLine();
          // bluetooth.printNewLine();

          bluetooth
              .paperCut(); //some printer not supported (sometime making image not centered)
          //bluetooth.drawerPin2(); // or you can use bluetooth.drawerPin5();
        } else {
          tappedPrintButton = false;
          setState(() {
            showSpinner = false;
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

  void _disconnectForKOTPrint() {
    print('came into disconnect');
    addRunningOrderToServer();
    Timer? _timer;
    int _everySecondForDisconnecting = 0;
    _everySecondForConnection = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_everySecondForDisconnecting < 2) {
        print('timer disconnect is $_everySecondForDisconnecting');
        _everySecondForDisconnecting++;
      } else {
        bluetooth.disconnect();
        localKOTItemNames = [];
        localKOTNumberOfItems = [];
        localKOTItemComments = [];

        _timer!.cancel();
        _everySecondForDisconnecting = 0;
        print('bluetooth is disconnecting');
        print('came to showspinner false');
        setState(() {
          showSpinner = false;
          _connected = false;
        });
        printingOver = true;
        tappedPrintButton = false;
        Navigator.pop(context);
        // int count = 0;
        // Navigator.of(context).popUntil((_) => count++ >= 2);
      }
    });
  }

  void addRunningOrderToServer() {
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
        'orderID': ((1000000 + Random().nextInt(9999999 - 1000000)).toString())
      });
      baseInfoMap.addAll({'tableOrParcel': widget.tableOrParcel});
      baseInfoMap.addAll(
          {'tableOrParcelNumber': widget.tableOrParcelNumber.toString()});
      baseInfoMap
          .addAll({'startTime': ((now.hour * 60) + now.minute).toString()});
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
//InCase,TheWaiterReducedItToZero,ThenWeShouldn'tAddItRight
        if (widget.itemsAddedMap[key] != 0) {
          final filteredItem = allItemsFromMenuMap
              .firstWhere((element) => element['itemName'] == key);
          itemPrice = filteredItem['price'];
          tempItemAddingMap.addAll({'itemName': key});
          if (widget.itemsAddedComment[key] != '') {
            itemComment = widget.itemsAddedComment[key]!;
          }
          tempItemAddingMap.addAll({'itemComment': itemComment});
          tempItemAddingMap.addAll({'itemPrice': itemPrice});
          tempItemAddingMap.addAll({'numberOfItem': widget.itemsAddedMap[key]});
          tempItemAddingMap.addAll(
              {'orderTakingTime': ((now.hour * 60) + now.minute).toString()});
          tempItemAddingMap.addAll({'itemStatus': 9});
          tempItemAddingMap.addAll({'chefKOT': 'chefkotnotyet'});
          tempItemAddingMap.addAll({'ticketNumberOfItem': '1'});
          tempItemAddingMap.addAll({'itemCancelled': 'false'});
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
      masterOrderMapToServer.addAll(
          {'partOfTableOrParcelNumber': widget.tableOrParcelNumber.toString()});
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
        num itemPrice = 0;
        if (widget.itemsAddedMap[key] != 0) {
          final filteredItem = allItemsFromMenuMap
              .firstWhere((element) => element['itemName'] == key);
          itemPrice = filteredItem['price'];
          tempItemAddingMap.addAll({'itemName': key});
          if (widget.itemsAddedComment[key] != '') {
            itemComment = widget.itemsAddedComment[key]!;
          }
          tempItemAddingMap.addAll({'itemComment': itemComment});
          tempItemAddingMap.addAll({'itemPrice': itemPrice});
          tempItemAddingMap.addAll({'numberOfItem': widget.itemsAddedMap[key]});
          tempItemAddingMap.addAll(
              {'orderTakingTime': ((now.hour * 60) + now.minute).toString()});
          tempItemAddingMap.addAll({'itemStatus': 9});
          tempItemAddingMap.addAll({'chefKOT': 'chefkotnotyet'});
          tempItemAddingMap.addAll({'ticketNumberOfItem': ticketNumberUpdater});
          tempItemAddingMap.addAll({'itemCancelled': 'false'});
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
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .currentUserPhoneNumberFromClass]['restaurantName'],
        body: '*newOrderForCook*');
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
        if (bluetoothConnected) {
          bluetooth.disconnect();
          _everySecondForConnection = 0;
          setState(() {
            showSpinner = false;

            tappedPrintButton = false;
            print('12 $tappedPrintButton');

            _connected = false;
          });
        }
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
                builder: (context) => MenuPageWithRunningOrdersChange(
                  hotelName: widget.hotelName,
                  tableOrParcel: widget.tableOrParcel,
                  tableOrParcelNumber: widget.tableOrParcelNumber,
                  menuItems: widget.menuItems,
                  menuPrices: widget.menuPrices,
                  menuTitles: widget.menuTitles,
                  itemsAddedMapCalled: widget.itemsAddedMap,
                  itemsAddedCommentCalled: widget.itemsAddedComment,
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
              if (bluetoothConnected) {
                bluetooth.disconnect();
                _everySecondForConnection = 0;
                setState(() {
                  showSpinner = false;

                  tappedPrintButton = false;
                  print('12 $tappedPrintButton');

                  _connected = false;
                });
              }
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
                      builder: (context) => MenuPageWithRunningOrdersChange(
                        hotelName: widget.hotelName,
                        tableOrParcel: widget.tableOrParcel,
                        tableOrParcelNumber: widget.tableOrParcelNumber,
                        menuItems: widget.menuItems,
                        menuPrices: widget.menuPrices,
                        menuTitles: widget.menuTitles,
                        itemsAddedMapCalled: widget.itemsAddedMap,
                        itemsAddedCommentCalled: widget.itemsAddedComment,
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
                //  else {
                //   print('back timer at cancel is $_everyMilliSecondBeforeGoingBack');
                //   _timerAtBackButton!.cancel();
                //   Navigator.pushReplacement(
                //     context,
                //     MaterialPageRoute(
                //       builder: (context) => MenuPageAddItems(
                //         hotelName: widget.hotelName,
                //         tableOrParcel: widget.tableOrParcel,
                //         tableOrParcelNumber: widget.tableOrParcelNumber,
                //         menuItems: widget.menuItems,
                //         menuPrices: widget.menuPrices,
                //         menuTitles: widget.menuTitles,
                //         itemsAddedMapCalled: widget.itemsAddedMap,
                //         unavailableItems: widget.unavailableItems,
                //       ),
                //     ),
                //   );
                //   print('back timer at true is is $_everyMilliSecondBeforeGoingBack');
                //   // return true;
                //   // Navigator.pop(context);
                //   // return true;
                //
                // }
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
                          .captainPrinterAddressFromClass ==
                      ''
                  ? Expanded(
                      child: BottomButton(
                        buttonColor: kBottomContainerColour,
                        buttonWidth: double.infinity,
                        buttonTitle: 'Add Printer',
                        onTap: () {
                          bluetoothStateChangeFunction();

                          if (bluetoothOnTrueOrOffFalse) {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        SearchingConnectingPrinter(
                                            chefOrCaptain: 'Captain')));
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
                      ),
                    )
                  : Expanded(
                      child: BottomButton(
                        buttonColor: Colors.orangeAccent,
                        buttonWidth: double.infinity,
                        buttonTitle: 'Print KOT',
                        onTap: () {
                          disconnectAndConnectAttempted = false;
                          // tappedPrintButton = true;
                          print(
                              'from bottom button entry-tapped Print Button $tappedPrintButton');
                          if (tappedPrintButton == false) {
                            bluetoothStateChangeFunction();
                          }
                          if (bluetoothOnTrueOrOffFalse) {
                            if (tappedPrintButton == false) {
                              print('came with false');
                              tappedPrintButton = true;
                              DateTime now = DateTime.now();
                              bool allItemsAddedToItemsUpdaterString = false;

//InitialPortionsOfTheItemUpdaterStringForTheTable/Parcel/Number
//WeNeedThisOnlyIfNoOrdersHadBeenTakenTillNow
//Else,theLastOrderWillHaveThe Table/parcel Number
//HenceTheIfElseLoop
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
                              separateKOTForEachUserPrintMap = [];
                              allUserProfile.forEach((keyOfUser, valueUser) {
//SinceThereIsAnotherKeyValueInside,AddingUserAlongWithIt
                                List<String> userWontCook = [];
                                if (valueUser['wontCook'] != null) {
                                  List<dynamic> tempUserWontCook =
                                      valueUser['wontCook'];
                                  userWontCook = tempUserWontCook
                                      .map((e) => e.toString())
                                      .toList();
                                }
                                Map<String, dynamic> eachUserPrinterMap =
                                    HashMap();
                                List<String> printKOTItemNames = [];
                                List<num> printKOTNumberOfItems = [];
                                List<String> printKOTItemComments = [];
                                if (valueUser['privileges']['8'] == true) {
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
//ThisWillEnsureIfTheCookDoesntHaveAnythingToCookBecauseOfChefSpecialities...
// ...ThenHisListWontBeAdded
                                  if (printKOTItemNames.isNotEmpty) {
                                    eachUserPrinterMap.addAll(
                                        {'printItemNames': printKOTItemNames});
                                    eachUserPrinterMap.addAll({
                                      'printItemNumbers': printKOTNumberOfItems
                                    });
                                    eachUserPrinterMap.addAll({
                                      'printItemComments': printKOTItemComments
                                    });
                                    separateKOTForEachUserPrintMap
                                        .addAll({eachUserPrinterMap});
                                  }
                                }
                              });
                              if (separateKOTForEachUserPrintMap.isNotEmpty) {
                                if (_connected == false) {
                                  printerConnectionToLastSavedPrinterForKOT();
                                } else {
                                  setState(() {
                                    showSpinner = true;
                                  });
                                  print(
                                      'came inside printer already connected');
                                  printKOTThroughBluetoothForSeparateUser();
                                }
                              } else {
                                errorAlertDialogBox(
                                    'Please assign Chef Specialities to at least one user');
                              }
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
                      ),
                    ),
              SizedBox(width: 10),
              Expanded(
                child: BottomButton(
                  buttonColor: Colors.green,
                  buttonWidth: double.infinity,
                  buttonTitle: 'Send to Kitchen',
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
