# RunCoach 🏃‍♂️

RunCoach는 개인 러닝 데이터를 수동으로 기록하거나 가짜 Strava 데이터를 연동해 통합 관리하고 분석할 수 있는 Flutter 애플리케이션입니다. 분석 결과에 따라 규칙 기반으로 다음 러닝 플랜을 추천합니다.

## 기술 스택
- **Framework**: Flutter (Material 3)
- **Language**: Dart
- **Storage**: SharedPreferences (로컬 데이터 영속성)
- **State Management**: Stateful widgets & callbacks

## 주요 기능
1. **홈 요약**: 주간 누적 거리, 총 러닝 횟수, 평균 페이스, Streak 현황을 확인하고 수동 기록과 Mock Strava 기록의 세부 지표를 바로 모니터링합니다.
2. **활동 입력 및 연동**: 
   - **수동 입력**: 날짜, 거리, 시간, 컨디션, 메모 기록 기능 제공.
   - **Mock Strava 연동**: 가짜 Strava JSON 데이터를 읽어와 로컬 기록에 중복 없이(ID 체크) 병합합니다. 실제 Strava 연동으로 용이하게 확장할 수 있는 구조입니다.
3. **기록 조회 및 삭제**: 모든 기록을 최신순으로 정렬해서 보고 기록별 출처(Manual / Mock Strava) 배지를 확인할 수 있습니다. 개별 삭제 시 확인 다이얼로그를 제공합니다.
4. **분석 리포트 및 AI 추천**: 
   - 모든 활동 데이터를 집계해 가장 긴 러닝, 가장 빠른 페이스 등의 세부 리포트를 제공합니다.
   - 누적된 사용자의 페이스와 컨디션 변화, 연속 훈련(Streak)을 종합하여 개인화된 **규칙 기반 다음 러닝 플랜**을 매치해 추천합니다.

## 규칙 기반 다음 러닝 추천 로직
1. 기록이 없는 상태: **Easy Run 3km** 추천
2. 이번 주 누적 거리가 20km 이상인 상태: 회복을 위한 **Recovery Run 3km** 추천
3. 최근 3회 기록 중 컨디션 '힘듦'이 2회 이상 발생 시: **Recovery Run 3km** 추천
4. 최근 평균 페이스가 7분/km보다 느릴 시: 기초 증진을 위한 **Easy Run 3km** 추천
5. 최근 평균 페이스가 6분/km 이하이고 주간 거리가 20km 미만일 시: 강도 높은 **Tempo Run 4km** 추천
6. 현재 연속 러닝 streak가 3일 이상일 시: 무리 방지용 **Easy Run 3km** 추천
7. 그 외 기본 상태: **Easy Run 4km** 추천

---

## 프로젝트 자동화 스크립트 (Shell Scripts)
프로젝트 루트 폴더의 `scripts/` 디렉터리에 다양한 유틸리티 스크립트가 구성되어 있습니다.

- **`./scripts/setup.sh`**:
  - `reports/` 및 `backups/` 폴더를 생성하고 `flutter pub get`을 수행하여 빌드 환경을 구축합니다.
- **`./scripts/generate_mock_strava.sh`**:
  - `runcoach_flutter/assets/mock_strava_runs.json` 가짜 데이터 리스트를 자동 생성합니다.
- **`./scripts/run_check.sh`**:
  - 코드의 문제를 검사하는 `flutter analyze`와 테스트 케이스인 `flutter test`를 차례로 구동하여 그 로그를 `reports/check_result.txt`에 기록합니다.
- **`./scripts/weekly_report.sh`**:
  - Mock Strava JSON 데이터를 분석하여 통계를 계산하고 가독성 좋은 `reports/weekly_report.md` 리포트 파일로 추출합니다.
- **`./scripts/backup_project.sh`**:
  - 현재 코딩 자산(`lib/`, `assets/`, `pubspec.yaml`, `README.md`)을 타임스탬프가 지정된 zip 파일 형식으로 `backups/` 폴더에 백업합니다.

---

## 실행 및 검증 방법

### 1. 스크립트 권한 부여
```bash
chmod +x scripts/*.sh
```

### 2. 빌드 환경 설정 및 종속성 다운로드
```bash
./scripts/setup.sh
```

### 3. Mock Strava JSON 리스트 생성
```bash
./scripts/generate_mock_strava.sh
```

### 4. 앱 실행
```bash
cd runcoach_flutter
flutter run
```

### 5. 테스트 및 품질 검증
```bash
# 전체 정적분석 및 유닛테스트 자동화 실행
./scripts/run_check.sh
```

### 6. 통계 보고서 및 백업
```bash
# Mock Strava 주간 리포트 파일 생성
./scripts/weekly_report.sh

# 백업 zip 압축본 생성
./scripts/backup_project.sh
```
