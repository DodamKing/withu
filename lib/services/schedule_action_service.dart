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

  /// 🔧 일정 수정
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

      // 🔄 조용한 백그라운드 동기화 (완전히 조용하게)
      _trueSilentBackgroundSync();

      // 성공 메시지 (간단하게)
      _showSimpleSnackBar(context, '일정이 수정되었습니다!', Icons.edit_rounded);

    } catch (e) {
      _showSimpleSnackBar(context, '일정 수정에 실패했습니다', Icons.error_outline, Colors.red);
    }
  }

  /// 🗑️ 일정 삭제
  static Future<void> deleteSchedule(
      BuildContext context,
      Schedule schedule,
      ) async {
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

    if (shouldDelete != true) return;

    try {
      // 🔔 알림 취소 (있다면)
      if (schedule.hasNotification) {
        await _notificationService.cancelScheduleNotification(schedule);
      }

      // 일정 삭제
      await _firestoreService.deleteSchedule(schedule.id);

      // 🔄 조용한 백그라운드 동기화 (완전히 조용하게)
      _trueSilentBackgroundSync();

      // 성공 메시지 (간단하게)
      _showSimpleSnackBar(context, '일정이 삭제되었습니다', Icons.delete_outline);

    } catch (e) {
      _showSimpleSnackBar(context, '일정 삭제에 실패했습니다', Icons.error_outline, Colors.red);
    }
  }

  /// 📝 일정 추가
  static Future<void> addSchedule(
      BuildContext context,
      DateTime? selectedDate,
      ) async {
    try {
      final newSchedule = await showScheduleFormDialog(
        context: context,
        selectedDate: selectedDate,
      );

      if (newSchedule == null) return;

      // 일정 추가
      await _firestoreService.addSchedule(newSchedule);

      // 🔔 알림 예약 (설정되어 있다면)
      if (newSchedule.hasNotification) {
        final success = await _notificationService.scheduleNotification(newSchedule);

        if (success) {
          _showSimpleSnackBar(context, '일정이 추가되고 알림이 설정되었습니다!', Icons.add_circle_outline);
        } else {
          _showSimpleSnackBar(context, '일정은 추가되었지만 알림 설정에 실패했습니다', Icons.add_circle_outline);
        }
      } else {
        _showSimpleSnackBar(context, '일정이 추가되었습니다!', Icons.add_circle_outline);
      }

      // 🔄 조용한 백그라운드 동기화 (완전히 조용하게)
      _trueSilentBackgroundSync();

    } catch (e) {
      _showSimpleSnackBar(context, '일정 추가에 실패했습니다', Icons.error_outline, Colors.red);
    }
  }

  /// 🔇 진짜 조용한 백그라운드 동기화 (아무 메시지 없음)
  static void _trueSilentBackgroundSync() {
    // 백그라운드에서 조용히 동기화 실행 (아무 출력 없음)
    BackgroundSyncService.syncNow().catchError((e) {
      // 에러도 조용히 무시
    });
  }

  /// 🔔 알림 업데이트 처리
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
      // 알림 실패해도 일정 수정은 성공으로 처리
    }
  }

  /// 📱 간단한 SnackBar (Context 검증 최소화)
  static void _showSimpleSnackBar(
      BuildContext context,
      String message,
      IconData icon, [
        Color color = const Color(0xFF10B981),
      ]) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: color,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      // SnackBar 실패해도 조용히 무시
    }
  }
}