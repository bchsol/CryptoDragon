import marketContractData from "../contracts/marketContract";
import dragonContractData from "../contracts/dragonContract";
import { Contract, decodeBytes32String, encodeBytes32String } from "ethers";
import { fetchNftData } from "./fetchData";

const marketContractAddress = marketContractData.AddressSepolia;
const marketAbi = marketContractData.Abi;
const dragonContractAddress = dragonContractData.AddressSepolia;

export const fetchMarketItems = async (ethersProvider) => {
  const providerContract = new Contract(
    marketContractAddress,
    marketAbi,
    ethersProvider
  );

  const filterFn = async(item) => 
    await providerContract.getSaleStatus(item) == encodeBytes32String("ACTIVE");
  return fetchMarketItemsData(ethersProvider, filterFn);
};

export const fetchHistory = async (ethersProvider) => {
  const providerContract = new Contract(
    marketContractAddress,
    marketAbi,
    ethersProvider
  );
  const marketFilterFn = async(itemId) => 
    await providerContract.getSaleStatus(itemId) !== 
    encodeBytes32String("ACTIVE") || encodeBytes32String("NOTLISTED");

  const auctionFilterFn = async(itemId) => 
    await providerContract.getAuctionStatus(itemId) !== 
    encodeBytes32String("ACTIVE") || encodeBytes32String("NOTLISTED");

  const marketHistory = await fetchMarketItemsData(ethersProvider, marketFilterFn);
  const auctionHistory = await fetchAuctionItemsData(ethersProvider, auctionFilterFn);

  const marketStatus = await Promise.all(marketHistory.map(async (item) => {
    const saleStatus = decodeBytes32String(await providerContract.getSaleStatus(item.itemId));
    return { ...item, saleStatus };
  }));

  const auctionStatus = await Promise.all(auctionHistory.map(async (item) => {
    const auctionStatus = decodeBytes32String(await providerContract.getAuctionStatus(item.itemId));
    return { ...item, auctionStatus };
  }));

  return { marketHistory: marketStatus, auctionHistory: auctionStatus };
};

export const fetchAuctionItems = async (ethersProvider) => {
  const providerContract = new Contract(
    marketContractAddress,
    marketAbi,
    ethersProvider
  );

  const filterFn = async(item) => 
    await providerContract.getAuctionStatus(item) === encodeBytes32String("ACTIVE");
  return fetchAuctionItemsData(ethersProvider, filterFn);
};

export const fetchAuctionItemsData = async (ethersProvider, filterFn) => {
  try {
    const providerContract = new Contract(
      marketContractAddress,
      marketAbi,
      ethersProvider
    );
    const maxItemId = await providerContract._auctionIds();
    const fetchItems = [];

    for (let i = 1; i <= maxItemId; i++) {
      try {
        const item = await providerContract.auctionItems(i);
        if (filterFn(item)) {
          fetchItems.push(item);
        }
      } catch (error) {
        console.error(error);
      }
    }

    return await processAuctionItems(fetchItems, ethersProvider);
  } catch (error) {
    console.error(error);
  }
};

export const fetchMarketItemsData = async (ethersProvider, filterFn) => {
  try {
    const providerContract = new Contract(
      marketContractAddress,
      marketAbi,
      ethersProvider
    );

    const maxItemId = await providerContract._saleIds();
    const fetchItems = [];

    for (let i = 1; i <= maxItemId; i++) {
      try {
        const item = await providerContract.items(i);
        if (await filterFn(item.itemId)) {
          fetchItems.push(item);
        }
      } catch (error) {
        console.error(error);
      }
    }
    return await processItems(fetchItems, ethersProvider);
  } catch (error) {
    console.error("Failed to fetch market items: ", error);
    throw error;
  }
};

const processItems = async (items, ethersProvider) => {
  const nfts = await Promise.allSettled(
    items.map(async (item) => {
      const metadata = await fetchNftData(ethersProvider, item.tokenId);
      return {
        nftContract: item.tokenAddress,
        itemId: Number(item.itemId),
        owner: item.owner,
        price: item.price,
        quantity: Number(item.quantity),
        startTime: Number(item.startTime),
        endTime: Number(item.endTime),
        sold: item.sold,
        cancel: item.cancel,
        ...metadata,
      };
    })
  );

  return nfts
    .filter((result) => result.status === "fulfilled")
    .map((result) => result.value);
};

const processAuctionItems = async (items, ethersProvider) => {
  const nfts = await Promise.allSettled(
    items.map(async (item) => {
      const metadata = await fetchNftData(ethersProvider, item.tokenId);

      const bidInfo = await fetchBidInfo(ethersProvider, item.itemId);

      return {
        nftContract: item.tokenAddress,
        itemId: Number(item.itemId),
        owner: item.owner,
        price: item.reservePrice,
        startTime: Number(item.startTime),
        endTime: Number(item.endTime),
        sold: item.sold,
        cancel: item.cancel,
        ...metadata,
        bidInfo,
      };
    })
  );

  return nfts
    .filter((result) => result.status === "fulfilled" && result.value !== null)
    .map((result) => result.value);
};

export const fetchBidInfo = async (ethersProvider, auctionId) => {
  try {
    const providerContract = new Contract(
      marketContractAddress,
      marketAbi,
      ethersProvider
    );

    const listed = await providerContract.auctionItems(auctionId);

    if (listed.itemId != 0) {
      const highestBidder =
        (await providerContract.highestBidder(auctionId)) || "0";
      const bidDetails = await providerContract.bids(auctionId, highestBidder);
      const status = await providerContract.getAuctionStatus(auctionId);

      return {
        auctionId: Number(auctionId),
        highestBidder: highestBidder,
        price: Number(bidDetails.price),
        timestamp: Number(bidDetails.timestamp),
        status: decodeBytes32String(status),
      };
    }

    return null;
  } catch (error) {
    console.error("Failed to fetch bid information: ", error);
    return null;
  }
};
