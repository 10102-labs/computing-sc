// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import "@chainlink/contracts/src/v0.8/functions/v1_0_0/interfaces/IFunctionsRouter.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/ISafeWallet.sol";
import "../interfaces/IPremiumLegacy.sol";
import {NotifyLib} from "../libraries/NotifyLib.sol";

// PUSH Comm Contract Interface
interface IPUSHCommInterface {
  function sendNotification(address _channel, address _recipient, bytes calldata _identity) external;
}

contract PremiumNotification is OwnableUpgradeable, AutomationCompatibleInterface {
  using FunctionsRequest for FunctionsRequest.Request;
  address public EPNS_COMM_ADDRESS = 0x0C34d54a09CFe75BCcd878A469206Ae77E0fe6e7; //fixed for Sepolia
  address public channel;
  address public enps_comm;

  //CHAINLINK FUNCTION
  // Router address - Hardcoded for Sepolia
  // Check to get the router address for your supported network https://docs.chain.link/chainlink-functions/supported-networks
  address public router = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;
  // State variables to store the last request ID, response, and error
  bytes32 public s_lastRequestId;
  bytes public s_lastResponse;
  bytes public s_lastError;
  //Callback gas limit
  uint32 public gasLimit = 300000;

  // donID - Hardcoded for Sepolia
  // Check to get the donID for your supported network https://docs.chain.link/chainlink-functions/supported-networks
  bytes32 public donID = 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;
  uint64 public subscriptionId;

  //Premium - call send push notification
  address public manager;
  address public premiumSetting;

  uint256 public notifyId; 

  address  [] public queueRecipient;
  bytes  [] public queuePayload;
  uint256 public indexNotifying; 

  event NotificationSent(
    address indexed legacy,
    NotifyLib.NotifyType notifyType,
    NotifyLib.RecipientType recipientType,
    address[] recipients,
    string body,
    uint256  notifyId
  );

  event Sent(address recipient, string title, string body, uint256 notifyId );

  //modifier
  modifier onlyManager() {
    require(msg.sender == manager || msg.sender == owner(), "Premium Notification: Only manager!");
    _;
  }

  modifier onlySetting() {
    require(msg.sender == premiumSetting || msg.sender == owner(), "Premium Notification: Only setting!");
    _;
  }

  function initialize() public initializer {
    __Ownable_init(msg.sender);
  }

  function setUpPush(address _enpsComm, address _channel, address _manager, address _premiumSetting) external onlyOwner {
    require(_enpsComm != address(0), "invalid address");
    require(_channel != address(0), "invalid address");
    require(_manager != address(0), "invalid address");

    channel = _channel;
    enps_comm = _enpsComm;
    manager = _manager;
    premiumSetting = _premiumSetting;
  }

  function sendPushNoti(address[] memory recipients, string calldata title, string calldata notification) external onlyOwner {
    _sendPushNotification(recipients, title, notification);
  }
  

  function notifyTransferActivation(uint8 layer, address legacy, string calldata contractName, bool remaining) external onlySetting {
    // send PUSH Protocol
    address creator = IPremiumLegacy(legacy).creator();
    string memory body ;
    if (!remaining) {
      body =  string.concat("You 've receive your inheritance from ", contractName, ".");
    }
    else {
      body =  string.concat("You 've receive part of your inheritance from ", contractName, ".");
    }
    
    (address[] memory beneficiaries, address layer2, address layer3) = IPremiumLegacy(legacy).getLegacyBeneficiaries();
    _sendIfNotEmpty(legacy, NotifyLib.NotifyType.ContractActivated, NotifyLib.RecipientType.Owner, _makeArray(creator));
    if (layer == 1) {
      _sendPushNotification(beneficiaries, contractName, body);
    } else if (layer == 2) {
      _sendPushNotification(_makeArray(layer2), contractName, body);
    } else if (layer == 3) {
      _sendPushNotification(_makeArray(layer3), contractName, body);
    }
  }

  function notifyMultisigActivation(address legacy) external onlySetting {
    (address[] memory beneficiaries,,) = IPremiumLegacy(legacy).getLegacyBeneficiaries();
    _sendIfNotEmpty(legacy, NotifyLib.NotifyType.ContractActivated, NotifyLib.RecipientType.Beneficiary, beneficiaries);
  }

  function notifyOwnerReset(address legacy) external onlySetting {
    uint8 layer = IPremiumLegacy(legacy).getLayer();
    (address[] memory beneficiaries, address layer2, address layer3) = IPremiumLegacy(legacy).getLegacyBeneficiaries();
    _sendIfNotEmpty(legacy, NotifyLib.NotifyType.OwnerReset, NotifyLib.RecipientType.Beneficiary, beneficiaries);
    if (layer >= 2) {
      _sendIfNotEmpty(legacy, NotifyLib.NotifyType.OwnerReset, NotifyLib.RecipientType.Secondline, _makeArray(layer2));
    }
    if (layer == 3) {
      _sendIfNotEmpty(legacy, NotifyLib.NotifyType.OwnerReset, NotifyLib.RecipientType.Thirdline, _makeArray(layer3));
    }
  }

  function handleLegacyNotify(address legacy, NotifyLib.NotifyType notifyType) external onlyManager {
    //send push notification
    //send email
    //prepare recipient
    (address[] memory beneficiaries, address layer2, address layer3) = IPremiumLegacy(legacy).getLegacyBeneficiaries();
    address creator = IPremiumLegacy(legacy).creator();
    address owner = IPremiumLegacy(legacy).getLegacyOwner();
    address[] memory owners; // owner and cosigner

    if (owner.code.length > 0) {
      owners = new address[](ISafeWallet(owner).getOwners().length);
      owners = ISafeWallet(owner).getOwners();
    } else {
      owners = new address[](1);
      owners[0] = creator;
    }

    // Send notifications if body is not empty
    _sendIfNotEmpty(legacy, notifyType, NotifyLib.RecipientType.Owner, owners);
    _sendIfNotEmpty(legacy, notifyType, NotifyLib.RecipientType.Beneficiary, beneficiaries);

    // // layer2 & layer3 wrapped in single-address arrays
    if (layer2 != address(0)) {
      _sendIfNotEmpty(legacy, notifyType, NotifyLib.RecipientType.Secondline, _makeArray(layer2));
    }

    if (layer3 != address(0)) {
      _sendIfNotEmpty(legacy, notifyType, NotifyLib.RecipientType.Thirdline, _makeArray(layer3));
    }
  }

  ///@dev send notification if body is not empty - define in NotifyLib.sol
  function _sendIfNotEmpty(
    address legacy,
    NotifyLib.NotifyType notifyType,
    NotifyLib.RecipientType recipientType,
    address[] memory recipients
  ) internal {
    string memory body = _getBody(legacy, notifyType, recipientType);
    string memory title = IPremiumLegacy(legacy).getLegacyName();
    if (bytes(body).length != 0) {
      _sendPushNotification(recipients, title, body);
      // emit NotificationSent(legacy, notifyType, recipientType, recipients, body, notifyId);
    }
  }

  //queue noti
  function _sendPushNotification(address[] memory recipients, string memory title, string memory body) internal {
    for (uint i = 0; i < recipients.length; i++) {
      queueRecipient.push(recipients[i]);
      queuePayload.push(_getPayload(title, body));
      emit Sent(recipients[i], title, body, notifyId);
    }
  }

  function _getPayload(string memory title, string memory body) internal returns (bytes memory) {
    bytes memory payload = bytes(
      string(
        // We are passing identity here: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/identity/payload-identity-implementations
        abi.encodePacked(
          "0", // this is notification identity: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/identity/payload-identity-implementations
          "+", // segregator
          "3", // this is payload type: https://docs.epns.io/developers/developer-guides/sending-notifications/advanced/notification-payload-types/payload (1, 3 or 4) = (Broadcast, targeted or subset)
          "+", // segregator
          title, // this is notification title
          "+", // segregator
          body // notification body
        )
      )
    );
    notifyId++;
    return payload;
  }

  function _getBody(address legacy, NotifyLib.NotifyType notifyType, NotifyLib.RecipientType recipient) internal view returns (string memory) {
    (uint256 triggerTimestamp, , ) = IPremiumLegacy(legacy).getTriggerActivationTimestamp();

    uint256 secondsUntilActivation = triggerTimestamp > block.timestamp ? triggerTimestamp - block.timestamp : 0;
    string memory contractName = IPremiumLegacy(legacy).getLegacyName(); // legacy contract must store legacy name
    string memory daysStr = _days(secondsUntilActivation);

    if (recipient == NotifyLib.RecipientType.Owner) {
      if (notifyType == NotifyLib.NotifyType.BeforeActivation) {
        return string.concat("Your contract ", contractName, " activates in ", daysStr, ". Mark yourself alive to delay activation.");
      }
      if (notifyType == NotifyLib.NotifyType.ContractActivated) {
        return string.concat(contractName, " has been activated.");
      }
    }

    if (recipient == NotifyLib.RecipientType.Beneficiary) {
      if (notifyType == NotifyLib.NotifyType.BeforeActivation) {
        return
          string.concat(
            daysStr,
            " until ",
            contractName,
            " can be activated. You will be able to claim your inheritance soon."
          );
      }
      if (notifyType == NotifyLib.NotifyType.ReadyToActivate) {
        return string.concat(contractName, " is ready to activate. Connect your wallet to activate and claim the funds. Gas fees apply.");
      }
      if (notifyType == NotifyLib.NotifyType.ContractActivated) {
        if (IPremiumLegacy(legacy).LEGACY_TYPE() == 1) {
          // multisig
          return
            string.concat(
              " You're now a co-signer on the Safe Wallet for ",
              contractName,
              ". You can approve or initiate transactions using Safe."
            );
        } else {
          return string.concat("You've received your inheritance from ", contractName, ".");
        }
      }
      if (notifyType == NotifyLib.NotifyType.BeforeLayer2) {
        return
          string.concat(
            daysStr,
            " left to activate ",
            contractName,
            ". After that, the second-line beneficiary will be able to claim the inheritance. Activate now."
          );
      }
      if (notifyType == NotifyLib.NotifyType.Layer2ReadyToActivate) {
        return
          string.concat(
            "The second-line activation for contract ",
            contractName,
            " is in effect, and the second-line beneficiary will be able to claim the funds."
          );
      }

      if (notifyType == NotifyLib.NotifyType.Layer3ReadyToActivate) {
        return
          string.concat(
            "The third-line activation for contract ",
            contractName,
            " is in effect, and the third-line beneficiary will be able to claim the funds."
          );
      }

      if (notifyType == NotifyLib.NotifyType.OwnerReset) {
        return
          string.concat(
            "The activation timeline of ",
            contractName,
            " has been reset by the owner. We will notify you later when it's time to activate."
          );
      }
    }

    if (recipient == NotifyLib.RecipientType.Secondline) {
      if (notifyType == NotifyLib.NotifyType.BeforeLayer2) {
        return
          string.concat(
            "You may be eligible to activate ",
            contractName,
            " in ",
            daysStr,
            ", pending first-line's inaction. Stay tuned for the activation link."
          );
      }

      if (notifyType == NotifyLib.NotifyType.Layer2ReadyToActivate) {
        return string.concat(contractName, " is ready to activate. Connect your wallet to activate and claim the funds. Gas fees apply.");
      }

      if (notifyType == NotifyLib.NotifyType.ContractActivated) {
        return string.concat("You 've receive your inheritance from ", contractName, ".");
      }

      if (notifyType == NotifyLib.NotifyType.BeforeLayer3) {
        return
          string.concat(
            daysStr,
            " left to activate ",
            contractName,
            ". After that, only the third-line beneficiary can claim the inheritance. Activate now."
          );
      }

      if (notifyType == NotifyLib.NotifyType.Layer3ReadyToActivate) {
        return
          string.concat(
            "The third-line activation for contract ",
            contractName,
            " is in effect. and the third-line beneficiary will be able to claim the funds."
          );
      }

      if (notifyType == NotifyLib.NotifyType.OwnerReset) {
        return
          string.concat(
            "The activation timeline of ",
            contractName,
            " has been reset by the owner. We will notify you later when it's time to activate."
          );
      }
    }

    if (recipient == NotifyLib.RecipientType.Thirdline) {
      if (notifyType == NotifyLib.NotifyType.BeforeLayer3) {
        return
          string.concat(
            "You may be eligible to activate ",
            contractName,
            " in ",
            daysStr,
            ", pending second-line's inaction. Stay tuned for the activation link."
          );
      }
      if (notifyType == NotifyLib.NotifyType.Layer3ReadyToActivate) {
        return string.concat(contractName, " is ready to activate. Connect your wallet to activate and claim the funds. Gas fees apply.");
      }
      if (notifyType == NotifyLib.NotifyType.OwnerReset) {
        return
          string.concat(
            "The activation timeline of ",
            contractName,
            " has been reset by the owner. We will notify you later when it's time to activate."
          );
      }

      if (notifyType == NotifyLib.NotifyType.ContractActivated) {
        return string.concat("You 've receive your inheritance from ", contractName, ".");
      }
    }

    return "";
  }

  function _days(uint256 secondsTime) internal pure returns (string memory) {
    uint256 daysTime = secondsTime / 86400;
    return string(abi.encodePacked(Strings.toString(daysTime), " day", daysTime <= 1 ? "" : "s"));
  }

  function _makeArray(address addr) internal pure returns (address[] memory) {
    address[] memory arr = new address[](1);
    arr[0] = addr;
    return arr;
  }

  function checkUpkeep(bytes calldata checkData) external override view returns (bool upkeepNeeded, bytes memory performData) {
    if(indexNotifying < queueRecipient.length) return (true, "0x");
  }

  function performUpkeep(bytes calldata performData) external override {
    IPUSHCommInterface(enps_comm).sendNotification(
        channel,
        queueRecipient[indexNotifying], // to recipient, put address(this) in case you want Broadcast or Subset. For Targetted put the address to which you want to send
        queuePayload[indexNotifying]
    );
    indexNotifying++;

  }
}