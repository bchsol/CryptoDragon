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
    
        // 환경 변수 확인 및 기본값 설정
        const relayUrl = process.env.REACT_APP_RELAY_URL;
        const url = `${relayUrl}/relay`;
        
        const response = await fetch(url, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({request, signature}),
        });

        // 응답 상태 확인
        if (!response.ok) {
            const errorText = await response.text();
            console.error('서버 응답 오류:', response.status, errorText);
            throw new Error(`서버 오류: ${response.status} - ${errorText.substring(0, 100)}...`);
        }

        // 응답이 JSON인지 확인
        const contentType = response.headers.get('content-type');
        if (!contentType || !contentType.includes('application/json')) {
            const text = await response.text();
            console.error('서버가 JSON이 아닌 응답을 반환했습니다:', text.substring(0, 200));
            throw new Error('서버가 JSON이 아닌 응답을 반환했습니다');
        }

        const result = await response.json();
        return result;
    } catch(error) {
        console.error('Error in signAndSubmitForwardRequest: ', error);
        throw error;
    }
}