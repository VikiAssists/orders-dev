import 'package:flutter/material.dart';

class TableButton extends StatelessWidget {
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
  final String tableOrParcel;
  final num tableOrParcelNumber;
  final double size;
  final Function() onPress;

  TableButton(
      {Key? key,
      required this.textColor,
      required this.backgroundColor,
      required this.borderColor,
      required this.tableOrParcel,
      required this.tableOrParcelNumber,
      required this.size,
      required this.onPress})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(5, 5, 5, 5),
      width: size * 1.8,
      height: size * 2,
      child: Center(
        child: TextButton(
          onPressed: onPress,
          child: Text(
            '${tableOrParcelNumber.toString()}',
//BelowWasTheInitialWayWhereWePutAsTable1.NowSimplyShowingAs 1 Alone
            // '$tableOrParcel\n    ${tableOrParcelNumber.toString()}',
            style: TextStyle(color: textColor),
          ),
        ),
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
      ),
    );
  }
}
