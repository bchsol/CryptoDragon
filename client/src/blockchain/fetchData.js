import dragonContractData from "../contracts/dragonContract";
import { Contract } from "ethers";

const contractAddress = dragonContractData.AddressSepolia;
const abi = dragonContractData.Abi;

const fetchMetadata = async (ethersProvider, tokenId) => {
  try {
    const providerContract = new Contract(contractAddress, abi, ethersProvider);
    const [name, metadataUrl, tokenInfo, growthInfo] = await Promise.all([
      providerContract.name(),
      providerContract.tokenURI(tokenId),
      providerContract.getToken(tokenId),
      providerContract.getGrowthInfo(tokenId),
    ]);

    const tokenUrl = metadataUrl.replace("data:application/json;utf8,", "");
    const jsonObject = JSON.parse(tokenUrl);
    const imageUrl = jsonObject.image;

    const tokenName = `${name} #${tokenId}`;

    return { tokenName, imageUrl, tokenInfo, growthInfo };
  } catch (error) {
    console.error("Failed to fetch metadata:", error);
    throw error;
  }
};

export const fetchNftData = async (ethersProvider, tokenId) => {
  try {
    const { tokenName, imageUrl, tokenInfo, growthInfo } = await fetchMetadata(
      ethersProvider,
      tokenId
    );
    return {
      id: Number(tokenId),
      name: tokenName,
      tokenInfo,
      imageUrl,
      growthInfo,
    };
  } catch (error) {
    console.error("Failed to fetch NFT data:", error);
    throw error;
  }
};

export const fetchNfts = async (ethersProvider, address) => {
  try {
    const signer = await ethersProvider.getSigner();
    const signerContract = new Contract(contractAddress, abi, signer);

    const tokenIds = await signerContract.getUserNftIds(address);

    const nfts = await Promise.allSettled(
      tokenIds.map((tokenId) => fetchNftData(ethersProvider, tokenId))
    );
    const fulfilledNfts = nfts
      .filter((result) => result.status == "fulfilled")
      .map((result) => result.value);
    return fulfilledNfts;
  } catch (error) {
    console.error("Failed to fetch NFTs:", error);
    throw error;
  }
};
