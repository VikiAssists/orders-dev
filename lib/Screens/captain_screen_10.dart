import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:orders_dev/Methods/table_Button.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:orders_dev/Screens/items_each_order_10.dart';
import 'package:orders_dev/Screens/items_each_order_11.dart';
import 'package:orders_dev/Screens/menu_page_add_items_6.dart';
import 'package:orders_dev/Screens/tableOrParcelSplit_3.dart';
import 'package:orders_dev/constants.dart';
import 'package:orders_dev/services/background_services.dart';
import 'package:orders_dev/services/firestore_services.dart';
import 'package:orders_dev/services/notification_service.dart';
import 'package:modal_progress_hud_alt/modal_progress_hud_alt.dart';
import 'package:provider/provider.dart';
import 'package:wakelock/wakelock.dart';

//TheCaptainScreenForTheWaiter,InputsBeingTitles,Items,Price&NumberOfTables
class CaptainScreenEachItemCheck extends StatefulWidget {
  final String hotelName;
  final List<String> menuTitles;
  final List<String> entireMenuItems;
  final List<num> entireMenuPrice;

  const CaptainScreenEachItemCheck({
    Key? key,
    required this.hotelName,
    required this.menuTitles,
    required this.entireMenuItems,
    required this.entireMenuPrice,
  }) : super(key: key);
  @override
  _CaptainScreenEachItemCheckState createState() =>
      _CaptainScreenEachItemCheckState();
}

class _CaptainScreenEachItemCheckState extends State<CaptainScreenEachItemCheck>
    with WidgetsBindingObserver {
//WidgetsBindingObserverForUnderstandingTheStateOfTheScreen
//WhetherItIsInForegroundOrBackground
//AudioPlayerPackageIsFromFlutter
//WeKeepPlayerStateStopped&PlayerPlayingIsFalse
//EveryThirtySeconds0,WeInitializeTimer
//SomeItemReady&SomeItemRejectedAsFalse
//itemsReadyOrRejectedInLastCheckIsForAlertingOnlyIfSomethingNewHasCome
//internetCheckerSubscriptionChecksForStreamToCheckInternet
//PageHasInternetIsBooleanToCheckInternet

  final player = AudioPlayer();
  PlayerState playerState = PlayerState.stopped;
  bool playerPlaying = false;
  int _everyTenSeconds = 0;
  Timer? _timer;
  bool someItemReady = false;
  bool someItemRejected = false;
  List<String> itemsReadyOrRejectedInLastCheck = [];
  late StreamSubscription internetCheckerSubscription;
  bool pageHasInternet = true;
  num backgroundTimerCounter = 0;
  bool appInBackground = false;
  bool timerRunningForCheckingNewOrdersInBackground = false;
  List<String> localMenuTitles = [];
  List<String> localEntireMenuItems = [];
  List<num> localEntireMenuPrice = [];
  bool showSpinner = false;

  @override
  void initState() {
    // TODO: implement initState

//WidgetsBindingObserverIsToInitializeAnObserver

    WidgetsBinding.instance.addObserver(this);
//WeKeepEveryThirtySecondsIsZero&LastCheckToEmptyList
    _everyTenSeconds = 0;
    itemsReadyOrRejectedInLastCheck = [];
    internetAvailabilityChecker();
    backgroundTimerCounter = 0;
    appInBackground = false;
    timerRunningForCheckingNewOrdersInBackground = false;
    localMenuTitles = widget.menuTitles;
    localEntireMenuItems = widget.entireMenuItems;
    localEntireMenuPrice = widget.entireMenuPrice;
    showSpinner = false;
    Wakelock.enable();
    // FlutterBackground.initialize();
    // BackgroundCheck().saveInsideCaptainScreenChangingInBackground(
    //     insideCaptainScreenTrueElseFalse: true);

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

  void chefSpecialitiesChanged() async {
    final allUserProfileDetailsOfTheRestaurant = await FirebaseFirestore
        .instance
        .collection(widget.hotelName)
        .doc('allUserProfiles')
        .get();
    if (allUserProfileDetailsOfTheRestaurant.data() != null) {
      var allUserProfiles = allUserProfileDetailsOfTheRestaurant.data()!;
      Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
          .saveAllUserProfiles(json.encode(allUserProfiles));
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
//DuringWidgetsBinding,WeRemoveObserver
    WidgetsBinding.instance.removeObserver(this);
//WeCancelInternetCheckerSubscriptionTooNext
    internetCheckerSubscription.cancel();
//PlayerIsDisposed&Released
    player.dispose();
    player.release();
    super.dispose();
  }

//ThisIsToCheckAppLifeCycleStateWhetherItIsInForegroundOrBackground
  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    // TODO: implement didChangeAppLifecycleState

    // if (state == AppLifecycleState.inactive ||
    //     state == AppLifecycleState.detached) return;

    final isBackground = state == AppLifecycleState.paused;
    final isBackground2 = state == AppLifecycleState.inactive;
    final isBackground3 = state == AppLifecycleState.detached;
    final isForeground = state == AppLifecycleState.resumed;

//WhenWeAreClosingTheApp
//     if (isBackground3) {
//       BackgroundCheck().saveInsideCaptainScreenChangingInBackground(
//           insideCaptainScreenTrueElseFalse: false);
//     }

//IfItIsInBackground,SimilarToChefScreen,WeCheckTheOrdersInBackground
    if (isBackground || isBackground2 || isBackground3) {
      timerRunningForCheckingNewOrdersInBackground = false;

      // timerForCheckingNewOrdersInBackground();
      if (appInBackground == false) {
        currentOrdersCheckInBackground();
        setState(() {
          appInBackground = true;
        });
      }
    } else if (isForeground) {
      setState(() {
        appInBackground = false;
      });
      NotificationService().cancelAllNotifications();
      // FlutterBackground.disableBackgroundExecution();
      backgroundTimerCounter = 0;
//OnceForeGround,PlayerCanBeStopped
//PlayerPlayingIsChangedToFalse
//TimerCanBeCancelled
//EveryThirtySecondsIsZero
      player.stop();
      playerPlaying = false;
      _timer?.cancel();
      _everyTenSeconds = 0;
      setState(() {
        pageHasInternet = true;
      });
      internetAvailabilityChecker();
    }

    super.didChangeAppLifecycleState(state);
  }

  //WeCheckCurrentOrdersInBackground
  void currentOrdersCheckInBackground() async {
    backgroundTimerCounter++;
    print('background called $backgroundTimerCounter');
    if (backgroundTimerCounter < 361) {
      //WeCheckInCurrentOrdersWhetherSomethingIsGreaterThanOrEqualTo10
//If10MeansSomethingIsReady,11-Rejected
//     final currentOrdersCheck = await FirebaseFirestore.instance
//         .collection(widget.hotelName)
//         .doc('currentorders')
//         .collection('currentorders')
//         .where('statusoforder', isGreaterThanOrEqualTo: 10)
//         .get();
      final presentOrdersCheck = await FirebaseFirestore.instance
          .collection(widget.hotelName)
          .doc('runningorders')
          .collection('runningorders')
          .where('statusMap.${'captainStatus'}', isGreaterThanOrEqualTo: 10)
          .get();
//InsideEachDoc,ThereIsStatusMapWhereWeHaveCaptainStatus
//WeAreCheckingOnlyReadyItems
      bool someItemRejected = false;
      bool someItemReady = false;

      //WeCheckEachOrder&CheckSomethingIsRejected-IfYes,SomeItemRejectedToTrue,,
//andSomeItemReadyToFalse
      num i = 0;
      for (var eachOrder in presentOrdersCheck.docs) {
        i++;
        if (eachOrder['statusMap']['captainStatus'] == 11) {
          someItemRejected = true;
        } else if (eachOrder['statusMap']['captainStatus'] == 10 &&
            someItemRejected == false) {
          someItemReady = true;
        }
        if (i == presentOrdersCheck.size) {
          if (someItemRejected) {
            playRejected();
          } else if (someItemReady) {
            playCaptain();
          }
        }
      }
    }
    if (appInBackground
        // &&
        // timerRunningForCheckingNewOrdersInBackground == false
        ) {
      print('appInBackground $appInBackground');
      timerForCheckingNewOrdersInBackground();
    }
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
          timerRunningForCheckingNewOrdersInBackground = true;
          _everySecondBeforeCallingTimer++;
          print(
              '_everySecondBeforeCallingTimer1 $_everySecondBeforeCallingTimer');
        } else if (_everySecondBeforeCallingTimer == 10) {
          timerRunningForCheckingNewOrdersInBackground = false;
          // bluetoothTurnOnMessageShown = false;
          // print('came inside bluetooth On Point');
          if (appInBackground) {
            currentOrdersCheckInBackground();
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

  void playRejected() async {
//IfOrderIsRejected,PlayTuneWithPlay-ItIsAnAssetSource-SoWeNeedToPutItIn
    if (!playerPlaying) {
      await player.play(AssetSource('audio/rejected_orders.mp3'));
      playerState = PlayerState.playing;
      playerPlaying = true;
//OnceCompletedWeChangeItToCompleted
      player.onPlayerComplete.listen((event) {
        playerState = PlayerState.completed;
        playerPlaying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
//ThisIsMethodToMakeWidgetsForTheCaptainScreen
    //ItReturnsListOfWrapWidgets
//ThisIsTheMasterListWhichWillReturnBothDineInAndParcelButtonsTogether
//WasUsedInTheFirstRelease

    List<Widget> dineInTableWidgets(AsyncSnapshot snapshot) {
      DateTime now = DateTime.now();
      List<Map<String, dynamic>> items = [];
      Map<String, dynamic> mapToAddIntoItems = {};
//TheSnapshotInputIsFromWhereTheMethodIsCalled
      final itemstream = snapshot.data?.docs;

      for (var eachDoc in itemstream) {
        Map<String, dynamic>? tempMap = eachDoc.data() as Map<String, dynamic>?;
        if (tempMap!.containsKey('baseInfoMap') &&
            tempMap!.containsKey('itemsInOrderMap') &&
            tempMap!.containsKey('partOfTableOrParcel') &&
            tempMap!.containsKey('partOfTableOrParcelNumber') &&
            tempMap!.containsKey('statusMap') &&
            tempMap!.containsKey('ticketsMap')) {
          Map<String, dynamic> eachDocBaseInfoMap = eachDoc['baseInfoMap'];
          String tableorparcel = eachDocBaseInfoMap['tableOrParcel'];
          num tableorparcelnumber =
              num.parse(eachDocBaseInfoMap['tableOrParcelNumber']);
          num timecustomercametoseat =
              num.parse(eachDocBaseInfoMap['startTime']);
          num currentTimeHourMinuteMultiplied = ((now.hour * 60) + now.minute);
          String parentOrChild = eachDocBaseInfoMap['parentOrChild'];
          String serialNumber = eachDocBaseInfoMap['serialNumber'];
          bool billPrinted = eachDocBaseInfoMap['billPrinted'];
          Map<String, dynamic> eachDocItemsInOrderMap =
              eachDoc['itemsInOrderMap'];

          eachDocItemsInOrderMap.forEach((key, value) {
//WeWontShowTheOrdersCancelledByTheCaptain
            if (value['itemCancelled'] == 'false') {
              mapToAddIntoItems = {};
              mapToAddIntoItems['tableorparcel'] = tableorparcel;
              mapToAddIntoItems['tableorparcelnumber'] = tableorparcelnumber;
              mapToAddIntoItems['parentOrChild'] = parentOrChild;
              mapToAddIntoItems['serialNumber'] = serialNumber;
              mapToAddIntoItems['billPrinted'] = billPrinted;
              mapToAddIntoItems['timecustomercametoseat'] =
                  timecustomercametoseat;
              if ((currentTimeHourMinuteMultiplied - timecustomercametoseat) >=
                  kCustomerWaitingTime) {
                mapToAddIntoItems['nowMinusTimeCustomerCameToSeat'] =
                    currentTimeHourMinuteMultiplied - timecustomercametoseat;
              } else {
                mapToAddIntoItems['nowMinusTimeCustomerCameToSeat'] = 0;
              }
              mapToAddIntoItems['eachiteminorderid'] = key;
              mapToAddIntoItems['item'] = value['itemName'];
              mapToAddIntoItems['priceofeach'] = value['itemPrice'];
              mapToAddIntoItems['number'] = value['numberOfItem'];
              mapToAddIntoItems['timeoforder'] =
                  num.parse(value['orderTakingTime']);
              mapToAddIntoItems['statusoforder'] = value['itemStatus'];
              mapToAddIntoItems['commentsForTheItem'] = value['itemComment'];
              mapToAddIntoItems['chefKotStatus'] = value['chefKOT'];
              mapToAddIntoItems['itemBelongsToDoc'] = eachDoc.id;
              items.add(mapToAddIntoItems);
            }
          });
        }
      }

//WeHaveTwoLists-WrapWidgetsOfTableAndParcelButtons
      List<Wrap> wrapWidgetsOfTableButtons = [];

//EveryHotelMightHaveTimesWhereThereMightBeTwoThreeDifferentPeopleSittingIn,,
//SameTable,,,SoTheyNeedMoreTableNumbersThanWhatTheyActuallyHave
//ThisFormulaHelpsToCreateMoreSetOfTableRows
//WeGetAnIntegerValueDividedBy4&AddItWithOne
      int numberOfTableRows = ((json.decode(
                      Provider.of<PrinterAndOtherDetailsProvider>(context,
                              listen: false)
                          .restaurantInfoDataFromClass)['tables'] +
                  4) ~/
              4) +
          1;
      //ToGetIntegerValueOfNumberOfTablesDividedBy4
      for (int i = 0; i < numberOfTableRows; i++) {
//WeGoThroughEachItem&
//WeHaveListOfTables&Parcels,Number&Colors
        List<String> table = [];
        List<String> parcel = [];
        List<num> tableNumber = [];
        List<Color> tableColors = [];
        List<Color> parcelColors = [];
//ThisToEnsureWeHave4WidgetsPerRowAndOneExtraRow
        for (int j = i * 4; j < ((i * 4) + 4); j++) {
//OneByOneWeGoThroughAllItems
          bool tableHasOrders = false;
          bool parcelHasOrders = false;
          bool parcelEverythingIsReady = true;
          int tableStatus = 0;
          int parcelStatus = 0;
          bool billPrinted = false;
          for (var item in items) {
//WeGoThroughEachItems'Status&WhatShouldBeTheTableStatus
            if ((item['tableorparcel'] == 'Table') &&
                (item['tableorparcelnumber'] == (j + 1))) {
              tableHasOrders = true;
              if (item['billPrinted'] == true) {
                billPrinted = true;
              }
              if (item['statusoforder'] == 11) {
                tableStatus = 11;
              } else if (item['statusoforder'] == 10 && tableStatus != 11) {
//IfItemsReady
                tableStatus = 10;
              } else if (item['statusoforder'] == 9 &&
                  tableStatus != 11 &&
                  tableStatus != 10) {
                tableStatus = 9;
              } else if (item['statusoforder'] == 7 &&
                  tableStatus != 11 &&
                  tableStatus != 9 &&
                  tableStatus != 10) {
                tableStatus = 7;
              } else if (item['statusoforder'] == 3 &&
                  tableStatus != 11 &&
                  tableStatus != 9 &&
                  tableStatus != 10 &&
                  tableStatus != 7) {
//ifAllItemsDelivered
                tableStatus = 3;
              }
              //EvenIf 1 ItemReady,WeWillShowStatusAsGreen
            }
//WeUnderstandTheStatusOfEachParcelToo
            if ((item['tableorparcel'] == 'Parcel') &&
                (item['tableorparcelnumber'] == (j + 1))) {
              parcelHasOrders =
                  true; //thisIsToDecideWhetherOrNotATableOrParcelHasOrder

              if (item['statusoforder'] == 11) {
                parcelStatus = 11;
                parcelEverythingIsReady = false;
              } else if ((item['statusoforder'] == 9) && parcelStatus != 11) {
                parcelStatus = item['statusoforder'];
                parcelEverythingIsReady = false;
                //WithThisInParcelOnlyIfAllItemsArePrepared,WeWillShowGreen
                //However,IfTheLastItemWasFirstPrepared
                //ThenItCouldBe 7 Only
              } else if (item['statusoforder'] == 7 &&
                  parcelStatus != 11 &&
                  parcelStatus != 9) {
                parcelStatus = 7;
                parcelEverythingIsReady = false;
              } else if (item['statusoforder'] == 10 &&
                  parcelStatus != 11 &&
                  parcelStatus != 9 &&
                  parcelStatus != 7 &&
                  parcelEverythingIsReady) {
                //ThisWillEnsureOnlyIfAllTheItemsAreReadyInParcel,itWillShowGreen
                parcelStatus = 10;
              } else if (item['statusoforder'] == 3 &&
                  parcelStatus != 11 &&
                  parcelStatus != 9 &&
                  parcelStatus != 10 &&
                  parcelStatus != 7 &&
                  parcelEverythingIsReady) {
                //ThisWillEnsureOnlyIfAllTheItemsAreReadyInParcel,itWillShowGreen
                parcelStatus = 3;
              }
            }
          }
//WeKeepTheColorOfStatusAccordinglyForTablesAndParcels
          if (tableHasOrders) {
            if (tableStatus == 9) {
              tableColors.add(Colors.white);
            } else if (tableStatus == 7) {
              tableColors.add(Colors.orangeAccent);
            } else if (tableStatus == 10) {
              tableColors.add(Colors.green);
            } else if (tableStatus == 11) {
              tableColors.add(Colors.red);
            } else if (tableStatus == 3 && billPrinted) {
              tableColors.add(Colors.purple.shade200);
            } else if (tableStatus == 3) {
              tableColors.add(Colors.lightBlueAccent);
            }
          } else {
            tableColors.add(Colors.brown.shade100);
          }
          if (parcelHasOrders) {
            if (parcelStatus == 9) {
              parcelColors.add(Colors.white);
            } else if (parcelStatus == 7) {
              parcelColors.add(Colors.orangeAccent);
            } else if (parcelStatus == 10) {
              parcelColors.add(Colors.green);
            } else if (parcelStatus == 11) {
              parcelColors.add(Colors.red);
            } else if (parcelStatus == 3) {
              parcelColors.add(Colors.lightBlueAccent);
            }
          } else {
            parcelColors.add(Colors.blueGrey);
          }
          table.add(' Table');
          parcel.add('Parcel');
          tableNumber.add(j + 1);
        }
//OnceWeGoThroughThe int j Loop
//WrapWidgetIsWhatWillHaveFourButtonsInOneRow
//WithTableNumberWeAddTableButtonsOneByOne&BasedOnStatus
//WePutColor&SoOn
        wrapWidgetsOfTableButtons.add(Wrap(
          alignment: WrapAlignment.spaceEvenly,
          direction: Axis.horizontal,
          children: List.generate(4, (index) {
            return TableButton(
              textColor: Colors.black,
              backgroundColor: tableColors[index],
              borderColor: Colors.black,
              tableOrParcel: table[index],
              tableOrParcelNumber: tableNumber[index],
              size: 35.0,
//InCaseWeAreRingingAlarm,OnceWePressTableButton,ThePlayerShouldBeStopped
              onPress: () {
                player.stop();
                playerState = PlayerState.stopped;
                playerPlaying = false;
                someItemRejected = false;
                someItemReady = false;
//ifAButtonIsPressed,WeGoThroughEntireList,CollectAllTheItemsInTheTable
//AndWeGoToItemsInEachTableScreen
                List<String> itemsID = [];
                List<String> itemsName = [];
                List<int> itemsNumber = [];
                List<int> itemsStatus = [];
                List<num> itemsEachPrice = [];
                List<String> itemsBelongsToDoc = [];
                List<String> itemBelongsToParentOrChildOrder = [];
                for (var item in items) {
//ForEachItemInItems,WeAddItemsId,Number,Status&Price
                  if ((item['tableorparcel'] == 'Table') &&
                      (item['tableorparcelnumber'] == tableNumber[index])) {
                    itemsID.add(item['eachiteminorderid']);
                    itemsName.add(item['item']);
                    itemsNumber.add(item['number']);
                    itemsStatus.add(item['statusoforder']);
                    itemsEachPrice.add(item['priceofeach']);
                    itemsBelongsToDoc.add(item['itemBelongsToDoc']);
                    itemBelongsToParentOrChildOrder.add(item['parentOrChild']);
                  }
                }
                if (itemsID.isNotEmpty) {
                  setState(() {
                    showSpinner = true;
                  });
//IfItemsIdIsNotEmpty,ItMeansThereIsSomethingOrderedInTheTable
// WeGoToItemsEachTableScreenWithItemsId,Name,Number,Status,Price
//WeGoIntoThisOnlyIfThisTableHasNotBeenSplitYet
                  if (itemBelongsToParentOrChildOrder[0] == 'parent') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ItemsWithCancelRegister(
                                  hotelName: widget.hotelName,
                                  menuItems: widget.entireMenuItems,
                                  menuTitles: widget.menuTitles,
                                  menuPrices: widget.entireMenuPrice,
                                  itemsID: itemsID,
                                  itemsName: itemsName,
                                  itemsNumber: itemsNumber,
                                  itemsStatus: itemsStatus,
                                  itemsEachPrice: itemsEachPrice,
                                  itemsBelongsToDoc: itemsBelongsToDoc,
                                  itemsFromDoc: itemsBelongsToDoc[0],
                                  tableOrParcel: 'Table',
                                  tableOrParcelNumber: tableNumber[index],
                                )));
                  } else {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                TableOrParcelSplitWithRunningOrders(
                                  hotelName: widget.hotelName,
                                  partOfTableOrParcel: 'Table',
                                  partOfTableOrParcelNumber:
                                      tableNumber[index].toString(),
                                  menuItems: widget.entireMenuItems,
                                  menuTitles: widget.menuTitles,
                                  menuPrices: widget.entireMenuPrice,
                                )));
                  }

                  setState(() {
                    showSpinner = false;
                  });
                } else {
                  setState(() {
                    showSpinner = true;
                  });
//IfItemsIDIsEmpty,itMeansThatThereIsNoItemsInThatTableYet
//AndWeGoToTheMenuPageWithInputs

//ToEnsureWeComeBackToItemsPageItself
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ItemsWithCancelRegister(
                                hotelName: widget.hotelName,
                                menuItems: widget.entireMenuItems,
                                menuTitles: widget.menuTitles,
                                menuPrices: widget.entireMenuPrice,
                                itemsID: [],
                                itemsName: [],
                                itemsNumber: [],
                                itemsStatus: [],
                                itemsEachPrice: [],
                                itemsBelongsToDoc: [],
                                itemsFromDoc: 'Table:${tableNumber[index]}',
                                tableOrParcel: 'Table',
                                tableOrParcelNumber: tableNumber[index],
                              )));

//CommentedTillNextScreenReady
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => MenuPageWithBackButtonUsage(
                              hotelName: widget.hotelName,
                              tableOrParcel: 'Table',
                              tableOrParcelNumber: tableNumber[index],
                              menuItems: localEntireMenuItems,
                              menuPrices: localEntireMenuPrice,
                              menuTitles: localMenuTitles,
                              itemsAddedMapCalled: {},
                              itemsAddedCommentCalled: {},
                              itemsAddedTimeCalled: {},
                              parentOrChild: 'parent',
                              alreadyRunningTicketsMap: {})));
//CommentedTillNextScreenReady
                  setState(() {
                    showSpinner = false;
                  });
                }
              },
            );
          }),
        ));
//wrapWidgetsOfParcelButtonIsSameAsTableButton,
//ExceptThatOnlyIfAllItemsAreReady,WeGiveItGreen

      }
//FinallyWeAddWrapWidgetsTable&ParcelButtons&ReturnItToTheListView
      return (wrapWidgetsOfTableButtons);
    }

    List<Widget> parcelTableWidgets(AsyncSnapshot snapshot) {
      DateTime now = DateTime.now();
      List<Map<String, dynamic>> items = [];
      Map<String, dynamic> mapToAddIntoItems = {};
//TheSnapshotInputIsFromWhereTheMethodIsCalled
      final itemstream = snapshot.data?.docs;

      for (var eachDoc in itemstream) {
        Map<String, dynamic>? tempMap = eachDoc.data() as Map<String, dynamic>?;
        if (tempMap!.containsKey('baseInfoMap') &&
            tempMap!.containsKey('itemsInOrderMap') &&
            tempMap!.containsKey('partOfTableOrParcel') &&
            tempMap!.containsKey('partOfTableOrParcelNumber') &&
            tempMap!.containsKey('statusMap') &&
            tempMap!.containsKey('ticketsMap')) {
          Map<String, dynamic> eachDocBaseInfoMap = eachDoc['baseInfoMap'];
          String tableorparcel = eachDocBaseInfoMap['tableOrParcel'];
          num tableorparcelnumber =
              num.parse(eachDocBaseInfoMap['tableOrParcelNumber']);
          num timecustomercametoseat =
              num.parse(eachDocBaseInfoMap['startTime']);
          num currentTimeHourMinuteMultiplied = ((now.hour * 60) + now.minute);
          String parentOrChild = eachDocBaseInfoMap['parentOrChild'];
          String serialNumber = eachDocBaseInfoMap['serialNumber'];
          bool billPrinted = eachDocBaseInfoMap['billPrinted'];
          Map<String, dynamic> eachDocItemsInOrderMap =
              eachDoc['itemsInOrderMap'];

          eachDocItemsInOrderMap.forEach((key, value) {
            if (value['itemCancelled'] == 'false') {
              mapToAddIntoItems = {};
              mapToAddIntoItems['tableorparcel'] = tableorparcel;
              mapToAddIntoItems['tableorparcelnumber'] = tableorparcelnumber;
              mapToAddIntoItems['parentOrChild'] = parentOrChild;
              mapToAddIntoItems['serialNumber'] = serialNumber;
              mapToAddIntoItems['billPrinted'] = billPrinted;
              mapToAddIntoItems['timecustomercametoseat'] =
                  timecustomercametoseat;
              if ((currentTimeHourMinuteMultiplied - timecustomercametoseat) >=
                  kCustomerWaitingTime) {
                mapToAddIntoItems['nowMinusTimeCustomerCameToSeat'] =
                    currentTimeHourMinuteMultiplied - timecustomercametoseat;
              } else {
                mapToAddIntoItems['nowMinusTimeCustomerCameToSeat'] = 0;
              }
              mapToAddIntoItems['eachiteminorderid'] = key;
              mapToAddIntoItems['item'] = value['itemName'];
              mapToAddIntoItems['priceofeach'] = value['itemPrice'];
              mapToAddIntoItems['number'] = value['numberOfItem'];
              mapToAddIntoItems['timeoforder'] =
                  num.parse(value['orderTakingTime']);
              mapToAddIntoItems['statusoforder'] = value['itemStatus'];
              mapToAddIntoItems['commentsForTheItem'] = value['itemComment'];
              mapToAddIntoItems['chefKotStatus'] = value['chefKOT'];
              mapToAddIntoItems['itemBelongsToDoc'] = eachDoc.id;
              items.add(mapToAddIntoItems);
            }
          });
        }
      }

//WeHaveTwoLists-WrapWidgetsOfTableAndParcelButtons
      List<Wrap> wrapWidgetsOfParcelButtons = [];
//EveryHotelMightHaveTimesWhereThereMightBeTwoThreeDifferentPeopleSittingIn,,
//SameTable,,,SoTheyNeedMoreTableNumbersThanWhatTheyActuallyHave
//ThisFormulaHelpsToCreateMoreSetOfTableRows
//WeGetAnIntegerValueDividedBy4&AddItWithOne
      int numberOfTableRows = (((json.decode(
                      Provider.of<PrinterAndOtherDetailsProvider>(context,
                              listen: false)
                          .restaurantInfoDataFromClass)['tables']) +
                  4) ~/
              4) +
          1;
      //ToGetIntegerValueOfNumberOfTablesDividedBy4
      for (int i = 0; i < numberOfTableRows; i++) {
//WeGoThroughEachItem&
//WeHaveListOfTables&Parcels,Number&Colors
        List<String> table = [];
        List<String> parcel = [];
        List<num> tableNumber = [];
        List<Color> tableColors = [];
        List<Color> parcelColors = [];
//ThisToEnsureWeHave4WidgetsPerRowAndOneExtraRow
        for (int j = i * 4; j < ((i * 4) + 4); j++) {
//OneByOneWeGoThroughAllItems
          bool tableHasOrders = false;
          bool parcelHasOrders = false;
          bool parcelEverythingIsReady = true;
          int tableStatus = 0;
          int parcelStatus = 0;
          bool billPrinted = false;
          for (var item in items) {
//WeGoThroughEachItems'Status&WhatShouldBeTheTableStatus
            if ((item['tableorparcel'] == 'Table') &&
                (item['tableorparcelnumber'] == (j + 1))) {
              tableHasOrders = true;
              if (item['statusoforder'] == 11) {
                tableStatus = 11;
              } else if (item['statusoforder'] == 10 && tableStatus != 11) {
//IfItemsReady
                tableStatus = 10;
              } else if (item['statusoforder'] == 9 &&
                  tableStatus != 11 &&
                  tableStatus != 10) {
                tableStatus = 9;
              } else if (item['statusoforder'] == 7 &&
                  tableStatus != 11 &&
                  tableStatus != 9 &&
                  tableStatus != 10) {
                tableStatus = 7;
              } else if (item['statusoforder'] == 3 &&
                  tableStatus != 11 &&
                  tableStatus != 9 &&
                  tableStatus != 10 &&
                  tableStatus != 7) {
//ifAllItemsDelivered
                tableStatus = 3;
              }
              //EvenIf 1 ItemReady,WeWillShowStatusAsGreen
            }
//WeUnderstandTheStatusOfEachParcelToo
            if ((item['tableorparcel'] == 'Parcel') &&
                (item['tableorparcelnumber'] == (j + 1))) {
              parcelHasOrders =
                  true; //thisIsToDecideWhetherOrNotATableOrParcelHasOrder
              if (item['billPrinted'] == true) {
                billPrinted = true;
              }

              if (item['statusoforder'] == 11) {
                parcelStatus = 11;
                parcelEverythingIsReady = false;
              } else if ((item['statusoforder'] == 9) && parcelStatus != 11) {
                parcelStatus = item['statusoforder'];
                parcelEverythingIsReady = false;
                //WithThisInParcelOnlyIfAllItemsArePrepared,WeWillShowGreen
                //However,IfTheLastItemWasFirstPrepared
                //ThenItCouldBe 7 Only
              } else if (item['statusoforder'] == 7 &&
                  parcelStatus != 11 &&
                  parcelStatus != 9) {
                parcelStatus = 7;
                parcelEverythingIsReady = false;
              } else if (item['statusoforder'] == 10 &&
                  parcelStatus != 11 &&
                  parcelStatus != 9 &&
                  parcelStatus != 7 &&
                  parcelEverythingIsReady) {
                //ThisWillEnsureOnlyIfAllTheItemsAreReadyInParcel,itWillShowGreen
                parcelStatus = 10;
              } else if (item['statusoforder'] == 3 &&
                  parcelStatus != 11 &&
                  parcelStatus != 9 &&
                  parcelStatus != 10 &&
                  parcelStatus != 7 &&
                  parcelEverythingIsReady) {
                //ThisWillEnsureOnlyIfAllTheItemsAreReadyInParcel,itWillShowGreen
                parcelStatus = 3;
              }
            }
          }
//WeKeepTheColorOfStatusAccordinglyForTablesAndParcels
          if (tableHasOrders) {
            if (tableStatus == 9) {
              tableColors.add(Colors.white);
            } else if (tableStatus == 7) {
              tableColors.add(Colors.orangeAccent);
            } else if (tableStatus == 10) {
              tableColors.add(Colors.green);
            } else if (tableStatus == 11) {
              tableColors.add(Colors.red);
            } else if (tableStatus == 3) {
              tableColors.add(Colors.lightBlueAccent);
            }
          } else {
            tableColors.add(Colors.brown.shade100);
          }
          if (parcelHasOrders) {
            if (parcelStatus == 9) {
              parcelColors.add(Colors.white);
            } else if (parcelStatus == 7) {
              parcelColors.add(Colors.orangeAccent);
            } else if (parcelStatus == 10) {
              parcelColors.add(Colors.green);
            } else if (parcelStatus == 11) {
              parcelColors.add(Colors.red);
            } else if (parcelStatus == 3 && billPrinted) {
              parcelColors.add(Colors.purple.shade200);
            } else if (parcelStatus == 3) {
              parcelColors.add(Colors.lightBlueAccent);
            }
          } else {
            parcelColors.add(Colors.blueGrey);
          }
          table.add(' Table');
          parcel.add('Parcel');
          tableNumber.add(j + 1);
        }
//OnceWeGoThroughThe int j Loop
//WrapWidgetIsWhatWillHaveFourButtonsInOneRow
//WithTableNumberWeAddTableButtonsOneByOne&BasedOnStatus
//WePutColor&SoOn

//wrapWidgetsOfParcelButtonIsSameAsTableButton,
//ExceptThatOnlyIfAllItemsAreReady,WeGiveItGreen
        wrapWidgetsOfParcelButtons.add(Wrap(
          alignment: WrapAlignment.spaceEvenly,
          direction: Axis.horizontal,
          children: List.generate(4, (index) {
            return TableButton(
              textColor: Colors.black,
              backgroundColor: parcelColors[index],
              borderColor: Colors.black,
              tableOrParcel: parcel[index],
              tableOrParcelNumber: tableNumber[index],
              size: 35.0,
              onPress: () {
                player.stop();
                playerState = PlayerState.stopped;
                playerPlaying = false;
                someItemRejected = false;
                someItemReady = false;
                List<String> itemsID = [];
                List<String> itemsName = [];
                List<int> itemsNumber = [];
                List<int> itemsStatus = [];
                List<num> itemsEachPrice = [];
                List<String> itemsBelongsToDoc = [];

                List<String> itemBelongsToParentOrChildOrder = [];
                for (var item in items) {
                  if ((item['tableorparcel'] == 'Parcel') &&
                      (item['tableorparcelnumber'] == tableNumber[index])) {
                    itemsID.add(item['eachiteminorderid']);
                    itemsName.add(item['item']);
                    itemsNumber.add(item['number']);
                    itemsStatus.add(item['statusoforder']);
                    itemsEachPrice.add(item['priceofeach']);
                    itemsBelongsToDoc.add(item['itemBelongsToDoc']);
                    itemBelongsToParentOrChildOrder.add(item['parentOrChild']);
                  }
                }
                if (itemsID.isNotEmpty) {
                  setState(() {
                    showSpinner = true;
                  });
//WeGoIntoThisOnlyIfThisTableIsYetToBeSplit
                  if (itemBelongsToParentOrChildOrder[0] == 'parent') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ItemsWithCancelRegister(
                                  hotelName: widget.hotelName,
                                  menuItems: widget.entireMenuItems,
                                  menuTitles: widget.menuTitles,
                                  menuPrices: widget.entireMenuPrice,
                                  itemsID: itemsID,
                                  itemsName: itemsName,
                                  itemsNumber: itemsNumber,
                                  itemsStatus: itemsStatus,
                                  itemsEachPrice: itemsEachPrice,
                                  itemsBelongsToDoc: itemsBelongsToDoc,
                                  itemsFromDoc: itemsBelongsToDoc[0],
                                  tableOrParcel: 'Parcel',
                                  tableOrParcelNumber: tableNumber[index],
                                )));
                  } else {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                TableOrParcelSplitWithRunningOrders(
                                  hotelName: widget.hotelName,
                                  partOfTableOrParcel: 'Parcel',
                                  partOfTableOrParcelNumber:
                                      tableNumber[index].toString(),
                                  menuItems: widget.entireMenuItems,
                                  menuTitles: widget.menuTitles,
                                  menuPrices: widget.entireMenuPrice,
                                )));
                  }

                  setState(() {
                    showSpinner = false;
                  });
                } else {
                  setState(() {
                    showSpinner = true;
                  });

                  //ToEnsureWeComeBackToItemsPageItself
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ItemsWithCancelRegister(
                                hotelName: widget.hotelName,
                                menuItems: widget.entireMenuItems,
                                menuTitles: widget.menuTitles,
                                menuPrices: widget.entireMenuPrice,
                                itemsID: [],
                                itemsName: [],
                                itemsNumber: [],
                                itemsStatus: [],
                                itemsEachPrice: [],
                                itemsBelongsToDoc: [],
                                itemsFromDoc: 'Parcel:${tableNumber[index]}',
                                tableOrParcel: 'Parcel',
                                tableOrParcelNumber: tableNumber[index],
                              )));
//CommentedTillNextScreenReady
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => MenuPageWithBackButtonUsage(
                              hotelName: widget.hotelName,
                              tableOrParcel: 'Parcel',
                              tableOrParcelNumber: tableNumber[index],
                              parentOrChild: 'parent',
                              menuItems: localEntireMenuItems,
                              menuPrices: localEntireMenuPrice,
                              menuTitles: localMenuTitles,
                              itemsAddedMapCalled: {},
                              itemsAddedCommentCalled: {},
                              itemsAddedTimeCalled: {},
                              alreadyRunningTicketsMap: {})));
//CommentedTillNextScreenReady
                  setState(() {
                    showSpinner = false;
                  });
                }
              },
            );
          }),
        ));
      }
//FinallyWeAddWrapWidgetsTable&ParcelButtons&ReturnItToTheListView
      return (wrapWidgetsOfParcelButtons);
    }

    return WillPopScope(
//ToPopIfBackButtonPressed
      onWillPop: () async {
        print('here will pop captain');
        Wakelock.disable();
        showSpinner = false;
        // BackgroundCheck().saveInsideCaptainScreenChangingInBackground(
        //     insideCaptainScreenTrueElseFalse: false);
        Navigator.pop(context);
        return false;
      },
      child: Material(
        child: Scaffold(
//ToPopIfBackButtonInAppBarIsPressed
          appBar: AppBar(
            leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: kAppBarBackIconColor),
                onPressed: () async {
                  Wakelock.disable();
                  showSpinner = false;
                  // BackgroundCheck().saveInsideCaptainScreenChangingInBackground(
                  //     insideCaptainScreenTrueElseFalse: false);
                  Navigator.pop(context);
                }),
            backgroundColor: kAppBarBackgroundColor,
//AppBarTitle-Captain
            title: Text(
              'Captain',
              style: kAppBarTextStyle,
            ),
            centerTitle: true,
          ),
          body: ModalProgressHUD(
            inAsyncCall: showSpinner,
            child: Column(
              children: [
//FirstWeCheckWhetherPageHasInternet,IfYes,WePutNothingThere(YouCan'tPutNull),
//SoIPutNoSizedSizedBoxThere
//IfThereIsNoInternet,WePutContainerSayingTheyAreOffline
                pageHasInternet
                    ? const SizedBox.shrink()
                    : Container(
                        width: double.infinity,
                        color: Colors.red,
                        child: const Center(
                          child: Text('You are Offline',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 30.0)),
                        ),
                      ),
                Container(
                  padding: EdgeInsets.all(10),
                  color: Colors.black54,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          legend_widget(
                              color: Colors.white,
                              colorDescription: 'Not Accepted'),
                          legend_widget(
                              color: Colors.orangeAccent,
                              colorDescription: 'Accepted'),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          legend_widget(
                              color: Colors.red, colorDescription: 'Rejected'),
                          legend_widget(
                              color: Colors.green, colorDescription: 'Ready'),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          legend_widget(
                              color: Colors.lightBlueAccent,
                              colorDescription: 'Served'),
                          legend_widget(
                              color: Colors.purple.shade200,
                              colorDescription: 'Billed'),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
//ThenWeHaveStreamBuilderWhoseJobIsToKeepCheckingForNewContentsOrChanges,,
//InTheCurrentOrdersCollection
                  child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection(widget.hotelName)
                          .doc('runningorders')
                          .collection('runningorders')
                          .snapshots(),
                      builder: (context, snapshot) {
//IfConnectionStateIsWaiting,ThenWePutTheRotatingCircleThatShowsLoadingInTheCenter
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              backgroundColor: Colors.lightBlueAccent,
                            ),
                          );
                        } else if (snapshot.hasError) {
//IfThereIsAnError,WeCaptureTheErrorAndPutItInThePage
                          return Center(
                            child: Text(snapshot.error.toString()),
                          );
                        } else if (snapshot.hasData) {
                          DateTime now = DateTime.now();
//IfThereIsData,WeGetTheDocsFromThatData
                          List<Map<String, dynamic>> items = [];
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
                                tempMap!
                                    .containsKey('partOfTableOrParcelNumber') &&
                                tempMap!.containsKey('statusMap') &&
                                tempMap!.containsKey('ticketsMap')) {
                              print('isnide 1');
                              Map<String, dynamic> eachDocBaseInfoMap =
                                  eachDoc['baseInfoMap'];

                              String tableorparcel =
                                  eachDocBaseInfoMap['tableOrParcel'];
                              num tableorparcelnumber = num.parse(
                                  eachDocBaseInfoMap['tableOrParcelNumber']);
                              num timecustomercametoseat =
                                  num.parse(eachDocBaseInfoMap['startTime']);
                              num currentTimeHourMinuteMultiplied =
                                  ((now.hour * 60) + now.minute);
                              String parentOrChild =
                                  eachDocBaseInfoMap['parentOrChild'];
                              String serialNumber =
                                  eachDocBaseInfoMap['serialNumber'];
                              bool billPrinted =
                                  eachDocBaseInfoMap['billPrinted'];

                              Map<String, dynamic> eachDocItemsInOrderMap =
                                  eachDoc['itemsInOrderMap'];

                              eachDocItemsInOrderMap.forEach((key, value) {
//WeCheckWhetherItsSomeDeletedItemWhichWasAccidentallySentFromSomeOfflinePhone
//Value.LengthWillCheckHowManyValuesAreThere
//UsuallyThereWillBeNumberOfValuesWillBe9.IfItsLessThan8,WeShallDeleteIt
                                if (value.length > 8) {
                                  if (value['itemCancelled'] == 'false') {
                                    mapToAddIntoItems = {};
                                    mapToAddIntoItems['tableorparcel'] =
                                        tableorparcel;
                                    mapToAddIntoItems['tableorparcelnumber'] =
                                        tableorparcelnumber;
                                    mapToAddIntoItems['parentOrChild'] =
                                        parentOrChild;
                                    mapToAddIntoItems['serialNumber'] =
                                        serialNumber;
                                    mapToAddIntoItems['billPrinted'] =
                                        billPrinted;
                                    mapToAddIntoItems[
                                            'timecustomercametoseat'] =
                                        timecustomercametoseat;

                                    if ((currentTimeHourMinuteMultiplied -
                                            timecustomercametoseat) >=
                                        kCustomerWaitingTime) {
                                      mapToAddIntoItems[
                                              'nowMinusTimeCustomerCameToSeat'] =
                                          currentTimeHourMinuteMultiplied -
                                              timecustomercametoseat;
                                    } else {
                                      mapToAddIntoItems[
                                          'nowMinusTimeCustomerCameToSeat'] = 0;
                                    }
                                    if ((num.parse(value['orderTakingTime']) -
                                            timecustomercametoseat) >=
                                        kCustomerWaitingTime) {
                                      mapToAddIntoItems[
                                              'ThisItemOrderedTimeMinusCustomerCameToSeatTime'] =
                                          (num.parse(value['orderTakingTime']) -
                                              timecustomercametoseat);
                                    } else {
                                      mapToAddIntoItems[
                                          'ThisItemOrderedTimeMinusCustomerCameToSeatTime'] = 0;
                                    }

                                    mapToAddIntoItems['eachiteminorderid'] =
                                        key;
                                    mapToAddIntoItems['item'] =
                                        value['itemName'];
                                    mapToAddIntoItems['priceofeach'] =
                                        value['itemPrice'];
                                    mapToAddIntoItems['number'] =
                                        value['numberOfItem'];
                                    mapToAddIntoItems['timeoforder'] =
                                        num.parse(value['orderTakingTime']);
                                    mapToAddIntoItems['statusoforder'] =
                                        value['itemStatus'];
                                    mapToAddIntoItems['commentsForTheItem'] =
                                        value['itemComment'];
                                    mapToAddIntoItems['chefKotStatus'] =
                                        value['chefKOT'];
                                    mapToAddIntoItems['itemBelongsToDoc'] =
                                        eachDoc.id;
                                    items.add(mapToAddIntoItems);
                                  }
                                } else {
                                  if (eachDocItemsInOrderMap.length == 1) {
//ThisMeansThatThereIsOnlyThatWrongItemInThatTableAndHence
//TheWholeTableNeedsToBeDeleted
                                    FireStoreDeleteFinishedOrderInRunningOrders(
                                            hotelName: widget.hotelName,
                                            eachTableId: eachDoc.id)
                                        .deleteFinishedOrder();
                                  } else {
                                    Map<String, dynamic>
                                        masterOrderMapToServer = HashMap();
//ToDeleteCancelledItem
                                    masterOrderMapToServer.addAll({
                                      'itemsInOrderMap': {
                                        key: FieldValue.delete()
                                      },
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

                          someItemRejected = false;
                          someItemReady = false;
//WeGetReadyWithTheBelowEmptyLists
                          List<String> tempItemReadyAndRejectedList = [];
                          List<String> tablesOrParcelsWhereSomethingIsReady =
                              [];
                          List<num> tablesOrParcelsNumberWhereSomethingIsReady =
                              [];
                          List<num>
                              tablesOrParcelNumbersWhereSomethingIsNotReady =
                              [];
//WeGoThroughTheEntireDocsAndDependingOnTheStatusWeAddToTheAppropriateLists
                          for (var item in items!) {
//ThisIfIsForRejected
                            if (item['statusoforder'] == 11) {
                              tempItemReadyAndRejectedList
                                  .add(item['eachiteminorderid']);
                              if (!itemsReadyOrRejectedInLastCheck
                                  .contains(item['eachiteminorderid'])) {
                                someItemRejected = true;
                                someItemReady = false;
                              }
                            } else if (item['statusoforder'] == 10) {
//ThisIfIsToCheckSomethingIsReady
//WeAddToTableOrParcelWhereSomethingIsReady
//IfItIsParcel,WeAddParcelNumberList
                              tempItemReadyAndRejectedList
                                  .add(item['eachiteminorderid']);
                              tablesOrParcelsWhereSomethingIsReady
                                  .add(item['tableorparcel']);
                              if (item['tableorparcel'] == 'Parcel') {
                                tablesOrParcelsNumberWhereSomethingIsReady
                                    .add(item['tableorparcelnumber']);
                              }
//WeChangeSomeItemReadyToTrue,OnlyIfNothingIsRejectedOr,,
//ItHasBeenAlreadyCheckedInTheLastCheck
                              if (someItemRejected == false &&
                                  !itemsReadyOrRejectedInLastCheck
                                      .contains(item['eachiteminorderid'])) {
                                someItemReady = true;
                              }
                            } else if (item['statusoforder'] == 9 ||
                                item['statusoforder'] == 7) {
//ThenWeCheckWhetherSomethingNewHasComeOrIfSomethingIsAccepted
//AndAddToTheListsAccordingly
                              if (item['tableorparcel'] == 'Parcel') {
                                tablesOrParcelNumbersWhereSomethingIsNotReady
                                    .add(item['tableorparcelnumber']);
                              }
                            }
                          }
//WeMakeTempItemReadyAndRejectedInLastCheckToWhatWeCheckedLastTime
//ThisWayWeWillOnlyRingAlarmOnlyIfSomethingNewGetsReady/Rejected
                          itemsReadyOrRejectedInLastCheck =
                              tempItemReadyAndRejectedList;

//IfSomethingRejected,ImmediatelyPlayTheAlarm
                          if (someItemRejected) {
                            playRejected();
                          } else if (someItemReady) {
//ElseIfSomethingIsReady,WeGoThroughAllItemsWhereWeHaveRegisteredAParcelIsReady
//AndCheckWhether 'ParcelItemsNotReady' doesn'tHaveIt
//ThisWillEnsureOnlyIfAllItemsInParcelAreReady,WeWillRingTheReadyAlarm
                            bool allItemsInParcelReady = false;
                            if (tablesOrParcelsNumberWhereSomethingIsReady
                                .isNotEmpty) {
                              for (var statusOfParcelNumber
                                  in tablesOrParcelsNumberWhereSomethingIsReady) {
                                if (!tablesOrParcelNumbersWhereSomethingIsNotReady
                                    .contains(statusOfParcelNumber)) {
                                  allItemsInParcelReady = true;
                                }
                              }
                            }
//WeFinallyCheckWhetherAnyTableHasSomeItemReadyOrIfAllItemsInParcelAreReady
//AndIfAnyOfThisIsTrueWeRingTheAlarm
                            if (tablesOrParcelsWhereSomethingIsReady
                                    .contains('Table') ||
                                allItemsInParcelReady) {
                              playCaptain();
                            }
                          }
//Finally,WeCallTheListViewWhichWillHaveAllTheTableAndParcelButtons
//TheInputOfThisWillBeTheSnapshot
                          return Container(
                            child: ListView(
                              children: [
                                SizedBox(height: 20),
                                Container(
                                    child: Text(
                                  'Dine-In Tables',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.brown,
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold),
                                )),
                                ...dineInTableWidgets(snapshot),
                                SizedBox(height: 20),
                                Container(
                                    child: Text(
                                  'Parcels',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.blueGrey,
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold),
                                )),
                                ...parcelTableWidgets(snapshot),
                              ],
                            ),
                          );
                        } else {
//ThisErrorMessageIfSnapshotDoesn'tHaveData
                          return Center(
                            child: Text('Some Error Occured'),
                          );
                        }
                      }),
                ),
              ],
            ),
          ),
          // persistentFooterButtons: [
          //   Container(
          //     padding: EdgeInsets.all(10),
          //     color: Colors.black87,
          //     child: Row(
          //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          //       children: [
          //         legend_widget(
          //             color: Colors.white, colorDescription: 'Not Accepted'),
          //         legend_widget(
          //             color: Colors.orangeAccent, colorDescription: 'Accepted'),
          //         legend_widget(
          //             color: Colors.red, colorDescription: 'Rejected'),
          //         legend_widget(color: Colors.green, colorDescription: 'Ready'),
          //         legend_widget(
          //             color: Colors.lightBlueAccent,
          //             colorDescription: 'Delivered'),
          //         legend_widget(
          //             color: Colors.purple.shade200,
          //             colorDescription: 'Billed'),
          //       ],
          //     ),
          //   ),
          // ],
        ),
      ),
    );
  }
}

class legend_widget extends StatelessWidget {
  final Color color;
  final String colorDescription;
  const legend_widget({
    required this.color,
    required this.colorDescription,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 7,
          width: 7,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        Text(colorDescription,
            style: TextStyle(color: color, fontWeight: FontWeight.bold))
      ],
    );
  }
}
