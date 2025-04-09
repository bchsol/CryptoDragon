import styled from "styled-components";

export const PageContainer = styled.div`
  background-color: #1e1e2f;
  color: #fff;
  height: 100%;
  padding: 20px;
`;

export const ProfileSection = styled.section`
  margin-bottom: 120px;
`;

export const ProfileBanner = styled.div`
  background-color: #2c2c3e;
  padding: 20px;
  border-radius: 10px;
  height: 10vh;
`;

export const ProfileInfo = styled.div`
  display: flex;
  align-items: center;
`;

export const ProfileImage = styled.img`
  width: 80px;
  height: 80px;
  border-radius: 50%;
  margin-right: 20px;
`;

export const ProfileDetails = styled.div`
  display: flex;
  flex-direction: column;
`;

export const WalletAddress = styled.h2`
  font-size: 1.7rem;
  margin: 0;
`;

export const ProfileActions = styled.div`
  display: flex;
  gap: 10px;
  margin: 10px 0;
`;

export const ProfileStats = styled.div`
  display: flex;
  gap: 15px;
`;

export const Stat = styled.span`
  font-size: 1.2rem;
`;

export const ItemsSection = styled.section`
  background-color: #2c2c3e;
  padding: 20px;
  border-radius: 10px;
  height: 100%;
`;

export const ItemsHeader = styled.div`
  display: flex;
  justify-content: space-between;
  margin-bottom: 50px;
`;

export const ViewModeSwitch = styled.div`
  button {
    background: none;
    border: 1px solid #fff;
    color: #fff;
    padding: 5px 10px;
    margin-right: 5px;
    cursor: pointer;
    border-radius: 5px;
    &:hover {
      background-color: #4e73f8;
    }
  }
`;

export const Button = styled.button`
  display: inline-flex;
  outline: #333;
  border-radius: 10px;
  color: black;
  font-weight: bold;
  cursor: pointer;
  padding-left: 1.5rem;
  padding-right: 1.5rem;

  &.info {
    background-color: #81daf5;
  }

  &.sell {
    background-color: #fe2e64;
  }

  &.trading {
    background-color: #848484;
  }
`;

export const SearchBar = styled.input`
  padding: 10px;
  border-radius: 5px;
  border: none;
  background-color: #1a1a2e;
  color: #fff;
  width: 500px;
`;

export const SortDropdown = styled.select`
  padding: 10px;
  border-radius: 5px;
  background-color: #1a1a2e;
  color: #fff;
  border: none;
`;

export const ItemsGrid = styled.div`
  display: grid;
  width: 100%;
  grid-template-columns: ${({ viewMode }) =>
    viewMode === "grid" ? "repeat(4, 1fr)" : "repeat(1, 1fr)"};
  gap: 20px;
`;

export const NFTCard = styled.div`
  background-color: #1a1a2e;
  padding: 20px;
  border-radius: 10px;
  text-align: center;
`;

export const NFTImage = styled.img`
  width: 30%;
  height: auto;
  border-radius: 10px;
`;

export const NFTInfo = styled.div`
  margin-top: 10px;
  padding-bottom: 10px;
`;

export const NFTName = styled.h3`
  font-size: 1rem;
  margin: 0;
`;

export const NFTStatus = styled.span`
  color: #aaa;
  font-size: 0.9rem;
`;
