import 'package:flutter/material.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:orders_dev/Screens/edit_menu_items_4.dart';
import 'package:orders_dev/Screens/edit_restaurant_info.dart';
import 'package:orders_dev/constants.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:provider/provider.dart';

import 'edit_categories_1.dart';

class EditMenuBaseOptions extends StatelessWidget {
  final String hotelName;
  const EditMenuBaseOptions({Key? key, required this.hotelName})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    void errorAlertDialogBox() async {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Center(
              child: Text(
            'Confirm Your Changes!',
            style: TextStyle(color: Colors.red),
          )),
          content: Text(
            'Changes have been made to the menu/billing details. Please restart Orders app in all active devices to reflect these changes.\n\n Press Ok to save and restart Orders app',
          ),
          actions: [
            ElevatedButton(
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(Colors.green),
                ),
                onPressed: () {
                  Provider.of<PrinterAndOtherDetailsProvider>(context,
                          listen: false)
                      .menuOrRestaurantInfoUpdated(false);
                  Phoenix.rebirth(context);
                  Navigator.pop(context);
                },
                child: Text('OK')),
          ],
        ),
        barrierDismissible: false,
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (Provider.of<PrinterAndOtherDetailsProvider>(context, listen: false)
            .menuOrRestaurantInfoUpdatedFromClass) {
          errorAlertDialogBox();
        } else {
          Navigator.pop(context);
        }
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: kAppBarBackgroundColor,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: kAppBarBackIconColor),
            onPressed: () {
              if (Provider.of<PrinterAndOtherDetailsProvider>(context,
                      listen: false)
                  .menuOrRestaurantInfoUpdatedFromClass) {
                errorAlertDialogBox();
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: Text(
            'Edit Info',
            style: kAppBarTextStyle,
          ),
        ),
        body: Container(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Bill Requirements',
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
                          builder: (Buildcontext) =>
                              RestaurantBaseInfo(hotelName: hotelName)));
                },
                child: Text(
                  'Basic Bill Information',
                  style: Theme.of(context).textTheme.headline6,
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Menu Options',
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
                          builder: (Buildcontext) =>
                              EditCategories(hotelName: hotelName)));
                },
                child: Text(
                  'Add/Edit/Re-Order Categories',
                  style: Theme.of(context).textTheme.headline6,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (Buildcontext) =>
                              EditItemsFloatButton(hotelName: hotelName)));
                },
                child: Text(
                  'Add/Edit Items',
                  style: Theme.of(context).textTheme.headline6,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
