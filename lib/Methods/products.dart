class Product {
  String? productId;
  String? menuTitle;
  String? menuItem;
  double? price;
  //thisQuestionMarkEnsuresThisIsOptional

  Product({this.price, this.productId, this.menuTitle, this.menuItem});

  Map<String, dynamic> createMap() {
    return {'menuItem': menuItem, 'productPrice': price};
  }

  Product.fromFirestore(Map<String, dynamic> firestoreMap)
      : productId = firestoreMap['productId'],
        price = firestoreMap['productPrice'];
}
