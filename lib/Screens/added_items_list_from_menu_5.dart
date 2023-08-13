import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_alt/modal_progress_hud_alt.dart';
import 'package:orders_dev/Methods/bottom_button.dart';
import 'package:orders_dev/Screens/menu_page_add_items_3.dart';
import 'package:orders_dev/Screens/printer_settings_screen.dart';
import 'package:orders_dev/Screens/searching_Connecting_Printer_Screen.dart';
import 'package:orders_dev/constants.dart';
import 'package:orders_dev/services/firestore_services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:orders_dev/Methods/printerenum.dart' as printerenum;
import 'package:provider/provider.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';

class AddedItemsFromMenuPrintChange extends StatefulWidget {
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
  final String addedItemsSet;
  List<String> unavailableItems;
//ThisItemsAddedMapIsHashMapWhichContainsDataOnWhatAllAreTheItemsAddedAnd,,
//HowManyIsAdded
  Map<String, num> itemsAddedMap = HashMap();
  Map<String, String> itemsAddedComment = HashMap();
  final String parentOrChild;

  AddedItemsFromMenuPrintChange(
      {required this.hotelName,
      required this.menuItems,
      required this.menuPrices,
      required this.menuTitles,
      required this.tableOrParcel,
      required this.tableOrParcelNumber,
      required this.itemsAddedMap,
      required this.itemsAddedComment,
      required this.addedItemsSet,
      required this.unavailableItems,
      required this.parentOrChild});

  @override
  _AddedItemsFromMenuPrintChangeState createState() =>
      _AddedItemsFromMenuPrintChangeState();
}

class _AddedItemsFromMenuPrintChangeState
    extends State<AddedItemsFromMenuPrintChange> {
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
          bluetooth.disconnect();
          setState(() => _connected = false);
          _everySecondForConnection = 0;

          if (disconnectAndConnectAttempted) {
            tappedPrintButton = false;
            setState(() {
              showSpinner = false;
            });
          } else {
            Timer? _timerInDisconnectAndConnect;
            _timerInDisconnectAndConnect =
                Timer.periodic(const Duration(seconds: 1), (_) async {
              if (_everySecondHelpingToDisconnectBeforeConnectingAgain < 4) {
                _everySecondHelpingToDisconnectBeforeConnectingAgain++;
                print(
                    '_everySecondHelpingToDisconnectBeforeConnectingAgainInChefScreen $_everySecondHelpingToDisconnectBeforeConnectingAgain');
              } else {
                _timerInDisconnectAndConnect!.cancel;
                print('need a dosconnection here4');
                if (disconnectAndConnectAttempted == false) {
                  disconnectAndConnectAttempted = true;
                  printerConnectionToLastSavedPrinterForKOT();
                } else {
                  _timerInDisconnectAndConnect!.cancel();
                }
                _everySecondHelpingToDisconnectBeforeConnectingAgain = 0;
                printerConnectionToLastSavedPrinterForKOT();
                print(
                    'cancelling _everySecondHelpingToDisconnectBeforeConnectingAgain $_everySecondHelpingToDisconnectBeforeConnectingAgain');
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
        if (localKOTItemNames.isEmpty) {
          localKOTItemNames.add('Printer Check');
          localKOTNumberOfItems.add(1);
          localKOTItemComments.add(' ');
        }
      } else {
        if (_connected) {
          print('Inside intermediate- it is connected');
          printKOTThroughBluetooth();
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
            bluetooth.printNewLine();
            for (int i = 0; i < localKOTItemNames.length; i++) {
              if ((' '.allMatches(localKOTItemNames[i]).length >= 3)) {
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
                bluetooth.printNewLine();
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
              if (i == (localKOTItemNames.length - 1)) {
                _disconnectForKOTPrint();
              }
            }
          } else if (Provider.of<PrinterAndOtherDetailsProvider>(context,
                      listen: false)
                  .captainPrinterSizeFromClass ==
              '58') {
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
            bluetooth.printNewLine();
            for (int i = 0; i < localKOTItemNames.length; i++) {
              if ((' '.allMatches(localKOTItemNames[i]).length >= 3)) {
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
                bluetooth.printCustom(
                  "$firstName x ${localKOTNumberOfItems[i].toString()}",
                  printerenum.Size.bold.val,
                  printerenum.Align.left.val,
                );
                bluetooth.printCustom(
                  "$secondName",
                  printerenum.Size.bold.val,
                  printerenum.Align.left.val,
                );
                bluetooth.printNewLine();
              } else {
                bluetooth.printCustom(
                  "${localKOTItemNames[i]} x ${localKOTNumberOfItems[i].toString()}",
                  printerenum.Size.bold.val,
                  printerenum.Align.left.val,
                );
              }

              if (localKOTItemComments[i] != 'nocomments') {
                bluetooth.printCustom(
                    "     (Comment : ${localKOTItemComments[i]})",
                    printerenum.Size.bold.val,
                    printerenum.Align.left.val);
              }
              //ToAccessDisconnectWhenWeArePrintingParcel
              if (i == (localKOTItemNames.length - 1)) {
                _disconnectForKOTPrint();
              }
            }
          }

          bluetooth.printNewLine();
          bluetooth.printNewLine();

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
    FireStoreAddOrderServiceWithSplit(
            hotelName: widget.hotelName,
            itemsUpdaterString: localItemsUpdaterString,
            seatingNumber: localSeatingNumber,
            captainStatus: localCaptainStatus,
            chefStatus: localChefStatus,
            partOfTableOrParcel: localPartOfTableOrParcel,
            partOfTableOrParcelNumber: localPartOfTableOrParcelNumber)
        .addOrder();
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

  @override
  Widget build(BuildContext context) {
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
                builder: (context) => MenuPageWithSplit(
                  hotelName: widget.hotelName,
                  tableOrParcel: widget.tableOrParcel,
                  tableOrParcelNumber: widget.tableOrParcelNumber,
                  menuItems: widget.menuItems,
                  menuPrices: widget.menuPrices,
                  menuTitles: widget.menuTitles,
                  itemsAddedMapCalled: widget.itemsAddedMap,
                  itemsAddedCommentCalled: widget.itemsAddedComment,
                  unavailableItems: widget.unavailableItems,
                  addedItemsSet: widget.addedItemsSet,
                  parentOrChild: widget.parentOrChild,
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
                      builder: (context) => MenuPageWithSplit(
                        hotelName: widget.hotelName,
                        tableOrParcel: widget.tableOrParcel,
                        tableOrParcelNumber: widget.tableOrParcelNumber,
                        menuItems: widget.menuItems,
                        menuPrices: widget.menuPrices,
                        menuTitles: widget.menuTitles,
                        itemsAddedMapCalled: widget.itemsAddedMap,
                        itemsAddedCommentCalled: widget.itemsAddedComment,
                        unavailableItems: widget.unavailableItems,
                        addedItemsSet: widget.addedItemsSet,
                        parentOrChild: widget.parentOrChild,
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
                      ),
                    )
                  : Expanded(
                      child: BottomButton(
                        buttonColor: Colors.orangeAccent,
                        buttonWidth: double.infinity,
                        buttonTitle: 'Update & Print',
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
                              String ticketNumberUpdater = '1';
//InitialPortionsOfTheItemUpdaterStringForTheTable/Parcel/Number
//WeNeedThisOnlyIfNoOrdersHadBeenTakenTillNow
//Else,theLastOrderWillHaveThe Table/parcel Number
//HenceTheIfElseLoop
                              itemsUpdaterString = '';
                              localKOTItemNames = [];
                              localKOTNumberOfItems = [];
                              localKOTItemComments = [];

                              if (widget.addedItemsSet == '') {
                                for (int i = 0; i < 15; i++) {
                                  if (i == 0) {
                                    itemsUpdaterString = (itemsUpdaterString +
                                        widget.tableOrParcel +
                                        '*');
                                  }
                                  if (i == 1) {
                                    itemsUpdaterString = (itemsUpdaterString +
                                        widget.tableOrParcelNumber.toString() +
                                        '*');
                                  }
                                  if (i == 2) {
//toUpdateWhenTheySatOnTheTableAndGaveTheFirstOrder

                                    itemsUpdaterString = (itemsUpdaterString +
                                        ((now.hour * 60) + now.minute)
                                            .toString() +
                                        '*');
                                  }

                                  if (i == 3) {
//toUpdateTicketNumberForThatTable

                                    itemsUpdaterString = (itemsUpdaterString +
                                        ticketNumberUpdater +
                                        '*');
                                  }
                                  if (i == 4) {
                                    itemsUpdaterString = (itemsUpdaterString +
                                        'customername' +
                                        '*');
                                  }
                                  if (i == 5) {
                                    itemsUpdaterString = (itemsUpdaterString +
                                        'customermobileNumber' +
                                        '*');
                                  }
                                  if (i == 6) {
                                    itemsUpdaterString = (itemsUpdaterString +
                                        'customeraddressline1' +
                                        '*');
                                  }
                                  if (i == 7) {
                                    itemsUpdaterString = (itemsUpdaterString +
                                        '${widget.parentOrChild}' +
                                        '*');
                                  }

                                  if (i == 8) {
                                    itemsUpdaterString = (itemsUpdaterString +
                                        'noSerialYet' +
                                        '*');
                                  }

                                  if (i > 8) {
                                    itemsUpdaterString = (itemsUpdaterString +
                                        'futureUse' +
                                        '*');
                                  }
                                }
                              } else {
                                String beforeItemsUpdaterString =
                                    widget.addedItemsSet;
                                final itemsUpdaterSplit =
                                    beforeItemsUpdaterString.split('*');
                                num numberOfTicketsTillNow =
                                    num.parse(itemsUpdaterSplit[3]);
                                ticketNumberUpdater =
                                    (numberOfTicketsTillNow + 1).toString();
                                itemsUpdaterSplit[3] = ticketNumberUpdater;
                                itemsUpdaterString = '';
                                for (int i = 0;
                                    i < itemsUpdaterSplit.length - 1;
                                    i++) {
                                  itemsUpdaterString +=
                                      '${itemsUpdaterSplit[i]}*';
                                }
                              }
                              localSlotNumber = widget.parentOrChild == 'parent'
                                  ? '${widget.tableOrParcel}:${widget.tableOrParcelNumber}'
                                  : '${widget.tableOrParcel}:${widget.tableOrParcelNumber}${widget.parentOrChild}';
                              localTicketNumber = ticketNumberUpdater;
                              localPartOfTableOrParcel = widget.tableOrParcel;
                              localPartOfTableOrParcelNumber =
                                  widget.tableOrParcelNumber.toString();

                              //IfTheItemHasSomeNumberOfItemsOrdered
                              //Meaning,TheWaiterHadn'tReducedTheItemToZero
                              //ThenWeGoToThisLoop
                              int checkerForItemsAddedMapCompletion = 0;
                              widget.itemsAddedMap.forEach((key, value) {
                                ++checkerForItemsAddedMapCompletion;
                                //WeGoThroughItemsAddedMapOneByOne
                                //AndUploadToFireStore,HotelNameItemName,Number,TableNumber,,
                                //PriceOfTheItemAndGiveAddOrder
                                //AddOrderIsSeparateClassWeHadCreated,,
                                //WhereMostOfTheFireStoreWorksAreDone
                                //itWillSendTheOrderToFireStoreDatabase
                                if (widget.itemsAddedMap[key] != 0) {
                                  String itemComment = 'nocomments';
                                  if (widget.itemsAddedComment[key] != '') {
                                    itemComment =
                                        widget.itemsAddedComment[key]!;
                                  }
                                  localKOTItemNames.add(key);
                                  localKOTNumberOfItems
                                      .add(widget.itemsAddedMap[key]!);
                                  localKOTItemComments.add(itemComment);
                                  itemsUpdaterString = itemsUpdaterString +
                                      ((10000 + Random().nextInt(99999 - 10000))
                                          .toString()) +
                                      '*' +
                                      key +
                                      '*' +
                                      localMenuPrice[
                                              localMenuItems.indexOf(key)]
                                          .toString() +
                                      '*' +
                                      widget.itemsAddedMap[key].toString() +
                                      '*' +
                                      ((now.hour * 60) + now.minute)
                                          .toString() +
                                      '*' +
                                      '9' +
                                      '*' +
                                      itemComment +
                                      '*' +
                                      'chefkotnotyet' +
                                      '*' +
                                      ticketNumberUpdater +
                                      '*' +
                                      'futureUse' +
                                      '*' +
                                      'futureUse' +
                                      '*' +
                                      'futureUse' +
                                      '*' +
                                      'futureUse' +
                                      '*' +
                                      'futureUse' +
                                      '*' +
                                      'futureUse' +
                                      '*';
                                }
                                if (checkerForItemsAddedMapCompletion ==
                                    widget.itemsAddedMap.length) {
                                  print('came Inside thissss');
                                  final statusUpdatedStringCheck =
                                      itemsUpdaterString.split('*');

//keepingDefaultAs7-AcceptedStatusWhichNeedNotCreateAnyIssue
                                  num chefStatus = 7;
                                  num captainStatus = 7;

                                  for (int j = 1;
                                      j <
                                          ((statusUpdatedStringCheck.length -
                                                  1) /
                                              15);
                                      j++) {
//ThisForLoopWillGoThroughEveryOrder,GoExactlyThroughThePointsWhereStatusIsThere
                                    if (((statusUpdatedStringCheck[
                                            (j * 15) + 5]) ==
                                        '11')) {
                                      captainStatus = 11;
                                    } else if (((statusUpdatedStringCheck[
                                                (j * 15) + 5]) ==
                                            '10') &&
                                        captainStatus != 11) {
                                      captainStatus = 10;
                                    }
                                    if (((statusUpdatedStringCheck[
                                            (j * 15) + 5]) ==
                                        '9')) {
                                      chefStatus = 9;
                                    }
                                  }
                                  localItemsUpdaterString = itemsUpdaterString;
                                  localSeatingNumber = widget.parentOrChild ==
                                          'parent'
                                      ? '${widget.tableOrParcel}:${widget.tableOrParcelNumber}'
                                      : '${widget.tableOrParcel}:${widget.tableOrParcelNumber}${widget.parentOrChild}';
                                  localCaptainStatus = captainStatus;
                                  localChefStatus = chefStatus;
                                  localPartOfTableOrParcel =
                                      widget.tableOrParcel;
                                  localPartOfTableOrParcelNumber =
                                      widget.tableOrParcelNumber.toString();
                                  if (_connected == false) {
                                    printerConnectionToLastSavedPrinterForKOT();
                                  } else {
                                    setState(() {
                                      showSpinner = true;
                                    });
                                    print(
                                        'came inside printer already connected');
                                    printKOTThroughBluetooth();
                                  }

                                  // FireStoreAddOrderServiceAsString(
                                  //     hotelName: widget.hotelName,
                                  //     itemsUpdaterString: itemsUpdaterString,
                                  //     captainStatus: captainStatus,
                                  //     chefStatus: chefStatus,
                                  //     seatingNumber:
                                  //     '${widget.tableOrParcel}:${widget.tableOrParcelNumber}')
                                  //     .addOrder();
                                }
                              });
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
                  buttonTitle: 'Update Order',
                  onTap: () {
                    DateTime now = DateTime.now();
                    bool allItemsAddedToItemsUpdaterString = false;
                    String ticketNumberUpdater = '1';
//InitialPortionsOfTheItemUpdaterStringForTheTable/Parcel/Number
//WeNeedThisOnlyIfNoOrdersHadBeenTakenTillNow
//Else,theLastOrderWillHaveThe Table/parcel Number
//HenceTheIfElseLoop
                    itemsUpdaterString = '';

                    if (widget.addedItemsSet == '') {
                      for (int i = 0; i < 15; i++) {
                        if (i == 0) {
                          itemsUpdaterString =
                              (itemsUpdaterString + widget.tableOrParcel + '*');
                        }
                        if (i == 1) {
                          itemsUpdaterString = (itemsUpdaterString +
                              widget.tableOrParcelNumber.toString() +
                              '*');
                        }
                        if (i == 2) {
//toUpdateWhenTheySatOnTheTableAndGaveTheFirstOrder

                          itemsUpdaterString = (itemsUpdaterString +
                              ((now.hour * 60) + now.minute).toString() +
                              '*');
                        }

                        if (i == 3) {
//toUpdateTicketNumberForThatTable

                          itemsUpdaterString =
                              (itemsUpdaterString + ticketNumberUpdater + '*');
                        }
                        if (i == 4) {
                          itemsUpdaterString =
                              (itemsUpdaterString + 'customername' + '*');
                        }
                        if (i == 5) {
                          itemsUpdaterString = (itemsUpdaterString +
                              'customermobileNumber' +
                              '*');
                        }
                        if (i == 6) {
                          itemsUpdaterString = (itemsUpdaterString +
                              'customeraddressline1' +
                              '*');
                        }

                        if (i == 7) {
                          itemsUpdaterString = (itemsUpdaterString +
                              '${widget.parentOrChild}' +
                              '*');
                        }

                        if (i == 8) {
                          itemsUpdaterString =
                              (itemsUpdaterString + 'noSerialYet' + '*');
                        }

                        if (i > 8) {
                          itemsUpdaterString =
                              (itemsUpdaterString + 'futureUse' + '*');
                        }
                      }
                    } else {
                      String beforeItemsUpdaterString = widget.addedItemsSet;
                      final itemsUpdaterSplit =
                          beforeItemsUpdaterString.split('*');
                      num numberOfTicketsTillNow =
                          num.parse(itemsUpdaterSplit[3]);
                      ticketNumberUpdater =
                          (numberOfTicketsTillNow + 1).toString();
                      itemsUpdaterSplit[3] = ticketNumberUpdater;
                      itemsUpdaterString = '';
                      for (int i = 0; i < itemsUpdaterSplit.length - 1; i++) {
                        itemsUpdaterString += '${itemsUpdaterSplit[i]}*';
                      }
                    }

                    //IfTheItemHasSomeNumberOfItemsOrdered
                    //Meaning,TheWaiterHadn'tReducedTheItemToZero
                    //ThenWeGoToThisLoop
                    int checkerForItemsAddedMapCompletion = 0;
                    widget.itemsAddedMap.forEach((key, value) {
                      ++checkerForItemsAddedMapCompletion;
                      //WeGoThroughItemsAddedMapOneByOne
                      //AndUploadToFireStore,HotelNameItemName,Number,TableNumber,,
                      //PriceOfTheItemAndGiveAddOrder
                      //AddOrderIsSeparateClassWeHadCreated,,
                      //WhereMostOfTheFireStoreWorksAreDone
                      //itWillSendTheOrderToFireStoreDatabase
                      if (widget.itemsAddedMap[key] != 0) {
                        String itemComment = 'nocomments';
                        if (widget.itemsAddedComment[key] != '') {
                          itemComment = widget.itemsAddedComment[key]!;
                        }
                        itemsUpdaterString = itemsUpdaterString +
                            ((10000 + Random().nextInt(99999 - 10000))
                                .toString()) +
                            '*' +
                            key +
                            '*' +
                            localMenuPrice[localMenuItems.indexOf(key)]
                                .toString() +
                            '*' +
                            widget.itemsAddedMap[key].toString() +
                            '*' +
                            ((now.hour * 60) + now.minute).toString() +
                            '*' +
                            '9' +
                            '*' +
                            itemComment +
                            '*' +
                            'chefkotnotyet' +
                            '*' +
                            ticketNumberUpdater +
                            '*' +
                            'futureUse' +
                            '*' +
                            'futureUse' +
                            '*' +
                            'futureUse' +
                            '*' +
                            'futureUse' +
                            '*' +
                            'futureUse' +
                            '*' +
                            'futureUse' +
                            '*';
                      }
                      if (checkerForItemsAddedMapCompletion ==
                          widget.itemsAddedMap.length) {
                        print('came Inside this');
                        final statusUpdatedStringCheck =
                            itemsUpdaterString.split('*');

//keepingDefaultAs7-AcceptedStatusWhichNeedNotCreateAnyIssue
                        num chefStatus = 7;
                        num captainStatus = 7;

                        for (int j = 1;
                            j < ((statusUpdatedStringCheck.length - 1) / 15);
                            j++) {
//ThisForLoopWillGoThroughEveryOrder,GoExactlyThroughThePointsWhereStatusIsThere
                          if (((statusUpdatedStringCheck[(j * 15) + 5]) ==
                              '11')) {
                            captainStatus = 11;
                          } else if (((statusUpdatedStringCheck[
                                      (j * 15) + 5]) ==
                                  '10') &&
                              captainStatus != 11) {
                            captainStatus = 10;
                          }
                          if (((statusUpdatedStringCheck[(j * 15) + 5]) ==
                              '9')) {
                            chefStatus = 9;
                          }
                        }
                        FireStoreAddOrderServiceWithSplit(
                                hotelName: widget.hotelName,
                                itemsUpdaterString: itemsUpdaterString,
                                captainStatus: captainStatus,
                                chefStatus: chefStatus,
                                seatingNumber: widget.parentOrChild == 'parent'
                                    ? '${widget.tableOrParcel}:${widget.tableOrParcelNumber}'
                                    : '${widget.tableOrParcel}:${widget.tableOrParcelNumber}${widget.parentOrChild}',
                                partOfTableOrParcel: widget.tableOrParcel,
                                partOfTableOrParcelNumber:
                                    widget.tableOrParcelNumber.toString())
                            .addOrder();
                      }
                    });
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
