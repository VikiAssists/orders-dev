import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';

// class FireStoreAddOrderService {
//   final _fireStore = FirebaseFirestore.instance;
//   final String hotelName;
//   String? tableOrParcel;
//   num? tableOrParcelNumber;
//   String? itemName;
//   num? number;
//   num? statusOfOrder;
//   num? priceOfEachItem;
//
//   FireStoreAddOrderService(
//       {required this.hotelName,
//       this.tableOrParcel,
//       this.tableOrParcelNumber,
//       this.itemName,
//       this.number,
//       this.statusOfOrder,
//       this.priceOfEachItem});
//
//   Future<void> addOrder() {
//     return _fireStore
//         .collection(hotelName)
//         .doc('currentorders')
//         .collection('currentorders')
//         .add(({
//           'item': itemName,
//           'number': number,
//           'tableorparcel': tableOrParcel,
//           'tableorparcelnumber': tableOrParcelNumber,
//           'statusoforder': statusOfOrder,
//           'priceofeach': priceOfEachItem,
//           'timeoforder': DateTime.now(),
//         }));
//   }
// }

// class FireStoreUpdateStatusOfCurrentOrder {
//   final _fireStore = FirebaseFirestore.instance;
//   final String hotelName;
//   final String itemID;
//   final num? statusOfOrder;
//
//   FireStoreUpdateStatusOfCurrentOrder(
//       {required this.hotelName,
//       required this.statusOfOrder,
//       required this.itemID});
//
//   Future<void> updateStatus() {
//     return _fireStore
//         .collection(hotelName)
//         .doc('currentorders')
//         .collection('currentorders')
//         .doc(itemID)
//         .update({'statusoforder': statusOfOrder});
//   }
// }

// class FireStoreDeleteFinishedOrder {
//   final _fireStore = FirebaseFirestore.instance;
//   final String hotelName;
//   final String eachItemId;
//   double? incrementBy;
//
//   FireStoreDeleteFinishedOrder({
//     required this.hotelName,
//     required this.eachItemId,
//     this.incrementBy,
//   });
//
//   Future<void> deleteFinishedOrder() {
//     return _fireStore
//         .collection(hotelName)
//         .doc('currentorders')
//         .collection('currentorders')
//         .doc(eachItemId)
//         .delete();
//   }
// }

class FireStoreAddOrderServiceAsString {
  final _fireStore = FirebaseFirestore.instance;
  final String hotelName;
  final String itemsUpdaterString;
  final String seatingNumber;
  final num captainStatus;
  final num chefStatus;

  FireStoreAddOrderServiceAsString(
      {required this.hotelName,
      required this.itemsUpdaterString,
      required this.seatingNumber,
      required this.captainStatus,
      required this.chefStatus});

  Future<void> addOrder() {
    return _fireStore
        .collection(hotelName)
        .doc('presentorders')
        .collection('presentorders')
        .doc(seatingNumber)
        .set({
      'addedItemsSet': '$itemsUpdaterString',
      'captainStatus': captainStatus,
      'chefStatus': chefStatus,
    });
  }
}

class FireStoreAddOrderServiceWithSplit {
  final _fireStore = FirebaseFirestore.instance;
  final String hotelName;
  final String itemsUpdaterString;
  final String seatingNumber;
  final num captainStatus;
  final num chefStatus;
  final String partOfTableOrParcel;
  final String partOfTableOrParcelNumber;

  FireStoreAddOrderServiceWithSplit(
      {required this.hotelName,
      required this.itemsUpdaterString,
      required this.seatingNumber,
      required this.captainStatus,
      required this.chefStatus,
      required this.partOfTableOrParcel,
      required this.partOfTableOrParcelNumber});

  Future<void> addOrder() {
    return _fireStore
        .collection(hotelName)
        .doc('presentorders')
        .collection('presentorders')
        .doc(seatingNumber)
        .set({
      'addedItemsSet': '$itemsUpdaterString',
      'captainStatus': captainStatus,
      'chefStatus': chefStatus,
      'partOfTableOrParcel': partOfTableOrParcel,
      'partOfTableOrParcelNumber': partOfTableOrParcelNumber
    });
  }
}

class FireStoreUpdateSerialNumber {
  final _fireStore = FirebaseFirestore.instance;
  final String hotelName;
  final String itemsUpdaterString;
  final String seatingNumber;

  FireStoreUpdateSerialNumber({
    required this.hotelName,
    required this.itemsUpdaterString,
    required this.seatingNumber,
  });

  Future<void> updateSerialNumber() {
    return _fireStore
        .collection(hotelName)
        .doc('presentorders')
        .collection('presentorders')
        .doc(seatingNumber)
        .update({
      'addedItemsSet': '$itemsUpdaterString',
    });
  }
}

class FireStoreAddItemToCancelledList {
  final _fireStore = FirebaseFirestore.instance;
  final String hotelName;
  final String deletedKey;
  final String deletedValue;

  FireStoreAddItemToCancelledList({
    required this.hotelName,
    required this.deletedKey,
    required this.deletedValue,
  });

  Future<void> addCancelledOrder() {
    return _fireStore
        .collection(hotelName)
        .doc('presentorders')
        .collection('presentorders')
        .doc('ZCancelledList') //CallingItZCancelledBecauseIWantItAsTheLast
        .set({
      deletedKey: deletedValue,
      'chefStatus': '9',
    }, SetOptions(merge: true));
  }
}

class FireStoreUnavailableItems {
  final _fireStore = FirebaseFirestore.instance;
  final String hotelName;
  Map<String, bool> unavailableItemsUpload = HashMap();

  FireStoreUnavailableItems(
      {required this.hotelName, required this.unavailableItemsUpload});

  Future<void> updateInventory() {
    return _fireStore
        .collection(hotelName)
        .doc('unavailableitems')
        .set(unavailableItemsUpload);
  }
}

class FireStoreChefWontCook {
  final _fireStore = FirebaseFirestore.instance;
  final String hotelName;
  String? chefNumber;
  Map<String, bool> unavailableItemsUpload = HashMap();

  FireStoreChefWontCook(
      {required this.hotelName,
      required this.unavailableItemsUpload,
      this.chefNumber});

  Future<void> updateChefWontCook() {
    return _fireStore
        .collection(hotelName)
        .doc('users')
        .collection('users')
        .doc(chefNumber)
        .set(unavailableItemsUpload);
  }
}

class FireStoreUpdateBill {
  final _fireStore = FirebaseFirestore.instance;
  final String hotelName;
  final String orderHistoryDocID;
  Map<String, String> printOrdersMap = HashMap();

  FireStoreUpdateBill(
      {required this.hotelName,
      required this.printOrdersMap,
      required this.orderHistoryDocID});

  Future<void> updateBill() {
    return _fireStore
        .collection(hotelName)
        .doc('orderhistory')
        .collection('orderhistory')
        .doc(orderHistoryDocID)
        .set(printOrdersMap);

    //    .add(printOrdersMap);
  }
}

class FireStoreUpdateStatistics {
  final _fireStore = FirebaseFirestore.instance;
  final String hotelName;
  final String docID;
  double? incrementBy;
  final String key;

  FireStoreUpdateStatistics(
      {required this.hotelName,
      required this.docID,
      this.incrementBy,
      required this.key});

  Future<void> updateStatistics() {
    return _fireStore
        .collection(hotelName)
        .doc('statistics')
        .collection('statistics')
        .doc(docID)
        .set(
            {key: FieldValue.increment(incrementBy!)}, SetOptions(merge: true));
  }
}

class FireStoreDeleteFinishedOrderInPresentOrders {
  final _fireStore = FirebaseFirestore.instance;
  final String hotelName;
  final String eachItemId;
  double? incrementBy;

  FireStoreDeleteFinishedOrderInPresentOrders({
    required this.hotelName,
    required this.eachItemId,
    this.incrementBy,
  });

  Future<void> deleteFinishedOrder() {
    return _fireStore
        .collection(hotelName)
        .doc('presentorders')
        .collection('presentorders')
        .doc(eachItemId)
        .delete();
  }
}

class FireStoreClearCancelledItemFromPresentOrders {
  final _fireStore = FirebaseFirestore.instance;
  final String hotelName;
  final String cancelledItemId;
  final String cancelledItemsDoc;

  FireStoreClearCancelledItemFromPresentOrders({
    required this.hotelName,
    required this.cancelledItemId,
    required this.cancelledItemsDoc,
  });

  Future<void> deleteCancelledItem() {
    return _fireStore
        .collection(hotelName)
        .doc('presentorders')
        .collection('presentorders')
        .doc(cancelledItemsDoc)
        .update({
      cancelledItemId: FieldValue.delete(),
    });
  }
}

class FireStoreAddOrEditMenuItem {
  final _fireStore = FirebaseFirestore.instance;
  final String hotelName;
  final String docIdItemName;
  final num price;
  final num variety;

  FireStoreAddOrEditMenuItem({
    required this.hotelName,
    required this.docIdItemName,
    required this.price,
    required this.variety,
  });

  Future<void> addOrEditMenuItem() {
    return _fireStore
        .collection(hotelName)
        .doc('menu')
        .collection('menu')
        .doc(docIdItemName)
        .set({
      'price': price,
      'variety': variety,
    });
  }
}

class FireStoreDeleteItemFromMenu {
  final _fireStore = FirebaseFirestore.instance;
  final String hotelName;
  final String eachItemMenuName;
  double? incrementBy;

  FireStoreDeleteItemFromMenu({
    required this.hotelName,
    required this.eachItemMenuName,
    this.incrementBy,
  });

  Future<void> deleteItemFromMenu() {
    return _fireStore
        .collection(hotelName)
        .doc('menu')
        .collection('menu')
        .doc(eachItemMenuName)
        .delete();
  }
}

class FireStoreAddOrEditCategory {
  final _fireStore = FirebaseFirestore.instance;
  final String hotelName;
  final String categoryKey;
  final String categoryName;

  FireStoreAddOrEditCategory(
      {required this.hotelName,
      required this.categoryKey,
      required this.categoryName});

  Future<void> addOrEditMenuCategory() {
    return _fireStore.collection(hotelName).doc('menu').update({
      categoryKey: categoryName,
    });
  }
}

class FireStoreDeleteParticularCategory {
  final _fireStore = FirebaseFirestore.instance;
  final String hotelName;
  final String deletedCategoryId;

  FireStoreDeleteParticularCategory({
    required this.hotelName,
    required this.deletedCategoryId,
  });

  Future<void> deleteCategory() {
    return _fireStore.collection(hotelName).doc('menu').update({
      deletedCategoryId: FieldValue.delete(),
    });
  }
}

class FireStoreBaseInfoStringSaving {
  final _fireStore = FirebaseFirestore.instance;
  final String hotelName;
  final String baseInfoKey;
  final String baseInfoValue;

  FireStoreBaseInfoStringSaving(
      {required this.hotelName,
      required this.baseInfoKey,
      required this.baseInfoValue});

  Future<void> addOrEditBaseInfo() {
    return _fireStore.collection(hotelName).doc('basicinfo').update({
      baseInfoKey: baseInfoValue,
    });
  }
}

class FireStoreBaseInfoNumSaving {
  final _fireStore = FirebaseFirestore.instance;
  final String hotelName;
  final String baseInfoKey;
  final num baseInfoValue;

  FireStoreBaseInfoNumSaving(
      {required this.hotelName,
      required this.baseInfoKey,
      required this.baseInfoValue});

  Future<void> addOrEditBaseInfo() {
    return _fireStore.collection(hotelName).doc('basicinfo').update({
      baseInfoKey: baseInfoValue,
    });
  }
}
