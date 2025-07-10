import 'dart:developer';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/schedule.dart';
import 'firestore_service.dart';
import 'notification_service.dart';
import '../firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class BackgroundSyncService {
  static const String SYNC_TASK = 'withu_sync_task';
  static const String LAST_SYNC_KEY = 'last_sync_timestamp';
  static const String BACKGROUND_SYNC_ENABLED_KEY = 'background_sync_enabled';

  /// 🚀 백그라운드 동기화 시작 (앱 시작 시 호출)
  static Future<void> startBackgroundSync() async {
    log('🔄 백그라운드 동기화 서비스 시작');

    try {
      // WorkManager 초기화
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false, // 🔧 false로 변경하여 디버그 알림 제거
      );

      // 주기적 동기화 작업 등록 (15분마다)
      await Workmanager().registerPeriodicTask(
        SYNC_TASK,
        SYNC_TASK,
        frequency: Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );

      // 설정 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(BACKGROUND_SYNC_ENABLED_KEY, true);

      log('✅ 15분마다 백그라운드 동기화 등록 완료 (조용한 모드)');

      // 앱 시작 시 즉시 한 번 동기화
      await syncNow();

    } catch (e) {
      log('❌ 백그라운드 동기화 등록 실패: $e');
    }
  }

  /// 📡 실제 동기화 수행 (핵심 로직) - 🔇 조용한 버전
  static Future<void> _performSync() async {
    try {
      log('📡 조용한 동기화 시작 (오늘 알림 일정만)');

      // Firebase 초기화 확인
      if (Firebase.apps.isEmpty) {
        log('🔥 Firebase 초기화되지 않음 - 초기화 시도 중...');
        try {
          await Firebase.initializeApp();
          log('✅ Firebase 백그라운드 초기화 성공');
        } catch (e) {
          log('❌ Firebase 백그라운드 초기화 실패: $e');
          return;
        }
      }

      final firestoreService = FirestoreService();
      final notificationService = NotificationService();

      // NotificationService 초기화
      try {
        await notificationService.initialize();
      } catch (e) {
        log('⚠️ NotificationService 초기화 실패 (백그라운드): $e');
        return;
      }

      // 오늘 알림 일정만 가져오기
      final todayNotifiableSchedules = await firestoreService.getTodayNotifiableSchedules();

      if (todayNotifiableSchedules.isEmpty) {
        log('📭 오늘 알림 설정된 일정이 없습니다');
        await _updateLastSyncTime();
        return;
      }

      log('📬 오늘 알림 설정된 일정 ${todayNotifiableSchedules.length}개 발견');

      // 이미 처리된 일정들 확인
      final newSchedules = <Schedule>[];
      for (final schedule in todayNotifiableSchedules) {
        final isProcessed = await notificationService.isScheduleProcessed(schedule.id);
        if (!isProcessed) {
          newSchedules.add(schedule);
        }
      }

      if (newSchedules.isEmpty) {
        log('🔄 오늘 모든 일정이 이미 처리되었습니다');
        await _updateLastSyncTime();
        return;
      }

      log('🆕 오늘 새로운 일정 ${newSchedules.length}개 발견');

      // 새 일정들의 알림 등록
      int successCount = 0;
      for (final schedule in newSchedules) {
        final success = await notificationService.scheduleNotification(schedule);
        if (success) {
          successCount++;
          log('✅ "${schedule.title}" 알림 예약 완료');
        } else {
          log('⚠️ "${schedule.title}" 알림 예약 실패');
        }
      }

      // 마지막 동기화 시간 업데이트
      await _updateLastSyncTime();

      // 🔇 성공 알림 제거 - 로그만 남기고 사용자 알림은 없음
      log('🎉 조용한 백그라운드 동기화 완료! 오늘 일정 ${newSchedules.length}개 중 ${successCount}개 성공');

      // ❌ 제거: 성공 알림 표시 코드 삭제
      // await _showSyncSuccessNotification(); // 이런 코드가 있었다면 제거

    } catch (e) {
      log('❌ 백그라운드 동기화 실패: $e');
    }
  }

  /// 🚀 즉시 동기화 (앱 시작 시 또는 수동 새로고침)
  static Future<void> syncNow() async {
    log('🚀 즉시 동기화 시작 (조용한 모드)');
    await _performSync();
  }

  /// 🔄 전체 재동기화 (설정 변경 시 또는 오류 복구용)
  static Future<void> fullResync() async {
    log('🔄 전체 재동기화 시작 (조용한 모드)');

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final firestoreService = FirestoreService();
      final notificationService = NotificationService();

      // 기존 알림 모두 취소
      await notificationService.cancelAllNotifications();
      log('🧹 기존 알림 모두 취소 완료');

      // 오늘과 내일 알림 일정만 가져오기
      final nearFutureSchedules = await firestoreService.getTodayAndTomorrowNotifiableSchedules();

      if (nearFutureSchedules.isEmpty) {
        log('📭 오늘~내일 알림 일정이 없습니다');
        await _updateLastSyncTime();
        return;
      }

      // 알림 재등록
      final successCount = await notificationService.scheduleMultipleNotifications(nearFutureSchedules);

      await _updateLastSyncTime();

      // 🔇 조용한 완료 로그
      log('🔄 조용한 전체 재동기화 완료: ${nearFutureSchedules.length}개 중 ${successCount}개 성공');

    } catch (e) {
      log('❌ 전체 재동기화 실패: $e');
    }
  }

  /// 🛑 백그라운드 동기화 중지
  static Future<void> stopBackgroundSync() async {
    try {
      await Workmanager().cancelByUniqueName(SYNC_TASK);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(BACKGROUND_SYNC_ENABLED_KEY, false);

      log('🛑 백그라운드 동기화 중지');
    } catch (e) {
      log('❌ 백그라운드 동기화 중지 실패: $e');
    }
  }

  /// ⚙️ 백그라운드 동기화 활성화 상태 확인
  static Future<bool> isBackgroundSyncEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(BACKGROUND_SYNC_ENABLED_KEY) ?? false;
    } catch (e) {
      log('❌ 백그라운드 동기화 상태 확인 실패: $e');
      return false;
    }
  }

  /// 🕐 마지막 동기화 시간 업데이트
  static Future<void> _updateLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(LAST_SYNC_KEY, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      log('❌ 마지막 동기화 시간 저장 실패: $e');
    }
  }

  /// 📱 앱 생명주기 관리
  static Future<void> onAppResumed() async {
    log('📱 앱이 포그라운드로 복귀');

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getInt(LAST_SYNC_KEY);

      if (lastSync != null) {
        final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
        final timeSinceSync = DateTime.now().difference(lastSyncTime);

        if (timeSinceSync.inMinutes >= 10) {
          log('🔄 10분 이상 지나서 조용한 즉시 동기화 실행');
          await syncNow();
        }
      } else {
        await syncNow();
      }
    } catch (e) {
      log('❌ 앱 복귀 시 동기화 실패: $e');
    }
  }

  static Future<void> onAppPaused() async {
    log('📱 앱이 백그라운드로 이동');
  }

  /// 📊 동기화 상태 확인 (디버그용)
  static Future<void> checkSyncStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getInt(LAST_SYNC_KEY);
      final isEnabled = await isBackgroundSyncEnabled();

      log('📊 === 조용한 동기화 상태 ===');
      log('Firebase 앱 개수: ${Firebase.apps.length}');
      log('백그라운드 동기화: ${isEnabled ? "활성화" : "비활성화"}');

      if (lastSync != null) {
        final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
        log('마지막 동기화: ${lastSyncTime.toString()}');

        final timeSinceSync = DateTime.now().difference(lastSyncTime);
        log('동기화 후 경과 시간: ${timeSinceSync.inMinutes}분');
      } else {
        log('마지막 동기화: 없음');
      }

      final notificationService = NotificationService();
      await notificationService.checkNotificationStatus();

      log('=============================');

    } catch (e) {
      log('❌ 동기화 상태 확인 실패: $e');
    }
  }

  /// 🎛️ 알림 + 백그라운드 동기화 통합 설정
  static Future<void> setNotificationSystemEnabled(bool enabled) async {
    try {
      final notificationService = NotificationService();

      if (enabled) {
        await notificationService.initialize();
        await notificationService.setNotificationEnabled(true);
        await BackgroundSyncService.startBackgroundSync();
      } else {
        await notificationService.cancelAllNotifications();
        await notificationService.setNotificationEnabled(false);
        await BackgroundSyncService.stopBackgroundSync();
      }

      log('🎛️ 조용한 알림 시스템: ${enabled ? "활성화" : "비활성화"}');
    } catch (e) {
      log('❌ 알림 시스템 설정 실패: $e');
    }
  }
}

/// 🔄 백그라운드 콜백 함수 (WorkManager에서 호출) - 조용한 버전
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      log('🔄 조용한 백그라운드 작업 실행: $task');

      WidgetsFlutterBinding.ensureInitialized();
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

      if (task == BackgroundSyncService.SYNC_TASK) {
        try {
          WidgetsFlutterBinding.ensureInitialized();

          if (Firebase.apps.isEmpty) {
            log('🔥 백그라운드에서 Firebase 초기화 시작');

            await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            );

            log('✅ 백그라운드 Firebase 초기화 성공');
          } else {
            log('✅ Firebase 이미 초기화됨');
          }

          // 🔇 조용한 동기화 실행
          await BackgroundSyncService._performSync();

        } catch (firebaseError) {
          log('❌ 백그라운드 Firebase 초기화 실패: $firebaseError');
          return true;
        }
      }

      return true;

    } catch (e) {
      log('❌ 백그라운드 콜백 전체 실패: $e');
      return false;
    }
  });
}