import 'dart:developer';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationTestService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  /// 1단계: 기본 즉시 알림 테스트
  static Future<void> initializeBasicNotifications() async {
    log('🔔 기본 알림 초기화 시작');

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _localNotifications.initialize(initSettings);
    log('✅ 기본 알림 초기화 완료');
  }

  /// 즉시 알림 테스트
  static Future<void> sendTestNotificationNow() async {
    log('📱 즉시 알림 테스트 시작');

    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: '테스트용 알림 채널',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      1,
      '🔔 WithU 테스트',
      '즉시 알림이 정상 작동합니다! ${DateTime.now().toString().substring(11, 19)}',
      notificationDetails,
    );

    log('✅ 즉시 알림 전송 완료');
  }

  /// 권한 확인 및 요청
  static Future<bool> checkAndRequestPermissions() async {
    log('🔐 알림 권한 확인 시작');

    // Android 13+ 알림 권한
    if (await Permission.notification.isDenied) {
      final result = await Permission.notification.request();
      if (result != PermissionStatus.granted) {
        log('❌ 알림 권한이 거부되었습니다');
        return false;
      }
    }

    // 정확한 알람 권한 (Android 12+)
    try {
      if (await Permission.scheduleExactAlarm.isDenied) {
        final result = await Permission.scheduleExactAlarm.request();
        if (result != PermissionStatus.granted) {
          log('⚠️ 정확한 알람 권한이 거부되었습니다');
        }
      }

      // AndroidFlutterLocalNotificationsPlugin을 통한 추가 권한 요청
      final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final granted = await androidImplementation.requestExactAlarmsPermission();
        log('🔑 requestExactAlarmsPermission 결과: $granted');
      }

    } catch (e) {
      log('⚠️ 정확한 알람 권한 처리 중 오류: $e');
    }

    log('✅ 권한 확인 완료');
    return true;
  }

  /// 30초 후 알림 테스트 (zonedSchedule 올바른 사용법)
  static Future<void> scheduleTestNotificationIn30Seconds() async {
    log('⏰ 30초 후 알림 예약 시작');

    try {
      // 타임존 초기화
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

      const androidDetails = AndroidNotificationDetails(
        'test_30sec_channel',
        'Test 30 Second Notifications',
        channelDescription: '30초 테스트 알림 채널',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      final scheduledTime = tz.TZDateTime.now(tz.local).add(Duration(seconds: 30));

      log('📅 예약 시간: ${scheduledTime.toString()}');
      log('🕐 현재 시간: ${tz.TZDateTime.now(tz.local).toString()}');

      // 올바른 zonedSchedule 사용법
      await _localNotifications.zonedSchedule(
        3, // 고유 ID
        '🚀 WithU 30초 테스트',
        '30초 후 알림 성공! ${scheduledTime.toString().substring(11, 19)}',
        scheduledTime, // tz.TZDateTime 그대로 사용
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      log('✅ 30초 후 알림 예약 완료 - 백그라운드로 이동하세요!');

    } catch (e) {
      log('❌ 30초 알림 예약 실패: $e');
      log('💡 권한 문제일 가능성이 높습니다. 권한을 다시 확인해주세요.');
    }
  }

  /// 1분 후 알림 테스트 (올바른 zonedSchedule)
  static Future<void> scheduleTestNotificationIn1Minute() async {
    log('⏰ 1분 후 알림 예약 시작');

    try {
      // 타임존 초기화
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

      const androidDetails = AndroidNotificationDetails(
        'test_1min_channel',
        'Test 1 Minute Notifications',
        channelDescription: '1분 테스트 알림 채널',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
      );

      const notificationDetails = NotificationDetails(android: androidDetails);

      final scheduledTime = tz.TZDateTime.now(tz.local).add(Duration(minutes: 1));

      log('📅 예약 시간: ${scheduledTime.toString()}');
      log('🕐 현재 시간: ${tz.TZDateTime.now(tz.local).toString()}');

      // 올바른 zonedSchedule 사용법
      await _localNotifications.zonedSchedule(
        2, // 고유 ID
        '⏰ WithU 예약 알림',
        '1분 후 알림 테스트 성공! ${scheduledTime.toString().substring(11, 19)}',
        scheduledTime, // tz.TZDateTime 사용
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      log('✅ 1분 후 알림 예약 완료');

    } catch (e) {
      log('❌ 1분 후 알림 예약 실패: $e');

      // 간단한 대안 시도
      try {
        log('🔄 간단한 방법으로 재시도...');
        await _fallbackSchedule();
      } catch (fallbackError) {
        log('❌ 대안 방법도 실패: $fallbackError');
      }
    }
  }

  /// 대안 방법 (더 간단한 스케줄링)
  static Future<void> _fallbackSchedule() async {
    log('📱 대안 방법으로 알림 예약');

    const androidDetails = AndroidNotificationDetails(
      'fallback_channel',
      'Fallback Notifications',
      channelDescription: 'Fallback 알림',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    // 간단한 방법으로 30초 후 알림
    final scheduledTime = tz.TZDateTime.now(tz.local).add(Duration(seconds: 30));

    await _localNotifications.zonedSchedule(
      999,
      '🔧 WithU 대안',
      '대안 방법으로 30초 후 알림',
      scheduledTime,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, // 덜 정확하지만 더 안전
    );

    log('✅ 대안 알림 예약 완료');
  }

  /// WorkManager 초기화
  static Future<void> initializeWorkManager() async {
    log('🔧 WorkManager 초기화 시작');

    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: true,
      );
      log('✅ WorkManager 초기화 완료');
    } catch (e) {
      log('❌ WorkManager 초기화 실패: $e');
    }
  }

  /// WorkManager 백그라운드 작업 등록
  static Future<void> scheduleBackgroundWork() async {
    log('⚙️ 백그라운드 작업 등록 시작');

    try {
      await Workmanager().registerOneOffTask(
        'notification_test_task',
        'notificationTestTask',
        initialDelay: Duration(minutes: 2),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );
      log('✅ 2분 후 백그라운드 작업 등록 완료');
    } catch (e) {
      log('❌ 백그라운드 작업 등록 실패: $e');
    }
  }

  /// 모든 예약된 알림 취소
  static Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      await Workmanager().cancelAll();
      log('🗑️ 모든 알림 및 작업 취소 완료');
    } catch (e) {
      log('❌ 취소 중 오류: $e');
    }
  }

  /// 현재 예약된 알림 목록 확인
  static Future<void> checkPendingNotifications() async {
    try {
      final pending = await _localNotifications.pendingNotificationRequests();
      log('📋 예약된 알림 개수: ${pending.length}');

      if (pending.isEmpty) {
        log('⚠️ 예약된 알림이 없습니다!');
        log('💡 가능한 원인:');
        log('   1. Android 13/14 권한 문제');
        log('   2. 배터리 최적화 설정');
        log('   3. zonedSchedule 실행 실패');
        return;
      }

      for (final notification in pending) {
        log('  - ID: ${notification.id}, 제목: ${notification.title}');
        log('    내용: ${notification.body}');
      }
    } catch (e) {
      log('❌ 예약 목록 확인 실패: $e');
    }
  }
}

/// WorkManager 백그라운드 콜백 함수
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    log('🔄 백그라운드 작업 실행: $task');

    switch (task) {
      case 'notificationTestTask':
        await _sendBackgroundNotification();
        break;
    }

    return Future.value(true);
  });
}

/// 백그라운드에서 알림 전송
Future<void> _sendBackgroundNotification() async {
  log('📱 백그라운드 알림 전송');

  try {
    final plugin = FlutterLocalNotificationsPlugin();

    const androidDetails = AndroidNotificationDetails(
      'background_channel',
      'Background Notifications',
      channelDescription: '백그라운드 알림',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    await plugin.show(
      999,
      '🔄 WithU 백그라운드',
      '백그라운드 작업이 성공적으로 실행되었습니다!',
      NotificationDetails(android: androidDetails),
    );
  } catch (e) {
    log('❌ 백그라운드 알림 실패: $e');
  }
}