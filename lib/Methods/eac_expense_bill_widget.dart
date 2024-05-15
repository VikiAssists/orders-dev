import 'package:flutter/material.dart';
import 'package:orders_dev/constants.dart';

class EachExpenseBill extends StatelessWidget {
  final Map eachBillMap;
  final Function editBill;
  // final Map editFunctionInputMap;

  const EachExpenseBill({
    Key? key,
    required this.eachBillMap,
    required this.editBill,
    // required this.editFunctionInputMap
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String dateOfBill(String dateInBillMap) {
      final dateSplit = dateInBillMap.split('*');
      return '${dateSplit[2]}-${dateSplit[1]}-${dateSplit[0]}';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.black,
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text('${dateOfBill(eachBillMap['date'])}'),
              Text(
                  'Bill ID: ${eachBillMap['expenseBillId'].toString().substring(11, 16)}'),
              IconButton(
                  onPressed: () {
                    editBill(eachBillMap);
                  },
                  icon: Icon(Icons.edit, color: Colors.green))
            ],
          ),
          DataTable(columns: [
            DataColumn(label: Text('Item')),
            DataColumn(label: Text('${eachBillMap['category']}')),
          ], rows: [
            DataRow(cells: [
              DataCell(
                Text('Expense/Income:'),
              ),
              DataCell(
                Text('${eachBillMap['expenseOrIncome']}'),
              )
            ]),
            DataRow(cells: [
              DataCell(
                Text('Entered By:'),
              ),
              DataCell(
                Text('${eachBillMap['username']}'),
              )
            ]),
            DataRow(cells: [
              DataCell(
                Text('Paid By:'),
              ),
              DataCell(
                Text('${eachBillMap['paidBy']}'),
              )
            ]),
            DataRow(cells: [
              DataCell(
                Text('Payment Method:'),
              ),
              DataCell(
                Text('${eachBillMap['paymentMethod']}'),
              )
            ]),
            if ('${eachBillMap['vendor']}' != '')
              DataRow(cells: [
                DataCell(
                  Text('Vendor'),
                ),
                DataCell(
                  Text('${eachBillMap['vendor']}'),
                )
              ]),
            if ('${eachBillMap['description']}' != '')
              DataRow(cells: [
                DataCell(
                  Text('Description'),
                ),
                DataCell(
                  Text('${eachBillMap['description']}'),
                )
              ]),
            if ('${eachBillMap['unitPrice']}' != '')
              DataRow(cells: [
                DataCell(
                  Text('Unit Price'),
                ),
                DataCell(
                  Text('${eachBillMap['unitPrice']}'),
                )
              ]),
            if ('${eachBillMap['numberOfUnits']}' != '')
              DataRow(cells: [
                DataCell(
                  Text('Number of Units'),
                ),
                DataCell(
                  Text('${eachBillMap['numberOfUnits']}'),
                )
              ]),
            if ('${eachBillMap['cgstPercentage']}' != '')
              DataRow(cells: [
                DataCell(
                  Text('CGST%'),
                ),
                DataCell(
                  Text('${eachBillMap['cgstPercentage']}'),
                )
              ]),
            if ('${eachBillMap['cgstValue']}' != '')
              DataRow(cells: [
                DataCell(
                  Text('CGST Value'),
                ),
                DataCell(
                  Text('₹${eachBillMap['cgstValue']}'),
                )
              ]),
            if ('${eachBillMap['sgstPercentage']}' != '')
              DataRow(cells: [
                DataCell(
                  Text('SGST%'),
                ),
                DataCell(
                  Text('${eachBillMap['sgstPercentage']}'),
                )
              ]),
            if ('${eachBillMap['sgstValue']}' != '')
              DataRow(cells: [
                DataCell(
                  Text('SGST Value'),
                ),
                DataCell(
                  Text('₹${eachBillMap['sgstValue']}'),
                )
              ]),
            DataRow(cells: [
              DataCell(
                Text('Total Price'),
              ),
              DataCell(
                Text('₹${eachBillMap['totalPrice']}'),
              )
            ]),
          ]),
        ],
      ),
    );
  }
}
