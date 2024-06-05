import 'package:flutter/material.dart';
import 'package:orders_dev/constants.dart';

class EachSalesBill extends StatelessWidget {
  //FromOrderHistoryScreenClassWeGetThisData
  //EachBillIsGivenAsMap

  final Map eachOrderMap;
  final String eachOrderId;

  const EachSalesBill(
      {Key? key, required this.eachOrderMap, required this.eachOrderId})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    //ReturnItemsIsTheMethod/FunctionToSeparateTheBillIntoItsContents
    List<Row> returnItems() {
      //ThisListOfTypeRowsIsWhereWeWillHaveAllTheItemsWithItsPricesAnd
      //WeWillReturnToTheColumnBelow
      List<Row> itemsInRows = [];
      //ThisItemsInRowsWillHaveToHaveAllTheOrderedItemsAndTheTotal
      //WeAssignThisToTemporaryMapWhichWeCanWorkWith
      Map temporaryMap = eachOrderMap;
      //SinceWeHaveAlreadyTakenTheDateOfOrder,WeCanRemoveTheDateOfOrder,
      //WeNeedOnlyTheOrderedItems&Total
      temporaryMap.remove(' Date of Order  :');
      temporaryMap.remove('statisticsDocID');
      temporaryMap.remove('hotelNameForPrint');
      temporaryMap.remove('phoneNumberForPrint');
      temporaryMap.remove('addressline1ForPrint');
      temporaryMap.remove('addressline2ForPrint');
      temporaryMap.remove('addressline3ForPrint');
      temporaryMap.remove('gstcodeforprint');
      temporaryMap.remove('customerNameForPrint');
      temporaryMap.remove('customerMobileForPrint');
      temporaryMap.remove('customerAddressForPrint');
      temporaryMap.remove('dateForPrint');
      temporaryMap.remove('serialNumberForPrint');
      temporaryMap.remove('totalNumberOfItemsForPrint');
      temporaryMap.remove('billNumberForPrint');
      temporaryMap.remove('takeAwayOrDineInForPrint');
      temporaryMap.remove('distinctItemsForPrint');
      temporaryMap.remove('individualPriceOfEachDistinctItemForPrint');
      temporaryMap.remove('numberOfEachDistinctItemForPrint');
      temporaryMap.remove('priceOfEachDistinctItemWithoutTotalForPrint');
      temporaryMap.remove('extraItemsDistinctNames');
      temporaryMap.remove('extraItemsDistinctNumbers');
      temporaryMap.remove('totalQuantityForPrint');
      temporaryMap.remove('discount');
      temporaryMap.remove('discountEnteredValue');
      temporaryMap.remove('discountValueClickedTruePercentageClickedFalse');
      temporaryMap.remove('subTotalForPrint');
      temporaryMap.remove('cgstPercentageForPrint');
      temporaryMap.remove('cgstCalculatedForPrint');
      temporaryMap.remove('sgstPercentageForPrint');
      temporaryMap.remove('sgstCalculatedForPrint');
      temporaryMap.remove('roundOff');
      temporaryMap.remove('grandTotalForPrint');
      temporaryMap.remove('billedItemsInOrder');
      temporaryMap.remove('cancelledItemsInOrder');
      temporaryMap.remove('orderClosingCaptainName');
      temporaryMap.remove('orderClosingCaptainPhone');
      temporaryMap.remove('serialNumberNum');

      //WeSortItemNamesToAList.SinceWeSaveItWithNumbers,WeCanUseSort
      List itemNames = temporaryMap.keys.toList()..sort();
      //List<String> itemNames = [];
      //ThoughWeHadNamedItItemNumbers,ItsActuallyItemPrice
      //usingTheKeys,WePutItAllInsideList
      List<String> itemNumbers = [];
      for (int k = 0; k < itemNames.length; k++) {
        itemNumbers.add(temporaryMap[itemNames[k]]);
      }
//      temporaryMap.forEach((key, value) {
//        itemNames.add(key);
//        itemNumbers.add(value);
//      });
      //ThenInsideListOfTypeRows,WePutEachItemAndEachPrice
      for (int i = 0; i < itemNames.length; i++) {
        String itemName = '';
//InOrderHistoryMap,ForDiscountToTotalBillWithTaxesIHaveAddedA *
//ToRemoveIt, * RemovingCodeNeedsToBeAdded
        if (itemNames[i].contains('*')) {
          final itemSplit = itemNames[i].toString().split('*');
          itemName = itemSplit[1];
        } else {
          itemName = itemNames[i];
        }
        itemsInRows.add(Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              itemName,
              style: TextStyle(fontSize: 10.0),
            ),
            Text(itemNumbers[i])
          ],
        ));
      }
      //finallyWeReturnThisRows
      return itemsInRows;
    }

    return Container(
      //ThisIsTheContainerInWhichEachBillIsShown
      //WeDecorateItBelow
      padding: EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.black,
          width: 1.0,
        ),
      ),
      //AsColumn,OrderIdIsShownFirst
      //EachOrderMapHasDateOfOrderAsOneAmongTheFields
      //SoWeCanStraightAwayAccessIt
      //InTheReturnItemsMethodAbove,WeSegregateTheItems

      child: Column(
        children: [
          Text('Order Id  : ${eachOrderId.substring(0, 14)}'),
          Text('Date:  ${eachOrderMap['dateForPrint']}'),
          eachOrderMap['serialNumberForPrint'] != null
              ? Text('Sl.No: ${eachOrderMap['serialNumberForPrint']}')
              : SizedBox.shrink(),
          eachOrderMap['orderClosingCaptainName'] != null
              ? Text('Closed By: ${eachOrderMap['orderClosingCaptainName']}')
              : SizedBox.shrink(),
          Text('${eachOrderMap['takeAwayOrDineInForPrint']}'),
          ...returnItems(),
        ],
      ),
    );
  }
}
