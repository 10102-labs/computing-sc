// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract EIP712LegacyVerifier is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
  struct Legacy {
    address legacyAddress;
    uint256 timestamp;
    bytes signature;
  }

  mapping(address => Legacy[]) public legacySigned;
  address public transferLegacyEOA;
  address public transferLegacy;
  address public multisigLegacy;

  event LegacySigned(address indexed user, uint256 legacyId, uint256 timestamp);

  error InvalidSignature();
  error TimestampOutOfRange();
  error InvalidV();
  error HexLengthInsufficient();
  error ZeroAddressNotAllowed();
  error UnauthorizedCaller();
  error AlreadyInit();

  string private constant MESSAGE_PREFIX = "I agree to legacy at address ";
  uint256 private constant MAX_PAST_OFFSET = 10 minutes;
  uint256 private constant MAX_FUTURE_OFFSET = 5 minutes;

  function initialize(address initialOwner) public initializer {
    __ReentrancyGuard_init();
    __Ownable_init(initialOwner);
  }

  modifier onlyRouter() {
    if (msg.sender != transferLegacy && msg.sender != transferLegacyEOA && msg.sender != multisigLegacy) revert UnauthorizedCaller();
    _;
  }

  function setRouterAddresses(address _transferLegacyEOA, address _transferLegacy, address _multisigLegacy) external onlyOwner {
    //if (transferLegacyEOA != address(0)) revert AlreadyInit();

    if (_transferLegacyEOA == address(0) || _transferLegacy == address(0) || _multisigLegacy == address(0)) {
      revert ZeroAddressNotAllowed();
    }

    transferLegacyEOA = _transferLegacyEOA;
    transferLegacy = _transferLegacy;
    multisigLegacy = _multisigLegacy;
  }

  /// @notice Store a legacy agreement signed via signMessage
  function storeLegacyAgreement(address user, address legacyAddress, uint256 timestamp, bytes calldata signature) external nonReentrant onlyRouter {
    uint256 nowTs = block.timestamp;
    if (timestamp < nowTs - MAX_PAST_OFFSET || timestamp > nowTs + MAX_FUTURE_OFFSET) {
      revert TimestampOutOfRange();
    }

    string memory message = generateMessage(legacyAddress, timestamp);
    bytes32 ethSignedMessageHash = _getEthSignedMessageHash(message);
    address recovered = recoverSigner(ethSignedMessageHash, signature);
    if (recovered != user) {
      revert InvalidSignature();
    }

    legacySigned[user].push(Legacy({legacyAddress: legacyAddress, timestamp: timestamp, signature: signature}));

    emit LegacySigned(user, uint256(uint160(legacyAddress)), timestamp);
  }

  function _getEthSignedMessageHash(string memory message) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", _uintToString(bytes(message).length), message));
  }

  function getUserLegacyCount(address user) external view returns (uint256) {
    return legacySigned[user].length;
  }

  function getUserLegacy(
    address user,
    uint256 index
  ) external view returns (address legacyAddress, uint256 timestamp, string memory message, bytes memory signature) {
    Legacy memory legacy = legacySigned[user][index];
    string memory termString = generateMessage(legacy.legacyAddress, legacy.timestamp);
    return (legacy.legacyAddress, legacy.timestamp, termString, legacy.signature);
  }

  function recoverSigner(bytes32 digest, bytes memory signature) public pure returns (address) {
    if (signature.length != 65) {
      revert InvalidSignature();
    }

    bytes32 r;
    bytes32 s;
    uint8 v;

    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    if (v < 27) v += 27;
    if (v != 27 && v != 28) {
      revert InvalidV();
    }

    return ecrecover(digest, v, r, s);
  }

  function generateMessage(address legacyAddress, uint256 timestamp) internal pure returns (string memory) {
    return string.concat(MESSAGE_PREFIX, addressToString(legacyAddress), " at timestamp ", _uintToString(timestamp));
  }

  function addressToString(address _addr) public pure returns (string memory) {
    bytes20 value = bytes20(_addr);
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(42); // "0x" + 40 hex chars
    str[0] = "0";
    str[1] = "x";

    for (uint256 i = 0; i < 20; i++) {
      str[2 + i * 2] = alphabet[uint8(value[i] >> 4)];
      str[3 + i * 2] = alphabet[uint8(value[i] & 0x0f)];
    }

    return string(str);
  }

  function _uintToString(uint256 value) internal pure returns (string memory) {
    if (value == 0) return "0";
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + (value % 10)));
      value /= 10;
    }
    return string(buffer);
  }

  function _toHexString(address account) internal pure returns (string memory) {
    return _toHexString(uint256(uint160(account)), 20);
  }

  function _toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
    bytes16 _hexSymbols = "0123456789abcdef";
    bytes memory buffer = new bytes(2 + length * 2);
    buffer[0] = "0";
    buffer[1] = "x";
    for (uint256 i = 2 + length * 2; i > 2; --i) {
      buffer[i - 1] = _hexSymbols[value & 0xf];
      value >>= 4;
    }
    if (value != 0) revert HexLengthInsufficient();
    return string(buffer);
  }
}
