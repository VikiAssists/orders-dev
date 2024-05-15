import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:orders_dev/Screens/printers_adding_saving_1.dart';
import 'package:orders_dev/constants.dart';
import 'package:orders_dev/services/firestore_services.dart';
import 'package:provider/provider.dart';

class PrinterRolesAssigning extends StatefulWidget {
  const PrinterRolesAssigning({Key? key}) : super(key: key);

  @override
  State<PrinterRolesAssigning> createState() => _PrinterRolesAssigningState();
}

class _PrinterRolesAssigningState extends State<PrinterRolesAssigning> {
  Map<String, dynamic> kotPrinterAssigningMap = HashMap();
  Map<String, dynamic> billingPrinterAssigningMap = HashMap();
  Map<String, dynamic> chefPrinterAssigningMap = HashMap();
  List<Map<String, dynamic>> kotPrinterAssignedList = [];
  String billingPrinterRandomID = '';
  String chefPrinterRandomID = '';
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
      if (Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .kotAssignedPrintersFromClass !=
          '{}') {
        kotPrinterAssigningMap = json.decode(
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .kotAssignedPrintersFromClass);
      }
      if (Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .billingAssignedPrinterFromClass !=
          '{}') {
        billingPrinterAssigningMap = json.decode(
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .billingAssignedPrinterFromClass);
        if (billingPrinterAssigningMap.isNotEmpty) {
          billingPrinterAssigningMap.forEach((key, value) {
            billingPrinterRandomID = key;
          });
        }
      }

      if (Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .chefAssignedPrinterFromClass !=
          '{}') {
        chefPrinterAssigningMap = json.decode(
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .chefAssignedPrinterFromClass);
        if (chefPrinterAssigningMap.isNotEmpty) {
          chefPrinterAssigningMap.forEach((key, value) {
            chefPrinterRandomID = key;
          });
        }
      }

      printersList = [];
      kotPrinterAssignedList = [];
      listOfLanPrintersAmongPrintersSaved = [];

      assignMoreLanPrinterForKotPrinting = false;
      printerSavingMap.forEach((key, value) {
        printersList.add(value);
        if (value['printerIPAddress'] != 'NA') {
          listOfLanPrintersAmongPrintersSaved.add(key);
        }
        if (kotPrinterAssigningMap.isNotEmpty) {
          kotPrinterAssigningMap.forEach((kotPrinterKey, kotPrinterValue) {
//ThisWillHelpToHaveAllTheInfoAboutThePrinterInKotPrinterAssignedList
//WhenWeAreMakingListOfPrintersForAdding,ThisListWillHelpToEliminateTheOnes
//ThatHaveAlreadyBeenAdded
            if (key == kotPrinterKey) {
              if (value['printerIPAddress'] != 'NA') {
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
    phoneNumbersListForUsersNeededInKot = [];

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

  void assignKotPrinterBottomSheetBuilder() {
    String tempSelectedKotPrinterRandomID = '';
    bool printerSelected = false;
    Map<String, dynamic> usersThatNeedKotAsMap = HashMap();
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
                                eachPrinter['printerIPAddress'] == 'NA') {
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
                                      value: usersThatNeedKotAsMap
                                              .containsKey(kotPhoneNumberOfUser)
                                          ? true
                                          : false,
                                      onChanged: (value) {
                                        setStateSB(() {
                                          if (usersThatNeedKotAsMap.containsKey(
                                              kotPhoneNumberOfUser)) {
                                            usersThatNeedKotAsMap
                                                .remove(kotPhoneNumberOfUser);
                                          } else {
                                            usersThatNeedKotAsMap.addAll({
                                              kotPhoneNumberOfUser: {
                                                'copies': 1
                                              }
                                            });
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
                                  'users': usersThatNeedKotAsMap
                                }
                              });
                              Navigator.pop(context);
                              Provider.of<PrinterAndOtherDetailsProvider>(
                                      context,
                                      listen: false)
                                  .savingKotAssignedPrinterByTheUser(
                                      json.encode(kotPrinterAssigningMap));
                              savedPrintersAndPrinterAssigningFromProvider();
//SavingKotAssignedMapInServer
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
                                      printerMapKey: 'kotPrinterAssigningMap',
                                      printerMapValue:
                                          json.encode(kotPrinterAssigningMap))
                                  .updatePrinterInfo();
                            },
                            child: Text('Save Users')),
                      ],
                    ),
                  );
          });
        });
  }

  void assignBillingPrinterBottomSheetBuilder() {
    String tempSelectedKotPrinterRandomID = '';
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setStateSB) {
            return SingleChildScrollView(
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
                      children: printersList
                          .map((eachPrinter) => ListTile(
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
                                      billingPrinterAssigningMap.addAll({
                                        eachPrinter['printerRandomID']: {
                                          'assigned': true,
                                          'copies': 1
                                        }
                                      });
                                      Provider.of<PrinterAndOtherDetailsProvider>(
                                              context,
                                              listen: false)
                                          .savingBillingAssignedPrinterByTheUser(
                                              json.encode(
                                                  billingPrinterAssigningMap));
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
                                                  'billingPrinterAssigningMap',
                                              printerMapValue: json.encode(
                                                  billingPrinterAssigningMap))
                                          .updatePrinterInfo();
//justMakingAMapSoThatInFutureICanUseInCaseNewPurposesPopsUpForThis
                                      savedPrintersAndPrinterAssigningFromProvider();
                                      Navigator.pop(context);
                                    },
                                    child: Text('Click to Assign')),
                              ))
                          .toList()),
                ],
              ),
            );
          });
        });
  }

  void assignChefPrinterBottomSheetBuilder() {
    String tempSelectedKotPrinterRandomID = '';
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setStateSB) {
            return SingleChildScrollView(
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
                      children: printersList
                          .map((eachPrinter) => ListTile(
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
                                      chefPrinterAssigningMap.addAll({
                                        eachPrinter['printerRandomID']: {
                                          'assigned': true,
                                          'copies': 1
                                        }
                                      });
                                      Provider.of<PrinterAndOtherDetailsProvider>(
                                              context,
                                              listen: false)
                                          .savingChefAssignedPrinterByTheUser(
                                              json.encode(
                                                  chefPrinterAssigningMap));
//justMakingAMapSoThatInFutureICanUseInCaseNewPurposesPopsUpForThis
                                      savedPrintersAndPrinterAssigningFromProvider();
//SavingChefAssignedMapInServer
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
                                                  'chefPrinterAssigningMap',
                                              printerMapValue: json.encode(
                                                  chefPrinterAssigningMap))
                                          .updatePrinterInfo();
                                      Navigator.pop(context);
                                    },
                                    child: Text('Click to Assign')),
                              ))
                          .toList()),
                ],
              ),
            );
          });
        });
  }

  void editKotPrinterUsersBottomSheetBuilder(String clickedPrinterID,
      Map<String, dynamic> alreadySelectedUsersOfKotPrinter) {
    String tempSelectedKotPrinterRandomID = clickedPrinterID;
    Map<String, dynamic> tempMapOfUsersThatNeedKot =
        alreadySelectedUsersOfKotPrinter;
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setStateSB) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                      child: Text(
                    'Select Users',
                    style: TextStyle(fontSize: 30.0),
                  )),
                  SizedBox(height: 10),
                  SizedBox(
                      height: 400,
                      child: ListView.builder(
                          itemCount: phoneNumbersListForUsersNeededInKot.length,
                          itemBuilder: (context, index) {
                            final kotPersonName = phoneNameMap[
                                phoneNumbersListForUsersNeededInKot[index]];
                            final kotPhoneNumberOfUser =
                                phoneNumbersListForUsersNeededInKot[index];
                            return ListTile(
                              title: Text(kotPersonName!),
                              trailing: Checkbox(
                                value: tempMapOfUsersThatNeedKot
                                        .containsKey(kotPhoneNumberOfUser)
                                    ? true
                                    : false,
                                onChanged: (value) {
                                  setStateSB(() {
                                    if (tempMapOfUsersThatNeedKot
                                        .containsKey(kotPhoneNumberOfUser)) {
                                      tempMapOfUsersThatNeedKot
                                          .remove(kotPhoneNumberOfUser);
                                    } else {
                                      tempMapOfUsersThatNeedKot.addAll({
                                        kotPhoneNumberOfUser: {'copies': 1}
                                      });
                                    }
                                  });
                                },
                              ),
                            );
                          })),
                  ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.green),
                      ),
                      onPressed: () {
                        kotPrinterAssigningMap
                            .remove(tempSelectedKotPrinterRandomID);
                        kotPrinterAssigningMap.addAll({
                          tempSelectedKotPrinterRandomID: {
                            'users': tempMapOfUsersThatNeedKot
                          }
                        });
                        Navigator.pop(context);
                        Provider.of<PrinterAndOtherDetailsProvider>(context,
                                listen: false)
                            .savingKotAssignedPrinterByTheUser(
                                json.encode(kotPrinterAssigningMap));
                        savedPrintersAndPrinterAssigningFromProvider();
                        //SavingKotAssignedMapInServer
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
                      },
                      child: Text('Save Users')),
                ],
              ),
            );
          });
        });
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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
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
              SizedBox(width: 20),
              ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.green),
                  ),
                  onPressed: () {
                    if (kotOrBillOrChefPrinter == 'KotPrinter') {
                      kotPrinterAssigningMap.remove(printerID);
                      Provider.of<PrinterAndOtherDetailsProvider>(context,
                              listen: false)
                          .savingKotAssignedPrinterByTheUser(
                              json.encode(kotPrinterAssigningMap));
                      //SavingKotAssignedMapInServer
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
                    } else if (kotOrBillOrChefPrinter == 'BillPrinter') {
                      billingPrinterAssigningMap.remove(printerID);
                      Provider.of<PrinterAndOtherDetailsProvider>(context,
                              listen: false)
                          .savingBillingAssignedPrinterByTheUser(
                              json.encode(billingPrinterAssigningMap));
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
                    } else if (kotOrBillOrChefPrinter == 'ChefPrinter') {
                      chefPrinterAssigningMap.remove(printerID);
                      Provider.of<PrinterAndOtherDetailsProvider>(context,
                              listen: false)
                          .savingChefAssignedPrinterByTheUser(
                              json.encode(chefPrinterAssigningMap));
                      //SavingChefAssignedMapInServer
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
                    savedPrintersAndPrinterAssigningFromProvider();
                    Navigator.pop(context);
                  },
                  child: Text('OK')),
            ],
          ),
        ],
      ),
      barrierDismissible: false,
    );
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.fromLTRB(5, 5, 0, 0),
                child: ListTile(
                  tileColor: Colors.grey.shade200,
                  title: Padding(
                    padding: const EdgeInsets.fromLTRB(60, 0, 60, 0),
                    child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all<Color>(Colors.green),
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      PrintersAddingSavingAndEditing()));
                        },
                        child: Text('Add/Edit all Printers')),
                  ),
                ),
              ),
              Divider(thickness: 2),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Text(
                  'Assign Printer Roles',
                  style: Theme.of(context).textTheme.headline6,
                ),
              ),
              Center(
                  child: Text(
                'Billing Printer',
                style: Theme.of(context).textTheme.headline5,
              )),
              billingPrinterAssigningMap.isEmpty
                  ? Container(
                      margin: EdgeInsets.fromLTRB(5, 5, 0, 0),
                      child: ListTile(
                        tileColor: Colors.grey.shade200,
                        title: Padding(
                          padding: const EdgeInsets.fromLTRB(60, 0, 60, 0),
                          child: ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Colors.green),
                              ),
                              onPressed: () {
                                if (printerSavingMap.isEmpty) {
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              PrintersAddingSavingAndEditing()));
                                } else {
                                  assignBillingPrinterBottomSheetBuilder();
                                }
                              },
                              child: Text('Click to Assign')),
                        ),
                      ),
                    )
                  : Container(
                      margin: EdgeInsets.fromLTRB(5, 5, 0, 0),
                      child: ListTile(
                        tileColor: Colors.grey.shade200,
                        title: Text(printerSavingMap[billingPrinterRandomID]
                            ['printerName']),
                        subtitle: Text(printerSavingMap[billingPrinterRandomID]
                            ['printerType']),
                        trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              deleteAlertDialogBox(
                                  billingPrinterRandomID, 'BillPrinter');
                            }),
                      ),
                    ),
              SizedBox(
                child: ListTile(
                  title: Text('KOT Printer',
                      style: Theme.of(context).textTheme.headline5,
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
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      IconButton(
                                          icon: Icon(Icons.account_circle),
                                          onPressed: () {
                                            editKotPrinterUsersBottomSheetBuilder(
                                                eachKotPrinter[
                                                    'printerRandomID'],
                                                eachKotPrinter['users']);
                                          }),
                                      IconButton(
                                          icon: Icon(Icons.delete),
                                          onPressed: () {
                                            deleteAlertDialogBox(
                                                eachKotPrinter[
                                                    'printerRandomID'],
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
                          tileColor: Colors.grey.shade200,
                          title: Padding(
                            padding: assignMoreLanPrinterForKotPrinting
                                ? const EdgeInsets.fromLTRB(40, 0, 40, 0)
                                : const EdgeInsets.fromLTRB(60, 0, 60, 0),
                            child: ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Colors.green),
                              ),
                              onPressed: () {
                                if (printerSavingMap.isEmpty) {
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              PrintersAddingSavingAndEditing()));
                                } else if (kotPrinterAssigningMap.length ==
                                    printerSavingMap.length) {
                                  show('No Other Printers Found');
                                } else {
                                  assignKotPrinterBottomSheetBuilder();
                                }
                              },
                              child: assignMoreLanPrinterForKotPrinting
                                  ? Text('Assign One More LAN Printer')
                                  : Text('Click To Assign'),
                            ),
                          )))),
              SizedBox(
                child: ListTile(
                  title: Text('Chef Printer',
                      style: Theme.of(context).textTheme.headline5,
                      textAlign: TextAlign.center),
                  subtitle: Text(
                      'Will be used only for Printing Purposes in Chef Screen'),
                ),
              ),
              chefPrinterAssigningMap.isEmpty
                  ? Container(
                      margin: EdgeInsets.fromLTRB(5, 0, 0, 0),
                      child: ListTile(
                        tileColor: Colors.grey.shade200,
                        title: Padding(
                          padding: const EdgeInsets.fromLTRB(60, 0, 60, 0),
                          child: ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Colors.green),
                              ),
                              onPressed: () {
                                if (printerSavingMap.isEmpty) {
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              PrintersAddingSavingAndEditing()));
                                } else {
                                  assignChefPrinterBottomSheetBuilder();
                                }
                              },
                              child: Text('Click to Assign')),
                        ),
                      ),
                    )
                  : Container(
                      margin: EdgeInsets.fromLTRB(5, 0, 0, 0),
                      child: ListTile(
                        tileColor: Colors.grey.shade200,
                        title: Text(printerSavingMap[chefPrinterRandomID]
                            ['printerName']),
                        subtitle: Text(printerSavingMap[chefPrinterRandomID]
                            ['printerType']),
                        trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              deleteAlertDialogBox(
                                  chefPrinterRandomID, 'ChefPrinter');
                            }),
                      ),
                    ),
              Container(
                margin: EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: ListTile(
                  tileColor: Colors.grey.shade200,
                  title: Text('Chef KOT Print'),
                  subtitle:
                      Text('Orders will be auto-accepted when chef KOT is On'),
                  trailing: Switch(
                    // This bool value toggles the switch.
                    value: Provider.of<PrinterAndOtherDetailsProvider>(context)
                        .chefPrinterKOTFromClass,
                    activeColor: Colors.green,
                    onChanged: (bool changedValue) {
                      // This is called when the user toggles the switch.
                      Provider.of<PrinterAndOtherDetailsProvider>(context,
                              listen: false)
                          .neededOrNotChefKot(changedValue);
                    },
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: ListTile(
                  tileColor: Colors.grey.shade200,
                  title: Text('Delivery Slip Print'),
                  trailing: Switch(
                    // This bool value toggles the switch.
                    value: Provider.of<PrinterAndOtherDetailsProvider>(context)
                        .chefPrinterAfterOrderReadyPrintFromClass,
                    activeColor: Colors.green,
                    onChanged: (bool changedValue) {
                      // This is called when the user toggles the switch.

                      Provider.of<PrinterAndOtherDetailsProvider>(context,
                              listen: false)
                          .neededOrNotChefAfterOrderReadyPrint(changedValue);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
