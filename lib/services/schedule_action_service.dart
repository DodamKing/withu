// lib/services/schedule_action_service.dart
import 'package:flutter/material.dart';
import '../models/schedule.dart';
import '../widgets/schedule_form_dialog.dart';
import 'firestore_service.dart';
import 'notification_service.dart';
import 'background_sync_service.dart';

class ScheduleActionService {
  static final FirestoreService _firestoreService = FirestoreService();
  static final NotificationService _notificationService = NotificationService();

  /// 🔧 일정 수정 (공통 메서드)
  static Future<void> editSchedule(
      BuildContext context,
      Schedule schedule,
      ) async {
    try {
      final editedSchedule = await showScheduleFormDialog(
        context: context,
        existingSchedule: schedule,
      );

      if (editedSchedule == null) return;

      // 일정 업데이트
      await _firestoreService.updateSchedule(schedule.id, editedSchedule);

      // 🔔 알림 처리
      await _handleNotificationUpdate(schedule, editedSchedule);

      // 🔄 조용한 백그라운드 동기화
      _silentBackgroundSync();

      // 성공 메시지
      _showSuccessSnackBar(
        context,
        '일정이 수정되었습니다!',
        icon: Icons.edit_rounded,
      );

    } catch (e) {
      _showErrorSnackBar(
        context,
        '일정 수정에 실패했습니다: $e',
      );
    }
  }

  /// 🗑️ 일정 삭제 (공통 메서드)
  static Future<void> deleteSchedule(
      BuildContext context,
      Schedule schedule,
      ) async {
    if (!_isContextValid(context)) return;

    // 삭제 확인 다이얼로그
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('일정 삭제'),
          ],
        ),
        content: Text(
          '"${schedule.title}" 일정을 삭제하시겠습니까?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              '취소',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('삭제'),
          ),
        ],
      ),
    );

    // 확인 후 context 재확인
    if (!_isContextValid(context) || shouldDelete != true) return;

    try {
      // 🔔 알림 취소 (있다면)
      if (schedule.hasNotification) {
        await _notificationService.cancelScheduleNotification(schedule);
      }

      // 일정 삭제
      await _firestoreService.deleteSchedule(schedule.id);

      // 🔄 조용한 백그라운드 동기화 (SnackBar 없음)
      _silentBackgroundSync();

      // 성공 메시지
      if (_isContextValid(context)) {
        _showSuccessSnackBar(
          context,
          '일정이 삭제되었습니다',
          icon: Icons.delete_outline,
          color: Color(0xFF6B7280),
        );
      }

    } catch (e) {
      if (_isContextValid(context)) {
        _showErrorSnackBar(
          context,
          '일정 삭제에 실패했습니다: $e',
        );
      }
    }
  }

  /// 📝 일정 추가 (main.dart에서 사용)
  static Future<void> addSchedule(
      BuildContext context,
      DateTime? selectedDate,
      ) async {
    if (!_isContextValid(context)) return;

    try {
      final newSchedule = await showScheduleFormDialog(
        context: context,
        selectedDate: selectedDate,
      );

      if (!_isContextValid(context) || newSchedule == null) return;

      // 일정 추가
      await _firestoreService.addSchedule(newSchedule);

      // 🔔 알림 예약 (설정되어 있다면)
      if (newSchedule.hasNotification) {
        final success = await _notificationService.scheduleNotification(newSchedule);

        if (_isContextValid(context)) {
          if (success) {
            _showSuccessSnackBar(
              context,
              '일정이 추가되고 알림이 설정되었습니다!',
              icon: Icons.add_circle_outline,
            );
          } else {
            _showSuccessSnackBar(
              context,
              '일정은 추가되었지만 알림 설정에 실패했습니다',
              icon: Icons.add_circle_outline,
            );
          }
        }
      } else {
        if (_isContextValid(context)) {
          _showSuccessSnackBar(
            context,
            '일정이 추가되었습니다!',
            icon: Icons.add_circle_outline,
          );
        }
      }

      // 🔄 조용한 백그라운드 동기화 (SnackBar 없음)
      _silentBackgroundSync();

    } catch (e) {
      if (_isContextValid(context)) {
        _showErrorSnackBar(
          context,
          '일정 추가에 실패했습니다: $e',
        );
      }
    }
  }

  /// 🔇 조용한 백그라운드 동기화 (SnackBar 없음)
  static void _silentBackgroundSync() {
    // 백그라운드에서 조용히 동기화 실행
    BackgroundSyncService.syncNow().then((_) {
      print('🔄 조용한 백그라운드 동기화 완료');
    }).catchError((e) {
      print('⚠️ 조용한 백그라운드 동기화 실패: $e');
    });
  }

  /// 🔔 알림 업데이트 처리 (내부 메서드)
  static Future<void> _handleNotificationUpdate(
      Schedule oldSchedule,
      Schedule newSchedule,
      ) async {
    try {
      // 기존 알림 취소
      if (oldSchedule.hasNotification) {
        await _notificationService.cancelScheduleNotification(oldSchedule);
      }

      // 새 알림 예약 (설정되어 있다면)
      if (newSchedule.hasNotification) {
        await _notificationService.scheduleNotification(newSchedule);
      }
    } catch (e) {
      print('⚠️ 알림 업데이트 실패: $e');
      // 알림 실패해도 일정 수정은 성공으로 처리
    }
  }

  /// 🔧 Context 유효성 검사 (개선된 버전)
  static bool _isContextValid(BuildContext context) {
    try {
      // 1. context가 null인지 확인
      if (context == null) return false;

      // 2. Element의 mounted 상태 확인
      final element = context as Element?;
      if (element == null) return false;

      // 3. Element가 active하고 mounted 상태인지 확인
      if (!element.mounted) return false;

      // 4. StatefulWidget의 경우 추가 확인
      if (element is StatefulElement) {
        final state = element.state;
        if (state == null || !state.mounted) return false;
      }

      // 5. ScaffoldMessenger 접근 가능한지 테스트
      try {
        ScaffoldMessenger.maybeOf(context);
        return true;
      } catch (e) {
        return false;
      }

    } catch (e) {
      return false;
    }
  }

  /// ✅ 성공 SnackBar (안전한 버전)
  static void _showSuccessSnackBar(
      BuildContext context,
      String message, {
        IconData icon = Icons.check_circle,
        Color color = const Color(0xFF10B981),
      }) {
    // 더 엄격한 context 검사
    if (!_isContextValid(context)) {
      print('⚠️ Context가 유효하지 않아 SnackBar 표시 생략: $message');
      return;
    }

    try {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) {
        print('⚠️ ScaffoldMessenger를 찾을 수 없어 SnackBar 표시 생략: $message');
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: color,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      print('⚠️ SnackBar 표시 중 오류: $e - 메시지: $message');
    }
  }

  /// ❌ 에러 SnackBar (안전한 버전)
  static void _showErrorSnackBar(
      BuildContext context,
      String message,
      ) {
    // 더 엄격한 context 검사
    if (!_isContextValid(context)) {
      print('⚠️ Context가 유효하지 않아 에러 SnackBar 표시 생략: $message');
      return;
    }

    try {
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) {
        print('⚠️ ScaffoldMessenger를 찾을 수 없어 에러 SnackBar 표시 생략: $message');
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFFEF4444),
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      print('⚠️ 에러 SnackBar 표시 중 오류: $e - 메시지: $message');
    }
  }

  /// 📊 일정 상태 정보 (디버그용)
  static Future<void> logScheduleStatus(Schedule schedule) async {
    print('📋 === 일정 상태 ===');
    print('제목: ${schedule.title}');
    print('ID: ${schedule.id}');
    print('알림 설정: ${schedule.hasNotification}');
    if (schedule.hasNotification) {
      print('알림 시간: ${schedule.notificationMinutes}분 전');
      print('알림 ID: ${schedule.notificationId}');
    }
    print('==================');
  }
}