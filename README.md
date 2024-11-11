##

### 소개

**Crypto Dragon**은 하이브로에서 개발한 드래곤 빌리지 컬렉션을 블록체인으로 개발한 컨트랙트입니다.

플레이어는 NFT(Non-Fungible Token)로 표현되는 가상 애완동물을 번식, 수집, 진화시킬 수 있습니다.

ERC721 및 ERC721URIStorage 표준을 사용하여 고유한 토큰 소유권과 동적 메타데이터 업데이트를 보장합니다.

### 주요 특징

- **번식:** 두 개의 기존 드래곤을 번식시켜 다양한 특징과 특성을 가진 새로운 드래곤을 만들 수 있습니다.
- **진화:** Egg, Hatch, Hatchling, Adult 와 같이 다양한 성장 단계를 거쳐 드래곤을 키우고 각 단계마다 독특한 외모와 기능을 가질 수 있습니다.
- **먹이주기:** 토큰으로 표현되는 먹이를 제공하여 드래곤의 진화 속도를 높이고 각 단계에 도달하는 데 걸리는 시간을 줄일 수 있습니다.
- **소유권:** 각 드래곤은 고유한 NFT이며, 플레이어에게 검증 가능한 소유권을 제공하며 마켓플레이스에서 거래하거나 판매할 수 있습니다.
- **메타데이터:** 성장 단계, 성별, 세대 및 기타 속성을 포함하는 토큰 메타데이터는 투명성과 불변성을 위해 체인에 저장됩니다.

### 계약 구조

- **TokenBase:** 기본 계약은 발행, 토큰 소유권, 성장 단계, 성별 결정 및 메타데이터 관리와 같은 핵심 기능을 정의합니다.
- **Breeding:** TokenBase 계약을 확장하고 번식 기능을 추가하며 번식 조건, 번식 쿨다운 기간 및 부모 특성에 따라 자손 생성과 같은 측면을 처리합니다.
- **Token:** Breeding 계약을 상속받고 제네시스 발행, NFT 정보 검색, 사용자 NFT 목록과 같은 특정 편의를 제공합니다.
- **TokenTypeManager:** 토큰 유형을 추가, 제거하고 현재 허용된 토큰 유형을 확인할 수 있습니다.
- **MarketPlace:** ERC20 토큰으로 ERC721과 ERC1155 토큰을 거래할 수 있습니다.
- **Quest:** 퀘스트를 수행하고 보상을 받을 수 있습니다.
- **DailyCheck:** 매일 출석체크를 하고 보상을 받을 수 있습니다.
- **Battle:** 다른 사용자와 배틀을 통해 경쟁할 수 있도록 합니다.
- **Exploration:** 탐험을 통해 여러 아이템을 얻을 수 있습니다.

### 시작하기

1.  **웹에 접속:**: https://bchsol.github.io/CryptoDragon/ 웹에 접속합니다.
2.  **Web3 지갑 연결:** MetaMask 또는 WalletConnect와 같이 Ethereum 및 NFT 상호 작용을 지원하는 지갑을 선택하고 연결합니다.
3.  **NFT 얻기:** 다음 두 가지 방법 중 하나를 선택할 수 있습니다.

    - **제네시스 NFT 발행:** 초기 단계에서는 제한된 수의 제네시스 NFT를 토큰과 교환하여 발행할 수 있습니다(가용성에 따라 다름).
    - **기존 NFT 번식:** 두 개의 호환되는 드래곤을 가지고 있으면 이를 번식하여 고유한 특성을 가진 새로운 자손을 만들 수 있습니다.

4.  **드래곤 키우기:** 먹이를 주고 돌봐서 성장 단계를 거쳐 새로운 능력과 외모를 잠금 해제합니다.
5.  **게임 즐기기:** 드래곤을 교배시키거나 매매하며 수집하고 여러 컨텐츠에 참여합니다.

### 업데이트 예정

- 배틀, 탐험 페이지 추가
- 탐험 아이템 보상 추가
- 마켓 옥션 추가

### 리뷰

보안 이슈와 가스비 문제로 대부분의 로직은 서버에서 처리하는 것이 좋음.