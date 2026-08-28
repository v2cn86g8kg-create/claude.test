# TestFlight로 배포하기 (Mac 없이, GitHub Actions + 유료 Apple Developer 계정)

이 문서는 **Apple Developer Program(유료, $99/년)에 이미 가입되어 있다는 전제**로, GitHub Actions가
서명된 `.ipa`를 자동으로 만들어 **TestFlight**에 업로드하도록 세팅하는 절차입니다. 한 번 세팅해두면
그 다음부터는 브랜치에 push만 하면 자동으로 빌드 → TestFlight 업로드가 되고, iPhone에서는 TestFlight
앱으로 설치/업데이트만 하면 됩니다. Windows PC나 Sideloadly, 7일 재설치 같은 것도 더 이상 필요 없습니다.

## 준비물 체크리스트

브라우저로 로그인해서 직접 하셔야 하는 부분(제가 대신 할 수 없는 부분)과, 제가 준비해드리는 부분을
나눴습니다.

### A. 본인이 포털에서 직접 해야 하는 것

1. **Team ID 확인**
   - [developer.apple.com/account](https://developer.apple.com/account) → 오른쪽 위 **Membership details**
     (또는 좌측 "Membership")에서 **Team ID**(10자리 영숫자, 예: `A1B2C3D4E5`)를 확인해서 알려주세요.

2. **App ID(Bundle ID) 등록**
   - developer.apple.com/account → **Certificates, Identifiers & Profiles** → **Identifiers** → **+**
   - App IDs → App 선택 → Description: `Snowboard Rush`, Bundle ID: **Explicit**로
     `com.yourname.snowboardrush` 같은 고유한 값 입력 (원하시는 접두사 알려주시면 그걸로 통일하겠습니다).
   - Capabilities는 기본값 그대로 두면 됩니다 (지금 버전은 특별한 권한 필요 없음).

3. **배포용 인증서(Distribution Certificate) 만들기**
   - 이미 보내드린 `distribution.csr` 파일을 사용합니다.
   - Certificates, Identifiers & Profiles → **Certificates** → **+** → **Apple Distribution** 선택 → Continue
   - "Choose File"에서 제가 보내드린 `distribution.csr` 업로드 → Continue → **Download**
   - 다운로드된 `.cer` 파일(예: `distribution.cer`)을 **저에게 보내주세요** (채팅에 첨부해주시면 됩니다).
     제가 갖고 있는 개인키와 합쳐서 서명용 `.p12`를 만들겠습니다.

4. **App Store Connect API 키 만들기** (CI가 TestFlight에 업로드할 때 사용, Apple ID/2단계 인증 없이
   자동 업로드 가능)
   - [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **Users and Access** →
     **Integrations** 탭 → **App Store Connect API** → **Team Keys** → **Generate API Key**
   - Name: `github-actions-ci`, Access: **App Manager** 선택 → Generate
   - **Key ID**와 **Issuer ID**를 적어두고, **Download API Key**로 `.p8` 파일을 받으세요
     (⚠️ 이 파일은 딱 한 번만 다운로드할 수 있습니다. 받으신 `.p8` 파일도 저에게 보내주세요).

5. **App Store Connect에 앱 등록**
   - App Store Connect → **My Apps** → **+** → **New App**
   - Platform: iOS, Name: `Snowboard Rush` (또는 원하는 이름), Primary language: Korean,
     Bundle ID: 위에서 만든 것 선택, SKU: 아무 고유 문자열(예: `snowboardrush001`)
   - Create를 누르면 앱 레코드가 만들어집니다 (이 단계에서는 실제 스크린샷/설명 등은 나중에 채워도 됩니다).

6. **Provisioning Profile 만들기**
   - Certificates, Identifiers & Profiles → **Profiles** → **+** → **App Store Connect** → Continue
   - App ID: 2번에서 만든 것 선택 → Continue
   - Certificate: 3번에서 만든 배포 인증서 선택 → Continue
   - Profile Name: `SnowboardGame AppStore` → Generate → **Download**
   - 다운로드된 `.mobileprovision` 파일도 저에게 보내주세요.

### B. 제가 준비하는 것

- CSR/개인키 생성 (완료 — `distribution.csr` 보내드렸습니다)
- `.cer` + 개인키 → `.p12`로 변환
- Xcode 프로젝트의 Bundle Identifier / Team ID / 서명 방식(Manual)을 실제 값으로 업데이트
- GitHub Actions 워크플로를 "서명 없는 빌드"에서 "서명 + TestFlight 업로드"로 교체
- GitHub 저장소에 등록해야 할 **Secrets 목록**과 값 안내 (실제 값은 GitHub 웹에서 직접 입력하시게 됩니다 —
  민감한 값이라 제가 대신 입력할 방법은 없습니다)

## 다음 필요한 정보 (채팅으로 알려주세요)

1. **Team ID**
2. 원하시는 **Bundle ID 접두사** (예: `com.shiwookcho`) — 없으면 제가 `com.example`로 임시 지정하고
   나중에 바꿔도 됩니다.
3. 위 A-3, A-4, A-6에서 받은 `.cer`, `.p8`, `.mobileprovision` 파일 (준비되는 대로 하나씩 보내주셔도
   됩니다)

## 이후 흐름 (한 번 세팅되면)

1. 코드를 이 브랜치에 push
2. GitHub Actions가 자동으로 서명된 `.ipa`를 빌드해서 TestFlight에 업로드
3. 몇 분~십몇 분 후 TestFlight 앱(iPhone)에 새 빌드 알림이 뜸 → 설치/업데이트
4. (최초 1회) App Store Connect에서 본인을 **Internal Tester**로 등록해두면 그 이후부터는 별도 승인 없이
   바로 테스트 가능합니다.
