// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IPremiumSetting.sol";
import "../interfaces/IPremiumLegacy.sol";
import "../interfaces/IPremiumAutomationManager.sol";
import "../libraries/NotifyLib.sol";
import {ISafeWallet} from "../interfaces/ISafeWallet.sol";


contract PremiumAutomation is AutomationCompatibleInterface {
  using NotifyLib for *;
  bytes32 internal constant GUARD_STORAGE_SLOT = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;
  address public user;
  IPremiumSetting public setting;
  IPremiumAutomationManager public manager;
  address[] public legacyContracts;
  mapping(address legacy => mapping(NotifyLib.NotifyType => uint256)) lastNotify;
  mapping(address => bool) enableNotify; //fasle if activated / deleted
  uint256 public defaultNotifyAhead; // time to notify before activation if user doesn't set it
  uint256 public keepupId;
  address public forwarder; //the only address that can call performUpkeep for each automation contract

  event KeepupIdAndForwarderSet(uint256 indexed keepupId, address indexed forwarder);
  
  modifier onlyManager() {
    require(msg.sender == address(manager), "Only Manager");
    _;
  }

  modifier onlyForwarder()  { 
    require(msg.sender == forwarder, "Only Forwarder");
    _; 
  }

  function initialize(address _user, address _premiumSetting, uint256 _defaultNotifyAhead) public  {
    require(user == address(0), "Already initialized");
    user = _user;
    setting = IPremiumSetting(_premiumSetting);
    manager = IPremiumAutomationManager(msg.sender);
    defaultNotifyAhead = _defaultNotifyAhead;
  }

  ///@dev check if there is any email to send
  function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
    if (!setting.isPremium(user)) return (false, "");

    uint256 notifyAhead = setting.getTimeAhead(user) > 0 ? setting.getTimeAhead(user) : defaultNotifyAhead;

    for (uint256 i = 0; i < legacyContracts.length; i++) {
      address legacy = legacyContracts[i];

      if(!enableNotify[legacy]) continue;
      if (!_checkGuardInSafeWalletLegacy(legacy)) return (false, "");


      if (!IPremiumLegacy(legacy).isLive()) {
        return (true, abi.encode(legacy, NotifyLib.NotifyType.ContractActivated)); //mark disabled
      }
      // bene , layer2, layer 3
      (uint256 t1, uint256 t2, uint256 t3) = IPremiumLegacy(legacy).getTriggerActivationTimestamp();
      uint8 currentLayer = IPremiumLegacy(legacy).getLayer();
      uint256 nowTs = block.timestamp;
      uint256 notifyCooldown = IPremiumLegacy(legacy).getActivationTrigger();

      ///Multisig Legacy is always in layer1 
      //Transfer Legacy can switch to layer 2 or 3
      if (currentLayer == 1) {
        if (nowTs  >= t2 - notifyAhead && t2 != t1 && isCooldownOver(legacy, NotifyLib.NotifyType.BeforeLayer2, notifyCooldown)) {
          return (true, abi.encode(legacy, NotifyLib.NotifyType.BeforeLayer2));
        }

        if (nowTs >= t1 && isCooldownOver(legacy, NotifyLib.NotifyType.ReadyToActivate, notifyCooldown)) {
          uint256 lastNotifyBefore = lastNotify[legacy][NotifyLib.NotifyType.BeforeActivation];
          uint256 lastNotifyReady = lastNotify[legacy][NotifyLib.NotifyType.ReadyToActivate];
          if (lastNotifyReady <= lastNotifyBefore) { // must notiy before
            return (true, abi.encode(legacy, NotifyLib.NotifyType.ReadyToActivate));
          }
        }

        if (nowTs  >= t1 - notifyAhead && nowTs < t1  && isCooldownOver(legacy, NotifyLib.NotifyType.BeforeActivation, notifyCooldown)) {
          return (true, abi.encode(legacy, NotifyLib.NotifyType.BeforeActivation));
        }
      }

      if (currentLayer == 2) {
        if (nowTs  >= t3 - notifyAhead && t3 != t2 && isCooldownOver(legacy, NotifyLib.NotifyType.BeforeLayer3, notifyCooldown)) {
          return (true, abi.encode(legacy, NotifyLib.NotifyType.BeforeLayer3));
        }

        if (nowTs >= t2  && isCooldownOver(legacy, NotifyLib.NotifyType.Layer2ReadyToActivate, notifyCooldown)) {
          uint256 lastNotifyBeforeL2 = lastNotify[legacy][NotifyLib.NotifyType.BeforeLayer2];
          uint256 lastNotifyReadyL2 = lastNotify[legacy][NotifyLib.NotifyType.Layer2ReadyToActivate];
          if (lastNotifyReadyL2 <= lastNotifyBeforeL2) { // must notiy before
            return (true, abi.encode(legacy, NotifyLib.NotifyType.Layer2ReadyToActivate));
          }
        }
      }

      if (currentLayer == 3) {
        uint256 lastNotifyLayer3 = lastNotify[legacy][NotifyLib.NotifyType.Layer3ReadyToActivate];
        uint256 lastNotifyLayer2 = lastNotify[legacy][NotifyLib.NotifyType.Layer2ReadyToActivate];
        if (isCooldownOver(legacy, NotifyLib.NotifyType.Layer3ReadyToActivate, notifyCooldown)
          && lastNotifyLayer3 <= lastNotifyLayer2
        ) {
          return (true, abi.encode(legacy, NotifyLib.NotifyType.Layer3ReadyToActivate));
        }
      }
    }

    return (false, "");
  }

  function performUpkeep(bytes calldata data) external override onlyForwarder {
    if(!setting.isPremium((user))) return;
    (address legacy, NotifyLib.NotifyType notifyType) = abi.decode(data, (address, NotifyLib.NotifyType));
    //Already sent when contract activated 
    if (notifyType == NotifyLib.NotifyType.ContractActivated) {
        enableNotify[legacy] = false;
        return; 
    }
    lastNotify[legacy][notifyType] = block.timestamp;
    //send reminder
    IPremiumAutomationManager(manager).sendNotifyFromCronjob(legacy, notifyType);
  }

  function addLegacyIfNeed(address[] memory legacyAddresses) external onlyManager {
    for (uint256 i = 0; i < legacyAddresses.length; i++) {
      address legacy = legacyAddresses[i];
      if (enableNotify[legacy] == false  && IPremiumLegacy(legacy).isLive()) {
        legacyContracts.push(legacy);
        enableNotify[legacy] = true;
      }
    }
  }

  function setKeepUpIdAndForwarder(uint256 _keepupId, address _forwarder) external onlyManager {
    keepupId = _keepupId;
    forwarder = _forwarder;
    emit KeepupIdAndForwarderSet(keepupId, forwarder);
  }

  function decodePerformData(bytes calldata data) external pure returns (address legacy, NotifyLib.NotifyType notifyType) {
    return abi.decode(data, (address, NotifyLib.NotifyType));
  }

  function isCooldownOver(address legacy, NotifyLib.NotifyType notifyType, uint256 cooldown) internal view returns (bool) {
    return block.timestamp > lastNotify[legacy][notifyType] + cooldown;

  }

  function _checkGuardInSafeWalletLegacy(address legacyAddress) internal view returns (bool) {
    IPremiumLegacy legacy = IPremiumLegacy(legacyAddress);
    if (legacy.LEGACY_TYPE() == 3) return true; // Skip check EOA legacy (Live by default when created)
    address safeWallet_ = legacy.getLegacyOwner();
    bytes memory guardSafeWalletBytes = ISafeWallet(safeWallet_).getStorageAt(uint256(GUARD_STORAGE_SLOT), 1);
    address guardSafeWalletAddress = address(uint160(uint256(bytes32(guardSafeWalletBytes))));
    if (guardSafeWalletAddress == address(0)) return false;
    return true;
  }
}
