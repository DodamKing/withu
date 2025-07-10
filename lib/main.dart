import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/weekly_screen.dart';
import 'screens/notification_test_screen.dart';
import 'services/app_initialization_service.dart';
import 'services/background_sync_service.dart';
import 'services/schedule_action_service.dart';

// 🔔 전역 네비게이터 키 및 메인 화면 컨트롤러
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<_MainScreenState> mainScreenKey = GlobalKey<_MainScreenState>();

void main() async {
  // 🚀 통합 초기화 서비스로 모든 초기화 처리
  await AppInitializationService.initialize();

  runApp(WithUApp());
}

class WithUApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WithU - 둘만의 일정 공유',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,

      // 🇰🇷 한국어 지원
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
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
        cardTheme: CardTheme(
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF6366F1),
          foregroundColor: Colors.white,
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
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
  final GlobalKey<CalendarScreenState> _calendarKey = GlobalKey<CalendarScreenState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // 🔔 알림에서 호출할 수 있는 공개 메서드
  void navigateToCalendar() {
    setState(() {
      _selectedIndex = 1;
    });
  }

  // 🔄 앱 생명주기 관리
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        BackgroundSyncService.onAppResumed();
        break;
      case AppLifecycleState.paused:
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
      CalendarScreen(key: _calendarKey),
      WeeklyScreen(),
    ];

    return Scaffold(
      key: mainScreenKey,
      body: Stack(
        children: [
          _screens[_selectedIndex],

          // 🔧 디버그 모드 테스트 버튼
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
                  backgroundColor: Colors.red[400],
                  child: Icon(Icons.bug_report, size: 20),
                  tooltip: '알림 테스트',
                  heroTag: "debug_button",
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
            _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, '홈'),
            _buildNavItem(1, Icons.calendar_month_rounded, Icons.calendar_month_outlined, '달력'),
            _buildNavItem(2, Icons.calendar_view_week_rounded, Icons.calendar_view_week_outlined, '주간'),
          ],
        ),
      ),

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
          child: Icon(Icons.add_rounded, size: 28),
          heroTag: "main_fab",
        ),
      ),
    );
  }

  // 🎨 하단 네비게이션 아이템 생성 헬퍼
  BottomNavigationBarItem _buildNavItem(int index, IconData selectedIcon, IconData unselectedIcon, String label) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _selectedIndex == index
              ? Color(0xFF6366F1).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          _selectedIndex == index ? selectedIcon : unselectedIcon,
        ),
      ),
      label: label,
    );
  }

  // 🎯 일정 추가 다이얼로그
  void _showAddScheduleDialog() async {
    DateTime? selectedDate = _getSelectedDateForCurrentScreen();
    await ScheduleActionService.addSchedule(context, selectedDate);
  }

  DateTime? _getSelectedDateForCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return DateTime.now();
      case 1:
        final calendarState = _calendarKey.currentState;
        return calendarState?.selectedDay ?? DateTime.now();
      case 2:
        return DateTime.now();
      default:
        return DateTime.now();
    }
  }
}