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

  // 시작일시 관련
  late DateTime _startDate;
  TimeOfDay _startTime = TimeOfDay(hour: 9, minute: 0);

  // 종료일시 관련
  late DateTime _endDate;
  TimeOfDay _endTime = TimeOfDay(hour: 10, minute: 0);

  bool _isAllDay = false;
  bool _isLoading = false;

  Color _selectedColor = Colors.blueAccent;

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
    } else {
      // 새 일정 모드
      final baseDate = widget.selectedDate ?? DateTime.now();
      _startDate = DateTime(baseDate.year, baseDate.month, baseDate.day);
      _endDate = _startDate;

      final now = DateTime.now();
      _startTime = TimeOfDay(hour: now.hour, minute: 0);
      _endTime = TimeOfDay(hour: (now.hour + 1) % 24, minute: 0);
      _isAllDay = false;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingSchedule != null;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.85,
            ),
            margin: EdgeInsets.only(
              bottom: keyboardHeight > 0 ? keyboardHeight + 20 : 0,
            ),
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

                // 스크롤 가능한 폼
                Flexible(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: EdgeInsets.all(20),
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

                        SizedBox(height: 20),

                        // 날짜 및 시간 섹션
                        _buildDateTimeSection(),

                        Text('일정 색상 선택',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)
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
                                width: 32, height: 32,
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

                        SizedBox(height: 20),

                        // 메모 입력
                        _buildInputField(
                          controller: _memoController,
                          label: '메모 (선택사항)',
                          hint: '추가 설명을 입력하세요',
                          icon: Icons.note,
                          color: Color(0xFF10B981),
                          maxLines: 3,
                        ),

                        SizedBox(height: 80), // 버튼 영역 확보
                      ],
                    ),
                  ),
                ),

                // 고정 하단 버튼
                _buildBottomButtons(isEditing),
              ],
            ),
          ),
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
          child: TextField(
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
                    onChanged: (value) => setState(() => _isAllDay = value),
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
                onTimeChanged: (time) => setState(() => _startTime = time),
              ),

              SizedBox(height: 16),

              // 종료일시 섹션
              _buildDateTimeInput(
                title: '종료',
                date: _endDate,
                time: _endTime,
                color: Color(0xFFEF4444),
                onDateTap: () => _selectDate(isStart: false),
                onTimeChanged: (time) => setState(() => _endTime = time),
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

  // 🎯 스크롤 휠 시간 선택 다이얼로그
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

  Widget _buildBottomButtons(bool isEditing) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
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
    );
  }

  // 🔧 유틸리티 메서드들

  String _formatKoreanDate(DateTime date) {
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];
    final weekday = weekdays[date.weekday % 7];
    return '${date.month}월 ${date.day}일 ($weekday)';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // 🎯 액션 메서드들

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
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = date;
          if (_startDate.isAfter(_endDate)) {
            _startDate = _endDate;
          }
        }
      });
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _isTimeAfter(TimeOfDay time1, TimeOfDay time2) {
    return time1.hour > time2.hour ||
        (time1.hour == time2.hour && time1.minute > time2.minute);
  }

  // ✅ 핵심: 기존 Schedule 모델 형태로 변환해서 저장
  Future<void> _saveSchedule() async {
    if (_titleController.text.trim().isEmpty) {
      _showErrorSnackBar('제목을 입력해주세요');
      return;
    }

    setState(() => _isLoading = true);

    try {
      DateTime scheduledAt; // 기존 모델의 시작 시간
      DateTime? endTime;    // 기존 모델의 종료 시간

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

        // 시작 시간이 종료 시간보다 늦으면 에러
        if (endTime.isBefore(scheduledAt)) {
          _showErrorSnackBar('종료 시간이 시작 시간보다 이릅니다');
          setState(() => _isLoading = false);
          return;
        }
      }

      // ✅ 기존 Schedule 모델 형태로 생성
      final schedule = Schedule(
        id: widget.existingSchedule?.id ?? '',
        title: _titleController.text.trim(),
        memo: _memoController.text.trim(),
        scheduledAt: scheduledAt,    // 기존 필드명
        endTime: endTime,           // 기존 필드명
        isAllDay: _isAllDay,
        createdAt: widget.existingSchedule?.createdAt ?? DateTime.now(),
        ownerColorValue: _selectedColor.value,
      );

      // Schedule 객체를 반환 (기존 코드와 호환)
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

                // 분 선택 (15분 단위)
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

// 사용하기 쉬운 헬퍼 함수
Future<Schedule?> showScheduleFormDialog({
  required BuildContext context,
  DateTime? selectedDate,
  Schedule? existingSchedule,
}) {
  return showDialog<Schedule>(
    context: context,
    barrierDismissible: false,
    builder: (context) => ScheduleFormDialog(
      selectedDate: selectedDate,
      existingSchedule: existingSchedule,
    ),
  );
}