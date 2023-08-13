import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';

class PrinterAndOtherDetailsProvider extends ChangeNotifier {
  String captainPrinterNameFromClass = '';
  String captainPrinterAddressFromClass = '';
  String captainPrinterSizeFromClass = '0';
  String chefPrinterNameFromClass = '';
  String chefPrinterAddressFromClass = '';
  String chefPrinterSizeFromClass = '0';
  bool chefPrinterKOTFromClass = false;
  bool chefPrinterAfterOrderReadyPrintFromClass = false;
  bool chefInstructionsVideoPlayedFromClass = false;
  bool captainInsideTableInstructionsVideoPlayedFromClass = false;
  bool menuOrRestaurantInfoUpdatedFromClass =
      false; //ToRegisterSomethingHasBeenUpdated

  PrinterAndOtherDetailsProvider() {
    initialState();
  }

  void initialState() {
    syncDataWithProvider();
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

  Future syncDataWithProvider() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var captainResultName = prefs.getString('captainPrinterNameSaving');
    var captainResultAddress = prefs.getString('captainPrinterAddressSaving');
    var captainResultSize = prefs.getString('captainPrinterSizeSaving');
    var chefResultName = prefs.getString('chefPrinterNameSaving');
    var chefResultAddress = prefs.getString('chefPrinterAddressSaving');
    var chefResultSize = prefs.getString('chefPrinterSizeSaving');
    var chefResultKOT = prefs.getBool('chefPrinterKOTPreferenceSaving');
    var chefResultAfterOrderPrint =
        prefs.getBool('chefPrinterAfterOrderReadyPrintPreferenceSaving');
    var chefInstructionsVideoPlayedOrNot =
        prefs.getBool('chefInstructionVideoPlayedOrNotSaving');
    var captainInTableInstructionsVideoPlayedOrNot =
        prefs.getBool('captainInTableInstructionVideoPlayedOrNotSaving');

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

    if (chefInstructionsVideoPlayedOrNot != null) {
      chefInstructionsVideoPlayedFromClass = chefInstructionsVideoPlayedOrNot;
    }

    if (captainInTableInstructionsVideoPlayedOrNot != null) {
      captainInsideTableInstructionsVideoPlayedFromClass =
          captainInTableInstructionsVideoPlayedOrNot;
    }

    notifyListeners();
  }
}
