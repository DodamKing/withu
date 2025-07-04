import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Schedule {
  final String id;
  final String title;
  final String memo;
  final DateTime scheduledAt;  // 시작 날짜/시간 (기존 필드명 유지)
  final DateTime? endTime;     // 종료 날짜/시간 (기존 필드명 유지)
  final bool isAllDay;         // 하루종일 여부
  final DateTime createdAt;
  final int?   ownerColorValue; // Color.value 로 저장할 수 있도록

  Schedule({
    required this.id,
    required this.title,
    required this.memo,
    required this.scheduledAt,
    this.endTime,
    this.isAllDay = false,
    required this.createdAt,
    this.ownerColorValue,
  });

  // Firestore에서 데이터 가져올 때 (기존 코드와 호환)
  factory Schedule.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Schedule(
      id: doc.id,
      title: data['title'] ?? '',
      memo: data['memo'] ?? '',
      scheduledAt: (data['scheduled_at'] as Timestamp).toDate(),
      endTime: data['end_time'] != null
          ? (data['end_time'] as Timestamp).toDate()
          : null,
      isAllDay: data['is_all_day'] ?? false,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      ownerColorValue: data['owner_color'] as int? ?? Colors.grey.value,
    );
  }

  // Firestore에 데이터 저장할 때 (기존 코드와 호환)
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'memo': memo,
      'scheduled_at': Timestamp.fromDate(scheduledAt),
      'end_time': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'is_all_day': isAllDay,
      'created_at': Timestamp.fromDate(createdAt),
      'owner_color': ownerColorValue,
    };
  }

  // 🆕 새로운 편의 메서드들 (기존 코드는 그대로 동작)

  // 시작 날짜 (날짜만)
  DateTime get startDate {
    return DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
  }

  // 종료 날짜 (날짜만)
  DateTime get endDate {
    if (endTime != null) {
      return DateTime(endTime!.year, endTime!.month, endTime!.day);
    }
    return startDate; // 종료일이 없으면 시작일과 동일
  }

  // 시작 시간 (하루종일이면 00:00)
  DateTime get startTime {
    if (isAllDay) {
      return DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
    }
    return scheduledAt;
  }

  // 실제 종료 시간
  DateTime get actualEndTime {
    if (isAllDay) {
      if (endTime != null) {
        // 하루종일 + 종료날짜가 있으면 종료날짜 23:59:59
        return DateTime(endTime!.year, endTime!.month, endTime!.day, 23, 59, 59);
      }
      // 하루종일 + 종료날짜 없으면 당일 23:59:59
      return DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day, 23, 59, 59);
    }
    return endTime ?? scheduledAt.add(Duration(hours: 1)); // 기본 1시간
  }

  // 🆕 여러 날에 걸친 일정인지 확인
  bool get isMultiDay {
    if (endTime == null) return false;
    return !_isSameDay(scheduledAt, endTime!);
  }

  // 🆕 일정 기간 (일 단위)
  int get durationInDays {
    if (endTime == null) return 1;
    return endDate.difference(startDate).inDays + 1;
  }

  // 🆕 일정 시간 텍스트 (UI 표시용) - 개선
  String get timeText {
    if (isAllDay) {
      if (isMultiDay) {
        return '하루종일 (${durationInDays}일간)';
      }
      return '하루종일';
    }

    final start = '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';

    if (endTime != null) {
      final end = '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}';

      if (isMultiDay) {
        return '$start - $end (+${durationInDays - 1}일)';
      }
      return '$start - $end';
    }

    return start;
  }

  // 🆕 날짜 범위 텍스트
  String get dateRangeText {
    if (isMultiDay) {
      return '${_formatDate(startDate)} - ${_formatDate(endDate)}';
    }
    return _formatDate(startDate);
  }

  // 🆕 특정 날짜에 이 일정이 포함되는지 확인
  bool includesDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    return (targetDate.isAfter(startDate) || targetDate.isAtSameMomentAs(startDate)) &&
        (targetDate.isBefore(endDate) || targetDate.isAtSameMomentAs(endDate));
  }

  // 🆕 일정이 진행 중인지 확인
  bool get isCurrentlyActive {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(actualEndTime);
  }

  // 🆕 편의 생성자들 (기존 생성자는 그대로 유지)

  // 하루종일 일정 생성 (여러 날 지원)
  factory Schedule.createAllDay({
    required String id,
    required String title,
    required String memo,
    required DateTime startDate,
    DateTime? endDate, // null이면 하루만
    required DateTime createdAt,
    int? ownerColorValue,
  }) {
    final scheduledAt = DateTime(startDate.year, startDate.month, startDate.day);
    final endTime = endDate != null
        ? DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59)
        : null;

    return Schedule(
      id: id,
      title: title,
      memo: memo,
      scheduledAt: scheduledAt,
      endTime: endTime,
      isAllDay: true,
      createdAt: createdAt,
      ownerColorValue: ownerColorValue,
    );
  }

  // 시간 일정 생성 (여러 날 지원)
  factory Schedule.createTimed({
    required String id,
    required String title,
    required String memo,
    required DateTime startDateTime,
    required DateTime endDateTime,
    required DateTime createdAt,
  }) {
    return Schedule(
      id: id,
      title: title,
      memo: memo,
      scheduledAt: startDateTime,
      endTime: endDateTime,
      isAllDay: false,
      createdAt: createdAt,
    );
  }

  // 도우미 메서드들
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }

  // 복사 생성자
  Schedule copyWith({
    String? id,
    String? title,
    String? memo,
    DateTime? scheduledAt,
    DateTime? endTime,
    bool? isAllDay,
    DateTime? createdAt,
    int? ownerColorValue,
  }) {
    return Schedule(
      id: id ?? this.id,
      title: title ?? this.title,
      memo: memo ?? this.memo,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      createdAt: createdAt ?? this.createdAt,
      ownerColorValue: ownerColorValue ?? this.ownerColorValue
    );
  }
}