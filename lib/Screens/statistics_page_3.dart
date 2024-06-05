import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:orders_dev/constants.dart';
import 'package:provider/provider.dart';

class StatisticsWithExpensesAndIncome extends StatefulWidget {
  const StatisticsWithExpensesAndIncome({Key? key}) : super(key: key);

  @override
  State<StatisticsWithExpensesAndIncome> createState() =>
      _StatisticsWithExpensesAndIncomeState();
}

class _StatisticsWithExpensesAndIncomeState
    extends State<StatisticsWithExpensesAndIncome> {
  final _fireStore = FirebaseFirestore.instance;
  String startDateText = DateFormat('dd-MM-yyyy').format(DateTime.now());
  String endDateText = DateFormat('dd-MM-yyyy').format(DateTime.now());
  List<Query> queries = [];
  Map<int, dynamic> savedStatisticsMonthData = HashMap();
  Map<int, dynamic> savedStatisticsDayData = HashMap();
  bool noDataFound = false;
  Map<int, dynamic> calculationMonthsDataRequired = HashMap();
  Map<int, dynamic> calculationDaysDataRequired = HashMap();
  List<Map<String, dynamic>> totalExpenseOfEachItem = [];
  List<Map<String, dynamic>> totalExpenseByEachUser = [];
  List<Map<String, dynamic>> totalExpenseByEachPaymentMethod = [];
  bool viewClicked = false;
  bool showSpinner = false;
  final scrollController = ScrollController();
  StreamSubscription<QuerySnapshot>? _streamSubscriptionDataCheck;
  String thisIsTheText = 'Text varuma?';
  TextEditingController _salesIncomeStatsText = TextEditingController();
  TextEditingController _expensesStatsText = TextEditingController();

  DateTimeRange dateRange = DateTimeRange(
      start: DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day),
      end: DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day));
  Future pickDateRange() async {
    DateTimeRange? newDateRange = await showDateRangePicker(
        initialEntryMode: DatePickerEntryMode.calendarOnly,
        saveText: 'Proceed',
        builder: (context, child) {
          return Theme(
              data: Theme.of(context).copyWith(
                  dialogTheme: DialogTheme(
                      shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        16.0), // this is the border radius of the picker
                  )),
                  colorScheme: ColorScheme(
                      brightness: Brightness.light,
                      primary: Colors.green,
                      onPrimary: Colors.black,
                      secondary: Colors.white,
                      onSecondary: Colors.white,
                      error: Colors.red,
                      onError: Colors.black,
                      background: Colors.white,
                      onBackground: Colors.black,
                      surface: Colors.white,
                      onSurface: Colors.black)),
              child: child!);
        },
        context: context,
        initialDateRange: dateRange,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (newDateRange == null) return;

    setState(() {
      dateRange = newDateRange;
    });
  }

//   void statisticsReportsQueryGeneration() {
//     calculationMonthsDataRequired = {};
//     calculationDaysDataRequired = {};
//     queries = [];
//     int startDateMilliSeconds = DateTime(
//             dateRange.start.year, dateRange.start.month, dateRange.start.day)
//         .millisecondsSinceEpoch;
//     int endDateMilliSeconds =
//         DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day)
//             .millisecondsSinceEpoch;
//
//     for (int iterationYear = dateRange.start.year;
//         iterationYear <= dateRange.end.year;
//         iterationYear++) {
//       int iterationStartMonth = 1;
//       List<int> monthsDataNeededArray = [];
//       List<int> monthsDataNotNeededArray = [];
//       Map yearDataInSavedMonthData = HashMap();
//       Map yearDataInSavedDayData = HashMap();
//       if (savedExpensesMonthData.containsKey(iterationYear)) {
//         yearDataInSavedMonthData = savedExpensesMonthData[iterationYear];
//       }
//       if (savedExpensesDayData.containsKey(iterationYear)) {
//         yearDataInSavedDayData = savedExpensesDayData[iterationYear];
//       }
//       for (iterationStartMonth = 1;
//           iterationStartMonth <= 12;
//           iterationStartMonth++) {
// //ThisLoopToRunThroughMonths
//         if ((DateTime(iterationYear, iterationStartMonth, 1)
//                     .millisecondsSinceEpoch >=
//                 startDateMilliSeconds) && //ThisMeansMonthStartsWithOne
//             ((DateTime(
//                             iterationYear,
//                             iterationStartMonth,
//                             DateUtils.getDaysInMonth(
//                                 iterationYear, iterationStartMonth))
//                         .millisecondsSinceEpoch <=
//                     endDateMilliSeconds)
// //ThisMeansWeAreCheckingWhetherTheEntireMonthIsCovered
//                 ||
// //ThisMeansWeAreCheckingInCaseTheEntireMonthIsNotCovered,WhetherTheLastRequested
// //DateIsToday'sDateSoThatWeCanStillQueryTheEntireMonth
//                 ((DateTime(DateTime.now().year, DateTime.now().month,
//                                 DateTime.now().day)
//                             .millisecondsSinceEpoch ==
//                         endDateMilliSeconds) &&
//                     (DateTime(DateTime.now().year, DateTime.now().month,
//                                 DateTime.now().day)
//                             .millisecondsSinceEpoch ==
//                         DateTime(iterationYear, iterationStartMonth,
//                                 DateTime.now().day)
//                             .millisecondsSinceEpoch)))) {
//           monthsDataNeededArray.add(iterationStartMonth);
//           if (yearDataInSavedMonthData.containsKey(iterationStartMonth)) {
//             monthsDataNotNeededArray.add(iterationStartMonth);
//           }
//         } else if ( //ThisMeansWholeMonthIsNotNeededAndWeNeedDailyBasedQueries
//             (startDateMilliSeconds <=
//                     DateTime(
//                             iterationYear,
//                             iterationStartMonth,
//                             DateUtils.getDaysInMonth(
//                                 iterationYear, iterationStartMonth))
//                         .millisecondsSinceEpoch) &&
//                 (endDateMilliSeconds >=
//                     DateTime(iterationYear, iterationStartMonth, 1)
//                         .millisecondsSinceEpoch)) {
//           List<int> daysDataNeededArray = [];
//           List<int> daysDataNotNeededArray = [];
// //ThisIsTheTemporaryCalculationDaysNeededInThisYearWhichWeWillMerge
// //WithMainCalculationDaysAtTheEndOfEachMonthIteration
//           List<int> tempCalculationDaysNeededInThisYear = [];
//           if (calculationDaysDataRequired.containsKey(iterationYear)) {
//             tempCalculationDaysNeededInThisYear =
//                 calculationDaysDataRequired[iterationYear];
//           }
// //ThisLoopRunsTheLoopForDaysAndUnderstandsExactlyWhichDaysAreNeeded
//           for (int iterationStartDay = 1;
//               iterationStartDay <=
//                   DateUtils.getDaysInMonth(iterationYear, iterationStartMonth);
//               iterationStartDay++) {
//             if ((DateTime(iterationYear, iterationStartMonth, iterationStartDay)
//                         .millisecondsSinceEpoch >=
//                     startDateMilliSeconds) &&
//                 (DateTime(iterationYear, iterationStartMonth, iterationStartDay)
//                         .millisecondsSinceEpoch <=
//                     endDateMilliSeconds)) {
// //ThisMeansThisDayIsNeeded
//               daysDataNeededArray.add(iterationStartDay);
//               int dayNumberFromNewYear = DateTime(
//                           iterationYear, iterationStartMonth, iterationStartDay)
//                       .difference(DateTime(iterationYear))
//                       .inDays +
//                   1;
// //ThisDateWillAlsoBeRequiredForCalculation
//               tempCalculationDaysNeededInThisYear.add(dayNumberFromNewYear);
//               if (yearDataInSavedDayData.containsKey(dayNumberFromNewYear)) {
// //ThisMeansWeAlreadyHaveTheData
//                 daysDataNotNeededArray.add(iterationStartDay);
//               }
//             }
//           }
//           if (tempCalculationDaysNeededInThisYear.isNotEmpty) {
// //WeMergeWithTheAlreadyExistingCalculationDaysAndSaveItInMap
//             calculationDaysDataRequired[iterationYear] =
//                 tempCalculationDaysNeededInThisYear;
//           }
//           if ((daysDataNeededArray.last - daysDataNeededArray.first + 1) >
//               daysDataNotNeededArray.length) {
// //ThisMeansThatNotAllDataExistsAndSomeDataIsNeeded
// //ToEnsureZeroIsBehindTheMonthAndDay
//             String monthInString = iterationStartMonth.toString().length == 1
//                 ? '0${iterationStartMonth.toString()}'
//                 : iterationStartMonth.toString();
//             Query dayQuery = _fireStore
//                 .collection(Provider.of<PrinterAndOtherDetailsProvider>(context,
//                         listen: false)
//                     .chosenRestaurantDatabaseFromClass)
//                 .doc('reports')
//                 .collection('dailyReports')
//                 .doc(iterationYear.toString())
//                 .collection(monthInString)
//                 .where('day', isGreaterThanOrEqualTo: daysDataNeededArray.first)
//                 .where('day', isLessThanOrEqualTo: daysDataNeededArray.last);
//             if (daysDataNotNeededArray.length > 0) {
// //ThisMeansWeDontNeedSomeDataAmongTheDays
//               for (var eachNotNeededDay in daysDataNotNeededArray) {
//                 dayQuery.where('day', isNotEqualTo: eachNotNeededDay);
//               }
//             }
//             queries.add(dayQuery);
//           }
//         }
//       }
// //ThisWillGiveTheMonthsThatNeedsCalculationInThatYearForFinalCalculation
//       if (monthsDataNeededArray.isNotEmpty) {
//         calculationMonthsDataRequired
//             .addAll({iterationYear: monthsDataNeededArray});
//
//         if ((monthsDataNeededArray.last - monthsDataNeededArray.first + 1) >
//             monthsDataNotNeededArray.length) {
// //ThisMeansThatNotAllDataExistsAndSomeDataIsNeeded
//
//           Query monthQuery = _fireStore
//               .collection(Provider.of<PrinterAndOtherDetailsProvider>(context,
//                       listen: false)
//                   .chosenRestaurantDatabaseFromClass)
//               .doc('reports')
//               .collection('monthlyReports')
//               .doc(iterationYear.toString())
//               .collection('month')
//               .where('month',
//                   isGreaterThanOrEqualTo: monthsDataNeededArray.first)
//               .where('month', isLessThanOrEqualTo: monthsDataNeededArray.last);
//
//           if (monthsDataNotNeededArray.length > 0) {
// //ThisMeansWeDontNeedSomeDataAmongTheDays
//             for (var eachNotNeededMonth in monthsDataNotNeededArray) {
//               monthQuery.where('month', isNotEqualTo: eachNotNeededMonth);
//             }
//           }
//           queries.add(monthQuery);
//         }
//       }
//     }
//     if (queries.length > 0) {
//       executeQueries();
//     } else {
//       dataCalculation();
//     }
//   }

  void statisticsReportsQueryGenerationVersionTwo() {
    print('dgfgdf1');
    queries = [];
    List<int> neededMidMonthMilliseconds = [];
    List<int> notNeededMidMonthMilliseconds = [];
    int startDateMilliSeconds = DateTime(
            dateRange.start.year, dateRange.start.month, dateRange.start.day)
        .millisecondsSinceEpoch;
    int endDateMilliSeconds =
        DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day)
            .millisecondsSinceEpoch;

    for (int iterationYear = dateRange.start.year;
        iterationYear <= dateRange.end.year;
        iterationYear++) {
      int iterationStartMonth = 1;
      Map yearDataInSavedMonthData = HashMap();
      Map yearDataInSavedDayData = HashMap();
      if (savedStatisticsMonthData.containsKey(iterationYear)) {
        yearDataInSavedMonthData = savedStatisticsMonthData[iterationYear];
      }
      if (savedStatisticsDayData.containsKey(iterationYear)) {
        yearDataInSavedDayData = savedStatisticsDayData[iterationYear];
      }
      for (iterationStartMonth = 1;
          iterationStartMonth <= 12;
          iterationStartMonth++) {
//FirstStepIsToJustGetMonthsAlone.WeNeedToDownloadAllMonthsThatWeTouch
//SinceWeNeedTheStartAndEndMonthCashBalanceDataAnyway
        if ( //ThisMeansSomeDataInThisMonthIsNeeded.SoWeGetTheEntireMonth
            (startDateMilliSeconds <=
                    DateTime(
                            iterationYear,
                            iterationStartMonth,
                            DateUtils.getDaysInMonth(
                                iterationYear, iterationStartMonth))
                        .millisecondsSinceEpoch) &&
                (endDateMilliSeconds >=
                    DateTime(iterationYear, iterationStartMonth, 1)
                        .millisecondsSinceEpoch)) {
          if (yearDataInSavedMonthData.containsKey(iterationStartMonth)) {
//ThisMeansNeededMonthDataFirstMonthItselfIsNotTaken
//SoWeDon'tHaveToSpecificallyAddNotNeededAgain
            if (neededMidMonthMilliseconds.isNotEmpty) {
              notNeededMidMonthMilliseconds.add(
                  DateTime(iterationYear, iterationStartMonth, 15)
                      .millisecondsSinceEpoch);
            }
          } else {
            neededMidMonthMilliseconds.add(
                DateTime(iterationYear, iterationStartMonth, 15)
                    .millisecondsSinceEpoch);
          }
        }

//ThisLoopToRunThroughMonths
        if ((DateTime(iterationYear, iterationStartMonth, 1)
                    .millisecondsSinceEpoch >=
                startDateMilliSeconds) && //ThisMeansMonthStartsWithOne
            ((DateTime(
                            iterationYear,
                            iterationStartMonth,
                            DateUtils.getDaysInMonth(
                                iterationYear, iterationStartMonth))
                        .millisecondsSinceEpoch <=
                    endDateMilliSeconds)
//ThisMeansWeAreCheckingWhetherTheEntireMonthIsCovered
                ||
//ThisMeansWeAreCheckingInCaseTheEntireMonthIsNotCovered,WhetherTheLastRequested
//DateIsToday'sDateSoThatWeCanStillQueryTheEntireMonth
                ((DateTime(DateTime.now().year, DateTime.now().month,
                                DateTime.now().day)
                            .millisecondsSinceEpoch ==
                        endDateMilliSeconds) &&
                    (DateTime(DateTime.now().year, DateTime.now().month,
                                DateTime.now().day)
                            .millisecondsSinceEpoch ==
                        DateTime(iterationYear, iterationStartMonth,
                                DateTime.now().day)
                            .millisecondsSinceEpoch)))) {
//WeAreTakingEntireMonthDataInLastStepItself

        } else if ( //ThisMeansWholeMonthIsNotNeededAndWeNeedDailyBasedQueries
            (startDateMilliSeconds <=
                    DateTime(
                            iterationYear,
                            iterationStartMonth,
                            DateUtils.getDaysInMonth(
                                iterationYear, iterationStartMonth))
                        .millisecondsSinceEpoch) &&
                (endDateMilliSeconds >=
                    DateTime(iterationYear, iterationStartMonth, 1)
                        .millisecondsSinceEpoch)) {
          List<int> daysDataNeededArray = [];
          List<int> daysDataNotNeededArray = [];
//ThisLoopRunsTheLoopForDaysAndUnderstandsExactlyWhichDaysAreNeeded
          for (int iterationStartDay = 1;
              iterationStartDay <=
                  DateUtils.getDaysInMonth(iterationYear, iterationStartMonth);
              iterationStartDay++) {
            if ((DateTime(iterationYear, iterationStartMonth, iterationStartDay)
                        .millisecondsSinceEpoch >=
                    startDateMilliSeconds) &&
                (DateTime(iterationYear, iterationStartMonth, iterationStartDay)
                        .millisecondsSinceEpoch <=
                    endDateMilliSeconds)) {
//ThisMeansThisDayIsNeeded
              daysDataNeededArray.add(iterationStartDay);
              int dayNumberFromNewYear = DateTime(
                          iterationYear, iterationStartMonth, iterationStartDay)
                      .difference(DateTime(iterationYear))
                      .inDays +
                  1;

              if (yearDataInSavedDayData.containsKey(dayNumberFromNewYear)) {
//ThisMeansWeAlreadyHaveTheData
                daysDataNotNeededArray.add(iterationStartDay);
              }
            }
          }
          if ((daysDataNeededArray.last - daysDataNeededArray.first + 1) >
              daysDataNotNeededArray.length) {
//ThisMeansThatNotAllDataExistsAndSomeDataIsNeeded
//ToEnsureZeroIsBehindTheMonthAndDay
            String monthInString = iterationStartMonth.toString().length == 1
                ? '0${iterationStartMonth.toString()}'
                : iterationStartMonth.toString();
            Query dayQuery = _fireStore
                .collection(Provider.of<PrinterAndOtherDetailsProvider>(context,
                        listen: false)
                    .chosenRestaurantDatabaseFromClass)
                .doc('reports')
                .collection('dailyReports')
                .doc(iterationYear.toString())
                .collection(monthInString)
                .where('day', isGreaterThanOrEqualTo: daysDataNeededArray.first)
                .where('day', isLessThanOrEqualTo: daysDataNeededArray.last);
            if (daysDataNotNeededArray.length > 0) {
//ThisMeansWeDontNeedSomeDataAmongTheDays
              for (var eachNotNeededDay in daysDataNotNeededArray) {
                dayQuery.where('day', isNotEqualTo: eachNotNeededDay);
              }
            }
            queries.add(dayQuery);
          }
        }
      }
    }
    if (neededMidMonthMilliseconds.isNotEmpty) {
      Query monthQuery = _fireStore
          .collection(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .chosenRestaurantDatabaseFromClass)
          .doc('reports')
          .collection('monthlyReports')
          .where('midMonthMilliSecond',
              isGreaterThanOrEqualTo: neededMidMonthMilliseconds.reduce(min))
          .where('midMonthMilliSecond',
              isLessThanOrEqualTo: neededMidMonthMilliseconds.reduce(max));
      if (notNeededMidMonthMilliseconds.isNotEmpty) {
        for (var eachNotNeededMillisecond in notNeededMidMonthMilliseconds) {
          monthQuery.where('midMonthMilliSecond',
              isNotEqualTo: eachNotNeededMillisecond);
        }
      }
      print('dgfgdf3');
      queries.add(monthQuery);
    }
    if (queries.length > 0) {
      print('dgfgdf2');
      // executeQueries();
      executeQueriesVersionTwo(queries.first);
    } else {
      // dataCalculation();
    }
  }

  void executeQueriesVersionTwo(Query query) {
    _streamSubscriptionDataCheck = query.snapshots().listen((dataSnapshot) {
      Timer(Duration(seconds: 5), () {
        for (var eachMonthStat in dataSnapshot.docs) {
          _salesIncomeStatsText.text =
              eachMonthStat['salesIncomeStats'].toString();
          _expensesStatsText.text = eachMonthStat['expenses'].toString();

          // print('month Data one by one');
          // print('billedCancellationStats');
          // print(eachMonthStat['billedCancellationStats']);
          // print('cashBalanceData');
          // print(eachMonthStat['cashBalanceData']);
          // print('arrayExpenseCategoryArray');
          // print(eachMonthStat['expenses']['arrayExpenseCategoryArray']);
          // print('mapEachExpenseStatisticsMap');
          // print(eachMonthStat['expenses']['mapEachExpenseStatisticsMap']);
          // print('mapExpensePaidByUserMap');
          // print(eachMonthStat['expenses']['mapExpensePaidByUserMap']);
          // print('mapExpensePaymentMethodMap');
          // print(eachMonthStat['expenses']['mapExpensePaymentMethodMap']);
          // print('arraySoldItemsCategoryArray');
          // print(
          //     eachMonthStat['salesIncomeStats']['arraySoldItemsCategoryArray']);
          // print('mapEachCaptainOrdersTakenStatsMap');
          // print(eachMonthStat['salesIncomeStats']
          //     ['mapEachCaptainOrdersTakenStatsMap']);
          // print('mapGeneralStatsMap');
          // print(eachMonthStat['salesIncomeStats']['mapGeneralStatsMap']);
          // print('menuIndividualItemsStatsMap');
          // print(
          //     eachMonthStat['salesIncomeStats']['menuIndividualItemsStatsMap']);
          // Map<String, dynamic> totalIndividualItems =
          //     eachMonthStat['salesIncomeStats']['menuIndividualItemsStatsMap'];
          // thisIsTheText = '';
          // int counter = 0;
          // totalIndividualItems.forEach((key, value) {
          //   counter++;
          //   thisIsTheText += '$counter.$key';
          // });
          setState(() {
            showSpinner = false;
          });
        }
      });
    });
  }

  Future<void> executeQueries() async {
    int counterForCallingCalculation = 0;
    print('dgfgdf4');
    for (final query in queries) {
      counterForCallingCalculation++;
      final querySnapshot = await query.get();
      if (querySnapshot.docs.length > 0) {
        // Access the first document
        final firstDoc = querySnapshot.docs.first;
        final data = firstDoc.data();
        if (data != null && data is Map && data.containsKey('day')) {
          print('dgfgdf5');
//ThisMeansWeHaveGotTheDataOfDayQueriesSinceItHasTheField-'Day'
          convertingDownloadedDaysStatisticsToData(querySnapshot);
        } else {
          print('dgfgdf6');
//ThisMeansWeHaveGotTheDataOfMonthQueries
          convertingDownloadedMonthsExpenseToData(querySnapshot);
        }
      }
      if (counterForCallingCalculation == queries.length) {
//JustGivingSomeTimeForTheDataToBeAccumulatedAfterDownload
        Timer(Duration(milliseconds: 3000), () {
          print('dgfgdf7');
          // dataCalculation();
        });
      }
    }
  }

  void convertingDownloadedDaysStatisticsToData(
      QuerySnapshot dayStatisticsDataSnapshot) {
    for (var eachDayStat in dayStatisticsDataSnapshot.docs) {
      int dayAdded = eachDayStat['day'];
      int monthAdded = eachDayStat['month'];
      int yearAdded = eachDayStat['year'];
      int daysFromStartOfYear = DateTime(yearAdded, monthAdded, dayAdded)
              .difference(DateTime(yearAdded))
              .inDays +
          1;
      Map tempSavedStatisticsData = HashMap();
      if (savedStatisticsDayData[yearAdded] != null) {
        tempSavedStatisticsData = savedStatisticsDayData[yearAdded];
      }
      tempSavedStatisticsData.addAll({daysFromStartOfYear: eachDayStat.data()});
      savedStatisticsDayData.addAll({yearAdded: tempSavedStatisticsData});
    }
  }

  void convertingDownloadedMonthsExpenseToData(
      QuerySnapshot monthsStatisticsDataSnapshot) {
    for (var eachMonthStat in monthsStatisticsDataSnapshot.docs) {
      int monthAdded = eachMonthStat['month'];
      int yearAdded = eachMonthStat['year'];

      print('month Data one by one');
      print('billedCancellationStats');
      print(eachMonthStat['billedCancellationStats']);
      print('cashBalanceData');
      print(eachMonthStat['cashBalanceData']);
      print('arrayExpenseCategoryArray');
      print(eachMonthStat['expenses']['arrayExpenseCategoryArray']);
      print('mapEachExpenseStatisticsMap');
      print(eachMonthStat['expenses']['mapEachExpenseStatisticsMap']);
      print('mapExpensePaidByUserMap');
      print(eachMonthStat['expenses']['mapExpensePaidByUserMap']);
      print('mapExpensePaymentMethodMap');
      print(eachMonthStat['expenses']['mapExpensePaymentMethodMap']);
      print('arraySoldItemsCategoryArray');
      print(eachMonthStat['salesIncomeStats']['arraySoldItemsCategoryArray']);
      print('mapEachCaptainOrdersTakenStatsMap');
      print(eachMonthStat['salesIncomeStats']
          ['mapEachCaptainOrdersTakenStatsMap']);
      print('mapGeneralStatsMap');
      print(eachMonthStat['salesIncomeStats']['mapGeneralStatsMap']);
      print('menuIndividualItemsStatsMap');
      print(eachMonthStat['salesIncomeStats']['menuIndividualItemsStatsMap']);

      Map tempSavedStatisticsData = HashMap();
      if (savedStatisticsMonthData[yearAdded] != null) {
        tempSavedStatisticsData = savedStatisticsMonthData[yearAdded];
      }
      tempSavedStatisticsData.addAll({monthAdded: eachMonthStat.data()});
      savedStatisticsMonthData.addAll({yearAdded: tempSavedStatisticsData});
    }
  }

  void dataCalculation() {
//ListOfAllItems
    totalExpenseOfEachItem = [];
    totalExpenseByEachUser = [];
    totalExpenseByEachPaymentMethod = [];

    num totalExpensesDuringThisPeriod = 0;
    num totalCgstExpenseDuringThisPeriod = 0;
    num totalSgstExpenseDuringThisPeriod = 0;
    if (calculationDaysDataRequired.isNotEmpty) {
      calculationDaysDataRequired.forEach((keyYear, valueArrayOfDays) {
        List<int> daysRequired = valueArrayOfDays;
        if (savedStatisticsDayData.containsKey(keyYear)) {
          Map<dynamic, dynamic> tempEachYearData =
              savedStatisticsDayData[keyYear];
          Map<String, dynamic> tempEachDayData = HashMap();
          for (var eachDay in daysRequired) {
            if (tempEachYearData.containsKey(eachDay)) {
              tempEachDayData = tempEachYearData[eachDay];
              tempEachDayData.forEach((categoryKey, value) {
                if (categoryKey != 'arrayExpenseCategoryArray' &&
                    categoryKey != 'arrayExpenseDescriptionArray' &&
                    categoryKey != 'arrayExpenseVendorArray' &&
                    categoryKey != 'day' &&
                    categoryKey != 'month' &&
                    categoryKey != 'year') {
                  if (categoryKey == 'mapEachExpenseStatisticsMap') {
                    Map<String, dynamic> tempAllItemStatisticsMap =
                        tempEachDayData[categoryKey];
                    tempAllItemStatisticsMap
                        .forEach((itemNameKey, statsOfItemAsValue) {
                      Map<String, dynamic> eachCategoryDataCompiled = HashMap();
                      Map<String, dynamic> eachCategoryDataOfThatDay =
                          HashMap();

                      eachCategoryDataOfThatDay = statsOfItemAsValue;
                      int foundIndex = -1;
                      int indexCounter = 0;
                      for (var map in totalExpenseOfEachItem) {
                        if (map.containsKey(itemNameKey)) {
                          foundIndex = indexCounter;
                        }
                        indexCounter++;
                      }

                      if (foundIndex != -1) {
//ThisMeansCompiledDataAlreadyExists
                        eachCategoryDataCompiled =
                            totalExpenseOfEachItem[foundIndex];
                        num numberOfUnits =
                            eachCategoryDataCompiled[itemNameKey]
                                    ['numberOfUnits'] +
                                eachCategoryDataOfThatDay['numberOfUnits'];

                        num cgstValue = eachCategoryDataCompiled[itemNameKey]
                                ['cgstValue'] +
                            eachCategoryDataOfThatDay['cgstValue'];
                        totalCgstExpenseDuringThisPeriod =
                            totalCgstExpenseDuringThisPeriod +
                                eachCategoryDataOfThatDay['cgstValue'];

                        num sgstValue = eachCategoryDataCompiled[itemNameKey]
                                ['sgstValue'] +
                            eachCategoryDataOfThatDay['sgstValue'];
                        totalSgstExpenseDuringThisPeriod =
                            totalSgstExpenseDuringThisPeriod +
                                eachCategoryDataOfThatDay['sgstValue'];

                        num totalPrice = eachCategoryDataCompiled[itemNameKey]
                                ['totalPrice'] +
                            eachCategoryDataOfThatDay['totalPrice'];

                        totalExpensesDuringThisPeriod =
                            totalExpensesDuringThisPeriod +
                                eachCategoryDataOfThatDay['totalPrice'];

                        totalExpenseOfEachItem.removeAt(foundIndex);
                        totalExpenseOfEachItem.add({
                          itemNameKey: {
                            'numberOfUnits': numberOfUnits,
                            'cgstValue': cgstValue,
                            'sgstValue': sgstValue,
                            'totalPrice': totalPrice
                          }
                        });
                      } else {
                        num numberOfUnits =
                            eachCategoryDataOfThatDay['numberOfUnits'];

                        num cgstValue = eachCategoryDataOfThatDay['cgstValue'];

                        totalCgstExpenseDuringThisPeriod =
                            totalCgstExpenseDuringThisPeriod +
                                eachCategoryDataOfThatDay['cgstValue'];

                        num sgstValue = eachCategoryDataOfThatDay['sgstValue'];

                        totalSgstExpenseDuringThisPeriod =
                            totalSgstExpenseDuringThisPeriod +
                                eachCategoryDataOfThatDay['sgstValue'];

                        num totalPrice =
                            eachCategoryDataOfThatDay['totalPrice'];
                        totalExpensesDuringThisPeriod =
                            totalExpensesDuringThisPeriod +
                                eachCategoryDataOfThatDay['totalPrice'];

                        totalExpenseOfEachItem.add({
                          itemNameKey: {
                            'numberOfUnits': numberOfUnits,
                            'cgstValue': cgstValue,
                            'sgstValue': sgstValue,
                            'totalPrice': totalPrice
                          }
                        });
                      }
                    });
                  }
                  if (categoryKey == 'mapExpensePaidByUserMap') {
                    Map<String, dynamic> tempAllPaidByUserMap =
                        tempEachDayData[categoryKey];
                    tempAllPaidByUserMap
                        .forEach((paidByUserNameKey, statsOfUserAsValue) {
                      Map<String, dynamic> eachCategoryDataCompiled = HashMap();
                      Map<String, dynamic> eachCategoryDataOfThatDay =
                          HashMap();

                      eachCategoryDataOfThatDay = statsOfUserAsValue;
                      int foundIndex = -1;
                      int indexCounter = 0;
                      for (var map in totalExpenseByEachUser) {
                        if (map.containsKey(paidByUserNameKey)) {
                          foundIndex = indexCounter;
                        }
                        indexCounter++;
                      }

                      if (foundIndex != -1) {
//ThisMeansCompiledDataAlreadyExists
                        eachCategoryDataCompiled =
                            totalExpenseByEachUser[foundIndex];
                        num paidAmount =
                            eachCategoryDataCompiled[paidByUserNameKey]
                                    ['paidAmount'] +
                                eachCategoryDataOfThatDay['paidAmount'];

                        totalExpenseByEachUser.removeAt(foundIndex);
                        totalExpenseByEachUser.add({
                          paidByUserNameKey: {
                            'paidAmount': paidAmount,
                          }
                        });
                      } else {
                        num paidAmount =
                            eachCategoryDataOfThatDay['paidAmount'];

                        totalExpenseByEachUser.add({
                          paidByUserNameKey: {
                            'paidAmount': paidAmount,
                          }
                        });
                      }
                    });
                  }
                  if (categoryKey == 'mapExpensePaymentMethodMap') {
                    Map<String, dynamic> tempAllPaymentMethodMap =
                        tempEachDayData[categoryKey];
                    tempAllPaymentMethodMap.forEach(
                        (paymentMethodNameKey, statsOfPaymentMethodAsValue) {
                      Map<String, dynamic> eachCategoryDataCompiled = HashMap();
                      Map<String, dynamic> eachCategoryDataOfThatDay =
                          HashMap();

                      eachCategoryDataOfThatDay = statsOfPaymentMethodAsValue;
                      int foundIndex = -1;
                      int indexCounter = 0;
                      for (var map in totalExpenseByEachPaymentMethod) {
                        if (map.containsKey(paymentMethodNameKey)) {
                          foundIndex = indexCounter;
                        }
                        indexCounter++;
                      }

                      if (foundIndex != -1) {
//ThisMeansCompiledDataAlreadyExists
                        eachCategoryDataCompiled =
                            totalExpenseByEachPaymentMethod[foundIndex];
                        num paidAmount =
                            eachCategoryDataCompiled[paymentMethodNameKey]
                                    ['paidAmount'] +
                                eachCategoryDataOfThatDay['paidAmount'];

                        totalExpenseByEachPaymentMethod.removeAt(foundIndex);
                        totalExpenseByEachPaymentMethod.add({
                          paymentMethodNameKey: {
                            'paidAmount': paidAmount,
                          }
                        });
                      } else {
                        num paidAmount =
                            eachCategoryDataOfThatDay['paidAmount'];

                        totalExpenseByEachPaymentMethod.add({
                          paymentMethodNameKey: {
                            'paidAmount': paidAmount,
                          }
                        });
                      }
                    });
                  }
                }
              });
            }
          }
        }
      });
    }
    if (calculationMonthsDataRequired.isNotEmpty) {
      calculationMonthsDataRequired.forEach((keyYear, valueArrayOfMonths) {
        List<int> monthsRequired = valueArrayOfMonths;
        if (savedStatisticsMonthData.containsKey(keyYear)) {
          Map<dynamic, dynamic> tempEachYearData =
              savedStatisticsMonthData[keyYear];
          Map<String, dynamic> tempEachMonthData = HashMap();
          for (var eachMonth in monthsRequired) {
            if (tempEachYearData.containsKey(eachMonth)) {
              tempEachMonthData = tempEachYearData[eachMonth];
              tempEachMonthData.forEach((categoryKey, value) {
                if (categoryKey != 'arrayExpenseCategoryArray' &&
                    categoryKey != 'arrayExpenseDescriptionArray' &&
                    categoryKey != 'arrayExpenseVendorArray' &&
                    categoryKey != 'day' &&
                    categoryKey != 'month' &&
                    categoryKey != 'year') {
                  if (categoryKey == 'mapEachExpenseStatisticsMap') {
                    Map<String, dynamic> tempAllItemStatisticsMap =
                        tempEachMonthData[categoryKey];
                    tempAllItemStatisticsMap
                        .forEach((itemNameKey, statsOfItemAsValue) {
                      Map<String, dynamic> eachCategoryDataCompiled = HashMap();
                      Map<String, dynamic> eachCategoryDataOfThatMonth =
                          HashMap();

                      eachCategoryDataOfThatMonth = statsOfItemAsValue;
                      int foundIndex = -1;
                      int indexCounter = 0;
                      for (var map in totalExpenseOfEachItem) {
                        if (map.containsKey(itemNameKey)) {
                          foundIndex = indexCounter;
                        }
                        indexCounter++;
                      }

                      if (foundIndex != -1) {
//ThisMeansCompiledDataAlreadyExists
                        eachCategoryDataCompiled =
                            totalExpenseOfEachItem[foundIndex];
                        num numberOfUnits =
                            eachCategoryDataCompiled[itemNameKey]
                                    ['numberOfUnits'] +
                                eachCategoryDataOfThatMonth['numberOfUnits'];

                        num cgstValue = eachCategoryDataCompiled[itemNameKey]
                                ['cgstValue'] +
                            eachCategoryDataOfThatMonth['cgstValue'];
                        totalCgstExpenseDuringThisPeriod =
                            totalCgstExpenseDuringThisPeriod +
                                eachCategoryDataOfThatMonth['cgstValue'];

                        num sgstValue = eachCategoryDataCompiled[itemNameKey]
                                ['sgstValue'] +
                            eachCategoryDataOfThatMonth['sgstValue'];
                        totalSgstExpenseDuringThisPeriod =
                            totalSgstExpenseDuringThisPeriod +
                                eachCategoryDataOfThatMonth['sgstValue'];

                        num totalPrice = eachCategoryDataCompiled[itemNameKey]
                                ['totalPrice'] +
                            eachCategoryDataOfThatMonth['totalPrice'];

                        totalExpensesDuringThisPeriod =
                            totalExpensesDuringThisPeriod +
                                eachCategoryDataOfThatMonth['totalPrice'];

                        totalExpenseOfEachItem.removeAt(foundIndex);
                        totalExpenseOfEachItem.add({
                          itemNameKey: {
                            'numberOfUnits': numberOfUnits,
                            'cgstValue': cgstValue,
                            'sgstValue': sgstValue,
                            'totalPrice': totalPrice
                          }
                        });
                      } else {
                        num numberOfUnits =
                            eachCategoryDataOfThatMonth['numberOfUnits'];

                        num cgstValue =
                            eachCategoryDataOfThatMonth['cgstValue'];

                        totalCgstExpenseDuringThisPeriod =
                            totalCgstExpenseDuringThisPeriod +
                                eachCategoryDataOfThatMonth['cgstValue'];

                        num sgstValue =
                            eachCategoryDataOfThatMonth['sgstValue'];

                        totalSgstExpenseDuringThisPeriod =
                            totalSgstExpenseDuringThisPeriod +
                                eachCategoryDataOfThatMonth['sgstValue'];

                        num totalPrice =
                            eachCategoryDataOfThatMonth['totalPrice'];
                        totalExpensesDuringThisPeriod =
                            totalExpensesDuringThisPeriod +
                                eachCategoryDataOfThatMonth['totalPrice'];

                        totalExpenseOfEachItem.add({
                          itemNameKey: {
                            'numberOfUnits': numberOfUnits,
                            'cgstValue': cgstValue,
                            'sgstValue': sgstValue,
                            'totalPrice': totalPrice
                          }
                        });
                      }
                    });
                  }
                  if (categoryKey == 'mapExpensePaidByUserMap') {
                    Map<String, dynamic> tempAllPaidByUserMap =
                        tempEachMonthData[categoryKey];
                    tempAllPaidByUserMap
                        .forEach((paidByUserNameKey, statsOfUserAsValue) {
                      Map<String, dynamic> eachCategoryDataCompiled = HashMap();
                      Map<String, dynamic> eachCategoryDataOfThatMonth =
                          HashMap();

                      eachCategoryDataOfThatMonth = statsOfUserAsValue;
                      int foundIndex = -1;
                      int indexCounter = 0;
                      for (var map in totalExpenseByEachUser) {
                        if (map.containsKey(paidByUserNameKey)) {
                          foundIndex = indexCounter;
                        }
                        indexCounter++;
                      }

                      if (foundIndex != -1) {
//ThisMeansCompiledDataAlreadyExists
                        eachCategoryDataCompiled =
                            totalExpenseByEachUser[foundIndex];
                        num paidAmount =
                            eachCategoryDataCompiled[paidByUserNameKey]
                                    ['paidAmount'] +
                                eachCategoryDataOfThatMonth['paidAmount'];

                        totalExpenseByEachUser.removeAt(foundIndex);
                        totalExpenseByEachUser.add({
                          paidByUserNameKey: {
                            'paidAmount': paidAmount,
                          }
                        });
                      } else {
                        num paidAmount =
                            eachCategoryDataOfThatMonth['paidAmount'];

                        totalExpenseByEachUser.add({
                          paidByUserNameKey: {
                            'paidAmount': paidAmount,
                          }
                        });
                      }
                    });
                  }
                  if (categoryKey == 'mapExpensePaymentMethodMap') {
                    Map<String, dynamic> tempAllPaymentMethodMap =
                        tempEachMonthData[categoryKey];
                    tempAllPaymentMethodMap.forEach(
                        (paymentMethodNameKey, statsOfPaymentMethodAsValue) {
                      Map<String, dynamic> eachCategoryDataCompiled = HashMap();
                      Map<String, dynamic> eachCategoryDataOfThatMonth =
                          HashMap();

                      eachCategoryDataOfThatMonth = statsOfPaymentMethodAsValue;
                      int foundIndex = -1;
                      int indexCounter = 0;
                      for (var map in totalExpenseByEachPaymentMethod) {
                        if (map.containsKey(paymentMethodNameKey)) {
                          foundIndex = indexCounter;
                        }
                        indexCounter++;
                      }

                      if (foundIndex != -1) {
//ThisMeansCompiledDataAlreadyExists
                        eachCategoryDataCompiled =
                            totalExpenseByEachPaymentMethod[foundIndex];
                        num paidAmount =
                            eachCategoryDataCompiled[paymentMethodNameKey]
                                    ['paidAmount'] +
                                eachCategoryDataOfThatMonth['paidAmount'];

                        totalExpenseByEachPaymentMethod.removeAt(foundIndex);
                        totalExpenseByEachPaymentMethod.add({
                          paymentMethodNameKey: {
                            'paidAmount': paidAmount,
                          }
                        });
                      } else {
                        num paidAmount =
                            eachCategoryDataOfThatMonth['paidAmount'];

                        totalExpenseByEachPaymentMethod.add({
                          paymentMethodNameKey: {
                            'paidAmount': paidAmount,
                          }
                        });
                      }
                    });
                  }
                }
              });
            }
          }
        }
      });
    }

    totalExpenseOfEachItem.sort((b, a) =>
        a.values.first['totalPrice'].compareTo(b.values.first['totalPrice']));
    totalExpenseByEachUser.sort((b, a) =>
        a.values.first['paidAmount'].compareTo(b.values.first['paidAmount']));
    totalExpenseByEachPaymentMethod.sort((b, a) =>
        a.values.first['paidAmount'].compareTo(b.values.first['paidAmount']));
    setState(() {
      showSpinner = false;
    });
  }

  List<DataRow> dataRowWidgetOfUserAmount() {
    List<DataRow> dataRowsWithUserAmount = [];
    for (var eachUserAmount in totalExpenseByEachUser) {
      Map<String, dynamic> tempEachUserAmount = eachUserAmount;
      tempEachUserAmount.forEach((userNameAsKey, userStatAsValue) {
        dataRowsWithUserAmount.add(DataRow(cells: [
          DataCell(
            Text(userNameAsKey),
          ),
          DataCell(
            Text(userStatAsValue['paidAmount'].toString()),
          )
        ]));
      });
    }
    return dataRowsWithUserAmount;
  }

  List<DataRow> dataRowWidgetOfPaymentMethod() {
    List<DataRow> dataRowsWithPaymentMethod = [];
    for (var eachPaymentMethod in totalExpenseByEachPaymentMethod) {
      Map<String, dynamic> tempEachPaymentMethod = eachPaymentMethod;
      tempEachPaymentMethod
          .forEach((paymentMethodNameAsKey, paymentMethodStatAsValue) {
        dataRowsWithPaymentMethod.add(DataRow(cells: [
          DataCell(
            Text(paymentMethodNameAsKey),
          ),
          DataCell(
            Text(paymentMethodStatAsValue['paidAmount'].toString()),
          )
        ]));
      });
    }
    return dataRowsWithPaymentMethod;
  }

  List<DataRow> dataRowWidgetOfItems() {
    List<DataRow> dataRowsWithItems = [];
    for (var eachItem in totalExpenseOfEachItem) {
      Map<String, dynamic> tempEachItem = eachItem;
      tempEachItem.forEach((itemNameAsKey, itemStatAsValue) {
        dataRowsWithItems.add(DataRow(cells: [
          DataCell(
            Text(itemNameAsKey),
          ),
          DataCell(
            Text(itemStatAsValue['numberOfUnits'].toString()),
          ),
          DataCell(
            Text(itemStatAsValue['totalPrice'].toString()),
          ),
          DataCell(
            Text(itemStatAsValue['cgstValue'].toString()),
          ),
          DataCell(
            Text(itemStatAsValue['sgstValue'].toString()),
          ),
        ]));
      });
    }
    return dataRowsWithItems;
  }

  @override
  Widget build(BuildContext context) {
    final start = dateRange.start;
    final end = dateRange.end;
    return Scaffold(
        appBar: AppBar(
          backgroundColor: kAppBarBackgroundColor,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: kAppBarBackIconColor),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text('Expenses Reports', style: kAppBarTextStyle),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text('Click Below Button to Choose Date Range',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                  SizedBox(width: 10)
                ],
              ),
              ListTile(
                title: ElevatedButton(
                    style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                            Colors.orangeAccent)),
                    onPressed: pickDateRange,
                    child: Text(
                        '${DateFormat('dd-MM-yyyy').format(start)}  to ${DateFormat('dd-MM-yyyy').format(end)}',
                        style: TextStyle(fontSize: 15, color: Colors.black))),
                trailing: ElevatedButton(
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all<Color>(Colors.green)),
                    onPressed: () {
                      statisticsReportsQueryGenerationVersionTwo();
                      viewClicked = true;
                      showSpinner = true;
                      setState(() {});
                    },
                    child: Text('View', style: TextStyle(fontSize: 15))),
                // subtitle: Text('Click Button to Choose Date Range',
                //     style: TextStyle(color: Colors.green)),
              ),
//TableOfTotalExpenseOfEachUser
              Divider(thickness: 5),
//               (totalExpenseByEachUser.isNotEmpty && showSpinner == false)
//                   ? DataTable(columns: [
//                       DataColumn(label: Text('Paid By')),
//                       DataColumn(label: Text('Amount')),
//                     ], rows: dataRowWidgetOfUserAmount())
//                   : SizedBox.shrink(),
//               (totalExpenseByEachUser.isNotEmpty && showSpinner == false)
//                   ? Divider(thickness: 2)
//                   : SizedBox.shrink(),
// //TableOfPaymentMethod
//               (totalExpenseByEachPaymentMethod.isNotEmpty &&
//                       showSpinner == false)
//                   ? DataTable(columns: [
//                       DataColumn(label: Text('Payment Method')),
//                       DataColumn(label: Text('Amount')),
//                     ], rows: dataRowWidgetOfPaymentMethod())
//                   : SizedBox.shrink(),
//               (totalExpenseByEachPaymentMethod.isNotEmpty &&
//                       showSpinner == false)
//                   ? Divider(thickness: 2)
//                   : SizedBox.shrink(),
// //TableOfItems
//               (totalExpenseOfEachItem.isNotEmpty && showSpinner == false)
//                   ? Scrollbar(
//                       thumbVisibility: true,
//                       controller: scrollController,
//                       child: SingleChildScrollView(
//                         controller: scrollController,
//                         scrollDirection: Axis.horizontal,
//                         child: DataTable(columns: [
//                           DataColumn(label: Text('Item')),
//                           DataColumn(label: Text('Number')),
//                           DataColumn(label: Text('Total')),
//                           DataColumn(label: Text('Cgst')),
//                           DataColumn(label: Text('Sgst')),
//                         ], rows: dataRowWidgetOfItems()),
//                       ),
//                     )
//                   : SizedBox.shrink(),
//               (totalExpenseOfEachItem.isNotEmpty && showSpinner == false)
//                   ? Divider(thickness: 2)
//                   : SizedBox.shrink(),
//               showSpinner == true
//                   ? Center(child: CircularProgressIndicator())
//                   : SizedBox.shrink(),
//               (viewClicked &&
//                       showSpinner == false &&
//                       totalExpenseOfEachItem.isEmpty)
//                   ? Center(
//                       child: Text(
//                       'No Records Found',
//                       style: TextStyle(fontSize: 30),
//                     ))
//                   : SizedBox.shrink(),
              Divider(thickness: 5),
              // Container(child: Text(thisIsTheText)),
              Container(
                  padding: EdgeInsets.all(8),
                  child: TextField(controller: _salesIncomeStatsText)),
              Container(
                  padding: EdgeInsets.all(8),
                  child: TextField(controller: _expensesStatsText)),
            ],
          ),
        ));
  }
}
