import styled from "styled-components";

export const QuestContainer = styled.div`
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  width: 100%;
  min-height: 100vh;
  padding: 40px 20px;
  background-color: #f0f4f8;
`;

export const QuestTitle = styled.h1`
  font-size: 2.5rem;
  color: #007bff;
  margin-bottom: 1.5rem;
  text-align: center;
`;

export const AccountText = styled.p`
  font-size: 1.2rem;
  color: #333;
  text-align: center;
  margin-bottom: 20px;
`;

export const QuestCard = styled.div`
  width: 100%;
  max-width: 700px;
  background-color: white;
  border-radius: 15px;
  box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
  margin-bottom: 20px;
  padding: 20px;
`;

export const CardTitle = styled.h2`
  font-size: 1.5rem;
  color: #007bff;
  margin-bottom: 10px;
`;

export const CardText = styled.p`
  font-size: 1.1rem;
  color: #555;
  margin-bottom: 10px;
`;

export const ActionButton = styled.button`
  padding: 10px 20px;
  font-size: 1.1rem;
  color: white;
  background-color: ${(props) => (props.disabled ? "#ccc" : "#007bff")};
  border: none;
  border-radius: 8px;
  cursor: ${(props) => (props.disabled ? "not-allowed" : "pointer")};
  transition: background-color 0.3s ease;

  &:hover {
    background-color: ${(props) => (props.disabled ? "#ccc" : "#0056b3")};
  }
`;

export const DailyCheckContainer = styled.div`
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
`;

export const DailyCheckButton = styled(ActionButton)`
  padding: 10px 20px;
  font-size: 1rem;
`;

export const DayCircle = styled.div`
  width: 50px;
  height: 50px;
  border: 2px solid #007bff;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
  margin: 0 auto;
  background-color: ${(props) => (props.checked ? "#007bff" : "white")};
  color: ${(props) => (props.checked ? "white" : "#007bff")};
  transition: background-color 0.3s ease, color 0.3s ease;
`;

export const DayCirclesGroup = styled.div`
  display: flex;
  gap: 10px;
  justify-content: center;
  flex-wrap: wrap;
  margin-top: 10px;
  width: 100%;
`;
