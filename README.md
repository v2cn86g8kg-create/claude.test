# Snowboard Rush (Prototype)

끊임없이 내려가는 스노우보드 러너 게임의 iOS 프로토타입입니다. SwiftUI + SpriteKit으로 만들어졌고,
`SnowboardGame.xcodeproj`를 Xcode(15 이상 권장, iOS 16+ 타겟)로 열면 바로 시뮬레이터에서 실행할 수 있습니다.

Mac 없이 실기기(iPhone)에서 플레이하고 싶다면 [SIDELOAD.md](SIDELOAD.md)를 참고하세요 — GitHub
Actions가 자동으로 `.ipa`를 빌드해주고, Windows PC + 무료 Apple ID로 사이드로딩하는 방법을 정리해뒀습니다.
TestFlight로 배포하려면 [TESTFLIGHT.md](TESTFLIGHT.md)를 참고하세요.

## 지금 구현된 것

- **흐름**: 로딩 화면 → 대기실(설정/상점 버튼, 게임 시작) → 게임.
- **끊임없는 하강**: 캐릭터가 자동으로 언덕을 타고 내려가며, 거리에 따라 점점 속도가 빨라집니다. 속도가
  붙을수록 캐릭터가 화면 왼쪽에서 정중앙으로 서서히 이동합니다.
- **거리/최고기록/트릭점수**: 화면 상단에 거리(중앙), 최고기록(좌측), 트릭 점수(우측)가 표시됩니다.
- **디오라마 배경**: 원경/중경/근경 3겹의 산 실루엣이 서로 다른 속도로 스크롤되는 패럴랙스 배경. 폰을
  좌우로 기울이면(자이로) 배경이 살짝 더 움직여 입체감을 더합니다.
- **에어(점프)**: 지형의 경사가 급격히 떨어지는 구간에서 자동으로 공중에 뜹니다. 급강하 구간 직전에는
  경고용 레일이 표시됩니다.
- **트릭 콤보**: 공중에서 자유롭게 탭 → 화면 하단 타이밍 바로 판정(퍼펙트/그레잇/굿/미스). 성공하면
  그랩 → 스핀 → 백플립 순서로 다음 트릭 진행, 미스면 그때까지 딴 점수만 남기고 콤보 종료.
- **게임 오버**: 장애물은 없습니다. 트릭 회전이 다 끝나지 않은 채로(보드가 수평으로 돌아오기 전에)
  착지하면 보드 대신 몸이 땅에 닿아 게임 오버됩니다. 트릭을 시도하지 않았다면 보통 안전하게 착지합니다.
- **이어하기**: 게임 오버 시 하루 1번 무료로(그 이후엔 광고 시청 후) 죽은 자리에서 바로 이어할 수
  있습니다. 광고는 실제 SDK 없이 테스트용 모의 광고로 동작합니다 (`AdsManager`).
- **상점/코스메틱**: 주행 거리로 코인을 벌어 보드/캐릭터 색상 스킨을 구매·장착. 광고 제거 구매(테스트
  placeholder)도 있습니다.
- **설정**: 마스터/이펙트/SFX 볼륨 슬라이더, 진동 on/off (착지·트릭·게임오버 시 실제 햅틱 반응).

## 아직 구현되지 않은 것 (다음 단계 후보)

- 좌우 이동/조작 (현재는 자동 하강 경로만 따라감)
- 캐릭터/보드 스프라이트 아트 (현재는 도형으로만 표현된 플레이스홀더)
- 실제 사운드 (볼륨 설정은 있지만 아직 재생할 오디오 에셋이 없음)
- 실제 광고 SDK(AdMob 등)·실제 StoreKit 인앱결제 연동 (지금은 목업)

## 프로젝트 구조

```
SnowboardGame.xcodeproj/         Xcode 프로젝트 파일
SnowboardGame/
  SnowboardGameApp.swift         앱 진입점 (SwiftUI @main)
  ContentView.swift              SpriteView로 LoadingScene을 호스팅
  LoadingScene.swift             로딩 화면 (진행바)
  LobbyScene.swift               대기실 (게임 시작/설정/상점)
  ShopScene.swift                상점 (코스메틱 구매, 광고 제거)
  SettingsPopup.swift             설정 팝업 모달
  SliderControl.swift / ToggleControl.swift  설정 팝업용 UI 위젯
  GameScene.swift                 메인 게임 루프 (스크롤, 카메라, 상태 전환, 이어하기)
  Player.swift                    플레이어(라이더) 상태 머신: riding / airborne / crashed
  Terrain.swift                   절차적 지형 생성 (수식 기반, 저장 없이 즉석 계산) + 급강하 구간
  BackgroundLayers.swift          패럴랙스 산 배경 레이어
  TiltInput.swift                 자이로 틸트 입력
  Trick.swift                     에어 트릭 종류/점수/판정 정의
  HUD.swift                       거리/최고기록/트릭점수/콤보바/게임오버 UI
  GameState.swift                 최고 기록 영속화 (UserDefaults)
  CoinWallet.swift / CosmeticsStore.swift / PurchaseStore.swift  코인/코스메틱/구매
  ContinueTracker.swift           하루 1회 무료 이어하기 추적
  AdsManager.swift                리워드 광고 추상화 + 테스트용 모의 광고
  Haptics.swift                   진동 피드백 모음
.github/workflows/build-ipa.yml  GitHub Actions: push마다 서명 없는 .ipa 자동 빌드
SIDELOAD.md                      Mac 없이 iPhone에 설치하는 방법
TESTFLIGHT.md                    TestFlight 배포 체크리스트
```

## Xcode로 직접 실행 (Mac이 있는 경우)

1. macOS에서 Xcode로 `SnowboardGame.xcodeproj`를 엽니다.
2. 타겟의 Signing & Capabilities에서 본인의 Team을 선택합니다 (Bundle Identifier는
   `com.example.SnowboardGame`으로 기본 설정되어 있으니 필요하면 변경하세요).
3. iOS 시뮬레이터(또는 실기기)를 선택하고 Run 합니다.

## Mac 없이 iPhone에서 실행

[SIDELOAD.md](SIDELOAD.md)를 참고하세요.
