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
    final Color primaryColor = _getScheduleColor();
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      // 🔧 동적 높이 설정 (화면 크기에 따라 조정)
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.9, // 화면의 90%까지만 사용
        minHeight: 300, // 최소 높이 보장
      ),
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

          // 🔧 스크롤 가능한 내용 영역
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 일정 정보 헤더
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: _buildHeader(primaryColor),
                  ),

                  SizedBox(height: 20),

                  // 일정 상세 정보
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: _buildDetailSection(),
                  ),

                  SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // 🔧 고정 하단 버튼 영역
          Container(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 액션 버튼들
                Row(
                  children: [
                    // 🔧 수정 버튼 (고정 색상)
                    Expanded(
                      child: _buildActionButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onEdit?.call();
                        },
                        icon: Icons.edit_rounded,
                        label: '수정',
                        color: Color(0xFF6366F1), // 🔧 고정 색상 (인디고)
                      ),
                    ),

                    SizedBox(width: 12),

                    // 삭제 버튼 (빨간색 고정)
                    Expanded(
                      child: _buildActionButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onDelete?.call();
                        },
                        icon: Icons.delete_rounded,
                        label: '삭제',
                        color: Color(0xFFEF4444), // 빨간색 고정
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // 닫기 버튼
                Container(
                  width: double.infinity,
                  height: 44, // 🔧 50 → 44로 줄임
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: Color(0xFFF3F4F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '닫기',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600,
                        fontSize: 15, // 🔧 16 → 15로 줄임
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔧 헤더 위젯 (분리)
  Widget _buildHeader(Color primaryColor) {
    return Row(
      children: [
        // 사용자 색상 적용된 아이콘
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
                  fontSize: 18, // 🔧 20 → 18로 줄임
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                maxLines: 2, // 🔧 제목이 길 때 2줄까지 허용
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              // 🔧 배지들을 컴팩트하게 배치
              _buildCompactBadges(),
            ],
          ),
        ),
      ],
    );
  }

  // 🔧 컴팩트한 배지 위젯
  Widget _buildCompactBadges() {
    List<Widget> badges = [];

    // 여러 날 일정 배지
    if (schedule.isMultiDay) {
      badges.add(_buildBadge('${schedule.durationInDays}일간', Color(0xFF3B82F6)));
    }

    // 하루종일 배지
    if (schedule.isAllDay && !schedule.isMultiDay) {
      badges.add(_buildBadge('하루종일', Color(0xFF8B5CF6)));
    }

    // 오늘 배지
    if (utils.DateUtils.isToday(schedule.scheduledAt) && !schedule.isAllDay) {
      badges.add(_buildBadge('오늘', Color(0xFF10B981)));
    }

    // 진행 중 배지
    if (schedule.isCurrentlyActive) {
      badges.add(_buildBadge('진행중', Color(0xFFEF4444)));
    }

    if (badges.isEmpty) return SizedBox.shrink();

    return Wrap(
      spacing: 6, // 🔧 8 → 6으로 줄임
      runSpacing: 4,
      children: badges,
    );
  }

  // 🔧 상세 정보 섹션 (분리)
  Widget _buildDetailSection() {
    return Container(
      padding: EdgeInsets.all(16), // 🔧 20 → 16으로 줄임
      decoration: BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // 날짜 정보
          _buildDetailRow(
            Icons.calendar_today_rounded,
            schedule.isMultiDay ? '기간' : '날짜',
            schedule.isMultiDay ? schedule.dateRangeText : utils.DateUtils.formatDate(schedule.scheduledAt),
            Color(0xFFEC4899),
          ),

          SizedBox(height: 12), // 🔧 16 → 12로 줄임

          // 시간 정보
          _buildDetailRow(
            schedule.isAllDay ? Icons.event_rounded : Icons.access_time_rounded,
            '시간',
            schedule.timeText,
            Color(0xFF06B6D4),
          ),

          // 상세 일정 정보 (여러 날 시간 일정용)
          if (schedule.isMultiDay && !schedule.isAllDay) ...[
            SizedBox(height: 12),
            _buildDetailRow(
              Icons.schedule_rounded,
              '상세 시간',
              _getDetailedTimeInfo(),
              Color(0xFF8B5CF6),
            ),
          ],

          if (schedule.memo.isNotEmpty) ...[
            SizedBox(height: 12),
            _buildDetailRow(
              Icons.note_rounded,
              '메모',
              schedule.memo,
              Color(0xFF10B981),
              isExpandable: true, // 🔧 메모는 확장 가능
            ),
          ],

          SizedBox(height: 12),

          // 생성 시간 (컴팩트하게)
          _buildDetailRow(
            Icons.schedule_rounded,
            '생성',
            utils.DateUtils.formatDateTime(schedule.createdAt),
            Color(0xFF6B7280),
            isCompact: true, // 🔧 생성 시간은 컴팩트하게
          ),
        ],
      ),
    );
  }

  // 🔧 액션 버튼 위젯 (분리)
  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      height: 44, // 🔧 50 → 44로 줄임
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12), // 🔧 16 → 12로 줄임
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 6, // 🔧 8 → 6으로 줄임
            offset: Offset(0, 3), // 🔧 4 → 3으로 줄임
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon, color: Colors.white, size: 18), // 🔧 20 → 18로 줄임
        label: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14, // 🔧 16 → 14로 줄임
          ),
        ),
      ),
    );
  }

  // 사용자별 색상 가져오기
  Color _getScheduleColor() {
    if (schedule.ownerColorValue != null) {
      return Color(schedule.ownerColorValue!);
    }

    return utils.DateUtils.isToday(schedule.scheduledAt)
        ? Color(0xFF6366F1)
        : Color(0xFF64748B);
  }

  // 상세 시간 정보
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

  // 🔧 개선된 상세 정보 행
  Widget _buildDetailRow(
      IconData icon,
      String label,
      String value,
      Color iconColor, {
        bool isExpandable = false,
        bool isCompact = false,
      }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(6), // 🔧 8 → 6으로 줄임
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 16, // 🔧 18 → 16으로 줄임
          ),
        ),
        SizedBox(width: 10), // 🔧 12 → 10으로 줄임
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isCompact ? 10 : 11, // 🔧 12 → 11 (컴팩트는 10)
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: isCompact ? 12 : 13, // 🔧 14 → 13 (컴팩트는 12)
                  color: Color(0xFF374151),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: isExpandable ? null : 2, // 🔧 메모는 무제한, 나머지는 2줄
                overflow: isExpandable ? null : TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 🔧 더 작은 배지 위젯
  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3), // 🔧 8,4 → 6,3으로 줄임
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(10), // 🔧 12 → 10으로 줄임
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 3, // 🔧 4 → 3으로 줄임
            offset: Offset(0, 1), // 🔧 2 → 1로 줄임
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 9, // 🔧 10 → 9로 줄임
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
    isScrollControlled: true, // 🔧 중요: 화면 크기에 맞춰 조정
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.9, // 🔧 최대 높이 제한
    ),
    builder: (context) => ScheduleDetailSheet(
      schedule: schedule,
      onEdit: onEdit,
      onDelete: onDelete,
    ),
  );
}