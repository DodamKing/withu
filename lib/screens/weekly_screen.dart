import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/schedule.dart';
import '../services/firestore_service.dart';
import '../utils/date_utils.dart' as utils;
import '../widgets/schedule_detail_sheet.dart';

class WeeklyScreen extends StatefulWidget {
  @override
  _WeeklyScreenState createState() => _WeeklyScreenState();
}

class _WeeklyScreenState extends State<WeeklyScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ScrollController _scrollController = ScrollController();
  DateTime _currentWeek = DateTime.now();

  // 현재 주의 시작일 (월요일) 계산
  DateTime get _weekStart {
    final now = _currentWeek;
    final daysFromMonday = now.weekday - 1;
    return DateTime(now.year, now.month, now.day - daysFromMonday);
  }

  // 현재 주의 마지막일 (일요일) 계산
  DateTime get _weekEnd {
    return _weekStart.add(Duration(days: 6));
  }

  static const double _hourHeight = 60; // 🆕 40 → 60으로 증가
  final int _startHour = 9;
  final int _endHour   = 22;

  @override
  void initState() {
    super.initState();
    // 🆕 현재 시간대로 자동 스크롤
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 🆕 현재 시간대로 스크롤
  void _scrollToCurrentTime() {
    final now = DateTime.now();
    if (now.hour >= _startHour && now.hour <= _endHour) {
      final targetOffset = (now.hour - _startHour) * (_hourHeight + 8) + 200; // 헤더 높이 고려
      _scrollController.animateTo(
        targetOffset,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('주간 일정'),
        backgroundColor: Colors.transparent,
        actions: [
          // 🆕 현재 시간으로 스크롤 버튼
          IconButton(
            onPressed: _scrollToCurrentTime,
            icon: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.schedule_rounded,
                color: Color(0xFF10B981),
                size: 20,
              ),
            ),
          ),
          // 이번 주로 돌아가기 버튼
          IconButton(
            onPressed: () {
              setState(() {
                _currentWeek = DateTime.now();
              });
              _scrollToCurrentTime();
            },
            icon: Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.today_rounded,
                color: Color(0xFF6366F1),
                size: 20,
              ),
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8B5CF6).withOpacity(0.1),
              Color(0xFF06B6D4).withOpacity(0.05),
              Colors.white,
            ],
            stops: [0.0, 0.3, 0.7],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 주간 헤더 (날짜 네비게이션)
              _buildWeekHeader(),

              // 주간 타임라인
              Expanded(
                child: _buildWeeklyTimeline(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 주간 헤더 (날짜 네비게이션)
  Widget _buildWeekHeader() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // 주간 타이틀 + 네비게이션
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _currentWeek = _currentWeek.subtract(Duration(days: 7));
                  });
                },
                icon: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: Colors.white,
                  ),
                ),
              ),

              Column(
                children: [
                  Text(
                    '${DateFormat('M월').format(_weekStart)} ${DateFormat('d일').format(_weekStart)} - ${DateFormat('M월 d일').format(_weekEnd)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    DateFormat('yyyy년').format(_weekStart),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              IconButton(
                onPressed: () {
                  setState(() {
                    _currentWeek = _currentWeek.add(Duration(days: 7));
                  });
                },
                icon: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // 요일 헤더
          Row(
            children: [
              SizedBox(width: 60), // 시간 컬럼 공간
              ...List.generate(7, (index) {
                final date = _weekStart.add(Duration(days: index));
                final isToday = utils.DateUtils.isToday(date);
                final dayNames = ['월', '화', '수', '목', '금', '토', '일'];

                return Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isToday
                          ? Colors.white.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          dayNames[index],
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          date.day.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  // 주간 타임라인
  Widget _buildWeeklyTimeline() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: StreamBuilder<List<Schedule>>(
        stream: _firestoreService.getSchedulesByTimeRange(_weekStart, _weekEnd.add(Duration(days: 1))),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Container(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: Color(0xFF6366F1)),
              ),
            );
          }

          final schedules = snapshot.data ?? [];

          return SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // 여러 날 하루종일 일정 상단 표시
                _buildMultiDayAllDaySection(schedules),

                SizedBox(height: 16),

                // 시간대별 타임라인 (9시 ~ 22시)
                ...List.generate(14, (hourIndex) {
                  final hour = 9 + hourIndex;
                  return _buildTimeSlot(hour, schedules);
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  // 여러 날 하루종일 일정 섹션
  Widget _buildMultiDayAllDaySection(List<Schedule> allSchedules) {
    final multiDayAllDaySchedules = allSchedules.where((schedule) =>
    schedule.isAllDay &&
        schedule.isMultiDay &&
        _scheduleOverlapsWeek(schedule)
    ).toList();

    if (multiDayAllDaySchedules.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_note, size: 16, color: Color(0xFF64748B)),
              SizedBox(width: 8),
              Text(
                '기간 일정',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...multiDayAllDaySchedules.map((schedule) => GestureDetector(
            onTap: () => _showScheduleDetail(schedule),
            child: Container(
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                // 🆕 사용자별 색상 적용
                color: _getScheduleColor(schedule),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: _getScheduleColor(schedule).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          schedule.dateRangeText,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${schedule.durationInDays}일간',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  // 시간대별 슬롯
  Widget _buildTimeSlot(int hour, List<Schedule> allSchedules) {
    final isCurrentHour = DateTime.now().hour == hour &&
        utils.DateUtils.isToday(_currentWeek);

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        // 🆕 현재 시간대 강조
        color: isCurrentHour
            ? Color(0xFF10B981).withOpacity(0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isCurrentHour
            ? Border.all(color: Color(0xFF10B981).withOpacity(0.3), width: 1)
            : null,
      ),
      child: Row(
        children: [
          // 시간 표시
          Container(
            width: 50,
            padding: EdgeInsets.symmetric(vertical: 16), // 🆕 높이 증가
            child: Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isCurrentHour ? FontWeight.bold : FontWeight.w500,
                color: isCurrentHour ? Color(0xFF10B981) : Color(0xFF6B7280),
              ),
            ),
          ),

          SizedBox(width: 10),

          // 요일별 일정 표시
          ...List.generate(7, (dayIndex) {
            final date = _weekStart.add(Duration(days: dayIndex));
            final daySchedules = _getSchedulesForHour(allSchedules, date, hour);

            return Expanded(
              child: GestureDetector(
                onTap: daySchedules.isNotEmpty
                    ? () => _showScheduleDetail(daySchedules.first)
                    : null,
                child: Container(
                  height: _hourHeight, // 🆕 60px로 증가
                  margin: EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: _getSlotColor(daySchedules, date),
                    borderRadius: BorderRadius.circular(8),
                    border: utils.DateUtils.isToday(date)
                        ? Border.all(color: Color(0xFF10B981), width: 2)
                        : null,
                  ),
                  child: daySchedules.isNotEmpty
                      ? Container(
                    padding: EdgeInsets.all(6), // 🆕 패딩 증가
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min, // 🔧 오버플로우 해결
                      children: [
                        Flexible( // 🔧 Flexible로 감싸서 공간 제한
                          child: Text(
                            _getSlotText(daySchedules),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10, // 🔧 11 → 10으로 줄임
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1, // 🔧 2 → 1로 줄임
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // 🔧 시간 정보는 공간이 충분할 때만 표시
                        if (daySchedules.length == 1 && !daySchedules.first.isAllDay && _hourHeight >= 50) ...[
                          SizedBox(height: 1),
                          Flexible(
                            child: Text(
                              _getTimeInfo(daySchedules.first, date),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 8, // 🔧 9 → 8로 줄임
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                      : null,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // 🆕 일정 상세 보기
  void _showScheduleDetail(Schedule schedule) {
    showScheduleDetailSheet(
      context: context,
      schedule: schedule,
      onEdit: () {
        // 편집 콜백 (필요시 구현)
      },
      onDelete: () {
        // 삭제 콜백 (필요시 구현)
      },
    );
  }

  // 🆕 사용자별 색상 가져오기
  Color _getScheduleColor(Schedule schedule) {
    if (schedule.ownerColorValue != null) {
      return Color(schedule.ownerColorValue!);
    }

    // 기본 색상들
    return Color(0xFF6366F1);
  }

  // 특정 시간대의 일정 찾기 (여러 날 일정 지원)
  List<Schedule> _getSchedulesForHour(List<Schedule> schedules, DateTime date, int hour) {
    return schedules.where((schedule) {
      // 해당 날짜에 일정이 포함되는지 확인 (여러 날 일정 지원)
      if (!schedule.includesDate(date)) {
        return false;
      }

      // 하루종일 일정이면 모든 시간에 표시 (단, 여러 날 하루종일은 위쪽 섹션에서 처리)
      if (schedule.isAllDay) {
        return !schedule.isMultiDay; // 여러 날 하루종일은 위쪽에서 처리하므로 제외
      }

      // 시간 일정의 경우 더 정교하게 처리
      DateTime scheduleStart, scheduleEnd;

      if (schedule.isMultiDay) {
        // 여러 날 시간 일정
        if (utils.DateUtils.isSameDay(schedule.scheduledAt, date)) {
          // 시작일: 실제 시작 시간부터
          scheduleStart = schedule.scheduledAt;
          scheduleEnd = DateTime(date.year, date.month, date.day, 23, 59);
        } else if (schedule.endTime != null && utils.DateUtils.isSameDay(schedule.endTime!, date)) {
          // 종료일: 00:00부터 실제 종료 시간까지
          scheduleStart = DateTime(date.year, date.month, date.day, 0, 0);
          scheduleEnd = schedule.endTime!;
        } else {
          // 중간일: 하루 종일
          scheduleStart = DateTime(date.year, date.month, date.day, 0, 0);
          scheduleEnd = DateTime(date.year, date.month, date.day, 23, 59);
        }
      } else {
        // 단일 날 시간 일정
        scheduleStart = schedule.scheduledAt;
        scheduleEnd = schedule.actualEndTime;
      }

      // 해당 시간대에 겹치는지 확인
      final slotStart = DateTime(date.year, date.month, date.day, hour, 0);
      final slotEnd = DateTime(date.year, date.month, date.day, hour + 1, 0);

      return scheduleStart.isBefore(slotEnd) && scheduleEnd.isAfter(slotStart);
    }).toList();
  }

  // 🆕 슬롯 색상 결정 (사용자별 색상 적용)
  Color _getSlotColor(List<Schedule> schedules, DateTime date) {
    if (schedules.isEmpty) {
      return Color(0xFFF3F4F6);
    }

    final schedule = schedules.first;
    Color baseColor = _getScheduleColor(schedule);

    // 진행 중인 일정은 더 진하게
    if (schedule.isCurrentlyActive) {
      return baseColor.withOpacity(1.0);
    }

    // 여러 날 일정은 약간 투명하게
    if (schedule.isMultiDay) {
      return baseColor.withOpacity(0.8);
    }

    // 일반 일정
    return baseColor.withOpacity(0.9);
  }

  // 슬롯 텍스트 결정
  String _getSlotText(List<Schedule> schedules) {
    if (schedules.isEmpty) return '';

    final schedule = schedules.first;

    if (schedules.length > 1) {
      return '${schedule.title} +${schedules.length - 1}';
    }

    return schedule.title;
  }

  // 🆕 시간 정보 텍스트
  String _getTimeInfo(Schedule schedule, DateTime date) {
    if (schedule.isAllDay) return '';

    if (schedule.isMultiDay) {
      if (utils.DateUtils.isSameDay(schedule.scheduledAt, date)) {
        return '${schedule.scheduledAt.hour}:${schedule.scheduledAt.minute.toString().padLeft(2, '0')}~';
      } else if (schedule.endTime != null && utils.DateUtils.isSameDay(schedule.endTime!, date)) {
        return '~${schedule.endTime!.hour}:${schedule.endTime!.minute.toString().padLeft(2, '0')}';
      }
      return '종일';
    }

    return '${schedule.scheduledAt.hour}:${schedule.scheduledAt.minute.toString().padLeft(2, '0')}';
  }

  // 일정이 현재 주와 겹치는지 확인
  bool _scheduleOverlapsWeek(Schedule schedule) {
    return schedule.startDate.isBefore(_weekEnd.add(Duration(days: 1))) &&
        schedule.endDate.isAfter(_weekStart.subtract(Duration(days: 1)));
  }
}