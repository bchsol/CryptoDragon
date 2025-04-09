import questContractData from "../contracts/questContract";

import { Contract } from "ethers";

const questAddress = questContractData.AddressSepolia;
const questAbi = questContractData.Abi;

export const getQuestData = async (ethersProvider, address) => {
  try {
    const signer = await ethersProvider.getSigner();
    const providerContract = new Contract(questAddress, questAbi, signer);

    const battleCompleted = await providerContract.getBattleCompleted(address);
    const exploreCompleted = await providerContract.getExploreCompleted(
      address
    );

    return { battleCompleted, exploreCompleted };
  } catch (error) {
    console.error("Failed to Data: ", error);
    throw error;
  }
};
