import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/schedule.dart';
import '../services/firestore_service.dart';
import '../widgets/schedule_tile.dart';
import '../widgets/schedule_form_dialog.dart';
import '../utils/date_utils.dart' as utils;
import '../services/schedule_action_service.dart';

class HomeScreen extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF7F56D9).withOpacity(0.8),
                Color(0xFF9E77ED).withOpacity(0.8),
              ],
            ),
          ),
        ),
        title: Text(
          'WithU',
          style: GoogleFonts.pacifico(  // 또는 Lobster, Amatic SC 등
            fontSize: 26,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0E7FF),  // 연한 보라 (확실히 보임)
              Color(0xFFDBEAFE),  // 연한 파랑 (확실히 보임)
              Color(0xFFDDD6FE),  // 연한 라벤더 (확실히 보임)
              Color(0xFFE5E7EB),  // 연한 회색 (확실히 보임)
            ],
            stops: [0.0, 0.4, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 날짜 헤더 카드
                Container(
                  padding: EdgeInsets.all(24),
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
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.calendar_today_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '오늘',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              utils.DateUtils.formatDate(today),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32),

                // 섹션 헤더
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '오늘의 일정',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w700, // 700으로 더 진하게
                        color: Color(0xFF1F2937),
                        letterSpacing: -0.5, // 글자 간격 조정
                      ),
                    ),
                    StreamBuilder<List<Schedule>>(
                      stream: _firestoreService.getSchedulesByDate(today),
                      builder: (context, snapshot) {
                        final schedules = snapshot.data ?? [];
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Color(0xFF6366F1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${schedules.length}개',
                            style: TextStyle(
                              color: Color(0xFF6366F1),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // 간단한 통계 (선택사항)
                StreamBuilder<List<Schedule>>(
                  stream: _firestoreService.getHomeFeedSchedules(),
                  builder: (context, snapshot) {
                    final allSchedules = snapshot.data ?? [];
                    final tomorrow = today.add(Duration(days: 1));
                    final tomorrowSchedules = allSchedules.where((s) =>
                        utils.DateUtils.isSameDay(s.scheduledAt, tomorrow)
                    ).length;

                    if (tomorrowSchedules > 0) {
                      return Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFF8B5CF6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Color(0xFF8B5CF6).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.event_note_rounded,
                              color: Color(0xFF8B5CF6),
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text(
                              '내일 $tomorrowSchedules개의 일정이 있습니다',
                              style: TextStyle(
                                color: Color(0xFF8B5CF6),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),

                SizedBox(height: 20),

                // 일정 목록
                Expanded(
                  child: StreamBuilder<List<Schedule>>(
                    stream: _firestoreService.getSchedulesByDate(today),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
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
                              border: Border.all(color: Color(0xFFFECACA)),
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
                            padding: EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 15,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF6366F1).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.event_available_rounded,
                                    size: 48,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                                SizedBox(height: 20),
                                Text(
                                  '오늘은 일정이 없습니다',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  '새로운 일정을 추가해보세요!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
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
                            onEdit: () => ScheduleActionService.editSchedule(context, schedule),
                            onDelete: () => ScheduleActionService.deleteSchedule(context, schedule),
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
      ),
    );
  }
}