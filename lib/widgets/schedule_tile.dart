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
    final baseColor = schedule.ownerColorValue != null
        ? Color(schedule.ownerColorValue!)
        : Color(0xFF6366F1);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isToday
              ? [baseColor.withOpacity(0.15), baseColor.withOpacity(0.25)]
              : [baseColor.withOpacity(0.05), baseColor.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isToday
                ? baseColor.withOpacity(0.15)  // 🔧 사용자 색상으로 통일
                : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        border: isToday
            ? Border.all(color: baseColor.withOpacity(0.3), width: 1.5)  // 🔧 사용자 색상으로 통일
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
                          ? [baseColor.withOpacity(0.7), baseColor]
                          : [baseColor.withOpacity(0.5), baseColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: baseColor.withOpacity(0.3),
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

                // 🔧 내용 영역 (Expanded로 감싸서 오버플로우 방지)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // 🔧 필요한 공간만 사용
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

                      // 🔧 날짜 범위 표시 (여러 날 일정일 때) - 공간 최적화
                      if (schedule.isMultiDay) ...[
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 🔧 패딩 줄임
                          decoration: BoxDecoration(
                            color: Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.date_range_rounded,
                                size: 14, // 🔧 16 → 14로 줄임
                                color: Color(0xFF6B7280),
                              ),
                              SizedBox(width: 4), // 🔧 6 → 4로 줄임
                              Flexible( // 🔧 Text를 Flexible로 감쌈
                                child: Text(
                                  schedule.dateRangeText,
                                  style: TextStyle(
                                    fontSize: 12, // 🔧 13 → 12로 줄임
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6B7280),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 8),
                      ],

                      // 🔧 시간 및 배지 - 유연한 레이아웃
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 시간 정보
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), // 🔧 패딩 줄임
                            decoration: BoxDecoration(
                              color: isToday
                                  ? baseColor.withOpacity(0.15)  // 🔧 사용자 색상으로 통일
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
                                  size: 14, // 🔧 16 → 14로 줄임
                                  color: isToday
                                      ? baseColor  // 🔧 사용자 색상으로 통일
                                      : Color(0xFF6B7280),
                                ),
                                SizedBox(width: 4), // 🔧 6 → 4로 줄임
                                Flexible( // 🔧 시간 텍스트도 Flexible로
                                  child: Text(
                                    _getTimeDisplayText(),
                                    style: TextStyle(
                                      fontSize: 12, // 🔧 13 → 12로 줄임
                                      fontWeight: FontWeight.w600,
                                      color: isToday
                                          ? baseColor  // 🔧 사용자 색상으로 통일
                                          : Color(0xFF6B7280),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // 🔧 배지들 - 별도 행으로 분리하고 Wrap 사용
                          SizedBox(height: 6),
                          _buildBadgeSection(),
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

  // 🔧 배지 섹션 - 원래 고정 색상으로 복원
  Widget _buildBadgeSection() {
    List<Widget> badges = [];

    // 여러 날 일정 배지 (파란색 고정)
    if (schedule.isMultiDay) {
      badges.add(_buildBadge(
        '${schedule.durationInDays}일간',
        [Color(0xFF3B82F6), Color(0xFF2563EB)],
        iconData: Icons.date_range,
      ));
    }

    // 하루종일 배지 (보라색 고정)
    if (schedule.isAllDay && !schedule.isMultiDay) {
      badges.add(_buildBadge(
        '하루종일',
        [Color(0xFF8B5CF6), Color(0xFFA855F7)],
        iconData: Icons.event,
      ));
    }

    // 오늘 배지 (녹색 고정)
    if (showDate && utils.DateUtils.isToday(schedule.scheduledAt) && !schedule.isAllDay) {
      badges.add(_buildBadge(
        '오늘',
        [Color(0xFF10B981), Color(0xFF059669)],
        iconData: Icons.today,
      ));
    }

    // 진행 중 배지 (빨간색 고정)
    if (schedule.isCurrentlyActive) {
      badges.add(_buildBadge(
        '진행중',
        [Color(0xFFEF4444), Color(0xFFDC2626)],
        iconData: Icons.play_circle_filled,
        hasAnimation: true, // 진행중 표시를 위한 작은 점
      ));
    }

    // 배지가 없으면 빈 위젯 반환
    if (badges.isEmpty) {
      return SizedBox.shrink();
    }

    // Wrap을 사용해서 공간에 따라 자동 줄바꿈
    return Wrap(
      spacing: 6, // 배지 간 가로 간격
      runSpacing: 4, // 배지 간 세로 간격 (줄바꿈 시)
      children: badges,
    );
  }

  // 🔧 통일된 배지 생성 (모두 사용자 색상)
  Widget _buildBadge(String text, List<Color> colors, {IconData? iconData, bool hasAnimation = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconData != null) ...[
            Icon(
              iconData,
              size: 8,
              color: Colors.white,
            ),
            SizedBox(width: 2),
          ],
          // 진행중일 때는 작은 점 추가
          if (hasAnimation) ...[
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 3),
          ],
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 🗑️ 기존 진행중 배지 함수 제거 (통합됨)



  // 상세 바텀시트 표시
  void _showDetailSheet(BuildContext context) {
    showScheduleDetailSheet(
      context: context,
      schedule: schedule,
      onEdit: onEdit,
      onDelete: onDelete,
    );
  }

  // 시간 표시 텍스트 생성 (개선됨)
  String _getTimeDisplayText() {
    if (schedule.isAllDay) {
      if (schedule.isMultiDay) {
        return '하루종일';
      }
      return showDate
          ? utils.DateUtils.formatDate(schedule.scheduledAt)
          : '하루종일';
    }

    if (showDate) {
      // 날짜 + 시간 표시
      if (schedule.isMultiDay) {
        return '${utils.DateUtils.formatDateTime(schedule.scheduledAt)} 시작';
      }
      return utils.DateUtils.formatDateTime(schedule.scheduledAt);
    } else {
      // 시간만 표시 (새로운 timeText 메서드 활용)
      return schedule.timeText;
    }
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