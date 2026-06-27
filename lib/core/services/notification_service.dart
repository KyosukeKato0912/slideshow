import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ══════════════════════════════════════════════════════════
// 通知サービス
//
// flutter_local_notifications のラッパー。
// アプリ内のすべてのローカル通知をここで一元管理する。
//
// ■ 使用方法
//   1. main.dart で NotificationService.initialize() を呼ぶ
//   2. 通知を出したい箇所で NotificationService.showTimerFinished() を呼ぶ
//
// ■ 対応プラットフォーム
//   Android / iOS（Web は flutter_local_notifications 非対応のため無視）
// ══════════════════════════════════════════════════════════
class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();

  // ── 通知チャンネル（Android 8.0+）──────────────────────
  static const _channelId = 'habit_timer';
  static const _channelName = 'メリハリタイマー';
  static const _channelDesc = 'メリハリタイマーの終了通知';

  // ── 通知 ID ───────────────────────────────────────────
  static const _timerFinishedId = 1001;

  // ── 初期化 ────────────────────────────────────────────
  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
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

    // Android 13+ では実行時に通知権限をリクエストする必要がある
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ── メリハリタイマー終了通知 ───────────────────────────
  static Future<void> showTimerFinished() async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
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

    await _plugin.show(
      _timerFinishedId,
      'メリハリタイマー終了',
      '設定時間が経過しました。お疲れさまでした！',
      details,
    );
  }
}
