// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {LegacyRouter} from "../common/LegacyRouter.sol";
import {LegacyFactory} from "../common/LegacyFactory.sol";
import {TransferLegacy} from "./TransferLegacyContract.sol";
import {SafeGuard} from "../SafeGuard.sol";
import {ITransferLegacy} from "../interfaces/ITransferLegacyContract.sol";
import {ISafeGuard} from "../interfaces/ISafeGuard.sol";
import {ISafeWallet} from "../interfaces/ISafeWallet.sol";
import {TransferLegacyStruct} from "../libraries/TransferLegacyStruct.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {EIP712LegacyVerifier} from "../term/VerifierTerm.sol";
import {IPremiumSetting} from "../interfaces/IPremiumSetting.sol";

contract TransferLegacyRouter is LegacyRouter, LegacyFactory, Initializable {
  address public premiumSetting;
  EIP712LegacyVerifier public verifier;
  address public paymentContract;
  address public uniswapRouter;
  address public weth;

  /* Error */
  error ExistedGuardInSafeWallet(address);
  error SignerIsNotOwnerOfSafeWallet();
  error NumBeneficiariesInvalid();
  error NumAssetsInvalid();
  error DistributionsInvalid();
  error ActivationTriggerInvalid();
  error OnlyBeneficaries();
  error SenderIsCreatedLegacy(address);
  error CannotClaim();
  error SafeWalletInvalid();

  /* Struct */
  struct LegacyMainConfig {
    string name;
    string note;
    string[] nickNames;
    TransferLegacyStruct.Distribution[] distributions;
  }

  /* Event */
  event TransferLegacyCreated(
    uint256 legacyId,
    address legacyAddress,
    address guardAddress,
    address creatorAddress,
    address safeAddress,
    LegacyMainConfig mainConfig,
    TransferLegacyStruct.LegacyExtraConfig extraConfig,
    uint256 timestamp
  );
  event TransferLegacyConfigUpdated(
    uint256 legacyId,
    LegacyMainConfig mainConfig,
    TransferLegacyStruct.LegacyExtraConfig extraConfig,
    uint256 timestamp
  );
  event TransferLegacyDistributionUpdated(uint256 legacyId, string[] nickNames, TransferLegacyStruct.Distribution[] distributions, uint256 timestamp);
  event TransferLegacyTriggerUpdated(uint256 legacyId, uint128 lackOfOutgoingTxRange, uint256 timestamp);
  event TransferLegacyNameNoteUpdated(uint256 legacyId, string name, string note, uint256 timestamp);
  event TransferLegacyActivated(uint256 legacyId, uint8 layer, uint256 timestamp);
  event TransferLegacyLayer23DistributionUpdated(
    uint256 legacyId,
    uint8 layer,
    string nickNames,
    TransferLegacyStruct.Distribution distribution,
    uint256 timestamp
  );
  event TransferLegacyLayer23Created(uint256 legacyId, uint8 layer, TransferLegacyStruct.Distribution distribution, string nickName);

  /* Modifier */
  modifier onlySafeWallet(uint256 legacyId_) {
    _checkSafeWalletValid(legacyId_, msg.sender);
    _;
  }

  function initialize(address _deployerContract, address _premiumSetting, address _verifier, address _paymentContract, address router_, address weth_) external initializer {
    legacyDeployerContract = _deployerContract;
    premiumSetting = _premiumSetting;
    verifier = EIP712LegacyVerifier(_verifier);
    paymentContract = _paymentContract;
    uniswapRouter = router_;
    weth = weth_;
  }

  /**
   * @dev Get next legacy address that would be created for a sender
   * @param sender_ The address of the sender
   * @return address The next legacy address that would be created
   */
  function getNextLegacyAddress(address sender_) external view returns (address) {
    return _getNextAddress(type(TransferLegacy).creationCode, sender_);
  }

  /**

  /* External function */

  /**
   * @dev Check activation conditions. This activation conditions is current time >= last transaction of safe wallet + lackOfOutgoingTxRange.
   * @param legacyId_ legacy id
   * @return bool true if eligible for activation, false otherwise
   */
  function checkActiveLegacy(uint256 legacyId_) external view returns (bool) {
    address legacyAddress = _checkLegacyExisted(legacyId_);
    address guardAddress = _checkGuardExisted(legacyId_);

    return ITransferLegacy(legacyAddress).checkActiveLegacy(guardAddress);
  }

  /**
   * @dev create new legacy and guard
   * @param safeWallet   safe wallet address
   * @param mainConfig_  include name, note, nickname [], distributions[]
   * @param extraConfig_  include lackOfOutgoingTxRange
   * @return address legacy address
   * @return address guard address
   */
  function createLegacy(
    address safeWallet,
    LegacyMainConfig calldata mainConfig_,
    TransferLegacyStruct.LegacyExtraConfig calldata extraConfig_,
    TransferLegacyStruct.Distribution calldata layer2Distribution_,
    TransferLegacyStruct.Distribution calldata layer3Distribution_,
    string calldata nickName2,
    string calldata nickName3,
    uint256 signatureTimestamp,
    bytes calldata agreementSignature
  ) external returns (address, address) {
    if (mainConfig_.distributions.length != mainConfig_.nickNames.length || mainConfig_.distributions.length == 0) revert DistributionsInvalid();
    if (safeWallet == address(0)) revert SafeWalletInvalid();
    if (_checkExistGuardInSafeWallet(safeWallet)) revert ExistedGuardInSafeWallet(safeWallet);
    if (!_checkSignerIsOwnerOfSafeWallet(safeWallet, msg.sender)) revert SignerIsNotOwnerOfSafeWallet();
    if (extraConfig_.lackOfOutgoingTxRange == 0) revert ActivationTriggerInvalid();

    (uint256 newLegacyId, address legacyAddress, address guardAddress) = _createLegacy(
      type(TransferLegacy).creationCode,
      msg.sender
    );

    verifier.storeLegacyAgreement(msg.sender, legacyAddress, signatureTimestamp, agreementSignature);

    uint256 numberOfBeneficiaries = ITransferLegacy(legacyAddress).initialize(
      newLegacyId,
      safeWallet,
      mainConfig_.distributions,
      extraConfig_,
      layer2Distribution_,
      layer3Distribution_,
      premiumSetting,
      msg.sender,
      guardAddress,
      uniswapRouter,
      weth,
      paymentContract,
      mainConfig_.nickNames,
      nickName2,
      nickName3
    );

    ITransferLegacy(legacyAddress).setLegacyName(mainConfig_.name);
   

    ISafeGuard(guardAddress).initialize(safeWallet);

    if (!_checkNumBeneficiariesLimit(numberOfBeneficiaries)) revert NumBeneficiariesInvalid();
    TransferLegacyStruct.LegacyExtraConfig memory _legacyExtraConfig = TransferLegacyStruct.LegacyExtraConfig({
      lackOfOutgoingTxRange: extraConfig_.lackOfOutgoingTxRange,
      delayLayer2: ITransferLegacy(legacyAddress).delayLayer2(),
      delayLayer3: ITransferLegacy(legacyAddress).delayLayer3()
    });

    emit TransferLegacyCreated(newLegacyId, legacyAddress, guardAddress, msg.sender, safeWallet, mainConfig_, _legacyExtraConfig, block.timestamp);

    //set private code for legacy of premium user
    IPremiumSetting(premiumSetting).setPrivateCodeAndCronjob(msg.sender, legacyAddress);

    // Emit layer2/3 creation event if configured
    uint256 distribution2 = ITransferLegacy(legacyAddress).getDistribution(2, layer2Distribution_.user);
    uint256 distribution3 = ITransferLegacy(legacyAddress).getDistribution(3, layer3Distribution_.user);

    if (distribution2 != 0) {
      emit TransferLegacyLayer23Created(newLegacyId, 2, layer2Distribution_, nickName2);
    }

    if (distribution3 != 0) {
      emit TransferLegacyLayer23Created(newLegacyId, 3, layer3Distribution_, nickName3);
    }

    return (legacyAddress, guardAddress);
  }

  /**
   * @dev set legacy config include distributions, lackOfOutGoingTxRange
   * @param legacyId_  legacy id
   * @param mainConfig_ include name, note, nickname [], distributions[]
   * @param extraConfig_ include lackOfOutgoingTxRange
   */
  function setLegacyConfig(
    uint256 legacyId_,
    LegacyMainConfig calldata mainConfig_,
    TransferLegacyStruct.LegacyExtraConfig calldata extraConfig_,
    TransferLegacyStruct.Distribution calldata layer2Distribution_,
    TransferLegacyStruct.Distribution calldata layer3Distribution_,
    string calldata nickName2,
    string calldata nickName3
  ) external onlySafeWallet(legacyId_)  {
    address legacyAddress = _checkLegacyExisted(legacyId_);

    address owner = ITransferLegacy(legacyAddress).creator();

    bool isPremium = IPremiumSetting(premiumSetting).isPremium(owner);

    //Check ditribution length
    if (mainConfig_.distributions.length != mainConfig_.nickNames.length || mainConfig_.distributions.length == 0) revert DistributionsInvalid();

    if (_isCreateLegacy(msg.sender)) revert SenderIsCreatedLegacy(msg.sender);

    //Check invalid activation trigger
    if (extraConfig_.lackOfOutgoingTxRange == 0) revert ActivationTriggerInvalid();

    //Set distributions
    uint256 numberBeneficiaries = ITransferLegacy(legacyAddress).setLegacyDistributions(msg.sender, mainConfig_.distributions, mainConfig_.nickNames);

    //Check num beneficiaries and assets
    if (!_checkNumBeneficiariesLimit(numberBeneficiaries)) revert NumBeneficiariesInvalid();

    ITransferLegacy(legacyAddress).setActivationTrigger(msg.sender, extraConfig_.lackOfOutgoingTxRange);

    // Combine setting delay and layer 2/3 distribution (for premium user)
    ITransferLegacy(legacyAddress).setDelayAndLayer23Distributions(
      msg.sender,
      extraConfig_.delayLayer2,
      extraConfig_.delayLayer3,
      nickName2,
      nickName3,
      layer2Distribution_,
      layer3Distribution_
    );

    if (isPremium) {
      // Only emit events for premium users
      emit TransferLegacyLayer23DistributionUpdated(legacyId_, 2, nickName2, layer2Distribution_, block.timestamp);
      emit TransferLegacyLayer23DistributionUpdated(legacyId_, 3, nickName3, layer3Distribution_, block.timestamp);
    }

    TransferLegacyStruct.LegacyExtraConfig memory _legacyExtraConfig = TransferLegacyStruct.LegacyExtraConfig({
      lackOfOutgoingTxRange: extraConfig_.lackOfOutgoingTxRange,
      delayLayer2: ITransferLegacy(legacyAddress).delayLayer2(),
      delayLayer3: ITransferLegacy(legacyAddress).delayLayer3()
    });

    ITransferLegacy(legacyAddress).setLegacyName(mainConfig_.name); 

    emit TransferLegacyConfigUpdated(legacyId_, mainConfig_, _legacyExtraConfig, block.timestamp);
  }

  /**
   * @dev Set distributions[] legacy, call this function if only modify beneficiaries[], minRequiredSignatures to save gas for user.
   * @param legacyId_ legacy id
   * @param nickNames_  nick name[]
   * @param distributions_ ditributions[]
   */
  function setLegacyDistributions(
    uint256 legacyId_,
    string[] calldata nickNames_,
    TransferLegacyStruct.Distribution[] calldata distributions_
  ) external onlySafeWallet(legacyId_) {
    address legacyAddress = _checkLegacyExisted(legacyId_);
    // Check distribution length
    if (distributions_.length != nickNames_.length || distributions_.length == 0) revert DistributionsInvalid();

    // Set distribution assets
    uint256 numberOfBeneficiaries = ITransferLegacy(legacyAddress).setLegacyDistributions(msg.sender, distributions_,nickNames_);
    //Check beneficiary limit
    if (!_checkNumBeneficiariesLimit(numberOfBeneficiaries)) revert NumBeneficiariesInvalid();

    emit TransferLegacyDistributionUpdated(legacyId_, nickNames_, distributions_, block.timestamp);
  }

  function setLayer23Distributions(
    uint256 legacyId_,
    uint8 layer_,
    string calldata nickname_,
    TransferLegacyStruct.Distribution calldata distribution_
  ) external onlySafeWallet(legacyId_) {
   _setLayer23Distributions(legacyId_, layer_, nickname_, distribution_);
  }

    function setBothLayer23Distributions(
    uint256 legacyId_,
    string calldata nicknameLayer2_,
    TransferLegacyStruct.Distribution calldata layer2Distribution_,
    string calldata nicknameLayer3_,
    TransferLegacyStruct.Distribution calldata layer3Distribution_
  ) external onlySafeWallet(legacyId_) {
    _setLayer23Distributions(legacyId_, 2, nicknameLayer2_, layer2Distribution_);
    _setLayer23Distributions(legacyId_, 3, nicknameLayer3_, layer3Distribution_);

  }

  /**
   * @dev set activation trigger time, call this function if only mofify lackOfOutgoingTxRange to save gas for user.
   * @param legacyId_ legacy id
   * @param lackOfOutgoingTxRange_ lackOfOutgoingTxRange
   */
  function setActivationTrigger(uint256 legacyId_, uint128 lackOfOutgoingTxRange_) external onlySafeWallet(legacyId_) {
    address legacyAddress = _checkLegacyExisted(legacyId_);

    //Check invalid activation trigger
    if (lackOfOutgoingTxRange_ == 0) revert ActivationTriggerInvalid();

    //Set lackOfOutgoingTxRange_
    ITransferLegacy(legacyAddress).setActivationTrigger(msg.sender, lackOfOutgoingTxRange_);

    emit TransferLegacyTriggerUpdated(legacyId_, lackOfOutgoingTxRange_, block.timestamp);
  }

  /**
   * @dev Set name and note legacy, call this function if only modify name and note to save gas for user.
   * @param legacyId_ legacy id
   * @param name_ name legacy
   * @param note_ note legacy
   */
  function setNameNote(uint256 legacyId_, string calldata name_, string calldata note_) external onlySafeWallet(legacyId_) {
    address legacyAddress = _checkLegacyExisted(legacyId_);
    ITransferLegacy(legacyAddress).setLegacyName(name_);
    emit TransferLegacyNameNoteUpdated(legacyId_, name_, note_, block.timestamp);
  }

  /**
   * @dev Active legacy, call this function when the safewallet is eligible for activation.
   * @param legacyId_ legacy id
   */
  function activeLegacy(uint256 legacyId_, address[] calldata assets_, bool isETH_) external {
    address legacyAddress = _checkLegacyExisted(legacyId_);
    address guardAddress = _checkGuardExisted(legacyId_);
    if (isETH_ == false && assets_.length == 0) revert NumAssetsInvalid();

    //Active legacy
    ITransferLegacy(legacyAddress).activeLegacy(guardAddress, assets_, isETH_, msg.sender);
    uint8 beneLayer = ITransferLegacy(legacyAddress).getBeneficiaryLayer(msg.sender);
    uint8 currentLayer = ITransferLegacy(legacyAddress).getLayer();
    if (beneLayer > currentLayer) revert CannotClaim();
    if (beneLayer == 0) revert OnlyBeneficaries();
    emit TransferLegacyActivated(legacyId_, beneLayer, block.timestamp);

  }

  /* Internal function */
    function _setLayer23Distributions(
    uint256 legacyId_,
    uint8 layer_,
    string calldata nickname_,
    TransferLegacyStruct.Distribution calldata distribution_
  ) internal {
    address legacyAddress = _checkLegacyExisted(legacyId_);
    ITransferLegacy(legacyAddress).setLayer23Distributions(msg.sender, layer_, nickname_, distribution_);
    emit TransferLegacyLayer23DistributionUpdated(legacyId_, layer_, nickname_, distribution_, block.timestamp);
  }
}
