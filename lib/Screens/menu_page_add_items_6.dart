import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:orders_dev/Methods/bottom_button.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:orders_dev/Screens/added_items_list_from_menu_12.dart';
import 'package:orders_dev/Screens/added_items_list_from_menu_13.dart';
import 'package:orders_dev/constants.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

//WeMakeLocalVersionOfPrices/Titles/UnavailableItemsBecause
//WeNeedAllThisDataInSearchScreenToo
//ByKeepingTheseVariablesOutside,WeCanGetDataToTheSearchScreen
List<dynamic> allItemsFromMenuMap = [];
List<String> localMenuItems = [];
List<num> localMenuPrice = [];
List<String> localMenuTitles = [];
List<String> localUnavailableItems = [];
Map<String, num> itemsAddedMap = HashMap();
Map<String, String> itemsAddedComment = HashMap();
Map<String, num> itemsAddedTime = HashMap();

//ThisIsThePageWeAlwaysCallForWhenWeNeedMenu
//TheInputsWillBeMenuPrices,Titles,Items,UnavailableItems(FromInventory)
//WeHaveAnItemsAddedMap-HashMapToPutWhateverTheWaiterIsSelecting
class MenuPageWithBackButtonUsage extends StatefulWidget {
  final String hotelName;
  final String tableOrParcel;
  final num tableOrParcelNumber;
  final List<String> menuItems;
  final List<num> menuPrices;
  final List<String> menuTitles;
  Map<String, num> itemsAddedMapCalled = HashMap();
  Map<String, String> itemsAddedCommentCalled = HashMap();
  Map<String, num> itemsAddedTimeCalled = HashMap();
  final String parentOrChild;
  final Map<String, dynamic> alreadyRunningTicketsMap;

  MenuPageWithBackButtonUsage(
      {required this.hotelName,
      required this.tableOrParcel,
      required this.tableOrParcelNumber,
      required this.menuItems,
      required this.menuPrices,
      required this.menuTitles,
      required this.itemsAddedMapCalled,
      required this.itemsAddedCommentCalled,
      required this.itemsAddedTimeCalled,
      required this.parentOrChild,
      required this.alreadyRunningTicketsMap});

  @override
  _MenuPageWithBackButtonUsageState createState() =>
      _MenuPageWithBackButtonUsageState();
}

class _MenuPageWithBackButtonUsageState
    extends State<MenuPageWithBackButtonUsage> {
  final ItemScrollController _itemScrollController = ItemScrollController();
  bool backButtonNotPressed = true;

  @override
  void initState() {
//WeNeedLocalVersionOfAllDataForTheSearchScreen
//WeSaveAllTheDataHere

    // TODO: implement initState
    localUnavailableItems = [];
    itemsAddedMap = {};
    itemsAddedComment = {};
    itemsAddedTime = {};

    makeMenu();

//InCaseDuringInputWeNoticeThatThereAreItemsTheWaiterHadAlreadySelected,,
//MaybeInSearchScreen,OrWaiterHasComeBackFromItemsAddedScreen,Then,HeWillHave
//SomeItemsAdded,WePutThemIntoItemsAddedMapWithKeyAndValue
    if (widget.itemsAddedMapCalled.isNotEmpty) {
      widget.itemsAddedMapCalled.forEach((key, value) {
        itemsAddedMap.addAll({key: value});
      });
      widget.itemsAddedCommentCalled.forEach((key, value) {
        itemsAddedComment.addAll({key: value});
      });
      widget.itemsAddedTimeCalled.forEach((key, value) {
        itemsAddedTime.addAll({key: value});
      });
    }
//FillingTheLocalVersionOfUnavailableItems
//IfUnavailableItemsListIsEmpty,WeJustCheckOnceWithTheBelowMethod
    unavailableItemsMethod();

    FirebaseMessaging.instance.getInitialMessage();
//foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('message in foreground');
      print(message.data);

      if (message.data['title'].toString() == widget.hotelName &&
          message.data['body'].toString().split('*')[1] ==
              'unavailableItemsChanged') {
        unavailableItemsMethod();
      }
    });

    super.initState();
  }

  void makeMenu() {
    allItemsFromMenuMap = json.decode(
        Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .entireMenuFromClass);
    localMenuTitles = ['Browse Menu'];
    localMenuPrice = [];
    localMenuItems = [];

    for (var eachItem in allItemsFromMenuMap) {
      if (eachItem['category'] == 'title') {
//MeaningItsCategory
        localMenuTitles.add(eachItem['itemName']);
        localMenuPrice.add(eachItem['price']);
        localMenuItems.add(eachItem['itemName']);
      } else {
//MeaningItsNotCategory
        localMenuPrice.add(eachItem['price']);
        localMenuItems.add(eachItem['itemName']);
      }
    }

    //
    // for (var item in widget.menuItems) {
    //   localMenuItems.add(item);
    // }
    //
    // for (var price in widget.menuPrices) {
    //   localMenuPrice.add(price);
    // }
    // for (var title in widget.menuTitles) {
    //   localMenuTitles.add(title);
    // }

    setState(() {
      localMenuItems;
      localMenuPrice;
      localMenuTitles;
    });
  }

  void unavailableItemsMethod() async {
//ThisIsJustToCheckWhetherThereIsAnyUnavailableItems
//WeQueryTheFireStore
    localUnavailableItems = [];
    final unavailableQuery = await FirebaseFirestore.instance
        .collection(widget.hotelName)
        .doc('unavailableitems')
        .get();
//IfUnavailableQueryHasData,WeGoThroughAllTheKeys,,
//AndStoreItInLocalUnavailableItems
    if (unavailableQuery.data() != null) {
      for (var unavailableItem in unavailableQuery.data()!.keys) {
        localUnavailableItems.add(unavailableItem);
      }
    }
//WeSetStateAndEnsureItIsReflectedThroughOut
    setState(() {
      localUnavailableItems;
    });
  }

//
// // ThisIsTheButtonInTheSideWhereWeAdd/MinusTheNumberOfItems
// // WrittenExplanationIn "added_items_list" page
  Widget addOrCounterButton(String item) {
    if (itemsAddedMap.containsKey(item)) {
      return Container(
        decoration: kMenuAddButtonDecoration,
        height: kMenuButtonHeight,
        width: kMenuButtonWidth,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
                onPressed: () {
                  setState(() {
                    if (itemsAddedMap[item] == 1) {
                      itemsAddedMap[item] = itemsAddedMap[item]! - 1;
                      itemsAddedMap.remove(item);
                      itemsAddedComment.remove(item);
                      itemsAddedTime.remove(item);
                    } else {
                      itemsAddedMap[item] = itemsAddedMap[item]! - 1;
                    }
                  });
                },
                icon: const Icon(
                  Icons.remove,
                  color: Colors.green,
                  size: kAddMinusButtonIconSize,
                )),
            Text(
              itemsAddedMap[item]!.toString(),
              style: kAddButtonNumberTextStyle,
            ),
            IconButton(
                onPressed: () {
                  setState(() {
                    itemsAddedMap[item] = itemsAddedMap[item]! + 1;
                  });
                },
                icon: const Icon(
                  Icons.add,
                  color: Colors.green,
                  size: kAddMinusButtonIconSize,
                ))
          ],
        ),
      );
    } else {
      return Container(
        decoration: kMenuAddButtonDecoration,
        height: kMenuButtonHeight,
        width: kMenuButtonWidth,
        child: TextButton(
            onPressed: () {
              setState(() {
                DateTime now = DateTime.now();
                itemsAddedMap.addAll({item: 1});
                itemsAddedComment.addAll({item: ''});

                itemsAddedTime.addAll({
                  item: ((now.hour * 3600000) +
                      (now.minute * 60000) +
                      (now.second * 1000) +
                      now.millisecond)
                });
              });
            },
            child: Text(
              'ADD',
              style: kAddButtonWordTextStyle,
            )),
      );
    }
  }

  void _scrollingToIndex(String value) {
//WeHaveFloatingActionButtonInWhichWeCanChooseTitle
//AndTheScreenWillScrollToThatParticularList
//Example:IfYouClick "Beverages", itWillScrollToTheSpotWithTea/Coffee
//ItWorksWithIndex,FirstWeCheckTheIndexOfWhatIsClickedInTheMenu
//ThenUsingItemsScrollController,WeScrollToThatSpotInDuration1Second
    int index = (localMenuItems.indexOf(value));
    if (index >= 0) {
      _itemScrollController.scrollTo(
          index: index,
          duration: const Duration(seconds: 1),
          curve: Curves.easeInOutCubic);
    }
  }

  void backClickedAlertDialogBox() async {
//ThisNeedsToPopUpIfThereAreItemsAddedAndTheUserClicksBack
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Center(
            child: Text(
          'WARNING!',
          style: TextStyle(color: Colors.red),
        )),
        content: Text('There are items added. Do you want to exit?'),
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
                    backButtonNotPressed = true;
                  },
                  child: Text('Cancel')),
              ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.red),
                  ),
                  onPressed: () {
                    clearingAddedItemsBeforeExit();
                    Navigator.pop(context);
                  },
                  child: Text('Exit')),
            ],
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  void clearingAddedItemsBeforeExit() {
    int _everyMilliSecondBeforeGoingBack = 0;
    Timer? _timerAtBackButton;
    _timerAtBackButton = Timer.periodic(Duration(milliseconds: 100), (_) {
      itemsAddedMap = {};
      widget.itemsAddedMapCalled = {};
      print('back timer is $_everyMilliSecondBeforeGoingBack');
      // return false;
      _everyMilliSecondBeforeGoingBack++;
      if (_everyMilliSecondBeforeGoingBack >= 4) {
        print('back timer at cancel is $_everyMilliSecondBeforeGoingBack');
        _timerAtBackButton!.cancel();
        if (widget.alreadyRunningTicketsMap.isNotEmpty) {
          backButtonNotPressed = true;
          Navigator.pop(context);
        } else {
          backButtonNotPressed = true;
          int count = 0;
          Navigator.of(context).popUntil((_) => count++ >= 2);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const title = 'Menu';
    return WillPopScope(
//ForBackButtonInPhone
//IfWeClickBackFromMenu,WeNeedToRemoveEverythingInItemsAddedMapAndExitScreen
//IfWeDon'tDoIt,itWasObservedThatIfTheWaiterGoesToAnotherTable&Menu,,
//TheseAddedItemsIsShowingThere
      onWillPop: () async {
        if (backButtonNotPressed) {
          backButtonNotPressed = false;
          if (itemsAddedMap.isEmpty) {
            clearingAddedItemsBeforeExit();
          } else {
            backClickedAlertDialogBox();
          }
        } else {
          backButtonNotPressed = true;
        }
        return false;
      },
      child: MaterialApp(
        title: title,
        home: Scaffold(
          appBar: AppBar(
//SimilarToWillPopScope-BackButtonInAppBarToo
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: kAppBarBackIconColor),
              onPressed: () {
                if (backButtonNotPressed) {
                  backButtonNotPressed = false;
                  if (itemsAddedMap.isEmpty) {
                    clearingAddedItemsBeforeExit();
                  } else {
                    backClickedAlertDialogBox();
                  }
                } else {
                  backButtonNotPressed = true;
                }
              },
            ),
            backgroundColor: kAppBarBackgroundColor,
//TitleOfAppBar "menu", fixedAtTopItself
            title: const Text(title, style: kAppBarTextStyle),
            centerTitle: true,
            actions: [
//WeAlsoHaveSearchButtonInAppBar,OnPressed,WeUseCustomSearchDelegateFunction,,
//ToGetToTheSearchBar
              IconButton(
                onPressed: () {
                  // method to show the search bar
                  showSearch(
                      context: context,
                      // delegate to customize the search bar
                      delegate: CustomSearchDelegate());
                },
                icon: const Icon(
                  Icons.search,
                  color: kAppBarBackIconColor,
                  size: 40.0,
                ),
              ),
            ],
          ),
//ThisIsWhereTheEntireMenuAppears
          body: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 10.0),
              Expanded(
//UnlikeOtherPlacesWhereWeUseListViewBuilder,hereWeUseScrollablePositionListBuilder
//ThisHelpsWithTheFunctionOfScrollingToAParticularIndex
                child: ScrollablePositionedList.builder(
                  // Let the ListView know how many items it needs to build.
                  itemCount: localMenuItems.length,
                  itemScrollController: _itemScrollController,
                  // Provide a builder function. This is where the magic happens.
                  // Convert each item into a widget based on the type of item it is.
                  itemBuilder: (context, index) {
                    final item = localMenuItems[index];

                    return Container(
//ContainerJustToEnsureWeCouldGiveTheMarginsToListTile
                      margin: index != localMenuItems.length - 1
                          ? EdgeInsets.fromLTRB(5, 5, 0, 10)
                          : EdgeInsets.fromLTRB(5, 5, 0, 100),
//                      decoration: BoxDecoration(
//                        borderRadius: BorderRadius.circular(5),
//                        border: Border.all(
//                          color: Colors.black87,
//                          width: 1.0,
//                        ),
//                      ),
                      child: ListTile(
                          tileColor: Colors.white54,
//FirstWeCheckWhetherMenuTitlesListContainsItem
//ThisMeansIt'sAHeading,WeGiveItBiggerFontThen
//NextWeCheckWhetherUnavailableItemsListHasTheItem,ifYes,WeGiveSlightlyGreyFont
//IfItIsn'tInEither,TheFoodItemIsNormallyShownInTheList
                          title: localMenuTitles.contains(item)
                              ? Text(
                                  item,
                                  style: Theme.of(context).textTheme.headline6,
                                )
                              : Text(item,
                                  style: localUnavailableItems.contains(item)
                                      ? const TextStyle(
                                          color: Colors.grey,
                                          fontStyle: FontStyle.italic)
                                      : null),
//SubtitleAppearsSlightlyUnderTheTitle,IfItIsInTitle,WeShowNothingInIt
//ElseWeShowThePriceOfItemFromTheIndex
                          subtitle: localMenuTitles.contains(item)
                              ? null
                              : Text(localMenuPrice[index].toString()),
//RightSide-WeCheckWhetherItIsHeading,IfYesWeShowNothing,
//ElseWeGiveTheAddOrCounterButton,TheInputBeingTheItemName
                          trailing: localUnavailableItems.contains(item) ||
                                  localMenuTitles.contains(item)
                              ? null
                              : addOrCounterButton(item)),
                    );
                  },
                ),
              ),
            ],
          ),
//FloatingActionButtonLocationHelpsToPutTheFloatingActionButtonInCenter
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
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
              value: localMenuTitles[0],
              onChanged: (value) {
                _scrollingToIndex(value.toString());
              },
              items: localMenuTitles.map((title) {
//DropDownMenuItemWillHaveOneByOneItems,WePutThatAsList
//ValueWillBeEachTitle
                return DropdownMenuItem(
                  child: Container(
                      alignment: Alignment.center,
                      child: Text(title,
                          textAlign: TextAlign.center,
                          style: title != 'Browse Menu'
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
          persistentFooterButtons: [
            BottomButton(
//OnTapNeedsToWorkOnlyIfSomeItemHasBeenAdded
//WeMoveToAddedItemsPageWithAllInputsBecause,,
//IncaseTheWaiterNeedsToComeBackToTheMainPage
//WeCouldGetAllInputsStraightAway
              onTap: () {
                if (itemsAddedMap.isNotEmpty) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddedItemsWithCaptainInfo(
                        hotelName: widget.hotelName,
                        tableOrParcel: widget.tableOrParcel,
                        tableOrParcelNumber: widget.tableOrParcelNumber,
                        menuItems: localMenuItems,
                        menuPrices: localMenuPrice,
                        menuTitles: localMenuTitles,
                        itemsAddedMap: itemsAddedMap,
                        itemsAddedComment: itemsAddedComment,
                        itemsAddedTime: itemsAddedTime,
                        unavailableItems: localUnavailableItems,
                        parentOrChild: widget.parentOrChild,
                        alreadyRunningTicketsMap:
                            widget.alreadyRunningTicketsMap,
                      ),
                    ),
                  );
                }
              },
//ButtonTitleWillBeConfirmYourOrders
              buttonTitle: 'Confirm Your Orders',
              buttonColor: kBottomContainerColour,
            )
          ],
        ),
      ),
    );
  }
}

//ThisIsForTheSearchButton

class CustomSearchDelegate extends SearchDelegate {
  // Demo list to show querying
//TheseAreTheSearchTerms,
//WeDon'tWantItemsThatAreUnavailable,SoWeUse SetFrom(localMenuItems)toDifference
//from setFrom(UnavailableItems)AndMakeItIntoAList
  List<String> searchTerms = List.from(
      (Set.from(localMenuItems).difference(Set.from(localUnavailableItems))));

  // first overwrite to
  // clear the search text
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      query != ''
          ? IconButton(
              onPressed: () {
                query = '';
              },
//WeUseDeleteIconForThat
              icon: const Icon(
                Icons.delete,
                color: kAppBarBackIconColor,
              ),
            )
          : SizedBox.shrink(),
    ];
  }

  // second overwrite to pop out of search menu
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        query = '';
        close(context, null);
      },
      icon: const Icon(
        Icons.arrow_back,
        color: kAppBarBackIconColor,
      ),
    );
  }

  // third overwrite to show query result
  @override
  Widget buildResults(BuildContext context) {
//TookThisLoopOutOfNet,ThatHadFruit-Didn'tCareToChangeIt
//WhateverMatchesWithTheQuery(WeSearchInLowerCase),
//WillBeAddedToThe MatchQueryList
    List<String> matchQuery = [];
    for (var fruit in searchTerms) {
      if (fruit.toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(fruit);
      }
    }

    return Column(
      children: [
        Expanded(
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
//ThisWillWrittenListViewWithWhateverThatHadMatched
              return ListView.builder(
                  itemCount: matchQuery.length,
                  itemBuilder: (context, index) {
                    var result = matchQuery[index];
                    return Container(
                      margin: EdgeInsets.fromLTRB(5, 5, 0, 10),
//SimilarToTheClassAbove,WeHaveDifferentFontForHeadings
                      child: ListTile(
                        tileColor: Colors.white54,
                        title: localMenuTitles.contains(result)
                            ? Text(
                                result,
                                style: Theme.of(context).textTheme.headline6,
                              )
                            : Text(result),
//ForTitlesWeDon'tShowPriceButToTheOthersWeShow
                        subtitle: localMenuTitles.contains(result)
                            ? null
                            : Text(
                                (localMenuPrice[localMenuItems.indexOf(result)])
                                    .toString()),
//UnlikeTheLastClass,Didn'tMakeAnAddButtonMethod
//ItWasHardToUseMethodInMultiplePlaces
//SoInTrailing,WroteDownTheEntireAddButtonMethodWithTheHelpOfTernaryOperator
//TheFunctionOfThisAddButtonIsSameAsTheOtherAddButton
                        trailing: localMenuTitles.contains(result)
                            ? null
                            : itemsAddedMap.containsKey(result)
                                ? Container(
                                    decoration: kMenuAddButtonDecoration,
                                    height: kMenuButtonHeight,
                                    width: kMenuButtonWidth,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                            onPressed: () {
                                              setState(() {
                                                if (itemsAddedMap[result] ==
                                                    1) {
                                                  itemsAddedMap[result] =
                                                      itemsAddedMap[result]! -
                                                          1;
                                                  itemsAddedMap.remove(result);
                                                  itemsAddedComment
                                                      .remove(result);
                                                  itemsAddedTime.remove(result);
                                                } else {
                                                  itemsAddedMap[result] =
                                                      itemsAddedMap[result]! -
                                                          1;
                                                }
                                              });
                                            },
                                            icon: const Icon(
                                              Icons.remove,
                                              color: Colors.green,
                                              size: kAddMinusButtonIconSize,
                                            )),
                                        Text(
                                          itemsAddedMap[result]!.toString(),
                                          style: kAddButtonNumberTextStyle,
                                        ),
                                        IconButton(
                                            onPressed: () {
                                              setState(() {
                                                itemsAddedMap[result] =
                                                    itemsAddedMap[result]! + 1;
                                              });
                                            },
                                            icon: const Icon(
                                              Icons.add,
                                              color: Colors.green,
                                              size: kAddMinusButtonIconSize,
                                            ))
                                      ],
                                    ),
                                  )
                                : Container(
                                    decoration: kMenuAddButtonDecoration,
                                    height: kMenuButtonHeight,
                                    width: kMenuButtonWidth,
                                    child: TextButton(
                                        onPressed: () {
                                          setState(() {
                                            DateTime now = DateTime.now();
                                            itemsAddedMap.addAll({result: 1});
                                            itemsAddedComment
                                                .addAll({result: ''});
                                            itemsAddedTime.addAll({
                                              result: ((now.hour * 3600000) +
                                                  (now.minute * 60000) +
                                                  (now.second * 1000) +
                                                  now.millisecond)
                                            });
                                          });
                                        },
                                        child: Text(
                                          'ADD',
                                          style: kAddButtonWordTextStyle,
                                        )),
                                  ),
                      ),
                    );
                  });
            },
          ),
        ),
      ],
    );
  }

  // last overwrite to show the
  // querying process at the runtime(ShowHowTheQueryIsFilteringOutTheResults-CommentsSameAsLastOne)
  @override
  Widget buildSuggestions(BuildContext context) {
    List<String> matchQuery = [];
    for (var fruit in searchTerms) {
      if (fruit.toLowerCase().contains(query.toLowerCase())) {
        matchQuery.add(fruit);
      }
    }
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                  itemCount: matchQuery.length,
                  itemBuilder: (context, index) {
                    var result = matchQuery[index];
                    return Container(
                      margin: EdgeInsets.fromLTRB(5, 5, 0, 10),
                      child: ListTile(
                        tileColor: Colors.white54,
                        title: localMenuTitles.contains(result)
                            ? Text(
                                result,
                                style: Theme.of(context).textTheme.headline6,
                              )
                            : Text(result),
                        //
                        subtitle: localMenuTitles.contains(result)
                            ? null
                            : Text(
                                (localMenuPrice[localMenuItems.indexOf(result)])
                                    .toString()),
                        //
                        trailing: localMenuTitles.contains(result)
                            ? null
                            : itemsAddedMap.containsKey(result)
                                ? Container(
                                    decoration: kMenuAddButtonDecoration,
                                    height: kMenuButtonHeight,
                                    width: kMenuButtonWidth,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        IconButton(
                                            onPressed: () {
                                              setState(() {
                                                if (itemsAddedMap[result] ==
                                                    1) {
                                                  itemsAddedMap[result] =
                                                      itemsAddedMap[result]! -
                                                          1;
                                                  itemsAddedMap.remove(result);
                                                  itemsAddedComment
                                                      .remove(result);
                                                  itemsAddedTime.remove(result);
                                                } else {
                                                  setState(() {
                                                    itemsAddedMap[result] =
                                                        itemsAddedMap[result]! -
                                                            1;
                                                  });
                                                }
                                              });
                                            },
                                            icon: const Icon(
                                              Icons.remove,
                                              color: Colors.green,
                                              size: kAddMinusButtonIconSize,
                                            )),
                                        Text(
                                          itemsAddedMap[result]!.toString(),
                                          style: kAddButtonNumberTextStyle,
                                        ),
                                        IconButton(
                                            onPressed: () {
                                              setState(() {
                                                itemsAddedMap[result] =
                                                    itemsAddedMap[result]! + 1;
                                              });
                                            },
                                            icon: const Icon(
                                              Icons.add,
                                              color: Colors.green,
                                              size: kAddMinusButtonIconSize,
                                            ))
                                      ],
                                    ),
                                  )
                                : Container(
                                    decoration: kMenuAddButtonDecoration,
                                    height: kMenuButtonHeight,
                                    width: kMenuButtonWidth,
                                    child: TextButton(
                                        onPressed: () {
                                          setState(() {
                                            DateTime now = DateTime.now();
                                            itemsAddedMap.addAll({result: 1});
                                            itemsAddedComment
                                                .addAll({result: ''});
                                            itemsAddedTime.addAll({
                                              result: ((now.hour * 3600000) +
                                                  (now.minute * 60000) +
                                                  (now.second * 1000) +
                                                  now.millisecond)
                                            });
                                          });
                                        },
                                        child: Text(
                                          'ADD',
                                          style: kAddButtonWordTextStyle,
                                        )),
                                  ),
                      ),
                    );
                  }),
            ),
          ],
        );
      },
    );
  }
}
