import 'package:flutter/material.dart';

class SplitButton extends StatelessWidget {
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
  final String tableOrParcel;

  final double size;
  final Function() onPress;

  SplitButton({
    Key? key,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.tableOrParcel,
    required this.size,
    required this.onPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(5, 5, 5, 5),
      width: size * 1.8,
      height: size * 2,
      child: TextButton(
        onPressed: onPress,
        child: Center(
          child: Text(
            '$tableOrParcel',
            style: TextStyle(color: textColor, fontSize: 20),
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
