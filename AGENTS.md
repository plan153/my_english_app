<!-- Parent: ../AGENTS.md -->
<!-- Generated: 2026-06-03 | Updated: 2026-06-06 -->

# my_english_app — PronouncePro

## Purpose
한국인 영어 초보자를 위한 듣기·발음 연습 앱. "입으로 익히는 진짜 영어".
하나의 문장을 **문장 / 청크 / 단어** 3단계 단위로 듣고(TTS) 따라 말하면(STT),
단어 단위로 정렬·채점하여 피드백을 준다. 학습 진행도(연속 학습·평균 점수)를 추적한다.

## 아키텍처

```
lib/
  main.dart            MaterialApp.router 진입점
  app/
    theme.dart         AppColors / AppTheme (다크 slate + Outfit)
    router.dart        go_router 라우트 (/, /practice, /progress, /admin)
  screens/
    home_screen.dart       홈: 브랜딩, 3단계 안내, 진행도 요약, CTA
    practice_screen.dart   연습: 문장/청크/단어 세그먼트 + 듣기/발음/채점
    progress_screen.dart   통계: 평균·최고·합격·단위별·최근 기록
    admin_screen.dart      문장 DB 관리 (추가/업로드/내보내기)
    widgets/               MicButton, ComparisonText
  services/
    tts_service.dart           Azure Neural TTS + flutter_tts 폴백
    speech_service.dart        speech_to_text + 데모 시뮬레이션
    sentence_storage_service.dart  문장 영속화 (shared_preferences)
    progress_service.dart      연습 기록·통계 (순수 집계 + 영속화)
    translation_service.dart   한/영 UI 문자열
    alignment_service.dart     엔진 패키지 어댑터 (얇은 래퍼)
    file_helper*.dart          조건부 import 파일 입출력 (web/io/stub)
packages/
  pronunciation_engine/    ← 재사용 가능한 순수 Dart 핵심 엔진 (별도 패키지)
```

## 재사용 핵심 엔진: `packages/pronunciation_engine`
Flutter 비의존 순수 Dart 패키지. 다른 앱에서 그대로 import 가능.
- `PronunciationScorer` — DP 정렬 + 점수 (string_similarity 기반)
- `FeedbackGenerator` — 한/영 자체 피드백 문구
- `TextNormalizer` — 텍스트 정규화/토큰화
- 모델: `PracticeSentence`, `PracticeLevel`, `AlignmentWord`, `WordStatus`, `PracticeResult`
- 인터페이스: `TtsEngine`, `SpeechRecognitionEngine` (구현은 앱이 주입)
- 테스트: `dart test` (정규화/채점/피드백/진행도 25개)

## For AI Agents

### Working In This Directory
- 의존성: `flutter pub get`
- 실행: `flutter run` (웹: `flutter run -d chrome`)
- 분석: `flutter analyze` (에러 0 유지)
- 앱 테스트: `flutter test test/`
- 엔진 테스트: `cd packages/pronunciation_engine && dart test`
- 웹 빌드: `flutter build web`

### 규칙
- 채점·정렬 로직은 **엔진 패키지**에만 둔다 (앱에서 중복 구현 금지).
- 새 화면 텍스트는 `TranslationService`의 `_ko`/`_en` 양쪽에 키 추가.
- 플랫폼 분기 파일 입출력은 `file_helper.dart` 조건부 import 패턴 사용.
- 권한: Android `RECORD_AUDIO`/`INTERNET`, iOS `NSMicrophone/NSSpeechRecognitionUsageDescription` 설정됨.

### 주의
- 위젯 테스트에서 `flutter_animate` 사용 화면은 `pumpAndSettle()`로 타이머 정리.
- `TtsService`에 Azure 키가 base64로 내장되어 있음 (koreacentral).

## Dependencies

### External
- `flutter_riverpod`은 사용하지 않음 (StatefulWidget + 정적 서비스).
- `go_router`, `google_fonts`, `flutter_animate` — UI/네비/타이포
- `speech_to_text`, `flutter_tts`, `audioplayers`, `permission_handler`, `http` — 음성
- `shared_preferences`, `file_picker` — 저장/관리
- `pronunciation_engine` (path) — 핵심 엔진

<!-- MANUAL: -->
