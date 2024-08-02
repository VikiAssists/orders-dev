import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:orders_dev/constants.dart';
import 'package:provider/provider.dart';

class ReportsDisplayPage extends StatelessWidget {
  final Map mapOne;
  final Map mapTwo;
  final Map mapThree;
  final Map mapFour;

  final String reportsName;
  const ReportsDisplayPage({
    Key? key,
    required this.mapOne,
    required this.mapTwo,
    required this.mapThree,
    required this.mapFour,
    required this.reportsName,
  }) : super(key: key);

//MethodForMakingGeneralStats
  Widget generalStatsDataTable() {
    return Center(
      child: DataTable(columns: [
        DataColumn(label: Text('Amount', style: TextStyle(fontSize: 20))),
        DataColumn(
            label: Text(mapOne['totalbillamounttoday'].toString(),
                style: TextStyle(fontSize: 20)))
      ], rows: <DataRow>[
        DataRow(cells: <DataCell>[
          DataCell(Text('Orders', style: TextStyle(fontSize: 18))),
          DataCell(Text(mapOne['totalnumberoforders'].toString(),
              style: TextStyle(fontSize: 18)))
        ]),
        DataRow(cells: <DataCell>[
          DataCell(Text('Dine-Ins', style: TextStyle(fontSize: 18))),
          DataCell(Text(
              (mapOne['totalnumberoforders']! - mapOne['numberofparcel']!)
                  .toString(),
              style: TextStyle(fontSize: 18)))
        ]),
        DataRow(cells: <DataCell>[
          DataCell(Text('Parcels', style: TextStyle(fontSize: 18))),
          DataCell(Text(mapOne['numberofparcel'].toString(),
              style: TextStyle(fontSize: 18)))
        ]),
        DataRow(cells: <DataCell>[
          DataCell(Text('Discount', style: TextStyle(fontSize: 18))),
          DataCell(Text(mapOne['totaldiscount'].toString(),
              style: TextStyle(fontSize: 18)))
        ])
      ]),
    );
  }

//MethodForMakingSalesPaymentMethods
  Widget salesPaymentMethodStatsTable() {
    return DataTable(columns: [
      DataColumn(label: Text('Method', style: TextStyle(fontSize: 20))),
      DataColumn(label: Text('Count', style: TextStyle(fontSize: 20))),
      DataColumn(label: Text('Amount', style: TextStyle(fontSize: 20)))
    ], rows: dataRowWidgetOfSalesPaymentMethods());
  }

//MethodForMakingRowOfSalesPaymentMethods
  List<DataRow> dataRowWidgetOfSalesPaymentMethods() {
    List<DataRow> dataRowsWithSalesPaymentMethods = [];
    final statsMapToList = mapOne.entries.toList();
    statsMapToList.sort((a, b) => (b.value['TAPM'].compareTo(a.value['TAPM'])));
    for (var eachIteration in statsMapToList) {
      MapEntry copyOfEachIteration = eachIteration;
      dataRowsWithSalesPaymentMethods.add(DataRow(cells: [
        DataCell(Text(copyOfEachIteration.key)),
        DataCell(Text(copyOfEachIteration.value['NTPM'].toString())),
        DataCell(Text(copyOfEachIteration.value['TAPM'].toString())),
      ]));
    }

    return dataRowsWithSalesPaymentMethods;
  }

  @override
  Widget build(BuildContext context) {
    final scrollControllerOne = ScrollController();
    final scrollControllerTwo = ScrollController();
//MethodForMakingCashierAmountStats

//MethodForMakingRowOfCashierSalesBaseStats
    List<DataRow> dataRowWidgetOfSalesCashierAmountBaseStats() {
      Map<String, dynamic> userProfileMap = json.decode(
          Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .allUserProfilesFromClass);
      final statsMapToList = mapOne.entries.toList();
      statsMapToList.sort((a, b) => (b.value['TAC'].compareTo(a.value['TAC'])));
      List<DataRow> dataRowsWithSalesCashierStats = [];

      for (var eachIteration in statsMapToList) {
        MapEntry copyOfEachIteration = eachIteration;
        final userName = userProfileMap.containsKey(copyOfEachIteration.key)
            ? userProfileMap[copyOfEachIteration.key]['username']
            : copyOfEachIteration.key;
        dataRowsWithSalesCashierStats.add(DataRow(cells: [
          DataCell(Text(userName)),
          DataCell(Text(copyOfEachIteration.value['NOC'].toString())),
          DataCell(Text(copyOfEachIteration.value['TAC'].toString()))
        ]));
      }

      return dataRowsWithSalesCashierStats;
    }

//MethodForMakingSalesCashierBasicStats
    DataTable salesCashierAmountBaseStatsTable() {
      return DataTable(columns: [
        DataColumn(label: Text('Name', style: TextStyle(fontSize: 20))),
        DataColumn(label: Text('Orders', style: TextStyle(fontSize: 20))),
        DataColumn(label: Text('Amount', style: TextStyle(fontSize: 20)))
      ], rows: dataRowWidgetOfSalesCashierAmountBaseStats());
    }

//MethodForMakingRowOfCashierPaymentMethodStats
    List<DataRow> dataRowWidgetOfSalesCashierPaymentMethodStats(
        Map<String, dynamic> eachCashierPaymentMethodRows) {
      List<DataRow> dataRowsWithSalesCashierPaymentMethodStats = [];
      final statsMapToList = eachCashierPaymentMethodRows.entries.toList();
      statsMapToList
          .sort((a, b) => (b.value['TAPM'].compareTo(a.value['TAPM'])));

      for (var eachIteration in statsMapToList) {
        MapEntry copyOfEachIteration = eachIteration;
        dataRowsWithSalesCashierPaymentMethodStats.add(DataRow(cells: [
          DataCell(Text(copyOfEachIteration.key)),
          DataCell(Text(copyOfEachIteration.value['NTPM'].toString())),
          DataCell(Text(copyOfEachIteration.value['TAPM'].toString()))
        ]));
      }

      return dataRowsWithSalesCashierPaymentMethodStats;
    }

//MethodForMakingSalesCashierPaymentMethodStats
    Column salesCashierPaymentMethodTable() {
      Map<String, dynamic> userProfileMap = json.decode(
          Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .allUserProfilesFromClass);
      final statsMapToList = mapOne.entries.toList();
      statsMapToList.sort((a, b) => (b.value['TAC'].compareTo(a.value['TAC'])));
      List<String> phoneNumberListAsPerHighestAmountTaken = [];
      for (var eachIteration in statsMapToList) {
        MapEntry copyOfEachIteration = eachIteration;
        phoneNumberListAsPerHighestAmountTaken.add(copyOfEachIteration.key);
      }
      List<Column> eachCashierPaymentMethodStats = [];
      int dividerCounter = 0;
      for (var eachPhoneNumber in phoneNumberListAsPerHighestAmountTaken) {
        dividerCounter++;
        final userName = userProfileMap.containsKey(eachPhoneNumber)
            ? userProfileMap[eachPhoneNumber]['username']
            : eachPhoneNumber;
        Map<String, dynamic> tempEachPaymentMethodStats =
            mapTwo[eachPhoneNumber];
        eachCashierPaymentMethodStats.add(Column(children: [
          Text(userName,
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
          DataTable(
              columns: [
                DataColumn(
                    label: Text('Payment\nMethod',
                        style: TextStyle(fontSize: 20))),
                DataColumn(
                    label: Text('Count', style: TextStyle(fontSize: 20))),
                DataColumn(
                    label: Text('Amount', style: TextStyle(fontSize: 20)))
              ],
              rows: dataRowWidgetOfSalesCashierPaymentMethodStats(
                  tempEachPaymentMethodStats)),
//ForTopDataThereWillBeLines.ForLastData,thereWilBeOnlyClosingLine
          dividerCounter == mapTwo.length ? SizedBox.shrink() : Divider()
        ]));
      }
//       mapTwo.forEach((cashierPhoneNumberAsKey, statsAsValue) {
//         dividerCounter++;
//         final userName = userProfileMap.containsKey(cashierPhoneNumberAsKey)
//             ? userProfileMap[cashierPhoneNumberAsKey]['username']
//             : cashierPhoneNumberAsKey;
//         Map<String, dynamic> tempEachPaymentMethodStats = statsAsValue;
//         eachCashierPaymentMethodStats.add(Column(
//           children: [
//             Text(userName,
//                 style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
//             DataTable(
//                 columns: [
//                   DataColumn(
//                       label: Text('Payment\nMethod',
//                           style: TextStyle(fontSize: 20))),
//                   DataColumn(
//                       label: Text('Count', style: TextStyle(fontSize: 20))),
//                   DataColumn(
//                       label: Text('Amount', style: TextStyle(fontSize: 20)))
//                 ],
//                 rows: dataRowWidgetOfSalesCashierPaymentMethodStats(
//                     tempEachPaymentMethodStats)),
// //ForTopDataThereWillBeLines.ForLastData,thereWilBeOnlyClosingLine
//             dividerCounter == mapTwo.length ? SizedBox.shrink() : Divider()
//           ],
//         ));
//       });
      return Column(
        children: eachCashierPaymentMethodStats,
      );
    }

//MethodForMakingCategoryWiseSalesStats

//MethodForMakingCashierAmountStats

//MethodForMakingRowsOfCategorySalesStats

    //DataRowsForCategory
    List<DataRow> dataRowWidgetOfCategoryBaseStats() {
      List<DataRow> dataRowWithStats = [];
      final statsMapToList = mapOne.entries.toList();

      statsMapToList.sort((a, b) => (b.value['TA'].compareTo(a.value['TA'])));

      for (var eachIteration in statsMapToList) {
        MapEntry copyOfEachIteration = eachIteration;
        dataRowWithStats.add(DataRow(cells: [
          DataCell(Text(copyOfEachIteration.key)),
          DataCell(Text((copyOfEachIteration.value['NU']).toString())),
          DataCell(Text((copyOfEachIteration.value['TA']).toString())),
          DataCell(Text((copyOfEachIteration.value['CG']).toString())),
          DataCell(Text((copyOfEachIteration.value['SG']).toString())),
        ]));
      }
      return dataRowWithStats;
    }

    //CategoryStatsDataTable
    Scrollbar salesCategoryStatsTable() {
      return Scrollbar(
        thumbVisibility: true,
        controller: scrollControllerOne,
        child: SingleChildScrollView(
          controller: scrollControllerOne,
          scrollDirection: Axis.horizontal,
          child: DataTable(columns: [
            DataColumn(label: Text('Name', style: TextStyle(fontSize: 20))),
            DataColumn(label: Text('Count', style: TextStyle(fontSize: 20))),
            DataColumn(label: Text('Amount', style: TextStyle(fontSize: 20))),
            DataColumn(label: Text('CGST', style: TextStyle(fontSize: 20))),
            DataColumn(label: Text('SGST', style: TextStyle(fontSize: 20))),
          ], rows: dataRowWidgetOfCategoryBaseStats()),
        ),
      );
    }

    //toConvertMapOfCategoryToItemsToItemsToCategory
    Map<String, String> convertingMapOfListOfMap() {
      Map<String, String> convertedMap = HashMap();
      mapTwo.forEach((key, value) {
        List<String> listOfValue = value;
        for (var iterations in listOfValue) {
          convertedMap.addAll({iterations: key});
        }
      });
      return convertedMap;
    }

    //DataRowsForItems

    List<DataRow> dataRowWidgetOfItemsStats() {
      Map<String, String> itemsToCategory = convertingMapOfListOfMap();
      List<DataRow> dataRowWithStats = [];
      final statsMapToList = mapThree.entries.toList();

      statsMapToList.sort((a, b) => (b.value['TA'].compareTo(a.value['TA'])));

      for (var eachIteration in statsMapToList) {
        MapEntry copyOfEachIteration = eachIteration;
        dataRowWithStats.add(DataRow(cells: [
          DataCell(Text(copyOfEachIteration.key)),
          DataCell(Text((copyOfEachIteration.value['NU']).toString())),
          DataCell(Text((copyOfEachIteration.value['TA']).toString())),
          DataCell(Text((copyOfEachIteration.value['CG']).toString())),
          DataCell(Text((copyOfEachIteration.value['SG']).toString())),
          DataCell(Text(itemsToCategory[copyOfEachIteration.key].toString())),
        ]));
      }
      return dataRowWithStats;
    }

    //ItemsStatsDataTable
    Scrollbar salesItemsStatsTable() {
      return Scrollbar(
        thumbVisibility: true,
        controller: scrollControllerTwo,
        child: SingleChildScrollView(
          controller: scrollControllerTwo,
          scrollDirection: Axis.horizontal,
          child: DataTable(columns: [
            DataColumn(label: Text('Name', style: TextStyle(fontSize: 20))),
            DataColumn(label: Text('Count', style: TextStyle(fontSize: 20))),
            DataColumn(label: Text('Amount', style: TextStyle(fontSize: 20))),
            DataColumn(label: Text('CGST', style: TextStyle(fontSize: 20))),
            DataColumn(label: Text('SGST', style: TextStyle(fontSize: 20))),
            DataColumn(label: Text('Category', style: TextStyle(fontSize: 20))),
          ], rows: dataRowWidgetOfItemsStats()),
        ),
      );
    }

//ExtraItemsSalesStats
    //DataRowsForItems

    List<DataRow> dataRowWidgetOfExtraItemsStats() {
      List<DataRow> dataRowWithStats = [];
      final statsMapToList = mapOne.entries.toList();

      statsMapToList.sort((a, b) => (b.value['TE'].compareTo(a.value['TE'])));

      for (var eachIteration in statsMapToList) {
        MapEntry copyOfEachIteration = eachIteration;
        dataRowWithStats.add(DataRow(cells: [
          DataCell(Text(copyOfEachIteration.key)),
          DataCell(Text((copyOfEachIteration.value['UE']).toString())),
          DataCell(Text((copyOfEachIteration.value['TE']).toString())),
          DataCell(Text((copyOfEachIteration.value['CGE']).toString())),
          DataCell(Text((copyOfEachIteration.value['SGE']).toString())),
        ]));
      }
      return dataRowWithStats;
    }

    //ItemsStatsDataTable
    Scrollbar salesExtraItemsStatsTable() {
      return Scrollbar(
        thumbVisibility: true,
        controller: scrollControllerOne,
        child: SingleChildScrollView(
          controller: scrollControllerOne,
          scrollDirection: Axis.horizontal,
          child: DataTable(columns: [
            DataColumn(label: Text('Name', style: TextStyle(fontSize: 20))),
            DataColumn(label: Text('Count', style: TextStyle(fontSize: 20))),
            DataColumn(label: Text('Amount', style: TextStyle(fontSize: 20))),
            DataColumn(label: Text('CGST', style: TextStyle(fontSize: 20))),
            DataColumn(label: Text('SGST', style: TextStyle(fontSize: 20)))
          ], rows: dataRowWidgetOfExtraItemsStats()),
        ),
      );
    }

//MethodsForMakingAllCashierStats

//MethodForMakingRowOfCaptainOrdersTakenBaseStats
    List<DataRow> dataRowWidgetOfCaptainOrdersTakenStatsTable() {
      Map<String, dynamic> userProfileMap = json.decode(
          Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .allUserProfilesFromClass);
      final statsMapToList = mapOne.entries.toList();
      statsMapToList.sort((a, b) => (b.value['TI'].compareTo(a.value['TI'])));
      List<DataRow> dataRowsWithCaptainGeneralStats = [];

      for (var eachIteration in statsMapToList) {
        MapEntry copyOfEachIteration = eachIteration;
        final userName = userProfileMap.containsKey(copyOfEachIteration.key)
            ? userProfileMap[copyOfEachIteration.key]['username']
            : copyOfEachIteration.key;
        dataRowsWithCaptainGeneralStats.add(DataRow(cells: [
          DataCell(Text(userName)),
          DataCell(Text(copyOfEachIteration.value['TI'].toString())),
          DataCell(Text(copyOfEachIteration.value['OT'].toString()))
        ]));
      }

      return dataRowsWithCaptainGeneralStats;
    }

//MethodForMakingCaptainOrdersTakenBasicStats
    DataTable captainOrdersTakenStatsTable() {
      return DataTable(columns: [
        DataColumn(label: Text('Name', style: TextStyle(fontSize: 20))),
        DataColumn(label: Text('Tickets', style: TextStyle(fontSize: 20))),
        DataColumn(label: Text('Orders', style: TextStyle(fontSize: 20)))
      ], rows: dataRowWidgetOfCaptainOrdersTakenStatsTable());
    }

//MethodForMakingRowOfCaptainIndividualItemsStats
    List<DataRow> dataRowWidgetOfCaptainIndividualItemsStatsTable(
        Map<String, dynamic> eachCaptainIndividualItemsRows) {
      List<DataRow> dataRowsWithCaptainIndividualItemsStats = [];
      final statsMapToList = eachCaptainIndividualItemsRows.entries.toList();
      statsMapToList.sort((a, b) => (b.value['CTA'].compareTo(a.value['CTA'])));

      for (var eachIteration in statsMapToList) {
        MapEntry copyOfEachIteration = eachIteration;
        dataRowsWithCaptainIndividualItemsStats.add(DataRow(cells: [
          DataCell(Text(copyOfEachIteration.key)),
          DataCell(Text(copyOfEachIteration.value['CNU'].toString())),
          DataCell(Text(copyOfEachIteration.value['CTA'].toString()))
        ]));
      }

      return dataRowsWithCaptainIndividualItemsStats;
    }

//MethodForMakingCaptainIndividualItemsStats
    Column captainIndividualItemsStatsTable() {
      Map<String, dynamic> userProfileMap = json.decode(
          Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .allUserProfilesFromClass);
      final statsMapToList = mapOne.entries.toList();
      statsMapToList.sort((a, b) => (b.value['TI'].compareTo(a.value['TI'])));
      List<String> phoneNumberListAsPerHighestAmountTaken = [];
      for (var eachIteration in statsMapToList) {
        MapEntry copyOfEachIteration = eachIteration;
        phoneNumberListAsPerHighestAmountTaken.add(copyOfEachIteration.key);
      }
      List<Column> eachCaptainIndividualItemsOrdersTakenStats = [];
      int dividerCounter = 0;
      for (var eachPhoneNumber in phoneNumberListAsPerHighestAmountTaken) {
        dividerCounter++;
        final userName = userProfileMap.containsKey(eachPhoneNumber)
            ? userProfileMap[eachPhoneNumber]['username']
            : eachPhoneNumber;
        Map<String, dynamic> tempEachCaptainIndividualItemsStats =
            mapTwo[eachPhoneNumber];
        eachCaptainIndividualItemsOrdersTakenStats.add(Column(children: [
          Text(userName,
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
          DataTable(
              columns: [
                DataColumn(label: Text('Item', style: TextStyle(fontSize: 20))),
                DataColumn(
                    label: Text('Count', style: TextStyle(fontSize: 20))),
                DataColumn(
                    label: Text('Amount', style: TextStyle(fontSize: 20)))
              ],
              rows: dataRowWidgetOfCaptainIndividualItemsStatsTable(
                  tempEachCaptainIndividualItemsStats)),
//ForTopDataThereWillBeLines.ForLastData,thereWilBeOnlyClosingLine
          dividerCounter == mapTwo.length ? SizedBox.shrink() : Divider()
        ]));
      }
      return Column(
        children: eachCaptainIndividualItemsOrdersTakenStats,
      );
    }

//ExpensesCategoryStats
    //DataRowsForItems

    List<DataRow> dataRowWidgetOfExpensesCategoriesStats() {
      List<DataRow> dataRowWithStats = [];
      final statsMapToList = mapOne.entries.toList();

      statsMapToList.sort((a, b) => (b.value['TPC'].compareTo(a.value['TPC'])));

      for (var eachIteration in statsMapToList) {
        MapEntry copyOfEachIteration = eachIteration;
        dataRowWithStats.add(DataRow(cells: [
          DataCell(Text(copyOfEachIteration.key)),
          DataCell(Text((copyOfEachIteration.value['NUC']).toString())),
          DataCell(Text((copyOfEachIteration.value['TPC']).toString())),
          DataCell(Text((copyOfEachIteration.value['CGC']).toString())),
          DataCell(Text((copyOfEachIteration.value['SGC']).toString())),
        ]));
      }
      return dataRowWithStats;
    }

    //ExpensesCategoryStatsDataTable
    Scrollbar expensesCategoriesStatsTable() {
      return Scrollbar(
        thumbVisibility: true,
        controller: scrollControllerOne,
        child: SingleChildScrollView(
          controller: scrollControllerOne,
          scrollDirection: Axis.horizontal,
          child: DataTable(columns: [
            DataColumn(label: Text('Category', style: TextStyle(fontSize: 20))),
            DataColumn(label: Text('Count', style: TextStyle(fontSize: 20))),
            DataColumn(label: Text('Amount', style: TextStyle(fontSize: 20))),
            DataColumn(label: Text('CGST', style: TextStyle(fontSize: 20))),
            DataColumn(label: Text('SGST', style: TextStyle(fontSize: 20)))
          ], rows: dataRowWidgetOfExpensesCategoriesStats()),
        ),
      );
    }

//MethodForMakingExpensesPaidByUserStats

//MethodForMakingRowOfExpensesPaidByUserBaseStats
    List<DataRow> dataRowWidgetOfExpensePaidByUserAmountBaseStatsTable() {
      Map<String, dynamic> userProfileMap = json.decode(
          Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .allUserProfilesFromClass);
      final statsMapToList = mapOne.entries.toList();
      statsMapToList.sort((a, b) => (b.value['UPA'].compareTo(a.value['UPA'])));
      List<DataRow> dataRowsWithExpensePaidByUserBaseStats = [];

      for (var eachIteration in statsMapToList) {
        MapEntry copyOfEachIteration = eachIteration;
        final userName = userProfileMap.containsKey(copyOfEachIteration.key)
            ? userProfileMap[copyOfEachIteration.key]['username']
            : copyOfEachIteration.key;
        dataRowsWithExpensePaidByUserBaseStats.add(DataRow(cells: [
          DataCell(Text(userName)),
          DataCell(Text(copyOfEachIteration.value['NEUP'].toString())),
          DataCell(Text(copyOfEachIteration.value['UPA'].toString()))
        ]));
      }

      return dataRowsWithExpensePaidByUserBaseStats;
    }

//MethodForMakingSalesCashierBasicStats
    DataTable expensePaidByUserAmountBaseStatsTable() {
      return DataTable(columns: [
        DataColumn(label: Text('Name', style: TextStyle(fontSize: 20))),
        DataColumn(label: Text('Count', style: TextStyle(fontSize: 20))),
        DataColumn(label: Text('Amount', style: TextStyle(fontSize: 20)))
      ], rows: dataRowWidgetOfExpensePaidByUserAmountBaseStatsTable());
    }

//MethodForMakingRowOfCashierPaymentMethodStats
    List<DataRow> dataRowWidgetOfExpensePaidByUserPaymentMethodTableStats(
        Map<String, dynamic> eachPaidByUserPaymentMethodRows) {
      List<DataRow> dataRowsWithExpensePaidByUserPaymentMethodStats = [];
      final statsMapToList = eachPaidByUserPaymentMethodRows.entries.toList();
      statsMapToList
          .sort((a, b) => (b.value['PAPM'].compareTo(a.value['PAPM'])));

      for (var eachIteration in statsMapToList) {
        MapEntry copyOfEachIteration = eachIteration;
        dataRowsWithExpensePaidByUserPaymentMethodStats.add(DataRow(cells: [
          DataCell(Text(copyOfEachIteration.key)),
          DataCell(Text(copyOfEachIteration.value['NEPM'].toString())),
          DataCell(Text(copyOfEachIteration.value['PAPM'].toString()))
        ]));
      }

      return dataRowsWithExpensePaidByUserPaymentMethodStats;
    }

//MethodForMakingExpensePaidByUserPaymentMethodStats
    Column expensePaidByUserPaymentMethodTable() {
      Map<String, dynamic> userProfileMap = json.decode(
          Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .allUserProfilesFromClass);
      final statsMapToList = mapOne.entries.toList();
      statsMapToList.sort((a, b) => (b.value['UPA'].compareTo(a.value['UPA'])));
      List<String> phoneNumberListAsPerHighestAmountTaken = [];
      for (var eachIteration in statsMapToList) {
        MapEntry copyOfEachIteration = eachIteration;
        phoneNumberListAsPerHighestAmountTaken.add(copyOfEachIteration.key);
      }
      List<Column> eachExpensePaidByUserPaymentMethodStats = [];
      int dividerCounter = 0;
      for (var eachPhoneNumber in phoneNumberListAsPerHighestAmountTaken) {
        dividerCounter++;
        final userName = userProfileMap.containsKey(eachPhoneNumber)
            ? userProfileMap[eachPhoneNumber]['username']
            : eachPhoneNumber;
        Map<String, dynamic> tempEachPaymentMethodStats =
            mapTwo[eachPhoneNumber];
        eachExpensePaidByUserPaymentMethodStats.add(Column(children: [
          Text(userName,
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
          DataTable(
              columns: [
                DataColumn(
                    label: Text('Payment\nMethod',
                        style: TextStyle(fontSize: 20))),
                DataColumn(
                    label: Text('Count', style: TextStyle(fontSize: 20))),
                DataColumn(
                    label: Text('Amount', style: TextStyle(fontSize: 20)))
              ],
              rows: dataRowWidgetOfExpensePaidByUserPaymentMethodTableStats(
                  tempEachPaymentMethodStats)),
//ForTopDataThereWillBeLines.ForLastData,thereWilBeOnlyClosingLine
          dividerCounter == mapTwo.length ? SizedBox.shrink() : Divider()
        ]));
      }
      return Column(
        children: eachExpensePaidByUserPaymentMethodStats,
      );
    }

//MethodForMakingExpensePaymentMethods

//MethodForMakingRowOfExpensesPaymentMethods
    List<DataRow> dataRowWidgetOfExpensesPaymentMethodStatsTable() {
      List<DataRow> dataRowsWithSalesPaymentMethods = [];
      final statsMapToList = mapOne.entries.toList();
      statsMapToList
          .sort((a, b) => (b.value['PAPM'].compareTo(a.value['PAPM'])));
      for (var eachIteration in statsMapToList) {
        MapEntry copyOfEachIteration = eachIteration;
        dataRowsWithSalesPaymentMethods.add(DataRow(cells: [
          DataCell(Text(copyOfEachIteration.key)),
          DataCell(Text(copyOfEachIteration.value['NEPM'].toString())),
          DataCell(Text(copyOfEachIteration.value['PAPM'].toString())),
        ]));
      }

      return dataRowsWithSalesPaymentMethods;
    }

    Widget expensesPaymentMethodStatsTable() {
      return DataTable(columns: [
        DataColumn(label: Text('Method', style: TextStyle(fontSize: 20))),
        DataColumn(label: Text('Count', style: TextStyle(fontSize: 20))),
        DataColumn(label: Text('Amount', style: TextStyle(fontSize: 20)))
      ], rows: dataRowWidgetOfExpensesPaymentMethodStatsTable());
    }

//MethodForMakingBilledCancelledIndividualItems

//MethodForMakingRowOfBilledCancelledIndividualItemsStats
    List<DataRow> dataRowWidgetOfBilledCancelledIndividualItemsStatsTable() {
      List<DataRow> dataRowsWithCancelledIndividualItems = [];
      final statsMapToList = mapOne.entries.toList();
      statsMapToList.sort((a, b) => (b.value['TAC'].compareTo(a.value['TAC'])));
      for (var eachIteration in statsMapToList) {
        MapEntry copyOfEachIteration = eachIteration;
        dataRowsWithCancelledIndividualItems.add(DataRow(cells: [
          DataCell(Text(copyOfEachIteration.key)),
          DataCell(Text(copyOfEachIteration.value['NIC'].toString())),
          DataCell(Text(copyOfEachIteration.value['TAC'].toString())),
        ]));
      }

      return dataRowsWithCancelledIndividualItems;
    }

    Widget billedCancelledIndividualItemsStatsTable() {
      return DataTable(columns: [
        DataColumn(label: Text('Name', style: TextStyle(fontSize: 20))),
        DataColumn(label: Text('Count', style: TextStyle(fontSize: 20))),
        DataColumn(label: Text('Amount', style: TextStyle(fontSize: 20)))
      ], rows: dataRowWidgetOfBilledCancelledIndividualItemsStatsTable());
    }

//MethodForMakingNonBilledCancelledIndividualItems

//MethodForMakingRowOfNonBilledCancelledIndividualItemsStats
    List<DataRow> dataRowWidgetOfNonBilledCancelledIndividualItemsStatsTable() {
      List<DataRow> dataRowsWithCancelledIndividualItems = [];
      final statsMapToList = mapTwo.entries.toList();
      statsMapToList.sort((a, b) => (b.value['TAC'].compareTo(a.value['TAC'])));
      for (var eachIteration in statsMapToList) {
        MapEntry copyOfEachIteration = eachIteration;
        dataRowsWithCancelledIndividualItems.add(DataRow(cells: [
          DataCell(Text(copyOfEachIteration.key)),
          DataCell(Text(copyOfEachIteration.value['NIC'].toString())),
          DataCell(Text(copyOfEachIteration.value['TAC'].toString())),
        ]));
      }

      return dataRowsWithCancelledIndividualItems;
    }

    Widget nonBilledCancelledIndividualItemsStatsTable() {
      return DataTable(columns: [
        DataColumn(label: Text('Name', style: TextStyle(fontSize: 20))),
        DataColumn(label: Text('Count', style: TextStyle(fontSize: 20))),
        DataColumn(label: Text('Amount', style: TextStyle(fontSize: 20)))
      ], rows: dataRowWidgetOfNonBilledCancelledIndividualItemsStatsTable());
    }

//CaptainCancellationDataMaking

//ColumnsOfCaptainIndividualItemsCancelStats

//MethodForMakingRowOfCashierPaymentMethodStats
    List<DataRow> dataRowWidgetOfEachCaptainIndividualItemsCancelledTable(
        Map<String, dynamic> eachCancelledIndividualItemsRows) {
      List<DataRow> dataRowsWithCancelledIndividualItemsStats = [];
      final statsMapToList = eachCancelledIndividualItemsRows.entries.toList();
      statsMapToList.sort((a, b) => (b.value['totalAmountOfIndividualItems']
          .compareTo(a.value['totalAmountOfIndividualItems'])));

      for (var eachIteration in statsMapToList) {
        MapEntry copyOfEachIteration = eachIteration;
        dataRowsWithCancelledIndividualItemsStats.add(DataRow(cells: [
          DataCell(Text(copyOfEachIteration.key)),
          DataCell(Text(
              copyOfEachIteration.value['numberOfIndividualItems'].toString())),
          DataCell(Text(copyOfEachIteration
              .value['totalAmountOfIndividualItems']
              .toString()))
        ]));
      }

      return dataRowsWithCancelledIndividualItemsStats;
    }

    Column eachCaptainIndividualItemsCancelledTable(
        List<String> captainPhoneKeys) {
      Map<String, dynamic> userProfileMap = json.decode(
          Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .allUserProfilesFromClass);

      List<Column> eachCaptainItemCancellationStats = [];
      int dividerCounter = 0;
      for (var eachPhoneNumber in captainPhoneKeys) {
        dividerCounter++;
        final userName = userProfileMap.containsKey(eachPhoneNumber)
            ? userProfileMap[eachPhoneNumber]['username']
            : eachPhoneNumber;
        bool userNameShown = false;
        if (mapThree.containsKey(eachPhoneNumber)) {
          userNameShown = true;
          Map<String, dynamic> tempEachCaptainCancelledIndividualItemsStats =
              mapThree[eachPhoneNumber];
          eachCaptainItemCancellationStats.add(Column(children: [
            dividerCounter > 1 ? Divider() : SizedBox.shrink(),
            Text(userName,
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
            Text('Closed Bill Cancelled Items', style: TextStyle(fontSize: 20)),
            DataTable(
                columns: [
                  DataColumn(
                      label: Text('Item', style: TextStyle(fontSize: 20))),
                  DataColumn(
                      label: Text('Count', style: TextStyle(fontSize: 20))),
                  DataColumn(
                      label: Text('Amount', style: TextStyle(fontSize: 20)))
                ],
                rows: dataRowWidgetOfEachCaptainIndividualItemsCancelledTable(
                    tempEachCaptainCancelledIndividualItemsStats))
//ForTopDataThereWillBeLines.ForLastData,thereWilBeOnlyClosingLine
          ]));
        }
        if (mapFour.containsKey(eachPhoneNumber)) {
          Map<String, dynamic> tempEachCaptainCancelledIndividualItemsStats =
              mapFour[eachPhoneNumber];
          eachCaptainItemCancellationStats.add(Column(children: [
            (userNameShown == false && dividerCounter > 1)
                ? Divider()
                : SizedBox.shrink(),
//ThisMeansThisWasNotTheFirstItemAndThereWereNamesBefore.SoWeNeedDivider
            userNameShown == false
                ? Text(userName,
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold))
                : SizedBox.shrink(),
            Text('Non-Closed Bill Cancelled Items',
                style: TextStyle(fontSize: 20)),
            DataTable(
                columns: [
                  DataColumn(
                      label: Text('Item', style: TextStyle(fontSize: 20))),
                  DataColumn(
                      label: Text('Count', style: TextStyle(fontSize: 20))),
                  DataColumn(
                      label: Text('Amount', style: TextStyle(fontSize: 20)))
                ],
                rows: dataRowWidgetOfEachCaptainIndividualItemsCancelledTable(
                    tempEachCaptainCancelledIndividualItemsStats))
//ForTopDataThereWillBeLines.ForLastData,thereWilBeOnlyClosingLine
          ]));
        }
      }
      return Column(
        children: eachCaptainItemCancellationStats,
      );
    }

//DataTableOfGeneralStats

//DataRowWidgetForCancellationCaptainGeneralStats
    List<DataRow> dataRowWidgetOfCancellationCaptainGeneralStats(
        List<String> captainPhoneKeys) {
      Map<String, dynamic> userProfileMap = json.decode(
          Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .allUserProfilesFromClass);
      List<DataRow> dataRowWithStats = [];

      for (var eachPhoneNumber in captainPhoneKeys) {
        final userName = userProfileMap.containsKey(eachPhoneNumber)
            ? userProfileMap[eachPhoneNumber]['username']
            : eachPhoneNumber;

        dataRowWithStats.add(DataRow(cells: [
          DataCell(Text(userName)),
          if (mapOne.containsKey(eachPhoneNumber))
            DataCell(Text((mapOne[eachPhoneNumber]['NCC']).toString())),
          if (!mapOne.containsKey(eachPhoneNumber)) DataCell(Text('0')),
          if (mapOne.containsKey(eachPhoneNumber))
            DataCell(Text((mapOne[eachPhoneNumber]['ACC']).toString())),
          if (!mapOne.containsKey(eachPhoneNumber)) DataCell(Text('0')),
          if (mapTwo.containsKey(eachPhoneNumber))
            DataCell(Text((mapTwo[eachPhoneNumber]['NCC']).toString())),
          if (!mapTwo.containsKey(eachPhoneNumber)) DataCell(Text('0')),
          if (mapTwo.containsKey(eachPhoneNumber))
            DataCell(Text((mapTwo[eachPhoneNumber]['ACC']).toString())),
          if (!mapTwo.containsKey(eachPhoneNumber)) DataCell(Text('0')),
        ]));
      }
      return dataRowWithStats;
    }

    Scrollbar cancellationCaptainGeneralStats(
        List<String> keysAsPerHighestCancellation) {
      return Scrollbar(
        thumbVisibility: true,
        controller: scrollControllerOne,
        child: SingleChildScrollView(
          controller: scrollControllerOne,
          scrollDirection: Axis.horizontal,
          child: DataTable(
              columns: [
                DataColumn(label: Text('Name', style: TextStyle(fontSize: 20))),
                DataColumn(
                    label: Text('Closed Bill\nCancel Count',
                        style: TextStyle(fontSize: 20))),
                DataColumn(
                    label: Text('Closed Bill\nCancel Amount',
                        style: TextStyle(fontSize: 20))),
                DataColumn(
                    label: Text('Non-Closed Bill\nCancel Count',
                        style: TextStyle(fontSize: 20))),
                DataColumn(
                    label: Text('Non-Closed Bill\nCancel Amount',
                        style: TextStyle(fontSize: 20))),
              ],
              rows: dataRowWidgetOfCancellationCaptainGeneralStats(
                  keysAsPerHighestCancellation)),
        ),
      );
    }

//CompleteColumnWithAllStats
    Widget captainCancellationReports() {
      List<dynamic> billedCancelledCaptainKeys =
          mapOne.isNotEmpty ? mapOne.keys.toList() : [];
      List<dynamic> nonBilledCancelledCaptainKeys =
          mapTwo.isNotEmpty ? mapTwo.keys.toList() : [];
//ThisWillEnsureThereAreNoDuplicates
      List<dynamic> mergedListOfCaptainKeys = [
        ...billedCancelledCaptainKeys,
        ...nonBilledCancelledCaptainKeys
      ].toSet().toList();
      List<String> keysAsPerHighestCancellation = [];
      Map<String, dynamic> tempTotalAmountAddMap = HashMap();
      for (var eachCaptain in mergedListOfCaptainKeys) {
        num totalAmountByEachCaptain = 0;
        if (mapOne.containsKey(eachCaptain)) {
          totalAmountByEachCaptain =
              totalAmountByEachCaptain + mapOne[eachCaptain]['ACC'];
        }
        if (mapTwo.containsKey(eachCaptain)) {
          totalAmountByEachCaptain =
              totalAmountByEachCaptain + mapTwo[eachCaptain]['ACC'];
        }
        tempTotalAmountAddMap.addAll({eachCaptain: totalAmountByEachCaptain});
      }
      var sortedByValueMap = Map.fromEntries(
          tempTotalAmountAddMap.entries.toList()
            ..sort((e1, e2) => e2.value.compareTo(e1.value)));
      keysAsPerHighestCancellation = sortedByValueMap.keys.toList();

      return Column(
        children: [
          cancellationCaptainGeneralStats(keysAsPerHighestCancellation),
          SizedBox(height: 20),
          eachCaptainIndividualItemsCancelledTable(keysAsPerHighestCancellation)
        ],
      );
    }

//ChefRejectionDataMaking. CopiedFromCaptainCancellation.SoWhereverYouReadDownAsCaptain...
//..YouCanReadItAsChef

//ColumnsOfCaptainIndividualItemsCancelStats

//MethodForMakingRowOfCashierPaymentMethodStats
    List<DataRow> dataRowWidgetOfEachChefIndividualItemsRejectionTable(
        Map<String, dynamic> eachCancelledIndividualItemsRows) {
      List<DataRow> dataRowsWithCancelledIndividualItemsStats = [];
      final statsMapToList = eachCancelledIndividualItemsRows.entries.toList();
      statsMapToList.sort((a, b) => (b.value['totalAmountOfIndividualItems']
          .compareTo(a.value['totalAmountOfIndividualItems'])));

      for (var eachIteration in statsMapToList) {
        MapEntry copyOfEachIteration = eachIteration;
        dataRowsWithCancelledIndividualItemsStats.add(DataRow(cells: [
          DataCell(Text(copyOfEachIteration.key)),
          DataCell(Text(
              copyOfEachIteration.value['numberOfIndividualItems'].toString())),
          DataCell(Text(copyOfEachIteration
              .value['totalAmountOfIndividualItems']
              .toString()))
        ]));
      }

      return dataRowsWithCancelledIndividualItemsStats;
    }

    Column eachChefIndividualItemsRejectedTable(List<String> captainPhoneKeys) {
      Map<String, dynamic> userProfileMap = json.decode(
          Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .allUserProfilesFromClass);

      List<Column> eachCaptainItemCancellationStats = [];
      int dividerCounter = 0;
      for (var eachPhoneNumber in captainPhoneKeys) {
        dividerCounter++;
        final userName = userProfileMap.containsKey(eachPhoneNumber)
            ? userProfileMap[eachPhoneNumber]['username']
            : eachPhoneNumber;
        bool userNameShown = false;
        if (mapThree.containsKey(eachPhoneNumber)) {
          userNameShown = true;
          Map<String, dynamic> tempEachCaptainCancelledIndividualItemsStats =
              mapThree[eachPhoneNumber];
          eachCaptainItemCancellationStats.add(Column(children: [
            dividerCounter > 1 ? Divider() : SizedBox.shrink(),
            Text(userName,
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
            Text('Closed Bill Rejected Items', style: TextStyle(fontSize: 20)),
            DataTable(
                columns: [
                  DataColumn(
                      label: Text('Item', style: TextStyle(fontSize: 20))),
                  DataColumn(
                      label: Text('Count', style: TextStyle(fontSize: 20))),
                  DataColumn(
                      label: Text('Amount', style: TextStyle(fontSize: 20)))
                ],
                rows: dataRowWidgetOfEachChefIndividualItemsRejectionTable(
                    tempEachCaptainCancelledIndividualItemsStats))
//ForTopDataThereWillBeLines.ForLastData,thereWilBeOnlyClosingLine
          ]));
        }
        if (mapFour.containsKey(eachPhoneNumber)) {
          Map<String, dynamic> tempEachCaptainCancelledIndividualItemsStats =
              mapFour[eachPhoneNumber];
          eachCaptainItemCancellationStats.add(Column(children: [
            (userNameShown == false && dividerCounter > 1)
                ? Divider()
                : SizedBox.shrink(),
//ThisMeansThisWasNotTheFirstItemAndThereWereNamesBefore.SoWeNeedDivider
            userNameShown == false
                ? Text(userName,
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold))
                : SizedBox.shrink(),
            Text('Non-Closed Bill Rejected Items',
                style: TextStyle(fontSize: 20)),
            DataTable(
                columns: [
                  DataColumn(
                      label: Text('Item', style: TextStyle(fontSize: 20))),
                  DataColumn(
                      label: Text('Count', style: TextStyle(fontSize: 20))),
                  DataColumn(
                      label: Text('Amount', style: TextStyle(fontSize: 20)))
                ],
                rows: dataRowWidgetOfEachChefIndividualItemsRejectionTable(
                    tempEachCaptainCancelledIndividualItemsStats))
//ForTopDataThereWillBeLines.ForLastData,thereWilBeOnlyClosingLine
          ]));
        }
      }
      return Column(
        children: eachCaptainItemCancellationStats,
      );
    }

//DataTableOfGeneralStats

//DataRowWidgetForCancellationCaptainGeneralStats
    List<DataRow> dataRowWidgetOfChefRejectionGeneralStats(
        List<String> captainPhoneKeys) {
      Map<String, dynamic> userProfileMap = json.decode(
          Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .allUserProfilesFromClass);
      List<DataRow> dataRowWithStats = [];

      for (var eachPhoneNumber in captainPhoneKeys) {
        final userName = userProfileMap.containsKey(eachPhoneNumber)
            ? userProfileMap[eachPhoneNumber]['username']
            : eachPhoneNumber;

        dataRowWithStats.add(DataRow(cells: [
          DataCell(Text(userName)),
          if (mapOne.containsKey(eachPhoneNumber))
            DataCell(Text((mapOne[eachPhoneNumber]['NCR']).toString())),
          if (!mapOne.containsKey(eachPhoneNumber)) DataCell(Text('0')),
          if (mapOne.containsKey(eachPhoneNumber))
            DataCell(Text((mapOne[eachPhoneNumber]['ACR']).toString())),
          if (!mapOne.containsKey(eachPhoneNumber)) DataCell(Text('0')),
          if (mapTwo.containsKey(eachPhoneNumber))
            DataCell(Text((mapTwo[eachPhoneNumber]['NCR']).toString())),
          if (!mapTwo.containsKey(eachPhoneNumber)) DataCell(Text('0')),
          if (mapTwo.containsKey(eachPhoneNumber))
            DataCell(Text((mapTwo[eachPhoneNumber]['ACR']).toString())),
          if (!mapTwo.containsKey(eachPhoneNumber)) DataCell(Text('0')),
        ]));
      }
      return dataRowWithStats;
    }

    Scrollbar chefRejectionGeneralStats(
        List<String> keysAsPerHighestCancellation) {
      return Scrollbar(
        thumbVisibility: true,
        controller: scrollControllerOne,
        child: SingleChildScrollView(
          controller: scrollControllerOne,
          scrollDirection: Axis.horizontal,
          child: DataTable(
              columns: [
                DataColumn(label: Text('Name', style: TextStyle(fontSize: 20))),
                DataColumn(
                    label: Text('Closed Bill\nRejected Count',
                        style: TextStyle(fontSize: 20))),
                DataColumn(
                    label: Text('Closed Bill\nRejected Amount',
                        style: TextStyle(fontSize: 20))),
                DataColumn(
                    label: Text('Non-Closed Bill\nRejected Count',
                        style: TextStyle(fontSize: 20))),
                DataColumn(
                    label: Text('Non-Closed Bill\nRejected Amount',
                        style: TextStyle(fontSize: 20))),
              ],
              rows: dataRowWidgetOfChefRejectionGeneralStats(
                  keysAsPerHighestCancellation)),
        ),
      );
    }

//CompleteColumnWithAllStats
    Widget chefRejectionReports() {
      List<dynamic> billedCancelledCaptainKeys =
          mapOne.isNotEmpty ? mapOne.keys.toList() : [];
      List<dynamic> nonBilledCancelledCaptainKeys =
          mapTwo.isNotEmpty ? mapTwo.keys.toList() : [];
//ThisWillEnsureThereAreNoDuplicates
      List<dynamic> mergedListOfCaptainKeys = [
        ...billedCancelledCaptainKeys,
        ...nonBilledCancelledCaptainKeys
      ].toSet().toList();
      List<String> keysAsPerHighestCancellation = [];
      Map<String, dynamic> tempTotalAmountAddMap = HashMap();
      for (var eachCaptain in mergedListOfCaptainKeys) {
        num totalAmountByEachCaptain = 0;
        if (mapOne.containsKey(eachCaptain)) {
          totalAmountByEachCaptain =
              totalAmountByEachCaptain + mapOne[eachCaptain]['ACR'];
        }
        if (mapTwo.containsKey(eachCaptain)) {
          totalAmountByEachCaptain =
              totalAmountByEachCaptain + mapTwo[eachCaptain]['ACR'];
        }
        tempTotalAmountAddMap.addAll({eachCaptain: totalAmountByEachCaptain});
      }
      var sortedByValueMap = Map.fromEntries(
          tempTotalAmountAddMap.entries.toList()
            ..sort((e1, e2) => e2.value.compareTo(e1.value)));
      keysAsPerHighestCancellation = sortedByValueMap.keys.toList();

      return Column(
        children: [
          chefRejectionGeneralStats(keysAsPerHighestCancellation),
          SizedBox(height: 20),
          eachChefIndividualItemsRejectedTable(keysAsPerHighestCancellation)
        ],
      );
    }

    return Scaffold(
        appBar: AppBar(
          backgroundColor: kAppBarBackgroundColor,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: kAppBarBackIconColor),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: reportsName == 'GeneralStats'
              ? Text('General Report', style: kAppBarTextStyle)
              : reportsName == 'SalesPaymentStats'
                  ? Text('Sales Payment Method Report', style: kAppBarTextStyle)
                  : reportsName == 'SalesCashierStats'
                      ? Text('Cashier Sales Report', style: kAppBarTextStyle)
                      : reportsName == 'CategoryAndItemsSalesStats'
                          ? Text('Items Sales Report', style: kAppBarTextStyle)
                          : reportsName == 'ExtraItemsSalesStats'
                              ? Text('Extra Items Sales Report',
                                  style: kAppBarTextStyle)
                              : reportsName == 'CaptainOrdersTakenStats'
                                  ? Text('Captain Stats Report',
                                      style: kAppBarTextStyle)
                                  : reportsName == 'ExpenseCategoryStats'
                                      ? Text('Expense Stats Report',
                                          style: kAppBarTextStyle)
                                      : reportsName == 'ExpensePaidByUserStats'
                                          ? Text('Expense Paid By User Report',
                                              style: kAppBarTextStyle)
                                          : reportsName ==
                                                  'ExpensePaymentMethodStats'
                                              ? Text(
                                                  'Expense Payment Method Report',
                                                  style: kAppBarTextStyle)
                                              : reportsName ==
                                                      'CancelledIndividualItemsStats'
                                                  ? Text(
                                                      'Cancelled Items Report',
                                                      style: kAppBarTextStyle)
                                                  : reportsName ==
                                                          'CaptainCancellationStats'
                                                      ? Text(
                                                          'Captain Cancellation Report',
                                                          style:
                                                              kAppBarTextStyle)
                                                      : reportsName ==
                                                              'ChefRejectionStats'
                                                          ? Text(
                                                              'Chef Rejection Report',
                                                              style:
                                                                  kAppBarTextStyle)
                                                          : Text('Reports'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              reportsName == 'GeneralStats'
                  ? generalStatsDataTable()
                  : SizedBox.shrink(),
              reportsName == 'SalesPaymentStats'
                  ? salesPaymentMethodStatsTable()
                  : SizedBox.shrink(),
              (reportsName == 'SalesCashierStats' && mapOne.isNotEmpty)
                  ? salesCashierAmountBaseStatsTable()
                  : SizedBox.shrink(),
              (reportsName == 'SalesCashierStats' && mapOne.isNotEmpty)
                  ? Divider(thickness: 2)
                  : SizedBox.shrink(),
              (reportsName == 'SalesCashierStats' && mapTwo.isNotEmpty)
                  ? salesCashierPaymentMethodTable()
                  : SizedBox.shrink(),
              (reportsName == 'SalesCashierStats' && mapTwo.isNotEmpty)
                  ? Divider(thickness: 2)
                  : SizedBox.shrink(),
              reportsName == 'CategoryAndItemsSalesStats'
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text('Category Stats',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    )
                  : SizedBox.shrink(),
              reportsName == 'CategoryAndItemsSalesStats'
                  ? salesCategoryStatsTable()
                  : SizedBox.shrink(),
              reportsName == 'CategoryAndItemsSalesStats'
                  ? Divider(thickness: 2)
                  : SizedBox.shrink(),
              reportsName == 'CategoryAndItemsSalesStats'
                  ? Text('Items Stats',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                  : SizedBox.shrink(),
              reportsName == 'CategoryAndItemsSalesStats'
                  ? salesItemsStatsTable()
                  : SizedBox.shrink(),
              reportsName == 'CategoryAndItemsSalesStats'
                  ? Divider(thickness: 2)
                  : SizedBox.shrink(),
              (reportsName == 'ExtraItemsSalesStats' && mapOne.isNotEmpty)
                  ? salesExtraItemsStatsTable()
                  : SizedBox.shrink(),
              (reportsName == 'ExtraItemsSalesStats' && mapOne.isNotEmpty)
                  ? Divider(thickness: 2)
                  : SizedBox.shrink(),
              (reportsName == 'CaptainOrdersTakenStats' && mapOne.isNotEmpty)
                  ? captainOrdersTakenStatsTable()
                  : SizedBox.shrink(),
              (reportsName == 'CaptainOrdersTakenStats' && mapOne.isNotEmpty)
                  ? Divider(thickness: 2)
                  : SizedBox.shrink(),
              (reportsName == 'CaptainOrdersTakenStats' && mapTwo.isNotEmpty)
                  ? captainIndividualItemsStatsTable()
                  : SizedBox.shrink(),
              (reportsName == 'CaptainOrdersTakenStats' && mapTwo.isNotEmpty)
                  ? Divider(thickness: 2)
                  : SizedBox.shrink(),
              reportsName == 'ExpenseCategoryStats'
                  ? expensesCategoriesStatsTable()
                  : SizedBox.shrink(),
              reportsName == 'ExpenseCategoryStats'
                  ? Divider(thickness: 2)
                  : SizedBox.shrink(),
              (reportsName == 'ExpensePaidByUserStats' && mapOne.isNotEmpty)
                  ? expensePaidByUserAmountBaseStatsTable()
                  : SizedBox.shrink(),
              (reportsName == 'ExpensePaidByUserStats' && mapOne.isNotEmpty)
                  ? Divider(thickness: 2)
                  : SizedBox.shrink(),
              (reportsName == 'ExpensePaidByUserStats' && mapTwo.isNotEmpty)
                  ? expensePaidByUserPaymentMethodTable()
                  : SizedBox.shrink(),
              (reportsName == 'ExpensePaidByUserStats' && mapTwo.isNotEmpty)
                  ? Divider(thickness: 2)
                  : SizedBox.shrink(),
              reportsName == 'ExpensePaymentMethodStats'
                  ? expensesPaymentMethodStatsTable()
                  : SizedBox.shrink(),
              (reportsName == 'CancelledIndividualItemsStats' &&
                      mapOne.isNotEmpty)
                  ? Text('Closed Bills',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                  : SizedBox.shrink(),
              (reportsName == 'CancelledIndividualItemsStats' &&
                      mapOne.isNotEmpty)
                  ? billedCancelledIndividualItemsStatsTable()
                  : SizedBox.shrink(),
              (reportsName == 'CancelledIndividualItemsStats' &&
                      mapOne.isNotEmpty)
                  ? Divider(thickness: 2)
                  : SizedBox.shrink(),
              (reportsName == 'CancelledIndividualItemsStats' &&
                      mapTwo.isNotEmpty)
                  ? Text('Non Closed Bills',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold))
                  : SizedBox.shrink(),
              (reportsName == 'CancelledIndividualItemsStats' &&
                      mapTwo.isNotEmpty)
                  ? nonBilledCancelledIndividualItemsStatsTable()
                  : SizedBox.shrink(),
              (reportsName == 'CancelledIndividualItemsStats' &&
                      mapTwo.isNotEmpty)
                  ? Divider(thickness: 2)
                  : SizedBox.shrink(),
              (reportsName == 'CaptainCancellationStats')
                  ? captainCancellationReports()
                  : SizedBox.shrink(),
              (reportsName == 'CaptainCancellationStats')
                  ? Divider(thickness: 2)
                  : SizedBox.shrink(),
              (reportsName == 'ChefRejectionStats')
                  ? chefRejectionReports()
                  : SizedBox.shrink(),
              (reportsName == 'ChefRejectionStats')
                  ? Divider(thickness: 2)
                  : SizedBox.shrink(),
            ],
          ),
        ));
  }
}
