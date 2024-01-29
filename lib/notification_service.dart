import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('notification_icon');

    void onDidReceiveNotificationResponse(
        NotificationResponse notificationResponse) async {}

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    notificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);

    //const NotificationDetails notificationDetails = NotificationDetails(android: );
    //notificationsPlugin.show(0, 'plain title', 'plain body', notificationDetails, payload: 'item x');
  }

  notificationDetails(
      {Importance importance = Importance.min,
      Priority priority = Priority.defaultPriority}) {
    AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'channelId',
      'channelName',
      importance: importance,
      priority: priority,
    );

    return NotificationDetails(android: androidNotificationDetails);
  }

  Future showNotification(
      {int id = 0,
      String? title,
      String? body,
      String? payload,
      Importance importance = Importance.min,
      Priority priority = Priority.min}) async {
    return notificationsPlugin.show(id, title, body,
        await notificationDetails(importance: importance, priority: priority),
        payload: payload);
  }
}
