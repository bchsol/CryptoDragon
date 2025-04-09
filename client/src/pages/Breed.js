import React, { useState, useEffect } from "react";
import NftSelectionModal from "./NftSelectionModal";
import dragonContractData from "../contracts/dragonContract";
import {
  BreedPageContainer,
  BoxContainer,
  Box,
  BreedButton,
  HeartIcon,
  EggProbabilityContainer,
  EggBox,
  DragonName,
} from "../Style/BreedStyles";
import { fetchNfts } from "../blockchain/fetchData";
import { useWeb3ModalProvider,useWeb3ModalAccount } from "@web3modal/ethers/react";
import { BrowserProvider, Contract } from "ethers";

import heartImage from "../image/heart.png";
import eggImage from "../image/secret_egg.png";
import forwarder from "../contracts/forwarder";
import { createRequest, getInterface, getNonce, requestMetaTx } from "../utils/relay";

const contractAddress = dragonContractData.AddressSepolia;
const abi = dragonContractData.Abi;
const forwarderAddress = forwarder.AddressSepolia;
const forwarderAbi = forwarder.Abi;

const dataUrl = process.env.REACT_APP_DATA_URL;

function Breed() {
  const [isMaleModalOpen, setIsMaleModalOpen] = useState(false);
  const [isFemaleModalOpen, setIsFemaleModalOpen] = useState(false);
  const [selectedHusband, setSelectedHusband] = useState(null);
  const [selectedWife, setSelectedWife] = useState(null);

  const [maleNftIds, setMaleNftIds] = useState([]);
  const [femaleNftIds, setFemaleNftIds] = useState([]);

  const { address, isConnected } = useWeb3ModalAccount();
  const { walletProvider } = useWeb3ModalProvider();

  useEffect(() => {
    if (isMaleModalOpen) {
      showMaleNfts();
    }
  }, [isMaleModalOpen]);

  useEffect(() => {
    if (isFemaleModalOpen) {
      showFemaleNfts();
    }
  }, [isFemaleModalOpen]);

  const showMaleNfts = async () => {
    try {
      const ethersProvider = new BrowserProvider(walletProvider);
      const nfts = await fetchNfts(ethersProvider, address);
      setMaleNftIds(nfts.filter(nft => Number(nft.growthInfo.currentStage) == 3 && nft.tokenInfo.gender == 1));
    } catch (error) {
      console.error("Error fetching male NFTs:", error);
    }
  };

  const showFemaleNfts = async () => {
    try {
      const ethersProvider = new BrowserProvider(walletProvider);
      const nfts = await fetchNfts(ethersProvider, address);
      setFemaleNftIds(nfts.filter(nft => Number(nft.growthInfo.currentStage) == 3 && nft.tokenInfo.gender == 2));
    } catch (error) {
      console.error("Error fetching female NFTs:", error);
    }
  };

  const breed = async () => {
    try {
      if (!isConnected) throw Error("User disconnected");
      const ethersProvider = new BrowserProvider(walletProvider);
      const signer = await ethersProvider.getSigner();
      
      const contractInterface = getInterface(abi);
      const callFunction = contractInterface.encodeFunctionData('breedTokens', [Number(selectedHusband.id), Number(selectedWife.id)]);

      const forwarderContract = new Contract(forwarderAddress, forwarderAbi, signer);
      const nonce = await getNonce(forwarderContract, address);

      const request = createRequest(address, contractAddress, callFunction, nonce);

      const result = await requestMetaTx(signer, request);
      console.log(result);
      //window.location.reload();
    } catch (error) {
      console.log(error);
      alert("Failed");
    }
  };

  const checkHandleMale = (nft) => setSelectedHusband(selectedHusband && selectedHusband.id == nft.id ? null : nft);
  const checkHandleFemale = (nft) => setSelectedWife(selectedWife && selectedWife.id == nft.id ? null : nft);

  return (
    <BreedPageContainer>
      <NftSelectionModal
        show={isMaleModalOpen}
        onHide={() => setIsMaleModalOpen(false)}
        nftIds={maleNftIds}
        selectedNft={selectedHusband}
        onSelectNft={checkHandleMale}
        title="Select Husband NFT"
        onConfirm={() => setIsMaleModalOpen(false)}
      />

      <NftSelectionModal
        show={isFemaleModalOpen}
        onHide={() => setIsFemaleModalOpen(false)}
        nftIds={femaleNftIds}
        selectedNft={selectedWife}
        onSelectNft={checkHandleFemale}
        title="Select Wife NFT"
        onConfirm={() => setIsFemaleModalOpen(false)}
      />

      <BoxContainer>
        <Box
          onClick={() => {
            setIsMaleModalOpen(true);
          }}
        >
          {selectedHusband ? (
            <>
              <img src={selectedHusband.imageUrl} alt="Husband Dragon" />
              <DragonName>{selectedHusband.name}</DragonName>
            </>
          ) : (
            "Select Husband"
          )}
        </Box>

        {selectedHusband && selectedWife && (
          <HeartIcon src={heartImage} alt="Heart Icon" />
        )}

        <Box
          onClick={() => {
            setIsFemaleModalOpen(true);
          }}
        >
          {selectedWife ? (
            <>
              <img src={selectedWife.imageUrl} alt="Wife Dragon" />
              <DragonName>{selectedWife.name}</DragonName>
            </>
          ) : (
            "Select Wife"
          )}
        </Box>
      </BoxContainer>

      {selectedHusband && selectedWife && (
        <EggProbabilityContainer>
          {selectedHusband.tokenInfo.tokenType ===
          selectedWife.tokenInfo.tokenType ? (
            <EggBox>
              <img
                src={`${dataUrl}${selectedHusband.tokenInfo.tokenType}_egg.webp
                `}
                alt="Egg Type"
              />
              <span>100%</span>
            </EggBox>
          ) : (
            <>
              <EggBox>
                <img
                  src={`${dataUrl}${selectedHusband.tokenInfo.tokenType}_egg.webp
                  `}
                  alt="Egg Type 1"
                />
                <span>50%</span>
              </EggBox>

              <EggBox>
                <img
                  src={`${dataUrl}${selectedWife.tokenInfo.tokenType}_egg.webp
                  `}
                  alt="Egg Type 2"
                />
                <span>50%</span>
              </EggBox>
            </>
          )}
        </EggProbabilityContainer>
      )}

      <BreedButton onClick={breed}>Breed Now</BreedButton>
    </BreedPageContainer>
  );
}

export default Breed;
