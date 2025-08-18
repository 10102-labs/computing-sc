// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "../libraries/NotifyLib.sol";
interface IPremiumNotification {
    function sendPushNoti(address[] memory recipients, string calldata title, string calldata notification) external;   
    function handleLegacyNotify(address legacy, NotifyLib.NotifyType notifyType) external;
    function notifyTransferActivation(uint8 layer, address legacy, string calldata contractName, bool remaining) external; 
    function notifyOwnerReset(address legacy) external;
    function notifyMultisigActivation(address legacy) external;
} 