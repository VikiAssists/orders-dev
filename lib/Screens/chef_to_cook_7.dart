//ThisIsThePresentBluetoothScreenWithBlueThermalPrinterPackage_5Feb2023
import 'dart:async';
import 'dart:collection';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:orders_dev/Screens/printer_settings_screen.dart';
import 'package:orders_dev/Screens/searching_Connecting_Printer_Screen.dart';
import 'package:orders_dev/constants.dart';
import 'package:orders_dev/services/firestore_services.dart';
import 'package:modal_progress_hud_alt/modal_progress_hud_alt.dart';
import 'package:orders_dev/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:orders_dev/Methods/printerenum.dart' as printerenum;
import 'package:provider/provider.dart';
import 'package:wakelock/wakelock.dart';
import 'package:video_player/video_player.dart';

// bool thisIsChefCallingForBackground = true;
// String hotelNameForBackground = '';
// bool chefPrinterKOTFromClassForBackgroundKOT = false;
// List<String> chefSpecialitiesForBackground = [];
// var chefPrinterAddressFromClassForBackground;
// String chefPrinterSizeFromClassForBackground = '';

//ThisIsTheScreenWhereTheCookGetsTheItemsToCook
class ChefToCookFullForm extends StatefulWidget {
  //TheInputsAreHotelNameAndChefSpecialities
  //ChefSpecialitiesAreTheItemsChefWon'tCook
  //Example:thereAreCooksWhoMakeJuicesAlone.So,
  //basedOnChefSpecialities,theCookWon'tGetTheItemsOtherThanJuices
  //ChefSpecialitiesIsInputtedWhenThisScreenIsCalledItself

  final String hotelName;
  final List<String> chefSpecialities;

  ChefToCookFullForm(
      {Key? key, required this.hotelName, required this.chefSpecialities})
      : super(key: key);

  @override
  State<ChefToCookFullForm> createState() => _ChefToCookFullFormState();
}

//InThisScreen,WeNeedToKnowWhenTheScreenIsOnAndWhenItIsOff
//OnlyThenWeCanAlertTheChefWhenNewItemComesEvenWhenTheScreenIsOff
//ToUnderstandThisScreenState,WeUseWidgetsBindingObserver

class _ChefToCookFullFormState extends State<ChefToCookFullForm>
    with WidgetsBindingObserver {
//0-InitialStateOfPrinterWhenEnteringScreen
//1-PrinterIsDisconnectedByTheUser
//2-SomePrinterConnected
//3-CheckingForNewPrinter
  //thisIsTheVariableWeUseTheKeepTrackOfBluetoothPrinterConnection
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  List<BluetoothDevice> _devices = [];
  List<BluetoothDevice> additionalDevices = [];
  BluetoothDevice? _device;
  bool _connected = false;
  bool printingOver = true;
  int _everySecondForConnection = 0;

  String tips = 'no device connect';

  bool bluetoothConnected = false;
  bool bluetoothAlreadyConnected = false;
  //String hotelNameAlone = '';
//SpinnerOrCircularProgressIndicatorWhenTryingToPrint
  bool showSpinner = false;
  String printerSize = '0';
//InCase,DeviceNotConnectingInFirstAttempt,WeCanTryThis
  bool disconnectAndConnectAttempted = false;
//checkingBluetoothOnOrOff
  bool bluetoothOnTrueOrOffFalse = true;

  bool bluetoothTurnOnMessageShown = false;
  int timeForKot = 1;
  int kotCounter = 0;
  int _everySecondForKot = 0;
  int _everySecondForKotTimer = 0;
  List<String> tempLocalKOTItemNames = [];
  bool bluetoothJustTurningOn = false;
  bool timerForPrintingKOTRunning = false;
  bool timerForPrintingTenSecKOTRunning = false;
  bool intermediatePrintingCallKOTRunning = false;
  bool intermediatePrintingAfterOrderReadyRunning = false;
  bool appInBackground = false;
  bool timerRunningForCheckingNewOrdersInBackground = false;
  late VideoPlayerController _videoController;

  //WeHaveAnAudioPlayer.ThisAudioPlayerIsAPackageDownloadedFromInternet
  //InInitialState,WeAlwaysKeepItStopped&PlayerPlayingBoolWillBeFalse
  //WeHaveTimerSoThat,Every30Seconds,WeCanRingChefBellWhenTheScreenIsOff,,
  //AndNewItemComes
  //WeHave"ItemsArrivedArrivedInLastCheck"ListToEnsureWeDon'tRingTheBellFor,,
  //SameItemAgain&Again
  //pageHasInternetToCheckConnectivity
  //StreamSubscriptionIsHowWeKeepCheckingWhetherThePageHasInternetAnd,,
  //ifItDoesn'tHaveInternet,WeCanAlertTheUser
  //WeKeepCheckingWithAStreamWhetherThereIsInternet

  final player = AudioPlayer();
  PlayerState playerState = PlayerState.stopped;
  bool playerPlaying = false;
  int _everyThirtySeconds = 0;
  Timer? _timer;
  Timer? _timerToGoForKOt;
  bool someNewItemsOrdered = false;
  List<String> itemsArrivedInLastCheck = [];
  bool pageHasInternet = true;
  late StreamSubscription internetCheckerSubscription;
  //ThisThreeWillHelpToEnsureWeCanPrintOutsideShowModalButton(BottomPage)
  List<String> localParcelReadyItemNames = [];
  String localTableOrParcelNumber = '';
  List<num> localParcelReadyNumberOfItems = [];
  List<String> localParcelReadyItemComments = [];
  String localParcelNumber = '';
  bool locationPermissionAccepted = true;
  List<String> cancelledItemsKey = [];

  List<String> localKOTItemNames = [];
  List<num> localKOTNumberOfItems = [];
  List<String> localKOTItemComments = [];
  List<String> localKotItemsBelongsToDoc = [];
  List<String> localKotItemsEntireItemListBeforeSplitting = [];
  List<String> localKotItemsEachItemFromEntireItemsString = [];
  List<String> localKotItemsTableOrParcel = [];
  List<String> localKotItemsTableOrParcelNumber = [];
  List<String> localKotItemsParentOrChild = [];
  List<String> localKotItemsTicketNumber = [];
  List<String> localKOTItemsID = [];
  List<String> localKotCancelledItemTrueElseFalse = [];
  List<String> tempLocalKOTItemsID = [];
  num backgroundTimerCounter = 0;

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
            bluetoothJustTurningOn = false;
            print("bluetooth device state: connected");
          });
          break;
        case BlueThermalPrinter.DISCONNECTED:
          setState(() {
            _connected = false;
            bluetoothOnTrueOrOffFalse = true;
            bluetoothJustTurningOn = false;
            print("bluetooth device state: disconnected");
          });
          break;
        case BlueThermalPrinter.DISCONNECT_REQUESTED:
          setState(() {
            _connected = false;
            bluetoothOnTrueOrOffFalse = true;
            bluetoothJustTurningOn = false;
            print("bluetooth device state: disconnect requested");
          });
          break;
        case BlueThermalPrinter.STATE_TURNING_OFF:
          setState(() {
            _connected = false;
            bluetoothOnTrueOrOffFalse = false;
            bluetoothJustTurningOn = false;
            print("bluetooth device state: bluetooth turning off");
          });
          break;
        case BlueThermalPrinter.STATE_OFF:
          setState(() {
            _connected = false;
            bluetoothOnTrueOrOffFalse = false;
            bluetoothJustTurningOn = false;
            print("bluetooth device state: bluetooth off");
          });
          break;
        case BlueThermalPrinter.STATE_ON:
          setState(() {
            _connected = false;
            bluetoothOnTrueOrOffFalse = true;
            bluetoothJustTurningOn = false;
            print("bluetooth device state: bluetooth on");
          });
          break;
        case BlueThermalPrinter.STATE_TURNING_ON:
          // _everySecondForKotTimer = -15;
          setState(() {
            bluetoothTurnOnMessageShown = false;
            bluetoothJustTurningOn = true;
            print('bluetoothTurnOnMessageShown $bluetoothTurnOnMessageShown');
            print('came into bluetooth state turning on');
            if (localKOTItemNames.isNotEmpty &&
                timerForPrintingKOTRunning == false &&
                timerForPrintingTenSecKOTRunning == false &&
                intermediatePrintingCallKOTRunning == false &&
                intermediatePrintingAfterOrderReadyRunning == false) {
              timerForPrintingKOT();
            }
            _connected = false;
            bluetoothOnTrueOrOffFalse = true;
            print("bluetooth device state: bluetooth turning on");
          });
          break;
        case BlueThermalPrinter.ERROR:
          setState(() {
            _connected = false;
            bluetoothOnTrueOrOffFalse = true;
            bluetoothJustTurningOn = false;
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

  //FunctionToConnectToTheSavedBluetoothPrinter
  Future<void> printerConnectionToLastSavedPrinterForAfterOrderPrint() async {
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
      setState(() {
        showSpinner = true;
      });
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
                .chefPrinterAddressFromClass) {
          printerPairedTrueYetToPairFalse = true;
          print('checking for printer saved');
          var nowConnectingPrinter = device;
          _connectForAfterOrderPrint(nowConnectingPrinter);
        }
        if (devicesCount == _devices.length &&
            printerPairedTrueYetToPairFalse == false) {
          setState(() {
            showSpinner = false;
          });
          print('here7');
          if (appInBackground == false) {
            show('Couldn\'t Connect. Please check Printer');
          }

          printingOver = true;
        }
      }
    }
    // else {
    //   show('Please Turn On Bluetooth');
    // }

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

  void _connectForAfterOrderPrint(BluetoothDevice nowConnectingPrinter) {
    bool timerForStartOfPrinting;
    print('start of _Connect loop');
    if (nowConnectingPrinter != null) {
      print('device isnt null');

      bluetooth.isConnected.then((isConnected) {
        print('came inside bluetooth trying to connect');
        if (isConnected == false) {
          bluetooth.connect(nowConnectingPrinter!).catchError((error) {
            print('did not get connected1 inside _connect- ${_connected}');
            if (appInBackground == false) {
              show('Couldn\'t Connect. Please check Printer');
            }

            printingOver = true;
            setState(() {
              _connected = false;
              showSpinner = false;
            });
            print('did not get connected2 inside _connect- ${_connected}');
          });
          setState(() => _connected = true);
          print('we are connected inside _connect- ${_connected}');
          intermediateFunctionToCallPrintForAfterOrderReady();
        } else {
          int _everySecondHelpingToDisconnectBeforeConnectingAgain = 0;
          bluetooth.disconnect();
          setState(() => _connected = false);
          _everySecondForConnection = 0;

          if (disconnectAndConnectAttempted) {
            printingOver = true;
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
                  printerConnectionToLastSavedPrinterForAfterOrderPrint();
                } else {
                  _timerInDisconnectAndConnect!.cancel();
                }
                _everySecondHelpingToDisconnectBeforeConnectingAgain = 0;
                printerConnectionToLastSavedPrinterForAfterOrderPrint();
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

  void intermediateFunctionToCallPrintForAfterOrderReady() {
    if (showSpinner == false) {
      setState(() {
        showSpinner = true;
      });
    }
    intermediatePrintingAfterOrderReadyRunning = false;

    print('start of intermediateFunctionToCallPrintThroughBluetooth');
    Timer? _timer;
    _everySecondForConnection = 0;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_everySecondForConnection <= 2) {
        intermediatePrintingAfterOrderReadyRunning = true;
        print('timer inside connect is $_everySecondForConnection');
        _everySecondForConnection++;
        if (localParcelReadyItemNames.isEmpty) {
          localParcelReadyItemNames.add('Printer Check');
          localParcelReadyNumberOfItems.add(1);
          localParcelReadyItemComments.add(' ');
        }
      } else {
        intermediatePrintingAfterOrderReadyRunning = false;
        if (_connected) {
          print('Inside intermediate- it is connected');
          printAfterOrderReadyThroughBluetooth();
        } else {
          printingOver = true;
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

  void printAfterOrderReadyThroughBluetooth() {
    print('start of inside printThroughBluetooth');
    if (_connected) {
      bluetooth.isConnected.then((isConnected) {
        print('came inside bluetooth isConnected');
        if (isConnected == true) {
          print('inside printThroughBluetooth-is connected is true here');
          // bluetooth.printNewLine();
          if (localParcelReadyItemNames[0] != 'Printer Check') {
            bluetooth.printCustom("Slot:$localParcelNumber",
                printerenum.Size.extraLarge.val, printerenum.Align.center.val);
            bluetooth.printNewLine();
            bluetooth.printCustom(
                "Packed:${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year} at ${DateTime.now().hour}:${DateTime.now().minute}",
                printerenum.Size.medium.val,
                printerenum.Align.center.val);
            bluetooth.printNewLine();
            // bluetooth.printNewLine();
          }
          if (localParcelReadyItemNames.length > 1) {
            for (int i = 0; i < localParcelReadyItemNames.length; i++) {
              // print('i value is $i');
              // bluetooth.printLeftRight(
              //     "${localParcelReadyItemNames[i]} x ${localParcelReadyNumberOfItems[i]}",
              //     "",
              //     printerenum.Size.medium.val);
              // bluetooth.printCustom(
              //     "${localParcelReadyItemNames[i]} x ${localParcelReadyNumberOfItems[i].toString()}",
              //     printerenum.Size.medium.val,
              //     printerenum.Align.left.val);
              if (Provider.of<PrinterAndOtherDetailsProvider>(context,
                          listen: false)
                      .chefPrinterSizeFromClass ==
                  '80') {
                if ((' '.allMatches(localParcelReadyItemNames[i]).length >=
                    3)) {
                  String firstName = '';
                  String secondName = '';
                  String thirdName = '';
                  final longItemNameSplit =
                      localParcelReadyItemNames[i].split(' ');
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
                      secondName += '${longItemNameSplit[i]} ';
                    }
                    if (i > 3) {
                      thirdName += '${longItemNameSplit[i]} ';
                    }
                  }
                  bluetooth.printLeftRight(
                      "$firstName",
                      "${localParcelReadyNumberOfItems[i].toString()}",
                      printerenum.Size.bold.val,
                      format: "%-30s %10s %n");
                  bluetooth.printLeftRight(
                      "$secondName", "", printerenum.Size.bold.val,
                      format: "%-30s %10s %n");
                  bluetooth.printLeftRight(
                      "$thirdName", "", printerenum.Size.bold.val,
                      format: "%-30s %10s %n");
                } else {
                  bluetooth.printLeftRight(
                      "${localParcelReadyItemNames[i]}",
                      "${localParcelReadyNumberOfItems[i].toString()}",
                      printerenum.Size.bold.val,
                      format: "%-30s %30s %n");
                }

                if (localParcelReadyItemComments[i] != 'nocomments') {
                  bluetooth.printCustom(
                      "     (Comment : ${localParcelReadyItemComments[i]})",
                      printerenum.Size.medium.val,
                      printerenum.Align.left.val);
                }
              } else if (Provider.of<PrinterAndOtherDetailsProvider>(context,
                          listen: false)
                      .chefPrinterSizeFromClass ==
                  '58') {
                if ((' '.allMatches(localParcelReadyItemNames[i]).length >=
                    3)) {
                  String firstName = '';
                  String secondName = '';
                  String thirdName = '';
                  final longItemNameSplit =
                      localParcelReadyItemNames[i].split(' ');
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
                      secondName += '${longItemNameSplit[i]} ';
                    }
                    if (i > 3) {
                      thirdName += '${longItemNameSplit[i]} ';
                    }
                  }
                  bluetooth.printCustom(
                    "$firstName x ${localParcelReadyNumberOfItems[i].toString()}",
                    printerenum.Size.medium.val,
                    printerenum.Align.left.val,
                  );

                  bluetooth.printCustom(
                    "$secondName",
                    printerenum.Size.medium.val,
                    printerenum.Align.left.val,
                  );
                  bluetooth.printCustom(
                    "$thirdName",
                    printerenum.Size.medium.val,
                    printerenum.Align.left.val,
                  );
                } else {
                  bluetooth.printCustom(
                    "${localParcelReadyItemNames[i]} x ${localParcelReadyNumberOfItems[i].toString()}",
                    printerenum.Size.medium.val,
                    printerenum.Align.left.val,
                  );
                }

                if (localParcelReadyItemComments[i] != 'nocomments') {
                  bluetooth.printCustom(
                      "     (Comment : ${localParcelReadyItemComments[i]})",
                      printerenum.Size.medium.val,
                      printerenum.Align.left.val);
                }
              }

//ToAccessDisconnectWhenWeArePrintingParcel
              if (i == (localParcelReadyItemNames.length - 1)) {
                _disconnectForAfterOrderPrint();
              }
            }
            bluetooth.printNewLine();
            bluetooth.printNewLine();
            if (Provider.of<PrinterAndOtherDetailsProvider>(context,
                            listen: false)
                        .chefPrinterSizeFromClass ==
                    '80' &&
                localParcelReadyItemNames[0] != 'Printer Check') {
              bluetooth.printCustom(
                "Note:Consume Within Two Hours",
                printerenum.Size.bold.val,
                printerenum.Align.center.val,
              );
              bluetooth.printNewLine();
            } else if (Provider.of<PrinterAndOtherDetailsProvider>(context,
                            listen: false)
                        .chefPrinterSizeFromClass ==
                    '58' &&
                localParcelReadyItemNames[0] != 'Printer Check') {
              bluetooth.printCustom(
                "Note:Consume Within Two Hours",
                printerenum.Size.bold.val,
                printerenum.Align.left.val,
              );
              bluetooth.printNewLine();
              bluetooth.printNewLine();
            }
          } else {
            if (Provider.of<PrinterAndOtherDetailsProvider>(context,
                        listen: false)
                    .chefPrinterSizeFromClass ==
                '80') {
              if ((' '.allMatches(localParcelReadyItemNames[0]).length >= 3)) {
                String firstName = '';
                String secondName = '';
                String thirdName = '';
                final longItemNameSplit =
                    localParcelReadyItemNames[0].split(' ');
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
                    secondName += '${longItemNameSplit[i]} ';
                  }
                  if (i > 3) {
                    thirdName += '${longItemNameSplit[i]} ';
                  }
                }
                bluetooth.printLeftRight(
                    "$firstName",
                    "${localParcelReadyNumberOfItems[0].toString()}",
                    printerenum.Size.bold.val,
                    format: "%-30s %10s %n");
                bluetooth.printLeftRight(
                    "$secondName", "", printerenum.Size.bold.val,
                    format: "%-30s %10s %n");
                bluetooth.printLeftRight(
                    "$thirdName", "", printerenum.Size.bold.val,
                    format: "%-30s %10s %n");
              } else {
                bluetooth.printLeftRight(
                    "${localParcelReadyItemNames[0]}",
                    "${localParcelReadyNumberOfItems[0].toString()}",
                    printerenum.Size.bold.val,
                    format: "%-30s %30s %n");
              }

              if (localParcelReadyItemComments[0] != 'nocomments') {
                bluetooth.printCustom(
                    "     (Comment : ${localParcelReadyItemComments[0]})",
                    printerenum.Size.medium.val,
                    printerenum.Align.left.val);
              }
            } else if (Provider.of<PrinterAndOtherDetailsProvider>(context,
                        listen: false)
                    .chefPrinterSizeFromClass ==
                '58') {
              if ((' '.allMatches(localParcelReadyItemNames[0]).length >= 3)) {
                String firstName = '';
                String secondName = '';
                String thirdName = '';
                final longItemNameSplit =
                    localParcelReadyItemNames[0].split(' ');
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
                    secondName += '${longItemNameSplit[i]} ';
                  }
                  if (i > 3) {
                    thirdName += '${longItemNameSplit[i]} ';
                  }
                }
                bluetooth.printCustom(
                  "$firstName x ${localParcelReadyNumberOfItems[0].toString()}",
                  printerenum.Size.medium.val,
                  printerenum.Align.left.val,
                );

                bluetooth.printCustom(
                  "$secondName",
                  printerenum.Size.medium.val,
                  printerenum.Align.left.val,
                );
                bluetooth.printCustom(
                  "$thirdName",
                  printerenum.Size.medium.val,
                  printerenum.Align.left.val,
                );
              } else {
                bluetooth.printCustom(
                  "${localParcelReadyItemNames[0]} x ${localParcelReadyNumberOfItems[0].toString()}",
                  printerenum.Size.medium.val,
                  printerenum.Align.left.val,
                );
              }
              if (localParcelReadyItemComments[0] != 'nocomments') {
                bluetooth.printCustom(
                    "     (Comment : ${localParcelReadyItemComments[0]})",
                    printerenum.Size.medium.val,
                    printerenum.Align.left.val);
              }
            }

            bluetooth.printNewLine();
            if (Provider.of<PrinterAndOtherDetailsProvider>(context,
                            listen: false)
                        .chefPrinterSizeFromClass ==
                    '80' &&
                localParcelReadyItemNames[0] != 'Printer Check') {
              bluetooth.printCustom(
                "Note:Consume Within Two Hours",
                printerenum.Size.bold.val,
                printerenum.Align.center.val,
              );
              bluetooth.printNewLine();
            } else if (Provider.of<PrinterAndOtherDetailsProvider>(context,
                            listen: false)
                        .chefPrinterSizeFromClass ==
                    '58' &&
                localParcelReadyItemNames[0] != 'Printer Check') {
              bluetooth.printCustom(
                "Note:Consume Within Two Hours",
                printerenum.Size.bold.val,
                printerenum.Align.left.val,
              );
              bluetooth.printNewLine();
              bluetooth.printNewLine();
            }
            _fastDisconnectForAfterOrderPrint();
          }

          bluetooth
              .paperCut(); //some printer not supported (sometime making image not centered)
          //bluetooth.drawerPin2(); // or you can use bluetooth.drawerPin5();
        } else {
          printingOver = true;
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

  void _disconnectForAfterOrderPrint() {
    Timer? _timer;
    int _everySecondForDisconnecting = 0;
    _everySecondForConnection = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_everySecondForDisconnecting < 2) {
        print('timer disconnect is $_everySecondForDisconnecting');
        _everySecondForDisconnecting++;
      } else {
        bluetooth.disconnect();
        localParcelNumber = '';
        localParcelReadyItemNames = [];
        localParcelReadyNumberOfItems = [];
        localParcelReadyItemComments = [];

        _timer!.cancel();
        _everySecondForDisconnecting = 0;
        print('bluetooth is disconnecting');
        print('came to showspinner false');
        setState(() {
          showSpinner = false;
          _connected = false;
        });
        printingOver = true;
      }
    });
  }

  void _fastDisconnectForAfterOrderPrint() {
    print('fast disconnect');
    bluetooth.disconnect();
    localParcelNumber = '';
    localParcelReadyItemNames = [];
    localParcelReadyItemComments = [];
    localParcelReadyNumberOfItems = [];
    _everySecondForConnection = 0;
    setState(() {
      showSpinner = false;
      _connected = false;
    });
    printingOver = true;
  }

  Future<void> printerConnectionToLastSavedPrinterForKOT() async {
    // if (Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
    //         .chefPrinterAddressFromClass !=
    //     '') {
    print('kot printer');
    // printingOver = false;
    print('123');
//
//     if (bluetoothOnTrueOrOffFalse == false) {
//       setState(() {
//         showSpinner = false;
//       });
//       show('Please Turn on bluetooth1');
//       printingOver = true;
//       playPrinterError();
//       print('cameInsideTheLoopprinterConnectionToLastSavedPrinter');
// //ThisIfLoopWillEnsureWeDontCheckBluetoothOnOrOffAgainAndAgain
// //       bluetoothStateChangeFunction();
//     }
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
    print('kot bluetooth is $bluetoothOnTrueOrOffFalse');
    if (bluetoothOnTrueOrOffFalse == true) {
      // playPrinterKOT();
      getAllPairedDevices();
      printingOver = false;
      // if (showSpinner == false) {
      //   setState(() {
      //     showSpinner = true;
      //   });
      // }

      bool? isConnected = await bluetooth.isConnected;
      print(
          'kot printerConnectionToLastSavedPrinter start is connected value is $isConnected');
      bool printerPairedTrueYetToPairFalse = false;
      int devicesCount = 0;
      for (var device in _devices) {
        ++devicesCount;
        print('checking device addresses');
        if (device.address ==
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .chefPrinterAddressFromClass) {
          printerPairedTrueYetToPairFalse = true;
          print('checking for printer saved');
          var nowConnectingPrinter = device;
          _connectForKOTPrint(nowConnectingPrinter);
        }
        if (devicesCount == _devices.length &&
            printerPairedTrueYetToPairFalse == false) {
          // _everySecondForKotTimer = -3;
          setState(() {
            showSpinner = false;
          });
          print('here3');
          if (appInBackground == false) {
            show('Couldn\'t Connect. Please check Printer');
          }

          printingOver = true;
          playPrinterError();
          timerForPrintingKOTTenSeconds();
        }
      }
    }
    // }
    // else {
    //   if (printerNotAddedForKotMessageNotShown == true) {
    //     show('Add Printer For KOT');
    //     playPrinterError();
    //     timerForPrintingKOTTenSeconds();
    //     printerNotAddedForKotMessageNotShown = false;
    //   }
    // }

    // else if (bluetoothOnTrueOrOffFalse == false &&
    //     bluetoothTurnOnMessageShown == false) {
    //   setState(() {
    //     showSpinner = false;
    //   });
    //   printingOver = true;
    //
    //   playPrinterError();
    //   print('cameInsideTheLoopprinterConnectionToLastSavedPrinter');
    //   show('Please Turn On Bluetooth');
    // }

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

//   Future<void> printerConnectionToLastSavedPrinterForBackgroundKOT() async {
//     print('kot printer');
//     printingOver = false;
//     print('123');
// //
// //     if (bluetoothOnTrueOrOffFalse == false) {
// //       setState(() {
// //         showSpinner = false;
// //       });
// //       show('Please Turn on bluetooth1');
// //       printingOver = true;
// //       playPrinterError();
// //       print('cameInsideTheLoopprinterConnectionToLastSavedPrinter');
// // //ThisIfLoopWillEnsureWeDontCheckBluetoothOnOrOffAgainAndAgain
// // //       bluetoothStateChangeFunction();
// //     }
//     print('printerConnectionToLastSavedPrinter');
//     // TODO here add a permission request using permission_handler
//     // if (locationPermissionAccepted == false) {
//     //   showDialog(
//     //     context: context,
//     //     builder: (BuildContext context) => AlertDialog(
//     //       elevation: 24.0,
//     //       // backgroundColor: Colors.greenAccent,
//     //       // shape: CircleBorder(),
//     //       title: Text('Permission for Location Use'),
//     //       content: Text(
//     //           'Orders App collects location data only to enable bluetooth printer. This information will not be used when the app is closed or not in use. Kindly allow location access when prompted'),
//     //       actions: [
//     //         TextButton(
//     //             onPressed: () {
//     //               Permission.locationWhenInUse.request();
//     //               // Navigator.of(context, rootNavigator: true)
//     //               //     .pop();
//     //               Navigator.pop(context);
//     //               print('came till this pop1');
//     //               // Navigator.pop(context);
//     //               // print('came till this pop2');
//     //               Timer? _timer;
//     //               int _everySecondInRequestPermissionLoop = 0;
//     //               _timer = Timer.periodic(Duration(seconds: 1),
//     //                       (_) async {
//     //                     if (_everySecondInRequestPermissionLoop < 2) {
//     //                       print(
//     //                           'duration is $_everySecondInRequestPermissionLoop');
//     //                       _everySecondInRequestPermissionLoop++;
//     //                     } else {
//     //                       _timer?.cancel();
//     //                       print('came inside timer cancel loop1111');
//     //                       setState(() {
//     //                         locationPermissionAccepted = true;
//     //                         // Permission.location.request();
//     //                       });
//     //                       // savedBluetoothPrinterConnect();
//     //                       if (connectingPrinterAddressChefScreen !=
//     //                           '') {
//     //                         printerConnectionToLastSavedPrinter();
//     //                       } else {
//     //                         setState(() {
//     //                           noNeedPrinterConnectionScreen = false;
//     //                         });
//     //                       }
//     //                     }
//     //                   });
//     //             },
//     //             child: Text('Ok'))
//     //       ],
//     //     ),
//     //     barrierDismissible: false,
//     //   );
//     // }
//
//     // if permission is not granted, kzaki's thermal print plugin will ask for location permission
//     // which will invariably crash the app even if user agrees so we'd better ask it upfront
//
//     // var statusLocation = Permission.location;
//     // if (await statusLocation.isGranted != true) {
//     //   await Permission.location.request();
//     // }
//     // if (await statusLocation.isGranted) {
//     // ...
//     // } else {
//     // showDialogSayingThatThisPermissionIsRequired());
//     // }
//     print('kot bluetooth is $bluetoothOnTrueOrOffFalse');
//     if (bluetoothOnTrueOrOffFalse == true) {
//       playPrinterKOT();
//       getAllPairedDevices();
//       printingOver = false;
//       // if (showSpinner == false) {
//       //   setState(() {
//       //     showSpinner = true;
//       //   });
//       // }
//
//       bool? isConnected = await bluetooth.isConnected;
//       print(
//           'kot printerConnectionToLastSavedPrinter start is connected value is $isConnected');
//       bool printerPairedTrueYetToPairFalse = false;
//       int devicesCount = 0;
//       for (var device in _devices) {
//         ++devicesCount;
//         print('checking device addresses');
//         if (device.address ==
//             Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
//                 .chefPrinterAddressFromClass) {
//           printerPairedTrueYetToPairFalse = true;
//           print('checking for printer saved');
//           var nowConnectingPrinter = device;
//           _connectForKOTPrint(nowConnectingPrinter);
//         }
//         if (devicesCount == _devices.length &&
//             printerPairedTrueYetToPairFalse == false) {
//           // _everySecondForKotTimer = -3;
//           setState(() {
//             showSpinner = false;
//           });
//           print('here2');
//           show('Couldnt Connect. Please check Printer2');
//           printingOver = true;
//           playPrinterError();
//         }
//       }
//     } else {
//       print('camne insidjsbfshfbsbf');
//       // _everySecondForKotTimer = -3;
//       setState(() {
//         showSpinner = false;
//       });
//       printingOver = true;
//
//       playPrinterError();
//       print('cameInsideTheLoopprinterConnectionToLastSavedPrinter');
//       show('Please Turn On Bluetooth');
//     }
//
//     if (!mounted) return;
//     // setState(() {
//     //   _devices = devices;
//     // });
//
//     // if (isConnected == true) {
//     //   printThroughBluetooth();
//     //   setState(() {
//     //     _connected = true;
//     //   });
//     // }
//   }

  void _connectForKOTPrint(BluetoothDevice nowConnectingPrinter) {
    bool timerForStartOfPrinting;
    print('start of _Connect loop');
    if (nowConnectingPrinter != null) {
      print('device isnt null');

      bluetooth.isConnected.then((isConnected) {
        print('came inside bluetooth trying to connect for KOT');
        if (isConnected == false) {
          bluetooth.connect(nowConnectingPrinter!).catchError((error) {
            print('did not get connected1 inside KOT _connect- ${_connected}');
            if (appInBackground == false) {
              show('Couldn\'t Connect. Please check Printer');
            }

            if (timerForPrintingKOTRunning == false &&
                timerForPrintingTenSecKOTRunning == false &&
                intermediatePrintingCallKOTRunning == false &&
                intermediatePrintingAfterOrderReadyRunning == false) {
              timerForPrintingKOTTenSeconds();
            }

            playPrinterError();
            printingOver = true;
            // _everySecondForKotTimer = -3;
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
          bluetooth.disconnect();
          setState(() => _connected = false);
          _everySecondForConnection = 0;
          playPrinterError();
          if (timerForPrintingKOTRunning == false &&
              timerForPrintingTenSecKOTRunning == false &&
              intermediatePrintingCallKOTRunning == false &&
              intermediatePrintingAfterOrderReadyRunning == false) {
            timerForPrintingKOTTenSeconds();
          }

          print('here1');
          if (appInBackground == false) {
            show('Couldn\'t Connect. Please Try Again');
          }

          playPrinterError();
          int _everySecondHelpingToDisconnectBeforeConnectingAgain = 0;
          // if (disconnectAndConnectAttempted) {
          //   printingOver = true;
          //   setState(() {
          //     showSpinner = false;
          //   });
          // } else {
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
    intermediatePrintingCallKOTRunning = false;

    print('start of intermediateFunctionToCallPrintThroughBluetooth');
    Timer? _timer;
    _everySecondForConnection = 0;

    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_everySecondForConnection <= 2) {
        intermediatePrintingCallKOTRunning = true;
        print('timer inside KOTconnect is $_everySecondForConnection');
        _everySecondForConnection++;
      } else {
        intermediatePrintingCallKOTRunning = false;
        if (_connected) {
          print('Inside intermediate- it is connected');
          // playPrinterKOT();
          printKOTThroughBluetooth();
        } else {
          printingOver = true;
          // _everySecondForKotTimer = -3;
          setState(() {
            showSpinner = false;
          });
          print('unable to connect');
          // bluetooth.disconnect();
          if (appInBackground == false) {
            show('Couldn\'t Connect. Please check Printer');
          }
        }
        _timer!.cancel();
      }
    });
    print('end of intermediateFunctionToCallPrintThroughBluetooth');
  }

  void printKOTThroughBluetooth() {
    String tempTableOrParcel = '';
    String tempTableOrParcelNumber = '';
    String tempParentOrChild = '';
    String tempTicketNumber = '';
    String tempCancelledItemTrueElseFalse = '';
    print('start of inside printThroughBluetooth');
    if (_connected) {
      bluetooth.isConnected.then((isConnected) {
        print('came inside bluetooth isConnected');
        if (isConnected == true) {
          print('inside printThroughBluetooth-is connected is true here');
          // bluetooth.printNewLine();
          for (int i = 0; i < localKOTItemNames.length; i++) {
            if (localKotCancelledItemTrueElseFalse[i] != 'false') {
//CancelledItemsKOTPrinting
              if (Provider.of<PrinterAndOtherDetailsProvider>(context,
                          listen: false)
                      .chefPrinterSizeFromClass ==
                  '80') {
                if (tempTableOrParcel != localKotItemsTableOrParcel[i] ||
                    tempTableOrParcelNumber !=
                        localKotItemsTableOrParcelNumber[i] ||
                    tempParentOrChild != localKotItemsParentOrChild[i] ||
                    tempTicketNumber != localKotItemsTicketNumber[i] ||
                    tempCancelledItemTrueElseFalse !=
                        localKotCancelledItemTrueElseFalse[i]) {
                  bluetooth.paperCut();
                  bluetooth.printNewLine();
                  bluetooth.printNewLine();
                  if (localKotItemsParentOrChild[i] == 'parent') {
                    bluetooth.printCustom(
                      "xxxxx CANCELLED xxxxx",
                      printerenum.Size.extraLarge.val,
                      printerenum.Align.center.val,
                    );
                    bluetooth.printCustom(
                      "Slot : ${localKotItemsTableOrParcel[i]}:${localKotItemsTableOrParcelNumber[i]}",
                      printerenum.Size.boldMedium.val,
                      printerenum.Align.center.val,
                    );
                  } else {
                    bluetooth.printCustom(
                      "xxxxx CANCELLED xxxxx",
                      printerenum.Size.extraLarge.val,
                      printerenum.Align.center.val,
                    );
                    bluetooth.printCustom(
                      "Slot : ${localKotItemsTableOrParcel[i]}:${localKotItemsTableOrParcelNumber[i]}${localKotItemsParentOrChild[i]}",
                      printerenum.Size.boldMedium.val,
                      printerenum.Align.center.val,
                    );
                  }

                  bluetooth.printCustom(
                    "Ticket Number : ${localKotItemsTicketNumber[i]}",
                    printerenum.Size.bold.val,
                    printerenum.Align.center.val,
                  );
                  bluetooth.printNewLine();
                  tempTableOrParcel = localKotItemsTableOrParcel[i];
                  tempTableOrParcelNumber = localKotItemsTableOrParcelNumber[i];
                  tempTicketNumber = localKotItemsTicketNumber[i];
                  tempParentOrChild = localKotItemsParentOrChild[i];
                  tempCancelledItemTrueElseFalse =
                      localKotCancelledItemTrueElseFalse[i];
                }
                if ((' '.allMatches(localKOTItemNames[i]).length >= 3)) {
                  String firstName = '';
                  String secondName = '';
                  String thirdName = '';
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
                    if (i == 3) {
                      secondName += '${longItemNameSplit[i]} ';
                    }
                    if (i > 3) {
                      thirdName += '${longItemNameSplit[i]} ';
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
                  bluetooth.printLeftRight(
                      "$thirdName", "", printerenum.Size.bold.val,
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
                  // if (localKotCancelledItemTrueElseFalse[i + 1] == 'false') {
                  //   print('came inside false for last line cancel');
                  //   bluetooth.printCustom(
                  //     "xxxxx CANCELLED xxxxx",
                  //     printerenum.Size.extraLarge.val,
                  //     printerenum.Align.center.val,
                  //   );
                  //   bluetooth.printNewLine();
                  //   bluetooth.printNewLine();
                  //   bluetooth.paperCut();
                  // }
                }
              } else if (Provider.of<PrinterAndOtherDetailsProvider>(context,
                          listen: false)
                      .chefPrinterSizeFromClass ==
                  '58') {
                if (tempTableOrParcel != localKotItemsTableOrParcel[i] ||
                    tempTableOrParcelNumber !=
                        localKotItemsTableOrParcelNumber[i] ||
                    tempParentOrChild != localKotItemsParentOrChild[i] ||
                    tempTicketNumber != localKotItemsTicketNumber[i] ||
                    tempCancelledItemTrueElseFalse !=
                        localKotCancelledItemTrueElseFalse[i]) {
                  bluetooth.printNewLine();
                  bluetooth.printNewLine();
                  if (localKotItemsParentOrChild[i] == 'parent') {
                    bluetooth.printCustom(
                      "xx CANCELLED xx",
                      printerenum.Size.extraLarge.val,
                      printerenum.Align.center.val,
                    );
                    bluetooth.printCustom(
                      "Slot : ${localKotItemsTableOrParcel[i]}:${localKotItemsTableOrParcelNumber[i]}",
                      printerenum.Size.boldMedium.val,
                      printerenum.Align.center.val,
                    );
                  } else {
                    bluetooth.printCustom(
                      "xx CANCELLED xx",
                      printerenum.Size.extraLarge.val,
                      printerenum.Align.center.val,
                    );
                    bluetooth.printCustom(
                      "Slot : ${localKotItemsTableOrParcel[i]}:${localKotItemsTableOrParcelNumber[i]}${localKotItemsParentOrChild[i]}",
                      printerenum.Size.boldMedium.val,
                      printerenum.Align.center.val,
                    );
                  }

                  bluetooth.printCustom(
                    "Ticket Number : ${localKotItemsTicketNumber[i]}",
                    printerenum.Size.bold.val,
                    printerenum.Align.center.val,
                  );
                  bluetooth.printNewLine();
                  bluetooth.printNewLine();
                  tempTableOrParcel = localKotItemsTableOrParcel[i];
                  tempTableOrParcelNumber = localKotItemsTableOrParcelNumber[i];
                  tempTicketNumber = localKotItemsTicketNumber[i];
                  tempParentOrChild = localKotItemsParentOrChild[i];

                  tempCancelledItemTrueElseFalse =
                      localKotCancelledItemTrueElseFalse[i];
                }
                if ((' '.allMatches(localKOTItemNames[i]).length >= 3)) {
                  String firstName = '';
                  String secondName = '';
                  String thirdName = '';
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
                    if (i == 3) {
                      secondName += '${longItemNameSplit[i]} ';
                    }
                    if (i > 3) {
                      thirdName += '${longItemNameSplit[i]} ';
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
                  bluetooth.printCustom(
                    "$thirdName",
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
              }

//ToAccessDisconnectWhenWeArePrintingParcel
              if (i == (localKOTItemNames.length - 1)) {
                playPrinterKOT();
                _disconnectForKOTPrint();
              }
            } else {
////NewlyOrderedItemsKOTPrinting
              if (Provider.of<PrinterAndOtherDetailsProvider>(context,
                          listen: false)
                      .chefPrinterSizeFromClass ==
                  '80') {
                if (tempTableOrParcel != localKotItemsTableOrParcel[i] ||
                    tempTableOrParcelNumber !=
                        localKotItemsTableOrParcelNumber[i] ||
                    tempParentOrChild != localKotItemsParentOrChild[i] ||
                    tempTicketNumber != localKotItemsTicketNumber[i] ||
                    tempCancelledItemTrueElseFalse !=
                        localKotCancelledItemTrueElseFalse[i]) {
                  bluetooth.paperCut();
                  bluetooth.printNewLine();
                  bluetooth.printNewLine();
                  if (localKotItemsParentOrChild[i] == 'parent') {
                    bluetooth.printCustom(
                      "Slot : ${localKotItemsTableOrParcel[i]}:${localKotItemsTableOrParcelNumber[i]}",
                      printerenum.Size.boldMedium.val,
                      printerenum.Align.center.val,
                    );
                  } else {
                    bluetooth.printCustom(
                      "Slot : ${localKotItemsTableOrParcel[i]}:${localKotItemsTableOrParcelNumber[i]}${localKotItemsParentOrChild[i]}",
                      printerenum.Size.boldMedium.val,
                      printerenum.Align.center.val,
                    );
                  }

                  bluetooth.printCustom(
                    "Ticket Number : ${localKotItemsTicketNumber[i]}",
                    printerenum.Size.bold.val,
                    printerenum.Align.center.val,
                  );
                  bluetooth.printNewLine();
                  tempTableOrParcel = localKotItemsTableOrParcel[i];
                  tempTableOrParcelNumber = localKotItemsTableOrParcelNumber[i];
                  tempTicketNumber = localKotItemsTicketNumber[i];
                  tempParentOrChild = localKotItemsParentOrChild[i];
                  tempCancelledItemTrueElseFalse =
                      localKotCancelledItemTrueElseFalse[i];
                }
                if ((' '.allMatches(localKOTItemNames[i]).length >= 3)) {
                  String firstName = '';
                  String secondName = '';
                  String thirdName = '';
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
                    if (i == 3) {
                      secondName += '${longItemNameSplit[i]} ';
                    }
                    if (i > 3) {
                      thirdName += '${longItemNameSplit[i]} ';
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
                  bluetooth.printLeftRight(
                      "$thirdName", "", printerenum.Size.bold.val,
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
              } else if (Provider.of<PrinterAndOtherDetailsProvider>(context,
                          listen: false)
                      .chefPrinterSizeFromClass ==
                  '58') {
                if (tempTableOrParcel != localKotItemsTableOrParcel[i] ||
                    tempTableOrParcelNumber !=
                        localKotItemsTableOrParcelNumber[i] ||
                    tempParentOrChild != localKotItemsParentOrChild[i] ||
                    tempTicketNumber != localKotItemsTicketNumber[i] ||
                    tempCancelledItemTrueElseFalse !=
                        localKotCancelledItemTrueElseFalse[i]) {
                  bluetooth.printNewLine();
                  bluetooth.printNewLine();
                  if (localKotItemsParentOrChild[i] == 'parent') {
                    bluetooth.printCustom(
                      "Slot : ${localKotItemsTableOrParcel[i]}:${localKotItemsTableOrParcelNumber[i]}",
                      printerenum.Size.boldMedium.val,
                      printerenum.Align.center.val,
                    );
                  } else {
                    bluetooth.printCustom(
                      "Slot : ${localKotItemsTableOrParcel[i]}:${localKotItemsTableOrParcelNumber[i]}${localKotItemsParentOrChild[i]}",
                      printerenum.Size.boldMedium.val,
                      printerenum.Align.center.val,
                    );
                  }

                  bluetooth.printCustom(
                    "Ticket Number : ${localKotItemsTicketNumber[i]}",
                    printerenum.Size.bold.val,
                    printerenum.Align.center.val,
                  );
                  bluetooth.printNewLine();
                  bluetooth.printNewLine();
                  tempTableOrParcel = localKotItemsTableOrParcel[i];
                  tempTableOrParcelNumber = localKotItemsTableOrParcelNumber[i];
                  tempTicketNumber = localKotItemsTicketNumber[i];
                  tempParentOrChild = localKotItemsParentOrChild[i];
                  tempCancelledItemTrueElseFalse =
                      localKotCancelledItemTrueElseFalse[i];
                }
                if ((' '.allMatches(localKOTItemNames[i]).length >= 3)) {
                  String firstName = '';
                  String secondName = '';
                  String thirdName = '';
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
                    if (i == 3) {
                      secondName += '${longItemNameSplit[i]} ';
                    }
                    if (i > 3) {
                      thirdName += '${longItemNameSplit[i]} ';
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
                  bluetooth.printCustom(
                    "$thirdName",
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
              }

//ToAccessDisconnectWhenWeArePrintingParcel
              if (i == (localKOTItemNames.length - 1)) {
                playPrinterKOT();
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
          // _everySecondForKotTimer = -3;
          setState(() {
            printingOver = true;
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
    Timer? _timer;
    int _everySecondForDisconnecting = 0;
    _everySecondForConnection = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_everySecondForDisconnecting < 2) {
        print('timer disconnect is $_everySecondForDisconnecting');
        _everySecondForDisconnecting++;
      } else {
        localKOTItemNames = [];
        localKotItemsParentOrChild = [];
        bluetooth.disconnect();

        kotCounter = 0;
        localKOTNumberOfItems = [];
        localKOTItemComments = [];
//ItMeansThereIsOnlyOneItemForKOT
        if (localKotItemsEachItemFromEntireItemsString.length <= 1) {
          if (localKotCancelledItemTrueElseFalse[0] != 'false') {
            print('got inside this loop 466546');
//CancelledItemAndThereIsOnlyOneCancelledItem
            FireStoreDeleteFinishedOrderInPresentOrders(
                    hotelName: widget.hotelName,
                    eachItemId: localKotItemsBelongsToDoc[0])
                .deleteFinishedOrder();
          } else {
//NewlyOrderedItem
            final eachItemFromEntireItemsStringSplit =
                localKotItemsEachItemFromEntireItemsString[0].split('*');
            eachItemFromEntireItemsStringSplit[5] = '7';
            eachItemFromEntireItemsStringSplit[7] = 'chefkotprinted';
            String tempKOTUpdaterString = '';
            for (int i = 0;
                i < eachItemFromEntireItemsStringSplit.length - 1;
                i++) {
              tempKOTUpdaterString +=
                  '${eachItemFromEntireItemsStringSplit[i]}*';
            }
            String stringUsedForUpdatingKOT =
                localKotItemsEntireItemListBeforeSplitting[0].replaceAll(
                    localKotItemsEachItemFromEntireItemsString[0],
                    tempKOTUpdaterString);
            final statusUpdatedStringCheck =
                stringUsedForUpdatingKOT.split('*');
            // //keepingDefaultAs7-AcceptedStatusWhichNeedNotCreateAnyIssue
            String partOfTableOrParcel = statusUpdatedStringCheck[0];
            String partOfTableOrParcelNumber = statusUpdatedStringCheck[1];
            num chefStatus = 7;
            num captainStatus = 7;

            for (int j = 1;
                j < ((statusUpdatedStringCheck.length - 1) / 15);
                j++) {
//ThisForLoopWillGoThroughEveryOrder,GoExactlyThroughThePointsWhereStatusIsThere
              if (((statusUpdatedStringCheck[(j * 15) + 5]) == '11')) {
                captainStatus = 11;
              } else if (((statusUpdatedStringCheck[(j * 15) + 5]) == '10') &&
                  captainStatus != 11) {
                captainStatus = 10;
              }
              if (((statusUpdatedStringCheck[(j * 15) + 5]) == '9')) {
                chefStatus = 9;
              }
            }
            FireStoreAddOrderServiceWithSplit(
                    hotelName: widget.hotelName,
                    itemsUpdaterString: stringUsedForUpdatingKOT,
                    seatingNumber: localKotItemsBelongsToDoc[0],
                    captainStatus: captainStatus,
                    chefStatus: chefStatus,
                    partOfTableOrParcel: partOfTableOrParcel,
                    partOfTableOrParcelNumber: partOfTableOrParcelNumber)
                .addOrder();
          }
        } else {
          Map<String, String> kotStatusUpdaterMap = HashMap();
          List<String> deletingListCancelledItemsAfterKot = [];
          List<String> deletingListCancelledItemsDocAfterKot = [];
          for (int k = 0;
              k < localKotItemsEachItemFromEntireItemsString.length;
              k++) {
            if (localKotCancelledItemTrueElseFalse[k] == 'false') {
//ForNewlyOrderedItems
              final eachItemFromEntireItemsStringSplit =
                  localKotItemsEachItemFromEntireItemsString[k].split('*');
              eachItemFromEntireItemsStringSplit[5] = '7';
              eachItemFromEntireItemsStringSplit[7] = 'chefkotprinted';
              String tempKOTUpdaterString = '';
              for (int i = 0;
                  i < eachItemFromEntireItemsStringSplit.length - 1;
                  i++) {
                tempKOTUpdaterString +=
                    '${eachItemFromEntireItemsStringSplit[i]}*';
              }
              String entireStringBeforeSplittingForUpdating = '';
              if (kotStatusUpdaterMap
                  .containsKey(localKotItemsBelongsToDoc[k])) {
                entireStringBeforeSplittingForUpdating =
                    kotStatusUpdaterMap[localKotItemsBelongsToDoc[k]]!;
              } else {
                entireStringBeforeSplittingForUpdating =
                    localKotItemsEntireItemListBeforeSplitting[k];
              }
              String stringUsedForUpdatingKOT =
                  entireStringBeforeSplittingForUpdating.replaceAll(
                      localKotItemsEachItemFromEntireItemsString[k],
                      tempKOTUpdaterString);
              kotStatusUpdaterMap[localKotItemsBelongsToDoc[k]] =
                  stringUsedForUpdatingKOT;
              // kotStatusUpdaterMap.update(localKotItemsBelongsToDoc[k],
              //     (value) => stringUsedForUpdatingKOT);

            } else {
//ForCancelledItems
              deletingListCancelledItemsAfterKot.add(localKOTItemsID[k]);
              deletingListCancelledItemsDocAfterKot
                  .add(localKotItemsBelongsToDoc[k]);
            }

            if ((k + 1) == localKotItemsEachItemFromEntireItemsString.length) {
              if (deletingListCancelledItemsAfterKot.isNotEmpty) {
                if (deletingListCancelledItemsAfterKot.length == 1) {
                  FireStoreDeleteFinishedOrderInPresentOrders(
                          hotelName: widget.hotelName,
                          eachItemId: deletingListCancelledItemsDocAfterKot[0])
                      .deleteFinishedOrder();
                } else {
                  for (int i = 0;
                      i < deletingListCancelledItemsAfterKot.length;
                      i++) {
                    if (i + 1 != deletingListCancelledItemsAfterKot.length) {
//WeHaven'tReachedTheLastItemInTheList
                      FireStoreClearCancelledItemFromPresentOrders(
                        hotelName: widget.hotelName,
                        cancelledItemId: deletingListCancelledItemsAfterKot[i],
                        cancelledItemsDoc:
                            deletingListCancelledItemsDocAfterKot[i],
                      ).deleteCancelledItem();
                    } else {
//ClearingTheDocBecauseCancelledItemsAreAllCleared
                      FireStoreDeleteFinishedOrderInPresentOrders(
                              hotelName: widget.hotelName,
                              eachItemId:
                                  deletingListCancelledItemsDocAfterKot[i])
                          .deleteFinishedOrder();
                    }

                    cancelledItemsKey
                        .remove(deletingListCancelledItemsAfterKot[i]);
                  }
                }
              }

              if (kotStatusUpdaterMap.isNotEmpty) {
//ThisWillEnsureAllTheNewlyOrderedItemsStatusIsUpdatedInServer
                kotStatusUpdaterMap.forEach((key, value) {
                  final statusUpdatedStringCheck = value.split('*');

                  String partOfTableOrParcel = statusUpdatedStringCheck[0];
                  String partOfTableOrParcelNumber =
                      statusUpdatedStringCheck[1];

//keepingDefaultAs7-AcceptedStatusWhichNeedNotCreateAnyIssue
                  num chefStatus = 7;
                  num captainStatus = 7;

                  for (int j = 1;
                      j < ((statusUpdatedStringCheck.length - 1) / 15);
                      j++) {
//ThisForLoopWillGoThroughEveryOrder,GoExactlyThroughThePointsWhereStatusIsThere
                    if (((statusUpdatedStringCheck[(j * 15) + 5]) == '11')) {
                      captainStatus = 11;
                    } else if (((statusUpdatedStringCheck[(j * 15) + 5]) ==
                            '10') &&
                        captainStatus != 11) {
                      captainStatus = 10;
                    }
                    if (((statusUpdatedStringCheck[(j * 15) + 5]) == '9')) {
                      chefStatus = 9;
                    }
                  }

                  FireStoreAddOrderServiceWithSplit(
                          hotelName: widget.hotelName,
                          itemsUpdaterString: value,
                          seatingNumber: key,
                          captainStatus: captainStatus,
                          chefStatus: chefStatus,
                          partOfTableOrParcel: partOfTableOrParcel,
                          partOfTableOrParcelNumber: partOfTableOrParcelNumber)
                      .addOrder();
                });
              }
            }
          }
        }

        _timer!.cancel();
        _everySecondForDisconnecting = 0;
        // _everySecondForKotTimer = -3;
        print('bluetooth is disconnecting');
        print('came to showspinner false');
        setState(() {
          showSpinner = false;
          _connected = false;
        });
        printingOver = true;
      }
    });
  }

  void _fastDisconnectForKOTPrint() {
    print('fast disconnect');
    bluetooth.disconnect();
    localKOTItemNames = [];
    kotCounter = 0;
    localKOTItemComments = [];
    localKOTNumberOfItems = [];
    localKotItemsParentOrChild = [];
    _everySecondForConnection = 0;
    setState(() {
      showSpinner = false;
      _connected = false;
    });
    printingOver = true;
  }

  @override
  void initState() {
    //WeAreMakingThisVariableSimplyToGetTheProviderValueOnce.FirstTimeItWillBeInitialValue
//IfWeDontHaveThisFirstTimeTaking,TheVideoWillPlayAgainAndAgain
//EverytimeSomeoneGets
    bool tempProviderInitialize =
        Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .chefInstructionsVideoPlayedFromClass;
    // TODO: implement initState
    //BasicallyWithWidgetsBinding,WeCreateAnInstanceToKeepCheckingThe,,
    //ScreenLockedOrUnlockedState
    WidgetsBinding.instance.addObserver(this);

    //WeInitializeTimerToZero
    _everyThirtySeconds = 0;
    //AndItemsArrivedInLastCheckListWillBeMadeEmptyInInitState
    itemsArrivedInLastCheck = [];

//VideoPlayer
    _videoController =
        VideoPlayerController.asset('assets/videos/chef_accept_reject.mp4');
    // _videoController.initialize().then((value) => _videoController.play());
    // _videoController.initialize();
    buildChefInstructionAlertDialogWidgetWithTimer();

//ThisIsTheStreamWhichWillKeepCheckingOnTheStatusOfInternet
    //ItWillKeepLookingForStatusChangeAndWillUpdateThe hasInternet Variable
    internetAvailabilityChecker();
    // final androidConfig = FlutterBackgroundAndroidConfig(
    //   notificationTitle: "Orders",
    //   notificationText: "We are looking for updates",
    //   notificationImportance: AndroidNotificationImportance.Default,
    //   notificationIcon: AndroidResource(
    //       name: 'background_icon',
    //       defType: 'drawable'), // Default is ic_launcher from folder mipmap
    // );
    // FlutterBackground.initialize();

    // getAllPairedDevices();
    requestLocationPermission();
    bluetoothConnected = false;
    bluetoothAlreadyConnected = false;
    showSpinner = false;
    printingOver = true;
    disconnectAndConnectAttempted = false;
    bluetoothTurnOnMessageShown = false;
    timeForKot = 1;
    kotCounter = 0;
    localKOTItemNames = [];
    tempLocalKOTItemNames = [];
    tempLocalKOTItemsID = [];
    _everySecondForKot = 0;
    _everySecondForKotTimer = 0;
    timerForPrintingKOTRunning = false;
    timerForPrintingTenSecKOTRunning = false;
    intermediatePrintingCallKOTRunning = false;
    intermediatePrintingAfterOrderReadyRunning = false;
    appInBackground = false;
    timerRunningForCheckingNewOrdersInBackground = false;
    backgroundTimerCounter = 0;
    // thisIsChefCallingForBackground = true;
    // hotelNameForBackground = widget.hotelName;
    // chefSpecialitiesForBackground = widget.chefSpecialities;
    FlutterBackground.initialize();
    Wakelock.enable();

    super.initState();
  }

  void internetAvailabilityChecker() {
    Timer? _timerToCheckInternet;
    int _everySecondForInternetChecking = 0;
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
  void dispose() {
    // TODO: implement dispose

    //WeHaveDisposeLoopWhichWillCloseEverythingWhenThePageIsDisposed
    //WeDisposeInternetChecker,AudioPlayer

    WidgetsBinding.instance.removeObserver(this);
    internetCheckerSubscription.cancel();
    player.stop();
    player.release();
    player.dispose();
    super.dispose();
  }

  void requestLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;
    var status1 = await Permission.locationAlways.status;
    var status2 = await Permission.location.status;
    if (status.isDenied && status1.isDenied && status2.isDenied) {
      setState(() {
        locationPermissionAccepted = false;
      });
      // if (Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
      //         .chefPrinterKOTFromClass ||
      //     Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
      //         .chefPrinterAfterOrderReadyPrintFromClass) {
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
                  getAllPairedDevices();
                  bluetoothStateChangeFunction();

                  // FlutterBackground.initialize();
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
      // }

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
      bluetoothStateChangeFunction();
      // getAllPairedDevices();
      print('location permission already accepted');
      setState(() {
        locationPermissionAccepted = true;
      });
      // FlutterBackground.initialize();

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

  //ThisIsTheMethodThatLooksToLifeCycleStateOfTheApp
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    // TODO: implement didChangeAppLifecycleState

//ItWillCheckWhetherTheAppIsInForegroundOrBackground

    // if (state == AppLifecycleState.inactive ||
    //     state == AppLifecycleState.detached) return;

    final isBackground = state == AppLifecycleState.paused;
    final isBackground2 = state == AppLifecycleState.inactive;
    final isBackground3 = state == AppLifecycleState.detached;
    final isForeground = state == AppLifecycleState.resumed;

//IfItIsInBackground
    if (isBackground || isBackground2 || isBackground3) {
      FlutterBackground.enableBackgroundExecution();
      timerRunningForCheckingNewOrdersInBackground = false;

      backgroundTimerCounter = 0;
      if (appInBackground == false) {
        currentNewOrdersCheckInBackground();
        setState(() {
          appInBackground = true;
        });
      }

      // timerForCheckingNewOrdersInBackground();
      print('tried giving background here');
      // print('thisIsChefCallingForBackground1 $thisIsChefCallingForBackground');

      // _everyThirtySeconds = 0;
//ThisLoopMeansItWillEnterTheLoopEvery10Seconds
//       _timer = Timer.periodic(const Duration(seconds: 10), (_) {
//         //ItWillCheckWhetherTheVariableEveryThirtySecondsIsLessThan121,,
// //ThenItWillBeIncrementedBy1AndItWillAlsoCallTheFunctionWhichWillCheck,,
// //ForNewOrdersInTheBackground
// //IfItIsMoreThan120,ThenForOneHourThereHasNotBeenAnyOrder
// //AndHenceWeCancelTheTimer
//         currentNewOrdersCheckInBackground();
//         print(_everyThirtySeconds);
//         if (_everyThirtySeconds < 361) {
//           _everyThirtySeconds++;
//           // currentNewOrdersCheckInBackground();
//
//         } else {
//           _timer?.cancel();
//           //toCloseTheAppInCaseTheAppIsn'tOpenedForAnHour
//         }
//       });
    } else if (isForeground) {
      // thisIsChefCallingForBackground = true;
      setState(() {
        appInBackground = false;
      });
      backgroundTimerCounter = 0;
      // FlutterBackground.initialize();
      NotificationService().cancelAllNotifications();
      FlutterBackground.disableBackgroundExecution();

//ifTheAppHasChangedToForeground,ItMeansTheUserHasOpenedTheAppAnd
//itHasComeToTheForeground
//WeStopTheAppThen
//AndWeChangePlayerPlayingToFalse
//AndWeCancelTheTimer

      player.stop();
      playerState = PlayerState.stopped;
      playerPlaying = false;
      _everyThirtySeconds = 0;
      _timer?.cancel();
      // if (bluetoothOnTrueOrOffFalse == false &&
      //     (Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
      //         .chefPrinterKOTFromClass) &&
      //     localKOTItemNames.isNotEmpty) {
      //   // bluetoothForKotNotTurnedOn();
      //   // ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      //   //   content: Text(
      //   //     'Please Turn On Bluetooth For KOT',
      //   //     textAlign: TextAlign.center,
      //   //     style: const TextStyle(fontSize: kSnackbarMessageSize),
      //   //   ),
      //   //   duration: Duration(seconds: 10),
      //   // ));
      //   // show('Please Turn On Bluetooth For KOT1243');
      // }

      setState(() {
        pageHasInternet = true;
      });
      internetAvailabilityChecker();
    }

    super.didChangeAppLifecycleState(state);
  }

  void timerForCheckingNewOrdersInBackground() {
    if (backgroundTimerCounter < 361) {
      Timer? _timerForCheckingBackgroundOrders;
      int _everySecondBeforeCallingTimer = 0;
      _timerForCheckingBackgroundOrders =
          Timer.periodic(Duration(seconds: 1), (_) async {
        if (appInBackground == false) {
          _timerForCheckingBackgroundOrders!.cancel();
        }
        if (_everySecondBeforeCallingTimer < 10) {
          // timerRunningForCheckingNewOrdersInBackground = true;
          _everySecondBeforeCallingTimer++;
          // if (_everySecondBeforeCallingTimer == 10) {
          //   NotificationService().showNotification(
          //       title: 'Orders', body: 'We are looking for Updates');
          // }
          // if()
          print(
              '_everySecondBeforeCallingTimer $_everySecondBeforeCallingTimer');
        } else if (_everySecondBeforeCallingTimer == 10) {
          // if (backgroundTimerCounter % 2 == 0) {
          // NotificationService().showNotification(
          //     title: 'Orders', body: 'We are looking for Updates');
          // }
          timerRunningForCheckingNewOrdersInBackground = false;
          // bluetoothTurnOnMessageShown = false;
          // print('came inside bluetooth On Point');
          if (appInBackground) {
            currentNewOrdersCheckInBackground();
          }
          _everySecondBeforeCallingTimer++;

          _timerForCheckingBackgroundOrders!.cancel();
        } else {
          timerRunningForCheckingNewOrdersInBackground = false;
          _timerForCheckingBackgroundOrders!.cancel();
        }
      });
    }
  }

  // void timerForBackgroundNotifications() {
  //   Timer? _timerForBackgroundNotifications;
  //   int _everySecondBeforeCallingNotifications = 0;
  //   _timerForBackgroundNotifications =
  //       Timer.periodic(Duration(seconds: 10), (_) async {
  //     if (_everySecondBeforeCallingNotifications < 2) {
  //       // timerRunningForCheckingNewOrdersInBackground = true;
  //       _everySecondBeforeCallingNotifications++;
  //       print(
  //           '_everySecondBeforeCallingNotifications $_everySecondBeforeCallingNotifications');
  //     } else if (_everySecondBeforeCallingNotifications == 2) {
  //       // if (backgroundTimerCounter % 2 == 0) {
  //       NotificationService().showNotification(
  //           title: 'Orders', body: 'We are looking for Updates');
  //       // }
  //
  //       _everySecondBeforeCallingNotifications++;
  //
  //       _timerForBackgroundNotifications!.cancel();
  //     } else {
  //       _timerForBackgroundNotifications!.cancel();
  //     }
  //   });
  // }

  void currentNewOrdersCheckInBackground() async {
    // bool enabled = FlutterBackground.isBackgroundExecutionEnabled;
    // print('enabled $enabled');
    NotificationService()
        .showNotification(title: 'Orders', body: 'We are looking for Updates');

    backgroundTimerCounter++;
    print('background called $backgroundTimerCounter');
    if (backgroundTimerCounter < 361) {
      final presentOrdersCheck = await FirebaseFirestore.instance
          .collection(widget.hotelName)
          .doc('presentorders')
          .collection('presentorders')
          .where('chefStatus', isEqualTo: 9)
          .get();
//WeFirstMake "SomeNewItemsOrdered" AsFalse
      someNewItemsOrdered = false;
      List<String> kotItemNames = [];
      List<num> kotNumberOfOrderedItems = [];
      List<String> kotItemsBelongsToDoc = [];
      List<String> kotItemsEntireItemListBeforeSplitting = [];
      List<String> kotItemsEachItemFromEntireItemsString = [];
      List<String> kotItemsComments = [];
      List<String> kotItemsTableOrParcel = [];
      List<String> kotItemsTableOrParcelNumber = [];
      List<String> kotItemsParentOrChild = [];
      List<String> kotItemsTicketNumber = [];
      List<String> kotItemsID = [];
      List<String> kotCancelledItemTrueElseFalse = [];
      num counterForKOT = 0;
      List<Map<String, dynamic>> backgroundItems = [];
      cancelledItemsKey = [];
      Map<String, dynamic> mapToAddIntoBackgroundItems = {};
      String eachItemFromEntireItemsString = '';
      DateTime now = DateTime.now();

//WeGoThrough "EachNewOrder" ByGoingThroughTheDocs
      num presentOrderSizeCounter = 0;
      for (var eachOrder in presentOrdersCheck.docs) {
        presentOrderSizeCounter++;
        if (Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .chefPrinterKOTFromClass) {
          if (eachOrder.id != 'ZCancelledList') {
            String splitCheck = eachOrder['addedItemsSet'];

            final setSplit = splitCheck.split('*');

            setSplit.removeLast();
            String tableorparcel = setSplit[0];
            num tableorparcelnumber = num.parse(setSplit[1]);
            String parentOrChild = setSplit[7];
            num timecustomercametoseat = num.parse(setSplit[2]);

            num currentTimeHourMinuteMultiplied =
                ((now.hour * 60) + now.minute);

            for (int i = 0; i < setSplit.length; i++) {
              if ((i) > 14) {
                if ((i + 1) % 15 == 1) {
                  mapToAddIntoBackgroundItems = {};
                  eachItemFromEntireItemsString = '';

                  mapToAddIntoBackgroundItems['tableorparcel'] = tableorparcel;
                  mapToAddIntoBackgroundItems['parentOrChild'] = parentOrChild;
                  mapToAddIntoBackgroundItems['tableorparcelnumber'] =
                      tableorparcelnumber;
                  mapToAddIntoBackgroundItems['timecustomercametoseat'] =
                      timecustomercametoseat;
                  mapToAddIntoBackgroundItems[
                          'nowMinusTimeCustomerCameToSeat'] =
                      currentTimeHourMinuteMultiplied - timecustomercametoseat;

                  mapToAddIntoBackgroundItems['eachiteminorderid'] =
                      setSplit[i];
                  eachItemFromEntireItemsString += '${setSplit[i]}*';
                }
                if ((i + 1) % 15 == 2) {
                  mapToAddIntoBackgroundItems['item'] = setSplit[i];
                  eachItemFromEntireItemsString += '${setSplit[i]}*';
                }
                if ((i + 1) % 15 == 3) {
                  mapToAddIntoBackgroundItems['priceofeach'] =
                      num.parse(setSplit[i]);
                  eachItemFromEntireItemsString += '${setSplit[i]}*';
                }
                if ((i + 1) % 15 == 4) {
                  mapToAddIntoBackgroundItems['number'] =
                      num.parse(setSplit[i]);
                  eachItemFromEntireItemsString += '${setSplit[i]}*';
                }

                if ((i + 1) % 15 == 5) {
                  mapToAddIntoBackgroundItems['timeoforder'] =
                      num.parse(setSplit[i]);
                  mapToAddIntoBackgroundItems[
                          'nowTimeMinusThisItemOrderedTime'] =
                      (currentTimeHourMinuteMultiplied -
                          num.parse(setSplit[i]));

                  eachItemFromEntireItemsString += '${setSplit[i]}*';
                }
                if ((i + 1) % 15 == 6) {
                  mapToAddIntoBackgroundItems['statusoforder'] =
                      num.parse(setSplit[i]);
                  eachItemFromEntireItemsString += '${setSplit[i]}*';
                }
                if ((i + 1) % 15 == 7) {
                  mapToAddIntoBackgroundItems['commentsForTheItem'] =
                      setSplit[i];
                  eachItemFromEntireItemsString += '${setSplit[i]}*';
                }
                if ((i + 1) % 15 == 8) {
                  mapToAddIntoBackgroundItems['chefKotStatus'] = setSplit[i];
                  eachItemFromEntireItemsString += '${setSplit[i]}*';
                }
                if ((i + 1) % 15 == 9) {
                  mapToAddIntoBackgroundItems['ticketNumber'] = setSplit[i];
                  mapToAddIntoBackgroundItems['itemBelongsToDoc'] =
                      eachOrder.id;
                  mapToAddIntoBackgroundItems['entireItemListBeforeSplitting'] =
                      splitCheck;
                  eachItemFromEntireItemsString = eachItemFromEntireItemsString +
                      setSplit[i] +
                      "*" +
                      "futureUse*futureUse*futureUse*futureUse*futureUse*futureUse*";
                  mapToAddIntoBackgroundItems['eachItemFromEntireItemsString'] =
                      eachItemFromEntireItemsString;
                  backgroundItems.add(mapToAddIntoBackgroundItems);
                }
              }
            }
          } else {
            //TheListThatKeepsTrackOfAllTheItemsThatAreCancelled
            cancelledItemsKey = [];
            final cancelledData = eachOrder.data() as Map<String, dynamic>;
            cancelledData.forEach((key, value) {
              if (key != 'chefStatus') {
                cancelledItemsKey.add(key);
                mapToAddIntoBackgroundItems = {};
                eachItemFromEntireItemsString = value.toString();
                String cancelledItemsSplitCheck = value.toString();
                final cancelledItemSplit = cancelledItemsSplitCheck.split('*');
                cancelledItemSplit.removeLast();
                num currentTimeHourMinuteMultiplied =
                    ((now.hour * 60) + now.minute);

                mapToAddIntoBackgroundItems['tableorparcel'] =
                    cancelledItemSplit[9];

                mapToAddIntoBackgroundItems['tableorparcelnumber'] =
                    num.parse(cancelledItemSplit[10]);

                mapToAddIntoBackgroundItems['parentOrChild'] =
                    cancelledItemSplit[11];

                mapToAddIntoBackgroundItems['cancelledItemTrueElseFalse'] =
                    cancelledItemSplit[12];

                mapToAddIntoBackgroundItems['timecustomercametoseat'] =
                    num.parse(cancelledItemSplit[4]);

                mapToAddIntoBackgroundItems['nowMinusTimeCustomerCameToSeat'] =
                    (currentTimeHourMinuteMultiplied -
                        num.parse(cancelledItemSplit[4]));
                mapToAddIntoBackgroundItems['eachiteminorderid'] = key;

                mapToAddIntoBackgroundItems['item'] = cancelledItemSplit[1];

                mapToAddIntoBackgroundItems['priceofeach'] =
                    num.parse(cancelledItemSplit[2]);

                mapToAddIntoBackgroundItems['number'] =
                    num.parse(cancelledItemSplit[3]);

                mapToAddIntoBackgroundItems['timeoforder'] =
                    num.parse(cancelledItemSplit[4]);
                mapToAddIntoBackgroundItems['nowTimeMinusThisItemOrderedTime'] =
                    (currentTimeHourMinuteMultiplied -
                        num.parse(cancelledItemSplit[4]));
                mapToAddIntoBackgroundItems['statusoforder'] = 9;

                mapToAddIntoBackgroundItems['commentsForTheItem'] =
                    cancelledItemSplit[6];

                mapToAddIntoBackgroundItems['chefKotStatus'] =
                    cancelledItemSplit[7];

                mapToAddIntoBackgroundItems['ticketNumber'] =
                    cancelledItemSplit[8];

                mapToAddIntoBackgroundItems['itemBelongsToDoc'] = eachOrder.id;

                mapToAddIntoBackgroundItems['entireItemListBeforeSplitting'] =
                    value;
                mapToAddIntoBackgroundItems['eachItemFromEntireItemsString'] =
                    value;
                print(mapToAddIntoBackgroundItems);
                backgroundItems.add(mapToAddIntoBackgroundItems);
              }
            });
            // print(cancelledData);
            print(backgroundItems);
          }
          if (presentOrderSizeCounter == presentOrdersCheck.size) {
            counterForKOT = 0;
            for (var backgroundItem in backgroundItems!) {
              counterForKOT++;

              print('inside backgroundKOT collection area1');
              if (backgroundItem['chefKotStatus'] == 'chefkotnotyet' &&
                  !widget.chefSpecialities.contains(backgroundItem['item'])) {
                print('inside backgroundKOT collection area2');
                kotItemNames.add(backgroundItem['item']);
                kotNumberOfOrderedItems.add(backgroundItem['number']);
                kotItemsComments.add(backgroundItem['commentsForTheItem']);
                kotItemsBelongsToDoc.add(backgroundItem['itemBelongsToDoc']);
                kotItemsEntireItemListBeforeSplitting
                    .add(backgroundItem['entireItemListBeforeSplitting']);
                kotItemsEachItemFromEntireItemsString
                    .add(backgroundItem['eachItemFromEntireItemsString']);
                kotItemsTableOrParcel.add(backgroundItem['tableorparcel']);
                kotItemsTableOrParcelNumber
                    .add(backgroundItem['tableorparcelnumber'].toString());
                kotItemsParentOrChild.add(backgroundItem['parentOrChild']);
                kotItemsTicketNumber.add(backgroundItem['ticketNumber']);
                kotItemsID.add(backgroundItem['eachiteminorderid']);
                kotCancelledItemTrueElseFalse
                    .add(backgroundItem['cancelledItemTrueElseFalse']);
              }
              if (counterForKOT == backgroundItems.length &&
                  kotItemNames.isNotEmpty &&
                  // printingOver &&
                  locationPermissionAccepted) {
                print('entered dfgdfgdf');
                printingOver = false;
                localKOTItemNames = kotItemNames;
                localKOTNumberOfItems = kotNumberOfOrderedItems;
                localKOTItemComments = kotItemsComments;
                localKotItemsBelongsToDoc = kotItemsBelongsToDoc;
                localKotItemsEntireItemListBeforeSplitting =
                    kotItemsEntireItemListBeforeSplitting;
                localKotItemsEachItemFromEntireItemsString =
                    kotItemsEachItemFromEntireItemsString;
                localKotItemsTableOrParcel = kotItemsTableOrParcel;
                localKotItemsTableOrParcelNumber = kotItemsTableOrParcelNumber;
                localKotItemsParentOrChild = kotItemsParentOrChild;
                localKotItemsTicketNumber = kotItemsTicketNumber;
                localKotCancelledItemTrueElseFalse =
                    kotCancelledItemTrueElseFalse;
                localKOTItemsID = kotItemsID;
                print('234');
//ThisWillEnsurePrintingIsCalledOnlyWhenNewItemsAreComingOrSomethingIsCancelled
                if ((!listEquals(tempLocalKOTItemsID, localKOTItemsID) ||
                        cancelledItemsKey.isNotEmpty) &&
                    bluetoothJustTurningOn == false) {
                  if (bluetoothOnTrueOrOffFalse &&
                      timerForPrintingKOTRunning == false &&
                      timerForPrintingTenSecKOTRunning == false &&
                      intermediatePrintingCallKOTRunning == false &&
                      intermediatePrintingAfterOrderReadyRunning == false) {
                    timerForPrintingKOT();
                  } else if (bluetoothTurnOnMessageShown == false &&
                      bluetoothOnTrueOrOffFalse == false) {
                    bluetoothForKotNotTurnedOn();
                  }
                } else {
                  print('nothing needed');
                }
                // int _everySecondForKOT = 0;
                // Timer? _timerForKOT;
                // _timerForKOT = Timer.periodic(Duration(seconds: 2), (_) async {
                //   if (_everySecondForKOT <= 2) {
                //     print('fgdfgdgdgfdgdn45465gh');
                //     _everySecondForKOT++;
                //   } else {
                //     print('fgdfgdgdgfdgdngh');
                //     if (bluetoothOnTrueOrOffFalse) {
                //       timerForPrintingKOT();
                //       printerConnectionToLastSavedPrinterForKOT();
                //     } else if (bluetoothTurnOnMessageShown == false) {
                //       bluetoothForKotNotTurnedOn();
                //     }
                //     // playPrinterKOT();
                //
                //     bluetoothStateChangeFunction();
                //
                //     print('calling KOT');
                //     _timerForKOT!.cancel();
                //     _everySecondForKOT = 0;
                //   }
                // });
              }

              // else {
              //   if (bluetoothTurnOnMessageShown == false) {
              //     bluetoothForKotNotTurnedOn();
              //     // show('Please Turn On Bluetooth 45657');
              //     // playPrinterError();
              //     // bluetoothTurnOnMessageShown = true;
              //   }
              // }
            }
          }
        } else {
          // i++;
          print('counter $presentOrderSizeCounter');
          if (eachOrder['chefStatus'] == 9) {
            someNewItemsOrdered = true;
          }

//IfAnOrderStatusIs9 & AlsoWeCheckIfChefSpecialitiesDoesn'tHaveTheItem,
          //WeChangeThe SomeNewItemsOrdered As True
//           String addedItemsSet = eachOrder['addedItemsSet'];
//           final screenOffCheckSplit = addedItemsSet.split('*');
//
//           for (int j = 1; j < ((screenOffCheckSplit.length - 1) / 15); j++) {
// //ThisForLoopWillGoThroughEveryOrder,GoExactlyThroughThePointsWhereStatusIsThere
//             if (((screenOffCheckSplit[(j * 15) + 5]) == '9') &&
//                 !widget.chefSpecialities
//                     .contains((screenOffCheckSplit[(j * 15) + 1]))) {
//               someNewItemsOrdered = true;
//             }
//             // if ((j == ((screenOffCheckSplit.length - 1) / 15) - 1)) {
//             //   print('cook alarm $j');
//             //   if (someNewItemsOrdered) {
//             //     playCook();
//             //   }
//             // }
//           }
          if (presentOrderSizeCounter == presentOrdersCheck.size) {
            print('counter end $presentOrderSizeCounter');
            if (someNewItemsOrdered) {
              playCookTrim();
            }
          }
        }

        //
        // if (eachNewOrder['statusoforder'] == 9 &&
        //     !widget.chefSpecialities.contains(eachNewOrder['item'])) {
        //   someNewItemsOrdered = true;
        // }
      }
    }

    if (appInBackground
        // &&
        // timerRunningForCheckingNewOrdersInBackground == false
        ) {
      print('appInBackground $appInBackground');
      // timerForBackgroundNotifications();
      timerForCheckingNewOrdersInBackground();
      timerRunningForCheckingNewOrdersInBackground = true;
    }
    // bluetoothTurnOnMessageShown = false;
//ThisIsTheFireStoreCommandWeUseToCheckWhetherThereIsAnyNewOrder
//IfSomeOrderHasStatusOfOrderAs9,ThatMeansItIsANewOrder

//IfItIsTrue,WeWillPlayTheCookMusic
//     if (someNewItemsOrdered) {
//       playCook();
//     }
  }

//PlayCookIsTheMethodToPlayMusic
//WeFirstCheckWhetherPlayerIsPlaying
//ifItIsFalse,Then WeGivePlayerPlay and WeGive AssetSourceWhichIsTheSource,,
//ofTheFile and WeAlsoChangePlayerStateToPlaying
//WeChangePlayerPlayingToTrue

  void playCook() async {
    if (!playerPlaying) {
      //await player.setSource(AssetSource('audio/chef_orders.mp3'));
      await player.play(AssetSource('audio/chef_orders.mp3'));
      playerState = PlayerState.playing;
      playerPlaying = true;
//WeHave EventListener,WhichOnPlayerIsComplete
//itWillChange playerState to completed& playerPlayingToFalse
      player.onPlayerComplete.listen((event) {
        playerState = PlayerState.completed;
        playerPlaying = false;
      });
    }
  }

  void playCookTrim() async {
    if (!playerPlaying) {
      //await player.setSource(AssetSource('audio/chef_orders.mp3'));
      await player.play(AssetSource('audio/chef_orders_trim.mp3'));
      playerState = PlayerState.playing;
      playerPlaying = true;
//WeHave EventListener,WhichOnPlayerIsComplete
//itWillChange playerState to completed& playerPlayingToFalse
      player.onPlayerComplete.listen((event) {
        playerState = PlayerState.completed;
        playerPlaying = false;
      });
    }
  }

  void playCaptain() async {
//IfOrderIsReady,PlayTuneWithPlay-ItIsAnAssetSource-SoWeNeedToPutItIn
    if (!playerPlaying) {
      await player.play(AssetSource('audio/captain_orders.mp3'));
      playerState = PlayerState.playing;
      playerPlaying = true;
//OnceCompletedWeChangeItToCompleted
      player.onPlayerComplete.listen((event) {
        playerState = PlayerState.completed;
        playerPlaying = false;
      });
    }
  }

  void playPrinterError() async {
    if (!playerPlaying) {
      //await player.setSource(AssetSource('audio/chef_orders.mp3'));
      await player.play(AssetSource('audio/printererror.mp3'));
      playerState = PlayerState.playing;
      playerPlaying = true;
//WeHave EventListener,WhichOnPlayerIsComplete
//itWillChange playerState to completed& playerPlayingToFalse
      player.onPlayerComplete.listen((event) {
        playerState = PlayerState.completed;
        playerPlaying = false;
      });
    }
  }

  void playPrinterKOT() async {
    if (!playerPlaying) {
      //await player.setSource(AssetSource('audio/chef_orders.mp3'));
      await player.play(AssetSource('audio/chefprinterKOT.mp3'));
      playerState = PlayerState.playing;
      playerPlaying = true;
//WeHave EventListener,WhichOnPlayerIsComplete
//itWillChange playerState to completed& playerPlayingToFalse
      player.onPlayerComplete.listen((event) {
        playerState = PlayerState.completed;
        playerPlaying = false;
      });
    }
  }

  void bluetoothForKotNotTurnedOn() {
    bluetoothTurnOnMessageShown = false;
    print('came inside this bluetoothForKotNotTurnedOn');
    print(localKOTItemNames);
    print(bluetoothTurnOnMessageShown);
    if (bluetoothTurnOnMessageShown == false &&
        localKOTItemNames.isNotEmpty &&
        Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .chefPrinterKOTFromClass &&
        bluetoothOnTrueOrOffFalse == false) {
      bluetoothTurnOnMessageShown = true;
      print('bluetoothForKotNotTurnedOn2');
      playPrinterError();
      if (appInBackground == false) {
        show('Please Turn On Bluetooth');
      }

      timerForFlashingBluetoothMessage();
    }

    // if (bluetoothOnTrueOrOffFalse == false &&
    //     Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
    //         .chefPrinterKOTFromClass &&
    //     localKOTItemNames.isNotEmpty &&
    //     bluetoothTurnOnMessageShown == true) {
    //   print('bluetoothForKotNotTurnedOn3');
    //   timerForFlashingBluetoothMessage();
    // }
  }

  void timerForFlashingBluetoothMessage() {
    bluetoothStateChangeFunction();
    int _everySecondForBluetoothMessage = 0;
    Timer? _timerToGoForBluetoothMessage;
    _timerToGoForBluetoothMessage =
        Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_everySecondForBluetoothMessage < 10) {
        _everySecondForBluetoothMessage++;
        print(
            '_everySecondForBluetoothMessage $_everySecondForBluetoothMessage');
      } else if (_everySecondForBluetoothMessage == 10) {
        // bluetoothTurnOnMessageShown = false;
        print('came inside bluetooth On Point2');
        if (bluetoothOnTrueOrOffFalse == false &&
            localKOTItemNames.isNotEmpty &&
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .chefPrinterKOTFromClass) {
          bluetoothForKotNotTurnedOn();
        } else {
          print('turned bluetoothmessage turning on');
          bluetoothTurnOnMessageShown = false;
        }
        _everySecondForBluetoothMessage++;

        _timerToGoForBluetoothMessage!.cancel();
      } else {
        _timerToGoForBluetoothMessage!.cancel();
        print('ingabl $_everySecondForBluetoothMessage');
      }
    });
  }

  void timerForPrintingKOT() {
    _everySecondForKotTimer = 0;
    timerForPrintingKOTRunning = false;
    Timer? _timerToGoForKOt;
    _timerToGoForKOt = Timer.periodic(const Duration(seconds: 1), (_) async {
//ThisWillEnsureOnlyWhenNewItemsComeNextTime,itWillBePrinted
      tempLocalKOTItemsID = localKOTItemsID;
      print('__everySecondForKotTimer inside timer $_everySecondForKotTimer');
      if (_everySecondForKotTimer < 3) {
        timerForPrintingKOTRunning = true;
        _everySecondForKotTimer++;
        print('_everySecondForKotTimer $_everySecondForKotTimer');
      } else if (_everySecondForKotTimer == 3) {
        timerForPrintingKOTRunning = false;
        print('came inside bluetooth On Point3');
        if (localKOTItemNames.isNotEmpty) {
          printerConnectionToLastSavedPrinterForKOT();
        }
        _everySecondForKotTimer++;

        _timerToGoForKOt!.cancel();
      } else {
        timerForPrintingKOTRunning = false;
        _timerToGoForKOt!.cancel();
        print('inga $_everySecondForKotTimer');
      }
    });
  }

  void timerForPrintingKOTTenSeconds() {
    _everySecondForKotTimer = 0;
    timerForPrintingTenSecKOTRunning = false;
    // Timer? _timerToGoForKOt;
    _timerToGoForKOt = Timer.periodic(const Duration(seconds: 1), (_) async {
      tempLocalKOTItemsID = localKOTItemsID;
      print('__everySecondForKotTimer inside timer $_everySecondForKotTimer');
      if (_everySecondForKotTimer < 8) {
        timerForPrintingTenSecKOTRunning = true;
        _everySecondForKotTimer++;
        print('_everySecondForKotTimer $_everySecondForKotTimer');
      } else if (_everySecondForKotTimer == 8) {
        timerForPrintingTenSecKOTRunning = false;
        print('came inside bluetooth On Point4');
        if (localKOTItemNames.isNotEmpty &&
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .chefPrinterKOTFromClass) {
          printerConnectionToLastSavedPrinterForKOT();
        }
        _everySecondForKotTimer++;

        _timerToGoForKOt!.cancel();
      } else {
        timerForPrintingTenSecKOTRunning = false;
        _timerToGoForKOt!.cancel();
        print('inga $_everySecondForKotTimer');
      }
    });
  }

  void statusUpdaterInFireStore(
      String eachItemFromEntireItemsString,
      String entireItemListBeforeSplitting,
      String itemBelongsToDoc,
      String newStatusToUpdate) {
    print('eachItemFromEntireItemsString');
    print(eachItemFromEntireItemsString);
    final eachItemFromEntireItemsStringSplit =
        eachItemFromEntireItemsString.split('*');
    eachItemFromEntireItemsStringSplit[5] = newStatusToUpdate;

    String tempStatusUpdaterString = '';
    for (int i = 0; i < eachItemFromEntireItemsStringSplit.length - 1; i++) {
      tempStatusUpdaterString += '${eachItemFromEntireItemsStringSplit[i]}*';
    }

    String stringUsedForUpdatingStatus = entireItemListBeforeSplitting
        .replaceAll(eachItemFromEntireItemsString, tempStatusUpdaterString);

    final statusUpdatedStringCheck = stringUsedForUpdatingStatus.split('*');

    String partOfTableOrParcel = statusUpdatedStringCheck[0];
    String partOfTableOrParcelNumber = statusUpdatedStringCheck[1];

//keepingDefaultAs7-AcceptedStatusWhichNeedNotCreateAnyIssue
    num chefStatus = 7;
    num captainStatus = 7;

    for (int j = 1; j < ((statusUpdatedStringCheck.length - 1) / 15); j++) {
//ThisForLoopWillGoThroughEveryOrder,GoExactlyThroughThePointsWhereStatusIsThere
      if (((statusUpdatedStringCheck[(j * 15) + 5]) == '11')) {
        captainStatus = 11;
      } else if (((statusUpdatedStringCheck[(j * 15) + 5]) == '10') &&
          captainStatus != 11) {
        captainStatus = 10;
      }
      if (((statusUpdatedStringCheck[(j * 15) + 5]) == '9')) {
        chefStatus = 9;
      }
    }

    FireStoreAddOrderServiceWithSplit(
            hotelName: widget.hotelName,
            itemsUpdaterString: stringUsedForUpdatingStatus,
            seatingNumber: itemBelongsToDoc,
            captainStatus: captainStatus,
            chefStatus: chefStatus,
            partOfTableOrParcel: partOfTableOrParcel,
            partOfTableOrParcelNumber: partOfTableOrParcelNumber)
        .addOrder();
  }

  void buildChefInstructionAlertDialogWidgetWithTimer() async {
    Timer _videoPlayTimer;
    _videoController.initialize();
    _videoPlayTimer = Timer(Duration(milliseconds: 500), () async {
      await Future(() {
        if (Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .chefInstructionsVideoPlayedFromClass ==
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
                              .chefVideoInstructionLookedOrNot(true);

                          Navigator.pop(context);
                        },
                        child: Padding(
                          // padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                          padding: const EdgeInsets.all(20.0),
                          child: Text('  Ok  '),
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      //thisOnWillPopIsForTheBackButtonInPhone&ifItIsClicked,ItWillPopTheScreen
      onWillPop: () async {
        Wakelock.disable();
        showSpinner = false;

        // thisIsChefCallingForBackground = true;
        // _timerToGoForKOt!.cancel();
        appInBackground = false;
        localKOTItemNames = [];
        kotCounter = 0;
        player.stop();
        if (bluetoothConnected) {
          _fastDisconnectForAfterOrderPrint();
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
        appBar: AppBar(
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: kAppBarBackIconColor),
              onPressed: () async {
                Wakelock.disable();
                showSpinner = false;
                // thisIsChefCallingForBackground = true;
                // _timerToGoForKOt!.cancel();
                appInBackground = false;
                localKOTItemNames = [];
                kotCounter = 0;
                player.stop();
                if (bluetoothConnected) {
                  _fastDisconnectForAfterOrderPrint();
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

//IfBluetoothConnectedDuringBackButtonPressed,ItShouldBeDisconnected
//                   if (bluetoothConnected) {
//                     await bluetoothPrint.disconnect();
//                     bluetoothConnected = false;
//                   }
//                   Navigator.pop(context);
              }),
          backgroundColor: kAppBarBackgroundColor,
//IfNormalChefScreen-ThisTitle
//IfBluetoothConnectionScreenIsNeeded,NextTitle
//IfPrinterSettingsAreNeededFinalTitle
          title: const Text(
            'For the Chef',
            style: kAppBarTextStyle,
          ),
          centerTitle: true,
//ThisIsForSettingsIconWhereWeCanAlterPrinterSettings
//IfNoPrinterIsAlreadyStored,ThroughNoNeedPrinterConnectionScreenFalse,,
//WeGoToPrinterConnectionScreen
//ifPrinterIsAlreadyStored,WeGoToPrinterSettingsScreenWithElseStatement
          actions: <Widget>[
            IconButton(
                onPressed: () {
                  Provider.of<PrinterAndOtherDetailsProvider>(context,
                          listen: false)
                      .chefVideoInstructionLookedOrNot(false);

                  buildChefInstructionAlertDialogWidgetWithTimer();
                  // _videoController.play();
                },
                icon: Icon(
                  Icons.help,
                  color: kAppBarBackIconColor,
                )),
            IconButton(
                onPressed: () {
                  // _timerToGoForKOt!.cancel();
                  // Navigator.pop(context);
                  Wakelock.disable();
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              PrinterSettings(chefOrCaptain: 'Chef')));
                },
                icon: Icon(
                  Icons.settings,
                  color: kAppBarBackIconColor,
                ))
          ],
        ),
//ThisIsTheColumnWhichWePutIntoTheChefScreen
//ThisWillShowTheSpinnerWheneverItIsChangedToTrue
        body: ModalProgressHUD(
          inAsyncCall: showSpinner,
          child: Column(
            children: [
//IfPageHasInternet,WeActuallyNeedNothing,SoJustPuttingSmallSizedBox
              pageHasInternet
                  ? SizedBox.shrink()
                  // Image(
                  //         image: AssetImage(
                  //             'assets/images/chef_reject_accept_image.png'))
                  : Container(
//IfItIsOffline,WePutContainerSaying "YouAreOffline"
                      width: double.infinity,
                      color: Colors.red,
                      child: Center(
                        child: Text('You are Offline',
                            style:
                                TextStyle(color: Colors.white, fontSize: 30.0)),
                      ),
                    ),

//UsingStreamBuilder,WeGetAllTheSnapshotsInsideCurrentOrdersCollection
//IfPrinterSettings/ConnectionScreenIsNotNeeded,WeCanShowAllTheItemsForChef
              StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection(widget.hotelName)
                      .doc('presentorders')
                      .collection('presentorders')
                      .snapshots(),
                  builder: (context, snapshot) {
                    //ThisOrderedItemsAndNumberOfItemsBelongToTheSameSet
                    List<String> orderedItems = [];
                    List<num> numberOfOrderedItems = [];
                    List<String> allItemsID = [];
                    List<num> allItemsStatus = [];
                    List<String> allItemsBelongsToDoc = [];
                    List<String> allItemsEntireItemListBeforeSplitting = [];
                    List<String> allItemsEachItemFromEntireItemsString = [];
                    List<String> allItemsComments = [];
                    List<String> allItemsCancelledTrueElseFalse = [];
                    //addingNewSetForCancelledItems
                    List<String> cancelledItems = [];
                    List<num> numberOfCancelledItems = [];
                    List<String> cancelledItemsID = [];
                    List<num> cancelledItemsStatus = [];
                    List<String> cancelledItemsBelongsToDoc = [];
                    List<String> cancelledEntireItemListBeforeSplitting = [];
                    List<String> cancelledEachItemFromEntireItemsString = [];
                    List<String> cancelledItemsComments = [];
                    List<String> cancelledItemsCancelledTrueElseFalse = [];
                    //addingNewSetForCancelledItems
                    List<String> acceptedItems = [];
                    List<num> numberOfAcceptedItems = [];
                    List<String> acceptedItemsID = [];
                    List<num> acceptedItemsStatus = [];
                    List<String> acceptedItemsBelongsToDoc = [];
                    List<String> acceptedEntireItemListBeforeSplitting = [];
                    List<String> acceptedEachItemFromEntireItemsString = [];
                    List<String> acceptedItemsComments = [];
                    List<String> acceptedItemsCancelledTrueElseFalse = [];
                    List<String> readyItems = [];
                    List<num> numberOfReadyItems = [];
                    List<String> readyItemsID = [];
                    List<num> readyItemsStatus = [];
                    List<String> readyItemsBelongsToDoc = [];
                    List<String> readyEntireItemListBeforeSplitting = [];
                    List<String> readyEachItemFromEntireItemsString = [];
                    List<String> readyItemsComments = [];
                    List<String> readyItemsCancelledTrueElseFalse = [];
                    List<String> rejectedItems = [];
                    List<num> numberOfRejectedItems = [];
                    List<String> rejectedItemsID = [];
                    List<num> rejectedItemsStatus = [];
                    List<String> rejectedItemsBelongsToDoc = [];
                    List<String> rejectedEntireItemListBeforeSplitting = [];
                    List<String> rejectedEachItemFromEntireItemsString = [];
                    List<String> rejectedItemsComments = [];
                    List<String> rejectedItemsCancelledTrueElseFalse = [];
                    bool chefPrinterAfterOrderReadyPrintFromClass =
                        Provider.of<PrinterAndOtherDetailsProvider>(context)
                            .chefPrinterAfterOrderReadyPrintFromClass;
                    // chefPrinterKOTFromClassForBackgroundKOT =
                    //     Provider.of<PrinterAndOtherDetailsProvider>(context,
                    //             listen: false)
                    //         .chefPrinterKOTFromClass;
                    // chefPrinterAddressFromClassForBackground =
                    //     Provider.of<PrinterAndOtherDetailsProvider>(context,
                    //             listen: false)
                    //         .chefPrinterAddressFromClass;
                    // chefPrinterSizeFromClassForBackground =
                    //     Provider.of<PrinterAndOtherDetailsProvider>(context,
                    //             listen: false)
                    //         .chefPrinterSizeFromClass;
//ThisIsTheListOfAllTheListsWeNeed
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Expanded(
                        child: const Center(
                          child: CircularProgressIndicator(
                            backgroundColor: Colors.lightBlueAccent,
                          ),
                        ),
                      );
                    } else if (snapshot.hasError) {
//IfThereIsAnError,WeCaptureTheErrorAndPutItInThePage
                      return Center(
                        child: Text(snapshot.error.toString()),
                      );
                    } else if (snapshot.hasData) {
//TheFirstPartIsToPlayAudioWhenNewOrderComes
//InitiallyWeKeepSomeNewItemsOrderedAsFalse&ListOfTemporaryNewItemsAddedAsEmpty

                      someNewItemsOrdered = false;
                      List<String> tempNewItemAddedList = [];
//TheCommandToGetTheDocsFromTheSnapshot
                      DateTime now = DateTime.now();
//IfThereIsData,WeGetTheDocsFromThatData
                      List<Map<String, dynamic>> items = [];
                      cancelledItemsKey = [];

                      Map<String, dynamic> mapToAddIntoItems = {};
                      String eachItemFromEntireItemsString = '';
//TheSnapshotInputIsFromWhereTheMethodIsCalled
                      final itemstream = snapshot.data?.docs;

                      for (var eachDoc in itemstream!) {
                        if (eachDoc.id != 'ZCancelledList') {
//EnsuringThisIsNotFromCancelledList
                          String splitCheck = eachDoc['addedItemsSet'];
                          final setSplit = splitCheck.split('*');

                          setSplit.removeLast();
                          String tableorparcel = setSplit[0];
                          num tableorparcelnumber = num.parse(setSplit[1]);
                          String parentOrChild = setSplit[7];
                          num timecustomercametoseat = num.parse(setSplit[2]);
                          num currentTimeHourMinuteMultiplied =
                              ((now.hour * 60) + now.minute);

                          for (int i = 0; i < setSplit.length; i++) {
//thisWillEnsureWeSwitchedFromTableInfoToOrderInfo
                            if ((i) > 14) {
                              if ((i + 1) % 15 == 1) {
                                mapToAddIntoItems = {};
                                eachItemFromEntireItemsString = '';
                                mapToAddIntoItems[
                                    'cancelledItemTrueElseFalse'] = 'false';

                                mapToAddIntoItems['tableorparcel'] =
                                    tableorparcel;
                                mapToAddIntoItems['tableorparcelnumber'] =
                                    tableorparcelnumber;
                                mapToAddIntoItems['parentOrChild'] =
                                    parentOrChild;
                                mapToAddIntoItems['timecustomercametoseat'] =
                                    timecustomercametoseat;
                                mapToAddIntoItems[
                                        'nowMinusTimeCustomerCameToSeat'] =
                                    currentTimeHourMinuteMultiplied -
                                        timecustomercametoseat;
                                // if ((currentTimeHourMinuteMultiplied -
                                //         timecustomercametoseat) >=
                                //     kCustomerWaitingTime) {
                                //   mapToAddIntoItems[
                                //           'nowMinusTimeCustomerCameToSeat'] =
                                //       currentTimeHourMinuteMultiplied -
                                //           timecustomercametoseat;
                                // } else {
                                //   mapToAddIntoItems[
                                //       'nowMinusTimeCustomerCameToSeat'] = 0;
                                // }
                                mapToAddIntoItems['eachiteminorderid'] =
                                    setSplit[i];
                                eachItemFromEntireItemsString +=
                                    '${setSplit[i]}*';
                              }
                              if ((i + 1) % 15 == 2) {
                                mapToAddIntoItems['item'] = setSplit[i];
                                eachItemFromEntireItemsString +=
                                    '${setSplit[i]}*';
                              }
                              if ((i + 1) % 15 == 3) {
                                mapToAddIntoItems['priceofeach'] =
                                    num.parse(setSplit[i]);
                                eachItemFromEntireItemsString +=
                                    '${setSplit[i]}*';
                              }
                              if ((i + 1) % 15 == 4) {
                                mapToAddIntoItems['number'] =
                                    num.parse(setSplit[i]);
                                eachItemFromEntireItemsString +=
                                    '${setSplit[i]}*';
                              }

                              if ((i + 1) % 15 == 5) {
                                mapToAddIntoItems['timeoforder'] =
                                    num.parse(setSplit[i]);
                                mapToAddIntoItems[
                                        'nowTimeMinusThisItemOrderedTime'] =
                                    (currentTimeHourMinuteMultiplied -
                                        num.parse(setSplit[i]));
                                // if ((num.parse(setSplit[i]) -
                                //         timecustomercametoseat) >=
                                //     kCustomerWaitingTime) {
                                //   mapToAddIntoItems[
                                //           'ThisItemOrderedTimeMinusCustomerCameToSeatTime'] =
                                //       (num.parse(setSplit[i]) -
                                //           timecustomercametoseat);
                                // } else {
                                //   mapToAddIntoItems[
                                //       'ThisItemOrderedTimeMinusCustomerCameToSeatTime'] = 0;
                                // }

                                eachItemFromEntireItemsString +=
                                    '${setSplit[i]}*';
                              }
                              if ((i + 1) % 15 == 6) {
                                mapToAddIntoItems['statusoforder'] =
                                    num.parse(setSplit[i]);
                                eachItemFromEntireItemsString +=
                                    '${setSplit[i]}*';
                              }
                              if ((i + 1) % 15 == 7) {
                                mapToAddIntoItems['commentsForTheItem'] =
                                    setSplit[i];
                                eachItemFromEntireItemsString +=
                                    '${setSplit[i]}*';
                              }
                              if ((i + 1) % 15 == 8) {
                                mapToAddIntoItems['chefKotStatus'] =
                                    setSplit[i];
                                eachItemFromEntireItemsString +=
                                    '${setSplit[i]}*';
                              }
                              if ((i + 1) % 15 == 9) {
                                mapToAddIntoItems['ticketNumber'] = setSplit[i];
                                mapToAddIntoItems['itemBelongsToDoc'] =
                                    eachDoc.id;
                                mapToAddIntoItems[
                                        'entireItemListBeforeSplitting'] =
                                    splitCheck;
                                eachItemFromEntireItemsString =
                                    eachItemFromEntireItemsString +
                                        setSplit[i] +
                                        "*" +
                                        "futureUse*futureUse*futureUse*futureUse*futureUse*futureUse*";
                                mapToAddIntoItems[
                                        'eachItemFromEntireItemsString'] =
                                    eachItemFromEntireItemsString;
                                items.add(mapToAddIntoItems);
                              }
                            }
                          }
                        } else {
//TheListThatKeepsTrackOfAllTheItemsThatAreCancelled
                          cancelledItemsKey = [];
                          final cancelledData =
                              eachDoc.data() as Map<String, dynamic>;
                          cancelledData.forEach((key, value) {
                            if (key != 'chefStatus') {
                              cancelledItemsKey.add(key);
                              mapToAddIntoItems = {};
                              eachItemFromEntireItemsString = value.toString();
                              String cancelledItemsSplitCheck =
                                  value.toString();
                              final cancelledItemSplit =
                                  cancelledItemsSplitCheck.split('*');
                              cancelledItemSplit.removeLast();
                              num currentTimeHourMinuteMultiplied =
                                  ((now.hour * 60) + now.minute);

                              mapToAddIntoItems['tableorparcel'] =
                                  cancelledItemSplit[9];

                              mapToAddIntoItems['tableorparcelnumber'] =
                                  num.parse(cancelledItemSplit[10]);

                              mapToAddIntoItems['parentOrChild'] =
                                  cancelledItemSplit[11];

                              mapToAddIntoItems['cancelledItemTrueElseFalse'] =
                                  cancelledItemSplit[12];

                              mapToAddIntoItems['timecustomercametoseat'] =
                                  num.parse(cancelledItemSplit[4]);

                              mapToAddIntoItems[
                                      'nowMinusTimeCustomerCameToSeat'] =
                                  (currentTimeHourMinuteMultiplied -
                                      num.parse(cancelledItemSplit[4]));
                              mapToAddIntoItems['eachiteminorderid'] = key;

                              mapToAddIntoItems['item'] = cancelledItemSplit[1];

                              mapToAddIntoItems['priceofeach'] =
                                  num.parse(cancelledItemSplit[2]);

                              mapToAddIntoItems['number'] =
                                  num.parse(cancelledItemSplit[3]);

                              mapToAddIntoItems['timeoforder'] =
                                  num.parse(cancelledItemSplit[4]);
                              mapToAddIntoItems[
                                      'nowTimeMinusThisItemOrderedTime'] =
                                  (currentTimeHourMinuteMultiplied -
                                      num.parse(cancelledItemSplit[4]));
                              mapToAddIntoItems['statusoforder'] = 9;

                              mapToAddIntoItems['commentsForTheItem'] =
                                  cancelledItemSplit[6];

                              mapToAddIntoItems['chefKotStatus'] =
                                  cancelledItemSplit[7];

                              mapToAddIntoItems['ticketNumber'] =
                                  cancelledItemSplit[8];

                              mapToAddIntoItems['itemBelongsToDoc'] =
                                  eachDoc.id;

                              mapToAddIntoItems[
                                  'entireItemListBeforeSplitting'] = value;
                              mapToAddIntoItems[
                                  'eachItemFromEntireItemsString'] = value;
                              // print(mapToAddIntoItems);
                              items.add(mapToAddIntoItems);
                            }
                          });
                          // print(cancelledData);
                          print('items to check');
                          print(items);
                        }
                      }

//creatingNewListToPrintKOTandAlsoUpdateKOTInServer
                      List<String> kotItemNames = [];
                      List<num> kotNumberOfOrderedItems = [];
                      List<String> kotItemsBelongsToDoc = [];
                      List<String> kotItemsEntireItemListBeforeSplitting = [];
                      List<String> kotItemsEachItemFromEntireItemsString = [];
                      List<String> kotItemsComments = [];
                      List<String> kotItemsTableOrParcel = [];
                      List<String> kotItemsTableOrParcelNumber = [];
                      List<String> kotItemsParentOrChild = [];
                      List<String> kotItemsTicketNumber = [];
                      List<String> kotItemsID = [];
                      List<String> kotCancelledItemTrueElseFalse = [];
                      num counterForKOT = 0;

//WeCheckIfSomeItemIsStatus9-MeansNewlyOrdered
//ToTempNewItemsAddedList,WeAddTheItemsId
//ThenWithinThatWeCheck,ItemsArrivedInLastCheckContainsItemIdAnd
//WhetherTheChefSpecialitiesHasThisItem,ThenWeChangeSomeNewItemsOrderedToTrue
                      for (var item in items!) {
                        counterForKOT++;
                        if (item['statusoforder'] == 9) {
                          if (Provider.of<PrinterAndOtherDetailsProvider>(
                                  context,
                                  listen: false)
                              .chefPrinterKOTFromClass) {
                            print('inside KOT collection area1');
                            if (item['chefKotStatus'] == 'chefkotnotyet' &&
                                !widget.chefSpecialities
                                    .contains(item['item'])) {
                              print('inside KOT collection area21');
                              kotItemNames.add(item['item']);
                              kotNumberOfOrderedItems.add(item['number']);
                              kotItemsComments.add(item['commentsForTheItem']);
                              kotItemsBelongsToDoc
                                  .add(item['itemBelongsToDoc']);
                              kotItemsEntireItemListBeforeSplitting
                                  .add(item['entireItemListBeforeSplitting']);
                              kotItemsEachItemFromEntireItemsString
                                  .add(item['eachItemFromEntireItemsString']);
                              kotItemsTableOrParcel.add(item['tableorparcel']);
                              kotItemsTableOrParcelNumber
                                  .add(item['tableorparcelnumber'].toString());
                              kotItemsParentOrChild.add(item['parentOrChild']);
                              kotItemsTicketNumber.add(item['ticketNumber']);
                              kotItemsID.add(item['eachiteminorderid']);
                              kotCancelledItemTrueElseFalse
                                  .add(item['cancelledItemTrueElseFalse']);
                            }
                          } else {
                            tempNewItemAddedList.add(item['eachiteminorderid']);
                            if (!itemsArrivedInLastCheck
                                    .contains(item['eachiteminorderid']) &&
                                !widget.chefSpecialities
                                    .contains(item['item'])) {
                              someNewItemsOrdered = true;
                            }
                          }
                        }

                        if (counterForKOT == items.length &&
                            kotItemNames.isNotEmpty &&
                            // printingOver &&
                            locationPermissionAccepted &&
                            _connected == false) {
                          print('Icoming inside this again and ahain');
                          printingOver = false;
                          localKOTItemNames = kotItemNames;
                          localKOTNumberOfItems = kotNumberOfOrderedItems;
                          localKOTItemComments = kotItemsComments;
                          localKotItemsBelongsToDoc = kotItemsBelongsToDoc;
                          localKotItemsEntireItemListBeforeSplitting =
                              kotItemsEntireItemListBeforeSplitting;
                          localKotItemsEachItemFromEntireItemsString =
                              kotItemsEachItemFromEntireItemsString;
                          localKotItemsTableOrParcel = kotItemsTableOrParcel;
                          localKotItemsTableOrParcelNumber =
                              kotItemsTableOrParcelNumber;
                          localKotItemsParentOrChild = kotItemsParentOrChild;
                          localKotItemsTicketNumber = kotItemsTicketNumber;
                          localKotCancelledItemTrueElseFalse =
                              kotCancelledItemTrueElseFalse;
                          localKOTItemsID = kotItemsID;
                          print(
                              '_everySecondForKotTimer1 $_everySecondForKotTimer');

                          if ((!listEquals(
                                      tempLocalKOTItemsID, localKOTItemsID) ||
                                  cancelledItemsKey.isNotEmpty) &&
                              bluetoothJustTurningOn == false) {
                            print('came into temp also');
                            print(tempLocalKOTItemsID);
                            print(localKOTItemsID);
                            if (bluetoothOnTrueOrOffFalse &&
                                timerForPrintingKOTRunning == false &&
                                timerForPrintingTenSecKOTRunning == false &&
                                intermediatePrintingCallKOTRunning == false &&
                                intermediatePrintingAfterOrderReadyRunning ==
                                    false) {
                              timerForPrintingKOT();
                            } else if (bluetoothTurnOnMessageShown == false &&
                                bluetoothOnTrueOrOffFalse == false) {
                              print(
                                  'inside calling bluetoothForKotNotTurnedOn');
                              bluetoothForKotNotTurnedOn();
                            }
                          } else {
                            print('nothing needed');
                          }
                        }
                      }
//FinallyWeMakeItemsArrivedInLastCheckSameAsTempNewItemsAddedList
//NextTimeWeWillAlertOnlyIfNewItemsThatAreNotInItemsArrivedInLastCheckComes

                      itemsArrivedInLastCheck = tempNewItemAddedList;

//IfSomeNewItemsCome,WePlayTheTune
                      if (someNewItemsOrdered &&
                          Provider.of<PrinterAndOtherDetailsProvider>(context)
                                  .chefPrinterKOTFromClass ==
                              false) {
                        playCook();
                      }
                      //ThisIsTheWayWeArrangeTheList.ThisFormulaShouldEnsure,IfCustomerWhoCameLongBack
//SuddenlyOrderedAnItemAtTheLast,WeCouldGiveHimMorePriority
                      items.sort((a, b) =>
                          (a['nowTimeMinusThisItemOrderedTime'] +
                                  a['nowMinusTimeCustomerCameToSeat'])
                              .compareTo(b['nowTimeMinusThisItemOrderedTime'] +
                                  b['nowMinusTimeCustomerCameToSeat']));
                      // items.sort((a, b) =>
                      //     a['nowTimeMinusThisItemOrderedTime'].compareTo(
                      //         b['nowTimeMinusThisItemOrderedTime']));
                      // items.sort((a, b) => a[
                      //         'ThisItemOrderedTimeMinusCustomerCameToSeatTime']
                      //     .compareTo(b[
                      //         'ThisItemOrderedTimeMinusCustomerCameToSeatTime']));

//WeIterateThroughAllItems
                      for (var item in items) {
//WeSeparateItemsFromTheDocument-itemName,TableOrParcelNumber
                        String itemNameAsString = item['item'];
                        String tableOrParcelNumberAsString =
                            item['tableorparcelnumber'].toString();
                        String parentOrChildAsString = item['parentOrChild'];

                        //IfLoopHereToEnsureOnlyCook'sSpecialitiesAreEnteredHere
//IfLoopToEliminateTheListOfItemsTheChefWon'tCook
                        if (!widget.chefSpecialities.contains(item['item'])) {
                          if (item['cancelledItemTrueElseFalse'] != 'false') {
                            //IfItemsAreAccepted,WeAddItToAcceptedItemsListWith T/P basedOn Table/Parcel
                            if (item['tableorparcel'] == "Table") {
                              if (item['parentOrChild'] == "parent") {
                                cancelledItems.add(
                                    'Table-$tableOrParcelNumberAsString: $itemNameAsString');
                              } else {
                                cancelledItems.add(
                                    'Table-$tableOrParcelNumberAsString$parentOrChildAsString: $itemNameAsString');
                              }
                            } else {
                              if (item['parentOrChild'] == "parent") {
                                cancelledItems.add(
                                    'Parcel-$tableOrParcelNumberAsString: $itemNameAsString');
                              } else {
                                cancelledItems.add(
                                    'Parcel-$tableOrParcelNumberAsString$parentOrChildAsString: $itemNameAsString');
                              }
                            }
                            //ThenWeAdd Number,ID and Status
                            numberOfCancelledItems.add(item['number']);
                            cancelledItemsID.add(item['eachiteminorderid']);
                            cancelledItemsStatus.add(item['statusoforder']);
                            cancelledItemsBelongsToDoc
                                .add(item['itemBelongsToDoc']);
                            cancelledEntireItemListBeforeSplitting
                                .add(item['entireItemListBeforeSplitting']);
                            cancelledEachItemFromEntireItemsString
                                .add(item['eachItemFromEntireItemsString']);
                            cancelledItemsComments
                                .add(item['commentsForTheItem']);
                            cancelledItemsCancelledTrueElseFalse
                                .add(item['cancelledItemTrueElseFalse']);
                          } else if (item['statusoforder'] == 11) {
                            //meansChefRejectedOrder
                            //basedOnTableOrParcelWePutTorP&AddItToRejectedItems
                            if (item['tableorparcel'] == "Table") {
                              if (item['parentOrChild'] == 'parent') {
                                rejectedItems.add(
                                    'Table-$tableOrParcelNumberAsString: $itemNameAsString');
                              } else {
                                rejectedItems.add(
                                    'Table-$tableOrParcelNumberAsString$parentOrChildAsString: $itemNameAsString');
                              }
                            } else {
                              if (item['parentOrChild'] == 'parent') {
                                rejectedItems.add(
                                    'Parcel-$tableOrParcelNumberAsString: $itemNameAsString');
                              } else {
                                rejectedItems.add(
                                    'Parcel-$tableOrParcelNumberAsString$parentOrChildAsString: $itemNameAsString');
                              }
                            }
//WeAddNumberOfRejectedItems,Id&Status
                            numberOfRejectedItems.add(item['number']);
                            rejectedItemsID.add(item['eachiteminorderid']);
                            rejectedItemsStatus.add(item['statusoforder']);
                            rejectedItemsBelongsToDoc
                                .add(item['itemBelongsToDoc']);
                            rejectedEntireItemListBeforeSplitting
                                .add(item['entireItemListBeforeSplitting']);
                            rejectedEachItemFromEntireItemsString
                                .add(item['eachItemFromEntireItemsString']);
                            rejectedItemsComments
                                .add(item['commentsForTheItem']);
                            rejectedItemsCancelledTrueElseFalse
                                .add(item['cancelledItemTrueElseFalse']);
                          } else if (item['statusoforder'] < 7 ||
                              item['statusoforder'] == 10) {
                            //thisMeansEitherItemReadyOrPickedUp
                            //BasedOnTable/parcel,WeAdded T/P toReadyItemsList

                            if (item['tableorparcel'] == "Table") {
                              if (item['parentOrChild'] == 'parent') {
                                readyItems.add(
                                    'Table-$tableOrParcelNumberAsString: $itemNameAsString');
                              } else {
                                readyItems.add(
                                    'Table-$tableOrParcelNumberAsString$parentOrChildAsString: $itemNameAsString');
                              }
                            } else {
                              if (item['parentOrChild'] == 'parent') {
                                readyItems.add(
                                    'Parcel-$tableOrParcelNumberAsString: $itemNameAsString');
                              } else {
                                readyItems.add(
                                    'Parcel-$tableOrParcelNumberAsString$parentOrChildAsString: $itemNameAsString');
                              }
                            }
                            //WeAddNumber,id&StatusToTheAppropriateLists
                            numberOfReadyItems.add(item['number']);
                            readyItemsID.add(item['eachiteminorderid']);
                            readyItemsStatus.add(item['statusoforder']);
                            readyItemsBelongsToDoc
                                .add(item['itemBelongsToDoc']);
                            readyEntireItemListBeforeSplitting
                                .add(item['entireItemListBeforeSplitting']);
                            readyEachItemFromEntireItemsString
                                .add(item['eachItemFromEntireItemsString']);
                            readyItemsComments.add(item['commentsForTheItem']);
                            readyItemsCancelledTrueElseFalse
                                .add(item['cancelledItemTrueElseFalse']);
                          } else if (item['statusoforder'] == 7) {
//IfItemsAreAccepted,WeAddItToAcceptedItemsListWith T/P basedOn Table/Parcel
                            if (item['tableorparcel'] == "Table") {
                              if (item['parentOrChild'] == "parent") {
                                acceptedItems.add(
                                    'Table-$tableOrParcelNumberAsString: $itemNameAsString');
                              } else {
                                acceptedItems.add(
                                    'Table-$tableOrParcelNumberAsString$parentOrChildAsString: $itemNameAsString');
                              }
                            } else {
                              if (item['parentOrChild'] == "parent") {
                                acceptedItems.add(
                                    'Parcel-$tableOrParcelNumberAsString: $itemNameAsString');
                              } else {
                                acceptedItems.add(
                                    'Parcel-$tableOrParcelNumberAsString$parentOrChildAsString: $itemNameAsString');
                              }
                            }
                            //ThenWeAdd Number,ID and Status
                            numberOfAcceptedItems.add(item['number']);
                            acceptedItemsID.add(item['eachiteminorderid']);
                            acceptedItemsStatus.add(item['statusoforder']);
                            acceptedItemsBelongsToDoc
                                .add(item['itemBelongsToDoc']);
                            acceptedEntireItemListBeforeSplitting
                                .add(item['entireItemListBeforeSplitting']);
                            acceptedEachItemFromEntireItemsString
                                .add(item['eachItemFromEntireItemsString']);
                            acceptedItemsComments
                                .add(item['commentsForTheItem']);
                            acceptedItemsCancelledTrueElseFalse
                                .add(item['cancelledItemTrueElseFalse']);
                          } else {
//AnyOtherStatusWillBeNewlyOrderedItems.WeAdd T/P according to Table/Parcel
                            if (item['tableorparcel'] == "Table") {
                              if (item['parentOrChild'] == 'parent') {
                                orderedItems.add(
                                    'Table-$tableOrParcelNumberAsString: $itemNameAsString');
                              } else {
                                orderedItems.add(
                                    'Table-$tableOrParcelNumberAsString$parentOrChildAsString: $itemNameAsString');
                              }
                            } else {
                              if (item['parentOrChild'] == 'parent') {
                                orderedItems.add(
                                    'Parcel-$tableOrParcelNumberAsString: $itemNameAsString');
                              } else {
                                orderedItems.add(
                                    'Parcel-$tableOrParcelNumberAsString$parentOrChildAsString: $itemNameAsString');
                              }
                            }
//ThenWeAdd Number,id,status
                            numberOfOrderedItems.add(item['number']);
                            allItemsID.add(item['eachiteminorderid']);
                            allItemsStatus.add(item['statusoforder']);
                            allItemsBelongsToDoc.add(item['itemBelongsToDoc']);
                            allItemsEntireItemListBeforeSplitting
                                .add(item['entireItemListBeforeSplitting']);
                            allItemsEachItemFromEntireItemsString
                                .add(item['eachItemFromEntireItemsString']);
                            allItemsComments.add(item['commentsForTheItem']);
                            allItemsCancelledTrueElseFalse
                                .add(item['cancelledItemTrueElseFalse']);
                          }
                        }
                      }
                      //WeWantTheChefScreenToHaveItemsInParticularOrder
//1NewOrders  2AcceptedItems 3Ready/PickedUpItems 4RejectedItems
//SoBelowWeAddStuffInTheParticularOrder
//WeUse "OrderedItems" AsTheMasterListOfItems
//"NumberOfOrderedItems" IsTheMasterListOfNumberOfItems
// "AllItemsId" and "AllItemsStatus" AsTheMasterListOf Id and Status

//InsertingCancelledItemsInThisListEndSoThatItWillShowAtTheStartOfThePage

                      orderedItems.addAll(cancelledItems);
                      numberOfOrderedItems.addAll(numberOfCancelledItems);
                      allItemsID.addAll(cancelledItemsID);
                      allItemsStatus.addAll(cancelledItemsStatus);
                      allItemsBelongsToDoc.addAll(cancelledItemsBelongsToDoc);
                      allItemsEachItemFromEntireItemsString
                          .addAll(cancelledEachItemFromEntireItemsString);
                      allItemsEntireItemListBeforeSplitting
                          .addAll(cancelledEntireItemListBeforeSplitting);
                      allItemsComments.addAll(cancelledItemsComments);
                      allItemsCancelledTrueElseFalse
                          .addAll(cancelledItemsCancelledTrueElseFalse);

//InsertingAcceptedItemsHereBecauseWeWantItToShowAfterNewItems
                      orderedItems.insertAll(0, acceptedItems);
                      numberOfOrderedItems.insertAll(0, numberOfAcceptedItems);
                      allItemsID.insertAll(0, acceptedItemsID);
                      allItemsStatus.insertAll(0, acceptedItemsStatus);
                      allItemsBelongsToDoc.insertAll(
                          0, acceptedItemsBelongsToDoc);
                      allItemsEachItemFromEntireItemsString.insertAll(
                          0, acceptedEachItemFromEntireItemsString);
                      allItemsEntireItemListBeforeSplitting.insertAll(
                          0, acceptedEntireItemListBeforeSplitting);
                      allItemsComments.insertAll(0, acceptedItemsComments);
                      allItemsCancelledTrueElseFalse.insertAll(
                          0, acceptedItemsCancelledTrueElseFalse);

                      orderedItems.insertAll(0, readyItems);
                      numberOfOrderedItems.insertAll(0, numberOfReadyItems);
                      allItemsID.insertAll(0, readyItemsID);
                      allItemsStatus.insertAll(0, readyItemsStatus);
                      allItemsBelongsToDoc.insertAll(0, readyItemsBelongsToDoc);
                      allItemsEachItemFromEntireItemsString.insertAll(
                          0, readyEachItemFromEntireItemsString);
                      allItemsEntireItemListBeforeSplitting.insertAll(
                          0, readyEntireItemListBeforeSplitting);
                      allItemsComments.insertAll(0, readyItemsComments);
                      allItemsCancelledTrueElseFalse.insertAll(
                          0, readyItemsCancelledTrueElseFalse);

                      orderedItems.insertAll(0, rejectedItems);
                      numberOfOrderedItems.insertAll(0, numberOfRejectedItems);
                      allItemsID.insertAll(0, rejectedItemsID);
                      allItemsStatus.insertAll(0, rejectedItemsStatus);
                      allItemsBelongsToDoc.insertAll(
                          0, rejectedItemsBelongsToDoc);
                      allItemsEachItemFromEntireItemsString.insertAll(
                          0, rejectedEachItemFromEntireItemsString);
                      allItemsEntireItemListBeforeSplitting.insertAll(
                          0, rejectedEntireItemListBeforeSplitting);
                      allItemsComments.insertAll(0, rejectedItemsComments);
                      allItemsCancelledTrueElseFalse.insertAll(
                          0, rejectedItemsCancelledTrueElseFalse);

                      return orderedItems.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(top: 200.0),
                              child: const Center(
                                  child: Text(
                                'No Items For you',
                                style: TextStyle(fontSize: 30),
                              )),
                            )
//ifItemsAreThere-WeGoForThisListViewBuilderEnclosedInAnExpanded
//WeArePuttingInsideSlidable-FlutterPackageFromNet
//ThisWillHelpToMoveMoveListTileToLeftOrRightAndGetAnOptionThere
//WeHaveTheSlidableAutoCloseBehaviourToEnsureIfOneSlidableIsPulledInADirection
//ThenIfAnyOtherSlidableIsOpen,ItWillAutomaticallyClose
                          : Expanded(
                              child: SlidableAutoCloseBehavior(
                                closeWhenOpened: true,
                                child: ListView.builder(
//TheBelowItemsAreTheInputForTheListTile
                                  itemCount: orderedItems.length,
                                  itemBuilder: (context, index) {
                                    final orderedItem = orderedItems[
                                        orderedItems.length - index - 1];
                                    final numberOfOrderedItem =
                                        numberOfOrderedItems[
                                            orderedItems.length - index - 1];
                                    final itemID = allItemsID[
                                        orderedItems.length - index - 1];
                                    final statusOfOrderedItem = allItemsStatus[
                                        orderedItems.length - index - 1];
                                    final itemBelongsToDoc =
                                        allItemsBelongsToDoc[
                                            orderedItems.length - index - 1];
                                    final entireItemListBeforeSplitting =
                                        allItemsEntireItemListBeforeSplitting[
                                            orderedItems.length - index - 1];
                                    final eachItemFromEntireItemsString =
                                        allItemsEachItemFromEntireItemsString[
                                            orderedItems.length - index - 1];
                                    final allItemComment = allItemsComments[
                                        orderedItems.length - index - 1];
                                    final itemCancelledTrueElseFalse =
                                        allItemsCancelledTrueElseFalse[
                                            orderedItems.length - index - 1];

//ToEnsureTheItemsThatCameFirstAreAlwaysShownFirst
                                    return Slidable(
                                        //InSlidable-StartActionPaneIsToSlideAndGetOptionsInTheLeft
                                        //ThereAreDifferentAnimationsInScrolling-WeUseScrollMotion
                                        endActionPane: ActionPane(
                                          motion: const ScrollMotion(),
                                          children: [
                                            SlidableAction(
//WhateverBeIt,IfAnyOptionIsPressed,PlayerNeedsToBeStopped
//AndPlayerPlayingShouldBeFalse
                                              onPressed:
                                                  (BuildContext context) {
                                                player.stop();
                                                playerState =
                                                    PlayerState.stopped;
                                                playerPlaying = false;
//WeDontKeepAnythingForCancelledItemInStartActionPane
                                                //ifNewItem-SayingOrderIsAcceptedAndUpdatingStatusInFireStore
                                                // if(cancelledItemsKey.contains(itemID)){
                                                //
                                                // }
                                                //  else
                                                if (!cancelledItemsKey
                                                        .contains(itemID) &&
                                                    statusOfOrderedItem == 9) {
                                                  statusUpdaterInFireStore(
                                                      eachItemFromEntireItemsString,
                                                      entireItemListBeforeSplitting,
                                                      itemBelongsToDoc,
                                                      '7');
                                                  // FireStoreUpdateStatusOfCurrentOrder(
                                                  //         hotelName: widget
                                                  //             .hotelName,
                                                  //         itemID: itemID,
                                                  //         statusOfOrder: 7)
                                                  //     .updateStatus();
                                                } else if (!cancelledItemsKey
                                                        .contains(itemID) &&
                                                    statusOfOrderedItem == 7) {
//sayingOrderIsReadyIfAlreadyAcceptedAndUpdatingStatusInFireStore
                                                  statusUpdaterInFireStore(
                                                      eachItemFromEntireItemsString,
                                                      entireItemListBeforeSplitting,
                                                      itemBelongsToDoc,
                                                      '10');
//ThisIsTheListWhereWeWillTakeListOfAllItemsInTheReadyParcel
                                                  List<String>
                                                      parcelReadyItemNames = [];
                                                  List<num>
                                                      parcelReadyNumberOfItems =
                                                      [];
                                                  List<String>
                                                      parcelReadyItemComments =
                                                      [];
//ThisBoolWillHelpToUnderstandWhetherAllItemsInParcelAreReadyOrNot
                                                  bool allItemsInParcelReady =
                                                      true;

                                                  if (orderedItem
                                                      .startsWith('P')) {
                                                    final parcelCheckItemNameSplit =
                                                        orderedItem.split(':');

//IfSomethingIsParcelThenWeAddTheItemThatIsReadiedFirstIntoTheList
                                                    parcelReadyItemNames.add(
                                                        parcelCheckItemNameSplit[
                                                            1]);
                                                    parcelReadyNumberOfItems.add(
                                                        numberOfOrderedItem);
                                                    parcelReadyItemComments
                                                        .add(allItemComment);
//HereWeTakeTheParcelNumberOfTheItemThatHasBeenReadiedNowFromTheOrderedItemString

                                                    String
                                                        parcelNumberFromOrderedItem =
                                                        orderedItem[1];
//WeGoThroughTheEntireListToCheckWhetherAllItemsInThatParcelAreReady
                                                    for (int i = 0;
                                                        i < orderedItems.length;
                                                        i++) {
//ToEnsureCancelledItemsAreNotIncludedInTheParcelPrintList
//AndAlsoEnsureTheItemsTheCookRejectedAreNotPartOfTheList
                                                      if (!cancelledItemsKey
                                                              .contains(
                                                                  allItemsID[
                                                                      i]) &&
                                                          allItemsStatus[i] !=
                                                              11) {
                                                        //IfLoopToCheckWhetherTheCurrentItemInForLoopBelongsToThatParcel
                                                        final itemToBeCheckedItemNameSplit =
                                                            orderedItems[i]
                                                                .split(':');
//WeCheckWhetherItIsParcel,WhetherItIsntTheItemThatHasJustNowGotReady
//AndFinallyWhetherTheParcelNumbersAreSame
                                                        if (orderedItems[i]
                                                                    .startsWith(
                                                                        'P') &&
                                                                allItemsID[i] !=
                                                                    itemID &&
                                                                itemToBeCheckedItemNameSplit[
                                                                        0] ==
                                                                    parcelCheckItemNameSplit[
                                                                        0]
                                                            // &&
                                                            //     orderedItems[i]
                                                            //             [1] ==
                                                            //         parcelNumberFromOrderedItem
                                                            ) {
//IfAnItemInParcelIsNotReady,WeChangeTheBoolToFalse-10-Ready,,,3-Delivered
                                                          if ((allItemsStatus[
                                                                      i] !=
                                                                  10 &&
                                                              allItemsStatus[
                                                                      i] !=
                                                                  3)) {
                                                            allItemsInParcelReady =
                                                                false;
                                                          } else {
//ElseIfItIsReady,WeAddItToTheListTheNameAndTheNumber
                                                            parcelReadyItemNames
                                                                .add(
                                                                    itemToBeCheckedItemNameSplit[
                                                                        1]);
                                                            parcelReadyNumberOfItems
                                                                .add(
                                                                    numberOfOrderedItems[
                                                                        i]);
                                                            parcelReadyItemComments
                                                                .add(
                                                                    allItemsComments[
                                                                        i]);
                                                          }
                                                        }
                                                      }
                                                    }
//IfAllItemsInParcelReady,,,WeWantTheBottomSheetToPrint
                                                    if (allItemsInParcelReady) {
                                                      bluetoothStateChangeFunction();
                                                      if (chefPrinterAfterOrderReadyPrintFromClass) {
                                                        showModalBottomSheet(
                                                            context: context,
                                                            builder: (context) {
//WeCheckTheBluetoothStateToCheckWhetherOrNotTheBluetoothIsOn
//IfBluetoothIsOff-MostlyTheStateIs10
                                                              int bluetoothOnOrOffState =
                                                                  11;
//ThisIsSimplyCommented-ChangeItInFuture
//                                                                 bluetoothPrint
//                                                                     .state
//                                                                     .listen(
//                                                                         (state) {
//                                                                   bluetoothOnOrOffState =
//                                                                       state;
//                                                                 });
//WeCallForTheBottomSheetWith Names,NoOfItems, parcelNumber
//HowWeGetParcelNumberIsWeTakeWhatHasBeenSplitBefore :
//ThenInsteadOf P InParcel,WeUseReplaceRangeToChangeItToEmptyString
                                                              return buildBottomSheetForParcelPrint(
                                                                  context,
                                                                  parcelReadyItemNames,
                                                                  parcelReadyNumberOfItems,
                                                                  parcelReadyItemComments,
                                                                  parcelCheckItemNameSplit[
                                                                      0]);
                                                            });
                                                      } else {
                                                        parcelReadyItemNames =
                                                            [];
                                                        parcelReadyNumberOfItems =
                                                            [];
                                                        parcelReadyItemComments =
                                                            [];
                                                      }

//ModalButton
                                                    } else {
//ElseNotReady,WeClearTheList
                                                      parcelReadyItemNames = [];
                                                      parcelReadyNumberOfItems =
                                                          [];
                                                      parcelReadyItemComments =
                                                          [];
                                                    }
                                                  }
                                                }
                                              },
                                              //BackGroundColorOfButtonBehindSlidableIsBasedOnStatusOfItem
                                              //IfNewOrder-GreenButtonForAcceptingOrder
                                              //If 11-Rejected 10-OrderReady Or 3-OrderPickedUp-ColorWhite
                                              //Else- ifAnythingElse(Mostly Only AcceptedOrder)-ItWillBeGreenOnly
                                              backgroundColor: cancelledItemsKey
                                                      .contains(itemID)
                                                  ? Colors.white
                                                  : statusOfOrderedItem == 9
                                                      ? Colors.green.shade300
                                                      : (statusOfOrderedItem ==
                                                                  11 ||
                                                              statusOfOrderedItem ==
                                                                  10 ||
                                                              statusOfOrderedItem ==
                                                                  3)
                                                          ? Colors.white
                                                          : Colors
                                                              .green.shade300,

                                              //ToShowAsPerStatus-AddIcon/ReadyIcon/Null
                                              icon: cancelledItemsKey
                                                      .contains(itemID)
                                                  ? null
                                                  : statusOfOrderedItem == 9
                                                      ? Icons.add
                                                      : (statusOfOrderedItem ==
                                                                  11 ||
                                                              statusOfOrderedItem ==
                                                                  10 ||
                                                              statusOfOrderedItem ==
                                                                  3)
                                                          ? null
                                                          : const IconData(
                                                              0xe770,
                                                              fontFamily:
                                                                  'MaterialIcons'),
                                              //LabelAsPerStatus- NewOrderMeansAcceptAsLabel
                                              //ifRejectedOrReadyOrPickedUp- NoLabel
                                              //ifNoneOfThis-ItMeansTheAlreadyAcceptedItemIsReady-So Ready as label
                                              label: cancelledItemsKey
                                                      .contains(itemID)
                                                  ? ' '
                                                  : statusOfOrderedItem == 9
                                                      ? 'Accept'
                                                      : (statusOfOrderedItem ==
                                                                  11 ||
                                                              statusOfOrderedItem ==
                                                                  10 ||
                                                              statusOfOrderedItem ==
                                                                  3)
                                                          ? ' '
                                                          : 'Ready',
                                            )
                                          ],
                                        ),
//EndActionPaneIsForRightSideButtons
//NoMatterWhatIfAnythingIsPressed,PlayerNeedsToStop
                                        startActionPane: ActionPane(
                                          motion: const ScrollMotion(),
                                          children: [
                                            SlidableAction(
                                              onPressed:
                                                  (BuildContext context) {
                                                player.stop();
                                                playerState =
                                                    PlayerState.stopped;
                                                playerPlaying = false;
//FirstWeCheckWhetherItIsCancelledItemMeantForDelete
                                                if (cancelledItemsKey
                                                    .contains(itemID)) {
                                                  if (cancelledItemsKey
                                                          .length ==
                                                      1) {
//ThisMeansOnlyThisParticularItemIsCancelled
//WeCanGoOnToDeleteTheCancelledDocumentItself
                                                    FireStoreDeleteFinishedOrderInPresentOrders(
                                                            hotelName: widget
                                                                .hotelName,
                                                            eachItemId:
                                                                itemBelongsToDoc)
                                                        .deleteFinishedOrder();
                                                    cancelledItemsKey
                                                        .remove(itemID);
                                                  } else {
//IfThereAreMoreItemsInCancelledList,WeShouldEnsureOnlyThatParticularItemFieldIsDeletedInServer
                                                    FireStoreClearCancelledItemFromPresentOrders(
                                                            hotelName: widget
                                                                .hotelName,
                                                            cancelledItemId:
                                                                itemID,
                                                            cancelledItemsDoc:
                                                                itemBelongsToDoc)
                                                        .deleteCancelledItem();
                                                    cancelledItemsKey
                                                        .remove(itemID);
                                                  }
                                                } else if (statusOfOrderedItem ==
                                                        9 ||
                                                    statusOfOrderedItem == 7) {
//IfNewOrderOrAlsoAnAcceptedOrder-WeGiveOptionToRejectItByUpdatingStatusInFireStore
                                                  //sayingOrderIsRejected
                                                  statusUpdaterInFireStore(
                                                      eachItemFromEntireItemsString,
                                                      entireItemListBeforeSplitting,
                                                      itemBelongsToDoc,
                                                      '11');
                                                }
//                                                 else if (statusOfOrderedItem ==
//                                                     7) {
//                                                   statusUpdaterInFireStore(
//                                                       eachItemFromEntireItemsString,
//                                                       entireItemListBeforeSplitting,
//                                                       itemBelongsToDoc,
//                                                       '10');
// //sayingOrderIsReadyIfAlreadyAcceptedAndUpdatingStatusInFireStore
// //                                                     FireStoreUpdateStatusOfCurrentOrder(
// //                                                             hotelName: widget
// //                                                                 .hotelName,
// //                                                             itemID: itemID,
// //                                                             statusOfOrder: 10)
// //                                                         .updateStatus();
// //ThisIsTheListWhereWeWillTakeListOfAllItemsInTheReadyParcel
//                                                   List<String>
//                                                       parcelReadyItemNames = [];
//                                                   List<num>
//                                                       parcelReadyNumberOfItems =
//                                                       [];
//                                                   List<String>
//                                                       parcelReadyItemComments =
//                                                       [];
// //ThisBoolWillHelpToUnderstandWhetherAllItemsInParcelAreReadyOrNot
//                                                   bool allItemsInParcelReady =
//                                                       true;
//
//                                                   if (orderedItem
//                                                       .startsWith('P')) {
//                                                     final parcelCheckItemNameSplit =
//                                                         orderedItem.split(':');
//                                                     // localParcelNumber =
//                                                     //     'P${parcelCheckItemNameSplit[0].toString()}';
//                                                     // ;
//
// //IfSomethingIsParcelThenWeAddTheItemThatIsReadiedFirstIntoTheList
//                                                     parcelReadyItemNames.add(
//                                                         parcelCheckItemNameSplit[
//                                                             1]);
//                                                     parcelReadyNumberOfItems.add(
//                                                         numberOfOrderedItem);
//                                                     parcelReadyItemComments
//                                                         .add(allItemComment);
// //HereWeTakeTheParcelNumberOfTheItemThatHasBeenReadiedNowFromTheOrderedItemString
//
//                                                     String
//                                                         parcelNumberFromOrderedItem =
//                                                         orderedItem[1];
// //WeGoThroughTheEntireListToCheckWhetherAllItemsInThatParcelAreReady
//                                                     for (int i = 0;
//                                                         i < orderedItems.length;
//                                                         i++) {
// //IfLoopToCheckWhetherTheCurrentItemInForLoopBelongsToThatParcel
//                                                       final itemToBeCheckedItemNameSplit =
//                                                           orderedItems[i]
//                                                               .split(':');
//
//                                                       if (orderedItems[i]
//                                                                   .startsWith(
//                                                                       'P') &&
//                                                               allItemsID[i] !=
//                                                                   itemID &&
//                                                               itemToBeCheckedItemNameSplit[
//                                                                       0] ==
//                                                                   parcelCheckItemNameSplit[
//                                                                       0]
//                                                           // &&
//                                                           //     orderedItems[i]
//                                                           //             [1] ==
//                                                           //         parcelNumberFromOrderedItem
//                                                           ) {
// //IfAnItemInParcelIsNotReady,WeChangeTheBoolToFalse-10-Ready,,,3-Delivered
//                                                         if ((allItemsStatus[
//                                                                     i] !=
//                                                                 10 &&
//                                                             allItemsStatus[i] !=
//                                                                 3)) {
//                                                           allItemsInParcelReady =
//                                                               false;
//                                                         } else {
// //ElseIfItIsReady,WeAddItToTheListTheNameAndTheNumber
//                                                           parcelReadyItemNames.add(
//                                                               itemToBeCheckedItemNameSplit[
//                                                                   1]);
//                                                           parcelReadyNumberOfItems
//                                                               .add(
//                                                                   numberOfOrderedItems[
//                                                                       i]);
//                                                           parcelReadyItemComments
//                                                               .add(
//                                                                   allItemsComments[
//                                                                       i]);
//                                                         }
//                                                       }
//                                                     }
// //IfAllItemsInParcelReady,,,WeNeedBottomButtonToPrint-ExplanationSameAsLastOne
//                                                     if (allItemsInParcelReady) {
//                                                       int bluetoothOnOrOffState =
//                                                           11;
// //ThisIsSimplyCommented-ChangeItInFuture
// //                                                           bluetoothPrint.state
// //                                                               .listen((state) {
// //                                                             bluetoothOnOrOffState =
// //                                                                 state;
// //                                                           });
//                                                       bluetoothStateChangeFunction();
//                                                       if (chefPrinterAfterOrderReadyPrintFromClass) {
//                                                         showModalBottomSheet(
//                                                             context: context,
//                                                             builder: (context) {
//                                                               return buildBottomSheetForParcelPrint(
//                                                                   context,
//                                                                   parcelReadyItemNames,
//                                                                   parcelReadyNumberOfItems,
//                                                                   parcelReadyItemComments,
//                                                                   parcelCheckItemNameSplit[
//                                                                       0]);
//                                                             });
//                                                       } else {
//                                                         parcelReadyItemNames =
//                                                             [];
//                                                         parcelReadyNumberOfItems =
//                                                             [];
//                                                         parcelReadyItemComments =
//                                                             [];
//                                                       }
//
// //ModalButton
//                                                     } else {
// //ElseNotReady,WeClearTheList
//                                                       parcelReadyItemNames = [];
//                                                       parcelReadyNumberOfItems =
//                                                           [];
//                                                       parcelReadyItemComments =
//                                                           [];
//                                                     }
//                                                   }
//                                                 }
                                              },
                                              //BackGroundColorOfButtonBehindSlidableIsBasedOnStatusOfItem
                                              //IfNewOrder-RedButtonForRejectingOrder
                                              //If 11-Rejected 10-OrderReady Or 3-OrderPickedUp-ColorWhite
                                              //Else- ifAnythingElse(Mostly Only AcceptedOrder)-ItWillBeGreenOnly
                                              backgroundColor: (statusOfOrderedItem ==
                                                          7 ||
                                                      statusOfOrderedItem ==
                                                          9 ||
                                                      cancelledItemsKey
                                                          .contains(itemID))
                                                  ? Colors.red.shade300
                                                  :
                                                  // (statusOfOrderedItem ==
                                                  //                 11 ||
                                                  //             statusOfOrderedItem ==
                                                  //                 10 ||
                                                  //             statusOfOrderedItem ==
                                                  //                 3)
                                                  //         ?
                                                  Colors.white,
//RemovingReadyInTheRightSide
//                                                       : Colors.green.shade300,
                                              //ToShowAsPerStatus-AddIcon/Null/ReadyIcon
                                              icon: (statusOfOrderedItem == 7 ||
                                                      statusOfOrderedItem ==
                                                          9 ||
                                                      cancelledItemsKey
                                                          .contains(itemID))
                                                  ? Icons.close
                                                  :
                                                  // (statusOfOrderedItem ==
                                                  //                 11 ||
                                                  //             statusOfOrderedItem ==
                                                  //                 10 ||
                                                  //             statusOfOrderedItem ==
                                                  //                 3)
                                                  //         ?
                                                  null
//RemovingReadyInTheRightSide
                                              // : const IconData(0xe770,
                                              //     fontFamily:
                                              //         'MaterialIcons')
                                              ,
                                              //NewOrderMeans-RejectLabel, ifAlreadyRejected/Ready/PickedUp-NoLabel
                                              //ifAcceptedOrder-ReadyAsLabel
                                              label: cancelledItemsKey
                                                      .contains(itemID)
                                                  ? 'Remove'
                                                  : (statusOfOrderedItem == 7 ||
                                                          statusOfOrderedItem ==
                                                              9)
                                                      ? 'Reject'
                                                      :
                                                      // (statusOfOrderedItem ==
                                                      //                 11 ||
                                                      //             statusOfOrderedItem ==
                                                      //                 10 ||
                                                      //             statusOfOrderedItem ==
                                                      //                 3)
                                                      //         ?
                                                      ' ',
//RemovingReadyInTheRightSide
                                              // : 'Ready'
                                            )
                                          ],
                                        ),
                                        //ChildWillBeListTile-WhoseInputWillBe Item,Number,Status(ForColorOfListTile)
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color:
                                                // cancelledItemsKey
                                                //         .contains(itemID)
                                                //     ? Colors.red
                                                //     :
                                                itemCancelledTrueElseFalse ==
                                                        'acceptedToDelete'
                                                    ? Colors.orangeAccent
                                                    : itemCancelledTrueElseFalse ==
                                                            'readyToDelete'
                                                        ? Colors.green
                                                        : statusOfOrderedItem <
                                                                    5 ||
                                                                statusOfOrderedItem ==
                                                                    10
                                                            ? Colors.green
                                                            : statusOfOrderedItem ==
                                                                    11
                                                                ? Colors.red
                                                                : statusOfOrderedItem ==
                                                                        7
                                                                    ? Colors
                                                                        .orangeAccent
                                                                    : null,
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            border: Border.all(
                                              color: Colors.black87,
                                              width: 1.0,
                                            ),
                                          ),
//inListTile-LeftSideWillBeItemName&RightSideWillBeNumber
                                          child: ListTile(
                                            onLongPress: () {
//ToEnsureIfAnItemIsCancelled,WeDoNotGiveLongPressPrintOptions
                                              if (!cancelledItemsKey
                                                      .contains(itemID) &&
                                                  statusOfOrderedItem != 11) {
                                                bluetoothStateChangeFunction();
                                                final orderedItemNameSplit =
                                                    orderedItem.split(':');

                                                localParcelReadyItemNames = [];
                                                localParcelReadyNumberOfItems =
                                                    [];
                                                localParcelReadyItemComments =
                                                    [];

                                                localParcelNumber = '';
                                                localParcelNumber =
                                                    orderedItemNameSplit[0]
                                                        .toString();
                                                localParcelReadyItemNames.add(
                                                    orderedItemNameSplit[1]
                                                        .toString());
                                                localParcelReadyNumberOfItems
                                                    .add(numberOfOrderedItem);
                                                localParcelReadyItemComments
                                                    .add(allItemComment);
                                                for (int i = 0;
                                                    i < orderedItems.length;
                                                    i++) {
//ToEnsureCancelledItemsDoNotBecomePartOfTheGroup
                                                  if (!cancelledItemsKey
                                                          .contains(
                                                              allItemsID[i]) &&
                                                      allItemsStatus[i] != 11) {
                                                    final itemToBeCheckedItemNameSplit =
                                                        orderedItems[i]
                                                            .split(':');
                                                    if ((allItemsID[i] !=
                                                            itemID) &&
                                                        (itemToBeCheckedItemNameSplit[
                                                                0] ==
                                                            orderedItemNameSplit[
                                                                0])) {
//WeAreAddingThatTableOrParcelItemsToTheLocalList
                                                      localParcelReadyItemNames.add(
                                                          itemToBeCheckedItemNameSplit[
                                                                  1]
                                                              .toString());
                                                      localParcelReadyNumberOfItems
                                                          .add(
                                                              numberOfOrderedItems[
                                                                  i]);
                                                      localParcelReadyItemComments
                                                          .add(allItemsComments[
                                                              i]);
                                                    }
                                                  }
                                                }

                                                int bluetoothOnTrueOrOffFalseState =
                                                    11;
//ThisIsSimplyCommented-ChangeItInFuture
                                                // bluetoothPrint.state.listen((state) {
                                                //   bluetoothOnTrueOrOffFalseState = state;
                                                // });
                                                if (localParcelReadyItemNames
                                                        .length ==
                                                    1) {
                                                  showModalBottomSheet(
                                                      context: context,
                                                      builder: (context) {
                                                        return buildBottomSheetForParcelPrint(
                                                            context,
                                                            localParcelReadyItemNames,
                                                            localParcelReadyNumberOfItems,
                                                            localParcelReadyItemComments,
                                                            localParcelNumber);
                                                      });
                                                } else {
                                                  showModalBottomSheet(
                                                      context: context,
                                                      builder: (context) {
                                                        return buildBottomSheetForLongPressPrint(
                                                            context,
                                                            localParcelReadyItemNames,
                                                            localParcelReadyNumberOfItems,
                                                            localParcelReadyItemComments,
                                                            localParcelNumber);
                                                      });
                                                }
                                              }
                                            },
                                            title: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  child: Text(
                                                      orderedItem.split(':')[0],
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .headline6),
                                                  decoration: BoxDecoration(
                                                    color: orderedItem.split(
                                                                ':')[0][0] ==
                                                            'P'
                                                        ? Colors.yellow.shade600
                                                        : null,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5),
                                                    border: Border.all(
                                                      color: Colors.black87,
                                                      width: 1.0,
                                                    ),
                                                  ),
                                                ),
                                                Text(orderedItem.split(':')[1],
                                                    style: cancelledItemsKey
                                                            .contains(itemID)
                                                        ? TextStyle(
                                                            decoration:
                                                                TextDecoration
                                                                    .lineThrough,
                                                            fontSize: 28.0,
                                                            color: Colors.red)
                                                        : TextStyle(
                                                            fontSize: 28.0)),
                                              ],
                                            ),
                                            trailing: Text(
                                                numberOfOrderedItem.toString(),
                                                style: cancelledItemsKey
                                                        .contains(itemID)
                                                    ? TextStyle(
                                                        decoration:
                                                            TextDecoration
                                                                .lineThrough,
                                                        fontSize: 35.0,
                                                        color: Colors.red)
                                                    : Theme.of(context)
                                                        .textTheme
                                                        .headline5),
                                            subtitle: (cancelledItemsKey
                                                        .contains(itemID) &&
                                                    allItemComment ==
                                                        'nocomments')
                                                ? Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      Container(
                                                          child: Text(
                                                              'Cancelled',
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      35.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .red))),
                                                    ],
                                                  )
                                                : (cancelledItemsKey
                                                            .contains(itemID) &&
                                                        allItemComment !=
                                                            'nocomments')
                                                    ? Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            allItemComment,
                                                            style: TextStyle(
                                                                fontSize: 23.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: Colors
                                                                    .black),
                                                          ),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .end,
                                                            children: [
                                                              Text('Cancelled',
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          28.0,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Colors
                                                                          .red)),
                                                            ],
                                                          ),
                                                        ],
                                                      )
                                                    : allItemComment ==
                                                            'nocomments'
                                                        ? null
                                                        : Text(
                                                            allItemComment,
                                                            style: TextStyle(
                                                                fontSize: 23.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: Colors
                                                                    .black),
                                                          ),
                                            // allItemComment ==
                                            //         'nocomments'
                                            //     ? null
                                            //     : Text(
                                            //         allItemComment,
                                            //         style: TextStyle(
                                            //             fontWeight:
                                            //                 FontWeight.w500,
                                            //             color: Colors.black),
                                            //       ),
                                          ),
                                        ));
                                  },
                                ),
                              ),
                            );
                    } else {
                      return Center(
                        child: Text('Some Error Occured'),
                      );
                    }
//WeCheckWhetherOrderedItemsIsEmpty-yes-return "No items"

                    // }
                    // else {
                    //   return Center(
                    //     child: Text('Some Error Occured'),
                    //   );
                    // }
                  }),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildBottomSheetForParcelPrint(
      BuildContext context,
      List<String> parcelReadyItemNames,
      List<num> parcelReadyNumberOfItems,
      List<String> parcelReadyItemComments,
      String parcelNumber) {
//IfParcelNumberIsThere,WePutParcelItemsAsHeading
//ElseWePut ItemsToPrint
    return Column(
      children: [
        Center(
          child: parcelNumber != ''
              ? Text(
                  'Parcel Items',
                  style: TextStyle(fontSize: 30.0),
                )
              : Text(
                  'Items to Print',
                  style: TextStyle(fontSize: 30.0),
                ),
        ),
//WemakeListViewBuilderWithItemNamesAndNoOfItems
        Expanded(
          child: ListView.builder(
              itemCount: parcelReadyItemNames.length,
              itemBuilder: (context, index) {
                final parcelItem = parcelReadyItemNames[index];
                final parcelNumberOfItems =
                    parcelReadyNumberOfItems[index].toString();
                final parcelItemComment = parcelReadyItemComments[index];
                return ListTile(
                  title: Text(parcelItem,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text(parcelNumberOfItems,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                );
              }),
        ),
//BottomWeGiveTwoOptions
//closeWillSimplyCloseTheBottomSheetWithoutPrinting
        Row(
          children: [
            SizedBox(width: 10),
            Expanded(
              //width: 300.0,
              child: TextButton.icon(
                icon: Icon(Icons.close),
                label: Text(
                  'Close',
                ),
                style: TextButton.styleFrom(
                    primary: Colors.white,
                    backgroundColor: kBottomContainerColour),
                onPressed: () async {
                  //WeDontNeedToPrint.SoJustPoppingBottomSheet
                  Navigator.pop(context);
//PoppingItTwiceSoThatWeStraightAwayGoToTheCaptain'sScreen,AvoidingTheItemsEachTableScreen
                },
              ),
            ),
            SizedBox(width: 10),
//IfBluetoothStateIdOff-LessThan10 And Not 1
//WePutTheButtonNameAs "TurnBluetoothOnToPrint
//ElseWeJustSayPrint
            Provider.of<PrinterAndOtherDetailsProvider>(context)
                        .chefPrinterAddressFromClass ==
                    ''
                ? Expanded(
                    // width: 300.0,
                    child: TextButton.icon(
                      icon: Icon(Icons.print),
                      label: bluetoothOnTrueOrOffFalse
                          ? Text(
                              'Add Printer',
                            )
                          : Text(
                              'Turn Bluetooth On & Add Printer',
                            ),
                      style: TextButton.styleFrom(
                          primary: Colors.white, backgroundColor: Colors.green),
                      onPressed: () async {
                        disconnectAndConnectAttempted = false;
//OnClickingPrint,WeAlwaysCallForTheMethodSavedBluetoothPrinterConnect
//WhichWillInsideItCallForThePrintFunction

                        if (bluetoothOnTrueOrOffFalse) {
                          Navigator.pop(context);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      SearchingConnectingPrinter(
                                          chefOrCaptain: 'Chef')));
                        } else {
                          Navigator.pop(context);
                          if (appInBackground == false) {
                            show('Please Turn On Bluetooth');
                          }
                        }
                      },
                    ),
                  )
                : Expanded(
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
//OnClickingPrint,WeAlwaysCallForTheMethodSavedBluetoothPrinterConnect
//WhichWillInsideItCallForThePrintFunction
                        print('fdfdffddsnfjdnfiyhjrnsdkj');
                        localParcelReadyNumberOfItems =
                            parcelReadyNumberOfItems;
                        localParcelReadyItemNames = parcelReadyItemNames;
                        localParcelReadyItemComments = parcelReadyItemComments;
                        localParcelNumber = parcelNumber;

                        if (bluetoothOnTrueOrOffFalse) {
                          printerConnectionToLastSavedPrinterForAfterOrderPrint();

                          Navigator.pop(context);
                        } else {
                          Navigator.pop(context);
                          if (appInBackground == false) {
                            show('Please Turn On Bluetooth');
                          }
                        }
                      },
                    ),
                  ),
            SizedBox(width: 10),
          ],
        )
      ],
    );
  }

  Widget buildBottomSheetForLongPressPrint(
      BuildContext context,
      List<String> parcelReadyItemNames,
      List<num> parcelReadyNumberOfItems,
      List<String> parcelReadyItemComments,
      String parcelNumber) {
//IfParcelNumberIsThere,WePutParcelItemsAsHeading
//ElseWePut ItemsToPrint
    return Column(
      children: [
        Center(
          child: parcelNumber != ''
              ? Text(
                  'Parcel Items',
                  style: TextStyle(fontSize: 30.0),
                )
              : Text(
                  'Items to Print',
                  style: TextStyle(fontSize: 30.0),
                ),
        ),
//WemakeListViewBuilderWithItemNamesAndNoOfItems
        Expanded(
          child: ListView.builder(
              itemCount: parcelReadyItemNames.length,
              itemBuilder: (context, index) {
                final parcelItem = parcelReadyItemNames[index];
                final parcelNumberOfItems =
                    parcelReadyNumberOfItems[index].toString();
                final parcelComment = parcelReadyItemComments[index];
                return ListTile(
                  title: Text(parcelItem,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Text(parcelNumberOfItems,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                );
              }),
        ),
        Provider.of<PrinterAndOtherDetailsProvider>(context)
                    .chefPrinterAddressFromClass ==
                ''
            ? Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: Container(
                  width: double.infinity,
                  // width: 300.0,
                  child: TextButton.icon(
                    icon: Icon(Icons.print),
                    label: bluetoothOnTrueOrOffFalse
                        ? Text(
                            'Add Printer',
                          )
                        : Text(
                            'Turn On Bluetooth and Add Printer',
                          ),
                    style: TextButton.styleFrom(
                        primary: Colors.white, backgroundColor: Colors.green),
                    onPressed: () async {
//OnClickingPrint,WeAlwaysCallForTheMethodSavedBluetoothPrinterConnect
//WhichWillInsideItCallForThePrintFunction
                      print('fdnfjdnfiyhfdfdfjrnsdkj');

                      if (bluetoothOnTrueOrOffFalse) {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    SearchingConnectingPrinter(
                                        chefOrCaptain: 'Chef')));
                      } else {
                        Navigator.pop(context);
                        if (appInBackground == false) {
                          show('Please Turn On Bluetooth');
                        }
                      }
                    },
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: Container(
                  width: double.infinity,
                  // width: 300.0,
                  child: TextButton.icon(
                    icon: Icon(Icons.print),
                    label: bluetoothOnTrueOrOffFalse
                        ? Text(
                            'Print All',
                          )
                        : Text(
                            'Turn Bluetooth To Print All',
                          ),
                    style: TextButton.styleFrom(
                        primary: Colors.white, backgroundColor: Colors.green),
                    onPressed: () async {
//OnClickingPrint,WeAlwaysCallForTheMethodSavedBluetoothPrinterConnect
//WhichWillInsideItCallForThePrintFunction
                      print('fdnfjdnfiyhfdfdfjrnsdkj');
                      localParcelReadyNumberOfItems = parcelReadyNumberOfItems;
                      localParcelReadyItemNames = parcelReadyItemNames;
                      localParcelReadyItemComments = parcelReadyItemComments;
                      localParcelNumber = parcelNumber;

                      if (bluetoothOnTrueOrOffFalse) {
                        printerConnectionToLastSavedPrinterForAfterOrderPrint();
                        Navigator.pop(context);
                      } else {
                        Navigator.pop(context);
                        if (appInBackground == false) {
                          show('Please Turn On Bluetooth');
                        }
                      }
                    },
                  ),
                ),
              ),
//BottomWeGiveTwoOptions
//closeWillSimplyCloseTheBottomSheetWithoutPrinting
//         Row(
//           children: [
//             SizedBox(width: 10),
//             Expanded(
//               //width: 300.0,
//               child: TextButton.icon(
//                 icon: Icon(Icons.close),
//                 label: Text(
//                   'Close',
//                 ),
//                 style: TextButton.styleFrom(
//                     primary: Colors.white,
//                     backgroundColor: kBottomContainerColour),
//                 onPressed: () async {
//                   //WeDontNeedToPrint.SoJustPoppingBottomSheet
//                   Navigator.pop(context);
// //PoppingItTwiceSoThatWeStraightAwayGoToTheCaptain'sScreen,AvoidingTheItemsEachTableScreen
//                 },
//               ),
//             ),
//             // SizedBox(width: 10),
// //IfBluetoothStateIdOff-LessThan10 And Not 1
// //WePutTheButtonNameAs "TurnBluetoothOnToPrint
// //ElseWeJustSayPrint
//             Expanded(
//               // width: 300.0,
//               child: TextButton.icon(
//                 icon: Icon(Icons.print),
//                 label: bluetoothOnTrueOrOffFalse
//                     ? Text(
//                         'Print All',
//                       )
//                     : Text(
//                         'Turn Bluetooth To Print All',
//                       ),
//                 style: TextButton.styleFrom(
//                     primary: Colors.white, backgroundColor: Colors.green),
//                 onPressed: () async {
// //OnClickingPrint,WeAlwaysCallForTheMethodSavedBluetoothPrinterConnect
// //WhichWillInsideItCallForThePrintFunction

//                   localParcelReadyNumberOfItems = parcelReadyNumberOfItems;
//                   localParcelReadyItemNames = parcelReadyItemNames;
//                   localParcelNumber = parcelNumber;
//
//                   if (connectingPrinterAddressChefScreen != '') {
//                     printerConnectionToLastSavedPrinter();
//                   } else {
//                     getAllPairedDevices();
//                     setState(() {
//                       noNeedPrinterConnectionScreen = false;
//                     });
//                   }
//
//                   Navigator.pop(context);
//                 },
//               ),
//             ),
//             SizedBox(width: 10),
//           ],
//         ),
        Divider(thickness: 6),
        Container(
          child: ListTile(
            title: Text(parcelReadyItemNames[0],
                style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(parcelReadyNumberOfItems[0].toString(),
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        Row(
          children: [
            SizedBox(width: 10),
            Expanded(
              //width: 300.0,
              child: TextButton.icon(
                icon: Icon(Icons.close),
                label: Text(
                  'Close',
                ),
                style: TextButton.styleFrom(
                    primary: Colors.white,
                    backgroundColor: kBottomContainerColour),
                onPressed: () async {
                  //WeDontNeedToPrint.SoJustPoppingBottomSheet
                  Navigator.pop(context);
//PoppingItTwiceSoThatWeStraightAwayGoToTheCaptain'sScreen,AvoidingTheItemsEachTableScreen
                },
              ),
            ),
            SizedBox(width: 10),
//IfBluetoothStateIdOff-LessThan10 And Not 1
//WePutTheButtonNameAs "TurnBluetoothOnToPrint
//ElseWeJustSayPrint
            Provider.of<PrinterAndOtherDetailsProvider>(context)
                        .chefPrinterAddressFromClass ==
                    ''
                ? Expanded(
                    // width: 300.0,
                    child: TextButton.icon(
                      icon: Icon(Icons.print),
                      label: bluetoothOnTrueOrOffFalse
                          ? Text(
                              'Add Printer',
                            )
                          : Text(
                              'Turn Bluetooth On & Add Printer',
                            ),
                      style: TextButton.styleFrom(
                          primary: Colors.white, backgroundColor: Colors.green),
                      onPressed: () async {
//OnClickingPrint,WeAlwaysCallForTheMethodSavedBluetoothPrinterConnect
//WhichWillInsideItCallForThePrintFunction
                        localParcelReadyNumberOfItems = [];
                        localParcelReadyItemNames = [];
                        localParcelReadyItemComments = [];
                        print('fdnfjdnfiyhjrnsdkjdfgg');
                        // localParcelReadyNumberOfItems = parcelReadyNumberOfItems;
                        // localParcelReadyItemNames = parcelReadyItemNames;
                        localParcelNumber = '';

                        if (bluetoothOnTrueOrOffFalse) {
                          Navigator.pop(context);
                          print('nnknfkjnfndfdfdd');
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      SearchingConnectingPrinter(
                                          chefOrCaptain: 'Chef')));
                        } else {
                          Navigator.pop(context);
                          if (appInBackground == false) {
                            show('Please Turn On Bluetooth');
                          }
                        }
                      },
                    ),
                  )
                : Expanded(
                    // width: 300.0,
                    child: TextButton.icon(
                      icon: Icon(Icons.print),
                      label: bluetoothOnTrueOrOffFalse
                          ? Text(
                              'Print Item',
                            )
                          : Text(
                              'Turn Bluetooth To Print Item',
                            ),
                      style: TextButton.styleFrom(
                          primary: Colors.white, backgroundColor: Colors.green),
                      onPressed: () async {
//OnClickingPrint,WeAlwaysCallForTheMethodSavedBluetoothPrinterConnect
//WhichWillInsideItCallForThePrintFunction
                        localParcelReadyNumberOfItems = [];
                        localParcelReadyItemNames = [];
                        localParcelReadyItemComments = [];
                        localParcelReadyNumberOfItems
                            .add(parcelReadyNumberOfItems[0]);
                        localParcelReadyItemNames.add(parcelReadyItemNames[0]);
                        localParcelReadyItemComments
                            .add(parcelReadyItemComments[0]);
                        print('fdnfjdnfiyhjrnsdkjdfgg');
                        // localParcelReadyNumberOfItems = parcelReadyNumberOfItems;
                        // localParcelReadyItemNames = parcelReadyItemNames;
                        localParcelNumber = parcelNumber;

                        if (bluetoothOnTrueOrOffFalse) {
                          printerConnectionToLastSavedPrinterForAfterOrderPrint();
                          Navigator.pop(context);
                        } else {
                          Navigator.pop(context);
                          if (appInBackground == false) {
                            show('Please Turn On Bluetooth');
                          }
                        }
                      },
                    ),
                  ),
            SizedBox(width: 10),
          ],
        ),
      ],
    );
  }
}
