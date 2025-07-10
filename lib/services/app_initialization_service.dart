import 'dart:developer';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../firebase_options.dart';
import 'notification_service.dart';
import 'background_sync_service.dart';

/// 🚀 앱 초기화 통합 서비스
class AppInitializationService {

  /// 🎯 전체 앱 초기화 (main.dart에서 한 번만 호출)
  static Future<void> initialize() async {
    try {
      log('🚀 WithU 앱 초기화 시작');

      // 1. 기본 설정
      await _initializeBasicSettings();

      // 2. Firebase 초기화
      await _initializeFirebase();

      // 3. WorkManager 초기화 (한 번만)
      await _initializeWorkManager();

      // 4. 알림 서비스 초기화
      await _initializeNotificationService();

      // 5. 백그라운드 동기화 시작
      await _initializeBackgroundSync();

      log('🎉 WithU 앱 초기화 완료!');

    } catch (e) {
      log('❌ 앱 초기화 실패: $e');
      rethrow;
    }
  }

  /// ⚙️ 기본 설정 초기화
  static Future<void> _initializeBasicSettings() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 타임존 설정
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    log('✅ 기본 설정 초기화 완료');
  }

  /// 🔥 Firebase 초기화
  static Future<void> _initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    log('✅ Firebase 초기화 완료');
  }

  /// 🧹 WorkManager 초기화 (한 번만)
  static Future<void> _initializeWorkManager() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasReset = prefs.getBool('workmanager_reset_done') ?? false;

      if (!hasReset) {
        log('🧹 WorkManager 첫 초기화 시작');

        // 모든 기존 작업 삭제
        await Workmanager().cancelAll();
        log('✅ 기존 WorkManager 작업 모두 삭제');

        // 초기화 완료 표시
        await prefs.setBool('workmanager_reset_done', true);
        log('✅ WorkManager 초기화 완료 기록');

        // 잠깐 대기
        await Future.delayed(Duration(seconds: 1));
      } else {
        log('📱 WorkManager 이미 초기화됨 - 스킵');
      }

    } catch (e) {
      log('❌ WorkManager 초기화 실패: $e');
    }
  }

  /// 🔔 알림 서비스 초기화
  static Future<void> _initializeNotificationService() async {
    final notificationService = NotificationService();
    await notificationService.initialize();

    // 알림 탭 리스너 설정
    await _setupNotificationTapHandler();

    log('✅ 알림 서비스 초기화 완료');
  }

  /// 🔄 백그라운드 동기화 초기화
  static Future<void> _initializeBackgroundSync() async {
    await BackgroundSyncService.startBackgroundSync();
    log('✅ 백그라운드 동기화 서비스 시작 완료');
  }

  /// 🔔 알림 탭 처리 설정
  static Future<void> _setupNotificationTapHandler() async {
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        await handleNotificationTap(response);
      },
    );
  }

  /// 🔔 알림 탭 처리 함수
  static Future<void> handleNotificationTap(NotificationResponse response) async {
    try {
      log('🔔 알림 탭됨: ${response.payload}');

      // 메인 화면으로 이동 로직
      final payload = response.payload;
      if (payload != null && payload.isNotEmpty) {
        log('📅 일정 정보: $payload');
        // TODO: 특정 일정이 있는 날짜로 이동하는 기능
        _navigateToCalendar();
      }

    } catch (e) {
      log('❌ 알림 탭 처리 실패: $e');
    }
  }

  /// 📱 캘린더로 이동 (전역 키 사용)
  static void _navigateToCalendar() {
    // main.dart에서 설정한 전역 키 사용
    // mainScreenKey.currentState?.navigateToCalendar();
    log('📅 캘린더로 이동 요청');
  }

  /// 🔧 개발용 - WorkManager 강제 리셋
  static Future<void> forceResetWorkManager() async {
    try {
      log('🔧 WorkManager 강제 리셋 시작');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('workmanager_reset_done', false);

      await Workmanager().cancelAll();
      await Future.delayed(Duration(seconds: 1));

      await _initializeWorkManager();
      await _initializeBackgroundSync();

      log('🔧 WorkManager 강제 리셋 완료');

    } catch (e) {
      log('❌ WorkManager 강제 리셋 실패: $e');
    }
  }
}