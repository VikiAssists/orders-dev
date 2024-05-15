import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';

class PrinterAndOtherDetailsProvider extends ChangeNotifier {
  String chosenRestaurantDatabaseFromClass =
      ''; //ThisIsTheRestaurantTheUserHasLastSignedIn
  String captainPrinterNameFromClass = '';
  String captainPrinterAddressFromClass = '';
  String captainPrinterSizeFromClass = '0';
  String chefPrinterNameFromClass = '';
  String chefPrinterAddressFromClass = '';
  String chefPrinterSizeFromClass = '0';
  bool chefPrinterKOTFromClass = false;
  bool chefPrinterAfterOrderReadyPrintFromClass = false;
  int spacesAboveKotFromClass = 0;
  int spacesBelowKotFromClass = 0;
  String kotFontSizeFromClass = 'Small';
  String savedPrintersFromClass = '';
  String kotAssignedPrintersFromClass = '{}';
  String billingAssignedPrinterFromClass = '{}';
  String chefAssignedPrinterFromClass = '{}';
  bool chefInstructionsVideoPlayedFromClass = false;
  bool captainInsideTableInstructionsVideoPlayedFromClass = false;
  bool menuOrRestaurantInfoUpdatedFromClass =
      false; //ToRegisterSomethingHasBeenUpdated
  String allUserProfilesFromClass = '';
  String allUserTokensFromClass = '';
  String entireMenuFromClass = '';
  String currentUserPhoneNumberFromClass = '';
  String restaurantInfoDataFromClass = '';
  String versionOfAppFromClass = '';
  bool experimentForBluetooth = false;
  int expensesSegregationDeviceSavedTimestampFromClass = 0;
  String expensesSegregationMapFromClass = '{}';

  PrinterAndOtherDetailsProvider() {
    initialState();
  }

  void initialState() {
    syncDataWithProvider();
  }

  void saveCurrentUserPhoneNumber(String userPhoneNumber) {
    currentUserPhoneNumberFromClass = userPhoneNumber;

    updateCurrentUserPhoneNumberSharedPreferences();
    notifyListeners();
  }

  Future updateCurrentUserPhoneNumberSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // await prefs.setStringList('firstPrinter', firstPrinterSavingVersion);

    await prefs.setString(
        'currentUserPhoneNumberSaving', currentUserPhoneNumberFromClass);
  }

  void restaurantChosenByUser(String restaurantDatabaseName) {
    chosenRestaurantDatabaseFromClass = restaurantDatabaseName;

    updateRestaurantChosenSharedPreferences();
    notifyListeners();
  }

  Future updateRestaurantChosenSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // await prefs.setStringList('firstPrinter', firstPrinterSavingVersion);

    await prefs.setString(
        'restaurantChosenByUserSaving', chosenRestaurantDatabaseFromClass);
  }

  void saveRestaurantInfo(String restaurantInfo) {
    restaurantInfoDataFromClass = restaurantInfo;

    updateRestaurantInfoSharedPreferences();
    notifyListeners();
  }

  Future updateRestaurantInfoSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString('restaurantInfoSaving', restaurantInfoDataFromClass);
  }

  void saveAllUserProfiles(String allUserProfile) {
    allUserProfilesFromClass = allUserProfile;

    updateAllUserProfileSharedPreferences();
    notifyListeners();
  }

  Future updateAllUserProfileSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // await prefs.setStringList('firstPrinter', firstPrinterSavingVersion);

    await prefs.setString('allUserProfileSaving', allUserProfilesFromClass);
  }

  void saveAllUserTokens(String allUserTokens) {
    allUserTokensFromClass = allUserTokens;

    updateAllUserTokensSharedPreferences();
    notifyListeners();
  }

  Future updateAllUserTokensSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString('allUserTokensSaving', allUserTokensFromClass);
  }

  void savingEntireMenuFromMap(String entireMenu) {
    entireMenuFromClass = entireMenu;

    updateEntireMenuSharedPreferences();
    notifyListeners();
  }

  Future updateEntireMenuSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString('entireMenuSaving', entireMenuFromClass);
  }

  void saveVersionOfApp(String appVersion) {
    versionOfAppFromClass = appVersion;
    updateVersionApp();
  }

  Future updateVersionApp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString('appVersionSaving', versionOfAppFromClass);
  }

  void savingPrintersAddedByTheUser(String stringOfMapOfAddedPrinters) {
    savedPrintersFromClass = stringOfMapOfAddedPrinters;
    updateSavedPrintersInSharedPreferences();
  }

  Future updateSavedPrintersInSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('addedPrintersSaving', savedPrintersFromClass);
  }

  void savingKotAssignedPrinterByTheUser(
      String stringOfMapOfKotAssignedPrinters) {
    kotAssignedPrintersFromClass = stringOfMapOfKotAssignedPrinters;
    updateKotAssignedPrintersInSharedPreferences();
  }

  Future updateKotAssignedPrintersInSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'kotAssignedPrintersSaving', kotAssignedPrintersFromClass);
  }

  void savingBillingAssignedPrinterByTheUser(
      String stringOfMapOfBillingAssignedPrinter) {
    billingAssignedPrinterFromClass = stringOfMapOfBillingAssignedPrinter;
    updateBillingAssignedPrinterInSharedPreferences();
  }

  Future updateBillingAssignedPrinterInSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'billingAssignedPrinterSaving', billingAssignedPrinterFromClass);
  }

  void savingChefAssignedPrinterByTheUser(
      String stringOfMapOfChefAssignedPrinter) {
    chefAssignedPrinterFromClass = stringOfMapOfChefAssignedPrinter;
    updateChefAssignedPrinterInSharedPreferences();
  }

  Future updateChefAssignedPrinterInSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'chefAssignedPrinterSaving', chefAssignedPrinterFromClass);
  }

  void addCaptainPrinter(String connectingPrinterName,
      String connectingPrinterAddress, String connectingPrinterSize) {
    captainPrinterNameFromClass = connectingPrinterName;
    captainPrinterAddressFromClass = connectingPrinterAddress;
    captainPrinterSizeFromClass = connectingPrinterSize;

    updateCaptainPrinterSharedPreferences();
    notifyListeners();
  }

  Future updateCaptainPrinterSharedPreferences() async {
    print('here $captainPrinterNameFromClass');
    // List<String> firstPrinterSavingVersion =
    //     firstPrinter.map((f) => json.encode(f.toJson())).toList();

    SharedPreferences prefs = await SharedPreferences.getInstance();

    // await prefs.setStringList('firstPrinter', firstPrinterSavingVersion);

    await prefs.setString(
        'captainPrinterNameSaving', captainPrinterNameFromClass);
    await prefs.setString(
        'captainPrinterAddressSaving', captainPrinterAddressFromClass);
    await prefs.setString(
        'captainPrinterSizeSaving', captainPrinterSizeFromClass);
  }

  void addChefPrinter(String connectingPrinterName,
      String connectingPrinterAddress, String connectingPrinterSize) {
    chefPrinterNameFromClass = connectingPrinterName;
    chefPrinterAddressFromClass = connectingPrinterAddress;
    chefPrinterSizeFromClass = connectingPrinterSize;

    updateChefPrinterSharedPreferences();
    notifyListeners();
  }

  Future updateChefPrinterSharedPreferences() async {
    // List<String> firstPrinterSavingVersion =
    //     firstPrinter.map((f) => json.encode(f.toJson())).toList();
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // await prefs.setStringList('firstPrinter', firstPrinterSavingVersion);

    await prefs.setString('chefPrinterNameSaving', chefPrinterNameFromClass);
    await prefs.setString(
        'chefPrinterAddressSaving', chefPrinterAddressFromClass);
    await prefs.setString('chefPrinterSizeSaving', chefPrinterSizeFromClass);
  }

  void neededOrNotChefKot(bool neededChefKotTrue) {
    chefPrinterKOTFromClass = neededChefKotTrue;
    updateChefKOTPreferenceInSharedPreferences();

    notifyListeners();
  }

  Future updateChefKOTPreferenceInSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        'chefPrinterKOTPreferenceSaving', chefPrinterKOTFromClass);
  }

  void neededOrNotChefAfterOrderReadyPrint(bool neededChefAfterOrderReadyTrue) {
    chefPrinterAfterOrderReadyPrintFromClass = neededChefAfterOrderReadyTrue;
    updateChefAfterOrderReadyPrintPreferenceInSharedPreferences();

    notifyListeners();
  }

  Future updateChefAfterOrderReadyPrintPreferenceInSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('chefPrinterAfterOrderReadyPrintPreferenceSaving',
        chefPrinterAfterOrderReadyPrintFromClass);
  }

  void kotOptionsSaving(
      int spacesAboveKot, int spacesBelowKot, String kotFontSize) {
    spacesAboveKotFromClass = spacesAboveKot;
    spacesBelowKotFromClass = spacesBelowKot;
    kotFontSizeFromClass = kotFontSize;

    updateKotOptionsInSharedPreferences();
    notifyListeners();
  }

  Future updateKotOptionsInSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setInt('spacesAboveKotSaving', spacesAboveKotFromClass);
    await prefs.setInt('spacesBelowKotSaving', spacesBelowKotFromClass);
    await prefs.setString('kotFontSizeSaving', kotFontSizeFromClass);
  }

  void chefVideoInstructionLookedOrNot(bool neededChefVideoPlayedOrNot) {
    chefInstructionsVideoPlayedFromClass = neededChefVideoPlayedOrNot;
    updateChefInstructionVideoPlayedOrNotInSharedPreferences();

    notifyListeners();
  }

  Future updateChefInstructionVideoPlayedOrNotInSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('chefInstructionVideoPlayedOrNotSaving',
        chefInstructionsVideoPlayedFromClass);
  }

  void captainInsideTableVideoInstructionLookedOrNot(
      bool neededCaptainVideoPlayedOrNot) {
    captainInsideTableInstructionsVideoPlayedFromClass =
        neededCaptainVideoPlayedOrNot;
    updateCaptainInTableInstructionVideoPlayedOrNotInSharedPreferences();

    notifyListeners();
  }

  Future
      updateCaptainInTableInstructionVideoPlayedOrNotInSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('captainInTableInstructionVideoPlayedOrNotSaving',
        captainInsideTableInstructionsVideoPlayedFromClass);
  }

  void menuOrRestaurantInfoUpdated(bool updatedTrueNotUpdatedFalse) {
//registeringThatSomethingHasBeenUpdated
    menuOrRestaurantInfoUpdatedFromClass = updatedTrueNotUpdatedFalse;

    notifyListeners();
  }

  // String expensesLastSavedTimestampFromClass = '';
  // String expensesSegregationMapFromClass = '{}';

  void expensesSegregationTimeStampSaving(
      int expensesTimeStamp, String expensesSegregation) {
    expensesSegregationDeviceSavedTimestampFromClass = expensesTimeStamp;
    expensesSegregationMapFromClass = expensesSegregation;

    updateExpensesSegregationTimeStampInSharedPreferences();
    notifyListeners();
  }

  Future updateExpensesSegregationTimeStampInSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setInt('expensesSegregationTimeStampSaving',
        expensesSegregationDeviceSavedTimestampFromClass);
    await prefs.setString(
        'expensesSegregationSaving', expensesSegregationMapFromClass);
  }

  Future syncDataWithProvider() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var bluetoothSaveResult = prefs.getBool('bluetoothExperimentSaving');

    var restaurantChosenResult =
        prefs.getString('restaurantChosenByUserSaving');

    var savedPrintersMapResult = prefs.getString('addedPrintersSaving');
    var kotAssignedPrinterMapResult =
        prefs.getString('kotAssignedPrintersSaving');

    var billingAssignedPrinterMapResult =
        prefs.getString('billingAssignedPrinterSaving');
    var chefAssignedPrinterMapResult =
        prefs.getString('chefAssignedPrinterSaving');

    var captainResultName = prefs.getString('captainPrinterNameSaving');
    var captainResultAddress = prefs.getString('captainPrinterAddressSaving');
    var captainResultSize = prefs.getString('captainPrinterSizeSaving');
    var chefResultName = prefs.getString('chefPrinterNameSaving');
    var chefResultAddress = prefs.getString('chefPrinterAddressSaving');
    var chefResultSize = prefs.getString('chefPrinterSizeSaving');
    var chefResultKOT = prefs.getBool('chefPrinterKOTPreferenceSaving');
    var chefResultAfterOrderPrint =
        prefs.getBool('chefPrinterAfterOrderReadyPrintPreferenceSaving');
    var spacesAboveKotResult = prefs.getInt('spacesAboveKotSaving');
    var spacesBelowKotResult = prefs.getInt('spacesBelowKotSaving');
    var kotFontSizeResult = prefs.getString('kotFontSizeSaving');
    var chefInstructionsVideoPlayedOrNot =
        prefs.getBool('chefInstructionVideoPlayedOrNotSaving');
    var captainInTableInstructionsVideoPlayedOrNot =
        prefs.getBool('captainInTableInstructionVideoPlayedOrNotSaving');
    var allUserProfileResult = prefs.getString('allUserProfileSaving');
    var allUserTokensResult = prefs.getString('allUserTokensSaving');
    var entireMenuResult = prefs.getString('entireMenuSaving');
    var currentUserPhoneNumberResult =
        prefs.getString('currentUserPhoneNumberSaving');
    var restaurantInfoSavingResult = prefs.getString('restaurantInfoSaving');
    var appVersionSavingResult = prefs.getString('appVersionSaving');
    var expensesSegregationTimeStampResult =
        prefs.getInt('expensesSegregationTimeStampSaving');
    var expensesSegregationSavingResult =
        prefs.getString('expensesSegregationSaving');

    if (restaurantChosenResult != null) {
      chosenRestaurantDatabaseFromClass = restaurantChosenResult;
    }

    if (savedPrintersMapResult != null) {
      savedPrintersFromClass = savedPrintersMapResult;
    }
    if (kotAssignedPrinterMapResult != null) {
      kotAssignedPrintersFromClass = kotAssignedPrinterMapResult;
    }

    if (billingAssignedPrinterMapResult != null) {
      billingAssignedPrinterFromClass = billingAssignedPrinterMapResult;
    }

    if (chefAssignedPrinterMapResult != null) {
      chefAssignedPrinterFromClass = chefAssignedPrinterMapResult;
    }

    if (captainResultName != null) {
      captainPrinterNameFromClass = captainResultName;
    }
    if (captainResultAddress != null) {
      captainPrinterAddressFromClass = captainResultAddress;
    }
    if (captainResultSize != null) {
      captainPrinterSizeFromClass = captainResultSize;
    }
    if (chefResultName != null) {
      chefPrinterNameFromClass = chefResultName;
    }
    if (chefResultAddress != null) {
      chefPrinterAddressFromClass = chefResultAddress;
    }
    if (chefResultSize != null) {
      chefPrinterSizeFromClass = chefResultSize;
    }
    if (chefResultKOT != null) {
      chefPrinterKOTFromClass = chefResultKOT;
    }
    if (chefResultAfterOrderPrint != null) {
      chefPrinterAfterOrderReadyPrintFromClass = chefResultAfterOrderPrint;
    }

    if (spacesAboveKotResult != null) {
      spacesAboveKotFromClass = spacesAboveKotResult;
    }
    if (spacesBelowKotResult != null) {
      spacesBelowKotFromClass = spacesBelowKotResult;
    }
    if (kotFontSizeResult != null) {
      kotFontSizeFromClass = kotFontSizeResult;
    }

    if (chefInstructionsVideoPlayedOrNot != null) {
      chefInstructionsVideoPlayedFromClass = chefInstructionsVideoPlayedOrNot;
    }

    if (captainInTableInstructionsVideoPlayedOrNot != null) {
      captainInsideTableInstructionsVideoPlayedFromClass =
          captainInTableInstructionsVideoPlayedOrNot;
    }

    if (allUserProfileResult != null) {
      allUserProfilesFromClass = allUserProfileResult;
    }

    if (allUserTokensResult != null) {
      allUserTokensFromClass = allUserTokensResult;
    }

    if (entireMenuResult != null) {
      entireMenuFromClass = entireMenuResult;
    }

    if (currentUserPhoneNumberResult != null) {
      currentUserPhoneNumberFromClass = currentUserPhoneNumberResult;
    }

    if (restaurantInfoSavingResult != null) {
      restaurantInfoDataFromClass = restaurantInfoSavingResult;
    }

    if (appVersionSavingResult != null) {
      versionOfAppFromClass = appVersionSavingResult;
    }

    if (bluetoothSaveResult != null) {
      experimentForBluetooth = bluetoothSaveResult;
    }

    if (expensesSegregationTimeStampResult != null) {
      expensesSegregationDeviceSavedTimestampFromClass =
          expensesSegregationTimeStampResult;
    }

    if (expensesSegregationSavingResult != null) {
      expensesSegregationMapFromClass = expensesSegregationSavingResult;
    }

    notifyListeners();
  }
}
