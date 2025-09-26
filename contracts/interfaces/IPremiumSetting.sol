// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "../libraries/NotifyLib.sol";

interface IPremiumSetting {
  function updatePremiumTime(address user, uint256 duration) external;
  function premiumExpired(address user) external view returns (uint256 expiredTimestamp);
  function isPremium(address user) external view returns (bool);
  function getTimeAhead(address user) external view returns (uint256);
  function setPrivateCodeAndCronjob(address user, address legacyAddress) external;
  function getUserData(address user) external view returns (string memory, string memory, uint256);
  function getCosignerData(address legacyAddress) external view returns (address[] memory, string[] memory, string[] memory);
  function getBeneficiaryData(address legacyAddress) external view returns (address[] memory, string[] memory, string[] memory);
  function getSecondLineData(address legacyAddress) external view returns (address, string memory, string memory);
  function getThirdLineData(address legacyAddress) external view returns (address, string memory, string memory);

  //reminder
  function triggerActivationMultisig(address legacyAddress) external;
  function triggerOwnerResetReminder(address legacyAddress) external;
  function triggerActivationTransferLegacy(
    NotifyLib.ListAsset[] memory listAsset, 
    NotifyLib.BeneReceived[] memory _listBeneReceived,
    bool remaining) external;
}
