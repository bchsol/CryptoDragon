import React, { useCallback, useEffect, useState } from "react";
import CollectionInfoModal from "./CollectionInfoModal";
import CollectionSellModal from "./CollectionSellModal";
import {
  PageContainer,
  ProfileSection,
  ProfileBanner,
  ProfileInfo,
  ProfileDetails,
  WalletAddress,
  ProfileStats,
  Stat,
  ItemsSection,
  ItemsHeader,
  ViewModeSwitch,
  SearchBar,
  SortDropdown,
  ItemsGrid,
  NFTCard,
  NFTImage,
  NFTInfo,
  NFTName,
  NFTStatus,
  Button,
} from "../Style/collectionStyles";
import { fetchNfts } from "../blockchain/fetchData";
import { useWeb3ModalProvider,useWeb3ModalAccount } from "@web3modal/ethers/react";
import {
  BrowserProvider,
  Contract,
  formatUnits,
  parseUnits,
  decodeBytes32String,
} from "ethers";

import dragonContractData from "../contracts/dragonContract";
import marketContractData from "../contracts/marketContract";
import drinkContractData from "../contracts/drinkContract";
import forwarder from "../contracts/forwarder";
import { createRequest, getInterface, getNonce, requestMetaTx } from "../utils/relay";

const dragonContractAddress = dragonContractData.AddressSepolia;
const dragonAbi = dragonContractData.Abi;
const marketContractAddress = marketContractData.AddressSepolia;
const marketAbi = marketContractData.Abi;
const drinkContractAddress = drinkContractData.AddressSepolia;
const drinkAbi = drinkContractData.Abi;
const forwarderAddress = forwarder.AddressSepolia;
const forwarderAbi = forwarder.Abi;

function Collection() {
  // State Variables
  const [viewMode, setViewMode] = useState("grid");
  const [nftIds, setNftIds] = useState([]);
  const [listedStatus, setListedStatus] = useState({});
  const [show, setShow] = useState(false);
  const [stage, setStage] = useState("");
  const [timeRemaining, setTimeRemaining] = useState();
  const [selectedNft, setSelectedNft] = useState();
  const [price, setPrice] = useState();
  const [duration, setDuration] = useState("");
  const [endTime, setEndTime] = useState("");
  const [durationSec, setDurationSec] = useState(0);
  const [sellSelectNft, setSellSelectNft] = useState();
  const [tokenInfo, setTokenInfo] = useState([]);
  const [drinkBalance, setDrinkBalance] = useState();
  const [isSellModalOpen, setIsSellModalOpen] = useState(false);
  const [isEvolveBtnEnabled, setIsEvolveBtnEnabled] = useState(false);

  const { address, isConnected } = useWeb3ModalAccount();
  const { walletProvider } = useWeb3ModalProvider();

  // Truncate wallet address for display
  const truncateAccount = address
    ? address.substring(0, 6) + "..." + address.substring(address.length - 4)
    : null;

  // Fetch NFTs and their listed statuses
  const fetchMyNfts = useCallback(async () => {
    if (!isConnected) throw Error("User disconnected");

    const ethersProvider = new BrowserProvider(walletProvider);
    const nfts = await fetchNfts(ethersProvider, address);
    setNftIds(nfts);

    const signer = await ethersProvider.getSigner();
    const marketContract = new Contract(marketContractAddress, marketAbi, signer);

    const statuses = await Promise.all(
      nfts.map(async (nft) => {
        const isMarketListed = await marketContract.getListedInMarket(dragonContractAddress, nft.id);
        const isAuctionListed = await marketContract.getListedInAuction(dragonContractAddress, nft.id);
        let auctionId = 0, auctionStatus = null, marketId = 0, marketStatus = null;
        // 경매 상태 확인
        if (isAuctionListed) {
          try {
            auctionId = await marketContract.getAuctionStatusByToken(dragonContractAddress, nft.id);
            auctionStatus = await marketContract.getAuctionStatus(auctionId);
          } catch (error) {
            console.error(`Failed to fetch auction status for NFT ID ${nft.id}`, error);
          }
          return { id: nft.id, auctionId, listed: "auction", status: decodeBytes32String(auctionStatus) };
        } 
        // 마켓 상태 확인
        else if (isMarketListed) {
          try {
            marketId = await marketContract.tokenToItemId(dragonContractAddress, nft.id);
            marketStatus = await marketContract.getSaleStatus(marketId);
          } catch (error) {
            console.error(`Failed to fetch market status for NFT ID ${nft.id}`, error);
          }
          return { id: nft.id, marketId, listed: "market", status: decodeBytes32String(marketStatus) };
        }
        return { id: nft.id, listed: "notListed" };
      })
    );

    // Update listed status of NFTs
    const listedStatusMap = statuses.reduce((acc, status) => {
      acc[status.id] = {
        listed: status.listed,
        marketId: Number(status.marketId) || null,
        auctionId: Number(status.auctionId) || null,
        status: status.status,
      };
      return acc;
    }, {});
    setListedStatus(listedStatusMap);

    // Fetch Drink token balance
    const drinkContract = new Contract(drinkContractAddress, drinkAbi, signer);
    const balance = await drinkContract.balanceOf(address);
    setDrinkBalance(formatUnits(balance, 18).split(".")[0]);
  }, [address, isConnected, walletProvider]);

  // Fetch NFT growth info
  const getGrowthInfo = async (tokenId) => {
    const ethersProvider = new BrowserProvider(walletProvider);
    const providerContract = new Contract(
      dragonContractAddress,
      dragonAbi,
      ethersProvider
    );
    const growInfo = await providerContract.getGrowthInfo(tokenId);

    const stages = ["egg", "hatch", "hatchling", "adult"];
    const currentStage = stages[Number(growInfo.currentStage)] || "unknown";

    setStage(currentStage);
    setTimeRemaining(Number(growInfo.timeRemaining));
    setSelectedNft(tokenId);
  };

  // Handle price input with validation
  const handlePriceChange = (e) => {
    let value = e.target.value;
    if (/^\d{0,10}(\.\d{0,5})?$/.test(value)) setPrice(value);
  };

  // Handle duration selection for NFT sale
  const handleDurationSelect = (value) => {
    const durationMap = {
      "1 hour": 1,
      "6 hours": 6,
      "1 day": 24,
      "3 days": 72,
      "7 days": 168,
      "1 month": 720,
      "3 months": 2160,
      "6 months": 4320,
    };

    const hours = durationMap[value];
    const endTime = new Date();
    endTime.setHours(endTime.getHours() + hours);

    setEndTime(endTime.toLocaleString());
    setDuration(value);
    setDurationSec(hours * 3600);
  };

  // Handle NFT listing for auction
  const listNftForAuction = async () => {
    try {
      await listNftOnMarket("listAuction");
    } catch (error) {
      console.error(error);
    }
  };

  // Handle NFT listing for sale
  const listNftForSale = async () => {
    try {
      await listNftOnMarket("listItem");
    } catch (error) {
      console.error(error);
    }
  };

  // Reusable function to list NFT on the market
  const listNftOnMarket = async (method) => {
    const ethersProvider = new BrowserProvider(walletProvider);
    const signer = await ethersProvider.getSigner();

    const marketContract = new Contract(
      marketContractAddress,
      marketAbi,
      signer
    );
    const dragonContract = new Contract(
      dragonContractAddress,
      dragonAbi,
      signer
    );

    const isApproved = await dragonContract.isApprovedForAll(
      address,
      marketContractAddress
    );

    if (!isApproved){
      const forwarderContract = new Contract(forwarderAddress, forwarderAbi, signer);
      
      const nonce = await getNonce(forwarderContract, address);
      
      const callFunction = dragonContract.interface.encodeFunctionData('setApprovalForAll', [marketContractAddress, true]);
    
      const estimatedGas = await dragonContract.setApprovalForAll.estimateGas(marketContractAddress, true);
      console.log(estimatedGas);
      
      const request = createRequest(address, dragonContractAddress, callFunction, nonce, estimatedGas);
      const result = await requestMetaTx(signer, request);

      console.log(result);
    }

    if (method === "listItem") {
      const callFunction = marketContract.interface.encodeFunctionData(method, [
        dragonContractAddress,
        sellSelectNft,
        durationSec,
        parseUnits(price, 18),
        1,
        true,
      ]);


      const forwarderContract = new Contract(forwarderAddress, forwarderAbi, signer);
      const nonce = await getNonce(forwarderContract, address);
      const request = createRequest(address, marketContractAddress, callFunction, nonce);

      const result = await requestMetaTx(signer, request);

      console.log(result);
      alert("Success");
      window.location.reload();
    } else if (method === "listAuction") {
      const callFunction = marketContract.interface.encodeFunctionData(method, [
        dragonContractAddress,
        sellSelectNft,
        durationSec,
        parseUnits(price, 18),
      ]);

      const forwarderContract = new Contract(forwarderAddress, forwarderAbi, signer);
      const nonce = await getNonce(forwarderContract, address);
      const request = createRequest(address, marketContractAddress, callFunction, nonce);

      const result = await requestMetaTx(signer, request);

      console.log(result);
      alert("Success");
      window.location.reload();
    }
  };

  // Handle evolution and feeding of selected NFT
  const evolveOrFeed = async (action) => {
    try {
      const ethersProvider = new BrowserProvider(walletProvider);
      const signer = await ethersProvider.getSigner();

      const contractInterface = getInterface(dragonAbi);
      const callFunction = contractInterface.encodeFunctionData(action, [selectedNft]);
      const forwarderContract = new Contract(forwarderAddress, forwarderAbi, signer);
      const nonce = await getNonce(forwarderContract, address);
      const request = createRequest(address, dragonContractAddress, callFunction, nonce);

      const result = await requestMetaTx(signer, request);
      console.log(result);
    
      alert("Success");
      window.location.reload();
    } catch (error) {
      alert("Failed");
    }
  };

  const resolveAuction = async (auctionId) => {
    try {
      const ethersProvider = new BrowserProvider(walletProvider);
      const signer = await ethersProvider.getSigner();

      const contractInterface = getInterface(marketAbi);
      const callFunction = contractInterface.encodeFunctionData('resolveAuction', [auctionId]);

      const forwarderContract = new Contract(forwarderAddress, forwarderAbi, signer);
      const nonce = await getNonce(forwarderContract, address);

      const request = createRequest(address, marketContractAddress, callFunction, nonce);

      const result = await requestMetaTx(signer, request);
      console.log(result);
    
      window.location.reload();
    } catch (error) {
      console.error(`Failed to resolve: ${error}`);
    }
  };

  const unlistItem = async(marketId) => {
    try {
      const ethersProvider = new BrowserProvider(walletProvider);
      const signer = await ethersProvider.getSigner();

      const contractInterface = getInterface(marketAbi);
      const callFunction = contractInterface.encodeFunctionData('unlistItem', [marketId]);

      const forwarderContract = new Contract(forwarderAddress, forwarderAbi, signer);
      const nonce = await getNonce(forwarderContract, address);

      const request = createRequest(address, marketContractAddress, callFunction, nonce);

      const result = await requestMetaTx(signer, request);
      console.log(result);
    
      window.location.reload();
    } catch (error) {
      console.error(`Failed to resolve: ${error}`);
    }
  }

  const evolve = () => evolveOrFeed("evolve");
  const feeding = () => evolveOrFeed("feeding");

  // Fetch user's NFTs upon connection
  useEffect(() => {
    if (isConnected) fetchMyNfts().catch(console.error);
  }, [fetchMyNfts, isConnected]);

  // Enable evolve button when timeRemaining reaches zero
  useEffect(() => {
    setIsEvolveBtnEnabled(timeRemaining === 0 && stage !== "adult");
  }, [timeRemaining, stage]);

  return (
    <PageContainer>
      <ProfileSection>
        <ProfileBanner>
          <ProfileInfo>
            <ProfileDetails>
              <WalletAddress>{truncateAccount}</WalletAddress>
              <ProfileStats>
                <Stat>Total Items: {nftIds.length}</Stat>
                <Stat>Total Value: {drinkBalance} Drink</Stat>
              </ProfileStats>
            </ProfileDetails>
          </ProfileInfo>
        </ProfileBanner>
      </ProfileSection>

      <ItemsSection>
        <ItemsHeader>
          <ViewModeSwitch>
            <button onClick={() => setViewMode("grid")}>Grid View</button>
            <button onClick={() => setViewMode("list")}>List View</button>
          </ViewModeSwitch>
          <SearchBar placeholder="Search items" />
          <SortDropdown>
            <option value="newest">Newest</option>
            <option value="oldest">Oldest</option>
            <option value="value">Highest Value</option>
          </SortDropdown>
        </ItemsHeader>

        <ItemsGrid viewMode={viewMode}>
          {nftIds.map((item) => (
            <NFTCard key={item.id} viewMode={viewMode}>
              <NFTImage src={item.imageUrl} alt={item.name} />
              <NFTInfo>
                <NFTName>{item.name}</NFTName>
                <NFTStatus>{item.status}</NFTStatus>
              </NFTInfo>
              <Button
                className="info"
                onClick={() => {
                  setShow(true);
                  setTokenInfo(item.tokenInfo);
                  getGrowthInfo(item.id);
                }}
                style={{ marginRight: "15px" }}
              >
                Info
              </Button>

              {listedStatus[item.id]?.status === "ENDED" ||
              listedStatus[item.id]?.status === "CANCELED" ? (
                <Button
                  className="resolve"
                  onClick={() =>
                    {listedStatus[item.id].listed === "market" ? 
                      unlistItem(listedStatus[item.id].marketId) : 
                      resolveAuction(listedStatus[item.id].auctionId)}
                  }
                >
                  Resolve
                </Button>
              ) : listedStatus[item.id]?.status === "ACTIVE" ? (
                <Button className="trading" disabled>
                  Trading...
                </Button>
              ) : (
                <Button
                  className="sell"
                  onClick={() => {
                    setIsSellModalOpen(true);
                    setSellSelectNft(item.id);
                  }}
                >
                  Sell
                </Button>
              )}
            </NFTCard>
          ))}
        </ItemsGrid>
      </ItemsSection>

      <CollectionInfoModal
        show={show}
        onHide={() => setShow(false)}
        info={tokenInfo}
        stage={stage}
        timeRemaining={timeRemaining}
        feeding={feeding}
        evolve={evolve}
      />

      <CollectionSellModal
        show={isSellModalOpen}
        onHide={() => {
          setIsSellModalOpen(false);
        }}
        price={price}
        handleDurationSelect={handleDurationSelect}
        handlePriceChange={handlePriceChange}
        endTime={endTime}
        duration={duration}
        listNftForAuction={listNftForAuction}
        listNftForSale={listNftForSale}
      />
    </PageContainer>
  );
}

export default Collection;
