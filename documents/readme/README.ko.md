# 🎙️ Readio — 텍스트 음성 변환 스튜디오

<p align="center">
  <img src="../../assets/logo-readio.png" alt="Readio 로고" width="160"/>
</p>

<p align="center">
  <b>전문적인 텍스트 음성 변환 · 배경음악 · MP3/WAV 내보내기</b>
</p>

<p align="center">
  <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter"/>
  <img alt="Dart" src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart"/>
  <img alt="Android" src="https://img.shields.io/badge/Android-API%2024+-3DDC84?logo=android"/>
  <img alt="License" src="https://img.shields.io/badge/license-MIT-blue"/>
</p>

<p align="center">
  <a href="README.vi.md">🇻🇳 Tiếng Việt</a> ·
  <a href="../../README.md">🇺🇸 English</a> ·
  <a href="README.ja.md">🇯🇵 日本語</a> ·
  <a href="README.ko.md">🇰🇷 한국어</a> ·
  <a href="README.zh.md">🇨🇳 中文</a> ·
  <a href="README.fr.md">🇫🇷 Français</a> ·
  <a href="README.es.md">🇪🇸 Español</a> ·
  <a href="README.de.md">🇩🇪 Deutsch</a>
</p>

---

## ✨ 기능

### 🗣️ 텍스트 음성 변환 (TTS)
- 텍스트 자유 입력, **붙여넣기**, `.txt` 파일 불러오기, 또는 샘플 텍스트 사용
- 실시간 글자 수 카운트 및 예상 재생 시간 표시
- 언어별 음성 필터링 및 선택 — **국기 + 읽기 쉬운 이름**으로 표시
- 음성 설정: **성별, 스타일, 속도, 피치**
- 파일 생성 전 미리 듣기 (10~30초)
- 긴 텍스트를 550자 청크로 분할 — 버퍼 오버플로우 없음

### 🎵 배경음악 (BGM)
- 6개 기본 트랙: Asphyxia, Beat 1, Illusionary Daytime, Paris, Shiverr, Time Back
- **로컬 파일** 또는 **URL 다운로드**로 음악 추가 (끊김 없는 재생을 위해 로컬 저장)
- 메인 화면의 토글 스위치로 BGM 켜기/끄기
- 기본 BGM 볼륨 **30%**, 최대 **80%**
- 재생 모드: **한 곡 반복 / 전체 반복 / 순서 재생 후 정지**
- 트랙 건너뛰기 (회색 표시) 또는 사용자 추가 트랙 삭제

### 📁 내보내기
- 만들기 화면에서 **MP3** 또는 **WAV** 형식 선택
- **FFmpeg**으로 BGM을 내보내기 파일에 믹스
- 텍스트의 **첫 30자**로 파일명 자동 생성
- **애니메이션 진행 링** 및 **완료 %** 표시가 있는 전체 화면 오버레이
- **취소 버튼** — 즉시 중지 및 임시 파일 롤백
- `/storage/emulated/0/copecute/readio/`에 저장 (Android)

### 🎚️ 프리셋
- 음성 설정 (속도, 피치, 음성)을 프리셋으로 저장
- 기본 프리셋: 일반, 오디오북, 팟캐스트
- 한 번의 탭으로 프리셋 적용

### 📚 기록
- 생성된 모든 파일을 폴더 경로와 함께 저장
- 파일명 또는 텍스트 내용으로 검색
- 진행 바와 파형 애니메이션이 있는 **인라인 재생**
- 기록에서 공유 또는 삭제
- 메타데이터: 음성, 파일 크기, 생성 날짜

### ⚙️ 설정
- 국기 그리드 인터페이스로 **UI 언어** (8개 언어) 선택
- 테마: **시스템 / 라이트 / 다크**
- **TTS 엔진** (예: Google TTS) 선택 및 음성 목록 새로 고침
- 오디오 출력 폴더 관리, 경로 빠른 복사

### 🌍 다국어 지원
**8개 UI 언어** 지원:
🇻🇳 베트남어 · 🇺🇸 영어 · 🇯🇵 일본어 · 🇰🇷 한국어 · 🇨🇳 중국어 · 🇫🇷 프랑스어 · 🇪🇸 스페인어 · 🇩🇪 독일어

### 🎨 UX / UI
- 딥 네이비에 정제된 티얼 악센트의 다크 모드
- 생성 중 전체 화면 오버레이 — 부드러운 애니메이션 진행 링
- **완전 오프라인** — 인터넷 연결 불필요

---

## 📱 스크린샷

<p align="center">
  <img src="https://i.imgur.com/wrcop0w.jpeg" alt="만들기 화면" width="22%"/>
  &nbsp;
  <img src="https://i.imgur.com/l00Rw50.jpeg" alt="생성 중 (81%)" width="22%"/>
  &nbsp;
  <img src="https://i.imgur.com/vVt0X26.jpeg" alt="기록 화면" width="22%"/>
  &nbsp;
  <img src="https://i.imgur.com/wTLSYk5.jpeg" alt="설정 화면" width="22%"/>
</p>

<p align="center">
  <em>음성 만들기</em>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <em>생성 중 (81%)</em>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <em>기록</em>
  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  <em>설정</em>
</p>

---

## 🚀 설치 & 빌드

### 요구 사항
- Flutter SDK ≥ 3.13
- Android SDK API 24+ (Android 7.0 Nougat)
- Java 17+

### 클론 & 실행
```bash
git clone https://github.com/copecute/readio.git
cd readio
flutter pub get
flutter run
```

### APK 빌드
```bash
# 디버그
flutter build apk --debug

# 릴리즈
flutter build apk --release
```

출력 APK: `build/app/outputs/flutter-apk/`

---

## 📦 주요 의존성

| 패키지 | 용도 |
|---|---|
| `flutter_tts` | Android TTS 엔진 |
| `ffmpeg_kit_flutter_new` | 내보내기 파일에 BGM 믹스 |
| `audioplayers` | BGM 재생 + 음성 미리 듣기 |
| `file_picker` | 로컬 음악 파일 선택 |
| `share_plus` | 파일 공유 |
| `path_provider` | 임시 파일 경로 |
| `shared_preferences` | 설정·기록·프리셋 저장 |

---

## 📄 라이선스

MIT © 2026 [copecute](https://github.com/copecute)
