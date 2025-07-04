import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'withu_schedules';

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
}