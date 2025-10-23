// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../libraries/NotifyLib.sol";
import "../interfaces/IPremiumLegacy.sol";
import "./PremiumAutomation.sol";
import "../interfaces/IPremiumSendMail.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import "../libraries/ArrayUtils.sol";

struct RegistrationParams {
  string name;
  bytes encryptedEmail;
  address upkeepContract;
  uint32 gasLimit;
  address adminAddress;
  uint8 triggerType;
  bytes checkData;
  bytes triggerConfig;
  bytes offchainConfig;
  uint96 amount;
}

interface AutomationRegistrarInterface {
  function registerUpkeep(RegistrationParams calldata requestParams) external returns (uint256);
}

interface IKeeperRegistryMaster {
  function addFunds(uint256 id, uint96 amount) external;
  function getForwarder(uint256 upkeepID) external view returns (address);
  function getMinBalance(uint256 id) external view returns (uint96);
  function getMinBalanceForUpkeep(uint256 id) external view returns (uint96 minBalance);
  function getBalance(uint256 id) external view returns (uint96 balance);
}

contract PremiumAutomationManager is OwnableUpgradeable {
  using NotifyLib for *;
  
  LinkTokenInterface public i_link;
  AutomationRegistrarInterface public i_registrar;
  IPremiumSendMail public premiumSendMail; //SendMail Router
  IKeeperRegistryMaster public keeperRegistry; // to add fund dynamically
  address public premiumSetting;

  mapping(address => uint256) public nonceByUsers;
  mapping(address => address) public cronjob; //store cron-job contract address for each user
  
  uint32 baseGasLimit; 
  uint256 public defaultNotifyAhead; // time to notify before activation if user doesn't set it
  uint256 notifyId;


  event CronjobCreated(address indexed user, address indexed cronjobAddress);
  event LegacyAdded(address indexed user, address[] legacyAddress, address indexed cronjobAddress);

  modifier onlySetting() {
    require(msg.sender == premiumSetting || msg.sender == owner(), "only setting");
    _;
  }

  modifier onlyCronjob() {
    address user = PremiumAutomation(msg.sender).user();
    require(cronjob[user] == msg.sender, "only crobjob");
    _;
  }

  function initialize() public initializer {
    __Ownable_init(msg.sender);
  }

  function setParams(
    address _i_link,
    address _i_registrar,
    address _keeperRegistry,
    address _premiumSetting,
    uint32 _baseGasLimit,
    address _premiumSendMail, //send mail router 
    uint256 _defaultNotifyAhead
  ) external onlyOwner {
    require(_i_link != address(0), "invalid _i_link");
    require(_i_registrar != address(0), "invalid _i_registrar");
    require(_premiumSetting != address(0), "invalid _premiumSetting");
    require(_baseGasLimit > 0, "invaid _baseGasLimit");
    require(_defaultNotifyAhead > 0, "invalid _defaultNotifyAhead");

    premiumSetting = _premiumSetting;
    i_link = LinkTokenInterface(_i_link);
    i_registrar = AutomationRegistrarInterface(_i_registrar);
    keeperRegistry = IKeeperRegistryMaster(_keeperRegistry);
    baseGasLimit = _baseGasLimit;
    defaultNotifyAhead = _defaultNotifyAhead;
    premiumSendMail = IPremiumSendMail(_premiumSendMail);
    i_link.approve(address(keeperRegistry), type(uint256).max);
    i_link.approve(address(i_registrar), type(uint256).max);
  }
  ///@dev create contract cronjob for user (if not created yet) and add legacy to cronjob
  function addLegacyCronjob(address user, address[] memory legacyAddresses) external onlySetting {
    if (!IPremiumSetting(premiumSetting).isPremium(user)) {
      return;
    }
    if (cronjob[user] == address(0)) {
      _createCronjob(user);
    }
    _addLegacy(user, legacyAddresses);
  }

  function addLegacy(address user, address[] memory legacyAddresses) external onlyOwner {
    _addLegacy(user, legacyAddresses);
  }

  function resetCronjob(address user) external onlyOwner {
    delete cronjob[user];
  }

  function resetCronjobs(address[] memory users) external onlyOwner {
    for (uint256 i = 0; i < users.length; i++) {
      delete cronjob[users[i]];
    }
  }

  function createCronjob(address user) external onlyOwner {
    _createCronjob(user);
  }

  function _createCronjob(address user) internal {
    nonceByUsers[user] += 1;
    bytes32 salt = keccak256(abi.encodePacked(user, nonceByUsers[user]));
    address cronjobAddress = Create2.deploy(0, salt, type(PremiumAutomation).creationCode);

    PremiumAutomation(cronjobAddress).initialize(user, premiumSetting, defaultNotifyAhead);
    cronjob[user] = cronjobAddress;

    RegistrationParams memory params = RegistrationParams({
      name: string.concat("Cronjob ", Strings.toHexString(user)),
      encryptedEmail: "",
      upkeepContract: cronjobAddress,
      gasLimit: baseGasLimit,
      adminAddress: owner(),
      triggerType: 0,
      checkData: "",
      triggerConfig: "",
      offchainConfig: "",
      amount: 1e18 //0.1
    });

    _registerAndPredictID(params);

    emit CronjobCreated(user, cronjobAddress);
  }

  function _registerAndPredictID(RegistrationParams memory params) internal {
    uint256 upkeepID = i_registrar.registerUpkeep(params);
    if (upkeepID != 0) {
      // set keepupId and forwarder
      address forwarder = IKeeperRegistryMaster(keeperRegistry).getForwarder(upkeepID);
      PremiumAutomation(params.upkeepContract).setKeepUpIdAndForwarder(upkeepID, forwarder);
      _fundKeepupIfNeeded(upkeepID);
    } else {
      revert("auto-approve disabled");
    }
  }

  function _addLegacy(address user, address[] memory legacyAddresses) internal {
    address cronjobAddress = cronjob[user];
    if (cronjobAddress != address(0)) {
      PremiumAutomation(cronjobAddress).addLegacyIfNeed(legacyAddresses);
      emit LegacyAdded(user, legacyAddresses, cronjobAddress);
      _fundKeepupIfNeeded(PremiumAutomation(cronjobAddress).keepupId());
    }
  }

  function sendNotifyFromCronjob(address legacy, NotifyLib.NotifyType notifyType) external onlyCronjob {
    //send email
    if (address(premiumSendMail) != address(0)) {
      _sendEmailFromManager(legacy, notifyType);
    }

    //Fund keepup if needed
    uint256 keepupId = PremiumAutomation(msg.sender).keepupId();
    _fundKeepupIfNeeded(keepupId);
  }


  function sendEmailFromManager(address legacy, NotifyLib.NotifyType notifyType) external onlyOwner {
    _sendEmailFromManager(legacy, notifyType);
  }

  function _sendEmailFromManager(address legacy, NotifyLib.NotifyType notifyType) internal {
    // return;
    //process send email for each type of notify
    if (notifyType == NotifyLib.NotifyType.BeforeActivation) {
      _handleBeforeActivation(legacy);
    }
    if (notifyType == NotifyLib.NotifyType.ReadyToActivate) {
      _handleReadyToActivate(legacy);
    }
    
    if (notifyType == NotifyLib.NotifyType.BeforeLayer2) {
      _handleBeforeLayer2(legacy);
    }

    if (notifyType == NotifyLib.NotifyType.Layer2ReadyToActivate) {
      _handleReadyToActivateLayer2(legacy);
    }

    if (notifyType == NotifyLib.NotifyType.BeforeLayer3) {
      _handleBeforeLayer3(legacy);
    }

    if (notifyType == NotifyLib.NotifyType.Layer3ReadyToActivate) {
      _handleReadyToActivateLayer3(legacy);
    }
  }

  function withdrawLINK(address to) external onlyOwner{
    i_link.transfer(to, i_link.balanceOf(address(this)));
  }

  function _fundKeepupIfNeeded(uint256 keepupId) internal {
    uint96 minBalance = IKeeperRegistryMaster(keeperRegistry).getMinBalance(keepupId);
    uint96 balance = IKeeperRegistryMaster(keeperRegistry).getBalance(keepupId);
    if (balance <= (minBalance * 13000) / 10000) {
      IKeeperRegistryMaster(keeperRegistry).addFunds(keepupId, (minBalance * 13000) / 10000);
    }
  }

  function _handleReadyToActivate(address legacy) internal {
    string memory contractName = IPremiumLegacy(legacy).getLegacyName();
    // send email to layer 1 only
    (, string [] memory beneEmails, string [] memory beneNames) = IPremiumSetting(premiumSetting).getBeneficiaryData(legacy);
    premiumSendMail.sendEmailReadyToActivateToLayer1(beneNames, beneEmails, contractName);
  }

  function _handleReadyToActivateLayer2(address legacy) internal {
    // send email to layer 1 
    string memory contractName = IPremiumLegacy(legacy).getLegacyName();
    (, string [] memory beneEmails, string [] memory beneNames) = IPremiumSetting(premiumSetting).getBeneficiaryData(legacy);
    (address layer2Address,string memory layerEmail , string memory layer2Name) = IPremiumSetting(premiumSetting).getSecondLineData(legacy);
    (, uint256 t2, ) = IPremiumLegacy(legacy).getTriggerActivationTimestamp();
    IPremiumSendMail(premiumSendMail).sendEmailReadyToActivateLayer2ToLayer1(beneNames, beneEmails, layer2Address, contractName, t2);
    IPremiumSendMail(premiumSendMail).sendEmailReadyToActivateLayer2ToLayer2(layer2Name, layerEmail, contractName);
  }

  function _handleReadyToActivateLayer3(address legacy) internal {
    string memory contractName = IPremiumLegacy(legacy).getLegacyName();
    (, string [] memory beneEmails, string [] memory beneNames) = IPremiumSetting(premiumSetting).getBeneficiaryData(legacy);
    (, string memory layer2Email, string memory layer2Name) = IPremiumSetting(premiumSetting).getSecondLineData(legacy);
    (address layer3Address, string memory layer3Email, string memory layer3Name) = IPremiumSetting(premiumSetting).getThirdLineData(legacy);
    (, uint256 t3, ) = IPremiumLegacy(legacy).getTriggerActivationTimestamp();
    IPremiumSendMail(premiumSendMail).sendEmailReadyToActivateLayer3ToLayer3(layer3Name, layer3Email, contractName);
    IPremiumSendMail(premiumSendMail).sendEmailReadyToActivateLayer3ToLayer12(beneNames, beneEmails, contractName, t3, layer3Address);
    if (bytes(layer2Email).length != 0) {
      IPremiumSendMail(premiumSendMail).sendEmailReadyToActivateLayer3ToLayer12(
        ArrayUtils.makeStringArray(layer2Name), 
        ArrayUtils.makeStringArray(layer2Email), contractName, t3, layer3Address);
    }
  }


  function _handleBeforeActivation(address legacy) internal {
    string memory contractName = IPremiumLegacy(legacy).getLegacyName();
    (uint256 t1, , ) = IPremiumLegacy(legacy).getTriggerActivationTimestamp();
    (string memory ownerName, string memory ownerEmail, ) = IPremiumSetting(premiumSetting).getUserData(IPremiumLegacy(legacy).creator());
    (, string[] memory beneEmails, string[] memory beneNames) = IPremiumSetting(premiumSetting).getBeneficiaryData(legacy);
    (address []  memory  beneficiares ,,) = IPremiumLegacy(legacy).getLegacyBeneficiaries();
    uint256 lastTimestamp = IPremiumLegacy(legacy).getLastTimestamp();
    // 1.to owner
    if (bytes(ownerEmail).length != 0) {
      premiumSendMail.sendEmailBeforeActivationToOwner(ownerName, contractName, lastTimestamp, t1-lastTimestamp, beneficiares, ownerEmail);
    }

    // 2.to beneficiary
    uint256 timeCountdown = t1 > lastTimestamp ? (t1 - lastTimestamp) / 86400 : 0;
    premiumSendMail.sendEmailBeforeActivationToBeneficiary(beneNames, contractName, timeCountdown, beneEmails);
  }

  function _handleBeforeLayer2(address legacy) internal {
    //prepare data
    string memory contractName = IPremiumLegacy(legacy).getLegacyName();
    (, uint256 t2, ) = IPremiumLegacy(legacy).getTriggerActivationTimestamp();
    uint256 dayTillActivate = t2 > block.timestamp ? (t2 - block.timestamp) / 86400 : 0;
    (, string[] memory beneEmails, string[] memory beneNames) = IPremiumSetting(premiumSetting).getBeneficiaryData(legacy);
    (, string memory layer2Email, string memory layer2Name) = IPremiumSetting(premiumSetting).getSecondLineData(legacy);


    //2.to layer1
    premiumSendMail.sendEmailBeforeLayer2ToLayer1(beneNames, beneEmails, contractName, dayTillActivate);

    //3.to layer2
    if (bytes(layer2Email).length != 0) {
      premiumSendMail.sendEmailBeforeLayer2ToLayer2(layer2Name, layer2Email, contractName, dayTillActivate);
    }
    return;
  }

  function _handleBeforeLayer3(address legacy) internal {
    //prepare data
    string memory contractName = IPremiumLegacy(legacy).getLegacyName();
    (, , uint256 t3) = IPremiumLegacy(legacy).getTriggerActivationTimestamp();
    (, string memory layer2Email, string memory layer2Name) = IPremiumSetting(premiumSetting).getSecondLineData(legacy);
    (, string memory layer3Email, string memory layer3Name) = IPremiumSetting(premiumSetting).getThirdLineData(legacy);
    (, string [] memory beneEmails, string [] memory beneNames) = IPremiumSetting(premiumSetting).getBeneficiaryData(legacy);
    uint256 dayTillActivate = t3 > block.timestamp  ? (t3 - block.timestamp) / 86400 : 0;
    //1.to layer1
    premiumSendMail.sendEmailBeforeLayer3ToLayer12(beneNames, beneEmails, contractName, dayTillActivate);

    //2.to layer2
    if (bytes(layer2Email).length != 0) {
      premiumSendMail.sendEmailBeforeLayer3ToLayer12(ArrayUtils.makeStringArray(layer2Name), ArrayUtils.makeStringArray(layer2Email), contractName, dayTillActivate);
    }

    //3.to layer3
    if (bytes(layer3Email).length != 0) {
      premiumSendMail.sendEmailBeforeLayer3ToLayer3(layer3Name, layer3Email, contractName, dayTillActivate);
    }
  }

  function handleActivated(address legacy, address[] memory listToken, uint256[] calldata listAmount, address activatedByBene) external onlySetting {
    string memory contractName = IPremiumLegacy(legacy).getLegacyName();
    (, string[] memory beneEmails, string[] memory beneNames) = IPremiumSetting(premiumSetting).getBeneficiaryData(legacy);
    (, string memory layer2Email, string memory layer2Name) = IPremiumSetting(premiumSetting).getSecondLineData(legacy);
    // (, string memory layer3Email, string memory layer3Name) = IPremiumSetting(premiumSetting).getThirdLineData(legacy);
    (, address layer2, address layer3) = IPremiumLegacy(legacy).getLegacyBeneficiaries();
    string[] memory listAssetName = new string[](listToken.length);
    for (uint256 i = 0; i < listToken.length; i++) {
      listAssetName[i] = ERC20(listToken[i]).symbol();
    }

    //to owner

    //to beneficiaries all layers
    if (activatedByBene == layer2) {
      if (bytes(layer2Email).length != 0) {
        premiumSendMail.sendEmailActivatedToLayer2(layer2Name, layer2Email, contractName, listToken, listAmount, listAssetName);
      }
    } else {
      if (activatedByBene != layer3) {
        // => activated by layer 1
        for (uint i = 0; i < beneEmails.length; i++) {
          if (bytes(beneEmails[i]).length != 0) {
            premiumSendMail.sendEmailActivatedToLayer1(beneNames[i], beneEmails[i], contractName, listToken, listAmount, listAssetName);
          }
        }
      } else {
        // => activated by layer 3
        // No template found
      }
    }
  }
}
