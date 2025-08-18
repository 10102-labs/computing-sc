// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v5.x
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/Create2.sol";

contract EOALegacyFactory {
  /* Error */
  error LegacyNotFound();

  /* State variable */
  uint256 public _legacyId;
  mapping(uint256 => address) public legacyAddresses;
  mapping(address => bool) public isCreateLegacy;
  mapping(address => uint256) public nonceByUsers;

  /* Internal function */
  /**
   * @dev get next address create
   * @param bytecode_  byte code
   * @param sender_  sender
   */
  function _getNextAddress(bytes memory bytecode_, address sender_) internal view returns (address) {
    uint256 nextNonce = nonceByUsers[sender_] + 1;
    bytes32 salt = keccak256(abi.encodePacked(sender_, nextNonce));
    bytes32 bytecodeHash = keccak256(bytecode_);
    return Create2.computeAddress(salt, bytecodeHash);
  }

  /**
   * @dev create legacy
   * @param legacyBytecode_  legacy byte code

   * @param sender_ sender
   * @return legacyId
   * @return legacyAddress

   */
  function _createLegacy(bytes memory legacyBytecode_, address sender_) internal returns (uint256, address) {
    _legacyId += 1;
    nonceByUsers[sender_] += 1;
    bytes32 salt = keccak256(abi.encodePacked(sender_, nonceByUsers[sender_]));
    address legacyAddress = Create2.deploy(0, salt, legacyBytecode_);
    legacyAddresses[_legacyId] = legacyAddress;
    isCreateLegacy[sender_] = true;

    return (_legacyId, legacyAddress);
  }

  /**
   * @dev Check whether legacy existed
   * @param legacyId_  legacy id
   */
  function _checkLegacyExisted(uint256 legacyId_) internal view returns (address legacyAddress) {
    legacyAddress = legacyAddresses[legacyId_];
    if (legacyAddress == address(0)) revert LegacyNotFound();
  }

  function _isCreateLegacy(address sender_) internal view returns (bool) {
    return isCreateLegacy[sender_];
  }
}
