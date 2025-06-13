````markdown
# Barrier Free Bank (BFBANK)

> **Copy‑paste ready.** Plain Markdown + minimal HTML only. English is expanded by default; Korean can be toggled via `<details>`.

---

<details open>
<summary><strong>🇬🇧 English</strong></summary>

### ⚠️ Project Migration Notice
This project was originally built with **React Native**. However, running **YOLO** fully on‑device required writing *all* image pre‑processing and post‑processing logic by hand in React Native. Considering maintenance and performance, migrating the entire codebase to **Flutter** was the most pragmatic solution.

---

#### Features
- Real‑time object detection (YOLO)  
- Live camera preview  
- Object cropping & gallery  
- Clean architecture (presentation / service / utility)

#### Getting Started

```bash
# 1 Clone
$ git clone <repository-url>
$ cd bfbank

# 2 Install dependencies
$ flutter pub get

# 3 Add models (.tflite / .onnx)
#   assets/                 – default models
#   android/.../assets/     – Android‑specific large models

# 4 Run
$ flutter run
````

#### Project Structure

```
lib/
├── features/
│   └── object_detection/
│       └── presentation/
│           └── pages/
└── services/
    ├── coordinate_transformer.dart
    ├── image_processing_service.dart
    ├── object_crop_service.dart
    └── gallery_service.dart
```

#### Architecture Layers

* **Presentation** — Widgets, pages, state
* **Service** — Business logic, inference, data
* **Utility** — Pure helpers / transforms

#### Development Roadmap (2025)

| Date   | Task                                    |
| ------ | --------------------------------------- |
| Jun 15 | Send cropped images to OCR model        |
| Jun 16 | Migrate base screens (RN → Flutter)     |
| Jun 17 | Continue screen migration               |
| Jun 18 | Continue screen migration               |
| Jun 19 | Pre‑crop ONNX upscaling experiment      |
| Jun 20 | Continue upscaling work                 |
| Jun 21 | Decide keep/drop upscaling & tidy files |
| Jun 22 | Performance evaluation                  |
| Jun 23 | Migration complete                      |

#### Security & Privacy

We treat model integrity and user data with the utmost care:

* **No weights or datasets** live in this repo. Provision them locally or through a secure CI secret store.
* **Environment files** (`*.env`) and API keys are `.gitignore`d. Never commit secrets.
* **Git hooks** (git‑secrets) prevent accidental secret pushes.
* Release builds should encrypt models with TensorFlow Lite metadata encryption (or equivalent).
* If a leak is suspected, rotate the key immediately and open an internal security ticket.

#### Contributing

1 Fork → 2 Branch → 3 Code → 4 Test → 5 PR

#### License

© 2025 Barrier Free Bank. All rights reserved. This repository is private and not licensed for public use.

</details>

---

<details>
<summary><strong>🇰🇷 한국어</strong></summary>

### ⚠️ 프로젝트 마이그레이션 안내

이 프로젝트는 처음에 **React Native**로 개발되었습니다. 그러나 온디바이스에서 **YOLO**를 안정적으로 실행하려면 모든 전·후처리 과정을 직접 구현해야 했고, 이는 유지보수와 성능 면에서 부담이 컸습니다. 더 효율적이고 일관된 개발 환경을 위해 전체 코드를 **Flutter**로 새로 작성했습니다.

---

#### 주요 기능

* YOLO 기반 실시간 객체 탐지
* 카메라 라이브 프리뷰
* 객체 크롭 및 갤러리
* 클린 아키텍처 (Presentation / Service / Utility)

#### 시작하기

```bash
# 1 클론
$ git clone <repository-url>
$ cd bfbank

# 2 의존성 설치
$ flutter pub get

# 3 모델 추가 (.tflite / .onnx)
#   assets/                 – 기본 모델
#   android/.../assets/     – Android 전용 대용량 모델

# 4 실행
$ flutter run
```

#### 프로젝트 구조

```
lib/
├── features/
│   └── object_detection/
│       └── presentation/
│           └── pages/
└── services/
    ├── coordinate_transformer.dart
    ├── image_processing_service.dart
    ├── object_crop_service.dart
    └── gallery_service.dart
```

#### 아키텍처 레이어

* **Presentation** — UI·상태 관리
* **Service** — 비즈니스 로직·추론·데이터
* **Utility** — 헬퍼·변환 함수

#### 개발 일정 (2025)

| 날짜     | 작업                       |
| ------ | ------------------------ |
| 6월 15일 | OCR 모델로 크롭한 이미지 전송       |
| 6월 16일 | RN 기본 화면 Flutter로 마이그레이션 |
| 6월 17일 | 화면 마이그레이션 지속             |
| 6월 18일 | 화면 마이그레이션 지속             |
| 6월 19일 | 크롭 전 ONNX 업스케일링 시도       |
| 6월 20일 | 업스케일링 작업 지속              |
| 6월 21일 | 업스케일링 유지/제외 결정·파일 정리     |
| 6월 22일 | 성능 평가                    |
| 6월 23일 | 마이그레이션 완료                |

#### 보안 및 개인정보 보호

모델과 사용자 데이터를 안전하게 지키기 위해 다음 원칙을 준수합니다.

1. **모델 가중치와 데이터셋**은 저장소에 포함하지 않습니다. 필요한 경우 로컬 환경이나 보안된 CI 비밀 저장소를 통해 제공합니다.
2. **환경 변수(`*.env`)와 API 키** 등 민감 정보는 `.gitignore`에 등록해 원격 저장소에 노출되지 않도록 합니다.
3. 커밋 시 **git‑secrets** 훅이 비밀 정보 유출 여부를 자동으로 확인합니다.
4. 배포 빌드에는 TFLite 메타데이터 암호화 등 적절한 방법을 적용해 모델 파일을 보호합니다.

#### 컨트리뷰션

1 포크 → 2 브랜치 → 3 코드 → 4 테스트 → 5 PR

#### 라이선스

© 2025 Barrier Free Bank. 모든 권리 보유. 본 저장소는 비공개이며 외부 사용이 허가되지 않습니다.

</details>
```
