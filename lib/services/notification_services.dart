import 'dart:math';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:my_chat/main.dart';

class NotificationServices {
  static ReceivedAction? initialAction;

  static Future<void> initializeLocalNotification() async {
    await AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: "high_importance_channel",
          channelName: "Message Channel",
          channelDescription: "Channel of messaging",
          importance: NotificationImportance.Max,
          defaultColor: Colors.transparent,
          channelShowBadge: true,
          locked: true,
          defaultRingtoneType: DefaultRingtoneType.Notification,
        ),
      ],
    );

    initialAction = await AwesomeNotifications()
        .getInitialNotificationAction(removeFromActionEvents: false);
  }

  static Future<void> startListeningNotificationEvents() async {
    AwesomeNotifications()
        .setListeners(onActionReceivedMethod: onActionReceivedMethod);
  }

  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    if (receivedAction.buttonKeyPressed == "READ") {
      //FROM HERE, WE NAVIGATE TO HOME WHERE WE WILL CREATE A FUNCTION TO HELP US NAVIGATE TO THE SPECIFC CHAT THE NOTIFICATION IS FROM

      MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/home', (route) => (route.settings.name != '/home') || route.isFirst,
          arguments: receivedAction);
    }
  }

  static Future<void> showNotification(
      {required RemoteMessage remoteMessage}) async {
    Random random = Random();
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: random.nextInt(100000000),
        channelKey: "high_importance_channel",
        largeIcon: remoteMessage.data['photo'],
        title: remoteMessage.data['name'],
        body: remoteMessage.data['text'],
        autoDismissible: true,
        category: NotificationCategory.Message,
        notificationLayout: NotificationLayout.Default,
        backgroundColor: Colors.transparent,
        payload: {
          'user': remoteMessage.data['user'],
          'name': remoteMessage.data['name'],
          'photo': remoteMessage.data['photo'],
          'email': remoteMessage.data['email'],
        },
      ),
      actionButtons: [
        NotificationActionButton(
          key: "READ",
          label: "Read Message",
          color: Colors.green,
          autoDismissible: true,
        ),
      ],
    );
  }

}
