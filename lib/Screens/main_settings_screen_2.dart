import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:orders_dev/Screens/permissions_screen.dart';
import 'package:orders_dev/Screens/permissions_screen_2.dart';
import 'package:orders_dev/Screens/printer_settings_screen.dart';
import 'package:orders_dev/Screens/searching_Connecting_Printer_Screen.dart';
import 'package:orders_dev/constants.dart';
import 'package:orders_dev/services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

class MainSettingsWithPrintOptions extends StatelessWidget {
  const MainSettingsWithPrintOptions({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String tempSpacesAboveKOT = '';
    String tempSpacesBelowKOT = '';
    String tempKotSize = '';
    List<String> kotSizes = ['Small', 'Large'];
    TextEditingController spacesAboveKotEditingController =
        TextEditingController();
    TextEditingController spacesBelowKotEditingController =
        TextEditingController();

    Widget kotOptionsEditBottomSheet() {
      return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: Text('Spaces Above KOT', style: userInfoTextStyle),
              ),
              Container(
                padding: EdgeInsets.all(10),
                child: TextField(
                  maxLength: 2,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  controller: spacesAboveKotEditingController,
//ToUseNumberInputKeyboard,youNeedToDeclareControllerInsideStatefulWidgetItself
                  onChanged: (value) {
                    tempSpacesAboveKOT = value.toString();
                  },
                  decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Spaces above KOT',
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
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: Text('Spaces Below KOT', style: userInfoTextStyle),
              ),
              Container(
                padding: EdgeInsets.all(10),
                child: TextField(
                  maxLength: 2,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  controller: spacesBelowKotEditingController,
//ToUseNumberInputKeyboard,youNeedToDeclareControllerInsideStatefulWidgetItself
                  onChanged: (value) {
                    tempSpacesBelowKOT = value.toString();
                  },
                  decoration:
                      // kTextFieldInputDecoration,
                      InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Spaces Below KOT',
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
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                child: Text('KOT Size', style: userInfoTextStyle),
              ),
              Center(
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(30)),
                  width: 200,
                  height: 50,
                  // height: 200,
                  child: DropdownButtonFormField(
                    decoration: InputDecoration.collapsed(hintText: ''),
                    isExpanded: true,
                    // underline: Container(),
                    dropdownColor: Colors.green,
                    value: tempKotSize,
                    onChanged: (value) {
                      tempKotSize = value.toString();
                    },
                    items: kotSizes.map((kotSize) {
//DropDownMenuItemWillHaveOneByOneItems,WePutThatAsList
//ValueWillBeEachTitle
                      return DropdownMenuItem(
                        alignment: Alignment.center,
                        child: Text(kotSize,
                            style: const TextStyle(
                                fontSize: 15,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        value: kotSize,
                      );
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.green),
                    ),
                    onPressed: () async {
                      int spacesAboveKot = tempSpacesAboveKOT == ''
                          ? 0
                          : num.parse(tempSpacesAboveKOT).toInt();
                      int spacesBelowKot = tempSpacesBelowKOT == ''
                          ? 0
                          : num.parse(tempSpacesBelowKOT).toInt();
                      Provider.of<PrinterAndOtherDetailsProvider>(context,
                              listen: false)
                          .kotOptionsSaving(
                              spacesAboveKot, spacesBelowKot, tempKotSize);

                      Navigator.pop(context);
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (BuildContext) =>
                                  MainSettingsWithPrintOptions()));
                    },
                    child: Text('Done')),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kAppBarBackgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: kAppBarBackIconColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Settings', style: kAppBarTextStyle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Printer Settings',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 15),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            PrinterSettings(chefOrCaptain: 'Captain')));
              },
              child: Text(
                'Captain Printer Settings',
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            PrinterSettings(chefOrCaptain: 'Chef')));
              },
              child: Text(
                'Chef Printer Settings',
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'KOT Options',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 15),
                  ),
                  IconButton(
                      onPressed: () {
                        tempSpacesAboveKOT =
                            (Provider.of<PrinterAndOtherDetailsProvider>(
                                        context,
                                        listen: false)
                                    .spacesAboveKotFromClass)
                                .toString();
                        spacesAboveKotEditingController =
                            TextEditingController(text: tempSpacesAboveKOT);
                        tempSpacesBelowKOT =
                            (Provider.of<PrinterAndOtherDetailsProvider>(
                                        context,
                                        listen: false)
                                    .spacesBelowKotFromClass)
                                .toString();
                        spacesBelowKotEditingController =
                            TextEditingController(text: tempSpacesBelowKOT);
                        tempKotSize =
                            Provider.of<PrinterAndOtherDetailsProvider>(context,
                                    listen: false)
                                .kotFontSizeFromClass;
                        showModalBottomSheet(
                            isScrollControlled: true,
                            context: context,
                            builder: (context) {
                              return kotOptionsEditBottomSheet();
                            });
                      },
                      icon: Icon(Icons.edit, color: Colors.green)),
                ],
              ),
            ),
            Container(
              child: ListTile(
                title: Text('Spaces Above KOT',
                    style: Theme.of(context).textTheme.headline6),
                trailing: Text(
                    '${Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).spacesAboveKotFromClass}',
                    style: Theme.of(context).textTheme.headline6),
              ),
            ),
            Container(
              child: ListTile(
                title: Text('Spaces Below KOT',
                    style: Theme.of(context).textTheme.headline6),
                trailing: Text(
                    '${Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).spacesBelowKotFromClass}',
                    style: Theme.of(context).textTheme.headline6),
              ),
            ),
            Container(
              child: ListTile(
                title: Text('KOT Font Size',
                    style: Theme.of(context).textTheme.headline6),
                trailing: Text(
                    '${Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false).kotFontSizeFromClass}',
                    style: Theme.of(context).textTheme.headline6),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Permissions',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 15),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                PermissionStatus? statusNotification =
                    await Permission.notification.request();

                bool isGranted = statusNotification == PermissionStatus.granted;
                if (!isGranted) {
                  NotificationService().showNotification(
                      title: 'Orders', body: 'Requesting Your Permission');
                }
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (BuildContext) => PermissionsWithAutoStart(
                              fromFirstScreenTrueElseFalse: false,
                            )));
              },
              child: Text(
                'App Permissions',
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
