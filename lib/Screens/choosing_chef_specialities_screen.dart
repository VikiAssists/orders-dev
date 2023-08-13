import 'package:flutter/material.dart';
import 'package:orders_dev/Screens/inventory_chef_specialities.dart';
import 'package:orders_dev/constants.dart';

class ChoosingChefForSpecialities extends StatelessWidget {
  final String hotelName;
  final List<String> menuTitles;
  final List<String> entireMenuItems;
  const ChoosingChefForSpecialities(
      {Key? key,
      required this.hotelName,
      required this.menuTitles,
      required this.entireMenuItems})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
          'Chef Specialities',
          style: kAppBarTextStyle,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 10),
            ListTile(
              leading:
                  const Icon(IconData(0xf04b3, fontFamily: 'MaterialIcons')),
              title: Text(
                'Chef 1 Specialities',
                style: Theme.of(context).textTheme.headline6,
              ),
              onTap: () {
                // Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (Buildcontext) => InventoryOrChefSpecialities(
                              entireMenuItems: entireMenuItems,
                              entireTitles: menuTitles,
                              hotelName: hotelName,
                              chefNumber: '1',
                              inventoryOrChefSelection: false,
                            )));
              },
            ),
            const Divider(color: Colors.black54),
            ListTile(
              leading:
                  const Icon(IconData(0xf04b3, fontFamily: 'MaterialIcons')),
              title: Text(
                'Chef 2 Specialities',
                style: Theme.of(context).textTheme.headline6,
              ),
              onTap: () {
                // Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (Buildcontext) => InventoryOrChefSpecialities(
                              entireMenuItems: entireMenuItems,
                              entireTitles: menuTitles,
                              hotelName: hotelName,
                              chefNumber: '2',
                              inventoryOrChefSelection: false,
                            )));
              },
            ),
            const Divider(color: Colors.black54),
            ListTile(
              leading:
                  const Icon(IconData(0xf04b3, fontFamily: 'MaterialIcons')),
              title: Text(
                'Chef 3 Specialities',
                style: Theme.of(context).textTheme.headline6,
              ),
              onTap: () {
                // Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (Buildcontext) => InventoryOrChefSpecialities(
                              entireMenuItems: entireMenuItems,
                              entireTitles: menuTitles,
                              hotelName: hotelName,
                              chefNumber: '3',
                              inventoryOrChefSelection: false,
                            )));
              },
            ),
            const Divider(color: Colors.black54),
            ListTile(
              leading:
                  const Icon(IconData(0xf04b3, fontFamily: 'MaterialIcons')),
              title: Text(
                'Chef 4 Specialities',
                style: Theme.of(context).textTheme.headline6,
              ),
              onTap: () {
                // Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (Buildcontext) => InventoryOrChefSpecialities(
                              entireMenuItems: entireMenuItems,
                              entireTitles: menuTitles,
                              hotelName: hotelName,
                              chefNumber: '4',
                              inventoryOrChefSelection: false,
                            )));
              },
            ),
            const Divider(color: Colors.black54),
            ListTile(
              leading:
                  const Icon(IconData(0xf04b3, fontFamily: 'MaterialIcons')),
              title: Text(
                'Chef 5 Specialities',
                style: Theme.of(context).textTheme.headline6,
              ),
              onTap: () {
                // Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (Buildcontext) => InventoryOrChefSpecialities(
                              entireMenuItems: entireMenuItems,
                              entireTitles: menuTitles,
                              hotelName: hotelName,
                              chefNumber: '5',
                              inventoryOrChefSelection: false,
                            )));
              },
            ),
            const Divider(color: Colors.black54),
            ListTile(
              leading:
                  const Icon(IconData(0xf04b3, fontFamily: 'MaterialIcons')),
              title: Text(
                'Chef 6 Specialities',
                style: Theme.of(context).textTheme.headline6,
              ),
              onTap: () {
                // Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (Buildcontext) => InventoryOrChefSpecialities(
                              entireMenuItems: entireMenuItems,
                              entireTitles: menuTitles,
                              hotelName: hotelName,
                              chefNumber: '6',
                              inventoryOrChefSelection: false,
                            )));
              },
            ),
            const Divider(color: Colors.black54),
            ListTile(
              leading:
                  const Icon(IconData(0xf04b3, fontFamily: 'MaterialIcons')),
              title: Text(
                'Chef 7 Specialities',
                style: Theme.of(context).textTheme.headline6,
              ),
              onTap: () {
                // Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (Buildcontext) => InventoryOrChefSpecialities(
                              entireMenuItems: entireMenuItems,
                              entireTitles: menuTitles,
                              hotelName: hotelName,
                              chefNumber: '7',
                              inventoryOrChefSelection: false,
                            )));
              },
            ),
          ],
        ),
      ),
    );
  }
}
