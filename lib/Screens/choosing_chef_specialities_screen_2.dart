import 'package:flutter/material.dart';
import 'package:orders_dev/Screens/inventory_chef_specialities.dart';
import 'package:orders_dev/Screens/inventory_chef_specialities_2.dart';
import 'package:orders_dev/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChefSpecialities extends StatefulWidget {
  final String hotelName;
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic> currentUserProfileMap;

  const ChefSpecialities({
    Key? key,
    required this.hotelName,
    required this.items,
    required this.currentUserProfileMap,
  }) : super(key: key);

  @override
  State<ChefSpecialities> createState() => _ChefSpecialitiesState();
}

class _ChefSpecialitiesState extends State<ChefSpecialities> {
  List<Map<String, dynamic>> allUsers = [];

  void allRestaurantUserDetails() async {
    Map<String, dynamic> tempMap = {};
//ToGetAllTheUsersWhoAreInThisRestaurant
    final allUsersQuery = await FirebaseFirestore.instance
        .collection('loginDetails')
        .where('restaurantDatabase.${'${widget.hotelName}'}', isEqualTo: true)
        .get();
    for (var eachUser in allUsersQuery.docs) {
//toEnsureAdminCanSeeAllUserButNon-AdminUsersCanSeeOnlyNon-AdminUsers
      if (widget.currentUserProfileMap[widget.hotelName]['admin']) {
        tempMap = eachUser[widget.hotelName];
        tempMap.addAll({'chefPhoneNumber': eachUser.id});

        allUsers.add(tempMap);
      } else {
        if (eachUser[widget.hotelName]['admin'] == false) {
          tempMap = eachUser[widget.hotelName];
          tempMap.addAll({'chefPhoneNumber': eachUser.id});

          allUsers.add(tempMap);
        }
      }
    }
    setState(() {});
  }

  @override
  void initState() {
    allRestaurantUserDetails();
    // TODO: implement initState
    super.initState();
  }

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
          'Choose the Chef',
          style: kAppBarTextStyle,
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
                itemCount: allUsers.length,
                itemBuilder: (context, index) {
                  final chefName = allUsers[index]['username'];
                  final chefPhoneNumber = allUsers[index]['chefPhoneNumber'];
                  return ListTile(
                    leading: const Icon(
                        IconData(0xf04b3, fontFamily: 'MaterialIcons')),
                    title: Text(
                      '$chefName',
                      style: Theme.of(context).textTheme.headline6,
                    ),
                    onTap: () {
                      // Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (Buildcontext) =>
                                  InventoryOrChefSpecialitiesWithFCM(
                                    allMenuItems: widget.items,
                                    chefPhoneNumber: chefPhoneNumber,
                                    hotelName: widget.hotelName,
                                    inventoryOrChefSelection: false,
                                  )));
                    },
                  );
                }),
          ),
        ],
      ),
    );
  }
}
