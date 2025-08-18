// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {NotifyLib} from "../libraries/NotifyLib.sol";

interface IPremiumSendMail {
  function sendEmailFromManager(address legacy, NotifyLib.NotifyType notifyType) external;

  //BEFORE ACTIVATION
  function sendEmailBeforeActivationToOwner(
    string memory ownerName,
    string memory contractName,
    uint256 lastTx,
    uint256 bufferTime,
    address[] memory listBene,
    string memory ownerEmail
  ) external;

  function sendEmailBeforeActivationToBeneficiary(
    string[] memory beneNames,
    string memory contractName,
    uint256 timeCountdown,
    string[] memory beneEmails
  ) external;

  function sendEmailBeforeLayer2ToLayer1(string[] memory beneNames, string[] memory beneEmails, string memory contractName, uint256 x_days) external;

  function sendEmailBeforeLayer2ToLayer2(string memory beneName, string memory beneEmail, string memory contractName, uint256 x_days) external;

  function sendEmailBeforeLayer3ToLayer12(string[] memory beneNames, string[] memory beneEmails, string memory contractName, uint256 x_days) external;
  function sendEmailBeforeLayer3ToLayer3(string memory beneName, string memory beneEmail, string memory contractName, uint256 x_day) external;

  function sendEmailReadyToActivateToLayer1(string[] memory beneName, string[] memory beneEmail, string memory contractName) external;

  //READY TO ACTIVATE
  function sendEmailReadyToActivateLayer2ToLayer1(
    string[] memory beneNameLayer1,
    string[] memory beneEmailLayer1,
    address beneAddressLayer2,
    string memory contractName,
    uint256 timeActiveLayer2
  ) external;

  function sendEmailReadyToActivateLayer2ToLayer2(string memory beneName, string memory beneEmail, string memory contractName) external;

  function sendEmailReadyToActivateLayer3ToLayer12(
    string[] memory beneName,
    string[] memory beneEmail,
    string memory contractName,
    uint256 activationDate,
    address layer3Addr
  ) external;

  function sendEmailReadyToActivateLayer3ToLayer3(string memory beneName, string memory beneEmail, string memory contractName) external;

  function sendEmailActivatedToLayer1(
    string memory beneName,
    string memory beneEmail,
    string memory contractName,
    address[] memory listToken,
    uint256[] memory listAmount,
    string[] memory listAssetName
  ) external;

  function sendEmailActivatedToLayer2(
    string memory beneName,
    string memory beneEmail,
    string memory contractName,
    address[] memory listToken,
    uint256[] memory listAmount,
    string[] memory listAssetName
  ) external;

  function sendMailOwnerResetToBene(string[] memory beneNames, string[] memory beneEmails, string memory contractName) external;

  //ACTIVATED
  function sendMailActivatedMultisig(string[] memory beneNames, string[] memory beneEmails, string memory contractName, address safeWallet) external;

  function sendEmailActivatedToBene(
    string memory beneName,
    string memory beneEmail,
    string memory contractName,
    address[] memory listToken,
    uint256[] memory listAmount,
    string[] memory listAssetName,
    address contractAddress,
    bool remaining
  ) external;

  function sendEmailContractActivatedToOwner(
    string memory toEmail,
    string memory contractName,
    address activatedByBene,
    uint256 timeActivated,
    address safeWallet,
    NotifyLib.ListAsset[] memory _listAsset,
    NotifyLib.BeneReceived[] memory _listBeneReceived,
    address contractAddress,
    bool remaining
  ) external;
}
