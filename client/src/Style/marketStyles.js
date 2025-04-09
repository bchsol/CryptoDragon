import styled from "styled-components";

export const Container = styled.div`
  padding: 20px;
  font-family: "Arial", sans-serif;
`;

export const BannerSection = styled.div`
  display: flex;
  align-items: center;
  margin-bottom: 30px;
`;

export const ProfileImage = styled.img`
  border-radius: 50%;
  width: 150px;
  height: 150px;
  margin-right: 20px;
`;

export const ProfileInfo = styled.div`
  h1 {
    margin: 0;
    font-size: 2rem;
  }

  p {
    margin: 5px 0;
    color: gray;
  }
`;

export const MainSection = styled.div`
  display: flex;
  align-items: flex-start;
  margin-top: 20px;
`;

export const FilterSection = styled.div`
  flex: 0 0 250px; /* 왼쪽에 고정된 필터의 넓이 */
  margin-right: 20px;
  background-color: #f9f9f9;
  padding: 20px;
  border-radius: 10px;
  box-shadow: 0px 2px 5px rgba(0, 0, 0, 0.1);
`;

export const FilterForm = styled.form`
  margin-bottom: 20px;

  select {
    width: 100%;
    padding: 10px;
    margin-top: 10px;
    border: 1px solid #ddd;
    border-radius: 8px;
  }
`;

export const CheckboxWrapper = styled.div`
  display: flex;
  align-items: center;
  gap: 8px;
`;

export const CheckboxInput = styled.input`
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;

  &:checked + label {
    background-color: rgba(165, 176, 248, 1);
    color: rgb(0, 0, 0);
  }
`;

export const CheckboxLabel = styled.label`
  padding: 0.5rem 1rem;
  height: 2.25rem;
  cursor: pointer;
  border-radius: 2rem;
  background-color: #f2f4f6;
  font-size: 0.75rem;
  color: #383838;

  display: inline-block;
  vertical-align: middle;
`;

export const ContentSection = styled.div`
  flex: 1;
`;

export const SearchBarContainer = styled.div`
  display: flex;
  justify-content: space-between;
  margin-bottom: 20px;
`;

export const SearchBar = styled.input`
  padding: 10px;
  width: 70%;
  border: 1px solid #ddd;
  border-radius: 8px;
`;

export const SortDropdown = styled.select`
  padding: 10px;
  width: 25%;
  border: 1px solid #ddd;
  border-radius: 8px;
`;

export const Grid = styled.div`
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 20px;
`;

export const Card = styled.div`
  border: 1px solid #ddd;
  border-radius: 10px;
  overflow: hidden;
  transition: box-shadow 0.3s ease;

  &:hover {
    box-shadow: 0px 4px 12px rgba(0, 0, 0, 0.1);
  }
`;

export const CardImage = styled.img`
  width: 100%;
  height: 200px;
  object-fit: cover;
`;

export const CardBody = styled.div`
  padding: 15px;
  text-align: center;

  h3 {
    margin: 0 0 10px 0;
    font-size: 1.25rem;
  }

  p {
    color: gray;
    margin-bottom: 15px;
  }
`;

export const Button = styled.button`
  background-color: #007bff;
  color: white;
  border: none;
  padding: 10px 20px;
  border-radius: 5px;
  cursor: pointer;

  &:hover {
    background-color: #0056b3;
  }
`;

export const Tabs = styled.div`
  display: flex;
  margin-bottom: 20px;
  border-bottom: 2px solid #ddd;
`;

export const Tab = styled.button`
  padding: 10px 20px;
  background: ${(props) => (props.active ? "#007bff" : "white")};
  color: ${(props) => (props.active ? "white" : "black")};
  border: none;
  border-bottom: ${(props) => (props.active ? "none" : "2px solid #ddd")};
  cursor: pointer;
  border-radius: 5px 5px 0 0;
  margin-right: 10px;

  &:hover {
    background: ${(props) => (props.active ? "#0056b3" : "#f0f0f0")};
  }
`;

export const SubTabs = styled.div`
  display: flex;
  margin-top: 10px;
`;

export const SubTab = styled.button`
  padding: 8px 15px;
  background: ${(props) => (props.active ? "#28a745" : "white")};
  color: ${(props) => (props.active ? "white" : "black")};
  border: none;
  border-bottom: ${(props) => (props.active ? "none" : "2px solid #ddd")};
  cursor: pointer;
  border-radius: 5px 5px 0 0;
  margin-right: 10px;

  &:hover {
    background: ${(props) => (props.active ? "#218838" : "#f0f0f0")};
  }
`;
