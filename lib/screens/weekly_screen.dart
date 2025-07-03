import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/schedule.dart';
import '../services/firestore_service.dart';
import '../utils/date_utils.dart' as utils;

class WeeklyScreen extends StatefulWidget {
  @override
  _WeeklyScreenState createState() => _WeeklyScreenState();
}

class _WeeklyScreenState extends State<WeeklyScreen> {
  final FirestoreService _firestoreService = FirestoreService();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('주간 일정'),
        backgroundColor: Colors.transparent,
        actions: [
          // 이번 주로 돌아가기 버튼
          IconButton(
            onPressed: () {
              setState(() {
                _currentWeek = DateTime.now();
              });
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
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
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

  // 시간대별 슬롯
  Widget _buildTimeSlot(int hour, List<Schedule> allSchedules) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // 시간 표시
          Container(
            width: 50,
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ),

          SizedBox(width: 10),

          // 요일별 일정 표시
          ...List.generate(7, (dayIndex) {
            final date = _weekStart.add(Duration(days: dayIndex));
            final daySchedules = _getSchedulesForHour(allSchedules, date, hour);

            return Expanded(
              child: Container(
                height: 40,
                margin: EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: daySchedules.isNotEmpty
                      ? Color(0xFF6366F1).withOpacity(0.8)
                      : Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                  border: utils.DateUtils.isToday(date)
                      ? Border.all(color: Color(0xFF10B981), width: 2)
                      : null,
                ),
                child: daySchedules.isNotEmpty
                    ? Container(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    daySchedules.first.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                )
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }

  // 특정 시간대의 일정 찾기
  List<Schedule> _getSchedulesForHour(List<Schedule> schedules, DateTime date, int hour) {
    return schedules.where((schedule) {
      // 같은 날짜인지 확인
      if (!utils.DateUtils.isSameDay(schedule.scheduledAt, date)) {
        return false;
      }

      // 하루종일 일정이면 모든 시간에 표시
      if (schedule.isAllDay) {
        return true;
      }

      // 해당 시간대에 겹치는지 확인
      final startHour = schedule.scheduledAt.hour;
      final endHour = schedule.actualEndTime.hour;

      return hour >= startHour && hour < endHour;
    }).toList();
  }
}