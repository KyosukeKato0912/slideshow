import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../constants/app_colors.dart';

// ══════════════════════════════════════════════════════════
// 通知サービス
//
// ■ 即時通知
//   showWorkFinished()  : 作業終了 → 休憩開始（軽い振動＋タイマー画面内バナー / ネイティブ通知）
//   showBreakFinished() : 休憩終了 → 作業開始（軽い振動＋タイマー画面内バナー / ネイティブ通知）
//
// ■ 毎日スケジュール通知
//   scheduleReminder(hour, minute) : 毎日指定時刻に作業開始を促す通知を登録
//   cancelReminder()               : 作業開始促進通知を解除
//
// ■ 復帰促進通知
//   scheduleComebackIfNeeded(lastPracticeDate, thresholdDays)
//     : 最終練習日から thresholdDays 日後の正午に1回だけ通知を登録。
//       既に閾値を超えていれば即日正午（過去なら翌日）に登録。
//   cancelComeback() : 復帰促進通知を解除
// ══════════════════════════════════════════════════════════
class NotificationService {
  NotificationService._();

  static final navigatorKey = GlobalKey<NavigatorState>();
  static final _plugin = FlutterLocalNotificationsPlugin();

  // ── 通知チャンネル ────────────────────────────────────
  static const _timerChannelId   = 'habit_timer';
  static const _timerChannelName = 'メリハリタイマー';
  static const _timerChannelDesc = 'メリハリタイマーのフェーズ切替通知';

  static const _reminderChannelId   = 'habit_reminder';
  static const _reminderChannelName = '作業開始促進';
  static const _reminderChannelDesc = '毎日の作業開始を促す通知';

  // ── 通知ID ───────────────────────────────────────────
  static const _workFinishedId  = 1001;
  static const _breakFinishedId = 1002;
  static const _reminderId      = 2001;
  static const _comebackId      = 2002;

  // ── 通知テキスト ──────────────────────────────────────
  static const _titleWorkFinished    = '作業終了 — 休憩を始めましょう';
  static const _messageWorkFinished  = '設定時間が経過しました。少し休憩しましょう！';
  static const _titleBreakFinished   = '休憩終了 — 作業を再開しましょう';
  static const _messageBreakFinished = '休憩時間が終わりました。また頑張りましょう！';
  static const _titleReminder        = '今日も練習しましょう！';
  static const _messageReminder      = 'イラスト練習の時間です。少しずつ続けることが上達への近道です🎨';
  static const _titleComeback        = 'しばらく練習が空いていますよ！';
  static const _messageComeback      = 'また少しずつ練習を再開しませんか？あなたのペースで大丈夫です🎨';

  // ── 初期化 ────────────────────────────────────────────
  static Future<void> initialize() async {
    if (kIsWeb) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );
    await _plugin.initialize(initSettings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ── 作業終了（→ 休憩開始）通知 ────────────────────────
  static Future<void> showWorkFinished() async {
    HapticFeedback.lightImpact();
    if (kIsWeb) {
      _showWebBanner(
          icon: Icons.coffee_outlined,
          title: _titleWorkFinished,
          message: _messageWorkFinished);
      return;
    }
    await _showNativeNow(
        id: _workFinishedId,
        channelId: _timerChannelId,
        channelName: _timerChannelName,
        channelDesc: _timerChannelDesc,
        title: _titleWorkFinished,
        message: _messageWorkFinished);
  }

  // ── 休憩終了（→ 作業開始）通知 ────────────────────────
  static Future<void> showBreakFinished() async {
    HapticFeedback.lightImpact();
    if (kIsWeb) {
      _showWebBanner(
          icon: Icons.play_circle_outline,
          title: _titleBreakFinished,
          message: _messageBreakFinished);
      return;
    }
    await _showNativeNow(
        id: _breakFinishedId,
        channelId: _timerChannelId,
        channelName: _timerChannelName,
        channelDesc: _timerChannelDesc,
        title: _titleBreakFinished,
        message: _messageBreakFinished);
  }

  // ── 作業開始促進：毎日スケジュール登録 ────────────────
  // Web では SnackBar 不可のため何もしない。
  static Future<void> scheduleReminder({
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return;

    await cancelReminder(); // 既存を一旦解除してから再登録

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    // 今日の指定時刻が過去なら翌日に設定
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      _reminderChannelId,
      _reminderChannelName,
      channelDescription: _reminderChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.zonedSchedule(
      _reminderId,
      _titleReminder,
      _messageReminder,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // 毎日繰り返し
    );
  }

  // ── 作業開始促進：スケジュール解除 ───────────────────
  static Future<void> cancelReminder() async {
    if (kIsWeb) return;
    await _plugin.cancel(_reminderId);
  }

  // ── 復帰促進：スケジュール登録 ────────────────────────
  // lastPracticeDate : 最後に練習した日（時刻は無視）
  // thresholdDays    : この日数分空白が続いたら通知する
  //
  // 登録タイミング：lastPracticeDate + thresholdDays 日後の正午。
  // その時刻が既に過去の場合（= 既に閾値超過）は翌日正午に設定。
  // Web では何もしない。
  static Future<void> scheduleComebackIfNeeded({
    required DateTime lastPracticeDate,
    required int thresholdDays,
  }) async {
    if (kIsWeb) return;

    await cancelComeback(); // 既存を解除してから再登録

    final last = DateTime(
        lastPracticeDate.year, lastPracticeDate.month, lastPracticeDate.day);
    final triggerDate = last.add(Duration(days: thresholdDays));

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      triggerDate.year,
      triggerDate.month,
      triggerDate.day,
      12, // 正午
      0,
    );
    // 既に過去なら翌日正午に設定
    if (scheduled.isBefore(now)) {
      final tomorrow = now.add(const Duration(days: 1));
      scheduled = tz.TZDateTime(
          tz.local, tomorrow.year, tomorrow.month, tomorrow.day, 12, 0);
    }

    const androidDetails = AndroidNotificationDetails(
      _reminderChannelId,
      _reminderChannelName,
      channelDescription: _reminderChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _plugin.zonedSchedule(
      _comebackId,
      _titleComeback,
      _messageComeback,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      // 繰り返しなし（1回きり）
    );
  }

  // ── 復帰促進：スケジュール解除 ────────────────────────
  static Future<void> cancelComeback() async {
    if (kIsWeb) return;
    await _plugin.cancel(_comebackId);
  }

  // ── Web：アプリ内バナー ────────────────────────────────
  static void _showWebBanner({
    required IconData icon,
    required String title,
    required String message,
  }) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text('$title\n$message',
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        backgroundColor: AppColors.themeDark,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── ネイティブ：即時プッシュ通知 ──────────────────────
  static Future<void> _showNativeNow({
    required int id,
    required String channelId,
    required String channelName,
    required String channelDesc,
    required String title,
    required String message,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
    await _plugin.show(id, title, message, details);
  }
}
