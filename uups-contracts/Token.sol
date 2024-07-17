// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Breeding.sol";

contract Token is Breeding {
    uint256 public mintCount;
    bool public premiumMintEnabled;

    function InitializeToken(
        address initialOwner, 
        address _tokenTypeManager, 
        string memory name, 
        string memory symbol
    ) initializer public {
        Breeding.initializeBreed(initialOwner, _tokenTypeManager, name, symbol);
    }

    function nomalMint(address owner, string calldata tokenType) external {
        mintCount++;
        mintToken(tokenType, 0, 0, 1, owner, false);
    }

    function premiumMint(address owner, string calldata tokenType) external {
        require(premiumMintEnabled, "Premium minting is not enabled");
        mintCount++;
        mintToken(tokenType, 0,0,1,owner, true);
    }

    function getToken(uint256 id) external view returns(
        uint256 gender,
        uint256 husbandId,
        uint256 wifeId,
        uint256 generation,
        uint256 birth,
        string memory tokenType
        ){
            Token storage token = tokens[id];
            return (
                token.gender, 
                token.husbandId, 
                token.wifeId, 
                token.generation, 
                token.birth, 
                token.tokenType
            );
    }

    function getUserNftIds(address user) external view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](newTokenId);

        for (uint256 i = 1; i <= newTokenId; i++) {
            if (ownerOf(i) == user) {
                ids[i - 1] = i;

            }
        }
        return ids;
    }

    function isPremiumOpen(bool isEnabled) external onlyOwner {
        premiumMintEnabled = isEnabled;
    }
}