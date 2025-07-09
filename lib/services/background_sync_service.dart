import 'dart:developer';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart'; // 🔧 추가
import '../models/schedule.dart';
import 'firestore_service.dart';
import 'notification_service.dart';
import '../firebase_options.dart';

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
        isInDebugMode: true,
      );

      // 주기적 동기화 작업 등록 (15분마다)
      await Workmanager().registerPeriodicTask(
        SYNC_TASK,
        SYNC_TASK,
        frequency: Duration(minutes: 15), // 최소 15분
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

      log('✅ 15분마다 백그라운드 동기화 등록 완료');

      // 앱 시작 시 즉시 한 번 동기화
      await syncNow();

    } catch (e) {
      log('❌ 백그라운드 동기화 등록 실패: $e');
    }
  }

  /// 🛑 백그라운드 동기화 중지
  static Future<void> stopBackgroundSync() async {
    try {
      await Workmanager().cancelByUniqueName(SYNC_TASK);

      // 설정 저장
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

  /// 🚀 즉시 동기화 (앱 시작 시 또는 수동 새로고침)
  static Future<void> syncNow() async {
    log('🚀 즉시 동기화 시작');
    await _performSync();
  }

  /// 📡 실제 동기화 수행 (핵심 로직) - Firebase 초기화 포함
  static Future<void> _performSync() async {
    try {
      log('📡 동기화 시작 - Firebase 상태 확인 중...');

      // 🔧 Firebase 초기화 확인 및 초기화
      if (Firebase.apps.isEmpty) {
        log('🔥 Firebase 초기화되지 않음 - 초기화 시도 중...');

        // 백그라운드에서 Firebase 초기화 시도
        try {
          await Firebase.initializeApp();
          log('✅ Firebase 백그라운드 초기화 성공');
        } catch (e) {
          log('❌ Firebase 백그라운드 초기화 실패: $e');
          log('⚠️ 백그라운드 동기화 스킵 - Firebase 접근 불가');
          return;
        }
      } else {
        log('✅ Firebase 이미 초기화됨');
      }

      final firestoreService = FirestoreService();
      final notificationService = NotificationService();

      // NotificationService 초기화 확인
      try {
        await notificationService.initialize();
      } catch (e) {
        log('⚠️ NotificationService 초기화 실패 (백그라운드): $e');
        // 알림 서비스 실패해도 동기화는 계속 진행
      }

      // 1. 알림이 설정된 미래 일정들만 가져오기
      final allSchedules = await firestoreService.getAllSchedulesOnce();
      final now = DateTime.now();

      final notifiableSchedules = allSchedules.where((schedule) {
        return schedule.hasNotification &&
            schedule.scheduledAt.isAfter(now) &&
            schedule.getNotificationTime() != null;
      }).toList();

      if (notifiableSchedules.isEmpty) {
        log('📭 알림 설정된 미래 일정이 없습니다');
        await _updateLastSyncTime();
        return;
      }

      log('📬 알림 설정된 일정 ${notifiableSchedules.length}개 발견');

      // 2. 이미 처리된 일정들 확인
      final newSchedules = <Schedule>[];
      for (final schedule in notifiableSchedules) {
        final isProcessed = await notificationService.isScheduleProcessed(schedule.id);
        if (!isProcessed) {
          newSchedules.add(schedule);
        }
      }

      if (newSchedules.isEmpty) {
        log('🔄 모든 일정이 이미 처리되었습니다');
        await _updateLastSyncTime();
        return;
      }

      log('🆕 새로운 일정 ${newSchedules.length}개 발견');

      // 3. 새 일정들의 알림 등록
      int successCount = 0;
      for (final schedule in newSchedules) {
        final success = await notificationService.scheduleNotification(schedule);
        if (success) {
          successCount++;
        }
      }

      // 4. 마지막 동기화 시간 업데이트
      await _updateLastSyncTime();

      log('🎉 백그라운드 동기화 완료! ${newSchedules.length}개 중 ${successCount}개 성공');

    } catch (e) {
      log('❌ 백그라운드 동기화 실패: $e');
    }
  }

  /// 🔄 전체 재동기화 (설정 변경 시 또는 오류 복구용)
  static Future<void> fullResync() async {
    log('🔄 전체 재동기화 시작');

    try {
      // Firebase 초기화 확인
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final firestoreService = FirestoreService();
      final notificationService = NotificationService();

      // 1. 모든 일정 가져오기
      final allSchedules = await firestoreService.getAllSchedulesOnce();

      // 2. 기존 알림 정리 후 새로 동기화
      await notificationService.resyncAllNotifications(allSchedules);

      // 3. 마지막 동기화 시간 업데이트
      await _updateLastSyncTime();

      log('🔄 전체 재동기화 완료');

    } catch (e) {
      log('❌ 전체 재동기화 실패: $e');
    }
  }

  /// 📊 동기화 상태 확인 (디버그용)
  static Future<void> checkSyncStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getInt(LAST_SYNC_KEY);
      final isEnabled = await isBackgroundSyncEnabled();

      log('📊 === 동기화 상태 ===');
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

      // 알림 서비스 상태도 확인
      final notificationService = NotificationService();
      await notificationService.checkNotificationStatus();

      log('====================');

    } catch (e) {
      log('❌ 동기화 상태 확인 실패: $e');
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

  // 앱이 포그라운드로 올 때
  static Future<void> onAppResumed() async {
    log('📱 앱이 포그라운드로 복귀');

    try {
      // 마지막 동기화에서 10분 이상 지났으면 즉시 동기화
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getInt(LAST_SYNC_KEY);

      if (lastSync != null) {
        final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSync);
        final timeSinceSync = DateTime.now().difference(lastSyncTime);

        if (timeSinceSync.inMinutes >= 10) {
          log('🔄 10분 이상 지나서 즉시 동기화 실행');
          await syncNow();
        }
      } else {
        // 한 번도 동기화 안 했으면 즉시 실행
        await syncNow();
      }
    } catch (e) {
      log('❌ 앱 복귀 시 동기화 실패: $e');
    }
  }

  // 앱이 백그라운드로 갈 때
  static Future<void> onAppPaused() async {
    log('📱 앱이 백그라운드로 이동');
    // 필요시 정리 작업 수행
  }

  /// 🎛️ 알림 + 백그라운드 동기화 통합 설정
  static Future<void> setNotificationSystemEnabled(bool enabled) async {
    try {
      final notificationService = NotificationService();

      if (enabled) {
        // 알림 서비스 초기화
        await notificationService.initialize();
        await notificationService.setNotificationEnabled(true);

        // 백그라운드 동기화 시작
        await BackgroundSyncService.startBackgroundSync();

      } else {
        // 모든 알림 취소
        await notificationService.cancelAllNotifications();
        await notificationService.setNotificationEnabled(false);

        // 백그라운드 동기화 중지
        await BackgroundSyncService.stopBackgroundSync();
      }

      log('🎛️ 알림 시스템: ${enabled ? "활성화" : "비활성화"}');
    } catch (e) {
      log('❌ 알림 시스템 설정 실패: $e');
    }
  }
}

/// 🔄 백그라운드 콜백 함수 (WorkManager에서 호출) - Firebase 초기화 포함
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      log('🔄 백그라운드 작업 실행: $task');

      if (task == BackgroundSyncService.SYNC_TASK) {
        // 🔧 백그라운드에서 Firebase 완전 초기화
        try {
          // 1. WidgetsFlutterBinding 초기화 (필수!)
          WidgetsFlutterBinding.ensureInitialized();

          // 2. Firebase Apps 체크
          if (Firebase.apps.isEmpty) {
            log('🔥 백그라운드에서 Firebase 초기화 시작');

            // 3. Firebase 초기화 (옵션 포함)
            await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            );

            log('✅ 백그라운드 Firebase 초기화 성공');
          } else {
            log('✅ Firebase 이미 초기화됨');
          }

          // 4. 동기화 실행
          await BackgroundSyncService._performSync();

        } catch (firebaseError) {
          log('❌ 백그라운드 Firebase 초기화 실패: $firebaseError');

          // Firebase 실패 시에도 작업은 성공으로 처리 (재시도 방지)
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