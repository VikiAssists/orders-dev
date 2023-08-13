import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:orders_dev/Methods/bottom_button.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:orders_dev/Screens/menu_page_add_items_3.dart';
import 'package:orders_dev/Screens/tableOrParcelSplit_2.dart';
import 'package:orders_dev/constants.dart';
import 'package:orders_dev/services/firestore_services.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import 'bill_print_screen_6.dart';

//ThisIsTheScreenIfTheWaiterClicksOnAnyTable/Parcel
//ItWillShowHimAllItemsThatHaveBeenOrderedTillNow
//AndHeWillHaveOptionToAddMenuOrHeCanGoForBillPrintScreen
class ItemsInEachOrderWithDeleteTillEnd extends StatefulWidget {
//WhenWeClickOnATable/Parcel,WeWillDownloadAllTheBelowDataFromFireStore,
//AndInputToThisClass
  final String hotelName;
  final List<String> menuItems;
  final List<num> menuPrices;
  final List<String> menuTitles;
  final List<String> itemsID;
  final List<String> itemsName;
  final List<int> itemsNumber;
  final List<int> itemsStatus;
  final List<num> itemsEachPrice;
  final List<String> itemsBelongsToDoc;
  final String itemsFromDoc;
  final List<String> entireItemsListBeforeSplitting;
  final List<String> eachItemsFromEntireItemsString;
  final String tableOrParcel;
  final num tableOrParcelNumber;
  final num cgstPercentage;
  final num sgstPercentage;
  final String hotelNameForPrint;
  final String addressLine1ForPrint;
  final String addressLine2ForPrint;
  final String addressLine3ForPrint;
  final String phoneNumberForPrint;
  final num numberOfTables;
  final String gstCodeForPrint;

  const ItemsInEachOrderWithDeleteTillEnd(
      {Key? key,
      required this.hotelName,
      required this.menuItems,
      required this.menuPrices,
      required this.menuTitles,
      required this.itemsID,
      required this.itemsName,
      required this.itemsNumber,
      required this.itemsStatus,
      required this.itemsEachPrice,
      required this.itemsBelongsToDoc,
      required this.itemsFromDoc,
      required this.entireItemsListBeforeSplitting,
      required this.eachItemsFromEntireItemsString,
      required this.tableOrParcel,
      required this.tableOrParcelNumber,
      required this.cgstPercentage,
      required this.sgstPercentage,
      required this.hotelNameForPrint,
      required this.addressLine1ForPrint,
      required this.addressLine2ForPrint,
      required this.addressLine3ForPrint,
      required this.phoneNumberForPrint,
      required this.numberOfTables,
      required this.gstCodeForPrint})
      : super(key: key);

  @override
  State<ItemsInEachOrderWithDeleteTillEnd> createState() =>
      _ItemsInEachOrderWithDeleteTillEndState();
}

class _ItemsInEachOrderWithDeleteTillEndState
    extends State<ItemsInEachOrderWithDeleteTillEnd>
    with WidgetsBindingObserver {
//KeepingInitialStateOfAllItemsDeliveredAsFalse
  bool allItemsDeliveredToCustomerTrueElseFalse = true;

  late StreamSubscription internetCheckerSubscription;
  bool pageHasInternet = true;
  List<Map<String, dynamic>> items = [];
  String addedItemsSet = '';
  List<num> localItemsStatus = [];
  String parentOrChild = '';
  num chefStatusForSplit = 0;
  num captainStatusForSplit = 0;
  bool splitPressed = false;
  bool movePressed = false;
  List<String> tablesToMoveTo = ['Select'];
  List<String> parcelsToMoveTo = ['Select'];
  bool tableClickedTrueParcelClickedFalse = true;
  String tableOrParcelToMoveTo = 'Select';
  List<String> tablesAlreadyOccupied = [];
  List<String> parcelsAlreadyOccupied = [];
  List<Map<String, dynamic>> presentTablesParcelsOccupied = [];
  late VideoPlayerController _videoController;

  @override
  void initState() {
//WeAreMakingThisVariableSimplyToGetTheProviderValueOnce.FirstTimeItWillBeInitialValue
//IfWeDontHaveThisFirstTimeTaking,TheVideoWillPlayAgainAndAgain
//EverytimeSomeoneGets
    bool tempProviderInitialize =
        Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .captainInsideTableInstructionsVideoPlayedFromClass;
    // TODO: implement initState
    _videoController = VideoPlayerController.asset(
        'assets/videos/captain_delivered_cancel_tutorial.mp4');
    // _videoController.initialize().then((value) => _videoController.play());
    // _videoController.initialize();
    buildCaptainInTableInstructionAlertDialogWidgetWithTimer();

    //ThisIsTheStreamWhichWillKeepCheckingOnTheStatusOfInternet
    //ItWillKeepLookingForStatusChangeAndWillUpdateThe hasInternet Variable
    internetAvailabilityChecker();
    localItemsStatus = [];
    localItemsStatus = widget.itemsStatus;
    itemsDeliveredOrNotStatusChecker();
    splitPressed = false;
    movePressed = false;

    super.initState();
  }

  //ThisIsToCheckAppLifeCycleStateWhetherItIsInForegroundOrBackground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // TODO: implement didChangeAppLifecycleState

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) return;

    final isBackground = state == AppLifecycleState.paused;
    final isForeground = state == AppLifecycleState.resumed;

    if (isForeground) {
      setState(() {
        pageHasInternet = true;
      });
      internetAvailabilityChecker();
    }

    super.didChangeAppLifecycleState(state);
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
        print(
            '_everySecondForInternetChecking $_everySecondForInternetChecking');
      }
    });
  }

//Giving500msTimerToCheckWhetherThatInitializingTimeHelpsIt
//InSomeMobilesItWasntPlayingAndBlankScreenWasGettingReturned
//HenceThisStrategyTryOut.
  void buildCaptainInTableInstructionAlertDialogWidgetWithTimer() async {
    print('start of 2 seconds');
    Timer _videoPlayTimer;
    _videoController.initialize();
    _videoPlayTimer = Timer(Duration(milliseconds: 1000), () async {
      print('after 2 seconds');
      await Future(() {
        if (Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .captainInsideTableInstructionsVideoPlayedFromClass ==
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
                  // height: 400,
                  // width: 100,
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
                              .captainInsideTableVideoInstructionLookedOrNot(
                                  true);

                          Navigator.pop(context);
                        },
                        child: Padding(
                          // padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                          padding: const EdgeInsets.all(20.0),
                          child: Text('  OK  '),
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

  void itemsDeliveredOrNotStatusChecker() {
    bool allItemsDeliveredToCustomerTrueOrFalse = true;
    int i = 0;
    for (var status in localItemsStatus) {
      ++i;
      if (status != 3) {
        allItemsDeliveredToCustomerTrueOrFalse = false;
      }
      if (i == localItemsStatus.length) {
        setState(() {
          allItemsDeliveredToCustomerTrueElseFalse =
              allItemsDeliveredToCustomerTrueOrFalse;
        });
      }
    }
  }

  @override
  Widget build(BuildContext innerContext) {
//namingItAsInnerContextBecauseUnlessInnerContextIsMentioned
//AfterTakingAlertDialog,ItIsntClosingUnlessExactInnerContextIsMentioned
    num cgstCalculated = 0;
    num sgstCalculated = 0;
    num totalBillWithTaxes = 0;
    String customername = '';
    String customermobileNumber = '';
    String customeraddressline1 = '';
    TextEditingController _controller = TextEditingController();

    void userInfoUpdaterInFireStore() {
      if (customername == '') {
        customername = 'customername';
      }
      if (customermobileNumber == '') {
        customermobileNumber = 'customermobileNumber';
      }
      if (customeraddressline1 == '') {
        customeraddressline1 = 'customeraddressline1';
      }

      final userInfoStringSplit = addedItemsSet.split('*');
      userInfoStringSplit[4] = customername;
      userInfoStringSplit[5] = customermobileNumber;
      userInfoStringSplit[6] = customeraddressline1;

      String tempStatusUpdaterString = '';
      for (int i = 0; i < userInfoStringSplit.length - 1; i++) {
        tempStatusUpdaterString += '${userInfoStringSplit[i]}*';
      }

      final statusUpdatedStringCheck = tempStatusUpdaterString.split('*');

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
              itemsUpdaterString: tempStatusUpdaterString,
              seatingNumber: widget.itemsFromDoc,
              captainStatus: captainStatus,
              chefStatus: chefStatus,
              partOfTableOrParcel: widget.tableOrParcel,
              partOfTableOrParcelNumber: widget.tableOrParcelNumber.toString())
          .addOrder();
    }

    Widget buildUserInfoWidget() {
      return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Text('Customer name',
                    style: TextStyle(
                        fontWeight: FontWeight.w500, color: Colors.green)),
              ),
              Container(
                padding: EdgeInsets.all(10),
                child: TextField(
                  maxLength: 100,
                  controller: TextEditingController(text: customername),
                  onChanged: (value) {
                    customername = value;
                  },
                  decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Enter Username',
                          hintStyle: TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: Colors.green)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: Colors.green))),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: Text('Mobile Number', style: userInfoTextStyle),
              ),
              Container(
                padding: EdgeInsets.all(10),
                child: TextField(
                  maxLength: 20,
                  keyboardType: TextInputType.phone,
                  // controller: TextEditingController(text: customermobileNumber),
//ToUseNumberInputKeyboard,youNeedToDeclareControllerInsideStatefulWidgetItself
                  controller: _controller,
                  onChanged: (value) {
                    customermobileNumber = value.toString();
                  },
                  decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Enter Mobile Number',
                          hintStyle: TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: Colors.green)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: Colors.green))),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: Text('Address', style: userInfoTextStyle),
              ),
              Container(
                padding: EdgeInsets.all(10),
                child: TextField(
                  maxLength: 250,
                  controller: TextEditingController(text: customeraddressline1),
                  onChanged: (value) {
                    customeraddressline1 = value;
                  },
                  decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Enter Address',
                          hintStyle: TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: Colors.green)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(color: Colors.green))),
                ),
              ),
              Center(
                child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.green),
                    ),
                    onPressed: () {
                      userInfoUpdaterInFireStore();
                      Navigator.pop(context);
                    },
                    child: Text('Done')),
              )
            ],
          ),
        ),
      );
    }

    List<DropdownMenuItem<String>> getTableDropDownMenuItem() {
      List<DropdownMenuItem<String>> dropDownMenuItems = [
        DropdownMenuItem(
            child: Center(
              child: Text('Select',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
            ),
            value: 'Select')
      ];
      for (int i = 1; i <= (((widget.numberOfTables + 4) ~/ 4) + 1) * 4; i++) {
        if (!((widget.tableOrParcel == 'Table') &&
            (widget.tableOrParcelNumber == i))) {
          var newItem = DropdownMenuItem(
            child: Center(
              child: Text(i.toString(),
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: tablesAlreadyOccupied.contains(i.toString())
                          ? Colors.red
                          : Colors.black)),
            ),
            value: i.toString(),
          );
          dropDownMenuItems.add(newItem);
        }
      }
      return dropDownMenuItems;
    }

    List<DropdownMenuItem<String>> getParcelDropDownMenuItem() {
      List<DropdownMenuItem<String>> dropDownMenuItems = [
        DropdownMenuItem(
            child: Center(
              child: Text('Select',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
            ),
            value: 'Select')
      ];
      for (int i = 1; i <= (((widget.numberOfTables + 4) ~/ 4) + 1) * 4; i++) {
        if (!((widget.tableOrParcel == 'Parcel') &&
            (widget.tableOrParcelNumber == i))) {
          var newItem = DropdownMenuItem(
            child: Container(
                alignment: Alignment.centerLeft,
                child: Center(
                  child: Text(i.toString(),
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: parcelsAlreadyOccupied.contains(i.toString())
                              ? Colors.red
                              : Colors.black)),
                )),
            value: i.toString(),
          );
          dropDownMenuItems.add(newItem);
        }
      }
      return dropDownMenuItems;
    }

//     Widget buildMoveTableOrParcelWidget() {
//       return Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Center(
//               child: Text(
//             'Move To',
//             style: TextStyle(fontSize: 30.0),
//           )),
//           SizedBox(height: 10),
//           Row(
//             children: [
//               SizedBox(width: 10),
//               Expanded(
//                 // width: double.infinity,
//                 child: ElevatedButton(
//                     style: ButtonStyle(
//                       backgroundColor: tableClickedTrueParcelClickedFalse
//                           ? MaterialStateProperty.all(Colors.grey)
//                           : MaterialStateProperty.all(Colors.green),
//                     ),
//                     onPressed: () {
//                       setState(() {
//                         tableClickedTrueParcelClickedFalse = false;
//                       });
//                       Navigator.pop(context);
//                       showModalBottomSheet(
//                           isScrollControlled: true,
//                           context: context,
//                           builder: (context) {
//                             return buildMoveTableOrParcelWidget();
//                           });
//                     },
//                     child: Text('Parcels')),
//               ),
//               SizedBox(width: 10),
//               Expanded(
//                   // width: double.infinity,
//                   child: ElevatedButton(
//                       style: ButtonStyle(
//                         backgroundColor: tableClickedTrueParcelClickedFalse
//                             ? MaterialStateProperty.all(Colors.green)
//                             : MaterialStateProperty.all(Colors.grey),
//                       ),
//                       onPressed: () {
//                         setState(() {
//                           tableClickedTrueParcelClickedFalse = true;
//                         });
//                         Navigator.pop(context);
//                         showModalBottomSheet(
//                             isScrollControlled: true,
//                             context: context,
//                             builder: (context) {
//                               return buildMoveTableOrParcelWidget();
//                             });
//                       },
//                       child: Text('Tables'))),
//               SizedBox(width: 10)
//             ],
//           ),
//           SizedBox(height: 10),
//           Container(
//             padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
//             width: 100,
//             decoration: BoxDecoration(
//                 color: Colors.green,
// //                Theme.of(context).primaryColor
//                 borderRadius: BorderRadius.circular(30)),
// //WeHaveDropDownButtonInside
// //UnderlineWillBeContainer
// //InitiallyWhenWeOpen,TheValueAlwaysWillBe 0-BrowseMenu
// //OnClicked,ItWillCheckTheValueOfThatItem&ScrollToThatIndex
//             child: DropdownButtonFormField<String>(
//               isExpanded: true,
//               // underline: Container(),
//               decoration: InputDecoration.collapsed(hintText: ''),
//               dropdownColor: Colors.white,
//               value: tableOrParcelToMoveTo,
//               onChanged: (value) {
//                 setState(() {
//                   tableOrParcelToMoveTo = value.toString();
//                 });
//                 print('tableOrParcelToMoveTo');
//                 print(tableOrParcelToMoveTo);
//               },
//               items: tableClickedTrueParcelClickedFalse
//                   ? getTableDropDownMenuItem()
//                   : getParcelDropDownMenuItem(),
//             ),
//           ),
//           SizedBox(height: 10),
//           ElevatedButton(
//               style: ButtonStyle(
//                 backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
//               ),
//               onPressed: () {
//                 Navigator.pop(context);
//               },
//               child: Text('Done')),
//           SizedBox(height: 10)
//         ],
//       );
//     }

    void buildMoveTableOrParcelAlertDialogWidget() {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          elevation: 24.0,
          // backgroundColor: Colors.greenAccent,
          // shape: CircleBorder(),
          title: Column(
            children: [
              Center(
                  child: Text(
                'Move To',
                style: TextStyle(fontSize: 30.0),
              )),
              SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(width: 10),
                  Expanded(
                    // width: double.infinity,
                    child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: tableClickedTrueParcelClickedFalse
                              ? MaterialStateProperty.all(Colors.grey)
                              : MaterialStateProperty.all(Colors.green),
                        ),
                        onPressed: () {
                          setState(() {
                            tableClickedTrueParcelClickedFalse = false;
                            tableOrParcelToMoveTo = 'Select';
                          });
                          print('tableClickedTrueParcelClickedFalse');
                          print(tableClickedTrueParcelClickedFalse);
                          Navigator.pop(context);
                          buildMoveTableOrParcelAlertDialogWidget();
                        },
                        child: Text('Parcels')),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                      // width: double.infinity,
                      child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: tableClickedTrueParcelClickedFalse
                                ? MaterialStateProperty.all(Colors.green)
                                : MaterialStateProperty.all(Colors.grey),
                          ),
                          onPressed: () {
                            setState(() {
                              tableClickedTrueParcelClickedFalse = true;
                              tableOrParcelToMoveTo = 'Select';
                            });
                            print('tableClickedTrueParcelClickedFalse');
                            print(tableClickedTrueParcelClickedFalse);
                            Navigator.pop(context);
                            buildMoveTableOrParcelAlertDialogWidget();
                          },
                          child: Text('Tables'))),
                  SizedBox(width: 10)
                ],
              ),
              SizedBox(height: 10),
            ],
          ),
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            // width: 5,
            decoration: BoxDecoration(
                color: tableClickedTrueParcelClickedFalse
                    ? Colors.brown.shade100
                    : Colors.blueGrey,
//                Theme.of(context).primaryColor
                borderRadius: BorderRadius.circular(30)),
//WeHaveDropDownButtonInside
//UnderlineWillBeContainer
//InitiallyWhenWeOpen,TheValueAlwaysWillBe 0-BrowseMenu
//OnClicked,ItWillCheckTheValueOfThatItem&ScrollToThatIndex
            child: DropdownButtonFormField<String>(
              isDense: true,
              isExpanded: true,
              // underline: Container(),
              decoration: InputDecoration.collapsed(hintText: ''),
              dropdownColor: Colors.white,
              value: tableOrParcelToMoveTo,
              onChanged: (value) {
                setState(() {
                  tableOrParcelToMoveTo = value.toString();
                });
                print('tableOrParcelToMoveTo');
                print(tableOrParcelToMoveTo);
              },
              items: tableClickedTrueParcelClickedFalse
                  ? getTableDropDownMenuItem()
                  : getParcelDropDownMenuItem(),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.grey),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Cancel')),
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.green),
                    ),
                    onPressed: () {
//ThisIsIfAnyTableorParcelWasIndeedSelected
                      if (tableOrParcelToMoveTo != 'Select') {
                        print('inside select');
                        setState(() {
                          movePressed = true;
                        });

//ThisWillCloseTheDialogBox
                        Navigator.pop(context);
//ThisWillCloseTheEntireItemsScreen
                        Navigator.pop(innerContext);
// ThisIsIfWeAreMovingToTable
                        if (tableClickedTrueParcelClickedFalse) {
//ThisIsIfThereIsAlreadySomeoneSitingInTheTable
                          if (tablesAlreadyOccupied
                              .contains(tableOrParcelToMoveTo)) {
//ThisIsTheMapInServerThatNeedsToBeMoved
                            Map<String, dynamic> alreadyPresentOrderToBeMoved =
                                HashMap();
                            String
                                lastStringOfIDOfAlreadyPresentOrderToBeMoved =
                                '';
                            for (var eachPresentTablesParcelsOccupied
                                in presentTablesParcelsOccupied) {
                              if (eachPresentTablesParcelsOccupied[
                                          'partOfTableOrParcel'] ==
                                      'Table' &&
                                  eachPresentTablesParcelsOccupied[
                                          'partOfTableOrParcelNumber'] ==
                                      tableOrParcelToMoveTo) {
//NoMatterHowManyItemsAreThereWithThisTableAndParcelNumber
//WhenItComesInOrder,WeOnlyNeedTheLastOne.
//So,NotMakingList.SimplyStoringItAllInOneMapOnly
                                alreadyPresentOrderToBeMoved['addedItemsSet'] =
                                    eachPresentTablesParcelsOccupied[
                                        'addedItemsSet'];
                                alreadyPresentOrderToBeMoved['captainStatus'] =
                                    eachPresentTablesParcelsOccupied[
                                        'captainStatus'];
                                alreadyPresentOrderToBeMoved['chefStatus'] =
                                    eachPresentTablesParcelsOccupied[
                                        'chefStatus'];
                                alreadyPresentOrderToBeMoved[
                                        'partOfTableOrParcel'] =
                                    eachPresentTablesParcelsOccupied[
                                        'partOfTableOrParcel'];
                                alreadyPresentOrderToBeMoved[
                                        'partOfTableOrParcelNumber'] =
                                    eachPresentTablesParcelsOccupied[
                                        'partOfTableOrParcelNumber'];
                                alreadyPresentOrderToBeMoved[
                                        'presentOccupiedTablesParcelsID'] =
                                    eachPresentTablesParcelsOccupied[
                                        'presentOccupiedTablesParcelsID'];
                                lastStringOfIDOfAlreadyPresentOrderToBeMoved =
                                    eachPresentTablesParcelsOccupied[
                                            'presentOccupiedTablesParcelsID']
                                        .toString()[eachPresentTablesParcelsOccupied[
                                                'presentOccupiedTablesParcelsID']
                                            .toString()
                                            .length -
                                        1];
                              }
                            }
//TrueMeansWeAreMovingToATable/ParcelThatWasAlreadySplit
                            if (lastStringOfIDOfAlreadyPresentOrderToBeMoved
                                .contains(RegExp(r'[A-Z]'))) {
//WeAreEnsuringThatTheUpdateIsMadeAsTheNextAlphabetInTheAlreadyPresentTable
//AndAlsoEnsuringTableNumberIsChanged
                              final parentOrChildUpdateStringSplit =
                                  addedItemsSet.split('*');
                              parentOrChildUpdateStringSplit[0] = 'Table';
                              parentOrChildUpdateStringSplit[1] =
                                  tableOrParcelToMoveTo;
//InCaseItWasAParent,WeAreReplacingItAsChildWithAppropriateAlphabet
                              parentOrChildUpdateStringSplit[7] =
                                  String.fromCharCode(
                                      (lastStringOfIDOfAlreadyPresentOrderToBeMoved
                                              .codeUnitAt(0)) +
                                          1);

                              String tempStatusUpdaterString = '';
                              for (int i = 0;
                                  i < parentOrChildUpdateStringSplit.length - 1;
                                  i++) {
                                tempStatusUpdaterString +=
                                    '${parentOrChildUpdateStringSplit[i]}*';
                              }

                              FireStoreAddOrderServiceWithSplit(
                                      hotelName: widget.hotelName,
                                      itemsUpdaterString:
                                          tempStatusUpdaterString,
                                      seatingNumber:
                                          'Table:${tableOrParcelToMoveTo}${String.fromCharCode((lastStringOfIDOfAlreadyPresentOrderToBeMoved.codeUnitAt(0)) + 1)}',
                                      captainStatus: captainStatusForSplit,
                                      chefStatus: chefStatusForSplit,
                                      partOfTableOrParcel: 'Table',
                                      partOfTableOrParcelNumber:
                                          tableOrParcelToMoveTo)
                                  .addOrder();
                              // Navigator.pop(context);
                              // Navigator.pop(innerContext);

                              FireStoreDeleteFinishedOrderInPresentOrders(
                                      hotelName: widget.hotelName,
                                      eachItemId: widget.itemsFromDoc)
                                  .deleteFinishedOrder();
                            } else {
//WeAreMovingToTableWhichIsYetToBeSplitted
//First,StoringThatATableWithAAsThoughItWasSplit

                              final parentOrChildUpdateStringSplit1 =
                                  alreadyPresentOrderToBeMoved['addedItemsSet']
                                      .split('*');
                              parentOrChildUpdateStringSplit1[7] = 'A';

                              String tempStatusUpdaterString1 = '';
                              for (int i = 0;
                                  i <
                                      parentOrChildUpdateStringSplit1.length -
                                          1;
                                  i++) {
                                tempStatusUpdaterString1 +=
                                    '${parentOrChildUpdateStringSplit1[i]}*';
                              }

                              FireStoreAddOrderServiceWithSplit(
                                      hotelName: widget.hotelName,
                                      itemsUpdaterString:
                                          tempStatusUpdaterString1,
                                      seatingNumber:
                                          'Table:${tableOrParcelToMoveTo}A',
                                      captainStatus:
                                          alreadyPresentOrderToBeMoved[
                                              'captainStatus'],
                                      chefStatus: alreadyPresentOrderToBeMoved[
                                          'chefStatus'],
                                      partOfTableOrParcel: 'Table',
                                      partOfTableOrParcelNumber:
                                          tableOrParcelToMoveTo)
                                  .addOrder();
//WeNeedToDeleteTheOrderBeforeWeHadResavedItAsSplitOne
                              FireStoreDeleteFinishedOrderInPresentOrders(
                                      hotelName: widget.hotelName,
                                      eachItemId: alreadyPresentOrderToBeMoved[
                                          'presentOccupiedTablesParcelsID'])
                                  .deleteFinishedOrder();
                              // Navigator.pop(context);
                              // Navigator.pop(innerContext);

                              final parentOrChildUpdateStringSplit =
                                  addedItemsSet.split('*');
                              parentOrChildUpdateStringSplit[0] = 'Table';
                              parentOrChildUpdateStringSplit[1] =
                                  tableOrParcelToMoveTo;
                              parentOrChildUpdateStringSplit[7] = 'B';

                              String tempStatusUpdaterString = '';
                              for (int i = 0;
                                  i < parentOrChildUpdateStringSplit.length - 1;
                                  i++) {
                                tempStatusUpdaterString +=
                                    '${parentOrChildUpdateStringSplit[i]}*';
                              }

                              FireStoreAddOrderServiceWithSplit(
                                      hotelName: widget.hotelName,
                                      itemsUpdaterString:
                                          tempStatusUpdaterString,
                                      seatingNumber:
                                          'Table:${tableOrParcelToMoveTo}B',
                                      captainStatus: captainStatusForSplit,
                                      chefStatus: chefStatusForSplit,
                                      partOfTableOrParcel: 'Table',
                                      partOfTableOrParcelNumber:
                                          tableOrParcelToMoveTo)
                                  .addOrder();
                              FireStoreDeleteFinishedOrderInPresentOrders(
                                      hotelName: widget.hotelName,
                                      eachItemId: widget.itemsFromDoc)
                                  .deleteFinishedOrder();
                            }
                          } else {
//IfThereIsNoOneSittingInTheTableAlready
//IfTheOrderWeAremovingIsFromAnAlreadySplitTable,
//ItShouldBeEnsured,ItIsMovedAsAParentToTheNoOneOccupiedTable
                            // Navigator.pop(context);
                            // Navigator.pop(innerContext);

                            final parentOrChildUpdateStringSplit =
                                addedItemsSet.split('*');
                            parentOrChildUpdateStringSplit[0] = 'Table';
                            parentOrChildUpdateStringSplit[1] =
                                tableOrParcelToMoveTo;
                            parentOrChildUpdateStringSplit[7] = 'parent';

                            String tempStatusUpdaterString = '';
                            for (int i = 0;
                                i < parentOrChildUpdateStringSplit.length - 1;
                                i++) {
                              tempStatusUpdaterString +=
                                  '${parentOrChildUpdateStringSplit[i]}*';
                            }

                            FireStoreAddOrderServiceWithSplit(
                                    hotelName: widget.hotelName,
                                    itemsUpdaterString: tempStatusUpdaterString,
                                    seatingNumber:
                                        'Table:${tableOrParcelToMoveTo}',
                                    captainStatus: captainStatusForSplit,
                                    chefStatus: chefStatusForSplit,
                                    partOfTableOrParcel: 'Table',
                                    partOfTableOrParcelNumber:
                                        tableOrParcelToMoveTo)
                                .addOrder();

                            FireStoreDeleteFinishedOrderInPresentOrders(
                                    hotelName: widget.hotelName,
                                    eachItemId: widget.itemsFromDoc)
                                .deleteFinishedOrder();
                          }
                        } else {
//ThisIsIfWeAreMovingToParcel
                          //ThisIsIfThereIsAlreadySomeoneSitingInTheParcel
                          if (parcelsAlreadyOccupied
                              .contains(tableOrParcelToMoveTo)) {
//ThisIsTheMapInServerThatNeedsToBeMoved
                            Map<String, dynamic> alreadyPresentOrderToBeMoved =
                                HashMap();
                            String
                                lastStringOfIDOfAlreadyPresentOrderToBeMoved =
                                '';
                            for (var eachPresentTablesParcelsOccupied
                                in presentTablesParcelsOccupied) {
                              if (eachPresentTablesParcelsOccupied[
                                          'partOfTableOrParcel'] ==
                                      'Parcel' &&
                                  eachPresentTablesParcelsOccupied[
                                          'partOfTableOrParcelNumber'] ==
                                      tableOrParcelToMoveTo) {
//NoMatterHowManyItemsAreThereWithThisTableAndParcelNumber
//WhenItComesInOrder,WeOnlyNeedTheLastOne.
//So,NotMakingList.SimplyStoringItAllInOneMapOnly
                                alreadyPresentOrderToBeMoved['addedItemsSet'] =
                                    eachPresentTablesParcelsOccupied[
                                        'addedItemsSet'];
                                alreadyPresentOrderToBeMoved['captainStatus'] =
                                    eachPresentTablesParcelsOccupied[
                                        'captainStatus'];
                                alreadyPresentOrderToBeMoved['chefStatus'] =
                                    eachPresentTablesParcelsOccupied[
                                        'chefStatus'];
                                alreadyPresentOrderToBeMoved[
                                        'partOfTableOrParcel'] =
                                    eachPresentTablesParcelsOccupied[
                                        'partOfTableOrParcel'];
                                alreadyPresentOrderToBeMoved[
                                        'partOfTableOrParcelNumber'] =
                                    eachPresentTablesParcelsOccupied[
                                        'partOfTableOrParcelNumber'];
                                alreadyPresentOrderToBeMoved[
                                        'presentOccupiedTablesParcelsID'] =
                                    eachPresentTablesParcelsOccupied[
                                        'presentOccupiedTablesParcelsID'];
                                lastStringOfIDOfAlreadyPresentOrderToBeMoved =
                                    eachPresentTablesParcelsOccupied[
                                            'presentOccupiedTablesParcelsID']
                                        .toString()[eachPresentTablesParcelsOccupied[
                                                'presentOccupiedTablesParcelsID']
                                            .toString()
                                            .length -
                                        1];
                              }
                            }
//TrueMeansWeAreMovingToATable/ParcelThatWasAlreadySplit
                            if (lastStringOfIDOfAlreadyPresentOrderToBeMoved
                                .contains(RegExp(r'[A-Z]'))) {
//WeAreEnsuringThatTheUpdateIsMadeAsTheNextAlphabetInTheAlreadyPresentParcel
//AndAlsoEnsuringTableNumberIsChanged
                              final parentOrChildUpdateStringSplit =
                                  addedItemsSet.split('*');
                              parentOrChildUpdateStringSplit[0] = 'Parcel';
                              parentOrChildUpdateStringSplit[1] =
                                  tableOrParcelToMoveTo;
//InCaseItWasAParent,WeAreReplacingItAsChildWithAppropriateAlphabet
                              parentOrChildUpdateStringSplit[7] =
                                  String.fromCharCode(
                                      (lastStringOfIDOfAlreadyPresentOrderToBeMoved
                                              .codeUnitAt(0)) +
                                          1);

                              String tempStatusUpdaterString = '';
                              for (int i = 0;
                                  i < parentOrChildUpdateStringSplit.length - 1;
                                  i++) {
                                tempStatusUpdaterString +=
                                    '${parentOrChildUpdateStringSplit[i]}*';
                              }

                              FireStoreAddOrderServiceWithSplit(
                                      hotelName: widget.hotelName,
                                      itemsUpdaterString:
                                          tempStatusUpdaterString,
                                      seatingNumber:
                                          'Parcel:${tableOrParcelToMoveTo}${String.fromCharCode((lastStringOfIDOfAlreadyPresentOrderToBeMoved.codeUnitAt(0)) + 1)}',
                                      captainStatus: captainStatusForSplit,
                                      chefStatus: chefStatusForSplit,
                                      partOfTableOrParcel: 'Parcel',
                                      partOfTableOrParcelNumber:
                                          tableOrParcelToMoveTo)
                                  .addOrder();
                              // Navigator.pop(context);
                              // Navigator.pop(innerContext);

                              FireStoreDeleteFinishedOrderInPresentOrders(
                                      hotelName: widget.hotelName,
                                      eachItemId: widget.itemsFromDoc)
                                  .deleteFinishedOrder();
                            } else {
//WeAreMovingToTableWhichIsYetToBeSplitted
//First,StoringThatATableWithAAsThoughItWasSplit

                              final parentOrChildUpdateStringSplit1 =
                                  alreadyPresentOrderToBeMoved['addedItemsSet']
                                      .split('*');
                              parentOrChildUpdateStringSplit1[7] = 'A';

                              String tempStatusUpdaterString1 = '';
                              for (int i = 0;
                                  i <
                                      parentOrChildUpdateStringSplit1.length -
                                          1;
                                  i++) {
                                tempStatusUpdaterString1 +=
                                    '${parentOrChildUpdateStringSplit1[i]}*';
                              }

                              FireStoreAddOrderServiceWithSplit(
                                      hotelName: widget.hotelName,
                                      itemsUpdaterString:
                                          tempStatusUpdaterString1,
                                      seatingNumber:
                                          'Parcel:${tableOrParcelToMoveTo}A',
                                      captainStatus:
                                          alreadyPresentOrderToBeMoved[
                                              'captainStatus'],
                                      chefStatus: alreadyPresentOrderToBeMoved[
                                          'chefStatus'],
                                      partOfTableOrParcel: 'Parcel',
                                      partOfTableOrParcelNumber:
                                          tableOrParcelToMoveTo)
                                  .addOrder();
//WeNeedToDeleteTheOrderBeforeWeHadResavedItAsSplitOne
                              FireStoreDeleteFinishedOrderInPresentOrders(
                                      hotelName: widget.hotelName,
                                      eachItemId: alreadyPresentOrderToBeMoved[
                                          'presentOccupiedTablesParcelsID'])
                                  .deleteFinishedOrder();
                              // Navigator.pop(context);
                              // Navigator.pop(innerContext);

                              final parentOrChildUpdateStringSplit =
                                  addedItemsSet.split('*');
                              parentOrChildUpdateStringSplit[0] = 'Parcel';
                              parentOrChildUpdateStringSplit[1] =
                                  tableOrParcelToMoveTo;
                              parentOrChildUpdateStringSplit[7] = 'B';

                              String tempStatusUpdaterString = '';
                              for (int i = 0;
                                  i < parentOrChildUpdateStringSplit.length - 1;
                                  i++) {
                                tempStatusUpdaterString +=
                                    '${parentOrChildUpdateStringSplit[i]}*';
                              }

                              FireStoreAddOrderServiceWithSplit(
                                      hotelName: widget.hotelName,
                                      itemsUpdaterString:
                                          tempStatusUpdaterString,
                                      seatingNumber:
                                          'Parcel:${tableOrParcelToMoveTo}B',
                                      captainStatus: captainStatusForSplit,
                                      chefStatus: chefStatusForSplit,
                                      partOfTableOrParcel: 'Parcel',
                                      partOfTableOrParcelNumber:
                                          tableOrParcelToMoveTo)
                                  .addOrder();
                              FireStoreDeleteFinishedOrderInPresentOrders(
                                      hotelName: widget.hotelName,
                                      eachItemId: widget.itemsFromDoc)
                                  .deleteFinishedOrder();
                            }
                          } else {
//IfThereIsNoOneSittingInTheTableAlready
//IfTheOrderWeAremovingIsFromAnAlreadySplitTable,
//ItShouldBeEnsured,ItIsMovedAsAParentToTheNoOneOccupiedTable
                            // Navigator.pop(context);
                            // Navigator.pop(innerContext);

                            final parentOrChildUpdateStringSplit =
                                addedItemsSet.split('*');
                            parentOrChildUpdateStringSplit[0] = 'Parcel';
                            parentOrChildUpdateStringSplit[1] =
                                tableOrParcelToMoveTo;
                            parentOrChildUpdateStringSplit[7] = 'parent';

                            String tempStatusUpdaterString = '';
                            for (int i = 0;
                                i < parentOrChildUpdateStringSplit.length - 1;
                                i++) {
                              tempStatusUpdaterString +=
                                  '${parentOrChildUpdateStringSplit[i]}*';
                            }

                            FireStoreAddOrderServiceWithSplit(
                                    hotelName: widget.hotelName,
                                    itemsUpdaterString: tempStatusUpdaterString,
                                    seatingNumber:
                                        'Parcel:${tableOrParcelToMoveTo}',
                                    captainStatus: captainStatusForSplit,
                                    chefStatus: chefStatusForSplit,
                                    partOfTableOrParcel: 'Parcel',
                                    partOfTableOrParcelNumber:
                                        tableOrParcelToMoveTo)
                                .addOrder();

                            FireStoreDeleteFinishedOrderInPresentOrders(
                                    hotelName: widget.hotelName,
                                    eachItemId: widget.itemsFromDoc)
                                .deleteFinishedOrder();
                          }
                        }
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Text('Move'))
              ],
            ),
          ],
        ),
        barrierDismissible: false,
      );
    }

    return WillPopScope(
      onWillPop: () async {
        print('inside this back');
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
//TheBackIconButtonInAppBarWillPopTheScreenOut
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: kAppBarBackIconColor),
              onPressed: () async {
                Navigator.pop(context);
              }),
          backgroundColor: kAppBarBackgroundColor,
//WithTheTable/ParcelNumber,WeInputTheHeadingAccordingly
          title: Text(
            ' ${widget.itemsFromDoc}',
            style: kAppBarTextStyle,
          ),

          centerTitle: true,
          actions: <Widget>[
            IconButton(
                onPressed: () {
                  Provider.of<PrinterAndOtherDetailsProvider>(context,
                          listen: false)
                      .captainInsideTableVideoInstructionLookedOrNot(false);

                  buildCaptainInTableInstructionAlertDialogWidgetWithTimer();

                  // _videoController.play();
                },
                icon: Icon(
                  Icons.help,
                  color: kAppBarBackIconColor,
                )),
            PopupMenuButton(
                icon: const Icon(Icons.more_vert_rounded,
                    color: kAppBarBackIconColor),
                itemBuilder: (BuildContext context) => [
                      PopupMenuItem(
                        child: TextButton(
                          style: ButtonStyle(alignment: Alignment.bottomLeft),
                          child: Text(
                            'Split',
                            style: kMenuBarPopUpMenuButtonTextStyle,
                          ),
                          onPressed: () {
                            setState(() {
                              splitPressed = true;
                            });
                            if (parentOrChild == 'parent') {
                              final parentOrChildUpdateStringSplit =
                                  addedItemsSet.split('*');
                              parentOrChildUpdateStringSplit[7] = 'A';

                              String tempStatusUpdaterString = '';
                              for (int i = 0;
                                  i < parentOrChildUpdateStringSplit.length - 1;
                                  i++) {
                                tempStatusUpdaterString +=
                                    '${parentOrChildUpdateStringSplit[i]}*';
                              }

                              FireStoreAddOrderServiceWithSplit(
                                      hotelName: widget.hotelName,
                                      itemsUpdaterString:
                                          tempStatusUpdaterString,
                                      seatingNumber:
                                          '${widget.tableOrParcel}:${widget.tableOrParcelNumber}A',
                                      captainStatus: captainStatusForSplit,
                                      chefStatus: chefStatusForSplit,
                                      partOfTableOrParcel: widget.tableOrParcel,
                                      partOfTableOrParcelNumber:
                                          widget.tableOrParcelNumber.toString())
                                  .addOrder();
                              Navigator.pop(context);

                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          TableOrParcelSplitTwo(
                                            hotelName: widget.hotelName,
                                            partOfTableOrParcel:
                                                widget.tableOrParcel,
                                            partOfTableOrParcelNumber: widget
                                                .tableOrParcelNumber
                                                .toString(),
                                            menuItems: widget.menuItems,
                                            menuTitles: widget.menuTitles,
                                            menuPrices: widget.menuPrices,
                                            cgstPercentage:
                                                widget.cgstPercentage,
                                            sgstPercentage:
                                                widget.sgstPercentage,
                                            hotelNameForPrint:
                                                widget.hotelNameForPrint,
                                            phoneNumberForPrint:
                                                widget.phoneNumberForPrint,
                                            addressLine1ForPrint:
                                                widget.addressLine1ForPrint,
                                            addressLine2ForPrint:
                                                widget.addressLine2ForPrint,
                                            addressLine3ForPrint:
                                                widget.addressLine3ForPrint,
                                            numberOfTables:
                                                widget.numberOfTables,
                                            gstCodeForPrint:
                                                widget.gstCodeForPrint,
                                          )));

                              FireStoreDeleteFinishedOrderInPresentOrders(
                                      hotelName: widget.hotelName,
                                      eachItemId: widget.itemsFromDoc)
                                  .deleteFinishedOrder();
                            } else {
                              int count = 0;
                              Navigator.of(context)
                                  .popUntil((_) => count++ >= 2);
                            }
                          },
                        ),
                      ),
                      PopupMenuItem(
                        child: TextButton(
                            style: ButtonStyle(alignment: Alignment.bottomLeft),
                            onPressed: () async {
                              final tablesParcelsOccupied =
                                  await FirebaseFirestore.instance
                                      .collection(widget.hotelName)
                                      .doc('presentorders')
                                      .collection('presentorders')
                                      .get();
                              presentTablesParcelsOccupied = [];
                              Map<String, dynamic>
                                  mapToAddPresentTablesParcels = {};
                              for (var eachTableParcelOccupied
                                  in tablesParcelsOccupied.docs) {
                                mapToAddPresentTablesParcels['addedItemsSet'] =
                                    eachTableParcelOccupied['addedItemsSet'];
                                mapToAddPresentTablesParcels['captainStatus'] =
                                    eachTableParcelOccupied['captainStatus'];
                                mapToAddPresentTablesParcels['chefStatus'] =
                                    eachTableParcelOccupied['chefStatus'];
                                mapToAddPresentTablesParcels[
                                        'partOfTableOrParcel'] =
                                    eachTableParcelOccupied[
                                        'partOfTableOrParcel'];
                                mapToAddPresentTablesParcels[
                                        'partOfTableOrParcelNumber'] =
                                    eachTableParcelOccupied[
                                        'partOfTableOrParcelNumber'];
                                mapToAddPresentTablesParcels[
                                        'presentOccupiedTablesParcelsID'] =
                                    eachTableParcelOccupied.id;

                                if (eachTableParcelOccupied[
                                        'partOfTableOrParcel'] ==
                                    'Table') {
                                  tablesAlreadyOccupied.add(
                                      eachTableParcelOccupied[
                                          'partOfTableOrParcelNumber']);
                                }
                                if (eachTableParcelOccupied[
                                        'partOfTableOrParcel'] ==
                                    'Parcel') {
                                  parcelsAlreadyOccupied.add(
                                      eachTableParcelOccupied[
                                          'partOfTableOrParcelNumber']);
                                }
                                presentTablesParcelsOccupied.insert(
                                    presentTablesParcelsOccupied.length,
                                    mapToAddPresentTablesParcels);
                                mapToAddPresentTablesParcels = {};
                              }

                              Navigator.pop(context);

                              buildMoveTableOrParcelAlertDialogWidget();
                            },
                            child: Text(
                              'Move',
                              style: kMenuBarPopUpMenuButtonTextStyle,
                            )),
                      )
                    ])
          ],
        ),
        body: Column(
          children: [
            pageHasInternet
                ? const SizedBox.shrink()
                : Container(
                    width: double.infinity,
                    color: Colors.red,
                    child: const Center(
                      child: Text('You are Offline',
                          style:
                              TextStyle(color: Colors.white, fontSize: 30.0)),
                    ),
                  ),
            (splitPressed || movePressed)
                ? Expanded(child: Center(child: CircularProgressIndicator()))
                : Expanded(
                    child: StreamBuilder<
                            DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection(widget.hotelName)
                            .doc('presentorders')
                            .collection('presentorders')
                            .doc(widget.itemsFromDoc)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
//IfConnectionStateIsWaiting,ThenWePutTheRotatingCircleThatShowsLoadingInTheCenter
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
                            if (snapshot.data!.data() == null) {
                              print('came inside null');
                              // Navigator.pop(context);
                              // if (parentOrChild == 'parent') {
                              //   Navigator.pop(context);
                              // } else {
                              //   print('did we come inside non parent?');
                              //
                              //   Navigator.pushReplacement(
                              //       context,
                              //       MaterialPageRoute(
                              //           builder: (context) =>
                              //               TableOrParcelSplitTwo(
                              //                 hotelName: widget.hotelName,
                              //                 partOfTableOrParcel:
                              //                     widget.tableOrParcel,
                              //                 partOfTableOrParcelNumber: widget
                              //                     .tableOrParcelNumber
                              //                     .toString(),
                              //                 menuItems: widget.menuItems,
                              //                 menuTitles: widget.menuTitles,
                              //                 menuPrices: widget.menuPrices,
                              //                 cgstPercentage:
                              //                     widget.cgstPercentage,
                              //                 sgstPercentage:
                              //                     widget.sgstPercentage,
                              //                 hotelNameForPrint:
                              //                     widget.hotelNameForPrint,
                              //                 phoneNumberForPrint:
                              //                     widget.phoneNumberForPrint,
                              //                 addressLine1ForPrint:
                              //                     widget.addressLine1ForPrint,
                              //                 addressLine2ForPrint:
                              //                     widget.addressLine2ForPrint,
                              //                 addressLine3ForPrint:
                              //                     widget.addressLine3ForPrint,
                              //               )));
                              //   Navigator.pop(context);
                              // }

                              return const Center(
                                child: Text(
                                  'No Items Inside',
                                  style: TextStyle(fontSize: 30),
                                ),
                              );
                            } else {
                              items = [];
                              localItemsStatus = [];
//RemakingTheEntireListPassedIntoThisPageEachTimeStreamBuilderRebuildsIt
                              widget.itemsID.clear();
                              widget.itemsName.clear();
                              widget.itemsNumber.clear();
                              widget.itemsStatus.clear();
                              widget.itemsEachPrice.clear();

                              Map<String, dynamic> mapToAddIntoItems = {};
                              String eachItemFromEntireItemsString = '';
                              var output = snapshot.data!.data();
                              // if (output == null) {
                              //   Navigator.pop(context);
                              //   // Navigator.pop(context);
                              // }
                              addedItemsSet = output!['addedItemsSet'];
                              chefStatusForSplit = output!['chefStatus'];
                              captainStatusForSplit = output!['captainStatus'];
                              String splitCheck = addedItemsSet;
                              final setSplit = splitCheck.split('*');
                              setSplit.removeLast();
                              String tableorparcel = setSplit[0];
                              num tableorparcelnumber = num.parse(setSplit[1]);
                              num timecustomercametoseat =
                                  num.parse(setSplit[2]);
                              num ticketNumber = num.parse(setSplit[3]);
                              if (setSplit[4] != 'customername') {
                                customername = setSplit[4];
                              }
                              if (setSplit[5] != 'customermobileNumber') {
                                customermobileNumber = setSplit[5];
                              }
                              if (setSplit[6] != 'customeraddressline1') {
                                customeraddressline1 = setSplit[6];
                              }
                              parentOrChild = setSplit[7];

                              for (int i = 0; i < setSplit.length; i++) {
//thisWillEnsureWeSwitchedFromTableInfoToOrderInfo
                                if ((i) > 14) {
                                  if ((i + 1) % 15 == 1) {
                                    mapToAddIntoItems = {};
                                    eachItemFromEntireItemsString = '';
                                    mapToAddIntoItems['tableorparcel'] =
                                        tableorparcel;
                                    mapToAddIntoItems['tableorparcelnumber'] =
                                        tableorparcelnumber;
                                    mapToAddIntoItems[
                                            'timecustomercametoseat'] =
                                        timecustomercametoseat;
                                    widget.itemsID.add(setSplit[i]);
                                    mapToAddIntoItems['eachiteminorderid'] =
                                        setSplit[i];
                                    eachItemFromEntireItemsString +=
                                        '${setSplit[i]}*';
                                  }
                                  if ((i + 1) % 15 == 2) {
                                    widget.itemsName.add(setSplit[i]);
                                    mapToAddIntoItems['item'] = setSplit[i];
                                    eachItemFromEntireItemsString +=
                                        '${setSplit[i]}*';
                                  }
                                  if ((i + 1) % 15 == 3) {
                                    widget.itemsEachPrice
                                        .add(num.parse(setSplit[i]));
                                    mapToAddIntoItems['priceofeach'] =
                                        num.parse(setSplit[i]);
                                    eachItemFromEntireItemsString +=
                                        '${setSplit[i]}*';
                                  }
                                  if ((i + 1) % 15 == 4) {
                                    widget.itemsNumber
                                        .add(int.parse(setSplit[i]));
                                    mapToAddIntoItems['number'] =
                                        num.parse(setSplit[i]);
                                    eachItemFromEntireItemsString +=
                                        '${setSplit[i]}*';
                                  }

                                  if ((i + 1) % 15 == 5) {
                                    mapToAddIntoItems['timeoforder'] =
                                        num.parse(setSplit[i]);
                                    eachItemFromEntireItemsString +=
                                        '${setSplit[i]}*';
                                  }
                                  if ((i + 1) % 15 == 6) {
                                    widget.itemsStatus
                                        .add(int.parse(setSplit[i]));
                                    mapToAddIntoItems['statusoforder'] =
                                        num.parse(setSplit[i]);
                                    localItemsStatus
                                        .add(num.parse(setSplit[i]));
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
                                    mapToAddIntoItems['ticketNumber'] =
                                        setSplit[i];
                                    mapToAddIntoItems['itemBelongsToDoc'] =
                                        widget.itemsFromDoc;
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

                              return Container(
                                  child: SlidableAutoCloseBehavior(
                                closeWhenOpened: true,
                                child: ListView.builder(
                                    itemCount: items.length,
                                    itemBuilder: (context, index) {
//WeGoThroughAllTheItemsAndItemsNumberList
//IDAndStatusIsForActionsWeCanDoWithSlidableInFireStore
                                      final itemName = items[index]['item'];
                                      final itemNumber = items[index]['number'];
                                      final itemID =
                                          items[index]['eachiteminorderid'];
                                      final itemStatus =
                                          items[index]['statusoforder'];
                                      final itemBelongsToDoc =
                                          items[index]['itemBelongsToDoc'];
                                      final entireItemListBeforeSplitting =
                                          items[index]
                                              ['entireItemListBeforeSplitting'];
                                      final eachItemFromEntireItemsString =
                                          items[index]
                                              ['eachItemFromEntireItemsString'];
                                      final commentsForTheItem =
                                          items[index]['commentsForTheItem'];
                                      return Slidable(
//SlidablePackageFromNetHelpsToSlideAndGetOptions
//AmongTheManyAnimationOptionsForSliding,WeChooseScrollMotion
                                          endActionPane: ActionPane(
//StartActionPaneIsForOptionsInLeftSide
                                            motion: const ScrollMotion(),
                                            children: [
                                              SlidableAction(
//IfItemStatusIs11,ItMeansChefHasRejectedTheOrder
//SoWeDeleteItInFireStoreWithFireStoreServices
                                                onPressed:
                                                    (BuildContext context) {
                                                  setState(() {
//                                                     if (itemStatus == 11) {
//                                                       String
//                                                           stringUsedForDeleting =
//                                                           entireItemListBeforeSplitting
//                                                               .replaceAll(
//                                                                   eachItemFromEntireItemsString,
//                                                                   "");
//                                                       print(
//                                                           'stringUsedForDeleting');
//                                                       print(
//                                                           stringUsedForDeleting);
//                                                       final isEveryItemDeletedCheck =
//                                                           stringUsedForDeleting
//                                                               .split('*');
//                                                       if (isEveryItemDeletedCheck
//                                                               .length >
//                                                           18) {
//                                                         final statusUpdatedStringCheck =
//                                                             stringUsedForDeleting
//                                                                 .split('*');
//
// //keepingDefaultAs7-AcceptedStatusWhichNeedNotCreateAnyIssue
//                                                         num chefStatus = 7;
//                                                         num captainStatus = 7;
//
//                                                         for (int j = 1;
//                                                             j <
//                                                                 ((statusUpdatedStringCheck
//                                                                             .length -
//                                                                         1) /
//                                                                     15);
//                                                             j++) {
// //ThisForLoopWillGoThroughEveryOrder,GoExactlyThroughThePointsWhereStatusIsThere
//                                                           if (((statusUpdatedStringCheck[
//                                                                   (j * 15) +
//                                                                       5]) ==
//                                                               '11')) {
//                                                             captainStatus = 11;
//                                                           } else if (((statusUpdatedStringCheck[
//                                                                       (j * 15) +
//                                                                           5]) ==
//                                                                   '10') &&
//                                                               captainStatus !=
//                                                                   11) {
//                                                             captainStatus = 10;
//                                                           }
//                                                           if (((statusUpdatedStringCheck[
//                                                                   (j * 15) +
//                                                                       5]) ==
//                                                               '9')) {
//                                                             chefStatus = 9;
//                                                           }
//                                                         }
//                                                         FireStoreAddOrderServiceWithSplit(
//                                                                 hotelName: widget
//                                                                     .hotelName,
//                                                                 itemsUpdaterString:
//                                                                     stringUsedForDeleting,
//                                                                 captainStatus:
//                                                                     captainStatus,
//                                                                 chefStatus:
//                                                                     chefStatus,
//                                                                 seatingNumber:
//                                                                     itemBelongsToDoc,
//                                                                 partOfTableOrParcel:
//                                                                     widget
//                                                                         .tableOrParcel,
//                                                                 partOfTableOrParcelNumber: widget
//                                                                     .tableOrParcelNumber
//                                                                     .toString())
//                                                             .addOrder();
//                                                         localItemsStatus
//                                                             .removeAt(index);
//                                                         itemsDeliveredOrNotStatusChecker();
//                                                       } else {
//                                                         FireStoreDeleteFinishedOrderInPresentOrders(
//                                                                 hotelName: widget
//                                                                     .hotelName,
//                                                                 eachItemId:
//                                                                     itemBelongsToDoc)
//                                                             .deleteFinishedOrder();
//                                                         Navigator.pop(context);
//                                                         localItemsStatus
//                                                             .removeAt(index);
//                                                         itemsDeliveredOrNotStatusChecker();
//                                                         localItemsStatus
//                                                             .removeAt(index);
//                                                         itemsDeliveredOrNotStatusChecker();
//                                                       }
//                                                     } else
                                                    if (itemStatus != 3) {
//IfStatusIsNot3,itMeansTheItemHasNotYetBeenPickedUpByTheWaiter
//WeGiveHimTheOptionToClickPickedUpByUpdatingStatusTo3

                                                      final eachItemFromEntireItemsStringSplit =
                                                          eachItemFromEntireItemsString
                                                              .split('*');
                                                      eachItemFromEntireItemsStringSplit[
                                                          5] = '3';

                                                      String
                                                          tempStatusUpdaterString =
                                                          '';
                                                      for (int i = 0;
                                                          i <
                                                              eachItemFromEntireItemsStringSplit
                                                                      .length -
                                                                  1;
                                                          i++) {
                                                        tempStatusUpdaterString +=
                                                            '${eachItemFromEntireItemsStringSplit[i]}*';
                                                      }

                                                      String
                                                          stringUsedForUpdatingStatus =
                                                          entireItemListBeforeSplitting
                                                              .replaceAll(
                                                                  eachItemFromEntireItemsString,
                                                                  tempStatusUpdaterString);

                                                      final statusUpdatedStringCheck =
                                                          stringUsedForUpdatingStatus
                                                              .split('*');

//keepingDefaultAs7-AcceptedStatusWhichNeedNotCreateAnyIssue
                                                      num chefStatus = 7;
                                                      num captainStatus = 7;

                                                      for (int j = 1;
                                                          j <
                                                              ((statusUpdatedStringCheck
                                                                          .length -
                                                                      1) /
                                                                  15);
                                                          j++) {
//ThisForLoopWillGoThroughEveryOrder,GoExactlyThroughThePointsWhereStatusIsThere
                                                        if (((statusUpdatedStringCheck[
                                                                (j * 15) +
                                                                    5]) ==
                                                            '11')) {
                                                          captainStatus = 11;
                                                        } else if (((statusUpdatedStringCheck[
                                                                    (j * 15) +
                                                                        5]) ==
                                                                '10') &&
                                                            captainStatus !=
                                                                11) {
                                                          captainStatus = 10;
                                                        }
                                                        if (((statusUpdatedStringCheck[
                                                                (j * 15) +
                                                                    5]) ==
                                                            '9')) {
                                                          chefStatus = 9;
                                                        }
                                                      }

                                                      FireStoreAddOrderServiceWithSplit(
                                                              hotelName: widget
                                                                  .hotelName,
                                                              itemsUpdaterString:
                                                                  stringUsedForUpdatingStatus,
                                                              captainStatus:
                                                                  captainStatus,
                                                              chefStatus:
                                                                  chefStatus,
                                                              seatingNumber:
                                                                  itemBelongsToDoc,
                                                              partOfTableOrParcel:
                                                                  widget
                                                                      .tableOrParcel,
                                                              partOfTableOrParcelNumber:
                                                                  widget
                                                                      .tableOrParcelNumber
                                                                      .toString())
                                                          .addOrder();
                                                      localItemsStatus[index] =
                                                          3;
                                                      itemsDeliveredOrNotStatusChecker();
                                                    }
                                                  });
                                                },
//WeKeepBackgroundColorOfSlidableOptionAsPerStatus,
//ifStatus11(Rejected)-Red,If3(Delivered)-DarkGreen,Else-LightGreen
                                                backgroundColor: itemStatus ==
                                                        11
                                                    ? Colors.white
                                                    : itemStatus == 3
                                                        ? Colors.green.shade900
                                                        : Colors.green.shade500,
//iconAsPerStatus,11(Rejected)-deleteIcon,
//if3(AlreadyDelivered)-DoubleTick
//Else(DeliveredNow)-SingleTick
                                                icon: itemStatus == 11
                                                    ? null
                                                    : itemStatus == 3
                                                        ? const IconData(0xefe5,
                                                            fontFamily:
                                                                'MaterialIcons')
                                                        : const IconData(0xe1f8,
                                                            fontFamily:
                                                                'MaterialIcons'),
//labelAsPerStatus,11(Rejected)-delete,
//if3(AlreadyDelivered)-Already Delivered
//Else(DeliveredNow)-Delivered
                                                label: itemStatus == 11
                                                    ? ' '
                                                    : itemStatus == 3
                                                        ? 'Already Delivered'
                                                        : 'Delivered',
                                              ),
                                            ],
                                          ),
//EndActionPaneIsForRightSideSlidableOptions
                                          startActionPane: ActionPane(
                                            motion: const ScrollMotion(),
                                            children: [
                                              SlidableAction(
//ifStatusNotEqualTo3(MeansNotAlreadyDelivered),WeAlwaysGiveHereDeleteOption
//SoWaiterCanDeleteItAnyTimeInCaseTheCustomerSaysTheyDon'tWant
//WeRemoveItOutOfTheListsToo
                                                  onPressed:
                                                      (BuildContext context) {
                                                    setState(() {
                                                      // if (itemStatus == 3 ||
                                                      //     itemStatus == 9 ||
                                                      //     itemStatus == 11
                                                      // ) {
//IfItemIsAccepted/Ready-WeNeedToIntimateTheChef

                                                      if (itemStatus == 7 ||
                                                          itemStatus == 10) {
                                                        String
                                                            idToSaveInsideDeleteMap =
                                                            '';
                                                        String
                                                            deleteStringToBeSavedInServer =
                                                            '';
                                                        final splittingEachItemForUpdatingDelete =
                                                            eachItemFromEntireItemsString
                                                                .toString()
                                                                .split('*');
                                                        idToSaveInsideDeleteMap =
                                                            splittingEachItemForUpdatingDelete[
                                                                    0]
                                                                .toString();
                                                        splittingEachItemForUpdatingDelete[
                                                            5] = "9";
                                                        splittingEachItemForUpdatingDelete[
                                                                7] =
                                                            "chefkotnotyet";
                                                        splittingEachItemForUpdatingDelete[
                                                                9] =
                                                            widget
                                                                .tableOrParcel;
                                                        splittingEachItemForUpdatingDelete[
                                                                10] =
                                                            widget
                                                                .tableOrParcelNumber
                                                                .toString();
                                                        splittingEachItemForUpdatingDelete[
                                                            11] = parentOrChild;
//ToFindWhetherTheItemHasBeenDeletedFromReadyOrAccepted
                                                        splittingEachItemForUpdatingDelete[
                                                            12] = itemStatus ==
                                                                10
                                                            ? 'readyToDelete'
                                                            : 'acceptedToDelete';
                                                        for (int i = 0;
                                                            i <
                                                                splittingEachItemForUpdatingDelete
                                                                        .length -
                                                                    1;
                                                            i++) {
                                                          deleteStringToBeSavedInServer +=
                                                              '${splittingEachItemForUpdatingDelete[i].toString()}*';
                                                        }
                                                        FireStoreAddItemToCancelledList(
                                                                hotelName: widget
                                                                    .hotelName,
                                                                deletedKey:
                                                                    idToSaveInsideDeleteMap,
                                                                deletedValue:
                                                                    deleteStringToBeSavedInServer)
                                                            .addCancelledOrder();
                                                      }

                                                      String
                                                          stringUsedForDeleting =
                                                          entireItemListBeforeSplitting
                                                              .replaceAll(
                                                                  eachItemFromEntireItemsString,
                                                                  "");
                                                      print(
                                                          'stringForDeleting');
                                                      print(
                                                          stringUsedForDeleting);
                                                      final isEveryItemDeletedCheck =
                                                          stringUsedForDeleting
                                                              .split('*');
                                                      if (isEveryItemDeletedCheck
                                                              .length >
                                                          18) {
                                                        final statusUpdatedStringCheck =
                                                            stringUsedForDeleting
                                                                .split('*');

//keepingDefaultAs7-AcceptedStatusWhichNeedNotCreateAnyIssue
                                                        num chefStatus = 7;
                                                        num captainStatus = 7;

                                                        for (int j = 1;
                                                            j <
                                                                ((statusUpdatedStringCheck
                                                                            .length -
                                                                        1) /
                                                                    15);
                                                            j++) {
//ThisForLoopWillGoThroughEveryOrder,GoExactlyThroughThePointsWhereStatusIsThere
                                                          if (((statusUpdatedStringCheck[
                                                                  (j * 15) +
                                                                      5]) ==
                                                              '11')) {
                                                            captainStatus = 11;
                                                          } else if (((statusUpdatedStringCheck[
                                                                      (j * 15) +
                                                                          5]) ==
                                                                  '10') &&
                                                              captainStatus !=
                                                                  11) {
                                                            captainStatus = 10;
                                                          }
                                                          if (((statusUpdatedStringCheck[
                                                                  (j * 15) +
                                                                      5]) ==
                                                              '9')) {
                                                            chefStatus = 9;
                                                          }
                                                        }
                                                        FireStoreAddOrderServiceWithSplit(
                                                                hotelName: widget
                                                                    .hotelName,
                                                                itemsUpdaterString:
                                                                    stringUsedForDeleting,
                                                                captainStatus:
                                                                    captainStatus,
                                                                chefStatus:
                                                                    chefStatus,
                                                                seatingNumber:
                                                                    itemBelongsToDoc,
                                                                partOfTableOrParcel:
                                                                    widget
                                                                        .tableOrParcel,
                                                                partOfTableOrParcelNumber: widget
                                                                    .tableOrParcelNumber
                                                                    .toString())
                                                            .addOrder();
                                                        localItemsStatus
                                                            .removeAt(index);
                                                        itemsDeliveredOrNotStatusChecker();
                                                      } else {
                                                        FireStoreDeleteFinishedOrderInPresentOrders(
                                                                hotelName: widget
                                                                    .hotelName,
                                                                eachItemId:
                                                                    itemBelongsToDoc)
                                                            .deleteFinishedOrder();
                                                        localItemsStatus
                                                            .removeAt(index);
                                                        itemsDeliveredOrNotStatusChecker();
                                                        // widget.itemsName
                                                        //     .removeAt(index);
                                                        // widget.itemsNumber
                                                        //     .removeAt(index);
                                                        // widget.itemsID
                                                        //     .removeAt(index);
                                                        // widget.itemsStatus
                                                        //     .removeAt(index);
                                                        // widget.itemsBelongsToDoc
                                                        //     .removeAt(index);
                                                        // widget
                                                        //     .entireItemsListBeforeSplitting
                                                        //     .removeAt(index);
                                                        // widget
                                                        //     .eachItemsFromEntireItemsString
                                                        //     .removeAt(index);
                                                        Navigator.pop(context);
                                                      }
                                                    });
                                                  },
//IfAlreadyDelivered(Status 3)-GreenColor,Else-Red
                                                  backgroundColor:
                                                      Colors.red.shade500,
//IfAlreadyDelivered(Status 3)-DoubleTick,Else-DeleteIcon
                                                  icon: Icons.close,
//IfAlreadyDelivered(Status 3)-Already Delivered,Else-Delete as label
                                                  label: 'Cancel'),
                                            ],
                                          ),
                                          child: Container(
//thisContainerWillHaveTheListTile,WithBorderRadius
                                            //margin: EdgeInsets.fromLTRB(5, 5, 5, 5),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                              border: Border.all(
                                                color: Colors.black87,
                                                width: 1.0,
                                              ),
//ContainerColor-Status11(Rejected)-Red,10(ReadyWithChef)-Green,
//3-AlreadyDelivered-LightBlue
                                              color: itemStatus == 11
                                                  ? Colors.red
                                                  : itemStatus == 10
                                                      ? Colors.green
                                                      : itemStatus == 7
                                                          ? Colors.orangeAccent
                                                          : itemStatus == 3
                                                              ? Colors
                                                                  .lightBlueAccent
                                                              : null,
                                            ),
                                            child: ListTile(
//ListTileWillHaveItemNameInLeftAndNumberInRight
                                              title: Text(itemName,
                                                  style: TextStyle(
                                                      fontSize: 28.0)),
                                              trailing: Text(
                                                  itemNumber.toString(),
                                                  style: TextStyle(
                                                      fontSize: 28.0)),
                                              subtitle: commentsForTheItem ==
                                                      'nocomments'
                                                  ? null
                                                  : Text(
                                                      commentsForTheItem,
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: Colors.black),
                                                    ),
                                            ),
                                          ));
                                    }),
                              ));
                            }
                          } else {
                            return CircularProgressIndicator();
                          }
                        }))
          ],
        ),

//inDownRight,WeHaveFloatingActionButton,
//ThisWillBeContainerAndWillBeInRoundShape
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 75.0,
              height: 75.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                // border: Border.all(
                //   color: Colors.black87,
                //   width: 0.2,
                // )
              ),
              child: MaterialButton(
                color: Colors.white70,
                onPressed: () {
                  _controller =
                      TextEditingController(text: customermobileNumber);
                  showModalBottomSheet(
                      isScrollControlled: true,
                      context: context,
                      builder: (context) {
                        return buildUserInfoWidget();
                      });
                },
                shape: CircleBorder(

                    // side: BorderSide(
                    //     // width: 2,
                    //     // color: Colors.red,
                    //     // style: BorderStyle.solid,
                    //     )
                    ),
                child: const Icon(
                  IconData(0xe043, fontFamily: 'MaterialIcons'),
                  size: 35,
                ),
              ),
            ),
            SizedBox(height: 10),
            Container(
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
                child: const Text(
                  'Menu',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.w900),
                ),
                onPressed: () {
//onPressedWeAlreadyHaveAllTheBelowInputsAsThisScreenWasCalled
//WeGiveUnavailableItemsToEnsureWeDon'tShowItAndItemsAddedMap
//WillHaveTheItemNameAsKeyAndTheNumberAsValue
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MenuPageWithSplit(
                        hotelName: widget.hotelName,
                        tableOrParcel: widget.tableOrParcel,
                        tableOrParcelNumber: widget.tableOrParcelNumber,
                        parentOrChild: parentOrChild,
                        menuItems: widget.menuItems,
                        menuPrices: widget.menuPrices,
                        menuTitles: widget.menuTitles,
                        itemsAddedMapCalled: {},
                        itemsAddedCommentCalled: {},
                        addedItemsSet: addedItemsSet,
                        unavailableItems: [],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        persistentFooterButtons: [
//InPersistentFooterButton,WeGiveTheWaiterTheOptionToGoForTheBill
          BottomButton(
              buttonWidth: double.infinity,
              buttonColor: allItemsDeliveredToCustomerTrueElseFalse
                  ? kBottomContainerColour
                  : Colors.grey,
              onTap: () {
//OnlyIfAllItemAreDelivered,WeGoForwardWithPrint
                if (allItemsDeliveredToCustomerTrueElseFalse) {
//WeWantListWhereDuplicateItemsAreRemoved,WeUse toSetWithToListToGetDistinctItems
//Initially,WeWillHaveTheOtherListsEmpty
                  List<String> distinctItems =
                      widget.itemsName.toSet().toList();
                  List<num> priceOfEachDistinctItem = [];
                  List<num> priceOfEachDistinctItemWithoutTotal = [];
                  List<num> individualPriceOfEachDistinctItem = [];
                  List<int> numberOfEachDistinctItem = [];
                  List<String> completeItemListToPrint = [];
                  Map<String, String> printOrdersMap = HashMap();
                  Map<String, num> statisticsMap = HashMap();
//WeGetTheDateReadyUsingThisInherentFlutterMethod
                  DateTime now = DateTime.now();
//WeEnsureWeTakeTheMonth,Day,Hour,MinuteAsString
//ifItIsLessThan10,WeSaveItWithZeroInTheFront
//ThisWillEnsure,ItIsAlwaysIn2Digits,AndWithoutPuttingItInTwoDigits,,
//ItWon'tComeInAscendingOrder
                  String tempMonth = now.month < 10
                      ? '0${now.month.toString()}'
                      : '${now.month.toString()}';
                  String tempDay = now.day < 10
                      ? '0${now.day.toString()}'
                      : '${now.day.toString()}';
                  String tempHour = now.hour < 10
                      ? '0${now.hour.toString()}'
                      : '${now.hour.toString()}';
                  String tempMinute = now.minute < 10
                      ? '0${now.minute.toString()}'
                      : '${now.minute.toString()}';
                  String tempSecond = now.second < 10
                      ? '0${now.second.toString()}'
                      : '${now.second.toString()}';
//InThePrintOrdersMap(HashMap),FirstWeSaveKeyAs "DateOfOrder"&ValueAs,,
//year/Month/Day At Hour:Minute
                  printOrdersMap.addAll({
                    ' Date of Order  :':
                        '${now.year.toString()}/$tempMonth/$tempDay at $tempHour:$tempMinute'
                  });
//IfItIsParcel,WeAddParcelNumbers1&TotalNumberOfOrdersAdd1InStatisticsMap
                  if (widget.tableOrParcel == 'Parcel') {
                    statisticsMap.addAll({'numberofparcel': 1});
                    statisticsMap.addAll({'totalnumberoforders': 1});
                  } else {
//ElseIfItIsTable,WeAddParcelNumbers0&TotalNumberOfOrdersAdd1InStatisticsMap
                    statisticsMap.addAll({'numberofparcel': 0});
                    statisticsMap.addAll({'totalnumberoforders': 1});
                  }

//WeGoThroughEachItemInDistinctItemsList
                  for (String distinctItem in distinctItems) {
                    int numberOfItems = 0;
                    num priceOfEachItem = 0;
//WeHaveAnotherForLoop,AndInsideWeCheckEachItemAndIfTwoItemsAreSame,,
//AndWeSimplyAddTheNumbers
//SinceTheDistinctItemsHaveNoDuplicates,WeCouldGetTheNumber
//AndPriceOfEachItemIsNoted
                    for (int i = 0; i < widget.itemsName.length; i++) {
                      if (distinctItem == widget.itemsName[i]) {
                        numberOfItems = numberOfItems + widget.itemsNumber[i];
                        priceOfEachItem = widget.itemsEachPrice[i];
                      }
                    }
//AfterTheForLoop,InPriceOfEachDistinctItemxNumberOfItemsToGetThePrice
                    individualPriceOfEachDistinctItem.add(priceOfEachItem);
                    priceOfEachDistinctItem
                        .add(priceOfEachItem * numberOfItems);
//InStatisticsMapWeAdd key-item,value-NumberOfItems
                    numberOfEachDistinctItem.add(numberOfItems);
                    statisticsMap.addAll({distinctItem: numberOfItems});
                  }
//TOGoForTheBillWeLoop
//CompleteItemListToPrint,WePutItLike- ItemNamexNumber =
                  for (int i = 0; i < distinctItems.length; i++) {
                    completeItemListToPrint.add(
                        '${distinctItems[i]}*${individualPriceOfEachDistinctItem[i]} * ${numberOfEachDistinctItem[i]} = ');
//IfNumberLessThan9,InOrderToGetOrderRight,WePut '0'BehindNumber
//WePrintItLike 01.idlyx5 = 50 02.Chapthix3 = 60
                    if (i < 9) {
                      printOrdersMap.addAll({
                        '0${i + 1} . ${distinctItems[i]} x ${individualPriceOfEachDistinctItem[i]} x ${numberOfEachDistinctItem[i]} = ':
                            (priceOfEachDistinctItem[i]).toString()
                      });
                    } else {
//ifNumberMoreThan9,WeDon'tNeedTheAdditionOf 0 at First
                      printOrdersMap.addAll({
                        '${i + 1} . ${distinctItems[i]} x ${individualPriceOfEachDistinctItem[i]} x  ${numberOfEachDistinctItem[i]} = ':
                            (priceOfEachDistinctItem[i]).toString()
                      });
                    }
                  }
//ThisWillEnsureIHaveListWithoutTotallingTheFinalSum
                  priceOfEachDistinctItemWithoutTotal = priceOfEachDistinctItem;
//ifItIsTable WeSimplyAddEveryPriceWith reduce(a,b) to a+b
//ThisIsHowWeGetSum
                  if (widget.tableOrParcel == 'Table') {
                    completeItemListToPrint.add('Total = ');
                    printOrdersMap.addAll({
                      'Total = ': (priceOfEachDistinctItem
                          .reduce((a, b) => a + b)).toString()
                    });
//InStatisticsMapWeAddThePriceSumTo TotalBillAmountToday
                    statisticsMap.addAll({
                      'totalbillamounttoday':
                          priceOfEachDistinctItem.reduce((a, b) => a + b)
                    });
//CalculatingCGST&SGSTHereWithPercentageDownloadedFromDatabase
                    cgstCalculated = (statisticsMap['totalbillamounttoday']! *
                            (widget.cgstPercentage / 100))
                        .roundToDouble();
                    sgstCalculated = (statisticsMap['totalbillamounttoday']! *
                            (widget.sgstPercentage / 100))
                        .roundToDouble();
//WeCalculateTheEntireAmountWithTheTaxes
                    totalBillWithTaxes = cgstCalculated +
                        sgstCalculated +
                        statisticsMap['totalbillamounttoday']!;

//ToSaveTheEntireSumInPriceOfEachDistinctItem,WeAddAllTheSumAnd
//SaveItInPriceOfEachDistinctItemItself
                    priceOfEachDistinctItem
                        .add(priceOfEachDistinctItem.reduce((a, b) => a + b));
                    printOrdersMap.addAll({
                      'Total Bill With Taxes': totalBillWithTaxes.toString()
                    });
                  } else {
                    //ThisMeansItIsParcel
                    //WeDoTheSameThingsAsWeHadDoneForTheTable
                    //InCase,WeNeedSomeChangeForParcelInTheFuture,ThisLoopCanBeUsed
                    completeItemListToPrint.add('Total = ');
                    printOrdersMap.addAll({
                      'Total = ': ((priceOfEachDistinctItem
                          .reduce((a, b) => a + b)).toString())
                    });
                    statisticsMap.addAll({
                      'totalbillamounttoday':
                          priceOfEachDistinctItem.reduce((a, b) => a + b)
                    });
//CalculatingCGST&SGSTHereWithPercentageDownloadedFromDatabase
                    cgstCalculated = (statisticsMap['totalbillamounttoday']! *
                            (widget.cgstPercentage / 100))
                        .roundToDouble();
                    sgstCalculated = (statisticsMap['totalbillamounttoday']! *
                            (widget.sgstPercentage / 100))
                        .roundToDouble();
//TotalTaxesCalculatedHere
                    totalBillWithTaxes = cgstCalculated +
                        sgstCalculated +
                        statisticsMap['totalbillamounttoday']!;
                    priceOfEachDistinctItem
                        .add(priceOfEachDistinctItem.reduce((a, b) => a + b));
                    printOrdersMap.addAll({
                      'Total Bill With Taxes': totalBillWithTaxes.toString()
                    });
                  }
//WeHaveTodayMonthAndDateReadyWithAnAdditionOfZeroIfIt'sLessThan10
                  String todayMonth = now.month < 10
                      ? '0${now.month.toString()}'
                      : now.month.toString();
                  String today = now.day < 10
                      ? '0${now.day.toString()}'
                      : now.day.toString();

                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => BillPrintWithSerialNumber(
                                hotelName: widget.hotelName,
                                addedItemsSet: addedItemsSet,
                                itemsID: widget.itemsID,
                                itemsFromThisDocumentInFirebaseDoc:
                                    widget.itemsFromDoc,
                                cgstPercentage: widget.cgstPercentage,
                                sgstPercentage: widget.sgstPercentage,
                                hotelNameForPrint: widget.hotelNameForPrint,
                                addressLine1ForPrint:
                                    widget.addressLine1ForPrint,
                                addressLine2ForPrint:
                                    widget.addressLine2ForPrint,
                                addressLine3ForPrint:
                                    widget.addressLine3ForPrint,
                                phoneNumberForPrint: widget.phoneNumberForPrint,
                                gstCodeForPrint: widget.gstCodeForPrint,
                              )));

//WeGiveThePrintOrdersMap,navigatingToPrintScreen,WhereItWillBeDisplayedAsBill
//                 Navigator.pushReplacement(
//                     context,
//                     MaterialPageRoute(
//                         builder: (context) => FinalBillScreen(
//                               eachOrderMap: printOrdersMap,
//                             )));
                }
              },
//ButtonTitleWillBePrint
              buttonTitle: 'Confirm Bill')
        ],
      ),
    );
  }
}
