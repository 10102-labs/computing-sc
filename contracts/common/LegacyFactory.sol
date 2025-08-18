// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v5.x
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/Create2.sol";
import {ISafeWallet} from "../interfaces/ISafeWallet.sol";
contract LegacyFactory {

  bytes32 internal constant GUARD_STORAGE_SLOT = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;
  
  /* Error */
  error LegacyNotFound();
  error GuardNotFound();
  error GuardSafeWalletInvalid();
  error ModuleSafeWalletInvalid();

  /* State variable */
  uint256 internal _legacyId;
  mapping(uint256 => address) public legacyAddresses;
  mapping(uint256 => address) public guardAddresses;
  mapping(address => uint256) internal nonceByUsers;
  mapping(address => bool) internal isCreateLegacy;

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
   * @dev create legacy and guard
   * @param legacyBytecode_  legacy byte code
   * @param guardByteCode_ guard byte code
   * @param sender_ sender
   * @return legacyId
   * @return legacyAddress
   * @return guardAddress
   */
  function _createLegacy(bytes memory legacyBytecode_, bytes memory guardByteCode_, address sender_) internal returns (uint256, address, address) {
    _legacyId += 1;
    nonceByUsers[sender_] += 1;
    bytes32 salt = keccak256(abi.encodePacked(sender_, nonceByUsers[sender_]));
    address legacyAddress = Create2.deploy(0, salt, legacyBytecode_);
    address guardAddress = Create2.deploy(0, salt, guardByteCode_);
    legacyAddresses[_legacyId] = legacyAddress;
    guardAddresses[_legacyId] = guardAddress;
    isCreateLegacy[sender_] = true;
    return (_legacyId, legacyAddress, guardAddress);
  }

  /**
   * @dev Check whether legacy existed
   * @param legacyId_  legacy id
   */
  function _checkLegacyExisted(uint256 legacyId_) internal view returns (address legacyAddress) {
    legacyAddress = legacyAddresses[legacyId_];
    if (legacyAddress == address(0)) revert LegacyNotFound();
  }

  /**
   * @dev Check whether guard existed
   * @param legacyId_ legacy id
   */
  function _checkGuardExisted(uint256 legacyId_) internal view returns (address guardAddress) {
    guardAddress = guardAddresses[legacyId_];
    if (guardAddress == address(0)) revert LegacyNotFound();
  }

  function _isCreateLegacy(address sender_) internal view returns (bool) {
    return isCreateLegacy[sender_];
  }

    /**
   * @dev Check whether the safe wallet invalid. Ensure safe wallet exist guard and legacy was created by system.
   * @param legacyId_ legacy id
   * @param safeWallet_ safe wallet address
   */
  function _checkSafeWalletValid(uint256 legacyId_, address safeWallet_) internal view {
    address guardAddress = _checkGuardExisted(legacyId_);
    address moduleAddress = _checkLegacyExisted(legacyId_);

    //Check safe wallet exist guard created by system
    bytes memory guardBytes = ISafeWallet(safeWallet_).getStorageAt(uint256(GUARD_STORAGE_SLOT), 1);
    bytes32 rawBytes = abi.decode(guardBytes, (bytes32));
    address guardSafeWalletAddress = address(uint160(uint256(rawBytes)));

     if (guardAddress != guardSafeWalletAddress) revert GuardSafeWalletInvalid();

    //Check safe wallet exist legacy created by system
    if (ISafeWallet(safeWallet_).isModuleEnabled(moduleAddress) == false) revert ModuleSafeWalletInvalid();
  }

  /**
   * @dev Check whether safe wallet exist guard.
   * @param safeWallet_ safe wallet address
   * @return bool true if guard exist, false otherwise
   */
  function _checkExistGuardInSafeWallet(address safeWallet_) internal view returns (bool) {
    bytes memory guardBytes = ISafeWallet(safeWallet_).getStorageAt(uint256(GUARD_STORAGE_SLOT), 1);
    bytes32 rawBytes = abi.decode(guardBytes, (bytes32));
    address guardSafeWalletAddress = address(uint160(uint256(rawBytes)));
    if (guardSafeWalletAddress == address(0)) return false;
    return true;
  }

  /**
   * @dev Check whether signer is signer of safewallet.
   * @param safeWallet_  safe wallet address
   * @param signer_ signer address
   */
  function _checkSignerIsOwnerOfSafeWallet(address safeWallet_, address signer_) internal view returns (bool) {
    address[] memory signers = ISafeWallet(safeWallet_).getOwners();
    for (uint256 i = 0; i < signers.length;) {
      if (signer_ == signers[i]) {
        return true;
      }
      unchecked { ++i; }
    }
    return false;
  }


}
