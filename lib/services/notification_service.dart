import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// 🚀 초기화 (앱 시작 시 한 번만 호출)
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      log('🔔 NotificationService 초기화 시작');

      // 1. 타임존 초기화
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

      // 2. 알림 플러그인 초기화 (간단한 버전)
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);

      await _localNotifications.initialize(initSettings);

      // 3. 권한 요청
      final hasPermissions = await _requestPermissions();
      if (!hasPermissions) {
        log('⚠️ 알림 권한이 없어서 알림 기능이 제한됩니다');
      }

      _isInitialized = true;
      log('✅ NotificationService 초기화 완료');
      return true;

    } catch (e) {
      log('❌ NotificationService 초기화 실패: $e');
      return false;
    }
  }

  /// 🔐 권한 요청
  Future<bool> _requestPermissions() async {
    try {
      // Android 13+ 알림 권한
      if (await Permission.notification.isDenied) {
        final result = await Permission.notification.request();
        if (result != PermissionStatus.granted) {
          return false;
        }
      }

      // 정확한 알람 권한 (Android 12+)
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }

      // AndroidFlutterLocalNotificationsPlugin을 통한 추가 권한
      final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        await androidImplementation.requestExactAlarmsPermission();
      }

      return true;
    } catch (e) {
      log('❌ 권한 요청 실패: $e');
      return false;
    }
  }

  /// ⏰ 특정 일정의 알림 예약 (간단한 버전)
  Future<bool> scheduleNotification(Schedule schedule) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return false;
    }

    // 알림이 비활성화되어 있으면 스킵
    if (!schedule.hasNotification) {
      log('📵 ${schedule.title}: 알림 비활성화됨');
      return false;
    }

    final notificationTime = schedule.getNotificationTime();
    if (notificationTime == null) {
      log('⏰ ${schedule.title}: 알림 시간이 과거거나 없음');
      return false;
    }

    try {
      // 알림 제목과 내용을 미리 변수로 저장
      final title = schedule.notificationTitle;
      final body = schedule.notificationBody;

      // 🔔 payload 추가 (일정 ID와 제목)
      final payload = '${schedule.id}:${schedule.title}';

      // 간단한 알림 설정
      final androidDetails = AndroidNotificationDetails(
        'withu_schedule_channel',
        'WithU 일정 알림',
        channelDescription: 'WithU 앱의 일정 알림',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        // 🔔 알림 탭 시 앱 실행 설정
        autoCancel: true,
        // 스타일 정보 추가 (더 간단한 버전)
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'WithU',
        ),
      );

      var notificationDetails = NotificationDetails(android: androidDetails);
      final tzScheduledTime = tz.TZDateTime.from(notificationTime, tz.local);

      await _localNotifications.zonedSchedule(
        schedule.notificationId,
        title,
        body,
        tzScheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload, // 🔔 탭 처리용 데이터 추가
      );

      log('⏰ ${schedule.title} 알림 예약 완료: ${notificationTime.toString().substring(11, 16)}');

      // 처리된 일정 목록에 추가
      await _markScheduleAsProcessed(schedule.id);

      return true;

    } catch (e) {
      log('❌ ${schedule.title} 알림 예약 실패: $e');
      return false;
    }
  }

  /// 📝 여러 일정의 알림을 한 번에 예약
  Future<int> scheduleMultipleNotifications(List<Schedule> schedules) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return 0;
    }

    int successCount = 0;

    for (final schedule in schedules) {
      final success = await scheduleNotification(schedule);
      if (success) successCount++;
    }

    log('📝 ${schedules.length}개 중 ${successCount}개 알림 예약 완료');
    return successCount;
  }

  /// 🗑️ 특정 일정의 알림 취소
  Future<void> cancelNotification(int notificationId) async {
    try {
      await _localNotifications.cancel(notificationId);
      log('🗑️ 알림 취소 완료: ID $notificationId');
    } catch (e) {
      log('❌ 알림 취소 실패: $e');
    }
  }

  /// 🗑️ 특정 일정의 알림 취소 (Schedule 객체로)
  Future<void> cancelScheduleNotification(Schedule schedule) async {
    await cancelNotification(schedule.notificationId);
    await _removeScheduleFromProcessed(schedule.id);
  }

  /// 🧹 모든 알림 취소
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      await _clearProcessedSchedules();
      log('🧹 모든 알림 취소 완료');
    } catch (e) {
      log('❌ 모든 알림 취소 실패: $e');
    }
  }

  /// 📋 현재 예약된 알림 목록 조회
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _localNotifications.pendingNotificationRequests();
    } catch (e) {
      log('❌ 예약된 알림 조회 실패: $e');
      return [];
    }
  }

  /// 📊 알림 상태 확인 (디버그용)
  Future<void> checkNotificationStatus() async {
    try {
      final pending = await getPendingNotifications();
      final processed = await _getProcessedSchedules();

      log('📋 === 알림 상태 ===');
      log('예약된 알림: ${pending.length}개');
      log('처리된 일정: ${processed.length}개');

      if (pending.isNotEmpty) {
        log('예약된 알림 목록:');
        for (final notification in pending) {
          log('  - ID: ${notification.id}, 제목: ${notification.title}');
        }
      }

      log('==================');
    } catch (e) {
      log('❌ 알림 상태 확인 실패: $e');
    }
  }

  /// 🧪 테스트 알림 (디버그용)
  Future<void> sendTestNotification() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return;
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription: '테스트용 알림',
        importance: Importance.max,
        priority: Priority.high,
      );

      await _localNotifications.show(
        999999,
        '🧪 WithU 테스트 알림',
        '알림 시스템이 정상 작동합니다! ${DateTime.now().toString().substring(11, 19)}',
        NotificationDetails(android: androidDetails),
      );

      log('🧪 테스트 알림 전송 완료');
    } catch (e) {
      log('❌ 테스트 알림 실패: $e');
    }
  }

  /// 🔄 기존 알림 정리 후 새로 동기화
  Future<void> resyncAllNotifications(List<Schedule> schedules) async {
    log('🔄 모든 알림 재동기화 시작');

    // 1. 기존 알림 모두 취소
    await cancelAllNotifications();

    // 2. 알림이 설정된 미래 일정들만 필터링
    final notifiableSchedules = schedules.where((schedule) {
      return schedule.hasNotification &&
          schedule.getNotificationTime() != null;
    }).toList();

    // 3. 새로 예약
    final successCount = await scheduleMultipleNotifications(notifiableSchedules);

    log('🔄 재동기화 완료: ${notifiableSchedules.length}개 중 ${successCount}개 성공');
  }

  /// ⚙️ 알림 설정 관리

  // 알림 전체 활성화/비활성화
  Future<void> setNotificationEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notification_enabled', enabled);

      if (!enabled) {
        await cancelAllNotifications();
      }

      log('⚙️ 알림 ${enabled ? "활성화" : "비활성화"}');
    } catch (e) {
      log('❌ 알림 설정 저장 실패: $e');
    }
  }

  // 알림 활성화 상태 확인
  Future<bool> isNotificationEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('notification_enabled') ?? true;
    } catch (e) {
      log('❌ 알림 설정 확인 실패: $e');
      return true;
    }
  }

  /// 📝 처리된 일정 관리 (SharedPreferences 사용)

  Future<void> _markScheduleAsProcessed(String scheduleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final processed = await _getProcessedSchedules();
      processed.add(scheduleId);
      await prefs.setStringList('processed_schedules', processed);
    } catch (e) {
      log('❌ 처리된 일정 저장 실패: $e');
    }
  }

  Future<void> _removeScheduleFromProcessed(String scheduleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final processed = await _getProcessedSchedules();
      processed.remove(scheduleId);
      await prefs.setStringList('processed_schedules', processed);
    } catch (e) {
      log('❌ 처리된 일정 제거 실패: $e');
    }
  }

  Future<List<String>> _getProcessedSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList('processed_schedules') ?? [];
    } catch (e) {
      log('❌ 처리된 일정 목록 가져오기 실패: $e');
      return [];
    }
  }

  Future<void> _clearProcessedSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('processed_schedules');
    } catch (e) {
      log('❌ 처리된 일정 목록 삭제 실패: $e');
    }
  }

  // 일정이 이미 처리되었는지 확인
  Future<bool> isScheduleProcessed(String scheduleId) async {
    final processed = await _getProcessedSchedules();
    return processed.contains(scheduleId);
  }

  /// 🔚 서비스 정리
  void dispose() {
    log('👋 NotificationService 종료');
  }
}