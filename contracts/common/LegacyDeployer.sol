// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {SafeGuard} from "../SafeGuard.sol";
import {TransferLegacy} from "../forwarding/TransferLegacyContract.sol";
import {TransferEOALegacy} from "../forwarding/TransferLegacyEOAContract.sol";
import {MultisigLegacy} from "../inheritance/MultisigLegacyContract.sol";
import {ILegacyDeployer} from "../interfaces/ILegacyDeployer.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract LegacyDeployer is OwnableUpgradeable, ILegacyDeployer {
  address public multisigLegacyRouter;
  address public transferLegacyRouter;
  address public transferEOALegacyRouter;

  mapping(address => uint256) internal nonceByUsers;

  error InvalidParam();

  modifier onlyRouter() {
    require(
      msg.sender == transferLegacyRouter || msg.sender == transferEOALegacyRouter || msg.sender == multisigLegacyRouter || msg.sender == owner(),
      "Router only"
    );
    _;
  }
  function initialize() public initializer {
    __Ownable_init(msg.sender);
  }

  function setParams(address _multisigLegacyRouter, address _transferLegacyRouter, address _transferEOALegacyRouter) public onlyOwner {
    if (_multisigLegacyRouter == address(0) || _transferLegacyRouter == address(0) || _transferEOALegacyRouter == address(0)) revert InvalidParam();
    multisigLegacyRouter = _multisigLegacyRouter;
    transferLegacyRouter = _transferLegacyRouter;
    transferEOALegacyRouter = _transferEOALegacyRouter;
  }

  function getNextAddress(bytes calldata byteCode, address user) external view returns (address nextLegacy) {
    uint256 nextNonce = nonceByUsers[user] + 1;
    bytes32 salt = keccak256(abi.encodePacked(user, nextNonce));
    bytes32 bytecodeHash = keccak256(byteCode);
    return Create2.computeAddress(salt, bytecodeHash);
  }

  function createLegacy(bytes calldata byteCode, address user) external onlyRouter returns (address legacyAddress, address guardAddress) {
    nonceByUsers[user] += 1;
    bytes32 salt = keccak256(abi.encodePacked(user, nonceByUsers[user]));
    legacyAddress = Create2.deploy(0, salt, byteCode);
    if (msg.sender != transferEOALegacyRouter) {
      guardAddress = Create2.deploy(0, salt, type(SafeGuard).creationCode);
    }
  }
}
