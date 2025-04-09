// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IQuest {
    struct QuestData{
        bool dailyCheck;
        bool exploration;
        bool battle;
    }
    function battleCheck(address user) external;
    function exploreCheck(address user) external;
    function dailyCheck(address user) external returns(bool);
    function getBattleCompleted(address user) external view returns(bool);
    function getExploreCompleted(address user) external view returns(bool);
}