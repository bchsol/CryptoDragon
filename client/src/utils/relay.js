import { ethers } from "ethers";
import forwarder from "../contracts/forwarder";

const forwarderAddress = forwarder.AddressSepolia;
const domain = {
    name: 'ERC2771Forwarder',
    version: '1',
    chainId: 11155111,
    verifyingContract: forwarderAddress
}

const types = {
    ForwardRequest: [
      {name: 'from', type: 'address'},
      { name: 'to', type: 'address' },
      { name: 'value', type: 'uint256' },
      { name: 'gas', type: 'uint256' },
      { name:'nonce', type: 'uint256'},
      { name: 'deadline', type: 'uint48' },
      { name: 'data', type: 'bytes' },
    ]
}

export const getInterface = (abi) => {
    return new ethers.Interface(abi);
}

export const getNonce = async (forwarderContract, address) => {
    const nonce = await forwarderContract.nonces(address).then((n) =>n.toString());
    return Number(nonce);
}

export const createRequest = (address, contractAddress, callFunction, nonce) => {
    return {
        from: address,
        to: contractAddress,
        value: 0,
        gas: 3e6,
        nonce,
        deadline: Math.floor(Date.now() / 1000) + 1000,
        data: callFunction,
    };
}

export const requestMetaTx = async (signer, request) => {
    try{
        const signature = await signer.signTypedData(domain, types, request);
    
        const url = `${process.env.RELAY_URL}/relay`
        const response = await fetch(url, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({request, signature}),
    });

    const result = await response.json();
    return result;
    } catch(error) {
        console.error('Error in signAndSubmitForwardRequest: ', error);
        throw error;
    }

}