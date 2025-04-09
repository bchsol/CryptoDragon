import React from "react";
import "../Style/mintStyles";
import dragonContractData from "../contracts/dragonContract";
import forwarder from "../contracts/forwarder";

import { useWeb3ModalProvider,useWeb3ModalAccount } from "@web3modal/ethers/react";
import { ethers } from "ethers";

import {
  EggContainer,
  MintButton,
  MintPageContainer,
} from "../Style/mintStyles";
import { createRequest, getInterface, requestMetaTx, getNonce } from "../utils/relay";

const contractAddress = dragonContractData.AddressSepolia;
const abi = dragonContractData.Abi;

const forwarderAddress = forwarder.AddressSepolia;
const forwarderAbi = forwarder.Abi;

function Mint() {
  const { address } = useWeb3ModalAccount();
  const { walletProvider } = useWeb3ModalProvider();

  const handleMint = async () => {
    try {
      const ethersProvider = new ethers.BrowserProvider(walletProvider);
      const signer = await ethersProvider.getSigner();

      const contractInterface = getInterface(abi);
      const callFunction = contractInterface.encodeFunctionData('normalMint(address)', [address]);

      const forwarderContract = new ethers.Contract(forwarderAddress, forwarderAbi, signer);
      const nonce = await getNonce(forwarderContract, address);

      const request = createRequest(address, contractAddress, callFunction, nonce);

      const result = await requestMetaTx(signer, request);
      console.log(result);
      if(result.status === 'success'){
        alert("Minting Success");
        window.location.reload();
      } else{
        alert("Mint error");
      } 
    } catch (error) {
      console.error("Failed to Mint", error);
    }
  };

  return (
    <MintPageContainer>
      <EggContainer />
      <MintButton onClick={() => handleMint()}>Mint</MintButton>
    </MintPageContainer>
  );
}
export default Mint;
