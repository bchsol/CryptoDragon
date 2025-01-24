import React, { useEffect, useState } from "react";
import { useLocation, useParams } from "react-router-dom";
import { BsChevronUp, BsChevronDown } from "react-icons/bs";
import {
  fetchAuctionItems,
  fetchMarketItems,
} from "../blockchain/fetchMarketData";
import { useWeb3ModalProvider } from "@web3modal/ethers/react"
import { BrowserProvider, Contract, formatUnits, parseUnits, Block } from "ethers";
import marketContractData from "../contracts/marketContract";
import drinkContractData from "../contracts/drinkContract";
import {
  StyledCard,
  ItemImageWrapper,
  DetailSectionWrapper,
  Button,
  CollapseWrapper,
  CollapsibleHeader,
  Container,
  StyledImage,
  DescriptionCard,
  DescriptionTitle,
  DescriptionText,
  TraitRow,
  TraitColumn,
  TraitTitle,
  TraitValue,
  TraitText,
  PriceCard,
  PriceHeader,
  PriceInfoText,
  PriceAmount,
  ButtonWrapper,
  InputField,
  SecondaryButton,
  BidCard,
  BidRow,
  BidColumn,
  BidTitle,
  BidValue,
  GrowthList,
  GrowthItem,
} from "../Style/ItemDetailStyles";
import { createRequest, getInterface, getNonce, requestMetaTx } from "../utils/relay";
import forwarder from "../contracts/forwarder";
const forwarderAddress = forwarder.AddressSepolia;
const forwarderAbi = forwarder.Abi;

const handleTransaction = async (contractAddress, abi, walletProvider, action, ...args) => {
  try {
    const ethersProvider = new BrowserProvider(walletProvider);
    const signer = await ethersProvider.getSigner();
    const forwarderContract = new Contract(forwarderAddress, forwarderAbi, signer);
    const nonce = await getNonce(forwarderContract, walletProvider.address);

    if (action === "buyItem" || action === "bid") {
      const drinkContract = new Contract(
        drinkContractData.AddressSepolia,
        drinkContractData.Abi,
        signer
      );
      const priceInDrink = args[1];

      const allowance = await drinkContract.allowance(
        signer.getAddress(),
        contractAddress
      );

      if (allowance < priceInDrink) {
        const contractInterface = getInterface(drinkContractData.Abi);
        const callFunction = contractInterface.encodeFunctionData('approve', [contractAddress,priceInDrink]);

        const request = createRequest(walletProvider.address, drinkContractData.AddressSepolia, callFunction, nonce);
        const result = await requestMetaTx(signer, request);
        console.log(result);
      }
    }

    const contractInterface = getInterface(abi);
    const callFunction = action === "buyItem" 
      ? contractInterface.encodeFunctionData('buyItem', [args[0], 1]) 
      : contractInterface.encodeFunctionData('bid', [...args]);

    const request = createRequest(walletProvider.address, contractAddress, callFunction, nonce);
    const result = await requestMetaTx(signer, request);
    console.log(result);
    window.location.reload();
  } catch (error) {
    console.error(`Failed to ${action}:`, error);
  }
};

function ItemDetail() {
  const { walletProvider } = useWeb3ModalProvider();
  const { id } = useParams();
  const location = useLocation();
  const itemType = new URLSearchParams(location.search).get("type");

  const [marketItem, setMarketItem] = useState(null);
  const [tokenInfo, setTokenInfo] = useState([]);
  const [growthInfo, setGrowthInfo] = useState([]);
  const [bidAmount, setBidAmount] = useState("");

  useEffect(() => {
    const fetchData = async () => {
      try {
        const ethersProvider = new BrowserProvider(walletProvider);
        const marketData = itemType === "market" 
          ? await fetchMarketItems(ethersProvider) 
          : await fetchAuctionItems(ethersProvider);

        const marketItemData = marketData.find(item => Number(item.itemId) == id);
        setMarketItem(marketItemData);
        setTokenInfo(marketItemData.tokenInfo);
        setGrowthInfo(marketItemData.growthInfo);
      } catch (error) {
        console.error("Failed to fetch item data: ", error);
      }
    };
    fetchData();
  }, [id, walletProvider]);

  if (!marketItem) {
    return <div>Loading...</div>;
  }

  return (
    <Container>
      <StyledCard>
        <ItemImageWrapper>
          <ItemImage marketItem={marketItem} />
          <ItemDescription />
          <Traits tokenInfo={tokenInfo} />
        </ItemImageWrapper>

        <DetailSectionWrapper>
          <DetailsSection
            id={id}
            marketItem={marketItem}
            tokenInfo={tokenInfo}
            growthInfo={growthInfo}
            itemType={itemType}
            bidAmount={bidAmount}
            setBidAmount={setBidAmount}
            walletProvider={walletProvider}
          />
        </DetailSectionWrapper>
      </StyledCard>
    </Container>
  );
}

const ItemImage = ({ marketItem }) => (
  <StyledImage src={marketItem.imageUrl} alt="Item Image" />
);

const ItemDescription = () => (
  <DescriptionCard>
    <DescriptionTitle>Description</DescriptionTitle>
    <DescriptionText>This is a Description</DescriptionText>
  </DescriptionCard>
);

const Traits = ({ tokenInfo }) => (
  <CollapsibleSection title="Traits">
    <TraitRow>
      <TraitColumn>
        <TraitTitle>
          <TraitText>RARITY</TraitText>
          <TraitText>TEST</TraitText>
        </TraitTitle>
      </TraitColumn>
      <TraitColumn>
        <TraitTitle>TYPE</TraitTitle>
        <TraitValue>{tokenInfo.tokenType.toUpperCase()}</TraitValue>
      </TraitColumn>
    </TraitRow>
  </CollapsibleSection>
);

const DetailsSection = ({
  id,
  marketItem,
  tokenInfo,
  growthInfo,
  itemType,
  bidAmount,
  setBidAmount,
  walletProvider,
}) => {
  const [saleRemaining, setSaleRemaining] = useState(0);

  useEffect(() => {
    const fetchSaleRemaining = async () => {
      const ethersProvider = new BrowserProvider(walletProvider);
      const currentBlockTimestamp = await ethersProvider.getBlock("latest").then(block => block.timestamp);
      const { endTime } = marketItem;
      if(endTime - currentBlockTimestamp <= 0) setSaleRemaining(0);
      else setSaleRemaining(endTime - currentBlockTimestamp);
    };

    fetchSaleRemaining();
  }, [marketItem]);

  return (
    <>
      <PriceInfo
        id={id}
        price={marketItem.price}
        SaleRemaining={saleRemaining}
        itemType={itemType}
        bidInfo={marketItem.bidInfo}
        bidAmount={bidAmount}
        setBidAmount={setBidAmount}
        walletProvider={walletProvider}
      />
      {itemType === "auction" && marketItem.bidInfo && <BidInfo bidInfo={marketItem.bidInfo} />}
      <GrowthInfo tokenInfo={tokenInfo} growthInfo={growthInfo} />
    </>
  );
};

const GrowthInfo = ({ tokenInfo, growthInfo }) => (
  <CollapsibleSection title="GrowthInfo">
    <GrowthList>
      <GrowthItem>
        <strong>Gender: </strong>
        {tokenInfo.type === "egg" ? "secret" : Number(tokenInfo.gender) % 2 === 0 ? "Female" : "Male"}
      </GrowthItem>
      <GrowthItem>
        <strong>Husband Id: </strong>
        {Number(tokenInfo.husbandId)}
      </GrowthItem>
      <GrowthItem>
        <strong>Wife Id: </strong>
        {Number(tokenInfo.wifeId)}
      </GrowthItem>
      <GrowthItem>
        <strong>Generation: </strong>
        {Number(tokenInfo.generation)}
      </GrowthItem>
      <GrowthItem>
        <strong>Birth: </strong>
        {new Date(Number(tokenInfo.birth) * 1000).toLocaleDateString()}
      </GrowthItem>
      <GrowthItem>
        <strong>Type: </strong>
        {tokenInfo.tokenType}
      </GrowthItem>
      <GrowthItem>
        <strong>Remaining Time: </strong>
        {displayTime(Number(growthInfo.timeRemaining))}
      </GrowthItem>
    </GrowthList>
  </CollapsibleSection>
);

const PriceInfo = ({
  id,
  price,
  SaleRemaining,
  itemType,
  bidInfo,
  bidAmount,
  setBidAmount,
  walletProvider,
}) => (
  <PriceCard>
    <PriceHeader>{displayTime(SaleRemaining)}</PriceHeader>
    <PriceInfoText>
      {itemType === "auction" ? "Current Bid" : "Current Price"}
    </PriceInfoText>
    <PriceAmount>
      {itemType === "auction"
        ? formatUnits(String(bidInfo.price), 18).split(".")[0]
        : formatUnits(price, 18).split(".")[0]}{" "}
      Drink
    </PriceAmount>

    <ButtonWrapper>
      {itemType === "auction" ? (
        <>
          <InputField
            type="text"
            placeholder="Enter bid amount"
            value={bidAmount}
            onChange={(e) => setBidAmount(e.target.value)}
          />
          <Button
            onClick={() =>
              handleTransaction(
                marketContractData.AddressSepolia,
                marketContractData.Abi,
                walletProvider,
                "bid",
                id,
                parseUnits(bidAmount, 18)
              )
            }
          >
            Bid
          </Button>
        </>
      ) : (
        <>
          <Button
            onClick={() =>
              handleTransaction(
                marketContractData.AddressSepolia,
                marketContractData.Abi,
                walletProvider,
                "buyItem",
                id,
                price
              )
            }
          >
            Buy now
          </Button>
          <SecondaryButton>Make offer</SecondaryButton>
        </>
      )}
    </ButtonWrapper>
  </PriceCard>
);

const BidInfo = ({ bidInfo }) => (
  <BidCard>
    <BidRow>
      <BidColumn>
        <BidTitle>LAST BID AMOUNT</BidTitle>
        <BidValue>
          {formatUnits(String(bidInfo.price), 18).split(".")[0]} Drink
        </BidValue>
      </BidColumn>
      <BidColumn>
        <BidTitle>LAST BIDDER</BidTitle>
        <BidValue>{bidInfo.highestBidder}</BidValue>
      </BidColumn>
    </BidRow>
  </BidCard>
);

const CollapsibleSection = ({ title, children }) => {
  const [isOpen, setIsOpen] = useState(false);

  return (
    <CollapseWrapper>
      <CollapsibleHeader onClick={() => setIsOpen(!isOpen)}>
        <p>{title}</p>
        {isOpen ? <BsChevronUp /> : <BsChevronDown />}
      </CollapsibleHeader>
      {isOpen && <div>{children}</div>}
    </CollapseWrapper>
  );
};

const displayTime = (remainingSeconds) => {
  const minutes = Math.floor(remainingSeconds / 60);
  const hours = Math.floor(minutes / 60);
  const days = Math.floor(hours / 24);
  return `${days} days ${hours % 24} hours ${minutes % 60} minutes`;
};

export default ItemDetail;
