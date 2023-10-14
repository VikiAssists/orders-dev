import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:modal_progress_hud_alt/modal_progress_hud_alt.dart';
import 'package:orders_dev/Providers/notification_provider.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:orders_dev/constants.dart';
import 'package:orders_dev/services/firestore_services.dart';
import 'package:provider/provider.dart';

class EditCategories extends StatefulWidget {
  final String hotelName;
  const EditCategories({Key? key, required this.hotelName}) : super(key: key);

  @override
  State<EditCategories> createState() => _EditCategoriesState();
}

class _EditCategoriesState extends State<EditCategories> {
  final _fireStore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> baseCategories = [];
  List<Map<String, dynamic>> updatedCategories = [];
  String errorMessage = '';
  String tempCategoryNameForEdit = '';
  num tempCategoryInitialKey = 0;
  num tempCategoryRandomID = 0;
  bool tempCategoryExisting = true;
  TextEditingController _editNamecontroller = TextEditingController();
  int maxNumberOfCategories = 0;
  List<String> deleteList = [];
  bool showSpinner = false;

  @override
  void initState() {
    // TODO: implement initState
//EnsuringOldValueNotStoredAndHenceAccidentallyDeletingMenu
    maxNumberOfCategories = 0;

    getCategories();
    super.initState();
  }

  void getCategories() async {
    setState(() {
      showSpinner = true;
    });
    List<num> temporaryOrderingNum = [];
    final menuCategories =
        await _fireStore.collection(widget.hotelName).doc('menu').get();
    //tryingToPutInOrder
    for (num i = 1; i <= menuCategories.data()!.length; i++) {
      temporaryOrderingNum.add(i);
    }
    maxNumberOfCategories = menuCategories.data()!.length;
    //toGetMenuItems
    final menuItems = await _fireStore
        .collection(widget.hotelName)
        .doc('menu')
        .collection('menu')
        .get();

    setState(() {
      for (num key in temporaryOrderingNum) {
        String currentCategory = menuCategories[key.toString()];
        num randomID = ((key * 100) + Random().nextInt(99));
        baseCategories.add({
          'initialKey': key,
          'category': menuCategories[key.toString()],
          'randomID': randomID,
          'existingCategory': true
        });
        updatedCategories.add({
          'initialKey': key,
          'category': menuCategories[key.toString()],
          'randomID': randomID,
          'existingCategory': true
        });
        items.add({
          'itemName': menuCategories[key.toString()],
          'price': -1,
          'variety': key,
          'category': 'title',
          'bulkEditSelected': false
        });
        for (var menuItem in menuItems.docs) {
          if (menuItem['variety'] == key) {
            items.add({
              'itemName': menuItem.id,
              'price': menuItem['price'],
              'variety': menuItem['variety'],
              'category': currentCategory,
              'bulkEditSelected': false
            });
          }
        }
      }
    });
    setState(() {
      showSpinner = false;
    });
  }

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

  Widget categoryAddBottomBar(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            Text('Add Category', style: TextStyle(fontSize: 30)),
            SizedBox(height: 20),
            ListTile(
              leading: Text('Name', style: TextStyle(fontSize: 20)),
              title: Container(
                child: TextField(
                  maxLength: 40,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) {
                    tempCategoryNameForEdit = value;
                  },
                  decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Enter Category Name',
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
                      if (tempCategoryNameForEdit == '') {
                        errorMessage = 'Please enter Category Name';
                        errorAlertDialogBox();
                      } else {
                        bool categoryAlreadyExists = false;
                        int newIndex = 0;
                        int counter = 0;
//ForLoopToFindWhetherItemAlreadyExists,PlaceWhereItemShouldBeInserted
                        for (var category in updatedCategories) {
                          if (categoryAlreadyExists == false) {
                            if (category['category'] ==
                                tempCategoryNameForEdit) {
                              categoryAlreadyExists = true;
                              errorMessage = 'Item Already Exists';
                              errorAlertDialogBox();
                            }
                          }
                        }
                        if (categoryAlreadyExists == false) {
                          maxNumberOfCategories = maxNumberOfCategories + 1;
                          num randomID =
                              (10000 + Random().nextInt(99999 - 10000));
//SinceItIsNewCategory,WeCantJustLikeThatGiveKeyForNow
                          updatedCategories.add({
                            'initialKey': maxNumberOfCategories,
                            'category': tempCategoryNameForEdit,
                            'randomID': randomID,
                            'existingCategory': false
                          });
                          //AddingToServer
                          FireStoreAddOrEditCategory(
                                  hotelName: widget.hotelName,
                                  categoryKey: maxNumberOfCategories.toString(),
                                  categoryName: tempCategoryNameForEdit)
                              .addOrEditMenuCategory();
                          Provider.of<PrinterAndOtherDetailsProvider>(context,
                                  listen: false)
                              .menuOrRestaurantInfoUpdated(true);
                        }

                        setState(() {
                          updatedCategories;
                        });
                        Navigator.pop(context);
                      }
                    },
                    child: Text('Add'))
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget categoryNameEditBottomBar(BuildContext context, index) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            Text('Edit Category', style: TextStyle(fontSize: 30)),
            SizedBox(height: 20),
            ListTile(
              leading: Text('Name', style: TextStyle(fontSize: 20)),
              title: Container(
                child: TextField(
                  maxLength: 40,
                  controller: _editNamecontroller,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) {
                    print(value);
                    tempCategoryNameForEdit = value.toString();
                    print(tempCategoryNameForEdit);
                  },
                  decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Enter Category Name',
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
                    onPressed: () async {
                      if (tempCategoryExisting == true) {
//meansThisCategoryHadALreadyExistedAndWillMostProbablyHaveItemsUnderIt
                        deleteList = [];
                        for (var item in items) {
                          if (item['category'] ==
                              updatedCategories[index]['category']) {
                            setState(() {
                              deleteList.add(item['itemName']);
                            });
                          }
                        }
                        if (deleteList.isNotEmpty) {
                          print('came inside not empty');
                          Navigator.pop(context);
                          showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return deleteConfirmationBottomSheet(
                                    context, index);
                              });
                        } else {
                          //itsCategoryWithNoItems.WeCanSimplyDeleteTheCategory
                          FireStoreDeleteParticularCategory(
                                  hotelName: widget.hotelName,
                                  deletedCategoryId:
                                      tempCategoryInitialKey.toString())
                              .deleteCategory();
                          Provider.of<PrinterAndOtherDetailsProvider>(context,
                                  listen: false)
                              .menuOrRestaurantInfoUpdated(true);
                          setState(() {
                            updatedCategories.removeAt(index);
                          });
                          Navigator.pop(context);
                        }
                      } else {
//itsNewCategory.WeCanSimplyDeleteTheCategoryAlone
                        FireStoreDeleteParticularCategory(
                                hotelName: widget.hotelName,
                                deletedCategoryId:
                                    tempCategoryInitialKey.toString())
                            .deleteCategory();
                        Provider.of<PrinterAndOtherDetailsProvider>(context,
                                listen: false)
                            .menuOrRestaurantInfoUpdated(true);
                        setState(() {
                          updatedCategories.removeAt(index);
                        });
                        Navigator.pop(context);
                      }
                    },
                    child: Text('Delete')),
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
                      print('categoryNameEdit');
                      print(tempCategoryNameForEdit);
                      if (tempCategoryNameForEdit == '') {
                        print('came inside this');
                        errorMessage = 'Please enter Category Name';
                        errorAlertDialogBox();
                      } else {
                        FireStoreAddOrEditCategory(
                                hotelName: widget.hotelName,
                                categoryKey: tempCategoryInitialKey.toString(),
                                categoryName: tempCategoryNameForEdit)
                            .addOrEditMenuCategory();
                        Provider.of<PrinterAndOtherDetailsProvider>(context,
                                listen: false)
                            .menuOrRestaurantInfoUpdated(true);
                        setState(() {
                          updatedCategories[index] = {
                            'initialKey': tempCategoryInitialKey,
                            'category': tempCategoryNameForEdit,
                            'randomID': tempCategoryRandomID,
                            'existingCategory': tempCategoryExisting
                          };
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

  Widget deleteConfirmationBottomSheet(BuildContext context, int index) {
    return Column(
      children: [
        Center(
            child: Text(
          'Confirm Removing Items Of\n ${updatedCategories[index]['category']}',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 30.0),
        )),
        SizedBox(height: 10),
        Expanded(
            child: ListView.builder(
                itemCount: deleteList.length,
                itemBuilder: (context, index) {
                  final itemName = deleteList[index];
                  return ListTile(
                    title: Text(itemName,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  );
                })),
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
                  for (var deleteItem in deleteList) {
//ThisIsForUpdatingInServerForDeletingMenu
                    FireStoreDeleteItemFromMenu(
                            hotelName: widget.hotelName,
                            eachItemMenuName: deleteItem)
                        .deleteItemFromMenu();
                  }
                  FireStoreDeleteParticularCategory(
                          hotelName: widget.hotelName,
                          deletedCategoryId: tempCategoryInitialKey.toString())
                      .deleteCategory();
                  Provider.of<PrinterAndOtherDetailsProvider>(context,
                          listen: false)
                      .menuOrRestaurantInfoUpdated(true);
                  setState(() {
                    updatedCategories.removeAt(index);
                  });

                  Navigator.pop(context);
                },
                child: Text('OK'))
          ],
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    final fcmProvider = Provider.of<NotificationProvider>(context);
    return WillPopScope(
      onWillPop: () async {
        if (updatedCategories.isNotEmpty) {
          bool extraCategoriesNeedsToBeRemoved = false;
          if (maxNumberOfCategories - updatedCategories.length > 0) {
//ThisMeansThatWeDeletedItemsAfterAddingItems.SoLengthIsLonger
            extraCategoriesNeedsToBeRemoved = true;
          }
          int counter = 0;
          for (var updatedCategory in updatedCategories) {
            if (updatedCategory['initialKey'] != counter + 1) {
//ThisMeansTheSequenceHasBeenReordered
              FireStoreAddOrEditCategory(
                      hotelName: widget.hotelName,
                      categoryKey: (counter + 1).toString(),
                      categoryName: updatedCategory['category'])
                  .addOrEditMenuCategory();
              Provider.of<PrinterAndOtherDetailsProvider>(context,
                      listen: false)
                  .menuOrRestaurantInfoUpdated(true);
              for (var item in items) {
                if ((item['variety'] == updatedCategory['initialKey']) &&
                    item['category'] != 'title') {
//THisIsTheInitialCateogory
                  FireStoreAddOrEditMenuItem(
                          hotelName: widget.hotelName,
                          docIdItemName: item['itemName'],
                          price: item['price'],
                          variety: counter + 1)
                      .addOrEditMenuItem();
                }
              }
            }

            counter++;
          }
          if (extraCategoriesNeedsToBeRemoved) {
            for (int j = maxNumberOfCategories;
                j > updatedCategories.length;
                j--) {
              print('came inside this delete');
              FireStoreDeleteParticularCategory(
                      hotelName: widget.hotelName,
                      deletedCategoryId: j.toString())
                  .deleteCategory();
              Provider.of<PrinterAndOtherDetailsProvider>(context,
                      listen: false)
                  .menuOrRestaurantInfoUpdated(true);
            }
          }

          maxNumberOfCategories = 0;
        }

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
              body: '*menuUpdated*');
        }
        Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .menuOrRestaurantInfoUpdated(false);
        Navigator.pop(context);

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
              if (updatedCategories.isNotEmpty) {
                bool extraCategoriesNeedsToBeRemoved = false;
                if (maxNumberOfCategories - updatedCategories.length > 0) {
//ThisMeansThatWeDeletedItemsAfterAddingItems.SoLengthIsLonger
                  extraCategoriesNeedsToBeRemoved = true;
                }
                int counter = 0;
                for (var updatedCategory in updatedCategories) {
                  if (updatedCategory['initialKey'] != counter + 1) {
//ThisMeansTheSequenceHasBeenReordered
                    FireStoreAddOrEditCategory(
                            hotelName: widget.hotelName,
                            categoryKey: (counter + 1).toString(),
                            categoryName: updatedCategory['category'])
                        .addOrEditMenuCategory();
                    Provider.of<PrinterAndOtherDetailsProvider>(context,
                            listen: false)
                        .menuOrRestaurantInfoUpdated(true);
                    for (var item in items) {
                      if ((item['variety'] == updatedCategory['initialKey']) &&
                          item['category'] != 'title') {
//THisIsTheInitialCateogory
                        FireStoreAddOrEditMenuItem(
                                hotelName: widget.hotelName,
                                docIdItemName: item['itemName'],
                                price: item['price'],
                                variety: counter + 1)
                            .addOrEditMenuItem();
                      }
                    }
                  }

                  counter++;
                }
                if (extraCategoriesNeedsToBeRemoved) {
                  for (int j = maxNumberOfCategories;
                      j > updatedCategories.length;
                      j--) {
                    print('came inside this delete');
                    FireStoreDeleteParticularCategory(
                            hotelName: widget.hotelName,
                            deletedCategoryId: j.toString())
                        .deleteCategory();
                    Provider.of<PrinterAndOtherDetailsProvider>(context,
                            listen: false)
                        .menuOrRestaurantInfoUpdated(true);
                  }
                }

                maxNumberOfCategories = 0;
              }

              if (Provider.of<PrinterAndOtherDetailsProvider>(context,
                      listen: false)
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
                    body: '*menuUpdated*');
              }
              Provider.of<PrinterAndOtherDetailsProvider>(context,
                      listen: false)
                  .menuOrRestaurantInfoUpdated(false);

              Navigator.pop(context);
            },
          ),
          title: Text(
            'Edit Categories',
            style: kAppBarTextStyle,
          ),
        ),
        body: ModalProgressHUD(
          inAsyncCall: showSpinner,
          child: Visibility(
            visible: !showSpinner,
            child: Column(
              children: [
                SizedBox(height: 10),
                Expanded(
                    child: ReorderableListView.builder(
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            final index =
                                newIndex > oldIndex ? newIndex - 1 : newIndex;
                            final reorderedCategory =
                                updatedCategories.removeAt(oldIndex);
                            updatedCategories.insert(index, reorderedCategory);
                          });
                        },
                        itemCount: updatedCategories.length,
                        itemBuilder: (context, index) {
                          final itemCategory = updatedCategories[index];

                          return Container(
                            key: ValueKey(itemCategory['randomID']),
                            //ContainerJustToEnsureWeCouldGiveTheMarginsToListTile
                            margin: EdgeInsets.fromLTRB(5, 5, 0, 10),
                            child: ListTile(
                                leading: Icon(Icons.menu),
                                tileColor: Colors.white54,
//FirstWeCheckWhetherMenuTitlesListContainsItem
//ThisMeansIt'sAHeading,WeGiveItBiggerFontThen
//NextWeCheckWhetherUnavailableItemsListHasTheItem,ifYes,WeGiveSlightlyGreyFont
//IfItIsn'tInEither,TheFoodItemIsNormallyShownInTheList
                                title: Text(itemCategory['category']),

//RightSide-WeCheckWhetherItIsHeading,IfYesWeShowNothing,
//ElseWeGiveTheAddOrCounterButton,TheInputBeingTheItemName
                                trailing: IconButton(
                                  icon: Icon(Icons.edit,
                                      size: 20, color: Colors.green),
                                  onPressed: () {
                                    tempCategoryNameForEdit =
                                        updatedCategories[index]['category'];
                                    tempCategoryInitialKey =
                                        updatedCategories[index]['initialKey'];
                                    tempCategoryRandomID =
                                        updatedCategories[index]['randomID'];
                                    tempCategoryExisting =
                                        updatedCategories[index]
                                            ['existingCategory'];

                                    _editNamecontroller = TextEditingController(
                                        text: tempCategoryNameForEdit);
                                    showModalBottomSheet(
                                        context: context,
                                        builder: (context) {
                                          return categoryNameEditBottomBar(
                                              context, index);
                                        });
                                  },
                                )),
                          );
                        })),
              ],
            ),
          ),
        ),
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
              tempCategoryNameForEdit = '';
              tempCategoryExisting = false;
              showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return categoryAddBottomBar(context);
                  });
            },
          ),
        ),
      ),
    );
  }
}
