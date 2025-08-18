// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {TimelockERC20} from "./TimeLockERC20.sol";
import {TimelockERC721} from "./TimeLockERC721.sol";
import {TimelockERC1155} from "./TimeLockERC1155.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {ISafeWallet} from "../interfaces/ISafeWallet.sol";

import {Enum} from "../libraries/Enum.sol";
import {TimelockHelper} from "./TimelockHelper.sol";

contract TimeLockRouter is OwnableUpgradeable {
  struct TimelockERC20InputData {
    address tokenAddress;
    uint256 amount;
  }

  struct TimelockERC721InputData {
    address tokenAddress;
    uint256 id;
  }

  struct TimelockERC1155InputData {
    address tokenAddress;
    uint256 id;
    uint256 amount;
  }

  struct TimelockRegular {
    TimelockERC20InputData[] timelockERC20;
    TimelockERC721InputData[] timelockERC721;
    TimelockERC1155InputData[] timelockERC1155;
    uint256 duration;
    string name;
  }

  struct TimelockSoft {
    TimelockERC20InputData[] timelockERC20;
    TimelockERC721InputData[] timelockERC721;
    TimelockERC1155InputData[] timelockERC1155;
    uint256 bufferTime;
    string name;
  }

  struct TimelockGift {
    TimelockERC20InputData[] timelockERC20;
    TimelockERC721InputData[] timelockERC721;
    TimelockERC1155InputData[] timelockERC1155;
    uint256 duration;
    address recipient;
    string name;
    string giftName;
  }

  TimelockERC20 public timelockERC20Contract;
  TimelockERC721 public timelockERC721Contract;
  TimelockERC1155 public timelockERC1155Contract;

  uint256 public timelockCounter;
  address internal constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  bytes4 private constant IERC721_ID = 0x80ac58cd;
  bytes4 private constant IERC1155_ID = 0xd9b67a26;

  // ───────────── Native Token Receive ─────────────
  receive() external payable {}

  function initialize(address initialOwner) external initializer {
    __Ownable_init(initialOwner);
  }

  function setTimelock(address payable _timelockERC20, address payable _timelockERC721, address payable _timelockERC1155) external onlyOwner {
    timelockERC20Contract = TimelockERC20(_timelockERC20);
    timelockERC721Contract = TimelockERC721(_timelockERC721);
    timelockERC1155Contract = TimelockERC1155(_timelockERC1155);
  }

  function createTimelock(TimelockRegular calldata timelockRegular) external payable {
    if (timelockRegular.duration == 0) revert TimelockHelper.ZeroDuration();

    timelockCounter++;

    if (timelockRegular.timelockERC20.length > 0) {
      _handleTimelockRegularERC20(
        timelockCounter,
        timelockRegular.timelockERC20,
        timelockRegular.duration,
        timelockRegular.name,
        msg.sender,
        TimelockHelper.LockStatus.Live
      );
    }
    if (timelockRegular.timelockERC721.length > 0) {
      _handleTimelockRegularERC721(
        timelockCounter,
        timelockRegular.timelockERC721,
        timelockRegular.duration,
        timelockRegular.name,
        msg.sender,
        TimelockHelper.LockStatus.Live
      );
    }
    if (timelockRegular.timelockERC1155.length > 0) {
      _handleTimelockRegularERC1155(
        timelockCounter,
        timelockRegular.timelockERC1155,
        timelockRegular.duration,
        timelockRegular.name,
        msg.sender,
        TimelockHelper.LockStatus.Live
      );
    }
  }

  function createTimelockWithSafe(TimelockRegular calldata timelockRegular, address safeAddress) external {
    if (timelockRegular.duration == 0) revert TimelockHelper.ZeroDuration();

    timelockCounter++;

    if (timelockRegular.timelockERC20.length > 0) {
      _handleTimelockRegularERC20(
        timelockCounter,
        timelockRegular.timelockERC20,
        timelockRegular.duration,
        timelockRegular.name,
        safeAddress,
        TimelockHelper.LockStatus.Created
      );
    }
    if (timelockRegular.timelockERC721.length > 0) {
      _handleTimelockRegularERC721(
        timelockCounter,
        timelockRegular.timelockERC721,
        timelockRegular.duration,
        timelockRegular.name,
        safeAddress,
        TimelockHelper.LockStatus.Created
      );
    }
    if (timelockRegular.timelockERC1155.length > 0) {
      _handleTimelockRegularERC1155(
        timelockCounter,
        timelockRegular.timelockERC1155,
        timelockRegular.duration,
        timelockRegular.name,
        safeAddress,
        TimelockHelper.LockStatus.Created
      );
    }
  }

  function getStatusOwner(uint256 id) public view returns (TimelockHelper.LockStatus, address) {
    (TimelockHelper.LockStatus status, address owner) = timelockERC20Contract.getStatus(id);
    if (status == TimelockHelper.LockStatus.Null) {
      (status, owner) = timelockERC721Contract.getStatus(id);
    }
    if (status == TimelockHelper.LockStatus.Null) {
      (status, owner) = timelockERC1155Contract.getStatus(id);
    }
    return (status, owner);
  }

  function makeLiveBySafe(uint256 id) external {
    (TimelockHelper.LockStatus status, address safe) = getStatusOwner(id);
    if (status != TimelockHelper.LockStatus.Created) revert TimelockHelper.InvalidStatus();
    if (safe != msg.sender) revert TimelockHelper.NotOwner();

    // transfer
    _handleSafeTransferERC20(id, safe);
    _handleSafeTransferERC721(id, safe);
    _handleSafeTransferERC1155(id, safe);

    timelockERC20Contract.changeStatus(id, TimelockHelper.LockStatus.Live);
    timelockERC721Contract.changeStatus(id, TimelockHelper.LockStatus.Live);
    timelockERC1155Contract.changeStatus(id, TimelockHelper.LockStatus.Live);
  }

  function _handleSafeTransferERC20(uint256 id, address safe) internal {
    (address[] memory tokens, uint256[] memory amounts) = TimelockERC20(timelockERC20Contract).getData(id);
    if (tokens.length == 0) return;

    for (uint256 i = 0; i < tokens.length; i++) {
      if (tokens[i] == NATIVE_TOKEN) {
        bool transferEthSuccess = ISafeWallet(safe).execTransactionFromModule(address(timelockERC20Contract), amounts[i], "", Enum.Operation.Call);
        if (!transferEthSuccess) revert TimelockHelper.ExecTransactionFromModuleFailed();
      } else {
        bytes memory transferErc20Data = abi.encodeWithSignature("transfer(address,uint256)", address(timelockERC20Contract), amounts[i]);
        bool transferErc20Success = ISafeWallet(safe).execTransactionFromModule(tokens[i], 0, transferErc20Data, Enum.Operation.Call);
        if (!transferErc20Success) revert TimelockHelper.ExecTransactionFromModuleFailed();
      }
    }
  }

  function _handleSafeTransferERC721(uint256 id, address safe) internal {
    (address[] memory tokens, uint256[] memory ids) = TimelockERC721(timelockERC721Contract).getData(id);
    if (tokens.length == 0) return;

    for (uint256 i = 0; i < tokens.length; i++) {
      bytes memory transferErc721Data = abi.encodeWithSignature(
        "transferFrom(address,address,uint256)",
        safe,
        address(timelockERC721Contract),
        ids[i]
      );
      bool transferErc721Success = ISafeWallet(safe).execTransactionFromModule(tokens[i], 0, transferErc721Data, Enum.Operation.Call);
      if (!transferErc721Success) revert TimelockHelper.ExecTransactionFromModuleFailed();
    }
  }

  function _handleSafeTransferERC1155(uint256 id, address safe) internal {
    (address[] memory tokens, uint256[] memory ids, uint256[] memory amounts) = TimelockERC1155(timelockERC1155Contract).getData(id);
    if (tokens.length == 0) return;

    for (uint256 i = 0; i < tokens.length; i++) {
      bytes memory transferErc1155Data = abi.encodeWithSignature(
        "safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)",
        safe,
        address(timelockERC1155Contract),
        ids,
        amounts,
        ""
      );
      bool transferErc1155Success = ISafeWallet(safe).execTransactionFromModule(tokens[i], 0, transferErc1155Data, Enum.Operation.Call);
      if (!transferErc1155Success) revert TimelockHelper.ExecTransactionFromModuleFailed();
    }
  }

  function createSoftTimelock(TimelockSoft calldata timelockSoft) external payable {
    if (timelockSoft.bufferTime == 0) revert TimelockHelper.ZeroBufferTime();

    timelockCounter++;

    if (timelockSoft.timelockERC20.length > 0) {
      _handleTimelockSoftERC20(
        timelockCounter,
        timelockSoft.timelockERC20,
        timelockSoft.bufferTime,
        timelockSoft.name,
        msg.sender,
        TimelockHelper.LockStatus.Live
      );
    }
    if (timelockSoft.timelockERC721.length > 0) {
      _handleTimelockSoftERC721(
        timelockCounter,
        timelockSoft.timelockERC721,
        timelockSoft.bufferTime,
        timelockSoft.name,
        msg.sender,
        TimelockHelper.LockStatus.Live
      );
    }

    if (timelockSoft.timelockERC1155.length > 0) {
      _handleTimelockSoftERC1155(
        timelockCounter,
        timelockSoft.timelockERC1155,
        timelockSoft.bufferTime,
        timelockSoft.name,
        msg.sender,
        TimelockHelper.LockStatus.Live
      );
    }
  }

  function createSoftTimelockWithSafe(TimelockSoft calldata timelockSoft, address safeAddress) external payable {
    if (timelockSoft.bufferTime == 0) revert TimelockHelper.ZeroBufferTime();

    timelockCounter++;

    if (timelockSoft.timelockERC20.length > 0) {
      _handleTimelockSoftERC20(
        timelockCounter,
        timelockSoft.timelockERC20,
        timelockSoft.bufferTime,
        timelockSoft.name,
        safeAddress,
        TimelockHelper.LockStatus.Created
      );
    }
    if (timelockSoft.timelockERC721.length > 0) {
      _handleTimelockSoftERC721(
        timelockCounter,
        timelockSoft.timelockERC721,
        timelockSoft.bufferTime,
        timelockSoft.name,
        safeAddress,
        TimelockHelper.LockStatus.Created
      );
    }

    if (timelockSoft.timelockERC1155.length > 0) {
      _handleTimelockSoftERC1155(
        timelockCounter,
        timelockSoft.timelockERC1155,
        timelockSoft.bufferTime,
        timelockSoft.name,
        safeAddress,
        TimelockHelper.LockStatus.Created
      );
    }
  }

  function createTimelockedGift(TimelockGift calldata timelockGift) external payable {
    if (timelockGift.duration == 0) revert TimelockHelper.ZeroDuration();
    if (timelockGift.recipient == address(0)) revert TimelockHelper.InvalidRecipient();

    timelockCounter++;

    if (timelockGift.timelockERC20.length > 0) {
      _handleTimelockGiftERC20(
        timelockCounter,
        timelockGift.timelockERC20,
        timelockGift.duration,
        timelockGift.recipient,
        timelockGift.name,
        timelockGift.giftName,
        msg.sender,
        TimelockHelper.LockStatus.Live
      );
    }
    if (timelockGift.timelockERC721.length > 0) {
      _handleTimelockGiftERC721(
        timelockCounter,
        timelockGift.timelockERC721,
        timelockGift.duration,
        timelockGift.recipient,
        timelockGift.name,
        timelockGift.giftName,
        msg.sender,
        TimelockHelper.LockStatus.Live
      );
    }
    if (timelockGift.timelockERC1155.length > 0) {
      _handleTimelockGiftERC1155(
        timelockCounter,
        timelockGift.timelockERC1155,
        timelockGift.duration,
        timelockGift.recipient,
        timelockGift.name,
        timelockGift.giftName,
        msg.sender,
        TimelockHelper.LockStatus.Live
      );
    }
  }

  function createTimelockedGiftWithSafe(TimelockGift calldata timelockGift, address safeAddress) external payable {
    if (timelockGift.duration == 0) revert TimelockHelper.ZeroDuration();
    if (timelockGift.recipient == address(0)) revert TimelockHelper.InvalidRecipient();

    timelockCounter++;

    if (timelockGift.timelockERC20.length > 0) {
      _handleTimelockGiftERC20(
        timelockCounter,
        timelockGift.timelockERC20,
        timelockGift.duration,
        timelockGift.recipient,
        timelockGift.name,
        timelockGift.giftName,
        safeAddress,
        TimelockHelper.LockStatus.Created
      );
    }
    if (timelockGift.timelockERC721.length > 0) {
      _handleTimelockGiftERC721(
        timelockCounter,
        timelockGift.timelockERC721,
        timelockGift.duration,
        timelockGift.recipient,
        timelockGift.name,
        timelockGift.giftName,
        safeAddress,
        TimelockHelper.LockStatus.Created
      );
    }
    if (timelockGift.timelockERC1155.length > 0) {
      _handleTimelockGiftERC1155(
        timelockCounter,
        timelockGift.timelockERC1155,
        timelockGift.duration,
        timelockGift.recipient,
        timelockGift.name,
        timelockGift.giftName,
        safeAddress,
        TimelockHelper.LockStatus.Created
      );
    }
  }

  function unlockSoftTimelock(uint256 id) external {
    timelockERC20Contract.unlockSoftTimelock(id, msg.sender);
    timelockERC721Contract.unlockSoftTimelock(id, msg.sender);
    timelockERC1155Contract.unlockSoftTimelock(id, msg.sender);
  }

  function withdraw(uint256 id) external {
    timelockERC20Contract.withdraw(id, msg.sender);
    timelockERC721Contract.withdraw(id, msg.sender);
    timelockERC1155Contract.withdraw(id, msg.sender);
  }

  // ───────────── private ─────────────
  // ********** Regular **********

  // regular ERC20

  function _makeListERC20(TimelockERC20InputData[] calldata timelockERC20) private pure returns (address[] memory tokens, uint256[] memory amounts) {
    tokens = new address[](timelockERC20.length);
    amounts = new uint256[](timelockERC20.length);
    for (uint256 i = 0; i < timelockERC20.length; i++) {
      tokens[i] = timelockERC20[i].tokenAddress;
      amounts[i] = timelockERC20[i].amount;
    }
  }

  function _handleTimelockRegularERC20(
    uint256 timelockId,
    TimelockERC20InputData[] calldata timelockERC20,
    uint256 duration,
    string calldata name,
    address owner,
    TimelockHelper.LockStatus lockStatus
  ) private {
    (address[] memory tokens, uint256[] memory amounts) = _makeListERC20(timelockERC20);
    uint256 requiredNativeAmount = _validateERC20Input(tokens, amounts);
    if (lockStatus == TimelockHelper.LockStatus.Live) {
      _transferERC20TokensIn(tokens, amounts, requiredNativeAmount);
    }
    timelockERC20Contract.createTimelock{value: msg.value}(timelockId, tokens, amounts, duration, name, owner, lockStatus);
  }

  function _handleTimelockSoftERC20(
    uint256 timelockId,
    TimelockERC20InputData[] calldata timelockERC20,
    uint256 bufferTime,
    string calldata name,
    address owner,
    TimelockHelper.LockStatus lockStatus
  ) private {
    (address[] memory tokens, uint256[] memory amounts) = _makeListERC20(timelockERC20);
    uint256 requiredNativeAmount = _validateERC20Input(tokens, amounts);
    if (lockStatus == TimelockHelper.LockStatus.Live) {
      _transferERC20TokensIn(tokens, amounts, requiredNativeAmount);
    }
    timelockERC20Contract.createSoftTimelock{value: msg.value}(timelockId, tokens, amounts, bufferTime, name, owner, lockStatus);
  }

  function _handleTimelockGiftERC20(
    uint256 timelockId,
    TimelockERC20InputData[] calldata timelockERC20,
    uint256 duration,
    address recipient,
    string calldata name,
    string calldata giftName,
    address owner,
    TimelockHelper.LockStatus lockStatus
  ) private {
    (address[] memory tokens, uint256[] memory amounts) = _makeListERC20(timelockERC20);
    uint256 requiredNativeAmount = _validateERC20Input(tokens, amounts);
    if (lockStatus == TimelockHelper.LockStatus.Live) {
      _transferERC20TokensIn(tokens, amounts, requiredNativeAmount);
    }

    timelockERC20Contract.createTimelockedGift{value: msg.value}(timelockId, tokens, amounts, duration, recipient, name, giftName, owner, lockStatus);
  }

  function _transferERC20TokensIn(address[] memory tokens, uint256[] memory amounts, uint256 requiredNativeAmount) private {
    if (requiredNativeAmount != msg.value) {
      revert TimelockHelper.InsufficientNativeToken();
    }

    for (uint256 i = 0; i < tokens.length; i++) {
      if (tokens[i] != NATIVE_TOKEN) {
        IERC20(tokens[i]).transferFrom(msg.sender, address(timelockERC20Contract), amounts[i]);
      }
    }
  }

  function _validateERC20Input(address[] memory tokens, uint256[] memory amounts) private pure returns (uint256) {
    if (tokens.length == 0 || tokens.length != amounts.length) revert TimelockHelper.MismatchedArrayLength();

    uint256 requiredNativeAmount = 0;
    for (uint256 i = 0; i < tokens.length; i++) {
      if (amounts[i] == 0) revert TimelockHelper.InvalidTokenAmount();
      if (tokens[i] == NATIVE_TOKEN) {
        requiredNativeAmount = amounts[i];
      }
    }

    // ───── Check for duplicate token addresses ─────
    for (uint256 i = 0; i < tokens.length; i++) {
      for (uint256 j = i + 1; j < tokens.length; j++) {
        if (tokens[i] == tokens[j]) revert TimelockHelper.DuplicateTokenAddress();
      }
    }

    return requiredNativeAmount;
  }

  // regular ERC721

  function _makeListERC721(TimelockERC721InputData[] calldata timelockERC721) private pure returns (address[] memory tokens, uint256[] memory ids) {
    tokens = new address[](timelockERC721.length);
    ids = new uint256[](timelockERC721.length);
    for (uint256 i = 0; i < timelockERC721.length; i++) {
      tokens[i] = timelockERC721[i].tokenAddress;
      ids[i] = timelockERC721[i].id;
    }
  }

  function _handleTimelockRegularERC721(
    uint256 timelockId,
    TimelockERC721InputData[] calldata timelockERC721,
    uint256 duration,
    string calldata name,
    address owner,
    TimelockHelper.LockStatus lockStatus
  ) private {
    (address[] memory tokens, uint256[] memory ids) = _makeListERC721(timelockERC721);
    _validateERC721Input(tokens, ids);
    if (lockStatus == TimelockHelper.LockStatus.Live) {
      _transferERC721TokensIn(tokens, ids);
    }
    timelockERC721Contract.createTimelock(timelockId, tokens, ids, duration, name, owner, lockStatus);
  }

  function _handleTimelockSoftERC721(
    uint256 timelockId,
    TimelockERC721InputData[] calldata timelockERC721,
    uint256 bufferTime,
    string calldata name,
    address owner,
    TimelockHelper.LockStatus lockStatus
  ) private {
    (address[] memory tokens, uint256[] memory ids) = _makeListERC721(timelockERC721);

    _validateERC721Input(tokens, ids);
    if (lockStatus == TimelockHelper.LockStatus.Live) {
      _transferERC721TokensIn(tokens, ids);
    }
    timelockERC721Contract.createSoftTimelock(timelockId, tokens, ids, bufferTime, name, owner, lockStatus);
  }

  function _handleTimelockGiftERC721(
    uint256 timelockId,
    TimelockERC721InputData[] calldata timelockERC721,
    uint256 duration,
    address recipient,
    string calldata name,
    string calldata giftName,
    address owner,
    TimelockHelper.LockStatus lockStatus
  ) private {
    (address[] memory tokens, uint256[] memory ids) = _makeListERC721(timelockERC721);

    _validateERC721Input(tokens, ids);
    if (lockStatus == TimelockHelper.LockStatus.Live) {
      _transferERC721TokensIn(tokens, ids);
    }

    timelockERC721Contract.createTimelockedGift(timelockId, tokens, ids, duration, recipient, name, giftName, owner, lockStatus);
  }

  function _transferERC721TokensIn(address[] memory tokens, uint256[] memory ids) private {
    for (uint256 i = 0; i < tokens.length; i++) {
      IERC721(tokens[i]).safeTransferFrom(msg.sender, address(timelockERC721Contract), ids[i]);
    }
  }

  function _validateERC721(address token) private view {
    if (!IERC165(token).supportsInterface(IERC721_ID)) revert TimelockHelper.InvalidTokenType();
  }

  function _validateERC721Input(address[] memory tokens, uint256[] memory ids) private view {
    if (tokens.length == 0 || tokens.length != ids.length) revert TimelockHelper.MismatchedArrayLength();
    for (uint256 i = 0; i < tokens.length; i++) {
      _validateERC721(tokens[i]);
      for (uint256 j = i + 1; j < tokens.length; j++) {
        if (tokens[i] == tokens[j] && ids[i] == ids[j]) revert TimelockHelper.DuplicateTokenAddresses();
      }
    }
  }

  // regular ERC1155

  function _makeListERC1155(
    TimelockERC1155InputData[] calldata timelockERC1155
  ) private pure returns (address[] memory tokens, uint256[] memory ids, uint256[] memory amounts) {
    tokens = new address[](timelockERC1155.length);
    ids = new uint256[](timelockERC1155.length);
    amounts = new uint256[](timelockERC1155.length);
    for (uint256 i = 0; i < timelockERC1155.length; i++) {
      tokens[i] = timelockERC1155[i].tokenAddress;
      ids[i] = timelockERC1155[i].id;
      amounts[i] = timelockERC1155[i].amount;
    }
  }

  function _handleTimelockRegularERC1155(
    uint256 timelockId,
    TimelockERC1155InputData[] calldata timelockERC1155,
    uint256 duration,
    string calldata name,
    address owner,
    TimelockHelper.LockStatus lockStatus
  ) private {
    (address[] memory tokens, uint256[] memory ids, uint256[] memory amounts) = _makeListERC1155(timelockERC1155);

    _validateERC1155Input(tokens, ids, amounts);
    if (lockStatus == TimelockHelper.LockStatus.Live) {
      _transferERC1155TokensIn(tokens, ids, amounts);
    }
    timelockERC1155Contract.createTimelock(timelockId, tokens, ids, amounts, duration, name, owner, lockStatus);
  }

  function _handleTimelockSoftERC1155(
    uint256 timelockId,
    TimelockERC1155InputData[] calldata timelockERC1155,
    uint256 bufferTime,
    string calldata name,
    address owner,
    TimelockHelper.LockStatus lockStatus
  ) private {
    (address[] memory tokens, uint256[] memory ids, uint256[] memory amounts) = _makeListERC1155(timelockERC1155);

    for (uint256 i = 0; i < timelockERC1155.length; i++) {
      tokens[i] = timelockERC1155[i].tokenAddress;
      ids[i] = timelockERC1155[i].id;
      amounts[i] = timelockERC1155[i].amount;
    }

    _validateERC1155Input(tokens, ids, amounts);
    if (lockStatus == TimelockHelper.LockStatus.Live) {
      _transferERC1155TokensIn(tokens, ids, amounts);
    }
    timelockERC1155Contract.createSoftTimelock(timelockId, tokens, ids, amounts, bufferTime, name, owner, lockStatus);
  }

  function _handleTimelockGiftERC1155(
    uint256 timelockId,
    TimelockERC1155InputData[] calldata timelockERC1155,
    uint256 duration,
    address recipient,
    string calldata name,
    string calldata giftName,
    address owner,
    TimelockHelper.LockStatus lockStatus
  ) private {
    (address[] memory tokens, uint256[] memory ids, uint256[] memory amounts) = _makeListERC1155(timelockERC1155);

    _validateERC1155Input(tokens, ids, amounts);
    if (lockStatus == TimelockHelper.LockStatus.Live) {
      _transferERC1155TokensIn(tokens, ids, amounts);
    }

    timelockERC1155Contract.createTimelockedGift(timelockId, tokens, ids, amounts, duration, recipient, name, giftName, owner, lockStatus);
  }

  function _transferERC1155TokensIn(address[] memory tokens, uint256[] memory ids, uint256[] memory amounts) private {
    for (uint256 i = 0; i < tokens.length; i++) {
      IERC1155(tokens[i]).safeTransferFrom(msg.sender, address(timelockERC1155Contract), ids[i], amounts[i], "");
    }
  }

  function _validateERC1155(address token) private view {
    if (!IERC165(token).supportsInterface(IERC1155_ID)) revert TimelockHelper.InvalidTokenType();
  }

  function _validateERC1155Input(address[] memory tokens, uint256[] memory ids, uint256[] memory amounts) private view {
    if (tokens.length == 0 || tokens.length != ids.length || ids.length != amounts.length) revert TimelockHelper.MismatchedArrayLength();
    for (uint256 i = 0; i < amounts.length; i++) {
      if (amounts[i] == 0) revert TimelockHelper.ZeroAmount();
    }
    for (uint256 i = 0; i < tokens.length; i++) {
      _validateERC1155(tokens[i]);
      for (uint256 j = i + 1; j < tokens.length; j++) {
        if (tokens[i] == tokens[j] && ids[i] == ids[j]) revert TimelockHelper.DuplicateTokenAddresses();
      }
    }
  }
}
