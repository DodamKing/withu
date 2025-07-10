import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'withu_schedules';

  // ===== 기존 메서드들 (그대로 유지) =====

  // 일정 추가
  Future<void> addSchedule(Schedule schedule) async {
    await _firestore.collection(_collection).add(schedule.toFirestore());
  }

  // 모든 일정 가져오기 (실시간)
  Stream<List<Schedule>> getAllSchedules() {
    return _firestore
        .collection(_collection)
        .orderBy('scheduled_at')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Schedule.fromFirestore(doc))
        .toList());
  }

  // 특정 날짜의 일정 가져오기 (실시간) - 업데이트됨
  Stream<List<Schedule>> getSchedulesByDate(DateTime date) {
    return getAllSchedules().map((all) {
      // includesDate(date)가 true인 일정만 필터링
      final List<Schedule> filtered = all.where((s) => s.includesDate(date)).toList();

      // 하루종일을 맨 위, 그 다음 시간순 정렬
      filtered.sort((a, b) {
        if (a.isAllDay && !b.isAllDay) return -1;
        if (!a.isAllDay && b.isAllDay) return 1;
        return a.scheduledAt.compareTo(b.scheduledAt);
      });

      return filtered;
    });
  }

  // 진행 중인 일정 가져오기 (새로 추가)
  Stream<List<Schedule>> getCurrentSchedules() {
    final now = DateTime.now();

    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Schedule.fromFirestore(doc))
          .where((schedule) {
        final startTime = schedule.startTime;
        final endTime = schedule.actualEndTime;

        // 현재 시간이 일정 시간 범위 안에 있는지 확인
        return now.isAfter(startTime) && now.isBefore(endTime);
      })
          .toList()
        ..sort((a, b) => a.actualEndTime.compareTo(b.actualEndTime));
    });
  }

  // 다가오는 일정 가져오기 (새로 추가)
  Stream<List<Schedule>> getUpcomingSchedules({int limitHours = 24}) {
    final now = DateTime.now();
    final limitTime = now.add(Duration(hours: limitHours));

    return _firestore
        .collection(_collection)
        .where('scheduled_at', isGreaterThan: Timestamp.fromDate(now))
        .where('scheduled_at', isLessThanOrEqualTo: Timestamp.fromDate(limitTime))
        .orderBy('scheduled_at')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Schedule.fromFirestore(doc))
        .toList());
  }

  // 특정 시간 범위의 일정 가져오기 (새로 추가)
  Stream<List<Schedule>> getSchedulesByTimeRange(DateTime weekStart, DateTime weekEnd) {
    return getAllSchedules().map((all) {
      return all.where((s) {
        // 1) 주 시작 이전에 시작해 주 중간에 끝난 일정
        // 2) 주 후반에 시작해 주 종료 이후에 끝난 일정
        // 모두 걸러낼 수 있는 조건
        return s.actualEndTime.isAfter(weekStart) && s.startTime.isBefore(weekEnd);
      }).toList()
      // all-day 먼저, 그 다음 시간순 정렬
        ..sort((a, b) {
          if (a.isAllDay && !b.isAllDay) return -1;
          if (!a.isAllDay && b.isAllDay) return 1;
          return a.startTime.compareTo(b.startTime);
        });
    });
  }

  /// 🏠 홈 화면용: 오늘+내일 일정만 (최대 20개)
  Stream<List<Schedule>> getHomeFeedSchedules() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayAfterTomorrow = today.add(Duration(days: 2));

    return _firestore
        .collection(_collection)
        .where('scheduled_at', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
        .where('scheduled_at', isLessThan: Timestamp.fromDate(dayAfterTomorrow))
        .orderBy('scheduled_at')
        .limit(20) // 홈 화면은 20개 제한
        .snapshots()
        .map((snapshot) {
      final schedules = snapshot.docs.map((doc) => Schedule.fromFirestore(doc)).toList();

      // 하루종일 일정을 맨 위에 표시
      schedules.sort((a, b) {
        if (a.isAllDay && !b.isAllDay) return -1;
        if (!a.isAllDay && b.isAllDay) return 1;
        return a.scheduledAt.compareTo(b.scheduledAt);
      });

      return schedules;
    });
  }

  /// 📅 달력 화면용: 특정 월의 일정만
  Stream<List<Schedule>> getSchedulesByMonth(DateTime month) {
    final monthStart = DateTime(month.year, month.month, 1);
    final monthEnd = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

    return _firestore
        .collection(_collection)
        .where('scheduled_at', isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart))
        .where('scheduled_at', isLessThanOrEqualTo: Timestamp.fromDate(monthEnd))
        .orderBy('scheduled_at')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Schedule.fromFirestore(doc)).toList());
  }

  // 하루종일 일정만 가져오기 (새로 추가)
  Stream<List<Schedule>> getAllDaySchedules() {
    return _firestore
        .collection(_collection)
        .where('is_all_day', isEqualTo: true)
        .orderBy('scheduled_at')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Schedule.fromFirestore(doc))
        .toList());
  }

  // 일정 삭제
  Future<void> deleteSchedule(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  // 일정 수정
  Future<void> updateSchedule(String id, Schedule schedule) async {
    await _firestore.collection(_collection).doc(id).update(schedule.toFirestore());
  }

  // 일정 검색 (새로 추가)
  Stream<List<Schedule>> searchSchedules(String query) {
    return _firestore
        .collection(_collection)
        .orderBy('scheduled_at', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Schedule.fromFirestore(doc))
          .where((schedule) {
        final lowerQuery = query.toLowerCase();
        return schedule.title.toLowerCase().contains(lowerQuery) ||
            schedule.memo.toLowerCase().contains(lowerQuery);
      })
          .toList();
    });
  }

  // 일정 통계 (새로 추가)
  Future<Map<String, int>> getScheduleStats() async {
    final snapshot = await _firestore.collection(_collection).get();
    final schedules = snapshot.docs.map((doc) => Schedule.fromFirestore(doc)).toList();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(Duration(days: 1));
    final thisWeek = today.add(Duration(days: 7));

    return {
      'total': schedules.length,
      'today': schedules.where((s) =>
      s.scheduledAt.isAfter(today) && s.scheduledAt.isBefore(tomorrow)
      ).length,
      'thisWeek': schedules.where((s) =>
      s.scheduledAt.isAfter(today) && s.scheduledAt.isBefore(thisWeek)
      ).length,
      'allDay': schedules.where((s) => s.isAllDay).length,
    };
  }

  // ===== 🆕 백그라운드 동기화용 새 메서드들 =====

  /// 🔄 모든 일정 한 번만 가져오기 (Stream 아님) - 핵심!
  Future<List<Schedule>> getAllSchedulesOnce() async {
    try {
      print('📡 Firestore에서 모든 일정 가져오는 중...');

      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('scheduled_at')
          .get();

      final schedules = snapshot.docs
          .map((doc) => Schedule.fromFirestore(doc))
          .toList();

      print('✅ ${schedules.length}개 일정 가져오기 완료');
      return schedules;

    } catch (e) {
      print('❌ getAllSchedulesOnce 실패: $e');
      return [];
    }
  }

  /// 🔔 알림 설정된 미래 일정들만 가져오기 - 백그라운드 동기화용
  Future<List<Schedule>> getNotifiableSchedules() async {
    try {
      print('🔔 알림 설정된 일정들 확인 중...');

      final now = DateTime.now();

      final snapshot = await _firestore
          .collection(_collection)
          .where('has_notification', isEqualTo: true)
          .where('scheduled_at', isGreaterThan: Timestamp.fromDate(now))
          .orderBy('scheduled_at')
          .get();

      final schedules = snapshot.docs
          .map((doc) => Schedule.fromFirestore(doc))
          .toList();

      print('✅ 알림 설정된 미래 일정 ${schedules.length}개 발견');
      return schedules;

    } catch (e) {
      print('❌ getNotifiableSchedules 실패: $e');
      return [];
    }
  }

  /// 📅 특정 시간 이후 추가된 일정들만 가져오기 - 증분 동기화용
  Future<List<Schedule>> getSchedulesSince(DateTime lastSync) async {
    try {
      print('📅 ${lastSync} 이후 추가된 일정 확인 중...');

      final snapshot = await _firestore
          .collection(_collection)
          .where('created_at', isGreaterThan: Timestamp.fromDate(lastSync))
          .orderBy('created_at')
          .get();

      final schedules = snapshot.docs
          .map((doc) => Schedule.fromFirestore(doc))
          .toList();

      print('✅ 새로 추가된 일정 ${schedules.length}개 발견');
      return schedules;

    } catch (e) {
      print('❌ getSchedulesSince 실패: $e');
      return [];
    }
  }

  /// 🎯 오늘과 내일의 알림 설정된 일정만 가져오기 (효율적)
  Future<List<Schedule>> getTodayAndTomorrowNotifiableSchedules() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dayAfterTomorrow = today.add(Duration(days: 2));

      print('📱 오늘~내일 알림 일정 확인 중...');

      final snapshot = await _firestore
          .collection(_collection)
          .where('has_notification', isEqualTo: true)
          .where('scheduled_at', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('scheduled_at', isLessThan: Timestamp.fromDate(dayAfterTomorrow))
          .orderBy('scheduled_at')
          .get();

      final schedules = snapshot.docs
          .map((doc) => Schedule.fromFirestore(doc))
          .toList();

      print('✅ 오늘~내일 알림 일정 ${schedules.length}개 발견');
      return schedules;

    } catch (e) {
      print('❌ getTodayAndTomorrowNotifiableSchedules 실패: $e');
      return [];
    }
  }

  /// 🔍 특정 일정 ID로 일정 가져오기 (한 번만)
  Future<Schedule?> getScheduleById(String scheduleId) async {
    try {
      final doc = await _firestore
          .collection(_collection)
          .doc(scheduleId)
          .get();

      if (doc.exists) {
        print('✅ 일정 ID $scheduleId 찾기 성공');
        return Schedule.fromFirestore(doc);
      } else {
        print('⚠️ 일정 ID $scheduleId 찾을 수 없음');
        return null;
      }
    } catch (e) {
      print('❌ getScheduleById 실패: $e');
      return null;
    }
  }

  /// 📊 알림 통계 가져오기 (백그라운드 동기화 분석용)
  Future<Map<String, int>> getNotificationStats() async {
    try {
      print('📊 알림 통계 계산 중...');

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(Duration(days: 1));
      final nextWeek = today.add(Duration(days: 7));

      // 알림 설정된 일정들만 가져오기
      final snapshot = await _firestore
          .collection(_collection)
          .where('has_notification', isEqualTo: true)
          .get();

      final notifiableSchedules = snapshot.docs
          .map((doc) => Schedule.fromFirestore(doc))
          .toList();

      final stats = {
        'total_notifiable': notifiableSchedules.length,
        'today_notifiable': notifiableSchedules.where((s) =>
        s.scheduledAt.isAfter(today) && s.scheduledAt.isBefore(tomorrow)
        ).length,
        'tomorrow_notifiable': notifiableSchedules.where((s) =>
        s.scheduledAt.isAfter(tomorrow) && s.scheduledAt.isBefore(tomorrow.add(Duration(days: 1)))
        ).length,
        'this_week_notifiable': notifiableSchedules.where((s) =>
        s.scheduledAt.isAfter(today) && s.scheduledAt.isBefore(nextWeek)
        ).length,
        'future_notifiable': notifiableSchedules.where((s) =>
            s.scheduledAt.isAfter(now)
        ).length,
      };

      print('✅ 알림 통계: $stats');
      return stats;

    } catch (e) {
      print('❌ getNotificationStats 실패: $e');
      return {};
    }
  }

  /// 🧪 연결 테스트 (백그라운드에서 Firestore 접근 가능한지 확인)
  Future<bool> testConnection() async {
    try {
      print('🧪 Firestore 연결 테스트 중...');

      // 간단한 쿼리로 연결 테스트
      final snapshot = await _firestore
          .collection(_collection)
          .limit(1)
          .get();

      print('✅ Firestore 연결 테스트 성공 (문서 ${snapshot.docs.length}개 확인)');
      return true;
    } catch (e) {
      print('❌ Firestore 연결 테스트 실패: $e');
      return false;
    }
  }

  /// 🔄 특정 날짜 범위의 일정 가져오기 (한 번만) - 백그라운드용
  Future<List<Schedule>> getSchedulesByDateRangeOnce(DateTime startDate, DateTime endDate) async {
    try {
      print('📅 ${startDate.toString().substring(0, 10)} ~ ${endDate.toString().substring(0, 10)} 일정 확인 중...');

      final snapshot = await _firestore
          .collection(_collection)
          .where('scheduled_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('scheduled_at', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('scheduled_at')
          .get();

      final schedules = snapshot.docs
          .map((doc) => Schedule.fromFirestore(doc))
          .toList();

      print('✅ 해당 기간 일정 ${schedules.length}개 발견');
      return schedules;

    } catch (e) {
      print('❌ getSchedulesByDateRangeOnce 실패: $e');
      return [];
    }
  }

  /// 📱 일정 추가와 동시에 알림 예약 (통합 메서드)
  Future<void> addScheduleWithNotification(Schedule schedule) async {
    try {
      // 1. Firestore에 일정 추가
      await addSchedule(schedule);
      print('✅ 일정 "${schedule.title}" Firestore에 추가 완료');

      // 2. 알림이 설정되어 있으면 즉시 알림 예약도 트리거
      if (schedule.hasNotification) {
        print('🔔 알림이 설정된 일정이므로 백그라운드 동기화 트리거');
        // BackgroundSyncService에서 곧 감지할 것임
      }

    } catch (e) {
      print('❌ addScheduleWithNotification 실패: $e');
      rethrow;
    }
  }

  /// 🗑️ 일정 삭제와 동시에 알림 취소 (통합 메서드)
  Future<void> deleteScheduleWithNotification(String id) async {
    try {
      // 1. 먼저 일정 정보 가져오기 (알림 취소를 위해)
      final schedule = await getScheduleById(id);

      // 2. Firestore에서 일정 삭제
      await deleteSchedule(id);
      print('✅ 일정 ID $id Firestore에서 삭제 완료');

      // 3. 알림이 설정되어 있었으면 알림도 취소해야 함을 알림
      if (schedule?.hasNotification == true) {
        print('🗑️ 알림이 설정된 일정 삭제됨 - 알림 취소 필요');
        // NotificationService에서 처리해야 함
      }

    } catch (e) {
      print('❌ deleteScheduleWithNotification 실패: $e');
      rethrow;
    }
  }

  /// 🎯 오늘 알림 설정된 일정만 가져오기 (초경량 백그라운드용)
  Future<List<Schedule>> getTodayNotifiableSchedules() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(Duration(days: 1));

      final snapshot = await _firestore
          .collection(_collection)
          .where('has_notification', isEqualTo: true)
          .where('scheduled_at', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .where('scheduled_at', isLessThan: Timestamp.fromDate(tomorrow))
          .orderBy('scheduled_at')
          .get();

      final schedules = snapshot.docs
          .map((doc) => Schedule.fromFirestore(doc))
          .toList();

      // 과거 시간 알림은 제외 (이미 지난 알림)
      final validSchedules = schedules.where((schedule) {
        return schedule.getNotificationTime() != null;
      }).toList();

      return validSchedules;

    } catch (e) {
      // 에러 시 빈 리스트 반환 (백그라운드에서는 조용히 처리)
      return [];
    }
  }
}