import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:newapp/local/db_helper.dart';
import 'package:newapp/ui/readNotes.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize Timezone Database and configure device local timezone
      tz.initializeTimeZones();
      try {
        final TimezoneInfo timezoneInfo =
            await FlutterTimezone.getLocalTimezone();
        final String timeZoneName = timezoneInfo.identifier;
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        debugPrint("Timezone initialized to: $timeZoneName");
      } catch (e) {
        debugPrint("Could not set local timezone, defaulting to local: $e");
      }

      // 2. Configure Android and iOS initialization settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint("Notification tapped: ${response.payload}");
          final payload = response.payload;
          if (payload != null && int.tryParse(payload) != null) {
            navigateToNote(int.parse(payload));
          }
        },
      );

      // 3. Create high-importance Android notification channel
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'note_reminders_channel',
          'Note Reminders',
          description: 'High-priority notifications for scheduled note reminders',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );
        await androidImplementation.createNotificationChannel(channel);
      }

      _isInitialized = true;
      await requestPermissions();
    } catch (e) {
      debugPrint("NotificationService init error: $e");
    }
  }

  Future<void> requestPermissions() async {
    try {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
        await androidImplementation.requestExactAlarmsPermission();
      }

      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      debugPrint("Error requesting notification permissions: $e");
    }
  }

  Future<void> scheduleNoteReminder({
    required int id,
    required String title,
    required String content,
    required DateTime scheduledDate,
  }) async {
    try {
      await init();

      final tz.TZDateTime tzScheduledDate =
          tz.TZDateTime.from(scheduledDate, tz.local);

      if (tzScheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        debugPrint("Scheduled date $tzScheduledDate is in the past; skipping.");
        return;
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'note_reminders_channel',
        'Note Reminders',
        channelDescription: 'High-priority notifications for scheduled note reminders',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title.isNotEmpty ? title : "Note Reminder",
        body: content.isNotEmpty ? content : "You have a scheduled note reminder.",
        scheduledDate: tzScheduledDate,
        notificationDetails: platformDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: id.toString(),
      );

      debugPrint("Reminder successfully scheduled for Note $id at $tzScheduledDate");
    } catch (e) {
      debugPrint("Error scheduling reminder: $e");
    }
  }

  Future<void> cancelReminder(int id) async {
    try {
      await _notificationsPlugin.cancel(id: id);
      debugPrint("Cancelled reminder for Note $id");
    } catch (e) {
      debugPrint("Error cancelling reminder: $e");
    }
  }

  Future<void> navigateToNote(int noteId) async {
    try {
      final db = DbHelper.dbHelper;
      final allNotes = await db.getallnotes();
      final match = allNotes.firstWhere(
        (n) => n[DbHelper.COL_NOTE_SNO] == noteId,
        orElse: () => {},
      );

      if (match.isNotEmpty) {
        final navigatorState = navigatorKey.currentState;
        if (navigatorState != null) {
          final int? reminderAtMs = match[DbHelper.COL_NOTE_REMINDER_AT] as int?;
          final int? createdAtMs = match[DbHelper.COL_NOTE_CREATED_AT] as int?;

          navigatorState.push(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 280),
              pageBuilder: (context, animation, secondaryAnimation) => readnotes(
                noteId: match[DbHelper.COL_NOTE_SNO],
                title: match[DbHelper.COL_NOTE_TITLE] ?? '',
                desc: match[DbHelper.COL_NOTE_DESC] ?? '',
                color: Color(match[DbHelper.COL_NOTE_COLOR] ?? Colors.white.toARGB32()),
                isImportant: (match[DbHelper.COL_NOTE_IMPORTANT] ?? 0) == 1,
                reminderAt: reminderAtMs != null
                    ? DateTime.fromMillisecondsSinceEpoch(reminderAtMs)
                    : null,
                createdAt: createdAtMs != null
                    ? DateTime.fromMillisecondsSinceEpoch(createdAtMs)
                    : null,
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 1.0);
                const end = Offset.zero;
                const curve = Curves.ease;
                var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                return SlideTransition(position: animation.drive(tween), child: child);
              },
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error navigating to note $noteId from notification: $e");
    }
  }

  Future<void> checkLaunchNotification() async {
    try {
      final details =
          await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (details != null && details.didNotificationLaunchApp) {
        final payload = details.notificationResponse?.payload;
        if (payload != null && int.tryParse(payload) != null) {
          Future.delayed(const Duration(milliseconds: 400), () {
            navigateToNote(int.parse(payload));
          });
        }
      }
    } catch (e) {
      debugPrint("Error checking launch notification: $e");
    }
  }
}
