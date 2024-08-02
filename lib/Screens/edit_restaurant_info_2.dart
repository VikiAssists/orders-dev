import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:orders_dev/Providers/notification_provider.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:orders_dev/services/firestore_services.dart';
import 'package:provider/provider.dart';

import '../constants.dart';

class RestaurantBaseInfoWithPaymentMethod extends StatefulWidget {
  final String hotelName;
  const RestaurantBaseInfoWithPaymentMethod({Key? key, required this.hotelName})
      : super(key: key);

  @override
  State<RestaurantBaseInfoWithPaymentMethod> createState() =>
      _RestaurantBaseInfoWithPaymentMethodState();
}

class _RestaurantBaseInfoWithPaymentMethodState
    extends State<RestaurantBaseInfoWithPaymentMethod> {
  final _fireStore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> baseInformationList = [];
  String errorMessage = '';
  String addressline1 = '';
  String tempAddressline1 = '';
  String addressline2 = '';
  String tempAddressline2 = '';
  String addressline3 = '';
  String tempAddressline3 = '';
  String gstcode = '';
  String tempGstcode = '';
  String cgst = '';
  String tempCgst = '';
  String hotelname = ''; //ThisIsTheHotelNameForPrint
  String tempHotelname = '';
  String phonenumber = '';
  String tempPhonenumber = '';
  String sgst = '';
  String tempSgst = '';
  Map<String, dynamic> parcelConsumptionHoursMap = HashMap();
  String tempParcelConsumptionHours = '';
  Map<String, dynamic> footerNotesMap = HashMap();
  Map<String, dynamic> tempFooterNotesForEdit = HashMap();
  Map<String, dynamic> tempFooterNotesForView = HashMap();
  String tempFooterNote = '';
  String tables = '';
  String tempTables = '';
  TextEditingController _stringEditingcontroller = TextEditingController();
  List<String> timeForClosing = [
    '12 am',
    '01 am',
    '02 am',
    '03 am',
    '04 am',
    '05 am',
    '06 am'
  ];
  String closingHour = '03 am';
  String tempClosingHour = '03 am';
  int expensesSegregationTimeInServer = 0;
  Map<String, dynamic> expensesSegregationMap = HashMap();
  List<String> paymentMethod = ['Payment Methods'];
  TextEditingController _editPaymentMethodController = TextEditingController();

  void errorAlertDialogBox() async {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Center(
            child: Text(
          'ERROR!',
          style: TextStyle(color: Colors.red),
        )),
        content: Text('${errorMessage}'),
        actions: [
          ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK')),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void getBaseInfo() async {
    final basicInfo =
        await _fireStore.collection(widget.hotelName).doc('basicinfo').get();

    expensesSegregationTimeInServer =
        basicInfo.data()!['updateTimes']['expensesSegregation'];
    downloadingExpensesSegregation();

    setState(() {
      hotelname = basicInfo.data()!['hotelname']; //ThisIsTheHotelNameForPrint

      baseInformationList.add({'HotelName': hotelname});

      addressline1 = basicInfo.data()!['addressline1'];

      baseInformationList.add({'AddressLine1': addressline1});

      addressline2 = basicInfo.data()!['addressline2'];

      baseInformationList.add({'AddressLine2': addressline2});

      addressline3 = basicInfo.data()!['addressline3'];
      baseInformationList.add({'AddressLine3': addressline3});

      phonenumber = basicInfo.data()!['phonenumber'];
      baseInformationList.add({'Phone Number': phonenumber});
      gstcode = basicInfo.data()!['gstcode'];
      baseInformationList.add({'GST Code': gstcode});
      cgst = basicInfo.data()!['cgst'].toString();
      baseInformationList.add({'CGST %': cgst});
      sgst = basicInfo.data()!['sgst'].toString();
      baseInformationList.add({'SGST %': sgst});
      if (basicInfo.data()!['restaurantClosingHour'] != null) {
        closingHour =
            tempClosingHour = basicInfo.data()!['restaurantClosingHour'];
      }

      if (basicInfo.data()!['parcelConsumptionHours'] != null) {
        parcelConsumptionHoursMap = basicInfo.data()!['parcelConsumptionHours'];
      }
      if (basicInfo.data()!['footerNotes'] != null) {
        footerNotesMap = basicInfo.data()!['footerNotes'];
        tempFooterNotesForView = footerNotesMap['mapFooterNotesMap'];
      }

//tables-HadMadeFormulaBeforeToGiveMoreTablesThanWhatTheCustomerWants
//ButNowWeAreLettingThemEnterTablesAsPerWishAndItNeedsToShowIn4MultiplesInScreenToo
//SoIDoThatFormula,ShowTheCustomerHowMuchTablesThatIsDisplayingInScreen
//EveryHotelMightHaveTimesWhereThereMightBeTwoThreeDifferentPeopleSittingIn,,
//SameTable,,,SoTheyNeedMoreTableNumbersThanWhatTheyActuallyHave
//ThisFormulaHelpsToCreateMoreSetOfTableRows
//WeGetAnIntegerValueDividedBy4&AddItWithOne
      num tempTables = basicInfo.data()!['tables'];
      int numberOfTableRows = ((tempTables + 4) ~/ 4) + 1;
      tables = ((numberOfTableRows * 4)).toString();
      baseInformationList.add({'No Of Tables': tables});
    });
  }

  Future<void> downloadingExpensesSegregation() async {
    int lastExpensesLocallySavedSegregationTime =
        Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .expensesSegregationDeviceSavedTimestampFromClass;

    if ((Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                    .expensesSegregationMapFromClass ==
                '{}') ||
            (expensesSegregationTimeInServer >
                lastExpensesLocallySavedSegregationTime)
//ThisMeansThereIsNewUpdateToTheData
        ) {
      final expensesSegregationQuery = await FirebaseFirestore.instance
          .collection(widget.hotelName)
          .doc('expensesSegregation')
          .get();
      expensesSegregationMap = expensesSegregationQuery.data()!;
      Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
          .expensesSegregationTimeStampSaving(expensesSegregationTimeInServer,
              json.encode(expensesSegregationMap));
      paymentMethodFromExpensesSegregationData();
    } else {
      expensesSegregationMap = json.decode(
          Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .expensesSegregationMapFromClass);
      paymentMethodFromExpensesSegregationData();
    }
  }

  void paymentMethodFromExpensesSegregationData() {
//PaymentMethods
    Map<String, dynamic> tempPaymentMethodMap =
        expensesSegregationMap['paymentMethod'];
    List<String> tempPaymentMethodList = tempPaymentMethodMap.isNotEmpty
        ? tempPaymentMethodMap.values.toList().cast<String>()
        : [];
    tempPaymentMethodList.sort();
    paymentMethod.clear();
    paymentMethod.add('Payment Methods');
    paymentMethod.addAll(tempPaymentMethodList);
//IfOthersIsClickedWeShouldGiveThemTheTextBox
    setState(() {});
  }

  @override
  void initState() {
    getBaseInfo();
    // TODO: implement initState
    super.initState();
  }

  Widget hotelNameEditDeleteBottomBar(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            Text('Hotel Name', style: TextStyle(fontSize: 30)),
            SizedBox(height: 20),
            ListTile(
              leading: Text('Hotel Name', style: TextStyle(fontSize: 20)),
              title: Container(
                child: TextField(
                  maxLength: 100,
                  controller: _stringEditingcontroller,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) {
                    tempHotelname = value.toString();
                  },
                  decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Enter Hotel Name',
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
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.orangeAccent),
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
                      if (tempHotelname == '') {
                        errorMessage = 'Please enter HotelName';
                        errorAlertDialogBox();
                      } else {
                        hotelname = tempHotelname;
                        FireStoreBaseInfoStringSaving(
                                hotelName: widget.hotelName,
                                baseInfoKey: 'hotelname',
                                baseInfoValue: hotelname)
                            .addOrEditBaseInfo();
                        Provider.of<PrinterAndOtherDetailsProvider>(context,
                                listen: false)
                            .menuOrRestaurantInfoUpdated(true);

//ThisIsForLocalList.WeNeedToArrangeBasedOnVariety
                        setState(() {
                          hotelname;
                        });

                        Navigator.pop(context);
                      }
                    },
                    child: Text('Done'))
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget addressLine1EditDeleteBottomBar(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            Text('Address Line 1', style: TextStyle(fontSize: 30)),
            SizedBox(height: 20),
            ListTile(
              leading: Text('Address Line 1', style: TextStyle(fontSize: 20)),
              title: Container(
                child: TextField(
                  maxLength: 40,
                  controller: _stringEditingcontroller,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) {
                    tempAddressline1 = value.toString();
                  },
                  decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Enter Address Line 1',
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
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.orangeAccent),
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
                      addressline1 = tempAddressline1;
                      FireStoreBaseInfoStringSaving(
                              hotelName: widget.hotelName,
                              baseInfoKey: 'addressline1',
                              baseInfoValue: addressline1)
                          .addOrEditBaseInfo();
                      Provider.of<PrinterAndOtherDetailsProvider>(context,
                              listen: false)
                          .menuOrRestaurantInfoUpdated(true);

//ThisIsForLocalList.WeNeedToArrangeBasedOnVariety
                      setState(() {
                        addressline1;
                      });

                      Navigator.pop(context);
                    },
                    child: Text('Done'))
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget addressLine2EditDeleteBottomBar(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            Text('Address Line 2', style: TextStyle(fontSize: 30)),
            SizedBox(height: 20),
            ListTile(
              leading: Text('Address Line 2', style: TextStyle(fontSize: 20)),
              title: Container(
                child: TextField(
                  maxLength: 40,
                  controller: _stringEditingcontroller,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) {
                    tempAddressline2 = value.toString();
                  },
                  decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Enter Address Line 2',
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
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.orangeAccent),
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
                      addressline2 = tempAddressline2;

                      FireStoreBaseInfoStringSaving(
                              hotelName: widget.hotelName,
                              baseInfoKey: 'addressline2',
                              baseInfoValue: addressline2)
                          .addOrEditBaseInfo();
                      Provider.of<PrinterAndOtherDetailsProvider>(context,
                              listen: false)
                          .menuOrRestaurantInfoUpdated(true);

//ThisIsForLocalList.WeNeedToArrangeBasedOnVariety
                      setState(() {
                        addressline2;
                      });

                      Navigator.pop(context);
                    },
                    child: Text('Done'))
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget addressLine3EditDeleteBottomBar(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            Text('Address Line 3', style: TextStyle(fontSize: 30)),
            SizedBox(height: 20),
            ListTile(
              leading: Text('Address Line 3', style: TextStyle(fontSize: 20)),
              title: Container(
                child: TextField(
                  maxLength: 40,
                  controller: _stringEditingcontroller,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) {
                    tempAddressline3 = value.toString();
                  },
                  decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Enter Address Line 3',
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
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.orangeAccent),
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
                      addressline3 = tempAddressline3;

                      FireStoreBaseInfoStringSaving(
                              hotelName: widget.hotelName,
                              baseInfoKey: 'addressline3',
                              baseInfoValue: addressline3)
                          .addOrEditBaseInfo();
                      Provider.of<PrinterAndOtherDetailsProvider>(context,
                              listen: false)
                          .menuOrRestaurantInfoUpdated(true);

//ThisIsForLocalList.WeNeedToArrangeBasedOnVariety
                      setState(() {
                        addressline3;
                      });

                      Navigator.pop(context);
                    },
                    child: Text('Done'))
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget phoneNumberEditDeleteBottomBar(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            Text('Phone Number', style: TextStyle(fontSize: 30)),
            SizedBox(height: 20),
            ListTile(
              leading: Text('Phone Number', style: TextStyle(fontSize: 20)),
              title: Container(
                child: TextField(
                  maxLength: 40,
                  keyboardType: TextInputType.phone,
                  controller: _stringEditingcontroller,
                  onChanged: (value) {
                    tempPhonenumber = value.toString();
                  },
                  decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Enter Phone',
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
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.orangeAccent),
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
                      phonenumber = tempPhonenumber;
                      FireStoreBaseInfoStringSaving(
                              hotelName: widget.hotelName,
                              baseInfoKey: 'phonenumber',
                              baseInfoValue: phonenumber)
                          .addOrEditBaseInfo();
                      Provider.of<PrinterAndOtherDetailsProvider>(context,
                              listen: false)
                          .menuOrRestaurantInfoUpdated(true);

//ThisIsForLocalList.WeNeedToArrangeBasedOnVariety
                      setState(() {
                        phonenumber;
                      });

                      Navigator.pop(context);
                    },
                    child: Text('Done'))
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget gstCodeEditDeleteBottomBar(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            Text('GST Code', style: TextStyle(fontSize: 30)),
            SizedBox(height: 20),
            ListTile(
              leading: Text('GST Code', style: TextStyle(fontSize: 20)),
              title: Container(
                child: TextField(
                  maxLength: 40,
                  controller: _stringEditingcontroller,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: (value) {
                    tempGstcode = value.toString();
                  },
                  decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Enter GST Code',
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
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.orangeAccent),
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
                      gstcode = tempGstcode;
                      FireStoreBaseInfoStringSaving(
                              hotelName: widget.hotelName,
                              baseInfoKey: 'gstcode',
                              baseInfoValue: gstcode)
                          .addOrEditBaseInfo();
                      Provider.of<PrinterAndOtherDetailsProvider>(context,
                              listen: false)
                          .menuOrRestaurantInfoUpdated(true);

//ThisIsForLocalList.WeNeedToArrangeBasedOnVariety
                      setState(() {
                        gstcode;
                      });

                      Navigator.pop(context);
                    },
                    child: Text('Done'))
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget cgstEditDeleteBottomBar(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            Text('CGST', style: TextStyle(fontSize: 30)),
            SizedBox(height: 20),
            ListTile(
              leading: Text('CGST', style: TextStyle(fontSize: 20)),
              title: Container(
                child: TextField(
                  maxLength: 40,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  controller: _stringEditingcontroller,
                  onChanged: (value) {
                    tempCgst = value.toString();
                  },
                  decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Enter CGST %',
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
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.orangeAccent),
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
                      if (tempCgst == '') {
                        errorMessage = 'Please enter CGST %';
                        errorAlertDialogBox();
                      } else {
                        cgst = tempCgst;
                        FireStoreBaseInfoNumSaving(
                                hotelName: widget.hotelName,
                                baseInfoKey: 'cgst',
                                baseInfoValue: num.parse(cgst))
                            .addOrEditBaseInfo();
                        Provider.of<PrinterAndOtherDetailsProvider>(context,
                                listen: false)
                            .menuOrRestaurantInfoUpdated(true);

//ThisIsForLocalList.WeNeedToArrangeBasedOnVariety
                        setState(() {
                          cgst;
                        });

                        Navigator.pop(context);
                      }
                    },
                    child: Text('Done'))
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget sgstEditDeleteBottomBar(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            Text('SGST', style: TextStyle(fontSize: 30)),
            SizedBox(height: 20),
            ListTile(
              leading: Text('SGST', style: TextStyle(fontSize: 20)),
              title: Container(
                child: TextField(
                  maxLength: 40,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  controller: _stringEditingcontroller,
                  onChanged: (value) {
                    tempSgst = value.toString();
                  },
                  decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Enter SGST %',
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
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.orangeAccent),
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
                      if (tempSgst == '') {
                        errorMessage = 'Please enter SGST %';
                        errorAlertDialogBox();
                      } else {
                        sgst = tempSgst;
                        FireStoreBaseInfoNumSaving(
                                hotelName: widget.hotelName,
                                baseInfoKey: 'sgst',
                                baseInfoValue: num.parse(sgst))
                            .addOrEditBaseInfo();
                        Provider.of<PrinterAndOtherDetailsProvider>(context,
                                listen: false)
                            .menuOrRestaurantInfoUpdated(true);

//ThisIsForLocalList.WeNeedToArrangeBasedOnVariety
                        setState(() {
                          sgst;
                        });

                        Navigator.pop(context);
                      }
                    },
                    child: Text('Done'))
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget parcelConsumptionHoursEditDeleteBottomBar(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            Text('Parcel Consume Hours', style: TextStyle(fontSize: 30)),
            SizedBox(height: 20),
            ListTile(
              leading: Text('Hours', style: TextStyle(fontSize: 20)),
              title: Container(
                child: TextField(
                  maxLength: 40,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  controller: _stringEditingcontroller,
                  onChanged: (value) {
                    tempParcelConsumptionHours = value.toString();
                  },
                  decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Parcel Consumption Hours',
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
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.orangeAccent),
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
                      parcelConsumptionHoursMap = {
                        'mapParcelConsumptionHoursMap': {
                          'hours': tempParcelConsumptionHours,
                          'bold': true,
                          'size': 'Small',
                          'alignment': 'Center'
                        }
                      };

                      FireStoreBaseInfoMapSaving(
                              hotelName: widget.hotelName,
                              baseInfoKey: 'parcelConsumptionHours',
                              baseInfoValue: parcelConsumptionHoursMap)
                          .addOrEditBaseInfo();
                      Provider.of<PrinterAndOtherDetailsProvider>(context,
                              listen: false)
                          .menuOrRestaurantInfoUpdated(true);

//ThisIsForLocalList.WeNeedToArrangeBasedOnVariety
                      setState(() {
                        parcelConsumptionHoursMap;
                      });

                      Navigator.pop(context);
                    },
                    child: Text('Done'))
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget footerNotesAddEditBottomBar(
      BuildContext context, int addEditDeleteKey, bool addTrueEditFalse) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 10),
            addTrueEditFalse
                ? Text('Add Footer', style: TextStyle(fontSize: 30))
                : Text('Edit Footer', style: TextStyle(fontSize: 30)),
            SizedBox(height: 20),
            Container(
              child: TextField(
                maxLength: 200,
                controller: _stringEditingcontroller,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (value) {
                  tempFooterNote = value.toString();
                },
                decoration:
                    // kTextFieldInputDecoration,
                    InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Enter Footer Note',
                        hintStyle: TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            borderSide: BorderSide(color: Colors.green)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                            borderSide: BorderSide(color: Colors.green))),
              ),
            ),
            SizedBox(height: 20),
            addTrueEditFalse
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Colors.orangeAccent),
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
                            if (tempFooterNote == '') {
                              errorMessage = 'Please enter Footer';
                              errorAlertDialogBox();
                            } else {
                              tempFooterNotesForEdit = tempFooterNotesForView;
                              List<int> footerKeysAlreadyExisting = [];
                              if (tempFooterNotesForEdit.isNotEmpty) {
                                footerKeysAlreadyExisting =
                                    (tempFooterNotesForEdit.keys.toList())
                                        .map(int.parse)
                                        .toList();
                              }
                              Map<String, dynamic> tempSavingFooterNotes =
                                  HashMap();
                              int indexCounter = 0;
                              if (footerKeysAlreadyExisting.isNotEmpty &&
                                  (footerKeysAlreadyExisting
                                      .any((num) => num <= addEditDeleteKey))) {
//TheseAreTheItemsThatNeedsToBeAddedBeforeTheExistingFooterNote
                                tempFooterNotesForEdit.forEach((key, value) {
                                  if (int.parse(key) <= addEditDeleteKey) {
                                    indexCounter++;
                                    tempSavingFooterNotes.addAll(
                                        {indexCounter.toString(): value});
                                  }
                                });
                              }
//ThisWillAddTheCurrentFooterNoteAfterWhereTheAddButtonIsPressed
                              indexCounter++;
                              tempSavingFooterNotes.addAll({
                                indexCounter.toString(): {
                                  'footerString': tempFooterNote,
                                  'bold': false,
                                  'size': 'Small',
                                  'alignment': 'Center'
                                }
                              });
//ToAddAllTheFooterNotesAfterIt
                              if (footerKeysAlreadyExisting.isNotEmpty &&
                                  (footerKeysAlreadyExisting
                                      .any((num) => num > addEditDeleteKey))) {
//TheseAreTheItemsThatNeedsToBeAddedAfterTheExistingFooterNote
                                tempFooterNotesForEdit.forEach((key, value) {
                                  if (int.parse(key) > addEditDeleteKey) {
                                    indexCounter++;
                                    tempSavingFooterNotes.addAll(
                                        {indexCounter.toString(): value});
                                  }
                                });
                              }
                              List<String> sortedKeys =
                                  tempSavingFooterNotes.keys.toList()..sort();
                              tempFooterNotesForView = {};
                              for (String key in sortedKeys) {
                                tempFooterNotesForView[key] =
                                    tempSavingFooterNotes[key];
                              }

                              footerNotesMap = {
                                'mapFooterNotesMap': tempFooterNotesForView
                              };

                              FireStoreBaseInfoMapSaving(
                                      hotelName: widget.hotelName,
                                      baseInfoKey: 'footerNotes',
                                      baseInfoValue: footerNotesMap)
                                  .addOrEditBaseInfo();
                              Provider.of<PrinterAndOtherDetailsProvider>(
                                      context,
                                      listen: false)
                                  .menuOrRestaurantInfoUpdated(true);

//ThisIsForLocalList.WeNeedToArrangeBasedOnVariety
                              setState(() {});

                              Navigator.pop(context);
                            }
                          },
                          child: Text(' Add '))
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all<Color>(Colors.red),
                          ),
                          onPressed: () {
                            tempFooterNotesForEdit = tempFooterNotesForView;
                            tempFooterNotesForEdit
                                .remove(addEditDeleteKey.toString());
                            Map<String, dynamic> tempSavingFooterNotes =
                                HashMap();
                            if (tempFooterNotesForEdit.isNotEmpty) {
                              int indexOfFooter = 1;
                              tempFooterNotesForEdit.forEach((key, value) {
                                tempSavingFooterNotes
                                    .addAll({indexOfFooter.toString(): value});
                                indexOfFooter++;
                              });
                              List<String> sortedKeys =
                                  tempSavingFooterNotes.keys.toList()..sort();
                              tempFooterNotesForView = {};
                              for (String key in sortedKeys) {
                                tempFooterNotesForView[key] =
                                    tempSavingFooterNotes[key];
                              }

                              footerNotesMap = {
                                'mapFooterNotesMap': tempFooterNotesForView
                              };
                            } else {
                              tempFooterNotesForView = {};
                              footerNotesMap = {
                                'mapFooterNotesMap': tempFooterNotesForView
                              };
                            }
                            footerNotesMap = {
                              'mapFooterNotesMap': tempSavingFooterNotes
                            };

                            FireStoreBaseInfoMapSaving(
                                    hotelName: widget.hotelName,
                                    baseInfoKey: 'footerNotes',
                                    baseInfoValue: footerNotesMap)
                                .addOrEditBaseInfo();
                            Provider.of<PrinterAndOtherDetailsProvider>(context,
                                    listen: false)
                                .menuOrRestaurantInfoUpdated(true);

//ThisIsForLocalList.WeNeedToArrangeBasedOnVariety
                            setState(() {});

                            Navigator.pop(context);
                          },
                          child: Text('Delete')),
                      ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all<Color>(Colors.green),
                          ),
                          onPressed: () {
                            if (tempFooterNote == '') {
                              errorMessage = 'Please enter Footer';
                              errorAlertDialogBox();
                            } else {
                              tempFooterNotesForEdit = tempFooterNotesForView;
                              tempFooterNotesForEdit[
                                  addEditDeleteKey.toString()] = {
                                'footerString': tempFooterNote,
                                'bold': false,
                                'size': 'Small',
                                'alignment': 'Center'
                              };
                              Map<String, dynamic> tempSavingFooterNotes =
                                  tempFooterNotesForEdit;
                              List<String> sortedKeys =
                                  tempSavingFooterNotes.keys.toList()..sort();
                              tempFooterNotesForView = {};
                              for (String key in sortedKeys) {
                                tempFooterNotesForView[key] =
                                    tempSavingFooterNotes[key];
                              }

                              footerNotesMap = {
                                'mapFooterNotesMap': tempFooterNotesForView
                              };

                              FireStoreBaseInfoMapSaving(
                                      hotelName: widget.hotelName,
                                      baseInfoKey: 'footerNotes',
                                      baseInfoValue: footerNotesMap)
                                  .addOrEditBaseInfo();
                              Provider.of<PrinterAndOtherDetailsProvider>(
                                      context,
                                      listen: false)
                                  .menuOrRestaurantInfoUpdated(true);

//ThisIsForLocalList.WeNeedToArrangeBasedOnVariety
                              setState(() {});

                              Navigator.pop(context);
                            }
                          },
                          child: Text('Done')),
                      ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Colors.orangeAccent),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text('Cancel'))
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget tablesEditDeleteBottomBar(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            Text('Number Of Tables', style: TextStyle(fontSize: 30)),
            SizedBox(height: 20),
            ListTile(
              leading: Text('Tables', style: TextStyle(fontSize: 20)),
              title: Container(
                child: TextField(
                  maxLength: 40,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  controller: _stringEditingcontroller,
                  onChanged: (value) {
                    tempTables = value.toString();
                  },
                  decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Enter Number of Tables',
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
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.orangeAccent),
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
                      if (tempTables == '' ||
                          tempTables == '0' ||
                          (num.parse(tempTables) > 100)) {
                        errorMessage = tempTables == '0'
                            ? 'Please enter a higher number'
                            : (num.parse(tempTables) > 100)
                                ? 'Max Limit Reached'
                                : 'Please enter number of tables';
                        errorAlertDialogBox();
                      } else {
                        tables = tempTables;
//HereWeNeedFormulaToEditAsPerTheUserWants.
//ifTheyWant5Tables,ForBeautyWeWillGive8Tables
//WeHaveAFormulaForThatInCaptainScreen.WeHaveToMakeItAccordingly
                        num tempStoringTables = (num.parse(tables) % 4 == 0)
                            ? (num.parse(tables) - 8)
                            : (num.parse(tables) - 4);
                        FireStoreBaseInfoNumSaving(
                                hotelName: widget.hotelName,
                                baseInfoKey: 'tables',
                                baseInfoValue: tempStoringTables)
                            .addOrEditBaseInfo();
                        Provider.of<PrinterAndOtherDetailsProvider>(context,
                                listen: false)
                            .menuOrRestaurantInfoUpdated(true);

//ThisIsForLocalList.WeNeedToArrangeBasedOnVariety
                        setState(() {
                          tables;
                        });

                        Navigator.pop(context);
                      }
                    },
                    child: Text('Done'))
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget restaurantClosingTimeBottomBar(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            Text('Closing Time', style: TextStyle(fontSize: 30)),
            SizedBox(height: 20),
            ListTile(
              leading: Text('Hours', style: TextStyle(fontSize: 20)),
              title: Container(
                padding: EdgeInsets.fromLTRB(100, 0, 100, 0),
                decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(30)),
                width: 100,
                height: 50,
                child: Center(
                  child: DropdownButtonFormField(
                    decoration: InputDecoration.collapsed(hintText: ''),
                    isExpanded: true,
                    // underline: Container(),
                    dropdownColor: Colors.green,
                    value: tempClosingHour,
                    onChanged: (value) {
                      setState(() {
                        tempClosingHour = value.toString();
                      });
                    },
                    items: timeForClosing.map((hours) {
//DropDownMenuItemWillHaveOneByOneItems,WePutThatAsList
//ValueWillBeEachTitle
                      return DropdownMenuItem(
                        alignment: Alignment.center,
                        child: Text(hours,
                            style: const TextStyle(
                                fontSize: 20, color: Colors.white)),
                        value: hours,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.orangeAccent),
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
                      closingHour = tempClosingHour;
                      FireStoreBaseInfoStringSaving(
                              hotelName: widget.hotelName,
                              baseInfoKey: 'restaurantClosingHour',
                              baseInfoValue: closingHour)
                          .addOrEditBaseInfo();
                      Provider.of<PrinterAndOtherDetailsProvider>(context,
                              listen: false)
                          .menuOrRestaurantInfoUpdated(true);

//ThisIsForLocalList.WeNeedToArrangeBasedOnVariety
                      setState(() {
                        closingHour;
                      });

                      Navigator.pop(context);
                    },
                    child: Text('Done'))
              ],
            )
          ],
        ),
      ),
    );
  }

//DeletingAnExistingPaymentMethod
  void deletePaymentMethodAlertDialogBox(
      String nameOfPaymentMethod, String serverAddEditDeleteKey) async {
    final fcmProvider =
        Provider.of<NotificationProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Center(
            child: Text(
          'DELETE WARNING!',
          style: TextStyle(color: Colors.red),
        )),
        content: Text('$nameOfPaymentMethod will be deleted'),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.green),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel')),
              ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.red),
                  ),
                  onPressed: () {
//ThisIsToDeleteFromServer
                    int expensesUpdateTimeInMilliseconds =
                        DateTime.now().millisecondsSinceEpoch;
                    FireStoreEditOrDeleteExpenseCategoryOrVendor(
                            hotelName:
                                Provider.of<PrinterAndOtherDetailsProvider>(
                                        context,
                                        listen: false)
                                    .chosenRestaurantDatabaseFromClass,
                            categoryOrVendor: 'paymentMethod',
                            categoryVendorName: FieldValue.delete(),
                            categoryOrVendorKey: serverAddEditDeleteKey,
                            expensesUpdateTimeInMilliseconds:
                                expensesUpdateTimeInMilliseconds)
                        .deleteOrEditExpenseCategory();
                    fcmProvider.sendNotification(
                        token: dynamicTokensToStringToken(),
                        title: Provider.of<PrinterAndOtherDetailsProvider>(context,
                                listen: false)
                            .chosenRestaurantDatabaseFromClass,
                        restaurantNameForNotification: json.decode(
                                Provider.of<PrinterAndOtherDetailsProvider>(
                                        context,
                                        listen: false)
                                    .allUserProfilesFromClass)[
                            Provider.of<PrinterAndOtherDetailsProvider>(context,
                                    listen: false)
                                .currentUserPhoneNumberFromClass]['restaurantName'],
                        body: '*restaurantInfoUpdated*');

                    Map<String, dynamic> tempExpensesPaymentMethodMap =
                        expensesSegregationMap['paymentMethod'];
                    tempExpensesPaymentMethodMap.remove(serverAddEditDeleteKey);
                    expensesSegregationMap['paymentMethod'] =
                        tempExpensesPaymentMethodMap;

                    Provider.of<PrinterAndOtherDetailsProvider>(context,
                            listen: false)
                        .expensesSegregationTimeStampSaving(
                            expensesUpdateTimeInMilliseconds,
                            json.encode(expensesSegregationMap));

                    paymentMethodFromExpensesSegregationData();

                    Navigator.pop(context);
                  },
                  child: Text('Delete')),
            ],
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

//EditingAnExistingPaymentMethod
  Widget paymentMethodEditDeleteBottomBar(BuildContext context,
      String nameOfPaymentMethod, String serverAddEditDeleteKey) {
    String tempFieldForEdit = nameOfPaymentMethod;
    _editPaymentMethodController.text = tempFieldForEdit;
    _editPaymentMethodController.selection =
        TextSelection.collapsed(offset: tempFieldForEdit.toString().length);
    final fcmProvider =
        Provider.of<NotificationProvider>(context, listen: false);
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            Text('Edit Payment Method', style: TextStyle(fontSize: 30)),
            SizedBox(height: 10),
            ListTile(
              leading: Text('Payment Method', style: TextStyle(fontSize: 20)),
              title: Container(
                child: TextField(
                  maxLength: 40,
                  controller: _editPaymentMethodController,
                  onChanged: (value) {
                    tempFieldForEdit = value.toString();
                  },
                  decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          // hintText: categoryOrVendor == 'category'
                          //     ? 'Enter Category Name'
                          //     : 'Enter Vendor Name',
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
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.red),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      deletePaymentMethodAlertDialogBox(
                          nameOfPaymentMethod, serverAddEditDeleteKey);
                    },
                    child: Text('Delete')),
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.green),
                    ),
                    onPressed: () {
                      if (tempFieldForEdit == '') {
                        errorMessage = 'Please Enter the Field';
                        errorAlertDialogBox();
                      } else if (paymentMethod.contains(tempFieldForEdit)) {
                        errorMessage = 'Payment Method Already Exists';
                        errorAlertDialogBox();
                      } else {
                        //ThisIsToEditTheCategoryOrVendorName
                        int expensesUpdateTimeInMilliseconds =
                            DateTime.now().millisecondsSinceEpoch;
                        FireStoreEditOrDeleteExpenseCategoryOrVendor(
                                hotelName:
                                    Provider.of<PrinterAndOtherDetailsProvider>(
                                            context,
                                            listen: false)
                                        .chosenRestaurantDatabaseFromClass,
                                categoryOrVendor: 'paymentMethod',
                                categoryVendorName: tempFieldForEdit,
                                categoryOrVendorKey: serverAddEditDeleteKey,
                                expensesUpdateTimeInMilliseconds:
                                    expensesUpdateTimeInMilliseconds)
                            .deleteOrEditExpenseCategory();
                        fcmProvider.sendNotification(
                            token: dynamicTokensToStringToken(),
                            title: Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                                .chosenRestaurantDatabaseFromClass,
                            restaurantNameForNotification: json.decode(
                                        Provider.of<PrinterAndOtherDetailsProvider>(
                                                context,
                                                listen: false)
                                            .allUserProfilesFromClass)[
                                    Provider.of<PrinterAndOtherDetailsProvider>(
                                            context,
                                            listen: false)
                                        .currentUserPhoneNumberFromClass]
                                ['restaurantName'],
                            body: '*restaurantInfoUpdated*');
                        Map<String, dynamic> tempExpensesPaymentMethodMap =
                            expensesSegregationMap['paymentMethod'];
                        tempExpensesPaymentMethodMap[serverAddEditDeleteKey] =
                            tempFieldForEdit;
                        expensesSegregationMap['paymentMethod'] =
                            tempExpensesPaymentMethodMap;
                        Provider.of<PrinterAndOtherDetailsProvider>(context,
                                listen: false)
                            .expensesSegregationTimeStampSaving(
                                expensesUpdateTimeInMilliseconds,
                                json.encode(expensesSegregationMap));
                        paymentMethodFromExpensesSegregationData();
                        Navigator.pop(context);
                      }
                    },
                    child: Text('Done')),
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.orangeAccent),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Cancel'))
              ],
            )
          ],
        ),
      ),
    );
  }

  //EditingAnExistingPaymentMethod
  Widget paymentMethodAddBottomBar(BuildContext context,
      String nameOfPaymentMethod, String serverAddEditDeleteKey) {
    String tempFieldForEdit = nameOfPaymentMethod;
    _editPaymentMethodController.text = tempFieldForEdit;
    _editPaymentMethodController.selection =
        TextSelection.collapsed(offset: tempFieldForEdit.toString().length);
    final fcmProvider =
        Provider.of<NotificationProvider>(context, listen: false);
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            Text('Add Payment Method', style: TextStyle(fontSize: 30)),
            SizedBox(height: 10),
            ListTile(
              leading: Text('Payment Method', style: TextStyle(fontSize: 20)),
              title: Container(
                child: TextField(
                  maxLength: 40,
                  controller: _editPaymentMethodController,
                  onChanged: (value) {
                    tempFieldForEdit = value.toString();
                  },
                  decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          // hintText: categoryOrVendor == 'category'
                          //     ? 'Enter Category Name'
                          //     : 'Enter Vendor Name',
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
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.green),
                    ),
                    onPressed: () {
                      if (tempFieldForEdit == '') {
                        errorMessage = 'Please Enter the Field';
                        errorAlertDialogBox();
                      } else if (paymentMethod.contains(tempFieldForEdit)) {
                        errorMessage = 'Payment Method Already Exists';
                        errorAlertDialogBox();
                      } else {
                        //ThisIsToEditTheCategoryOrVendorName
                        int expensesUpdateTimeInMilliseconds =
                            DateTime.now().millisecondsSinceEpoch;
                        FireStoreEditOrDeleteExpenseCategoryOrVendor(
                                hotelName:
                                    Provider.of<PrinterAndOtherDetailsProvider>(
                                            context,
                                            listen: false)
                                        .chosenRestaurantDatabaseFromClass,
                                categoryOrVendor: 'paymentMethod',
                                categoryVendorName: tempFieldForEdit,
                                categoryOrVendorKey: serverAddEditDeleteKey,
                                expensesUpdateTimeInMilliseconds:
                                    expensesUpdateTimeInMilliseconds)
                            .deleteOrEditExpenseCategory();
                        fcmProvider.sendNotification(
                            token: dynamicTokensToStringToken(),
                            title: Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                                .chosenRestaurantDatabaseFromClass,
                            restaurantNameForNotification: json.decode(
                                        Provider.of<PrinterAndOtherDetailsProvider>(
                                                context,
                                                listen: false)
                                            .allUserProfilesFromClass)[
                                    Provider.of<PrinterAndOtherDetailsProvider>(
                                            context,
                                            listen: false)
                                        .currentUserPhoneNumberFromClass]
                                ['restaurantName'],
                            body: '*restaurantInfoUpdated*');
                        Map<String, dynamic> tempExpensesPaymentMethodMap =
                            expensesSegregationMap['paymentMethod'];
                        tempExpensesPaymentMethodMap
                            .addAll({serverAddEditDeleteKey: tempFieldForEdit});
                        expensesSegregationMap['paymentMethod'] =
                            tempExpensesPaymentMethodMap;
                        Provider.of<PrinterAndOtherDetailsProvider>(context,
                                listen: false)
                            .expensesSegregationTimeStampSaving(
                                expensesUpdateTimeInMilliseconds,
                                json.encode(expensesSegregationMap));
                        paymentMethodFromExpensesSegregationData();
                        Navigator.pop(context);
                      }
                    },
                    child: Text('Done')),
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.orangeAccent),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Cancel'))
              ],
            )
          ],
        ),
      ),
    );
  }

//AddingAnExistingPaymentMethod

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

  @override
  Widget build(BuildContext context) {
    final fcmProvider = Provider.of<NotificationProvider>(context);
    return WillPopScope(
      onWillPop: () async {
        if (Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .menuOrRestaurantInfoUpdatedFromClass) {
          fcmProvider.sendNotification(
              token: dynamicTokensToStringToken(),
              title: widget.hotelName,
              restaurantNameForNotification: json.decode(
                      Provider.of<PrinterAndOtherDetailsProvider>(context,
                              listen: false)
                          .allUserProfilesFromClass)[
                  Provider.of<PrinterAndOtherDetailsProvider>(context,
                          listen: false)
                      .currentUserPhoneNumberFromClass]['restaurantName'],
              body: '*restaurantInfoUpdated*');
        }
        Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .menuOrRestaurantInfoUpdated(false);
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
          appBar: AppBar(
            backgroundColor: kAppBarBackgroundColor,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: kAppBarBackIconColor),
              onPressed: () {
                if (Provider.of<PrinterAndOtherDetailsProvider>(context,
                        listen: false)
                    .menuOrRestaurantInfoUpdatedFromClass) {
                  fcmProvider.sendNotification(
                      token: dynamicTokensToStringToken(),
                      title: widget.hotelName,
                      restaurantNameForNotification: json.decode(
                                  Provider.of<PrinterAndOtherDetailsProvider>(
                                          context,
                                          listen: false)
                                      .allUserProfilesFromClass)[
                              Provider.of<PrinterAndOtherDetailsProvider>(
                                      context,
                                      listen: false)
                                  .currentUserPhoneNumberFromClass]
                          ['restaurantName'],
                      body: '*restaurantInfoUpdated*');
                }
                Provider.of<PrinterAndOtherDetailsProvider>(context,
                        listen: false)
                    .menuOrRestaurantInfoUpdated(false);
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            title: Text(
              'Restaurant Info',
              style: kAppBarTextStyle,
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 10),
                Container(
                  margin: EdgeInsets.fromLTRB(5, 5, 0, 10),
                  child: ListTile(
                      tileColor: Colors.white54,
                      leading: Text('Hotel Name        '),
                      title: Text(hotelname),
                      trailing: hotelname == ''
                          ? IconButton(
                              icon: Icon(Icons.add,
                                  size: 20, color: Colors.green),
                              onPressed: () {
                                tempHotelname = hotelname;
                                _stringEditingcontroller =
                                    TextEditingController(text: hotelname);

                                showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return hotelNameEditDeleteBottomBar(
                                          context);
                                    });
                              },
                            )
                          : IconButton(
                              icon: Icon(Icons.edit,
                                  size: 20, color: Colors.green),
                              onPressed: () {
                                _stringEditingcontroller =
                                    TextEditingController(text: hotelname);
                                showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return hotelNameEditDeleteBottomBar(
                                          context);
                                    });
                              },
                            )),
                ),
                Container(
                  //ContainerJustToEnsureWeCouldGiveTheMarginsToListTile
                  margin: EdgeInsets.fromLTRB(5, 5, 0, 10),
                  child: ListTile(
                      tileColor: Colors.white54,
                      leading: Text('Address Line 1  '),
                      title: Text(addressline1),
                      trailing: addressline1 == ''
                          ? IconButton(
                              icon: Icon(Icons.add,
                                  size: 20, color: Colors.green),
                              onPressed: () {
                                tempAddressline1 = addressline1;
                                _stringEditingcontroller =
                                    TextEditingController(
                                        text: tempAddressline1);

                                showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return addressLine1EditDeleteBottomBar(
                                          context);
                                    });
                              },
                            )
                          : IconButton(
                              icon: Icon(Icons.edit,
                                  size: 20, color: Colors.green),
                              onPressed: () {
                                tempAddressline1 = addressline1;
                                _stringEditingcontroller =
                                    TextEditingController(
                                        text: tempAddressline1);

                                showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return addressLine1EditDeleteBottomBar(
                                          context);
                                    });
                              },
                            )),
                ),
                Container(
                  //ContainerJustToEnsureWeCouldGiveTheMarginsToListTile
                  margin: EdgeInsets.fromLTRB(5, 5, 0, 10),
                  child: ListTile(
                      leading: Text('Address Line 2  '),
                      title: Text(addressline2),
                      trailing: addressline2 == ''
                          ? IconButton(
                              icon: Icon(Icons.add,
                                  size: 20, color: Colors.green),
                              onPressed: () {
                                tempAddressline2 = addressline2;
                                _stringEditingcontroller =
                                    TextEditingController(
                                        text: tempAddressline2);

                                showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return addressLine2EditDeleteBottomBar(
                                          context);
                                    });
                              },
                            )
                          : IconButton(
                              icon: Icon(Icons.edit,
                                  size: 20, color: Colors.green),
                              onPressed: () {
                                tempAddressline2 = addressline2;
                                _stringEditingcontroller =
                                    TextEditingController(
                                        text: tempAddressline2);

                                showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return addressLine2EditDeleteBottomBar(
                                          context);
                                    });
                              },
                            )),
                ),
                Container(
                  //ContainerJustToEnsureWeCouldGiveTheMarginsToListTile
                  margin: EdgeInsets.fromLTRB(5, 5, 0, 10),
                  child: ListTile(
                      leading: Text('Address Line 3  '),
                      title: Text(addressline3),
                      trailing: addressline3 == ''
                          ? IconButton(
                              icon: Icon(Icons.add,
                                  size: 20, color: Colors.green),
                              onPressed: () {
                                tempAddressline3 = addressline3;
                                _stringEditingcontroller =
                                    TextEditingController(
                                        text: tempAddressline3);

                                showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return addressLine3EditDeleteBottomBar(
                                          context);
                                    });
                              },
                            )
                          : IconButton(
                              icon: Icon(Icons.edit,
                                  size: 20, color: Colors.green),
                              onPressed: () {
                                tempAddressline3 = addressline3;
                                _stringEditingcontroller =
                                    TextEditingController(
                                        text: tempAddressline3);

                                showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return addressLine3EditDeleteBottomBar(
                                          context);
                                    });
                              },
                            )),
                ),
                Container(
                  //ContainerJustToEnsureWeCouldGiveTheMarginsToListTile
                  margin: EdgeInsets.fromLTRB(5, 5, 0, 10),
                  child: ListTile(
                      tileColor: Colors.white54,
                      leading: Text('Phone Number    '),
                      title: Text(phonenumber),
                      trailing: phonenumber == ''
                          ? IconButton(
                              icon: Icon(Icons.add,
                                  size: 20, color: Colors.green),
                              onPressed: () {
                                tempPhonenumber = phonenumber;
                                _stringEditingcontroller =
                                    TextEditingController(
                                        text: tempPhonenumber);

                                showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return phoneNumberEditDeleteBottomBar(
                                          context);
                                    });
                              },
                            )
                          : IconButton(
                              icon: Icon(Icons.edit,
                                  size: 20, color: Colors.green),
                              onPressed: () {
                                tempPhonenumber = phonenumber;
                                _stringEditingcontroller =
                                    TextEditingController(
                                        text: tempPhonenumber);

                                showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return phoneNumberEditDeleteBottomBar(
                                          context);
                                    });
                              },
                            )),
                ),
                Container(
                  //ContainerJustToEnsureWeCouldGiveTheMarginsToListTile
                  margin: EdgeInsets.fromLTRB(5, 5, 0, 10),
                  child: ListTile(
                      tileColor: Colors.white54,
                      leading: Text('GST Code             '),
                      title: Text(gstcode),
                      trailing: gstcode == ''
                          ? IconButton(
                              icon: Icon(Icons.add,
                                  size: 20, color: Colors.green),
                              onPressed: () {
                                tempGstcode = gstcode;
                                _stringEditingcontroller =
                                    TextEditingController(text: tempGstcode);

                                showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return gstCodeEditDeleteBottomBar(
                                          context);
                                    });
                              },
                            )
                          : IconButton(
                              icon: Icon(Icons.edit,
                                  size: 20, color: Colors.green),
                              onPressed: () {
                                tempGstcode = gstcode;
                                _stringEditingcontroller =
                                    TextEditingController(text: tempGstcode);

                                showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return gstCodeEditDeleteBottomBar(
                                          context);
                                    });
                              },
                            )),
                ),
                Container(
                  //ContainerJustToEnsureWeCouldGiveTheMarginsToListTile
                  margin: EdgeInsets.fromLTRB(5, 5, 0, 10),
                  child: ListTile(
                      tileColor: Colors.white54,
                      leading: Text('CGST %                 '),
                      title: Text(cgst),
//RightSide-WeCheckWhetherItIsHeading,IfYesWeShowNothing,
//ElseWeGiveTheAddOrCounterButton,TheInputBeingTheItemName
                      trailing: cgst == ''
                          ? IconButton(
                              icon: Icon(Icons.add,
                                  size: 20, color: Colors.green),
                              onPressed: () {
                                tempCgst = cgst;
                                _stringEditingcontroller =
                                    TextEditingController(text: tempCgst);

                                showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return cgstEditDeleteBottomBar(context);
                                    });
                              },
                            )
                          : IconButton(
                              icon: Icon(Icons.edit,
                                  size: 20, color: Colors.green),
                              onPressed: () {
                                tempCgst = cgst;
                                _stringEditingcontroller =
                                    TextEditingController(text: tempCgst);

                                showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return cgstEditDeleteBottomBar(context);
                                    });
                              },
                            )),
                ),
                Container(
                  //ContainerJustToEnsureWeCouldGiveTheMarginsToListTile
                  margin: EdgeInsets.fromLTRB(5, 5, 0, 10),
                  child: ListTile(
                      tileColor: Colors.white54,
                      leading: Text('SGST %                 '),
                      title: Text(sgst),
//RightSide-WeCheckWhetherItIsHeading,IfYesWeShowNothing,
//ElseWeGiveTheAddOrCounterButton,TheInputBeingTheItemName
                      trailing: sgst == ''
                          ? IconButton(
                              icon: Icon(Icons.add,
                                  size: 20, color: Colors.green),
                              onPressed: () {
                                tempSgst = sgst;
                                _stringEditingcontroller =
                                    TextEditingController(text: tempSgst);

                                showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return sgstEditDeleteBottomBar(context);
                                    });
                              },
                            )
                          : IconButton(
                              icon: Icon(Icons.edit,
                                  size: 20, color: Colors.green),
                              onPressed: () {
                                tempSgst = sgst;
                                _stringEditingcontroller =
                                    TextEditingController(text: tempSgst);

                                showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return sgstEditDeleteBottomBar(context);
                                    });
                              },
                            )),
                ),
                Container(
                  //ContainerJustToEnsureWeCouldGiveTheMarginsToListTile
                  margin: EdgeInsets.fromLTRB(5, 5, 0, 10),
                  child: ListTile(
                      tileColor: Colors.white54,
                      leading: Text('Tables                  '),
                      title: Text(tables),

//RightSide-WeCheckWhetherItIsHeading,IfYesWeShowNothing,
//ElseWeGiveTheAddOrCounterButton,TheInputBeingTheItemName
                      trailing: tables == ''
                          ? IconButton(
                              icon: Icon(Icons.add,
                                  size: 20, color: Colors.green),
                              onPressed: () {
                                tempTables = tables;
                                _stringEditingcontroller =
                                    TextEditingController(text: tempTables);

                                showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return tablesEditDeleteBottomBar(context);
                                    });
                              },
                            )
                          : IconButton(
                              icon: Icon(Icons.edit,
                                  size: 20, color: Colors.green),
                              onPressed: () {
                                tempTables = tables;
                                _stringEditingcontroller =
                                    TextEditingController(text: tempTables);

                                showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return tablesEditDeleteBottomBar(context);
                                    });
                              },
                            )),
                ),
                Container(
                  //ContainerJustToEnsureWeCouldGiveTheMarginsToListTile
                  margin: EdgeInsets.fromLTRB(5, 5, 0, 10),
                  child: ListTile(
                    leading: Text('Closing Hour       '),
                    title: Text(closingHour),
                    trailing: IconButton(
                      icon: Icon(Icons.edit, size: 20, color: Colors.green),
                      onPressed: () {
                        tempClosingHour = closingHour;
                        showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return restaurantClosingTimeBottomBar(context);
                            });
                      },
                    ),
                    subtitle: tempClosingHour == '12 am'
                        ? Text('Bills will be closed by mid-night')
                        : Text(
                            'Bills from 12 am to $tempClosingHour will be registered on the previous day'),
                  ),
                ),
//ForPaymentMethodEdit
                Container(
                  //ContainerJustToEnsureWeCouldGiveTheMarginsToListTile
                  margin: EdgeInsets.fromLTRB(5, 5, 0, 10),
                  child: ListTile(
                      tileColor: Colors.white54,
                      leading: Text('Payment Methods   \n              Edit'),
                      title: Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 15),
                        width: 160,
                        decoration: BoxDecoration(
                            color: Colors.green,
//                Theme.of(context).primaryColor
                            borderRadius: BorderRadius.circular(30)),
//WeHaveDropDownButtonInside
//UnderlineWillBeContainer
//InitiallyWhenWeOpen,TheValueAlwaysWillBe 0-BrowseMenu
//OnClicked,ItWillCheckTheValueOfThatItem&ScrollToThatIndex
                        child: DropdownButton(
                          isExpanded: true,
                          underline: Container(),
                          dropdownColor: Colors.green,
                          value: paymentMethod[0],
                          onChanged: (value) {
                            if (value.toString() != 'Payment Methods' &&
                                value.toString() != 'Cash Payment') {
                              Map<String, dynamic> tempPaymentMethodMap =
                                  expensesSegregationMap['paymentMethod'];
                              var keyOfPaymentMethod = tempPaymentMethodMap.keys
                                  .firstWhere((key) =>
                                      tempPaymentMethodMap[key] ==
                                      value.toString());
                              showModalBottomSheet(
                                  context: context,
                                  builder: (context) {
                                    return paymentMethodEditDeleteBottomBar(
                                        context,
                                        value.toString(),
                                        keyOfPaymentMethod);
                                  });
                            }
                          },
                          items: paymentMethod.map((title) {
//DropDownMenuItemWillHaveOneByOneItems,WePutThatAsList
//ValueWillBeEachTitle
                            return DropdownMenuItem(
                              child: Container(
                                  alignment: Alignment.center,
                                  child: (title != 'Cash Payment' &&
                                          title != 'Payment Methods')
                                      ? Text('$title',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.white))
                                      : Text(title,
                                          textAlign: TextAlign.center,
                                          style: title != 'Payment Methods'
                                              ? const TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.black)
                                              : const TextStyle(
                                                  fontSize: 15,
                                                  color: Colors.black,
                                                  fontWeight:
                                                      FontWeight.bold))),
                              value: title,
                            );
                          }).toList(),
                        ),
                      ),
//RightSide-WeCheckWhetherItIsHeading,IfYesWeShowNothing,
//ElseWeGiveTheAddOrCounterButton,TheInputBeingTheItemName
                      trailing: IconButton(
                        icon: Icon(Icons.add, size: 20, color: Colors.green),
                        onPressed: () {
                          Map<String, dynamic> tempPaymentMethodMap =
                              expensesSegregationMap['paymentMethod'];
                          num newPaymentMethodKey = 111111111;
                          if (tempPaymentMethodMap.isNotEmpty) {
                            List<num> currentPaymentMethodKey = [];
                            tempPaymentMethodMap.forEach((key, value) {
                              currentPaymentMethodKey.add(num.parse(key));
                            });
                            newPaymentMethodKey =
                                currentPaymentMethodKey.reduce(max) + 1;
                          }

                          showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return paymentMethodAddBottomBar(context, '',
                                    newPaymentMethodKey.toString());
                              });
                        },
                      )),
                ),
                Container(
                  //ContainerJustToEnsureWeCouldGiveTheMarginsToListTile
                  margin: EdgeInsets.fromLTRB(5, 5, 0, 10),
                  child: ListTile(
                      tileColor: Colors.white54,
                      leading: Text('Parcel Consume\nHours'),
                      title: parcelConsumptionHoursMap.isEmpty
                          ? Text('')
                          : Text(parcelConsumptionHoursMap[
                              'mapParcelConsumptionHoursMap']['hours']),
//RightSide-WeCheckWhetherItIsHeading,IfYesWeShowNothing,
//ElseWeGiveTheAddOrCounterButton,TheInputBeingTheItemN
                      trailing: (parcelConsumptionHoursMap.isEmpty ||
                              parcelConsumptionHoursMap[
                                          'mapParcelConsumptionHoursMap']
                                      ['hours'] ==
                                  '')
                          ? IconButton(
                              icon: Icon(Icons.add,
                                  size: 20, color: Colors.green),
                              onPressed: () {
                                tempParcelConsumptionHours = '';
                                _stringEditingcontroller =
                                    TextEditingController(
                                        text: tempParcelConsumptionHours);

                                showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return parcelConsumptionHoursEditDeleteBottomBar(
                                          context);
                                    });
                              },
                            )
                          : IconButton(
                              icon: Icon(Icons.edit,
                                  size: 20, color: Colors.green),
                              onPressed: () {
                                tempParcelConsumptionHours =
                                    parcelConsumptionHoursMap[
                                            'mapParcelConsumptionHoursMap']
                                        ['hours'];

                                _stringEditingcontroller =
                                    TextEditingController(
                                        text: tempParcelConsumptionHours);

                                showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return parcelConsumptionHoursEditDeleteBottomBar(
                                          context);
                                    });
                              },
                            )),
                ),

                Container(
                  //ContainerJustToEnsureWeCouldGiveTheMarginsToListTile
                  //IncaseFooterNotesAreThereItShouldBeClose
                  margin: tempFooterNotesForView.isEmpty
                      ? EdgeInsets.fromLTRB(5, 5, 0, 10)
                      : EdgeInsets.fromLTRB(5, 5, 0, 0),
                  child: ListTile(
                      tileColor: Colors.white54,
                      leading: Text('Footer Notes'),
                      // title: Text(''),
//RightSide-WeCheckWhetherItIsHeading,IfYesWeShowNothing,
//ElseWeGiveTheAddOrCounterButton,TheInputBeingTheItemN
                      trailing: Visibility(
                        visible: tempFooterNotesForView.isEmpty ? true : false,
                        child: IconButton(
                          icon: Icon(Icons.add, size: 20, color: Colors.green),
                          onPressed: () {
                            tempFooterNote = '';
                            _stringEditingcontroller =
                                TextEditingController(text: tempFooterNote);
                            showModalBottomSheet(
                                context: context,
                                builder: (context) {
                                  return footerNotesAddEditBottomBar(
                                      context, 0, true);
                                });
                          },
                        ),
                      )),
                ),
                Visibility(
                  visible: tempFooterNotesForView.isNotEmpty ? true : false,
                  child: Column(
                    children: tempFooterNotesForView.entries.map((entry) {
                      final eachFooterKey = entry.key;
                      Map<String, dynamic> eachFooterMap = entry.value;
                      return ListTile(
                        title: Text(eachFooterMap['footerString']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit,
                                  size: 20, color: Colors.green),
                              onPressed: () {
                                tempFooterNote = eachFooterMap['footerString'];
                                _stringEditingcontroller =
                                    TextEditingController(text: tempFooterNote);
                                showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return footerNotesAddEditBottomBar(
                                          context,
                                          int.parse(eachFooterKey),
                                          false);
                                    });
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.add,
                                  size: 20, color: Colors.green),
                              onPressed: () {
                                tempFooterNote = '';
                                _stringEditingcontroller =
                                    TextEditingController(text: tempFooterNote);
                                showModalBottomSheet(
                                    context: context,
                                    builder: (context) {
                                      return footerNotesAddEditBottomBar(
                                          context,
                                          int.parse(eachFooterKey),
                                          true);
                                    });
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          )),
    );
  }
}
