import 'dart:collection';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:orders_dev/Providers/notification_provider.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:orders_dev/constants.dart';
import 'package:orders_dev/services/background_services.dart';
import 'package:orders_dev/services/firestore_services.dart';
import 'package:orders_dev/services/notification_service.dart';
import 'package:provider/provider.dart';

class UserProfilesWithEdit extends StatefulWidget {
  final String hotelName;
  final Map<String, dynamic> currentUserProfileMap;
  const UserProfilesWithEdit(
      {Key? key, required this.hotelName, required this.currentUserProfileMap})
      : super(key: key);

  @override
  State<UserProfilesWithEdit> createState() => _UserProfilesWithEditState();
}

class _UserProfilesWithEditState extends State<UserProfilesWithEdit> {
  final _fireStore = FirebaseFirestore.instance;
  List<dynamic> tempListOfRestaurantsOfUser = [];
  List<String> listOfPhoneNumbersWithThatRestaurant = [];
//ThisIsTheRestaurantNameWeShowToTheUsers
  String tempRestaurantName = '';
  String tempUserName = '';
  String tempUserPhoneNumber = '';
  bool tempOwnerOrNot = false;
  bool tempStatisticsAccess = false;
  bool tempCompleteOrderHistory = false;
  bool tempUserProfileManagement = false;
  bool tempChefSpecialitiesAccess = false;
  bool tempItemsAvailabilityAccess = false;
  bool tempRestaurantInfoEdit = false;
  bool tempIndividualKOTPrintNeededTrueElseFalse = false;

  @override
  Widget build(BuildContext context) {
    final fcmProvider = Provider.of<NotificationProvider>(context);

    void errorAlertDialogBox(String errorMessage) async {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Center(
              child: Text(
            'Error!',
            style: TextStyle(color: Colors.red),
          )),
          content: Text(errorMessage),
          actions: [
            ElevatedButton(
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.green),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Ok')),
          ],
        ),
        barrierDismissible: false,
      );
    }

    //ToConvertDynamicListToStringList
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

    void deleteUserAlertDialogBox() async {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Center(
              child: Text(
            'DELETE WARNING!',
            style: TextStyle(color: Colors.red),
          )),
          content: Text('${tempUserName} will be deleted'),
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
                      if (tempListOfRestaurantsOfUser.length == 1) {
//ThisMeansTheUserDoesntBelongToAnyRestaurantAndCanBeCompletelyDeleted
                        FireStoreDeleteUserCompletely(
                                restaurantDatabaseName: widget.hotelName,
                                userPhoneNumber: tempUserPhoneNumber)
                            .deleteUserCompletely();
                      } else {
//HeHasMultipleRestaurantsAndIsOnlyGettingRemovedFromOneRestaurant
                        FireStoreDeleteUserFromOneRestaurant(
                                userPhoneNumber: tempUserPhoneNumber,
                                restaurantDatabaseName: widget.hotelName)
                            .deleteUserFromOneRestaurant();
                      }

                      Map<String, dynamic> allUsersTokenMap = json.decode(
                          Provider.of<PrinterAndOtherDetailsProvider>(context,
                                  listen: false)
                              .allUserTokensFromClass);
                      fcmProvider.sendNotification(
                          token: [
                            allUsersTokenMap[tempUserPhoneNumber].toString()
                          ],
                          title: widget.hotelName,
                          restaurantNameForNotification: json.decode(Provider
                                          .of<PrinterAndOtherDetailsProvider>(
                                              context,
                                              listen: false)
                                      .allUserProfilesFromClass)[
                                  Provider.of<PrinterAndOtherDetailsProvider>(
                                          context,
                                          listen: false)
                                      .currentUserPhoneNumberFromClass]
                              ['restaurantName'],
                          body: '*userDeleted*');
                      fcmProvider.sendNotification(
                          token: dynamicTokensToStringToken(),
                          title: widget.hotelName,
                          restaurantNameForNotification: json.decode(Provider
                                          .of<PrinterAndOtherDetailsProvider>(
                                              context,
                                              listen: false)
                                      .allUserProfilesFromClass)[
                                  Provider.of<PrinterAndOtherDetailsProvider>(
                                          context,
                                          listen: false)
                                      .currentUserPhoneNumberFromClass]
                              ['restaurantName'],
                          body: '*userProfileEdited*');
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

    void adminCreateUserProfileBottomSheet(context) {
      bool tempAdmin = false;
      tempUserPhoneNumber = '';
      tempUserName = '';
      tempOwnerOrNot = false;
      tempStatisticsAccess = true;
      tempCompleteOrderHistory = true;
      tempUserProfileManagement = true;
      tempChefSpecialitiesAccess = true;
      tempItemsAvailabilityAccess = true;
      tempRestaurantInfoEdit = true;
      tempIndividualKOTPrintNeededTrueElseFalse = false;

      showModalBottomSheet(
          isScrollControlled: true,
          context: context,
          builder: (BuildContext buildContext) {
            return StatefulBuilder(builder: (context, setStateSB) {
              return Padding(
                padding: EdgeInsets.only(
                    top: 20, bottom: MediaQuery.of(context).viewInsets.bottom),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 10),
                      Center(
                        child: Text(
                          'Add User',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 30),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                        child: Text('Customer name',
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.green)),
                      ),
                      Container(
                        padding: EdgeInsets.all(10),
                        child: TextField(
                          maxLength: 100,
                          controller: TextEditingController(text: tempUserName),
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (value) {
                            tempUserName = value;
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
                                      borderSide:
                                          BorderSide(color: Colors.green)),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(10)),
                                      borderSide:
                                          BorderSide(color: Colors.green))),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                        child: Text('Mobile Number', style: userInfoTextStyle),
                      ),
                      Container(
                          padding: EdgeInsets.all(20),
                          // height: 55,
                          // decoration: BoxDecoration(
                          //   borderRadius: BorderRadius.circular(50.0),
                          //   border: Border.all(width: 1, color: Colors.green),
                          // ),
                          child: IntlPhoneField(
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50.0),
                                borderSide:
                                    BorderSide(width: 1, color: Colors.green),
                              ),
                            ),
                            initialCountryCode: 'IN',
                            onChanged: (phone) {
                              tempUserPhoneNumber = phone.completeNumber;
                              // print(phone.completeNumber);
                            },
                          )
                          // Row(
                          //   children: [
                          //     SizedBox(width: 10),
                          //     SizedBox(width: 40, child: Text('+91')),
                          //     Text('|',
                          //         style: TextStyle(
                          //             fontSize: 33, color: Colors.green)),
                          //     SizedBox(width: 10),
                          //     Expanded(
                          //       child: TextField(
                          //         controller: _phoneNumberController,
                          //         keyboardType: TextInputType.number,
                          //         inputFormatters: [
                          //           FilteringTextInputFormatter.digitsOnly
                          //         ],
                          //         onChanged: (value) {
                          //           phoneNumber = value;
                          //         },
                          //         style: TextStyle(color: Colors.black),
                          //         decoration: InputDecoration(
                          //             border: InputBorder.none,
                          //             hintText: 'Enter Phone Number'),
                          //       ),
                          //     ),
                          //   ],
                          // ),
                          ),
                      ListTile(
                        title: Text('Orders App Admin'),
                        trailing: Switch(
                          activeColor: Colors.green,
                          value: tempAdmin,
                          onChanged: (bool changedValue) {
                            setStateSB(() {
                              tempAdmin = changedValue;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('Owner Login'),
                        trailing: Switch(
                          activeColor: Colors.green,
                          value: tempOwnerOrNot,
                          onChanged: (bool changedValue) {
                            setStateSB(() {
                              tempOwnerOrNot = changedValue;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('Statistics Access'),
                        trailing: Switch(
                          activeColor: Colors.green,
                          value: tempStatisticsAccess,
                          onChanged: (bool changedValue) {
                            setStateSB(() {
                              tempStatisticsAccess = changedValue;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('Complete Order History'),
                        trailing: Switch(
                          activeColor: Colors.green,
                          value: tempCompleteOrderHistory,
                          onChanged: (bool changedValue) {
                            setStateSB(() {
                              tempCompleteOrderHistory = changedValue;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('User Profile Management'),
                        trailing: Switch(
                          activeColor: Colors.green,
                          value: tempUserProfileManagement,
                          onChanged: (bool changedValue) {
                            setStateSB(() {
                              tempUserProfileManagement = changedValue;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('Chef Specialities Access'),
                        trailing: Switch(
                          activeColor: Colors.green,
                          value: tempChefSpecialitiesAccess,
                          onChanged: (bool changedValue) {
                            setStateSB(() {
                              tempChefSpecialitiesAccess = changedValue;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('Items Availability Access'),
                        trailing: Switch(
                          activeColor: Colors.green,
                          value: tempItemsAvailabilityAccess,
                          onChanged: (bool changedValue) {
                            setStateSB(() {
                              tempItemsAvailabilityAccess = changedValue;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('Restaurant Info Edit Access'),
//IfTheyDontHaveThisAccess,OnlyKOTCanBeGivenByTheCaptain
                        trailing: Switch(
                          activeColor: Colors.green,
                          value: tempRestaurantInfoEdit,
                          onChanged: (bool changedValue) {
                            setStateSB(() {
                              tempRestaurantInfoEdit = changedValue;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('Individual KOT Print'),
//IfTheyDontHaveThisAccess,OnlyKOTCanBeGivenByTheCaptain
                        trailing: Switch(
                          activeColor: Colors.green,
                          value: tempIndividualKOTPrintNeededTrueElseFalse,
                          onChanged: (bool changedValue) {
                            setStateSB(() {
                              tempIndividualKOTPrintNeededTrueElseFalse =
                                  changedValue;
                            });
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Colors.green),
                              ),
                              onPressed: () {
                                if (tempUserName == '') {
                                  errorAlertDialogBox('Please enter Username');
                                } else if (tempUserPhoneNumber == '') {
                                  errorAlertDialogBox(
                                      'Please enter User Phone Number');
                                } else if (listOfPhoneNumbersWithThatRestaurant
                                    .contains(tempUserPhoneNumber)) {
                                  errorAlertDialogBox(
                                      'User Phone Number Already Exists');
                                } else {
                                  Map<String, dynamic> updateUserMap =
                                      HashMap();
                                  updateUserMap
                                      .addAll({'username': tempUserName});
                                  updateUserMap.addAll(
                                      {'restaurantName': tempRestaurantName});
                                  updateUserMap.addAll({'admin': tempAdmin});
                                  updateUserMap.addAll({'wontCook': []});
                                  Map<String, bool> updatePrivilegesMap =
                                      HashMap();
                                  updatePrivilegesMap
                                      .addAll({'1': tempOwnerOrNot});
                                  updatePrivilegesMap
                                      .addAll({'2': tempStatisticsAccess});
                                  updatePrivilegesMap
                                      .addAll({'3': tempCompleteOrderHistory});
                                  updatePrivilegesMap
                                      .addAll({'4': tempUserProfileManagement});

                                  updatePrivilegesMap.addAll(
                                      {'5': tempChefSpecialitiesAccess});
                                  updatePrivilegesMap.addAll(
                                      {'6': tempItemsAvailabilityAccess});

                                  updatePrivilegesMap
                                      .addAll({'7': tempRestaurantInfoEdit});
                                  updatePrivilegesMap.addAll({
                                    '8':
                                        tempIndividualKOTPrintNeededTrueElseFalse
                                  });
                                  updatePrivilegesMap.addAll({'9': true});
                                  updatePrivilegesMap.addAll({'10': true});
                                  updatePrivilegesMap.addAll({'11': true});
                                  updatePrivilegesMap.addAll({'12': true});
                                  updatePrivilegesMap.addAll({'13': true});
                                  updatePrivilegesMap.addAll({'14': true});
                                  updatePrivilegesMap.addAll({'15': true});
                                  updatePrivilegesMap.addAll({'16': true});
                                  updatePrivilegesMap.addAll({'17': true});

                                  updatePrivilegesMap.addAll({'18': true});
                                  updatePrivilegesMap.addAll({'19': true});
                                  updatePrivilegesMap.addAll({'20': true});
                                  updatePrivilegesMap.addAll({'21': true});
                                  updatePrivilegesMap.addAll({'22': true});
                                  updatePrivilegesMap.addAll({'23': true});
                                  updatePrivilegesMap.addAll({'24': true});
                                  updatePrivilegesMap.addAll({'25': true});
                                  updatePrivilegesMap.addAll({'26': true});
                                  updatePrivilegesMap.addAll({'27': true});
                                  updatePrivilegesMap.addAll({'28': true});
                                  updatePrivilegesMap.addAll({'29': true});
                                  updatePrivilegesMap.addAll({'30': true});
                                  updateUserMap.addAll(
                                      {'privileges': updatePrivilegesMap});
                                  FireStoreAddUserProfile(
                                          userPhoneNumber: tempUserPhoneNumber,
                                          hotelName: widget.hotelName,
                                          updateUserProfileMap: updateUserMap)
                                      .addUserProfile();
                                  fcmProvider.sendNotification(
                                      token: dynamicTokensToStringToken(),
                                      title: widget.hotelName,
                                      restaurantNameForNotification: json.decode(Provider
                                                  .of<PrinterAndOtherDetailsProvider>(
                                                      context,
                                                      listen: false)
                                              .allUserProfilesFromClass)[Provider
                                                  .of<PrinterAndOtherDetailsProvider>(
                                                      context,
                                                      listen: false)
                                              .currentUserPhoneNumberFromClass]
                                          ['restaurantName'],
                                      body: '*userProfileEdited*');
                                  Navigator.pop(context);
                                }
                              },
                              child: Text('Add User'))
                        ],
                      )
                    ],
                  ),
                ),
              );
            });
          });
    }

    void nonAdminCreateUserProfileBottomSheet(context) {
      tempUserPhoneNumber = '';
      tempUserName = '';
      tempOwnerOrNot = false;
      tempStatisticsAccess = true;
      tempCompleteOrderHistory = true;
      tempUserProfileManagement = true;
      tempChefSpecialitiesAccess = true;
      tempItemsAvailabilityAccess = true;
      tempRestaurantInfoEdit = true;
      tempIndividualKOTPrintNeededTrueElseFalse = false;

      showModalBottomSheet(
          isScrollControlled: true,
          context: context,
          builder: (BuildContext buildContext) {
            return StatefulBuilder(builder: (context, setStateSB) {
              return Padding(
                padding: EdgeInsets.only(
                    top: 20, bottom: MediaQuery.of(context).viewInsets.bottom),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 10),
                      Center(
                        child: Text(
                          'Add User',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 30),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                        child: Text('Customer name',
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.green)),
                      ),
                      Container(
                        padding: EdgeInsets.all(10),
                        child: TextField(
                          maxLength: 100,
                          controller: TextEditingController(text: tempUserName),
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (value) {
                            tempUserName = value;
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
                                      borderSide:
                                          BorderSide(color: Colors.green)),
                                  focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(10)),
                                      borderSide:
                                          BorderSide(color: Colors.green))),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                        child: Text('Mobile Number', style: userInfoTextStyle),
                      ),
                      Container(
                          padding: EdgeInsets.all(20),
                          // height: 55,
                          // decoration: BoxDecoration(
                          //   borderRadius: BorderRadius.circular(50.0),
                          //   border: Border.all(width: 1, color: Colors.green),
                          // ),
                          child: IntlPhoneField(
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(50.0),
                                borderSide:
                                    BorderSide(width: 1, color: Colors.green),
                              ),
                            ),
                            initialCountryCode: 'IN',
                            onChanged: (phone) {
                              tempUserPhoneNumber = phone.completeNumber;
                              // print(phone.completeNumber);
                            },
                          )
                          // Row(
                          //   children: [
                          //     SizedBox(width: 10),
                          //     SizedBox(width: 40, child: Text('+91')),
                          //     Text('|',
                          //         style: TextStyle(
                          //             fontSize: 33, color: Colors.green)),
                          //     SizedBox(width: 10),
                          //     Expanded(
                          //       child: TextField(
                          //         controller: _phoneNumberController,
                          //         keyboardType: TextInputType.number,
                          //         inputFormatters: [
                          //           FilteringTextInputFormatter.digitsOnly
                          //         ],
                          //         onChanged: (value) {
                          //           phoneNumber = value;
                          //         },
                          //         style: TextStyle(color: Colors.black),
                          //         decoration: InputDecoration(
                          //             border: InputBorder.none,
                          //             hintText: 'Enter Phone Number'),
                          //       ),
                          //     ),
                          //   ],
                          // ),
                          ),
                      ListTile(
                        title: Text('Statistics Access'),
                        trailing: Switch(
                          activeColor: Colors.green,
                          value: tempStatisticsAccess,
                          onChanged: (bool changedValue) {
                            setStateSB(() {
                              tempStatisticsAccess = changedValue;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('Complete Order History'),
                        trailing: Switch(
                          activeColor: Colors.green,
                          value: tempCompleteOrderHistory,
                          onChanged: (bool changedValue) {
                            setStateSB(() {
                              tempCompleteOrderHistory = changedValue;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('User Profile Management'),
                        trailing: Switch(
                          activeColor: Colors.green,
                          value: tempUserProfileManagement,
                          onChanged: (bool changedValue) {
                            setStateSB(() {
                              tempUserProfileManagement = changedValue;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('Chef Specialities Access'),
                        trailing: Switch(
                          activeColor: Colors.green,
                          value: tempChefSpecialitiesAccess,
                          onChanged: (bool changedValue) {
                            setStateSB(() {
                              tempChefSpecialitiesAccess = changedValue;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('Items Availability Access'),
                        trailing: Switch(
                          activeColor: Colors.green,
                          value: tempItemsAvailabilityAccess,
                          onChanged: (bool changedValue) {
                            setStateSB(() {
                              tempItemsAvailabilityAccess = changedValue;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('Restaurant Info Edit Access'),
//IfTheyDontHaveThisAccess,OnlyKOTCanBeGivenByTheCaptain
                        trailing: Switch(
                          activeColor: Colors.green,
                          value: tempRestaurantInfoEdit,
                          onChanged: (bool changedValue) {
                            setStateSB(() {
                              tempRestaurantInfoEdit = changedValue;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('Individual KOT Print'),
//IfTheyDontHaveThisAccess,OnlyKOTCanBeGivenByTheCaptain
                        trailing: Switch(
                          activeColor: Colors.green,
                          value: tempIndividualKOTPrintNeededTrueElseFalse,
                          onChanged: (bool changedValue) {
                            setStateSB(() {
                              tempIndividualKOTPrintNeededTrueElseFalse =
                                  changedValue;
                            });
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Colors.green),
                              ),
                              onPressed: () {
                                if (tempUserName == '') {
                                  errorAlertDialogBox('Please enter Username');
                                } else if (tempUserPhoneNumber == '') {
                                  errorAlertDialogBox(
                                      'Please enter User Phone Number');
                                } else if (listOfPhoneNumbersWithThatRestaurant
                                    .contains(tempUserPhoneNumber)) {
                                  errorAlertDialogBox(
                                      'User Phone Number Already Exists');
                                } else {
                                  Map<String, dynamic> updateUserMap =
                                      HashMap();
                                  updateUserMap
                                      .addAll({'username': tempUserName});
                                  updateUserMap.addAll(
                                      {'restaurantName': tempRestaurantName});
                                  updateUserMap.addAll({'admin': false});
                                  updateUserMap.addAll({'wontCook': []});
                                  Map<String, bool> updatePrivilegesMap =
                                      HashMap();
                                  updatePrivilegesMap
                                      .addAll({'1': tempOwnerOrNot});
                                  updatePrivilegesMap
                                      .addAll({'2': tempStatisticsAccess});
                                  updatePrivilegesMap
                                      .addAll({'3': tempCompleteOrderHistory});

                                  updatePrivilegesMap
                                      .addAll({'4': tempUserProfileManagement});

                                  updatePrivilegesMap.addAll(
                                      {'5': tempChefSpecialitiesAccess});
                                  updatePrivilegesMap.addAll(
                                      {'6': tempItemsAvailabilityAccess});
                                  updatePrivilegesMap
                                      .addAll({'7': tempRestaurantInfoEdit});
                                  updatePrivilegesMap.addAll({
                                    '8':
                                        tempIndividualKOTPrintNeededTrueElseFalse
                                  });
                                  updatePrivilegesMap.addAll({'9': true});
                                  updatePrivilegesMap.addAll({'10': true});
                                  updatePrivilegesMap.addAll({'11': true});
                                  updatePrivilegesMap.addAll({'12': true});
                                  updatePrivilegesMap.addAll({'13': true});
                                  updatePrivilegesMap.addAll({'14': true});
                                  updatePrivilegesMap.addAll({'15': true});
                                  updatePrivilegesMap.addAll({'16': true});
                                  updatePrivilegesMap.addAll({'17': true});

                                  updatePrivilegesMap.addAll({'18': true});
                                  updatePrivilegesMap.addAll({'19': true});
                                  updatePrivilegesMap.addAll({'20': true});
                                  updatePrivilegesMap.addAll({'21': true});
                                  updatePrivilegesMap.addAll({'22': true});
                                  updatePrivilegesMap.addAll({'23': true});
                                  updatePrivilegesMap.addAll({'24': true});
                                  updatePrivilegesMap.addAll({'25': true});
                                  updatePrivilegesMap.addAll({'26': true});
                                  updatePrivilegesMap.addAll({'27': true});
                                  updatePrivilegesMap.addAll({'28': true});
                                  updatePrivilegesMap.addAll({'29': true});
                                  updatePrivilegesMap.addAll({'30': true});
                                  updateUserMap.addAll(
                                      {'privileges': updatePrivilegesMap});
                                  FireStoreAddUserProfile(
                                          userPhoneNumber: tempUserPhoneNumber,
                                          hotelName: widget.hotelName,
                                          updateUserProfileMap: updateUserMap)
                                      .addUserProfile();
                                  fcmProvider.sendNotification(
                                      token: dynamicTokensToStringToken(),
                                      title: widget.hotelName,
                                      restaurantNameForNotification: json.decode(Provider
                                                  .of<PrinterAndOtherDetailsProvider>(
                                                      context,
                                                      listen: false)
                                              .allUserProfilesFromClass)[Provider
                                                  .of<PrinterAndOtherDetailsProvider>(
                                                      context,
                                                      listen: false)
                                              .currentUserPhoneNumberFromClass]
                                          ['restaurantName'],
                                      body: '*userProfileEdited*');
                                  Navigator.pop(context);
                                }
                              },
                              child: Text('Add User'))
                        ],
                      )
                    ],
                  ),
                ),
              );
            });
          });
    }

    void adminEditUserProfileBottomSheet(
        context, Map<String, dynamic> userProfileMap) {
      tempListOfRestaurantsOfUser = userProfileMap['restaurantsOfTheUser'];

      tempUserPhoneNumber = userProfileMap['userPhoneNumber'];
      tempUserName = userProfileMap['username'];
      tempOwnerOrNot = userProfileMap['privileges']['1'];
      tempStatisticsAccess = userProfileMap['privileges']['2'];
      tempCompleteOrderHistory = userProfileMap['privileges']['3'];
      tempUserProfileManagement = userProfileMap['privileges']['4'];
      tempChefSpecialitiesAccess = userProfileMap['privileges']['5'];
      tempItemsAvailabilityAccess = userProfileMap['privileges']['6'];
      tempRestaurantInfoEdit = userProfileMap['privileges']['7'];
      tempIndividualKOTPrintNeededTrueElseFalse =
          userProfileMap['privileges']['8'];

      showModalBottomSheet(
          isScrollControlled: true,
          context: context,
          builder: (BuildContext buildContext) {
            return StatefulBuilder(builder: (context, setStateSB) {
              return Padding(
                padding: EdgeInsets.only(
                    top: 20, bottom: MediaQuery.of(context).viewInsets.bottom),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tempUserName,
                            style: TextStyle(fontSize: 30),
                          ),
                          IconButton(
                              onPressed: () {
                                String alertDialogUserName = tempUserName;
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        elevation: 24.0,
                                        // backgroundColor: Colors.greenAccent,
                                        // shape: CircleBorder(),
                                        title: Text('Name'),
                                        content: Container(
                                          padding: EdgeInsets.all(10),
                                          child: TextField(
                                            maxLength: 100,
                                            controller: TextEditingController(
                                                text: alertDialogUserName),
                                            textCapitalization:
                                                TextCapitalization.sentences,
                                            onChanged: (value) {
                                              alertDialogUserName = value;
                                            },
                                            decoration:
                                                // kTextFieldInputDecoration,
                                                InputDecoration(
                                                    filled: true,
                                                    fillColor: Colors.white,
                                                    hintText: 'Enter Username',
                                                    hintStyle: TextStyle(
                                                        color: Colors.grey),
                                                    enabledBorder: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                                Radius.circular(
                                                                    10)),
                                                        borderSide: BorderSide(
                                                            color:
                                                                Colors.green)),
                                                    focusedBorder: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                                Radius.circular(
                                                                    10)),
                                                        borderSide: BorderSide(
                                                            color:
                                                                Colors.green))),
                                          ),
                                        ),
                                        actions: [
                                          ElevatedButton(
                                              style: ButtonStyle(
                                                backgroundColor:
                                                    MaterialStateProperty.all<
                                                        Color>(Colors.green),
                                              ),
                                              onPressed: () {
                                                setStateSB(() {
                                                  tempUserName =
                                                      alertDialogUserName;
                                                });

                                                Navigator.pop(context);
                                              },
                                              child: Text('Done'))
                                        ],
                                      );
                                    });
                              },
                              icon: Icon(
                                Icons.edit,
                                color: Colors.green.shade500,
                              ))
                        ],
                      ),
                      Center(
                        child: Text(
                          'Phone : $tempUserPhoneNumber',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                      SizedBox(height: 20),
                      ListTile(
                        title: Text('Owner Login'),
                        trailing: Switch(
                          activeColor: Colors.green,
                          value: tempOwnerOrNot,
                          onChanged: (bool changedValue) {
                            setStateSB(() {
                              tempOwnerOrNot = changedValue;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('Statistics Access'),
                        trailing: Switch(
                          activeColor: Colors.green,
                          value: tempStatisticsAccess,
                          onChanged: (bool changedValue) {
                            setStateSB(() {
                              tempStatisticsAccess = changedValue;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('Complete Order History'),
                        trailing: Switch(
                          activeColor: Colors.green,
                          value: tempCompleteOrderHistory,
                          onChanged: (bool changedValue) {
                            setStateSB(() {
                              tempCompleteOrderHistory = changedValue;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('User Profile Management'),
                        trailing: Switch(
                          activeColor: Colors.green,
                          value: tempUserProfileManagement,
                          onChanged: (bool changedValue) {
                            setStateSB(() {
                              tempUserProfileManagement = changedValue;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('Chef Specialities Access'),
                        trailing: Switch(
                          activeColor: Colors.green,
                          value: tempChefSpecialitiesAccess,
                          onChanged: (bool changedValue) {
                            setStateSB(() {
                              tempChefSpecialitiesAccess = changedValue;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('Items Availability Access'),
                        trailing: Switch(
                          activeColor: Colors.green,
                          value: tempItemsAvailabilityAccess,
                          onChanged: (bool changedValue) {
                            setStateSB(() {
                              tempItemsAvailabilityAccess = changedValue;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('Restaurant Info Edit Access'),
//IfTheyDontHaveThisAccess,OnlyKOTCanBeGivenByTheCaptain
                        trailing: Switch(
                          activeColor: Colors.green,
                          value: tempRestaurantInfoEdit,
                          onChanged: (bool changedValue) {
                            setStateSB(() {
                              tempRestaurantInfoEdit = changedValue;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('Individual KOT Print'),
//IfTheyDontHaveThisAccess,OnlyKOTCanBeGivenByTheCaptain
                        trailing: Switch(
                          activeColor: Colors.green,
                          value: tempIndividualKOTPrintNeededTrueElseFalse,
                          onChanged: (bool changedValue) {
                            setStateSB(() {
                              tempIndividualKOTPrintNeededTrueElseFalse =
                                  changedValue;
                            });
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Colors.red),
                              ),
                              onPressed: () {
                                if (tempOwnerOrNot) {
                                  errorAlertDialogBox(
                                      '${tempUserName} is owner and hence, can\'t be deleted');
                                } else {
                                  Navigator.pop(context);
                                  deleteUserAlertDialogBox();
                                }
                              },
                              child: Text('Delete User')),
                          ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Colors.green),
                              ),
                              onPressed: () {
                                Map<String, dynamic> updateUserMap = HashMap();
                                updateUserMap
                                    .addAll({'username': tempUserName});
                                Map<String, bool> updatePrivilegesMap =
                                    HashMap();
                                updatePrivilegesMap
                                    .addAll({'1': tempOwnerOrNot});
                                updatePrivilegesMap
                                    .addAll({'2': tempStatisticsAccess});
                                updatePrivilegesMap
                                    .addAll({'3': tempCompleteOrderHistory});
                                updatePrivilegesMap
                                    .addAll({'4': tempUserProfileManagement});
                                updatePrivilegesMap
                                    .addAll({'5': tempChefSpecialitiesAccess});
                                updatePrivilegesMap
                                    .addAll({'6': tempItemsAvailabilityAccess});
                                updatePrivilegesMap
                                    .addAll({'7': tempRestaurantInfoEdit});
                                updatePrivilegesMap.addAll({
                                  '8': tempIndividualKOTPrintNeededTrueElseFalse
                                });
                                updateUserMap.addAll(
                                    {'privileges': updatePrivilegesMap});
                                FireStoreUpdateUserProfile(
                                        userPhoneNumber: tempUserPhoneNumber,
                                        hotelName: widget.hotelName,
                                        updateUserProfileMap: updateUserMap)
                                    .updateUserProfile();
                                Map<String, dynamic> allUsersTokenMap =
                                    json.decode(Provider.of<
                                                PrinterAndOtherDetailsProvider>(
                                            context,
                                            listen: false)
                                        .allUserTokensFromClass);

                                fcmProvider.sendNotification(
                                    token: [
                                      allUsersTokenMap[tempUserPhoneNumber]
                                          .toString()
                                    ],
                                    title: widget.hotelName,
                                    restaurantNameForNotification: json.decode(Provider
                                                .of<PrinterAndOtherDetailsProvider>(
                                                    context,
                                                    listen: false)
                                            .allUserProfilesFromClass)[Provider.of<
                                                    PrinterAndOtherDetailsProvider>(
                                                context,
                                                listen: false)
                                            .currentUserPhoneNumberFromClass]
                                        ['restaurantName'],
                                    body: '*userProfileEdited*');

                                Navigator.pop(context);
                              },
                              child: Text('Update'))
                        ],
                      )
                    ],
                  ),
                ),
              );
            });
          });
    }

    void nonAdminEditUserProfileBottomSheet(
        context, Map<String, dynamic> userProfileMap) {
      tempListOfRestaurantsOfUser = userProfileMap['restaurantsOfTheUser'];
      tempUserPhoneNumber = userProfileMap['userPhoneNumber'];
      tempUserName = userProfileMap['username'];
      tempOwnerOrNot = userProfileMap['privileges']['1'];
      tempStatisticsAccess = userProfileMap['privileges']['2'];
      tempCompleteOrderHistory = userProfileMap['privileges']['3'];
      tempUserProfileManagement = userProfileMap['privileges']['4'];

      tempChefSpecialitiesAccess = userProfileMap['privileges']['5'];
      tempItemsAvailabilityAccess = userProfileMap['privileges']['6'];
      tempRestaurantInfoEdit = userProfileMap['privileges']['7'];
      tempIndividualKOTPrintNeededTrueElseFalse =
          userProfileMap['privileges']['8'];

      showModalBottomSheet(
          isScrollControlled: true,
          context: context,
          builder: (BuildContext buildContext) {
            return StatefulBuilder(builder: (context, setStateSB) {
              return Padding(
                padding: EdgeInsets.only(
                    top: 20, bottom: MediaQuery.of(context).viewInsets.bottom),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            tempUserName,
                            style: TextStyle(fontSize: 30),
                          ),
                          IconButton(
                              onPressed: () {
                                String alertDialogUserName = tempUserName;
                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        elevation: 24.0,
                                        // backgroundColor: Colors.greenAccent,
                                        // shape: CircleBorder(),
                                        title: Text('Name'),
                                        content: Container(
                                          padding: EdgeInsets.all(10),
                                          child: TextField(
                                            maxLength: 100,
                                            controller: TextEditingController(
                                                text: alertDialogUserName),
                                            textCapitalization:
                                                TextCapitalization.sentences,
                                            onChanged: (value) {
                                              alertDialogUserName = value;
                                            },
                                            decoration:
                                                // kTextFieldInputDecoration,
                                                InputDecoration(
                                                    filled: true,
                                                    fillColor: Colors.white,
                                                    hintText: 'Enter Username',
                                                    hintStyle: TextStyle(
                                                        color: Colors.grey),
                                                    enabledBorder: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                                Radius.circular(
                                                                    10)),
                                                        borderSide: BorderSide(
                                                            color:
                                                                Colors.green)),
                                                    focusedBorder: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                                Radius.circular(
                                                                    10)),
                                                        borderSide: BorderSide(
                                                            color:
                                                                Colors.green))),
                                          ),
                                        ),
                                        actions: [
                                          ElevatedButton(
                                              style: ButtonStyle(
                                                backgroundColor:
                                                    MaterialStateProperty.all<
                                                        Color>(Colors.green),
                                              ),
                                              onPressed: () {
                                                setStateSB(() {
                                                  tempUserName =
                                                      alertDialogUserName;
                                                });

                                                Navigator.pop(context);
                                              },
                                              child: Text('Done'))
                                        ],
                                      );
                                    });
                              },
                              icon: Icon(
                                Icons.edit,
                                color: Colors.green.shade500,
                              ))
                        ],
                      ),
                      Center(
                        child: Text(
                          'Phone : $tempUserPhoneNumber',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                      SizedBox(height: 20),
                      ListTile(
                        title: Text('Statistics Access'),
                        trailing: Switch(
                          activeColor: Colors.green,
                          value: tempStatisticsAccess,
                          onChanged: (bool changedValue) {
                            setStateSB(() {
                              tempStatisticsAccess = changedValue;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('Complete Order History'),
                        trailing: Switch(
                          activeColor: Colors.green,
                          value: tempCompleteOrderHistory,
                          onChanged: (bool changedValue) {
                            setStateSB(() {
                              tempCompleteOrderHistory = changedValue;
                            });
                          },
                        ),
                      ),
                      !tempOwnerOrNot
                          ? ListTile(
                              title: Text('User Profile Management'),
                              trailing: Switch(
                                activeColor: Colors.green,
                                value: tempUserProfileManagement,
                                onChanged: (bool changedValue) {
                                  setStateSB(() {
                                    tempUserProfileManagement = changedValue;
                                  });
                                },
                              ),
                            )
                          : SizedBox.shrink(),
                      ListTile(
                        title: Text('Chef Specialities Access'),
                        trailing: Switch(
                          activeColor: Colors.green,
                          value: tempChefSpecialitiesAccess,
                          onChanged: (bool changedValue) {
                            setStateSB(() {
                              tempChefSpecialitiesAccess = changedValue;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('Items Availability Access'),
                        trailing: Switch(
                          activeColor: Colors.green,
                          value: tempItemsAvailabilityAccess,
                          onChanged: (bool changedValue) {
                            setStateSB(() {
                              tempItemsAvailabilityAccess = changedValue;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('Restaurant Info Edit Access'),
//IfTheyDontHaveThisAccess,OnlyKOTCanBeGivenByTheCaptain
                        trailing: Switch(
                          activeColor: Colors.green,
                          value: tempRestaurantInfoEdit,
                          onChanged: (bool changedValue) {
                            setStateSB(() {
                              tempRestaurantInfoEdit = changedValue;
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('Individual KOT Print'),
//IfTheyDontHaveThisAccess,OnlyKOTCanBeGivenByTheCaptain
                        trailing: Switch(
                          activeColor: Colors.green,
                          value: tempIndividualKOTPrintNeededTrueElseFalse,
                          onChanged: (bool changedValue) {
                            setStateSB(() {
                              tempIndividualKOTPrintNeededTrueElseFalse =
                                  changedValue;
                            });
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Colors.red),
                              ),
                              onPressed: () {
                                if (tempOwnerOrNot) {
                                  errorAlertDialogBox(
                                      '${tempUserName} is the primary login and hence, can\'t be deleted');
                                } else {
                                  Navigator.pop(context);
                                  deleteUserAlertDialogBox();
                                }
                              },
                              child: Text('Delete User')),
                          ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Colors.green),
                              ),
                              onPressed: () {
                                Map<String, dynamic> updateUserMap = HashMap();
                                updateUserMap
                                    .addAll({'username': tempUserName});
                                Map<String, bool> updatePrivilegesMap =
                                    HashMap();
                                updatePrivilegesMap
                                    .addAll({'2': tempStatisticsAccess});
                                updatePrivilegesMap
                                    .addAll({'3': tempCompleteOrderHistory});
                                updatePrivilegesMap
                                    .addAll({'4': tempUserProfileManagement});
                                updatePrivilegesMap
                                    .addAll({'5': tempChefSpecialitiesAccess});
                                updatePrivilegesMap
                                    .addAll({'6': tempItemsAvailabilityAccess});
                                updatePrivilegesMap
                                    .addAll({'7': tempRestaurantInfoEdit});
                                updatePrivilegesMap.addAll({
                                  '8': tempIndividualKOTPrintNeededTrueElseFalse
                                });
                                updateUserMap.addAll(
                                    {'privileges': updatePrivilegesMap});
                                FireStoreUpdateUserProfile(
                                        userPhoneNumber: tempUserPhoneNumber,
                                        hotelName: widget.hotelName,
                                        updateUserProfileMap: updateUserMap)
                                    .updateUserProfile();

                                Map<String, dynamic> allUsersTokenMap =
                                    json.decode(Provider.of<
                                                PrinterAndOtherDetailsProvider>(
                                            context,
                                            listen: false)
                                        .allUserTokensFromClass);

                                fcmProvider.sendNotification(
                                    token: [
                                      allUsersTokenMap[tempUserPhoneNumber]
                                          .toString()
                                    ],
                                    title: widget.hotelName,
                                    restaurantNameForNotification: json.decode(Provider
                                                .of<PrinterAndOtherDetailsProvider>(
                                                    context,
                                                    listen: false)
                                            .allUserProfilesFromClass)[Provider.of<
                                                    PrinterAndOtherDetailsProvider>(
                                                context,
                                                listen: false)
                                            .currentUserPhoneNumberFromClass]
                                        ['restaurantName'],
                                    body: '*userProfileEdited*');

                                Navigator.pop(context);
                              },
                              child: Text('Update'))
                        ],
                      )
                    ],
                  ),
                ),
              );
            });
          });
    }

    Column adminUserProfileMainScreen() {
      return Column(
        children: [
          StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('loginDetails')
                  .where('restaurantDatabase.${'${widget.hotelName}'}',
                      isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                List<Map<String, dynamic>> users = [];
                listOfPhoneNumbersWithThatRestaurant = [];
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
                  final userProfilesStream = snapshot.data?.docs;
                  Map<String, dynamic> temporaryMapToAdd = HashMap();
                  for (var eachDoc in userProfilesStream!) {
                    listOfPhoneNumbersWithThatRestaurant.add(eachDoc.id);

                    temporaryMapToAdd = {};
                    temporaryMapToAdd.addAll({'userPhoneNumber': eachDoc.id});
                    tempRestaurantName =
                        eachDoc[widget.hotelName]['restaurantName'];
                    Map<String, dynamic> tempTempMapOfEachRestaurantsOfUser =
                        eachDoc['restaurantDatabase'];
                    List<String> tempTempListOfRestaurantsOfEachUser = [];
                    tempTempMapOfEachRestaurantsOfUser.forEach((key, value) {
                      tempTempListOfRestaurantsOfEachUser.add(key.toString());
                    });
                    temporaryMapToAdd.addAll({
                      'restaurantsOfTheUser':
                          tempTempListOfRestaurantsOfEachUser
                    });
                    temporaryMapToAdd.addAll(eachDoc[widget.hotelName]);
                    users.add(temporaryMapToAdd);
                  }
                  return Expanded(
                      child: ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final userMap = users[index];
                            final userName = users[index]['username'];
                            final ownerOrNot =
                                users[index]['privileges']['1'] == true
                                    ? 'Owner Login|'
                                    : '';
                            final statisticsAccess =
                                users[index]['privileges']['2'] == true
                                    ? 'Statistics|'
                                    : '';
                            final completeOrderHistory =
                                users[index]['privileges']['3'] == true
                                    ? 'Complete Order History|'
                                    : '';
                            final userProfileManagement =
                                users[index]['privileges']['4'] == true
                                    ? 'User Profile Management|'
                                    : '';
                            final chefSpecialitiesAccess =
                                users[index]['privileges']['5'] == true
                                    ? 'Can Change Chef Specialities|'
                                    : '';
                            final itemsAvailabilityAccess =
                                users[index]['privileges']['6'] == true
                                    ? 'Can Change Item Availability|'
                                    : '';
                            final restaurantInfoEditAccess =
                                users[index]['privileges']['7'] == true
                                    ? 'Restaurant Info Edit|'
                                    : '';
                            final individualKOTPrintEdit =
                                users[index]['privileges']['8'] == true
                                    ? 'Individual KOT Print|'
                                    : '';

                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: Colors.black87,
                                  width: 1.0,
                                ),
                              ),
                              child: ListTile(
                                title: Text(
                                  userName,
                                  style: TextStyle(fontSize: 28),
                                ),
                                trailing: IconButton(
                                    onPressed: () {
                                      // tempOwnerOrNot = userMap
                                      adminEditUserProfileBottomSheet(
                                          context, userMap);
                                    },
                                    icon: Icon(Icons.edit)),
                                subtitle: Text(
                                    '$ownerOrNot$statisticsAccess$completeOrderHistory$userProfileManagement$chefSpecialitiesAccess$itemsAvailabilityAccess$restaurantInfoEditAccess$individualKOTPrintEdit',
                                    style: TextStyle(fontSize: 18)),
                              ),
                            );
                          }));
                } else {
                  return Center(
                    child: Text('Some Error Occurred'),
                  );
                }
              }),
        ],
      );
    }

    Column nonAdminOwnerUserProfileMainScreen() {
      return Column(
        children: [
          StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('loginDetails')
                  .where('restaurantDatabase.${'${widget.hotelName}'}',
                      isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                List<Map<String, dynamic>> users = [];
                listOfPhoneNumbersWithThatRestaurant = [];
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
                  final userProfilesStream = snapshot.data?.docs;
                  Map<String, dynamic> temporaryMapToAdd = HashMap();
                  for (var eachDoc in userProfilesStream!) {
                    listOfPhoneNumbersWithThatRestaurant.add(eachDoc.id);
                    if (eachDoc[widget.hotelName]['admin'] == false) {
                      temporaryMapToAdd = {};
                      temporaryMapToAdd.addAll({'userPhoneNumber': eachDoc.id});
                      tempRestaurantName =
                          eachDoc[widget.hotelName]['restaurantName'];
                      Map<String, dynamic> tempTempMapOfEachRestaurantsOfUser =
                          eachDoc['restaurantDatabase'];
                      List<String> tempTempListOfRestaurantsOfEachUser = [];
                      tempTempMapOfEachRestaurantsOfUser.forEach((key, value) {
                        tempTempListOfRestaurantsOfEachUser.add(key.toString());
                      });
                      temporaryMapToAdd.addAll({
                        'restaurantsOfTheUser':
                            tempTempListOfRestaurantsOfEachUser
                      });
                      temporaryMapToAdd.addAll(eachDoc[widget.hotelName]);
                      users.add(temporaryMapToAdd);
                    }
                  }
                  return Expanded(
                      child: ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final userMap = users[index];
                            final userName = users[index]['username'];
                            final statisticsAccess =
                                users[index]['privileges']['2'] == true
                                    ? 'Statistics|'
                                    : '';
                            final completeOrderHistory =
                                users[index]['privileges']['3'] == true
                                    ? 'Complete Order History|'
                                    : '';
                            final userProfileManagement =
                                users[index]['privileges']['4'] == true
                                    ? 'User Profile Management|'
                                    : '';
                            final chefSpecialitiesAccess =
                                users[index]['privileges']['5'] == true
                                    ? 'Can Change Chef Specialities|'
                                    : '';
                            final itemsAvailabilityAccess =
                                users[index]['privileges']['6'] == true
                                    ? 'Can Change Item Availability|'
                                    : '';
                            final restaurantInfoEditAccess =
                                users[index]['privileges']['7'] == true
                                    ? 'Restaurant Info Edit|'
                                    : '';
                            final individualKOTPrintEdit =
                                users[index]['privileges']['8'] == true
                                    ? 'Individual KOT Print|'
                                    : '';

                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: Colors.black87,
                                  width: 1.0,
                                ),
                              ),
                              child: ListTile(
                                title: Text(
                                  userName,
                                  style: TextStyle(fontSize: 28),
                                ),
                                trailing: IconButton(
                                    onPressed: () {
                                      // tempOwnerOrNot = userMap
                                      nonAdminEditUserProfileBottomSheet(
                                          context, userMap);
                                    },
                                    icon: Icon(Icons.edit)),
                                subtitle: Text(
                                    '$statisticsAccess$completeOrderHistory$userProfileManagement$chefSpecialitiesAccess$itemsAvailabilityAccess$restaurantInfoEditAccess$individualKOTPrintEdit',
                                    style: TextStyle(fontSize: 18)),
                              ),
                            );
                          }));
                } else {
                  return Center(
                    child: Text('Some Error Occurred'),
                  );
                }
              }),
        ],
      );
    }

    Column nonAdminNonOwnerUserProfileMainScreen() {
      return Column(
        children: [
          StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('loginDetails')
                  .where('restaurantDatabase.${'${widget.hotelName}'}',
                      isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                List<Map<String, dynamic>> users = [];
                listOfPhoneNumbersWithThatRestaurant = [];
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
                  final userProfilesStream = snapshot.data?.docs;
                  Map<String, dynamic> temporaryMapToAdd = HashMap();
                  for (var eachDoc in userProfilesStream!) {
                    listOfPhoneNumbersWithThatRestaurant.add(eachDoc.id);
                    if (eachDoc[widget.hotelName]['admin'] == false &&
                        eachDoc[widget.hotelName]['privileges']['1'] == false) {
                      temporaryMapToAdd = {};
                      temporaryMapToAdd.addAll({'userPhoneNumber': eachDoc.id});
                      tempRestaurantName =
                          eachDoc[widget.hotelName]['restaurantName'];
                      Map<String, dynamic> tempTempMapOfEachRestaurantsOfUser =
                          eachDoc['restaurantDatabase'];
                      List<String> tempTempListOfRestaurantsOfEachUser = [];
                      tempTempMapOfEachRestaurantsOfUser.forEach((key, value) {
                        tempTempListOfRestaurantsOfEachUser.add(key.toString());
                      });
                      temporaryMapToAdd.addAll({
                        'restaurantsOfTheUser':
                            tempTempListOfRestaurantsOfEachUser
                      });
                      temporaryMapToAdd.addAll(eachDoc[widget.hotelName]);
                      users.add(temporaryMapToAdd);
                    }
                  }
                  return Expanded(
                      child: ListView.builder(
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final userMap = users[index];
                            final userName = users[index]['username'];
                            final statisticsAccess =
                                users[index]['privileges']['2'] == true
                                    ? 'Statistics|'
                                    : '';
                            final completeOrderHistory =
                                users[index]['privileges']['3'] == true
                                    ? 'Complete Order History|'
                                    : '';
                            final userProfileManagement =
                                users[index]['privileges']['4'] == true
                                    ? 'User Profile Management|'
                                    : '';
                            final chefSpecialitiesAccess =
                                users[index]['privileges']['5'] == true
                                    ? 'Can Change Chef Specialities|'
                                    : '';
                            final itemsAvailabilityAccess =
                                users[index]['privileges']['6'] == true
                                    ? 'Can Change Item Availability|'
                                    : '';
                            final restaurantInfoEditAccess =
                                users[index]['privileges']['7'] == true
                                    ? 'Restaurant Info Edit|'
                                    : '';
                            final individualKOTPrintEdit =
                                users[index]['privileges']['8'] == true
                                    ? 'Individual KOT Print|'
                                    : '';

                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: Colors.black87,
                                  width: 1.0,
                                ),
                              ),
                              child: ListTile(
                                title: Text(
                                  userName,
                                  style: TextStyle(fontSize: 28),
                                ),
                                trailing: IconButton(
                                    onPressed: () {
                                      // tempOwnerOrNot = userMap
                                      nonAdminEditUserProfileBottomSheet(
                                          context, userMap);
                                    },
                                    icon: Icon(Icons.edit)),
                                subtitle: Text(
                                    '$statisticsAccess$completeOrderHistory$userProfileManagement$chefSpecialitiesAccess$itemsAvailabilityAccess$restaurantInfoEditAccess$individualKOTPrintEdit',
                                    style: TextStyle(fontSize: 18)),
                              ),
                            );
                          }));
                } else {
                  return Center(
                    child: Text('Some Error Occurred'),
                  );
                }
              }),
        ],
      );
    }

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
          'User Profiles',
          style: kAppBarTextStyle,
        ),
      ),
      body: widget.currentUserProfileMap[widget.hotelName]['admin']
          ? adminUserProfileMainScreen()
          : json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                          listen: false)
                      .allUserProfilesFromClass)[
                  Provider.of<PrinterAndOtherDetailsProvider>(context,
                          listen: false)
                      .currentUserPhoneNumberFromClass]['privileges']['1']
              ? nonAdminOwnerUserProfileMainScreen()
              : nonAdminNonOwnerUserProfileMainScreen(),
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
            if (widget.currentUserProfileMap[widget.hotelName]['admin']) {
              adminCreateUserProfileBottomSheet(context);
            } else {
              nonAdminCreateUserProfileBottomSheet(context);
            }
          },
        ),
      ),
    );
  }
}
