import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:orders_dev/Methods/bottom_button.dart';
import 'package:orders_dev/constants.dart';
import 'package:orders_dev/services/firestore_services.dart';

//ThisScreenIsForEitherInventoryOrChefSpecialities
class InventoryOrChefSpecialities extends StatefulWidget {
  final List<String> entireMenuItems;
  final List<String> entireTitles;
  final String hotelName;
  final String? chefNumber;
  final bool inventoryOrChefSelection;
  //inventoryMeansTrue
  //chefSelectionMeansFalse

  const InventoryOrChefSpecialities(
      {Key? key,
      required this.entireMenuItems,
      required this.entireTitles,
      required this.hotelName,
      this.chefNumber,
      required this.inventoryOrChefSelection})
      : super(key: key);

  @override
  _InventoryOrChefSpecialitiesState createState() =>
      _InventoryOrChefSpecialitiesState();
}

class _InventoryOrChefSpecialitiesState
    extends State<InventoryOrChefSpecialities> {
  //WeInitiallyHaveTheNecessaryListsEmptyAnd
  List<String> allItems = [];
  List<bool> allItemsAvailability = [];
  Map<String, bool> unavailableItemsUpload = HashMap();
  bool allItemsChangeStatus = false;

//ThisMethodIsCalledWhenInventoryOrChefSelectionVariableIsTrue
//MeansWeWantAreHereToUpdateInventory
  void unavailableItemsMethod() async {
    allItems = [];
//FromFireStore,WeGoAndFindOutWhatAreAllTheItemsThatHaveBeenAlreadyMarkedUnavailable
    final unavailableQuery = await FirebaseFirestore.instance
        .collection(widget.hotelName)
        .doc('unavailableitems')
        .get();
//WeLoopThroughEntireMenuItemsWeHadInputtedWhenWeCalledThisClass
//AndThenWeAddItToAllItemsList
//WeAlsoReConfirmWhetherThisMenuItemIsn'tInTitles
//WeWantToEnsureWeHaveOnlyTheMenuItemsHere
    for (var eachItem in widget.entireMenuItems) {
      if (!widget.entireTitles.contains(eachItem)) {
        allItems.add(eachItem);
      }
    }
//InitiallyWeMakeAllItemsAvailabilityToTrue
    for (int i = 0; i < allItems.length; i++) {
      //booleanForAllItems
      allItemsAvailability.add(true);
    }

    //ThenWeCheckThatUnavailableItemsQueryHasSomething,
    //meaningSomeItemWasAlreadyNotThere
    if (unavailableQuery.data() != null) {
//WeGoThroughAllTheItems(WhichWillBeTheKey)OneByOne
//AndInTheHashMapUnavailableItemsUpload,WePutTheItemAsKeyAndValueAsFalse
      for (var unavailableItem in unavailableQuery.data()!.keys) {
        unavailableItemsUpload.addAll({unavailableItem: false});
//AlsoWeFindTheIndexOfUnavailableItemAmongAllItemsAnd
//InAllItemsAvailabilityList,WeChangeThatIndexToFalse
        if (allItems.contains(unavailableItem)) {
          allItemsAvailability[allItems.indexOf(unavailableItem)] = false;
        }
      }
    }
//FinallyWeUpdateTheStateOfAllItemsAndAllItemsAvailability
    setState(() {
      allItems;
      allItemsAvailability;
    });
  }

//ThisMethodIsCalledWhenInventoryOrChefSelectionVariableIsFalse
//MeansWeWantAreHereToUpdateChefSpecialities
  void chefWontCookMethod() async {
    allItems = [];
//WeFirstCheckWhetherThereIsAnyItemThatIsAlreadyInTheListInFireStoreThat,,
//theChefWontCook,,,ThisIsDoneWithTheHelpOfTheChefNumber
    final unavailableQuery = await FirebaseFirestore.instance
        .collection(widget.hotelName)
        .doc('users')
        .collection('users')
        .doc(widget.chefNumber)
        .get();

    //WeLoopThroughEntireMenuItemsWeHadInputtedWhenWeCalledThisClass
//AndThenWeAddItToAllItemsList
//WeAlsoReConfirmWhetherThisMenuItemIsn'tInTitles
//WeWantToEnsureWeHaveOnlyTheMenuItemsHere
    for (var eachItem in widget.entireMenuItems) {
      if (!widget.entireTitles.contains(eachItem)) {
        allItems.add(eachItem);
      }
    }
//InitiallyWeMakeAllItemsTheCookWillCookToTrue
    for (int i = 0; i < allItems.length; i++) {
      allItemsAvailability.add(true);
    }
//ThenWeCheckThatUnavailableQueryHasSomething,
    //meaningSomeItemWasAlreadyNotThereInChefSpecialities
    if (unavailableQuery.data() != null) {
//WeGoThroughAllTheItems(WhichWillBeTheKey)OneByOne
//AndInTheHashMapUnavailableItemsUpload,WePutTheItemAsKeyAndValueAsFalse
      for (var unavailableItem in unavailableQuery.data()!.keys) {
        unavailableItemsUpload.addAll({unavailableItem: false});
//AlsoWeFindTheIndexOfUnavailableItemAmongAllItemsAnd
//InAllItemsAvailabilityList,WeChangeThatIndexToFalse
        if (allItems.contains(unavailableItem)) {
          allItemsAvailability[allItems.indexOf(unavailableItem)] = false;
        }
      }
    }
//FinallyWeUpdateTheStateOfAllItemsAndAllItemsAvailability
    setState(() {
      allItems;
      allItemsAvailability;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    //WeCheckWhetherRequiredIsChefSelectionOrInventory
    //DependingOnThatWeCallTheMethods
    if (allItems.isEmpty) {
      if (widget.inventoryOrChefSelection) {
        unavailableItemsMethod();
      } else {
        chefWontCookMethod();
      }
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
              : Text('Chef ${widget.chefNumber} Specialities',
                  style: kAppBarTextStyle),
          centerTitle: true,
        ),
        body: Column(
          children: [
//InTheColumnInsideBody,FirstIsRowWhichWillAllowToSelectAllItems
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Select All'),
                SizedBox(width: 230.0),
//WeHaveACheckBowHere
//WhenCheckBoxIsTicked,
//WeIterateThroughTheEntireAllItemsAvailabilityListAndChangeToTrue
//WeAlsoClearTheHashMapBecauseThisMeansAllItemsAvailable,
//orTheCookWillCookEverything
                Checkbox(
                    value: allItemsChangeStatus,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          allItemsChangeStatus = true;
                          for (int i = 0; i < allItems.length; i++) {
                            allItemsAvailability[i] = true;
                            unavailableItemsUpload = {};
                          }
                        } else {
//WhenCheckBoxIsUnticked,
//WeIterateThroughTheEntireAllItemsAvailabilityListAndChangeToFalse
//WeAlsoClearTheHashMapBecauseThisMeansAllItemsUnavailable,
//orTheCookWillCookNothing
                          allItemsChangeStatus = false;
                          for (int i = 0; i < allItems.length; i++) {
                            allItemsAvailability[i] = false;
                            unavailableItemsUpload.addAll({allItems[i]: false});
                          }
                        }
                      });
                    })
              ],
            ),
            Expanded(
//ThisListViewBuilderInsideExpandedIsTheMainContentOfThisScreen
//ItemNameWillBeInLeftAndItemAvailabilityWillBeInRightInTheFormOfCheckBox
              child: ListView.builder(
                  itemCount: allItems.length,
                  itemBuilder: (context, index) {
                    final item = allItems[index];
                    return ListTile(
                      title: Text(item),
                      trailing: Checkbox(
                        value: allItemsAvailability[index],
//ifCheckBoxIsTickedOrUnticked,WeChangeAllItemsAvailabilityIndexAccordingly
//AlsoIfSomethingIsUnticked,ThenWeNeedToRemoveTheItemFromHashmap
//IfItIsTicked,WeNeedToAddItWithTheValueAsFalse
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              allItemsAvailability[index] = true;
                              unavailableItemsUpload.remove(item);
                            } else {
                              allItemsAvailability[index] = false;
                              unavailableItemsUpload.addAll({item: false});
                            }
                          });
                        },
                      ),
                    );
                  }),
            ),
          ],
        ),
        persistentFooterButtons: [
//AtTheBottomWeHaveTheFooterButton
          BottomButton(
            buttonColor: kBottomContainerColour,
//FirstWeCheckWhetherItIsInventoryOrChefSpecialities
            onTap: () {
//ifInventory,WeUpdateInFireStoreWithTheHashMapOfUnavailableItemsAndHotelName
              if (widget.inventoryOrChefSelection) {
                FireStoreUnavailableItems(
                        hotelName: widget.hotelName,
                        unavailableItemsUpload: unavailableItemsUpload)
                    .updateInventory();
              } else {
//ifChefSpecialities,WeUploadInFireStoreWithHashMapOfUnavailableItems
//NoteThatWeNeedToGiveTheChefNumberTooAlongWithHotelNameAndMapOfUnavailableItems
                FireStoreChefWontCook(
                        hotelName: widget.hotelName,
                        chefNumber: widget.chefNumber,
                        unavailableItemsUpload: unavailableItemsUpload)
                    .updateChefWontCook();
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
