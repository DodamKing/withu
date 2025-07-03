import 'package:cloud_firestore/cloud_firestore.dart';

class Schedule {
  final String id;
  final String title;
  final String memo;
  final DateTime scheduledAt;  // 시작 시간 (또는 하루종일 일정의 날짜)
  final DateTime? endTime;     // 종료 시간 (하루종일이면 null)
  final bool isAllDay;         // 하루종일 여부
  final DateTime createdAt;

  Schedule({
    required this.id,
    required this.title,
    required this.memo,
    required this.scheduledAt,
    this.endTime,
    this.isAllDay = false,
    required this.createdAt,
  });

  // Firestore에서 데이터 가져올 때
  factory Schedule.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

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
    );
  }

  // Firestore에 데이터 저장할 때
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'memo': memo,
      'scheduled_at': Timestamp.fromDate(scheduledAt),
      'end_time': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'is_all_day': isAllDay,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  // 편의 메서드들

  // 시작 시간 (하루종일이면 00:00)
  DateTime get startTime {
    if (isAllDay) {
      return DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
    }
    return scheduledAt;
  }

  // 실제 종료 시간 (하루종일이면 23:59:59)
  DateTime get actualEndTime {
    if (isAllDay) {
      return DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day, 23, 59, 59);
    }
    return endTime ?? scheduledAt.add(Duration(hours: 1)); // 기본 1시간
  }

  // 일정 시간 텍스트 (UI 표시용)
  String get timeText {
    if (isAllDay) {
      return '하루종일';
    }

    final start = '${scheduledAt.hour.toString().padLeft(2, '0')}:${scheduledAt.minute.toString().padLeft(2, '0')}';

    if (endTime != null) {
      final end = '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}';
      return '$start - $end';
    }

    return start;
  }
}