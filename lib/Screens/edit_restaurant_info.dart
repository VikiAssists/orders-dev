import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:orders_dev/services/firestore_services.dart';
import 'package:provider/provider.dart';

import '../constants.dart';

class RestaurantBaseInfo extends StatefulWidget {
  final String hotelName;
  const RestaurantBaseInfo({Key? key, required this.hotelName})
      : super(key: key);

  @override
  State<RestaurantBaseInfo> createState() => _RestaurantBaseInfoState();
}

class _RestaurantBaseInfoState extends State<RestaurantBaseInfo> {
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
  String tables = '';
  String tempTables = '';
  TextEditingController _stringEditingcontroller = TextEditingController();
  TextEditingController _numEditingcontroller = TextEditingController();

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
                  maxLength: 40,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                            icon:
                                Icon(Icons.add, size: 20, color: Colors.green),
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
                            icon:
                                Icon(Icons.edit, size: 20, color: Colors.green),
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
                            icon:
                                Icon(Icons.add, size: 20, color: Colors.green),
                            onPressed: () {
                              tempAddressline1 = addressline1;
                              _stringEditingcontroller =
                                  TextEditingController(text: tempAddressline1);

                              showModalBottomSheet(
                                  context: context,
                                  builder: (context) {
                                    return addressLine1EditDeleteBottomBar(
                                        context);
                                  });
                            },
                          )
                        : IconButton(
                            icon:
                                Icon(Icons.edit, size: 20, color: Colors.green),
                            onPressed: () {
                              tempAddressline1 = addressline1;
                              _stringEditingcontroller =
                                  TextEditingController(text: tempAddressline1);

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
                            icon:
                                Icon(Icons.add, size: 20, color: Colors.green),
                            onPressed: () {
                              tempAddressline2 = addressline2;
                              _stringEditingcontroller =
                                  TextEditingController(text: tempAddressline2);

                              showModalBottomSheet(
                                  context: context,
                                  builder: (context) {
                                    return addressLine2EditDeleteBottomBar(
                                        context);
                                  });
                            },
                          )
                        : IconButton(
                            icon:
                                Icon(Icons.edit, size: 20, color: Colors.green),
                            onPressed: () {
                              tempAddressline2 = addressline2;
                              _stringEditingcontroller =
                                  TextEditingController(text: tempAddressline2);

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
                            icon:
                                Icon(Icons.add, size: 20, color: Colors.green),
                            onPressed: () {
                              tempAddressline3 = addressline3;
                              _stringEditingcontroller =
                                  TextEditingController(text: tempAddressline3);

                              showModalBottomSheet(
                                  context: context,
                                  builder: (context) {
                                    return addressLine3EditDeleteBottomBar(
                                        context);
                                  });
                            },
                          )
                        : IconButton(
                            icon:
                                Icon(Icons.edit, size: 20, color: Colors.green),
                            onPressed: () {
                              tempAddressline3 = addressline3;
                              _stringEditingcontroller =
                                  TextEditingController(text: tempAddressline3);

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
                            icon:
                                Icon(Icons.add, size: 20, color: Colors.green),
                            onPressed: () {
                              tempPhonenumber = phonenumber;
                              _stringEditingcontroller =
                                  TextEditingController(text: tempPhonenumber);

                              showModalBottomSheet(
                                  context: context,
                                  builder: (context) {
                                    return phoneNumberEditDeleteBottomBar(
                                        context);
                                  });
                            },
                          )
                        : IconButton(
                            icon:
                                Icon(Icons.edit, size: 20, color: Colors.green),
                            onPressed: () {
                              tempPhonenumber = phonenumber;
                              _stringEditingcontroller =
                                  TextEditingController(text: tempPhonenumber);

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
                            icon:
                                Icon(Icons.add, size: 20, color: Colors.green),
                            onPressed: () {
                              tempGstcode = gstcode;
                              _stringEditingcontroller =
                                  TextEditingController(text: tempGstcode);

                              showModalBottomSheet(
                                  context: context,
                                  builder: (context) {
                                    return gstCodeEditDeleteBottomBar(context);
                                  });
                            },
                          )
                        : IconButton(
                            icon:
                                Icon(Icons.edit, size: 20, color: Colors.green),
                            onPressed: () {
                              tempGstcode = gstcode;
                              _stringEditingcontroller =
                                  TextEditingController(text: tempGstcode);

                              showModalBottomSheet(
                                  context: context,
                                  builder: (context) {
                                    return gstCodeEditDeleteBottomBar(context);
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
                            icon:
                                Icon(Icons.add, size: 20, color: Colors.green),
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
                            icon:
                                Icon(Icons.edit, size: 20, color: Colors.green),
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
                            icon:
                                Icon(Icons.add, size: 20, color: Colors.green),
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
                            icon:
                                Icon(Icons.edit, size: 20, color: Colors.green),
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
                            icon:
                                Icon(Icons.add, size: 20, color: Colors.green),
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
                            icon:
                                Icon(Icons.edit, size: 20, color: Colors.green),
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
            ],
          ),
        ));
  }
}
