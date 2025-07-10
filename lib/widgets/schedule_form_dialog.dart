import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/schedule.dart';

class ScheduleFormDialog extends StatefulWidget {
  final DateTime? selectedDate;
  final Schedule? existingSchedule;

  const ScheduleFormDialog({
    Key? key,
    this.selectedDate,
    this.existingSchedule,
  }) : super(key: key);

  @override
  _ScheduleFormDialogState createState() => _ScheduleFormDialogState();
}

class _ScheduleFormDialogState extends State<ScheduleFormDialog> {
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();
  final _scrollController = ScrollController();
  final _formKey = GlobalKey<FormState>();

  // 시작일시 관련
  late DateTime _startDate;
  TimeOfDay _startTime = TimeOfDay(hour: 9, minute: 0);

  // 종료일시 관련
  late DateTime _endDate;
  TimeOfDay _endTime = TimeOfDay(hour: 10, minute: 0);

  bool _isAllDay = false;
  bool _isLoading = false;

  Color _selectedColor = Colors.blueAccent;

  // 🔔 알림 관련 변수들
  bool _hasNotification = false;
  int _notificationMinutes = 10;

  // 🆕 간격 유지 로직을 위한 변수들
  bool _isEndTimeManuallySet = false;  // 종료 시간이 수동으로 설정되었는지
  int _currentDurationMinutes = 60;    // 현재 일정 길이 (기본 1시간)

  // 알림 시간 옵션들
  final List<Map<String, dynamic>> _notificationOptions = [
    {'label': '정시', 'value': 0},
    {'label': '5분 전', 'value': 5},
    {'label': '10분 전', 'value': 10},
    {'label': '15분 전', 'value': 15},
    {'label': '30분 전', 'value': 30},
    {'label': '1시간 전', 'value': 60},
    {'label': '2시간 전', 'value': 120},
    {'label': '1일 전', 'value': 1440},
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();

    if (widget.existingSchedule != null && widget.existingSchedule!.ownerColorValue != null) {
      _selectedColor = Color(widget.existingSchedule!.ownerColorValue!);
    }
  }

  void _initializeForm() {
    if (widget.existingSchedule != null) {
      // 수정 모드 - 기존 Schedule 모델에서 데이터 추출
      final schedule = widget.existingSchedule!;
      _titleController.text = schedule.title;
      _memoController.text = schedule.memo;
      _isAllDay = schedule.isAllDay;

      // 알림 설정 불러오기
      _hasNotification = schedule.hasNotification;
      _notificationMinutes = schedule.notificationMinutes;

      // 시작일시
      _startDate = DateTime(
        schedule.scheduledAt.year,
        schedule.scheduledAt.month,
        schedule.scheduledAt.day,
      );

      if (!_isAllDay) {
        _startTime = TimeOfDay.fromDateTime(schedule.scheduledAt);
      }

      // 종료일시
      if (schedule.endTime != null) {
        _endDate = DateTime(
          schedule.endTime!.year,
          schedule.endTime!.month,
          schedule.endTime!.day,
        );

        if (!_isAllDay) {
          _endTime = TimeOfDay.fromDateTime(schedule.endTime!);
        }
      } else {
        _endDate = _startDate;
        if (!_isAllDay) {
          _endTime = TimeOfDay(hour: (_startTime.hour + 1) % 24, minute: _startTime.minute);
        }
      }

      // 🎯 기존 일정은 이미 설정된 간격이 있는 것으로 간주
      _isEndTimeManuallySet = true;
      _calculateCurrentDuration();

    } else {
      // 새 일정 모드
      final baseDate = widget.selectedDate ?? DateTime.now();
      _startDate = DateTime(baseDate.year, baseDate.month, baseDate.day);
      _endDate = _startDate;

      final now = DateTime.now();
      _startTime = TimeOfDay(hour: now.hour, minute: 0);
      _endTime = TimeOfDay(hour: (now.hour + 1) % 24, minute: 0);
      _isAllDay = false;

      // 새 일정 기본값
      _hasNotification = false;
      _notificationMinutes = 10;

      // 🎯 새 일정은 자동 설정 상태, 기본 1시간
      _isEndTimeManuallySet = false;
      _currentDurationMinutes = 60;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 🆕 현재 시작-종료 간격 계산
  void _calculateCurrentDuration() {
    if (_isAllDay) {
      _currentDurationMinutes = 60; // 하루종일은 기본값
      return;
    }

    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDateTime = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    final duration = endDateTime.difference(startDateTime).inMinutes;

    // 🔧 유효한 간격인지 확인 (15분 ~ 24시간)
    if (duration >= 15 && duration <= 1440) {
      _currentDurationMinutes = duration;
    } else {
      _currentDurationMinutes = 60; // 비정상적이면 기본값
    }
  }

  // 🆕 저장된 간격으로 종료 시간 업데이트
  void _updateEndTimeWithCurrentDuration() {
    if (_isAllDay) return;

    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDateTime = startDateTime.add(Duration(minutes: _currentDurationMinutes));

    // 날짜 넘어가는 경우 처리
    _endDate = DateTime(endDateTime.year, endDateTime.month, endDateTime.day);
    _endTime = TimeOfDay.fromDateTime(endDateTime);
  }

  // 🆕 기본 간격(1시간)으로 종료 시간 업데이트
  void _updateEndTimeWithDefaultDuration() {
    if (_isAllDay) return;

    final startDateTime = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    final endDateTime = startDateTime.add(Duration(minutes: 60)); // 기본 1시간

    _endDate = DateTime(endDateTime.year, endDateTime.month, endDateTime.day);
    _endTime = TimeOfDay.fromDateTime(endDateTime);

    // 기본값으로 설정했으므로 현재 간격도 업데이트
    _currentDurationMinutes = 60;
  }

  // 🎯 시작 시간 변경 처리 (핵심 로직)
  void _onStartTimeChanged(TimeOfDay newStartTime) {
    setState(() {
      _startTime = newStartTime;

      // 🎯 간격 유지 로직
      if (_isEndTimeManuallySet) {
        // 수동 설정된 간격이 있으면 그 간격 유지
        _updateEndTimeWithCurrentDuration();
      } else {
        // 자동 상태면 기본 1시간 적용
        _updateEndTimeWithDefaultDuration();
      }
    });
  }

  // 🎯 종료 시간 변경 처리 (수동 설정 기록)
  void _onEndTimeChanged(TimeOfDay newEndTime) {
    setState(() {
      _endTime = newEndTime;

      // 🎯 사용자가 수동으로 변경했음을 기록
      _isEndTimeManuallySet = true;

      // 새로운 간격 계산 및 저장
      _calculateCurrentDuration();
    });
  }

  // 🎯 하루종일 토글 처리
  void _onAllDayToggleChanged(bool isAllDay) {
    setState(() {
      _isAllDay = isAllDay;

      if (!_isAllDay) {
        // 하루종일에서 시간 일정으로 바뀔 때 초기화
        _isEndTimeManuallySet = false;
        _updateEndTimeWithDefaultDuration();
      }
    });
  }

  // 🆕 간격 표시용 포맷터
  String _formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}분';
    } else if (minutes % 60 == 0) {
      return '${minutes ~/ 60}시간';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}시간 ${mins}분';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingSchedule != null;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          minHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        margin: EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 헤더
            _buildHeader(isEditing),

            // 폼 영역
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목 입력
                    _buildInputField(
                      controller: _titleController,
                      label: '제목',
                      hint: '일정 제목을 입력하세요',
                      icon: Icons.title,
                      color: Color(0xFF6366F1),
                      autofocus: true,
                    ),

                    SizedBox(height: 16),

                    // 날짜 및 시간 섹션
                    _buildDateTimeSection(),

                    SizedBox(height: 16),

                    // 알림 설정 섹션
                    _buildNotificationSection(),

                    SizedBox(height: 16),

                    // 색상 선택
                    _buildColorSection(),

                    SizedBox(height: 16),

                    // 메모 입력
                    _buildInputField(
                      controller: _memoController,
                      label: '메모 (선택사항)',
                      hint: '추가 설명을 입력하세요',
                      icon: Icons.note,
                      color: Color(0xFF10B981),
                      maxLines: 3,
                    ),

                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // 고정 하단 버튼
            _buildBottomButtons(isEditing),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isEditing) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isEditing ? Icons.edit_rounded : Icons.add_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              isEditing ? '일정 수정' : '새 일정',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          if (_isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          SizedBox(width: 8),
          IconButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            icon: Icon(Icons.close, color: Colors.white, size: 20),
            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color color,
    int maxLines = 1,
    bool autofocus = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: color, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintStyle: TextStyle(color: Colors.grey[500]),
            ),
            maxLines: maxLines,
            autofocus: autofocus,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
            textInputAction: maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
            keyboardType: maxLines > 1 ? TextInputType.multiline : TextInputType.text,
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '날짜 및 시간',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        SizedBox(height: 8),

        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              // 하루종일 토글
              Row(
                children: [
                  Switch(
                    value: _isAllDay,
                    onChanged: _onAllDayToggleChanged, // 🎯 수정된 메서드 연결
                    activeColor: Color(0xFF6366F1),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '하루종일',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // 시작일시 섹션
              _buildDateTimeInput(
                title: '시작',
                date: _startDate,
                time: _startTime,
                color: Color(0xFF10B981),
                onDateTap: () => _selectDate(isStart: true),
                onTimeChanged: _onStartTimeChanged, // 🎯 간격 유지 로직 연결
              ),

              SizedBox(height: 16),

              // 종료일시 섹션
              _buildDateTimeInput(
                title: '종료',
                date: _endDate,
                time: _endTime,
                color: Color(0xFFEF4444),
                onDateTap: () => _selectDate(isStart: false),
                onTimeChanged: _onEndTimeChanged, // 🎯 수동 설정 추적 연결
              ),


            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeInput({
    required String title,
    required DateTime date,
    required TimeOfDay time,
    required Color color,
    required VoidCallback onDateTap,
    required Function(TimeOfDay) onTimeChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              title == '시작' ? Icons.play_arrow : Icons.stop,
              size: 16,
              color: color,
            ),
            SizedBox(width: 4),
            Text(
              '$title 일시',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),

        Row(
          children: [
            // 날짜 선택 버튼
            Expanded(
              flex: 2,
              child: InkWell(
                onTap: onDateTap,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: color),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatKoreanDate(date),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 시간 선택 (하루종일이 아닐 때만)
            if (!_isAllDay) ...[
              SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showTimeScrollPicker(time, onTimeChanged),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time, size: 16, color: color),
                        SizedBox(width: 4),
                        Text(
                          _formatTime(time),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildNotificationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '알림 설정',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        SizedBox(height: 8),

        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber[200]!),
          ),
          child: Column(
            children: [
              // 알림 켜기/끄기 토글
              Row(
                children: [
                  Icon(
                    _hasNotification ? Icons.notifications_active : Icons.notifications_off,
                    color: _hasNotification ? Colors.amber[700] : Colors.grey[500],
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '알림 받기',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  Switch(
                    value: _hasNotification,
                    onChanged: (value) => setState(() => _hasNotification = value),
                    activeColor: Colors.amber[700],
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),

              // 알림 시간 선택 (알림이 켜져있을 때만)
              if (_hasNotification) ...[
                SizedBox(height: 12),

                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Colors.amber[700],
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '알림 시간',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber[800],
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber[300]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _notificationMinutes,
                            isExpanded: true,
                            isDense: true,
                            items: _notificationOptions.map<DropdownMenuItem<int>>((option) {
                              return DropdownMenuItem<int>(
                                value: option['value'],
                                child: Text(
                                  option['label'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _notificationMinutes = value);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 6),
                Text(
                  _getNotificationDescription(),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.amber[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '일정 색상 선택',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            Colors.blueAccent,
            Colors.greenAccent,
            Colors.orangeAccent,
            Colors.pinkAccent,
            Colors.purpleAccent,
          ].map((color) {
            final isSelected = _selectedColor.value == color.value;
            return GestureDetector(
              onTap: () => setState(() => _selectedColor = color),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(width: 2, color: Colors.black)
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(bool isEditing) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 알림 미리보기 (알림이 켜져있을 때만)
          if (_hasNotification) ...[
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.amber[700], size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getNotificationPreview(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
          ],

          // 버튼들
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey[400]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    '취소',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveSchedule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    isEditing ? '수정' : '저장',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 스크롤 휠 시간 선택 다이얼로그
  void _showTimeScrollPicker(TimeOfDay currentTime, Function(TimeOfDay) onTimeChanged) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return TimeScrollPickerModal(
          initialTime: currentTime,
          onTimeChanged: onTimeChanged,
        );
      },
    );
  }

  // 🎯 시작 날짜 변경 처리
  Future<void> _selectDate({required bool isStart}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;

          // 시작 날짜 변경 시 간격 유지 로직 적용
          if (_isEndTimeManuallySet) {
            _updateEndTimeWithCurrentDuration();
          } else {
            _updateEndTimeWithDefaultDuration();
          }

          // 종료 날짜가 시작 날짜보다 이전이면 조정
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = date;

          // 종료 날짜 수동 변경 시
          _isEndTimeManuallySet = true;
          _calculateCurrentDuration();

          // 시작 날짜가 종료 날짜보다 이후면 조정
          if (_startDate.isAfter(_endDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  // 알림 시간 설명 텍스트
  String _getNotificationDescription() {
    if (_notificationMinutes == 0) {
      return _isAllDay ? '하루종일 일정 시작 시 알림' : '일정 시작 시간에 알림';
    } else if (_notificationMinutes >= 1440) {
      final days = _notificationMinutes ~/ 1440;
      return _isAllDay
          ? '하루종일 일정 ${days}일 전 오전 9시에 알림'
          : '일정 시작 ${days}일 전 같은 시간에 알림';
    } else if (_notificationMinutes >= 60) {
      final hours = _notificationMinutes ~/ 60;
      return _isAllDay
          ? '하루종일 일정 ${hours}시간 전 알림'
          : '일정 시작 ${hours}시간 전 알림';
    } else {
      return _isAllDay
          ? '하루종일 일정 ${_notificationMinutes}분 전 알림'
          : '일정 시작 ${_notificationMinutes}분 전 알림';
    }
  }

  // 알림 미리보기 텍스트
  String _getNotificationPreview() {
    final scheduleTime = _isAllDay
        ? '${_formatKoreanDate(_startDate)}'
        : '${_formatKoreanDate(_startDate)} ${_formatTime(_startTime)}';

    if (_notificationMinutes == 0) {
      return '알림: $scheduleTime';
    } else {
      final option = _notificationOptions.firstWhere((opt) => opt['value'] == _notificationMinutes);
      return '알림: $scheduleTime (${option['label']})';
    }
  }

  // 유틸리티 메서드들
  String _formatKoreanDate(DateTime date) {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final weekday = weekdays[date.weekday % 7];
    return '${date.month}월 ${date.day}일 ($weekday)';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // ✅ 핵심: 알림 설정이 포함된 Schedule 모델로 저장
  Future<void> _saveSchedule() async {
    if (_titleController.text.trim().isEmpty) {
      _showErrorSnackBar('제목을 입력해주세요');
      return;
    }

    setState(() => _isLoading = true);

    try {
      DateTime scheduledAt;
      DateTime? endTime;

      if (_isAllDay) {
        // 하루종일 일정
        scheduledAt = DateTime(_startDate.year, _startDate.month, _startDate.day);

        // 여러 날 하루종일 일정인지 확인
        if (!_isSameDay(_startDate, _endDate)) {
          endTime = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
        } else {
          endTime = null; // 하루만인 경우 기존 방식대로 null
        }
      } else {
        // 시간 일정
        scheduledAt = DateTime(
          _startDate.year,
          _startDate.month,
          _startDate.day,
          _startTime.hour,
          _startTime.minute,
        );

        endTime = DateTime(
          _endDate.year,
          _endDate.month,
          _endDate.day,
          _endTime.hour,
          _endTime.minute,
        );

        // 시간 일정에서 시작 시간이 종료 시간보다 늦으면 에러
        if (endTime.isBefore(scheduledAt)) {
          _showErrorSnackBar('종료 시간이 시작 시간보다 이릅니다');
          setState(() => _isLoading = false);
          return;
        }
      }

      // Schedule 모델 생성
      final schedule = Schedule(
        id: widget.existingSchedule?.id ?? '',
        title: _titleController.text.trim(),
        memo: _memoController.text.trim(),
        scheduledAt: scheduledAt,
        endTime: endTime,
        isAllDay: _isAllDay,
        createdAt: widget.existingSchedule?.createdAt ?? DateTime.now(),
        ownerColorValue: _selectedColor.value,
        hasNotification: _hasNotification,
        notificationMinutes: _notificationMinutes,
      );

      // Schedule 객체를 반환
      Navigator.pop(context, schedule);
    } catch (e) {
      _showErrorSnackBar('오류가 발생했습니다: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// 🎯 스크롤 휠 시간 선택 모달
class TimeScrollPickerModal extends StatefulWidget {
  final TimeOfDay initialTime;
  final Function(TimeOfDay) onTimeChanged;

  const TimeScrollPickerModal({
    Key? key,
    required this.initialTime,
    required this.onTimeChanged,
  }) : super(key: key);

  @override
  _TimeScrollPickerModalState createState() => _TimeScrollPickerModalState();
}

class _TimeScrollPickerModalState extends State<TimeScrollPickerModal> {
  late int selectedHour;
  late int selectedMinute;

  @override
  void initState() {
    super.initState();
    selectedHour = widget.initialTime.hour;
    selectedMinute = widget.initialTime.minute;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF6366F1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '시간 선택',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    widget.onTimeChanged(TimeOfDay(hour: selectedHour, minute: selectedMinute));
                    Navigator.pop(context);
                  },
                  child: Text(
                    '완료',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 스크롤 휠
          Expanded(
            child: Row(
              children: [
                // 시간 선택
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          '시간',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 50,
                          looping: true,
                          scrollController: FixedExtentScrollController(
                            initialItem: selectedHour,
                          ),
                          onSelectedItemChanged: (int index) {
                            setState(() => selectedHour = index);
                          },
                          children: List.generate(24, (index) =>
                              Center(
                                child: Text(
                                  '${index.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 구분선
                Container(
                  width: 1,
                  height: 100,
                  color: Colors.grey[300],
                ),

                // 분 선택
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          '분',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          itemExtent: 50,
                          looping: true,
                          scrollController: FixedExtentScrollController(
                            initialItem: selectedMinute,
                          ),
                          onSelectedItemChanged: (int index) {
                            setState(() => selectedMinute = index);
                          },
                          children: List.generate(60, (index) =>
                              Center(
                                child: Text(
                                  '${index.toString().padLeft(2, '0')}',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                                ),
                              ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 다이얼로그 호출 함수
Future<Schedule?> showScheduleFormDialog({
  required BuildContext context,
  DateTime? selectedDate,
  Schedule? existingSchedule,
}) {
  return showGeneralDialog<Schedule>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    transitionDuration: Duration(milliseconds: 300),
    pageBuilder: (context, animation1, animation2) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: ScheduleFormDialog(
                selectedDate: selectedDate,
                existingSchedule: existingSchedule,
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, animation1, animation2, child) {
      return FadeTransition(
        opacity: animation1,
        child: child,
      );
    },
  );
}