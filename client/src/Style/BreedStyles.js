import styled from "styled-components";

// 페이지 전체 컨테이너
export const BreedPageContainer = styled.div`
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  height: 100vh;
  background-color: #f0f8ff;
`;

// 두 드래곤 박스 담는 컨테이너
export const BoxContainer = styled.div`
  display: flex;
  justify-content: space-between;
  align-items: center;
  width: 800px; /* 넉넉한 간격을 위해 너비 조정 */
  margin-bottom: 40px;
  position: relative; /* 하트 위치를 조정하기 위해 position 설정 */
`;

// 드래곤을 담는 사각형 박스
export const Box = styled.div`
  width: 250px;
  height: 250px;
  border: 3px solid #888;
  border-radius: 10px;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  background-color: white;
  box-shadow: 0px 4px 6px rgba(0, 0, 0, 0.1);
  cursor: pointer;
  transition: transform 0.3s ease, box-shadow 0.3s ease;

  &:hover {
    transform: scale(1.05);
    box-shadow: 0px 6px 10px rgba(0, 0, 0, 0.15);
  }

  img {
    width: 200px;
    height: 200px;
    object-fit: contain;
  }
`;

// 드래곤 이름
export const DragonName = styled.span`
  margin-top: 10px;
  font-size: 1.2rem;
  font-weight: bold;
  color: #333;
`;

// 하트 이미지
export const HeartIcon = styled.img`
  width: 100px;
  height: 100px;
  position: absolute;
  left: 50%;
  top: 50%;
  transform: translate(-50%, -50%); /* 정확하게 가운데 정렬 */
`;

// 알과 확률을 담는 컨테이너
export const EggProbabilityContainer = styled.div`
  display: flex;
  justify-content: center;
  align-items: center;
  margin-top: 20px;
`;

// 알 이미지와 확률을 담는 박스
export const EggBox = styled.div`
  display: flex;
  flex-direction: column;
  align-items: center;
  margin: 0 15px;

  img {
    width: 70px;
    height: 70px;
  }

  span {
    margin-top: 5px;
    font-size: 1rem;
    color: #333;
  }
`;

// 브리드 버튼
export const BreedButton = styled.button`
  padding: 15px 30px;
  background-color: #6a5acd;
  color: white;
  border: none;
  border-radius: 8px;
  font-size: 1.3rem;
  cursor: pointer;
  transition: background-color 0.3s ease;

  &:hover {
    background-color: #5a4cb5;
  }

  &:active {
    transform: scale(0.98);
  }
`;
