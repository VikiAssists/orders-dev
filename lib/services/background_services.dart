import 'dart:async';
import 'dart:collection';

import 'package:audioplayers/audioplayers.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:orders_dev/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:orders_dev/Methods/printerenum.dart' as printerenum;
import 'package:orders_dev/services/firestore_services.dart';

class BackgroundCheck {
  final player = AudioPlayer();
  PlayerState playerState = PlayerState.stopped;
  bool playerPlaying = false;
  bool someNewItemsOrdered = false;
  //WhateverIsUpAreElementsThatAreTemporaryUsed

//WhateverIsDownAreElementsThatAreSavedAndReused
  String currentHotelNameOfUserInBackground = '';
  bool unavailableItemsChangedTrueElseFalseInBackground = false;
  bool insideCaptainScreenTrueElseFalseInBackground = false;
  bool insideChefScreenTrueElseFalseInBackground = false;
  bool tokenNumberUpdatedTrueElseFalseInBackground = false;
  bool profileUpdatedTrueElseFalseInBackground = false;
  bool userDeletedTrueElseFalseInBackground = false;
  bool menuUpdatedTrueElseFalseInBackground = false;
  bool restaurantInfoUpdatedTrueElseFalseInBackground = false;

  BackgroundCheck() {
    initialState();
  }

  void initialState() {
    syncDataOfBackground();
  }

  void saveHotelNameInBackground(String hotelName) {
    currentHotelNameOfUserInBackground = hotelName;
    updateRestaurantChosenSharedPreferencesInBackground();
  }

  Future updateRestaurantChosenSharedPreferencesInBackground() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString(
        'restaurantChosenByUserSaving', currentHotelNameOfUserInBackground);
  }

  Future<String> returnSavedHotelNameFromBackgroundClass() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var restaurantChosenResult =
        prefs.getString('restaurantChosenByUserSaving');

    if (restaurantChosenResult != null) {
      currentHotelNameOfUserInBackground = restaurantChosenResult;
    }
    return currentHotelNameOfUserInBackground;
  }

  void saveTokenNumberUpdateInBackground(
      {required String hotelNameOfMessage,
      required bool tokenUpdatedTrueNotedFalse}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var restaurantChosenResult =
        prefs.getString('restaurantChosenByUserSaving');
    if (restaurantChosenResult != null) {
      currentHotelNameOfUserInBackground = restaurantChosenResult;
    }
//ThisWillCallInBackgroundWhenChefSpecialityWasChangedBut
//UserWasInBackground
//OnceUserNoted,HeCanChangeItToFalse
    if (currentHotelNameOfUserInBackground == hotelNameOfMessage) {
      tokenNumberUpdatedTrueElseFalseInBackground = tokenUpdatedTrueNotedFalse;
    }
    updateTokenNumberUpdatedSharedPreferencesInBackground();
  }

  Future updateTokenNumberUpdatedSharedPreferencesInBackground() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setBool('tokenNumberChangedSaving',
        tokenNumberUpdatedTrueElseFalseInBackground);
  }

  Future<bool> returnTokenNumberChangedFromBackgroundClass() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var tokenNumberChangedOrNotResult =
        await prefs.getBool('tokenNumberChangedSaving');
    if (tokenNumberChangedOrNotResult != null) {
      tokenNumberUpdatedTrueElseFalseInBackground =
          tokenNumberChangedOrNotResult;
    }
    return tokenNumberUpdatedTrueElseFalseInBackground;
  }

  void saveProfileUpdateInBackground(
      {required String hotelNameOfMessage,
      required bool profileUpdatedTrueNotedFalse}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var restaurantChosenResult =
        prefs.getString('restaurantChosenByUserSaving');
    if (restaurantChosenResult != null) {
      currentHotelNameOfUserInBackground = restaurantChosenResult;
    }
//ThisWillCallInBackgroundWhenChefSpecialityWasChangedBut
//UserWasInBackground
//OnceUserNoted,HeCanChangeItToFalse
    if (currentHotelNameOfUserInBackground == hotelNameOfMessage) {
      profileUpdatedTrueElseFalseInBackground = profileUpdatedTrueNotedFalse;
    }
    updateProfileUpdatedSharedPreferencesInBackground();
  }

  Future updateProfileUpdatedSharedPreferencesInBackground() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
        'profileChangedSaving', profileUpdatedTrueElseFalseInBackground);
  }

  Future<bool> returnProfileChangedFromBackgroundClass() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var profileChangedOrNotResult = await prefs.getBool('profileChangedSaving');
    if (profileChangedOrNotResult != null) {
      profileUpdatedTrueElseFalseInBackground = profileChangedOrNotResult;
    }
    return profileUpdatedTrueElseFalseInBackground;
  }

  void saveMenuUpdateInBackground(
      {required String hotelNameOfMessage,
      required bool menuUpdatedTrueNotedFalse}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var restaurantChosenResult =
        prefs.getString('restaurantChosenByUserSaving');
    if (restaurantChosenResult != null) {
      currentHotelNameOfUserInBackground = restaurantChosenResult;
    }
//ThisWillCallInBackgroundWhenChefSpecialityWasChangedBut
//UserWasInBackground
//OnceUserNoted,HeCanChangeItToFalse
    if (currentHotelNameOfUserInBackground == hotelNameOfMessage) {
      menuUpdatedTrueElseFalseInBackground = menuUpdatedTrueNotedFalse;
    }
    updateMenuUpdatedSharedPreferencesInBackground();
  }

  Future updateMenuUpdatedSharedPreferencesInBackground() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
        'menuChangedSaving', menuUpdatedTrueElseFalseInBackground);
  }

  Future<bool> returnMenuChangedFromBackgroundClass() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var menuChangedOrNotResult = await prefs.getBool('menuChangedSaving');
    if (menuChangedOrNotResult != null) {
      menuUpdatedTrueElseFalseInBackground = menuChangedOrNotResult;
    }
    return menuUpdatedTrueElseFalseInBackground;
  }

  void saveRestaurantInfoUpdateInBackground(
      {required String hotelNameOfMessage,
      required bool restaurantInfoUpdatedTrueNotedFalse}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var restaurantChosenResult =
        prefs.getString('restaurantChosenByUserSaving');
    if (restaurantChosenResult != null) {
      currentHotelNameOfUserInBackground = restaurantChosenResult;
    }
//ThisWillCallInBackgroundWhenChefSpecialityWasChangedBut
//UserWasInBackground
//OnceUserNoted,HeCanChangeItToFalse
    if (currentHotelNameOfUserInBackground == hotelNameOfMessage) {
      restaurantInfoUpdatedTrueElseFalseInBackground =
          restaurantInfoUpdatedTrueNotedFalse;
    }
    updateRestaurantInfoUpdatedSharedPreferencesInBackground();
  }

  Future updateRestaurantInfoUpdatedSharedPreferencesInBackground() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setBool('restaurantInfoChangedSaving',
        restaurantInfoUpdatedTrueElseFalseInBackground);
  }

  Future<bool> returnRestaurantInfoChangedFromBackgroundClass() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var restaurantInfoChangedOrNotResult =
        await prefs.getBool('restaurantInfoChangedSaving');
    if (restaurantInfoChangedOrNotResult != null) {
      restaurantInfoUpdatedTrueElseFalseInBackground =
          restaurantInfoChangedOrNotResult;
    }
    return restaurantInfoUpdatedTrueElseFalseInBackground;
  }

  void saveUserDeletedInBackground(
      {required String hotelNameOfMessage,
      required bool userDeletedTrueNotedFalse}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var restaurantChosenResult =
        prefs.getString('restaurantChosenByUserSaving');
    if (restaurantChosenResult != null) {
      currentHotelNameOfUserInBackground = restaurantChosenResult;
    }
//ThisWillCallInBackgroundWhenChefSpecialityWasChangedBut
//UserWasInBackground
//OnceUserNoted,HeCanChangeItToFalse
    if (currentHotelNameOfUserInBackground == hotelNameOfMessage) {
      userDeletedTrueElseFalseInBackground = userDeletedTrueNotedFalse;
    }
    updateUserDeletedSharedPreferencesInBackground();
  }

  Future updateUserDeletedSharedPreferencesInBackground() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
        'userDeletedSaving', userDeletedTrueElseFalseInBackground);
  }

  Future<bool> returnUserDeletedFromBackgroundClass() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var userDeletedOrNotResult = await prefs.getBool('userDeletedSaving');
    if (userDeletedOrNotResult != null) {
      userDeletedTrueElseFalseInBackground = userDeletedOrNotResult;
    }
    return userDeletedTrueElseFalseInBackground;
  }

//ToRegisterWeAreInsideCaptainScreen
  void saveInsideCaptainScreenChangingInBackground(
      {required bool insideCaptainScreenTrueElseFalse}) async {
    insideCaptainScreenTrueElseFalseInBackground =
        insideCaptainScreenTrueElseFalse;

    updateInsideCaptainScreenSharedPreferencesInBackground();
  }

  Future updateInsideCaptainScreenSharedPreferencesInBackground() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setBool('insideCaptainScreenSaving',
        insideCaptainScreenTrueElseFalseInBackground);
  }

  //ToRegisterWeAreInsideChefScreen
  void saveInsideChefScreenChangingInBackground(
      {required bool insideChefScreenTrueElseFalse}) async {
    insideChefScreenTrueElseFalseInBackground = insideChefScreenTrueElseFalse;

    updateInsideChefScreenSharedPreferencesInBackground();
  }

  Future updateInsideChefScreenSharedPreferencesInBackground() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setBool(
        'insideChefScreenSaving', insideChefScreenTrueElseFalseInBackground);
  }

  Future syncDataOfBackground() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var restaurantChosenResult =
        prefs.getString('restaurantChosenByUserSaving');
    var insideCaptainScreenSavingResult =
        await prefs.getBool('insideCaptainScreenSaving');
    var insideChefScreenSavingResult =
        await prefs.getBool('insideChefScreenSaving');
    var tokenNumberChangedOrNotResult =
        await prefs.getBool('tokenNumberChangedSaving');
    var profileChangedOrNotResult = await prefs.getBool('profileChangedSaving');

    var userDeletedOrNotResult = await prefs.getBool('userDeletedSaving');

    var menuChangedOrNotResult = await prefs.getBool('menuChangedSaving');

    var restaurantInfoChangedOrNotResult =
        await prefs.getBool('restaurantInfoChangedSaving');

    if (restaurantChosenResult != null) {
      currentHotelNameOfUserInBackground = restaurantChosenResult;
    }
    if (insideCaptainScreenSavingResult != null) {
      insideCaptainScreenTrueElseFalseInBackground =
          insideCaptainScreenSavingResult;
    }
    if (insideChefScreenSavingResult != null) {
      insideChefScreenTrueElseFalseInBackground = insideChefScreenSavingResult;
    }

    if (tokenNumberChangedOrNotResult != null) {
      tokenNumberUpdatedTrueElseFalseInBackground =
          tokenNumberChangedOrNotResult;
    }
    if (profileChangedOrNotResult != null) {
      profileUpdatedTrueElseFalseInBackground = profileChangedOrNotResult;
    }
    if (userDeletedOrNotResult != null) {
      userDeletedTrueElseFalseInBackground = userDeletedOrNotResult;
    }

    if (menuChangedOrNotResult != null) {
      menuUpdatedTrueElseFalseInBackground = menuChangedOrNotResult;
    }

    if (restaurantInfoChangedOrNotResult != null) {
      restaurantInfoUpdatedTrueElseFalseInBackground =
          restaurantInfoChangedOrNotResult;
    }
  }

  void captainAlertsCheckInBackground(
      {required String hotelNameOfMessage}) async {
    await Firebase.initializeApp();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var restaurantChosenResult =
        prefs.getString('restaurantChosenByUserSaving');
    var insideCaptainScreenTrueElseFalseResult =
        prefs.getBool('insideCaptainScreenSaving');
    if (restaurantChosenResult != null) {
      currentHotelNameOfUserInBackground = restaurantChosenResult;
    }
    if (insideCaptainScreenTrueElseFalseResult != null) {
      insideCaptainScreenTrueElseFalseInBackground =
          insideCaptainScreenTrueElseFalseResult;
    }

//IfHotelNameIsSameAndIfUserIsInCaptainScreen,ThenWeExecuteIt
    if ((currentHotelNameOfUserInBackground == hotelNameOfMessage) &&
        insideCaptainScreenTrueElseFalseInBackground) {
      final presentOrdersCheck = await FirebaseFirestore.instance
          .collection(currentHotelNameOfUserInBackground)
          .doc('runningorders')
          .collection('runningorders')
          .where('statusMap.${'captainStatus'}', isGreaterThanOrEqualTo: 10)
          .get();
//InsideEachDoc,ThereIsStatusMapWhereWeHaveCaptainStatus
//WeAreCheckingOnlyReadyItems
      bool someItemRejected = false;
      bool someItemReady = false;

      //WeCheckEachOrder&CheckSomethingIsRejected-IfYes,SomeItemRejectedToTrue,,
//andSomeItemReadyToFalse
      num i = 0;
      for (var eachOrder in presentOrdersCheck.docs) {
        i++;
        if (eachOrder['statusMap']['captainStatus'] == 11) {
          someItemRejected = true;
        } else if (eachOrder['statusMap']['captainStatus'] == 10 &&
            someItemRejected == false) {
          someItemReady = true;
        }
        if (i == presentOrdersCheck.size) {
          if (someItemRejected) {
            playRejectedInBackground();
          } else if (someItemReady) {
            playCaptainInBackground();
          }
        }
      }
    }
  }

  void chefAlertsCheckInBackground({required String hotelNameOfMessage}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var restaurantChosenResult =
        prefs.getString('restaurantChosenByUserSaving');
    var insideChefScreenTrueElseFalseResult =
        prefs.getBool('insideChefScreenSaving');

    if (restaurantChosenResult != null) {
      currentHotelNameOfUserInBackground = restaurantChosenResult;
    }
    if (insideChefScreenTrueElseFalseResult != null) {
      insideChefScreenTrueElseFalseInBackground =
          insideChefScreenTrueElseFalseResult;
    }

//IfHotelNameIsSameAndIfUserIsInCaptainScreen,ThenWeExecuteIt
    if ((currentHotelNameOfUserInBackground == hotelNameOfMessage) &&
        insideChefScreenTrueElseFalseInBackground) {
      // playCookTrimInBackground();
      // NotificationService().showNotification(
      //     title: 'Orders', body: 'We are looking for Updates');
    }
  }

  void playCaptainInBackground() async {
//IfOrderIsReady,PlayTuneWithPlay-ItIsAnAssetSource-SoWeNeedToPutItIn
    if (!playerPlaying) {
      await player.play(AssetSource('audio/captain_orders.mp3'));
      playerState = PlayerState.playing;
      playerPlaying = true;
//OnceCompletedWeChangeItToCompleted
      player.onPlayerComplete.listen((event) {
        playerState = PlayerState.completed;
        playerPlaying = false;
      });
    }
  }

  void playRejectedInBackground() async {
//IfOrderIsRejected,PlayTuneWithPlay-ItIsAnAssetSource-SoWeNeedToPutItIn
    if (!playerPlaying) {
      await player.play(AssetSource('audio/rejected_orders.mp3'));
      playerState = PlayerState.playing;
      playerPlaying = true;
//OnceCompletedWeChangeItToCompleted
      player.onPlayerComplete.listen((event) {
        playerState = PlayerState.completed;
        playerPlaying = false;
      });
    }
  }

  void playStopInBackground() async {
//IfOrderIsRejected,PlayTuneWithPlay-ItIsAnAssetSource-SoWeNeedToPutItIn
    if (playerPlaying) {
      await player.stop();
      playerPlaying = false;
    }
  }
}
