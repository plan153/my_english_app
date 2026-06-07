# PronouncePro 변경 이력 (CHANGELOG)

영어 발음 연습을 정밀하게 도와주는 프리미엄 플러터(Flutter) 애플리케이션 **PronouncePro**의 버전별 업데이트 및 세부 패치 내역입니다.

---

## 🚀 버전별 업데이트 내역

### 🌐 v1.6.2 (Web Azure Speech SDK 및 아리아 고품질 뉴럴 음성 연동) - *최신*
* **CORS 우회 및 웹용 Azure SDK 통합**: 웹 브라우저에서 Azure REST API 호출 시 발생하는 CORS 문제를 근본적으로 해결하기 위해, WebSockets 통신을 사용하는 **공식 Microsoft Cognitive Services Speech SDK**를 웹 서비스 빌드에 완전 연동했습니다.
* **아리아(Aria) 등 고품질 뉴럴 TTS 웹 지원**: 이제 웹 브라우저(Chrome, Safari 등)에서도 로컬 음성(Samantha 등)의 쇳소리 나는 낡은 기계음 대신, 아리아(en-US-AriaNeural)와 같은 고품질 Azure Neural TTS 성우 발음을 끊김이나 CORS 차단 없이 실시간 스트리밍으로 들을 수 있습니다.
* **조건부 모듈 컴파일 구현 (`WebTtsHelper`)**: Dart의 조건부 컴파일(`export ... if (dart.library.html) ...`)을 활용하여 모바일 네이티브 빌드(iOS/Android)에 영향을 미치지 않고 웹 전용 SDK 자바스크립트 바인딩 및 함수(`playAzureTtsWeb`, `stopAzureTtsWeb`)를 안정적으로 구동시킵니다.

### 📱 v1.6.1 (iOS/Safari 오디오 엔진 언락 대응)
* **사용자 제스처 컨텍스트 오디오 언락 (`unlockAudioEngine`)**: iOS Safari 등 모바일 웹 환경의 오디오 자동 재생 차단(Autoplay Block) 정책에 맞춰 사용자의 명시적인 터치(홈 화면의 **오늘의 연습 시작** 버튼 및 연습 화면의 **듣기** 버튼) 시점에 빈 텍스트를 무음으로 즉시 재생하는 방식의 강제 오디오 엔진 활성화 기능을 도입했습니다.
* **비동기 지연으로 인한 블로킹 극복**: `speak` 전 비동기 초기화나 지연으로 발생할 수 있는 브라우저 터치 컨텍스트 유실 문제를 사전 강제 재생(Pre-play unlock)을 통해 안정적으로 해소했습니다.

### 🔊 v1.6.0 (TTS 재생 속도 조절 및 전체 앱 리디자인)
* **TTS 재생 속도 조절 슬라이더**: 설정(Settings) 창에서 원어민 음성 재생 속도를 `0.5배속 ~ 1.5배속` 범위(저장값 `0.25` ~ `0.75`, 기본 `0.5` = 1.0배속)로 조절할 수 있습니다.
* **다이나믹 SSML Prosody 적용**: Azure Neural TTS REST API 호출 시 `<prosody rate="X">` 실수 배율 필터를 동적으로 구성하여 고품질 뉴럴 음성 속도를 실시간으로 조절합니다. (배율 포맷을 percentage 대신 decimal multiplier로 표준화하여 relative 속도 왜곡 문제를 방지)
* **로컬 Fallback 속도 연동**: 로컬 재생 엔진(`flutter_tts`)의 `setSpeechRate`에도 선택된 속도 배율이 동적으로 적용되도록 연동하였습니다.
* **SharedPreferences 저장 지원**: 변경된 음성 속도(`tts_speech_rate`) 및 선택 성우(`tts_azure_voice`)를 로컬 브라우저/디바이스의 `SharedPreferences`에 지속 저장하여 앱 재부팅 후에도 유지됩니다.
* **전체 앱 아키텍처 리디자인 및 모듈화**: `my_english_app`으로 동기화되면서 홈 화면, 통계 화면, 라우터, 테마 등이 모듈화되고 `pronunciation_engine` 패키지가 별도 분리 패키지로 재구조화되었습니다.

### 💾 v1.5.0 (관리자 데이터베이스 업로드 및 번역 제어)
* **관리자 전용 화면 추가 (`admin_screen.dart`)**: 
  * 학습 문장 데이터베이스 로드/추가/삭제 및 다운로드 지원.
  * 로컬의 JSON 데이터베이스 파일을 업로드하여 문장 목록을 일괄 변경.
  * JSON 원문 텍스트를 직접 입력창에 붙여넣어 일괄 덮어쓰기 지원.
  * 현재 로드된 문장 목록을 브라우저를 통해 `sentences.json` 파일로 저장/백업.
* **로컬 스토리지 데이터 지속성**: `shared_preferences` 기반의 `SentenceStorageService`를 도입하여, 관리자가 업로드한 데이터셋이 앱 재시작 후에도 안전하게 유지되도록 구현.
* **뜻 보기/숨기기 기본 활성화**: 연습 문장 하단에 번역을 기본 노출하되, 이를 손쉽게 토글할 수 있는 `'뜻 숨기기'` / `'뜻 보기'` 토글을 추가하여 학습 몰입도 제어.
* **초과 단어 용어 현지화**: 잘못 발음된 삽입형 단어를 한글 모드일 때 `'➕ 초과 발음'`으로 명확하게 식별하도록 고도화.

### 🌐 v1.4.0 (다국어 다이내믹 지원)
* 한글/영어 화면 다이내믹 토글 지원 (`🇰🇷 한글` / `🇺🇸 ENG` 헤더 버튼).
* Levenshtein 정밀 교정 메시지 한국어 구조로 다이내믹 번역 변환.
* 발음 꼬리표(`🗣️ "..."`) 표시 시 글자 하단 높이를 일치시켜 정렬이 흐트러지지 않는 수평 기준선 유지 정렬 패치.

### 🔊 v1.3.0 (음성 합성 및 설정 패널)
* Azure Neural TTS 연동 및 성우 선택 기능 추가 (`Jenny`, `Guy`, `Aria` 등).
* 전체 듣기, 개별 청크 듣기, 집중 훈련 타겟 발음 듣기 컨트롤 지원.

### 🛠️ v1.2.0 (결과 집중 학습 기능)
* 결과 분석 카드 내 개별 단어 및 의미 청크(Chunk) 클릭 시, 해당 단어/구문만 따로 떼어 반복 훈련할 수 있는 "집중 연습 모드" 추가.
* 집중 연습 중인 단어나 구문만 민트색 하이라이트로 빛나도록 RichText 시각 효과 적용.
* 무반응 시 자동 녹음 정지 타임아웃을 1.5초로 줄이고 예외 정지 복구 로직 강화.

### 🚀 v1.0.0 (초기 릴리즈)
* 실시간 음성인식 엔진 및 DP 기반의 발음 매핑 비교 알고리즘 구축.
* 슬레이트 다크 테마 기반의 반응형 대시보드 인터페이스 디자인.

---

## 🛠️ 주요 아키텍처 및 핵심 모듈
* **재사용 핵심 엔진 (`packages/pronunciation_engine`)**: Flutter 비의존 순수 Dart 패키지. 채점 및 정렬 핵심 알고리즘, 모델 포함.
* **Azure Neural TTS & Local Fallback (`tts_service.dart`)**: Azure Speech SDK (Web) 및 REST API (Native)를 활용한 음성 서비스 + `flutter_tts` 로컬 폴백 지원.
