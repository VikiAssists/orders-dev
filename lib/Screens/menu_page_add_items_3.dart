import 'dart:async';
import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:orders_dev/Methods/bottom_button.dart';
import 'package:orders_dev/constants.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'added_items_list_from_menu_5.dart';

//WeMakeLocalVersionOfPrices/Titles/UnavailableItemsBecause
//WeNeedAllThisDataInSearchScreenToo
//ByKeepingTheseVariablesOutside,WeCanGetDataToTheSearchScreen
List<String> localMenuItems = [];
List<num> localMenuPrice = [];
List<String> localMenuTitles = [];
List<String> localUnavailableItems = [];
Map<String, num> itemsAddedMap = HashMap();
Map<String, String> itemsAddedComment = HashMap();

//ThisIsThePageWeAlwaysCallForWhenWeNeedMenu
//TheInputsWillBeMenuPrices,Titles,Items,UnavailableItems(FromInventory)
//WeHaveAnItemsAddedMap-HashMapToPutWhateverTheWaiterIsSelecting

class MenuPageWithSplit extends StatefulWidget {
  final String hotelName;
  final String tableOrParcel;
  final num tableOrParcelNumber;
  final List<String> menuItems;
  final List<num> menuPrices;
  final List<String> menuTitles;
  final List<String> unavailableItems;
  Map<String, num> itemsAddedMapCalled = HashMap();
  Map<String, String> itemsAddedCommentCalled = HashMap();
  final String addedItemsSet;
  final String parentOrChild;

  MenuPageWithSplit(
      {required this.hotelName,
      required this.tableOrParcel,
      required this.tableOrParcelNumber,
      required this.menuItems,
      required this.menuPrices,
      required this.menuTitles,
      required this.unavailableItems,
      required this.itemsAddedMapCalled,
      required this.itemsAddedCommentCalled,
      required this.addedItemsSet,
      required this.parentOrChild});

  @override
  _MenuPageWithSplitState createState() => _MenuPageWithSplitState();
}

class _MenuPageWithSplitState extends State<MenuPageWithSplit> {
  final ItemScrollController _itemScrollController = ItemScrollController();

  @override
  void initState() {
//WeNeedLocalVersionOfAllDataForTheSearchScreen
//WeSaveAllTheDataHere
    localMenuTitles = [];
    localMenuPrice = [];
    localMenuItems = [];
    localUnavailableItems = [];
    itemsAddedMap = {};

    // TODO: implement initState
    for (var item in widget.menuItems) {
      localMenuItems.add(item);
    }

    for (var price in widget.menuPrices) {
      localMenuPrice.add(price);
    }
    for (var title in widget.menuTitles) {
      localMenuTitles.add(title);
    }
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
    }
//FillingTheLocalVersionOfUnavailableItems
    if (widget.unavailableItems.isNotEmpty) {
      for (var unavailableItem in widget.unavailableItems) {
        localUnavailableItems.add(unavailableItem);
      }
    } else {
//IfUnavailableItemsListIsEmpty,WeJustCheckOnceWithTheBelowMethod
      unavailableItemsMethod();
    }

    super.initState();
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

//ThisIsTheButtonInTheSideWhereWeAdd/MinusTheNumberOfItems
//WrittenExplanationIn "added_items_list" page
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
                itemsAddedMap.addAll({item: 1});
                itemsAddedComment.addAll({item: ''});
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

  @override
  Widget build(BuildContext context) {
    const title = 'Menu';
    return WillPopScope(
//ForBackButtonInPhone
//IfWeClickBackFromMenu,WeNeedToRemoveEverythingInItemsAddedMapAndExitScreen
//IfWeDon'tDoIt,itWasObservedThatIfTheWaiterGoesToAnotherTable&Menu,,
//TheseAddedItemsIsShowingThere
      onWillPop: () async {
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
            Navigator.pop(context);
          }
        });
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
                int _everyMilliSecondBeforeGoingBack = 0;
                Timer? _timerAtBackButton;
                _timerAtBackButton =
                    Timer.periodic(Duration(milliseconds: 100), (_) {
                  itemsAddedMap = {};
                  widget.itemsAddedMapCalled = {};
                  print('back timer is $_everyMilliSecondBeforeGoingBack');
                  // return false;
                  _everyMilliSecondBeforeGoingBack++;
                  if (_everyMilliSecondBeforeGoingBack >= 4) {
                    print(
                        'back timer at cancel is $_everyMilliSecondBeforeGoingBack');
                    _timerAtBackButton!.cancel();
                    Navigator.pop(context);
                  }
                });
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
                      margin: EdgeInsets.fromLTRB(5, 5, 0, 10),
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
                      alignment: Alignment.centerLeft,
                      child: Center(
                        child: Text(title,
                            style: const TextStyle(
                                fontSize: 15, color: Colors.white)),
                      )),
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
                      builder: (context) => AddedItemsFromMenuPrintChange(
                        hotelName: widget.hotelName,
                        tableOrParcel: widget.tableOrParcel,
                        tableOrParcelNumber: widget.tableOrParcelNumber,
                        menuItems: localMenuItems,
                        menuPrices: localMenuPrice,
                        menuTitles: localMenuTitles,
                        itemsAddedMap: itemsAddedMap,
                        itemsAddedComment: itemsAddedComment,
                        unavailableItems: localUnavailableItems,
                        addedItemsSet: widget.addedItemsSet,
                        parentOrChild: widget.parentOrChild,
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
      IconButton(
        onPressed: () {
          query = '';
        },
//WeUseClearIconForThat
        icon: const Icon(
          Icons.clear,
          color: kAppBarBackIconColor,
        ),
      ),
    ];
  }

  // second overwrite to pop out of search menu
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
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
                                            itemsAddedMap.addAll({result: 1});
                                            itemsAddedComment
                                                .addAll({result: ''});
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
                                            itemsAddedMap.addAll({result: 1});
                                            itemsAddedComment
                                                .addAll({result: ''});
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
