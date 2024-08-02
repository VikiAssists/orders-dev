import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_alt/modal_progress_hud_alt.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:orders_dev/Screens/reports_display_screen.dart';
import 'package:orders_dev/constants.dart';
import 'package:provider/provider.dart';

class StatisticsWithExpenseIncomeCashBalance extends StatefulWidget {
  final String hotelName;
  const StatisticsWithExpenseIncomeCashBalance(
      {Key? key, required this.hotelName})
      : super(key: key);

  @override
  State<StatisticsWithExpenseIncomeCashBalance> createState() =>
      _StatisticsWithExpenseIncomeCashBalanceState();
}

class _StatisticsWithExpenseIncomeCashBalanceState
    extends State<StatisticsWithExpenseIncomeCashBalance> {
  final _fireStore = FirebaseFirestore.instance;
  String startDateText = DateFormat('dd-MM-yyyy').format(DateTime.now());
  String endDateText = DateFormat('dd-MM-yyyy').format(DateTime.now());
  List<Query> queries = [];
  Map<int, dynamic> savedStatisticsMonthData = HashMap();
  Map<int, dynamic> savedStatisticsDayData = HashMap();
  List<int> calculationDaysNeeded = [];
  List<int> calculationMonthsNeeded = [];
  Map<num, Map<String, dynamic>> savedStatisticsCashBalanceData = HashMap();
  List<Map<String, dynamic>> totalExpenseOfEachItem = [];
  List<Map<String, dynamic>> totalExpenseByEachUser = [];
  List<Map<String, dynamic>> totalExpenseByEachPaymentMethod = [];
  bool viewClicked = false;
  bool showSpinner = false;
  final scrollController = ScrollController();
  StreamSubscription<QuerySnapshot>? _streamSubscriptionDataCheck;
  StreamSubscription<QuerySnapshot>? _streamSubscriptionForThisMonth;
  // TextEditingController _salesIncomeStatsText = TextEditingController();
  // TextEditingController _expensesStatsText = TextEditingController();
  // Map<int, dynamic> savedExpensesMonthStats = HashMap();
  // Map<int, dynamic> savedExpensesDayStats = HashMap();
  // Map<int, dynamic> savedSalesCaptainMonthStats = HashMap();
  // Map<int, dynamic> savedSalesCaptainDayStats = HashMap();
  // Map<int, dynamic> savedSalesIndividualItemsMonthStats = HashMap();
  // Map<int, dynamic> savedSalesIndividualItemsDayStats = HashMap();
  // Map<int, dynamic> savedSalesGeneralDayStats = HashMap();
  // Map<int, dynamic> savedSalesGeneralMonthStats = HashMap();
  Map<int, dynamic> billedCancelledIndividualItemDayStats = HashMap();
  Map<int, dynamic> billedCancelledIndividualItemMonthStats = HashMap();
  Map<int, dynamic> billedCancellingCaptainDayStats = HashMap();
  Map<int, dynamic> billedCancellingCaptainMonthStats = HashMap();
  Map<int, dynamic> billedRejectingChefDayStats = HashMap();
  Map<int, dynamic> billedRejectingChefMonthStats = HashMap();
  Map<int, dynamic> nonBilledCancelledIndividualItemDayStats = HashMap();
  Map<int, dynamic> nonBilledCancelledIndividualItemMonthStats = HashMap();
  Map<int, dynamic> nonBilledCancellingCaptainDayStats = HashMap();
  Map<int, dynamic> nonBilledCancellingCaptainMonthStats = HashMap();
  Map<int, dynamic> nonBilledRejectingChefDayStats = HashMap();
  Map<int, dynamic> nonBilledRejectingChefMonthStats = HashMap();
  Map<int, dynamic> generalStatsDayStats = HashMap();
  Map<int, dynamic> generalStatsMonthStats = HashMap();
  Map<int, dynamic> eachCaptainOrdersTakenDayStats = HashMap();
  Map<int, dynamic> eachCaptainOrdersTakenMonthStats = HashMap();
  Map<int, dynamic> categoryAndItemsDayStats = HashMap();
  Map<int, dynamic> categoryAndItemsMonthStats = HashMap();
  Map<int, dynamic> individualItemsDayStats = HashMap();
  Map<int, dynamic> individualItemsMonthStats = HashMap();
  Map<int, dynamic> extraIndividualItemsDayStats = HashMap();
  Map<int, dynamic> extraIndividualItemsMonthStats = HashMap();
  Map<int, dynamic> salesCashierDayStats = HashMap();
  Map<int, dynamic> salesCashierMonthStats = HashMap();
  Map<int, dynamic> salesPaymentMethodDayStats = HashMap();
  Map<int, dynamic> salesPaymentMethodMonthStats = HashMap();
  Map<int, dynamic> eachExpenseDayStats = HashMap();
  Map<int, dynamic> eachExpenseMonthStats = HashMap();
  Map<int, dynamic> expensePaidByUserDayStats = HashMap();
  Map<int, dynamic> expensePaidByUserMonthStats = HashMap();
  Map<int, dynamic> expensePaymentMethodDayStats = HashMap();
  Map<int, dynamic> expensePaymentMethodMonthStats = HashMap();
  Map<String, num> finalGeneralStatsCalculated = HashMap();
  Map<String, Map<String, dynamic>>
      finalBilledCancelledIndividualItemsStatsCalculated = HashMap();
  Map<String, Map<String, dynamic>>
      finalNonBilledCancelledIndividualItemsStatsCalculated = HashMap();
  Map<String, Map<String, dynamic>>
      finalBilledCaptainCancelledIndividualItemsStats = HashMap();
  Map<String, Map<String, dynamic>>
      finalNonBilledCaptainCancelledIndividualItemsStats = HashMap();
  Map<String, Map<String, dynamic>> finalBilledCaptainCancellationStats =
      HashMap();
  Map<String, Map<String, dynamic>> finalNonBilledCaptainCancellationStats =
      HashMap();
  Map<String, Map<String, dynamic>>
      finalBilledChefRejectedIndividualItemsStats = HashMap();
  Map<String, Map<String, dynamic>>
      finalNonBilledChefRejectedIndividualItemsStats = HashMap();
  Map<String, Map<String, dynamic>> finalBilledChefRejectionStats = HashMap();
  Map<String, Map<String, dynamic>> finalNonBilledChefRejectionStats =
      HashMap();
  Map<String, Map<String, dynamic>> finalSalesIndividualItemsStatsCalculated =
      HashMap();
  Map<String, Map<String, dynamic>>
      finalSalesExtraIndividualItemsStatsCalculated = HashMap();
  Map<String, List<String>> finalEachCategoryWithItemsList = HashMap();
  Map<String, Map<String, dynamic>> finalEachCategorySalesStats = HashMap();
  Map<String, Map<String, dynamic>> finalSalesPaymentMethodStatsCalculated =
      HashMap();
  Map<String, Map<String, dynamic>> finalCashierClosingAmountStats = HashMap();
  Map<String, Map<String, dynamic>> finalCashierClosingPaymentMethodStats =
      HashMap();
  Map<String, Map<String, dynamic>>
      finalCaptainIndividualItemsOrdersTakenStats = HashMap();
  Map<String, Map<String, dynamic>> finalCaptainOrdersTakenGeneralStats =
      HashMap();
  Map<String, Map<String, dynamic>> finalEachExpenseStatsCalculated = HashMap();
  Map<String, Map<String, dynamic>> finalExpensePaymentMethodStatsCalculated =
      HashMap();
  Map<String, Map<String, dynamic>>
      finalExpensePaidByUserGeneralStatsCalculated = HashMap();
  Map<String, Map<String, dynamic>>
      finalExpensePaidByUserPaymentMethodStatsCalculated = HashMap();
  num totalSalesIncomeDuringTheCalculationPeriod = 0;
  num totalExpenseDuringTheCalculationPeriod = 0;
  bool firstCalculationStarted = false;
  int randomNumberForEachViewButtonPress = 0;
  num startingCashBalance = 0;
  num endingCashBalance = 0;
  bool noRecordsFound = false;

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
        lastDate: DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day));
    if (newDateRange == null) return;

    setState(() {
      dateRange = newDateRange;
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _streamSubscriptionForThisMonth?.cancel();
    super.dispose();
  }

  Future show(
    String message, {
    Duration duration: const Duration(seconds: 2),
  }) async {
    await new Future.delayed(new Duration(milliseconds: 100));
    ScaffoldMessenger.of(context).showSnackBar(
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

  void statisticsReportsQueryGenerationVersion3() {
    queries = [];
    Map<int, List<int>> monthsInYearsNeeded = HashMap();
    Map<int, List<int>> daysInMonthsInYearsNeeded = HashMap();
    calculationDaysNeeded = [];
    calculationMonthsNeeded = [];
    List<String> typeOfStats = [
      'expenseStats',
      'generalStats',
      'captainStats',
      'individualItemStats'
    ];
    List<String> inQueriesDocumentsNameList = [];

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
//ForCalculationWeAreTakingThisMonth
          calculationMonthsNeeded.add(
              DateTime(iterationYear, iterationStartMonth, 15, 12)
                  .millisecondsSinceEpoch);
//ForDownloadingWeNeedThisMonthOnlyIfItHasNotBeenSavedBefore
          if (!yearDataInSavedMonthData.containsKey(iterationStartMonth)) {
//thisMeansDataIsn'tThereYet
            if (monthsInYearsNeeded.containsKey(iterationYear)) {
              List<int> tempMonthsDataOfTheYear =
                  monthsInYearsNeeded[iterationYear]!;
              tempMonthsDataOfTheYear.add(iterationStartMonth);
              monthsInYearsNeeded[iterationYear] = tempMonthsDataOfTheYear;
            } else {
              monthsInYearsNeeded.addAll({
                iterationYear: [iterationStartMonth]
              });
            }
          }
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
              //ForCalculationWeAreTakingThisMonth
              calculationDaysNeeded.add(DateTime(
                      iterationYear, iterationStartMonth, iterationStartDay)
                  .millisecondsSinceEpoch);

              int dayNumberFromNewYear = DateTime(
                          iterationYear, iterationStartMonth, iterationStartDay)
                      .difference(DateTime(iterationYear))
                      .inDays +
                  1;
//IfDataNotExistsAlreadyWeNeedForDownload
              if (!yearDataInSavedDayData.containsKey(dayNumberFromNewYear)) {
//ThisMeansWeAlreadyHaveTheData
                if (daysInMonthsInYearsNeeded.containsKey(iterationYear)) {
                  List<int> tempDaysDataOfTheYear =
                      daysInMonthsInYearsNeeded[iterationYear]!;
                  tempDaysDataOfTheYear.add(dayNumberFromNewYear);
                  daysInMonthsInYearsNeeded[iterationYear] =
                      tempDaysDataOfTheYear;
                } else {
                  daysInMonthsInYearsNeeded.addAll({
                    iterationYear: [dayNumberFromNewYear]
                  });
                }
              }
            }
          }
        }
      }
    }
    if (monthsInYearsNeeded.isNotEmpty) {
      monthsInYearsNeeded.forEach((key, value) {
        List<int> tempMonthsDataNeededInTheYear = value;
        int numberOfMonthsDataNeededInTheYear = 0;
        for (int eachMonth in tempMonthsDataNeededInTheYear) {
          numberOfMonthsDataNeededInTheYear++;
          String eachMonthAsString = eachMonth < 10
              ? '0${eachMonth.toString()}'
              : eachMonth.toString();
          int statTypeCounter = 0;
          for (String eachStatType in typeOfStats) {
            statTypeCounter++;
            inQueriesDocumentsNameList.add('$eachMonthAsString*$eachStatType');
            if (statTypeCounter == typeOfStats.length &&
                (inQueriesDocumentsNameList.length > 7 ||
                    numberOfMonthsDataNeededInTheYear ==
                        tempMonthsDataNeededInTheYear.length)) {
//ThisMeansWeNeedToMakeItIntoAQuery
              queries.add(FirebaseFirestore.instance
                  .collection(widget.hotelName)
                  .doc('reports')
                  .collection('monthlyReports')
                  .doc('year')
                  .collection(key.toString())
                  .where(FieldPath.documentId,
                      whereIn: inQueriesDocumentsNameList));
              inQueriesDocumentsNameList = [];
            }
          }
        }
      });
    }
    inQueriesDocumentsNameList = [];
    if (daysInMonthsInYearsNeeded.isNotEmpty) {
      daysInMonthsInYearsNeeded.forEach((key, value) {
        List<int> tempDaysDataNeededInTheYear = value;
        int numberOfDaysDataNeededInTheYear = 0;
        for (int eachDay in tempDaysDataNeededInTheYear) {
          numberOfDaysDataNeededInTheYear++;
          DateTime dateTimeOfThisIterationDay =
              DateTime(key).add(Duration(days: eachDay - 1));
          String eachMonthAsString = dateTimeOfThisIterationDay.month < 10
              ? '0${dateTimeOfThisIterationDay.month.toString()}'
              : dateTimeOfThisIterationDay.month.toString();
          String eachDayAsString = dateTimeOfThisIterationDay.day < 10
              ? '0${dateTimeOfThisIterationDay.day.toString()}'
              : dateTimeOfThisIterationDay.day.toString();
          int statTypeCounter = 0;
          for (String eachStatType in typeOfStats) {
            statTypeCounter++;
            inQueriesDocumentsNameList.add('$eachDayAsString*$eachStatType');
            if (statTypeCounter == typeOfStats.length &&
                (inQueriesDocumentsNameList.length > 7 ||
                    numberOfDaysDataNeededInTheYear ==
                        tempDaysDataNeededInTheYear.length)) {
              queries.add(FirebaseFirestore.instance
                  .collection(widget.hotelName)
                  .doc('reports')
                  .collection('dailyReports')
                  .doc(key.toString())
                  .collection(eachMonthAsString)
                  .where(FieldPath.documentId,
                      whereIn: inQueriesDocumentsNameList));
              inQueriesDocumentsNameList = [];
            }
          }
        }
      });
    }
    if (DateTime(dateRange.start.year, dateRange.start.month)
            .millisecondsSinceEpoch ==
        DateTime(dateRange.end.year, dateRange.end.month)
            .millisecondsSinceEpoch) {
//thisMeansTheStartAndEndMonthAreTheSame
      String eachMonthString = dateRange.start.month < 10
          ? '0${dateRange.start.month.toString()}'
          : dateRange.start.month.toString();
      if (!savedStatisticsCashBalanceData
          .containsKey('${dateRange.start.year.toString()}*$eachMonthString')) {
        queries.add(FirebaseFirestore.instance
            .collection(widget.hotelName)
            .doc('reports')
            .collection('monthlyCashBalanceReports')
            .where('midMonthMilliSecond',
                isEqualTo:
                    DateTime(dateRange.start.year, dateRange.start.month, 15)
                        .millisecondsSinceEpoch));
      }
    } else {
      String eachMonthString = dateRange.start.month < 10
          ? '0${dateRange.start.month.toString()}'
          : dateRange.start.month.toString();
      if (!savedStatisticsCashBalanceData
          .containsKey('${dateRange.start.year.toString()}*$eachMonthString')) {
        queries.add(FirebaseFirestore.instance
            .collection(widget.hotelName)
            .doc('reports')
            .collection('monthlyCashBalanceReports')
            .where('midMonthMilliSecond',
                isEqualTo:
                    DateTime(dateRange.start.year, dateRange.start.month, 15)
                        .millisecondsSinceEpoch));
      }
      eachMonthString = dateRange.end.month < 10
          ? '0${dateRange.end.month.toString()}'
          : dateRange.end.month.toString();
      if (!savedStatisticsCashBalanceData
          .containsKey('${dateRange.end.year.toString()}*$eachMonthString')) {
        queries.add(FirebaseFirestore.instance
            .collection(widget.hotelName)
            .doc('reports')
            .collection('monthlyCashBalanceReports')
            .where('midMonthMilliSecond',
                isEqualTo: DateTime(dateRange.end.year, dateRange.end.month, 15)
                    .millisecondsSinceEpoch));
      }
    }

    if (queries.length > 0) {
      executeQueries();
    } else {
      // dataCalculation();
      dataCalculationVersionTwo();
    }
  }

  Future<void> executeQueries() async {
    int counterForCallingCalculation = 0;
    for (final query in queries) {
      counterForCallingCalculation++;
      final querySnapshot = await query.get();
      if (querySnapshot.docs.length > 0) {
        for (var eachDoc in querySnapshot.docs) {
// Access the first document
          final data = eachDoc.data();
          final documentName = eachDoc.id;
//           if (data != null &&
//               data is Map &&
//               data.containsKey('cashBalanceData')) {
// //callCashBalanceFunction
//             Map<String, dynamic>? cashBalanceStat =
//                 eachDoc.data() as Map<String, dynamic>?;
//             cashBalanceDataConversion(documentName, cashBalanceStat!);
//           } else
          if (documentName.contains('generalStats')) {
//CallFunctionThatGeneratesGeneralStats
            Map<String, dynamic>? eachGeneralStat =
                eachDoc.data() as Map<String, dynamic>?;
            generalStatsConversion(eachGeneralStat!);
          } else if (documentName.contains('captainStats')) {
//CallFunctionThatGeneratesCaptainStats
            Map<String, dynamic>? eachCaptainStat =
                eachDoc.data() as Map<String, dynamic>?;
            captainStatsConversion(eachCaptainStat!);
          } else if (documentName.contains('individualItemStats')) {
//CallFunctionThatGeneratesIndividualItemStats
            Map<String, dynamic>? eachIndividualItemStat =
                eachDoc.data() as Map<String, dynamic>?;
            individualItemsStatsConversion(eachIndividualItemStat!);
          } else if (documentName.contains('expenseStats')) {
//CallFunctionThatGeneratesExpenseStats
            Map<String, dynamic>? expenseStat =
                eachDoc.data() as Map<String, dynamic>?;
            expenseStatsConversion(expenseStat!);
          }
        }
      }
      if (counterForCallingCalculation == queries.length) {
//JustGivingSomeTimeForTheDataToBeAccumulatedAfterDownload
        Timer(Duration(milliseconds: 1000), () {
          dataCalculationVersionTwo();

          setState(() {});
        });
      }
    }
  }

  void generalStatsConversion(Map<String, dynamic> generalStatsMap) {
    if (generalStatsMap.containsKey('day')) {
      int dayNumberFromNewYear = DateTime(generalStatsMap['year'],
                  generalStatsMap['month'], generalStatsMap['day'])
              .difference(DateTime(generalStatsMap['year']))
              .inDays +
          1;

      int dayMillisecondsSinceEpoch = DateTime(generalStatsMap['year'],
              generalStatsMap['month'], generalStatsMap['day'])
          .millisecondsSinceEpoch;

      if (generalStatsMap.containsKey('billedCancellationStats')) {
        Map<String, dynamic> tempBilledCancellationStats =
            generalStatsMap['billedCancellationStats'];
        billedCancelledIndividualItemDayStats.addAll({
          dayMillisecondsSinceEpoch: generalStatsMap['billedCancellationStats']
              ['mapCancelledIndividualItemsStats']
        });
        if (tempBilledCancellationStats
            .containsKey('mapCancellingCaptainStats')) {
          billedCancellingCaptainDayStats.addAll({
            dayMillisecondsSinceEpoch:
                generalStatsMap['billedCancellationStats']
                    ['mapCancellingCaptainStats']
          });
        }
        if (tempBilledCancellationStats.containsKey('mapRejectingChefStats')) {
          billedRejectingChefDayStats.addAll({
            dayMillisecondsSinceEpoch:
                generalStatsMap['billedCancellationStats']
                    ['mapRejectingChefStats']
          });
        }
      }
      if (generalStatsMap.containsKey('nonBilledCancellationStats')) {
        Map<String, dynamic> tempNonBilledCancellationStats =
            generalStatsMap['nonBilledCancellationStats'];
        nonBilledCancelledIndividualItemDayStats.addAll({
          dayMillisecondsSinceEpoch:
              generalStatsMap['nonBilledCancellationStats']
                  ['mapCancelledIndividualItemsStats']
        });
        if (tempNonBilledCancellationStats
            .containsKey('mapCancellingCaptainStats')) {
          nonBilledCancellingCaptainDayStats.addAll({
            dayMillisecondsSinceEpoch:
                generalStatsMap['nonBilledCancellationStats']
                    ['mapCancellingCaptainStats']
          });
        }
        if (tempNonBilledCancellationStats
            .containsKey('mapRejectingChefStats')) {
          nonBilledRejectingChefDayStats.addAll({
            dayMillisecondsSinceEpoch:
                generalStatsMap['nonBilledCancellationStats']
                    ['mapRejectingChefStats']
          });
        }
      }
      if (generalStatsMap.containsKey('mapGeneralStatsMap')) {
        generalStatsDayStats.addAll(
            {dayMillisecondsSinceEpoch: generalStatsMap['mapGeneralStatsMap']});
      }
      if (generalStatsMap.containsKey('cashierClosingSalesStats')) {
        salesCashierDayStats.addAll({
          dayMillisecondsSinceEpoch: generalStatsMap['cashierClosingSalesStats']
        });
      }
      if (generalStatsMap.containsKey('paymentMethodClosingSalesStats')) {
        salesPaymentMethodDayStats.addAll({
          dayMillisecondsSinceEpoch:
              generalStatsMap['paymentMethodClosingSalesStats']
        });
      }

      //NextWeNeedToEnsureThatWeRegisterThatTheDayHasData
      if (savedStatisticsDayData.containsKey(generalStatsMap['year'])) {
//ThisMeansYearDataAlreadyExists
        Map<int, bool> tempDayExistenceCheckInYear = savedStatisticsDayData[
            int.parse(generalStatsMap['year'].toString())];
        if (!tempDayExistenceCheckInYear.containsKey(dayNumberFromNewYear)) {
          tempDayExistenceCheckInYear.addAll({dayNumberFromNewYear: true});
          savedStatisticsDayData[
                  int.parse(generalStatsMap['year'].toString())] =
              tempDayExistenceCheckInYear;
        }
      } else {
        savedStatisticsDayData.addAll({
          int.parse(generalStatsMap['year'].toString()): {
            dayNumberFromNewYear: true
          }
        });
      }
    } else {
      int monthMillisecondsSinceEpoch =
          DateTime(generalStatsMap['year'], generalStatsMap['month'], 15, 12)
              .millisecondsSinceEpoch;
//15AsMidMonthDay... 12AsHalfDayOfTheMonth

      if (generalStatsMap.containsKey('billedCancellationStats')) {
        Map<String, dynamic> tempBilledCancellationStats =
            generalStatsMap['billedCancellationStats'];
        billedCancelledIndividualItemMonthStats.addAll({
          monthMillisecondsSinceEpoch:
              generalStatsMap['billedCancellationStats']
                  ['mapCancelledIndividualItemsStats']
        });
        if (tempBilledCancellationStats
            .containsKey('mapCancellingCaptainStats')) {
          billedCancellingCaptainMonthStats.addAll({
            monthMillisecondsSinceEpoch:
                generalStatsMap['billedCancellationStats']
                    ['mapCancellingCaptainStats']
          });
        }
        if (tempBilledCancellationStats.containsKey('mapRejectingChefStats')) {
          billedRejectingChefMonthStats.addAll({
            monthMillisecondsSinceEpoch:
                generalStatsMap['billedCancellationStats']
                    ['mapRejectingChefStats']
          });
        }
      }
      if (generalStatsMap.containsKey('nonBilledCancellationStats')) {
        Map<String, dynamic> tempNonBilledCancellationStats =
            generalStatsMap['nonBilledCancellationStats'];
        nonBilledCancelledIndividualItemMonthStats.addAll({
          monthMillisecondsSinceEpoch:
              generalStatsMap['nonBilledCancellationStats']
                  ['mapCancelledIndividualItemsStats']
        });
        if (tempNonBilledCancellationStats
            .containsKey('mapCancellingCaptainStats')) {
          nonBilledCancellingCaptainMonthStats.addAll({
            monthMillisecondsSinceEpoch:
                generalStatsMap['nonBilledCancellationStats']
                    ['mapCancellingCaptainStats']
          });
        }
        if (tempNonBilledCancellationStats
            .containsKey('mapRejectingChefStats')) {
          nonBilledRejectingChefMonthStats.addAll({
            monthMillisecondsSinceEpoch:
                generalStatsMap['nonBilledCancellationStats']
                    ['mapRejectingChefStats']
          });
        }
      }
      if (generalStatsMap.containsKey('mapGeneralStatsMap')) {
        generalStatsMonthStats.addAll({
          monthMillisecondsSinceEpoch: generalStatsMap['mapGeneralStatsMap']
        });
      }
      if (generalStatsMap.containsKey('cashierClosingSalesStats')) {
        salesCashierMonthStats.addAll({
          monthMillisecondsSinceEpoch:
              generalStatsMap['cashierClosingSalesStats']
        });
      }
      if (generalStatsMap.containsKey('paymentMethodClosingSalesStats')) {
        salesPaymentMethodMonthStats.addAll({
          monthMillisecondsSinceEpoch:
              generalStatsMap['paymentMethodClosingSalesStats']
        });
      }

//NextWeNeedToEnsureThatWeRegisterThatTheMonthHasData
      if (savedStatisticsMonthData.containsKey(generalStatsMap['year'])) {
//ThisMeansYearDataAlreadyExists
        Map<int, bool> tempMonthExistenceCheckInYear = savedStatisticsMonthData[
            int.parse(generalStatsMap['year'].toString())];
        if (!tempMonthExistenceCheckInYear
            .containsKey(generalStatsMap['month'])) {
          tempMonthExistenceCheckInYear
              .addAll({int.parse(generalStatsMap['month'].toString()): true});
          savedStatisticsMonthData[
                  int.parse(generalStatsMap['year'].toString())] =
              tempMonthExistenceCheckInYear;
        }
      } else {
        savedStatisticsMonthData.addAll({
          int.parse(generalStatsMap['year'].toString()): {
            int.parse(generalStatsMap['month'].toString()): true
          }
        });
      }
    }
  }

  void captainStatsConversion(Map<String, dynamic> captainStatsMap) {
    if (captainStatsMap.containsKey('day')) {
      int dayNumberFromNewYear = DateTime(captainStatsMap['year'],
                  captainStatsMap['month'], captainStatsMap['day'])
              .difference(DateTime(captainStatsMap['year']))
              .inDays +
          1;

      int dayMillisecondsSinceEpoch = DateTime(captainStatsMap['year'],
              captainStatsMap['month'], captainStatsMap['day'])
          .millisecondsSinceEpoch;

      eachCaptainOrdersTakenDayStats.addAll({
        dayMillisecondsSinceEpoch:
            captainStatsMap['mapEachCaptainOrdersTakenStatsMap']
      });

      //NextWeNeedToEnsureThatWeRegisterThatTheDayHasData
      if (savedStatisticsDayData.containsKey(captainStatsMap['year'])) {
//ThisMeansYearDataAlreadyExists
        Map<int, bool> tempDayExistenceCheckInYear = savedStatisticsDayData[
            int.parse(captainStatsMap['year'].toString())];
        if (!tempDayExistenceCheckInYear.containsKey(dayNumberFromNewYear)) {
          tempDayExistenceCheckInYear.addAll({dayNumberFromNewYear: true});
          savedStatisticsDayData[
                  int.parse(captainStatsMap['year'].toString())] =
              tempDayExistenceCheckInYear;
        }
      } else {
        savedStatisticsDayData.addAll({
          int.parse(captainStatsMap['year'].toString()): {
            dayNumberFromNewYear: true
          }
        });
      }
    } else {
//thisIsMonthMap

      int monthMillisecondsSinceEpoch =
          DateTime(captainStatsMap['year'], captainStatsMap['month'], 15, 12)
              .millisecondsSinceEpoch;
      eachCaptainOrdersTakenMonthStats.addAll({
        monthMillisecondsSinceEpoch:
            captainStatsMap['mapEachCaptainOrdersTakenStatsMap']
      });
//NextWeNeedToEnsureThatWeRegisterThatTheMonthHasData
      if (savedStatisticsMonthData.containsKey(captainStatsMap['year'])) {
//ThisMeansYearDataAlreadyExists
        Map<int, bool> tempMonthExistenceCheckInYear = savedStatisticsMonthData[
            int.parse(captainStatsMap['year'].toString())];
        if (!tempMonthExistenceCheckInYear
            .containsKey(int.parse(captainStatsMap['month'].toString()))) {
          tempMonthExistenceCheckInYear
              .addAll({int.parse(captainStatsMap['month'].toString()): true});
          savedStatisticsMonthData[
                  int.parse(captainStatsMap['year'].toString())] =
              tempMonthExistenceCheckInYear;
        }
      } else {
        savedStatisticsMonthData.addAll({
          int.parse(captainStatsMap['year'].toString()): {
            int.parse(captainStatsMap['month'].toString()): true
          }
        });
      }
    }
  }

  void individualItemsStatsConversion(
      Map<String, dynamic> individualItemAllStatsMap) {
    Map<String, dynamic> individualItemStatsMap =
        individualItemAllStatsMap['salesIncomeStats'];

    if (individualItemAllStatsMap.containsKey('day')) {
      int dayNumberFromNewYear = DateTime(
                  individualItemAllStatsMap['year'],
                  individualItemAllStatsMap['month'],
                  individualItemAllStatsMap['day'])
              .difference(DateTime(individualItemAllStatsMap['year']))
              .inDays +
          1;

      int dayMillisecondsSinceEpoch = DateTime(
              individualItemAllStatsMap['year'],
              individualItemAllStatsMap['month'],
              individualItemAllStatsMap['day'])
          .millisecondsSinceEpoch;
      if (individualItemStatsMap.containsKey('mapCategoryAndItemsMap')) {
        categoryAndItemsDayStats.addAll({
          dayMillisecondsSinceEpoch:
              individualItemStatsMap['mapCategoryAndItemsMap']
        });
      }
      if (individualItemStatsMap.containsKey('menuIndividualItemsStatsMap')) {
        individualItemsDayStats.addAll({
          dayMillisecondsSinceEpoch:
              individualItemStatsMap['menuIndividualItemsStatsMap']
        });
      }
      if (individualItemStatsMap
          .containsKey('mapExtraIndividualItemsStatsMap')) {
        extraIndividualItemsDayStats.addAll({
          dayMillisecondsSinceEpoch:
              individualItemStatsMap['mapExtraIndividualItemsStatsMap']
        });
      }

      //NextWeNeedToEnsureThatWeRegisterThatTheDayHasData
      if (savedStatisticsDayData
          .containsKey(individualItemAllStatsMap['year'])) {
//ThisMeansYearDataAlreadyExists
        Map<int, bool> tempDayExistenceCheckInYear = savedStatisticsDayData[
            int.parse(individualItemAllStatsMap['year'].toString())];
        if (!tempDayExistenceCheckInYear.containsKey(dayNumberFromNewYear)) {
          tempDayExistenceCheckInYear.addAll({dayNumberFromNewYear: true});
          savedStatisticsDayData[
                  int.parse(individualItemAllStatsMap['year'].toString())] =
              tempDayExistenceCheckInYear;
        }
      } else {
        savedStatisticsDayData.addAll({
          int.parse(individualItemAllStatsMap['year'].toString()): {
            dayNumberFromNewYear: true
          }
        });
      }
    } else {
      int monthMillisecondsSinceEpoch = DateTime(
              individualItemAllStatsMap['year'],
              individualItemAllStatsMap['month'],
              15,
              12)
          .millisecondsSinceEpoch;
      if (individualItemStatsMap.containsKey('mapCategoryAndItemsMap')) {
        categoryAndItemsMonthStats.addAll({
          monthMillisecondsSinceEpoch:
              individualItemStatsMap['mapCategoryAndItemsMap']
        });
      }
      if (individualItemStatsMap.containsKey('menuIndividualItemsStatsMap')) {
        individualItemsMonthStats.addAll({
          monthMillisecondsSinceEpoch:
              individualItemStatsMap['menuIndividualItemsStatsMap']
        });
      }
      if (individualItemStatsMap
          .containsKey('mapExtraIndividualItemsStatsMap')) {
        extraIndividualItemsMonthStats.addAll({
          monthMillisecondsSinceEpoch:
              individualItemStatsMap['mapExtraIndividualItemsStatsMap']
        });
      }

//NextWeNeedToEnsureThatWeRegisterThatTheMonthHasData
      if (savedStatisticsMonthData
          .containsKey(individualItemAllStatsMap['year'])) {
//ThisMeansYearDataAlreadyExists
        Map<int, bool> tempMonthExistenceCheckInYear = savedStatisticsMonthData[
            int.parse(individualItemAllStatsMap['year'].toString())];
        if (!tempMonthExistenceCheckInYear
            .containsKey(individualItemAllStatsMap['month'])) {
          tempMonthExistenceCheckInYear.addAll(
              {int.parse(individualItemAllStatsMap['month'].toString()): true});
          savedStatisticsMonthData[
                  int.parse(individualItemAllStatsMap['year'].toString())] =
              tempMonthExistenceCheckInYear;
        }
      } else {
        savedStatisticsMonthData.addAll({
          int.parse(individualItemAllStatsMap['year'].toString()): {
            int.parse(individualItemAllStatsMap['month'].toString()): true
          }
        });
      }
    }
  }

  void expenseStatsConversion(Map<String, dynamic> expenseStatsMap) {
    Map<String, dynamic> expensesFromFullStats = expenseStatsMap['expenses'];

    if (expenseStatsMap.containsKey('day')) {
      int dayNumberFromNewYear = DateTime(expenseStatsMap['year'],
                  expenseStatsMap['month'], expenseStatsMap['day'])
              .difference(DateTime(expenseStatsMap['year']))
              .inDays +
          1;

      int dayMillisecondsSinceEpoch = DateTime(expenseStatsMap['year'],
              expenseStatsMap['month'], expenseStatsMap['day'])
          .millisecondsSinceEpoch;
      if (expensesFromFullStats.containsKey('mapEachExpenseStatisticsMap')) {
        eachExpenseDayStats.addAll({
          dayMillisecondsSinceEpoch:
              expensesFromFullStats['mapEachExpenseStatisticsMap']
        });
      }
      if (expensesFromFullStats.containsKey('mapExpensePaidByUserMap')) {
        expensePaidByUserDayStats.addAll({
          dayMillisecondsSinceEpoch:
              expensesFromFullStats['mapExpensePaidByUserMap']
        });
      }
      if (expensesFromFullStats.containsKey('mapExpensePaymentMethodMap')) {
        expensePaymentMethodDayStats.addAll({
          dayMillisecondsSinceEpoch:
              expensesFromFullStats['mapExpensePaymentMethodMap']
        });
      }

      //NextWeNeedToEnsureThatWeRegisterThatTheDayHasData
      if (savedStatisticsDayData.containsKey(expenseStatsMap['year'])) {
//ThisMeansYearDataAlreadyExists
        Map<int, bool> tempDayExistenceCheckInYear = savedStatisticsDayData[
            int.parse(expenseStatsMap['year'].toString())];
        if (!tempDayExistenceCheckInYear.containsKey(dayNumberFromNewYear)) {
          tempDayExistenceCheckInYear.addAll({dayNumberFromNewYear: true});
          savedStatisticsDayData[
                  int.parse(expenseStatsMap['year'].toString())] =
              tempDayExistenceCheckInYear;
        }
      } else {
        savedStatisticsDayData.addAll({
          int.parse(expenseStatsMap['year'].toString()): {
            dayNumberFromNewYear: true
          }
        });
      }
    } else {
      int monthMillisecondsSinceEpoch =
          DateTime(expenseStatsMap['year'], expenseStatsMap['month'], 15, 12)
              .millisecondsSinceEpoch;
      if (expensesFromFullStats.containsKey('mapEachExpenseStatisticsMap')) {
        eachExpenseMonthStats.addAll({
          monthMillisecondsSinceEpoch:
              expensesFromFullStats['mapEachExpenseStatisticsMap']
        });
      }
      if (expensesFromFullStats.containsKey('mapExpensePaidByUserMap')) {
        expensePaidByUserMonthStats.addAll({
          monthMillisecondsSinceEpoch:
              expensesFromFullStats['mapExpensePaidByUserMap']
        });
      }
      if (expensesFromFullStats.containsKey('mapExpensePaymentMethodMap')) {
        expensePaymentMethodMonthStats.addAll({
          monthMillisecondsSinceEpoch:
              expensesFromFullStats['mapExpensePaymentMethodMap']
        });
      }
//NextWeNeedToEnsureThatWeRegisterThatTheMonthHasData

      if (savedStatisticsMonthData.containsKey(expenseStatsMap['year'])) {
//ThisMeansYearDataAlreadyExists
        Map<int, bool> tempMonthExistenceCheckInYear = savedStatisticsMonthData[
            int.parse(expenseStatsMap['year'].toString())];
        if (!tempMonthExistenceCheckInYear
            .containsKey(expenseStatsMap['month'])) {
          tempMonthExistenceCheckInYear
              .addAll({int.parse(expenseStatsMap['month'].toString()): true});
          savedStatisticsMonthData[
                  int.parse(expenseStatsMap['year'].toString())] =
              tempMonthExistenceCheckInYear;
        }
      } else {
        savedStatisticsMonthData.addAll({
          int.parse(expenseStatsMap['year'].toString()): {
            int.parse(expenseStatsMap['month'].toString()): true
          }
        });
      }
    }
  }

  // void cashBalanceDataConversion(
  //     String cashBalanceDocumentName, Map<String, dynamic> cashBalanceDataMap) {
  //   Map<String, dynamic> cashBalanceStatsOfThePeriod = HashMap();
  //   if (cashBalanceDataMap.containsKey('cashBalanceData')) {
  //     cashBalanceStatsOfThePeriod
  //         .addAll({'cashBalanceData': cashBalanceDataMap['cashBalanceData']});
  //   }
  //   savedStatisticsCashBalanceData
  //       .addAll({cashBalanceDocumentName: cashBalanceStatsOfThePeriod});
  // }

  void dataCalculationVersionTwo() {
//generalStatsCalculation
    noRecordsFound = false;
    firstCalculationStarted = true;
    finalGeneralStatsCalculated = {};
    totalSalesIncomeDuringTheCalculationPeriod = 0;
    finalBilledCancelledIndividualItemsStatsCalculated = {};
    finalNonBilledCancelledIndividualItemsStatsCalculated = {};
    finalBilledCaptainCancelledIndividualItemsStats = {};
    finalNonBilledCaptainCancelledIndividualItemsStats = {};
    finalBilledCaptainCancellationStats = {};
    finalNonBilledCaptainCancellationStats = {};
    finalBilledChefRejectedIndividualItemsStats = {};
    finalNonBilledChefRejectedIndividualItemsStats = {};
    finalBilledChefRejectionStats = {};
    finalNonBilledChefRejectionStats = {};
    finalSalesIndividualItemsStatsCalculated = {};
    finalSalesExtraIndividualItemsStatsCalculated = {};
    finalEachCategoryWithItemsList = {};
    finalEachCategorySalesStats = {};
    finalSalesPaymentMethodStatsCalculated = {};
    finalCashierClosingAmountStats = {};
    finalCashierClosingPaymentMethodStats = {};
    finalCaptainIndividualItemsOrdersTakenStats = {};
    finalCaptainOrdersTakenGeneralStats = {};
    finalEachExpenseStatsCalculated = {};
    finalExpensePaymentMethodStatsCalculated = {};
    finalExpensePaidByUserGeneralStatsCalculated = {};
    finalExpensePaidByUserPaymentMethodStatsCalculated = {};
    totalExpenseDuringTheCalculationPeriod = 0;
//GeneralStatsCalculated
    if (calculationDaysNeeded.isNotEmpty) {
      for (var eachDay in calculationDaysNeeded) {
        if (generalStatsDayStats.containsKey(eachDay)) {
          Map<String, dynamic> eachDayStat = generalStatsDayStats[eachDay];
          eachDayStat.forEach((key, value) {
            if (key == 'totalbillamounttoday') {
              totalSalesIncomeDuringTheCalculationPeriod =
                  totalSalesIncomeDuringTheCalculationPeriod + value;
            }
            if (finalGeneralStatsCalculated.containsKey(key)) {
              finalGeneralStatsCalculated[key] =
                  finalGeneralStatsCalculated[key]! + value;
            } else {
              finalGeneralStatsCalculated.addAll({key: value});
            }
          });
        }
      }
    }
    if (calculationMonthsNeeded.isNotEmpty) {
      for (var eachMonth in calculationMonthsNeeded) {
        if (generalStatsMonthStats.containsKey(eachMonth)) {
          Map<String, dynamic> eachMonthStat =
              generalStatsMonthStats[eachMonth];
          eachMonthStat.forEach((key, value) {
            if (key == 'totalbillamounttoday') {
              totalSalesIncomeDuringTheCalculationPeriod =
                  totalSalesIncomeDuringTheCalculationPeriod + value;
            }
            if (finalGeneralStatsCalculated.containsKey(key)) {
              finalGeneralStatsCalculated[key] =
                  finalGeneralStatsCalculated[key]! + value;
            } else {
              finalGeneralStatsCalculated.addAll({key: value});
            }
          });
        }
      }
    }
//CashierClosingStats
    if (calculationDaysNeeded.isNotEmpty) {
      for (var eachDay in calculationDaysNeeded) {
        if (salesCashierDayStats.containsKey(eachDay)) {
          Map<String, dynamic> eachDayStat = salesCashierDayStats[eachDay];
          eachDayStat.forEach((cashierPhoneNumberAsKey, cashierStatsAsValue) {
            Map<String, dynamic> copyOfEntireMap = cashierStatsAsValue;
            copyOfEntireMap.forEach((statNameAsKey, statAsValue) {
              if (statNameAsKey == 'paymentMethodStats') {
                // ThisIfForCashierPaymentMethod
                if (finalCashierClosingPaymentMethodStats
                    .containsKey(cashierPhoneNumberAsKey)) {
//ThisMeansWeHadAlreadyCalculatedCashierPaymentMethodStatsBefore
                  Map<String, dynamic>? tempAlreadyAddedMap =
                      finalCashierClosingPaymentMethodStats[
                          cashierPhoneNumberAsKey];
                  Map<String, dynamic> mapWithKeyAndMapPair = statAsValue;
                  mapWithKeyAndMapPair.forEach(
                      (paymentMethodNameAsKey, secondaryMapWithStatsAsValue) {
                    if (tempAlreadyAddedMap!
                        .containsKey(paymentMethodNameAsKey)) {
                      Map<String, dynamic> copyOfSecondaryMapOfStatsAsValue =
                          secondaryMapWithStatsAsValue;
                      Map<String, dynamic> eachMapFromTempAlreadyAddedMap =
                          tempAlreadyAddedMap[paymentMethodNameAsKey];
                      copyOfSecondaryMapOfStatsAsValue
                          .forEach((eachStatNameAsKey, statAsValue) {
                        if (eachMapFromTempAlreadyAddedMap
                            .containsKey(eachStatNameAsKey)) {
//IfKeyAlreadyExists
                          eachMapFromTempAlreadyAddedMap[eachStatNameAsKey] =
                              eachMapFromTempAlreadyAddedMap[
                                      eachStatNameAsKey] +
                                  statAsValue;
                        } else {
//IfKeyDoesn'tExist
                          eachMapFromTempAlreadyAddedMap
                              .addAll({eachStatNameAsKey: statAsValue});
                        }
                      });
//FirstWeAddToAlreadyAddedMap
                      tempAlreadyAddedMap[paymentMethodNameAsKey] =
                          eachMapFromTempAlreadyAddedMap;
                    } else {
//WeCanAddTheSecondaryMethodStraightAwayBecauseThisKeyDidn'tExistBefore
                      tempAlreadyAddedMap.addAll({
                        paymentMethodNameAsKey: secondaryMapWithStatsAsValue
                      });
                    }
                  });

                  finalCashierClosingPaymentMethodStats[
                      cashierPhoneNumberAsKey] = tempAlreadyAddedMap!;
                } else {
                  finalCashierClosingPaymentMethodStats
                      .addAll({cashierPhoneNumberAsKey: statAsValue});
                }
              } else {
//ThisIsForAllCashierStatsExceptPaymentMethod
                if (finalCashierClosingAmountStats
                    .containsKey(cashierPhoneNumberAsKey)) {
                  //ThisMeansWeHadAlreadyCalculatedCashierAmountStatsBefore
                  Map<String, dynamic>? tempAlreadyAddedMap =
                      finalCashierClosingAmountStats[cashierPhoneNumberAsKey];

                  if (tempAlreadyAddedMap!.containsKey(statNameAsKey)) {
                    tempAlreadyAddedMap[statNameAsKey] =
                        tempAlreadyAddedMap[statNameAsKey] + statAsValue;
                  } else {
                    tempAlreadyAddedMap.addAll({statNameAsKey: statAsValue});
                  }

                  finalCashierClosingAmountStats[cashierPhoneNumberAsKey] =
                      tempAlreadyAddedMap!;
                } else {
                  finalCashierClosingAmountStats.addAll({
                    cashierPhoneNumberAsKey: {statNameAsKey: statAsValue}
                  });
                }
              }
            });
          });
        }
      }
    }
    if (calculationMonthsNeeded.isNotEmpty) {
      for (var eachMonth in calculationMonthsNeeded) {
        if (salesCashierMonthStats.containsKey(eachMonth)) {
          Map<String, dynamic> eachMonthStat =
              salesCashierMonthStats[eachMonth];
          eachMonthStat.forEach((cashierPhoneNumberAsKey, cashierStatsAsValue) {
            Map<String, dynamic> copyOfEntireMap = cashierStatsAsValue;
            copyOfEntireMap.forEach((statNameAsKey, statAsValue) {
              if (statNameAsKey == 'paymentMethodStats') {
                // ThisIfForCashierPaymentMethod
                if (finalCashierClosingPaymentMethodStats
                    .containsKey(cashierPhoneNumberAsKey)) {
//ThisMeansWeHadAlreadyCalculatedCashierPaymentMethodStatsBefore
                  Map<String, dynamic>? tempAlreadyAddedMap =
                      finalCashierClosingPaymentMethodStats[
                          cashierPhoneNumberAsKey];
                  Map<String, dynamic> mapWithKeyAndMapPair = statAsValue;
                  mapWithKeyAndMapPair.forEach(
                      (paymentMethodNameAsKey, secondaryMapWithStatsAsValue) {
                    if (tempAlreadyAddedMap!
                        .containsKey(paymentMethodNameAsKey)) {
                      Map<String, dynamic> copyOfSecondaryMapOfStatsAsValue =
                          secondaryMapWithStatsAsValue;
                      Map<String, dynamic> eachMapFromTempAlreadyAddedMap =
                          tempAlreadyAddedMap[paymentMethodNameAsKey];
                      copyOfSecondaryMapOfStatsAsValue
                          .forEach((eachStatNameAsKey, statAsValue) {
                        if (eachMapFromTempAlreadyAddedMap
                            .containsKey(eachStatNameAsKey)) {
//IfKeyAlreadyExists
                          eachMapFromTempAlreadyAddedMap[eachStatNameAsKey] =
                              eachMapFromTempAlreadyAddedMap[
                                      eachStatNameAsKey] +
                                  statAsValue;
                        } else {
//IfKeyDoesn'tExist
                          eachMapFromTempAlreadyAddedMap
                              .addAll({eachStatNameAsKey: statAsValue});
                        }
                      });
//FirstWeAddToAlreadyAddedMap
                      tempAlreadyAddedMap[paymentMethodNameAsKey] =
                          eachMapFromTempAlreadyAddedMap;
                    } else {
//WeCanAddTheSecondaryMethodStraightAwayBecauseThisKeyDidn'tExistBefore
                      tempAlreadyAddedMap.addAll({
                        paymentMethodNameAsKey: secondaryMapWithStatsAsValue
                      });
                    }
                  });

                  finalCashierClosingPaymentMethodStats[
                      cashierPhoneNumberAsKey] = tempAlreadyAddedMap!;
                } else {
                  finalCashierClosingPaymentMethodStats
                      .addAll({cashierPhoneNumberAsKey: statAsValue});
                }
              } else {
//ThisIsForAllCashierStatsExceptPaymentMethod
                if (finalCashierClosingAmountStats
                    .containsKey(cashierPhoneNumberAsKey)) {
                  //ThisMeansWeHadAlreadyCalculatedCashierAmountStatsBefore
                  Map<String, dynamic>? tempAlreadyAddedMap =
                      finalCashierClosingAmountStats[cashierPhoneNumberAsKey];

                  if (tempAlreadyAddedMap!.containsKey(statNameAsKey)) {
                    tempAlreadyAddedMap[statNameAsKey] =
                        tempAlreadyAddedMap[statNameAsKey] + statAsValue;
                  } else {
                    tempAlreadyAddedMap.addAll({statNameAsKey: statAsValue});
                  }

                  finalCashierClosingAmountStats[cashierPhoneNumberAsKey] =
                      tempAlreadyAddedMap!;
                } else {
                  finalCashierClosingAmountStats.addAll({
                    cashierPhoneNumberAsKey: {statNameAsKey: statAsValue}
                  });
                }
              }
            });
          });
        }
      }
    }
//PaymentMethodClosingStats
    if (calculationDaysNeeded.isNotEmpty) {
      for (var eachDay in calculationDaysNeeded) {
        if (salesPaymentMethodDayStats.containsKey(eachDay)) {
          Map<String, dynamic> eachDayStat =
              salesPaymentMethodDayStats[eachDay];
          eachDayStat.forEach((paymentNameAsKey, paymentStatsAsValue) {
            if (finalSalesPaymentMethodStatsCalculated
                .containsKey(paymentNameAsKey)) {
//ThisMeansWeHadAlreadyCalculatedThisItemBefore
              Map<String, dynamic> copyOfPaymentStatsAsValue =
                  paymentStatsAsValue;
              Map<String, dynamic>? tempAlreadyAddedMap =
                  finalSalesPaymentMethodStatsCalculated[paymentNameAsKey];
              copyOfPaymentStatsAsValue!
                  .forEach((eachStatOfPaymentMethodKey, valueOfThatStat) {
                if (tempAlreadyAddedMap!
                    .containsKey(eachStatOfPaymentMethodKey)) {
                  tempAlreadyAddedMap[eachStatOfPaymentMethodKey] =
                      tempAlreadyAddedMap[eachStatOfPaymentMethodKey] +
                          valueOfThatStat;
                } else {
                  tempAlreadyAddedMap
                      .addAll({eachStatOfPaymentMethodKey: valueOfThatStat});
                }
              });
              finalSalesPaymentMethodStatsCalculated[paymentNameAsKey] =
                  tempAlreadyAddedMap!;
            } else {
              finalSalesPaymentMethodStatsCalculated
                  .addAll({paymentNameAsKey: paymentStatsAsValue});
            }
          });
        }
      }
    }
    if (calculationMonthsNeeded.isNotEmpty) {
      for (var eachMonth in calculationMonthsNeeded) {
        if (salesPaymentMethodMonthStats.containsKey(eachMonth)) {
          Map<String, dynamic> eachMonthStat =
              salesPaymentMethodMonthStats[eachMonth];
          eachMonthStat.forEach((paymentNameAsKey, paymentStatsAsValue) {
            if (finalSalesPaymentMethodStatsCalculated
                .containsKey(paymentNameAsKey)) {
//ThisMeansWeHadAlreadyCalculatedThisItemBefore
              Map<String, dynamic> copyOfPaymentStatsAsValue =
                  paymentStatsAsValue;
              Map<String, dynamic>? tempAlreadyAddedMap =
                  finalSalesPaymentMethodStatsCalculated[paymentNameAsKey];
              copyOfPaymentStatsAsValue!
                  .forEach((eachStatOfPaymentMethodKey, valueOfThatStat) {
                if (tempAlreadyAddedMap!
                    .containsKey(eachStatOfPaymentMethodKey)) {
                  tempAlreadyAddedMap[eachStatOfPaymentMethodKey] =
                      tempAlreadyAddedMap[eachStatOfPaymentMethodKey] +
                          valueOfThatStat;
                } else {
                  tempAlreadyAddedMap
                      .addAll({eachStatOfPaymentMethodKey: valueOfThatStat});
                }
              });
              finalSalesPaymentMethodStatsCalculated[paymentNameAsKey] =
                  tempAlreadyAddedMap!;
            } else {
              finalSalesPaymentMethodStatsCalculated
                  .addAll({paymentNameAsKey: paymentStatsAsValue});
            }
          });
        }
      }
    }
//BilledCancelledIndividualItemsStats
    if (calculationDaysNeeded.isNotEmpty) {
      for (var eachDay in calculationDaysNeeded) {
        if (billedCancelledIndividualItemDayStats.containsKey(eachDay)) {
          Map<String, dynamic> eachDayStat =
              billedCancelledIndividualItemDayStats[eachDay];
          eachDayStat.forEach((itemNameAsKey, itemStatsAsValue) {
            if (finalBilledCancelledIndividualItemsStatsCalculated
                .containsKey(itemNameAsKey)) {
//ThisMeansWeHadAlreadyCalculatedThisItemBefore
              Map<String, dynamic> copyOfItemStatsAsValue = itemStatsAsValue;
              Map<String, dynamic>? tempAlreadyAddedMap =
                  finalBilledCancelledIndividualItemsStatsCalculated[
                      itemNameAsKey];
              copyOfItemStatsAsValue!
                  .forEach((eachStatOfItemNameAsKey, valueOfThatStat) {
                if (tempAlreadyAddedMap!.containsKey(eachStatOfItemNameAsKey)) {
                  tempAlreadyAddedMap[eachStatOfItemNameAsKey] =
                      tempAlreadyAddedMap[eachStatOfItemNameAsKey] +
                          valueOfThatStat;
                } else {
                  tempAlreadyAddedMap
                      .addAll({eachStatOfItemNameAsKey: valueOfThatStat});
                }
              });
              finalBilledCancelledIndividualItemsStatsCalculated[
                  itemNameAsKey] = tempAlreadyAddedMap!;
            } else {
              finalBilledCancelledIndividualItemsStatsCalculated
                  .addAll({itemNameAsKey: itemStatsAsValue});
            }
          });
        }
      }
    }
    if (calculationMonthsNeeded.isNotEmpty) {
      for (var eachMonth in calculationMonthsNeeded) {
        if (billedCancelledIndividualItemMonthStats.containsKey(eachMonth)) {
          Map<String, dynamic> eachMonthStat =
              billedCancelledIndividualItemMonthStats[eachMonth];
          eachMonthStat.forEach((itemNameAsKey, itemStatsAsValue) {
            if (finalBilledCancelledIndividualItemsStatsCalculated
                .containsKey(itemNameAsKey)) {
//ThisMeansWeHadAlreadyCalculatedThisItemBefore
              Map<String, dynamic> copyOfItemStatsAsValue = itemStatsAsValue;
              Map<String, dynamic>? tempAlreadyAddedMap =
                  finalBilledCancelledIndividualItemsStatsCalculated[
                      itemNameAsKey];
              copyOfItemStatsAsValue!
                  .forEach((eachStatOfItemNameAsKey, valueOfThatStat) {
                if (tempAlreadyAddedMap!.containsKey(eachStatOfItemNameAsKey)) {
                  tempAlreadyAddedMap[eachStatOfItemNameAsKey] =
                      tempAlreadyAddedMap[eachStatOfItemNameAsKey] +
                          valueOfThatStat;
                } else {
                  tempAlreadyAddedMap
                      .addAll({eachStatOfItemNameAsKey: valueOfThatStat});
                }
              });
              finalBilledCancelledIndividualItemsStatsCalculated[
                  itemNameAsKey] = tempAlreadyAddedMap!;
            } else {
              finalBilledCancelledIndividualItemsStatsCalculated
                  .addAll({itemNameAsKey: itemStatsAsValue});
            }
          });
        }
      }
    }
//NonBilledCancelledIndividualItemsStats
    if (calculationDaysNeeded.isNotEmpty) {
      for (var eachDay in calculationDaysNeeded) {
        if (nonBilledCancelledIndividualItemDayStats.containsKey(eachDay)) {
          Map<String, dynamic> eachDayStat =
              nonBilledCancelledIndividualItemDayStats[eachDay];
          eachDayStat.forEach((itemNameAsKey, itemStatsAsValue) {
            if (finalNonBilledCancelledIndividualItemsStatsCalculated
                .containsKey(itemNameAsKey)) {
//ThisMeansWeHadAlreadyCalculatedThisItemBefore
              Map<String, dynamic> copyOfItemStatsAsValue = itemStatsAsValue;
              Map<String, dynamic>? tempAlreadyAddedMap =
                  finalNonBilledCancelledIndividualItemsStatsCalculated[
                      itemNameAsKey];
              copyOfItemStatsAsValue!
                  .forEach((eachStatOfItemNameAsKey, valueOfThatStat) {
                if (tempAlreadyAddedMap!.containsKey(eachStatOfItemNameAsKey)) {
                  tempAlreadyAddedMap[eachStatOfItemNameAsKey] =
                      tempAlreadyAddedMap[eachStatOfItemNameAsKey] +
                          valueOfThatStat;
                } else {
                  tempAlreadyAddedMap
                      .addAll({eachStatOfItemNameAsKey: valueOfThatStat});
                }
              });
              finalNonBilledCancelledIndividualItemsStatsCalculated[
                  itemNameAsKey] = tempAlreadyAddedMap!;
            } else {
              finalNonBilledCancelledIndividualItemsStatsCalculated
                  .addAll({itemNameAsKey: itemStatsAsValue});
            }
          });
        }
      }
    }
    if (calculationMonthsNeeded.isNotEmpty) {
      for (var eachMonth in calculationMonthsNeeded) {
        if (nonBilledCancelledIndividualItemMonthStats.containsKey(eachMonth)) {
          Map<String, dynamic> eachMonthStat =
              nonBilledCancelledIndividualItemMonthStats[eachMonth];
          eachMonthStat.forEach((itemNameAsKey, itemStatsAsValue) {
            if (finalNonBilledCancelledIndividualItemsStatsCalculated
                .containsKey(itemNameAsKey)) {
//ThisMeansWeHadAlreadyCalculatedThisItemBefore
              Map<String, dynamic> copyOfItemStatsAsValue = itemStatsAsValue;
              Map<String, dynamic>? tempAlreadyAddedMap =
                  finalNonBilledCancelledIndividualItemsStatsCalculated[
                      itemNameAsKey];
              copyOfItemStatsAsValue!
                  .forEach((eachStatOfItemNameAsKey, valueOfThatStat) {
                if (tempAlreadyAddedMap!.containsKey(eachStatOfItemNameAsKey)) {
                  tempAlreadyAddedMap[eachStatOfItemNameAsKey] =
                      tempAlreadyAddedMap[eachStatOfItemNameAsKey] +
                          valueOfThatStat;
                } else {
                  tempAlreadyAddedMap
                      .addAll({eachStatOfItemNameAsKey: valueOfThatStat});
                }
              });
              finalNonBilledCancelledIndividualItemsStatsCalculated[
                  itemNameAsKey] = tempAlreadyAddedMap!;
            } else {
              finalNonBilledCancelledIndividualItemsStatsCalculated
                  .addAll({itemNameAsKey: itemStatsAsValue});
            }
          });
        }
      }
    }
//BilledCancellingCaptainStats
    if (calculationDaysNeeded.isNotEmpty) {
      for (var eachDay in calculationDaysNeeded) {
        if (billedCancellingCaptainDayStats.containsKey(eachDay)) {
          Map<String, dynamic> eachDayStat =
              billedCancellingCaptainDayStats[eachDay];
          eachDayStat.forEach((cancellingCaptainPhoneNumberAsKey,
              cancellingCaptainStatsAsValue) {
            Map<String, dynamic> copyOfEntireMap =
                cancellingCaptainStatsAsValue;
            copyOfEntireMap.forEach((statNameAsKey, statAsValue) {
              if (statNameAsKey == 'IICC') {
//ThisIsForCancelledIndividualItems
                if (finalBilledCaptainCancelledIndividualItemsStats
                    .containsKey(cancellingCaptainPhoneNumberAsKey)) {
                  //ThisMeansWeHadAlreadyCalculatedCashierPaymentMethodStatsBefore
                  Map<String, dynamic>? tempAlreadyAddedMap =
                      finalBilledCaptainCancelledIndividualItemsStats[
                          cancellingCaptainPhoneNumberAsKey];
                  Map<String, dynamic> mapWithKeyAndMapPair = statAsValue;
                  mapWithKeyAndMapPair.forEach(
                      (individualItemNameAsKey, secondaryMapWithStatsAsValue) {
                    if (tempAlreadyAddedMap!
                        .containsKey(individualItemNameAsKey)) {
                      Map<String, dynamic> copyOfSecondaryMapOfStatsAsValue =
                          secondaryMapWithStatsAsValue;
                      Map<String, dynamic> eachMapFromTempAlreadyAddedMap =
                          tempAlreadyAddedMap[individualItemNameAsKey];
                      copyOfSecondaryMapOfStatsAsValue
                          .forEach((eachStatNameAsKey, statAsValue) {
                        if (eachMapFromTempAlreadyAddedMap
                            .containsKey(eachStatNameAsKey)) {
//IfKeyAlreadyExists
                          eachMapFromTempAlreadyAddedMap[eachStatNameAsKey] =
                              eachMapFromTempAlreadyAddedMap[
                                      eachStatNameAsKey] +
                                  statAsValue;
                        } else {
//IfKeyDoesn'tExist
                          eachMapFromTempAlreadyAddedMap
                              .addAll({eachStatNameAsKey: statAsValue});
                        }
                      });
//FirstWeAddToAlreadyAddedMap
                      tempAlreadyAddedMap[individualItemNameAsKey] =
                          eachMapFromTempAlreadyAddedMap;
                    } else {
//WeCanAddTheSecondaryMethodStraightAwayBecauseThisKeyDidn'tExistBefore
                      tempAlreadyAddedMap.addAll({
                        individualItemNameAsKey: secondaryMapWithStatsAsValue
                      });
                    }
                  });

                  finalBilledCaptainCancelledIndividualItemsStats[
                      cancellingCaptainPhoneNumberAsKey] = tempAlreadyAddedMap!;
                } else {
                  finalBilledCaptainCancelledIndividualItemsStats
                      .addAll({cancellingCaptainPhoneNumberAsKey: statAsValue});
                }
              } else {
//AllTheOtherCaptainCancellingStatsExceptIndividualItems
                if (finalBilledCaptainCancellationStats
                    .containsKey(cancellingCaptainPhoneNumberAsKey)) {
                  //ThisMeansWeHadAlreadyCalculatedCashierAmountStatsBefore
                  Map<String, dynamic>? tempAlreadyAddedMap =
                      finalBilledCaptainCancellationStats[
                          cancellingCaptainPhoneNumberAsKey];

                  if (tempAlreadyAddedMap!.containsKey(statNameAsKey)) {
                    tempAlreadyAddedMap[statNameAsKey] =
                        tempAlreadyAddedMap[statNameAsKey] + statAsValue;
                  } else {
                    tempAlreadyAddedMap.addAll({statNameAsKey: statAsValue});
                  }

                  finalBilledCaptainCancellationStats[
                      cancellingCaptainPhoneNumberAsKey] = tempAlreadyAddedMap!;
                } else {
                  finalBilledCaptainCancellationStats.addAll({
                    cancellingCaptainPhoneNumberAsKey: {
                      statNameAsKey: statAsValue
                    }
                  });
                }
              }
            });
          });
        }
      }
    }
    if (calculationMonthsNeeded.isNotEmpty) {
      for (var eachMonth in calculationMonthsNeeded) {
        if (billedCancellingCaptainMonthStats.containsKey(eachMonth)) {
          Map<String, dynamic> eachMonthStat =
              billedCancellingCaptainMonthStats[eachMonth];
          eachMonthStat.forEach((cancellingCaptainPhoneNumberAsKey,
              cancellingCaptainStatsAsValue) {
            Map<String, dynamic> copyOfEntireMap =
                cancellingCaptainStatsAsValue;
            copyOfEntireMap.forEach((statNameAsKey, statAsValue) {
              if (statNameAsKey == 'IICC') {
//ThisIsForCancelledIndividualItems
                if (finalBilledCaptainCancelledIndividualItemsStats
                    .containsKey(cancellingCaptainPhoneNumberAsKey)) {
                  //ThisMeansWeHadAlreadyCalculatedCashierPaymentMethodStatsBefore
                  Map<String, dynamic>? tempAlreadyAddedMap =
                      finalBilledCaptainCancelledIndividualItemsStats[
                          cancellingCaptainPhoneNumberAsKey];
                  Map<String, dynamic> mapWithKeyAndMapPair = statAsValue;
                  mapWithKeyAndMapPair.forEach(
                      (individualItemNameAsKey, secondaryMapWithStatsAsValue) {
                    if (tempAlreadyAddedMap!
                        .containsKey(individualItemNameAsKey)) {
                      Map<String, dynamic> copyOfSecondaryMapOfStatsAsValue =
                          secondaryMapWithStatsAsValue;
                      Map<String, dynamic> eachMapFromTempAlreadyAddedMap =
                          tempAlreadyAddedMap[individualItemNameAsKey];
                      copyOfSecondaryMapOfStatsAsValue
                          .forEach((eachStatNameAsKey, statAsValue) {
                        if (eachMapFromTempAlreadyAddedMap
                            .containsKey(eachStatNameAsKey)) {
//IfKeyAlreadyExists
                          eachMapFromTempAlreadyAddedMap[eachStatNameAsKey] =
                              eachMapFromTempAlreadyAddedMap[
                                      eachStatNameAsKey] +
                                  statAsValue;
                        } else {
//IfKeyDoesn'tExist
                          eachMapFromTempAlreadyAddedMap
                              .addAll({eachStatNameAsKey: statAsValue});
                        }
                      });
//FirstWeAddToAlreadyAddedMap
                      tempAlreadyAddedMap[individualItemNameAsKey] =
                          eachMapFromTempAlreadyAddedMap;
                    } else {
//WeCanAddTheSecondaryMethodStraightAwayBecauseThisKeyDidn'tExistBefore
                      tempAlreadyAddedMap.addAll({
                        individualItemNameAsKey: secondaryMapWithStatsAsValue
                      });
                    }
                  });

                  finalBilledCaptainCancelledIndividualItemsStats[
                      cancellingCaptainPhoneNumberAsKey] = tempAlreadyAddedMap!;
                } else {
                  finalBilledCaptainCancelledIndividualItemsStats
                      .addAll({cancellingCaptainPhoneNumberAsKey: statAsValue});
                }
              } else {
//AllTheOtherCaptainCancellingStatsExceptIndividualItems
                if (finalBilledCaptainCancellationStats
                    .containsKey(cancellingCaptainPhoneNumberAsKey)) {
                  //ThisMeansWeHadAlreadyCalculatedCashierAmountStatsBefore
                  Map<String, dynamic>? tempAlreadyAddedMap =
                      finalBilledCaptainCancellationStats[
                          cancellingCaptainPhoneNumberAsKey];

                  if (tempAlreadyAddedMap!.containsKey(statNameAsKey)) {
                    tempAlreadyAddedMap[statNameAsKey] =
                        tempAlreadyAddedMap[statNameAsKey] + statAsValue;
                  } else {
                    tempAlreadyAddedMap.addAll({statNameAsKey: statAsValue});
                  }

                  finalBilledCaptainCancellationStats[
                      cancellingCaptainPhoneNumberAsKey] = tempAlreadyAddedMap!;
                } else {
                  finalBilledCaptainCancellationStats.addAll({
                    cancellingCaptainPhoneNumberAsKey: {
                      statNameAsKey: statAsValue
                    }
                  });
                }
              }
            });
          });
        }
      }
    }
//NonBilledCancellingCaptainStats
    if (calculationDaysNeeded.isNotEmpty) {
      for (var eachDay in calculationDaysNeeded) {
        if (nonBilledCancellingCaptainDayStats.containsKey(eachDay)) {
          Map<String, dynamic> eachDayStat =
              nonBilledCancellingCaptainDayStats[eachDay];
          eachDayStat.forEach((cancellingCaptainPhoneNumberAsKey,
              cancellingCaptainStatsAsValue) {
            Map<String, dynamic> copyOfEntireMap =
                cancellingCaptainStatsAsValue;
            copyOfEntireMap.forEach((statNameAsKey, statAsValue) {
              if (statNameAsKey == 'IICC') {
//ThisIsForCancelledIndividualItems
                if (finalNonBilledCaptainCancelledIndividualItemsStats
                    .containsKey(cancellingCaptainPhoneNumberAsKey)) {
                  //ThisMeansWeHadAlreadyCalculatedCashierPaymentMethodStatsBefore
                  Map<String, dynamic>? tempAlreadyAddedMap =
                      finalNonBilledCaptainCancelledIndividualItemsStats[
                          cancellingCaptainPhoneNumberAsKey];
                  Map<String, dynamic> mapWithKeyAndMapPair = statAsValue;
                  mapWithKeyAndMapPair.forEach(
                      (individualItemNameAsKey, secondaryMapWithStatsAsValue) {
                    if (tempAlreadyAddedMap!
                        .containsKey(individualItemNameAsKey)) {
                      Map<String, dynamic> copyOfSecondaryMapOfStatsAsValue =
                          secondaryMapWithStatsAsValue;
                      Map<String, dynamic> eachMapFromTempAlreadyAddedMap =
                          tempAlreadyAddedMap[individualItemNameAsKey];
                      copyOfSecondaryMapOfStatsAsValue
                          .forEach((eachStatNameAsKey, statAsValue) {
                        if (eachMapFromTempAlreadyAddedMap
                            .containsKey(eachStatNameAsKey)) {
//IfKeyAlreadyExists
                          eachMapFromTempAlreadyAddedMap[eachStatNameAsKey] =
                              eachMapFromTempAlreadyAddedMap[
                                      eachStatNameAsKey] +
                                  statAsValue;
                        } else {
//IfKeyDoesn'tExist
                          eachMapFromTempAlreadyAddedMap
                              .addAll({eachStatNameAsKey: statAsValue});
                        }
                      });
//FirstWeAddToAlreadyAddedMap
                      tempAlreadyAddedMap[individualItemNameAsKey] =
                          eachMapFromTempAlreadyAddedMap;
                    } else {
//WeCanAddTheSecondaryMethodStraightAwayBecauseThisKeyDidn'tExistBefore
                      tempAlreadyAddedMap.addAll({
                        individualItemNameAsKey: secondaryMapWithStatsAsValue
                      });
                    }
                  });

                  finalNonBilledCaptainCancelledIndividualItemsStats[
                      cancellingCaptainPhoneNumberAsKey] = tempAlreadyAddedMap!;
                } else {
                  finalNonBilledCaptainCancelledIndividualItemsStats
                      .addAll({cancellingCaptainPhoneNumberAsKey: statAsValue});
                }
              } else {
//AllTheOtherCaptainCancellingStatsExceptIndividualItems
                if (finalNonBilledCaptainCancellationStats
                    .containsKey(cancellingCaptainPhoneNumberAsKey)) {
                  //ThisMeansWeHadAlreadyCalculatedCashierAmountStatsBefore
                  Map<String, dynamic>? tempAlreadyAddedMap =
                      finalNonBilledCaptainCancellationStats[
                          cancellingCaptainPhoneNumberAsKey];

                  if (tempAlreadyAddedMap!.containsKey(statNameAsKey)) {
                    tempAlreadyAddedMap[statNameAsKey] =
                        tempAlreadyAddedMap[statNameAsKey] + statAsValue;
                  } else {
                    tempAlreadyAddedMap.addAll({statNameAsKey: statAsValue});
                  }

                  finalNonBilledCaptainCancellationStats[
                      cancellingCaptainPhoneNumberAsKey] = tempAlreadyAddedMap!;
                } else {
                  finalNonBilledCaptainCancellationStats.addAll({
                    cancellingCaptainPhoneNumberAsKey: {
                      statNameAsKey: statAsValue
                    }
                  });
                }
              }
            });
          });
        }
      }
    }
    if (calculationMonthsNeeded.isNotEmpty) {
      for (var eachMonth in calculationMonthsNeeded) {
        if (nonBilledCancellingCaptainMonthStats.containsKey(eachMonth)) {
          Map<String, dynamic> eachMonthStat =
              nonBilledCancellingCaptainMonthStats[eachMonth];
          eachMonthStat.forEach((cancellingCaptainPhoneNumberAsKey,
              cancellingCaptainStatsAsValue) {
            Map<String, dynamic> copyOfEntireMap =
                cancellingCaptainStatsAsValue;
            copyOfEntireMap.forEach((statNameAsKey, statAsValue) {
              if (statNameAsKey == 'IICC') {
//ThisIsForCancelledIndividualItems
                if (finalNonBilledCaptainCancelledIndividualItemsStats
                    .containsKey(cancellingCaptainPhoneNumberAsKey)) {
                  //ThisMeansWeHadAlreadyCalculatedCashierPaymentMethodStatsBefore
                  Map<String, dynamic>? tempAlreadyAddedMap =
                      finalNonBilledCaptainCancelledIndividualItemsStats[
                          cancellingCaptainPhoneNumberAsKey];
                  Map<String, dynamic> mapWithKeyAndMapPair = statAsValue;
                  mapWithKeyAndMapPair.forEach(
                      (individualItemNameAsKey, secondaryMapWithStatsAsValue) {
                    if (tempAlreadyAddedMap!
                        .containsKey(individualItemNameAsKey)) {
                      Map<String, dynamic> copyOfSecondaryMapOfStatsAsValue =
                          secondaryMapWithStatsAsValue;
                      Map<String, dynamic> eachMapFromTempAlreadyAddedMap =
                          tempAlreadyAddedMap[individualItemNameAsKey];
                      copyOfSecondaryMapOfStatsAsValue
                          .forEach((eachStatNameAsKey, statAsValue) {
                        if (eachMapFromTempAlreadyAddedMap
                            .containsKey(eachStatNameAsKey)) {
//IfKeyAlreadyExists
                          eachMapFromTempAlreadyAddedMap[eachStatNameAsKey] =
                              eachMapFromTempAlreadyAddedMap[
                                      eachStatNameAsKey] +
                                  statAsValue;
                        } else {
//IfKeyDoesn'tExist
                          eachMapFromTempAlreadyAddedMap
                              .addAll({eachStatNameAsKey: statAsValue});
                        }
                      });
//FirstWeAddToAlreadyAddedMap
                      tempAlreadyAddedMap[individualItemNameAsKey] =
                          eachMapFromTempAlreadyAddedMap;
                    } else {
//WeCanAddTheSecondaryMethodStraightAwayBecauseThisKeyDidn'tExistBefore
                      tempAlreadyAddedMap.addAll({
                        individualItemNameAsKey: secondaryMapWithStatsAsValue
                      });
                    }
                  });

                  finalNonBilledCaptainCancelledIndividualItemsStats[
                      cancellingCaptainPhoneNumberAsKey] = tempAlreadyAddedMap!;
                } else {
                  finalNonBilledCaptainCancelledIndividualItemsStats
                      .addAll({cancellingCaptainPhoneNumberAsKey: statAsValue});
                }
              } else {
//AllTheOtherCaptainCancellingStatsExceptIndividualItems
                if (finalNonBilledCaptainCancellationStats
                    .containsKey(cancellingCaptainPhoneNumberAsKey)) {
                  //ThisMeansWeHadAlreadyCalculatedCashierAmountStatsBefore
                  Map<String, dynamic>? tempAlreadyAddedMap =
                      finalNonBilledCaptainCancellationStats[
                          cancellingCaptainPhoneNumberAsKey];

                  if (tempAlreadyAddedMap!.containsKey(statNameAsKey)) {
                    tempAlreadyAddedMap[statNameAsKey] =
                        tempAlreadyAddedMap[statNameAsKey] + statAsValue;
                  } else {
                    tempAlreadyAddedMap.addAll({statNameAsKey: statAsValue});
                  }

                  finalNonBilledCaptainCancellationStats[
                      cancellingCaptainPhoneNumberAsKey] = tempAlreadyAddedMap!;
                } else {
                  finalNonBilledCaptainCancellationStats.addAll({
                    cancellingCaptainPhoneNumberAsKey: {
                      statNameAsKey: statAsValue
                    }
                  });
                }
              }
            });
          });
        }
      }
    }
//BilledChefRejectedStats
    if (calculationDaysNeeded.isNotEmpty) {
      for (var eachDay in calculationDaysNeeded) {
        if (billedRejectingChefDayStats.containsKey(eachDay)) {
          Map<String, dynamic> eachDayStat =
              billedRejectingChefDayStats[eachDay];
          eachDayStat.forEach(
              (rejectingChefPhoneNumberAsKey, rejectingChefStatsAsValue) {
            Map<String, dynamic> copyOfEntireMap = rejectingChefStatsAsValue;
            copyOfEntireMap.forEach((statNameAsKey, statAsValue) {
              if (statNameAsKey == 'IICR') {
//ThisIsForCancelledIndividualItems
                if (finalBilledChefRejectedIndividualItemsStats
                    .containsKey(rejectingChefPhoneNumberAsKey)) {
                  //ThisMeansWeHadAlreadyCalculatedCashierPaymentMethodStatsBefore
                  Map<String, dynamic>? tempAlreadyAddedMap =
                      finalBilledChefRejectedIndividualItemsStats[
                          rejectingChefPhoneNumberAsKey];
                  Map<String, dynamic> mapWithKeyAndMapPair = statAsValue;
                  mapWithKeyAndMapPair.forEach(
                      (individualItemNameAsKey, secondaryMapWithStatsAsValue) {
                    if (tempAlreadyAddedMap!
                        .containsKey(individualItemNameAsKey)) {
                      Map<String, dynamic> copyOfSecondaryMapOfStatsAsValue =
                          secondaryMapWithStatsAsValue;
                      Map<String, dynamic> eachMapFromTempAlreadyAddedMap =
                          tempAlreadyAddedMap[individualItemNameAsKey];
                      copyOfSecondaryMapOfStatsAsValue
                          .forEach((eachStatNameAsKey, statAsValue) {
                        if (eachMapFromTempAlreadyAddedMap
                            .containsKey(eachStatNameAsKey)) {
//IfKeyAlreadyExists
                          eachMapFromTempAlreadyAddedMap[eachStatNameAsKey] =
                              eachMapFromTempAlreadyAddedMap[
                                      eachStatNameAsKey] +
                                  statAsValue;
                        } else {
//IfKeyDoesn'tExist
                          eachMapFromTempAlreadyAddedMap
                              .addAll({eachStatNameAsKey: statAsValue});
                        }
                      });
//FirstWeAddToAlreadyAddedMap
                      tempAlreadyAddedMap[individualItemNameAsKey] =
                          eachMapFromTempAlreadyAddedMap;
                    } else {
//WeCanAddTheSecondaryMethodStraightAwayBecauseThisKeyDidn'tExistBefore
                      tempAlreadyAddedMap.addAll({
                        individualItemNameAsKey: secondaryMapWithStatsAsValue
                      });
                    }
                  });

                  finalBilledChefRejectedIndividualItemsStats[
                      rejectingChefPhoneNumberAsKey] = tempAlreadyAddedMap!;
                } else {
                  finalBilledChefRejectedIndividualItemsStats
                      .addAll({rejectingChefPhoneNumberAsKey: statAsValue});
                }
              } else {
//AllTheOtherCaptainCancellingStatsExceptIndividualItems
                if (finalBilledChefRejectionStats
                    .containsKey(rejectingChefPhoneNumberAsKey)) {
                  //ThisMeansWeHadAlreadyCalculatedCashierAmountStatsBefore
                  Map<String, dynamic>? tempAlreadyAddedMap =
                      finalBilledChefRejectionStats[
                          rejectingChefPhoneNumberAsKey];

                  if (tempAlreadyAddedMap!.containsKey(statNameAsKey)) {
                    tempAlreadyAddedMap[statNameAsKey] =
                        tempAlreadyAddedMap[statNameAsKey] + statAsValue;
                  } else {
                    tempAlreadyAddedMap.addAll({statNameAsKey: statAsValue});
                  }

                  finalBilledChefRejectionStats[rejectingChefPhoneNumberAsKey] =
                      tempAlreadyAddedMap!;
                } else {
                  finalBilledChefRejectionStats.addAll({
                    rejectingChefPhoneNumberAsKey: {statNameAsKey: statAsValue}
                  });
                }
              }
            });
          });
        }
      }
    }
    if (calculationMonthsNeeded.isNotEmpty) {
      for (var eachMonth in calculationMonthsNeeded) {
        if (billedRejectingChefMonthStats.containsKey(eachMonth)) {
          Map<String, dynamic> eachMonthStat =
              billedRejectingChefMonthStats[eachMonth];
          eachMonthStat.forEach(
              (rejectingChefPhoneNumberAsKey, rejectingChefStatsAsValue) {
            Map<String, dynamic> copyOfEntireMap = rejectingChefStatsAsValue;
            copyOfEntireMap.forEach((statNameAsKey, statAsValue) {
              if (statNameAsKey == 'IICR') {
//ThisIsForCancelledIndividualItems
                if (finalBilledChefRejectedIndividualItemsStats
                    .containsKey(rejectingChefPhoneNumberAsKey)) {
                  //ThisMeansWeHadAlreadyCalculatedCashierPaymentMethodStatsBefore
                  Map<String, dynamic>? tempAlreadyAddedMap =
                      finalBilledChefRejectedIndividualItemsStats[
                          rejectingChefPhoneNumberAsKey];
                  Map<String, dynamic> mapWithKeyAndMapPair = statAsValue;
                  mapWithKeyAndMapPair.forEach(
                      (individualItemNameAsKey, secondaryMapWithStatsAsValue) {
                    if (tempAlreadyAddedMap!
                        .containsKey(individualItemNameAsKey)) {
                      Map<String, dynamic> copyOfSecondaryMapOfStatsAsValue =
                          secondaryMapWithStatsAsValue;
                      Map<String, dynamic> eachMapFromTempAlreadyAddedMap =
                          tempAlreadyAddedMap[individualItemNameAsKey];
                      copyOfSecondaryMapOfStatsAsValue
                          .forEach((eachStatNameAsKey, statAsValue) {
                        if (eachMapFromTempAlreadyAddedMap
                            .containsKey(eachStatNameAsKey)) {
//IfKeyAlreadyExists
                          eachMapFromTempAlreadyAddedMap[eachStatNameAsKey] =
                              eachMapFromTempAlreadyAddedMap[
                                      eachStatNameAsKey] +
                                  statAsValue;
                        } else {
//IfKeyDoesn'tExist
                          eachMapFromTempAlreadyAddedMap
                              .addAll({eachStatNameAsKey: statAsValue});
                        }
                      });
//FirstWeAddToAlreadyAddedMap
                      tempAlreadyAddedMap[individualItemNameAsKey] =
                          eachMapFromTempAlreadyAddedMap;
                    } else {
//WeCanAddTheSecondaryMethodStraightAwayBecauseThisKeyDidn'tExistBefore
                      tempAlreadyAddedMap.addAll({
                        individualItemNameAsKey: secondaryMapWithStatsAsValue
                      });
                    }
                  });

                  finalBilledChefRejectedIndividualItemsStats[
                      rejectingChefPhoneNumberAsKey] = tempAlreadyAddedMap!;
                } else {
                  finalBilledChefRejectedIndividualItemsStats
                      .addAll({rejectingChefPhoneNumberAsKey: statAsValue});
                }
              } else {
//AllTheOtherChefRejectingStatsExceptIndividualItems
                if (finalBilledChefRejectionStats
                    .containsKey(rejectingChefPhoneNumberAsKey)) {
                  //ThisMeansWeHadAlreadyCalculatedCashierAmountStatsBefore
                  Map<String, dynamic>? tempAlreadyAddedMap =
                      finalBilledChefRejectionStats[
                          rejectingChefPhoneNumberAsKey];

                  if (tempAlreadyAddedMap!.containsKey(statNameAsKey)) {
                    tempAlreadyAddedMap[statNameAsKey] =
                        tempAlreadyAddedMap[statNameAsKey] + statAsValue;
                  } else {
                    tempAlreadyAddedMap.addAll({statNameAsKey: statAsValue});
                  }

                  finalBilledChefRejectionStats[rejectingChefPhoneNumberAsKey] =
                      tempAlreadyAddedMap!;
                } else {
                  finalBilledChefRejectionStats.addAll({
                    rejectingChefPhoneNumberAsKey: {statNameAsKey: statAsValue}
                  });
                }
              }
            });
          });
        }
      }
    }
//NonBilledChefRejectedStats
    if (calculationDaysNeeded.isNotEmpty) {
      for (var eachDay in calculationDaysNeeded) {
        if (nonBilledRejectingChefDayStats.containsKey(eachDay)) {
          Map<String, dynamic> eachDayStat =
              nonBilledRejectingChefDayStats[eachDay];
          eachDayStat.forEach(
              (rejectingChefPhoneNumberAsKey, rejectingChefStatsAsValue) {
            Map<String, dynamic> copyOfEntireMap = rejectingChefStatsAsValue;
            copyOfEntireMap.forEach((statNameAsKey, statAsValue) {
              if (statNameAsKey == 'IICR') {
//ThisIsForCancelledIndividualItems
                if (finalNonBilledChefRejectedIndividualItemsStats
                    .containsKey(rejectingChefPhoneNumberAsKey)) {
                  //ThisMeansWeHadAlreadyCalculatedCashierPaymentMethodStatsBefore
                  Map<String, dynamic>? tempAlreadyAddedMap =
                      finalNonBilledChefRejectedIndividualItemsStats[
                          rejectingChefPhoneNumberAsKey];
                  Map<String, dynamic> mapWithKeyAndMapPair = statAsValue;
                  mapWithKeyAndMapPair.forEach(
                      (individualItemNameAsKey, secondaryMapWithStatsAsValue) {
                    if (tempAlreadyAddedMap!
                        .containsKey(individualItemNameAsKey)) {
                      Map<String, dynamic> copyOfSecondaryMapOfStatsAsValue =
                          secondaryMapWithStatsAsValue;
                      Map<String, dynamic> eachMapFromTempAlreadyAddedMap =
                          tempAlreadyAddedMap[individualItemNameAsKey];
                      copyOfSecondaryMapOfStatsAsValue
                          .forEach((eachStatNameAsKey, statAsValue) {
                        if (eachMapFromTempAlreadyAddedMap
                            .containsKey(eachStatNameAsKey)) {
//IfKeyAlreadyExists
                          eachMapFromTempAlreadyAddedMap[eachStatNameAsKey] =
                              eachMapFromTempAlreadyAddedMap[
                                      eachStatNameAsKey] +
                                  statAsValue;
                        } else {
//IfKeyDoesn'tExist
                          eachMapFromTempAlreadyAddedMap
                              .addAll({eachStatNameAsKey: statAsValue});
                        }
                      });
//FirstWeAddToAlreadyAddedMap
                      tempAlreadyAddedMap[individualItemNameAsKey] =
                          eachMapFromTempAlreadyAddedMap;
                    } else {
//WeCanAddTheSecondaryMethodStraightAwayBecauseThisKeyDidn'tExistBefore
                      tempAlreadyAddedMap.addAll({
                        individualItemNameAsKey: secondaryMapWithStatsAsValue
                      });
                    }
                  });

                  finalNonBilledChefRejectedIndividualItemsStats[
                      rejectingChefPhoneNumberAsKey] = tempAlreadyAddedMap!;
                } else {
                  finalNonBilledChefRejectedIndividualItemsStats
                      .addAll({rejectingChefPhoneNumberAsKey: statAsValue});
                }
              } else {
//AllTheOtherCaptainCancellingStatsExceptIndividualItems
                if (finalNonBilledChefRejectionStats
                    .containsKey(rejectingChefPhoneNumberAsKey)) {
                  //ThisMeansWeHadAlreadyCalculatedCashierAmountStatsBefore
                  Map<String, dynamic>? tempAlreadyAddedMap =
                      finalNonBilledChefRejectionStats[
                          rejectingChefPhoneNumberAsKey];

                  if (tempAlreadyAddedMap!.containsKey(statNameAsKey)) {
                    tempAlreadyAddedMap[statNameAsKey] =
                        tempAlreadyAddedMap[statNameAsKey] + statAsValue;
                  } else {
                    tempAlreadyAddedMap.addAll({statNameAsKey: statAsValue});
                  }

                  finalNonBilledChefRejectionStats[
                      rejectingChefPhoneNumberAsKey] = tempAlreadyAddedMap!;
                } else {
                  finalNonBilledChefRejectionStats.addAll({
                    rejectingChefPhoneNumberAsKey: {statNameAsKey: statAsValue}
                  });
                }
              }
            });
          });
        }
      }
    }
    if (calculationMonthsNeeded.isNotEmpty) {
      for (var eachMonth in calculationMonthsNeeded) {
        if (nonBilledRejectingChefMonthStats.containsKey(eachMonth)) {
          Map<String, dynamic> eachMonthStat =
              nonBilledRejectingChefMonthStats[eachMonth];
          eachMonthStat.forEach(
              (rejectingChefPhoneNumberAsKey, rejectingChefStatsAsValue) {
            Map<String, dynamic> copyOfEntireMap = rejectingChefStatsAsValue;
            copyOfEntireMap.forEach((statNameAsKey, statAsValue) {
              if (statNameAsKey == 'IICR') {
//ThisIsForCancelledIndividualItems
                if (finalNonBilledChefRejectedIndividualItemsStats
                    .containsKey(rejectingChefPhoneNumberAsKey)) {
                  //ThisMeansWeHadAlreadyCalculatedCashierPaymentMethodStatsBefore
                  Map<String, dynamic>? tempAlreadyAddedMap =
                      finalNonBilledChefRejectedIndividualItemsStats[
                          rejectingChefPhoneNumberAsKey];
                  Map<String, dynamic> mapWithKeyAndMapPair = statAsValue;
                  mapWithKeyAndMapPair.forEach(
                      (individualItemNameAsKey, secondaryMapWithStatsAsValue) {
                    if (tempAlreadyAddedMap!
                        .containsKey(individualItemNameAsKey)) {
                      Map<String, dynamic> copyOfSecondaryMapOfStatsAsValue =
                          secondaryMapWithStatsAsValue;
                      Map<String, dynamic> eachMapFromTempAlreadyAddedMap =
                          tempAlreadyAddedMap[individualItemNameAsKey];
                      copyOfSecondaryMapOfStatsAsValue
                          .forEach((eachStatNameAsKey, statAsValue) {
                        if (eachMapFromTempAlreadyAddedMap
                            .containsKey(eachStatNameAsKey)) {
//IfKeyAlreadyExists
                          eachMapFromTempAlreadyAddedMap[eachStatNameAsKey] =
                              eachMapFromTempAlreadyAddedMap[
                                      eachStatNameAsKey] +
                                  statAsValue;
                        } else {
//IfKeyDoesn'tExist
                          eachMapFromTempAlreadyAddedMap
                              .addAll({eachStatNameAsKey: statAsValue});
                        }
                      });
//FirstWeAddToAlreadyAddedMap
                      tempAlreadyAddedMap[individualItemNameAsKey] =
                          eachMapFromTempAlreadyAddedMap;
                    } else {
//WeCanAddTheSecondaryMethodStraightAwayBecauseThisKeyDidn'tExistBefore
                      tempAlreadyAddedMap.addAll({
                        individualItemNameAsKey: secondaryMapWithStatsAsValue
                      });
                    }
                  });

                  finalNonBilledChefRejectedIndividualItemsStats[
                      rejectingChefPhoneNumberAsKey] = tempAlreadyAddedMap!;
                } else {
                  finalNonBilledChefRejectedIndividualItemsStats
                      .addAll({rejectingChefPhoneNumberAsKey: statAsValue});
                }
              } else {
//AllTheOtherChefRejectingStatsExceptIndividualItems
                if (finalNonBilledChefRejectionStats
                    .containsKey(rejectingChefPhoneNumberAsKey)) {
                  //ThisMeansWeHadAlreadyCalculatedCashierAmountStatsBefore
                  Map<String, dynamic>? tempAlreadyAddedMap =
                      finalNonBilledChefRejectionStats[
                          rejectingChefPhoneNumberAsKey];

                  if (tempAlreadyAddedMap!.containsKey(statNameAsKey)) {
                    tempAlreadyAddedMap[statNameAsKey] =
                        tempAlreadyAddedMap[statNameAsKey] + statAsValue;
                  } else {
                    tempAlreadyAddedMap.addAll({statNameAsKey: statAsValue});
                  }

                  finalNonBilledChefRejectionStats[
                      rejectingChefPhoneNumberAsKey] = tempAlreadyAddedMap!;
                } else {
                  finalNonBilledChefRejectionStats.addAll({
                    rejectingChefPhoneNumberAsKey: {statNameAsKey: statAsValue}
                  });
                }
              }
            });
          });
        }
      }
    }
//CaptainOrdersTakenStats
    if (calculationDaysNeeded.isNotEmpty) {
      for (var eachDay in calculationDaysNeeded) {
        if (eachCaptainOrdersTakenDayStats.containsKey(eachDay)) {
          Map<String, dynamic> eachDayStat =
              eachCaptainOrdersTakenDayStats[eachDay];
          eachDayStat.forEach(
              (captainPhoneNumberAsKey, captainOrdersTakingStatsAsValue) {
            Map<String, dynamic> copyOfEntireMap =
                captainOrdersTakingStatsAsValue;
            copyOfEntireMap.forEach((statNameAsKey, statAsValue) {
              if (statNameAsKey == 'ITS') {
//ThisIsForCancelledIndividualItems
                if (finalCaptainIndividualItemsOrdersTakenStats
                    .containsKey(captainPhoneNumberAsKey)) {
                  //ThisMeansWeHadAlreadyCalculatedCashierPaymentMethodStatsBefore
                  Map<String, dynamic>? tempAlreadyAddedMap =
                      finalCaptainIndividualItemsOrdersTakenStats[
                          captainPhoneNumberAsKey];
                  Map<String, dynamic> mapWithKeyAndMapPair = statAsValue;
                  mapWithKeyAndMapPair.forEach(
                      (individualItemNameAsKey, secondaryMapWithStatsAsValue) {
                    if (tempAlreadyAddedMap!
                        .containsKey(individualItemNameAsKey)) {
                      Map<String, dynamic> copyOfSecondaryMapOfStatsAsValue =
                          secondaryMapWithStatsAsValue;
                      Map<String, dynamic> eachMapFromTempAlreadyAddedMap =
                          tempAlreadyAddedMap[individualItemNameAsKey];
                      copyOfSecondaryMapOfStatsAsValue
                          .forEach((eachStatNameAsKey, statAsValue) {
                        if (eachMapFromTempAlreadyAddedMap
                            .containsKey(eachStatNameAsKey)) {
//IfKeyAlreadyExists
                          eachMapFromTempAlreadyAddedMap[eachStatNameAsKey] =
                              eachMapFromTempAlreadyAddedMap[
                                      eachStatNameAsKey] +
                                  statAsValue;
                        } else {
//IfKeyDoesn'tExist
                          eachMapFromTempAlreadyAddedMap
                              .addAll({eachStatNameAsKey: statAsValue});
                        }
                      });
//FirstWeAddToAlreadyAddedMap
                      tempAlreadyAddedMap[individualItemNameAsKey] =
                          eachMapFromTempAlreadyAddedMap;
                    } else {
//WeCanAddTheSecondaryMethodStraightAwayBecauseThisKeyDidn'tExistBefore
                      tempAlreadyAddedMap.addAll({
                        individualItemNameAsKey: secondaryMapWithStatsAsValue
                      });
                    }
                  });

                  finalCaptainIndividualItemsOrdersTakenStats[
                      captainPhoneNumberAsKey] = tempAlreadyAddedMap!;
                } else {
                  finalCaptainIndividualItemsOrdersTakenStats
                      .addAll({captainPhoneNumberAsKey: statAsValue});
                }
              } else if (statNameAsKey == 'TTS') {
//ThisIsForAllOtherStatsExceptIndividualItems
                if (finalCaptainOrdersTakenGeneralStats
                    .containsKey(captainPhoneNumberAsKey)) {
//ThisMeansWeHadAlreadyCalculatedThisCaptainGeneralStatsBefore
                  Map<String, dynamic>? tempAlreadyAddedMap =
                      finalCaptainOrdersTakenGeneralStats[
                          captainPhoneNumberAsKey];
                  Map<String, dynamic> mapWithKeyAndValuePair = statAsValue;
                  mapWithKeyAndValuePair.forEach(
                      (individualStatNameAsKey, individualStatAsValue) {
                    if (tempAlreadyAddedMap!
                        .containsKey(individualStatNameAsKey)) {
                      tempAlreadyAddedMap[individualStatNameAsKey] =
                          tempAlreadyAddedMap[individualStatNameAsKey] +
                              individualStatAsValue;
                    } else {
//WeCanAddTheSecondaryMethodStraightAwayBecauseThisKeyDidn'tExistBefore
                      tempAlreadyAddedMap.addAll(
                          {individualStatNameAsKey: individualStatAsValue});
                    }
                  });
                  finalCaptainOrdersTakenGeneralStats[captainPhoneNumberAsKey] =
                      tempAlreadyAddedMap!;
                } else {
                  finalCaptainOrdersTakenGeneralStats
                      .addAll({captainPhoneNumberAsKey: statAsValue});
                }
              }
            });
          });
        }
      }
    }
    if (calculationMonthsNeeded.isNotEmpty) {
      for (var eachMonth in calculationMonthsNeeded) {
        if (eachCaptainOrdersTakenMonthStats.containsKey(eachMonth)) {
          Map<String, dynamic> eachMonthStat =
              eachCaptainOrdersTakenMonthStats[eachMonth];
          eachMonthStat.forEach(
              (captainPhoneNumberAsKey, captainOrdersTakingStatsAsValue) {
            Map<String, dynamic> copyOfEntireMap =
                captainOrdersTakingStatsAsValue;
            copyOfEntireMap.forEach((statNameAsKey, statAsValue) {
              if (statNameAsKey == 'ITS') {
//ThisIsForCancelledIndividualItems
                if (finalCaptainIndividualItemsOrdersTakenStats
                    .containsKey(captainPhoneNumberAsKey)) {
                  //ThisMeansWeHadAlreadyCalculatedCashierPaymentMethodStatsBefore
                  Map<String, dynamic>? tempAlreadyAddedMap =
                      finalCaptainIndividualItemsOrdersTakenStats[
                          captainPhoneNumberAsKey];
                  Map<String, dynamic> mapWithKeyAndMapPair = statAsValue;
                  mapWithKeyAndMapPair.forEach(
                      (individualItemNameAsKey, secondaryMapWithStatsAsValue) {
                    if (tempAlreadyAddedMap!
                        .containsKey(individualItemNameAsKey)) {
                      Map<String, dynamic> copyOfSecondaryMapOfStatsAsValue =
                          secondaryMapWithStatsAsValue;
                      Map<String, dynamic> eachMapFromTempAlreadyAddedMap =
                          tempAlreadyAddedMap[individualItemNameAsKey];
                      copyOfSecondaryMapOfStatsAsValue
                          .forEach((eachStatNameAsKey, statAsValue) {
                        if (eachMapFromTempAlreadyAddedMap
                            .containsKey(eachStatNameAsKey)) {
//IfKeyAlreadyExists
                          eachMapFromTempAlreadyAddedMap[eachStatNameAsKey] =
                              eachMapFromTempAlreadyAddedMap[
                                      eachStatNameAsKey] +
                                  statAsValue;
                        } else {
//IfKeyDoesn'tExist
                          eachMapFromTempAlreadyAddedMap
                              .addAll({eachStatNameAsKey: statAsValue});
                        }
                      });
//FirstWeAddToAlreadyAddedMap
                      tempAlreadyAddedMap[individualItemNameAsKey] =
                          eachMapFromTempAlreadyAddedMap;
                    } else {
//WeCanAddTheSecondaryMethodStraightAwayBecauseThisKeyDidn'tExistBefore
                      tempAlreadyAddedMap.addAll({
                        individualItemNameAsKey: secondaryMapWithStatsAsValue
                      });
                    }
                  });

                  finalCaptainIndividualItemsOrdersTakenStats[
                      captainPhoneNumberAsKey] = tempAlreadyAddedMap!;
                } else {
                  finalCaptainIndividualItemsOrdersTakenStats
                      .addAll({captainPhoneNumberAsKey: statAsValue});
                }
              } else if (statNameAsKey == 'TTS') {
//ThisIsForAllOtherStatsExceptIndividualItems
                if (finalCaptainOrdersTakenGeneralStats
                    .containsKey(captainPhoneNumberAsKey)) {
//ThisMeansWeHadAlreadyCalculatedThisCaptainGeneralStatsBefore
                  Map<String, dynamic>? tempAlreadyAddedMap =
                      finalCaptainOrdersTakenGeneralStats[
                          captainPhoneNumberAsKey];
                  Map<String, dynamic> mapWithKeyAndValuePair = statAsValue;
                  mapWithKeyAndValuePair.forEach(
                      (individualStatNameAsKey, individualStatAsValue) {
                    if (tempAlreadyAddedMap!
                        .containsKey(individualStatNameAsKey)) {
                      tempAlreadyAddedMap[individualStatNameAsKey] =
                          tempAlreadyAddedMap[individualStatNameAsKey] +
                              individualStatAsValue;
                    } else {
//WeCanAddTheSecondaryMethodStraightAwayBecauseThisKeyDidn'tExistBefore
                      tempAlreadyAddedMap.addAll(
                          {individualStatNameAsKey: individualStatAsValue});
                    }
                  });
                  finalCaptainOrdersTakenGeneralStats[captainPhoneNumberAsKey] =
                      tempAlreadyAddedMap!;
                } else {
                  finalCaptainOrdersTakenGeneralStats
                      .addAll({captainPhoneNumberAsKey: statAsValue});
                }
              }
            });
          });
        }
      }
    }
//IndividualItemsSalesCalculation
    if (calculationDaysNeeded.isNotEmpty) {
      for (var eachDay in calculationDaysNeeded) {
        if (individualItemsDayStats.containsKey(eachDay)) {
          Map<String, dynamic> eachDayStat = individualItemsDayStats[eachDay];
          eachDayStat.forEach((itemNameAsKey, itemStatsAsValue) {
            if (finalSalesIndividualItemsStatsCalculated
                .containsKey(itemNameAsKey)) {
//ThisMeansWeHadAlreadyCalculatedThisItemBefore
              Map<String, dynamic> copyOfItemStatsAsValue = itemStatsAsValue;
              Map<String, dynamic>? tempAlreadyAddedMap =
                  finalSalesIndividualItemsStatsCalculated[itemNameAsKey];
              copyOfItemStatsAsValue!
                  .forEach((eachStatOfItemNameAsKey, valueOfThatStat) {
                if (tempAlreadyAddedMap!.containsKey(eachStatOfItemNameAsKey)) {
                  tempAlreadyAddedMap[eachStatOfItemNameAsKey] =
                      tempAlreadyAddedMap[eachStatOfItemNameAsKey] +
                          valueOfThatStat;
                } else {
                  tempAlreadyAddedMap
                      .addAll({eachStatOfItemNameAsKey: valueOfThatStat});
                }
              });
              finalSalesIndividualItemsStatsCalculated[itemNameAsKey] =
                  tempAlreadyAddedMap!;
            } else {
              finalSalesIndividualItemsStatsCalculated
                  .addAll({itemNameAsKey: itemStatsAsValue});
            }
          });
        }
      }
    }
    if (calculationMonthsNeeded.isNotEmpty) {
      for (var eachMonth in calculationMonthsNeeded) {
        if (individualItemsMonthStats.containsKey(eachMonth)) {
          Map<String, dynamic> eachMonthStat =
              individualItemsMonthStats[eachMonth];
          eachMonthStat.forEach((itemNameAsKey, itemStatsAsValue) {
            if (finalSalesIndividualItemsStatsCalculated
                .containsKey(itemNameAsKey)) {
//ThisMeansWeHadAlreadyCalculatedThisItemBefore
              Map<String, dynamic> copyOfItemStatsAsValue = itemStatsAsValue;
              Map<String, dynamic>? tempAlreadyAddedMap =
                  finalSalesIndividualItemsStatsCalculated[itemNameAsKey];
              copyOfItemStatsAsValue!
                  .forEach((eachStatOfItemNameAsKey, valueOfThatStat) {
                if (tempAlreadyAddedMap!.containsKey(eachStatOfItemNameAsKey)) {
                  tempAlreadyAddedMap[eachStatOfItemNameAsKey] =
                      tempAlreadyAddedMap[eachStatOfItemNameAsKey] +
                          valueOfThatStat;
                } else {
                  tempAlreadyAddedMap
                      .addAll({eachStatOfItemNameAsKey: valueOfThatStat});
                }
              });
              finalSalesIndividualItemsStatsCalculated[itemNameAsKey] =
                  tempAlreadyAddedMap!;
            } else {
              finalSalesIndividualItemsStatsCalculated
                  .addAll({itemNameAsKey: itemStatsAsValue});
            }
          });
        }
      }
    }
//ExtraIndividualItemsSalesStats
    if (calculationDaysNeeded.isNotEmpty) {
      for (var eachDay in calculationDaysNeeded) {
        if (extraIndividualItemsDayStats.containsKey(eachDay)) {
          Map<String, dynamic> eachDayStat =
              extraIndividualItemsDayStats[eachDay];
          eachDayStat.forEach((itemNameAsKey, itemStatsAsValue) {
            if (finalSalesExtraIndividualItemsStatsCalculated
                .containsKey(itemNameAsKey)) {
//ThisMeansWeHadAlreadyCalculatedThisItemBefore
              Map<String, dynamic> copyOfItemStatsAsValue = itemStatsAsValue;
              Map<String, dynamic>? tempAlreadyAddedMap =
                  finalSalesExtraIndividualItemsStatsCalculated[itemNameAsKey];
              copyOfItemStatsAsValue!
                  .forEach((eachStatOfItemNameAsKey, valueOfThatStat) {
                if (tempAlreadyAddedMap!.containsKey(eachStatOfItemNameAsKey)) {
                  tempAlreadyAddedMap[eachStatOfItemNameAsKey] =
                      tempAlreadyAddedMap[eachStatOfItemNameAsKey] +
                          valueOfThatStat;
                } else {
                  tempAlreadyAddedMap
                      .addAll({eachStatOfItemNameAsKey: valueOfThatStat});
                }
              });
              finalSalesExtraIndividualItemsStatsCalculated[itemNameAsKey] =
                  tempAlreadyAddedMap!;
            } else {
              finalSalesExtraIndividualItemsStatsCalculated
                  .addAll({itemNameAsKey: itemStatsAsValue});
            }
          });
        }
      }
    }
    if (calculationMonthsNeeded.isNotEmpty) {
      for (var eachMonth in calculationMonthsNeeded) {
        if (extraIndividualItemsMonthStats.containsKey(eachMonth)) {
          Map<String, dynamic> eachMonthStat =
              extraIndividualItemsMonthStats[eachMonth];
          eachMonthStat.forEach((itemNameAsKey, itemStatsAsValue) {
            if (finalSalesExtraIndividualItemsStatsCalculated
                .containsKey(itemNameAsKey)) {
//ThisMeansWeHadAlreadyCalculatedThisItemBefore
              Map<String, dynamic> copyOfItemStatsAsValue = itemStatsAsValue;
              Map<String, dynamic>? tempAlreadyAddedMap =
                  finalSalesExtraIndividualItemsStatsCalculated[itemNameAsKey];
              copyOfItemStatsAsValue!
                  .forEach((eachStatOfItemNameAsKey, valueOfThatStat) {
                if (tempAlreadyAddedMap!.containsKey(eachStatOfItemNameAsKey)) {
                  tempAlreadyAddedMap[eachStatOfItemNameAsKey] =
                      tempAlreadyAddedMap[eachStatOfItemNameAsKey] +
                          valueOfThatStat;
                } else {
                  tempAlreadyAddedMap
                      .addAll({eachStatOfItemNameAsKey: valueOfThatStat});
                }
              });
              finalSalesExtraIndividualItemsStatsCalculated[itemNameAsKey] =
                  tempAlreadyAddedMap!;
            } else {
              finalSalesExtraIndividualItemsStatsCalculated
                  .addAll({itemNameAsKey: itemStatsAsValue});
            }
          });
        }
      }
    }
//MakingCategoriesSeparately
    List<int> completeCalculationDaysAndMonthsNeeded =
        calculationDaysNeeded + calculationMonthsNeeded;
    List<String> itemsAddedTillNow = [];
//ThisMakesItInDescendingOrder
    completeCalculationDaysAndMonthsNeeded.sort((b, a) => a.compareTo(b));
    for (var eachTimeFrame in completeCalculationDaysAndMonthsNeeded) {
//AsPerDescendingOrder,WeWantPutItemInEachOfTheirCategories
//SoThatTheRecentDaysWillShowTheRightCategory
      if (categoryAndItemsDayStats.containsKey(eachTimeFrame)) {
        Map<String, dynamic> eachTimeFrameCategoryAndItems =
            categoryAndItemsDayStats[eachTimeFrame];
        eachTimeFrameCategoryAndItems
            .forEach((eachCategoryAsKey, itemsAndTimeOfAddingAsValue) {
          Map<String, dynamic> itemsAndTimeOfAdding =
              itemsAndTimeOfAddingAsValue;
          itemsAndTimeOfAdding.forEach((itemNameAskey, value) {
            if (!itemsAddedTillNow.contains(itemNameAskey)) {
              itemsAddedTillNow.add(itemNameAskey);
              if (finalEachCategoryWithItemsList
                  .containsKey(eachCategoryAsKey)) {
//WeTakeTheAlreadyAddedList
                List<String>? alreadyAddedItemsInCategory =
                    finalEachCategoryWithItemsList[eachCategoryAsKey];
//AddTheNewItem
                alreadyAddedItemsInCategory!.add(itemNameAskey);
//AndPutTheListAgain
                finalEachCategoryWithItemsList[eachCategoryAsKey] =
                    alreadyAddedItemsInCategory;
              } else {
//ThisMeansThisCategoryHasNotYetBeenRepresentedAndHenceCanBeAddedAlongWithTheItem
                finalEachCategoryWithItemsList.addAll({
                  eachCategoryAsKey: [itemNameAskey]
                });
              }
            }
          });
        });
      } else if (categoryAndItemsMonthStats.containsKey(eachTimeFrame)) {
        Map<String, dynamic> eachTimeFrameCategoryAndItems =
            categoryAndItemsMonthStats[eachTimeFrame];
        eachTimeFrameCategoryAndItems
            .forEach((eachCategoryAsKey, itemsAndTimeOfAddingAsValue) {
          Map<String, dynamic> itemsAndTimeOfAdding =
              itemsAndTimeOfAddingAsValue;
          itemsAndTimeOfAdding.forEach((itemNameAskey, value) {
            if (!itemsAddedTillNow.contains(itemNameAskey)) {
              itemsAddedTillNow.add(itemNameAskey);
              if (finalEachCategoryWithItemsList
                  .containsKey(eachCategoryAsKey)) {
//WeTakeTheAlreadyAddedList
                List<String>? alreadyAddedItemsInCategory =
                    finalEachCategoryWithItemsList[eachCategoryAsKey];
//AddTheNewItem
                alreadyAddedItemsInCategory!.add(itemNameAskey);
//AndPutTheListAgain
                finalEachCategoryWithItemsList[eachCategoryAsKey] =
                    alreadyAddedItemsInCategory;
              } else {
//ThisMeansThisCategoryHasNotYetBeenRepresentedAndHenceCanBeAddedAlongWithTheItem
                finalEachCategoryWithItemsList.addAll({
                  eachCategoryAsKey: [itemNameAskey]
                });
              }
            }
          });
        });
      }
    }
    finalEachCategoryWithItemsList
        .forEach((categoryTypeAsKey, listOfItemsInCategoryAsValue) {
      List<String> itemsInCategory = listOfItemsInCategoryAsValue;
      Map<String, dynamic> tempStatsMap = HashMap();
      for (var eachItemInCategory in itemsInCategory) {
        Map<String, dynamic> alreadyCalculatedItemsMap =
            finalSalesIndividualItemsStatsCalculated[eachItemInCategory]!;
        alreadyCalculatedItemsMap.forEach((eachStatAsKey, value) {
          if (tempStatsMap.containsKey(eachStatAsKey)) {
            tempStatsMap[eachStatAsKey] = tempStatsMap[eachStatAsKey] + value;
          } else {
//AddingEachStatsOfItems
            tempStatsMap.addAll({eachStatAsKey: value});
          }
        });
      }
      finalEachCategorySalesStats.addAll({categoryTypeAsKey: tempStatsMap});
    });

//EachExpenseStats
    if (calculationDaysNeeded.isNotEmpty) {
      for (var eachDay in calculationDaysNeeded) {
        if (eachExpenseDayStats.containsKey(eachDay)) {
          Map<String, dynamic> eachDayStat = eachExpenseDayStats[eachDay];
          eachDayStat.forEach((expenseTypeAsKey, expenseStatsAsValue) {
            totalExpenseDuringTheCalculationPeriod +=
                expenseStatsAsValue['TPC'];
            if (finalEachExpenseStatsCalculated.containsKey(expenseTypeAsKey)) {
//ThisMeansWeHadAlreadyCalculatedThisItemBefore
              Map<String, dynamic> copyOfExpenseStatsAsValue =
                  expenseStatsAsValue;
              Map<String, dynamic>? tempAlreadyAddedMap =
                  finalEachExpenseStatsCalculated[expenseTypeAsKey];
              copyOfExpenseStatsAsValue!
                  .forEach((eachStatOfExpenseAsKey, valueOfThatStat) {
                if (tempAlreadyAddedMap!.containsKey(eachStatOfExpenseAsKey)) {
                  tempAlreadyAddedMap[eachStatOfExpenseAsKey] =
                      tempAlreadyAddedMap[eachStatOfExpenseAsKey] +
                          valueOfThatStat;
                } else {
                  tempAlreadyAddedMap
                      .addAll({eachStatOfExpenseAsKey: valueOfThatStat});
                }
              });
              finalEachExpenseStatsCalculated[expenseTypeAsKey] =
                  tempAlreadyAddedMap!;
            } else {
              finalEachExpenseStatsCalculated
                  .addAll({expenseTypeAsKey: expenseStatsAsValue});
            }
          });
        }
      }
    }
    if (calculationMonthsNeeded.isNotEmpty) {
      for (var eachMonth in calculationMonthsNeeded) {
        if (eachExpenseMonthStats.containsKey(eachMonth)) {
          Map<String, dynamic> eachMonthStat = eachExpenseMonthStats[eachMonth];
          eachMonthStat.forEach((expenseTypeAsKey, expenseStatsAsValue) {
            totalExpenseDuringTheCalculationPeriod +=
                expenseStatsAsValue['TPC'];
            if (finalEachExpenseStatsCalculated.containsKey(expenseTypeAsKey)) {
//ThisMeansWeHadAlreadyCalculatedThisItemBefore
              Map<String, dynamic> copyOfExpenseStatsAsValue =
                  expenseStatsAsValue;
              Map<String, dynamic>? tempAlreadyAddedMap =
                  finalEachExpenseStatsCalculated[expenseTypeAsKey];
              copyOfExpenseStatsAsValue!
                  .forEach((eachStatOfExpenseAsKey, valueOfThatStat) {
                if (tempAlreadyAddedMap!.containsKey(eachStatOfExpenseAsKey)) {
                  tempAlreadyAddedMap[eachStatOfExpenseAsKey] =
                      tempAlreadyAddedMap[eachStatOfExpenseAsKey] +
                          valueOfThatStat;
                } else {
                  tempAlreadyAddedMap
                      .addAll({eachStatOfExpenseAsKey: valueOfThatStat});
                }
              });
              finalEachExpenseStatsCalculated[expenseTypeAsKey] =
                  tempAlreadyAddedMap!;
            } else {
              finalEachExpenseStatsCalculated
                  .addAll({expenseTypeAsKey: expenseStatsAsValue});
            }
          });
        }
      }
    }
//ExpensePaymentMethod
    if (calculationDaysNeeded.isNotEmpty) {
      for (var eachDay in calculationDaysNeeded) {
        if (expensePaymentMethodDayStats.containsKey(eachDay)) {
          Map<String, dynamic> eachDayStat =
              expensePaymentMethodDayStats[eachDay];
          eachDayStat.forEach((paymentNameAsKey, paymentStatsAsValue) {
            if (finalExpensePaymentMethodStatsCalculated
                .containsKey(paymentNameAsKey)) {
//ThisMeansWeHadAlreadyCalculatedThisItemBefore
              Map<String, dynamic> copyOfPaymentStatsAsValue =
                  paymentStatsAsValue;
              Map<String, dynamic>? tempAlreadyAddedMap =
                  finalExpensePaymentMethodStatsCalculated[paymentNameAsKey];
              copyOfPaymentStatsAsValue!
                  .forEach((eachStatOfPaymentMethodAsKey, valueOfThatStat) {
                if (tempAlreadyAddedMap!
                    .containsKey(eachStatOfPaymentMethodAsKey)) {
                  tempAlreadyAddedMap[eachStatOfPaymentMethodAsKey] =
                      tempAlreadyAddedMap[eachStatOfPaymentMethodAsKey] +
                          valueOfThatStat;
                } else {
                  tempAlreadyAddedMap
                      .addAll({eachStatOfPaymentMethodAsKey: valueOfThatStat});
                }
              });
              finalExpensePaymentMethodStatsCalculated[paymentNameAsKey] =
                  tempAlreadyAddedMap!;
            } else {
              finalExpensePaymentMethodStatsCalculated
                  .addAll({paymentNameAsKey: paymentStatsAsValue});
            }
          });
        }
      }
    }
    if (calculationMonthsNeeded.isNotEmpty) {
      for (var eachMonth in calculationMonthsNeeded) {
        if (expensePaymentMethodMonthStats.containsKey(eachMonth)) {
          Map<String, dynamic> eachMonthStat =
              expensePaymentMethodMonthStats[eachMonth];
          eachMonthStat.forEach((paymentNameAsKey, paymentStatsAsValue) {
            if (finalExpensePaymentMethodStatsCalculated
                .containsKey(paymentNameAsKey)) {
//ThisMeansWeHadAlreadyCalculatedThisItemBefore
              Map<String, dynamic> copyOfPaymentStatsAsValue =
                  paymentStatsAsValue;
              Map<String, dynamic>? tempAlreadyAddedMap =
                  finalExpensePaymentMethodStatsCalculated[paymentNameAsKey];
              copyOfPaymentStatsAsValue!
                  .forEach((eachStatOfPaymentMethodAsKey, valueOfThatStat) {
                if (tempAlreadyAddedMap!
                    .containsKey(eachStatOfPaymentMethodAsKey)) {
                  tempAlreadyAddedMap[eachStatOfPaymentMethodAsKey] =
                      tempAlreadyAddedMap[eachStatOfPaymentMethodAsKey] +
                          valueOfThatStat;
                } else {
                  tempAlreadyAddedMap
                      .addAll({eachStatOfPaymentMethodAsKey: valueOfThatStat});
                }
              });
              finalExpensePaymentMethodStatsCalculated[paymentNameAsKey] =
                  tempAlreadyAddedMap!;
            } else {
              finalExpensePaymentMethodStatsCalculated
                  .addAll({paymentNameAsKey: paymentStatsAsValue});
            }
          });
        }
      }
    }
//ExpensePaidByUserStats
    if (calculationDaysNeeded.isNotEmpty) {
      for (var eachDay in calculationDaysNeeded) {
        if (expensePaidByUserDayStats.containsKey(eachDay)) {
          Map<String, dynamic> eachDayStat = expensePaidByUserDayStats[eachDay];
          eachDayStat.forEach((userNameAsKey, userExpenseStatsAsValue) {
            Map<String, dynamic> copyOfEntireMap = userExpenseStatsAsValue;
            copyOfEntireMap.forEach((statNameAsKey, statAsValue) {
              if (statNameAsKey == 'paymentMethod') {
// ThisIfForPaidByUser'sPaymentMethod
                if (finalExpensePaidByUserPaymentMethodStatsCalculated
                    .containsKey(userNameAsKey)) {
//ThisMeansWeHadAlreadyCalculatedCashierPaymentMethodStatsBefore
                  Map<String, dynamic>? tempAlreadyAddedMap =
                      finalExpensePaidByUserPaymentMethodStatsCalculated[
                          userNameAsKey];
                  Map<String, dynamic> mapWithKeyAndMapPair = statAsValue;
                  mapWithKeyAndMapPair.forEach(
                      (paymentMethodNameAsKey, secondaryMapWithStatsAsValue) {
                    if (tempAlreadyAddedMap!
                        .containsKey(paymentMethodNameAsKey)) {
                      Map<String, dynamic> copyOfSecondaryMapOfStatsAsValue =
                          secondaryMapWithStatsAsValue;
                      Map<String, dynamic> eachMapFromTempAlreadyAddedMap =
                          tempAlreadyAddedMap[paymentMethodNameAsKey];
                      copyOfSecondaryMapOfStatsAsValue
                          .forEach((eachStatNameAsKey, statAsValue) {
                        if (eachMapFromTempAlreadyAddedMap
                            .containsKey(eachStatNameAsKey)) {
//IfKeyAlreadyExists
                          eachMapFromTempAlreadyAddedMap[eachStatNameAsKey] =
                              eachMapFromTempAlreadyAddedMap[
                                      eachStatNameAsKey] +
                                  statAsValue;
                        } else {
//IfKeyDoesn'tExist
                          eachMapFromTempAlreadyAddedMap
                              .addAll({eachStatNameAsKey: statAsValue});
                        }
                      });
//FirstWeAddToAlreadyAddedMap
                      tempAlreadyAddedMap[paymentMethodNameAsKey] =
                          eachMapFromTempAlreadyAddedMap;
                    } else {
//WeCanAddTheSecondaryMethodStraightAwayBecauseThisKeyDidn'tExistBefore
                      tempAlreadyAddedMap.addAll({
                        paymentMethodNameAsKey: secondaryMapWithStatsAsValue
                      });
                    }
                  });

                  finalExpensePaidByUserPaymentMethodStatsCalculated[
                      userNameAsKey] = tempAlreadyAddedMap!;
                } else {
                  finalExpensePaidByUserPaymentMethodStatsCalculated
                      .addAll({userNameAsKey: statAsValue});
                }
              } else {
                if (finalExpensePaidByUserGeneralStatsCalculated
                    .containsKey(userNameAsKey)) {
//ThisMeansWeHadAlreadyCalculatedThisItemBefore
                  Map<String, dynamic>? tempAlreadyAddedMap =
                      finalExpensePaidByUserGeneralStatsCalculated[
                          userNameAsKey];
                  if (tempAlreadyAddedMap!.containsKey(statNameAsKey)) {
                    tempAlreadyAddedMap[statNameAsKey] =
                        tempAlreadyAddedMap[statNameAsKey] + statAsValue;
                  } else {
                    tempAlreadyAddedMap.addAll({statNameAsKey: statAsValue});
                  }
                  finalExpensePaidByUserGeneralStatsCalculated[userNameAsKey] =
                      tempAlreadyAddedMap!;
                } else {
                  finalExpensePaidByUserGeneralStatsCalculated.addAll({
                    userNameAsKey: {statNameAsKey: statAsValue}
                  });
                }
              }
            });
          });
        }
      }
    }
    if (calculationMonthsNeeded.isNotEmpty) {
      for (var eachMonth in calculationMonthsNeeded) {
        if (expensePaidByUserMonthStats.containsKey(eachMonth)) {
          Map<String, dynamic> eachMonthStat =
              expensePaidByUserMonthStats[eachMonth];
          eachMonthStat.forEach((userNameAsKey, userExpenseStatsAsValue) {
            Map<String, dynamic> copyOfEntireMap = userExpenseStatsAsValue;
            copyOfEntireMap.forEach((statNameAsKey, statAsValue) {
              if (statNameAsKey == 'paymentMethod') {
// ThisIfForPaidByUser'sPaymentMethod
                if (finalExpensePaidByUserPaymentMethodStatsCalculated
                    .containsKey(userNameAsKey)) {
//ThisMeansWeHadAlreadyCalculatedCashierPaymentMethodStatsBefore
                  Map<String, dynamic>? tempAlreadyAddedMap =
                      finalExpensePaidByUserPaymentMethodStatsCalculated[
                          userNameAsKey];
                  Map<String, dynamic> mapWithKeyAndMapPair = statAsValue;
                  mapWithKeyAndMapPair.forEach(
                      (paymentMethodNameAsKey, secondaryMapWithStatsAsValue) {
                    if (tempAlreadyAddedMap!
                        .containsKey(paymentMethodNameAsKey)) {
                      Map<String, dynamic> copyOfSecondaryMapOfStatsAsValue =
                          secondaryMapWithStatsAsValue;
                      Map<String, dynamic> eachMapFromTempAlreadyAddedMap =
                          tempAlreadyAddedMap[paymentMethodNameAsKey];
                      copyOfSecondaryMapOfStatsAsValue
                          .forEach((eachStatNameAsKey, statAsValue) {
                        if (eachMapFromTempAlreadyAddedMap
                            .containsKey(eachStatNameAsKey)) {
//IfKeyAlreadyExists
                          eachMapFromTempAlreadyAddedMap[eachStatNameAsKey] =
                              eachMapFromTempAlreadyAddedMap[
                                      eachStatNameAsKey] +
                                  statAsValue;
                        } else {
//IfKeyDoesn'tExist
                          eachMapFromTempAlreadyAddedMap
                              .addAll({eachStatNameAsKey: statAsValue});
                        }
                      });
//FirstWeAddToAlreadyAddedMap
                      tempAlreadyAddedMap[paymentMethodNameAsKey] =
                          eachMapFromTempAlreadyAddedMap;
                    } else {
//WeCanAddTheSecondaryMethodStraightAwayBecauseThisKeyDidn'tExistBefore
                      tempAlreadyAddedMap.addAll({
                        paymentMethodNameAsKey: secondaryMapWithStatsAsValue
                      });
                    }
                  });

                  finalExpensePaidByUserPaymentMethodStatsCalculated[
                      userNameAsKey] = tempAlreadyAddedMap!;
                } else {
                  finalExpensePaidByUserPaymentMethodStatsCalculated
                      .addAll({userNameAsKey: statAsValue});
                }
              } else {
                if (finalExpensePaidByUserGeneralStatsCalculated
                    .containsKey(userNameAsKey)) {
//ThisMeansWeHadAlreadyCalculatedThisItemBefore
                  Map<String, dynamic>? tempAlreadyAddedMap =
                      finalExpensePaidByUserGeneralStatsCalculated[
                          userNameAsKey];
                  if (tempAlreadyAddedMap!.containsKey(statNameAsKey)) {
                    tempAlreadyAddedMap[statNameAsKey] =
                        tempAlreadyAddedMap[statNameAsKey] + statAsValue;
                  } else {
                    tempAlreadyAddedMap.addAll({statNameAsKey: statAsValue});
                  }
                  finalExpensePaidByUserGeneralStatsCalculated[userNameAsKey] =
                      tempAlreadyAddedMap!;
                } else {
                  finalExpensePaidByUserGeneralStatsCalculated.addAll({
                    userNameAsKey: {statNameAsKey: statAsValue}
                  });
                }
              }
            });
          });
        }
      }
    }

    if (finalGeneralStatsCalculated.isEmpty &&
        finalBilledCancelledIndividualItemsStatsCalculated.isEmpty &&
        finalNonBilledCancelledIndividualItemsStatsCalculated.isEmpty &&
        finalBilledCaptainCancelledIndividualItemsStats.isEmpty &&
        finalNonBilledCaptainCancelledIndividualItemsStats.isEmpty &&
        finalBilledCaptainCancellationStats.isEmpty &&
        finalNonBilledCaptainCancellationStats.isEmpty &&
        finalBilledChefRejectedIndividualItemsStats.isEmpty &&
        finalNonBilledChefRejectedIndividualItemsStats.isEmpty &&
        finalBilledChefRejectionStats.isEmpty &&
        finalNonBilledChefRejectionStats.isEmpty &&
        finalSalesIndividualItemsStatsCalculated.isEmpty &&
        finalSalesExtraIndividualItemsStatsCalculated.isEmpty &&
        finalEachCategoryWithItemsList.isEmpty &&
        finalEachCategorySalesStats.isEmpty &&
        finalSalesPaymentMethodStatsCalculated.isEmpty &&
        finalCashierClosingAmountStats.isEmpty &&
        finalCashierClosingPaymentMethodStats.isEmpty &&
        finalCaptainIndividualItemsOrdersTakenStats.isEmpty &&
        finalCaptainOrdersTakenGeneralStats.isEmpty &&
        finalEachExpenseStatsCalculated.isEmpty &&
        finalExpensePaymentMethodStatsCalculated.isEmpty &&
        finalExpensePaidByUserGeneralStatsCalculated.isEmpty &&
        finalExpensePaidByUserPaymentMethodStatsCalculated.isEmpty) {
//ThereIsNoStatsAvailableForTheDay
      noRecordsFound = true;
    }

    setState(() {
      showSpinner = false;
    });
  }

  void thisMonthStatisticsStreamToCheckInternet() {
    final thisMonthCollectionRef = FirebaseFirestore.instance
        .collection(
            Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                .chosenRestaurantDatabaseFromClass)
        .doc('reports')
        .collection('monthlyCashBalanceReports')
        .where('midMonthMilliSecond',
            isEqualTo: DateTime(DateTime.now().year, DateTime.now().month, 15)
                .millisecondsSinceEpoch);
    _streamSubscriptionForThisMonth = thisMonthCollectionRef
        .snapshots()
        .listen((thisMonthStatisticsSnapshot) {
//ThisStreamIsSimplyToCheckWhetherInternetIsWorkingOrNot
//IfStreamSubscriptionIsNull,ItMeansThatThereIsNoInternet
//OnceDataIsUploadedWeCanCancelTheStream
    });
  }

//   void cashBalanceCheckOfPreviousMonth(
//       DateTime dateTimeToCheckBalance,
//       int localRandomNumberForThisButtonPress,
//       bool startDataFalseEndDateTrue) {
// //ThisIsToCheckWhetherLastMonthDataExists
//     DateTime approximateMillisecondOfTheMonthBeforeTheRequiredMonth =
//         dateTimeToCheckBalance.day > 15
//             ? dateTimeToCheckBalance.subtract(Duration(days: 35))
//             : dateTimeToCheckBalance.subtract(Duration(days: 20));
//     int midMonthMillisecondsOfMonthBeforeTheRequiredMonth = DateTime(
//             approximateMillisecondOfTheMonthBeforeTheRequiredMonth.year,
//             approximateMillisecondOfTheMonthBeforeTheRequiredMonth.month,
//             15)
//         .millisecondsSinceEpoch;
//      if (savedStatisticsCashBalanceData
//           .containsKey(midMonthMillisecondsOfMonthBeforeTheRequiredMonth)) {
// //WeCheckWhetherWeHaveLastMonthData.IfThatIsThere.WeCanSeeTheHighestDate
// //AndThatCouldHelpCalculateTheRequiredCashBalance
//       } else {
// //NowThatBothAreNotAvailableWeWillTryDownloadingInOneGoAllTheData
// //OfOneYearBeforeTheRequiredDate
//       }
//
//   }

  void cashBalanceWithPreviousYearDataCheck(
      DateTime dateTimeToCheckBalance,
      int localRandomNumberForThisButtonPress,
      bool startDataFalseEndDateTrue) async {
    bool gotSomeData = false;
    bool calledNextFunction = false;
    List<int> eachMidMonthMillisecondList = [];
    Timer(Duration(seconds: 5), () {
      if (gotSomeData == false) {
        calledNextFunction = true;
        if (_streamSubscriptionForThisMonth == null) {
          setState(() {
            showSpinner = false;
          });
          randomNumberForEachViewButtonPress = 0;
          calledNextFunction = true;
          _streamSubscriptionForThisMonth?.cancel();
          show('Please Check Internet and Try Again');
        }
      }
    });
    num milliSecondsYearPreviousToPickedDate = DateTime(
            dateTimeToCheckBalance.year,
            dateTimeToCheckBalance.month,
            dateTimeToCheckBalance.day)
        .subtract(Duration(days: 365))
        .millisecondsSinceEpoch;

    final pastYearToNowCollectionRef = FirebaseFirestore.instance
        .collection(widget.hotelName)
        .doc('reports')
        .collection('monthlyCashBalanceReports')
        .where('midMonthMilliSecond',
            isGreaterThan: milliSecondsYearPreviousToPickedDate)
        .where('midMonthMilliSecond',
            isLessThanOrEqualTo: DateTime(dateTimeToCheckBalance.year,
                    dateTimeToCheckBalance.month, 15)
                .millisecondsSinceEpoch);
//WantInAscendingOrderSoThatWeCanCheckPreviousDayBalanceWhileIterating
    final pastYearToNowStatisticsSnapshot =
        await pastYearToNowCollectionRef.get();
    if (pastYearToNowStatisticsSnapshot.docs.length >= 1) {
      gotSomeData = true;
      int monthsCheckCounter = 0;
      for (var eachMonthDocument in pastYearToNowStatisticsSnapshot.docs) {
        monthsCheckCounter++;
        eachMidMonthMillisecondList
            .add(eachMonthDocument['midMonthMilliSecond']);
        savedStatisticsCashBalanceData.addAll({
          eachMonthDocument['midMonthMilliSecond']:
              eachMonthDocument['cashBalanceData']
        });

        if (monthsCheckCounter == pastYearToNowStatisticsSnapshot.docs.length &&
            localRandomNumberForThisButtonPress ==
                randomNumberForEachViewButtonPress &&
            calledNextFunction == false) {
          int maxMidMonthMilliSecond = eachMidMonthMillisecondList.reduce(max);
          if (maxMidMonthMilliSecond ==
              DateTime(dateTimeToCheckBalance.year,
                      dateTimeToCheckBalance.month, 15)
                  .millisecondsSinceEpoch) {
//ThisMeansWeSomehowNowHaveThatMonthData
            cashBalanceIfWeHaveDataOfTheSameMonthAsQueriedDate(
                dateTimeToCheckBalance,
                localRandomNumberForThisButtonPress,
                startDataFalseEndDateTrue,
                savedStatisticsCashBalanceData[maxMidMonthMilliSecond]!);
          } else {
//ThisMeansTheDataBelongsToSomePreviousMonth
            cashBalanceIfWeHaveDataOfTheLastPreviousMonthAsQueriedDate(
                dateTimeToCheckBalance,
                localRandomNumberForThisButtonPress,
                startDataFalseEndDateTrue,
                savedStatisticsCashBalanceData[maxMidMonthMilliSecond]!);
          }
        }
      }
    } else {
      if (_streamSubscriptionForThisMonth != null &&
          localRandomNumberForThisButtonPress ==
              randomNumberForEachViewButtonPress &&
          calledNextFunction == false) {
//ThisMeansNoDocumentsAreThereInThePastOneYear.MostProbablyNewRestaurant
//WeWillPutNewDataHere.SinceStreamSubscriptionIsNotNullWeCanConfirm
// ThatTheLackOfDataIsn'tBecauseOfInternet

        if (startDataFalseEndDateTrue) {
//thisMeansWeHaveCalculatedTheEndDate
          _streamSubscriptionForThisMonth?.cancel();
          randomNumberForEachViewButtonPress = 0;
          endingCashBalance = 0;
          statisticsReportsQueryGenerationVersion3();
        } else {
//thisMeansWeHaveOnlyCalculatedTheStartDate

          if (dateRange.start.isAtSameMomentAs(dateRange.end)) {
            _streamSubscriptionForThisMonth?.cancel();
            randomNumberForEachViewButtonPress = 0;
            startingCashBalance = endingCashBalance = 0;
            statisticsReportsQueryGenerationVersion3();
          } else {
            startingCashBalance = 0;
            startPointOfCashBalanceChecking(
                dateRange.end, localRandomNumberForThisButtonPress, true);
          }
        }

        calledNextFunction = true;
      }
    }
  }

//TheseTwoFunctionWillCheckWhetherThereIsAnyNumberLessThanOrBiggerThanTheTargetNumber
  bool hasSmallerNumber(List<int> list, int target) {
    return list.any((number) => number < target);
  }

  bool hasLargerNumber(List<int> list, int target) {
    return list.any((number) => number > target);
  }

  void cashBalanceIfWeHaveDataOfTheSameMonthAsQueriedDate(
      DateTime dateTimeToCheckBalance,
      int localRandomNumberForThisButtonPress,
      bool startDataFalseEndDateTrue,
      Map<String, dynamic> monthCashBalanceReport) {
    List<int> datesDataAvailableInThatMonth =
        monthCashBalanceReport.keys.toList().map(int.parse).toList();
    datesDataAvailableInThatMonth.sort();
    if (datesDataAvailableInThatMonth.contains(dateTimeToCheckBalance.day)) {
      String dayInString = dateTimeToCheckBalance.day.toString().length > 1
          ? dateTimeToCheckBalance.day.toString()
          : '0${dateTimeToCheckBalance.day.toString()}';
      if (!startDataFalseEndDateTrue) {
        startingCashBalance =
            monthCashBalanceReport[dayInString]['previousCashBalance'];
        if (dateRange.start.isAtSameMomentAs(dateRange.end)) {
//ThisMeansTheyAreCheckingOneDayData
          endingCashBalance = monthCashBalanceReport[dayInString]
                  ['previousCashBalance'] +
              monthCashBalanceReport[dayInString]['dayIncrements'];
          _streamSubscriptionForThisMonth?.cancel();
          statisticsReportsQueryGenerationVersion3();
        } else {
          startPointOfCashBalanceChecking(
              dateRange.end, localRandomNumberForThisButtonPress, true);
        }
      } else {
//ThisMeansTheyAreCheckingTheEndDate
        endingCashBalance = monthCashBalanceReport[dayInString]
                ['previousCashBalance'] +
            monthCashBalanceReport[dayInString]['dayIncrements'];
        _streamSubscriptionForThisMonth?.cancel();
        statisticsReportsQueryGenerationVersion3();
      }
    } else {
//ThisMeansThatPresentDateDoesn'tExist
      if (hasSmallerNumber(
          datesDataAvailableInThatMonth, dateTimeToCheckBalance.day)) {
//ThisMeansSomeDatesLesserThanTheDateIsAvailableWithWhichWeCanGetTheBalance
        int firstSmallerNumber = datesDataAvailableInThatMonth
            .lastWhere((number) => number < dateTimeToCheckBalance.day);
        String dayInString = firstSmallerNumber.toString().length > 1
            ? firstSmallerNumber.toString()
            : '0${firstSmallerNumber.toString()}';
        print('dayInString');
        print(dayInString);

        if (!startDataFalseEndDateTrue &&
            dateRange.start.isAtSameMomentAs(dateRange.end)) {
//ThisWillCheckWhetherStartAndEndAreSameDate
          startingCashBalance = endingCashBalance =
              monthCashBalanceReport[dayInString]['previousCashBalance'] +
                  monthCashBalanceReport[dayInString]['dayIncrements'];
          _streamSubscriptionForThisMonth?.cancel();
          statisticsReportsQueryGenerationVersion3();
        } else if (!startDataFalseEndDateTrue) {
          startingCashBalance = monthCashBalanceReport[dayInString]
                  ['previousCashBalance'] +
              monthCashBalanceReport[dayInString]['dayIncrements'];
          startPointOfCashBalanceChecking(
              dateRange.end, localRandomNumberForThisButtonPress, true);
//WeAreCallingSayingThatWeAreLookingForTheDataOfEndDate
        } else {
//ThisMeansThisIsForTheEndDate
          endingCashBalance = monthCashBalanceReport[dayInString]
                  ['previousCashBalance'] +
              monthCashBalanceReport[dayInString]['dayIncrements'];
          _streamSubscriptionForThisMonth?.cancel();
          statisticsReportsQueryGenerationVersion3();
        }
      } else {
        int firstBiggerNumber = datesDataAvailableInThatMonth
            .firstWhere((number) => number > dateTimeToCheckBalance.day);
        String dayInString = firstBiggerNumber.toString().length > 1
            ? firstBiggerNumber.toString()
            : '0${firstBiggerNumber.toString()}';

        if (!startDataFalseEndDateTrue &&
            dateRange.start.isAtSameMomentAs(dateRange.end)) {
//ThisWillCheckWhetherStartAndEndAreSameDate
          startingCashBalance = endingCashBalance =
              monthCashBalanceReport[dayInString]['previousCashBalance'];
          _streamSubscriptionForThisMonth?.cancel();
          statisticsReportsQueryGenerationVersion3();
        } else if (!startDataFalseEndDateTrue) {
          startingCashBalance =
              monthCashBalanceReport[dayInString]['previousCashBalance'];
          startPointOfCashBalanceChecking(
              dateRange.end, localRandomNumberForThisButtonPress, true);
        } else {
//ThisMeansThisIsForTheEndDate
          endingCashBalance =
              monthCashBalanceReport[dayInString]['previousCashBalance'];
          _streamSubscriptionForThisMonth?.cancel();
          statisticsReportsQueryGenerationVersion3();
        }
      }
    }
  }

  void cashBalanceIfWeHaveDataOfTheLastPreviousMonthAsQueriedDate(
      DateTime dateTimeToCheckBalance,
      int localRandomNumberForThisButtonPress,
      bool startDataFalseEndDateTrue,
      Map<String, dynamic> monthCashBalanceReport) {
    List<int> datesDataAvailableInThatMonth =
        monthCashBalanceReport.keys.toList().map(int.parse).toList();
    datesDataAvailableInThatMonth.sort();
    int maxDate = datesDataAvailableInThatMonth.reduce(max);
    String dayInString = maxDate.toString().length > 1
        ? maxDate.toString()
        : '0${maxDate.toString()}';

//WeUseMaxDateOfPreviousMonthToCheckCashBalanceOfThatDay

    if (!startDataFalseEndDateTrue &&
        dateRange.start.isAtSameMomentAs(dateRange.end)) {
//ThisWillCheckWhetherStartAndEndAreSameDate
      startingCashBalance = endingCashBalance =
          monthCashBalanceReport[dayInString]['previousCashBalance'] +
              monthCashBalanceReport[dayInString]['dayIncrements'];
      _streamSubscriptionForThisMonth?.cancel();
      statisticsReportsQueryGenerationVersion3();
    } else if (!startDataFalseEndDateTrue) {
//ThisMeansThisIsForStartDate
      startingCashBalance = monthCashBalanceReport[dayInString]
              ['previousCashBalance'] +
          monthCashBalanceReport[dayInString]['dayIncrements'];
      startPointOfCashBalanceChecking(
          dateRange.end, localRandomNumberForThisButtonPress, true);
    } else {
//ThisMeansThisIsForTheEndDate
      endingCashBalance = monthCashBalanceReport[dayInString]
              ['previousCashBalance'] +
          monthCashBalanceReport[dayInString]['dayIncrements'];
      _streamSubscriptionForThisMonth?.cancel();
      statisticsReportsQueryGenerationVersion3();
    }
  }

//ThisIsThePointAtWhichAnyCashBalanceCheckingStarts
  Future<void> startPointOfCashBalanceChecking(
      DateTime dateTimeToCheckBalance,
      int localRandomNumberForThisButtonPress,
      bool startDataFalseEndDateTrue) async {
    bool gotSomeData = false;
    bool calledNextFunction = false;
//ThisMeansWeNeedStartDayData
    if ((savedStatisticsCashBalanceData.containsKey(DateTime(
                dateTimeToCheckBalance.year, dateTimeToCheckBalance.month, 15)
            .millisecondsSinceEpoch)) &&
        localRandomNumberForThisButtonPress ==
            randomNumberForEachViewButtonPress) {
      cashBalanceIfWeHaveDataOfTheSameMonthAsQueriedDate(
          dateTimeToCheckBalance,
          localRandomNumberForThisButtonPress,
          startDataFalseEndDateTrue,
          savedStatisticsCashBalanceData[DateTime(
                  dateTimeToCheckBalance.year, dateTimeToCheckBalance.month, 15)
              .millisecondsSinceEpoch]!);
    } else {
//ThisMeansMonthDataIsn'tAvailableAndWeNeedToDownload
      if (!startDataFalseEndDateTrue) {
//WeStartThisOnlyIfItIsStartDate.IfItIsEndDate,ItWouldAlreadyHaveBeenStarted
        thisMonthStatisticsStreamToCheckInternet();
      }

      Timer(Duration(seconds: 3), () {
        if (gotSomeData == false) {
          calledNextFunction = true;
          cashBalanceWithPreviousYearDataCheck(dateTimeToCheckBalance,
              localRandomNumberForThisButtonPress, startDataFalseEndDateTrue);
        }
      });
      final queriedMonthCollectionRef = FirebaseFirestore.instance
          .collection(Provider.of<PrinterAndOtherDetailsProvider>(context,
                  listen: false)
              .chosenRestaurantDatabaseFromClass)
          .doc('reports')
          .collection('monthlyCashBalanceReports')
          .where('midMonthMilliSecond',
              isEqualTo: DateTime(dateTimeToCheckBalance.year,
                      dateTimeToCheckBalance.month, 15)
                  .millisecondsSinceEpoch);
      final queriedMonthStatisticsSnapshot =
          await queriedMonthCollectionRef.get();
      if (queriedMonthStatisticsSnapshot.docs.length >= 1) {
        print('entered Inside month');
        gotSomeData = true;
        for (var neededMonthDocument in queriedMonthStatisticsSnapshot.docs) {
          savedStatisticsCashBalanceData.addAll({
            DateTime(dateTimeToCheckBalance.year, dateTimeToCheckBalance.month,
                    15)
                .millisecondsSinceEpoch: neededMonthDocument['cashBalanceData']
          });
//OnceWeGetData,WeCallFunctionToGetCashBalance
          if (localRandomNumberForThisButtonPress ==
                  randomNumberForEachViewButtonPress &&
              calledNextFunction == false) {
            calledNextFunction = true;
            cashBalanceIfWeHaveDataOfTheSameMonthAsQueriedDate(
                dateTimeToCheckBalance,
                localRandomNumberForThisButtonPress,
                startDataFalseEndDateTrue,
                savedStatisticsCashBalanceData[DateTime(
                        dateTimeToCheckBalance.year,
                        dateTimeToCheckBalance.month,
                        15)
                    .millisecondsSinceEpoch]!);
          }
        }
      } else {
//ThisMeansThereAreNoDocumentsThisMonthAndWeMightNeedWholeYear
        calledNextFunction = true;
        cashBalanceWithPreviousYearDataCheck(dateTimeToCheckBalance,
            localRandomNumberForThisButtonPress, startDataFalseEndDateTrue);
      }
    }
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
          title: Text('Reports', style: kAppBarTextStyle),
          centerTitle: true,
        ),
        body: ModalProgressHUD(
          inAsyncCall: showSpinner,
          child: SingleChildScrollView(
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
                  tileColor: Colors.white54,
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
                      onPressed: () async {
                        // statisticsReportsQueryGenerationVersion3();
                        randomNumberForEachViewButtonPress =
                            (1000000 + Random().nextInt(9999999 - 1000000));
                        startPointOfCashBalanceChecking(
                            start, randomNumberForEachViewButtonPress, false);
//ByFalse,WeAreSayingThatThisIsTheStartDate

                        setState(() {
                          showSpinner = true;
                        });
                      },
                      child: Text('View', style: TextStyle(fontSize: 15))),
                  // subtitle: Text('Click Button to Choose Date Range',
                  //     style: TextStyle(color: Colors.green)),
                ),
//TableOfTotalExpenseOfEachUser
                Divider(thickness: 5),
                (showSpinner == false && firstCalculationStarted)
                    ? DataTable(columns: [
                        DataColumn(
                            label:
                                Text('Profit', style: TextStyle(fontSize: 20))),
                        DataColumn(
                            label: Text(
                                (totalSalesIncomeDuringTheCalculationPeriod -
                                        totalExpenseDuringTheCalculationPeriod)
                                    .toString(),
                                style: TextStyle(fontSize: 20)))
                      ], rows: <DataRow>[
                        DataRow(cells: <DataCell>[
                          DataCell(
                              Text('Sales', style: TextStyle(fontSize: 18))),
                          DataCell(Text(
                              totalSalesIncomeDuringTheCalculationPeriod
                                  .toString(),
                              style: TextStyle(fontSize: 18)))
                        ]),
                        DataRow(cells: <DataCell>[
                          DataCell(
                              Text('Expense', style: TextStyle(fontSize: 18))),
                          DataCell(Text(
                              totalExpenseDuringTheCalculationPeriod.toString(),
                              style: TextStyle(fontSize: 18)))
                        ]),
                        DataRow(cells: <DataCell>[
                          DataCell(Text('Starting Cash Balance',
                              style: TextStyle(fontSize: 18))),
                          DataCell(Text(startingCashBalance.toString(),
                              style: TextStyle(fontSize: 18)))
                        ]),
                        DataRow(cells: <DataCell>[
                          DataCell(Text('Ending Cash Balance',
                              style: TextStyle(fontSize: 18))),
                          DataCell(Text(endingCashBalance.toString(),
                              style: TextStyle(fontSize: 18)))
                        ]),
                      ])
                    : SizedBox.shrink(),
                (showSpinner == false && firstCalculationStarted)
                    ? Divider(thickness: 3)
                    : SizedBox.shrink(),
                (!showSpinner && noRecordsFound)
                    ? Center(
                        child: Text('No Records Found',
                            style: TextStyle(fontSize: 20)))
                    : SizedBox.shrink(),
                (finalGeneralStatsCalculated.isNotEmpty && showSpinner == false)
                    ? ListTile(
                        title: Text('General Sales Stats'),
                        trailing: Icon(Icons.keyboard_arrow_right),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (BuildContext) => ReportsDisplayPage(
                                        mapOne: finalGeneralStatsCalculated,
                                        mapTwo: {},
                                        mapThree: {},
                                        mapFour: {},
                                        reportsName: 'GeneralStats',
                                      )));
                        },
                      )
                    : SizedBox.shrink(),
                (finalGeneralStatsCalculated.isNotEmpty && showSpinner == false)
                    ? Divider(thickness: 2)
                    : SizedBox.shrink(),
                (finalSalesPaymentMethodStatsCalculated.isNotEmpty &&
                        showSpinner == false)
                    ? ListTile(
                        title: Text('Sales Payment Method Stats'),
                        trailing: Icon(Icons.keyboard_arrow_right),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (BuildContext) => ReportsDisplayPage(
                                        mapOne:
                                            finalSalesPaymentMethodStatsCalculated,
                                        mapTwo: {},
                                        mapThree: {},
                                        mapFour: {},
                                        reportsName: 'SalesPaymentStats',
                                      )));
                        },
                      )
                    : SizedBox.shrink(),
                (finalSalesPaymentMethodStatsCalculated.isNotEmpty &&
                        showSpinner == false)
                    ? Divider(thickness: 2)
                    : SizedBox.shrink(),
                (finalCashierClosingAmountStats.isNotEmpty &&
                        showSpinner == false)
                    ? ListTile(
                        title: Text('Cashier Stats'),
                        trailing: Icon(Icons.keyboard_arrow_right),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (BuildContext) => ReportsDisplayPage(
                                        mapOne: finalCashierClosingAmountStats,
                                        mapTwo:
                                            finalCashierClosingPaymentMethodStats,
                                        mapThree: {},
                                        mapFour: {},
                                        reportsName: 'SalesCashierStats',
                                      )));
                        },
                      )
                    : SizedBox.shrink(),
                (finalCashierClosingAmountStats.isNotEmpty &&
                        showSpinner == false)
                    ? Divider(thickness: 2)
                    : SizedBox.shrink(),
                (finalEachCategorySalesStats.isNotEmpty && showSpinner == false)
                    ? ListTile(
                        title: Text('Category and Items Sales Stats'),
                        trailing: Icon(Icons.keyboard_arrow_right),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (BuildContext) => ReportsDisplayPage(
                                        mapOne: finalEachCategorySalesStats,
                                        mapTwo: finalEachCategoryWithItemsList,
                                        mapThree:
                                            finalSalesIndividualItemsStatsCalculated,
                                        mapFour: {},
                                        reportsName:
                                            'CategoryAndItemsSalesStats',
                                      )));
                        },
                      )
                    : SizedBox.shrink(),
                (finalEachCategorySalesStats.isNotEmpty && showSpinner == false)
                    ? Divider(thickness: 2)
                    : SizedBox.shrink(),
                (finalSalesExtraIndividualItemsStatsCalculated.isNotEmpty &&
                        showSpinner == false)
                    ? ListTile(
                        title: Text('Extra Items Sales Stats'),
                        trailing: Icon(Icons.keyboard_arrow_right),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (BuildContext) => ReportsDisplayPage(
                                        mapOne:
                                            finalSalesExtraIndividualItemsStatsCalculated,
                                        mapTwo: {},
                                        mapThree: {},
                                        mapFour: {},
                                        reportsName: 'ExtraItemsSalesStats',
                                      )));
                        },
                      )
                    : SizedBox.shrink(),
                (finalSalesExtraIndividualItemsStatsCalculated.isNotEmpty &&
                        showSpinner == false)
                    ? Divider(thickness: 2)
                    : SizedBox.shrink(),
                (finalCaptainOrdersTakenGeneralStats.isNotEmpty &&
                        showSpinner == false)
                    ? ListTile(
                        title: Text('Captain Stats'),
                        trailing: Icon(Icons.keyboard_arrow_right),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (BuildContext) => ReportsDisplayPage(
                                        mapOne:
                                            finalCaptainOrdersTakenGeneralStats,
                                        mapTwo:
                                            finalCaptainIndividualItemsOrdersTakenStats,
                                        mapThree: {},
                                        mapFour: {},
                                        reportsName: 'CaptainOrdersTakenStats',
                                      )));
                        },
                      )
                    : SizedBox.shrink(),
                (finalCaptainOrdersTakenGeneralStats.isNotEmpty &&
                        showSpinner == false)
                    ? Divider(thickness: 2)
                    : SizedBox.shrink(),
                (finalEachExpenseStatsCalculated.isNotEmpty &&
                        showSpinner == false)
                    ? ListTile(
                        title: Text('Expenses Stats'),
                        trailing: Icon(Icons.keyboard_arrow_right),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (BuildContext) => ReportsDisplayPage(
                                        mapOne: finalEachExpenseStatsCalculated,
                                        mapTwo: {},
                                        mapThree: {},
                                        mapFour: {},
                                        reportsName: 'ExpenseCategoryStats',
                                      )));
                        },
                      )
                    : SizedBox.shrink(),
                (finalEachExpenseStatsCalculated.isNotEmpty &&
                        showSpinner == false)
                    ? Divider(thickness: 2)
                    : SizedBox.shrink(),
                (finalExpensePaidByUserGeneralStatsCalculated.isNotEmpty &&
                        showSpinner == false)
                    ? ListTile(
                        title: Text('Expenses Paid By User Stats'),
                        trailing: Icon(Icons.keyboard_arrow_right),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (BuildContext) => ReportsDisplayPage(
                                        mapOne:
                                            finalExpensePaidByUserGeneralStatsCalculated,
                                        mapTwo:
                                            finalExpensePaidByUserPaymentMethodStatsCalculated,
                                        mapThree: {},
                                        mapFour: {},
                                        reportsName: 'ExpensePaidByUserStats',
                                      )));
                        },
                      )
                    : SizedBox.shrink(),
                (finalExpensePaidByUserGeneralStatsCalculated.isNotEmpty &&
                        showSpinner == false)
                    ? Divider(thickness: 2)
                    : SizedBox.shrink(),
                (finalExpensePaymentMethodStatsCalculated.isNotEmpty &&
                        showSpinner == false)
                    ? ListTile(
                        title: Text('Expense Payment Method Stats'),
                        trailing: Icon(Icons.keyboard_arrow_right),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (BuildContext) => ReportsDisplayPage(
                                        mapOne:
                                            finalExpensePaymentMethodStatsCalculated,
                                        mapTwo: {},
                                        mapThree: {},
                                        mapFour: {},
                                        reportsName:
                                            'ExpensePaymentMethodStats',
                                      )));
                        },
                      )
                    : SizedBox.shrink(),
                (finalExpensePaymentMethodStatsCalculated.isNotEmpty &&
                        showSpinner == false)
                    ? Divider(thickness: 2)
                    : SizedBox.shrink(),
                ((finalBilledCancelledIndividualItemsStatsCalculated
                                .isNotEmpty ||
                            finalNonBilledCancelledIndividualItemsStatsCalculated
                                .isNotEmpty) &&
                        showSpinner == false)
                    ? ListTile(
                        title: Text('Items Cancelled Stats'),
                        trailing: Icon(Icons.keyboard_arrow_right),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (BuildContext) => ReportsDisplayPage(
                                        mapOne:
                                            finalBilledCancelledIndividualItemsStatsCalculated,
                                        mapTwo:
                                            finalNonBilledCancelledIndividualItemsStatsCalculated,
                                        mapThree: {},
                                        mapFour: {},
                                        reportsName:
                                            'CancelledIndividualItemsStats',
                                      )));
                        },
                      )
                    : SizedBox.shrink(),
                ((finalBilledCancelledIndividualItemsStatsCalculated
                                .isNotEmpty ||
                            finalNonBilledCancelledIndividualItemsStatsCalculated
                                .isNotEmpty) &&
                        showSpinner == false)
                    ? Divider(thickness: 2)
                    : SizedBox.shrink(),
                ((finalBilledCaptainCancellationStats.isNotEmpty ||
                            finalNonBilledCaptainCancellationStats
                                .isNotEmpty) &&
                        showSpinner == false)
                    ? ListTile(
                        title: Text('Captain Cancellation Stats'),
                        trailing: Icon(Icons.keyboard_arrow_right),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (BuildContext) => ReportsDisplayPage(
                                        mapOne:
                                            finalBilledCaptainCancellationStats,
                                        mapTwo:
                                            finalNonBilledCaptainCancellationStats,
                                        mapThree:
                                            finalBilledCaptainCancelledIndividualItemsStats,
                                        mapFour:
                                            finalNonBilledCaptainCancelledIndividualItemsStats,
                                        reportsName: 'CaptainCancellationStats',
                                      )));
                        },
                      )
                    : SizedBox.shrink(),
                ((finalBilledCaptainCancellationStats.isNotEmpty ||
                            finalNonBilledCaptainCancellationStats
                                .isNotEmpty) &&
                        showSpinner == false)
                    ? Divider(thickness: 2)
                    : SizedBox.shrink(),
                ((finalBilledChefRejectionStats.isNotEmpty ||
                            finalNonBilledChefRejectionStats.isNotEmpty) &&
                        showSpinner == false)
                    ? ListTile(
                        title: Text('Chef Rejection Stats'),
                        trailing: Icon(Icons.keyboard_arrow_right),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (BuildContext) => ReportsDisplayPage(
                                        mapOne: finalBilledChefRejectionStats,
                                        mapTwo:
                                            finalNonBilledChefRejectionStats,
                                        mapThree:
                                            finalBilledChefRejectedIndividualItemsStats,
                                        mapFour:
                                            finalNonBilledChefRejectedIndividualItemsStats,
                                        reportsName: 'ChefRejectionStats',
                                      )));
                        },
                      )
                    : SizedBox.shrink(),
                ((finalBilledChefRejectionStats.isNotEmpty ||
                            finalNonBilledChefRejectionStats.isNotEmpty) &&
                        showSpinner == false)
                    ? Divider(thickness: 2)
                    : SizedBox.shrink(),
              ],
            ),
          ),
        ));
  }
}
