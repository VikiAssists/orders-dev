import 'dart:collection';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
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

//ThisScreenIsForEitherInventoryOrChefSpecialities
class InventoryOrChefSpecialitiesWithFCM extends StatefulWidget {
  final List<Map<String, dynamic>> allMenuItems;
  final String hotelName;
  final String? chefPhoneNumber;
  final bool inventoryOrChefSelection;
  //inventoryMeansTrue
  //chefSelectionMeansFalse

  const InventoryOrChefSpecialitiesWithFCM(
      {Key? key,
      required this.allMenuItems,
      required this.hotelName,
      required this.inventoryOrChefSelection,
      this.chefPhoneNumber})
      : super(key: key);

  @override
  _InventoryOrChefSpecialitiesWithFCMState createState() =>
      _InventoryOrChefSpecialitiesWithFCMState();
}

class _InventoryOrChefSpecialitiesWithFCMState
    extends State<InventoryOrChefSpecialitiesWithFCM> {
  List<Map<String, dynamic>> itemsInMenu = [];
  List<bool> allItemsAvailability = [];
  Map<String, bool> unavailableItemsUpload = HashMap();
  List<String> unavailableItemsArray = [];
  bool allItemsChangeStatus = false;
  List<String> categoriesToScroll = ['Browse Menu'];
  final ItemScrollController _itemScrollController = ItemScrollController();
  bool allItemsSelected = false;
  String chefName = '';
  bool showSpinner = false;

  void createAllItemsAndCategoriesToScroll() {
    itemsInMenu = [];
    Map<String, dynamic> tempEachElement = HashMap();
    widget.allMenuItems.forEach((element) {
      if (element['category'] == 'title') {
        categoriesToScroll.add(element['itemName']);
        tempEachElement = element;
//SinceThisIsHeading,WeAreAlwaysKeepingItFalse
        tempEachElement.addAll({'itemSelected': false});
        itemsInMenu.add(tempEachElement);
      } else {
        tempEachElement = element;
//SinceThisIsHeading,WeAreAlwaysKeepingItFalse
        tempEachElement.addAll({'itemSelected': true});
        itemsInMenu.add(tempEachElement);
      }
    });
    setState(() {});
  }

//ThisMethodIsCalledWhenInventoryOrChefSelectionVariableIsTrue
//MeansWeWantAreHereToUpdateInventory
  void unavailableItemsMethod() async {
    setState(() {
      showSpinner = true;
    });
//FromFireStore,WeGoAndFindOutWhatAreAllTheItemsThatHaveBeenAlreadyMarkedUnavailable
    final unavailableQuery = await FirebaseFirestore.instance
        .collection(widget.hotelName)
        .doc('unavailableitems')
        .get();

    //ThenWeCheckThatUnavailableItemsQueryHasSomething,
    //meaningSomeItemWasAlreadyNotThere
    if (unavailableQuery.data() != null) {
//WeGoThroughAllTheItems(WhichWillBeTheKey)OneByOne
//AndInTheHashMapUnavailableItemsUpload,WePutTheItemAsKeyAndValueAsFalse
      int counter = 0;
      for (var unavailableItem in unavailableQuery.data()!.keys) {
        counter = 0;
        for (var eachItem in itemsInMenu) {
          if (eachItem['itemName'] == unavailableItem) {
            Map<String, dynamic> tempMap = eachItem;
            tempMap['itemSelected'] = false;
            itemsInMenu[counter] = tempMap;
          }
          counter++;
        }
      }
    }
//FinallyWeUpdateTheStateOfAllItemsAndAllItemsAvailability
    setState(() {
      showSpinner = false;
    });
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

//ThisMethodIsCalledWhenInventoryOrChefSelectionVariableIsFalse
//MeansWeWantAreHereToUpdateChefSpecialities
  void chefWontCookMethod() async {
    setState(() {
      showSpinner = true;
    });
//WeFirstCheckWhetherThereIsAnyItemThatIsAlreadyInTheListInFireStoreThat,,
//theChefWontCook,,,ThisIsDoneWithTheHelpOfTheChefNumber
    final wontCookQuery = await FirebaseFirestore.instance
        .collection('loginDetails')
        .doc(widget.chefPhoneNumber)
        .get();

    List<dynamic> tempChefWontCookItems =
        wontCookQuery[widget.hotelName]['wontCook'];

    if (tempChefWontCookItems.isNotEmpty) {
      int counter = 0;
      for (var tempWontCook in tempChefWontCookItems) {
        counter = 0;
        for (var eachItem in itemsInMenu) {
          if (eachItem['itemName'] == tempWontCook.toString()) {
            Map<String, dynamic> tempMap = eachItem;
            tempMap['itemSelected'] = false;
            itemsInMenu[counter] = tempMap;
          }
          counter++;
        }
      }
    }

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
    for (var item in itemsInMenu) {
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

  void checkBoxEditForSingleCategory(int index) {
    bool checkBoxChange = false;
//HereWeAreAlteringOnlyTheTitleFirst.
// OnceItIsAlteredWeAlterAllTheItemsUnderTheCategory
    var checkedItemName = itemsInMenu[index]['itemName'];
    var checkedItemPrice = itemsInMenu[index]['price'];
    var checkedItemVariety = itemsInMenu[index]['variety'];
    var checkedItemCategory = itemsInMenu[index]['category'];
    var checkedItemBulkEditSelected = itemsInMenu[index]['itemSelected'];
    if (checkedItemBulkEditSelected) {
      checkBoxChange = false;
    } else {
      checkBoxChange = true;
    }
    itemsInMenu[index] = {
      'itemName': checkedItemName,
      'price': checkedItemPrice,
      'variety': checkedItemVariety,
      'category': checkedItemCategory,
      'itemSelected': checkBoxChange
    };
    int counter = 0;
    for (var item in itemsInMenu) {
//ThisWillEnsureWeDontAlterTheTitleAnymore
//AndWeTouchOnlyTheItemsThatHasTheCategoryOfTheTitle
      if (item['itemName'] != checkedItemName &&
          item['category'] == checkedItemName) {
        var categoryItemName = item['itemName'];
        var categoryItemPrice = item['price'];
        var categoryItemVariety = item['variety'];
        var categoryItemCategory = item['category'];
        itemsInMenu[counter] = {
          'itemName': categoryItemName,
          'price': categoryItemPrice,
          'variety': categoryItemVariety,
          'category': categoryItemCategory,
          'itemSelected': checkBoxChange
        };
      }
      counter++;
    }
    setState(() {
      itemsInMenu;
    });
  }

  void checkBoxEditForSingleItem(int index) {
    bool checkBoxChange = false;

    var checkedItemName = itemsInMenu[index]['itemName'];
    var checkedItemPrice = itemsInMenu[index]['price'];
    var checkedItemVariety = itemsInMenu[index]['variety'];
    var checkedItemCategory = itemsInMenu[index]['category'];
    var checkedItemBulkEditSelected = itemsInMenu[index]['itemSelected'];
    if (checkedItemBulkEditSelected) {
      checkBoxChange = false;
    } else {
      checkBoxChange = true;
    }

    setState(() {
      itemsInMenu[index] = {
        'itemName': checkedItemName,
        'price': checkedItemPrice,
        'variety': checkedItemVariety,
        'category': checkedItemCategory,
        'itemSelected': checkBoxChange
      };
    });
  }

  void checkBoxEditForAllItemsAtOnce(bool selectedTrueUnselectedFalse) {
    int counter = 0;
    for (var item in itemsInMenu) {
      var categoryItemName = item['itemName'];
      var categoryItemPrice = item['price'];
      var categoryItemVariety = item['variety'];
      var categoryItemCategory = item['category'];
      itemsInMenu[counter] = {
        'itemName': categoryItemName,
        'price': categoryItemPrice,
        'variety': categoryItemVariety,
        'category': categoryItemCategory,
        'itemSelected': selectedTrueUnselectedFalse
      };

      counter++;
    }
    setState(() {
      allItemsSelected = selectedTrueUnselectedFalse;
      itemsInMenu;
    });
  }

  @override
  void initState() {
    createAllItemsAndCategoriesToScroll();
    // TODO: implement initState
    //WeCheckWhetherRequiredIsChefSelectionOrInventory
    //DependingOnThatWeCallTheMethods
    if (widget.inventoryOrChefSelection) {
      unavailableItemsMethod();
    } else {
      chefWontCookMethod();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final fcmProvider = Provider.of<NotificationProvider>(context);
    return WillPopScope(
      //ThisWillPopScopeIsForTheBackButtonOfPhone,JustToPopTheScreen
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
//WeHaveBackButtonInAppBar,WeClickBackAndItJustPopsTheScreen
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: kAppBarBackIconColor),
              onPressed: () async {
                Navigator.pop(context);
              }),
          backgroundColor: kAppBarBackgroundColor,
//DependingOnTheVariable-WeKnowWhetherWeNeedInventoryOrChefSpecialities
//WeWillPutInventory/ChefSpecialitiesWithChefNumberAccordingly
          title: widget.inventoryOrChefSelection
              ? const Text('Inventory', style: kAppBarTextStyle)
              : json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context,
                                  listen: false)
                              .allUserProfilesFromClass)[widget.chefPhoneNumber]
                          ['username'] == //ThisIsIfChefNameIsntYetUpdated
                      null
                  ? Text('Chef', style: kAppBarTextStyle)
                  : Text(
                      'Chef - ${json.decode(Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).allUserProfilesFromClass)[widget.chefPhoneNumber]['username']}',
                      style: kAppBarTextStyle),
          centerTitle: true,
        ),
        body: ModalProgressHUD(
          inAsyncCall: showSpinner,
          child: Visibility(
            visible: !showSpinner,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      'Select All',
                      style: Theme.of(context).textTheme.headline6,
                    ),
                    SizedBox(),
                    Checkbox(
                      value: allItemsSelected,
//ifCheckBoxIsTickedOrUnticked,WeChangeAllItemsAvailabilityIndexAccordingly
//AlsoIfSomethingIsUnticked,ThenWeNeedToRemoveTheItemFromHashmap
//IfItIsTicked,WeNeedToAddItWithTheValueAsFalse
                      onChanged: (changedValue) {
                        checkBoxEditForAllItemsAtOnce(changedValue!);
                      },
                    )
                  ],
                ),
                Expanded(
                  child: ScrollablePositionedList.builder(
                      itemCount: widget.allMenuItems.length,
                      itemScrollController: _itemScrollController,
                      itemBuilder: (context, index) {
                        final itemName = itemsInMenu[index]['itemName'];
                        final itemCategory = itemsInMenu[index]['category'];
                        final itemTickedTrueElseFalse =
                            itemsInMenu[index]['itemSelected'];

                        return Container(
                          //ContainerJustToEnsureWeCouldGiveTheMarginsToListTile
                          margin: index != itemsInMenu.length - 1
                              ? EdgeInsets.fromLTRB(5, 5, 0, 0)
                              : EdgeInsets.fromLTRB(5, 5, 0, 100),
                          child: ListTile(
                              tileColor: Colors.white54,
//FirstWeCheckWhetherMenuTitlesListContainsItem
//ThisMeansIt'sAHeading,WeGiveItBiggerFontThen
//NextWeCheckWhetherUnavailableItemsListHasTheItem,ifYes,WeGiveSlightlyGreyFont
//IfItIsn'tInEither,TheFoodItemIsNormallyShownInTheList
                              title: itemCategory == 'title'
                                  ? Row(
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
                                          value: itemTickedTrueElseFalse,
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
//RightSide-WeCheckWhetherItIsHeading,IfYesWeShowNothing,
//ElseWeGiveTheAddOrCounterButton,TheInputBeingTheItemName
                              trailing: itemCategory == 'title'
                                  ? null
                                  : Checkbox(
                                      value: itemTickedTrueElseFalse,
//ifCheckBoxIsTickedOrUnticked,WeChangeAllItemsAvailabilityIndexAccordingly
//AlsoIfSomethingIsUnticked,ThenWeNeedToRemoveTheItemFromHashmap
//IfItIsTicked,WeNeedToAddItWithTheValueAsFalse
                                      onChanged: (value) {
                                        checkBoxEditForSingleItem(index);
                                      },
                                    )),
                        );
                      }),
                ),
              ],
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
//FloatingActionButtonWePutContainerToEnsureWeCanDecorateItWithColor&Curves
        floatingActionButton: Container(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
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
                        style: title != 'Browse Menu'
                            ? const TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                              )
                            : const TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                fontWeight: FontWeight.bold))),
                value: title,
              );
            }).toList(),
          ),
        ),
        persistentFooterButtons: [
//AtTheBottomWeHaveTheFooterButton
          BottomButton(
            buttonColor: kBottomContainerColour,
//FirstWeCheckWhetherItIsInventoryOrChefSpecialities
            onTap: () async {
//ifInventory,WeUpdateInFireStoreWithTheHashMapOfUnavailableItemsAndHotelName
              if (widget.inventoryOrChefSelection) {
                for (var item in itemsInMenu) {
                  if (item['itemSelected'] == false &&
                      item['category'] != 'title') {
                    unavailableItemsUpload.addAll({item['itemName']: false});
                  }
                }
                FireStoreUnavailableItems(
                        hotelName: widget.hotelName,
                        unavailableItemsUpload: unavailableItemsUpload)
                    .updateInventory();
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
                    body: '*unavailableItemsChanged*');
              } else {
                List<String> chefWontCook = [];
                for (var item in itemsInMenu) {
                  if (item['itemSelected'] == false &&
                      item['category'] != 'title') {
                    chefWontCook.add(item['itemName']);
                  }
                }
                Map<String, dynamic> allUsersTokenMap = json.decode(
                    Provider.of<PrinterAndOtherDetailsProvider>(context,
                            listen: false)
                        .allUserTokensFromClass);
                List<String> chefToken = [
                  allUsersTokenMap[widget.chefPhoneNumber].toString()
                ];

                FireStoreChefSpecialities(
                        userPhoneNumber: widget.chefPhoneNumber!,
                        hotelName: widget.hotelName,
                        chefWontCook: chefWontCook)
                    .chefSpecialities();
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
                    body: '*userProfileEdited*');
              }
//WeCanQuitTheScreenOnceUploaded
              Navigator.pop(context);
            },
//DependingOn Inventory/ChefSpecialities,
//WeGiveTheAppropriateNameToTheBottomButton
            buttonTitle: widget.inventoryOrChefSelection
                ? 'Update Inventory'
                : 'Update Preferences',
            buttonWidth: double.infinity,
          )
        ],
      ),
    );
  }
}
