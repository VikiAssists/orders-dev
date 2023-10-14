import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class NotificationProvider extends ChangeNotifier {
  sendNotification({
    required List<String> token,
    required String title, //ThisWillBeDatabaseName
    required String restaurantNameForNotification, //ThisWillBeHotelName
    required String body,
  }) async {
    const postUrl = 'https://fcm.googleapis.com/fcm/send';
    Map<String, dynamic> data;

    data = {
      "registration_ids": token,
      "collapse_key": "type_a",
      "notification": {
        "title": restaurantNameForNotification,
        "body": "We are looking for updates",
        "tag": "unique_tag"
      },
      "data": {"title": title, "body": body},
      "priority": "high",
      // "timeToLive": 10
    };

    final response =
        await http.post(Uri.parse(postUrl), body: json.encode(data), headers: {
      'content-type': 'application/json',
      'Authorization':
          "Key=AAAAOiHooQw:APA91bFDm5VqhrO8-SIryNpq0gdmdQD56kEcOu6i0u8XUwieQ5EYqiaX8VLTh0B0xc5E5TQlM20v6uaJfgTjTTIyYDYzTv1PnW0498woFJ4iX2ReX-STSIMYBXdD-rv4Y2oO0tXgTp4F"
    });
    print('did the notification go');
    print(response.body);
  }
}
