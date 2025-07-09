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
  final int? ownerColorValue;  // Color.value로 저장할 수 있도록

  // 🔔 알림 관련 최소한의 추가 필드들
  final bool hasNotification;     // 알림 설정 여부 (단순 true/false)
  final int notificationMinutes;  // 몇 분 전 알림인지 (단일 값)

  Schedule({
    required this.id,
    required this.title,
    required this.memo,
    required this.scheduledAt,
    this.endTime,
    this.isAllDay = false,
    required this.createdAt,
    this.ownerColorValue,
    this.hasNotification = false,     // 기본값: 알림 없음
    this.notificationMinutes = 10,    // 기본값: 10분전
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

      // 새 필드들 (기존 데이터에 없으면 기본값)
      hasNotification: data['has_notification'] ?? false,
      notificationMinutes: data['notification_minutes'] ?? 10,
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

      // 새 필드들
      'has_notification': hasNotification,
      'notification_minutes': notificationMinutes,
    };
  }

  // 기존 편의 메서드들은 그대로 유지
  DateTime get startDate {
    return DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
  }

  DateTime get endDate {
    if (endTime != null) {
      return DateTime(endTime!.year, endTime!.month, endTime!.day);
    }
    return startDate;
  }

  DateTime get startTime {
    if (isAllDay) {
      return DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
    }
    return scheduledAt;
  }

  DateTime get actualEndTime {
    if (isAllDay) {
      if (endTime != null) {
        return DateTime(endTime!.year, endTime!.month, endTime!.day, 23, 59, 59);
      }
      return DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day, 23, 59, 59);
    }
    return endTime ?? scheduledAt.add(Duration(hours: 1));
  }

  bool get isMultiDay {
    if (endTime == null) return false;
    return !_isSameDay(scheduledAt, endTime!);
  }

  int get durationInDays {
    if (endTime == null) return 1;
    return endDate.difference(startDate).inDays + 1;
  }

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

  String get dateRangeText {
    if (isMultiDay) {
      return '${_formatDate(startDate)} - ${_formatDate(endDate)}';
    }
    return _formatDate(startDate);
  }

  bool includesDate(DateTime date) {
    final targetDate = DateTime(date.year, date.month, date.day);
    return (targetDate.isAfter(startDate) || targetDate.isAtSameMomentAs(startDate)) &&
        (targetDate.isBefore(endDate) || targetDate.isAtSameMomentAs(endDate));
  }

  bool get isCurrentlyActive {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(actualEndTime);
  }

  // 🔔 알림 관련 간단한 메서드들

  // 알림 시간 계산
  DateTime? getNotificationTime() {
    if (!hasNotification) return null;

    DateTime notificationTime;
    if (isAllDay) {
      // 하루종일: 당일 오전 9시에서 분만큼 빼기
      final targetTime = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day, 9, 0);
      notificationTime = targetTime.subtract(Duration(minutes: notificationMinutes));
    } else {
      // 시간 일정: 시작 시간에서 분만큼 빼기
      notificationTime = scheduledAt.subtract(Duration(minutes: notificationMinutes));
    }

    // 과거 시간이면 null 반환
    return notificationTime.isAfter(DateTime.now()) ? notificationTime : null;
  }

  // 알림 ID 생성 (일정별 고유)
  int get notificationId {
    return id.hashCode.abs();
  }

  // 알림 제목
  String get notificationTitle {
    if (notificationMinutes == 0) {
      return '📅 $title';
    } else {
      return '⏰ $notificationMinutes분 후: $title';
    }
  }

  // 알림 내용
  String get notificationBody {
    if (isAllDay) {
      return notificationMinutes == 0
          ? '하루종일 일정이 시작되었습니다.'
          : '$notificationMinutes분 후 하루종일 일정이 있습니다.';
    } else {
      return notificationMinutes == 0
          ? '$timeText 일정이 시작되었습니다.'
          : '$notificationMinutes분 후 $timeText 일정이 있습니다.';
    }
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
    bool? hasNotification,
    int? notificationMinutes,
  }) {
    return Schedule(
      id: id ?? this.id,
      title: title ?? this.title,
      memo: memo ?? this.memo,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      createdAt: createdAt ?? this.createdAt,
      ownerColorValue: ownerColorValue ?? this.ownerColorValue,
      hasNotification: hasNotification ?? this.hasNotification,
      notificationMinutes: notificationMinutes ?? this.notificationMinutes,
    );
  }
}