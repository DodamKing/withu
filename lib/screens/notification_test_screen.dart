import 'package:flutter/material.dart';
import 'dart:developer';
import '../services/notification_test_service.dart';

class NotificationTestScreen extends StatefulWidget {
  @override
  _NotificationTestScreenState createState() => _NotificationTestScreenState();
}

class _NotificationTestScreenState extends State<NotificationTestScreen> {
  bool _isInitialized = false;
  bool _hasPermissions = false;
  List<String> _testResults = [];

  @override
  void initState() {
    super.initState();
    _addResult('🚀 알림 테스트 화면 시작');
  }

  void _addResult(String result) {
    setState(() {
      _testResults.add('${DateTime.now().toString().substring(11, 19)} - $result');
    });
    log(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🔔 알림 테스트'),
        backgroundColor: Colors.indigo[100],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // 상태 표시
              _buildStatusCard(),
              SizedBox(height: 16),

              // 테스트 버튼들
              _buildTestButtons(),
              SizedBox(height: 16),

              // 결과 로그 (고정 높이)
              Container(
                height: 300, // 고정 높이 설정
                child: _buildResultsLog(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  _isInitialized ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: _isInitialized ? Colors.green : Colors.grey,
                ),
                SizedBox(width: 8),
                Text('알림 시스템 초기화'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _hasPermissions ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: _hasPermissions ? Colors.green : Colors.grey,
                ),
                SizedBox(width: 8),
                Text('권한 허용'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButtons() {
    return Column(
      children: [
        // 1단계: 초기화
        Card(
          child: Column(
            children: [
              ListTile(
                title: Text('1️⃣ 기본 설정', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _initializeNotifications,
                        icon: Icon(Icons.settings),
                        label: Text('초기화'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _checkPermissions,
                        icon: Icon(Icons.security),
                        label: Text('권한 확인'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 2단계: 즉시 테스트
        Card(
          child: Column(
            children: [
              ListTile(
                title: Text('2️⃣ 즉시 알림 테스트', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isInitialized ? _sendImmediateNotification : null,
                    icon: Icon(Icons.notifications_active),
                    label: Text('지금 알림 보내기'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 3단계: 예약 테스트
        Card(
          child: Column(
            children: [
              ListTile(
                title: Text('3️⃣ 예약 알림 테스트', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isInitialized ? _scheduleNotification : null,
                    icon: Icon(Icons.schedule),
                    label: Text('1분 후 알림 예약'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 4단계: 백그라운드 테스트
        Card(
          child: Column(
            children: [
              ListTile(
                title: Text('4️⃣ 백그라운드 테스트', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isInitialized ? _initializeWorkManager : null,
                        icon: Icon(Icons.work),
                        label: Text('WorkManager 설정'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isInitialized ? _scheduleBackgroundWork : null,
                        icon: Icon(Icons.timer),
                        label: Text('5분 후 작업'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 5단계: 관리
        Card(
          child: Column(
            children: [
              ListTile(
                title: Text('5️⃣ 관리', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _checkPendingNotifications,
                        icon: Icon(Icons.list),
                        label: Text('예약 목록'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _cancelAllNotifications,
                        icon: Icon(Icons.clear_all),
                        label: Text('모두 취소'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultsLog() {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.bug_report, color: Colors.indigo),
                SizedBox(width: 8),
                Text('테스트 로그', style: TextStyle(fontWeight: FontWeight.bold)),
                Spacer(),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _testResults.clear();
                    });
                  },
                  icon: Icon(Icons.clear),
                  tooltip: '로그 지우기',
                ),
              ],
            ),
          ),
          Container(
            height: 220, // 고정 높이
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: _testResults.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    _testResults[index],
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Colors.indigo[800],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  // 테스트 메서드들
  Future<void> _initializeNotifications() async {
    _addResult('⏳ 알림 시스템 초기화 중...');
    try {
      await NotificationTestService.initializeBasicNotifications();
      setState(() {
        _isInitialized = true;
      });
      _addResult('✅ 알림 시스템 초기화 성공');
    } catch (e) {
      _addResult('❌ 초기화 실패: $e');
    }
  }

  Future<void> _checkPermissions() async {
    _addResult('⏳ 권한 확인 중...');
    try {
      final hasPermissions = await NotificationTestService.checkAndRequestPermissions();
      setState(() {
        _hasPermissions = hasPermissions;
      });
      _addResult(hasPermissions ? '✅ 권한 허용됨' : '❌ 권한 거부됨');
    } catch (e) {
      _addResult('❌ 권한 확인 실패: $e');
    }
  }

  Future<void> _sendImmediateNotification() async {
    _addResult('⏳ 즉시 알림 전송 중...');
    try {
      await NotificationTestService.sendTestNotificationNow();
      _addResult('✅ 즉시 알림 전송 완료');
    } catch (e) {
      _addResult('❌ 즉시 알림 실패: $e');
    }
  }

  Future<void> _scheduleNotification() async {
    _addResult('⏳ 1분 후 알림 예약 중...');
    try {
      await NotificationTestService.scheduleTestNotificationIn1Minute();
      _addResult('✅ 1분 후 알림 예약 완료');
    } catch (e) {
      _addResult('❌ 예약 알림 실패: $e');
    }
  }

  Future<void> _initializeWorkManager() async {
    _addResult('⏳ WorkManager 초기화 중...');
    try {
      await NotificationTestService.initializeWorkManager();
      _addResult('✅ WorkManager 초기화 완료');
    } catch (e) {
      _addResult('❌ WorkManager 초기화 실패: $e');
    }
  }

  Future<void> _scheduleBackgroundWork() async {
    _addResult('⏳ 백그라운드 작업 예약 중...');
    try {
      await NotificationTestService.scheduleBackgroundWork();
      _addResult('✅ 5분 후 백그라운드 작업 예약 완료');
    } catch (e) {
      _addResult('❌ 백그라운드 작업 예약 실패: $e');
    }
  }

  Future<void> _checkPendingNotifications() async {
    _addResult('⏳ 예약된 알림 확인 중...');
    try {
      await NotificationTestService.checkPendingNotifications();
      _addResult('✅ 예약 목록 확인 완료 (로그 확인)');
    } catch (e) {
      _addResult('❌ 예약 목록 확인 실패: $e');
    }
  }

  Future<void> _cancelAllNotifications() async {
    _addResult('⏳ 모든 알림 취소 중...');
    try {
      await NotificationTestService.cancelAllNotifications();
      _addResult('✅ 모든 알림 및 작업 취소 완료');
    } catch (e) {
      _addResult('❌ 취소 실패: $e');
    }
  }
}