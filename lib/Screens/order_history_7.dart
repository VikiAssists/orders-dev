import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';
import 'package:orders_dev/Methods/eac_order_history_widget.dart';
import 'package:orders_dev/Methods/each_sales_bill_widget.dart';
import 'package:orders_dev/Methods/usb_bluetooth_printer.dart';
import 'package:orders_dev/Screens/printer_roles_assigning.dart';
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

class OrderHistoryWithDayWiseFolder extends StatefulWidget {
  //ScreenWhereWeShowTheBillsTillNow
  final String hotelName;

  const OrderHistoryWithDayWiseFolder({Key? key, required this.hotelName})
      : super(key: key);

  @override
  State<OrderHistoryWithDayWiseFolder> createState() =>
      _OrderHistoryWithDayWiseFolderState();
}

class _OrderHistoryWithDayWiseFolderState
    extends State<OrderHistoryWithDayWiseFolder> {
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

  int _everySecondForConnection = 0;
  // String hotelNameAlone = '';
//SpinnerOrCircularProgressIndicatorWhenTryingToPrint
  bool showSpinner = false;
  String printerSize = '0';
  //ToGetAllItemsOutsideForPrint

  bool locationPermissionAccepted = true;
  int _timerWorkingCheck = 0;
  bool printingOver = false;
  String localhotelNameForPrint = '';
  String localaddressLine1ForPrint = '';
  String localaddressLine2ForPrint = '';
  String localaddressLine3ForPrint = '';
  String localGstCodeForPrint = '';
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
//forNewPrintPackage
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
  var printerManager = PrinterManager.instance;
  StreamSubscription<PrinterDevice>? _subscription;
  StreamSubscription<BTStatus>? _subscriptionBtStatus;
  StreamSubscription<USBStatus>? _subscriptionUsbStatus;
  BTStatus _currentStatus = BTStatus.none;
  // _currentUsbStatus is only supports on Android
  // ignore: unused_field
  USBStatus _currentUsbStatus = USBStatus.none;
  var devices = <BluetoothPrinter>[];
  var _isBle = false;
  var _reconnect = false;
  var _isConnected = false;
  int printerConnectionSuccessCheckRandomNumber = 0;
  String year = '';
  String month = '';
  String day = '';
  String dateOfSalesBills = '';
  bool salesBillsDateChanged = false;

  @override
  void initState() {
//InitiallyWeWantThisAllToBeFalse

    showSpinner = false;
    viewingDateStringsSetting(DateTime.now());

    // TODO: implement initState
//ReadCounterToGetFromSharedPreferencesTheSavedPrinterDetails

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

  void viewingDateStringsSetting(DateTime timeChosen) {
    year = timeChosen.year.toString();
    month = timeChosen.month.toString().length == 1
        ? '0${timeChosen.month.toString()}'
        : timeChosen.month.toString();
    day = timeChosen.day.toString().length == 1
        ? '0${timeChosen.day.toString()}'
        : timeChosen.day.toString();
    dateOfSalesBills = '$day-$month-$year';
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
    Timer(Duration(seconds: 5), () {
      if (randomNumberForPrintingConnectionCheck ==
          printerConnectionSuccessCheckRandomNumber) {
        printerManager.disconnect(type: PrinterType.bluetooth);
        showMethodCallerWithShowSpinnerOffForBluetooth(
            'Unable to connect. Please check Printer');
      }
    });
  }

  void showMethodCallerWithShowSpinnerOffForBluetooth(String showMessage) {
    show(showMessage);
    setState(() {
      showSpinner = false;
      bluetoothBillConnect = false;
      bluetoothBillConnectTried = false;
      _isConnected = false;
    });
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

  void closingAllVariables() {
    localhotelNameForPrint = '';
    localaddressLine1ForPrint = '';
    localaddressLine2ForPrint = '';
    localaddressLine3ForPrint = '';
    localGstCodeForPrint = '';
    localphoneNumberForPrint = '';
    localCustomerNameForPrint = '';
    localCustomerMobileForPrint = '';
    localCustomerAddressForPrint = '';
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
  }

  Future<void> bytesGeneratorForBill(
    String hotelNameForPrint,
    String addressLine1ForPrint,
    String addressLine2ForPrint,
    String addressLine3ForPrint,
    String gstCodeForPrint,
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
  ) async {
    final distinctItems = distinctItemsForPrint.split('*');
    final individualPriceOfEachDistinctItem =
        individualPriceOfEachDistinctItemForPrint.split('*');
    final numberOfEachDistinctItem =
        numberOfEachDistinctItemForPrint.split('*');
    final priceOfEachDistinctItemWithoutTotal =
        priceOfEachDistinctItemWithoutTotalForPrint.split('*');
    final distinctExtraItems = extraItemsNamesForPrint.split('*');
    final distinctExtraItemsNumbers = extraItemsNumbersForPrint.split('*');
    if (showSpinner == false) {
      setState(() {
        showSpinner = true;
      });
    }
    print('start of inside printBytes Generator');

    billBytes = [];
    final profile = await CapabilityProfile.load();
    final generator = billingPrinterCharacters['printerSize'] == '80'
        ? Generator(PaperSize.mm80, profile)
        : Generator(PaperSize.mm58, profile);

//CurrentlyNotCaringWhether58mmOr80mm.WillChangeLater

    print('inside printThroughBluetooth-is connected is true here');
    if (billingPrinterCharacters['spacesAboveBill'] != '0') {
      for (int i = 0;
          i < num.parse(billingPrinterCharacters['spacesAboveBill']);
          i++) {
        billBytes += generator.text(" ");
      }
    }
    if (localhotelNameForPrint != '') {
      if (billingPrinterCharacters['printerSize'] == '80') {
        billBytes += generator.text("$hotelNameForPrint",
            styles: PosStyles(
                height: PosTextSize.size2,
                width: PosTextSize.size2,
                align: PosAlign.center));
        if (addressLine1ForPrint != '') {
          billBytes += generator.text("${addressLine1ForPrint}",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.center));
        }
        if (addressLine2ForPrint != '') {
          billBytes += generator.text("${addressLine2ForPrint}",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.center));
        }
        if (addressLine3ForPrint != '') {
          billBytes += generator.text("${addressLine3ForPrint}",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.center));
        }
        if (gstCodeForPrint != '') {
          billBytes += generator.text("GSTIN: $gstCodeForPrint",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.center));
        }
        if (phoneNumberForPrint != '') {
          billBytes += generator.text("${phoneNumberForPrint}",
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
        if (cgstPercentageForPrint != '0') {
          billBytes += generator.text("TAX INVOICE",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.center));
        }
        billBytes += generator.text(" ");
        billBytes += generator.text("ORDER DATE: $dateForPrint ",
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
        if (customerNameForPrint != '' || customerMobileForPrint != '') {
          String customerPrintingName = customerNameForPrint != ''
              ? 'Customer: ${customerNameForPrint}'
              : '';
          String customerPrintingMobile = customerMobileForPrint != ''
              ? 'Phone: ${customerMobileForPrint}'
              : '';
          if (customerNameForPrint != '') {
            billBytes += generator.text("$customerPrintingName",
                styles: PosStyles(
                    height: PosTextSize.size1,
                    width: PosTextSize.size1,
                    align: PosAlign.left));
          }
          if (customerMobileForPrint != '') {
            billBytes += generator.text("$customerPrintingMobile",
                styles: PosStyles(
                    height: PosTextSize.size1,
                    width: PosTextSize.size1,
                    align: PosAlign.left));
          }
        }
        if (customerAddressForPrint != '') {
          billBytes += generator.text("Address: ${customerAddressForPrint}",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.left));
        }
        if (customerNameForPrint != '' ||
            customerMobileForPrint != '' ||
            customerAddressForPrint != '') {
          billBytes += generator.text(
              "-----------------------------------------------",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.center));
        }
        billBytes += generator.row([
          PosColumn(
            text: "TOTAL NO. OF ITEMS:${totalNumberOfItemsForPrint}",
            width: 6,
            styles: PosStyles(align: PosAlign.left),
          ),
          PosColumn(
            text: "Qty:${totalQuantityForPrint}",
            width: 6,
            styles: PosStyles(align: PosAlign.right),
          ),
        ]);
        billBytes += generator.row([
          PosColumn(
            text: "BILL NO: ${billNumberForPrint.substring(0, 14)}",
            width: 6,
            styles: PosStyles(align: PosAlign.left),
          ),
          PosColumn(
            text: "$takeAwayOrDineInForPrint",
            width: 6,
            styles: PosStyles(align: PosAlign.right),
          ),
        ]);
        if (serialNumberForPrint != '') {
          billBytes += generator.text(" Sl.No: ${serialNumberForPrint}",
              styles: PosStyles(
                  height: PosTextSize.size2,
                  width: PosTextSize.size2,
                  align: PosAlign.left));
        }
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
            billBytes += generator.row([
              PosColumn(
                text: "$firstName",
                width: 6,
              ),
              PosColumn(
                text: "${individualPriceOfEachDistinctItem[i]}",
                width: 2,
              ),
              PosColumn(
                text: "${numberOfEachDistinctItem[i]}",
                width: 2,
              ),
              PosColumn(
                text: "${priceOfEachDistinctItemWithoutTotal[i]}",
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
                text: "${distinctItems[i]}",
                width: 6,
              ),
              PosColumn(
                text: "${individualPriceOfEachDistinctItem[i]}",
                width: 2,
              ),
              PosColumn(
                text: "${numberOfEachDistinctItem[i]}",
                width: 2,
              ),
              PosColumn(
                text: "${priceOfEachDistinctItemWithoutTotal[i]}",
                width: 2,
              ),
            ]);
          }
        }
        if (distinctExtraItems.isNotEmpty) {
          for (int l = 0; l < distinctExtraItems.length; l++) {
            billBytes += generator.row([
              PosColumn(
                text: "${distinctExtraItems[l]}",
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
                text: "${distinctExtraItemsNumbers[l]}",
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
        if (discountForPrint != '0') {
          if (discountValueClickedTruePercentageClickedFalse == 'true') {
            billBytes += generator.text("Discount : ${discountForPrint}",
                styles: PosStyles(
                    height: PosTextSize.size1,
                    width: PosTextSize.size1,
                    align: PosAlign.right));
          } else {
            billBytes += generator.text(
                "Discount ${discountEnteredValue}% : ${discountForPrint}",
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
        if (cgstPercentageForPrint != '0') {
          billBytes += generator.text("Sub-Total : $subTotalForPrint",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.right));
        }
        if (cgstPercentageForPrint != '0') {
          billBytes += generator.text(
              "CGST @ ${cgstPercentageForPrint}% : ${cgstCalculatedForPrint}",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.right));
        }
        if (sgstPercentageForPrint != '0') {
          billBytes += generator.text(
              "SGST @ ${sgstPercentageForPrint}% : ${sgstCalculatedForPrint}",
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
        if (roundOffForPrint != '0') {
          billBytes += generator.text("Round Off: ${roundOffForPrint}",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.right));
        }
        billBytes += generator.text("GRAND TOTAL: ${grandTotalForPrint}",
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
        if ((takeAwayOrDineInForPrint.substring(0, 15) == 'TYPE: TAKE-AWAY') &&
            consumeWithinHours != '' &&
            consumeWithinHours != '0') {
          billBytes += generator.text(
              "Note:Consume Within $consumeWithinHours Hours",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.center));
        }
        if (restaurantInfoData.containsKey('footerNotes')) {
          Map<String, dynamic> footerNotes =
              restaurantInfoData['footerNotes']['mapFooterNotesMap'];
          if (footerNotes.isNotEmpty) {
            billBytes += generator.text(" ");
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
        billBytes += generator.text("$hotelNameForPrint",
            styles: PosStyles(
                height: PosTextSize.size2,
                width: PosTextSize.size2,
                align: PosAlign.center));
        if (addressLine1ForPrint != '') {
          billBytes += generator.text("${addressLine1ForPrint}",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.center));
        }
        if (addressLine2ForPrint != '') {
          billBytes += generator.text("${addressLine2ForPrint}",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.center));
        }
        if (addressLine3ForPrint != '') {
          billBytes += generator.text("${addressLine3ForPrint}",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.center));
        }
        if (gstCodeForPrint != '') {
          billBytes += generator.text("GSTIN: $gstCodeForPrint",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.center));
        }
        if (phoneNumberForPrint != '') {
          billBytes += generator.text("$phoneNumberForPrint",
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
        if (cgstPercentageForPrint != '0') {
          billBytes += generator.text("TAX INVOICE",
              styles: PosStyles(align: PosAlign.center));
        }
        billBytes += generator.text("ORDER DATE: $dateForPrint ",
            styles: PosStyles(align: PosAlign.center));

        billBytes += generator.text("-------------------------------",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.center));

        if (customerNameForPrint != '' || customerMobileForPrint != '') {
          String customerPrintingName = customerNameForPrint != ''
              ? 'Customer: ${customerNameForPrint}'
              : '';
          String customerPrintingMobile = customerMobileForPrint != ''
              ? 'Phone: ${customerMobileForPrint}'
              : '';
          if (customerNameForPrint != '') {
            billBytes += generator.text("$customerPrintingName",
                styles: PosStyles(
                    height: PosTextSize.size1,
                    width: PosTextSize.size1,
                    align: PosAlign.left));
          }
          if (customerMobileForPrint != '') {
            billBytes += generator.text("$customerPrintingMobile",
                styles: PosStyles(
                    height: PosTextSize.size1,
                    width: PosTextSize.size1,
                    align: PosAlign.left));
          }
        }
        if (customerAddressForPrint != '') {
          billBytes += generator.text("Address: ${customerAddressForPrint}",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.left));
        }
        if (customerNameForPrint != '' ||
            customerMobileForPrint != '' ||
            customerAddressForPrint != '') {
          billBytes += generator.text("-------------------------------",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.center));
        }

        billBytes += generator.text(" ");
        billBytes += generator.text(
            "TOTAL NO. OF ITEMS:${totalNumberOfItemsForPrint}    Qty:${totalQuantityForPrint}",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.left));

        billBytes += generator.text(
            "BILL NO: ${billNumberForPrint.substring(0, 14)}",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.left));

        billBytes += generator.text("$takeAwayOrDineInForPrint",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.left));

        if (serialNumberForPrint != '') {
          billBytes += generator.text("Sl.No: ${serialNumberForPrint}",
              styles: PosStyles(
                  height: PosTextSize.size2,
                  width: PosTextSize.size2,
                  align: PosAlign.left));
        }
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

        for (int i = 0; i < distinctItems.length - 1; i++) {
          billBytes += generator.text("${distinctItems[i]}",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.left));

          billBytes += generator.row([
            PosColumn(
              text:
                  "${individualPriceOfEachDistinctItem[i]} x ${numberOfEachDistinctItem[i]}",
              width: 8,
              styles: PosStyles(align: PosAlign.center),
            ),
            PosColumn(
              text: "${priceOfEachDistinctItemWithoutTotal[i]}",
              width: 4,
              styles: PosStyles(align: PosAlign.right),
            ),
          ]);
        }
        billBytes += generator.text(" ");
        if (distinctExtraItems.isNotEmpty) {
          for (int l = 0; l < distinctExtraItems.length; l++) {
            billBytes += generator.row([
              PosColumn(
                text: "${distinctExtraItems[l]}",
                width: 8,
              ),
              PosColumn(
                text: "${distinctExtraItemsNumbers[l]}",
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
        if (discountForPrint != '0') {
          if (discountValueClickedTruePercentageClickedFalse == 'true') {
            billBytes += generator.text("Discount : ${discountForPrint} ",
                styles: PosStyles(
                    height: PosTextSize.size1,
                    width: PosTextSize.size1,
                    align: PosAlign.right));
          } else {
            billBytes += generator.text(
                "Discount ${discountEnteredValue}% : ${discountForPrint} ",
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
        if (cgstPercentageForPrint != '0') {
          billBytes += generator.text("Sub-Total : ${subTotalForPrint}",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.right));
        }
        if (cgstPercentageForPrint != '0') {
          billBytes += generator.text(
              "CGST @ ${cgstPercentageForPrint}% : ${cgstCalculatedForPrint}",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.right));
        }
        if (sgstPercentageForPrint != '0') {
          billBytes += generator.text(
              "SGST @ ${sgstPercentageForPrint}% : ${sgstCalculatedForPrint}",
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
        if (roundOffForPrint != '0') {
          billBytes += generator.text("Round Off: ${roundOffForPrint}",
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
              text: "${grandTotalForPrint}",
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
        Map<String, dynamic> restaurantInfoData = json.decode(
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .restaurantInfoDataFromClass);
        String consumeWithinHours = '';
        if (restaurantInfoData.containsKey('parcelConsumptionHours')) {
          consumeWithinHours = restaurantInfoData['parcelConsumptionHours']
              ['mapParcelConsumptionHoursMap']['hours'];
        }
        if ((takeAwayOrDineInForPrint.substring(0, 15) == 'TYPE: TAKE-AWAY') &&
            consumeWithinHours != '' &&
            consumeWithinHours != '0') {
          billBytes += generator.text(
              "Note:Consume Within $consumeWithinHours Hours",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.left));
        }
        if (restaurantInfoData.containsKey('footerNotes')) {
          Map<String, dynamic> footerNotes =
              restaurantInfoData['footerNotes']['mapFooterNotesMap'];
          if (footerNotes.isNotEmpty) {
            billBytes += generator.text(" ");
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
    }
    if (billingPrinterCharacters['printerBluetoothAddress'] != 'NA' ||
        billingPrinterCharacters['printerIPAddress'] != 'NA') {
      _connectDevice();
    } else {
//InCaseUsbPrinterIsNotConnected,WeDontHaveWayToScan.Hence,WeScanAndThenGoIn
      _scanForUsb();
    }
    print('end of inside print Bytes Generator');
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
        closingAllVariables();
        setState(() {
          showSpinner = false;
          usbBillConnect = false;
          usbBillConnectTried = false;
          _isConnected = false;
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
    print('came inside timerToCheckBluetoothOnOrOff');
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
        closingAllVariables();
//ChangingItToTrueInCaseTheyHaveTurnedOnWhyKeepItTurnedOff
        setState(() {
          showSpinner = false;
          _isConnected = false;
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
    closingAllVariables();
    Timer(Duration(seconds: 2), () {
      setState(() {
        showSpinner = false;
        usbBillConnect = false;
        usbBillConnectTried = false;
        bluetoothBillConnect = false;
        bluetoothBillConnectTried = false;
        _isConnected = false;
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
      closingAllVariables();

      setState(() {
        showSpinner = false;
        _isConnected = false;
      });
    } else {
      setState(() {
        showSpinner = false;
        _isConnected = false;
      });
      closingAllVariables();
      showMethodCaller('Unable To Connect. Please Check Printer');
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

                  print('came till this pop1');
                },
                child: Text('Ok'))
          ],
        ),
        barrierDismissible: false,
      );
      print('came into alertdialog loop4');
    } else {
      print('location permission loop2');
      print('location permission already accepted');
      setState(() {
        locationPermissionAccepted = true;
      });

      // initBluetooth();
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
    return Scaffold(
      // backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        leading: IconButton(
            //ThisBackButtonInAppbarToPopOutOfTheScreen
            icon: const Icon(Icons.arrow_back, color: kAppBarBackIconColor),
            onPressed: () async {
              Navigator.pop(context);
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
                        builder: (context) => PrinterRolesAssigning()));
              },
              icon: Icon(
                Icons.settings,
                color: kAppBarBackIconColor,
              ))
        ],
      ),
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(width: 10),
                Text('Date',
                    style: userInfoTextStyle, textAlign: TextAlign.right),
                ElevatedButton(
                  style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.green)),
                  child: Text(dateOfSalesBills, style: TextStyle(fontSize: 20)),
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialEntryMode: DatePickerEntryMode.calendarOnly,
                      builder: (context, child) {
                        return Theme(
                            data: Theme.of(context).copyWith(
                                dialogTheme: DialogTheme(
                                    shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      16.0), // this is the border radius of the picker
                                )),
                                colorScheme: ColorScheme(
                                    brightness: Brightness.light,
                                    primary: Colors.green,
                                    onPrimary: Colors.black,
                                    secondary: Colors.white,
                                    onSecondary: Colors.white,
                                    error: Colors.red,
                                    onError: Colors.black,
                                    background: Colors.white,
                                    onBackground: Colors.black,
                                    surface: Colors.white,
                                    onSurface: Colors.black)),
                            child: child!);
                      },
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().millisecondsSinceEpoch >=
                              DateTime(2025, 5, 1).millisecondsSinceEpoch
                          ? DateTime(DateTime.now().year - 1,
                              DateTime.now().month, DateTime.now().day)
                          : DateTime(2023, 5, 1),
                      lastDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        dateOfSalesBills =
                            DateFormat('dd-MM-yyyy').format(pickedDate);
                      });
                      viewingDateStringsSetting(pickedDate);
                    }
                  },
                ),
                SizedBox(width: 10),
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.green),
                    ),
                    onPressed: () {
                      setState(() {
                        salesBillsDateChanged = true;
                      });

                      Timer(Duration(milliseconds: 500), () {
                        setState(() {
                          salesBillsDateChanged = false;
                        });
                      });
                    },
                    child: Text('View'))
              ],
            ),
            salesBillsDateChanged == false
                ? Padding(
                    padding: const EdgeInsets.only(top: 70),
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
                        itemBuilderType: PaginateBuilderType
                            .listView, //Change types accordingly
                        itemBuilder: (context, documentSnapshots, index) {
                          final data = documentSnapshots[index].data() as Map?;
                          final printData =
                              documentSnapshots[index].data() as Map?;

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
                              localindividualPriceOfEachDistinctItemForPrint =
                                  '';
                              localnumberOfEachDistinctItemForPrint = '';
                              localpriceOfEachDistinctItemWithoutTotalForPrint =
                                  '';
                              localtotalQuantityForPrint = '';
                              localExtraItemsDistinctNamesForPrint = '';
                              localExtraItemsDistinctNumbersForPrint = '';
                              localDiscountForPrint = '';
                              localDiscountEnteredValue = '';
                              localDiscountValueClickedTruePercentageClickedFalse =
                                  '';
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
                              localGstCodeForPrint = '';
                              localphoneNumberForPrint = '';
                              localCustomerNameForPrint = '';
                              localCustomerMobileForPrint = '';
                              localCustomerAddressForPrint = '';
                              localSerialNumberForPrint = '';
                              localhotelNameForPrint =
                                  printData!['hotelNameForPrint'];
                              localdateForPrint = printData!['dateForPrint'];
                              if (printData['gstcodeforprint'] != null) {
                                localGstCodeForPrint =
                                    printData!['gstcodeforprint'];
                              }

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
                              if (printData!['customerMobileForPrint'] !=
                                  null) {
                                localCustomerMobileForPrint =
                                    printData!['customerMobileForPrint'];
                              }
                              if (printData!['customerAddressForPrint'] !=
                                  null) {
                                localCustomerAddressForPrint =
                                    printData!['customerAddressForPrint'];
                              }
                              if (printData!['serialNumberForPrint'] != null) {
                                localSerialNumberForPrint =
                                    printData!['serialNumberForPrint'];
                              }
                              localtotalNumberOfItemsForPrint =
                                  printData!['totalNumberOfItemsForPrint'];
                              localbillNumberForPrint =
                                  printData!['billNumberForPrint'];
                              localtakeAwayOrDineInForPrint =
                                  printData!['takeAwayOrDineInForPrint'];
                              localdistinctItemsForPrint =
                                  printData!['distinctItemsForPrint'];
                              localindividualPriceOfEachDistinctItemForPrint =
                                  printData![
                                      'individualPriceOfEachDistinctItemForPrint'];
                              localnumberOfEachDistinctItemForPrint =
                                  printData![
                                      'numberOfEachDistinctItemForPrint'];
                              localpriceOfEachDistinctItemWithoutTotalForPrint =
                                  printData![
                                      'priceOfEachDistinctItemWithoutTotalForPrint'];
                              localtotalQuantityForPrint =
                                  printData!['totalQuantityForPrint'];
                              if (printData!['extraItemsDistinctNames'] !=
                                  null) {
                                localExtraItemsDistinctNamesForPrint =
                                    printData!['extraItemsDistinctNames'];
                              }
                              if (printData!['extraItemsDistinctNumbers'] !=
                                  null) {
                                localExtraItemsDistinctNumbersForPrint =
                                    printData!['extraItemsDistinctNumbers'];
                              }

                              localDiscountForPrint = printData!['discount'];
                              localDiscountEnteredValue =
                                  printData!['discountEnteredValue'];
                              localDiscountValueClickedTruePercentageClickedFalse =
                                  printData![
                                      'discountValueClickedTruePercentageClickedFalse'];
                              localsubTotalForPrint =
                                  printData!['subTotalForPrint'];
                              localcgstPercentageForPrint =
                                  printData!['cgstPercentageForPrint'];
                              localcgstCalculatedForPrint =
                                  printData!['cgstCalculatedForPrint'];
                              localsgstPercentageForPrint =
                                  printData!['sgstPercentageForPrint'];
                              localsgstCalculatedForPrint =
                                  printData!['sgstCalculatedForPrint'];
                              localroundOff = printData!['roundOff'];
                              localgrandTotalForPrint =
                                  printData!['grandTotalForPrint'];
                              showModalBottomSheet(
                                  context: context,
                                  builder: (context) {
                                    return buildBottomSheetForPrint(context);
                                  });
                              //  print('the date is ${data![' Date of Order  :']}');
                            },
                            title: data == null
                                ? const Text('Error in data')
                                : EachSalesBill(
                                    eachOrderMap: data,
                                    eachOrderId: documentSnapshots[index].id),
                          );
                        },
                        // orderBy is compulsory to enable pagination
                        query: FirebaseFirestore.instance
                            .collection(widget.hotelName)
                            .doc('salesBills')
                            .collection(year)
                            .doc(month)
                            .collection(day)
                            .orderBy('serialNumberNum', descending: true),
                        itemsPerPage: 5,
                        // to fetch real-time data
                        isLive: true,
                      ),
                    ),
                  )
                : Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  ),
          ],
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
    );
  }

  Widget buildBottomSheetForPrint(BuildContext context) {
    return localhotelNameForPrint == ''
        ? Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text('Bill Not Available For Print'),
          )
        : Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                    .billingAssignedPrinterFromClass ==
                '{}'
            ? Container(
                padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                // width: 300.0,
                child: TextButton.icon(
                  icon: Icon(Icons.print),
                  label: Text(
                    'Assign Printer',
                  ),
                  style: TextButton.styleFrom(
                      primary: Colors.white, backgroundColor: Colors.green),
                  onPressed: () async {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => PrinterRolesAssigning()));
                  },
                ),
              )
            : Container(
                padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                // width: 300.0,
                child: TextButton.icon(
                  icon: Icon(Icons.print),
                  label: Text(
                    'Print',
                  ),
                  style: TextButton.styleFrom(
                      primary: Colors.white, backgroundColor: Colors.green),
                  onPressed: () async {
                    if (Provider.of<PrinterAndOtherDetailsProvider>(context,
                                listen: false)
                            .billingAssignedPrinterFromClass !=
                        '{}') {
                      billingPrinterAssigningMap = json.decode(
                          Provider.of<PrinterAndOtherDetailsProvider>(context,
                                  listen: false)
                              .billingAssignedPrinterFromClass);
                      billingPrinterAssigningMap.forEach((key, value) {
                        billingPrinterRandomID = key;
                      });
                      printerSavingMap = json.decode(
                          Provider.of<PrinterAndOtherDetailsProvider>(context,
                                  listen: false)
                              .savedPrintersFromClass);
                      printerSavingMap.forEach((key, value) {
                        if (key == billingPrinterRandomID) {
                          billingPrinterCharacters = value;
                        }
                      });
                    }
                    bytesGeneratorForBill(
                        localhotelNameForPrint,
                        localaddressLine1ForPrint,
                        localaddressLine2ForPrint,
                        localaddressLine3ForPrint,
                        localGstCodeForPrint,
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
                    Navigator.pop(context);
                  },
                ),
              );
    ;
  }
}
