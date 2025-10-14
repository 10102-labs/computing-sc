// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "../libraries/NotifyLib.sol";


interface IPremiumAutomationManager {
    function addLegacyCronjob(address user, address [] memory  legacyAddresses) external ;
    function sendNotifyFromCronjob(address legacy, NotifyLib.NotifyType notifyType) external ;

}