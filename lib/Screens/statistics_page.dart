import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:orders_dev/constants.dart';

//ThisIsThePageWhereWeGetTheStatistics,TheOnlyInputBeingHotelName
class StatisticsPage extends StatefulWidget {
  final String hotelName;

  const StatisticsPage({Key? key, required this.hotelName}) : super(key: key);

  @override
  _StatisticsPageState createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
//WeInitiallyMakeTheBasicLists
//PuttingSomeNumbersInDays&MonthsJustForFunRegisteringOnWhatDayIDidThisIn2022
//ButYearsIAmKeepingEmptyBecauseThatIsSomethingICheckInInitState
  List<String> years = [];
  List<String> months = ['07'];
  List<String> days = ['05'];
  List<String> distinctYears = ['1', '2'];
  List<String> startMonthsForDropDown = ['1', '2'];
  List<String> startDaysForDropDown = ['1', '2'];
  List<String> endMonthsForDropDown = ['1', '2'];
  List<String> endDaysForDropDown = ['1', '2'];
//AndWeHaveSeparateStartYear/Month/Day Strings
  String startSelectedYear = '2022';
  String startSelectedMonth = '07';
  String startSelectedDay = '25';
  String endSelectedYear = '2022';
  String endSelectedMonth = '07';
  String endSelectedDay = '25';

  List<Map> allDataInList = [];

  Map<String, num> allStatsAdded = HashMap();
  List<String> statsNameList = [];
  List<String> statsNumberList = [];

  @override
  void initState() {
    // TODO: implement initState
//WeCheckWhetherYearsIsEmpty&IfYes,iCallThisMethod
    if (years.isEmpty) {
      getStatistics();
    }

    super.initState();
  }

  void getStatistics() async {
//QueryToGetAllTheDataFromStatisticsCollectionWithHotelName
    final completeStatistics = await FirebaseFirestore.instance
        .collection(widget.hotelName)
        .doc('statistics')
        .collection('statistics')
        .get();
//FirstWeKeepYears/Months/DaysAs0
    years = [];
    months = [];
    days = [];
//TheDocOfEachStatisticForEachDayIsStoredAsForExample 2022*01*01
    //year/Month/Day
//ByUsingSplit, weCanSplitBetween *
//TheFirstOneWillBeYear,SecondOneMonths,ThirdOneDay,,WeSaveThemAllInAList
    for (var eachStatistic in completeStatistics.docs) {
      allDataInList.add(eachStatistic.data());
      final splitted = eachStatistic.id.split('*');
      years.add(splitted[0]);
      months.add(splitted[1]);
      days.add(splitted[2]);
    }
//YearsAloneWeGetDistinctYears
    distinctYears = years.toSet().toList();
//BasedOnWhichYearIsSelected,WeCallTheMethodWhichChoosesMonthsInThatYear
//WeCallTheStartMonthsForDropDownListMethod&EndMonthsForDropDownListMethod
    setState(() {
      startSelectedYear = distinctYears.last;
      endSelectedYear = distinctYears.last;
      startMonthsForDropdownList();
      endMonthsForDropDown = startMonthsForDropDown;
      startSelectedMonth = startMonthsForDropDown.last;
      endSelectedMonth = endMonthsForDropDown.last;
      startDaysForDropdownList();
      endDaysForDropDown = startDaysForDropDown;
      startSelectedDay = startDaysForDropDown.last;
      endSelectedDay = endDaysForDropDown.last;
    });
  }

//WithThisMethodWeFigureOutTheStartMonthsForTheChosenYear
  List<String> startMonthsForDropdownList() {
    List<String> yearMonths = [];
    for (int i = 0; i < years.length; i++) {
      if (years[i] == startSelectedYear) {
        yearMonths.add(months[i]);
      }
    }

    return startMonthsForDropDown = yearMonths.toSet().toList();
  }

//WithThisMethodWeFigureOutTheEndMonthsForTheChosenYear
  List<String> endMonthsForDropdownList() {
    List<String> yearMonths = [];
    for (int i = 0; i < years.length; i++) {
      if (years[i] == endSelectedYear) {
        yearMonths.add(months[i]);
      }
    }

    return endMonthsForDropDown = yearMonths.toSet().toList();
  }

//WithThisMethodWeFigureOutTheStartDayForTheChosenMonth
  List<String> startDaysForDropdownList() {
    startDaysForDropDown = [];
    for (int i = 0; i < years.length; i++) {
      if (years[i] == startSelectedYear && months[i] == startSelectedMonth) {
        startDaysForDropDown.add(days[i]);
      }
    }

    return startDaysForDropDown;
  }

//WithThisMethodWeFigureOutTheEndDayForTheChosenMonth
  List<String> endDaysForDropdownList() {
    endDaysForDropDown = [];
    for (int i = 0; i < years.length; i++) {
      if (years[i] == endSelectedYear && months[i] == endSelectedMonth) {
        endDaysForDropDown.add(days[i]);
      }
    }

    return endDaysForDropDown;
  }

//ThroughThisMapWeGoThroughTheStatsForTheMonths&DaysSelected&
//AddAllTheStatsInThoseMonths
  void listViewStatsMap() {
    allStatsAdded = {};
    int startIndex = 1;
    int endIndex = 1;
    for (int i = 0; i < years.length; i++) {
      if (startSelectedYear == years[i] &&
          startSelectedMonth == months[i] &&
          startSelectedDay == days[i]) {
        startIndex = i;
      }
      if (endSelectedYear == years[i] &&
          endSelectedMonth == months[i] &&
          endSelectedDay == days[i]) {
        endIndex = i;
      }
    }

    for (int j = startIndex; j <= endIndex; j++) {
      Map temporaryMap = allDataInList[j];
      temporaryMap.forEach((key, value) {
        if (allStatsAdded.containsKey(key)) {
          allStatsAdded[key] = allStatsAdded[key]! + value;
        } else {
          allStatsAdded.addAll({key: value});
        }
      });
    }

    Map<String, num> exceptItemsMap = {};
    num totalNumberOfOrders = 0;
    num totalParcels = 0;
    num totalDiscount = 0;
    if (allStatsAdded.containsKey('totalbillamounttoday')) {
      exceptItemsMap
          .addAll({'Total Sales': allStatsAdded['totalbillamounttoday']!});
      allStatsAdded.remove('totalbillamounttoday');
    }

    //IfThereAreNoItemsPaymentDoneInADayAndSerialNumberAloneWasAddedWhilePrinting
//WeWillShowSerialNumberAlone.ElseWeWontShowAnySerialNumber
    if (allStatsAdded.containsKey('serialNumber') &&
        !allStatsAdded.containsKey('totalnumberoforders')) {
      exceptItemsMap.addAll(
          {'Total Serial Numbers': allStatsAdded['serialNumber']!.round()});
    }
//AfterThisWeCanAnyWayRemoveSerialNumber
    allStatsAdded.remove('serialNumber');
    if (allStatsAdded.containsKey('totaldiscount')) {
      totalNumberOfOrders = allStatsAdded['totaldiscount']!.round();
      exceptItemsMap
          .addAll({'Total Discount': allStatsAdded['totaldiscount']!.round()});
      allStatsAdded.remove('totaldiscount');
    }
    if (allStatsAdded.containsKey('totalnumberoforders')) {
      totalNumberOfOrders = allStatsAdded['totalnumberoforders']!.round();
      exceptItemsMap.addAll(
          {'Total Orders': allStatsAdded['totalnumberoforders']!.round()});
    }

    if (allStatsAdded.containsKey('totalnumberoforders')) {
      if (allStatsAdded.containsKey('numberofparcel')) {
        totalParcels = allStatsAdded['numberofparcel']!;
        exceptItemsMap.addAll({
          '     Total Dine-Ins': (totalNumberOfOrders - totalParcels).round()
        });
        exceptItemsMap.addAll(
            {'     Total Parcels': allStatsAdded['numberofparcel']!.round()});
        allStatsAdded.remove('numberofparcel');
      } else {
        exceptItemsMap.addAll({
          '     Total Dine-Ins': (totalNumberOfOrders - totalParcels).round()
        });

        exceptItemsMap.addAll({'     Total Parcels': totalParcels.round()});
      }
      allStatsAdded.remove('totalnumberoforders');
    }

    Map<String, num> temporaryMapToRoundOff = HashMap();
    temporaryMapToRoundOff = {};
    allStatsAdded.forEach((key, value) {
      temporaryMapToRoundOff.addAll({key: value.round()});
    });

    var ascendingMapEntries = temporaryMapToRoundOff.entries.toList()
      ..sort((b, a) => a.value.compareTo(b.value));

    allStatsAdded
      ..clear()
      ..addAll(exceptItemsMap)
      ..addEntries(ascendingMapEntries);

    statsNameList = [];
    statsNumberList = [];

    allStatsAdded.forEach((key, value) {
      statsNameList.add(key);
      statsNumberList.add(value.toString());
    });
    setState(() {
      statsNumberList;
      statsNameList;
    });
  }

  @override
  Widget build(BuildContext context) {
//WillPopScreenJustToPopIfPhoneBackButtonIsPressed
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
          appBar: AppBar(
//ThisForScreenToPopIfAppbarBackButtonIsPressed
            leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: kAppBarBackIconColor),
                onPressed: () async {
                  Navigator.pop(context);
                }),
            backgroundColor: kAppBarBackgroundColor,
//TheAwesomeTitleThatIKept
            title: const Text(
              'Know Thyself',
              style: kAppBarTextStyle,
            ),
            centerTitle: true,
          ),
//IfYearsIsEmpty,ItMeansWeDon'tYetHaveTheData
          body: years.isEmpty
              ? Center(
                  child: Container(
                  child: Text('No Data Available Yet'),
                ))
              : Column(
//IfDataAvailable,ThenWeFirstHaveStartDate,EndDateWords
//UnderWhichWeSayYear,Month,Day,
//UnderWhichWeHaveDropDownButtonsForYears,Months,Days
//basedOnWhichYearIsSelected,WeWillSelectTheMonthsToDisplayAnd
//basedOnWhichMonthIsSelected,WeWillSelectTheDaysToDisplay
                  children: [
                    SizedBox(height: 10.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: const [Text('Start Date'), Text('End Date')],
                    ),
                    SizedBox(height: 10.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: const [
                        Text('Year'),
                        Text('Month'),
                        Text('Day'),
                        Text('Year'),
                        Text('Month'),
                        Text('Day'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        DropdownButton(
                          elevation: 9,
                          value: startSelectedYear,
                          onChanged: (value) {
                            setState(() {
                              startSelectedYear = value.toString();
                              startMonthsForDropdownList();
                              startSelectedMonth = startMonthsForDropDown.last;
                              startDaysForDropdownList();
                              startSelectedDay = startDaysForDropDown.last;
                            });
                          },
                          items: distinctYears.map((year) {
                            return DropdownMenuItem(
                              child: Text(year),
                              value: year,
                            );
                          }).toList(),
                        ),
                        DropdownButton(
                          elevation: 9,
                          value: startSelectedMonth,
                          onChanged: (value) {
                            setState(() {
                              startSelectedMonth = value.toString();
                              startDaysForDropdownList();
                              startSelectedDay = startDaysForDropDown.last;
                            });
                          },
                          items: startMonthsForDropDown.map((month) {
                            return DropdownMenuItem(
                              child: Text(month),
                              value: month,
                            );
                          }).toList(),
                        ),
                        DropdownButton(
                          elevation: 9,
                          value: startSelectedDay,
                          onChanged: (value) {
                            setState(() {
                              startSelectedDay = value.toString();
                            });
                          },
                          items: startDaysForDropDown.map((day) {
                            return DropdownMenuItem(
                              child: Text(day),
                              value: day,
                            );
                          }).toList(),
                        ),
                        DropdownButton(
                          elevation: 9,
                          value: endSelectedYear,
                          onChanged: (value) {
                            setState(() {
                              endSelectedYear = value.toString();
                              endMonthsForDropdownList();
                              endSelectedMonth = endMonthsForDropDown.last;
                              endDaysForDropdownList();
                              endSelectedDay = endDaysForDropDown.last;
                            });
                          },
                          items: distinctYears.map((year) {
                            return DropdownMenuItem(
                              child: Text(year),
                              value: year,
                            );
                          }).toList(),
                        ),
                        DropdownButton(
                          elevation: 9,
                          value: endSelectedMonth,
                          onChanged: (value) {
                            setState(() {
                              endSelectedMonth = value.toString();
                              endDaysForDropdownList();
                              endSelectedDay = endDaysForDropDown.last;
                            });
                          },
                          items: endMonthsForDropDown.map((month) {
                            return DropdownMenuItem(
                              child: Text(month),
                              value: month,
                            );
                          }).toList(),
                        ),
                        DropdownButton(
                          elevation: 9,
                          value: endSelectedDay,
                          onChanged: (value) {
                            setState(() {
                              endSelectedDay = value.toString();
                            });
                          },
                          items: endDaysForDropDown.map((day) {
                            return DropdownMenuItem(
                              child: Text(day),
                              value: day,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
//UnderTheDropDownWeHaveShowStatsButtonAndIfItIsPressed,WeCallListViewStatsMap
//WhichWillCalculateAllDataAndFeedItIntoTheListViewBuilderUnder
                    Center(
                        child: TextButton(
                            onPressed: () {
                              listViewStatsMap();
                            },
                            child: Text(
                              'Show Stats',
                              style: TextStyle(
                                  color: Colors.green.shade500, fontSize: 20.0),
                            ))),
                    statsNameList.isEmpty
                        ? SizedBox(height: 1.0)
                        : Expanded(
                            child: ListView.builder(
                                itemCount: statsNameList.length,
                                itemBuilder: (context, index) {
                                  final item = statsNameList[index];
                                  final itemNumber = statsNumberList[index];
                                  return Container(
                                    decoration:
                                        kMenuStatisticsContainerDecoration,
                                    child: ListTile(
                                      title: Text(item),
                                      trailing: Text(itemNumber),
                                    ),
                                  );
                                }),
                          ),
                  ],
                )),
    );
  }
}
