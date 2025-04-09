import styled, { keyframes } from "styled-components";
import secretEggImage from "../image/secret_egg.png";
export const floatAnimation = keyframes`
  0% {
    transform: translateY(0);
  }
  50% {
    transform: translateY(-20px);
  }
  100% {
    transform: translateY(0);
  }
`;

export const MintPageContainer = styled.div`
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  height: 100vh;
  background-color: #f0f8ff;
`;

export const EggContainer = styled.div`
  width: 300px;
  height: 300px;
  position: relative;
  animation: ${floatAnimation} 3s ease-in-out infinite;
  display: flex;
  justify-content: center;
  align-items: center;
  background-image: url(${secretEggImage});
  background-size: contain; /* 이미지를 컨테이너에 맞춰 조정 */
  background-repeat: no-repeat; /* 반복되지 않도록 설정 */
  background-position: center; /* 중앙에 맞추기 */
`;

export const EggImageStyled = styled.img`
  width: 100%;
  height: 100%;
  object-fit: contain;
`;
export const MintButton = styled.button`
  margin-top: 20px;
  padding: 10px 20px;
  background-color: #4caf50;
  color: white;
  border: none;
  border-radius: 5px;
  font-size: 1.2rem;
  cursor: pointer;
  transition: background-color 0.3s ease;

  &:hover {
    background-color: #45a049;
  }

  &:active {
    transform: scale(0.98);
  }
`;

export const PageTitle = styled.h1`
  font-size: 2.5rem;
  margin-bottom: 20px;
  color: #444;
`;
