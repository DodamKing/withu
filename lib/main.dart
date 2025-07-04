import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/weekly_screen.dart';
import 'widgets/schedule_form_dialog.dart';
import 'services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase 초기화 성공!');
  } catch (e) {
    print('❌ Firebase 초기화 실패: $e');
  }

  runApp(WithUApp());
}

class WithUApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WithU - 둘만의 일정 공유',
      debugShowCheckedModeBanner: false,

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

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final FirestoreService _firestoreService = FirestoreService();

  // 각 화면의 GlobalKey - 화면 상태에 접근하기 위해
  final GlobalKey<CalendarScreenState> _calendarKey = GlobalKey<CalendarScreenState>();

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      HomeScreen(),
      CalendarScreen(key: _calendarKey), // GlobalKey 추가
      WeeklyScreen(),
    ];

    return Scaffold(
      body: _screens[_selectedIndex],
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

      // 🎯 스마트 FAB - 화면별 맞춤 동작
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
        ),
      ),
    );
  }

  // 🎯 스마트 일정 추가 다이얼로그
  void _showAddScheduleDialog() async {
    // 현재 화면에 따라 다른 기본 날짜 설정
    DateTime? selectedDate = _getSelectedDateForCurrentScreen();

    final schedule = await showScheduleFormDialog(
      context: context,
      selectedDate: selectedDate,
    );

    if (schedule != null) {
      try {
        // 수정 모드인지 새 일정인지 구분
        if (schedule.id.isNotEmpty) {
          // 수정 모드
          await _firestoreService.updateSchedule(schedule.id, schedule);
        } else {
          // 새 일정 추가
          await _firestoreService.addSchedule(schedule);
        }

        // 화면별 맞춤 성공 메시지
        _showSuccessMessage();

      } catch (e) {
        // 오류 메시지
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('일정 처리에 실패했습니다: $e'),
                ),
              ],
            ),
            backgroundColor: Color(0xFFEF4444),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  // 🎯 현재 화면에 맞는 선택된 날짜 가져오기
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

  // 🎯 화면별 맞춤 성공 메시지
  void _showSuccessMessage() {
    String message = '일정이 추가되었습니다!';
    String actionText = '확인';
    VoidCallback? onAction;

    switch (_selectedIndex) {
      case 0: // 홈 화면
        message = '일정이 추가되었습니다!';
        actionText = '달력 보기';
        onAction = () {
          setState(() {
            _selectedIndex = 1; // 달력 탭으로 이동
          });
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        };
        break;

      case 1: // 달력 화면
        message = '선택한 날짜에 일정이 추가되었습니다!';
        actionText = '확인';
        // 달력 화면에서는 이미 해당 날짜에 있으므로 특별한 액션 없음
        break;

      case 2: // 주간 화면
        message = '일정이 추가되었습니다!';
        actionText = '새로고침';
        // 주간뷰 새로고침 로직 (추후 구현)
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
            if (onAction != null)
              TextButton(
                onPressed: onAction,
                child: Text(
                  actionText,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}