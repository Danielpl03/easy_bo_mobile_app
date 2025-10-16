import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificacionesService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (_initialized) return;

    //init Timezone handling
    tz.initializeTimeZones();
    final String currentTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(currentTimezone));

    //android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    //ios
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    //initialization settings
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      // onDidReceiveBackgroundNotificationResponse:
      //     (NotificationResponse details) async {},
      // onDidReceiveNotificationResponse: (NotificationResponse details) async {},
    );
  }

  //notificaciones
  static NotificationDetails _notificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_channel_id',
        'Daily Reminder',
        channelDescription: 'Daily Notification Channel',
        importance: Importance.max,
        priority: Priority.high,
        showProgress: true,
        // playSound: true,
        // sound: RawResourceAndroidNotificationSound(sound),
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  //show notification
  static Future<void> showNotification({
    int id = 0,
    String title = '',
    String body = '',
    // String payload,
  }) async {
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      _notificationDetails(),
    );
  }

  //schedule notification
  static Future<void> scheduleNotification({
    int id = 1,
    String title = '',
    String body = '',
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,

      matchDateTimeComponents: DateTimeComponents.time,
    );

    print('notificacion programada');
  }

  Future<void> cancellAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
  
}
