import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/schedule.dart';
import '../services/firestore_service.dart';
import '../widgets/schedule_tile.dart';
import '../widgets/schedule_form_dialog.dart';
import '../utils/date_utils.dart' as utils;

class CalendarScreen extends StatefulWidget {
  // Key 추가 - main.dart에서 접근할 수 있도록
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  CalendarScreenState createState() => CalendarScreenState(); // public으로 변경
}

class CalendarScreenState extends State<CalendarScreen> { // public으로 변경
  final FirestoreService _firestoreService = FirestoreService();

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // main.dart에서 접근할 수 있도록 getter 추가
  DateTime? get selectedDay => _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('캘린더'),
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        actions: [
          // 오늘로 이동 버튼만 남기기
          IconButton(
            onPressed: () {
              setState(() {
                _selectedDay = DateTime.now();
                _focusedDay = DateTime.now();
              });
            },
            icon: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.today_rounded,
                color: Color(0xFF6366F1),
                size: 18,
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
              // 달력 위젯
              Container(
                margin: EdgeInsets.all(16),
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
                  stream: _firestoreService.getAllSchedules(),
                  builder: (context, snapshot) {
                    final allSchedules = snapshot.data ?? [];

                    return TableCalendar<Schedule>(
                      firstDay: DateTime.utc(2020, 1, 1),
                      lastDay: DateTime.utc(2030, 12, 31),
                      focusedDay: _focusedDay,
                      calendarFormat: _calendarFormat,
                      locale: 'ko_KR', // 한국어 설정
                      selectedDayPredicate: (day) {
                        return isSameDay(_selectedDay, day);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onFormatChanged: (format) {
                        setState(() {
                          _calendarFormat = format;
                        });
                      },
                      eventLoader: (day) {
                        return allSchedules.where((schedule) {
                          return schedule.includesDate(day);
                        }).toList();
                      },
                      calendarBuilders: CalendarBuilders<Schedule>(
                        markerBuilder: (context, date, events) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: events.map((s) {
                              // ownerColorValue가 null일 수 있으니 기본색 방어
                              final color = s.ownerColorValue != null
                                  ? Color(s.ownerColorValue!)
                                  : Colors.grey;

                              return Container(
                                width: 6,
                                height: 6,
                                margin: EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        markersMaxCount: 4,
                        markerDecoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF6366F1).withOpacity(0.4),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        todayDecoration: BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF10B981).withOpacity(0.3),
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        weekendTextStyle: TextStyle(
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                        ),
                        selectedTextStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        todayTextStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: true,
                        titleCentered: true,
                        formatButtonShowsNext: false,
                        formatButtonDecoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        formatButtonTextStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        leftChevronIcon: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFF6366F1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.chevron_left_rounded,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                        rightChevronIcon: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFF6366F1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                        titleTextStyle: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.055, // 화면 너비의 5.5%
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 선택된 날짜의 일정 목록
              Expanded(
                child: Container(
                  margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  padding: EdgeInsets.all(20),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 날짜 헤더
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.event_note_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedDay != null
                                      ? utils.DateUtils.formatDate(_selectedDay!)
                                      : '날짜를 선택해주세요',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                if (_selectedDay != null) ...[
                                  SizedBox(height: 2),
                                  Text(
                                    utils.DateUtils.getRelativeDate(_selectedDay!),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // 날짜 헤더에서 + 버튼 제거 (FAB만 사용)
                        ],
                      ),

                      SizedBox(height: 20),

                      // 일정 목록
                      Expanded(
                        child: _selectedDay == null
                            ? Center(
                          child: Container(
                            padding: EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.touch_app_rounded,
                                  size: 48,
                                  color: Color(0xFF6B7280),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  '날짜를 선택해주세요',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                            : StreamBuilder<List<Schedule>>(
                          stream: _firestoreService.getSchedulesByDate(_selectedDay!),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(
                                child: Container(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Container(
                                  padding: EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.error_outline_rounded,
                                        color: Color(0xFFDC2626),
                                        size: 48,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        '오류가 발생했습니다',
                                        style: TextStyle(
                                          color: Color(0xFFDC2626),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final schedules = snapshot.data ?? [];

                            if (schedules.isEmpty) {
                              return Center(
                                child: Container(
                                  padding: EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.event_available_rounded,
                                        size: 48,
                                        color: Color(0xFF6B7280),
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        '이 날은 일정이 없습니다',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '하단 + 버튼으로 일정을 추가해보세요!',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ),
                                      // 빈 일정 화면에서 일정 추가 버튼 제거
                                    ],
                                  ),
                                ),
                              );
                            }

                            return ListView.builder(
                              itemCount: schedules.length,
                              itemBuilder: (context, index) {
                                final schedule = schedules[index];
                                return ScheduleTile(
                                  schedule: schedule,
                                  showDate: false,
                                  onEdit: () => _editSchedule(schedule),
                                  onDelete: () => _deleteSchedule(schedule),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 일정 수정
  void _editSchedule(Schedule schedule) async {
    final editedSchedule = await showScheduleFormDialog(
      context: context,
      existingSchedule: schedule,
    );

    if (editedSchedule != null) {
      try {
        await _firestoreService.updateSchedule(schedule.id, editedSchedule);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('일정이 수정되었습니다!'),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('일정 수정에 실패했습니다: $e'),
              ],
            ),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // 일정 삭제 - 간단한 확인만
  void _deleteSchedule(Schedule schedule) async {
    // 간단한 삭제 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('일정 삭제'),
        content: Text('"${schedule.title}" 일정을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deleteSchedule(schedule.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('일정이 삭제되었습니다'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('삭제 실패: $e'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

// ❌ 일정 추가 다이얼로그 제거 - main.dart에서만 처리
// void _showAddScheduleDialog() async {
//   // 이 메서드는 더 이상 사용하지 않음
// }
}