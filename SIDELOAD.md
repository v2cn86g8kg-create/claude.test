# Mac 없이 iPhone에 설치하기 (무료 Apple ID + Sideloadly)

이 문서는 **Mac이 없는 상태**에서 GitHub Actions로 앱을 빌드하고, **Windows PC + 무료 Apple ID**로
iPhone에 사이드로딩하는 절차입니다.

## 준비물

- Windows PC (Sideloadly는 Windows/Mac만 지원, Linux는 안 됩니다)
- 무료 Apple ID (없으면 appleid.apple.com에서 새로 만들면 됩니다. **2단계 인증**이 켜져 있어야 합니다)
- iPhone과 PC를 연결할 라이트닝/USB-C 케이블
- GitHub 계정 (이미 이 저장소를 갖고 계시니 OK)

## 1. GitHub Actions로 .ipa 빌드하기

이 브랜치에는 `.github/workflows/build-ipa.yml`이 추가되어 있어서, 이 브랜치에 push할 때마다
(또는 수동으로) GitHub의 macOS 러너가 서명되지 않은(unsigned) `.ipa`를 자동으로 만들어 줍니다.
Sideloadly는 어차피 자체적으로 서명을 다시 하기 때문에 서명 없는 상태로 빌드하는 게 정상입니다.

1. GitHub 저장소 페이지 → **Actions** 탭으로 이동합니다.
2. **Build Sideload IPA** 워크플로를 클릭합니다.
   - 이미 자동으로 한 번 실행되고 있을 수 있습니다 (이 커밋을 push하면 트리거됩니다).
   - 수동으로 다시 돌리고 싶으면 **Run workflow** 버튼을 눌러 이 브랜치를 선택하고 실행하세요.
3. 실행이 끝나면(초록 체크) 해당 실행(run) 페이지 맨 아래 **Artifacts** 섹션에서
   `SnowboardGame-ipa`를 다운로드합니다. 안에 `SnowboardGame.ipa` 파일이 들어있습니다.
4. 다운로드한 `.ipa`를 Windows PC로 옮겨둡니다.

> 코드가 바뀔 때마다 이 브랜치에 push하면 자동으로 새 `.ipa`가 만들어집니다. 매번 1~2에서
> 새 Artifact를 다시 받으면 됩니다.

## 2. Windows PC 준비

1. **Apple Devices** 앱 (Microsoft Store) 또는 구버전 **iTunes**를 설치합니다. iPhone을 USB로
   인식시키는 드라이버(Apple Mobile Device Support)가 필요해서 꼭 설치해야 합니다.
2. [sideloadly.io](https://sideloadly.io) 에서 Sideloadly를 다운로드해 설치합니다.

## 3. iPhone 사이드로딩

1. iPhone을 케이블로 PC에 연결하고, iPhone에서 "이 컴퓨터를 신뢰하시겠습니까?" 알림이 뜨면
   **신뢰**를 누릅니다.
2. Sideloadly를 실행하면 상단에 연결된 기기가 보입니다.
3. 다운로드한 `SnowboardGame.ipa`를 Sideloadly 창 가운데로 드래그 앤 드롭합니다.
4. **Apple ID** 입력란에 본인의 무료 Apple ID 이메일을 입력하고 **Start**를 누릅니다.
   - Apple ID 비밀번호와 2단계 인증 코드를 요청하면 입력합니다.
   - (선택) 앱 전용 비밀번호(App-specific password)를 요구하면 appleid.apple.com에서
     생성해서 사용하세요.
5. 설치가 끝나면 iPhone 홈 화면에 앱 아이콘이 생깁니다. 처음 실행하면
   **"신뢰할 수 없는 개발자"** 경고가 뜹니다 → iPhone에서
   **설정 → 일반 → VPN 및 기기 관리(VPN & Device Management)** 로 들어가서
   본인 Apple ID 항목을 탭하고 **신뢰(Trust)** 를 눌러줘야 실행됩니다.

## 4. 무료 Apple ID의 제약 (꼭 알아두세요)

- **7일마다 만료**됩니다. 7일이 지나면 앱이 실행되지 않고, PC에 다시 연결해서 Sideloadly로
  재설치해야 합니다(같은 과정 반복, 새 빌드가 있으면 최신 `.ipa`로 교체).
- 무료 계정은 **동시에 등록 가능한 앱이 3개**, **7일당 새로 만들 수 있는 App ID가 10개**로
  제한됩니다. 이 앱 하나만 쓰신다면 문제 없습니다.
- 매주 재설치가 번거로우면, 나중에 **AltStore**(AltServer가 PC에서 같은 Wi-Fi로 자동 재서명)로
  바꾸거나, 유료 Apple Developer Program($99/년)으로 업그레이드해 TestFlight를 쓰는 방법도
  있습니다 — 그때 말씀해주시면 그에 맞게 다시 세팅해 드릴게요.

## 문제가 생기면

- **Sideloadly에서 기기가 안 보임** → Apple Devices/iTunes 재설치, 케이블/포트 교체, iPhone
  잠금 해제 상태로 재연결.
- **"확인되지 않은 개발자" 경고 후에도 실행 안 됨** → 설정 → 일반 → VPN 및 기기 관리에서
  신뢰를 눌렀는지 다시 확인.
- **GitHub Actions 빌드 실패** → Actions 탭의 실행 로그를 확인해서 알려주시면 코드/워크플로를
  고쳐드리겠습니다.
