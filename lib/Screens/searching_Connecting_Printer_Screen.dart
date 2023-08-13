import 'dart:async';

import 'package:flutter/material.dart';
import 'package:modal_progress_hud_alt/modal_progress_hud_alt.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:orders_dev/constants.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:orders_dev/Methods/printerenum.dart' as printerenum;

class SearchingConnectingPrinter extends StatefulWidget {
  final String chefOrCaptain;

  const SearchingConnectingPrinter({Key? key, required this.chefOrCaptain})
      : super(key: key);

  @override
  State<SearchingConnectingPrinter> createState() =>
      _SearchingConnectingPrinterState();
}

class _SearchingConnectingPrinterState
    extends State<SearchingConnectingPrinter> {
  bool _connected = false;
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  bool bluetoothOnTrueOrOffFalse = true;
  BluetoothDevice? _device;
  List<BluetoothDevice> _devices = [];
  List<BluetoothDevice> additionalDevices = [];
  String printerSizeToSave = '0';
  String tips = 'no device connect';
  String connectingPrinterAddress = '';
  String connectingPrinterName = '';
  String connectingPrinterSize = '';
  bool bluetoothConnected = false;
  bool printingError = false;
  bool showSpinner = false;
  int _everySecondForConnection = 0;
  bool disconnectAndConnectAttempted = false;
  bool printingOver = false;
  bool locationPermissionAccepted = true;

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
          style: const TextStyle(fontSize: kSnackbarMessageSize),
        ),
        duration: duration,
      ),
    );
  }

  void _connect(BluetoothDevice nowConnectingPrinter) {
    printingError = false;

    print('start of _Connect loop');
    if (nowConnectingPrinter != null) {
      print('device isnt null');

      bluetooth.isConnected.then((isConnected) {
        print('came inside bluetooth trying to connect');
        if (isConnected == false) {
          bluetooth.connect(nowConnectingPrinter!).catchError((error) {
            print('did not get connected1 inside _connect- ${_connected}');
            show('Couldn\'t Connect. Please check Printer');
            setState(() {
              printingError = true;
              _connected = false;
              showSpinner = false;
              // print('1 $tappedPrintButton');
              //
              // tappedPrintButton = false;
              // print('2 $tappedPrintButton');
            });
            print('did not get connected2 inside _connect- ${_connected}');
          });
          setState(() => _connected = true);
          print('we are connected inside _connect- ${_connected}');
          intermediateFunctionToCallPrintThroughBluetooth();
        } else {
          print('need a dosconnection here1');
          Timer? _timerInDisconnectAndConnect;
          int _everySecondHelpingToDisconnectBeforeConnectingAgain = 0;
          bluetooth.disconnect();
          setState(() => _connected = false);
          _everySecondForConnection = 0;

          if (disconnectAndConnectAttempted) {
            print('need a dosconnection here2');
            setState(() {
              showSpinner = false;
              // print('4 $tappedPrintButton');
              //
              // tappedPrintButton = false;
              // print('5 $tappedPrintButton');
            });
          } else {
            print('need a disconnection here3');
            _timerInDisconnectAndConnect =
                Timer.periodic(const Duration(seconds: 1), (_) async {
              if (_everySecondHelpingToDisconnectBeforeConnectingAgain < 4) {
                _everySecondHelpingToDisconnectBeforeConnectingAgain++;
                print(
                    '_everySecondHelpingToDisconnectBeforeConnectingAgainInBillScreen $_everySecondHelpingToDisconnectBeforeConnectingAgain');
              } else {
                print('need a dosconnection here4');
                _timerInDisconnectAndConnect!.cancel;
                print('need a dosconnection here4');
                if (disconnectAndConnectAttempted == false) {
                  disconnectAndConnectAttempted = true;
                  show('Couldn\'t Connect. Please Try Again');
                  // printerConnectionToLastSavedPrinter();
                } else {
                  _timerInDisconnectAndConnect!.cancel();
                }
                _everySecondHelpingToDisconnectBeforeConnectingAgain = 0;
                show('Couldn\'t Connect. Please Try Again');
                // printerConnectionToLastSavedPrinter();
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
      if (_everySecondForConnection <= 2) {
        print('timer inside connect is $_everySecondForConnection');
        _everySecondForConnection++;
      } else {
        _timer!.cancel();
        if (_connected) {
          print('Inside intermediate- it is connected');

          printThroughBluetooth();
        } else {
          setState(() {
            showSpinner = false;
            // print('6 $tappedPrintButton');
            //
            // tappedPrintButton = false;
            // print('7 $tappedPrintButton');
          });
          print('unable to connect');
          // bluetooth.disconnect();
          // show('Couldnt Connect. Please check Printer');
        }
      }
    });
    print('end of intermediateFunctionToCallPrintThroughBluetooth');
  }

  void bluetoothDisconnectFunction() async {
//AlteredForNewBluetoothDisconnectFunctionToo
    bluetooth.disconnect();
    bool onceDisconnected = false;
    _everySecondForConnection = 0;
    if (onceDisconnected == false) {
      bluetoothConnected = false;
      printingOver = false;
      // bluetooth.disconnect();
      // bluetoothPrint.destroy();
      onceDisconnected = true;

      print('inside cancel 1');
    }
    if (showSpinner) {
      setState(() {
        showSpinner = false;
        _connected = false;
        bluetoothConnected = false;
        bluetoothOnTrueOrOffFalse = true;
        print('disconnecting bluetooth');
        // _everySecond = 0;
        if (printingError == false) {
          Navigator.pop(context);
          // int count = 0;
          // Navigator.of(context).popUntil((_) => count++ >= 1);
        }

        // tappedPrintButton = false;
        // print('10 $tappedPrintButton');
      });
    }

//     Timer? _timer;
//     int _everySecond = 0;
//     _timer = Timer.periodic(const Duration(seconds: 1), (_) async {
//       //ItWillCheckWhetherTheVariableEveryThirtySecondsIsLessThan121,,
// //ThenItWillBeIncrementedBy1AndItWillAlsoCallTheFunctionWhichWillCheck,,
// //ForNewOrdersInTheBackground
// //IfItIsMoreThan120,ThenForOneHourThereHasNotBeenAnyOrder
// //AndHenceWeCancelTheTimer
//
//       if (_everySecond < 1) {
//         print('timer disconnect1 is $_everySecond');
//         _everySecond++;
//       } else {
//         _everySecond++;
//         print('timer disconnect2 time at cance point is $_everySecond');
//         if (onceDisconnected == false) {
//           bluetoothConnected = false;
//           printingOver = false;
//           // bluetooth.disconnect();
//           // bluetoothPrint.destroy();
//           onceDisconnected = true;
//
//           print('inside cancel 1');
//         }
//         if (_everySecond >= 1) {
//           _timer!.cancel();
//           if (showSpinner) {
//             setState(() {
//               showSpinner = false;
//               _connected = false;
//               bluetoothConnected = false;
//               bluetoothOnTrueOrOffFalse = true;
//               print('disconnecting bluetooth');
//               // _everySecond = 0;
//               if (printingError == false) {
//                 Navigator.pop(context);
//                 // int count = 0;
//                 // Navigator.of(context).popUntil((_) => count++ >= 1);
//               }
//
//               // tappedPrintButton = false;
//               // print('10 $tappedPrintButton');
//             });
//           }
//
//           _everySecond = 0;
//           // if (printingError == false) {
//           //   int count = 0;
//           //   Navigator.of(context).popUntil((_) => count++ >= 1);
//           // }
//         }
//
//         print('done with disconnect');
//
//         //toCloseTheAppInCaseTheAppIsn'tOpenedForAnHour
//
//       }
//     });
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
        print('came inside bluetooth isConnected');
        if (isConnected == true) {
          print('inside printThroughBluetooth-is connected is true here');
          bluetooth.printCustom("PRINTER CHECK", printerenum.Size.bold.val,
              printerenum.Align.center.val);
          bluetooth.printNewLine();
          // bluetooth.printNewLine();

          bluetooth
              .paperCut(); //some printer not supported (sometime making image not centered)
          //bluetooth.drawerPin2(); // or you can use bluetooth.drawerPin5();
        } else {
          setState(() {
            showSpinner = false;

            // tappedPrintButton = false;
            // print('11 $tappedPrintButton');
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

  @override
  void initState() {
    // TODO: implement initState
    getAllPairedDevices();
    requestLocationPermission();
    super.initState();
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
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: showSpinner,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: kAppBarBackgroundColor,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: kAppBarBackIconColor),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(
            '${widget.chefOrCaptain} Printer Connect',
            style: kAppBarTextStyle,
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              widget.chefOrCaptain != 'Captain'
                  ? ListTile(
                      title: Text('KOT Print'),
                      trailing: Switch(
                        // This bool value toggles the switch.
                        value:
                            Provider.of<PrinterAndOtherDetailsProvider>(context)
                                .chefPrinterKOTFromClass,
                        activeColor: Colors.green,
                        onChanged: (bool changedValue) {
                          // This is called when the user toggles the switch.
                          Provider.of<PrinterAndOtherDetailsProvider>(context,
                                  listen: false)
                              .neededOrNotChefKot(changedValue);
                        },
                      ),
                    )
                  : SizedBox.shrink(),
              widget.chefOrCaptain != 'Captain'
                  ? Divider(thickness: 2)
                  : SizedBox.shrink(),
              widget.chefOrCaptain != 'Captain'
                  ? ListTile(
                      title: Text('Delivery Slip Print'),
                      trailing: Switch(
                        // This bool value toggles the switch.
                        value:
                            Provider.of<PrinterAndOtherDetailsProvider>(context)
                                .chefPrinterAfterOrderReadyPrintFromClass,
                        activeColor: Colors.green,
                        onChanged: (bool changedValue) {
                          // This is called when the user toggles the switch.

                          Provider.of<PrinterAndOtherDetailsProvider>(context,
                                  listen: false)
                              .neededOrNotChefAfterOrderReadyPrint(
                                  changedValue);
                        },
                      ),
                    )
                  : SizedBox.shrink(),
              widget.chefOrCaptain != 'Captain'
                  ? Divider(thickness: 2)
                  : SizedBox.shrink(),
              ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.green),
                  ),
                  onPressed: () {
                    bluetoothStateChangeFunction();
                    if (bluetoothOnTrueOrOffFalse) {
                      getAllPairedDevices();
                    } else {
                      show('Please Turn On Bluetooth');
                    }
                    getAllPairedDevices();
                    // bluetoothPrint.startScan(
                    //     timeout: Duration(seconds: 5));
                  },
                  child: Text('Refresh')),
              Divider(),
              additionalDevices != []
                  ? ListView.builder(
                      physics: NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: additionalDevices.length,
                      itemBuilder: (context, index) {
                        var d = additionalDevices[index];
                        return Container(
                          child: ListTile(
                            title: Text(d.name ?? ''),
                            subtitle: Text(d.address ?? ''),
                            onTap: () async {
                              setState(() {
                                _device = d;
                              });
                            },
//AtRightEndOfListTile,IfBluetoothDeviceIsNotSelected,WeShowButton
//ButtonClickToSelect,,, IfSelected,WeGiveTheCheckedIcon
                            trailing:
                                _device != null && _device!.address == d.address
                                    ? Icon(
                                        Icons.check,
                                        color: Colors.green,
                                      )
                                    : ElevatedButton(
                                        style: ButtonStyle(
                                          backgroundColor:
                                              MaterialStateProperty.all<Color>(
                                                  Colors.green),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _device = d;
                                          });
                                        },
                                        child: Text('Click to Select')),
                          ),
                        );
                      })
                  : Center(
                      child: Text(
                        'There are no paired Devices',
                        style: TextStyle(
                          fontSize: 30.0,
                        ),
                      ),
                    ),
              Divider(),
              Container(
                padding: EdgeInsets.fromLTRB(20, 5, 20, 10),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        (_device != null &&
                                _device!.address != null &&
                                bluetoothOnTrueOrOffFalse)
                            ? DropdownButton<String>(
                                value: printerSizeToSave,
                                items: [
                                  DropdownMenuItem(
                                    child: Text('Select Printer Size'),
                                    value: '0',
                                  ),
                                  DropdownMenuItem(
                                    child: Text('80mm'),
                                    value: '80',
                                  ),
                                  DropdownMenuItem(
                                    child: Text('58mm'),
                                    value: '58',
                                  ),
                                ],
                                onChanged: (value) {
                                  print(value);
                                  setState(() {
                                    printerSizeToSave = value.toString();
                                  });
                                })
                            : SizedBox.shrink(),
                        SizedBox(width: 20),
                        printerSizeToSave != '0'
                            ? ElevatedButton(
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.green),
                                ),
                                child: Text('Connect'),
                                onPressed: _connected
                                    ? null
                                    : () async {
                                        bluetoothStateChangeFunction();
                                        if (bluetoothOnTrueOrOffFalse) {
                                          if (_device != null &&
                                              _device!.address != null) {
                                            setState(() {
                                              tips = 'connecting...';
                                              connectingPrinterAddress =
                                                  _device!.address!.toString();
                                              connectingPrinterName =
                                                  _device!.name!.toString();
                                              connectingPrinterSize =
                                                  printerSizeToSave;
                                              if (connectingPrinterAddress !=
                                                  '') {
                                                if (widget.chefOrCaptain ==
                                                    'Captain') {
                                                  Provider.of<PrinterAndOtherDetailsProvider>(
                                                          context,
                                                          listen: false)
                                                      .addCaptainPrinter(
                                                          connectingPrinterName,
                                                          connectingPrinterAddress,
                                                          connectingPrinterSize);
                                                } else {
                                                  Provider.of<PrinterAndOtherDetailsProvider>(
                                                          context,
                                                          listen: false)
                                                      .addChefPrinter(
                                                          connectingPrinterName,
                                                          connectingPrinterAddress,
                                                          connectingPrinterSize);
                                                }

                                                bluetoothConnected = true;
                                              }
                                            });
                                            // tappedPrintButton = true;
                                            _connect(_device!);
                                          } else {
                                            setState(() {
                                              tips = 'please select device';
                                              bluetoothConnected = false;
                                            });
                                            print('please select device');
                                          }
                                        } else {
                                          show('Please Turn On Bluetooth');
                                        }
                                      },
                              )
                            : SizedBox.shrink(),
                      ],
                    ),
                    // Divider(),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
