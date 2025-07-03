import 'package:intl/intl.dart';

class DateUtils {
  // 날짜 포맷팅 - 한국어 스타일
  static String formatDate(DateTime date) {
    return DateFormat('yyyy년 M월 d일').format(date);
  }

  // 시간 포맷팅
  static String formatTime(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime);
  }

  // 날짜 + 시간 포맷팅
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('M월 d일 HH:mm').format(dateTime);
  }

  // 오늘인지 확인
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  // 같은 날인지 확인
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // 하루의 시작 시간 (00:00:00)
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // 하루의 끝 시간 (23:59:59)
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  // 상대적 날짜 표시 (오늘, 내일, 어제 등)
  static String getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = startOfDay(now);
    final targetDate = startOfDay(date);

    final difference = targetDate.difference(today).inDays;

    if (difference == 0) {
      return '오늘';
    } else if (difference == 1) {
      return '내일';
    } else if (difference == -1) {
      return '어제';
    } else if (difference > 1) {
      return '${difference}일 후';
    } else {
      return '${-difference}일 전';
    }
  }
}