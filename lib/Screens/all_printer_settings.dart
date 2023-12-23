import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:orders_dev/Screens/printers_saving_1.dart';
import 'package:orders_dev/constants.dart';
import 'package:provider/provider.dart';

class AllPrinterSettings extends StatefulWidget {
  const AllPrinterSettings({Key? key}) : super(key: key);

  @override
  State<AllPrinterSettings> createState() => _AllPrinterSettingsState();
}

class _AllPrinterSettingsState extends State<AllPrinterSettings> {
  Map<String, dynamic> kotPrinterAssigningMap = HashMap();
  Map<String, dynamic> billingPrinterAssigningMap = HashMap();
  Map<String, dynamic> chefPrinterAssigningMap = HashMap();
  List<Map<String, dynamic>> kotPrinterAssignedList = [];
  Map<String, dynamic> printerSavingMap = {};
  List<Map<String, dynamic>> printersList = [];
  Map<String, dynamic> allUserProfiles = HashMap();
  Map<String, String> phoneNameMap = HashMap();
  List<String> phoneNumbersListForUsersNeededInKot = [];
  bool assignMoreLanPrinterForKotPrinting = false;
  List<String> listOfLanPrintersAmongPrintersSaved = [];

  void savedPrintersAndPrinterAssigningFromProvider() {
//ForMapsAndListsWithThePrintersThatHasBeenSaved
    if (Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .savedPrintersFromClass !=
        '') {
      printerSavingMap = json.decode(
          Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .savedPrintersFromClass);
      printersList = [];
      listOfLanPrintersAmongPrintersSaved = [];
      assignMoreLanPrinterForKotPrinting = false;
      printerSavingMap.forEach((key, value) {
        printersList.add(value);
        if (value['printerBluetoothAddress'] != 'NA') {
          listOfLanPrintersAmongPrintersSaved.add(key);
        }
        if (kotPrinterAssigningMap.isNotEmpty) {
          kotPrinterAssigningMap.forEach((kotPrinterKey, kotPrinterValue) {
//ThisWillHelpToHaveAllTheInfoAboutThePrinterInKotPrinterAssignedList
//WhenWeAreMakingListOfPrintersForAdding,ThisListWillHelpToEliminateTheOnes
//ThatHaveAlreadyBeenAdded
            if (key == kotPrinterKey) {
              if (value['printerBluetoothAddress'] != 'NA') {
                listOfLanPrintersAmongPrintersSaved.remove(key);
//WeAreRemovingToCheckWhetherTheUserHasAnyMoreLanPrinterOtherThanThe
//AlreadyAssignedLanPrinter
                assignMoreLanPrinterForKotPrinting = true;
//ThisIsToSayWeHaveALanPrinterAssigned
              }
              Map<String, dynamic> tempKotMap = HashMap();
              tempKotMap.addAll(kotPrinterValue);
              tempKotMap.addAll(value);
              kotPrinterAssignedList.add(tempKotMap);
            }
          });
        }
      });
      if (assignMoreLanPrinterForKotPrinting &&
          listOfLanPrintersAmongPrintersSaved.isEmpty) {
        assignMoreLanPrinterForKotPrinting = false;
      }
    }
//MakingUserProfilesSoThatWeCanAddPeopleForKot
    phoneNameMap = {};

    allUserProfiles = json.decode(
        Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .allUserProfilesFromClass);
    if (allUserProfiles[
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .currentUserPhoneNumberFromClass]['admin'] ==
        true) {
//IfUserIsAdmin
      allUserProfiles.forEach((key, value) {
        phoneNameMap.addAll({key: value['username']});
        phoneNumbersListForUsersNeededInKot.add(key);
      });
    } else {
//ifUserIsNonAdmin
      allUserProfiles.forEach((key, value) {
        if (value['admin'] == false) {
          phoneNameMap.addAll({key: value['username']});
          phoneNumbersListForUsersNeededInKot.add(key);
        }
      });
    }
    setState(() {});
  }

  void deleteAlertDialogBox(
      String printerID, String kotOrBillOrChefPrinter) async {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Center(
            child: Text(
          'Warning!',
          style: TextStyle(color: Colors.red),
        )),
        content: Text('${'Are you sure you want to remove this Printer?'}'),
        actions: [
          ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
              ),
              onPressed: () {
                if (kotOrBillOrChefPrinter == 'KotPrinter') {
                  kotPrinterAssigningMap.remove(printerID);
                } else if (kotOrBillOrChefPrinter == 'BillPrinter') {
                  billingPrinterAssigningMap.remove(printerID);
                } else if (kotOrBillOrChefPrinter == 'ChefPrinter') {
                  chefPrinterAssigningMap.remove(printerID);
                }
                savedPrintersAndPrinterAssigningFromProvider();
              },
              child: Text('OK')),
        ],
      ),
      barrierDismissible: false,
    );
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    savedPrintersAndPrinterAssigningFromProvider();
  }

  void addKotPrinterBottomSheetBuilder() {
    String tempSelectedKotPrinterRandomID = '';
    bool printerSelected = false;
    List<String> usersThatNeedKot = [];
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setStateSB) {
            return !printerSelected
                ? SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Center(
                            child: Text(
                          'Available Printers',
                          style: TextStyle(fontSize: 30.0),
                        )),
                        SizedBox(height: 10),
                        Column(
                          children: printersList.map((eachPrinter) {
                            bool printerNotAlreadyAssigned = true;
                            if (kotPrinterAssignedList.isNotEmpty) {
                              for (var eachPrinterFromKotPrinterAssignedList
                                  in kotPrinterAssignedList) {
//CheckingToEnsureAlreadyAssignedPrintersArentAgainAddedToTheList
                                if (eachPrinterFromKotPrinterAssignedList[
                                        'printerRandomID'] ==
                                    eachPrinter['printerRandomID']) {
                                  printerNotAlreadyAssigned = false;
                                }
                              }
                            }
                            if (printerNotAlreadyAssigned &&
                                assignMoreLanPrinterForKotPrinting &&
                                eachPrinter['printerBluetoothAddress'] ==
                                    'NA') {
//ThisMeansEvenIfPrinterIsNotAlreadyAssignedWeNeedOnlyLANPrinters,WeMakePrinterNotAlreadyAssignedFalse
//BecauseThatWayItWontGetIntoTheList
                              printerNotAlreadyAssigned = false;
                            }
                            if (printerNotAlreadyAssigned) {
                              return ListTile(
                                title: Text(eachPrinter['printerName']),
                                trailing: ElevatedButton(
                                    style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all<Color>(
                                              Colors.green),
                                    ),
                                    onPressed: () {
                                      tempSelectedKotPrinterRandomID =
                                          eachPrinter['printerRandomID'];
                                      setStateSB(() {
                                        printerSelected = true;
                                      });
                                    },
                                    child: Text('Click to Select')),
                              );
                            } else {
                              return SizedBox.shrink();
                            }
                          }).toList(),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            IconButton(
                                onPressed: () {
                                  setStateSB(() {
                                    printerSelected = false;
                                  });
                                },
                                icon: Icon(Icons.arrow_back_outlined)),
                            Center(
                                child: Text(
                              'Select Users',
                              style: TextStyle(fontSize: 30.0),
                            )),
                            SizedBox(width: 10)
                          ],
                        ),
                        SizedBox(height: 10),
                        SizedBox(
                            height: 400,
                            child: ListView.builder(
                                itemCount:
                                    phoneNumbersListForUsersNeededInKot.length,
                                itemBuilder: (context, index) {
                                  final kotPersonName = phoneNameMap[
                                      phoneNumbersListForUsersNeededInKot[
                                          index]];
                                  final kotPhoneNumberOfUser =
                                      phoneNumbersListForUsersNeededInKot[
                                          index];
                                  return ListTile(
                                    title: Text(kotPersonName!),
                                    trailing: Checkbox(
                                      value: usersThatNeedKot
                                              .contains(kotPhoneNumberOfUser)
                                          ? true
                                          : false,
                                      onChanged: (value) {
                                        setStateSB(() {
                                          if (usersThatNeedKot
                                              .contains(kotPhoneNumberOfUser)) {
                                            usersThatNeedKot
                                                .remove(kotPhoneNumberOfUser);
                                          } else {
                                            usersThatNeedKot
                                                .add(kotPhoneNumberOfUser);
                                          }
                                        });
                                      },
                                    ),
                                  );
                                })),
                        ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<Color>(
                                  Colors.green),
                            ),
                            onPressed: () {
                              kotPrinterAssigningMap.addAll({
                                tempSelectedKotPrinterRandomID: {
                                  'users': usersThatNeedKot
                                }
                              });
                              Navigator.pop(context);
                              savedPrintersAndPrinterAssigningFromProvider();
                              print(kotPrinterAssigningMap);
                            },
                            child: Text('Save Users')),
                      ],
                    ),
                  );
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kAppBarBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: kAppBarBackIconColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Printer Settings', style: kAppBarTextStyle),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PrintersSavingAndEditing()));
              },
              child: Row(
                children: [
                  Text(
                    'All Printers',
                    style: Theme.of(context).textTheme.headline6,
                  ),
                  Icon(Icons.keyboard_arrow_right)
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Text(
                'Printer Roles',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 15),
              ),
            ),
            Center(
                child: Text(
              'Billing Printer',
              style: Theme.of(context).textTheme.headline6,
            )),
            billingPrinterAssigningMap.isEmpty
                ? Container(
                    margin: EdgeInsets.fromLTRB(5, 5, 0, 0),
                    child: ListTile(
                      tileColor: Colors.grey.shade200,
                      title: Text('Tap To Assign Billing Printer'),
                    ),
                  )
                : Container(
                    margin: EdgeInsets.fromLTRB(5, 5, 0, 0),
                    child: ListTile(
                      tileColor: Colors.white54,
                      title: Text('Here we show Billing Printer'),
                    ),
                  ),
            SizedBox(
              child: ListTile(
                title: Text('KOT Printer',
                    style: Theme.of(context).textTheme.headline6,
                    textAlign: TextAlign.center),
                subtitle: Text(
                    '*More than one LAN Printer can be assigned\n*Only one Bluetooth/USB Printer can be assigned'),
              ),
            ),
            Visibility(
                visible: kotPrinterAssigningMap.isNotEmpty ? true : false,
                child: Column(
                    children: kotPrinterAssignedList
                        .map((eachKotPrinter) => Container(
                              margin: EdgeInsets.fromLTRB(5, 5, 0, 0),
                              child: ListTile(
                                tileColor: Colors.grey.shade200,
                                title: Text(eachKotPrinter['printerName']),
                                subtitle: Text(eachKotPrinter['printerType']),
                                trailing: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                        icon: Icon(Icons.edit),
                                        onPressed: () {}),
                                    IconButton(
                                        icon: Icon(Icons.delete),
                                        onPressed: () {
                                          deleteAlertDialogBox(
                                              eachKotPrinter['printerRandomID'],
                                              'KotPrinter');
                                        }),
                                  ],
                                ),
                              ),
                            ))
                        .toList())),
            Visibility(
                visible: kotPrinterAssigningMap.isEmpty ||
                        assignMoreLanPrinterForKotPrinting
                    ? true
                    : false,
                child: Container(
                  margin: EdgeInsets.fromLTRB(5, 5, 0, 0),
                  child: ListTile(
                    onTap: () {
                      if (printerSavingMap.isEmpty) {
                        show('No Printers Added Till Now');
                      } else if (kotPrinterAssigningMap.length ==
                          printerSavingMap.length) {
                        show('No Other Printers Found');
                      } else {
                        addKotPrinterBottomSheetBuilder();
                      }
                    },
                    tileColor: Colors.grey.shade200,
                    title: assignMoreLanPrinterForKotPrinting
                        ? Text('Tap To Add Another LAN Printer')
                        : Text('Tap To Assign a KOT Printer'),
                  ),
                )),
            Center(
                child: Text(
              'Chef Printer',
              style: Theme.of(context).textTheme.headline6,
            )),
          ],
        ),
      ),
    );
  }
}
