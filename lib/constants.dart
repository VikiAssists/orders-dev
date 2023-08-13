import 'package:flutter/material.dart';

var kTextFieldInputDecoration = InputDecoration(
    filled: true,
    fillColor: Colors.green.shade500,
    hintText: 'Enter Restaurant Name',
    hintStyle: TextStyle(color: Colors.white),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(20.0)),
        borderSide: BorderSide.none));

const kSnackbarMessageSize = 20.0;

const kBottomContainerHeight = 80.0;
//DeclaringColorsUsedInsideInTheTopItself
var kBottomContainerColour = Colors.red.shade500;
//Color(0xFFEB1555); //pink
const kLargeButtonTextStyle =
    TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Colors.white);

const kAppBarTextStyle = TextStyle(
    color: Colors.black,
    fontStyle: FontStyle.italic,
    fontWeight: FontWeight.w900);

const kMenuBarPopUpMenuButtonTextStyle = TextStyle(
  color: Colors.black,
  fontSize: 20.0,
);

const userInfoTextStyle =
    TextStyle(fontWeight: FontWeight.w500, color: Colors.green);

const kAppBarBackgroundColor = Colors.white70;

const kAppBarBackIconColor = Colors.black;

var kMenuAddButtonDecoration = BoxDecoration(
  color: Colors.green.shade50,
  borderRadius: BorderRadius.circular(5),
  border: Border.all(
    color: Colors.green.shade500,
    width: 1.5,
  ),
);

var kMenuStatisticsContainerDecoration = BoxDecoration(
  color: Colors.white54,
//  borderRadius: BorderRadius.circular(5),
  border: Border.all(
    color: Colors.black87,
    width: 0.1,
  ),
);

const double kMenuButtonHeight = 40;

const double kMenuButtonWidth = 135;

var kMenuContainerTileDecoration = BoxDecoration(
  borderRadius: BorderRadius.circular(5),
  border: Border.all(
    color: Colors.black87,
    width: 1.0,
  ),
);

var kAddButtonNumberTextStyle =
    TextStyle(color: Colors.green.shade500, fontSize: 20.0);

var kAddButtonWordTextStyle =
    TextStyle(color: Colors.green.shade500, fontSize: 15.0);

const kAddMinusButtonIconSize = 20.0;

const kCustomerWaitingTime = 30;
