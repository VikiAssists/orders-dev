import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud_alt/modal_progress_hud_alt.dart';
import 'package:orders_dev/Methods/eac_expense_bill_widget.dart';
import 'package:orders_dev/Providers/notification_provider.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:orders_dev/constants.dart';
import 'package:orders_dev/services/firestore_services.dart';
import 'package:paginate_firestore/bloc/pagination_listeners.dart';
import 'package:paginate_firestore/paginate_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ExpensesSeparateFolderForExpenses extends StatefulWidget {


  const ExpensesSeparateFolderForExpenses({Key? key}) : super(key: key);

  @override
  State<ExpensesSeparateFolderForExpenses> createState() => _ExpensesSeparateFolderForExpensesState();
}

class _ExpensesSeparateFolderForExpensesState extends State<ExpensesSeparateFolderForExpenses> {
  final _fireStore = FirebaseFirestore.instance;
  num pageNumber = 1;
  var scrollKeyToExpenseCategory = GlobalKey();
  var scrollKeyToExpensePaidByUser = GlobalKey();
  var scrollKeyToExpensePaymentMethod = GlobalKey();
  DateTime pickedDateTimeStamp = DateTime.now();
  TextEditingController _dateForAddingExpense = TextEditingController(
      text: DateFormat('dd-MM-yyyy').format(DateTime.now()));
  String dateForAddingExpense = DateFormat('dd-MM-yyyy').format(DateTime.now());
  String year = '';
  String month = '';
  String day = '';
  String hour = '';
  String minute = '';
  String second = '';
  String tempNumberOfMillisecondsPassedToday = '';
  TextEditingController _eachItemCategoryEntryController =
  TextEditingController();
  TextEditingController _eachItemVendorEntryController =
  TextEditingController();
  TextEditingController _eachItemExpensePaidByUserEntryController = TextEditingController();
  TextEditingController _eachItemPaymentMethodEntryController = TextEditingController();
  TextEditingController _eachItemDescriptionEntryController =
  TextEditingController();
  TextEditingController _eachItemExpenseEntryController =
  TextEditingController();
  TextEditingController _numberOfItemsEntryController = TextEditingController();
  TextEditingController _cgstPercentageEntryController = TextEditingController();
  TextEditingController _sgstPercentageEntryController = TextEditingController();
  TextEditingController _cgstValueEntryController = TextEditingController();
  TextEditingController _sgstValueEntryController = TextEditingController();
  TextEditingController _totalExpenseWithTaxesEntryController =
  TextEditingController();
  String tempNumberOfUnitsInString = '';
  String tempPriceOfUnitInString = '';
  String tempCgstPercentageOfItemInString = '';
  String tempSgstPercentageOfItemInString = '';
  String tempCgstValueOfItemInString = '';
  String tempSgstValueOfItemInString = '';
  String tempTotalExpenseWithTaxesInString = '';
  String tempExpenseDescription = '';
  String tempVendor = '';
  String tempExpenseCategoryToSave = '';
  String tempExpensePaidByUser = '';
  String tempPaymentMethod = '';
  List<String> expenseCategories = [];
  List<String> expensesVendors = [];
  List<String> expensesCgstPercentage = [];
  List<String> expensesSgstPercentage = [];
  List<String> expensesPaidByUser = [];
  List<String> paymentMethod = [];
  Map<String, dynamic> expensesSegregationMap = HashMap();
  List<String> gstPercentageOrValue = ['%', '₹'];
  String tempCgstPercentageOrValue = '%';
  String tempSgstPercentageOrValue = '%';
  TextEditingController _editCategoryVendorPaidByPaymentMethodController =
  TextEditingController();
  String errorMessage = '';
  List<String> monthsForViewExpenses = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  List<String> yearsForViewExpenses = ['2024'];
  String chosenMonthForViewingExpense = 'Jan';
  String tempChosenMonthForViewingExpense = 'Jan';
  String chosenMonthNumberViewingExpenseInString = '01';
  String chosenYearForViewingExpense = DateTime.now().year.toString();
  String tempChosenYearForViewingExpense = DateTime.now().year.toString();
  bool viewingExpenseChanged = false;
  bool showSpinner = false;
  String beforeEditYear = '';
  String beforeEditMonth = '';
  String beforeEditDay = '';
  String beforeEditBillId = '';
  String beforeEditCategory = '';
  String beforeEditDescription = '';
  String beforeEditVendor = '';
  String beforeEditExpensePaidByUser = '';
  String beforeEditPaymentMethod = '';
  String beforeEditUnitPriceInString = '';
  String beforeEditNumberOfItemsInString = '';
  String beforeEditCgstPercentage = '';
  String beforeEditSgstPercentage = '';
  String beforeEditCgstValue = '';
  String beforeEditSgstValue = '';
  String beforeEditTotalPriceWithTaxes = '';
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _streamSubscriptionForPreviousDayCashBalance;
  num cashBalance = 0;
  num lastCashYear = 0;
  num lastCashMonth = 0;
  num lastCashDay = 0;
  bool gotCashBalanceInfo = false;//InCaseNetIsBadWeCanFindOut
  Map<String,dynamic> eachDayCashBalanceUpdateMap = HashMap();
//ThisIsForUpdatingEachDay
  Map<String,dynamic> continuousCashBalanceIterationMap = HashMap();
//ThisIsForAddingToCashBalance

  @override
  void initState() {
    // TODO: implement initState
    yearsAddingAndMonthsSettingForViewExpenses();
    downloadingExpensesSegregation();
    initialDateStringsSetting();
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _streamSubscriptionForPreviousDayCashBalance?.cancel();
    super.dispose();
  }

  void yearsAddingAndMonthsSettingForViewExpenses() {
    tempChosenMonthForViewingExpense= chosenMonthForViewingExpense =
    monthsForViewExpenses[DateTime.now().month - 1];
//MinusOneNeededBecauseArrayIndexStartsWithZero
    chosenMonthNumberViewingExpenseInString = DateTime.now().month.toString();
    if (chosenMonthNumberViewingExpenseInString.length == 1) {
      chosenMonthNumberViewingExpenseInString =
      '0$chosenMonthNumberViewingExpenseInString';
    }

    int currentYear = DateTime.now().year;
    if (currentYear > 2024) {
      for (int i = 2025; i <= currentYear; i++) {
        yearsForViewExpenses.add(i.toString());
      }
    }
    setState(() {});
  }

  void errorAlertDialogBox() async {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Center(
            child: Text(
              'ERROR!',
              style: TextStyle(color: Colors.red),
            )),
        content: Text('${errorMessage}'),
        actions: [
          ElevatedButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.green),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK')),
        ],
      ),
      barrierDismissible: false,
    );
  }

  List<String> dynamicTokensToStringToken() {
    List<String> tokensList = [];
    Map<String, dynamic> allUsersTokenMap = json.decode(
        Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .allUserTokensFromClass);
    for (var tokens in allUsersTokenMap.values) {
      tokensList.add(tokens.toString());
    }
    return tokensList;
  }

  void initialDateStringsSetting() {
    DateTime now = DateTime.now();
    pickedDateTimeStamp = now;
    year = now.year.toString();
    month = now.month.toString().length == 1
        ? '0${now.month.toString()}'
        : now.month.toString();
    day = now.day.toString().length == 1
        ? '0${now.day.toString()}'
        : now.day.toString();
    hour = now.hour.toString().length == 1
        ? '0${now.hour.toString()}'
        : now.hour.toString();
    minute = now.minute.toString().length == 1
        ? '0${now.minute.toString()}'
        : now.minute.toString();
    second = now.second.toString().length == 1
        ? '0${now.second.toString()}'
        : now.second.toString();
    tempNumberOfMillisecondsPassedToday = (((now.hour * 3600000) +
        (now.minute * 60000) +
        (now.second * 1000) +
        now.millisecond))
        .toString();
    if (tempNumberOfMillisecondsPassedToday.length < 8) {
      for (int i = tempNumberOfMillisecondsPassedToday.length; i < 8; i++) {
        tempNumberOfMillisecondsPassedToday =
            '0' + tempNumberOfMillisecondsPassedToday;
      }
    }
  }

  void chosenDateStringsSetting(DateTime chosenDateTime) {
    pickedDateTimeStamp = chosenDateTime;
    year = chosenDateTime.year.toString();
    month = chosenDateTime.month.toString().length == 1
        ? '0${chosenDateTime.month.toString()}'
        : chosenDateTime.month.toString();
    day = chosenDateTime.day.toString().length == 1
        ? '0${chosenDateTime.day.toString()}'
        : chosenDateTime.day.toString();
    //pickedTimeFromCalendarWillAlwaysShow12AM.
// SoChoosingNowToCalculateRemaining
    hour = DateTime.now().hour.toString().length == 1
        ? '0${DateTime.now().hour.toString()}'
        : DateTime.now().hour.toString();
    minute = DateTime.now().minute.toString().length == 1
        ? '0${DateTime.now().minute.toString()}'
        : DateTime.now().minute.toString();
    second = DateTime.now().second.toString().length == 1
        ? '0${DateTime.now().second.toString()}'
        : DateTime.now().second.toString();

    tempNumberOfMillisecondsPassedToday = (((DateTime.now().hour * 3600000) +
        (DateTime.now().minute * 60000) +
        (DateTime.now().second * 1000) +
        DateTime.now().millisecond))
        .toString();
    if (tempNumberOfMillisecondsPassedToday.length < 8) {
      for (int i = tempNumberOfMillisecondsPassedToday.length; i < 8; i++) {
        tempNumberOfMillisecondsPassedToday =
            '0' + tempNumberOfMillisecondsPassedToday;
      }
    }
  }

  Future<void> downloadingExpensesSegregation() async {
    int lastExpensesLocallySavedSegregationTime =
        Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .expensesSegregationDeviceSavedTimestampFromClass;
    int expensesSegregationTimeInServer = json.decode(
        Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .restaurantInfoDataFromClass)['updateTimes']['expensesSegregation'];

    if ((Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
        .expensesSegregationMapFromClass ==
        '{}') ||
        (expensesSegregationTimeInServer >
            lastExpensesLocallySavedSegregationTime)
//ThisMeansThereIsNewUpdateToTheData
    ) {
      final expensesSegregationQuery = await _fireStore
          .collection(Provider.of<PrinterAndOtherDetailsProvider>(context,
          listen: false)
          .chosenRestaurantDatabaseFromClass)
          .doc('expensesSegregation')
          .get();
      expensesSegregationMap = expensesSegregationQuery.data()!;
      Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
          .expensesSegregationTimeStampSaving(expensesSegregationTimeInServer,
          json.encode(expensesSegregationMap));
      expensesSegregationData();
    } else {
      expensesSegregationMap = json.decode(
          Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .expensesSegregationMapFromClass);
      expensesSegregationData();
    }
  }

  void expensesSegregationData() {
    Map<String, dynamic> tempExpensesCategoriesMap =
    expensesSegregationMap['expensesCategories'];
    List<String> tempExpensesCategoriesList =
    tempExpensesCategoriesMap.values.toList().cast<String>();
    tempExpensesCategoriesList.sort();
    expenseCategories.clear();

    expenseCategories.addAll(tempExpensesCategoriesList);
    Map<String, dynamic> tempExpensesVendorsMap =
    expensesSegregationMap['expensesVendors'];
    List<String> tempExpensesVendorsList = tempExpensesVendorsMap.isNotEmpty
        ? tempExpensesVendorsMap.values.toList().cast<String>()
        : [];
    tempExpensesVendorsList.sort();
    expensesVendors.clear();
    expensesVendors.addAll(tempExpensesVendorsList);
    print('expensesPaidByUser');
    print(expensesSegregationMap['expensesPaidByUser']);

    Map<String, dynamic> tempExpensesPaidByUserMap = expensesSegregationMap['expensesPaidByUser'];

    List<String> tempExpensesPaidByUserList = tempExpensesPaidByUserMap.isNotEmpty
        ? tempExpensesPaidByUserMap.values.toList().cast<String>()
        : [];
//InCaseThisIsTheFirstTimeTheUserIsComingInsideExpenses,HeWontHaveAnyUsers.
//SoWeMakeListOutOfExistingUsers.InFuture,EverytimeTheyTypeDownNewUser...
//...ItWillAutomaticallyBeSaved
    if(tempExpensesPaidByUserList.isEmpty){
      int expensesPaidByUserNumber = 11111111;
      Map<String,dynamic> mapToAddUsersInServer = HashMap();
      Map<String, dynamic> allUserProfiles = HashMap();
      allUserProfiles = json.decode(
          Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
              .allUserProfilesFromClass);
//ifUserIsNonAdmin
      allUserProfiles.forEach((key, value) {
        if (value['admin'] == false) {
          tempExpensesPaidByUserList.add(value['username']);
          mapToAddUsersInServer.addAll({expensesPaidByUserNumber.toString():value['username']});
          expensesPaidByUserNumber++;
        }
      });
      if(mapToAddUsersInServer.isNotEmpty){
        int expensesUpdateTimeInMilliseconds =
            DateTime.now().millisecondsSinceEpoch;
        var batch = _fireStore.batch();
        String hotelName = Provider.of<PrinterAndOtherDetailsProvider>(context,listen: false).chosenRestaurantDatabaseFromClass;
        var expensesPaidByUsersRef =
        _fireStore.collection(hotelName).doc('expensesSegregation');
        var expensesDateUpdationRef =
        _fireStore.collection(hotelName).doc('basicinfo');

        batch.set(
            expensesPaidByUsersRef,

            {'expensesPaidByUser':mapToAddUsersInServer}
            ,
            SetOptions(merge: true));
        batch.set(
            expensesDateUpdationRef,
            {
              'updateTimes': {
                'expensesSegregation': expensesUpdateTimeInMilliseconds
              }
            },
            SetOptions(merge: true));
        batch.commit();
        final fcmProvider =
        Provider.of<NotificationProvider>(context, listen: false);
        fcmProvider.sendNotification(
            token: dynamicTokensToStringToken(),
            title: Provider.of<PrinterAndOtherDetailsProvider>(context,
                listen: false)
                .chosenRestaurantDatabaseFromClass,
            restaurantNameForNotification: json.decode(
                Provider.of<PrinterAndOtherDetailsProvider>(
                    context,
                    listen: false)
                    .allUserProfilesFromClass)[
            Provider.of<PrinterAndOtherDetailsProvider>(context,
                listen: false)
                .currentUserPhoneNumberFromClass]['restaurantName'],
            body: '*restaurantInfoUpdated*');


      }


    }
    tempExpensesPaidByUserList.sort();
    expensesPaidByUser.clear();
    expensesPaidByUser.addAll(tempExpensesPaidByUserList);
//ExpensesPaidByMethod
    Map<String, dynamic> tempPaymentMethodMap = expensesSegregationMap['paymentMethod'];

    List<String> tempPaymentMethodList = tempPaymentMethodMap.isNotEmpty
        ? tempPaymentMethodMap.values.toList().cast<String>()
        : [];
    tempPaymentMethodList.sort();
    paymentMethod.clear();
    paymentMethod.addAll(tempPaymentMethodList);
//GettingCgstPercentageList
    Map<String, dynamic> tempExpensesCgstPercentageMap =
    expensesSegregationMap['expensesCgstPercentage'];
    List<String> tempExpensesCgstPercentageList =
    tempExpensesCgstPercentageMap.isNotEmpty
        ? tempExpensesCgstPercentageMap.keys.toList()
        : [];
    expensesCgstPercentage.clear();
    expensesCgstPercentage.addAll(tempExpensesCgstPercentageList);
    Map<String, dynamic> tempExpensesSgstPercentageMap =
    expensesSegregationMap['expensesSgstPercentage'];
    List<String> tempExpensesSgstPercentageList =
    tempExpensesSgstPercentageMap.isNotEmpty
        ? tempExpensesSgstPercentageMap.keys.toList()
        : [];
    expensesSgstPercentage.clear();
    expensesSgstPercentage.addAll(tempExpensesSgstPercentageList);
    setState(() {});
  }

  void expensesCalculationForNewExpense() {
    num localTempPriceOfUnitInNum =
    tempPriceOfUnitInString == '' ? 0 : num.parse(tempPriceOfUnitInString);
    num localTempNumberOfUnitsInNum = tempNumberOfUnitsInString == ''
        ? 0
        : num.parse(tempNumberOfUnitsInString);
    num localTempCgstPercentageOfItemInNum =
    tempCgstPercentageOfItemInString == ''
        ? 0
        : num.parse(tempCgstPercentageOfItemInString);
    num localTempSgstPercentageOfItemInNum =
    tempSgstPercentageOfItemInString == ''
        ? 0
        : num.parse(tempSgstPercentageOfItemInString);
    num localTotalWithoutTaxesInNum =
        localTempPriceOfUnitInNum * localTempNumberOfUnitsInNum;
    num localTempCgstValueOfItemInNum = tempCgstValueOfItemInString == ''
        ? 0
        : num.parse(tempCgstValueOfItemInString);
    num localTempSgstValueOfItemInNum = tempSgstValueOfItemInString == ''
        ? 0
        : num.parse(tempSgstValueOfItemInString);
//AfterThisAllCalculation
    localTempCgstValueOfItemInNum = localTotalWithoutTaxesInNum *
        (localTempCgstPercentageOfItemInNum / 100);
    localTempSgstValueOfItemInNum = localTotalWithoutTaxesInNum *
        (localTempSgstPercentageOfItemInNum / 100);

    num localTempTotalExpenseWithTaxesInNum = localTotalWithoutTaxesInNum +
        localTempCgstValueOfItemInNum +
        localTempSgstValueOfItemInNum;
//ConvertingCalculatedValuesToString
    if (tempCgstPercentageOrValue == '%' &&
        tempCgstPercentageOfItemInString != '') {
      tempCgstValueOfItemInString = localTempCgstValueOfItemInNum.toString();
    }
    if (tempSgstPercentageOrValue == '%' &&
        tempSgstPercentageOfItemInString != '') {
      tempSgstValueOfItemInString = localTempSgstValueOfItemInNum.toString();
    }

    tempTotalExpenseWithTaxesInString =
        localTempTotalExpenseWithTaxesInNum.toString();
    _totalExpenseWithTaxesEntryController.text =
        tempTotalExpenseWithTaxesInString;
    setState(() {});
  }

  void deleteCategoryVendorAlertDialogBox(String typeCategoryVendorPaidByPaymentMethod,
      String nameCategoryVendorPaidByPaymentMethod, String serverAddEditDeleteKey) async {
    final fcmProvider =
    Provider.of<NotificationProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Center(
            child: Text(
              'DELETE WARNING!',
              style: TextStyle(color: Colors.red),
            )),
        content: Text('$nameCategoryVendorPaidByPaymentMethod will be deleted'),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                    MaterialStateProperty.all<Color>(Colors.green),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel')),
              ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                    MaterialStateProperty.all<Color>(Colors.red),
                  ),
                  onPressed: () {
//ThisIsToDeleteFromServer
                    int expensesUpdateTimeInMilliseconds =
                        DateTime.now().millisecondsSinceEpoch;
                    FireStoreEditOrDeleteExpenseCategoryOrVendor(
                        hotelName:
                        Provider.of<PrinterAndOtherDetailsProvider>(
                            context,
                            listen: false)
                            .chosenRestaurantDatabaseFromClass,
                        categoryOrVendor: typeCategoryVendorPaidByPaymentMethod,
                        categoryVendorName: FieldValue.delete(),
                        categoryOrVendorKey: serverAddEditDeleteKey,
                        expensesUpdateTimeInMilliseconds:
                        expensesUpdateTimeInMilliseconds)
                        .deleteOrEditExpenseCategory();
                    fcmProvider.sendNotification(
                        token: dynamicTokensToStringToken(),
                        title: Provider.of<PrinterAndOtherDetailsProvider>(context,
                            listen: false)
                            .chosenRestaurantDatabaseFromClass,
                        restaurantNameForNotification: json.decode(
                            Provider.of<PrinterAndOtherDetailsProvider>(
                                context,
                                listen: false)
                                .allUserProfilesFromClass)[
                        Provider.of<PrinterAndOtherDetailsProvider>(context,
                            listen: false)
                            .currentUserPhoneNumberFromClass]['restaurantName'],
                        body: '*restaurantInfoUpdated*');
                    if (typeCategoryVendorPaidByPaymentMethod == 'category') {
                      Map<String, dynamic> tempExpensesCategoriesMap =
                      expensesSegregationMap['expensesCategories'];
                      tempExpensesCategoriesMap.remove(serverAddEditDeleteKey);
                      expensesSegregationMap['expensesCategories'] =
                          tempExpensesCategoriesMap;
                    }
                    else if (typeCategoryVendorPaidByPaymentMethod == 'vendor')
                    {
                      Map<String, dynamic> tempExpensesVendorsMap =
                      expensesSegregationMap['expensesVendors'];
                      tempExpensesVendorsMap.remove(serverAddEditDeleteKey);
                      expensesSegregationMap['expensesVendors'] =
                          tempExpensesVendorsMap;
                    }else if (typeCategoryVendorPaidByPaymentMethod == 'paidByUser') {
                      Map<String, dynamic> tempExpensesPaidByUsersMap =
                      expensesSegregationMap['expensesPaidByUser'];
                      tempExpensesPaidByUsersMap.remove(serverAddEditDeleteKey);
                      expensesSegregationMap['expensesPaidByUser'] =
                          tempExpensesPaidByUsersMap;
                    } else if (typeCategoryVendorPaidByPaymentMethod == 'paymentMethod')
                    {
                      Map<String, dynamic> tempExpensesPaymentMethodMap =
                      expensesSegregationMap['paymentMethod'];
                      tempExpensesPaymentMethodMap.remove(serverAddEditDeleteKey);
                      expensesSegregationMap['paymentMethod'] =
                          tempExpensesPaymentMethodMap;
                    }

                    Provider.of<PrinterAndOtherDetailsProvider>(context,
                        listen: false)
                        .expensesSegregationTimeStampSaving(
                        expensesUpdateTimeInMilliseconds,
                        json.encode(expensesSegregationMap));

                    expensesSegregationData();

                    Navigator.pop(context);
                  },
                  child: Text('Delete')),
            ],
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Widget categoryVendorPaidByPaymentMethodEditDeleteBottomBar(
      BuildContext context,
      String typeCategoryVendorPaidByPaymentMethod,
      String nameCategoryVendorPaidByPaymentMethod,
      String serverAddEditDeleteKey) {
    String tempFieldForEdit = nameCategoryVendorPaidByPaymentMethod;
    _editCategoryVendorPaidByPaymentMethodController.text = tempFieldForEdit;
    _editCategoryVendorPaidByPaymentMethodController.selection = TextSelection.collapsed(
        offset: tempFieldForEdit.toString().length);
    final fcmProvider =
    Provider.of<NotificationProvider>(context, listen: false);
    return Padding(
      padding:
      EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),

            typeCategoryVendorPaidByPaymentMethod == 'category'
                ? Text('Edit Category', style: TextStyle(fontSize: 30))
                : typeCategoryVendorPaidByPaymentMethod == 'vendor'? Text('Edit Vendor', style: TextStyle(fontSize: 30))
                : typeCategoryVendorPaidByPaymentMethod == 'paidByUser'?Text('Edit User Name', style: TextStyle(fontSize: 30)):
            typeCategoryVendorPaidByPaymentMethod == 'paymentMethod'?Text('Edit Payment Method', style: TextStyle(fontSize: 30)):
            SizedBox.shrink(),
            SizedBox(height: 10),
            ListTile(
              leading: typeCategoryVendorPaidByPaymentMethod == 'category'
                  ? Text('Category', style: TextStyle(fontSize: 20))
                  : typeCategoryVendorPaidByPaymentMethod == 'vendor'? Text('Vendor', style: TextStyle(fontSize: 20)):
              typeCategoryVendorPaidByPaymentMethod == 'paidByUser'? Text('Paid By', style: TextStyle(fontSize: 20)):
              typeCategoryVendorPaidByPaymentMethod == 'paymentMethod'? Text('Payment Method', style: TextStyle(fontSize: 20)):


              SizedBox.shrink(),
              title: Container(
                child: TextField(
                  maxLength: 40,
                  controller: _editCategoryVendorPaidByPaymentMethodController,
                  textCapitalization: typeCategoryVendorPaidByPaymentMethod != 'paymentMethod'?

                  TextCapitalization.sentences:TextCapitalization.none,
                  onChanged: (value) {
                    tempFieldForEdit = value.toString();
                  },
                  decoration:
                  // kTextFieldInputDecoration,
                  InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      // hintText: categoryOrVendor == 'category'
                      //     ? 'Enter Category Name'
                      //     : 'Enter Vendor Name',
                      hintStyle: TextStyle(color: Colors.grey),
                      enabledBorder: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(color: Colors.green)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(color: Colors.green))),
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.red),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      deleteCategoryVendorAlertDialogBox(typeCategoryVendorPaidByPaymentMethod,
                          nameCategoryVendorPaidByPaymentMethod, serverAddEditDeleteKey);
                    },
                    child: Text('Delete')),
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.green),
                    ),
                    onPressed: () {
                      if (tempFieldForEdit == '') {
                        errorMessage = 'Please Enter the Field';
                        errorAlertDialogBox();
                      } else if (typeCategoryVendorPaidByPaymentMethod == 'category' &&
                          expenseCategories
                              .contains(tempFieldForEdit)) {
                        errorMessage = 'Category Already Exists';
                        errorAlertDialogBox();
                      } else if (typeCategoryVendorPaidByPaymentMethod == 'vendor' &&
                          expensesVendors
                              .contains(tempFieldForEdit)) {
                        errorMessage = 'Vendor Already Exists';
                        errorAlertDialogBox();
                      } else if(expensesPaidByUser.contains(tempFieldForEdit))
                      {
                        errorMessage = 'User for payment Already Exists';
                        errorAlertDialogBox();
                      } else if(paymentMethod.contains(tempFieldForEdit))
                      {
                        errorMessage = 'Payment Method Already Exists';
                        errorAlertDialogBox();
                      } else {
                        //ThisIsToEditTheCategoryOrVendorName
                        int expensesUpdateTimeInMilliseconds =
                            DateTime.now().millisecondsSinceEpoch;
                        FireStoreEditOrDeleteExpenseCategoryOrVendor(
                            hotelName:
                            Provider.of<PrinterAndOtherDetailsProvider>(
                                context,
                                listen: false)
                                .chosenRestaurantDatabaseFromClass,
                            categoryOrVendor: typeCategoryVendorPaidByPaymentMethod,
                            categoryVendorName:
                            tempFieldForEdit,
                            categoryOrVendorKey: serverAddEditDeleteKey,
                            expensesUpdateTimeInMilliseconds:
                            expensesUpdateTimeInMilliseconds)
                            .deleteOrEditExpenseCategory();
                        fcmProvider.sendNotification(
                            token: dynamicTokensToStringToken(),
                            title: Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                                .chosenRestaurantDatabaseFromClass,
                            restaurantNameForNotification: json.decode(
                                Provider.of<PrinterAndOtherDetailsProvider>(
                                    context,
                                    listen: false)
                                    .allUserProfilesFromClass)[
                            Provider.of<PrinterAndOtherDetailsProvider>(
                                context,
                                listen: false)
                                .currentUserPhoneNumberFromClass]
                            ['restaurantName'],
                            body: '*restaurantInfoUpdated*');
                        if (typeCategoryVendorPaidByPaymentMethod == 'category') {
                          Map<String, dynamic> tempExpensesCategoriesMap =
                          expensesSegregationMap['expensesCategories'];
                          tempExpensesCategoriesMap[serverAddEditDeleteKey] =
                              tempFieldForEdit;
                          expensesSegregationMap['expensesCategories'] =
                              tempExpensesCategoriesMap;
                        } else if (typeCategoryVendorPaidByPaymentMethod == 'vendor') {
                          Map<String, dynamic> tempExpensesVendorsMap =
                          expensesSegregationMap['expensesVendors'];
                          tempExpensesVendorsMap[serverAddEditDeleteKey] =
                              tempFieldForEdit;
                          expensesSegregationMap['expensesVendors'] =
                              tempExpensesVendorsMap;
                        } else if (typeCategoryVendorPaidByPaymentMethod == 'paidByUser') {
                          Map<String, dynamic> tempExpensesPaidByUsersMap =
                          expensesSegregationMap['expensesPaidByUser'];
                          tempExpensesPaidByUsersMap[serverAddEditDeleteKey] =
                              tempFieldForEdit;
                          expensesSegregationMap['expensesPaidByUser'] =
                              tempExpensesPaidByUsersMap;
                        } else if (typeCategoryVendorPaidByPaymentMethod == 'paymentMethod') {
                          Map<String, dynamic> tempExpensesPaymentMethodMap =
                          expensesSegregationMap['paymentMethod'];
                          tempExpensesPaymentMethodMap[serverAddEditDeleteKey] =
                              tempFieldForEdit;
                          expensesSegregationMap['paymentMethod'] =
                              tempExpensesPaymentMethodMap;
                        }

                        Provider.of<PrinterAndOtherDetailsProvider>(context,
                            listen: false)
                            .expensesSegregationTimeStampSaving(
                            expensesUpdateTimeInMilliseconds,
                            json.encode(expensesSegregationMap));
                        expensesSegregationData();

                        Navigator.pop(context);
                      }
                    },
                    child: Text('Done')),
                ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.orangeAccent),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Cancel'))
              ],
            )
          ],
        ),
      ),
    );
  }

  Future show(
      String message, {
        Duration duration: const Duration(seconds: 2),
      }) async {
    await new Future.delayed(new Duration(milliseconds: 100));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: kSnackbarMessageSize),
        ),
        duration: duration,
      ),
    );
  }

  void editBill(Map<String, dynamic> billMap) {
    final tempDate = billMap['date'].toString().split('*');
    beforeEditYear = year= '${tempDate[0]}';
    beforeEditMonth = month =  '${tempDate[1]}';
    beforeEditDay = day = '${tempDate[2]}';
    _dateForAddingExpense.text = '$beforeEditDay-$beforeEditMonth-$beforeEditYear';
    dateForAddingExpense = '$beforeEditDay-$beforeEditMonth-$beforeEditYear';
    beforeEditCategory = tempExpenseCategoryToSave= billMap['category'];
    _eachItemCategoryEntryController.text = beforeEditCategory;
    beforeEditDescription = tempExpenseDescription = billMap['description'];
    _eachItemDescriptionEntryController.text = beforeEditDescription;
    beforeEditVendor = tempVendor = billMap['vendor'];
    _eachItemVendorEntryController.text = beforeEditVendor;
    beforeEditExpensePaidByUser = tempExpensePaidByUser= billMap['paidBy'];
    _eachItemExpensePaidByUserEntryController.text = beforeEditExpensePaidByUser;
    beforeEditPaymentMethod = tempPaymentMethod = billMap['paymentMethod'];
    _eachItemPaymentMethodEntryController.text = beforeEditPaymentMethod;
    beforeEditUnitPriceInString = tempPriceOfUnitInString = billMap['unitPrice'];
    _eachItemExpenseEntryController.text = beforeEditUnitPriceInString;
    beforeEditUnitPriceInString = tempNumberOfUnitsInString= billMap['numberOfUnits'];
    _numberOfItemsEntryController.text = beforeEditUnitPriceInString;
    beforeEditCgstPercentage = tempCgstPercentageOfItemInString = billMap['cgstPercentage'];
    _cgstPercentageEntryController.text = beforeEditCgstPercentage;
    beforeEditCgstValue = tempCgstValueOfItemInString = billMap['cgstValue'];
    _cgstValueEntryController.text = beforeEditCgstValue;
    if(beforeEditCgstPercentage != ''){
      tempCgstPercentageOrValue = '%';
    }else if(beforeEditCgstValue == ''){
      tempCgstPercentageOrValue = '%';
    }else
    {
      tempCgstPercentageOrValue = '₹';
    }
    beforeEditSgstPercentage = tempSgstPercentageOfItemInString = billMap['sgstPercentage'];
    if(beforeEditSgstPercentage != ''){
      tempSgstPercentageOrValue = '%';
    }else if(beforeEditSgstValue == ''){
      tempSgstPercentageOrValue = '%';
    }else
    {
      tempSgstPercentageOrValue = '₹';
    }
    _sgstPercentageEntryController.text = beforeEditSgstPercentage;
    beforeEditSgstValue = tempSgstValueOfItemInString = billMap['sgstValue'];
    _sgstValueEntryController.text = beforeEditSgstValue;

    beforeEditTotalPriceWithTaxes = tempTotalExpenseWithTaxesInString = billMap['totalPrice'].toString();
    _totalExpenseWithTaxesEntryController.text = beforeEditTotalPriceWithTaxes;
    beforeEditBillId = billMap['expenseBillId'];
    setState(() {
      pageNumber = 3;
    });
  }

  void deletePastBillAlertDialogBox() async {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Center(
            child: Text(
              'DELETE WARNING!',
              style: TextStyle(color: Colors.red),
            )),
        content: Text('Bill will be deleted'),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                    MaterialStateProperty.all<Color>(Colors.green),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Cancel')),
              ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                    MaterialStateProperty.all<Color>(Colors.red),
                  ),
                  onPressed: () {

                    Map<String, dynamic>
                    subMasterDeleteExpensesStatistics = HashMap();
                    subMasterDeleteExpensesStatistics.addAll({'mapEachExpenseStatisticsMap':
    {
                      beforeEditCategory: {
                        'numberOfEntriesOfCategory': FieldValue.increment(-1),
                        'numberOfUnits':
                        beforeEditNumberOfItemsInString != ''
                            ? FieldValue.increment(-1*(num.parse(
                            beforeEditNumberOfItemsInString)))
                            : 0,
                        'cgstValue':
                        beforeEditCgstValue != ''
                            ? FieldValue.increment((-1*num.parse(
                            beforeEditCgstValue)))
                            : 0,
                        'sgstValue':
                        beforeEditSgstValue != ''
                            ? FieldValue.increment((-1*num.parse(
                            beforeEditSgstValue)))
                            : 0,
                        'totalPrice': FieldValue.increment(
                            -1*(num.parse(
                                beforeEditTotalPriceWithTaxes)))
                      }
                    }});
                    subMasterDeleteExpensesStatistics.addAll({
                      'mapExpensePaidByUserMap':{
                        beforeEditExpensePaidByUser: {
                          'numberOfEntriesOfUserPaying': FieldValue.increment(-1),
                          'paidAmount':FieldValue.increment(
                            -1 * (num.parse(
                                beforeEditTotalPriceWithTaxes))
                        )}
                      }
                    });
                    subMasterDeleteExpensesStatistics.addAll({
                      'mapExpensePaymentMethodMap':{
                        beforeEditPaymentMethod: {
                          'numberOfEntriesInPaymentMethod': FieldValue.increment(-1),
                          'paidAmount':FieldValue.increment(
                            -1 * (num.parse(
                                beforeEditTotalPriceWithTaxes))
                        )}
                      }
                    });

                    Map<String, dynamic> masterDeleteExpensesStatistics =
                    {'expenses': subMasterDeleteExpensesStatistics};

                    FireStoreDeleteOldExpenseWithBatch(hotelName: Provider.of<PrinterAndOtherDetailsProvider>(context,listen: false).chosenRestaurantDatabaseFromClass,
                        expenseBillName: beforeEditBillId, year: beforeEditYear,month: beforeEditMonth,day: beforeEditDay,
                        statisticsExpensesMap: masterDeleteExpensesStatistics
                    ).deleteExpense();


                    setState(() {
                      pageNumber = 1;
                    });
                    Navigator.pop(context);
                  },
                  child: Text('Delete')),
            ],
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> lastDayCashBalanceStream(bool addButtonClickedTrueEditClickedFalse) async {
    final docRef = FirebaseFirestore.instance
        .collection(Provider.of<
        PrinterAndOtherDetailsProvider>(
        context,
        listen: false)
        .chosenRestaurantDatabaseFromClass)
        .doc('reports')
        .collection('continuousIncrementCollection')
        .doc('cashBalance');
    _streamSubscriptionForPreviousDayCashBalance=docRef.snapshots().listen((cashBalanceDataCheckSnapshot){
      if(!cashBalanceDataCheckSnapshot.exists){
//ThisMeansThisIsTheFirstTimeARestaurantIsStartingThisFeatureAndWeNeedToStartFromFirst
      gotCashBalanceInfo = true;
        cashBalance = 0;
      }else{
//ThisMeansCashHasAlreadyBeenStartedAccounting
        gotCashBalanceInfo = true;
        final cashData = cashBalanceDataCheckSnapshot.data();
        cashBalance = cashData!['amount'];
        lastCashYear = cashData!['year'];
        lastCashMonth = cashData!['month'];
        lastCashDay = cashData!['day'];
        if(lastCashYear == DateTime.now().year &&
            lastCashMonth == DateTime.now().month &&
            lastCashDay == DateTime.now().day && addButtonClickedTrueEditClickedFalse){
//ThisMeansThatIfTheStreamHadAlreadyBeenOnceUpdatedToday,WeCanCloseTheStream
          _streamSubscriptionForPreviousDayCashBalance?.cancel();
        }
      }
    });

  }


  @override
  Widget build(BuildContext context) {
    if (pageNumber == 1) {
      return WillPopScope(
        onWillPop: () async {
          Navigator.pop(context);
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: kAppBarBackgroundColor,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: kAppBarBackIconColor),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: Text('Expenses', style: kAppBarTextStyle),
            centerTitle: true,
          ),
          body: ModalProgressHUD(
            inAsyncCall: showSpinner,
            child:  Stack(
              children: [
                Positioned(
                  top: 10.0, // Set top position to 0.0
                  left: 0.0, // Set left position to 0.0
                  right: 0.0, // Stretch across the width
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(30)),
                        width: 100,
                        height: 50,
                        // height: 200,
                        child: Center(
                          child: DropdownButtonFormField(
                            decoration:
                            InputDecoration.collapsed(hintText: ''),
                            isExpanded: true,
                            // underline: Container(),
                            dropdownColor: Colors.green,
                            value: chosenMonthForViewingExpense,
                            onChanged: (value) {

                              chosenMonthForViewingExpense =
                                  value.toString();
                            },
                            items: monthsForViewExpenses.map((months) {
//DropDownMenuItemWillHaveOneByOneItems,WePutThatAsList
//ValueWillBeEachTitle
                              return DropdownMenuItem(
                                alignment: Alignment.center,
                                child: Text(months,
                                    style: const TextStyle(
                                        fontSize: 15, color: Colors.white)),
                                value: months,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(30)),
                        width: 100,
                        height: 50,
                        // height: 200,
                        child: Center(
                          child: DropdownButtonFormField(
                            decoration:
                            InputDecoration.collapsed(hintText: ''),
                            isExpanded: true,
                            // underline: Container(),
                            dropdownColor: Colors.green,
                            value: chosenYearForViewingExpense,
                            onChanged: (value) {
                              setState(() {
                                chosenYearForViewingExpense =
                                    value.toString();
                              });
                            },
                            items: yearsForViewExpenses.map((years) {
//DropDownMenuItemWillHaveOneByOneItems,WePutThatAsList
//ValueWillBeEachTitle
                              return DropdownMenuItem(
                                alignment: Alignment.center,
                                child: Text(years,
                                    style: const TextStyle(
                                        fontSize: 15, color: Colors.white)),
                                value: years,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(
                                Colors.green),
                          ),
                          onPressed: () {
                            if(tempChosenMonthForViewingExpense != chosenMonthForViewingExpense ||
                                tempChosenYearForViewingExpense != chosenYearForViewingExpense
                            ){

                              chosenMonthNumberViewingExpenseInString =
                                  (monthsForViewExpenses.indexOf(
                                      chosenMonthForViewingExpense) +
                                      1)
                                      .toString();
//SinceMonthsStartFromOneUnlikeIndexWhichStartsFromZero,WeNeed +1
                              if (chosenMonthNumberViewingExpenseInString
                                  .length ==
                                  1) {
                                chosenMonthNumberViewingExpenseInString =
                                '0$chosenMonthNumberViewingExpenseInString';
                              }

                              setState(() {
                                viewingExpenseChanged = true;
                                chosenMonthNumberViewingExpenseInString;
                                chosenYearForViewingExpense;
                              });
                              tempChosenMonthForViewingExpense = chosenMonthForViewingExpense;
                              tempChosenYearForViewingExpense = chosenYearForViewingExpense;


                              Timer(Duration(milliseconds: 500), () {

                                setState(() {
                                  viewingExpenseChanged = false;
                                });
                              });
                            }


//                             if(tempChosenMonthForViewingExpense != chosenMonthForViewingExpense ||
//                                 tempChosenYearForViewingExpense != chosenYearForViewingExpense
//                             ){
// //ThisWillEnsureIfSameDateIsClickedAgainAndViewBillIsGiven,NothingWillhappen
//                               Navigator.push(context,
//                                   MaterialPageRoute(builder: (BuildContext) => ExpensesExperiment(
//                                     viewingDateChanged: true,
//                                     viewingMonth: chosenMonthForViewingExpense,
//                                     viewingYear: chosenYearForViewingExpense,
//                                   )));
//                             }


                          },
                          child: Text('View'))
                    ],
                  ),
                ),
                viewingExpenseChanged == false?Padding(
                  padding: EdgeInsets.only(top:70),
                  child:

                  Scrollbar(
                    //ScrollbarIsTheSideScrollButtonWhichHelpsToScrollFurtherInScreen
                    thumbVisibility: true,
                    //ThumbVisibilityTrueToHaveTheScrollThumbAlwaysVisible
                    //paginationIsWidgetFromFireStore.HelpsToDownloadDataFromFirestore,
                    //AsTheUserScrollsDown.WeCanLimitToHowManyNeedsToBeDownloaded
                    //ThisWidgetIsPackageFromNetFlutterLibrary
                    //MostCodesBelowTakenRightFromTheExampleProvidedInPackage
                    child: PaginateFirestore(
                      // Use SliverAppBar in header to make it sticky
                      header: const SliverToBoxAdapter(
                          child: SizedBox(
                            height: 10.0,
                          )),
                      footer: const SliverToBoxAdapter(
                          child: SizedBox(
                            height: 10.0,
                          )),
                      // item builder type is compulsory.
                      itemBuilderType: PaginateBuilderType
                          .listView, //Change types accordingly
                      itemBuilder: (context, documentSnapshots, index) {
                        final data = documentSnapshots[index].data() as Map?;
                        return ListTile(
                          title: data == null
                              ? const Text('Error in data')
                              : EachExpenseBill(
                            eachBillMap: data,
                            editBill: editBill,
                          ),
                        );

                      },
                      // orderBy is compulsory to enable pagination
                      query:FirebaseFirestore.instance
                          .collection(
                          Provider.of<PrinterAndOtherDetailsProvider>(
                              context,
                              listen: false)
                              .chosenRestaurantDatabaseFromClass)
                          .doc('expensesBills')
                          .collection(chosenYearForViewingExpense)
                          .doc('month')
                          .collection(
                          chosenMonthNumberViewingExpenseInString
                      )
                          .orderBy('expenseBillId', descending: true),

                      itemsPerPage: 5,
                      // to fetch real-time data
                      isLive: true,
                      onEmpty: Center(child: Text('No Documents Found',style: TextStyle(
                          fontSize: 20
                      ),)),


                    ),
                  ),
                ):Center(
                  child: CircularProgressIndicator(color: Colors.green),
                )],
            ),
          ),
          floatingActionButton: Container(
            width: 75.0,
            height: 75.0,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
//            border: Border.all(
//          color: Colors.black87,
//          width: 0.2,
//        )
            ),
//FloatingActionButtonNameWillBeMenu
            child: FloatingActionButton(
              backgroundColor: Colors.white70,
              child: Icon(
                Icons.add,
                color: Colors.black,
                size: 35,
              ),
              onPressed: () {
                gotCashBalanceInfo = false;
                initialDateStringsSetting();
//ThisWillEnsureTheDocumentIdChangesEverytimeWeClickFloatingActionButton
                pickedDateTimeStamp = DateTime.now();
                _dateForAddingExpense = TextEditingController(
                    text: DateFormat('dd-MM-yyyy').format(DateTime.now()));
                dateForAddingExpense = DateFormat('dd-MM-yyyy').format(DateTime.now());
                tempExpenseCategoryToSave = '';
                tempTotalExpenseWithTaxesInString = '';
                tempNumberOfUnitsInString = '';
                tempPriceOfUnitInString = '';
                tempCgstPercentageOfItemInString = '';
                tempCgstValueOfItemInString = '';
                tempSgstPercentageOfItemInString = '';
                tempSgstValueOfItemInString = '';
                tempCgstPercentageOrValue = '%';
                tempSgstPercentageOrValue = '%';
                _totalExpenseWithTaxesEntryController.clear();
                _eachItemExpenseEntryController.clear();
                _numberOfItemsEntryController.clear();
                _cgstValueEntryController.clear();
                _sgstValueEntryController.clear();
                tempExpenseDescription = '';
                tempVendor = '';
                tempExpensePaidByUser = '';
                tempPaymentMethod = '';
                setState(() {
                  pageNumber = 2;
                });
              },
            ),
          ),
        ),
      );
    } else {
      return pageNumber == 2? WillPopScope(
        onWillPop: () async {
          setState(() {
            pageNumber = 1;
          });
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: kAppBarBackgroundColor,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: kAppBarBackIconColor),
              onPressed: () {
                setState(() {
                  pageNumber = 1;
                });
              },
            ),
            title: Text('Add New Expense', style: kAppBarTextStyle),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 10),
                Padding(
                  key: scrollKeyToExpenseCategory,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Text('Choose Category(Mandatory)', style: userInfoTextStyle),
                ),
                Container(
                  padding: EdgeInsets.all(10.0),
                  child: Autocomplete(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      } else {
                        return expenseCategories.where((word) => word
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()));
                      }
                    },
                    optionsViewBuilder:
                        (context, Function(String) onSelected, options) {
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            Material(
                              elevation: 16,
                              child: Container(
                                child: ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      final option =
                                      options.elementAt(index);
                                      return ListTile(
                                        title: Text(option.toString()),
                                        trailing: IconButton(
                                          onPressed: () {
                                            Map<String, dynamic>
                                            tempExpensesCategoriesMap =
                                            expensesSegregationMap[
                                            'expensesCategories'];
                                            String categoryOrVendorKey = '';
                                            tempExpensesCategoriesMap
                                                .forEach((key, value) {
                                              if (value ==
                                                  option.toString()) {
                                                categoryOrVendorKey = key;
                                              }
                                            });

                                            showModalBottomSheet(
                                                isScrollControlled: true,
                                                context: context,
                                                builder: (context) {
                                                  return categoryVendorPaidByPaymentMethodEditDeleteBottomBar(
                                                      context,
                                                      'category',
                                                      option.toString(),
                                                      categoryOrVendorKey);
                                                });
                                          },
                                          icon: Icon(Icons.edit,
                                              color: Colors.green),
                                        ),
                                        onTap: () {
                                          onSelected(option.toString());
                                        },
                                      );
                                    },
                                    separatorBuilder: (context, index) =>
                                        Divider(),
                                    itemCount: options.length),
                              ),
                            ),
                            SizedBox(height: 300)
                          ],
                        ),
                      );
                    },
                    onSelected: (selectedString) {
                      setState(() {
                        tempExpenseCategoryToSave = selectedString;
                      });
                    },
                    fieldViewBuilder: (context,
                        controller,
                        focusNode,
                        onEditingComplete) {
                      return TextField(
                        focusNode: focusNode,
                        maxLength: 40,
                        controller: controller,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (value) {
                          tempExpenseCategoryToSave = value;
                        },
                        decoration:
                        // kTextFieldInputDecoration,
                        InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Enter Category',
                            hintStyle: TextStyle(color: Colors.grey),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(10)),
                                borderSide:
                                BorderSide(color: Colors.green)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(10)),
                                borderSide:
                                BorderSide(color: Colors.green))),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Text('Description', style: userInfoTextStyle),
                ),
                Container(
                    padding: EdgeInsets.all(10),
                    child: TextField(
                      maxLength: 40,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (value) {
                        tempExpenseDescription = value;
                      },
                      decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Enter Description',
                          hintStyle: TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.all(Radius.circular(10)),
                              borderSide:
                              BorderSide(color: Colors.green)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.all(Radius.circular(10)),
                              borderSide:
                              BorderSide(color: Colors.green))),
                    )),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Text('Vendor/Receiver', style: userInfoTextStyle),
                ),
//Date
                Container(
                  padding: EdgeInsets.all(10.0),
                  child: Autocomplete(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                        //return expensesVendors;
                        // IfWeDecideToShowEveryCategory
                      } else {
                        return expensesVendors.where((word) => word
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()));
                      }
                    },
                    optionsViewBuilder:
                        (context, Function(String) onSelected, options) {
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            Material(
                              elevation: 16,
                              child: Container(
                                child: ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      final option =
                                      options.elementAt(index);
                                      return ListTile(
                                        title: Text(option.toString()),
                                        trailing: IconButton(
                                          onPressed: () {
                                            Map<String, dynamic>
                                            tempExpensesVendorsMap =
                                            expensesSegregationMap[
                                            'expensesVendors'];
                                            String categoryOrVendorKey = '';
                                            tempExpensesVendorsMap
                                                .forEach((key, value) {
                                              if (value ==
                                                  option.toString()) {
                                                categoryOrVendorKey = key;
                                              }
                                            });
                                            _editCategoryVendorPaidByPaymentMethodController
                                                .text = option.toString();
                                            showModalBottomSheet(
                                                isScrollControlled: true,
                                                context: context,
                                                builder: (context) {
                                                  return categoryVendorPaidByPaymentMethodEditDeleteBottomBar(
                                                      context,
                                                      'vendor',
                                                      option.toString(),
                                                      categoryOrVendorKey);
                                                });
                                          },
                                          icon: Icon(Icons.edit,
                                              color: Colors.green),
                                        ),
                                        onTap: () {
                                          onSelected(option.toString());
                                        },
                                      );
                                    },
                                    separatorBuilder: (context, index) =>
                                        Divider(),
                                    itemCount: options.length),
                              ),
                            ),
                            SizedBox(height: 300)
                          ],
                        ),
                      );
                    },
                    onSelected: (selectedString) {
                      setState(() {
                        tempVendor = selectedString;
                      });
                    },
                    fieldViewBuilder: (context, controller, focusNode,
                        onEditingComplete) {
                      return TextField(
                        focusNode: focusNode,
                        maxLength: 40,
                        controller: controller,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (value) {
                          tempVendor = value;
                        },
                        decoration:
                        // kTextFieldInputDecoration,
                        InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Enter Vendor',
                            hintStyle: TextStyle(color: Colors.grey),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(10)),
                                borderSide:
                                BorderSide(color: Colors.green)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(10)),
                                borderSide:
                                BorderSide(color: Colors.green))),
                      );
                    },
                  ),
                ),
                ListTile(
                  leading: Text('Date',style: userInfoTextStyle),
                  title: Row(
                    children: [
                      ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor:
                            MaterialStateProperty.all<Color>(
                                Colors.green)),
                        child: Text(dateForAddingExpense,style: TextStyle(fontSize: 20)),
                        onPressed: ()async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialEntryMode:
                            DatePickerEntryMode.calendarOnly,
                            builder: (context, child) {
                              return Theme(
                                  data: Theme.of(context).copyWith(
                                      dialogTheme: DialogTheme(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                16.0), // this is the border radius of the picker
                                          )),
                                      colorScheme: ColorScheme(
                                          brightness: Brightness.light,
                                          primary: Colors.green,
                                          onPrimary: Colors.black,
                                          secondary: Colors.white,
                                          onSecondary: Colors.white,
                                          error: Colors.red,
                                          onError: Colors.black,
                                          background: Colors.white,
                                          onBackground: Colors.black,
                                          surface: Colors.white,
                                          onSurface: Colors.black)),
                                  child: child!);
                            },
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now().millisecondsSinceEpoch>=DateTime(2025,5,1).millisecondsSinceEpoch? DateTime(DateTime.now().year-1, DateTime.now().month, DateTime.now().day):
                            DateTime(2024,5,1),
                            lastDate: DateTime.now(),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              dateForAddingExpense =
                                  DateFormat('dd-MM-yyyy').format(pickedDate);
                            });
                            chosenDateStringsSetting(pickedDate);
                          }
                        },
                      ),
                    ],
                  ),
                ),
//PaidBy:
                Padding(
                  key: scrollKeyToExpensePaidByUser,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Text('Paid By(Mandatory)', style: userInfoTextStyle),
                ),
                Container(
                  padding: EdgeInsets.all(10.0),
                  child: Autocomplete(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      } else {
                        return expensesPaidByUser.where((word) => word
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()));
                      }
                    },
                    optionsViewBuilder:
                        (context, Function(String) onSelected, options) {
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            Material(
                              elevation: 16,
                              child: Container(
                                child: ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      final option =
                                      options.elementAt(index);
                                      return ListTile(
                                        title: Text(option.toString()),
                                        trailing: IconButton(
                                          onPressed: () {
                                            Map<String, dynamic>
                                            tempExpensesPaidByUsersMap =
                                            expensesSegregationMap[
                                            'expensesPaidByUser'];
                                            String categoryVendorPaidByPaymentMethodKey = '';
                                            tempExpensesPaidByUsersMap
                                                .forEach((key, value) {
                                              if (value ==
                                                  option.toString()) {
                                                categoryVendorPaidByPaymentMethodKey = key;
                                              }
                                            });

                                            showModalBottomSheet(
                                                isScrollControlled: true,
                                                context: context,
                                                builder: (context) {
                                                  return categoryVendorPaidByPaymentMethodEditDeleteBottomBar(
                                                      context,
                                                      'paidByUser',
                                                      option.toString(),
                                                      categoryVendorPaidByPaymentMethodKey);
                                                });
                                          },
                                          icon: Icon(Icons.edit,
                                              color: Colors.green),
                                        ),
                                        onTap: () {
                                          onSelected(option.toString());
                                        },
                                      );
                                    },
                                    separatorBuilder: (context, index) =>
                                        Divider(),
                                    itemCount: options.length),
                              ),
                            ),
                            SizedBox(height: 300)
                          ],
                        ),
                      );
                    },
                    onSelected: (selectedString) {
                      setState(() {
                        tempExpensePaidByUser = selectedString;
                      });
                    },
                    fieldViewBuilder: (context,
                        controller,
                        focusNode,
                        onEditingComplete) {
                      return TextField(
                        focusNode: focusNode,
                        maxLength: 40,
                        controller: controller,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (value) {
                          tempExpensePaidByUser = value;
                        },
                        decoration:
                        // kTextFieldInputDecoration,
                        InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Paid By:',
                            hintStyle: TextStyle(color: Colors.grey),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(10)),
                                borderSide:
                                BorderSide(color: Colors.green)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(10)),
                                borderSide:
                                BorderSide(color: Colors.green))),
                      );
                    },
                  ),
                ),
//PaymentMethod
                Padding(
                  key:scrollKeyToExpensePaymentMethod,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Text('Payment Method(Mandatory)', style: userInfoTextStyle),
                ),
                Container(
                  padding: EdgeInsets.all(10.0),
                  child: Autocomplete(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      } else {
                        return paymentMethod.where((word) => word
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()));
                      }
                    },
                    optionsViewBuilder:
                        (context, Function(String) onSelected, options) {
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            Material(
                              elevation: 16,
                              child: Container(
                                child: ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      final option =
                                      options.elementAt(index);
                                      return ListTile(
                                        title: Text(option.toString()),
                                        trailing: IconButton(
                                          onPressed: () {
                                            Map<String, dynamic>
                                            tempPaymentMethodMap =
                                            expensesSegregationMap[
                                            'paymentMethod'];
                                            String categoryVendorPaidByPaymentMethodKey = '';
                                            tempPaymentMethodMap
                                                .forEach((key, value) {
                                              if (value ==
                                                  option.toString()) {
                                                categoryVendorPaidByPaymentMethodKey = key;
                                              }
                                            });

                                            showModalBottomSheet(
                                                isScrollControlled: true,
                                                context: context,
                                                builder: (context) {
                                                  return categoryVendorPaidByPaymentMethodEditDeleteBottomBar(
                                                      context,
                                                      'paymentMethod',
                                                      option.toString(),
                                                      categoryVendorPaidByPaymentMethodKey);
                                                });
                                          },
                                          icon: Icon(Icons.edit,
                                              color: Colors.green),
                                        ),
                                        onTap: () {
                                          onSelected(option.toString());
                                        },
                                      );
                                    },
                                    separatorBuilder: (context, index) =>
                                        Divider(),
                                    itemCount: options.length),
                              ),
                            ),
                            SizedBox(height: 300)
                          ],
                        ),
                      );
                    },
                    onSelected: (selectedString) {
                      setState(() {
                        tempPaymentMethod = selectedString;
                      });
                    },
                    fieldViewBuilder: (context,
                        controller,
                        focusNode,
                        onEditingComplete) {
                      return TextField(
                        focusNode: focusNode,
                        maxLength: 40,
                        controller: controller,
                        onChanged: (value) {
                          tempPaymentMethod = value;
                        },
                        decoration:
                        // kTextFieldInputDecoration,
                        InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Payment Method',
                            hintStyle: TextStyle(color: Colors.grey),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(10)),
                                borderSide:
                                BorderSide(color: Colors.green)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(10)),
                                borderSide:
                                BorderSide(color: Colors.green))),
                      );
                    },
                  ),
                ),
//UnitPrice
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Text('Unit Price', style: userInfoTextStyle),
                ),
                Container(
                  padding: EdgeInsets.all(10),
                  child: TextField(
                    maxLength: 10,
                    controller: _eachItemExpenseEntryController,
                    keyboardType:
                    TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      tempPriceOfUnitInString = value;
                      expensesCalculationForNewExpense();
                    },
                    decoration:
                    // kTextFieldInputDecoration,
                    InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Unit Price',
                        hintStyle: TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(10)),
                            borderSide:
                            BorderSide(color: Colors.green)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(10)),
                            borderSide:
                            BorderSide(color: Colors.green))),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Text('Number of Units', style: userInfoTextStyle),
                ),
                Container(
                  padding: EdgeInsets.all(10),
                  child: TextField(
                    maxLength: 10,
                    controller: _numberOfItemsEntryController,
                    keyboardType:
                    TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      tempNumberOfUnitsInString = value;
                      expensesCalculationForNewExpense();
                    },
                    decoration:
                    // kTextFieldInputDecoration,
                    InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Number of Units',
                        hintStyle: TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(10)),
                            borderSide:
                            BorderSide(color: Colors.green)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(10)),
                            borderSide:
                            BorderSide(color: Colors.green))),
                  ),
                ),
//CgstPercentageOrValue
                ListTile(
                  leading: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'CGST',
                      style: TextStyle(fontSize: 25, color: Colors.green),
                    ),
                  ),
                  title: Container(
                    padding: EdgeInsets.only(
                        left: 5, top: 10, right: 10, bottom: 10)
                    // EdgeInsets.all(10.0)
                    ,
                    child: tempCgstPercentageOrValue == '%'
                        ? Autocomplete(
                      optionsBuilder:
                          (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        } else {
                          return expensesCgstPercentage.where(
                                  (word) => word.toLowerCase().contains(
                                  textEditingValue.text
                                      .toLowerCase()));
                        }
                      },
                      optionsViewBuilder: (context,
                          Function(String) onSelected, options) {
                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              Material(
                                elevation: 16,
                                child: Container(
                                  child: ListView.separated(
                                      shrinkWrap: true,
                                      padding: EdgeInsets.zero,
                                      physics:
                                      NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        final option =
                                        options.elementAt(index);
                                        return ListTile(
                                          title:
                                          Text(option.toString()),
                                          onTap: () {
                                            onSelected(
                                                option.toString());
                                          },
                                        );
                                      },
                                      separatorBuilder:
                                          (context, index) =>
                                          Divider(),
                                      itemCount: options.length),
                                ),
                              ),
                              SizedBox(height: 300)
                            ],
                          ),
                        );
                      },
                      onSelected: (selectedString) {
                        setState(() {
                          tempCgstPercentageOfItemInString =
                              selectedString;
                          expensesCalculationForNewExpense();
                        });
                      },
                      fieldViewBuilder: (context, controller,
                          focusNode, onEditingComplete) {
                        return TextField(
                          focusNode: focusNode,
                          // maxLength: 40,
                          controller: controller,
                          keyboardType:
                          TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (value) {
                            tempCgstPercentageOfItemInString = value;
                            expensesCalculationForNewExpense();
                          },
                          decoration:
                          // kTextFieldInputDecoration,
                          InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Enter Cgst%',
                              hintStyle:
                              TextStyle(color: Colors.grey),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(10)),
                                  borderSide: BorderSide(
                                      color: Colors.green)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(10)),
                                  borderSide: BorderSide(
                                      color: Colors.green))),
                        );
                      },
                    )
                        : TextField(
                      maxLength: 10,
                      controller: _cgstValueEntryController,
                      keyboardType: TextInputType.numberWithOptions(
                          decimal: true),
                      onChanged: (value) {
                        setState(() {
                          tempCgstValueOfItemInString = value;
                          expensesCalculationForNewExpense();
                        });
                      },
                      decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Cgst Value',
                          hintStyle:
                          TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                  Radius.circular(10)),
                              borderSide: BorderSide(
                                  color: Colors.green)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                  Radius.circular(10)),
                              borderSide: BorderSide(
                                  color: Colors.green))),
                    ),
                  ),
                  trailing: Container(
                    decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(5)),
                    width: 50,
                    height: 50,
                    // height: 200,
                    child: Center(
                      child: DropdownButtonFormField(
                        decoration: InputDecoration.collapsed(hintText: ''),
                        isExpanded: true,
                        // underline: Container(),
                        dropdownColor: Colors.green,
                        value: tempCgstPercentageOrValue,
                        onChanged: (value) {
                          setState(() {
                            tempCgstPercentageOrValue = value.toString();
                            tempCgstValueOfItemInString = '';
                            tempCgstPercentageOfItemInString = '';
                            expensesCalculationForNewExpense();
                            _cgstValueEntryController.clear();
                          });
                        },
                        items: gstPercentageOrValue.map((gstChoices) {
//DropDownMenuItemWillHaveOneByOneItems,WePutThatAsList
//ValueWillBeEachTitle
                          return DropdownMenuItem(
                            alignment: Alignment.center,
                            child: Text(gstChoices,
                                style: const TextStyle(
                                    fontSize: 25, color: Colors.white)),
                            value: gstChoices,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  subtitle: Visibility(
                      visible: (tempCgstPercentageOrValue == '%' &&
                          tempCgstPercentageOfItemInString != '')
                          ? true
                          : false,
                      child: Text(
                        '₹$tempCgstValueOfItemInString(CGST Amount)',
                        style: TextStyle(fontSize: 20, color: Colors.green),
                        textAlign: TextAlign.left,
                      )),
                ),
//SgstPercentageOrValue
                ListTile(
                  leading: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'SGST',
                      style: TextStyle(fontSize: 25, color: Colors.green),
                    ),
                  ),
                  title: Container(
                    padding: EdgeInsets.only(
                        left: 5, top: 10, right: 10, bottom: 10)
                    // EdgeInsets.all(10.0)
                    ,
                    child: tempSgstPercentageOrValue == '%'
                        ? Autocomplete(
                      optionsBuilder:
                          (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        } else {
                          return expensesSgstPercentage.where(
                                  (word) => word.toLowerCase().contains(
                                  textEditingValue.text
                                      .toLowerCase()));
                        }
                      },
                      optionsViewBuilder: (context,
                          Function(String) onSelected, options) {
                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              Material(
                                elevation: 16,
                                child: Container(
                                  child: ListView.separated(
                                      shrinkWrap: true,
                                      padding: EdgeInsets.zero,
                                      physics:
                                      NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        final option =
                                        options.elementAt(index);
                                        return ListTile(
                                          title:
                                          Text(option.toString()),
                                          onTap: () {
                                            onSelected(
                                                option.toString());
                                          },
                                        );
                                      },
                                      separatorBuilder:
                                          (context, index) =>
                                          Divider(),
                                      itemCount: options.length),
                                ),
                              ),
                              SizedBox(height: 300)
                            ],
                          ),
                        );
                      },
                      onSelected: (selectedString) {
                        setState(() {
                          tempSgstPercentageOfItemInString =
                              selectedString;
                          expensesCalculationForNewExpense();
                        });
                      },
                      fieldViewBuilder: (context, controller,
                          focusNode, onEditingComplete) {
                        return TextField(
                          focusNode: focusNode,
                          // maxLength: 40,
                          controller: controller,
                          keyboardType:
                          TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (value) {
                            tempSgstPercentageOfItemInString = value;
                            expensesCalculationForNewExpense();
                          },
                          decoration:
                          // kTextFieldInputDecoration,
                          InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Enter Sgst%',
                              hintStyle:
                              TextStyle(color: Colors.grey),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(10)),
                                  borderSide: BorderSide(
                                      color: Colors.green)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(10)),
                                  borderSide: BorderSide(
                                      color: Colors.green))),
                        );
                      },
                    )
                        : TextField(
                      maxLength: 10,
                      controller: _sgstValueEntryController,
                      keyboardType: TextInputType.numberWithOptions(
                          decimal: true),
                      onChanged: (value) {
                        setState(() {
                          tempSgstValueOfItemInString = value;
                          // expensesCalculation();
                        });
                      },
                      decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Sgst Value',
                          hintStyle:
                          TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                  Radius.circular(10)),
                              borderSide: BorderSide(
                                  color: Colors.green)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                  Radius.circular(10)),
                              borderSide: BorderSide(
                                  color: Colors.green))),
                    ),
                  ),
                  trailing: Container(
                    decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(5)),
                    width: 50,
                    height: 50,
                    // height: 200,
                    child: Center(
                      child: DropdownButtonFormField(
                        decoration: InputDecoration.collapsed(hintText: ''),
                        isExpanded: true,
                        // underline: Container(),
                        dropdownColor: Colors.green,
                        value: tempSgstPercentageOrValue,
                        onChanged: (value) {
                          setState(() {
                            tempSgstPercentageOrValue = value.toString();
                            tempSgstValueOfItemInString = '';
                            tempSgstPercentageOfItemInString = '';
                            expensesCalculationForNewExpense();
                            _sgstValueEntryController.clear();
                          });
                        },
                        items: gstPercentageOrValue.map((gstChoices) {
//DropDownMenuItemWillHaveOneByOneItems,WePutThatAsList
//ValueWillBeEachTitle
                          return DropdownMenuItem(
                            alignment: Alignment.center,
                            child: Text(gstChoices,
                                style: const TextStyle(
                                    fontSize: 25, color: Colors.white)),
                            value: gstChoices,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  subtitle: Visibility(
                      visible: (tempSgstPercentageOrValue == '%' &&
                          tempSgstPercentageOfItemInString != '')
                          ? true
                          : false,
                      child: Text(
                        '₹$tempSgstValueOfItemInString(SGST Amount)',
                        style: TextStyle(fontSize: 20, color: Colors.green),
                        textAlign: TextAlign.left,
                      )),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child:
                  Text('Enter Total Price', style: userInfoTextStyle),
                ),
                Container(
                  padding: EdgeInsets.all(10),
                  child: TextField(
                    maxLength: 10,
                    controller: _totalExpenseWithTaxesEntryController,
                    keyboardType:
                    TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      tempTotalExpenseWithTaxesInString = value;
                    },
                    decoration:
                    // kTextFieldInputDecoration,
                    InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Total Price',
                        hintStyle: TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(10)),
                            borderSide:
                            BorderSide(color: Colors.green)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(10)),
                            borderSide:
                            BorderSide(color: Colors.green))),
                  ),
                ),
                Divider(thickness: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor:
                            MaterialStateProperty.all<Color>(
                                Colors.orangeAccent)),
                        onPressed: () {
                          setState(() {
                            pageNumber = 1;
                          });
                        },
                        child: Text('Cancel', style: TextStyle(fontSize: 20))),
                    ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor:
                            MaterialStateProperty.all<Color>(
                                Colors.green)),
                        onPressed: () {
                          if (tempExpenseCategoryToSave == '') {
                            show('Please enter Category');
                            Scrollable.ensureVisible(
                                scrollKeyToExpenseCategory.currentContext!);
                          } else if(
                          tempExpensePaidByUser == ''
                          ){
                            Scrollable.ensureVisible(
                                scrollKeyToExpensePaidByUser.currentContext!);
                            show('Please enter the user who paid');}else if(
                          tempPaymentMethod == ''
                          ){
                            show('Please enter the Payment Method');

                            Scrollable.ensureVisible(
                                scrollKeyToExpensePaymentMethod.currentContext!);
                          }
                          else if (tempTotalExpenseWithTaxesInString ==
                              '') {
                            show('Please enter Total Price');
                          } else if (num.parse(
                              tempTotalExpenseWithTaxesInString) ==
                              0) {
                            show('Please enter Total Price');
                          }  else {
                            if(gotCashBalanceInfo){
//ThisMeansTheStreamForFindingCashBalanceWasSuccessfulWithInternet
                              eachDayCashBalanceUpdateMap = {};
//ThisIsForUpdatingEachDay
                              continuousCashBalanceIterationMap = {};
//ThisIsForAddingToCashBalance
                              if(
                              pickedDateTimeStamp.year == DateTime.now().year &&
                                      pickedDateTimeStamp.month == DateTime.now().month &&
                                      pickedDateTimeStamp.day == DateTime.now().day
//ThisMeansItsToday
                              ){
                                if(lastCashYear != DateTime.now().year ||
                                    lastCashMonth != DateTime.now().month ||
                                    lastCashDay != DateTime.now().day){
//ThisMeansTodayCashIterationHasNotHappenedEvenOnce
//thisMeansToday'sStartingCashBalanceNeedsToBeStored
//FirstWeUpdateContinuousCashBalance
                                  continuousCashBalanceIterationMap.addAll({
                                    'amount': tempPaymentMethod == 'Cash'?FieldValue.increment(
                                        num.parse(
                                            tempTotalExpenseWithTaxesInString)*-1):
                                    FieldValue.increment(0),
                                    'year': pickedDateTimeStamp.year,
                                    'month':pickedDateTimeStamp.month,
                                    'day':pickedDateTimeStamp.day
                                  });
//hereWeSaveTheStartingCashBalanceOfThatDay
                                  eachDayCashBalanceUpdateMap.addAll({
                                    day:cashBalance
                                  });
                                }else if(//ThisMeansStartingBalanceWasAlreadySavedOnce
                                (lastCashYear == DateTime.now().year ||
                                    lastCashMonth == DateTime.now().month ||
                                    lastCashDay == DateTime.now().day) && tempPaymentMethod == 'Cash'){
                                  continuousCashBalanceIterationMap.addAll({
                                    'amount': FieldValue.increment(
                                        num.parse(
                                            tempTotalExpenseWithTaxesInString)*-1),
                                    'year': pickedDateTimeStamp.year,
                                    'month':pickedDateTimeStamp.month,
                                    'day':pickedDateTimeStamp.day
                                  });
                                }
                              }else if(
                              tempPaymentMethod != 'Cash'
                              ){
//ThisMeansItsNotTodayAndIncrementIsNotInCash
//InThisCase,WeOnlyNeedToCheckWhetherSomeDataForTheDayAlreadyExists
//
                              }

                              bool expensesSegregationUpdationNeeded = false;
                              int expensesUpdateTimeInMilliseconds =
                                  DateTime.now().millisecondsSinceEpoch;
                              Map<String, dynamic>
                              expensesSegregationUpdateMap = HashMap();
                              if (!expenseCategories
                                  .contains(tempExpenseCategoryToSave)) {
                                expensesSegregationUpdationNeeded = true;
                                Map<String, dynamic>
                                tempExpensesCategoriesMap =
                                expensesSegregationMap[
                                'expensesCategories'];
                                List<num> currentCategoriesKey = [];
                                tempExpensesCategoriesMap
                                    .forEach((key, value) {
                                  currentCategoriesKey.add(num.parse(key));
                                });
//WeAreGettingTheMaxValueOfTheKeyWeHaveInCategoriesAndAddingItByOne
                                num newCategoryKey =
                                    currentCategoriesKey.reduce(max) + 1;
//ThisIsForLocalUpdate
                                tempExpensesCategoriesMap.addAll({
                                  newCategoryKey.toString():
                                  tempExpenseCategoryToSave
                                });
                                expensesSegregationMap['expensesCategories'] =
                                    tempExpensesCategoriesMap;
//ThisIsForServerUpdate
                                expensesSegregationUpdateMap.addAll({
                                  'expensesCategories': {
                                    newCategoryKey.toString():
                                    tempExpenseCategoryToSave
                                  }
                                });
                              }
                              if (!expensesVendors.contains(tempVendor) &&
                                  tempVendor != '') {
                                expensesSegregationUpdationNeeded = true;
                                Map<String, dynamic> tempVendorsMap =
                                expensesSegregationMap['expensesVendors'];
                                num newVendorKey = 111111;
                                if (tempVendorsMap.isNotEmpty) {
                                  List<num> currentVendorsKey = [];
                                  tempVendorsMap.forEach((key, value) {
                                    currentVendorsKey.add(num.parse(key));
                                  });
                                  newVendorKey =
                                      currentVendorsKey.reduce(max) + 1;
                                }
//WeAreGettingTheMaxValueOfTheKeyWeHaveInCategoriesAndAddingItByOne
                                //ThisIsForLocalUpdate
                                tempVendorsMap.addAll(
                                    {newVendorKey.toString(): tempVendor});
                                expensesSegregationMap['expensesVendors'] =
                                    tempVendorsMap;

                                expensesSegregationUpdateMap.addAll({
                                  'expensesVendors': {
                                    newVendorKey.toString(): tempVendor
                                  }
                                });
                              }
//NewUserInPaidUser
                              if(!expensesPaidByUser.contains(tempExpensePaidByUser)
                                  && tempExpensePaidByUser != ''
                              ){
                                expensesSegregationUpdationNeeded = true;

                                Map<String, dynamic> tempExpensePaidByUserMap =
                                expensesSegregationMap['expensesPaidByUser'];
                                num newPaidByUserKey = 11111111;
                                if (tempExpensePaidByUserMap.isNotEmpty) {
                                  List<num> currentPaidByUserKey = [];
                                  tempExpensePaidByUserMap.forEach((key, value) {
                                    currentPaidByUserKey.add(num.parse(key));
                                  });
                                  newPaidByUserKey =
                                      currentPaidByUserKey.reduce(max) + 1;
                                }
//WeAreGettingTheMaxValueOfTheKeyWeHaveInCategoriesAndAddingItByOne
                                //ThisIsForLocalUpdate
                                tempExpensePaidByUserMap.addAll(
                                    {newPaidByUserKey.toString(): tempExpensePaidByUser});
                                expensesSegregationMap['expensesPaidByUser'] =
                                    tempExpensePaidByUserMap;

                                expensesSegregationUpdateMap.addAll({
                                  'expensesPaidByUser': {
                                    newPaidByUserKey.toString(): tempExpensePaidByUser
                                  }
                                });
                              }
//NewPaymentMethod
                              if(!paymentMethod.contains(tempPaymentMethod)
                                  && tempPaymentMethod != ''
                              ){
                                expensesSegregationUpdationNeeded = true;

                                Map<String, dynamic> tempPaymentMethodMap =
                                expensesSegregationMap['paymentMethod'];
                                num newPaymentMethodKey = 111111111;
                                if (tempPaymentMethodMap.isNotEmpty) {
                                  List<num> currentPaymentMethodKey = [];
                                  tempPaymentMethodMap.forEach((key, value) {
                                    currentPaymentMethodKey.add(num.parse(key));
                                  });
                                  newPaymentMethodKey =
                                      currentPaymentMethodKey.reduce(max) + 1;
                                }
//WeAreGettingTheMaxValueOfTheKeyWeHaveInCategoriesAndAddingItByOne
                                //ThisIsForLocalUpdate
                                tempPaymentMethodMap.addAll(
                                    {newPaymentMethodKey.toString(): tempPaymentMethod});
                                expensesSegregationMap['paymentMethod'] =
                                    tempPaymentMethodMap;

                                expensesSegregationUpdateMap.addAll({
                                  'paymentMethod': {
                                    newPaymentMethodKey.toString(): tempPaymentMethod
                                  }
                                });
                              }

//newCgstPercentage
                              if (!expensesCgstPercentage.contains(
                                  tempCgstPercentageOfItemInString) &&
                                  tempCgstPercentageOfItemInString != '') {
                                expensesSegregationUpdationNeeded = true;
//ThisIsForServerUpdate
                                expensesSegregationUpdateMap.addAll({
                                  'expensesCgstPercentage': {
                                    tempCgstPercentageOfItemInString: true
                                  }
                                });
//ThisIsForLocalUpdate
                                Map<String, dynamic>
                                tempExpensesCgstPercentageMap =
                                expensesSegregationMap[
                                'expensesCgstPercentage'];
                                tempExpensesCgstPercentageMap.addAll(
                                    {tempCgstPercentageOfItemInString: true});
                                expensesSegregationMap[
                                'expensesCgstPercentage'] =
                                    tempExpensesCgstPercentageMap;
                              }
                              if (!expensesSgstPercentage.contains(
                                  tempSgstPercentageOfItemInString) &&
                                  tempSgstPercentageOfItemInString != '') {
                                expensesSegregationUpdationNeeded = true;
                                expensesSegregationUpdateMap.addAll({
                                  'expensesSgstPercentage': {
                                    tempSgstPercentageOfItemInString: true
                                  }
                                });
//ThisIsForLocalUpdate
                                Map<String, dynamic>
                                tempExpensesSgstPercentageMap =
                                expensesSegregationMap[
                                'expensesSgstPercentage'];
                                tempExpensesSgstPercentageMap.addAll(
                                    {tempSgstPercentageOfItemInString: true});
                                expensesSegregationMap[
                                'expensesSgstPercentage'] =
                                    tempExpensesSgstPercentageMap;
                              }
//FirstWeMakeItForExpensesBills
                              Map<String, dynamic> masterExpensesBills =
                              HashMap();
                              masterExpensesBills.addAll({
                                'username': json.decode(Provider.of<
                                    PrinterAndOtherDetailsProvider>(
                                    context,
                                    listen: false)
                                    .allUserProfilesFromClass)[Provider.of<
                                    PrinterAndOtherDetailsProvider>(
                                    context,
                                    listen: false)
                                    .currentUserPhoneNumberFromClass]['username'],
                                'userPhoneNumber': Provider.of<
                                    PrinterAndOtherDetailsProvider>(
                                    context,
                                    listen: false)
                                    .currentUserPhoneNumberFromClass,
                                'category': tempExpenseCategoryToSave,
                                'description': tempExpenseDescription,
                                'vendor': tempVendor,
                                'paidBy': tempExpensePaidByUser,
                                'paymentMethod': tempPaymentMethod,
                                'date': '$year*$month*$day',
                                'expenseBillId':
                                '$year$month$day$tempNumberOfMillisecondsPassedToday',
                                'unitPrice': tempPriceOfUnitInString,
                                'numberOfUnits': tempNumberOfUnitsInString,
                                'cgstPercentage':
                                tempCgstPercentageOfItemInString,
                                'cgstValue': tempCgstValueOfItemInString,
                                'sgstPercentage':
                                tempSgstPercentageOfItemInString,
                                'sgstValue': tempSgstValueOfItemInString,
                                'totalPrice': num.parse(
                                    tempTotalExpenseWithTaxesInString)
                              });
                              Map<String, dynamic>
                              subMasterExpensesStatistics = HashMap();
                              subMasterExpensesStatistics.addAll({
                                'mapEachExpenseStatisticsMap':{tempExpenseCategoryToSave: {
//noOfTimesThatItemWasBought
                                  'numberOfEntriesOfCategory': FieldValue.increment(1),
                                  'numberOfUnits':
                                  tempNumberOfUnitsInString != ''
                                      ? FieldValue.increment(num.parse(
                                      tempNumberOfUnitsInString))
                                      : 0,
                                  'cgstValue':
                                  tempCgstValueOfItemInString != ''
                                      ? FieldValue.increment(num.parse(
                                      tempCgstValueOfItemInString))
                                      : 0,
                                  'sgstValue':
                                  tempSgstValueOfItemInString != ''
                                      ? FieldValue.increment(num.parse(
                                      tempSgstValueOfItemInString))
                                      : 0,
                                  'totalPrice': FieldValue.increment(
                                      num.parse(
                                          tempTotalExpenseWithTaxesInString))}
                                }
                              });
                              subMasterExpensesStatistics.addAll({
                                'mapExpensePaidByUserMap':{
                                  tempExpensePaidByUser: {
                                    //noOfTimesTheUserPaid
                                    'numberOfEntriesOfUserPaying': FieldValue.increment(1),
                                    'paidAmount':FieldValue.increment(
                                        num.parse(tempTotalExpenseWithTaxesInString)
                                    )}
                                }
                              });
                              subMasterExpensesStatistics.addAll({
                                'mapExpensePaymentMethodMap':{
                                  tempPaymentMethod: {
                                    //noOfTimesThePaymentMethodWasUser
                                    'numberOfEntriesInPaymentMethod': FieldValue.increment(1),
                                    'paidAmount':
                                    FieldValue.increment(
                                        num.parse(tempTotalExpenseWithTaxesInString)
                                    )}
                                }
                              });
                              subMasterExpensesStatistics.addAll({
                                'arrayExpenseCategoryArray': FieldValue.arrayUnion(
                                    [tempExpenseCategoryToSave])
                              });
                              if (tempExpenseDescription != '') {
                                subMasterExpensesStatistics.addAll({
                                  'arrayExpenseDescriptionArray': FieldValue.arrayUnion(
                                      [tempExpenseDescription])
                                });
                              }
                              if (tempVendor != '') {
                                subMasterExpensesStatistics.addAll({
                                  'arrayExpenseVendorArray':
                                  FieldValue.arrayUnion([tempVendor])
                                });
                              }
                              Map<String,dynamic> statisticsDailyExpensesMap = {'day': num.parse(day),'month': num.parse(month),'year':num.parse(year) };
                              Map<String,dynamic> statisticsMonthlyExpensesMap = {'month': num.parse(month) ,'year':num.parse(year)};

                              Map<String, dynamic> masterExpensesStatistics =
                              {'expenses': subMasterExpensesStatistics};
                              statisticsDailyExpensesMap.addAll(masterExpensesStatistics);
                              statisticsMonthlyExpensesMap.addAll(masterExpensesStatistics);

                              FireStoreAddNewExpenseWithBatch(
                                  hotelName: Provider.of<
                                      PrinterAndOtherDetailsProvider>(
                                      context,
                                      listen: false)
                                      .chosenRestaurantDatabaseFromClass,
                                  expenseBillName:
                                  '$year$month$day$tempNumberOfMillisecondsPassedToday',
                                  expensesBillMap: masterExpensesBills,
                                  year: year,
                                  month: month,
                                  day: day,
                                  statisticsDailyExpensesMap:
                                  statisticsDailyExpensesMap,
                                  statisticsMonthlyExpensesMap: statisticsMonthlyExpensesMap,
                                  expensesSegregationUpdateMap:
                                  expensesSegregationUpdateMap,
                                  expensesUpdateTimeInMilliseconds:
                                  expensesUpdateTimeInMilliseconds)
                                  .addExpense();
                              if (expensesSegregationUpdationNeeded) {
                                final fcmProvider =
                                Provider.of<NotificationProvider>(context,
                                    listen: false);
                                fcmProvider.sendNotification(
                                    token: dynamicTokensToStringToken(),
                                    title: Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                                        .chosenRestaurantDatabaseFromClass,
                                    restaurantNameForNotification: json.decode(
                                        Provider.of<PrinterAndOtherDetailsProvider>(
                                            context,
                                            listen: false)
                                            .allUserProfilesFromClass)[
                                    Provider.of<PrinterAndOtherDetailsProvider>(
                                        context,
                                        listen: false)
                                        .currentUserPhoneNumberFromClass]
                                    ['restaurantName'],
                                    body: '*restaurantInfoUpdated*');
                                Provider.of<PrinterAndOtherDetailsProvider>(
                                    context,
                                    listen: false)
                                    .expensesSegregationTimeStampSaving(
                                    expensesUpdateTimeInMilliseconds,
                                    json.encode(expensesSegregationMap));
                                expensesSegregationData();
                                expensesSegregationUpdationNeeded = false;
                              }
                              tempExpenseCategoryToSave = '';
                              tempTotalExpenseWithTaxesInString = '';
                              tempNumberOfUnitsInString = '';
                              tempPriceOfUnitInString = '';
                              tempCgstPercentageOfItemInString = '';
                              tempCgstValueOfItemInString = '';
                              tempSgstPercentageOfItemInString = '';
                              tempSgstValueOfItemInString = '';
                              _totalExpenseWithTaxesEntryController.clear();
                              _eachItemExpenseEntryController.clear();
                              _numberOfItemsEntryController.clear();
                              _cgstValueEntryController.clear();
                              _sgstValueEntryController.clear();
                              tempExpenseDescription = '';
                              tempVendor = '';
                              tempExpensePaidByUser = '';
                              tempPaymentMethod = '';
                              setState(() {
                                pageNumber = 1;
                              });
                            }else{
                              show('Please Check Internet & Retry');
                            }

                          }
                        },
                        child: Text('Add', style: TextStyle(fontSize: 20))),
                  ],
                )
              ],
            ),
          ),
        ),
      ): WillPopScope(
        onWillPop: () async {
          setState(() {
            pageNumber = 1;
          });
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: kAppBarBackgroundColor,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: kAppBarBackIconColor),
              onPressed: () {
                setState(() {
                  pageNumber = 1;
                });
              },
            ),
            title: Text('Edit Expense', style: kAppBarTextStyle),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 10),
                Padding(
                  key: scrollKeyToExpenseCategory,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Text('Choose Category', style: userInfoTextStyle),
                ),
                Container(
                  padding: EdgeInsets.all(10.0),
                  child: Autocomplete(
                    initialValue: TextEditingValue(text: beforeEditCategory),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      } else {
                        return expenseCategories.where((word) => word
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()));
                      }
                    },
                    optionsViewBuilder:
                        (context, Function(String) onSelected, options) {
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            Material(
                              elevation: 16,
                              child: Container(
                                child: ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      final option =
                                      options.elementAt(index);
                                      return ListTile(
                                        title: Text(option.toString()),
                                        trailing: IconButton(
                                          onPressed: () {
                                            Map<String, dynamic>
                                            tempExpensesCategoriesMap =
                                            expensesSegregationMap[
                                            'expensesCategories'];
                                            String categoryOrVendorKey = '';
                                            tempExpensesCategoriesMap
                                                .forEach((key, value) {
                                              if (value ==
                                                  option.toString()) {
                                                categoryOrVendorKey = key;
                                              }
                                            });

                                            showModalBottomSheet(
                                                isScrollControlled: true,
                                                context: context,
                                                builder: (context) {
                                                  return categoryVendorPaidByPaymentMethodEditDeleteBottomBar(
                                                      context,
                                                      'category',
                                                      option.toString(),
                                                      categoryOrVendorKey);
                                                });
                                          },
                                          icon: Icon(Icons.edit,
                                              color: Colors.green),
                                        ),
                                        onTap: () {
                                          onSelected(option.toString());
                                        },
                                      );
                                    },
                                    separatorBuilder: (context, index) =>
                                        Divider(),
                                    itemCount: options.length),
                              ),
                            ),
                            SizedBox(height: 300)
                          ],
                        ),
                      );
                    },
                    onSelected: (selectedString) {
                      setState(() {
                        tempExpenseCategoryToSave = selectedString;
                      });
                    },
                    fieldViewBuilder: (context,
                        _eachItemCategoryEntryController,
                        focusNode,
                        onEditingComplete) {
                      return TextField(
                        focusNode: focusNode,
                        maxLength: 40,
                        controller: _eachItemCategoryEntryController,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (value) {
                          tempExpenseCategoryToSave = value;
                        },
                        decoration:
                        // kTextFieldInputDecoration,
                        InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Enter Category',
                            hintStyle: TextStyle(color: Colors.grey),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(10)),
                                borderSide:
                                BorderSide(color: Colors.green)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(10)),
                                borderSide:
                                BorderSide(color: Colors.green))),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Text('Description', style: userInfoTextStyle),
                ),
                Container(
                    padding: EdgeInsets.all(10),
                    child: TextField(
                      maxLength: 40,
                      controller: _eachItemDescriptionEntryController,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (value) {
                        tempExpenseDescription = value;
                      },
                      decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Enter Description',
                          hintStyle: TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.all(Radius.circular(10)),
                              borderSide:
                              BorderSide(color: Colors.green)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.all(Radius.circular(10)),
                              borderSide:
                              BorderSide(color: Colors.green))),
                    )),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Text('Vendor/Receiver', style: userInfoTextStyle),
                ),
                Container(
                  padding: EdgeInsets.all(10.0),
                  child: Autocomplete(
                    initialValue: TextEditingValue(text: beforeEditVendor),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      } else {
                        return expensesVendors.where((word) => word
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()));
                      }
                    },
                    optionsViewBuilder:
                        (context, Function(String) onSelected, options) {
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            Material(
                              elevation: 16,
                              child: Container(
                                child: ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      final option =
                                      options.elementAt(index);
                                      return ListTile(
                                        title: Text(option.toString()),
                                        trailing: IconButton(
                                          onPressed: () {
                                            Map<String, dynamic>
                                            tempExpensesVendorsMap =
                                            expensesSegregationMap[
                                            'expensesVendors'];
                                            String categoryOrVendorKey = '';
                                            tempExpensesVendorsMap
                                                .forEach((key, value) {
                                              if (value ==
                                                  option.toString()) {
                                                categoryOrVendorKey = key;
                                              }
                                            });
                                            _editCategoryVendorPaidByPaymentMethodController
                                                .text = option.toString();
                                            showModalBottomSheet(
                                                isScrollControlled: true,
                                                context: context,
                                                builder: (context) {
                                                  return categoryVendorPaidByPaymentMethodEditDeleteBottomBar(
                                                      context,
                                                      'vendor',
                                                      option.toString(),
                                                      categoryOrVendorKey);
                                                });
                                          },
                                          icon: Icon(Icons.edit,
                                              color: Colors.green),
                                        ),
                                        onTap: () {
                                          onSelected(option.toString());
                                        },
                                      );
                                    },
                                    separatorBuilder: (context, index) =>
                                        Divider(),
                                    itemCount: options.length),
                              ),
                            ),
                            SizedBox(height: 300)
                          ],
                        ),
                      );
                    },
                    onSelected: (selectedString) {
                      setState(() {
                        tempVendor = selectedString;
                      });
                    },
                    fieldViewBuilder: (context, _eachItemVendorEntryController, focusNode,
                        onEditingComplete) {
                      return TextField(
                        focusNode: focusNode,
                        maxLength: 40,
                        controller: _eachItemVendorEntryController,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (value) {
                          tempVendor = value;
                        },
                        decoration:
                        // kTextFieldInputDecoration,
                        InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Enter Vendor',
                            hintStyle: TextStyle(color: Colors.grey),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(10)),
                                borderSide:
                                BorderSide(color: Colors.green)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(10)),
                                borderSide:
                                BorderSide(color: Colors.green))),
                      );
                    },
                  ),
                ),
                ListTile(
                  leading: Text('Date',style: userInfoTextStyle),
                  title: Row(
                    children: [
                      ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor:
                            MaterialStateProperty.all<Color>(
                                Colors.green)),
                        child: Text(dateForAddingExpense,style:TextStyle(fontSize: 20)),
                        onPressed: ()async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialEntryMode:
                            DatePickerEntryMode.calendarOnly,
                            builder: (context, child) {
                              return Theme(
                                  data: Theme.of(context).copyWith(
                                      dialogTheme: DialogTheme(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                16.0), // this is the border radius of the picker
                                          )),
                                      colorScheme: ColorScheme(
                                          brightness: Brightness.light,
                                          primary: Colors.green,
                                          onPrimary: Colors.black,
                                          secondary: Colors.white,
                                          onSecondary: Colors.white,
                                          error: Colors.red,
                                          onError: Colors.black,
                                          background: Colors.white,
                                          onBackground: Colors.black,
                                          surface: Colors.white,
                                          onSurface: Colors.black)),
                                  child: child!);
                            },
                            initialDate: DateTime(int.parse(beforeEditYear),int.parse(beforeEditMonth),int.parse(beforeEditDay)),
                            firstDate:DateTime.now().millisecondsSinceEpoch>=DateTime(2025,5,1).millisecondsSinceEpoch? DateTime(DateTime.now().year-1, DateTime.now().month, DateTime.now().day):
                            DateTime(2024,5,1),
                            lastDate: DateTime.now(),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              dateForAddingExpense =
                                  DateFormat('dd-MM-yyyy').format(pickedDate);
                            });
                            chosenDateStringsSetting(pickedDate);
                          }
                        },
                      ),
                    ],
                  ),
                ),
//PaidByUser
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Text('Paid By:', style: userInfoTextStyle),
                ),
                Container(
                  padding: EdgeInsets.all(10.0),
                  child: Autocomplete(
                    initialValue: TextEditingValue(text: beforeEditExpensePaidByUser),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      } else {
                        return expensesPaidByUser.where((word) => word
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()));
                      }
                    },
                    optionsViewBuilder:
                        (context, Function(String) onSelected, options) {
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            Material(
                              elevation: 16,
                              child: Container(
                                child: ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      final option =
                                      options.elementAt(index);
                                      return ListTile(
                                        title: Text(option.toString()),
                                        trailing: IconButton(
                                          onPressed: () {
                                            Map<String, dynamic>
                                            tempExpensesPaidByUsersMap =
                                            expensesSegregationMap[
                                            'expensesPaidByUser'];
                                            String categoryVendorPaidByPaymentMethodKey = '';
                                            tempExpensesPaidByUsersMap
                                                .forEach((key, value) {
                                              if (value ==
                                                  option.toString()) {
                                                categoryVendorPaidByPaymentMethodKey = key;
                                              }
                                            });
                                            _editCategoryVendorPaidByPaymentMethodController
                                                .text = option.toString();
                                            showModalBottomSheet(
                                                isScrollControlled: true,
                                                context: context,
                                                builder: (context) {
                                                  return categoryVendorPaidByPaymentMethodEditDeleteBottomBar(
                                                      context,
                                                      'paidByUser',
                                                      option.toString(),
                                                      categoryVendorPaidByPaymentMethodKey);
                                                });
                                          },
                                          icon: Icon(Icons.edit,
                                              color: Colors.green),
                                        ),
                                        onTap: () {
                                          onSelected(option.toString());
                                        },
                                      );
                                    },
                                    separatorBuilder: (context, index) =>
                                        Divider(),
                                    itemCount: options.length),
                              ),
                            ),
                            SizedBox(height: 300)
                          ],
                        ),
                      );
                    },
                    onSelected: (selectedString) {
                      setState(() {
                        tempExpensePaidByUser = selectedString;
                      });
                    },
                    fieldViewBuilder: (context, _eachItemVendorEntryController, focusNode,
                        onEditingComplete) {
                      return TextField(
                        focusNode: focusNode,
                        maxLength: 40,
                        controller: _eachItemVendorEntryController,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (value) {
                          tempExpensePaidByUser = value;
                        },
                        decoration:
                        // kTextFieldInputDecoration,
                        InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Paid By',
                            hintStyle: TextStyle(color: Colors.grey),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(10)),
                                borderSide:
                                BorderSide(color: Colors.green)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(10)),
                                borderSide:
                                BorderSide(color: Colors.green))),
                      );
                    },
                  ),
                ),
//PaymentMethod
                //PaymentMethod
                Padding(
                  key:scrollKeyToExpensePaymentMethod,
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Text('Payment Method(Mandatory)', style: userInfoTextStyle),
                ),
                Container(
                  padding: EdgeInsets.all(10.0),
                  child: Autocomplete(
                    initialValue: TextEditingValue(text: beforeEditPaymentMethod),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return const Iterable<String>.empty();
                      } else {
                        return paymentMethod.where((word) => word
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()));
                      }
                    },
                    optionsViewBuilder:
                        (context, Function(String) onSelected, options) {
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            Material(
                              elevation: 16,
                              child: Container(
                                child: ListView.separated(
                                    shrinkWrap: true,
                                    padding: EdgeInsets.zero,
                                    physics: NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      final option =
                                      options.elementAt(index);
                                      return ListTile(
                                        title: Text(option.toString()),
                                        trailing: IconButton(
                                          onPressed: () {
                                            Map<String, dynamic>
                                            tempPaymentMethodMap =
                                            expensesSegregationMap[
                                            'paymentMethod'];
                                            String categoryVendorPaidByPaymentMethodKey = '';
                                            tempPaymentMethodMap
                                                .forEach((key, value) {
                                              if (value ==
                                                  option.toString()) {
                                                categoryVendorPaidByPaymentMethodKey = key;
                                              }
                                            });
                                            _editCategoryVendorPaidByPaymentMethodController
                                                .text = option.toString();

                                            showModalBottomSheet(
                                                isScrollControlled: true,
                                                context: context,
                                                builder: (context) {
                                                  return categoryVendorPaidByPaymentMethodEditDeleteBottomBar(
                                                      context,
                                                      'paymentMethod',
                                                      option.toString(),
                                                      categoryVendorPaidByPaymentMethodKey);
                                                });
                                          },
                                          icon: Icon(Icons.edit,
                                              color: Colors.green),
                                        ),
                                        onTap: () {
                                          onSelected(option.toString());
                                        },
                                      );
                                    },
                                    separatorBuilder: (context, index) =>
                                        Divider(),
                                    itemCount: options.length),
                              ),
                            ),
                            SizedBox(height: 300)
                          ],
                        ),
                      );
                    },
                    onSelected: (selectedString) {
                      setState(() {
                        tempPaymentMethod = selectedString;
                      });
                    },
                    fieldViewBuilder: (context,
                        controller,
                        focusNode,
                        onEditingComplete) {
                      return TextField(
                        focusNode: focusNode,
                        maxLength: 40,
                        controller: controller,
                        onChanged: (value) {
                          tempPaymentMethod = value;
                        },
                        decoration:
                        // kTextFieldInputDecoration,
                        InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Payment Method',
                            hintStyle: TextStyle(color: Colors.grey),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(10)),
                                borderSide:
                                BorderSide(color: Colors.green)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                    Radius.circular(10)),
                                borderSide:
                                BorderSide(color: Colors.green))),
                      );
                    },
                  ),
                ),


//UnitPrice
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Text('Unit Price', style: userInfoTextStyle),
                ),
                Container(
                  padding: EdgeInsets.all(10),
                  child: TextField(
                    maxLength: 10,
                    controller: _eachItemExpenseEntryController,
                    keyboardType:
                    TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      tempPriceOfUnitInString = value;
                      expensesCalculationForNewExpense();
                    },
                    decoration:
                    // kTextFieldInputDecoration,
                    InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Unit Price',
                        hintStyle: TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(10)),
                            borderSide:
                            BorderSide(color: Colors.green)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(10)),
                            borderSide:
                            BorderSide(color: Colors.green))),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child: Text('Number of Units', style: userInfoTextStyle),
                ),
                Container(
                  padding: EdgeInsets.all(10),
                  child: TextField(
                    maxLength: 10,
                    controller: _numberOfItemsEntryController,
                    keyboardType:
                    TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      tempNumberOfUnitsInString = value;
                      expensesCalculationForNewExpense();
                    },
                    decoration:
                    // kTextFieldInputDecoration,
                    InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Number of Units',
                        hintStyle: TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(10)),
                            borderSide:
                            BorderSide(color: Colors.green)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(10)),
                            borderSide:
                            BorderSide(color: Colors.green))),
                  ),
                ),
//CgstPercentageOrValue
                ListTile(
                  leading: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'CGST',
                      style: TextStyle(fontSize: 25, color: Colors.green),
                    ),
                  ),
                  title: Container(
                    padding: EdgeInsets.only(
                        left: 5, top: 10, right: 10, bottom: 10)
                    // EdgeInsets.all(10.0)
                    ,
                    child: tempCgstPercentageOrValue == '%'
                        ? Autocomplete(
                      initialValue: TextEditingValue(text: beforeEditCgstPercentage),
                      optionsBuilder:
                          (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        } else {
                          return expensesCgstPercentage.where(
                                  (word) => word.toLowerCase().contains(
                                  textEditingValue.text
                                      .toLowerCase()));
                        }
                      },
                      optionsViewBuilder: (context,
                          Function(String) onSelected, options) {
                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              Material(
                                elevation: 16,
                                child: Container(
                                  child: ListView.separated(
                                      shrinkWrap: true,
                                      padding: EdgeInsets.zero,
                                      physics:
                                      NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        final option =
                                        options.elementAt(index);
                                        return ListTile(
                                          title:
                                          Text(option.toString()),
                                          onTap: () {
                                            onSelected(
                                                option.toString());
                                          },
                                        );
                                      },
                                      separatorBuilder:
                                          (context, index) =>
                                          Divider(),
                                      itemCount: options.length),
                                ),
                              ),
                              SizedBox(height: 300)
                            ],
                          ),
                        );
                      },
                      onSelected: (selectedString) {
                        setState(() {
                          tempCgstPercentageOfItemInString =
                              selectedString;
                          expensesCalculationForNewExpense();
                        });
                      },
                      fieldViewBuilder: (context, _cgstPercentageEntryController,
                          focusNode, onEditingComplete) {
                        return TextField(
                          focusNode: focusNode,
                          // maxLength: 40,
                          controller: _cgstPercentageEntryController,
                          keyboardType:
                          TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (value) {
                            tempCgstPercentageOfItemInString = value;
                            expensesCalculationForNewExpense();
                          },
                          decoration:
                          // kTextFieldInputDecoration,
                          InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Enter Cgst%',
                              hintStyle:
                              TextStyle(color: Colors.grey),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(10)),
                                  borderSide: BorderSide(
                                      color: Colors.green)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(10)),
                                  borderSide: BorderSide(
                                      color: Colors.green))),
                        );
                      },
                    )
                        : TextField(
                      maxLength: 10,
                      controller: _cgstValueEntryController,
                      keyboardType: TextInputType.numberWithOptions(
                          decimal: true),
                      onChanged: (value) {
                        setState(() {
                          tempCgstValueOfItemInString = value;
                          expensesCalculationForNewExpense();
                        });
                      },
                      decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Cgst Value',
                          hintStyle:
                          TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                  Radius.circular(10)),
                              borderSide: BorderSide(
                                  color: Colors.green)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                  Radius.circular(10)),
                              borderSide: BorderSide(
                                  color: Colors.green))),
                    ),
                  ),
                  trailing: Container(
                    decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(5)),
                    width: 50,
                    height: 50,
                    // height: 200,
                    child: Center(
                      child: DropdownButtonFormField(
                        decoration: InputDecoration.collapsed(hintText: ''),
                        isExpanded: true,
                        // underline: Container(),
                        dropdownColor: Colors.green,
                        value: tempCgstPercentageOrValue,
                        onChanged: (value) {
                          setState(() {
                            tempCgstPercentageOrValue = value.toString();
                            tempCgstValueOfItemInString = '';
                            tempCgstPercentageOfItemInString = '';
                            expensesCalculationForNewExpense();
                            _cgstValueEntryController.clear();
                          });
                        },
                        items: gstPercentageOrValue.map((gstChoices) {
//DropDownMenuItemWillHaveOneByOneItems,WePutThatAsList
//ValueWillBeEachTitle
                          return DropdownMenuItem(
                            alignment: Alignment.center,
                            child: Text(gstChoices,
                                style: const TextStyle(
                                    fontSize: 25, color: Colors.white)),
                            value: gstChoices,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  subtitle: Visibility(
                      visible: (tempCgstPercentageOrValue == '%' &&
                          tempCgstPercentageOfItemInString != '')
                          ? true
                          : false,
                      child: Text(
                        '₹$tempCgstValueOfItemInString(CGST Amount)',
                        style: TextStyle(fontSize: 20, color: Colors.green),
                        textAlign: TextAlign.left,
                      )),
                ),
//SgstPercentageOrValue
                ListTile(
                  leading: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'SGST',
                      style: TextStyle(fontSize: 25, color: Colors.green),
                    ),
                  ),
                  title: Container(
                    padding: EdgeInsets.only(
                        left: 5, top: 10, right: 10, bottom: 10)
                    // EdgeInsets.all(10.0)
                    ,
                    child: tempSgstPercentageOrValue == '%'
                        ? Autocomplete(
                      initialValue: TextEditingValue(text: beforeEditSgstPercentage),
                      optionsBuilder:
                          (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        } else {
                          return expensesSgstPercentage.where(
                                  (word) => word.toLowerCase().contains(
                                  textEditingValue.text
                                      .toLowerCase()));
                        }
                      },
                      optionsViewBuilder: (context,
                          Function(String) onSelected, options) {
                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              Material(
                                elevation: 16,
                                child: Container(
                                  child: ListView.separated(
                                      shrinkWrap: true,
                                      padding: EdgeInsets.zero,
                                      physics:
                                      NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        final option =
                                        options.elementAt(index);
                                        return ListTile(
                                          title:
                                          Text(option.toString()),
                                          onTap: () {
                                            onSelected(
                                                option.toString());
                                          },
                                        );
                                      },
                                      separatorBuilder:
                                          (context, index) =>
                                          Divider(),
                                      itemCount: options.length),
                                ),
                              ),
                              SizedBox(height: 300)
                            ],
                          ),
                        );
                      },
                      onSelected: (selectedString) {
                        setState(() {
                          tempSgstPercentageOfItemInString =
                              selectedString;
                          expensesCalculationForNewExpense();
                        });
                      },
                      fieldViewBuilder: (context, _sgstPercentageEntryController,
                          focusNode, onEditingComplete) {
                        return TextField(
                          focusNode: focusNode,
                          // maxLength: 40,
                          controller: _sgstPercentageEntryController,
                          keyboardType:
                          TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (value) {
                            tempSgstPercentageOfItemInString = value;
                            expensesCalculationForNewExpense();
                          },
                          decoration:
                          // kTextFieldInputDecoration,
                          InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              hintText: 'Enter Sgst%',
                              hintStyle:
                              TextStyle(color: Colors.grey),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(10)),
                                  borderSide: BorderSide(
                                      color: Colors.green)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(10)),
                                  borderSide: BorderSide(
                                      color: Colors.green))),
                        );
                      },
                    )
                        : TextField(
                      maxLength: 10,
                      controller: _sgstValueEntryController,
                      keyboardType: TextInputType.numberWithOptions(
                          decimal: true),
                      onChanged: (value) {
                        setState(() {
                          tempSgstValueOfItemInString = value;
                          // expensesCalculation();
                        });
                      },
                      decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Sgst Value',
                          hintStyle:
                          TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                  Radius.circular(10)),
                              borderSide: BorderSide(
                                  color: Colors.green)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                  Radius.circular(10)),
                              borderSide: BorderSide(
                                  color: Colors.green))),
                    ),
                  ),
                  trailing: Container(
                    decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(5)),
                    width: 50,
                    height: 50,
                    // height: 200,
                    child: Center(
                      child: DropdownButtonFormField(
                        decoration: InputDecoration.collapsed(hintText: ''),
                        isExpanded: true,
                        // underline: Container(),
                        dropdownColor: Colors.green,
                        value: tempSgstPercentageOrValue,
                        onChanged: (value) {
                          setState(() {
                            tempSgstPercentageOrValue = value.toString();
                            tempSgstValueOfItemInString = '';
                            tempSgstPercentageOfItemInString = '';
                            expensesCalculationForNewExpense();
                            _sgstValueEntryController.clear();
                          });
                        },
                        items: gstPercentageOrValue.map((gstChoices) {
//DropDownMenuItemWillHaveOneByOneItems,WePutThatAsList
//ValueWillBeEachTitle
                          return DropdownMenuItem(
                            alignment: Alignment.center,
                            child: Text(gstChoices,
                                style: const TextStyle(
                                    fontSize: 25, color: Colors.white)),
                            value: gstChoices,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  subtitle: Visibility(
                      visible: (tempSgstPercentageOrValue == '%' &&
                          tempSgstPercentageOfItemInString != '')
                          ? true
                          : false,
                      child: Text(
                        '₹$tempSgstValueOfItemInString(SGST Amount)',
                        style: TextStyle(fontSize: 20, color: Colors.green),
                        textAlign: TextAlign.left,
                      )),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                  child:
                  Text('Enter Total Price(Mandatory)', style: userInfoTextStyle),
                ),
                Container(
                  padding: EdgeInsets.all(10),
                  child: TextField(
                    maxLength: 10,
                    controller: _totalExpenseWithTaxesEntryController,
                    keyboardType:
                    TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      tempTotalExpenseWithTaxesInString = value;
                    },
                    decoration:
                    // kTextFieldInputDecoration,
                    InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Total Price',
                        hintStyle: TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(10)),
                            borderSide:
                            BorderSide(color: Colors.green)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(10)),
                            borderSide:
                            BorderSide(color: Colors.green))),
                  ),
                ),
                Divider(thickness: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor:
                            MaterialStateProperty.all<Color>(
                                Colors.red)),
                        onPressed: () {
                          deletePastBillAlertDialogBox();
                        },
                        child: Text('Delete',style: TextStyle(fontSize: 20))),
                    ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor:
                            MaterialStateProperty.all<Color>(
                                Colors.green)),
                        onPressed: () {
                          if (tempExpenseCategoryToSave == '') {
                            show('Please enter Category');
                            Scrollable.ensureVisible(
                                scrollKeyToExpenseCategory.currentContext!);
                          }else if(
                          tempExpensePaidByUser == ''
                          ){
                            Scrollable.ensureVisible(
                                scrollKeyToExpensePaidByUser.currentContext!);
                            show('Please enter the user who paid');}else if(
                          tempPaymentMethod == ''
                          ){
                            show('Please enter the Payment Method');

                            Scrollable.ensureVisible(
                                scrollKeyToExpensePaymentMethod.currentContext!);
                          } else if (tempTotalExpenseWithTaxesInString ==
                              '') {
                            show('Please enter Total Price');
                          } else if (num.parse(
                              tempTotalExpenseWithTaxesInString) ==
                              0) {
                            show('Please enter Total Price');
                          } else {
                            Map<String, dynamic>
                            subMasterDeleteExpensesStatistics = HashMap();

                            subMasterDeleteExpensesStatistics.addAll({
                              'mapEachExpenseStatisticsMap':
                              {
                              beforeEditCategory: {
                                'numberOfEntriesOfCategory': FieldValue.increment(-1),
                                'numberOfUnits':
                                beforeEditNumberOfItemsInString != ''
                                    ? FieldValue.increment(-1 * (num.parse(
                                    beforeEditNumberOfItemsInString)))
                                    : 0,
                                'cgstValue':
                                beforeEditCgstValue != ''
                                    ? FieldValue.increment((-1 * num.parse(
                                    beforeEditCgstValue)))
                                    : 0,
                                'sgstValue':
                                beforeEditSgstValue != ''
                                    ? FieldValue.increment((-1 * num.parse(
                                    beforeEditSgstValue)))
                                    : 0,
                                'totalPrice': FieldValue.increment(
                                    -1 * (num.parse(
                                        beforeEditTotalPriceWithTaxes)))
                              }
                            }});
                            subMasterDeleteExpensesStatistics.addAll({
                              'mapExpensePaidByUserMap':{
                                beforeEditExpensePaidByUser: {
                                  'numberOfEntriesOfUserPaying': FieldValue.increment(-1),
                                  'paidAmount':
                                  FieldValue.increment(
                                      -1 * (num.parse(
                                          beforeEditTotalPriceWithTaxes))
                                  )
                                }
                              }
                            });
                            subMasterDeleteExpensesStatistics.addAll({
                              'mapExpensePaymentMethodMap':{
                                beforeEditPaymentMethod: {
                                  'numberOfEntriesInPaymentMethod': FieldValue.increment(-1),
                                  'paidAmount':
                                  FieldValue.increment(
                                    -1 * (num.parse(
                                        beforeEditTotalPriceWithTaxes))
                                )}
                              }
                            });

                            Map<String, dynamic> masterDeleteExpensesStatistics =
                            {'expenses': subMasterDeleteExpensesStatistics};

                            FireStoreDeleteOldExpenseWithBatch(hotelName: Provider.of<PrinterAndOtherDetailsProvider>(context,listen: false).chosenRestaurantDatabaseFromClass,
                                expenseBillName: beforeEditBillId, year: beforeEditYear,month: beforeEditMonth,day: beforeEditDay,
                                statisticsExpensesMap: masterDeleteExpensesStatistics
                            ).deleteExpense();

                            Timer(Duration(seconds:1), () {


//FirstWeMakeItForExpensesBills
                              bool expensesSegregationUpdationNeeded = false;
                              int expensesUpdateTimeInMilliseconds =
                                  DateTime.now().millisecondsSinceEpoch;
                              Map<String, dynamic>
                              expensesSegregationUpdateMap = HashMap();
                              if (!expenseCategories
                                  .contains(tempExpenseCategoryToSave)) {
                                expensesSegregationUpdationNeeded = true;
                                Map<String, dynamic>
                                tempExpensesCategoriesMap =
                                expensesSegregationMap[
                                'expensesCategories'];
                                List<num> currentCategoriesKey = [];
                                tempExpensesCategoriesMap
                                    .forEach((key, value) {
                                  currentCategoriesKey.add(num.parse(key));
                                });
//WeAreGettingTheMaxValueOfTheKeyWeHaveInCategoriesAndAddingItByOne
                                num newCategoryKey =
                                    currentCategoriesKey.reduce(max) + 1;
//ThisIsForLocalUpdate
                                tempExpensesCategoriesMap.addAll({
                                  newCategoryKey.toString():
                                  tempExpenseCategoryToSave
                                });
                                expensesSegregationMap['expensesCategories'] =
                                    tempExpensesCategoriesMap;
//ThisIsForServerUpdate
                                expensesSegregationUpdateMap.addAll({
                                  'expensesCategories': {
                                    newCategoryKey.toString():
                                    tempExpenseCategoryToSave
                                  }
                                });
                              }
                              if (!expensesVendors.contains(tempVendor) &&
                                  tempVendor != '') {
                                expensesSegregationUpdationNeeded = true;
                                Map<String, dynamic> tempVendorsMap =
                                expensesSegregationMap['expensesVendors'];
                                num newVendorKey = 111111;
                                if (tempVendorsMap.isNotEmpty) {
                                  List<num> currentVendorsKey = [];
                                  tempVendorsMap.forEach((key, value) {
                                    currentVendorsKey.add(num.parse(key));
                                  });
                                  newVendorKey =
                                      currentVendorsKey.reduce(max) + 1;
                                }
//WeAreGettingTheMaxValueOfTheKeyWeHaveInCategoriesAndAddingItByOne
                                //ThisIsForLocalUpdate
                                tempVendorsMap.addAll(
                                    {newVendorKey.toString(): tempVendor});
                                expensesSegregationMap['expensesVendors'] =
                                    tempVendorsMap;

                                expensesSegregationUpdateMap.addAll({
                                  'expensesVendors': {
                                    newVendorKey.toString(): tempVendor
                                  }
                                });
                              }
                              //NewUserInPaidUser
                              if(!expensesPaidByUser.contains(tempExpensePaidByUser)
                                  && tempExpensePaidByUser != ''
                              ){
                                expensesSegregationUpdationNeeded = true;

                                Map<String, dynamic> tempExpensePaidByUserMap =
                                expensesSegregationMap['expensesPaidByUser'];
                                num newPaidByUserKey = 11111111;
                                if (tempExpensePaidByUserMap.isNotEmpty) {
                                  List<num> currentPaidByUserKey = [];
                                  tempExpensePaidByUserMap.forEach((key, value) {
                                    currentPaidByUserKey.add(num.parse(key));
                                  });
                                  newPaidByUserKey =
                                      currentPaidByUserKey.reduce(max) + 1;
                                }
//WeAreGettingTheMaxValueOfTheKeyWeHaveInCategoriesAndAddingItByOne
                                //ThisIsForLocalUpdate
                                tempExpensePaidByUserMap.addAll(
                                    {newPaidByUserKey.toString(): tempExpensePaidByUser});
                                expensesSegregationMap['expensesPaidByUser'] =
                                    tempExpensePaidByUserMap;

                                expensesSegregationUpdateMap.addAll({
                                  'expensesPaidByUser': {
                                    newPaidByUserKey.toString(): tempExpensePaidByUser
                                  }
                                });
                              }
//NewPaymentMethod
                              if(!paymentMethod.contains(tempPaymentMethod)
                                  && tempPaymentMethod != ''
                              ){
                                expensesSegregationUpdationNeeded = true;

                                Map<String, dynamic> tempPaymentMethodMap =
                                expensesSegregationMap['paymentMethod'];
                                num newPaymentMethodKey = 111111111;
                                if (tempPaymentMethodMap.isNotEmpty) {
                                  List<num> currentPaymentMethodKey = [];
                                  tempPaymentMethodMap.forEach((key, value) {
                                    currentPaymentMethodKey.add(num.parse(key));
                                  });
                                  newPaymentMethodKey =
                                      currentPaymentMethodKey.reduce(max) + 1;
                                }
//WeAreGettingTheMaxValueOfTheKeyWeHaveInCategoriesAndAddingItByOne
                                //ThisIsForLocalUpdate
                                tempPaymentMethodMap.addAll(
                                    {newPaymentMethodKey.toString(): tempPaymentMethod});
                                expensesSegregationMap['paymentMethod'] =
                                    tempPaymentMethodMap;

                                expensesSegregationUpdateMap.addAll({
                                  'paymentMethod': {
                                    newPaymentMethodKey.toString(): tempPaymentMethod
                                  }
                                });
                              }
                              if (!expensesCgstPercentage.contains(
                                  tempCgstPercentageOfItemInString) &&
                                  tempCgstPercentageOfItemInString != '') {
                                expensesSegregationUpdationNeeded = true;
//ThisIsForServerUpdate
                                expensesSegregationUpdateMap.addAll({
                                  'expensesCgstPercentage': {
                                    tempCgstPercentageOfItemInString: true
                                  }
                                });
//ThisIsForLocalUpdate
                                Map<String, dynamic>
                                tempExpensesCgstPercentageMap =
                                expensesSegregationMap[
                                'expensesCgstPercentage'];
                                tempExpensesCgstPercentageMap.addAll(
                                    {tempCgstPercentageOfItemInString: true});
                                expensesSegregationMap[
                                'expensesCgstPercentage'] =
                                    tempExpensesCgstPercentageMap;
                              }
                              if (!expensesSgstPercentage.contains(
                                  tempSgstPercentageOfItemInString) &&
                                  tempSgstPercentageOfItemInString != '') {
                                expensesSegregationUpdationNeeded = true;
                                expensesSegregationUpdateMap.addAll({
                                  'expensesSgstPercentage': {
                                    tempSgstPercentageOfItemInString: true
                                  }
                                });
//ThisIsForLocalUpdate
                                Map<String, dynamic>
                                tempExpensesSgstPercentageMap =
                                expensesSegregationMap[
                                'expensesSgstPercentage'];
                                tempExpensesSgstPercentageMap.addAll(
                                    {tempSgstPercentageOfItemInString: true});
                                expensesSegregationMap[
                                'expensesSgstPercentage'] =
                                    tempExpensesSgstPercentageMap;
                              }

                              Map<String, dynamic> masterExpensesBills =
                              HashMap();
                              masterExpensesBills.addAll({
                                'username': json.decode(Provider.of<
                                    PrinterAndOtherDetailsProvider>(
                                    context,
                                    listen: false)
                                    .allUserProfilesFromClass)[Provider.of<
                                    PrinterAndOtherDetailsProvider>(
                                    context,
                                    listen: false)
                                    .currentUserPhoneNumberFromClass]['username'],
                                'userPhoneNumber': Provider.of<
                                    PrinterAndOtherDetailsProvider>(
                                    context,
                                    listen: false)
                                    .currentUserPhoneNumberFromClass,
                                'category': tempExpenseCategoryToSave,
                                'description': tempExpenseDescription,
                                'vendor': tempVendor,
                                'paidBy': tempExpensePaidByUser,
                                'paymentMethod': tempPaymentMethod,
                                'date': '$year*$month*$day',
                                'expenseBillId':
                                '$year$month$day$tempNumberOfMillisecondsPassedToday',
                                'unitPrice': tempPriceOfUnitInString,
                                'numberOfUnits': tempNumberOfUnitsInString,
                                'cgstPercentage':
                                tempCgstPercentageOfItemInString,
                                'cgstValue': tempCgstValueOfItemInString,
                                'sgstPercentage':
                                tempSgstPercentageOfItemInString,
                                'sgstValue': tempSgstValueOfItemInString,
                                'totalPrice': num.parse(
                                    tempTotalExpenseWithTaxesInString)
                              });
                              Map<String, dynamic>
                              subMasterExpensesStatistics = HashMap();
                              subMasterExpensesStatistics.addAll({'mapEachExpenseStatisticsMap':{
                                tempExpenseCategoryToSave: {
                                  'numberOfEntriesOfCategory': FieldValue.increment(1),
                                  'numberOfUnits':
                                  tempNumberOfUnitsInString != ''
                                      ? FieldValue.increment(num.parse(
                                      tempNumberOfUnitsInString))
                                      : 0,
                                  'cgstValue':
                                  tempCgstValueOfItemInString != ''
                                      ? FieldValue.increment(num.parse(
                                      tempCgstValueOfItemInString))
                                      : 0,
                                  'sgstValue':
                                  tempSgstValueOfItemInString != ''
                                      ? FieldValue.increment(num.parse(
                                      tempSgstValueOfItemInString))
                                      : 0,
                                  'totalPrice': FieldValue.increment(
                                      num.parse(
                                          tempTotalExpenseWithTaxesInString))
                                }
                              }});
                              subMasterExpensesStatistics.addAll({
                                'mapExpensePaidByUserMap':{
                                  tempExpensePaidByUser: {
                                    'numberOfEntriesOfUserPaying': FieldValue.increment(1),
                                    'paidAmount':
                                    FieldValue.increment(
                                      num.parse(
                                          tempTotalExpenseWithTaxesInString)
                                  )}
                                }
                              });
                              subMasterExpensesStatistics.addAll({
                                'mapExpensePaymentMethodMap':{
                                  tempPaymentMethod: {
                                    'numberOfEntriesInPaymentMethod': FieldValue.increment(1),
                                    'paidAmount':
                                    FieldValue.increment(
                                      num.parse(
                                          tempTotalExpenseWithTaxesInString)
                                  )}
                                }
                              });
                              subMasterExpensesStatistics.addAll({
                                'arrayExpenseCategoryArray': FieldValue.arrayUnion(
                                    [tempExpenseCategoryToSave])
                              });
                              if (tempExpenseDescription != '') {
                                subMasterExpensesStatistics.addAll({
                                  'arrayExpenseDescriptionArray': FieldValue.arrayUnion(
                                      [tempExpenseDescription])
                                });
                              }
                              if (tempVendor != '') {
                                subMasterExpensesStatistics.addAll({
                                  'arrayExpenseVendorArray':
                                  FieldValue.arrayUnion([tempVendor])
                                });
                              }
                              Map<String,dynamic> statisticsDailyExpensesMap = {'day': num.parse(day),'month': num.parse(month),'year':num.parse(year) };
                              Map<String,dynamic> statisticsMonthlyExpensesMap = {'month': num.parse(month),'year':num.parse(year)  };

                              Map<String, dynamic> masterExpensesStatistics =
                              {'expenses': subMasterExpensesStatistics};
                              statisticsDailyExpensesMap.addAll(masterExpensesStatistics);
                              statisticsMonthlyExpensesMap.addAll(masterExpensesStatistics);
                              FireStoreAddNewExpenseWithBatch(
                                  hotelName: Provider.of<
                                      PrinterAndOtherDetailsProvider>(
                                      context,
                                      listen: false)
                                      .chosenRestaurantDatabaseFromClass,
                                  expenseBillName:
                                  '$year$month$day$tempNumberOfMillisecondsPassedToday',
                                  expensesBillMap: masterExpensesBills,
                                  year: year,
                                  month: month,
                                  day: day,
                                  statisticsDailyExpensesMap:
                                  statisticsDailyExpensesMap,
                                  statisticsMonthlyExpensesMap: statisticsMonthlyExpensesMap,
                                  expensesSegregationUpdateMap:
                                  expensesSegregationUpdateMap,
                                  expensesUpdateTimeInMilliseconds:
                                  expensesUpdateTimeInMilliseconds)
                                  .addExpense();
                              if (expensesSegregationUpdationNeeded) {
                                final fcmProvider =
                                Provider.of<NotificationProvider>(context,
                                    listen: false);
                                fcmProvider.sendNotification(
                                    token: dynamicTokensToStringToken(),
                                    title: Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
                                        .chosenRestaurantDatabaseFromClass,
                                    restaurantNameForNotification: json.decode(
                                        Provider.of<PrinterAndOtherDetailsProvider>(
                                            context,
                                            listen: false)
                                            .allUserProfilesFromClass)[
                                    Provider.of<PrinterAndOtherDetailsProvider>(
                                        context,
                                        listen: false)
                                        .currentUserPhoneNumberFromClass]
                                    ['restaurantName'],
                                    body: '*restaurantInfoUpdated*');
                                Provider.of<PrinterAndOtherDetailsProvider>(
                                    context,
                                    listen: false)
                                    .expensesSegregationTimeStampSaving(
                                    expensesUpdateTimeInMilliseconds,
                                    json.encode(expensesSegregationMap));
                                expensesSegregationData();
                                expensesSegregationUpdationNeeded = false;
                              }
                              tempExpenseCategoryToSave = '';
                              tempTotalExpenseWithTaxesInString = '';
                              tempNumberOfUnitsInString = '';
                              tempPriceOfUnitInString = '';
                              tempCgstPercentageOfItemInString = '';
                              tempCgstValueOfItemInString = '';
                              tempSgstPercentageOfItemInString = '';
                              tempSgstValueOfItemInString = '';
                              _totalExpenseWithTaxesEntryController.clear();
                              _eachItemExpenseEntryController.clear();
                              _numberOfItemsEntryController.clear();
                              _cgstValueEntryController.clear();
                              _sgstValueEntryController.clear();
                              tempExpenseDescription = '';
                              tempVendor = '';
                              tempExpensePaidByUser = '';
                              tempPaymentMethod = '';
                              setState(() {
                                pageNumber = 1;
                              });
                            });

                          }
                        },
                        child: Text('Done', style: TextStyle(fontSize: 20))),

                    ElevatedButton(
                        style: ButtonStyle(
                            backgroundColor:
                            MaterialStateProperty.all<Color>(
                                Colors.orangeAccent)),
                        onPressed: () {
                          setState(() {
                            pageNumber = 1;
                          });
                        },
                        child: Text('Cancel',style: TextStyle(fontSize: 20)))
                  ],
                )
              ],
            ),
          ),
        ),
      );
    }
  }
}
