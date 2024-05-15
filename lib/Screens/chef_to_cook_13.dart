//ChefScreenWithAllTypesOfPrinterPackage_9Jan2024
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_esc_pos_network/flutter_esc_pos_network.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:orders_dev/Methods/usb_bluetooth_printer.dart';
import 'package:orders_dev/Providers/notification_provider.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:orders_dev/Screens/printer_roles_assigning.dart';
import 'package:orders_dev/constants.dart';
import 'package:orders_dev/services/background_services.dart';
import 'package:orders_dev/services/firestore_services.dart';
import 'package:modal_progress_hud_alt/modal_progress_hud_alt.dart';
import 'package:orders_dev/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:orders_dev/Methods/printerenum.dart' as printerenum;
import 'package:provider/provider.dart';
import 'package:wakelock/wakelock.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_esc_pos_utils/flutter_esc_pos_utils.dart';

// bool thisIsChefCallingForBackground = true;
// String hotelNameForBackground = '';
// bool chefPrinterKOTFromClassForBackgroundKOT = false;
// List<String> chefSpecialitiesForBackground = [];
// var chefPrinterAddressFromClassForBackground;
// String chefPrinterSizeFromClassForBackground = '';

//ThisIsTheScreenWhereTheCookGetsTheItemsToCook
class ChefToCookNewPrinterPackage extends StatefulWidget {
  //TheInputsAreHotelNameAndChefSpecialities
  //ChefSpecialitiesAreTheItemsChefWon'tCook
  //Example:thereAreCooksWhoMakeJuicesAlone.So,
  //basedOnChefSpecialities,theCookWon'tGetTheItemsOtherThanJuices
  //ChefSpecialitiesIsInputtedWhenThisScreenIsCalledItself

  final String hotelName;
  final Map<String, dynamic> currentUserProfileMap;

  ChefToCookNewPrinterPackage(
      {Key? key, required this.hotelName, required this.currentUserProfileMap})
      : super(key: key);

  @override
  State<ChefToCookNewPrinterPackage> createState() =>
      _ChefToCookNewPrinterPackageState();
}

//InThisScreen,WeNeedToKnowWhenTheScreenIsOnAndWhenItIsOff
//OnlyThenWeCanAlertTheChefWhenNewItemComesEvenWhenTheScreenIsOff
//ToUnderstandThisScreenState,WeUseWidgetsBindingObserver

class _ChefToCookNewPrinterPackageState
    extends State<ChefToCookNewPrinterPackage> with WidgetsBindingObserver {
  bool _connected = false;
  bool printingOver = true;
  int _everySecondForConnection = 0;

  String tips = 'no device connect';

//SpinnerOrCircularProgressIndicatorWhenTryingToPrint
  bool showSpinner = false;
  String printerSize = '0';
  bool bluetoothOnTrueOrOffFalse = true; //variableForCheckingBluetoothOnOrOff
  bool deliverySlipPrinting = false;
  int timeForKot = 1;
  int kotCounter = 0;
  int _everySecondForKot = 0;
  int _everySecondForKotTimer = 0;
  List<String> tempLocalKOTItemNames = [];
  bool timerForPrintingKOTRunning = false;
  bool timerForPrintingTenSecKOTRunning = false;
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
  List<String> localKotItemsTableOrParcel = [];
  List<String> localKotItemsTableOrParcelNumber = [];
  List<String> localKotItemsParentOrChild = [];
  List<String> localKotItemsTicketNumber = [];
  List<String> localKOTItemsID = [];
  List<String> localKotCancelledItemTrueElseFalse = [];
  List<String> tempLocalKOTItemsID = [];
  num backgroundTimerCounter = 0;
  List<String> chefWontCookItems = [];
  List<int> kotBytes = [];
  List<int> deliverySlipBytes = [];
//newVariablesNeededForNewPrinterPackageWith3TypesOfPrinting
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
  var chefPrinterType = PrinterType.bluetooth;
  Map<String, dynamic> chefPrinterAssigningMap = HashMap();
  String chefPrinterRandomID = '';
  Map<String, dynamic> printerSavingMap = HashMap();
  Map<String, dynamic> chefPrinterCharacters = HashMap();
  bool usbKotConnect = false;
  bool usbKotConnectTried = false;
  bool usbDeliverySlipConnect = false;
  bool usbDeliverySlipConnectTried = false;
  bool bluetoothKotConnect = false;
  bool bluetoothKotConnectTried = false;
  bool bluetoothDeliverySlipConnect = false;
  bool bluetoothDeliverySlipConnectTried = false;
  int printerConnectionSuccessCheckRandomNumber = 0;
  bool serverUpdateAfterKotPrintIsOver = true;

  void showMethodCaller(String showMessage) {
    show(showMessage);
  }

  void showMethodCallerWithShowSpinnerOffForBluetooth(String showMessage) {
    printerManager.disconnect(type: PrinterType.bluetooth);
    if (!appInBackground) {
      show(showMessage);
    }

    playPrinterError();

    if (bluetoothKotConnect || bluetoothKotConnectTried) {
      if (timerForPrintingKOTRunning == false &&
          timerForPrintingTenSecKOTRunning == false &&
          deliverySlipPrinting == false &&
          serverUpdateAfterKotPrintIsOver) {
        timerForPrintingKOTTenSeconds();
      }

      bluetoothKotConnect = false;
      bluetoothKotConnectTried = false;
    }
    if (bluetoothDeliverySlipConnect || bluetoothDeliverySlipConnectTried) {
      deliverySlipPrinting = false;
      bluetoothDeliverySlipConnect = false;
      bluetoothDeliverySlipConnectTried = false;
    }

    setState(() {
      showSpinner = false;
      _isConnected = false;
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

  List<String> dynamicTokensToStringToken() {
    List<String> tokensList = [];
    Map<String, dynamic> allUsersTokenMap = json.decode(
        Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .allUserTokensFromClass);
    for (var tokens in allUsersTokenMap.values) {
      tokensList.add(tokens.toString());
    }
    return tokensList;
  }

  void bytesGeneratorForKot() async {
    if (showSpinner == false) {
      setState(() {
        showSpinner = true;
      });
    }
    kotBytes = [];

    var kotTextSize = chefPrinterCharacters['kotFontSize'] == 'Small'
        ? PosTextSize.size1
        : PosTextSize.size2;
    final profile = await CapabilityProfile.load();
    final generator = chefPrinterCharacters['printerSize'] == '80'
        ? Generator(PaperSize.mm80, profile)
        : Generator(PaperSize.mm58, profile);

    String tempTableOrParcel = '';
    String tempTableOrParcelNumber = '';
    String tempParentOrChild = '';
    String tempTicketNumber = '';
    String tempCancelledItemTrueElseFalse = '';

    for (int i = 0; i < localKOTItemNames.length; i++) {
      if (localKotCancelledItemTrueElseFalse[i] != 'false') {
//CancelledItemsKOTPrinting
        if (chefPrinterCharacters['printerSize'] == '80') {
          if (tempTableOrParcel != localKotItemsTableOrParcel[i] ||
              tempTableOrParcelNumber != localKotItemsTableOrParcelNumber[i] ||
              tempParentOrChild != localKotItemsParentOrChild[i] ||
              tempTicketNumber != localKotItemsTicketNumber[i] ||
              tempCancelledItemTrueElseFalse !=
                  localKotCancelledItemTrueElseFalse[i]) {
            // bluetooth.paperCut();
            if (chefPrinterCharacters['spacesAboveKOT'] != '0') {
              for (int i = 0;
                  i < num.parse(chefPrinterCharacters['spacesAboveKOT']);
                  i++) {
                kotBytes += generator.text(" ");
              }
            }

            if (localKotItemsParentOrChild[i] == 'parent') {
              kotBytes += generator.text("xxxxx CANCELLED xxxxx",
                  styles: PosStyles(
                      height: PosTextSize.size2,
                      width: PosTextSize.size2,
                      align: PosAlign.center));

              kotBytes += generator.text(
                  "KOT : ${localKotItemsTableOrParcel[i]}:${localKotItemsTableOrParcelNumber[i]}",
                  styles: PosStyles(
                      height: PosTextSize.size2,
                      width: PosTextSize.size2,
                      align: PosAlign.center));
            } else {
              kotBytes += generator.text("xxxxx CANCELLED xxxxx",
                  styles: PosStyles(
                      height: PosTextSize.size2,
                      width: PosTextSize.size2,
                      align: PosAlign.center));
              kotBytes += generator.text(
                  "KOT : ${localKotItemsTableOrParcel[i]}:${localKotItemsTableOrParcelNumber[i]}${localKotItemsParentOrChild[i]}",
                  styles: PosStyles(
                      height: PosTextSize.size2,
                      width: PosTextSize.size2,
                      align: PosAlign.center));
            }
            kotBytes += generator.text(
                "Ticket Number : ${localKotItemsTicketNumber[i]}",
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

            tempTableOrParcel = localKotItemsTableOrParcel[i];
            tempTableOrParcelNumber = localKotItemsTableOrParcelNumber[i];
            tempTicketNumber = localKotItemsTicketNumber[i];
            tempParentOrChild = localKotItemsParentOrChild[i];
            tempCancelledItemTrueElseFalse =
                localKotCancelledItemTrueElseFalse[i];
          }
          if ((' '.allMatches(localKOTItemNames[i]).length >= 2)) {
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

          if (localKOTItemComments[i] != 'noComment') {
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
          if ((i + 1) != localKOTItemNames.length) {
//MakingLoopForSpacesBelowKOT&Cut
            if (tempTableOrParcel != localKotItemsTableOrParcel[i + 1] ||
                tempTableOrParcelNumber !=
                    localKotItemsTableOrParcelNumber[i + 1] ||
                tempParentOrChild != localKotItemsParentOrChild[i + 1] ||
                tempTicketNumber != localKotItemsTicketNumber[i + 1] ||
                tempCancelledItemTrueElseFalse !=
                    localKotCancelledItemTrueElseFalse[i + 1]) {
              if (chefPrinterCharacters['spacesBelowKOT'] != '0') {
                for (int i = 0;
                    i < num.parse(chefPrinterCharacters['spacesBelowKOT']);
                    i++) {
                  kotBytes += generator.text(" ");
                }
              }
              kotBytes += generator.cut();
            }
          }
        } else if (chefPrinterCharacters['printerSize'] == '58') {
          if (tempTableOrParcel != localKotItemsTableOrParcel[i] ||
              tempTableOrParcelNumber != localKotItemsTableOrParcelNumber[i] ||
              tempParentOrChild != localKotItemsParentOrChild[i] ||
              tempTicketNumber != localKotItemsTicketNumber[i] ||
              tempCancelledItemTrueElseFalse !=
                  localKotCancelledItemTrueElseFalse[i]) {
            if (chefPrinterCharacters['spacesAboveKOT'] != '0') {
              for (int i = 0;
                  i < num.parse(chefPrinterCharacters['spacesAboveKOT']);
                  i++) {
                kotBytes += generator.text(" ");
              }
            }

            if (localKotItemsParentOrChild[i] == 'parent') {
              kotBytes += generator.text("xx CANCELLED xx",
                  styles: PosStyles(
                      height: PosTextSize.size2,
                      width: PosTextSize.size2,
                      align: PosAlign.center));

              kotBytes += generator.text(
                  "KOT : ${localKotItemsTableOrParcel[i]}:${localKotItemsTableOrParcelNumber[i]}",
                  styles: PosStyles(
                      height: PosTextSize.size2,
                      width: PosTextSize.size2,
                      align: PosAlign.center));
            } else {
              kotBytes += generator.text("xx CANCELLED xx",
                  styles: PosStyles(
                      height: PosTextSize.size2,
                      width: PosTextSize.size2,
                      align: PosAlign.center));

              kotBytes += generator.text(
                  "KOT : ${localKotItemsTableOrParcel[i]}:${localKotItemsTableOrParcelNumber[i]}${localKotItemsParentOrChild[i]}",
                  styles: PosStyles(
                      height: PosTextSize.size2,
                      width: PosTextSize.size2,
                      align: PosAlign.center));
            }
            kotBytes += generator.text(
                "Ticket Number : ${localKotItemsTicketNumber[i]}",
                styles: PosStyles(
                    height: PosTextSize.size1,
                    width: PosTextSize.size1,
                    align: PosAlign.center));

            kotBytes += generator.text("-------------------------------",
                styles: PosStyles(
                    height: PosTextSize.size1,
                    width: PosTextSize.size1,
                    align: PosAlign.center));

            tempTableOrParcel = localKotItemsTableOrParcel[i];
            tempTableOrParcelNumber = localKotItemsTableOrParcelNumber[i];
            tempTicketNumber = localKotItemsTicketNumber[i];
            tempParentOrChild = localKotItemsParentOrChild[i];

            tempCancelledItemTrueElseFalse =
                localKotCancelledItemTrueElseFalse[i];
          }
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

            kotBytes += generator.text("$secondName",
                styles: PosStyles(
                    height: kotTextSize,
                    width: kotTextSize,
                    align: PosAlign.left));
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
          if (localKOTItemComments[i] != 'noComment') {
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
          if ((i + 1) != localKOTItemNames.length) {
//MakingLoopForSpacesBelowKOT&Cut
            if (tempTableOrParcel != localKotItemsTableOrParcel[i + 1] ||
                tempTableOrParcelNumber !=
                    localKotItemsTableOrParcelNumber[i + 1] ||
                tempParentOrChild != localKotItemsParentOrChild[i + 1] ||
                tempTicketNumber != localKotItemsTicketNumber[i + 1] ||
                tempCancelledItemTrueElseFalse !=
                    localKotCancelledItemTrueElseFalse[i + 1]) {
              if (chefPrinterCharacters['spacesBelowKOT'] != '0') {
                for (int i = 0;
                    i < num.parse(chefPrinterCharacters['spacesBelowKOT']);
                    i++) {
                  kotBytes += generator.text(" ");
                }
              }
              kotBytes += generator.cut();
            }
          }
        }
      } else {
////NewlyOrderedItemsKOTPrinting
        if (chefPrinterCharacters['printerSize'] == '80') {
          if (tempTableOrParcel != localKotItemsTableOrParcel[i] ||
              tempTableOrParcelNumber != localKotItemsTableOrParcelNumber[i] ||
              tempParentOrChild != localKotItemsParentOrChild[i] ||
              tempTicketNumber != localKotItemsTicketNumber[i] ||
              tempCancelledItemTrueElseFalse !=
                  localKotCancelledItemTrueElseFalse[i]) {
            if (chefPrinterCharacters['spacesAboveKOT'] != '0') {
              for (int i = 0;
                  i < num.parse(chefPrinterCharacters['spacesAboveKOT']);
                  i++) {
                kotBytes += generator.text(" ");
              }
            }
            if (localKotItemsParentOrChild[i] == 'parent') {
              kotBytes += generator.text(
                  "KOT : ${localKotItemsTableOrParcel[i]}:${localKotItemsTableOrParcelNumber[i]}",
                  styles: PosStyles(
                      height: PosTextSize.size2,
                      width: PosTextSize.size2,
                      align: PosAlign.center));
            } else {
              kotBytes += generator.text(
                  "KOT : ${localKotItemsTableOrParcel[i]}:${localKotItemsTableOrParcelNumber[i]}${localKotItemsParentOrChild[i]}",
                  styles: PosStyles(
                      height: PosTextSize.size2,
                      width: PosTextSize.size2,
                      align: PosAlign.center));
            }

            kotBytes += generator.text(
                "Ticket Number : ${localKotItemsTicketNumber[i]}",
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

          if (localKOTItemComments[i] != 'noComment') {
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

          if ((i + 1) != localKOTItemNames.length) {
//MakingLoopForSpacesBelowKOT&Cut
            if (tempTableOrParcel != localKotItemsTableOrParcel[i + 1] ||
                tempTableOrParcelNumber !=
                    localKotItemsTableOrParcelNumber[i + 1] ||
                tempParentOrChild != localKotItemsParentOrChild[i + 1] ||
                tempTicketNumber != localKotItemsTicketNumber[i + 1] ||
                tempCancelledItemTrueElseFalse !=
                    localKotCancelledItemTrueElseFalse[i + 1]) {
              if (chefPrinterCharacters['spacesBelowKOT'] != '0') {
                for (int i = 0;
                    i < num.parse(chefPrinterCharacters['spacesBelowKOT']);
                    i++) {
                  kotBytes += generator.text(" ");
                }
              }
              kotBytes += generator.cut();
            }
          }
        } else if (chefPrinterCharacters['printerSize'] == '58') {
          if (tempTableOrParcel != localKotItemsTableOrParcel[i] ||
              tempTableOrParcelNumber != localKotItemsTableOrParcelNumber[i] ||
              tempParentOrChild != localKotItemsParentOrChild[i] ||
              tempTicketNumber != localKotItemsTicketNumber[i] ||
              tempCancelledItemTrueElseFalse !=
                  localKotCancelledItemTrueElseFalse[i]) {
            if (chefPrinterCharacters['spacesAboveKOT'] != '0') {
              for (int i = 0;
                  i < num.parse(chefPrinterCharacters['spacesAboveKOT']);
                  i++) {
                kotBytes += generator.text(" ");
              }
            }

            if (localKotItemsParentOrChild[i] == 'parent') {
              kotBytes += generator.text(
                  "KOT : ${localKotItemsTableOrParcel[i]}:${localKotItemsTableOrParcelNumber[i]}",
                  styles: PosStyles(
                      height: PosTextSize.size2,
                      width: PosTextSize.size2,
                      align: PosAlign.center));
            } else {
              kotBytes += generator.text(
                  "KOT : ${localKotItemsTableOrParcel[i]}:${localKotItemsTableOrParcelNumber[i]}${localKotItemsParentOrChild[i]}",
                  styles: PosStyles(
                      height: PosTextSize.size2,
                      width: PosTextSize.size2,
                      align: PosAlign.center));
            }
            kotBytes += generator.text(
                "Ticket Number : ${localKotItemsTicketNumber[i]}",
                styles: PosStyles(
                    height: PosTextSize.size1,
                    width: PosTextSize.size1,
                    align: PosAlign.center));

            kotBytes += generator.text("-------------------------------",
                styles: PosStyles(
                    height: PosTextSize.size1,
                    width: PosTextSize.size1,
                    align: PosAlign.center));

            tempTableOrParcel = localKotItemsTableOrParcel[i];
            tempTableOrParcelNumber = localKotItemsTableOrParcelNumber[i];
            tempTicketNumber = localKotItemsTicketNumber[i];
            tempParentOrChild = localKotItemsParentOrChild[i];
            tempCancelledItemTrueElseFalse =
                localKotCancelledItemTrueElseFalse[i];
          }
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

            kotBytes += generator.text("$secondName",
                styles: PosStyles(
                    height: kotTextSize,
                    width: kotTextSize,
                    align: PosAlign.left));
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
          if (localKOTItemComments[i] != 'noComment') {
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

          if ((i + 1) != localKOTItemNames.length) {
//MakingLoopForSpacesBelowKOT&Cut
            if (tempTableOrParcel != localKotItemsTableOrParcel[i + 1] ||
                tempTableOrParcelNumber !=
                    localKotItemsTableOrParcelNumber[i + 1] ||
                tempParentOrChild != localKotItemsParentOrChild[i + 1] ||
                tempTicketNumber != localKotItemsTicketNumber[i + 1] ||
                tempCancelledItemTrueElseFalse !=
                    localKotCancelledItemTrueElseFalse[i + 1]) {
              if (chefPrinterCharacters['spacesBelowKOT'] != '0') {
                for (int i = 0;
                    i < num.parse(chefPrinterCharacters['spacesBelowKOT']);
                    i++) {
                  kotBytes += generator.text(" ");
                }
              }
              kotBytes += generator.cut();
            }
          }
        }
      }
    }
    if (chefPrinterCharacters['spacesBelowKOT'] != '0') {
      for (int i = 0;
          i < num.parse(chefPrinterCharacters['spacesBelowKOT']);
          i++) {
        kotBytes += generator.text(" ");
      }
    }
    kotBytes += generator.cut();

    if (chefPrinterCharacters['printerBluetoothAddress'] != 'NA' ||
        chefPrinterCharacters['printerIPAddress'] != 'NA') {
      _connectDevice();
    } else {
//InCaseUsbPrinterIsNotConnected,WeDontHaveWayToScan.Hence,WeScanAndThenGoIn
      _scanForUsb();
    }

    print('end of inside kotBytesGenerator');
  }

  _scanForUsb() async {
    bool addedUSBDeviceNotAvailable = true;
//UnlikeBluetoothWeDontHavePerfectAvailableOrNotFeedbackForUsb
//HenceMakingScanForUsbDeviceEveryTimePrintIsCalled
    devices.clear();
    _subscription =
        printerManager.discovery(type: PrinterType.usb).listen((device) {
      if (device.vendorId.toString() ==
          chefPrinterCharacters['printerUsbVendorID']) {
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
        });
        playPrinterError();
        showMethodCaller('${chefPrinterCharacters['printerName']} not found');
      }
    });
  }

  _connectDevice() async {
    chefPrinterType = chefPrinterCharacters['printerUsbProductID'] != 'NA'
        ? PrinterType.usb
        : chefPrinterCharacters['printerBluetoothAddress'] != 'NA'
            ? PrinterType.bluetooth
            : PrinterType.network;
    _isConnected = false;
    setState(() {
      showSpinner = true;
    });
    switch (chefPrinterType) {
      case PrinterType.usb:
        printerManager.disconnect(type: PrinterType.usb);
        usbKotConnectTried = true;
        await printerManager.connect(
            type: chefPrinterType,
            model: UsbPrinterInput(
                name: chefPrinterCharacters['printerManufacturerDeviceName'],
                productId: chefPrinterCharacters['printerUsbProductID'],
                vendorId: chefPrinterCharacters['printerUsbVendorID']));
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
            type: chefPrinterType,
            model: BluetoothPrinterInput(
                name: chefPrinterCharacters['printerManufacturerDeviceName'],
                address: chefPrinterCharacters['printerBluetoothAddress'],
                isBle: false,
                autoConnect: _reconnect));
        bluetoothKotConnect = true;
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
        if (localKOTItemNames.isNotEmpty &&
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .chefPrinterKOTFromClass &&
            serverUpdateAfterKotPrintIsOver) {
//inCaseThereIsSomethingThereForKot,WeNeedToCallTenSecondsKotPrintTimer
          timerForPrintingKOTTenSeconds();
        }
        playPrinterError();
        showMethodCaller(
            'Please Check Bluetooth, Printer & try Printing Again');
        bluetoothKotConnect = false;
        bluetoothKotConnectTried = false;
        bluetoothDeliverySlipConnect = false;
        bluetoothDeliverySlipConnectTried = false;
        bluetoothOnTrueOrOffFalse = true;
//ChangingItToTrueInCaseTheyHaveTurnedOnWhyKeepItTurnedOff
        setState(() {
          showSpinner = false;
          _isConnected = false;
        });
      }
    });
  }

  void printThroughBluetoothOrUsb() {
    printerManager.send(type: chefPrinterType, bytes: kotBytes);
    if (chefPrinterType == PrinterType.bluetooth && !appInBackground) {
      showMethodCaller('Print SUCCESS...Disconnecting...');
    }

    Timer(Duration(seconds: 1), () {
      disconnectBluetoothOrUsb();
    });
  }

  void disconnectBluetoothOrUsb() {
    printerManager.disconnect(type: chefPrinterType);
    serverUpdateAfterKotPrintIsOver = false;
    Timer(Duration(seconds: 1), () {
//ThisTimerWillEnsureWeDontPrintAgainTillTheCurrentSetOfKot'sAreUpdated
      serverUpdateAfterKotPrintIsOver = true;
    });

    kotCounter = 0;

//ItMeansThereIsOnlyOneItemForKOT
    if (localKOTItemNames.length <= 1) {
      if (localKotCancelledItemTrueElseFalse[0] != 'false') {
//CancelledItemAndThereIsOnlyOneCancelledItem

        Map<String, dynamic> tempItemUpdater = HashMap();
        tempItemUpdater.addAll({localKOTItemsID[0]: FieldValue.delete()});
        Map<String, dynamic> masterUpdaterMap = HashMap();
        masterUpdaterMap.addAll({'itemsInOrderMap': tempItemUpdater});
        masterUpdaterMap.addAll({
          'statusMap': {'chefStatus': 7}
        });

        FireStoreAddOrderInRunningOrderFolder(
                hotelName: widget.hotelName,
                ordersMap: masterUpdaterMap,
                seatingNumber: localKotItemsBelongsToDoc[0])
            .addOrder();
      } else {
//NewlyOrderedItem
        statusUpdaterInFireStoreForRunningOrders(localKOTItemsID[0],
            localKotItemsBelongsToDoc[0], 7, 'chefkotprinted');
      }
    } else {
      List<String> tempItemsAcceptedIdList = [];
      List<String> tempItemsAcceptedDocList = [];
      List<String> tempItemsCancelledIdList = [];
      List<String> tempItemsCancelledDocList = [];
      for (int k = 0; k < localKOTItemNames.length; k++) {
        if (localKotCancelledItemTrueElseFalse[k] == 'false') {
//forAcceptedItems
          tempItemsAcceptedIdList.add(localKOTItemsID[k]);
          tempItemsAcceptedDocList.add(localKotItemsBelongsToDoc[k]);
        } else {
//forCancelledItems
          tempItemsCancelledIdList.add(localKOTItemsID[k]);
          tempItemsCancelledDocList.add(localKotItemsBelongsToDoc[k]);
        }
      }
      List<String> tempDistinctItemsAcceptedList =
          tempItemsAcceptedDocList.toSet().toList();
      for (var eachDistinctAcceptedDoc in tempDistinctItemsAcceptedList) {
        Map<String, dynamic> masterUpdaterMapForAcceptedKOT = HashMap();
        Map<String, dynamic> itemsUpdaterMapForAcceptedKOT = HashMap();
        int counter = 0;
        for (String acceptedItemDoc in tempItemsAcceptedDocList) {
          if (eachDistinctAcceptedDoc == acceptedItemDoc) {
            Map<String, dynamic> tempTempItemsUpdater = HashMap();
            tempTempItemsUpdater.addAll({'itemStatus': 7});
            tempTempItemsUpdater.addAll({'chefKOT': 'chefkotprinted'});
            itemsUpdaterMapForAcceptedKOT.addAll(
                {tempItemsAcceptedIdList[counter]: tempTempItemsUpdater});
          }
          counter++;
        }
        masterUpdaterMapForAcceptedKOT
            .addAll({'itemsInOrderMap': itemsUpdaterMapForAcceptedKOT});
        masterUpdaterMapForAcceptedKOT.addAll({
          'statusMap': {'chefStatus': 7}
        });
        FireStoreAddOrderInRunningOrderFolder(
                hotelName: widget.hotelName,
                ordersMap: masterUpdaterMapForAcceptedKOT,
                seatingNumber: eachDistinctAcceptedDoc)
            .addOrder();
      }
      List<String> tempDistinctItemsCancelledList =
          tempItemsCancelledDocList.toSet().toList();
      for (var eachDistinctCancelledDoc in tempDistinctItemsCancelledList) {
        Map<String, dynamic> masterUpdaterMapForCancelledKOT = HashMap();
        Map<String, dynamic> itemsUpdaterMapForCancelledKOT = HashMap();
        int counter = 0;
        for (String cancelledItemDoc in tempItemsCancelledDocList) {
          if (eachDistinctCancelledDoc == cancelledItemDoc) {
            itemsUpdaterMapForCancelledKOT.addAll(
                {tempItemsCancelledIdList[counter]: FieldValue.delete()});
            cancelledItemsKey.remove(tempItemsCancelledIdList[counter]);
          }
          counter++;
        }
        masterUpdaterMapForCancelledKOT
            .addAll({'itemsInOrderMap': itemsUpdaterMapForCancelledKOT});
        masterUpdaterMapForCancelledKOT.addAll({
          'statusMap': {'chefStatus': 7}
        });
        FireStoreAddOrderInRunningOrderFolder(
                hotelName: widget.hotelName,
                ordersMap: masterUpdaterMapForCancelledKOT,
                seatingNumber: eachDistinctCancelledDoc)
            .addOrder();
      }
    }
    localKOTNumberOfItems = [];
    localKOTItemComments = [];
    localKOTItemNames = [];
    localKotItemsParentOrChild = [];
    chefPrinterType == PrinterType.bluetooth
        ? Timer(Duration(seconds: 2), () {
            setState(() {
              showSpinner = false;
              usbKotConnect = false;
              usbKotConnectTried = false;
              bluetoothKotConnect = false;
              bluetoothKotConnectTried = false;
              _isConnected = false;
              printingOver = true;
            });
          })
        : Timer(Duration(milliseconds: 500), () {
            setState(() {
              showSpinner = false;
              usbKotConnect = false;
              usbKotConnectTried = false;
              bluetoothKotConnect = false;
              bluetoothKotConnectTried = false;
              _isConnected = false;
              printingOver = true;
            });
          });
  }

  Future<void> printWithNetworkPrinter() async {
    final printer =
        PrinterNetworkManager(chefPrinterCharacters['printerIPAddress']);
    PosPrintResult connect = await printer.connect();
    if (connect == PosPrintResult.success) {
      PosPrintResult printing =
          await printer.printTicket(Uint8List.fromList(kotBytes));
      printer.disconnect();
      serverUpdateAfterKotPrintIsOver = false;
      Timer(Duration(seconds: 1), () {
//ThisTimerWillEnsureWeDontPrintAgainTillTheCurrentSetOfKot'sAreUpdated
        serverUpdateAfterKotPrintIsOver = true;
      });

      kotCounter = 0;

//ItMeansThereIsOnlyOneItemForKOT
      if (localKOTItemNames.length <= 1) {
        if (localKotCancelledItemTrueElseFalse[0] != 'false') {
//CancelledItemAndThereIsOnlyOneCancelledItem

          Map<String, dynamic> tempItemUpdater = HashMap();
          tempItemUpdater.addAll({localKOTItemsID[0]: FieldValue.delete()});
          Map<String, dynamic> masterUpdaterMap = HashMap();
          masterUpdaterMap.addAll({'itemsInOrderMap': tempItemUpdater});
          masterUpdaterMap.addAll({
            'statusMap': {'chefStatus': 7}
          });

          FireStoreAddOrderInRunningOrderFolder(
                  hotelName: widget.hotelName,
                  ordersMap: masterUpdaterMap,
                  seatingNumber: localKotItemsBelongsToDoc[0])
              .addOrder();
        } else {
//NewlyOrderedItem
          statusUpdaterInFireStoreForRunningOrders(localKOTItemsID[0],
              localKotItemsBelongsToDoc[0], 7, 'chefkotprinted');
        }
      } else {
        List<String> tempItemsAcceptedIdList = [];
        List<String> tempItemsAcceptedDocList = [];
        List<String> tempItemsCancelledIdList = [];
        List<String> tempItemsCancelledDocList = [];
        for (int k = 0; k < localKOTItemNames.length; k++) {
          if (localKotCancelledItemTrueElseFalse[k] == 'false') {
//forAcceptedItems
            tempItemsAcceptedIdList.add(localKOTItemsID[k]);
            tempItemsAcceptedDocList.add(localKotItemsBelongsToDoc[k]);
          } else {
//forCancelledItems
            tempItemsCancelledIdList.add(localKOTItemsID[k]);
            tempItemsCancelledDocList.add(localKotItemsBelongsToDoc[k]);
          }
        }
        List<String> tempDistinctItemsAcceptedList =
            tempItemsAcceptedDocList.toSet().toList();
        for (var eachDistinctAcceptedDoc in tempDistinctItemsAcceptedList) {
          Map<String, dynamic> masterUpdaterMapForAcceptedKOT = HashMap();
          Map<String, dynamic> itemsUpdaterMapForAcceptedKOT = HashMap();
          int counter = 0;
          for (String acceptedItemDoc in tempItemsAcceptedDocList) {
            if (eachDistinctAcceptedDoc == acceptedItemDoc) {
              Map<String, dynamic> tempTempItemsUpdater = HashMap();
              tempTempItemsUpdater.addAll({'itemStatus': 7});
              tempTempItemsUpdater.addAll({'chefKOT': 'chefkotprinted'});
              itemsUpdaterMapForAcceptedKOT.addAll(
                  {tempItemsAcceptedIdList[counter]: tempTempItemsUpdater});
            }
            counter++;
          }
          masterUpdaterMapForAcceptedKOT
              .addAll({'itemsInOrderMap': itemsUpdaterMapForAcceptedKOT});
          masterUpdaterMapForAcceptedKOT.addAll({
            'statusMap': {'chefStatus': 7}
          });
          FireStoreAddOrderInRunningOrderFolder(
                  hotelName: widget.hotelName,
                  ordersMap: masterUpdaterMapForAcceptedKOT,
                  seatingNumber: eachDistinctAcceptedDoc)
              .addOrder();
        }
        List<String> tempDistinctItemsCancelledList =
            tempItemsCancelledDocList.toSet().toList();
        for (var eachDistinctCancelledDoc in tempDistinctItemsCancelledList) {
          Map<String, dynamic> masterUpdaterMapForCancelledKOT = HashMap();
          Map<String, dynamic> itemsUpdaterMapForCancelledKOT = HashMap();
          int counter = 0;
          for (String cancelledItemDoc in tempItemsCancelledDocList) {
            if (eachDistinctCancelledDoc == cancelledItemDoc) {
              itemsUpdaterMapForCancelledKOT.addAll(
                  {tempItemsCancelledIdList[counter]: FieldValue.delete()});
              cancelledItemsKey.remove(tempItemsCancelledIdList[counter]);
            }
            counter++;
          }
          masterUpdaterMapForCancelledKOT
              .addAll({'itemsInOrderMap': itemsUpdaterMapForCancelledKOT});
          masterUpdaterMapForCancelledKOT.addAll({
            'statusMap': {'chefStatus': 7}
          });
          FireStoreAddOrderInRunningOrderFolder(
                  hotelName: widget.hotelName,
                  ordersMap: masterUpdaterMapForCancelledKOT,
                  seatingNumber: eachDistinctCancelledDoc)
              .addOrder();
        }
      }
      localKOTNumberOfItems = [];
      localKOTItemComments = [];
      localKOTItemNames = [];
      localKotItemsParentOrChild = [];
      setState(() {
        showSpinner = false;
        _isConnected = false;
        printingOver = true;
      });
    } else {
      playPrinterError();
      if (timerForPrintingKOTRunning == false &&
          timerForPrintingTenSecKOTRunning == false &&
          deliverySlipPrinting == false &&
          serverUpdateAfterKotPrintIsOver) {
        timerForPrintingKOTTenSeconds();
      }
      setState(() {
        showSpinner = false;
        _isConnected = false;
      });
      if (!appInBackground) {
        showMethodCaller('Unable To Connect. Please Check Printer');
      }
    }
  }

  Future<void> deliverySlipPrintBytesGenerator() async {
    print('start of inside after Order Ready Bytes Generator');
    if (localParcelReadyItemNames.isEmpty) {
      localParcelReadyItemNames.add('Printer Check');
      localParcelReadyNumberOfItems.add(1);
      localParcelReadyItemComments.add(' ');
    }
    if (localParcelReadyItemNames[0] != 'Printer Check') {
//boolForCheckingWhetherWeAreIntoDeliverySlipPrinting
      deliverySlipPrinting = true;
      if (showSpinner == false) {
        setState(() {
          showSpinner = true;
        });
      }
      deliverySlipBytes = [];

      var deliverySlipTextSize =
          chefPrinterCharacters['deliverySlipFontSize'] == 'Small'
              ? PosTextSize.size1
              : PosTextSize.size2;
      final profile = await CapabilityProfile.load();
      final generator = chefPrinterCharacters['printerSize'] == '80'
          ? Generator(PaperSize.mm80, profile)
          : Generator(PaperSize.mm58, profile);
      if (chefPrinterCharacters['spacesAboveDeliverySlip'] != '0') {
        for (int i = 0;
            i < num.parse(chefPrinterCharacters['spacesAboveDeliverySlip']);
            i++) {
          deliverySlipBytes += generator.text(" ");
        }
      }
      deliverySlipBytes += generator.text("Slot:$localParcelNumber",
          styles: PosStyles(
              height: PosTextSize.size2,
              width: PosTextSize.size2,
              align: PosAlign.center));
      deliverySlipBytes += generator.text(" ");
      deliverySlipBytes += generator.text(
          "Packed:${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year} at ${DateTime.now().hour}:${DateTime.now().minute}",
          styles: PosStyles(
              height: PosTextSize.size1,
              width: PosTextSize.size1,
              align: PosAlign.center));
      if (chefPrinterCharacters['printerSize'] == '80') {
        deliverySlipBytes += generator.text(
            "-----------------------------------------------",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.center));
      } else if (chefPrinterCharacters['printerSize'] == '58') {
        deliverySlipBytes += generator.text("-------------------------------",
            styles: PosStyles(
                height: PosTextSize.size1,
                width: PosTextSize.size1,
                align: PosAlign.center));
      }

      if (localParcelReadyItemNames.length > 1) {
        for (int i = 0; i < localParcelReadyItemNames.length; i++) {
          if (chefPrinterCharacters['printerSize'] == '80') {
            if ((' '.allMatches(localParcelReadyItemNames[i]).length >= 2)) {
              String firstName = '';
              String secondName = '';
              final longItemNameSplit = localParcelReadyItemNames[i].split(' ');
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
              deliverySlipBytes += generator.row([
                PosColumn(
                  text: "$firstName",
                  styles: PosStyles(
                      align: PosAlign.left,
                      height: deliverySlipTextSize,
                      width: deliverySlipTextSize),
                  width: 10,
                ),
                PosColumn(
                  text: "${localParcelReadyNumberOfItems[i].toString()}",
                  styles: PosStyles(
                      align: PosAlign.right,
                      height: deliverySlipTextSize,
                      width: deliverySlipTextSize),
                  width: 2,
                ),
              ]);
              deliverySlipBytes += generator.row([
                PosColumn(
                  text: "$secondName",
                  styles: PosStyles(
                      align: PosAlign.left,
                      height: deliverySlipTextSize,
                      width: deliverySlipTextSize),
                  width: 10,
                ),
                PosColumn(
                  text: " ",
                  styles: PosStyles(
                      align: PosAlign.right,
                      height: deliverySlipTextSize,
                      width: deliverySlipTextSize),
                  width: 2,
                ),
              ]);
            } else {
              deliverySlipBytes += generator.row([
                PosColumn(
                  text: "${localParcelReadyItemNames[i]}",
                  styles: PosStyles(
                      align: PosAlign.left,
                      height: deliverySlipTextSize,
                      width: deliverySlipTextSize),
                  width: 10,
                ),
                PosColumn(
                  text: "${localParcelReadyNumberOfItems[i].toString()}",
                  styles: PosStyles(
                      align: PosAlign.right,
                      height: deliverySlipTextSize,
                      width: deliverySlipTextSize),
                  width: 2,
                ),
              ]);
            }

            if (localParcelReadyItemComments[i] != 'noComment') {
              deliverySlipBytes += generator.text(
                  "     (Comment : ${localParcelReadyItemComments[i]})",
                  styles: PosStyles(
                      height: PosTextSize.size1,
                      width: PosTextSize.size1,
                      align: PosAlign.left));
            }
            deliverySlipBytes += generator.text(
                "-----------------------------------------------",
                styles: PosStyles(
                    height: PosTextSize.size1,
                    width: PosTextSize.size1,
                    align: PosAlign.center));
          } else if (chefPrinterCharacters['printerSize'] == '58') {
            if ((' '.allMatches(localParcelReadyItemNames[i]).length >= 2) ||
                localParcelReadyItemNames[i].length > 14) {
              String firstName = '';
              String secondName = '';
              final longItemNameSplit = localParcelReadyItemNames[i].split(' ');
              for (int i = 0; i < longItemNameSplit.length; i++) {
                if (i == 0) {
                  firstName = longItemNameSplit[i];
                }

                if (i >= 1) {
                  secondName += '${longItemNameSplit[i]} ';
                }
              }
              deliverySlipBytes += generator.row([
                PosColumn(
                  text: "$firstName",
                  styles: PosStyles(
                      align: PosAlign.left,
                      height: deliverySlipTextSize,
                      width: deliverySlipTextSize),
                  width: 10,
                ),
                PosColumn(
                  text: "${localParcelReadyNumberOfItems[i].toString()}",
                  styles: PosStyles(
                      align: PosAlign.right,
                      height: deliverySlipTextSize,
                      width: deliverySlipTextSize),
                  width: 2,
                ),
              ]);
              deliverySlipBytes += generator.row([
                PosColumn(
                  text: "$secondName",
                  styles: PosStyles(
                      align: PosAlign.left,
                      height: deliverySlipTextSize,
                      width: deliverySlipTextSize),
                  width: 10,
                ),
                PosColumn(
                  text: " ",
                  styles: PosStyles(
                      align: PosAlign.right,
                      height: deliverySlipTextSize,
                      width: deliverySlipTextSize),
                  width: 2,
                ),
              ]);
            } else {
              deliverySlipBytes += generator.row([
                PosColumn(
                  text: "${localParcelReadyItemNames[i]}",
                  styles: PosStyles(
                      align: PosAlign.left,
                      height: deliverySlipTextSize,
                      width: deliverySlipTextSize),
                  width: 10,
                ),
                PosColumn(
                  text: "${localParcelReadyNumberOfItems[i].toString()}",
                  styles: PosStyles(
                      align: PosAlign.right,
                      height: deliverySlipTextSize,
                      width: deliverySlipTextSize),
                  width: 2,
                ),
              ]);
            }

            if (localParcelReadyItemComments[i] != 'noComment') {
              deliverySlipBytes += generator.text(
                  "     (Comment : ${localParcelReadyItemComments[i]})",
                  styles: PosStyles(
                      height: PosTextSize.size1,
                      width: PosTextSize.size1,
                      align: PosAlign.left));
            }
            deliverySlipBytes += generator.text(
                "-------------------------------",
                styles: PosStyles(
                    height: PosTextSize.size1,
                    width: PosTextSize.size1,
                    align: PosAlign.center));
          }
        }
        deliverySlipBytes += generator.text(" ");
        deliverySlipBytes += generator.text(" ");

        if (chefPrinterCharacters['printerSize'] == '80' &&
            localParcelReadyItemNames[0] != 'Printer Check') {
          deliverySlipBytes += generator.text("Note:Consume Within Two Hours",
              styles: PosStyles(
                  height: PosTextSize.size2,
                  width: PosTextSize.size2,
                  align: PosAlign.center));
        } else if (chefPrinterCharacters['printerSize'] == '58') {
          deliverySlipBytes += generator.text("Note:Consume Within Two Hours",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.left));
        }
      } else {
        if (chefPrinterCharacters['printerSize'] == '80') {
          if ((' '.allMatches(localParcelReadyItemNames[0]).length >= 2)) {
            String firstName = '';
            String secondName = '';

            final longItemNameSplit = localParcelReadyItemNames[0].split(' ');
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
            deliverySlipBytes += generator.row([
              PosColumn(
                text: "$firstName",
                styles: PosStyles(
                    align: PosAlign.left,
                    height: deliverySlipTextSize,
                    width: deliverySlipTextSize),
                width: 10,
              ),
              PosColumn(
                text: "${localParcelReadyNumberOfItems[0].toString()}",
                styles: PosStyles(
                    align: PosAlign.right,
                    height: deliverySlipTextSize,
                    width: deliverySlipTextSize),
                width: 2,
              ),
            ]);
            deliverySlipBytes += generator.row([
              PosColumn(
                text: "$secondName",
                styles: PosStyles(
                    align: PosAlign.left,
                    height: deliverySlipTextSize,
                    width: deliverySlipTextSize),
                width: 10,
              ),
              PosColumn(
                text: " ",
                styles: PosStyles(
                    align: PosAlign.right,
                    height: deliverySlipTextSize,
                    width: deliverySlipTextSize),
                width: 2,
              ),
            ]);
          } else {
            deliverySlipBytes += generator.row([
              PosColumn(
                text: "${localParcelReadyItemNames[0]}",
                styles: PosStyles(
                    align: PosAlign.left,
                    height: deliverySlipTextSize,
                    width: deliverySlipTextSize),
                width: 10,
              ),
              PosColumn(
                text: "${localParcelReadyNumberOfItems[0].toString()}",
                styles: PosStyles(
                    align: PosAlign.right,
                    height: deliverySlipTextSize,
                    width: deliverySlipTextSize),
                width: 2,
              ),
            ]);
          }

          if (localParcelReadyItemComments[0] != 'noComment') {
            deliverySlipBytes += generator.text(
                "     (Comment : ${localParcelReadyItemComments[0]})",
                styles: PosStyles(
                    height: PosTextSize.size1,
                    width: PosTextSize.size1,
                    align: PosAlign.left));
          }
          deliverySlipBytes += generator.text(
              "-----------------------------------------------",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.center));
        } else if (chefPrinterCharacters['printerSize'] == '58') {
          if ((' '.allMatches(localParcelReadyItemNames[0]).length >= 2) ||
              localParcelReadyItemNames[0].length > 14) {
            String firstName = '';
            String secondName = '';
            final longItemNameSplit = localParcelReadyItemNames[0].split(' ');
            for (int i = 0; i < longItemNameSplit.length; i++) {
              if (i == 0) {
                firstName = longItemNameSplit[i];
              }
              if (i >= 1) {
                secondName += '${longItemNameSplit[i]} ';
              }
            }
            deliverySlipBytes += generator.row([
              PosColumn(
                text: "$firstName",
                styles: PosStyles(
                    align: PosAlign.left,
                    height: deliverySlipTextSize,
                    width: deliverySlipTextSize),
                width: 10,
              ),
              PosColumn(
                text: "${localParcelReadyNumberOfItems[0].toString()}",
                styles: PosStyles(
                    align: PosAlign.right,
                    height: deliverySlipTextSize,
                    width: deliverySlipTextSize),
                width: 2,
              ),
            ]);
            deliverySlipBytes += generator.row([
              PosColumn(
                text: "$secondName",
                styles: PosStyles(
                    align: PosAlign.left,
                    height: deliverySlipTextSize,
                    width: deliverySlipTextSize),
                width: 10,
              ),
              PosColumn(
                text: " ",
                styles: PosStyles(
                    align: PosAlign.right,
                    height: deliverySlipTextSize,
                    width: deliverySlipTextSize),
                width: 2,
              ),
            ]);
          } else {
            deliverySlipBytes += generator.row([
              PosColumn(
                text: "${localParcelReadyItemNames[0]}",
                styles: PosStyles(
                    align: PosAlign.left,
                    height: deliverySlipTextSize,
                    width: deliverySlipTextSize),
                width: 10,
              ),
              PosColumn(
                text: "${localParcelReadyNumberOfItems[0].toString()}",
                styles: PosStyles(
                    align: PosAlign.right,
                    height: deliverySlipTextSize,
                    width: deliverySlipTextSize),
                width: 2,
              ),
            ]);
          }
          if (localParcelReadyItemComments[0] != 'noComment') {
            deliverySlipBytes += generator.text(
                "     (Comment : ${localParcelReadyItemComments[0]})",
                styles: PosStyles(
                    height: PosTextSize.size1,
                    width: PosTextSize.size1,
                    align: PosAlign.left));
          }
          deliverySlipBytes += generator.text("-------------------------------",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.center));
        }

        if (chefPrinterCharacters['printerSize'] == '80') {
          deliverySlipBytes += generator.text(" ");
          deliverySlipBytes += generator.text(" ");
          deliverySlipBytes += generator.text("Note:Consume Within Two Hours",
              styles: PosStyles(
                  height: PosTextSize.size2,
                  width: PosTextSize.size2,
                  align: PosAlign.center));
        } else if (chefPrinterCharacters['printerSize'] == '58') {
          deliverySlipBytes += generator.text(" ");
          deliverySlipBytes += generator.text(" ");
          deliverySlipBytes += generator.text("Note:Consume Within Two Hours",
              styles: PosStyles(
                  height: PosTextSize.size1,
                  width: PosTextSize.size1,
                  align: PosAlign.left));
        }
        if (chefPrinterCharacters['spacesBelowDeliverySlip'] != '0') {
          for (int i = 0;
              i < num.parse(chefPrinterCharacters['spacesBelowDeliverySlip']);
              i++) {
            deliverySlipBytes += generator.text(" ");
          }
        }
      }
      deliverySlipBytes += generator.cut();
      if (chefPrinterCharacters['printerBluetoothAddress'] != 'NA' ||
          chefPrinterCharacters['printerIPAddress'] != 'NA') {
        _connectDeviceForDeliverySlip();
      } else {
//InCaseUsbPrinterIsNotConnected,WeDontHaveWayToScan.Hence,WeScanAndThenGoIn
        _scanForUsbForDeliverySlipPrint();
      }
    }

    print('end of inside after Order Ready Bytes Generator');
  }

  _scanForUsbForDeliverySlipPrint() async {
    bool addedUSBDeviceNotAvailable = true;
//UnlikeBluetoothWeDontHavePerfectAvailableOrNotFeedbackForUsb
//HenceMakingScanForUsbDeviceEveryTimePrintIsCalled
    devices.clear();
    _subscription =
        printerManager.discovery(type: PrinterType.usb).listen((device) {
      if (device.vendorId.toString() ==
          chefPrinterCharacters['printerUsbVendorID']) {
        addedUSBDeviceNotAvailable = false;
        _connectDeviceForDeliverySlip();
      }
    });
    Timer(Duration(seconds: 2), () {
      if (addedUSBDeviceNotAvailable) {
        printerManager.disconnect(type: PrinterType.usb);
        setState(() {
          showSpinner = false;
          usbDeliverySlipConnect = false;
          usbDeliverySlipConnectTried = false;
          _isConnected = false;
        });
        playPrinterError();
        showMethodCaller('${chefPrinterCharacters['printerName']} not found');
      }
    });
  }

  _connectDeviceForDeliverySlip() async {
    chefPrinterType = chefPrinterCharacters['printerUsbProductID'] != 'NA'
        ? PrinterType.usb
        : chefPrinterCharacters['printerBluetoothAddress'] != 'NA'
            ? PrinterType.bluetooth
            : PrinterType.network;
    _isConnected = false;
    setState(() {
      showSpinner = true;
    });
    switch (chefPrinterType) {
      case PrinterType.usb:
        printerManager.disconnect(type: PrinterType.usb);
        usbDeliverySlipConnectTried = true;
        await printerManager.connect(
            type: chefPrinterType,
            model: UsbPrinterInput(
                name: chefPrinterCharacters['printerManufacturerDeviceName'],
                productId: chefPrinterCharacters['printerUsbProductID'],
                vendorId: chefPrinterCharacters['printerUsbVendorID']));
        usbDeliverySlipConnect = true;
        _isConnected = true;
        setState(() {
          showSpinner = true;
        });
        break;
      case PrinterType.bluetooth:
        bluetoothDeliverySlipConnectTried = true;
        bluetoothDeliverySlipConnect = false;
        bluetoothOnTrueOrOffFalse = false;
        timerToCheckBluetoothOnOrOff();
        await printerManager.connect(
            type: chefPrinterType,
            model: BluetoothPrinterInput(
                name: chefPrinterCharacters['printerManufacturerDeviceName'],
                address: chefPrinterCharacters['printerBluetoothAddress'],
                isBle: false,
                autoConnect: _reconnect));
        bluetoothDeliverySlipConnect = true;
        break;
      case PrinterType.network:
        printWithNetworkPrinterForDeliverySlip();
        break;
      default:
    }

    setState(() {});
  }

  void printThroughBluetoothOrUsbForDeliverySlip() {
    printerManager.send(type: chefPrinterType, bytes: deliverySlipBytes);
    if (chefPrinterType == PrinterType.bluetooth) {
      showMethodCaller('Print SUCCESS...Disconnecting...');
    }
    Timer(Duration(seconds: 1), () {
      disconnectBluetoothOrUsbForDeliverySlip();
    });
  }

  void disconnectBluetoothOrUsbForDeliverySlip() {
    printerManager.disconnect(type: chefPrinterType);
    deliverySlipPrinting = false;
    localParcelNumber = '';
    localParcelReadyItemNames = [];
    localParcelReadyNumberOfItems = [];
    localParcelReadyItemComments = [];

    chefPrinterType == PrinterType.bluetooth
        ? Timer(Duration(seconds: 2), () {
            setState(() {
              showSpinner = false;
              usbDeliverySlipConnect = false;
              usbDeliverySlipConnectTried = false;
              bluetoothDeliverySlipConnect = false;
              bluetoothDeliverySlipConnectTried = false;
              _isConnected = false;
              printingOver = true;
            });
          })
        : Timer(Duration(milliseconds: 500), () {
            setState(() {
              showSpinner = false;
              usbDeliverySlipConnect = false;
              usbDeliverySlipConnectTried = false;
              bluetoothDeliverySlipConnect = false;
              bluetoothDeliverySlipConnectTried = false;
              _isConnected = false;
              printingOver = true;
            });
          });
  }

  Future<void> printWithNetworkPrinterForDeliverySlip() async {
    final printer =
        PrinterNetworkManager(chefPrinterCharacters['printerIPAddress']);
    PosPrintResult connect = await printer.connect();
    if (connect == PosPrintResult.success) {
      PosPrintResult printing =
          await printer.printTicket(Uint8List.fromList(deliverySlipBytes));
      printer.disconnect();
      localParcelNumber = '';
      localParcelReadyItemNames = [];
      localParcelReadyNumberOfItems = [];
      localParcelReadyItemComments = [];
      deliverySlipPrinting = false;
      setState(() {
        showSpinner = false;
        _isConnected = false;
        printingOver = true;
      });
    } else {
      playPrinterError();
      deliverySlipPrinting = false;

      setState(() {
        showSpinner = false;
        _isConnected = false;
      });
      if (!appInBackground) {
        showMethodCaller('Unable To Connect. Please Check Printer');
      }
    }
  }

  @override
  void initState() {
    print('inside initState');
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
    // methodForChefWontCook();
    requestLocationPermission();
    deliverySlipPrinting = false;
    showSpinner = false;
    printingOver = true;
    timeForKot = 1;
    kotCounter = 0;
    localKOTItemNames = [];
    tempLocalKOTItemNames = [];
    tempLocalKOTItemsID = [];
    _everySecondForKot = 0;
    _everySecondForKotTimer = 0;
    timerForPrintingKOTRunning = false;
    timerForPrintingTenSecKOTRunning = false;
    serverUpdateAfterKotPrintIsOver = true;

    appInBackground = false;
    timerRunningForCheckingNewOrdersInBackground = false;
    backgroundTimerCounter = 0;
    // thisIsChefCallingForBackground = true;
    // hotelNameForBackground = widget.hotelName;
    // chefSpecialitiesForBackground = widget.chefSpecialities;
    // FlutterBackground.initialize();
    Wakelock.enable();

    // subscription to listen change status of bluetooth connection
    _subscriptionBtStatus =
        PrinterManager.instance.stateBluetooth.listen((status) {
//OnlyIfBluetoothIsOnWeCanEvenGetIntoThisLoop
//IfBluetoothIsOffWeCanGiveShowMessageSomewhere
      bluetoothOnTrueOrOffFalse = true;
      _currentStatus = status;
      // print('Bluetooth status $status');

      if (status == BTStatus.connecting &&
          ((!bluetoothKotConnect && bluetoothKotConnectTried) ||
              (!bluetoothDeliverySlipConnect &&
                  bluetoothDeliverySlipConnectTried))) {
        intermediateTimerBeforeCheckingBluetoothConnectionSuccess();
      }

      if (status == BTStatus.connected) {
        printerConnectionSuccessCheckRandomNumber = 0;
        if (bluetoothKotConnect) {
          printThroughBluetoothOrUsb();
        }
        if (bluetoothDeliverySlipConnect) {
          printThroughBluetoothOrUsbForDeliverySlip();
        }
        setState(() {
          _isConnected = true;
        });
      }
      if (status == BTStatus.none) {
        printerConnectionSuccessCheckRandomNumber = 0;
        if (bluetoothKotConnect || bluetoothKotConnectTried) {
          printerManager.disconnect(type: PrinterType.bluetooth);
          if (timerForPrintingKOTRunning == false &&
              timerForPrintingTenSecKOTRunning == false &&
              deliverySlipPrinting == false &&
              serverUpdateAfterKotPrintIsOver) {
            timerForPrintingKOTTenSeconds();
          }
          playPrinterError();
          if (!appInBackground) {
            showMethodCaller('Unable To Connect. Please Check Printer');
          }
          bluetoothKotConnect = false;
          bluetoothKotConnectTried = false;
        }
        if (bluetoothDeliverySlipConnect || bluetoothDeliverySlipConnectTried) {
          printerManager.disconnect(type: PrinterType.bluetooth);
          deliverySlipPrinting = false;
          playPrinterError();
          showMethodCaller('Unable To Connect. Please Check Printer');
          bluetoothDeliverySlipConnect = false;
          bluetoothDeliverySlipConnectTried = false;
        }
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
        if (usbKotConnect) {
          printThroughBluetoothOrUsb();
        }
        if (usbDeliverySlipConnect) {
          printThroughBluetoothOrUsbForDeliverySlip();
        }
      } else if (status == USBStatus.none) {
        printerManager.disconnect(type: PrinterType.usb);
        if (usbKotConnect || usbKotConnectTried) {
          playPrinterError();
          if (!appInBackground) {
            showMethodCaller('Unable To Connect. Please Check Printer');
          }
          usbKotConnect = false;
          usbKotConnectTried = false;
          if (timerForPrintingKOTRunning == false &&
              timerForPrintingTenSecKOTRunning == false &&
              deliverySlipPrinting == false &&
              serverUpdateAfterKotPrintIsOver) {
            timerForPrintingKOTTenSeconds();
          }
        }
        if (usbDeliverySlipConnect || usbDeliverySlipConnectTried) {
          deliverySlipPrinting = false;
          playPrinterError();
          showMethodCaller('Unable To Connect. Please Check Printer');
          usbDeliverySlipConnect = false;
          usbDeliverySlipConnectTried = false;
        }
        setState(() {
          showSpinner = false;
          _isConnected = false;
        });
      }
    });

    super.initState();
  }

  void rebirth() {
    Phoenix.rebirth(context);
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
      if (bluetoothDeliverySlipConnectTried) {
        if (!bluetoothDeliverySlipConnect) {
          int randomNumberGenerationForThisAttempt =
              (1000000 + Random().nextInt(9999999 - 1000000));
          printerConnectionSuccessCheckRandomNumber =
              randomNumberGenerationForThisAttempt;
          timerForCheckingBluetoothConnectionSuccess(
              randomNumberGenerationForThisAttempt);
        }
      } else if (bluetoothKotConnectTried) {
        if (!bluetoothKotConnect) {
          int randomNumberGenerationForThisAttempt =
              (1000000 + Random().nextInt(9999999 - 1000000));
          printerConnectionSuccessCheckRandomNumber =
              randomNumberGenerationForThisAttempt;
          timerForCheckingBluetoothConnectionSuccess(
              randomNumberGenerationForThisAttempt);
        }
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
      // FlutterBackground.enableBackgroundExecution();
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
      setState(() {
        appInBackground = false;
      });
      backgroundTimerCounter = 0;
      // FlutterBackground.initialize();
      NotificationService().cancelAllNotifications();
      // FlutterBackground.disableBackgroundExecution();

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
          timerRunningForCheckingNewOrdersInBackground = false;
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

  void currentNewOrdersCheckInBackground() async {
    // bool enabled = FlutterBackground.isBackgroundExecutionEnabled;
    // print('enabled $enabled');
    // NotificationService()
    //     .showNotification(title: 'Orders', body: 'We are looking for Updates');

    backgroundTimerCounter++;
    print('background called $backgroundTimerCounter');
    if (backgroundTimerCounter < 361) {
      final presentOrdersCheck = await FirebaseFirestore.instance
          .collection(widget.hotelName)
          .doc('runningorders')
          .collection('runningorders')
          .where('statusMap.${'chefStatus'}', isEqualTo: 9)
          .get();
//WeFirstMake "SomeNewItemsOrdered" AsFalse
      someNewItemsOrdered = false;
      List<String> kotItemNames = [];
      List<num> kotNumberOfOrderedItems = [];
      List<String> kotItemsBelongsToDoc = [];
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
      DateTime now = DateTime.now();

//WeGoThrough "EachNewOrder" ByGoingThroughTheDocs
      num presentOrderSizeCounter = 0;
      for (var eachDoc in presentOrdersCheck.docs) {
        presentOrderSizeCounter++;
        if (Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .chefPrinterKOTFromClass) {
          Map<String, dynamic> eachDocBaseInfoMap = eachDoc['baseInfoMap'];
          String tableorparcel = eachDocBaseInfoMap['tableOrParcel'];
          num tableorparcelnumber =
              num.parse(eachDocBaseInfoMap['tableOrParcelNumber']);
          String parentOrChild = eachDocBaseInfoMap['parentOrChild'];
          num timecustomercametoseat =
              num.parse(eachDocBaseInfoMap['startTime']);

          num currentTimeHourMinuteMultiplied = ((now.hour * 3600000) +
              (now.minute * 60000) +
              (now.second * 1000) +
              now.millisecond);
          Map<String, dynamic> eachDocItemsInOrderMap =
              eachDoc['itemsInOrderMap'];
          eachDocItemsInOrderMap.forEach((key, value) {
            mapToAddIntoBackgroundItems = {};
            if (value['itemCancelled'] != 'false') {
//ThisIsCancelledItem
              cancelledItemsKey.add(key);
            }
            mapToAddIntoBackgroundItems['cancelledItemTrueElseFalse'] =
                value['itemCancelled'];
            mapToAddIntoBackgroundItems['tableorparcel'] = tableorparcel;
            mapToAddIntoBackgroundItems['tableorparcelnumber'] =
                tableorparcelnumber;
            mapToAddIntoBackgroundItems['parentOrChild'] = parentOrChild;
            mapToAddIntoBackgroundItems['timecustomercametoseat'] =
                timecustomercametoseat;
            mapToAddIntoBackgroundItems['nowMinusTimeCustomerCameToSeat'] =
                currentTimeHourMinuteMultiplied - timecustomercametoseat;
            mapToAddIntoBackgroundItems['eachiteminorderid'] = key;
            mapToAddIntoBackgroundItems['item'] = value['itemName'];
            mapToAddIntoBackgroundItems['priceofeach'] = value['itemPrice'];
            mapToAddIntoBackgroundItems['number'] = value['numberOfItem'];
            mapToAddIntoBackgroundItems['timeoforder'] =
                value['orderTakingTime'];
            mapToAddIntoBackgroundItems['nowTimeMinusThisItemOrderedTime'] =
                (currentTimeHourMinuteMultiplied -
                    num.parse(value['orderTakingTime']));
            mapToAddIntoBackgroundItems['commentsForTheItem'] =
                value['itemComment'];
            mapToAddIntoBackgroundItems['statusoforder'] = value['itemStatus'];
            mapToAddIntoBackgroundItems['chefKotStatus'] = value['chefKOT'];
            mapToAddIntoBackgroundItems['ticketNumber'] =
                value['ticketNumberOfItem'];
            mapToAddIntoBackgroundItems['itemBelongsToDoc'] = eachDoc.id;
            backgroundItems.add(mapToAddIntoBackgroundItems);
          });
          if (presentOrderSizeCounter == presentOrdersCheck.size) {
            counterForKOT = 0;
            for (var backgroundItem in backgroundItems) {
              counterForKOT++;
              if (backgroundItem['chefKotStatus'] == 'chefkotnotyet' &&
                  !(json.decode(Provider.of<PrinterAndOtherDetailsProvider>(
                                  context,
                                  listen: false)
                              .allUserProfilesFromClass)[
                          Provider.of<PrinterAndOtherDetailsProvider>(context,
                                  listen: false)
                              .currentUserPhoneNumberFromClass]['wontCook'])
                      .contains(backgroundItem['item'])) {
                kotItemNames.add(backgroundItem['item']);
                kotNumberOfOrderedItems.add(backgroundItem['number']);
                kotItemsComments.add(backgroundItem['commentsForTheItem']);
                kotItemsBelongsToDoc.add(backgroundItem['itemBelongsToDoc']);
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
                  kotItemNames.isNotEmpty) {
                print('got into this 3');
                printingOver = false;
                localKOTItemNames = kotItemNames;
                localKOTNumberOfItems = kotNumberOfOrderedItems;
                localKOTItemComments = kotItemsComments;
                localKotItemsBelongsToDoc = kotItemsBelongsToDoc;
                localKotItemsTableOrParcel = kotItemsTableOrParcel;
                localKotItemsTableOrParcelNumber = kotItemsTableOrParcelNumber;
                localKotItemsParentOrChild = kotItemsParentOrChild;
                localKotItemsTicketNumber = kotItemsTicketNumber;
                localKotCancelledItemTrueElseFalse =
                    kotCancelledItemTrueElseFalse;
                localKOTItemsID = kotItemsID;

                if (bluetoothOnTrueOrOffFalse == false) {
                  playPrinterError();
                } else if (!listEquals(tempLocalKOTItemsID, localKOTItemsID) ||
                    cancelledItemsKey.isNotEmpty) {
                  if (bluetoothOnTrueOrOffFalse &&
                      timerForPrintingKOTRunning == false &&
                      timerForPrintingTenSecKOTRunning == false &&
                      serverUpdateAfterKotPrintIsOver) {
                    print('called print again');
                    timerForPrintingKOT();
                  }
                } else {
                  print('nothing needed');
                }
              }
            }
          }
        } else {
          print('counter $presentOrderSizeCounter');
          if (eachDoc['statusMap']['chefStatus'] == 9) {
            someNewItemsOrdered = true;
          }

          if (presentOrderSizeCounter == presentOrdersCheck.size) {
            print('counter end $presentOrderSizeCounter');
            if (someNewItemsOrdered) {
              playCookTrim();
            }
          }
        }
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
  }

// PlayCookIsTheMethodToPlayMusic
// WeFirstCheckWhetherPlayerIsPlaying
// ifItIsFalse,Then WeGivePlayerPlay and WeGive AssetSourceWhichIsTheSource,,
// ofTheFile and WeAlsoChangePlayerStateToPlaying
// WeChangePlayerPlayingToTrue

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

  void timerForPrintingKOT() {
    timerForPrintingKOTRunning = true;
    Timer(Duration(seconds: 4), () {
      tempLocalKOTItemsID = localKOTItemsID;
      timerForPrintingKOTRunning = false;
      if (localKOTItemNames.isNotEmpty) {
        if (Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .chefAssignedPrinterFromClass ==
            '{}') {
//ThisMeansNoPrinterHadBeenAssigned
          playPrinterError();
          show('Please Assign Chef Printer');
        } else {
          chefPrinterAssigningMap = json.decode(
              Provider.of<PrinterAndOtherDetailsProvider>(context,
                      listen: false)
                  .chefAssignedPrinterFromClass);
          chefPrinterAssigningMap.forEach((key, value) {
            chefPrinterRandomID = key;
          });
          printerSavingMap = json.decode(
              Provider.of<PrinterAndOtherDetailsProvider>(context,
                      listen: false)
                  .savedPrintersFromClass);
          chefPrinterCharacters = printerSavingMap[chefPrinterRandomID];
          bytesGeneratorForKot();
          // printerConnectionToLastSavedPrinterForKOT();
        }
      }
    });
//
//     Timer? _timerToGoForSmallKot;
//     _timerToGoForSmallKot =
//         Timer.periodic(const Duration(seconds: 1), (_) async {
// //ThisWillEnsureOnlyWhenNewItemsComeNextTime,itWillBePrinted
//       tempLocalKOTItemsID = localKOTItemsID;
//       print('__everySecondForKotTimer inside timer $_everySecondForKotTimer');
//       if (_everySecondForKotTimer < 3) {
//         timerForPrintingKOTRunning = true;
//         _everySecondForKotTimer++;
//         print('_everySecondForKotTimer $_everySecondForKotTimer');
//       } else if (_everySecondForKotTimer == 3) {
//         timerForPrintingKOTRunning = false;
//         print('came inside bluetooth On Point3');
//         if (localKOTItemNames.isNotEmpty) {
//           if (Provider.of<PrinterAndOtherDetailsProvider>(context,
//                       listen: false)
//                   .chefAssignedPrinterFromClass ==
//               '{}') {
// //ThisMeansNoPrinterHadBeenAssigned
//             playPrinterError();
//             show('Please Assign Chef Printer');
//           }
//           else {
//             chefPrinterAssigningMap = json.decode(
//                 Provider.of<PrinterAndOtherDetailsProvider>(context,
//                         listen: false)
//                     .chefAssignedPrinterFromClass);
//             chefPrinterAssigningMap.forEach((key, value) {
//               chefPrinterRandomID = key;
//             });
//             printerSavingMap = json.decode(
//                 Provider.of<PrinterAndOtherDetailsProvider>(context,
//                         listen: false)
//                     .savedPrintersFromClass);
//             chefPrinterCharacters = printerSavingMap[chefPrinterRandomID];
//             bytesGeneratorForKot();
//             // printerConnectionToLastSavedPrinterForKOT();
//           }
//         }
//         _everySecondForKotTimer++;
//
//         _timerToGoForSmallKot!.cancel();
//       } else {
//         timerForPrintingKOTRunning = false;
//         _timerToGoForSmallKot!.cancel();
//       }
//     });
  }

  void timerForPrintingKOTTenSeconds() {
    timerForPrintingTenSecKOTRunning = true;

    Timer(Duration(seconds: 9), () {
      tempLocalKOTItemsID = localKOTItemsID;
      timerForPrintingTenSecKOTRunning = false;
      if (localKOTItemNames.isNotEmpty &&
          Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .chefPrinterKOTFromClass) {
        if (Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .chefAssignedPrinterFromClass ==
            '{}') {
//ThisMeansNoPrinterHadBeenAssigned
          playPrinterError();
          show('Please Assign Chef Printer');
        } else {
          chefPrinterAssigningMap = json.decode(
              Provider.of<PrinterAndOtherDetailsProvider>(context,
                      listen: false)
                  .chefAssignedPrinterFromClass);
          chefPrinterAssigningMap.forEach((key, value) {
            chefPrinterRandomID = key;
          });
          printerSavingMap = json.decode(
              Provider.of<PrinterAndOtherDetailsProvider>(context,
                      listen: false)
                  .savedPrintersFromClass);
          chefPrinterCharacters = printerSavingMap[chefPrinterRandomID];
          bytesGeneratorForKot();
          // printerConnectionToLastSavedPrinterForKOT();
        }
      }
    });

//     Timer? _timerToGoForTenSecondsKot;
//     _timerToGoForTenSecondsKot =
//         Timer.periodic(const Duration(seconds: 1), (_) async {
//       tempLocalKOTItemsID = localKOTItemsID;
//       print(
//           '__everySecondForKotTenSecTimer inside timer $_everySecondForKotTimer');
//       if (_everySecondForKotTimer < 8) {
//         timerForPrintingTenSecKOTRunning = true;
//         _everySecondForKotTimer++;
//         print('_everySecondForKotTenSecKotTimer $_everySecondForKotTimer');
//       }
//       else if (_everySecondForKotTimer == 8) {
//         timerForPrintingTenSecKOTRunning = false;
//         print('came inside bluetooth On Point4');
//         if (localKOTItemNames.isNotEmpty &&
//             Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
//                 .chefPrinterKOTFromClass) {
//           print('What is chef assigned Printer');
//           print(Provider.of<PrinterAndOtherDetailsProvider>(context,
//                   listen: false)
//               .chefAssignedPrinterFromClass);
//
//           if (Provider.of<PrinterAndOtherDetailsProvider>(context,
//                       listen: false)
//                   .chefAssignedPrinterFromClass ==
//               '{}') {
//             print('why not inside here');
// //ThisMeansNoPrinterHadBeenAssigned
//             playPrinterError();
//             show('Please Assign Chef Printer');
//           } else {
//             chefPrinterAssigningMap = json.decode(
//                 Provider.of<PrinterAndOtherDetailsProvider>(context,
//                         listen: false)
//                     .chefAssignedPrinterFromClass);
//             chefPrinterAssigningMap.forEach((key, value) {
//               chefPrinterRandomID = key;
//             });
//             printerSavingMap = json.decode(
//                 Provider.of<PrinterAndOtherDetailsProvider>(context,
//                         listen: false)
//                     .savedPrintersFromClass);
//             chefPrinterCharacters = printerSavingMap[chefPrinterRandomID];
//             bytesGeneratorForKot();
//             // printerConnectionToLastSavedPrinterForKOT();
//           }
//         }
//         _everySecondForKotTimer++;
//
//         _timerToGoForTenSecondsKot!.cancel();
//       }
//       else {
//         timerForPrintingTenSecKOTRunning = false;
//         _timerToGoForTenSecondsKot!.cancel();
//       }
//     });
  }

  void statusUpdaterInFireStoreForRunningOrders(String itemID,
      String itemBelongsToDoc, num newStatusToUpdate, String chefKOTPrinted) {
    Map<String, dynamic> statusMap = HashMap();
    if (newStatusToUpdate == 11) {
      //ToShowThatTheItemHasBeenRejected
      statusMap.addAll({'captainStatus': 11});
//ToShowThatChefHasLookedAtTheOrder
      statusMap.addAll({'chefStatus': 7});
    } else if (newStatusToUpdate == 10) {
//ToShowThatHeHasReadiedTheOrderForTheCaptain
      statusMap.addAll({'captainStatus': 10});
//ToShowThatHeHasAcceptedTheOrder
      statusMap.addAll({'chefStatus': 7});
    } else {
      //ToShowThatHeHasAcceptedTheOrder
      statusMap.addAll({'chefStatus': 7});
    }
    Map<String, dynamic> tempMapToUpdateStatus = HashMap();
    tempMapToUpdateStatus.addAll({'itemStatus': newStatusToUpdate});

    if (chefKOTPrinted != 'dontTouch') {
      tempMapToUpdateStatus.addAll({'chefKOT': chefKOTPrinted});
    }

    Map<String, dynamic> masterOrderMapToServer = HashMap();
    masterOrderMapToServer.addAll({
      'itemsInOrderMap': {itemID: tempMapToUpdateStatus}
    });

    masterOrderMapToServer.addAll({'statusMap': statusMap});

    FireStoreAddOrderInRunningOrderFolder(
            hotelName: widget.hotelName,
            seatingNumber: itemBelongsToDoc,
            ordersMap: masterOrderMapToServer)
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
    final fcmProvider = Provider.of<NotificationProvider>(context);
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

        Navigator.pop(context);

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

                Navigator.pop(context);

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
                          builder: (context) => PrinterRolesAssigning()));
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
                      .doc('runningorders')
                      .collection('runningorders')
                      .snapshots(),
                  builder: (context, snapshot) {
                    //ThisOrderedItemsAndNumberOfItemsBelongToTheSameSet
                    List<String> orderedItems = [];
                    List<num> numberOfOrderedItems = [];
                    List<String> allItemsID = [];
                    List<num> allItemsStatus = [];
                    List<String> allItemsBelongsToDoc = [];
                    List<String> allItemsComments = [];
                    List<String> allItemsCancelledTrueElseFalse = [];
                    //addingNewSetForCancelledItems
                    List<String> cancelledItems = [];
                    List<num> numberOfCancelledItems = [];
                    List<String> cancelledItemsID = [];
                    List<num> cancelledItemsStatus = [];
                    List<String> cancelledItemsBelongsToDoc = [];

                    List<String> cancelledItemsComments = [];
                    List<String> cancelledItemsCancelledTrueElseFalse = [];
                    //addingNewSetForCancelledItems
                    List<String> acceptedItems = [];
                    List<num> numberOfAcceptedItems = [];
                    List<String> acceptedItemsID = [];
                    List<num> acceptedItemsStatus = [];
                    List<String> acceptedItemsBelongsToDoc = [];
                    List<String> acceptedItemsComments = [];
                    List<String> acceptedItemsCancelledTrueElseFalse = [];
                    List<String> readyItems = [];
                    List<num> numberOfReadyItems = [];
                    List<String> readyItemsID = [];
                    List<num> readyItemsStatus = [];
                    List<String> readyItemsBelongsToDoc = [];
                    List<String> readyItemsComments = [];
                    List<String> readyItemsCancelledTrueElseFalse = [];
                    List<String> rejectedItems = [];
                    List<num> numberOfRejectedItems = [];
                    List<String> rejectedItemsID = [];
                    List<num> rejectedItemsStatus = [];
                    List<String> rejectedItemsBelongsToDoc = [];
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
                        Map<String, dynamic>? tempMap =
                            eachDoc.data() as Map<String, dynamic>?;
                        if (tempMap!.containsKey('baseInfoMap') &&
                            tempMap!.containsKey('itemsInOrderMap') &&
                            tempMap!.containsKey('partOfTableOrParcel') &&
                            tempMap!.containsKey('partOfTableOrParcelNumber') &&
                            tempMap!.containsKey('statusMap') &&
                            tempMap!.containsKey('ticketsMap')) {
                          Map<String, dynamic> eachDocBaseInfoMap =
                              eachDoc['baseInfoMap'];
                          String tableorparcel =
                              eachDocBaseInfoMap['tableOrParcel'];
                          num tableorparcelnumber = num.parse(
                              eachDocBaseInfoMap['tableOrParcelNumber']);
                          String parentOrChild =
                              eachDocBaseInfoMap['parentOrChild'];
                          num timecustomercametoseat =
                              num.parse(eachDocBaseInfoMap['startTime']);

                          num currentTimeHourMinuteMultiplied =
                              ((now.hour * 3600000) +
                                  (now.minute * 60000) +
                                  (now.second * 1000) +
                                  now.millisecond);
                          Map<String, dynamic> eachDocItemsInOrderMap =
                              eachDoc['itemsInOrderMap'];

                          eachDocItemsInOrderMap.forEach((key, value) {
                            if (value.length > 8) {
                              mapToAddIntoItems = {};
                              if (value['itemCancelled'] != 'false') {
//ThisIsCancelledItem
                                cancelledItemsKey.add(key);
                              }
                              mapToAddIntoItems['cancelledItemTrueElseFalse'] =
                                  value['itemCancelled'];
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
                              mapToAddIntoItems['eachiteminorderid'] = key;
                              mapToAddIntoItems['item'] = value['itemName'];
                              mapToAddIntoItems['priceofeach'] =
                                  value['itemPrice'];
                              mapToAddIntoItems['number'] =
                                  value['numberOfItem'];
                              mapToAddIntoItems['timeoforder'] =
                                  value['orderTakingTime'];
                              mapToAddIntoItems[
                                      'nowTimeMinusThisItemOrderedTime'] =
                                  (currentTimeHourMinuteMultiplied -
                                      num.parse(value['orderTakingTime']));
                              mapToAddIntoItems['commentsForTheItem'] =
                                  value['itemComment'];
                              mapToAddIntoItems['statusoforder'] =
                                  value['itemStatus'];
                              mapToAddIntoItems['chefKotStatus'] =
                                  value['chefKOT'];
                              mapToAddIntoItems['ticketNumber'] =
                                  value['ticketNumberOfItem'];
                              mapToAddIntoItems['itemBelongsToDoc'] =
                                  eachDoc.id;
                              items.add(mapToAddIntoItems);
                            } else {
                              if (eachDocItemsInOrderMap.length == 1) {
//ThisMeansThatThereIsOnlyThatWrongItemInThatTableAndHence
//TheWholeTableNeedsToBeDeleted
                                FireStoreDeleteFinishedOrderInRunningOrders(
                                        hotelName: widget.hotelName,
                                        eachTableId: eachDoc.id)
                                    .deleteFinishedOrder();
                              } else {
                                Map<String, dynamic> masterOrderMapToServer =
                                    HashMap();
//ToDeleteCancelledItem
                                masterOrderMapToServer.addAll({
                                  'itemsInOrderMap': {key: FieldValue.delete()},
                                });
//ToSayThatTheChefHasSeenTheCancellation
                                masterOrderMapToServer.addAll({
                                  'statusMap': {
                                    'chefStatus': 7,
                                    'captainStatus': 7,
                                  },
                                });
                                FireStoreAddOrderInRunningOrderFolder(
                                        hotelName: widget.hotelName,
                                        seatingNumber: eachDoc.id,
                                        ordersMap: masterOrderMapToServer)
                                    .addOrder();
                              }

//TheseAreWrongItemsThatNeedsToBeDeleted
                            }
                          });
                        } else {
                          FireStoreDeleteFinishedOrderInRunningOrders(
                                  hotelName: widget.hotelName,
                                  eachTableId: eachDoc.id)
                              .deleteFinishedOrder();
                        }
                      }

//creatingNewListToPrintKOTandAlsoUpdateKOTInServer
                      List<String> kotItemNames = [];
                      List<num> kotNumberOfOrderedItems = [];
                      List<String> kotItemsBelongsToDoc = [];
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
                                !(json.decode(Provider.of<
                                                PrinterAndOtherDetailsProvider>(
                                            context,
                                            listen: false)
                                        .allUserProfilesFromClass)[Provider.of<
                                                PrinterAndOtherDetailsProvider>(
                                            context,
                                            listen: false)
                                        .currentUserPhoneNumberFromClass]['wontCook'])
                                    .contains(item['item'])) {
                              kotItemNames.add(item['item']);
                              kotNumberOfOrderedItems.add(item['number']);
                              kotItemsComments.add(item['commentsForTheItem']);
                              kotItemsBelongsToDoc
                                  .add(item['itemBelongsToDoc']);
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
                                !(json.decode(Provider.of<
                                                PrinterAndOtherDetailsProvider>(
                                            context,
                                            listen: false)
                                        .allUserProfilesFromClass)[Provider.of<
                                                PrinterAndOtherDetailsProvider>(
                                            context,
                                            listen: false)
                                        .currentUserPhoneNumberFromClass]['wontCook'])
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
                          localKotItemsTableOrParcel = kotItemsTableOrParcel;
                          localKotItemsTableOrParcelNumber =
                              kotItemsTableOrParcelNumber;
                          localKotItemsParentOrChild = kotItemsParentOrChild;
                          localKotItemsTicketNumber = kotItemsTicketNumber;
                          localKotCancelledItemTrueElseFalse =
                              kotCancelledItemTrueElseFalse;
                          localKOTItemsID = kotItemsID;

                          if (!listEquals(
                                  tempLocalKOTItemsID, localKOTItemsID) ||
                              cancelledItemsKey.isNotEmpty) {
                            print('came into temp also');
                            print(tempLocalKOTItemsID);
                            print(localKOTItemsID);
                            if (bluetoothOnTrueOrOffFalse &&
                                timerForPrintingKOTRunning == false &&
                                timerForPrintingTenSecKOTRunning == false &&
                                deliverySlipPrinting == false &&
                                serverUpdateAfterKotPrintIsOver) {
                              print('called print again');
                              timerForPrintingKOT();
                            }
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
                      // List<Map<String, dynamic>> reverseList =
                      //     items.reversed.toList();
                      // items = reverseList;

                      for (var item in items) {
//WeSeparateItemsFromTheDocument-itemName,TableOrParcelNumber
                        String itemNameAsString = item['item'];
                        String tableOrParcelNumberAsString =
                            item['tableorparcelnumber'].toString();
                        String parentOrChildAsString = item['parentOrChild'];

                        //IfLoopHereToEnsureOnlyCook'sSpecialitiesAreEnteredHere
//IfLoopToEliminateTheListOfItemsTheChefWon'tCook
                        if (!(json.decode(
                                Provider.of<PrinterAndOtherDetailsProvider>(
                                        context,
                                        listen: false)
                                    .allUserProfilesFromClass)[Provider.of<
                                        PrinterAndOtherDetailsProvider>(context,
                                    listen: false)
                                .currentUserPhoneNumberFromClass]['wontCook'])
                            .contains(item['item'])) {
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
                      allItemsComments.insertAll(0, acceptedItemsComments);
                      allItemsCancelledTrueElseFalse.insertAll(
                          0, acceptedItemsCancelledTrueElseFalse);

                      orderedItems.insertAll(0, readyItems);
                      numberOfOrderedItems.insertAll(0, numberOfReadyItems);
                      allItemsID.insertAll(0, readyItemsID);
                      allItemsStatus.insertAll(0, readyItemsStatus);
                      allItemsBelongsToDoc.insertAll(0, readyItemsBelongsToDoc);
                      allItemsComments.insertAll(0, readyItemsComments);
                      allItemsCancelledTrueElseFalse.insertAll(
                          0, readyItemsCancelledTrueElseFalse);

                      orderedItems.insertAll(0, rejectedItems);
                      numberOfOrderedItems.insertAll(0, numberOfRejectedItems);
                      allItemsID.insertAll(0, rejectedItemsID);
                      allItemsStatus.insertAll(0, rejectedItemsStatus);
                      allItemsBelongsToDoc.insertAll(
                          0, rejectedItemsBelongsToDoc);
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
                                                  statusUpdaterInFireStoreForRunningOrders(
                                                      itemID,
                                                      itemBelongsToDoc,
                                                      7,
                                                      'dontTouch');
                                                } else if (!cancelledItemsKey
                                                        .contains(itemID) &&
                                                    statusOfOrderedItem == 7) {
                                                  fcmProvider.sendNotification(
                                                      token:
                                                          dynamicTokensToStringToken(),
                                                      title: widget.hotelName,
                                                      restaurantNameForNotification: json.decode(Provider
                                                              .of<PrinterAndOtherDetailsProvider>(
                                                                  context,
                                                                  listen: false)
                                                          .allUserProfilesFromClass)[Provider
                                                              .of<PrinterAndOtherDetailsProvider>(
                                                                  context,
                                                                  listen: false)
                                                          .currentUserPhoneNumberFromClass]['restaurantName'],
                                                      body: '*itemReadyRejectedCaptainAlert*');
//sayingOrderIsReadyIfAlreadyAcceptedAndUpdatingStatusInFireStore
                                                  statusUpdaterInFireStoreForRunningOrders(
                                                      itemID,
                                                      itemBelongsToDoc,
                                                      10,
                                                      'dontTouch');
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
//WhenWeAddedItemNamesToAllListsLikeRejected,Ready,Accepted,WeMadeAnExtraSpaceForBeauty
//RemovingTheSpaceHere
                                                    parcelReadyItemNames.add(
                                                        parcelCheckItemNameSplit[
                                                                1]
                                                            .replaceFirst(
                                                                " ", ""));
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
                                                            parcelReadyItemNames.add(
                                                                itemToBeCheckedItemNameSplit[
                                                                        1]
                                                                    .replaceFirst(
                                                                        " ",
                                                                        ""));
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
                                                  Map<String, dynamic>
                                                      masterOrderMapToServer =
                                                      HashMap();
//ToDeleteCancelledItem
                                                  masterOrderMapToServer
                                                      .addAll({
                                                    'itemsInOrderMap': {
                                                      itemID:
                                                          FieldValue.delete()
                                                    },
                                                  });
//ToSayThatTheChefHasSeenTheCancellation
                                                  masterOrderMapToServer
                                                      .addAll({
                                                    'statusMap': {
                                                      'chefStatus': 7
                                                    },
                                                  });
                                                  FireStoreAddOrderInRunningOrderFolder(
                                                          hotelName:
                                                              widget.hotelName,
                                                          seatingNumber:
                                                              itemBelongsToDoc,
                                                          ordersMap:
                                                              masterOrderMapToServer)
                                                      .addOrder();
                                                } else if (statusOfOrderedItem ==
                                                        9 ||
                                                    statusOfOrderedItem == 7) {
//IfNewOrderOrAlsoAnAcceptedOrder-WeGiveOptionToRejectItByUpdatingStatusInFireStore
                                                  //sayingOrderIsRejected
//WeAlsoSendMessageThatItemHasBeenRejectedToAllUsers
                                                  fcmProvider.sendNotification(
                                                      token:
                                                          dynamicTokensToStringToken(),
                                                      title: widget.hotelName,
                                                      restaurantNameForNotification: json.decode(Provider
                                                              .of<PrinterAndOtherDetailsProvider>(
                                                                  context,
                                                                  listen: false)
                                                          .allUserProfilesFromClass)[Provider
                                                              .of<PrinterAndOtherDetailsProvider>(
                                                                  context,
                                                                  listen: false)
                                                          .currentUserPhoneNumberFromClass]['restaurantName'],
                                                      body: '*itemReadyRejectedCaptainAlert*');
                                                  statusUpdaterInFireStoreForRunningOrders(
                                                      itemID,
                                                      itemBelongsToDoc,
                                                      11,
                                                      'dontTouch');
                                                }
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
                                                        .replaceFirst(" ", "")
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
                                                              .replaceFirst(
                                                                  " ", "")
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
                                                        'noComment')
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
                                                            'noComment')
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
                                                            'noComment'
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
//FirstWeCheckWhetherChefPrinterHasBeenAssigned
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                        .chefAssignedPrinterFromClass ==
                    '{}'
                ? Expanded(
                    // width: 300.0,
                    child: TextButton.icon(
                      icon: Icon(Icons.print),
                      label: Text(
                        'Assign Printer',
                      ),
                      style: TextButton.styleFrom(
                          primary: Colors.white, backgroundColor: Colors.green),
                      onPressed: () async {
//WeGoToThePageForAssigningPrinters
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PrinterRolesAssigning()));
                      },
                    ),
                  )
                : Expanded(
                    // width: 300.0,
                    child: TextButton.icon(
                      icon: Icon(Icons.print),
                      label: Text(
                        'Print',
                      ),
                      style: TextButton.styleFrom(
                          primary: Colors.white, backgroundColor: Colors.green),
                      onPressed: () async {
//OnClickingPrint,WeAlwaysCallForTheMethodSavedBluetoothPrinterConnect
//WhichWillInsideItCallForThePrintFunction
                        localParcelReadyNumberOfItems =
                            parcelReadyNumberOfItems;
                        localParcelReadyItemNames = parcelReadyItemNames;
                        localParcelReadyItemComments = parcelReadyItemComments;
                        localParcelNumber = parcelNumber;
                        chefPrinterAssigningMap = json.decode(
                            Provider.of<PrinterAndOtherDetailsProvider>(context,
                                    listen: false)
                                .chefAssignedPrinterFromClass);
                        chefPrinterAssigningMap.forEach((key, value) {
                          chefPrinterRandomID = key;
                        });
                        printerSavingMap = json.decode(
                            Provider.of<PrinterAndOtherDetailsProvider>(context,
                                    listen: false)
                                .savedPrintersFromClass);
                        chefPrinterCharacters =
                            printerSavingMap[chefPrinterRandomID];

                        deliverySlipPrintBytesGenerator();
                        Navigator.pop(context);
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
        Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                    .chefAssignedPrinterFromClass ==
                '{}'
            ? Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: Container(
                  width: double.infinity,
                  // width: 300.0,
                  child: TextButton.icon(
                    icon: Icon(Icons.print),
                    label: Text(
                      'Assign Printer',
                    ),
                    style: TextButton.styleFrom(
                        primary: Colors.white, backgroundColor: Colors.green),
                    onPressed: () async {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PrinterRolesAssigning()));
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
                    label: Text(
                      'Print All',
                    ),
                    style: TextButton.styleFrom(
                        primary: Colors.white, backgroundColor: Colors.green),
                    onPressed: () async {
                      localParcelReadyNumberOfItems = parcelReadyNumberOfItems;
                      localParcelReadyItemNames = parcelReadyItemNames;
                      localParcelReadyItemComments = parcelReadyItemComments;
                      localParcelNumber = parcelNumber;
                      chefPrinterAssigningMap = json.decode(
                          Provider.of<PrinterAndOtherDetailsProvider>(context,
                                  listen: false)
                              .chefAssignedPrinterFromClass);
                      chefPrinterAssigningMap.forEach((key, value) {
                        chefPrinterRandomID = key;
                      });
                      printerSavingMap = json.decode(
                          Provider.of<PrinterAndOtherDetailsProvider>(context,
                                  listen: false)
                              .savedPrintersFromClass);
                      chefPrinterCharacters =
                          printerSavingMap[chefPrinterRandomID];
                      deliverySlipPrintBytesGenerator();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
        Divider(thickness: 6),
        Container(
          child: ListTile(
            title: Text(parcelReadyItemNames[0],
                style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(parcelReadyNumberOfItems[0].toString(),
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
//WeGiveTwoOptionsBelow-ToPrintOneItemAloneOrJustCloseWithoutDeliverySlipPrint
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
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                        .chefAssignedPrinterFromClass ==
                    '{}'
                ? Expanded(
                    // width: 300.0,
                    child: TextButton.icon(
                      icon: Icon(Icons.print),
                      label: Text(
                        'Assign Printer',
                      ),
                      style: TextButton.styleFrom(
                          primary: Colors.white, backgroundColor: Colors.green),
                      onPressed: () async {
//OnClickingPrint,WeAlwaysCallForTheMethodSavedBluetoothPrinterConnect
//WhichWillInsideItCallForThePrintFunction
                        localParcelReadyNumberOfItems = [];
                        localParcelReadyItemNames = [];
                        localParcelReadyItemComments = [];
                        localParcelNumber = '';
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PrinterRolesAssigning()));
                      },
                    ),
                  )
                : Expanded(
                    // width: 300.0,
                    child: TextButton.icon(
                      icon: Icon(Icons.print),
                      label: Text(
                        'Print Item',
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
                        // localParcelReadyNumberOfItems = parcelReadyNumberOfItems;
                        // localParcelReadyItemNames = parcelReadyItemNames;
                        localParcelNumber = parcelNumber;
                        chefPrinterAssigningMap = json.decode(
                            Provider.of<PrinterAndOtherDetailsProvider>(context,
                                    listen: false)
                                .chefAssignedPrinterFromClass);
                        chefPrinterAssigningMap.forEach((key, value) {
                          chefPrinterRandomID = key;
                        });
                        printerSavingMap = json.decode(
                            Provider.of<PrinterAndOtherDetailsProvider>(context,
                                    listen: false)
                                .savedPrintersFromClass);
                        chefPrinterCharacters =
                            printerSavingMap[chefPrinterRandomID];
                        deliverySlipPrintBytesGenerator();
                        Navigator.pop(context);
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
