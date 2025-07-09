import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/weekly_screen.dart';
import 'screens/notification_test_screen.dart';
import 'services/notification_service.dart';
import 'services/background_sync_service.dart';
import 'services/schedule_action_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// 🔔 전역 네비게이터 키 및 메인 화면 컨트롤러 (알림 탭 처리용)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<_MainScreenState> mainScreenKey = GlobalKey<_MainScreenState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

  try {
    // 1. Firebase 초기화
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase 초기화 성공!');

    // 2. 🔔 알림 서비스 초기화 (탭 리스너 포함)
    await _setupNotificationService();
    print('🔔 알림 서비스 초기화 완료');

    // 3. 🔄 백그라운드 동기화 서비스 시작
    await BackgroundSyncService.startBackgroundSync();
    print('🔄 백그라운드 동기화 서비스 시작 완료');

  } catch (e) {
    print('❌ 초기화 실패: $e');
  }

  runApp(WithUApp());
}

// 🔔 알림 탭 처리 설정
Future<void> _setupNotificationTapHandler() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // 알림 탭 시 실행될 함수 설정
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      // 알림을 탭했을 때 실행
      await _handleNotificationTap(response);
    },
  );
}

// 🔔 통합된 알림 서비스 설정 (기존 initialize + 탭 리스너)
Future<void> _setupNotificationService() async {
  final notificationService = NotificationService();

  // 기본 초기화
  await notificationService.initialize();

  // 탭 리스너 추가 설정
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // 알림 탭 처리를 위한 재초기화
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      // 🔔 알림 탭 시 실행
      await _handleNotificationTap(response);
    },
  );
}

// 🔔 알림 탭 처리 함수
Future<void> _handleNotificationTap(NotificationResponse response) async {
  try {
    print('🔔 알림 탭됨: ${response.payload}');

    // 앱이 실행 중이면 캘린더로 이동
    final mainScreenState = mainScreenKey.currentState;
    if (mainScreenState != null) {
      // 캘린더 탭으로 이동 (인덱스 1)
      mainScreenState.navigateToCalendar();

      // payload에서 일정 정보 추출하여 특정 날짜로 이동 (추후 구현)
      final payload = response.payload;
      if (payload != null && payload.isNotEmpty) {
        // payload 형식: "schedule_id:일정제목"
        print('📅 일정 정보: $payload');
        // TODO: 특정 일정이 있는 날짜로 이동하는 기능 추가
      }
    } else {
      print('⚠️ MainScreen이 아직 초기화되지 않음');
    }

  } catch (e) {
    print('❌ 알림 탭 처리 실패: $e');
  }
}

class WithUApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WithU - 둘만의 일정 공유',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // 🔔 네비게이터 키 설정

      // 🇰🇷 한국어 지원 추가
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
      ],
      locale: Locale('ko', 'KR'),

      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,

        // 전체 색상 테마
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF6366F1), // 인디고 색상
          brightness: Brightness.light,
        ),

        // 앱바 테마
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF1F2937),
          titleTextStyle: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),

        // 카드 테마
        cardTheme: CardTheme(
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        ),

        // FAB 테마
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF6366F1),
          foregroundColor: Colors.white,
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // 하단 네비게이션 바 테마
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF6366F1),
          unselectedItemColor: Color(0xFF9CA3AF),
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
          type: BottomNavigationBarType.fixed,
          elevation: 20,
        ),
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;

  // 각 화면의 GlobalKey - 화면 상태에 접근하기 위해
  final GlobalKey<CalendarScreenState> _calendarKey = GlobalKey<CalendarScreenState>();

  @override
  void initState() {
    super.initState();
    // 🔄 앱 생명주기 관찰자 등록
    WidgetsBinding.instance.addObserver(this);

    // 🔔 전역에서 접근할 수 있도록 키 설정
    mainScreenKey.currentState != null ? null :
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // mainScreenKey에 현재 상태 연결은 StatefulWidget 특성상 자동으로 됨
    });
  }

  @override
  void dispose() {
    // 🔄 앱 생명주기 관찰자 해제
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 🔔 알림에서 호출할 수 있는 공개 메서드
  void navigateToCalendar() {
    setState(() {
      _selectedIndex = 1; // 캘린더 탭으로 이동
    });
  }

  // 🔔 특정 날짜의 캘린더로 이동 (추후 구현)
  void navigateToScheduleDate(DateTime date) {
    setState(() {
      _selectedIndex = 1; // 캘린더 탭으로 이동
    });

    // 캘린더에서 해당 날짜로 이동
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final calendarState = _calendarKey.currentState;
      if (calendarState != null) {
        // TODO: CalendarScreen에 날짜 이동 메서드 추가 필요
        // calendarState.moveToDate(date);
      }
    });
  }

  // 🔄 앱 생명주기 관리
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
      // 앱이 포그라운드로 올 때
        BackgroundSyncService.onAppResumed();
        break;
      case AppLifecycleState.paused:
      // 앱이 백그라운드로 갈 때
        BackgroundSyncService.onAppPaused();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      HomeScreen(),
      CalendarScreen(key: _calendarKey), // GlobalKey 추가
      WeeklyScreen(),
    ];

    return Scaffold(
      key: mainScreenKey, // 🔔 전역 접근용 키 설정
      body: Stack(
        children: [
          // 기존 화면들
          _screens[_selectedIndex],

          // 🔧 디버그 모드에서만 보이는 테스트 버튼 (우상단 고정)
          if (kDebugMode)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 16,
              child: SafeArea(
                child: FloatingActionButton.small(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NotificationTestScreen(),
                      ),
                    );
                  },
                  backgroundColor: Colors.red[400], // 눈에 잘 띄게 빨간색
                  child: Icon(Icons.bug_report, size: 20),
                  tooltip: '알림 테스트',
                  heroTag: "debug_button", // 충돌 방지
                ),
              ),
            ),
        ],
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedIndex == 0
                      ? Color(0xFF6366F1).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _selectedIndex == 0
                      ? Icons.home_rounded
                      : Icons.home_outlined,
                ),
              ),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedIndex == 1
                      ? Color(0xFF6366F1).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _selectedIndex == 1
                      ? Icons.calendar_month_rounded
                      : Icons.calendar_month_outlined,
                ),
              ),
              label: '달력',
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _selectedIndex == 2
                      ? Color(0xFF6366F1).withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _selectedIndex == 2
                      ? Icons.calendar_view_week_rounded
                      : Icons.calendar_view_week_outlined,
                ),
              ),
              label: '주간',
            ),
          ],
        ),
      ),

      // 🎯 스마트 FAB - ScheduleActionService 사용
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showAddScheduleDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(
            Icons.add_rounded,
            size: 28,
          ),
          heroTag: "main_fab", // 충돌 방지
        ),
      ),
    );
  }

  // 🔧 간단해진 일정 추가 메서드 - ScheduleActionService 사용
  void _showAddScheduleDialog() async {
    // 현재 화면에 따라 다른 기본 날짜 설정
    DateTime? selectedDate = _getSelectedDateForCurrentScreen();

    // 🎯 ScheduleActionService 사용 - 모든 처리를 한 번에!
    await ScheduleActionService.addSchedule(context, selectedDate);
  }

  DateTime? _getSelectedDateForCurrentScreen() {
    switch (_selectedIndex) {
      case 0: // 홈 화면
        return DateTime.now(); // 기본값: 오늘

      case 1: // 달력 화면
      // 달력에서 선택된 날짜 가져오기
        final calendarState = _calendarKey.currentState;
        if (calendarState != null) {
          return calendarState.selectedDay ?? DateTime.now();
        }
        return DateTime.now();

      case 2: // 주간 화면
        return DateTime.now(); // 주간뷰는 추후 구현

      default:
        return DateTime.now();
    }
  }
}