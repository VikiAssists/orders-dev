import 'package:flutter/material.dart';
import 'package:orders_dev/Providers/printer_and_other_details_provider.dart';
import 'package:orders_dev/Screens/searching_Connecting_Printer_Screen.dart';
import 'package:orders_dev/constants.dart';
import 'package:provider/provider.dart';

class PrinterSettings extends StatelessWidget {
  final String chefOrCaptain;
  const PrinterSettings({Key? key, required this.chefOrCaptain})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    String connectingPrinterName = chefOrCaptain == 'Captain'
        ? Provider.of<PrinterAndOtherDetailsProvider>(context)
            .captainPrinterNameFromClass
        : Provider.of<PrinterAndOtherDetailsProvider>(context)
            .chefPrinterNameFromClass;
    String connectingPrinterAddress = chefOrCaptain == 'Captain'
        ? Provider.of<PrinterAndOtherDetailsProvider>(context)
            .captainPrinterAddressFromClass
        : Provider.of<PrinterAndOtherDetailsProvider>(context)
            .chefPrinterAddressFromClass;
    String connectingPrinterSize = chefOrCaptain == 'Captain'
        ? Provider.of<PrinterAndOtherDetailsProvider>(context)
            .captainPrinterSizeFromClass
        : Provider.of<PrinterAndOtherDetailsProvider>(context)
            .chefPrinterSizeFromClass;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kAppBarBackgroundColor,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kAppBarBackIconColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          '${chefOrCaptain} Printer Settings',
          style: kAppBarTextStyle,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            chefOrCaptain != 'Captain'
                ? ListTile(
                    title: Text('Chef KOT Print'),
                    subtitle: Text(
                        'Orders will be auto-accepted when chef KOT is On'),
                    trailing: Switch(
                      // This bool value toggles the switch.
                      value:
                          Provider.of<PrinterAndOtherDetailsProvider>(context)
                              .chefPrinterKOTFromClass,
                      activeColor: Colors.green,
                      onChanged: (bool changedValue) {
                        // This is called when the user toggles the switch.
                        Provider.of<PrinterAndOtherDetailsProvider>(context,
                                listen: false)
                            .neededOrNotChefKot(changedValue);
                      },
                    ),
                  )
                : SizedBox.shrink(),
            chefOrCaptain != 'Captain'
                ? Divider(thickness: 2)
                : SizedBox.shrink(),
            chefOrCaptain != 'Captain'
                ? ListTile(
                    title: Text('Delivery Slip Print'),
                    trailing: Switch(
                      // This bool value toggles the switch.
                      value:
                          Provider.of<PrinterAndOtherDetailsProvider>(context)
                              .chefPrinterAfterOrderReadyPrintFromClass,
                      activeColor: Colors.green,
                      onChanged: (bool changedValue) {
                        // This is called when the user toggles the switch.

                        Provider.of<PrinterAndOtherDetailsProvider>(context,
                                listen: false)
                            .neededOrNotChefAfterOrderReadyPrint(changedValue);
                      },
                    ),
                  )
                : SizedBox.shrink(),
            chefOrCaptain != 'Captain'
                ? Divider(thickness: 2)
                : SizedBox.shrink(),
            SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Stored Printer Name : ${connectingPrinterName == '' ? 'Not Yet Added' : connectingPrinterName}',
                style: TextStyle(fontSize: 15),
              ),
            ),
            SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Stored Printer Address : ${connectingPrinterAddress == '' ? 'Not Yet Added' : connectingPrinterAddress}',
                style: TextStyle(fontSize: 15),
              ),
            ),
            SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Stored Printer Size : ${connectingPrinterSize == '0' ? 'Not Yet Added' : connectingPrinterSize}',
                style: TextStyle(fontSize: 15),
              ),
            ),
            Divider(thickness: 2),
            Center(
              child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.green),
                  ),
                  onPressed: () {
                    if (chefOrCaptain == 'Captain') {
                      connectingPrinterName = '';
                      connectingPrinterAddress = '';
                      connectingPrinterSize = '0';
                      Provider.of<PrinterAndOtherDetailsProvider>(context,
                              listen: false)
                          .addCaptainPrinter(connectingPrinterName,
                              connectingPrinterAddress, connectingPrinterSize);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SearchingConnectingPrinter(
                                  chefOrCaptain: 'Captain')));
                    } else {
                      connectingPrinterName = '';
                      connectingPrinterAddress = '';
                      connectingPrinterSize = '0';
                      Provider.of<PrinterAndOtherDetailsProvider>(context,
                              listen: false)
                          .addChefPrinter(connectingPrinterName,
                              connectingPrinterAddress, connectingPrinterSize);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SearchingConnectingPrinter(
                                  chefOrCaptain: 'Chef')));
                    }
                  },
                  child: connectingPrinterName == ''
                      ? Text('Add Printer')
                      : Text('Change')),
            ),
          ],
        ),
      ),
    );
  }
}
