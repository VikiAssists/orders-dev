import 'package:flutter/material.dart';
import 'package:orders_dev/constants.dart';

//makingThisButtonForManyScreensBottomButtonLikePrint
class BottomButton extends StatelessWidget {
  //constructorsFOrFunction&ButtonTitle
  //soThatICanCallEachButtonWithTheseConstructors
  final Function onTap;
  final String buttonTitle;
  double? buttonWidth;
  final Color buttonColor;

  BottomButton(
      {required this.onTap,
      required this.buttonTitle,
      this.buttonWidth,
      required this.buttonColor});
  //ButtonWidthAloneNotAlwaysNeeded.ItWillStretchEntireScreenMostly
  //OnlyIfWeNeedTwoButtonsAtTheBottom,ThisWillBeNeeded.NotDeclaredFinalEither

  @override
  Widget build(BuildContext context) {
    //WrappingWithGestureDetectorSoThatWeCanGiveOnTapFunction
    return GestureDetector(
      onTap: () {
        onTap();
      },
      child: Container(
        child: Center(child: Text(buttonTitle, style: kLargeButtonTextStyle)),
//        margin: const EdgeInsets.only(top: 1), //MarginOnlyInTop
//        padding: const EdgeInsets.only(bottom: 1.0), //toAvoidBeingTooBottom

        width: buttonWidth, //ToStretchTheEntireWidthOfScreen
        height: kBottomContainerHeight, //DeclaredInTop
        decoration: BoxDecoration(
          //toGiveCircularRadiusToTheButton
          borderRadius: BorderRadius.circular(20.0),
          color: buttonColor,
          boxShadow: [
            //toGiveShadowEffectToTheButton
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
//              spreadRadius: 5,
//              blurRadius: 7,
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
      ),
    );
  }
}
