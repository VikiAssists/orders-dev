import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:modal_progress_hud_alt/modal_progress_hud_alt.dart';
import 'package:orders_dev/Methods/usb_bluetooth_printer.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:orders_dev/Screens/printer_roles_assigning.dart';
import 'package:orders_dev/constants.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';
import 'package:orders_dev/services/firestore_services.dart';
import 'package:provider/provider.dart';

enum TypesOfPrinters { Bluetooth, LAN, USB }

class PrintersAddingSavingAndEditing extends StatefulWidget {
  const PrintersAddingSavingAndEditing({Key? key}) : super(key: key);

  @override
  State<PrintersAddingSavingAndEditing> createState() =>
      _PrintersAddingSavingAndEditingState();
}

class _PrintersAddingSavingAndEditingState
    extends State<PrintersAddingSavingAndEditing> {
  var defaultPrinterType = PrinterType.bluetooth;
  var editPrinterType = PrinterType.bluetooth;
  var _isBle = false;
  var _reconnect = false;
  var _isConnected = false;
  var printerManager = PrinterManager.instance;
  var devices = <BluetoothPrinter>[];
  StreamSubscription<PrinterDevice>? _subscription;
  StreamSubscription<BTStatus>? _subscriptionBtStatus;
  StreamSubscription<USBStatus>? _subscriptionUsbStatus;
  BTStatus _currentStatus = BTStatus.none;
  // _currentUsbStatus is only supports on Android
  // ignore: unused_field
  USBStatus _currentUsbStatus = USBStatus.none;
  List<int>? pendingTask;
  BluetoothPrinter? selectedPrinter;
  String tempPrinterSizeToSave = '0';
  bool editingAlignmentOfSavedPrinterStarted = false;
  bool usbFirstConnect = false;
  bool usbFirstConnectTried = false;
  bool usbEditConnect = false;
  bool usbEditConnectTried = false;
  bool bluetoothFirstConnect = false;
  bool bluetoothFirstConnectTried = false;
  bool bluetoothEditConnect = false;
  bool bluetoothEditConnectTried = false;
  String tempSpacesAboveKOT = '';
  String tempSpacesBelowKOT = '';
  String tempKotSize = 'Small';
  List<String> kotSizes = ['Small', 'Large'];
  String tempSpacesAboveBill = '';
  String tempSpacesBelowBill = '';
  String tempBillSize = 'Small';
  List<String> billSizes = ['Small', 'Large'];
  String tempSpacesAboveDeliverySlip = '';
  String tempSpacesBelowDeliverySlip = '';
  String tempDeliverySlipSize = 'Small';
  List<String> deliverySlipSizes = ['Small', 'Large'];
  TextEditingController spacesAboveKotEditingController =
      TextEditingController();
  TextEditingController spacesBelowKotEditingController =
      TextEditingController();
  TextEditingController spacesAboveBillEditingController =
      TextEditingController();
  TextEditingController spacesBelowBillEditingController =
      TextEditingController();
  TextEditingController spacesAboveDeliverySlipEditingController =
      TextEditingController();
  TextEditingController spacesBelowDeliverySlipEditingController =
      TextEditingController();
  TypesOfPrinters? _character = TypesOfPrinters.Bluetooth;
  String errorMessage = '';
  num pageNumber = 1;
  var scrollKey = GlobalKey();
  var scrollKeyToPrinterSize = GlobalKey();
  var scrollKeyToPrinterName = GlobalKey();
  List<int> firstPrintBytes = [];
  List<int> printAlignmentCheckBytes = [];
  String tempDeviceManufacturerName = '';
  String editPrinterRandomID = '';
  String tempPrinterName = '';
  String tempBluetoothPrinterAddress = '';
  String tempUsbPrinterVendorID = '';
  String tempUsbPrinterProductID = '';
  String tempIPAddress = '';
  bool showSpinner = false;
  Map<String, dynamic> printerSavingMap = {};
  List<Map<String, dynamic>> printersList = [];

  void deleteAlertDialogBox() async {
    Map<String, dynamic> kotPrinterAssigningMap = HashMap();
    Map<String, dynamic> billingPrinterAssigningMap = HashMap();
    Map<String, dynamic> chefPrinterAssigningMap = HashMap();
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Center(
            child: Text(
          'Warning!',
          style: TextStyle(color: Colors.red),
        )),
        content: Text('${'Are you sure you want to delete this Printer?'}'),
        actions: [
          ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
              ),
              onPressed: () {
                printerSavingMap.remove(editPrinterRandomID);
//savingTheChangeInPrinterSavingMapInServer
                FireStorePrintersInformation(
                        userPhoneNumber:
                            Provider.of<PrinterAndOtherDetailsProvider>(context,
                                    listen: false)
                                .currentUserPhoneNumberFromClass,
                        hotelName: Provider.of<PrinterAndOtherDetailsProvider>(
                                context,
                                listen: false)
                            .chosenRestaurantDatabaseFromClass,
                        printerMapKey: 'printerSavingMap',
                        printerMapValue: json.encode(printerSavingMap))
                    .updatePrinterInfo();
                Provider.of<PrinterAndOtherDetailsProvider>(context,
                        listen: false)
                    .savingPrintersAddedByTheUser(jsonEncode(printerSavingMap));
                if (Provider.of<PrinterAndOtherDetailsProvider>(context,
                            listen: false)
                        .kotAssignedPrintersFromClass !=
                    '{}') {
                  kotPrinterAssigningMap = json.decode(
                      Provider.of<PrinterAndOtherDetailsProvider>(context,
                              listen: false)
                          .kotAssignedPrintersFromClass);
                  if (kotPrinterAssigningMap.containsKey(editPrinterRandomID)) {
                    kotPrinterAssigningMap.remove(editPrinterRandomID);
                    Provider.of<PrinterAndOtherDetailsProvider>(context,
                            listen: false)
                        .savingKotAssignedPrinterByTheUser(
                            json.encode(kotPrinterAssigningMap));
//WeCanSaveItAgainInServerOnlyIfWeAreRemovingTheKeyFromTheKotAssignedMap
                    FireStorePrintersInformation(
                            userPhoneNumber:
                                Provider.of<PrinterAndOtherDetailsProvider>(
                                        context,
                                        listen: false)
                                    .currentUserPhoneNumberFromClass,
                            hotelName:
                                Provider.of<PrinterAndOtherDetailsProvider>(
                                        context,
                                        listen: false)
                                    .chosenRestaurantDatabaseFromClass,
                            printerMapKey: 'kotPrinterAssigningMap',
                            printerMapValue:
                                json.encode(kotPrinterAssigningMap))
                        .updatePrinterInfo();
                  }
                }
                if (Provider.of<PrinterAndOtherDetailsProvider>(context,
                            listen: false)
                        .billingAssignedPrinterFromClass !=
                    '{}') {
                  billingPrinterAssigningMap = json.decode(
                      Provider.of<PrinterAndOtherDetailsProvider>(context,
                              listen: false)
                          .billingAssignedPrinterFromClass);
                  if (billingPrinterAssigningMap
                      .containsKey(editPrinterRandomID)) {
                    billingPrinterAssigningMap.remove(editPrinterRandomID);
                    Provider.of<PrinterAndOtherDetailsProvider>(context,
                            listen: false)
                        .savingBillingAssignedPrinterByTheUser(
                            json.encode(billingPrinterAssigningMap));
                    //WeCanSaveItAgainInServerOnlyIfWeAreRemovingTheKeyFromTheBillingAssignedMap
                    FireStorePrintersInformation(
                            userPhoneNumber:
                                Provider.of<PrinterAndOtherDetailsProvider>(
                                        context,
                                        listen: false)
                                    .currentUserPhoneNumberFromClass,
                            hotelName:
                                Provider.of<PrinterAndOtherDetailsProvider>(
                                        context,
                                        listen: false)
                                    .chosenRestaurantDatabaseFromClass,
                            printerMapKey: 'billingPrinterAssigningMap',
                            printerMapValue:
                                json.encode(billingPrinterAssigningMap))
                        .updatePrinterInfo();
                  }
                }

                if (Provider.of<PrinterAndOtherDetailsProvider>(context,
                            listen: false)
                        .chefAssignedPrinterFromClass !=
                    '{}') {
                  chefPrinterAssigningMap = json.decode(
                      Provider.of<PrinterAndOtherDetailsProvider>(context,
                              listen: false)
                          .chefAssignedPrinterFromClass);
                  if (chefPrinterAssigningMap
                      .containsKey(editPrinterRandomID)) {
                    chefPrinterAssigningMap.remove(editPrinterRandomID);

                    Provider.of<PrinterAndOtherDetailsProvider>(context,
                            listen: false)
                        .savingChefAssignedPrinterByTheUser(
                            json.encode(chefPrinterAssigningMap));
                    //WeCanSaveItAgainInServerOnlyIfWeAreRemovingTheKeyFromTheChefAssignedMap
                    FireStorePrintersInformation(
                            userPhoneNumber:
                                Provider.of<PrinterAndOtherDetailsProvider>(
                                        context,
                                        listen: false)
                                    .currentUserPhoneNumberFromClass,
                            hotelName:
                                Provider.of<PrinterAndOtherDetailsProvider>(
                                        context,
                                        listen: false)
                                    .chosenRestaurantDatabaseFromClass,
                            printerMapKey: 'chefPrinterAssigningMap',
                            printerMapValue:
                                json.encode(chefPrinterAssigningMap))
                        .updatePrinterInfo();
                  }
                }

//ToRefreshThePage
                savedPrintersFromProvider();
                defaultPrinterType = PrinterType.bluetooth;
                _scan();
                if (editingAlignmentOfSavedPrinterStarted) {
                  editingAlignmentOfSavedPrinterStarted = false;
                  if (tempBluetoothPrinterAddress != 'NA') {
                    printerManager.disconnect(type: PrinterType.bluetooth);
                  } else if (tempUsbPrinterVendorID != 'NA') {
                    printerManager.disconnect(type: PrinterType.usb);
                  }
                }
                selectedPrinter = null;
                pageNumber = 1;
                setState(() {});
                Navigator.pop(context);
              },
              child: Text('OK')),
        ],
      ),
      barrierDismissible: false,
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    savedPrintersFromProvider();
    _scan();
    printerFirstConnectBytesGenerator();

    // subscription to listen change status of bluetooth connection
    _subscriptionBtStatus =
        PrinterManager.instance.stateBluetooth.listen((status) {
      _currentStatus = status;
      if (status == BTStatus.connected) {
        if (bluetoothFirstConnect == true) {
          bluetoothFirstPrint();
        }
        if (bluetoothEditConnect == true) {
          printerAlignmentCheckBytesGenerator();
        }
        setState(() {
          _isConnected = true;
        });
      }
      if (status == BTStatus.none) {
        if (bluetoothFirstConnect == true ||
            bluetoothFirstConnectTried == true ||
            bluetoothEditConnect == true ||
            bluetoothEditConnectTried == true) {
          printerManager.disconnect(type: PrinterType.bluetooth);
//settingBluetoothCOnnectVariablesToDefaultValue
          bluetoothFirstConnect = false;
          bluetoothFirstConnectTried = false;
          bluetoothEditConnect = false;
          bluetoothEditConnectTried = false;
          showMethodCaller('Unable To Connect. Please Check Printer');
          setState(() {
            showSpinner = false;
          });
        }
        setState(() {
          _isConnected = false;
        });
      }
    });
    _subscriptionUsbStatus = PrinterManager.instance.stateUSB.listen((status) {
      // log(' ----------------- status usb $status ------------------ ');
      _currentUsbStatus = status;
      if (status == USBStatus.connected) {
        if (usbFirstConnect == true) {
          usbFirstPrint();
        }
        if (usbEditConnect == true) {
          printerFirstConnectBytesGenerator();
        }
      } else if (status == USBStatus.none) {
        if (usbFirstConnect ||
            usbFirstConnectTried ||
            usbEditConnect ||
            usbEditConnectTried) {
//settingUSBConnectVariablesToDefaultValue
          usbFirstConnect = false;
          usbFirstConnectTried = false;
          usbEditConnect = false;
          usbEditConnectTried = false;
          printerManager.disconnect(type: PrinterType.usb);
          setState(() {
            showSpinner = false;
          });
        }
        setState(() {
          _isConnected = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscriptionBtStatus?.cancel();
    _subscriptionUsbStatus?.cancel();
    super.dispose();
  }

  void savedPrintersFromProvider() {
    if (Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .savedPrintersFromClass !=
        '') {
      printerSavingMap = json.decode(
          Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .savedPrintersFromClass);
      printersList = [];
      printerSavingMap.forEach((key, value) {
        printersList.add(value);
      });
    }
    setState(() {});
  }

  void showMethodCaller(String showMessage) {
    show(showMessage);
  }

  Future show(
    String message, {
    Duration duration: const Duration(seconds: 3),
  }) async {
    await new Future.delayed(new Duration(milliseconds: 100));
    ScaffoldMessenger.of(context).showSnackBar(
      //   behavior: SnackBarBehavior.floating,
      //   margin: EdgeInsets.only(bottom: 400.0, right: 20, left: 20),
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

  void _scanBeforeEdit() {
    devices.clear();
    _subscription = printerManager
        .discovery(type: defaultPrinterType, isBle: _isBle)
        .listen((device) {
      devices.add(BluetoothPrinter(
        deviceName: device.name,
        address: device.address,
        isBle: _isBle,
        vendorId: device.vendorId,
        productId: device.productId,
        typePrinter: defaultPrinterType,
      ));

      setState(() {});
    });
  }

  void _scan() {
    devices.clear();
    _subscription = printerManager
        .discovery(type: defaultPrinterType, isBle: _isBle)
        .listen((device) {
      bool deviceNotAlreadyAdded = true;
      String checkAvailability = defaultPrinterType == PrinterType.bluetooth ||
              defaultPrinterType == PrinterType.network
          ? device.address.toString()
          : device.vendorId.toString();
      if (printerSavingMap.isNotEmpty) {
        printerSavingMap.forEach((key, value) {
          if (defaultPrinterType == PrinterType.bluetooth) {
            if (value['printerBluetoothAddress'].toString() ==
                checkAvailability) {
              deviceNotAlreadyAdded = false;
            }
          } else if (defaultPrinterType == PrinterType.usb) {
            if (value['printerUsbVendorID'].toString() == checkAvailability) {
              deviceNotAlreadyAdded = false;
            }
          } else {
//ThisMeansItsIPPrinter
            if (value['printerIPAddress'].toString() == checkAvailability) {
              deviceNotAlreadyAdded = false;
            }
          }
        });
      }
      if (deviceNotAlreadyAdded) {
        devices.add(BluetoothPrinter(
          deviceName: device.name,
          address: device.address,
          isBle: _isBle,
          vendorId: device.vendorId,
          productId: device.productId,
          typePrinter: defaultPrinterType,
        ));
      }

      setState(() {});
    });
  }

  void selectDevice(BluetoothPrinter device) async {
    if (selectedPrinter != null) {
      if ((device.address != selectedPrinter!.address) ||
          (device.typePrinter == PrinterType.usb &&
              selectedPrinter!.vendorId != device.vendorId)) {
        await PrinterManager.instance
            .disconnect(type: selectedPrinter!.typePrinter);
      }
    }

    selectedPrinter = device;
    setState(() {});
  }

  _connectDevice() async {
    _isConnected = false;
    setState(() {
      showSpinner = true;
    });
    if (selectedPrinter == null) return;
    switch (selectedPrinter!.typePrinter) {
      case PrinterType.usb:
        usbFirstConnectTried = true;
        await printerManager.connect(
            type: selectedPrinter!.typePrinter,
            model: UsbPrinterInput(
                name: selectedPrinter!.deviceName,
                productId: selectedPrinter!.productId,
                vendorId: selectedPrinter!.vendorId));
        tempDeviceManufacturerName = selectedPrinter!.deviceName.toString();
        tempUsbPrinterVendorID = selectedPrinter!.vendorId.toString();
        tempUsbPrinterProductID = selectedPrinter!.productId.toString();
        usbFirstConnect = true;
        _isConnected = true;
        break;
      case PrinterType.bluetooth:
        bluetoothFirstConnectTried = true;
        await printerManager.connect(
            type: selectedPrinter!.typePrinter,
            model: BluetoothPrinterInput(
                name: selectedPrinter!.deviceName,
                address: selectedPrinter!.address!,
                isBle: selectedPrinter!.isBle ?? false,
                autoConnect: _reconnect));
        tempDeviceManufacturerName = selectedPrinter!.deviceName.toString();
        tempBluetoothPrinterAddress = selectedPrinter!.address.toString();
        bluetoothFirstConnect = true;
        break;
      case PrinterType.network:
        final printer = PrinterNetworkManager(selectedPrinter!.address!);
        PosPrintResult connect = await printer.connect();
        if (connect == PosPrintResult.success) {
          PosPrintResult printing =
              await printer.printTicket(Uint8List.fromList(firstPrintBytes));
          printer.disconnect();
          tempDeviceManufacturerName = 'NA';
          tempIPAddress = selectedPrinter!.address.toString();
          setState(() {
            pageNumber = 3;
            showSpinner = false;
          });
        } else {
          showMethodCaller('Unable To Connect. Please Check Printer');
        }
        break;
      default:
    }

    setState(() {});
  }

  _connectDeviceForEdit() async {
    _isConnected = false;
    setState(() {
      showSpinner = true;
    });
    switch (editPrinterType) {
      case PrinterType.usb:
        usbEditConnectTried = true;
        await printerManager.connect(
            type: editPrinterType,
            model: UsbPrinterInput(
                name: tempDeviceManufacturerName,
                productId: tempUsbPrinterProductID,
                vendorId: tempUsbPrinterVendorID));
        usbEditConnect = true;
        _isConnected = true;
        break;
      case PrinterType.bluetooth:
        bluetoothEditConnectTried = true;
        await printerManager.connect(
            type: editPrinterType,
            model: BluetoothPrinterInput(
                name: tempDeviceManufacturerName,
                address: tempBluetoothPrinterAddress,
                isBle: false,
                autoConnect: _reconnect));
        bluetoothEditConnect = true;
        break;
      default:
    }

    setState(() {});
  }

  void printerFirstConnectBytesGenerator() async {
    firstPrintBytes = [];
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    firstPrintBytes += generator.text("Printer Check");
    firstPrintBytes += generator.cut();
  }

  void bluetoothFirstPrint() {
    print('came inside bluetooth first print');
    printerManager.send(type: PrinterType.bluetooth, bytes: firstPrintBytes);
    bluetoothFirstConnect = false;
    bluetoothFirstConnectTried = false;
    setState(() {
      pageNumber = 3;
      showSpinner = false;
    });
  }

  void usbFirstPrint() {
    printerManager.send(type: PrinterType.usb, bytes: firstPrintBytes);
    usbFirstConnect = false;
    usbFirstConnectTried = false;
    setState(() {
      pageNumber = 3;
      showSpinner = false;
    });
  }

  void printerAlignmentCheckBytesGenerator() async {
    printAlignmentCheckBytes = [];
    final profile = await CapabilityProfile.load();
    final generator = tempPrinterSizeToSave == '80'
        ? Generator(PaperSize.mm80, profile)
        : Generator(PaperSize.mm58, profile);
    printAlignmentCheckBytes += generator.text("<KOT Start>",
        styles: PosStyles(align: PosAlign.center));
    if (tempSpacesAboveKOT != '' && tempSpacesAboveKOT != '0') {
      for (int i = 0; i < num.parse(tempSpacesAboveKOT); i++) {
        printAlignmentCheckBytes += generator.text(" ");
      }
    }
    printAlignmentCheckBytes += generator.text("KOT Content",
        styles: tempKotSize == 'Small'
            ? PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.center)
            : PosStyles(
                height: PosTextSize.size2,
                width: PosTextSize.size2,
                align: PosAlign.center));
    if (tempSpacesBelowKOT != '' && tempSpacesBelowKOT != '0') {
      for (int i = 0; i < num.parse(tempSpacesBelowKOT); i++) {
        printAlignmentCheckBytes += generator.text(" ");
      }
    }
    printAlignmentCheckBytes +=
        generator.text("<KOT End>", styles: PosStyles(align: PosAlign.center));
    printAlignmentCheckBytes += generator.cut();
    printAlignmentCheckBytes += generator.text("<Delivery Slip Start>",
        styles: PosStyles(align: PosAlign.center));
    if (tempSpacesAboveDeliverySlip != '' &&
        tempSpacesAboveDeliverySlip != '0') {
      for (int i = 0; i < num.parse(tempSpacesAboveDeliverySlip); i++) {
        printAlignmentCheckBytes += generator.text(" ");
      }
    }
    printAlignmentCheckBytes += generator.text("Delivery Slip Content",
        styles: tempDeliverySlipSize == 'Small'
            ? PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.center)
            : PosStyles(
                height: PosTextSize.size2,
                width: PosTextSize.size2,
                align: PosAlign.center));
    if (tempSpacesBelowDeliverySlip != '' &&
        tempSpacesBelowDeliverySlip != '0') {
      for (int i = 0; i < num.parse(tempSpacesBelowDeliverySlip); i++) {
        printAlignmentCheckBytes += generator.text(" ");
      }
    }
    printAlignmentCheckBytes += generator.text("<Delivery Slip End>",
        styles: PosStyles(align: PosAlign.center));
    printAlignmentCheckBytes += generator.cut();
    printAlignmentCheckBytes += generator.text("<Bill Start>",
        styles: PosStyles(align: PosAlign.center));
    if (tempSpacesAboveBill != '' && tempSpacesAboveBill != '0') {
      for (int i = 0; i < num.parse(tempSpacesAboveBill); i++) {
        printAlignmentCheckBytes += generator.text(" ");
      }
    }
    printAlignmentCheckBytes += generator.text("Bill Content",
        styles: PosStyles(align: PosAlign.center));
    if (tempSpacesBelowBill != '' && tempSpacesBelowBill != '0') {
      for (int i = 0; i < num.parse(tempSpacesBelowBill); i++) {
        printAlignmentCheckBytes += generator.text(" ");
      }
    }
    printAlignmentCheckBytes +=
        generator.text("<Bill End>", styles: PosStyles(align: PosAlign.center));
    printAlignmentCheckBytes += generator.cut();
    printAlignmentSizeCheck();
  }

  void printAlignmentSizeCheck() async {
    if (pageNumber == 4) {
//ThisIsWhenWeAreEditingAnAlreadySavedPrinter
      if (editPrinterType == PrinterType.network) {
        final printer = PrinterNetworkManager(tempIPAddress);
        PosPrintResult connect = await printer.connect();
        if (connect == PosPrintResult.success) {
          PosPrintResult printing = await printer
              .printTicket(Uint8List.fromList(printAlignmentCheckBytes));
          printer.disconnect();
          setState(() {
            showSpinner = false;
          });
        } else {
          showMethodCaller('Unable To Connect. Please Check Printer');
          setState(() {
            showSpinner = false;
          });
        }
      } else {
        printerManager.send(
            type: editPrinterType, bytes: printAlignmentCheckBytes);
      }
//settingConnectUsefulVariablesToDefaultValue
      usbEditConnect = false;
      usbEditConnectTried = false;
      bluetoothEditConnect = false;
      bluetoothEditConnectTried = false;
      setState(() {
        showSpinner = false;
      });
    } else {
//ThisIsForNewPrinter
      if (selectedPrinter!.typePrinter == PrinterType.network) {
        final printer = PrinterNetworkManager(selectedPrinter!.address!);
        PosPrintResult connect = await printer.connect();
        if (connect == PosPrintResult.success) {
          PosPrintResult printing = await printer
              .printTicket(Uint8List.fromList(printAlignmentCheckBytes));
          printer.disconnect();
          setState(() {
            showSpinner = false;
          });
        } else {
          showMethodCaller('Unable To Connect. Please Check Printer');
          setState(() {
            showSpinner = false;
          });
        }
      } else {
        printerManager.send(
            type: selectedPrinter!.typePrinter,
            bytes: printAlignmentCheckBytes);
        setState(() {
          showSpinner = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return pageNumber == 1
        ? WillPopScope(
            onWillPop: () async {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PrinterRolesAssigning()));
              return false;
            },
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: kAppBarBackgroundColor,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: kAppBarBackIconColor),
                  onPressed: () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PrinterRolesAssigning()));
                  },
                ),
                title: Text('All Printers', style: kAppBarTextStyle),
                centerTitle: true,
              ),
              body: printerSavingMap.isEmpty
                  ? Center(
                      child: Text('No Printer Saved',
                          style: TextStyle(fontSize: 20)))
                  : Column(
                      children: printersList
                          .map((eachPrinter) => Container(
                                margin: EdgeInsets.fromLTRB(5, 5, 0, 10),
                                child: ListTile(
                                  tileColor: Colors.white70,
                                  leading: IconButton(
                                      icon:
                                          Icon(Icons.edit, color: Colors.green),
                                      onPressed: () {
                                        editPrinterRandomID =
                                            eachPrinter['printerRandomID'];
                                        tempPrinterName =
                                            eachPrinter['printerName'];
                                        tempDeviceManufacturerName = eachPrinter[
                                            'printerManufacturerDeviceName'];
                                        tempSpacesAboveKOT =
                                            eachPrinter['spacesAboveKOT'];
                                        spacesAboveKotEditingController =
                                            TextEditingController(
                                                text: tempSpacesAboveKOT);
                                        tempSpacesBelowKOT =
                                            eachPrinter['spacesBelowKOT'];
                                        spacesBelowKotEditingController =
                                            TextEditingController(
                                                text: tempSpacesBelowKOT);
                                        tempKotSize =
                                            eachPrinter['kotFontSize'];
                                        tempSpacesBelowBill =
                                            eachPrinter['spacesBelowBill'];
                                        spacesBelowBillEditingController =
                                            TextEditingController(
                                                text: tempSpacesBelowBill);
                                        tempSpacesAboveBill =
                                            eachPrinter['spacesAboveBill'];
                                        spacesAboveBillEditingController =
                                            TextEditingController(
                                                text: tempSpacesAboveBill);
                                        tempSpacesAboveDeliverySlip =
                                            eachPrinter[
                                                'spacesAboveDeliverySlip'];
                                        spacesAboveDeliverySlipEditingController =
                                            TextEditingController(
                                                text:
                                                    tempSpacesAboveDeliverySlip);
                                        tempSpacesBelowDeliverySlip =
                                            eachPrinter[
                                                'spacesBelowDeliverySlip'];
                                        spacesBelowDeliverySlipEditingController =
                                            TextEditingController(
                                                text:
                                                    tempSpacesBelowDeliverySlip);
                                        tempDeliverySlipSize =
                                            eachPrinter['deliverySlipFontSize'];
                                        tempPrinterSizeToSave =
                                            eachPrinter['printerSize'];
                                        tempIPAddress =
                                            eachPrinter['printerIPAddress'];
                                        tempBluetoothPrinterAddress =
                                            eachPrinter[
                                                'printerBluetoothAddress'];
                                        tempUsbPrinterProductID =
                                            eachPrinter['printerUsbProductID'];
                                        tempUsbPrinterVendorID =
                                            eachPrinter['printerUsbVendorID'];
                                        setState(() {
                                          pageNumber = 4;
                                        });
                                      }),
                                  title: Text(eachPrinter['printerName']),
                                  trailing: Text(eachPrinter['printerType']),
                                ),
                              ))
                          .toList()),
              floatingActionButton: Container(
                width: 75.0,
                height: 75.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1),
//            border: Border.all(
//          color: Colors.black87,
//          width: 0.2,
//        )
                ),
//FloatingActionButtonNameWillBeMenu
                child: FloatingActionButton(
                  backgroundColor: Colors.white70,
                  child: Icon(
                    Icons.add,
                    color: Colors.black,
                    size: 35,
                  ),
                  onPressed: () {
                    tempPrinterName = '';
                    tempSpacesAboveKOT = '';
                    spacesAboveKotEditingController =
                        TextEditingController(text: tempSpacesAboveKOT);
                    tempSpacesBelowKOT = '';
                    spacesBelowKotEditingController =
                        TextEditingController(text: tempSpacesBelowKOT);
                    tempKotSize = 'Small';
                    tempSpacesBelowBill = '';
                    spacesBelowBillEditingController =
                        TextEditingController(text: tempSpacesBelowBill);
                    tempSpacesAboveBill = '';
                    spacesAboveBillEditingController =
                        TextEditingController(text: tempSpacesAboveBill);
                    tempSpacesAboveDeliverySlip = '';
                    spacesAboveDeliverySlipEditingController =
                        TextEditingController(
                            text: tempSpacesAboveDeliverySlip);
                    tempSpacesBelowDeliverySlip = '';
                    spacesBelowDeliverySlipEditingController =
                        TextEditingController(
                            text: tempSpacesBelowDeliverySlip);
                    tempDeliverySlipSize = 'Small';
                    tempPrinterSizeToSave = '0';
                    tempIPAddress = '';
                    tempBluetoothPrinterAddress = '';
                    tempUsbPrinterProductID = '';
                    tempUsbPrinterVendorID = '';
                    _character = TypesOfPrinters.Bluetooth;
                    defaultPrinterType = PrinterType.bluetooth;
                    selectedPrinter = null;
                    _scan();
                    setState(() {
                      pageNumber = 2;
                    });
                  },
                ),
              ),
            ),
          )
        : pageNumber == 2
            ? WillPopScope(
                onWillPop: () async {
                  defaultPrinterType = PrinterType.bluetooth;
                  _scan();
                  setState(() {
                    pageNumber = 1;
                  });
                  return false;
                },
                child: Scaffold(
                  appBar: AppBar(
                    backgroundColor: kAppBarBackgroundColor,
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back, color: kAppBarBackIconColor),
                      onPressed: () {
                        defaultPrinterType = PrinterType.bluetooth;
                        _scan();
                        setState(() {
                          pageNumber = 1;
                        });
                      },
                    ),
                    title: Text('Add Printer', style: kAppBarTextStyle),
                    centerTitle: true,
                  ),
                  body: ModalProgressHUD(
                    inAsyncCall: showSpinner,
                    child: Padding(
                      padding: EdgeInsets.only(
                          top: 20,
                          bottom: MediaQuery.of(context).viewInsets.bottom),
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Choose Interface',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize: 15),
                              ),
                            ),
                            ListTile(
                              title:
                                  const Text('Bluetooth(Only Paired Printers)'),
                              leading: Radio<TypesOfPrinters>(
                                value: TypesOfPrinters.Bluetooth,
                                groupValue: _character,
                                onChanged: (TypesOfPrinters? value) {
                                  if (selectedPrinter != null) {
                                    if (selectedPrinter!.typePrinter ==
                                        PrinterType.usb) {
                                      printerManager.disconnect(
                                          type: PrinterType.usb);
                                    }
                                  }
                                  setState(() {
                                    selectedPrinter = null;
                                    _character = value;
                                    defaultPrinterType = PrinterType.bluetooth;
                                    _scan();
                                  });
                                },
                              ),
                            ),
                            ListTile(
                              title: const Text('LAN/WiFi'),
                              leading: Radio<TypesOfPrinters>(
                                value: TypesOfPrinters.LAN,
                                groupValue: _character,
                                onChanged: (TypesOfPrinters? value) {
                                  if (selectedPrinter != null) {
                                    if (selectedPrinter!.typePrinter ==
                                            PrinterType.usb ||
                                        selectedPrinter!.typePrinter ==
                                            PrinterType.bluetooth) {
                                      printerManager.disconnect(
                                          type: selectedPrinter!.typePrinter);
                                    }
                                  }
                                  setState(() {
                                    selectedPrinter = null;
                                    _character = value;
                                    defaultPrinterType = PrinterType.network;
                                    _scan();
                                  });
                                },
                              ),
                            ),
                            ListTile(
                              title: const Text('USB'),
                              leading: Radio<TypesOfPrinters>(
                                value: TypesOfPrinters.USB,
                                groupValue: _character,
                                onChanged: (TypesOfPrinters? value) {
                                  if (selectedPrinter != null) {
                                    if (selectedPrinter!.typePrinter ==
                                        PrinterType.bluetooth) {
                                      printerManager.disconnect(
                                          type: PrinterType.bluetooth);
                                    }
                                  }
                                  setState(() {
                                    selectedPrinter = null;
                                    _character = value;
                                    defaultPrinterType = PrinterType.usb;
                                    _scan();
                                  });
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Select Printer',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontSize: 15),
                              ),
                            ),
                            ElevatedButton(
                                style: ButtonStyle(
                                    backgroundColor:
                                        MaterialStateProperty.all<Color>(
                                            Colors.green)),
                                onPressed: () {
                                  selectedPrinter = null;
                                  _scan();
                                },
                                child: Text('Refresh')),
                            devices.length > 0
                                ? Column(
                                    children: devices
                                        .map(
                                          (device) => ListTile(
                                            title: defaultPrinterType !=
                                                    PrinterType.network
                                                ? Text('${device.deviceName}')
                                                : Text('${device.address}'),
//IPPrinerDoesntHaveAddress.HenceWeShowAddressInTitleAndNothingInSubTitle
                                            subtitle: defaultPrinterType ==
                                                    PrinterType.usb
                                                ? Text(
                                                    '*Product ID:${device.productId} * Vendor ID:${device.vendorId}')
                                                : defaultPrinterType ==
                                                        PrinterType.bluetooth
                                                    ? Text('${device.address}')
                                                    : null,
                                            onTap: () {
                                              // do something
                                              selectDevice(device);
                                            },
                                            trailing: selectedPrinter != null &&
                                                    ((device.typePrinter ==
                                                                PrinterType.usb
                                                            ? device.deviceName ==
                                                                selectedPrinter!
                                                                    .deviceName
                                                            : device.vendorId !=
                                                                    null &&
                                                                selectedPrinter!
                                                                        .vendorId ==
                                                                    device
                                                                        .vendorId) ||
                                                        (device.address !=
                                                                null &&
                                                            selectedPrinter!
                                                                    .address ==
                                                                device.address))
                                                ? const Icon(
                                                    Icons.check,
                                                    color: Colors.green,
                                                  )
                                                : ElevatedButton(
                                                    style: ButtonStyle(
                                                      backgroundColor:
                                                          MaterialStateProperty
                                                              .all<Color>(
                                                                  Colors.green),
                                                    ),
                                                    onPressed: () {
                                                      selectDevice(device);
                                                      Scrollable.ensureVisible(
                                                          scrollKey
                                                              .currentContext!);
                                                    },
                                                    child: Text(
                                                        'Click to Select')),
                                          ),
                                        )
                                        .toList())
                                : Text('No Devices Found',
                                    style: TextStyle(fontSize: 20),
                                    textAlign: TextAlign.center),
                            ElevatedButton(
                                key: scrollKey,
                                style: selectedPrinter != null
                                    ? ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.green))
                                    : ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.grey),
                                      ),
                                onPressed: () {
                                  if (selectedPrinter != null) {
                                    _connectDevice();
                                  }
                                },
                                child: Text('Connect'))
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : pageNumber == 3
                ? WillPopScope(
                    onWillPop: () async {
                      setState(() {
                        pageNumber = 2;
                      });
                      return false;
                    },
                    child: Scaffold(
                      appBar: AppBar(
                        backgroundColor: kAppBarBackgroundColor,
                        leading: IconButton(
                          icon: Icon(Icons.arrow_back,
                              color: kAppBarBackIconColor),
                          onPressed: () {
                            setState(() {
                              pageNumber = 2;
                            });
                          },
                        ),
                        title: Text('Edit Printer Settings',
                            style: kAppBarTextStyle),
                        centerTitle: true,
                      ),
                      body: SingleChildScrollView(
                        child: Column(
                          children: [
                            SizedBox(height: 10),
                            Center(
                                child: ListTile(
                              title: Text('Type'),
                              trailing: selectedPrinter!.typePrinter ==
                                      PrinterType.bluetooth
                                  ? Text('Bluetooth')
                                  : selectedPrinter!.typePrinter ==
                                          PrinterType.usb
                                      ? Text('USB')
                                      : Text('LAN/WiFi'),
                            )),
                            Center(
                                child: ListTile(
                              title: selectedPrinter!.typePrinter ==
                                      PrinterType.bluetooth
                                  ? Text('Address')
                                  : selectedPrinter!.typePrinter ==
                                          PrinterType.usb
                                      ? Text('Product and Vendor ID')
                                      : Text('IP Address'),
                              trailing: selectedPrinter!.typePrinter ==
                                      PrinterType.bluetooth
                                  ? Text(tempBluetoothPrinterAddress)
                                  : selectedPrinter!.typePrinter ==
                                          PrinterType.usb
                                      ? Text(
                                          'Product ID:${tempUsbPrinterProductID}, Vendor ID:${tempUsbPrinterVendorID}')
                                      : Text(tempIPAddress),
                            )),
                            Padding(
                              key: scrollKeyToPrinterName,
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                              child: Text('Enter Printer Name',
                                  style: userInfoTextStyle),
                            ),
                            Container(
                              padding: EdgeInsets.all(10),
                              child: TextField(
                                maxLength: 100,
                                controller: TextEditingController(
                                    text: tempPrinterName),
                                textCapitalization:
                                    TextCapitalization.sentences,
                                onChanged: (value) {
                                  tempPrinterName = value;
                                },
                                decoration:
                                    // kTextFieldInputDecoration,
                                    InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        hintText: 'Enter Printer Name',
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
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                              child: Text('Printer Size',
                                  style: userInfoTextStyle),
                            ),
                            Container(
                              key: scrollKeyToPrinterSize,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(30)),
                              width: 200,
                              height: 50,
                              child: DropdownButtonFormField<String>(
                                  decoration:
                                      InputDecoration.collapsed(hintText: ''),
                                  isExpanded: true,
                                  dropdownColor: Colors.green,
                                  value: tempPrinterSizeToSave,
                                  items: [
                                    DropdownMenuItem(
                                      alignment: Alignment.center,
                                      child: Text('Select Printer Size',
                                          style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                      value: '0',
                                    ),
                                    DropdownMenuItem(
                                      alignment: Alignment.center,
                                      child: Text('80mm',
                                          style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                      value: '80',
                                    ),
                                    DropdownMenuItem(
                                      alignment: Alignment.center,
                                      child: Text('58mm',
                                          style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                      value: '58',
                                    ),
                                  ],
                                  onChanged: (value) {
                                    print(value);
                                    setState(() {
                                      tempPrinterSizeToSave = value.toString();
                                    });
                                  }),
                            ),
                            Divider(thickness: 2),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                              child: Text('Spaces Above KOT',
                                  style: userInfoTextStyle),
                            ),
                            Container(
                              padding: EdgeInsets.all(10),
                              child: TextField(
                                maxLength: 2,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                controller: spacesAboveKotEditingController,
//ToUseNumberInputKeyboard,youNeedToDeclareControllerInsideStatefulWidgetItself
                                onChanged: (value) {
                                  tempSpacesAboveKOT = value.toString();
                                },
                                decoration:
                                    // kTextFieldInputDecoration,
                                    InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        hintText: 'Spaces above KOT',
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
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                              child: Text('Spaces Below KOT',
                                  style: userInfoTextStyle),
                            ),
                            Container(
                              padding: EdgeInsets.all(10),
                              child: TextField(
                                maxLength: 2,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                controller: spacesBelowKotEditingController,
//ToUseNumberInputKeyboard,youNeedToDeclareControllerInsideStatefulWidgetItself
                                onChanged: (value) {
                                  tempSpacesBelowKOT = value.toString();
                                },
                                decoration:
                                    // kTextFieldInputDecoration,
                                    InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        hintText: 'Spaces Below KOT',
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
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                              child: Text('KOT Font Size',
                                  style: userInfoTextStyle),
                            ),
                            Center(
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(30)),
                                width: 200,
                                height: 50,
                                // height: 200,
                                child: DropdownButtonFormField(
                                  decoration:
                                      InputDecoration.collapsed(hintText: ''),
                                  isExpanded: true,
                                  // underline: Container(),
                                  dropdownColor: Colors.green,
                                  value: tempKotSize,
                                  onChanged: (value) {
                                    tempKotSize = value.toString();
                                  },
                                  items: kotSizes.map((kotSize) {
//DropDownMenuItemWillHaveOneByOneItems,WePutThatAsList
//ValueWillBeEachTitle
                                    return DropdownMenuItem(
                                      alignment: Alignment.center,
                                      child: Text(kotSize,
                                          style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                      value: kotSize,
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            Divider(thickness: 2),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                              child: Text('Spaces Above Bill',
                                  style: userInfoTextStyle),
                            ),
                            Container(
                              padding: EdgeInsets.all(10),
                              child: TextField(
                                maxLength: 2,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                controller: spacesAboveBillEditingController,
//ToUseNumberInputKeyboard,youNeedToDeclareControllerInsideStatefulWidgetItself
                                onChanged: (value) {
                                  tempSpacesAboveBill = value.toString();
                                },
                                decoration:
                                    // kTextFieldInputDecoration,
                                    InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        hintText: 'Spaces above Bill',
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
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                              child: Text('Spaces Below Bill',
                                  style: userInfoTextStyle),
                            ),
                            Container(
                              padding: EdgeInsets.all(10),
                              child: TextField(
                                maxLength: 2,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                controller: spacesBelowBillEditingController,
//ToUseNumberInputKeyboard,youNeedToDeclareControllerInsideStatefulWidgetItself
                                onChanged: (value) {
                                  tempSpacesBelowBill = value.toString();
                                },
                                decoration:
                                    // kTextFieldInputDecoration,
                                    InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        hintText: 'Spaces Below Bill',
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
                            Divider(thickness: 2),
                            SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                              child: Text('Spaces Above Delivery Slip',
                                  style: userInfoTextStyle),
                            ),
                            Container(
                              padding: EdgeInsets.all(10),
                              child: TextField(
                                maxLength: 2,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                controller:
                                    spacesAboveDeliverySlipEditingController,
//ToUseNumberInputKeyboard,youNeedToDeclareControllerInsideStatefulWidgetItself
                                onChanged: (value) {
                                  tempSpacesAboveDeliverySlip =
                                      value.toString();
                                },
                                decoration:
                                    // kTextFieldInputDecoration,
                                    InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        hintText: 'Spaces above Delivery Slip',
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
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                              child: Text('Spaces Below Delivery Slip',
                                  style: userInfoTextStyle),
                            ),
                            Container(
                              padding: EdgeInsets.all(10),
                              child: TextField(
                                maxLength: 2,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                controller:
                                    spacesBelowDeliverySlipEditingController,
//ToUseNumberInputKeyboard,youNeedToDeclareControllerInsideStatefulWidgetItself
                                onChanged: (value) {
                                  tempSpacesBelowDeliverySlip =
                                      value.toString();
                                },
                                decoration:
                                    // kTextFieldInputDecoration,
                                    InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        hintText: 'Spaces Below Delivery Slip',
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
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                              child: Text('Delivery Slip Font Size',
                                  style: userInfoTextStyle),
                            ),
                            Center(
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(30)),
                                width: 200,
                                height: 50,
                                // height: 200,
                                child: DropdownButtonFormField(
                                  decoration:
                                      InputDecoration.collapsed(hintText: ''),
                                  isExpanded: true,
                                  // underline: Container(),
                                  dropdownColor: Colors.green,
                                  value: tempDeliverySlipSize,
                                  onChanged: (value) {
                                    tempDeliverySlipSize = value.toString();
                                  },
                                  items:
                                      deliverySlipSizes.map((deliverySlipSize) {
//DropDownMenuItemWillHaveOneByOneItems,WePutThatAsList
//ValueWillBeEachTitle
                                    return DropdownMenuItem(
                                      alignment: Alignment.center,
                                      child: Text(deliverySlipSize,
                                          style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                      value: deliverySlipSize,
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            Divider(thickness: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                    style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.red)),
                                    onPressed: () {
                                      selectedPrinter = null;
                                      defaultPrinterType =
                                          PrinterType.bluetooth;
                                      _scan();
                                      setState(() {
                                        pageNumber = 1;
                                      });
                                    },
                                    child: Text('Cancel')),
                                ElevatedButton(
                                    style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.green)),
                                    onPressed: () {
                                      if (tempPrinterName == '') {
                                        show('Please Enter Printer Name');
                                        Scrollable.ensureVisible(
                                            scrollKeyToPrinterName
                                                .currentContext!);
                                      } else if (tempPrinterSizeToSave == '0') {
                                        show('Please Choose Printer Size');
                                        Scrollable.ensureVisible(
                                            scrollKeyToPrinterSize
                                                .currentContext!);
                                      } else {
                                        String randomID = (10000 +
                                                Random().nextInt(99999 - 10000))
                                            .toString();
                                        Map<String, dynamic>
                                            tempPrinterMapForSaving = HashMap();
                                        tempPrinterMapForSaving.addAll({
                                          'printerRandomID': randomID,
                                          'printerName': tempPrinterName,
                                          'printerManufacturerDeviceName':
                                              tempDeviceManufacturerName,
                                          'printerType': selectedPrinter!
                                                      .typePrinter ==
                                                  PrinterType.bluetooth
                                              ? 'Bluetooth'
                                              : selectedPrinter!.typePrinter ==
                                                      PrinterType.usb
                                                  ? 'USB'
                                                  : 'LAN/WIFI',
                                          'printerBluetoothAddress':
                                              selectedPrinter!.typePrinter ==
                                                      PrinterType.bluetooth
                                                  ? tempBluetoothPrinterAddress
                                                  : 'NA',
                                          'printerIPAddress':
                                              selectedPrinter!.typePrinter ==
                                                      PrinterType.network
                                                  ? tempIPAddress
                                                  : 'NA',
                                          'printerUsbVendorID':
                                              selectedPrinter!.typePrinter ==
                                                      PrinterType.usb
                                                  ? tempUsbPrinterVendorID
                                                  : 'NA',
                                          'printerUsbProductID':
                                              selectedPrinter!.typePrinter ==
                                                      PrinterType.usb
                                                  ? tempUsbPrinterProductID
                                                  : 'NA',
                                          'printerSize': tempPrinterSizeToSave,
                                          'spacesAboveKOT':
                                              tempSpacesAboveKOT == ''
                                                  ? '0'
                                                  : tempSpacesAboveKOT,
                                          'spacesBelowKOT':
                                              tempSpacesBelowKOT == ''
                                                  ? '0'
                                                  : tempSpacesBelowKOT,
                                          'kotFontSize': tempKotSize,
                                          'spacesAboveBill':
                                              tempSpacesAboveBill == ''
                                                  ? '0'
                                                  : tempSpacesAboveBill,
                                          'spacesBelowBill':
                                              tempSpacesBelowBill == ''
                                                  ? '0'
                                                  : tempSpacesBelowBill,
                                          'billFontSize': tempBillSize,
                                          'spacesAboveDeliverySlip':
                                              tempSpacesAboveDeliverySlip == ''
                                                  ? '0'
                                                  : tempSpacesAboveDeliverySlip,
                                          'spacesBelowDeliverySlip':
                                              tempSpacesBelowDeliverySlip == ''
                                                  ? '0'
                                                  : tempSpacesBelowDeliverySlip,
                                          'deliverySlipFontSize':
                                              tempDeliverySlipSize,
                                          'singleUserPrinter': false,
                                          'autoCutAfterKotPrint': true,
                                          'autoCutAfterChefPrint': true,
                                          'autoCutAfterBillPrint': true,
                                          'extraBool1': true,
                                          'extraBool2': true,
                                          'extraBool3': true,
                                          'extraBool4': true,
                                          'extraBool5': true,
                                          'extraBool6': false,
                                          'extraBool7': false,
                                          'extraBool8': false,
                                          'extraBool9': false,
                                          'extraBool10': false,
                                          'extraString1': 'true',
                                          'extraString2': 'true',
                                          'extraString3': 'true',
                                          'extraString4': 'true',
                                          'extraString5': 'true',
                                          'extraString6': 'false',
                                          'extraString7': 'false',
                                          'extraString8': 'false',
                                          'extraString9': 'false',
                                          'extraString10': 'false'
                                        });
                                        printerSavingMap.addAll({
                                          randomID: tempPrinterMapForSaving
                                        });
                                        Provider.of<PrinterAndOtherDetailsProvider>(
                                                context,
                                                listen: false)
                                            .savingPrintersAddedByTheUser(
                                                jsonEncode(printerSavingMap));
                                        //savingTheChangeInPrinterSavingMapInServer
                                        FireStorePrintersInformation(
                                                userPhoneNumber: Provider.of<
                                                            PrinterAndOtherDetailsProvider>(
                                                        context,
                                                        listen: false)
                                                    .currentUserPhoneNumberFromClass,
                                                hotelName: Provider.of<
                                                            PrinterAndOtherDetailsProvider>(
                                                        context,
                                                        listen: false)
                                                    .chosenRestaurantDatabaseFromClass,
                                                printerMapKey:
                                                    'printerSavingMap',
                                                printerMapValue: json
                                                    .encode(printerSavingMap))
                                            .updatePrinterInfo();
//ToRefreshThePage
                                        savedPrintersFromProvider();
                                        if (selectedPrinter!.typePrinter ==
                                                PrinterType.bluetooth ||
                                            selectedPrinter!.typePrinter ==
                                                PrinterType.usb) {
                                          printerManager.disconnect(
                                              type:
                                                  selectedPrinter!.typePrinter);
                                        }
                                        defaultPrinterType =
                                            PrinterType.bluetooth;
                                        _scan();
                                        selectedPrinter = null;
                                        pageNumber = 1;
                                        setState(() {});
                                      }
                                    },
                                    child: Text('Save',
                                        style: TextStyle(fontSize: 20))),
                                ElevatedButton(
                                    style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.orangeAccent)),
                                    onPressed: () {
                                      if (tempPrinterSizeToSave != '0') {
                                        printerAlignmentCheckBytesGenerator();
                                      } else {
                                        show('Please Choose Printer Size');
                                        Scrollable.ensureVisible(
                                            scrollKeyToPrinterSize
                                                .currentContext!);
                                      }
                                    },
                                    child: Text('Check'))
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  )
                : WillPopScope(
                    onWillPop: () async {
                      if (editingAlignmentOfSavedPrinterStarted) {
                        editingAlignmentOfSavedPrinterStarted = false;
                        if (tempBluetoothPrinterAddress != 'NA') {
                          printerManager.disconnect(
                              type: PrinterType.bluetooth);
                        } else if (tempUsbPrinterVendorID != 'NA') {
                          printerManager.disconnect(type: PrinterType.usb);
                        }
                      }
                      defaultPrinterType = PrinterType.bluetooth;
                      _scan();
                      setState(() {
                        pageNumber = 1;
                      });
                      return false;
                    },
                    child: Scaffold(
                      appBar: AppBar(
                        backgroundColor: kAppBarBackgroundColor,
                        leading: IconButton(
                          icon: Icon(Icons.arrow_back,
                              color: kAppBarBackIconColor),
                          onPressed: () {
                            if (editingAlignmentOfSavedPrinterStarted) {
                              editingAlignmentOfSavedPrinterStarted = false;
                              if (tempBluetoothPrinterAddress != 'NA') {
                                printerManager.disconnect(
                                    type: PrinterType.bluetooth);
                              } else if (tempUsbPrinterVendorID != 'NA') {
                                printerManager.disconnect(
                                    type: PrinterType.usb);
                              }
                            }
                            defaultPrinterType = PrinterType.bluetooth;
                            _scan();
                            setState(() {
                              pageNumber = 1;
                            });
                          },
                        ),
                        title: Text('Edit Printer Settings',
                            style: kAppBarTextStyle),
                        centerTitle: true,
                      ),
                      body: SingleChildScrollView(
                        child: Column(
                          children: [
                            SizedBox(height: 10),
                            Center(
                                child: ListTile(
                              title: Text('Type'),
                              trailing: tempBluetoothPrinterAddress != 'NA'
                                  ? Text('Bluetooth')
                                  : tempUsbPrinterVendorID != 'NA'
                                      ? Text('USB')
                                      : Text('LAN/WiFi'),
                            )),
                            Center(
                                child: ListTile(
                              title: tempBluetoothPrinterAddress != 'NA' ||
                                      tempIPAddress != 'NA'
                                  ? Text('Address')
                                  : Text('Product and Vendor ID'),
                              trailing: tempBluetoothPrinterAddress != 'NA'
                                  ? Text(tempBluetoothPrinterAddress)
                                  : tempUsbPrinterVendorID != 'NA'
                                      ? Text(
                                          'Product ID:${tempUsbPrinterProductID} * Vendor ID:${tempUsbPrinterVendorID}')
                                      : Text(tempIPAddress),
                            )),
                            Padding(
                              key: scrollKeyToPrinterName,
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                              child: Text('Edit Printer Name',
                                  style: userInfoTextStyle),
                            ),
                            Container(
                              padding: EdgeInsets.all(10),
                              child: TextField(
                                maxLength: 100,
                                controller: TextEditingController(
                                    text: tempPrinterName),
                                textCapitalization:
                                    TextCapitalization.sentences,
                                onChanged: (value) {
                                  tempPrinterName = value;
                                },
                                decoration:
                                    // kTextFieldInputDecoration,
                                    InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        hintText: 'Enter Printer Name',
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
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                              child: Text('Printer Size',
                                  style: userInfoTextStyle),
                            ),
                            Container(
                              key: scrollKeyToPrinterSize,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(30)),
                              width: 200,
                              height: 50,
                              child: DropdownButtonFormField<String>(
                                  decoration:
                                      InputDecoration.collapsed(hintText: ''),
                                  isExpanded: true,
                                  dropdownColor: Colors.green,
                                  value: tempPrinterSizeToSave,
                                  items: [
                                    DropdownMenuItem(
                                      alignment: Alignment.center,
                                      child: Text('Select Printer Size',
                                          style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                      value: '0',
                                    ),
                                    DropdownMenuItem(
                                      alignment: Alignment.center,
                                      child: Text('80mm',
                                          style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                      value: '80',
                                    ),
                                    DropdownMenuItem(
                                      alignment: Alignment.center,
                                      child: Text('58mm',
                                          style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                      value: '58',
                                    ),
                                  ],
                                  onChanged: (value) {
                                    print(value);
                                    setState(() {
                                      tempPrinterSizeToSave = value.toString();
                                    });
                                  }),
                            ),
                            Divider(thickness: 2),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                              child: Text('Spaces Above KOT',
                                  style: userInfoTextStyle),
                            ),
                            Container(
                              padding: EdgeInsets.all(10),
                              child: TextField(
                                maxLength: 2,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                controller: spacesAboveKotEditingController,
//ToUseNumberInputKeyboard,youNeedToDeclareControllerInsideStatefulWidgetItself
                                onChanged: (value) {
                                  tempSpacesAboveKOT = value.toString();
                                },
                                decoration:
                                    // kTextFieldInputDecoration,
                                    InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        hintText: 'Spaces above KOT',
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
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                              child: Text('Spaces Below KOT',
                                  style: userInfoTextStyle),
                            ),
                            Container(
                              padding: EdgeInsets.all(10),
                              child: TextField(
                                maxLength: 2,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                controller: spacesBelowKotEditingController,
//ToUseNumberInputKeyboard,youNeedToDeclareControllerInsideStatefulWidgetItself
                                onChanged: (value) {
                                  tempSpacesBelowKOT = value.toString();
                                },
                                decoration:
                                    // kTextFieldInputDecoration,
                                    InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        hintText: 'Spaces Below KOT',
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
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                              child: Text('KOT Font Size',
                                  style: userInfoTextStyle),
                            ),
                            Center(
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(30)),
                                width: 200,
                                height: 50,
                                // height: 200,
                                child: DropdownButtonFormField(
                                  decoration:
                                      InputDecoration.collapsed(hintText: ''),
                                  isExpanded: true,
                                  // underline: Container(),
                                  dropdownColor: Colors.green,
                                  value: tempKotSize,
                                  onChanged: (value) {
                                    tempKotSize = value.toString();
                                  },
                                  items: kotSizes.map((kotSize) {
//DropDownMenuItemWillHaveOneByOneItems,WePutThatAsList
//ValueWillBeEachTitle
                                    return DropdownMenuItem(
                                      alignment: Alignment.center,
                                      child: Text(kotSize,
                                          style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                      value: kotSize,
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            Divider(thickness: 2),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                              child: Text('Spaces Above Bill',
                                  style: userInfoTextStyle),
                            ),
                            Container(
                              padding: EdgeInsets.all(10),
                              child: TextField(
                                maxLength: 2,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                controller: spacesAboveBillEditingController,
//ToUseNumberInputKeyboard,youNeedToDeclareControllerInsideStatefulWidgetItself
                                onChanged: (value) {
                                  tempSpacesAboveBill = value.toString();
                                },
                                decoration:
                                    // kTextFieldInputDecoration,
                                    InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        hintText: 'Spaces above Bill',
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
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                              child: Text('Spaces Below Bill',
                                  style: userInfoTextStyle),
                            ),
                            Container(
                              padding: EdgeInsets.all(10),
                              child: TextField(
                                maxLength: 2,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                controller: spacesBelowBillEditingController,
//ToUseNumberInputKeyboard,youNeedToDeclareControllerInsideStatefulWidgetItself
                                onChanged: (value) {
                                  tempSpacesBelowBill = value.toString();
                                },
                                decoration:
                                    // kTextFieldInputDecoration,
                                    InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        hintText: 'Spaces Below Bill',
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
                            Divider(thickness: 2),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                              child: Text('Spaces Above Delivery Slip',
                                  style: userInfoTextStyle),
                            ),
                            Container(
                              padding: EdgeInsets.all(10),
                              child: TextField(
                                maxLength: 2,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                controller:
                                    spacesAboveDeliverySlipEditingController,
//ToUseNumberInputKeyboard,youNeedToDeclareControllerInsideStatefulWidgetItself
                                onChanged: (value) {
                                  tempSpacesAboveDeliverySlip =
                                      value.toString();
                                },
                                decoration:
                                    // kTextFieldInputDecoration,
                                    InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        hintText: 'Spaces above Delivery Slip',
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
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                              child: Text('Spaces Below Delivery Slip',
                                  style: userInfoTextStyle),
                            ),
                            Container(
                              padding: EdgeInsets.all(10),
                              child: TextField(
                                maxLength: 2,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                controller:
                                    spacesBelowDeliverySlipEditingController,
//ToUseNumberInputKeyboard,youNeedToDeclareControllerInsideStatefulWidgetItself
                                onChanged: (value) {
                                  tempSpacesBelowDeliverySlip =
                                      value.toString();
                                },
                                decoration:
                                    // kTextFieldInputDecoration,
                                    InputDecoration(
                                        filled: true,
                                        fillColor: Colors.white,
                                        hintText: 'Spaces Below Delivery Slip',
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
                            Center(
                              child: Container(
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(30)),
                                width: 200,
                                height: 50,
                                // height: 200,
                                child: DropdownButtonFormField(
                                  decoration:
                                      InputDecoration.collapsed(hintText: ''),
                                  isExpanded: true,
                                  // underline: Container(),
                                  dropdownColor: Colors.green,
                                  value: tempDeliverySlipSize,
                                  onChanged: (value) {
                                    tempDeliverySlipSize = value.toString();
                                  },
                                  items:
                                      deliverySlipSizes.map((deliverySlipSize) {
//DropDownMenuItemWillHaveOneByOneItems,WePutThatAsList
//ValueWillBeEachTitle
                                    return DropdownMenuItem(
                                      alignment: Alignment.center,
                                      child: Text(deliverySlipSize,
                                          style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                      value: deliverySlipSize,
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            Divider(thickness: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                    style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.red)),
                                    onPressed: () {
                                      deleteAlertDialogBox();
                                    },
                                    child: Text('Delete')),
                                ElevatedButton(
                                    style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.green)),
                                    onPressed: () {
                                      if (tempPrinterName == '') {
                                        show('Please Enter Printer Name');
                                        Scrollable.ensureVisible(
                                            scrollKeyToPrinterName
                                                .currentContext!);
                                      } else if (tempPrinterSizeToSave == '0') {
                                        show('Please Choose Printer Size');
                                        Scrollable.ensureVisible(
                                            scrollKeyToPrinterSize
                                                .currentContext!);
                                      } else {
                                        printerSavingMap
                                            .remove(editPrinterRandomID);

                                        Map<String, dynamic>
                                            tempPrinterMapForSaving = HashMap();
                                        tempPrinterMapForSaving.addAll({
                                          'printerRandomID':
                                              editPrinterRandomID,
                                          'printerName': tempPrinterName,
                                          'printerManufacturerDeviceName':
                                              tempDeviceManufacturerName,
                                          'printerType':
                                              tempBluetoothPrinterAddress !=
                                                      'NA'
                                                  ? 'Bluetooth'
                                                  : tempUsbPrinterVendorID !=
                                                          'NA'
                                                      ? 'USB'
                                                      : 'LAN/WIFI',
                                          'printerBluetoothAddress':
                                              tempBluetoothPrinterAddress,
                                          'printerIPAddress': tempIPAddress,
                                          'printerUsbVendorID':
                                              tempUsbPrinterVendorID,
                                          'printerUsbProductID':
                                              tempUsbPrinterProductID,
                                          'printerSize': tempPrinterSizeToSave,
                                          'spacesAboveKOT':
                                              tempSpacesAboveKOT == ''
                                                  ? '0'
                                                  : tempSpacesAboveKOT,
                                          'spacesBelowKOT':
                                              tempSpacesBelowKOT == ''
                                                  ? '0'
                                                  : tempSpacesBelowKOT,
                                          'kotFontSize': tempKotSize,
                                          'spacesAboveBill':
                                              tempSpacesAboveBill == ''
                                                  ? '0'
                                                  : tempSpacesAboveBill,
                                          'spacesBelowBill':
                                              tempSpacesBelowBill == ''
                                                  ? '0'
                                                  : tempSpacesBelowBill,
                                          'billFontSize': tempBillSize,
                                          'spacesAboveDeliverySlip':
                                              tempSpacesAboveDeliverySlip == ''
                                                  ? '0'
                                                  : tempSpacesAboveDeliverySlip,
                                          'spacesBelowDeliverySlip':
                                              tempSpacesBelowDeliverySlip == ''
                                                  ? '0'
                                                  : tempSpacesBelowDeliverySlip,
                                          'deliverySlipFontSize':
                                              tempDeliverySlipSize,
                                          'singleUserPrinter': false,
                                          'autoCutAfterKotPrint': true,
                                          'autoCutAfterChefPrint': true,
                                          'autoCutAfterBillPrint': true,
                                          'extraBool1': true,
                                          'extraBool2': true,
                                          'extraBool3': true,
                                          'extraBool4': true,
                                          'extraBool5': true,
                                          'extraBool6': false,
                                          'extraBool7': false,
                                          'extraBool8': false,
                                          'extraBool9': false,
                                          'extraBool10': false,
                                          'extraString1': 'true',
                                          'extraString2': 'true',
                                          'extraString3': 'true',
                                          'extraString4': 'true',
                                          'extraString5': 'true',
                                          'extraString6': 'false',
                                          'extraString7': 'false',
                                          'extraString8': 'false',
                                          'extraString9': 'false',
                                          'extraString10': 'false'
                                        });
                                        printerSavingMap.addAll({
                                          editPrinterRandomID:
                                              tempPrinterMapForSaving
                                        });
                                        Provider.of<PrinterAndOtherDetailsProvider>(
                                                context,
                                                listen: false)
                                            .savingPrintersAddedByTheUser(
                                                jsonEncode(printerSavingMap));
                                        //savingTheChangeInPrinterSavingMapInServer
                                        FireStorePrintersInformation(
                                                userPhoneNumber: Provider.of<
                                                            PrinterAndOtherDetailsProvider>(
                                                        context,
                                                        listen: false)
                                                    .currentUserPhoneNumberFromClass,
                                                hotelName: Provider.of<
                                                            PrinterAndOtherDetailsProvider>(
                                                        context,
                                                        listen: false)
                                                    .chosenRestaurantDatabaseFromClass,
                                                printerMapKey:
                                                    'printerSavingMap',
                                                printerMapValue: json
                                                    .encode(printerSavingMap))
                                            .updatePrinterInfo();
//ToRefreshThePage
                                        savedPrintersFromProvider();
                                        if (editingAlignmentOfSavedPrinterStarted) {
                                          editingAlignmentOfSavedPrinterStarted =
                                              false;
                                          if (tempBluetoothPrinterAddress !=
                                              'NA') {
                                            printerManager.disconnect(
                                                type: PrinterType.bluetooth);
                                          } else if (tempUsbPrinterVendorID !=
                                              'NA') {
                                            printerManager.disconnect(
                                                type: PrinterType.usb);
                                          }
                                        }
                                        defaultPrinterType =
                                            PrinterType.bluetooth;
                                        _scan();
                                        selectedPrinter = null;
                                        pageNumber = 1;
                                        setState(() {});
                                      }
                                    },
                                    child: Text('Save',
                                        style: TextStyle(fontSize: 20))),
                                ElevatedButton(
                                    style: ButtonStyle(
                                        backgroundColor:
                                            MaterialStateProperty.all<Color>(
                                                Colors.orangeAccent)),
                                    onPressed: () {
                                      if (tempPrinterSizeToSave != '0') {
                                        if (editingAlignmentOfSavedPrinterStarted) {
                                          printerAlignmentCheckBytesGenerator();
                                        } else {
                                          editingAlignmentOfSavedPrinterStarted =
                                              true;
                                          editPrinterType =
                                              tempBluetoothPrinterAddress !=
                                                      'NA'
                                                  ? PrinterType.bluetooth
                                                  : tempUsbPrinterVendorID !=
                                                          'NA'
                                                      ? PrinterType.usb
                                                      : PrinterType.network;
                                          if (editPrinterType ==
                                              PrinterType.network) {
                                            printerAlignmentCheckBytesGenerator();
                                          } else {
                                            _connectDeviceForEdit();
                                          }
                                        }
                                      } else {
                                        Scrollable.ensureVisible(
                                            scrollKeyToPrinterSize
                                                .currentContext!);
                                        show('Please Choose Printer Size');
                                      }
                                    },
                                    child: Text('Check'))
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  );
  }
}
