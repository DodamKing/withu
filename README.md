# WithU - 둘만의 일정 공유 앱

## 주요 기능
- 📱 3개 탭 구조 (홈/달력/주간)
- ⏰ 하루종일/시간 일정 지원
- 🔄 실시간 동기화
- ✨ 모던한 UI/UX

## 기술 스택
- Flutter + Firebase Firestore
- Material 3 디자인

# 📱 WithU - 둘만의 일정 공유 앱 (완성 문서)

## 🎯 프로젝트 개요

**WithU**는 두 사람이 일정을 공유하고 조율할 수 있는 Flutter 기반 모바일 앱입니다.

- **목적**: 스케줄 조율 최적화, 겹치는 시간 파악, 빈 시간 찾기
- **사용자**: 커플, 가족, 친구 등 2인 그룹
- **플랫폼**: Android (iOS 확장 가능)

---

## 🏗️ 완성된 프로젝트 구조

```
lib/
├── main.dart                     # 앱 진입점 + 하단 탭바 관리
├── models/
│   └── schedule.dart            # 일정 데이터 모델 (하루종일, 시작/종료 시간)
├── services/
│   └── firestore_service.dart   # Firebase CRUD + 고급 쿼리
├── screens/
│   ├── home_screen.dart         # 홈: 오늘 일정 + 내일 미리보기
│   ├── calendar_screen.dart     # 달력: 월별 달력 + 일정 관리
│   └── weekly_screen.dart       # 주간: 타임라인 뷰 (조율 핵심)
├── widgets/
│   ├── schedule_tile.dart       # 일정 카드 (스마트 아이콘 + 배지)
│   ├── schedule_form_dialog.dart # 일정 추가/수정 폼
│   └── schedule_detail_sheet.dart # 일정 상세 바텀시트
└── utils/
    └── date_utils.dart          # 날짜 관련 유틸리티
```

---

## ✨ 완성된 주요 기능

### 📱 **UI/UX**
- **3개 탭 구조**: 홈/달력/주간뷰
- **하단 네비게이션**: 모든 화면에서 접근 가능
- **모던 디자인**: 그라데이션 + 3D 그림자 + 둥근 모서리
- **반응형 아이콘**: 선택 시 filled/outlined 자동 변경

### 📅 **일정 관리**
- **하루종일 일정**: 토글로 시간 입력 생략 가능
- **시간 범위**: 시작시간 - 종료시간 (예: 09:00 - 10:30)
- **다음날 지원**: 23:00 - 02:00 같은 형태 가능
- **스마트 시간 조정**: 시작 > 종료 시 자동 보정

### 🎨 **스마트 UI 요소**
- **아이콘 자동 선택**: 제목에 따라 회의, 식사, 운동 등 아이콘
- **상태 배지**:
    - 하루종일 (보라색)
    - 오늘 (녹색)
    - 진행중 (빨간색 + 점멸)
- **터치 플로우**: 일정 클릭 → 바텀시트 → 수정/삭제

### 🔄 **데이터 관리**
- **실시간 동기화**: Firebase Firestore StreamBuilder
- **CRUD 완성**: 추가/조회/수정/삭제
- **고급 쿼리**: 날짜별, 진행중, 하루종일 필터링

---

## 🔥 Firebase 설정

### **Firestore 구조**
```json
withu_schedules (컬렉션)
└── [자동생성ID] (문서)
    ├── title: "회의"
    ├── memo: "프로젝트 논의"
    ├── scheduled_at: Timestamp
    ├── end_time: Timestamp | null
    ├── is_all_day: boolean
    └── created_at: Timestamp
```

### **보안 규칙**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /withu_schedules/{document=**} {
      allow read, write: if true; // 개인용이므로 모든 접근 허용
    }
  }
}
```

---

## 📦 패키지 의존성

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.15.1
  cloud_firestore: ^4.8.5
  table_calendar: ^3.0.9
  intl: ^0.18.1
  provider: ^6.1.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0
```

---

## 🎯 각 화면별 상세 기능

### 🏠 **홈 화면 (HomeScreen)**
- **오늘 일정 요약**: 개수 표시 + 리스트
- **내일 미리보기**: 일정이 있으면 알림 표시
- **빈 상태 UI**: 일정 없을 때 친화적 메시지
- **실시간 업데이트**: StreamBuilder로 즉시 반영

### 📅 **달력 화면 (CalendarScreen)**
- **월별 달력**: table_calendar 사용
- **일정 마커**: 해당 날짜에 점 표시
- **날짜 선택**: 클릭 시 해당 날짜 일정 표시
- **오늘 하이라이트**: 현재 날짜 강조
- **오늘로 이동**: 상단 버튼으로 빠른 이동

### 📊 **주간뷰 (WeeklyScreen)**
- **타임라인 형태**: 9시-22시 시간대별 표시
- **주간 네비게이션**: 이전/다음 주 이동
- **일정 시각화**: 파란색 블록으로 일정 표시
- **겹치는 시간 파악**: 한눈에 스케줄 조율 가능
- **하루종일 일정**: 모든 시간대에 표시

### 🎨 **일정 카드 (ScheduleTile)**
- **그라데이션 배경**: 오늘 일정은 특별 강조
- **스마트 아이콘**: 제목 키워드 기반 자동 선택
- **배지 시스템**: 상태에 따른 다양한 배지
- **터치 피드백**: InkWell로 부드러운 애니메이션

### 📝 **일정 추가 (ScheduleFormDialog)**
- **풀스크린 다이얼로그**: 큰 화면으로 편리한 입력
- **하루종일 토글**: 시간 필드 조건부 표시
- **시작/종료 시간**: 별도 picker로 정확한 입력
- **유효성 검증**: 시간 충돌 자동 보정

### 📋 **일정 상세 (ScheduleDetailSheet)**
- **상세 정보 표시**: 모든 일정 정보 + 상태 배지
- **수정/삭제 버튼**: 큰 버튼으로 명확한 액션
- **삭제 확인**: 안전한 2단계 삭제

---

## 🛠️ 개발 히스토리

### **1단계: Firebase 연동 (완료)**
- Firebase 프로젝트 생성
- FlutterFire CLI 설정
- Firestore 연결 테스트
- JDK/Gradle 호환성 문제 해결

### **2단계: 기본 구조 (완료)**
- Schedule 모델 생성
- FirestoreService CRUD
- 홈/달력 화면 기본 구현

### **3단계: UI 개선 (완료)**
- 모던 테마 적용 (인디고 색상 팔레트)
- 그라데이션 + 3D 효과
- 컴포넌트별 예쁜 디자인

### **4단계: 고급 기능 (완료)**
- 하루종일/시간 일정 지원
- Schedule 모델 확장 (endTime, isAllDay)
- 스마트 아이콘 + 배지 시스템

### **5단계: 탭 구조 (완료)**
- 하단 네비게이션 바 추가
- 주간뷰 화면 구현
- 모든 탭에서 FAB 통합

### **6단계: 수정/삭제 (완료)**
- 바텀시트 상세 화면
- 수정 기능 완성
- 안전한 삭제 시스템

---

## 🚀 빌드 & 배포

### **개발 환경**
```bash
flutter run  # 개발 서버
```

### **APK 빌드**
```bash
# 디버그 APK
flutter build apk --debug

# 릴리즈 APK  
flutter build apk --release
```

### **실제 기기 설치**
```bash
flutter install  # USB 연결된 기기에 설치
```

---

## 🔮 향후 확장 계획

### **우선순위 높음**
1. **알림 기능**
    - `flutter_local_notifications`
    - 일정 시작 전 알림
    - 맞춤 알림 시간 설정

2. **사용자 구분**
    - Firebase Auth 도입
    - 사용자별 색상 구분
    - 개인/공유 일정 분리

3. **빈 시간 찾기**
    - "언제 만날 수 있을까?" 기능
    - AI 추천 시간대
    - 충돌 시간 알림

### **우선순위 중간**
1. **반복 일정**
    - 매일/매주/매월 반복
    - 반복 패턴 설정
    - 예외 날짜 처리

2. **일정 템플릿**
    - 자주 쓰는 일정 저장
    - 빠른 일정 추가
    - 카테고리 분류

3. **위젯 지원**
    - 홈스크린 위젯
    - 오늘 일정 미리보기
    - 빠른 일정 추가

### **우선순위 낮음**
1. **백업/동기화**
    - Google Drive 백업
    - 다른 캘린더 앱 연동
    - 데이터 내보내기

2. **고급 UI**
    - 다크모드 지원
    - 테마 커스터마이징
    - 애니메이션 강화

3. **통계 기능**
    - 일정 패턴 분석
    - 시간 사용 통계
    - 생산성 지표

---

## 📂 핵심 코드 스니펫

### **Firebase 초기화**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(WithUApp());
}
```

### **실시간 일정 조회**
```dart
Stream<List<Schedule>> getSchedulesByDate(DateTime date) {
  return _firestore
      .collection('withu_schedules')
      .where('scheduled_at', isGreaterThanOrEqualTo: startOfDay)
      .where('scheduled_at', isLessThanOrEqualTo: endOfDay)
      .orderBy('scheduled_at')
      .snapshots()
      .map((snapshot) => /* 변환 로직 */);
}
```

### **하루종일 일정 처리**
```dart
String get timeText {
  if (isAllDay) return '하루종일';
  
  final start = '${scheduledAt.hour:02d}:${scheduledAt.minute:02d}';
  if (endTime != null) {
    final end = '${endTime!.hour:02d}:${endTime!.minute:02d}';
    return '$start - $end';
  }
  return start;
}
```

---

## 🐛 알려진 이슈 & 해결방법

### **Firebase 연결 문제**
- **증상**: `PlatformException(channel-error)`
- **해결**: JDK 버전 통일 (Android Studio JDK 사용)
- **설정**: `gradle.properties`에 JDK 경로 명시

### **Gradle 버전 충돌**
- **증상**: `class file major version` 에러
- **해결**: Gradle 8.0 이상 사용
- **설정**: `gradle-wrapper.properties` 수정

### **빌드 최적화**
- **문제**: 빌드 시간 길어짐
- **해결**: `flutter clean` 주기적 실행
- **팁**: 개발 시 hot reload 활용

---

## 📞 문제 해결 가이드

### **개발 환경 문제**
1. `flutter doctor` 실행하여 환경 확인
2. Android SDK 최신 버전 확인
3. Firebase CLI 재설치

### **Firebase 연결 문제**
1. `google-services.json` 파일 위치 확인
2. 패키지명 일치 여부 확인
3. Firestore 보안 규칙 확인

### **빌드 문제**
1. `flutter clean && flutter pub get`
2. Gradle 캐시 삭제
3. JDK 버전 확인

---

## 🎉 개발 완료 상태

**개발 기간**: 2025년 7월 3일
**개발자**: Claude & 사용자 협업
**개발 환경**: Flutter 3.24.4, Firebase Firestore
**완성도**: 1차 MVP 완료 (100%)

**다음 개발 재개 시**: 이 문서를 참고하여 향후 확장 계획부터 진행

---

> 💡 **Tip**: 이 문서는 개발 재개 시 빠른 컨텍스트 파악을 위해 작성되었습니다. 각 섹션의 코드와 설명을 참고하여 기능을 확장해보세요!