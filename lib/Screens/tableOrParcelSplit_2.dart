import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_alt/modal_progress_hud_alt.dart';
import 'package:orders_dev/Screens/menu_page_add_items_3.dart';
import 'package:orders_dev/constants.dart';
import 'package:orders_dev/Methods/split_button.dart';

import 'items_each_order_5.dart';

class TableOrParcelSplitTwo extends StatefulWidget {
  final String hotelName;
  final String partOfTableOrParcel;
  final String partOfTableOrParcelNumber;
  final List<String> menuItems;
  final List<num> menuPrices;
  final List<String> menuTitles;
  final num cgstPercentage;
  final num sgstPercentage;
  final String hotelNameForPrint;
  final String addressLine1ForPrint;
  final String addressLine2ForPrint;
  final String addressLine3ForPrint;
  final String phoneNumberForPrint;
  final num numberOfTables;
  final String gstCodeForPrint;

  const TableOrParcelSplitTwo(
      {Key? key,
      required this.hotelName,
      required this.partOfTableOrParcel,
      required this.partOfTableOrParcelNumber,
      required this.menuItems,
      required this.menuPrices,
      required this.menuTitles,
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
  State<TableOrParcelSplitTwo> createState() => _TableOrParcelSplitTwoState();
}

class _TableOrParcelSplitTwoState extends State<TableOrParcelSplitTwo> {
  bool showSpinner = false;
  List<Map<String, dynamic>> items = [];
  List<String> distinctTablesParcels = [];
  Map<String, num> distinctTablesParcelsColorStatus = HashMap();
  num newButtonNeeded = 0;
  bool tableButtonPressed = false;

  @override
  Widget build(BuildContext context) {
    Widget tableOrParcelButtonWithItemsOrdered(int distinctItemNumber) {
      return SplitButton(
          textColor: Colors.black,
          backgroundColor: distinctTablesParcelsColorStatus[
                      distinctTablesParcels[distinctItemNumber]] ==
                  11
              ? Colors.red
              : distinctTablesParcelsColorStatus[
                          distinctTablesParcels[distinctItemNumber]] ==
                      10
                  ? Colors.green
                  : distinctTablesParcelsColorStatus[
                              distinctTablesParcels[distinctItemNumber]] ==
                          7
                      ? Colors.orangeAccent
                      : distinctTablesParcelsColorStatus[
                                  distinctTablesParcels[distinctItemNumber]] ==
                              9
                          ? Colors.white
                          : distinctTablesParcelsColorStatus[
                                      distinctTablesParcels[
                                          distinctItemNumber]] ==
                                  3
                              ? Colors.lightBlueAccent
                              : Colors.brown.shade100,
          borderColor: Colors.black,
          tableOrParcel:
              '${widget.partOfTableOrParcelNumber}${distinctTablesParcels[distinctItemNumber]}',
          size: 40.0,
          onPress: () {
            tableButtonPressed = true;
            if (tableButtonPressed) {}
            setState(() {
              showSpinner = true;
            });
            List<String> itemsID = [];
            List<String> itemsName = [];
            List<int> itemsNumber = [];
            List<int> itemsStatus = [];
            List<num> itemsEachPrice = [];
            List<String> itemsBelongsToDoc = [];
            List<String> entireItemsListBeforeSplitting = [];
            List<String> eachItemsFromEntireItemsString = [];
            for (var item in items) {
//ForEachItemInItems,WeAddItemsId,Number,Status&Price
              if (item['parentOrChild'] ==
                  distinctTablesParcels[distinctItemNumber]) {
                itemsID.add(item['eachiteminorderid']);
                itemsName.add(item['item']);
                itemsNumber.add(item['number']);
                itemsStatus.add(item['statusoforder']);
                itemsEachPrice.add(item['priceofeach']);
                itemsBelongsToDoc.add(item['itemBelongsToDoc']);
                entireItemsListBeforeSplitting
                    .add(item['entireItemListBeforeSplitting']);
                eachItemsFromEntireItemsString
                    .add(item['eachItemFromEntireItemsString']);
              }
            }
            // WeGoToItemsEachTableScreenWithItemsId,Name,Number,Status,Price
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ItemsInEachOrderWithDeleteTillEnd(
                          hotelName: widget.hotelName,
                          menuItems: widget.menuItems,
                          menuTitles: widget.menuTitles,
                          menuPrices: widget.menuPrices,
                          itemsID: itemsID,
                          itemsName: itemsName,
                          itemsNumber: itemsNumber,
                          itemsStatus: itemsStatus,
                          itemsEachPrice: itemsEachPrice,
                          itemsBelongsToDoc: itemsBelongsToDoc,
                          itemsFromDoc: itemsBelongsToDoc[0],
                          entireItemsListBeforeSplitting:
                              entireItemsListBeforeSplitting,
                          eachItemsFromEntireItemsString:
                              eachItemsFromEntireItemsString,
                          tableOrParcel: widget.partOfTableOrParcel,
                          tableOrParcelNumber:
                              num.parse(widget.partOfTableOrParcelNumber),
                          cgstPercentage: widget.cgstPercentage,
                          sgstPercentage: widget.sgstPercentage,
                          hotelNameForPrint: widget.hotelNameForPrint,
                          phoneNumberForPrint: widget.phoneNumberForPrint,
                          addressLine1ForPrint: widget.addressLine1ForPrint,
                          addressLine2ForPrint: widget.addressLine2ForPrint,
                          addressLine3ForPrint: widget.addressLine3ForPrint,
                          numberOfTables: widget.numberOfTables,
                          gstCodeForPrint: widget.gstCodeForPrint,
                        )));
            setState(() {
              showSpinner = false;
            });
          });
    }

    Widget emptyTableOrParcelRequestButton() {
      return SplitButton(
          textColor: Colors.black,
          backgroundColor: widget.partOfTableOrParcel == 'Parcel'
              ? Colors.blueGrey
              : Colors.brown.shade100,
          borderColor: Colors.black,
          tableOrParcel: distinctTablesParcels.length == 0
              ? '${widget.partOfTableOrParcelNumber}A'
              : '${widget.partOfTableOrParcelNumber}${String.fromCharCode(((distinctTablesParcels.last).codeUnitAt(0)) + 1)}',
          size: 40.0,
          onPress: () {
            setState(() {
              showSpinner = true;
            });
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => MenuPageWithSplit(
                          hotelName: widget.hotelName,
                          tableOrParcel: widget.partOfTableOrParcel,
                          tableOrParcelNumber:
                              num.parse(widget.partOfTableOrParcelNumber),
                          menuItems: widget.menuItems,
                          menuPrices: widget.menuPrices,
                          menuTitles: widget.menuTitles,
                          itemsAddedMapCalled: {},
                          itemsAddedCommentCalled: {},
                          unavailableItems: [],
                          addedItemsSet: '',
                          parentOrChild: distinctTablesParcels.length == 0
                              ? 'A'
                              : '${String.fromCharCode(((distinctTablesParcels.last).codeUnitAt(0)) + 1)}',
//ThisWillEnsureNewTableWithAlphabetNextToTheLastAlphabetIsMade
                        )));

            setState(() {
              newButtonNeeded = 0;
              showSpinner = false;
            });
          });
    }

    Widget splitPageButtons() {
      return SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            Row(
              mainAxisAlignment:
                  (newButtonNeeded == 2 || distinctTablesParcels.length > 1)
                      ? MainAxisAlignment.spaceEvenly
                      : MainAxisAlignment.center,
              children: [
                distinctTablesParcels.length > 0
                    ? tableOrParcelButtonWithItemsOrdered(0)
                    : (distinctTablesParcels.isEmpty && newButtonNeeded == 1)
                        ? emptyTableOrParcelRequestButton()
                        : SizedBox.shrink(),
                distinctTablesParcels.length > 1
                    ? tableOrParcelButtonWithItemsOrdered(1)
                    : (distinctTablesParcels.length == 1 &&
                            newButtonNeeded == 2)
                        ? emptyTableOrParcelRequestButton()
                        : SizedBox.shrink(),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment:
                  (newButtonNeeded == 4 || distinctTablesParcels.length > 3)
                      ? MainAxisAlignment.spaceEvenly
                      : MainAxisAlignment.center,
              children: [
                distinctTablesParcels.length > 2
                    ? tableOrParcelButtonWithItemsOrdered(2)
                    : (distinctTablesParcels.length == 2 &&
                            newButtonNeeded == 3)
                        ? emptyTableOrParcelRequestButton()
                        : SizedBox.shrink(),
                distinctTablesParcels.length > 3
                    ? tableOrParcelButtonWithItemsOrdered(3)
                    : (distinctTablesParcels.length == 3 &&
                            newButtonNeeded == 4)
                        ? emptyTableOrParcelRequestButton()
                        : SizedBox.shrink()
                // SizedBox(width: 80 * 1.8)
                ,
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment:
                  (newButtonNeeded == 6 || distinctTablesParcels.length > 5)
                      ? MainAxisAlignment.spaceEvenly
                      : MainAxisAlignment.center,
              children: [
                distinctTablesParcels.length > 4
                    ? tableOrParcelButtonWithItemsOrdered(4)
                    : (distinctTablesParcels.length == 4 &&
                            newButtonNeeded == 5)
                        ? emptyTableOrParcelRequestButton()
                        : SizedBox.shrink(),
                distinctTablesParcels.length > 5
                    ? tableOrParcelButtonWithItemsOrdered(5)
                    : (distinctTablesParcels.length == 5 &&
                            newButtonNeeded == 6)
                        ? emptyTableOrParcelRequestButton()
                        : SizedBox.shrink(),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment:
                  (newButtonNeeded == 8 || distinctTablesParcels.length > 7)
                      ? MainAxisAlignment.spaceEvenly
                      : MainAxisAlignment.center,
              children: [
                distinctTablesParcels.length > 6
                    ? tableOrParcelButtonWithItemsOrdered(6)
                    : (distinctTablesParcels.length == 6 &&
                            newButtonNeeded == 7)
                        ? emptyTableOrParcelRequestButton()
                        : SizedBox.shrink(),
                distinctTablesParcels.length > 7
                    ? tableOrParcelButtonWithItemsOrdered(7)
                    : (distinctTablesParcels.length == 7 &&
                            newButtonNeeded == 8)
                        ? emptyTableOrParcelRequestButton()
                        : SizedBox.shrink(),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment:
                  (newButtonNeeded == 10 || distinctTablesParcels.length > 9)
                      ? MainAxisAlignment.spaceEvenly
                      : MainAxisAlignment.center,
              children: [
                distinctTablesParcels.length > 8
                    ? tableOrParcelButtonWithItemsOrdered(8)
                    : (distinctTablesParcels.length == 8 &&
                            newButtonNeeded == 9)
                        ? emptyTableOrParcelRequestButton()
                        : SizedBox.shrink(),
                distinctTablesParcels.length > 9
                    ? tableOrParcelButtonWithItemsOrdered(9)
                    : (distinctTablesParcels.length == 9 &&
                            newButtonNeeded == 10)
                        ? emptyTableOrParcelRequestButton()
                        : SizedBox.shrink(),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment:
                  (newButtonNeeded == 12 || distinctTablesParcels.length > 11)
                      ? MainAxisAlignment.spaceEvenly
                      : MainAxisAlignment.center,
              children: [
                distinctTablesParcels.length > 10
                    ? tableOrParcelButtonWithItemsOrdered(10)
                    : (distinctTablesParcels.length == 10 &&
                            newButtonNeeded == 11)
                        ? emptyTableOrParcelRequestButton()
                        : SizedBox.shrink(),
                distinctTablesParcels.length > 11
                    ? tableOrParcelButtonWithItemsOrdered(11)
                    : (distinctTablesParcels.length == 11 &&
                            newButtonNeeded == 12)
                        ? emptyTableOrParcelRequestButton()
                        : SizedBox.shrink(),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment:
                  (newButtonNeeded == 14 || distinctTablesParcels.length > 13)
                      ? MainAxisAlignment.spaceEvenly
                      : MainAxisAlignment.center,
              children: [
                distinctTablesParcels.length > 12
                    ? tableOrParcelButtonWithItemsOrdered(12)
                    : (distinctTablesParcels.length == 12 &&
                            newButtonNeeded == 13)
                        ? emptyTableOrParcelRequestButton()
                        : SizedBox.shrink(),
                distinctTablesParcels.length > 13
                    ? tableOrParcelButtonWithItemsOrdered(13)
                    : (distinctTablesParcels.length == 13 &&
                            newButtonNeeded == 14)
                        ? emptyTableOrParcelRequestButton()
                        : SizedBox.shrink(),
              ],
            ),
          ],
        ),
      );
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

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kAppBarBackgroundColor,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back, color: kAppBarBackIconColor)),
        title: Text(
          '${widget.partOfTableOrParcel}:${widget.partOfTableOrParcelNumber}',
          style: kAppBarTextStyle,
        ),
        centerTitle: true,
      ),
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection(widget.hotelName)
                      .doc('presentorders')
                      .collection('presentorders')
                      .where('partOfTableOrParcel',
                          isEqualTo: widget.partOfTableOrParcel)
                      .where('partOfTableOrParcelNumber',
                          isEqualTo: widget.partOfTableOrParcelNumber)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
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
                      // if (snapshot.data?.docs.length == 0) {
                      //   print('came inside length us zero');
                      //   Navigator.pop(context);
                      //   // Navigator.pop(context);
                      //   return const Center(
                      //     child: CircularProgressIndicator(
                      //       backgroundColor: Colors.lightBlueAccent,
                      //     ),
                      //   );
                      // }
                      // else {
                      items = [];
                      Map<String, dynamic> mapToAddIntoItems = {};
                      String eachItemFromEntireItemsString = '';
                      distinctTablesParcels = [];
                      distinctTablesParcelsColorStatus = {};
                      final itemstream = snapshot.data?.docs;
                      // if (itemstream!.length == 0) {
                      //   print('came inside length 0');
                      //   Navigator.pop(context);
                      // }
                      for (var eachDoc in itemstream!) {
                        String splitCheck = eachDoc['addedItemsSet'];
                        final setSplit = splitCheck.split('*');
                        setSplit.removeLast();
                        String tableorparcel = setSplit[0];
                        num tableorparcelnumber = num.parse(setSplit[1]);
                        num timecustomercametoseat = num.parse(setSplit[2]);
                        String parentOrChild = setSplit[7];
                        distinctTablesParcels.insert(
                            distinctTablesParcels.length, parentOrChild);
                        distinctTablesParcelsColorStatus[parentOrChild] = 0;
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
                              mapToAddIntoItems['timecustomercametoseat'] =
                                  timecustomercametoseat;
                              mapToAddIntoItems['parentOrChild'] =
                                  parentOrChild;
                              mapToAddIntoItems['eachiteminorderid'] =
                                  setSplit[i];
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
                              if ((num.parse(setSplit[i]) -
                                      timecustomercametoseat) >=
                                  kCustomerWaitingTime) {
                                mapToAddIntoItems[
                                        'ThisItemOrderedTimeMinusCustomerCameToSeatTime'] =
                                    (num.parse(setSplit[i]) -
                                        timecustomercametoseat);
                              } else {
                                mapToAddIntoItems[
                                    'ThisItemOrderedTimeMinusCustomerCameToSeatTime'] = 0;
                              }

                              eachItemFromEntireItemsString +=
                                  '${setSplit[i]}*';
                            }
                            if ((i + 1) % 15 == 6) {
                              num statusOfThisItem = num.parse(setSplit[i]);
                              mapToAddIntoItems['statusoforder'] =
                                  num.parse(setSplit[i]);
                              eachItemFromEntireItemsString +=
                                  '${setSplit[i]}*';
                              if (tableorparcel == 'Table') {
                                if (statusOfThisItem == 11) {
                                  distinctTablesParcelsColorStatus[
                                      parentOrChild] = 11;
                                } else if (statusOfThisItem == 10 &&
                                    distinctTablesParcelsColorStatus[
                                            parentOrChild] !=
                                        11) {
//IfItemsReady
                                  distinctTablesParcelsColorStatus[
                                      parentOrChild] = 10;
                                } else if (statusOfThisItem == 9 &&
                                    distinctTablesParcelsColorStatus[
                                            parentOrChild] !=
                                        11 &&
                                    distinctTablesParcelsColorStatus[
                                            parentOrChild] !=
                                        10) {
                                  distinctTablesParcelsColorStatus[
                                      parentOrChild] = 9;
                                } else if (statusOfThisItem == 7 &&
                                    distinctTablesParcelsColorStatus[
                                            parentOrChild] !=
                                        11 &&
                                    distinctTablesParcelsColorStatus[
                                            parentOrChild] !=
                                        9 &&
                                    distinctTablesParcelsColorStatus[
                                            parentOrChild] !=
                                        10) {
                                  distinctTablesParcelsColorStatus[
                                      parentOrChild] = 7;
                                } else if (statusOfThisItem == 3 &&
                                    distinctTablesParcelsColorStatus[
                                            parentOrChild] !=
                                        11 &&
                                    distinctTablesParcelsColorStatus[
                                            parentOrChild] !=
                                        9 &&
                                    distinctTablesParcelsColorStatus[
                                            parentOrChild] !=
                                        10 &&
                                    distinctTablesParcelsColorStatus[
                                            parentOrChild] !=
                                        7) {
//ifAllItemsDelivered
                                  distinctTablesParcelsColorStatus[
                                      parentOrChild] = 3;
                                }
                              } else if (tableorparcel == 'Parcel') {
                                if (statusOfThisItem == 11) {
                                  distinctTablesParcelsColorStatus[
                                      parentOrChild] = 11;
                                } else if (statusOfThisItem == 9 &&
                                    distinctTablesParcelsColorStatus[
                                            parentOrChild] !=
                                        11) {
//IfItemsReady
                                  distinctTablesParcelsColorStatus[
                                      parentOrChild] = 9;
                                } else if (statusOfThisItem == 7 &&
                                    distinctTablesParcelsColorStatus[
                                            parentOrChild] !=
                                        11 &&
                                    distinctTablesParcelsColorStatus[
                                            parentOrChild] !=
                                        9) {
                                  distinctTablesParcelsColorStatus[
                                      parentOrChild] = 7;
                                } else if (statusOfThisItem == 10 &&
                                    distinctTablesParcelsColorStatus[
                                            parentOrChild] !=
                                        11 &&
                                    distinctTablesParcelsColorStatus[
                                            parentOrChild] !=
                                        9 &&
                                    distinctTablesParcelsColorStatus[
                                            parentOrChild] !=
                                        7) {
                                  distinctTablesParcelsColorStatus[
                                      parentOrChild] = 10;
                                } else if (statusOfThisItem == 3 &&
                                    distinctTablesParcelsColorStatus[
                                            parentOrChild] !=
                                        11 &&
                                    distinctTablesParcelsColorStatus[
                                            parentOrChild] !=
                                        9 &&
                                    distinctTablesParcelsColorStatus[
                                            parentOrChild] !=
                                        10 &&
                                    distinctTablesParcelsColorStatus[
                                            parentOrChild] !=
                                        7) {
//ifAllItemsDelivered
                                  distinctTablesParcelsColorStatus[
                                      parentOrChild] = 3;
                                }
                              }
                            }
                            if ((i + 1) % 15 == 7) {
                              mapToAddIntoItems['commentsForTheItem'] =
                                  setSplit[i];
                              eachItemFromEntireItemsString +=
                                  '${setSplit[i]}*';
                            }
                            if ((i + 1) % 15 == 8) {
                              mapToAddIntoItems['chefKotStatus'] = setSplit[i];
                              eachItemFromEntireItemsString +=
                                  '${setSplit[i]}*';
                            }
                            if ((i + 1) % 15 == 9) {
                              mapToAddIntoItems['ticketNumber'] = setSplit[i];
                              mapToAddIntoItems['itemBelongsToDoc'] =
                                  eachDoc.id;
                              mapToAddIntoItems[
                                  'entireItemListBeforeSplitting'] = splitCheck;
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
                      }
                      return (items.isEmpty && newButtonNeeded != 1)
                          ? const Center(
                              child: Text(
                              'No Items Inside',
                              style: TextStyle(fontSize: 30),
                            ))
                          : splitPageButtons();
                    } else {
//ThisErrorMessageIfSnapshotDoesn'tHaveData
                      return Center(
                        child: Text('Some Error Occured'),
                      );
                    }
                  }),
            ),
            // Container(
            //     height: double.infinity,
            //     child: VerticalDivider(color: Colors.red)),
            // Expanded(
            //     child: MaterialButton(
            //   minWidth: 20,
            //   color: Colors.white70,
            //   onPressed: () {},
            //   shape: CircleBorder(
            //
            //       // side: BorderSide(
            //       //     // width: 2,
            //       //     // color: Colors.red,
            //       //     // style: BorderStyle.solid,
            //       //     )
            //       ),
            //   child: const Icon(
            //     Icons.add,
            //     size: 35,
            //   ),
            // ))
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100.0),
        child: Container(
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
              setState(() {
                if (distinctTablesParcels.length == 14) {
                  show('Max Limit For Split Table Reached');
                } else {
                  newButtonNeeded = distinctTablesParcels.length + 1;
                  print('the length is ${newButtonNeeded}');
                }
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
              Icons.add,
              size: 35,
            ),
          ),
        ),
      ),
    );
  }
}
