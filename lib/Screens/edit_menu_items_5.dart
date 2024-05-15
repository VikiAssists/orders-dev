import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:modal_progress_hud_alt/modal_progress_hud_alt.dart';
import 'package:orders_dev/Methods/bottom_button.dart';
import 'package:orders_dev/Providers/notification_provider.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:orders_dev/constants.dart';
import 'package:orders_dev/services/firestore_services.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class EditItemsGapAtBottom extends StatefulWidget {
  final String hotelName;
  const EditItemsGapAtBottom({Key? key, required this.hotelName})
      : super(key: key);

  @override
  State<EditItemsGapAtBottom> createState() => _EditItemsGapAtBottomState();
}

class _EditItemsGapAtBottomState extends State<EditItemsGapAtBottom> {
  final _fireStore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> offsetList = [];
  List<String> categories = [];
  List<String> categoriesToScroll = ['Select Category'];

  final ItemScrollController _itemScrollController = ItemScrollController();
  String tempItemNameForEdit = '';
  num tempPriceForEdit = 0;
  String tempCategoryForEdit = '';
  String tempPriceForEditInString = '';
  TextEditingController _controller = TextEditingController();
  TextEditingController _editNamecontroller = TextEditingController();
  TextEditingController _offsetTextcontroller = TextEditingController(text: '');
  String errorMessage = '';
  bool bulkPriceEditSelected = false;
  bool allItemsSelected = false;
  bool addBulkPriceTrueReduceBulkPriceFalse = true;
  String bulkOffsetValue = '';
  bool showSpinner = false;

  void getMenu() async {
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
    //toGetMenuItems
    final menuItems = await _fireStore
        .collection(widget.hotelName)
        .doc('menu')
        .collection('menu')
        .get();

    setState(() {
      for (num key in temporaryOrderingNum) {
        String currentCategory = menuCategories[key.toString()];
        categories.add(menuCategories[key.toString()]);
        categoriesToScroll.add(menuCategories[key.toString()]);
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

  void _scrollingToIndex(String value) {
//WeHaveFloatingActionButtonInWhichWeCanChooseTitle
//AndTheScreenWillScrollToThatParticularList
//Example:IfYouClick "Beverages", itWillScrollToTheSpotWithTea/Coffee
//ItWorksWithIndex,FirstWeCheckTheIndexOfWhatIsClickedInTheMenu
//ThenUsingItemsScrollController,WeScrollToThatSpotInDuration1Second
    int index = 0;
    int indexCounter = 0;
    for (var item in items) {
      if (item['itemName'] == value) {
        index = indexCounter;
      }
      indexCounter++;
    }
    if (index >= 0) {
      _itemScrollController.scrollTo(
          index: index,
          duration: const Duration(seconds: 1),
          curve: Curves.easeInOutCubic);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    getMenu();
    super.initState();
  }

  Widget itemEditDeleteBottomBar(BuildContext context, int index) {
    String itemNameEdit = tempItemNameForEdit;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            Text('Edit Item', style: TextStyle(fontSize: 30)),
            SizedBox(height: 10),
            Text(
                '(If Item Name is edited, item will be added to every chef.\nPlease update in Chef Specialities if necessary)',
                textAlign: TextAlign.center),
            SizedBox(height: 20),
            ListTile(
              leading: Text('Name', style: TextStyle(fontSize: 20)),
              title: Container(
                child: TextField(
                  maxLength: 40,
                  controller: _editNamecontroller,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) {
                    tempItemNameForEdit = value.toString();
                  },
                  decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Enter Item Name',
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
            SizedBox(height: 10),
            ListTile(
              leading: Text('Price', style: TextStyle(fontSize: 20)),
              title: Container(
                child: TextField(
                  maxLength: 10,
                  controller: _controller,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    tempPriceForEditInString = value.toString();
                  },
                  decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Enter Price',
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
            SizedBox(height: 10),
            ListTile(
              leading: Text('Category', style: TextStyle(fontSize: 20)),
              title: Container(
                decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(30)),
                width: 200,
                height: 50,
                // height: 200,
                child: Center(
                  child: DropdownButtonFormField(
                    decoration: InputDecoration.collapsed(hintText: ''),
                    isExpanded: true,
                    // underline: Container(),
                    dropdownColor: Colors.green,
                    value: tempCategoryForEdit,
                    onChanged: (value) {
                      setState(() {
                        tempCategoryForEdit = value.toString();
                      });
                    },
                    items: categories.map((title) {
//DropDownMenuItemWillHaveOneByOneItems,WePutThatAsList
//ValueWillBeEachTitle
                      return DropdownMenuItem(
                        alignment: Alignment.center,
                        child: Text(title,
                            style: const TextStyle(
                                fontSize: 15, color: Colors.white)),
                        value: title,
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
                          MaterialStateProperty.all<Color>(Colors.red),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      deleteAlertDialogBox(index);
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
                      if (tempItemNameForEdit == '') {
                        errorMessage = 'Please enter Item Name';
                        errorAlertDialogBox();
                      } else if (tempPriceForEditInString == '') {
                        errorMessage = 'Please enter Item Price';
                        errorAlertDialogBox();
                      } else {
                        tempPriceForEdit = num.parse(tempPriceForEditInString);
                        num tempVariety =
                            categories.indexOf(tempCategoryForEdit);
//HereWePutItInServer
//IfTheItemNameIsChangedWeCanDeleteTheOldItemFromServerAndThenAdd
//ElseItWillCreate2InstancesOfTheSameItemInTwoNames
//So,FirstDeletingItInCaseNameIsDifferent
                        if (items[index]['itemName'] != tempItemNameForEdit) {
                          FireStoreDeleteItemFromMenu(
                                  hotelName: widget.hotelName,
                                  eachItemMenuName: items[index]['itemName'])
                              .deleteItemFromMenu();
                        }
//AddingItemToServerMenu
                        FireStoreAddOrEditMenuItem(
                                hotelName: widget.hotelName,
                                docIdItemName: tempItemNameForEdit,
                                price: tempPriceForEdit,
                                variety: tempVariety + 1
//PlusOneBecauseVarietyStartsFromNumber 1 InTheServer
                                )
                            .addOrEditMenuItem();

//ThisIsForLocalList.WeNeedToArrangeBasedOnVariety
                        String nextCategory =
                            categories.last == tempCategoryForEdit
                                ? 'notAvailable'
                                : categories[(tempVariety + 1).toInt()];
//ThisIsToGetTheNextCategory

                        if (items[index]['category'] == tempCategoryForEdit) {
//IfCategoryIsNotChanged,WeCanUpdateTheItemAtSameIndex
                          items[index] = {
                            'itemName': tempItemNameForEdit,
                            'price': tempPriceForEdit,
                            'variety': tempVariety +
                                1, //CategoryInLocalStartsFrom0.ServerStartsFromOne
                            'category': tempCategoryForEdit,
                            'bulkEditSelected': false
                          };
                        } else {
//ifCateogoryIsChanges,WeNeedToMoveToDifferentIndexToTheNewCategory

//ThisIsNeededForInsertingInCaseWeNeedToInsertItemInTheListSomewhere
//TopOfTheCurrentItem
//JustAboveTheNextCategory
                          if (nextCategory == 'notAvailable') {
                            items.add({
                              'itemName': tempItemNameForEdit,
                              'price': tempPriceForEdit,
                              'variety': tempVariety +
                                  1, //CategoryInLocalStartsFrom0.ServerStartsFromOne
                              'category': tempCategoryForEdit,
                              'bulkEditSelected': false
                            });
                            items.removeAt(index);
                          } else {
                            int newIndex = 0;
                            bool itemNotAdded = true;
                            for (var item in items) {
                              if (item['itemName'] == nextCategory &&
                                  itemNotAdded) {
                                itemNotAdded = false;
                                items.insert(newIndex, {
                                  'itemName': tempItemNameForEdit,
                                  'price': tempPriceForEdit,
                                  'variety': tempVariety +
                                      1, //CategoryInLocalStartsFrom0.ServerStartsFromOne
                                  'category': tempCategoryForEdit,
                                  'bulkEditSelected': false
                                });
                                if (newIndex > index) {
                                  items.removeAt(index);
                                } else {
                                  items.removeAt(index + 1);
                                }
                              }
                              newIndex++;
                            }
                          }
                        }
//RegisteringThatSomethingHasBeenUpdated
                        Provider.of<PrinterAndOtherDetailsProvider>(context,
                                listen: false)
                            .menuOrRestaurantInfoUpdated(true);
//ThisIsForLocalList.WeNeedToArrangeBasedOnVariety
                        setState(() {
                          items;
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

  Widget itemAddBottomBar(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            Text('Add Item', style: TextStyle(fontSize: 30)),
            SizedBox(height: 10),
            Text(
                '(Added item will be added to every chef.\nPlease update in Chef Specialities if necessary)',
                textAlign: TextAlign.center),
            SizedBox(height: 20),
            ListTile(
              leading: Text('Name', style: TextStyle(fontSize: 20)),
              title: Container(
                child: TextField(
                  maxLength: 40,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) {
                    tempItemNameForEdit = value;
                  },
                  decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Enter Item Name',
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
            SizedBox(height: 10),
            ListTile(
              leading: Text('Price', style: TextStyle(fontSize: 20)),
              title: Container(
                child: TextField(
                  maxLength: 10,
                  controller: _controller,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    tempPriceForEditInString = value;
                  },
                  decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Enter Price',
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
            SizedBox(height: 10),
            ListTile(
              leading: Text('Category', style: TextStyle(fontSize: 20)),
              title: Container(
                decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(30)),
                width: 200,
                height: 50,
                // height: 200,
                child: Center(
                  child: DropdownButtonFormField(
                    decoration: InputDecoration.collapsed(hintText: ''),
                    isExpanded: true,
                    // underline: Container(),
                    dropdownColor: Colors.green,
                    value: categoriesToScroll[0],
                    onChanged: (value) {
                      setState(() {
                        tempCategoryForEdit = value.toString();
                      });
                    },
                    items: categoriesToScroll.map((title) {
//DropDownMenuItemWillHaveOneByOneItems,WePutThatAsList
//ValueWillBeEachTitle
                      return DropdownMenuItem(
                        alignment: Alignment.center,
                        child: Text(title,
                            style: title != 'Select Category'
                                ? const TextStyle(
                                    fontSize: 15, color: Colors.white)
                                : const TextStyle(
                                    fontSize: 15,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                        value: title,
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
                      if (tempItemNameForEdit == '') {
                        errorMessage = 'Please enter Item Name';
                        errorAlertDialogBox();
                      } else if (tempPriceForEditInString == '') {
                        errorMessage = 'Please enter Item Price';
                        errorAlertDialogBox();
                      } else if (tempCategoryForEdit == '' ||
                          tempCategoryForEdit == 'Select Category') {
                        errorMessage = 'Please enter Item Category';
                        errorAlertDialogBox();
                      } else {
                        tempPriceForEdit = num.parse(tempPriceForEditInString);
                        num tempVariety =
                            categories.indexOf(tempCategoryForEdit);
                        String nextCategory =
                            categories.last == tempCategoryForEdit
                                ? 'notAvailable'
                                : categories[(tempVariety + 1).toInt()];
                        bool itemsAlreadyExists = false;
                        int newIndex = 0;
                        int counter = 0;
                        bool itemNotAdded = true;
//ForLoopToFindWhetherItemAlreadyExists,PlaceWhereItemShouldBeInserted
                        for (var item in items) {
                          if (itemsAlreadyExists == false) {
                            if (item['itemName'] == tempItemNameForEdit) {
                              itemsAlreadyExists = true;
                              errorMessage = 'Item Already Exists';
                              errorAlertDialogBox();
                              if (counter != 0) {
//ScrollingTo Counter -1 Index. If 0 ItWillThrowAnError
                                //WeScrollToThePlaceWhereTheItemIsAlreadyThere
                                _itemScrollController.scrollTo(
                                    index: counter - 1,
                                    duration: const Duration(seconds: 1),
                                    curve: Curves.easeInOutCubic);
                              } else {
                                _itemScrollController.scrollTo(
                                    index: counter,
                                    duration: const Duration(seconds: 1),
                                    curve: Curves.easeInOutCubic);
                              }
                            }
                            if (nextCategory != 'notAvailable' &&
                                item['itemName'] == nextCategory &&
                                itemNotAdded) {
                              itemNotAdded = false;
                              newIndex = counter;
                            }
                            counter++;
                          }
                        }
                        if (itemsAlreadyExists == false) {
                          //AddingItemToServerMenu
                          FireStoreAddOrEditMenuItem(
                                  hotelName: widget.hotelName,
                                  docIdItemName: tempItemNameForEdit,
                                  price: tempPriceForEdit,
                                  variety: tempVariety + 1
//PlusOneBecauseVarietyStartsFromNumber 1 InTheServer
                                  )
                              .addOrEditMenuItem();
                          if (nextCategory == 'notAvailable') {
                            items.add({
                              'itemName': tempItemNameForEdit,
                              'price': tempPriceForEdit,
                              'variety': tempVariety +
                                  1, //CategoryInLocalStartsFrom0.ServerStartsFromOne
                              'category': tempCategoryForEdit,
                              'bulkEditSelected': false
                            });
                          } else {
                            items.insert(newIndex, {
                              'itemName': tempItemNameForEdit,
                              'price': tempPriceForEdit,
                              'variety': tempVariety +
                                  1, //CategoryInLocalStartsFrom0.ServerStartsFromOne
                              'category': tempCategoryForEdit,
                              'bulkEditSelected': false
                            });
                          }
                          Provider.of<PrinterAndOtherDetailsProvider>(context,
                                  listen: false)
                              .menuOrRestaurantInfoUpdated(true);
                        }

                        setState(() {
                          items;
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

  void deleteAlertDialogBox(int index) async {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Center(
            child: Text(
          'DELETE WARNING!',
          style: TextStyle(color: Colors.red),
        )),
        content: Text('${items[index]['itemName']} will be deleted'),
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
                    FireStoreDeleteItemFromMenu(
                            hotelName: widget.hotelName,
                            eachItemMenuName: items[index]['itemName'])
                        .deleteItemFromMenu();
                    Provider.of<PrinterAndOtherDetailsProvider>(context,
                            listen: false)
                        .menuOrRestaurantInfoUpdated(true);
                    setState(() {
//ThisIsToRemoveFromLocal
                      items.removeAt(index);
                    });

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

  void checkBoxEditForSingleItem(int index) {
    bool checkBoxChange = false;

    var checkedItemName = items[index]['itemName'];
    var checkedItemPrice = items[index]['price'];
    var checkedItemVariety = items[index]['variety'];
    var checkedItemCategory = items[index]['category'];
    var checkedItemBulkEditSelected = items[index]['bulkEditSelected'];
    if (checkedItemBulkEditSelected) {
      checkBoxChange = false;
    } else {
      checkBoxChange = true;
    }

    setState(() {
      items[index] = {
        'itemName': checkedItemName,
        'price': checkedItemPrice,
        'variety': checkedItemVariety,
        'category': checkedItemCategory,
        'bulkEditSelected': checkBoxChange
      };
    });
  }

  void checkBoxEditForSingleCategory(int index) {
    bool checkBoxChange = false;
//HereWeAreAlteringOnlyTheTitleFirst.
// OnceItIsAlteredWeAlterAllTheItemsUnderTheCategory
    var checkedItemName = items[index]['itemName'];
    var checkedItemPrice = items[index]['price'];
    var checkedItemVariety = items[index]['variety'];
    var checkedItemCategory = items[index]['category'];
    var checkedItemBulkEditSelected = items[index]['bulkEditSelected'];
    if (checkedItemBulkEditSelected) {
      checkBoxChange = false;
    } else {
      checkBoxChange = true;
    }
    items[index] = {
      'itemName': checkedItemName,
      'price': checkedItemPrice,
      'variety': checkedItemVariety,
      'category': checkedItemCategory,
      'bulkEditSelected': checkBoxChange
    };
    int counter = 0;
    for (var item in items) {
//ThisWillEnsureWeDontAlterTheTitleAnymore
//AndWeTouchOnlyTheItemsThatHasTheCategoryOfTheTitle
      if (item['itemName'] != checkedItemName &&
          item['category'] == checkedItemName) {
        var categoryItemName = item['itemName'];
        var categoryItemPrice = item['price'];
        var categoryItemVariety = item['variety'];
        var categoryItemCategory = item['category'];
        items[counter] = {
          'itemName': categoryItemName,
          'price': categoryItemPrice,
          'variety': categoryItemVariety,
          'category': categoryItemCategory,
          'bulkEditSelected': checkBoxChange
        };
      }
      counter++;
    }
    setState(() {
      items;
    });
  }

  void checkBoxEditForAllItemsAtOnce(bool selectedTrueUnselectedFalse) {
    int counter = 0;
    for (var item in items) {
      var categoryItemName = item['itemName'];
      var categoryItemPrice = item['price'];
      var categoryItemVariety = item['variety'];
      var categoryItemCategory = item['category'];
      items[counter] = {
        'itemName': categoryItemName,
        'price': categoryItemPrice,
        'variety': categoryItemVariety,
        'category': categoryItemCategory,
        'bulkEditSelected': selectedTrueUnselectedFalse
      };

      counter++;
    }
    setState(() {
      items;
    });
  }

  Widget offsetEnterBottomSheet(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          // mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            ListTile(
              leading: Text('Offset', style: TextStyle(fontSize: 20)),
              title: Container(
                child: TextField(
                  maxLength: 10,
                  controller: _offsetTextcontroller,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) {
                    bulkOffsetValue = value;
                  },
                  decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Enter Offset',
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
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.red),
                    ),
                    onPressed: () {
                      if (bulkOffsetValue == '') {
                        errorMessage = 'Please Enter Offset';
                        errorAlertDialogBox();
                      } else {
                        offsetList = [];
                        int indexCounter = 0;
                        for (var item in items) {
//HereWeEnsureWeAreOnlySelectingTheItemsThatAreCheckedAndAlsoNoTitles
//WeAreAlsoAdditionallyNotingTheIndexOfEachItemInTheItemAndNewPrice
                          if (item['bulkEditSelected'] == true &&
                              item['category'] != 'title') {
                            offsetList.add({
                              'itemName': item['itemName'],
                              'oldPrice': item['price'],
                              'newPrice': (item['price'] -
                                  (num.parse(bulkOffsetValue))),
                              'variety': item['variety'],
                              'category': item['category'],
                              'bulkEditSelected': item['bulkEditSelected'],
                              'indexToChange': indexCounter
                            });
                          }
                          indexCounter++;
                        }
                        if (offsetList.isEmpty) {
                          errorMessage = 'Please Select Items';
                          errorAlertDialogBox();
                        } else {
                          Navigator.pop(context);
                          showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return offsetEditBottomSheet(context);
                              });
                        }
                      }
                    },
                    child: Text('Reduce')),
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.orangeAccent),
                    ),
                    onPressed: () {
                      bulkOffsetValue = '';
                      _offsetTextcontroller.clear();
                    },
                    child: Text('Clear')),
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.green),
                    ),
                    onPressed: () {
                      if (bulkOffsetValue == '') {
                        errorMessage = 'Please Enter Offset';
                        errorAlertDialogBox();
                      } else {
                        offsetList = [];
                        int indexCounter = 0;
                        for (var item in items) {
//HereWeEnsureWeAreOnlySelectingTheItemsThatAreCheckedAndAlsoNoTitles
//WeAreAlsoAdditionallyNotingTheIndexOfEachItemInTheItemAndNewPrice
                          if (item['bulkEditSelected'] == true &&
                              item['category'] != 'title') {
                            offsetList.add({
                              'itemName': item['itemName'],
                              'oldPrice': item['price'],
                              'newPrice': (item['price'] +
                                  (num.parse(bulkOffsetValue))),
                              'variety': item['variety'],
                              'category': item['category'],
                              'bulkEditSelected': item['bulkEditSelected'],
                              'indexToChange': indexCounter
                            });
                          }
                          indexCounter++;
                        }
                        if (offsetList.isEmpty) {
                          errorMessage = 'Please Select Items';
                          errorAlertDialogBox();
                        } else {
                          Navigator.pop(context);
                          showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return offsetEditBottomSheet(context);
                              });
                        }
                      }
                    },
                    child: Text('Add'))
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget offsetEditBottomSheet(BuildContext context) {
    return Column(
      children: [
        Center(
            child: Text(
          'Confirm Changes',
          style: TextStyle(fontSize: 30.0),
        )),
        SizedBox(height: 10),
        Expanded(
            child: ListView.builder(
                itemCount: offsetList.length,
                itemBuilder: (context, index) {
                  final itemName = offsetList[index]['itemName'];
                  final itemOldPrice = offsetList[index]['oldPrice'];
                  final itemNewPrice = offsetList[index]['newPrice'];
                  return ListTile(
                    title: Text(itemName,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Old Price: ${itemOldPrice.toString()}'),
                    trailing: Text('New Price: ${itemNewPrice.toString()}',
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
                  for (var offset in offsetList) {
//ThisIsForUpdatingInServer
                    //AddingItemToServerMenu
                    FireStoreAddOrEditMenuItem(
                            hotelName: widget.hotelName,
                            docIdItemName: offset['itemName'],
                            price: offset['newPrice'],
                            variety: offset['variety']
//PlusOneBecauseVarietyStartsFromNumber 1 InTheServer
                            )
                        .addOrEditMenuItem();

//ThisIsForUpdatingInLocalPage
                    items[offset['indexToChange']] = {
                      'itemName': offset['itemName'],
                      'price': offset['newPrice'],
                      'variety': offset['variety'],
                      'category': offset['category'],
                      'bulkEditSelected': offset['bulkEditSelected']
                    };
                  }
                  Provider.of<PrinterAndOtherDetailsProvider>(context,
                          listen: false)
                      .menuOrRestaurantInfoUpdated(true);
                  setState(() {
                    items;
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
    print('tokensList');
    print(tokensList);
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
              body: '*menuUpdated*');
        }
        Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .menuOrRestaurantInfoUpdated(false);

        Navigator.pop(context);

        return false;
      },
      child: Theme(
        data: ThemeData().copyWith(
          dividerColor:
              (bulkPriceEditSelected) ? Colors.transparent : Colors.white,
        ),
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: kAppBarBackgroundColor,
            // centerTitle: true,
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
                      body: '*menuUpdated*');
                }
                Provider.of<PrinterAndOtherDetailsProvider>(context,
                        listen: false)
                    .menuOrRestaurantInfoUpdated(false);
                Navigator.pop(context);
              },
            ),
            title: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Bulk Edit Price',
                style: TextStyle(color: Colors.black),
              ),
            ),
            actions: [
              Switch(
                activeColor: Colors.green,
                value: bulkPriceEditSelected,
                onChanged: (bool changedValue) {
                  setState(() {
                    bulkOffsetValue = '';
                    _offsetTextcontroller.clear();
                    bulkPriceEditSelected = changedValue;
                    if (changedValue == false) {
                      setState(() {
                        allItemsSelected = false;
                      });
                      checkBoxEditForAllItemsAtOnce(false);
                    }
                  });
                },
              ),
            ],
          ),
          body: ModalProgressHUD(
            inAsyncCall: showSpinner,
            child: Visibility(
              visible: !showSpinner,
              child: Column(
                children: [
                  bulkPriceEditSelected
                      ? Container(
                          //ContainerJustToEnsureWeCouldGiveTheMarginsToListTile
                          margin: EdgeInsets.fromLTRB(5, 5, 0, 10),
                          child: ListTile(
                            tileColor: Colors.white54,
//FirstWeCheckWhetherMenuTitlesListContainsItem
//ThisMeansIt'sAHeading,WeGiveItBiggerFontThen
//NextWeCheckWhetherUnavailableItemsListHasTheItem,ifYes,WeGiveSlightlyGreyFont
//IfItIsn'tInEither,TheFoodItemIsNormallyShownInTheList
                            title: Text(
                              'Select All',
                              style: Theme.of(context).textTheme.headline5,
                            ),

//RightSide-WeCheckWhetherItIsHeading,IfYesWeShowNothing,
//ElseWeGiveTheAddOrCounterButton,TheInputBeingTheItemName
                            trailing: Checkbox(
                              value: allItemsSelected,
//ifCheckBoxIsTickedOrUnticked,WeChangeAllItemsAvailabilityIndexAccordingly
//AlsoIfSomethingIsUnticked,ThenWeNeedToRemoveTheItemFromHashmap
//IfItIsTicked,WeNeedToAddItWithTheValueAsFalse
                              onChanged: (value) {
                                setState(() {
                                  if (allItemsSelected) {
                                    allItemsSelected = false;
                                    checkBoxEditForAllItemsAtOnce(false);
                                  } else {
                                    allItemsSelected = true;
                                    checkBoxEditForAllItemsAtOnce(true);
                                  }
                                });
                              },
                            ),
                          ),
                        )
                      : SizedBox.shrink(),
                  Expanded(
                      child: ScrollablePositionedList.builder(
                          itemCount: items.length,
                          itemScrollController: _itemScrollController,
                          itemBuilder: (context, index) {
                            final itemName = items[index]['itemName'];
                            final itemPrice = items[index]['price'];
                            final itemVariety = items[index]['variety'];
                            final itemCategory = items[index]['category'];
                            final itemBulkEditSelected =
                                items[index]['bulkEditSelected'];

                            return Container(
                              //ContainerJustToEnsureWeCouldGiveTheMarginsToListTile
                              margin: index != items.length - 1
                                  ? EdgeInsets.fromLTRB(5, 5, 0, 0)
                                  : EdgeInsets.fromLTRB(5, 5, 0, 100),
//GivingLotOfSpaceFromTheBottomIfItIsTheLastItem
                              child: ListTile(
                                  tileColor: Colors.white54,
//FirstWeCheckWhetherMenuTitlesListContainsItem
//ThisMeansIt'sAHeading,WeGiveItBiggerFontThen
//NextWeCheckWhetherUnavailableItemsListHasTheItem,ifYes,WeGiveSlightlyGreyFont
//IfItIsn'tInEither,TheFoodItemIsNormallyShownInTheList
                                  title: itemCategory == 'title'
                                      ? bulkPriceEditSelected == false
                                          ? Text(
                                              itemName,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .headline6,
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceEvenly,
                                              children: [
                                                Text(
                                                  itemName,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headline6,
                                                ),
                                                SizedBox(),
                                                Checkbox(
                                                  value: itemBulkEditSelected,
//ifCheckBoxIsTickedOrUnticked,WeChangeAllItemsAvailabilityIndexAccordingly
//AlsoIfSomethingIsUnticked,ThenWeNeedToRemoveTheItemFromHashmap
//IfItIsTicked,WeNeedToAddItWithTheValueAsFalse
                                                  onChanged: (value) {
                                                    checkBoxEditForSingleCategory(
                                                        index);
                                                  },
                                                )
                                              ],
                                            )
                                      : Text(itemName),
//NoPricesToSayIfIsTitleElseWeCanSayPrice
                                  subtitle: itemCategory == 'title'
                                      ? null
                                      : Text('Price:${itemPrice.toString()}'),

//RightSide-WeCheckWhetherItIsHeading,IfYesWeShowNothing,
//ElseWeGiveTheAddOrCounterButton,TheInputBeingTheItemName
                                  trailing: itemCategory == 'title'
                                      ? null
                                      : bulkPriceEditSelected
                                          ? Checkbox(
                                              value: itemBulkEditSelected,
//ifCheckBoxIsTickedOrUnticked,WeChangeAllItemsAvailabilityIndexAccordingly
//AlsoIfSomethingIsUnticked,ThenWeNeedToRemoveTheItemFromHashmap
//IfItIsTicked,WeNeedToAddItWithTheValueAsFalse
                                              onChanged: (value) {
                                                checkBoxEditForSingleItem(
                                                    index);
                                              },
                                            )
                                          : IconButton(
                                              icon: Icon(Icons.edit,
                                                  size: 20,
                                                  color: Colors.green),
                                              onPressed: () {
                                                tempItemNameForEdit = itemName;
                                                tempPriceForEdit = itemPrice;
                                                tempPriceForEditInString =
                                                    itemPrice.toString();
                                                tempCategoryForEdit =
                                                    itemCategory;
                                                _editNamecontroller =
                                                    TextEditingController(
                                                        text:
                                                            tempItemNameForEdit);
                                                _controller = TextEditingController(
                                                    text:
                                                        tempPriceForEditInString);
                                                showModalBottomSheet(
                                                    isScrollControlled: true,
                                                    context: context,
                                                    builder: (context) {
                                                      return itemEditDeleteBottomBar(
                                                          context, index);
                                                      // return commentsSection(context, item);
                                                    });
                                              },
                                            )),
                            );
                          })),
                ],
              ),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
//FloatingActionButtonWePutContainerToEnsureWeCanDecorateItWithColor&Curves
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  SizedBox(width: 100),
                  Column(
                    children: [
                      SizedBox(height: 75, width: 75),
                      Container(
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
                          value: categoriesToScroll[0],
                          onChanged: (value) {
                            _scrollingToIndex(value.toString());
                          },
                          items: categoriesToScroll.map((title) {
//DropDownMenuItemWillHaveOneByOneItems,WePutThatAsList
//ValueWillBeEachTitle
                            return DropdownMenuItem(
                              child: Container(
                                  alignment: Alignment.center,
                                  child: Text(title,
                                      textAlign: TextAlign.center,
                                      style: title != 'Select Category'
                                          ? const TextStyle(
                                              fontSize: 15, color: Colors.white)
                                          : const TextStyle(
                                              fontSize: 15,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold))),
                              value: title,
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  bulkPriceEditSelected
                      ? SizedBox(height: 75, width: 75)
                      : Column(
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
                                  tempItemNameForEdit = '';
                                  tempPriceForEditInString = '';
                                  _controller = TextEditingController(
                                      text: tempPriceForEditInString);
//JustOneNumeralToEnsureThatNewNumberIsPlacedDuringAdd
                                  tempPriceForEdit = -10009999991000;
                                  tempCategoryForEdit = '';

                                  showModalBottomSheet(
                                      // isScrollControlled: true,
                                      context: context,
                                      builder: (context) {
                                        return itemAddBottomBar(context);
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
                            SizedBox(height: 75, width: 75)
                          ],
                        ),
                ],
              ),
            ],
          ),
          persistentFooterButtons: [
            Visibility(
              visible: (bulkPriceEditSelected),
              child: BottomButton(
                  onTap: () {
                    bool atleastOneItemSelected = false;
                    for (var item in items) {
//HereWeEnsureWeAreOnlySelectingTheItemsThatAreCheckedAndAlsoNoTitles
//WeAreAlsoAdditionallyNotingTheIndexOfEachItemInTheItemAndNewPrice
                      if (item['bulkEditSelected'] == true &&
                          item['category'] != 'title') {
                        if (item['bulkEditSelected'] == true) {
                          atleastOneItemSelected = true;
                        }
                      }
                    }
//IfNoItemIsSelected
                    if (!atleastOneItemSelected) {
                      errorMessage = 'Please Select Items';
                      errorAlertDialogBox();
                    } else {
//IfAnItemIsSelectedWeBringOnBottomSheet
                      showModalBottomSheet(
                          context: context,
                          builder: (context) {
                            return offsetEnterBottomSheet(context);
                          });
                    }
                  },
                  buttonTitle: 'Continue',
                  buttonColor: Colors.green),
            )
          ],
        ),
      ),
    );
  }
}
