import React, { useCallback, useEffect, useState } from "react";
import { useWeb3ModalProvider,useWeb3ModalAccount } from "@web3modal/ethers/react";
import { BrowserProvider, Contract, formatUnits } from "ethers";
import { useNavigate } from "react-router-dom";

import {
  fetchMarketItems,
  fetchAuctionItems,
  fetchHistory,
} from "../blockchain/fetchMarketData";
import marketContractData from "../contracts/marketContract";

import {
  BannerSection,
  Container,
  FilterForm,
  FilterSection,
  ProfileImage,
  ProfileInfo,
  SearchBar,
  Card,
  Grid,
  CardImage,
  CardBody,
  SortDropdown,
  MainSection,
  SearchBarContainer,
  ContentSection,
  Tab,
  Tabs,
  SubTabs,
  SubTab,
  CheckboxLabel,
  CheckboxInput,
  CheckboxWrapper,
  Button,
} from "../Style/marketStyles";

import secretEggImage from "../image/secret_egg.png";
import { createRequest, getInterface, getNonce, requestMetaTx } from "../utils/relay";
import forwarder from "../contracts/forwarder";

// Constants for market contract address and ABI
const marketContractAddress = marketContractData.AddressSepolia;
const marketAbi = marketContractData.Abi;

const forwarderAddress = forwarder.AddressSepolia;
const forwarderAbi = forwarder.Abi;

function MarketPlace() {
  // State management for different components
  const [marketItems, setMarketItems] = useState([]);
  const [history, setHistory] = useState({
    marketHistory: [],
    auctionHistory: [],
  });
  const [auctionItems, setAuctionItems] = useState([]);
  const [filteredItems, setFilteredItems] = useState([]);
  const [isLoading, setIsLoading] = useState(true);

  // Web3 and router hooks
  const { address, isConnected } = useWeb3ModalAccount();
  const { walletProvider } = useWeb3ModalProvider();
  const navigate = useNavigate();

  // Filters and search/sort options
  const [filter, setFilter] = useState("All");
  const [sortOption, setSortOption] = useState("Price low to high");
  const [searchQuery, setSearchQuery] = useState("");
  const [activeTab, setActiveTab] = useState("market");
  const [activeSubTab, setActiveSubTab] = useState("market");
  const [showOnlyUserListings, setShowOnlyUserListings] = useState(false);

  // 1. Handle search input changes
  const handleSearchChange = (e) => {
    setSearchQuery(e.target.value);
  };

  // 2. Fetching data based on the active tab
  const loadData = useCallback(async () => {
    try {
      setIsLoading(true);
      const ethersProvider = new BrowserProvider(walletProvider);

      if (!isConnected) throw new Error("User disconnected");

      if (activeTab === "market") {
        const items = await fetchMarketItems(ethersProvider);
        setMarketItems(items);
      } else if (activeTab === "auction") {
        const items = await fetchAuctionItems(ethersProvider);
        setAuctionItems(items);
      } else if (activeTab === "history") {
        const { marketHistory = [], auctionHistory = [] } = await fetchHistory(
          ethersProvider
        );
        setHistory({ marketHistory, auctionHistory });
      }
    } catch (error) {
      console.error("Failed to load data: ", error);
    } finally {
      setIsLoading(false);
    }
  }, [activeTab, walletProvider, isConnected]);

  // 3. Filtering and sorting items based on user input
  const filterItems = useCallback(() => {
    let items = activeTab === "history" 
    ? (activeSubTab === "market" ? history.marketHistory : history.auctionHistory) 
    : (activeTab === "market" ? marketItems : auctionItems);

    const filtered = items
      .filter((item) => {
        const matchesFilter = filter === "All" || item.status === filter;
        const matchesUserListings =
          !showOnlyUserListings ||
          item.owner.toLowerCase() === address.toLowerCase();
        return matchesFilter && matchesUserListings;
      })
      .filter((item) =>
        item.name.toLowerCase().includes(searchQuery.toLowerCase())
      )
      .sort((a, b) => {
        if (sortOption === "Price low to high") {
          return Number(a.price - b.price);
        } else if (sortOption === "Price high to low") {
          return Number(b.price - a.price);
        }
        return 0;
      });

    setFilteredItems(filtered);
  }, [
    activeTab,
    activeSubTab,
    marketItems,
    auctionItems,
    history,
    filter,
    showOnlyUserListings,
    searchQuery,
    sortOption,
    address,
  ]);

  // 4. Get lowest price utility function
  const getLowestPrice = (items) => {
    if (items.length === 0) return "N/A";
    const lowestPriceItem = items.reduce((prev, current) =>
      Number(prev.price) < Number(current.price) ? prev : current
    );
    return formatUnits(lowestPriceItem.price, 18).split(".")[0];
  };

  // Trigger filtering when dependencies change
  useEffect(() => {
    filterItems();
  }, [filterItems]);

  // Load data when activeTab changes
  useEffect(() => {
    loadData();
  }, [loadData]);

  // Handle item click to navigate to item details
  const handleItemClick = (itemId) => {
    const itemType =
      activeTab === "market"
        ? "market"
        : activeTab == "auction"
        ? "auction"
        : "history";
    navigate(`/item/${itemId}?type=${itemType}`);
  };

  // Handle contract interactions like unlisting items
  const handleTransaction = async (contractMethod, itemId) => {
    try {
      const ethersProvider = new BrowserProvider(walletProvider);
      const signer = await ethersProvider.getSigner();
      const contractInterface = getInterface(marketAbi);
      const callFunction = contractInterface.encodeFunctionData(contractMethod, [itemId]);

      const forwarderContract = new Contract(forwarderAddress, forwarderAbi, signer);
      const nonce = await getNonce(forwarderContract, address);
      const request = createRequest(address, marketContractAddress, callFunction, nonce);
      const result = await requestMetaTx(signer, request);

      console.log(result);
      window.location.reload();
    } catch (error) {
      console.error('Failed to transaction', error);
    }
  };

  if (isLoading) {
    return <div>Loading...</div>;
  }

  const totalItems = filteredItems.length;
  const lowestPrice = getLowestPrice(filteredItems);

  return (
    <Container>
      {/* Banner with profile info */}
      <BannerSection>
        <ProfileImage src={secretEggImage} alt="Profile" />
        <ProfileInfo>
          <h1>Dragon Collection</h1>
          <p>Items: {totalItems} | Floor Price: {lowestPrice} Drink</p>
        </ProfileInfo>
      </BannerSection>

      {/* Tabs and SubTabs */}
      <Tabs>
        {/* Market, Auction, and History Tabs */}
        {["market", "auction", "history"].map(tab => (
          <Tab key={tab} active={activeTab === tab} onClick={() => setActiveTab(tab)}>
            {tab.charAt(0).toUpperCase() + tab.slice(1)}
          </Tab>
        ))}
      </Tabs>

      {activeTab === "history" && (
        <SubTabs>
          {/* SubTabs for market and auction history */}
          {["market", "auction"].map(subTab => (
            <SubTab key={subTab} active={activeSubTab === subTab} onClick={() => setActiveSubTab(subTab)}>
              {subTab.charAt(0).toUpperCase() + subTab.slice(1)} History
            </SubTab>
          ))}
        </SubTabs>
      )}

      <MainSection>
        {/* Filters and sorting UI */}
        <FilterSection>
          <h5>Filters</h5>
          <FilterForm>
            <select value={filter} onChange={(e) => setFilter(e.target.value)}>
              <option value="All">All</option>
            </select>
          </FilterForm>
          <CheckboxWrapper>
            <CheckboxInput
              type="checkbox"
              id="showOnlyUserListings"
              checked={showOnlyUserListings}
              onChange={(e) => setShowOnlyUserListings(e.target.checked)}
            />
            <CheckboxLabel htmlFor="showOnlyUserListings">
              {"My Listed"}
            </CheckboxLabel>
          </CheckboxWrapper>
        </FilterSection>

        {/* Content section with search and items display */}
        <ContentSection>
          <SearchBarContainer>
            <SearchBar
              type="text"
              placeholder="Search by name or trait"
              value={searchQuery}
              onChange={handleSearchChange}
            />
            <SortDropdown
              value={sortOption}
              onChange={(e) => setSortOption(e.target.value)}
            >
              <option value="Price low to high">Price low to high</option>
              <option value="Price high to low">Price high to low</option>
            </SortDropdown>
          </SearchBarContainer>

          {/* Grid display of items */}
          <Grid>
            {filteredItems.map((nftItem) => (
              <Card
                key={nftItem.id}
                onClick={activeTab !== "history" ? () => handleItemClick(nftItem.itemId) : undefined}
                onMouseEnter={(e) => {
                  e.currentTarget.style.transform = "scale(1.02)";
                  e.currentTarget.style.boxShadow =
                    "0 4px 8px rgba(0, 0, 0, 0.2)";
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.transform = "scale(1)";
                  e.currentTarget.style.boxShadow = "none";
                }}
              >
                <CardImage src={nftItem.imageUrl} alt={nftItem.name} />
                <CardBody>
                  <h3>{nftItem.name}</h3>
                  <p>
                    {activeTab === "auction"
                      ? `Reserve Price: ${
                          formatUnits(nftItem.price, 18).split(".")[0]
                        }`
                      : `Price: ${
                          formatUnits(nftItem.price, 18).split(".")[0]
                        }`
                    }
                    <br />
                    {activeTab === "auction" && nftItem.bidInfo?.price
                      ? `Current Bid: ${
                          formatUnits(String(nftItem.bidInfo.price), 18).split(
                            "."
                          )[0]
                        }`
                      : ""
                    }
                    {activeTab === "history" && activeSubTab === "market"
                     ? `${nftItem.saleStatus}` : activeSubTab === "auction" 
                     ? `${nftItem.auctionStatus}`: ""
                    }
                  </p>
                  {activeTab === "market" &&
                  nftItem.owner.toLowerCase() ===
                    address.toLocaleLowerCase() ? (
                    <Button
                      onClick={(e) => {
                        e.stopPropagation();
                        handleTransaction("unlistItem", nftItem.itemId);
                      }}
                    >
                      Unsell
                    </Button>
                  ) : activeTab === "auction" &&
                    nftItem.owner.toLowerCase() ===
                      address.toLocaleLowerCase() ? (
                    <Button
                      onClick={(e) => {
                        e.stopPropagation();
                        handleTransaction("cancelAuction", nftItem.itemId);
                      }}
                    >
                      Cancel
                    </Button>
                  ) : (
                    ""
                  )}
                </CardBody>
              </Card>
            ))}
          </Grid>
        </ContentSection>
      </MainSection>
    </Container>
  );
}
export default MarketPlace;
