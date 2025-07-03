import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../utils/date_utils.dart' as utils;
import '../widgets/schedule_detail_sheet.dart';

class ScheduleTile extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool showDate;

  const ScheduleTile({
    Key? key,
    required this.schedule,
    this.onTap,
    this.onDelete,
    this.onEdit,
    this.showDate = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isToday = utils.DateUtils.isToday(schedule.scheduledAt);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isToday
              ? [Color(0xFF6366F1).withOpacity(0.05), Color(0xFF8B5CF6).withOpacity(0.05)]
              : [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isToday
                ? Color(0xFF6366F1).withOpacity(0.1)
                : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        border: isToday
            ? Border.all(color: Color(0xFF6366F1).withOpacity(0.2), width: 1.5)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => _showDetailSheet(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                // 아이콘 영역
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isToday
                          ? [Color(0xFF6366F1), Color(0xFF8B5CF6)]
                          : [Color(0xFF64748B), Color(0xFF475569)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: isToday
                            ? Color(0xFF6366F1).withOpacity(0.3)
                            : Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getScheduleIcon(schedule.title),
                    color: Colors.white,
                    size: 24,
                  ),
                ),

                SizedBox(width: 16),

                // 내용 영역
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 제목
                      Text(
                        schedule.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      if (schedule.memo.isNotEmpty) ...[
                        SizedBox(height: 6),
                        Text(
                          schedule.memo,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      SizedBox(height: 12),

                      // 시간 및 배지
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isToday
                                  ? Color(0xFF6366F1).withOpacity(0.1)
                                  : Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  schedule.isAllDay
                                      ? Icons.event_rounded
                                      : Icons.access_time_rounded,
                                  size: 16,
                                  color: isToday
                                      ? Color(0xFF6366F1)
                                      : Color(0xFF6B7280),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  _getTimeDisplayText(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isToday
                                        ? Color(0xFF6366F1)
                                        : Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 하루종일 배지
                          if (schedule.isAllDay) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF8B5CF6), Color(0xFFA855F7)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF8B5CF6).withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '하루종일',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],

                          // 오늘 배지
                          if (showDate && isToday && !schedule.isAllDay) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF10B981).withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '오늘',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],

                          // 진행 중 배지
                          if (_isCurrentlyActive()) ...[
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFFEF4444).withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '진행중',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 상세 바텀시트 표시
  void _showDetailSheet(BuildContext context) {
    showScheduleDetailSheet(
      context: context,
      schedule: schedule,
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }

  // 시간 표시 텍스트 생성
  String _getTimeDisplayText() {
    if (schedule.isAllDay) {
      return showDate
          ? utils.DateUtils.formatDate(schedule.scheduledAt)
          : '하루종일';
    }

    if (showDate) {
      // 날짜 + 시간 표시
      return utils.DateUtils.formatDateTime(schedule.scheduledAt);
    } else {
      // 시간만 표시 (시작시간 - 종료시간)
      return schedule.timeText;
    }
  }

  // 현재 진행 중인 일정인지 확인
  bool _isCurrentlyActive() {
    if (schedule.isAllDay) {
      return utils.DateUtils.isToday(schedule.scheduledAt);
    }

    final now = DateTime.now();
    final startTime = schedule.startTime;
    final endTime = schedule.actualEndTime;

    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  // 일정 제목에 따른 아이콘 선택
  IconData _getScheduleIcon(String title) {
    final lowerTitle = title.toLowerCase();

    if (lowerTitle.contains('회의') || lowerTitle.contains('미팅')) {
      return Icons.groups_rounded;
    } else if (lowerTitle.contains('식사') || lowerTitle.contains('점심') || lowerTitle.contains('저녁')) {
      return Icons.restaurant_rounded;
    } else if (lowerTitle.contains('운동') || lowerTitle.contains('헬스')) {
      return Icons.fitness_center_rounded;
    } else if (lowerTitle.contains('공부') || lowerTitle.contains('학습')) {
      return Icons.school_rounded;
    } else if (lowerTitle.contains('쇼핑')) {
      return Icons.shopping_bag_rounded;
    } else if (lowerTitle.contains('여행') || lowerTitle.contains('여행')) {
      return Icons.flight_rounded;
    } else if (lowerTitle.contains('영화') || lowerTitle.contains('영화')) {
      return Icons.movie_rounded;
    } else {
      return Icons.event_rounded;
    }
  }
}