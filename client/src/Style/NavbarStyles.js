import styled from "styled-components";
import { Link } from "react-router-dom";

export const NavbarContainer = styled.nav`
  background-color: #282c34;
  padding: 1rem 2rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  box-shadow: 0px 4px 8px rgba(0, 0, 0, 0.1);
`;

export const NavLinks = styled.div`
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  flex-grow: 1;

  @media (max-width: 768px) {
    display: none; /* 작은 화면에서는 숨김 처리 */
  }
`;

export const NavLink = styled(Link)`
  color: white;
  text-decoration: none;
  margin-right: 25px;
  font-size: 18px;
  font-weight: 500;
  transition: color 0.3s ease;

  &:hover {
    color: #61dafb; /* React 로고 색상과 비슷한 파란색 */
  }

  &:last-child {
    margin-right: 0;
  }
`;

export const NavbarButton = styled.button`
  padding: 0.5rem 1.5rem;
  font-size: 1rem;
  color: white;
  background-color: #61dafb; /* React 로고와 비슷한 파란색 */
  border: none;
  cursor: pointer;
  border-radius: 4px;
  transition: background-color 0.3s ease, transform 0.3s ease;
  margin-left: auto;
  &:hover {
    background-color: #21a1f1; /* 호버 시 조금 더 진한 파란색 */
    transform: translateY(-2px); /* 호버 시 살짝 떠오르는 효과 */
  }

  &:active {
    transform: translateY(0); /* 클릭 시 다시 원위치 */
  }
`;

export const NavbarToggle = styled.div`
  display: none;

  @media (max-width: 768px) {
    display: block;
    cursor: pointer;
    color: white;
    font-size: 2rem;
  }
`;

export const CollapsedMenu = styled.div`
  display: flex;
  flex-direction: column;

  @media (min-width: 768px) {
    display: flex;
    flex-direction: row;
  }
`;

export const MobileMenu = styled.div`
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  background-color: #282c34;
  padding: 1rem;
  position: absolute;
  top: 70px; /* 네비게이션 바 아래에 나타나도록 설정 */
  left: 0;
  width: 100%;
  z-index: 999;

  a {
    color: white;
    text-decoration: none;
    padding: 0.75rem;
    font-size: 18px;
    font-weight: 500;
    width: 100%;
    text-align: left;

    &:hover {
      background-color: #61dafb;
    }
  }
`;
