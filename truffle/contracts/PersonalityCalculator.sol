// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract PersonalityCalculator {
    enum Attribute {Quickness, Strength, Focus, Intelligence}

    enum Personality {
        Naive, Rash, Hasty, QuickWitted, // 천진난만한, 덜렁대는, 성급한, 눈치빠른
        Brave, Quirky, Adamant, Bold,   // 용감한, 변덕쟁이, 고집있는, 대담한
        Quiet, Calm, Careful, Hardy,    // 냉정한, 차분한, 신중한, 노력하는
        Docile, Bashful, Lax, Smart     // 온순한, 수줍은, 촐랑대는, 똑똑한
    }

    struct Attributes {
        uint256 quickness;
        uint256 strength;
        uint256 focus;
        uint256 intelligence;
    }

    struct TrainingData {
        uint256 lastTrainingDate;
        uint256 trainingCount;
    }

    mapping(uint256 => Attributes) internal attributes;
    mapping(uint256 => TrainingData) internal trainingData;

    uint256 private constant MAX_DAILY_TRAINING = 3;

    // 토큰별 확정된 가능한 성격들을 저장하는 매핑 추가
    mapping(uint256 => Personality[]) public confirmedPersonalities;

    /// @notice 속성 훈련 함수
    /// 하루에 최대 3번까지 훈련 가능
    /// 훈련을 통해 특정 속성값 증가
    function _trainAttribute(uint256 tokenId, Attribute attribute) internal {
        uint256 currentDate = block.timestamp / 1 days;
        TrainingData storage data = trainingData[tokenId];
        
        if(data.lastTrainingDate < currentDate) {
            data.lastTrainingDate = currentDate;
            data.trainingCount = 0;
        }

        require(data.trainingCount < MAX_DAILY_TRAINING, "Training limit reached for today");
        data.trainingCount++;
        
        _increaseAttribute(tokenId, attribute);
    }

    /// @notice 토큰의 성격을 결정하는 함수
    /// @return 결정된 성격
    function determinePersonality(uint256 tokenId) internal view returns (Personality) {
        Attributes memory attr = attributes[tokenId];
        uint256[4] memory values = [attr.quickness, attr.strength, attr.focus, attr.intelligence];
        
        (uint8[] memory maxIndices, uint8[] memory minIndices) = _findMaxMinIndices(values);
        
        if (minIndices.length >= 2) {
            uint8 defaultRandomIndex = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, tokenId))) % maxIndices.length);
            return _getDefaultPersonality(maxIndices[defaultRandomIndex]);
        }
        
        uint8 randomMaxIndex = uint8(uint256(keccak256(abi.encodePacked(block.timestamp, tokenId))) % maxIndices.length);
        return _getPersonalityMatrix(maxIndices[randomMaxIndex], minIndices[0]);
    }

    /// @notice 배열에서 최대/최소값의 인덱스를 찾는 최적화된 함수
    /// @return maxIndices 최대값을 가진 인덱스들의 배열
    /// @return minIndices 최소값을 가진 인덱스들의 배열
    function _findMaxMinIndices(uint256[4] memory values) private pure returns (
        uint8[] memory maxIndices,
        uint8[] memory minIndices
    ) {
        uint256 maxValue = 0;
        uint256 minValue = type(uint256).max;
        
        // 최대값과 최소값 찾기
        for(uint8 i = 0; i < 4; i++) {
            if(values[i] > maxValue) {
                maxValue = values[i];
            }
            if(values[i] < minValue) {
                minValue = values[i];
            }
        }
        
        // 최대값과 최소값을 가진 인덱스들 수집
        uint8[] memory tempMaxIndices = new uint8[](4);
        uint8[] memory tempMinIndices = new uint8[](4);
        uint8 maxCount = 0;
        uint8 minCount = 0;
        
        for(uint8 i = 0; i < 4; i++) {
            if(values[i] == maxValue) {
                tempMaxIndices[maxCount] = i;
                maxCount++;
            }
            if(values[i] == minValue) {
                tempMinIndices[minCount] = i;
                minCount++;
            }
        }
        
        // 실제 크기의 배열로 복사
        maxIndices = new uint8[](maxCount);
        minIndices = new uint8[](minCount);
        
        for(uint8 i = 0; i < maxCount; i++) {
            maxIndices[i] = tempMaxIndices[i];
        }
        for(uint8 i = 0; i < minCount; i++) {
            minIndices[i] = tempMinIndices[i];
        }
    }

    /// @notice 기본 성격을 반환하는 함수 (최소값이 여러개일 때 사용)
    /// @param attributeIndex 속성 인덱스
    /// @return 해당 속성의 기본 성격
    function _getDefaultPersonality(uint8 attributeIndex) private pure returns (Personality) {
        Personality[4] memory defaults = [
            Personality.QuickWitted,
            Personality.Bold,
            Personality.Hardy,
            Personality.Smart
        ];
        return defaults[attributeIndex];
    }

    /// @notice 성격 매트릭스를 통해 성격을 결정하는 함수
    /// @param maxIndex 최대 속성 인덱스
    /// @param minIndex 최소 속성 인덱스
    /// @return 결정된 성격
    function _getPersonalityMatrix(uint8 maxIndex, uint8 minIndex) private pure returns (Personality) {
        // 성격 매트릭스 정의 [최대속성][최소속성]
        Personality[4][4] memory personalityMatrix = [
            // Quickness max
            [Personality.QuickWitted, Personality.Naive, Personality.Rash, Personality.Hasty],
            // Strength max
            [Personality.Brave, Personality.Bold, Personality.Quirky, Personality.Adamant],
            // Focus max
            [Personality.Quiet, Personality.Calm, Personality.Hardy, Personality.Careful],
            // Intelligence max
            [Personality.Docile, Personality.Bashful, Personality.Lax, Personality.Smart]
        ];
        
        return personalityMatrix[maxIndex][minIndex];
    }

    /// @notice 속성을 증가시키는 함수
    function _increaseAttribute(uint256 tokenId, Attribute attribute) internal {
        Attributes storage attr = attributes[tokenId];
        if (attribute == Attribute.Quickness) {
            attr.quickness++;
        } else if (attribute == Attribute.Strength) {
            attr.strength++;
        } else if (attribute == Attribute.Focus) {
            attr.focus++;
        } else if (attribute == Attribute.Intelligence) {
            attr.intelligence++;
        }
    }

    /// @notice 저장된 확정 성격들을 조회하는 함수
    /// @param tokenId 토큰 ID
    /// @return 저장된 가능한 성격들의 배열
    function getConfirmedPersonalities(uint256 tokenId) external view returns (Personality[] memory) {
        return confirmedPersonalities[tokenId];
    }
}