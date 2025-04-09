// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IToken {
    enum GrowthStage {Egg, Hatch, Hatchling, Adult}
    
    enum Personality {
        Naive, Rash, Hasty, QuickWitted, Brave, Quirky, Adamant, Bold, Quiet, Calm, Careful, Hardy, Docile, Bashful, Lax, Smart
    }

    function balanceOf(address account, uint256 id) external view returns(uint256);
    function ownerOf(uint256 tokenId) external view returns(address owner);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
    function approve(address to, uint256 tokenId) external;
    function isApprovedForAll(address owner, address operator) external view returns(bool);
    function setApprovalForAll(address operator, bool approved) external;
    function supportsInterface(bytes4 interfaceID) external returns(bool);

    function getUserNftIds(address user) external view returns(uint256[] memory);
    function getGrowthInfo(uint256 tokenId) external view returns(GrowthStage, uint256);
    function changePersonality(uint256 tokenId, Personality newPersonality) external;
    function changeGender(uint256 tokenId) external;
    function resetTraining(uint256 tokenId) external;
}