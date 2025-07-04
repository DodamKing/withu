import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../utils/date_utils.dart' as utils;

class ScheduleDetailSheet extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ScheduleDetailSheet({
    Key? key,
    required this.schedule,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 🆕 사용자별 색상 가져오기
    final Color primaryColor = _getScheduleColor();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들바
          Container(
            margin: EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          SizedBox(height: 24),

          // 일정 정보 헤더
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // 🆕 사용자 색상 적용된 아이콘
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
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

                // 제목과 상태
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          // 🆕 여러 날 일정 배지
                          if (schedule.isMultiDay)
                            _buildBadge('${schedule.durationInDays}일간', Color(0xFF3B82F6)),

                          // 하루종일 배지
                          if (schedule.isAllDay && !schedule.isMultiDay)
                            _buildBadge('하루종일', Color(0xFF8B5CF6)),

                          // 오늘 배지
                          if (utils.DateUtils.isToday(schedule.scheduledAt) && !schedule.isAllDay)
                            _buildBadge('오늘', Color(0xFF10B981)),

                          // 진행 중 배지
                          if (schedule.isCurrentlyActive)
                            _buildBadge('진행중', Color(0xFFEF4444)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24),

          // 일정 상세 정보
          Container(
            margin: EdgeInsets.symmetric(horizontal: 24),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                // 🆕 날짜 정보 (여러 날 일정 지원)
                _buildDetailRow(
                  Icons.calendar_today_rounded,
                  schedule.isMultiDay ? '기간' : '날짜',
                  schedule.isMultiDay ? schedule.dateRangeText : utils.DateUtils.formatDate(schedule.scheduledAt),
                  Color(0xFFEC4899),
                ),

                SizedBox(height: 16),

                // 🆕 시간 정보 (개선됨)
                _buildDetailRow(
                  schedule.isAllDay ? Icons.event_rounded : Icons.access_time_rounded,
                  '시간',
                  schedule.timeText,
                  Color(0xFF06B6D4),
                ),

                // 🆕 상세 일정 정보 (여러 날 시간 일정용)
                if (schedule.isMultiDay && !schedule.isAllDay) ...[
                  SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.schedule_rounded,
                    '상세 시간',
                    _getDetailedTimeInfo(),
                    Color(0xFF8B5CF6),
                  ),
                ],

                if (schedule.memo.isNotEmpty) ...[
                  SizedBox(height: 16),
                  _buildDetailRow(
                    Icons.note_rounded,
                    '메모',
                    schedule.memo,
                    Color(0xFF10B981),
                  ),
                ],

                SizedBox(height: 16),

                // 생성 시간
                _buildDetailRow(
                  Icons.schedule_rounded,
                  '생성',
                  utils.DateUtils.formatDateTime(schedule.createdAt),
                  Color(0xFF6B7280),
                ),
              ],
            ),
          ),

          SizedBox(height: 32),

          // 🆕 사용자 색상 적용된 액션 버튼들
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // 수정 버튼
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor, primaryColor.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onEdit?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                      label: Text(
                        '수정하기',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 12),

                // 삭제 버튼
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFEF4444).withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onDelete?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: Icon(Icons.delete_rounded, color: Colors.white, size: 20),
                      label: Text(
                        '삭제하기',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // 닫기 버튼
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: double.infinity,
              height: 50,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: Color(0xFFF3F4F6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  '닫기',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 32),
        ],
      ),
    );
  }

  // 🆕 사용자별 색상 가져오기
  Color _getScheduleColor() {
    if (schedule.ownerColorValue != null) {
      return Color(schedule.ownerColorValue!);
    }

    // 기본 색상 (오늘 일정은 특별 색상)
    return utils.DateUtils.isToday(schedule.scheduledAt)
        ? Color(0xFF6366F1)
        : Color(0xFF64748B);
  }

  // 🆕 상세 시간 정보 (여러 날 시간 일정용)
  String _getDetailedTimeInfo() {
    if (!schedule.isMultiDay || schedule.isAllDay) return schedule.timeText;

    final startDate = utils.DateUtils.formatDate(schedule.scheduledAt);
    final startTime = '${schedule.scheduledAt.hour.toString().padLeft(2, '0')}:${schedule.scheduledAt.minute.toString().padLeft(2, '0')}';

    if (schedule.endTime != null) {
      final endDate = utils.DateUtils.formatDate(schedule.endTime!);
      final endTime = '${schedule.endTime!.hour.toString().padLeft(2, '0')}:${schedule.endTime!.minute.toString().padLeft(2, '0')}';
      return '$startDate $startTime ~ $endDate $endTime';
    }

    return '$startDate $startTime ~';
  }

  // 상세 정보 행
  Widget _buildDetailRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 18,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 배지 위젯
  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 아이콘 선택
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
    } else if (lowerTitle.contains('여행')) {
      return Icons.flight_rounded;
    } else if (lowerTitle.contains('영화')) {
      return Icons.movie_rounded;
    } else {
      return Icons.event_rounded;
    }
  }
}

// 사용하기 쉬운 헬퍼 함수
void showScheduleDetailSheet({
  required BuildContext context,
  required Schedule schedule,
  VoidCallback? onEdit,
  VoidCallback? onDelete,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ScheduleDetailSheet(
      schedule: schedule,
      onEdit: onEdit,
      onDelete: onDelete,
    ),
  );
}