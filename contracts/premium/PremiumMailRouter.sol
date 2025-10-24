// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IPremiumLegacy.sol";
import "../interfaces/IPremiumSetting.sol";
import "../interfaces/IPremiumSendMail.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../libraries/NotifyLib.sol";

contract PremiumMailRouter is OwnableUpgradeable {
  address public mailBeforeActivation;
  address public mailActivated;
  address public mailReadyToActivate;
  address public premiumSetting;
  address public automationManager;
  uint256 public mailId;

  modifier onlySetting() {
    require(msg.sender == premiumSetting || msg.sender == owner(), "Only setting");
    _;
  }

  modifier onlyManager() {
    require(msg.sender == automationManager || msg.sender == owner(), "Only automation manager");
    _;
  }

  constructor () {
    _disableInitializers();
  }

  function initialize() external initializer {
    __Ownable_init(msg.sender);
  }

  function setParams(
    address _mailBeforeActivation,
    address _mailActivated,
    address _mailReadyToActivate,
    address _premiumSetting,
    address _automationManager
  ) external onlyOwner {
    mailBeforeActivation = _mailBeforeActivation;
    mailActivated = _mailActivated;
    mailReadyToActivate = _mailReadyToActivate;
    premiumSetting = _premiumSetting;
    automationManager = _automationManager;
  }

  //BEFORE ACTIVATION
  function sendEmailBeforeActivationToOwner(
    string memory ownerName,
    string memory contractName,
    uint256 lastTx,
    uint256 bufferTime,
    address[] memory listBene,
    string memory ownerEmail
  ) external onlyManager {
    IPremiumSendMail(mailBeforeActivation).sendEmailBeforeActivationToOwner(ownerName, contractName, lastTx, bufferTime, listBene, ownerEmail);
    mailId++;
  }

  function sendEmailBeforeActivationToBeneficiary(
    string[] memory beneNames,
    string memory contractName,
    uint256 timeCountdown,
    string[] memory beneEmails
  ) external onlyManager {
    IPremiumSendMail(mailBeforeActivation).sendEmailBeforeActivationToBeneficiary(beneNames, contractName, timeCountdown, beneEmails);
    mailId += beneEmails.length;
  }

  function sendEmailBeforeLayer2ToLayer1(
    string[] memory beneNames,
    string[] memory beneEmails,
    string memory contractName,
    uint256 x_days
  ) external onlyManager {
    IPremiumSendMail(mailBeforeActivation).sendEmailBeforeLayer2ToLayer1(beneNames, beneEmails, contractName, x_days);
  }

  function sendEmailBeforeLayer2ToLayer2(
    string memory beneName,
    string memory beneEmail,
    string memory contractName,
    uint256 x_days
  ) external onlyManager {
    IPremiumSendMail(mailBeforeActivation).sendEmailBeforeLayer2ToLayer2(beneName, beneEmail, contractName, x_days);
    mailId++;
  }

  function sendEmailBeforeLayer3ToLayer12(
    string[] memory beneNames,
    string[] memory beneEmails,
    string memory contractName,
    uint256 x_days
  ) external onlyManager {
    IPremiumSendMail(mailBeforeActivation).sendEmailBeforeLayer3ToLayer12(beneNames, beneEmails, contractName, x_days);
    mailId += beneEmails.length;
  }

  function sendEmailBeforeLayer3ToLayer3(
    string memory beneName,
    string memory beneEmail,
    string memory contractName,
    uint256 x_day
  ) external onlyManager {
    IPremiumSendMail(mailBeforeActivation).sendEmailBeforeLayer3ToLayer3(beneName, beneEmail, contractName, x_day);
    mailId++;
  }

  //READY TO ACTIVATE
  function sendEmailReadyToActivateToLayer1(string[] memory beneNames, string[] memory beneEmails, string memory contractName) external onlyManager {
    IPremiumSendMail(mailReadyToActivate).sendEmailReadyToActivateToLayer1(beneNames, beneEmails, contractName);
  }

  function sendEmailReadyToActivateLayer2ToLayer1(
    string[] memory beneNamesLayer1,
    string[] memory beneEmailsLayer1,
    address beneAddressLayer2,
    string memory contractName,
    uint256 timeActiveLayer2
  ) external onlyManager {
    IPremiumSendMail(mailReadyToActivate).sendEmailReadyToActivateLayer2ToLayer1(
      beneNamesLayer1,
      beneEmailsLayer1,
      beneAddressLayer2,
      contractName,
      timeActiveLayer2
    );
    mailId += beneEmailsLayer1.length;
  }

  function sendEmailReadyToActivateLayer2ToLayer2(string memory beneName, string memory beneEmail, string memory contractName) external onlyManager {
    IPremiumSendMail(mailReadyToActivate).sendEmailReadyToActivateLayer2ToLayer2(beneName, beneEmail, contractName);
  }

  function sendEmailReadyToActivateLayer3ToLayer12(
    string[] memory beneNames,
    string[] memory beneEmails,
    string memory contractName,
    uint256 activationDate,
    address layer3Addr
  ) external onlyManager {
    IPremiumSendMail(mailReadyToActivate).sendEmailReadyToActivateLayer3ToLayer12(beneNames, beneEmails, contractName, activationDate, layer3Addr);
    mailId += beneEmails.length;
  }

  function sendEmailReadyToActivateLayer3ToLayer3(string memory beneName, string memory beneEmail, string memory contractName) external onlyManager {
    IPremiumSendMail(mailReadyToActivate).sendEmailReadyToActivateLayer3ToLayer3(beneName, beneEmail, contractName);
    mailId++;
  }

  //ACTIVATED
  function sendMailActivatedMultisig(
    string[] memory beneNames,
    string[] memory beneEmails,
    string memory contractName,
    address safeWallet
  ) external onlySetting {
    IPremiumSendMail(mailActivated).sendMailActivatedMultisig(beneNames, beneEmails, contractName, safeWallet);
    mailId += beneEmails.length;
  }

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
  ) external onlySetting {
    IPremiumSendMail(mailActivated).sendEmailContractActivatedToOwner(
      toEmail,
      contractName,
      activatedByBene,
      timeActivated,
      safeWallet,
      _listAsset,
      _listBeneReceived,
      contractAddress,
      remaining
    );
    mailId++;
  }

  function sendEmailActivatedToBene(
    string memory beneName,
    string memory beneEmail,
    string memory contractName,
    address[] memory listToken,
    uint256[] memory listAmount,
    string[] memory listAssetName,
    address contractAddress,
    bool remaining
  ) external onlySetting {
   
    IPremiumSendMail(mailActivated).sendEmailActivatedToBene(
      beneName,
      beneEmail,
      contractName,
      listToken,
      listAmount,
      listAssetName,
      contractAddress,
      remaining
    );
    mailId++;
  }

  function sendMailOwnerResetToBene(string[] memory beneNames, string[] memory beneEmails, string memory contractName) external onlySetting {
    IPremiumSendMail(mailActivated).sendMailOwnerResetToBene(beneNames, beneEmails, contractName);
    mailId += beneEmails.length;
  }
}
