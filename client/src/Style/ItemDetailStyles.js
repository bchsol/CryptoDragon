import styled from "styled-components";

export const Container = styled.div`
  padding: 2rem;
`;

export const StyledCard = styled.div`
  background: white;
  box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
  border-radius: 8px;
  overflow: hidden;
  display: flex;
  flex-wrap: wrap;
`;

export const ItemImageWrapper = styled.div`
  flex: 1;

  min-width: 100px;
`;

export const StyledImage = styled.img`
  width: 35%;
  margin-left: 30%;
  border-radius: 8px;
`;

export const DescriptionCard = styled.div`
  margin-top: 20px;
  padding: 16px;
  border: 1px solid #e6e6e6;
  border-radius: 8px;
`;

export const DescriptionTitle = styled.p`
  color: #8a8a8a;
  margin: 0;
`;
export const DescriptionText = styled.p`
  margin: 8px 0 0 0;
  color: #333;
`;

export const TraitRow = styled.div`
  display: flex;
  justify-content: space-between;
`;

export const TraitColumn = styled.div`
  flex: 1;
`;

export const TraitTitle = styled.p`
  color: #8a8a8a;
`;

export const TraitText = styled.p`
  color: #333;
`;

export const TraitValue = styled.p`
  font-weight: bold;
`;

export const PriceCard = styled.div`
  margin-bottom: 20px;
  padding: 16px;
  border: 1px solid #e6e6e6;
  border-radius: 8px;
`;
export const PriceHeader = styled.p`
  color: #8a8a8a;
  margin-bottom: 12px;
`;

export const PriceInfoText = styled.p`
  color: #8a8a8a;
`;

export const PriceAmount = styled.p`
  font-size: 24px;
  font-weight: bold;
  margin-bottom: 20px;
`;
export const ButtonWrapper = styled.div`
  display: flex;
  justify-content: space-between;
`;

export const InputField = styled.input`
  width: 48%;
  padding: 10px;
  font-size: 16px;
`;

export const BidCard = styled.div`
  margin-top: 20px;
  padding: 16px;
  border: 1px solid #e6e6e6;
  border-radius: 8px;
`;

export const BidRow = styled.div`
  display: flex;
  justify-content: space-between;
`;

export const BidColumn = styled.div`
  flex: 1;
`;

export const BidTitle = styled.p`
  color: #8a8a8a;
`;

export const BidValue = styled.p`
  font-weight: bold;
`;

export const CollapsibleHeader = styled.div`
  padding: 16px;
  display: flex;
  justify-content: space-between;
  cursor: pointer;
  color: #333;
`;

export const ItemDescriptionWrapper = styled.div`
  padding: 20px;
  background: #f9f9f9;
`;

export const Button = styled.button`
  padding: 0.5rem 1rem;
  background-color: ${(props) => (props.secondary ? "#6c757d" : "#007bff")};
  color: white;
  border: none;
  border-radius: 8px; /* Rounded corners */
  cursor: pointer;
  width: 48%;
  margin-right: ${(props) => (props.secondary ? "0" : "4%")};

  &:hover {
    background-color: ${(props) => (props.secondary ? "#5a6268" : "#0056b3")};
  }
`;

export const SecondaryButton = styled(Button)`
  background-color: #6c757d;
`;

export const CollapseWrapper = styled.div`
  margin-top: 20px;
  background: #f9f9f9;
  border-radius: 8px;
  padding: 15px;
`;

export const ToggleHeader = styled.div`
  display: flex;
  justify-content: space-between;
  cursor: pointer;
`;

export const PriceSection = styled.div`
  padding: 20px;
  border-top: 1px solid #eaeaea;
`;

export const DetailSectionWrapper = styled.div`
  flex: 1;
  padding: 20px;
`;

export const GrowthList = styled.div`
  margin-top: 10px;
  padding: 10px;
  border: 1px solid #e6e6e6;
  border-radius: 8px;
  background-color: #f9f9f9;
`;

export const GrowthItem = styled.div`
  padding: 8px 0;
  border-bottom: 1px solid #eaeaea;

  &:last-child {
    border-bottom: none; /* Remove border for the last item */
  }

  strong {
    color: #333; /* Color for the labels */
  }

  color: #666; /* Color for the values */
`;
