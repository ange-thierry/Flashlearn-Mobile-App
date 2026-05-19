import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';
import '../models/models.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background FCM message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif = FlutterLocalNotificationsPlugin();
  final _uuid = const Uuid();

  final List<AppNotification> _notifications = [];
  final StreamController<List<AppNotification>> _controller =
      StreamController<List<AppNotification>>.broadcast();

  Stream<List<AppNotification>> get notificationsStream => _controller.stream;
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.read).length;

  Future<void> initialize() async {
    // Timezone init — use UTC and offset local target times accordingly
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);

    // FCM permissions
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: true,
    );

    // Local notifications init
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotif.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Create notification channels
    await _createChannels();

    // FCM handlers
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    final token = await _fcm.getToken();
    print('FCM Token: $token');

    // Schedule recurring reminders
    await _scheduleDailyReminder();
    await _scheduleWeeklyReport();

    // Demo: show welcome notification after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      addNotification(
        type: NotifType.newContent,
        title: '👋 Welcome back!',
        body: 'Choose a subject field to continue your learning journey.',
      );
    });
  }

  Future<void> _createChannels() async {
    const studyChannel = AndroidNotificationChannel(
      'flashcard_channel',
      'Flashcard Notifications',
      description: 'Study results and achievements',
      importance: Importance.high,
    );
    const reminderChannel = AndroidNotificationChannel(
      'flashcard_reminders',
      'Study Reminders',
      description: 'Daily study reminders and weekly reports',
      importance: Importance.high,
    );
    final plugin = _localNotif
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await plugin?.createNotificationChannel(studyChannel);
    await plugin?.createNotificationChannel(reminderChannel);
  }

  // ── Scheduled Notifications ────────────────────────────────────────────────

  Future<void> _scheduleDailyReminder() async {
    await _localNotif.zonedSchedule(
      100,
      ' Daily Study Reminder',
      "Don't break your streak! Review your flashcards today.",
      _nextInstanceOf(hour: 20, minute: 0),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'flashcard_reminders',
          'Study Reminders',
          channelDescription: 'Daily study reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleWeeklyReport() async {
    await _localNotif.zonedSchedule(
      101,
      'Weekly Progress Report',
      'Your weekly study summary is ready — tap to view!',
      _nextInstanceOf(hour: 9, minute: 0, weekday: DateTime.sunday),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'flashcard_reminders',
          'Study Reminders',
          channelDescription: 'Weekly progress reports',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  tz.TZDateTime _nextInstanceOf({required int hour, required int minute, int? weekday}) {
    final now = DateTime.now();
    // Adjust local target hour to UTC
    final offsetHours = now.timeZoneOffset.inHours;
    var utcHour = (hour - offsetHours) % 24;
    if (utcHour < 0) utcHour += 24;

    var scheduled = tz.TZDateTime.utc(now.year, now.month, now.day, utcHour, minute);
    if (scheduled.isBefore(tz.TZDateTime.now(tz.UTC))) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    if (weekday != null) {
      while (scheduled.weekday != weekday) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
    }
    return scheduled;
  }

  // ── FCM Handlers ──────────────────────────────────────────────────────────

  void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final type = _parseType(data['type'] ?? 'daily_reminder');
    addNotification(
      type: type,
      title: message.notification?.title ?? data['title'] ?? 'Notification',
      body: message.notification?.body ?? data['body'] ?? '',
    );
    _showLocalNotification(message);
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    print('App opened from notification: ${message.data}');
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    await _localNotif.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'flashcard_channel',
          'Flashcard Notifications',
          channelDescription: 'Study reminders and achievements',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ── In-App Notification List ──────────────────────────────────────────────

  void addNotification({required NotifType type, required String title, required String body}) {
    _notifications.insert(
      0,
      AppNotification(
        id: _uuid.v4(),
        type: type,
        title: title,
        body: body,
        timestamp: DateTime.now(),
      ),
    );
    _controller.add(_notifications);
  }

  void markAllRead() {
    for (final n in _notifications) n.read = true;
    _controller.add(_notifications);
  }

  void dismiss(String id) {
    _notifications.removeWhere((n) => n.id == id);
    _controller.add(_notifications);
  }

  void clearAll() {
    _notifications.clear();
    _controller.add(_notifications);
  }

  // ── App-event Triggers ─────────────────────────────────────────────────────

  void notifyQuizResult(int pct, int score, int total, bool passed) => addNotification(
        type: NotifType.quizResult,
        title: 'Assessment Complete',
        body: 'You scored $pct% — $score/$total correct. ${passed ? "Passed! " : "Keep practicing "}',
      );

  void notifyExamResult(int pct, int score, int total, bool passed) => addNotification(
        type: NotifType.quizResult,
        title: 'Final Exam Complete',
        body: 'You scored $pct% — $score/$total. ${passed ? "Outstanding!" : "Review and try again"}',
      );

  void notifyLevelUnlocked(String level) => addNotification(
        type: NotifType.achievement,
        title: 'Level Mastered!',
        body: 'You\'ve completed the $level level assessment. Next level unlocked!',
      );

  void notifyCourseComplete(String fieldName) => addNotification(
        type: NotifType.achievement,
        title: 'Course Complete!',
        body: 'You\'ve mastered all of $fieldName! Incredible achievement!',
      );

  void notifyWeakTopic(String questionPreview) => addNotification(
        type: NotifType.weakTopic,
        title: ' Weak Area Identified',
        body: 'Review needed: "${questionPreview.substring(0, questionPreview.length.clamp(0, 50))}..."',
      );

  void notifyStreakExtended(int days) => addNotification(
        type: NotifType.achievement,
        title: 'Streak Extended!',
        body: '$days-day study streak! You\'re on fire! Keep it up!',
      );

  void notifyCardStudied(String fieldName, String level) => addNotification(
        type: NotifType.achievement,
        title: 'Level Studied!',
        body: 'All $level cards in $fieldName reviewed. Take the assessment!',
      );

  void notifyAdminAction(String action) => addNotification(
        type: NotifType.admin,
        title: 'Admin Action',
        body: action,
      );

  void notifySpacedRepetition(String fieldName) => addNotification(
        type: NotifType.spacedRep,
        title: 'Time to Review',
        body: 'Spaced repetition: Review your $fieldName cards now for best retention.',
      );

  void notifyWeeklyReport(int cards, int passed, int streak) => addNotification(
        type: NotifType.progress,
        title: 'Weekly Summary',
        body: '$cards cards studied · $passed quizzes passed · $streak-day streak',
      );

  NotifType _parseType(String type) =>
      {
        'daily_reminder': NotifType.dailyReminder,
        'spaced_rep': NotifType.spacedRep,
        'quiz_result': NotifType.quizResult,
        'achievement': NotifType.achievement,
        'weak_topic': NotifType.weakTopic,
        'progress': NotifType.progress,
        'new_content': NotifType.newContent,
        'admin': NotifType.admin,
      }[type] ??
      NotifType.dailyReminder;

  void dispose() => _controller.close();
}
