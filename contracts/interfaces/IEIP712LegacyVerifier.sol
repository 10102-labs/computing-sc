// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IEIP712LegacyVerifier {
    function storeLegacyAgreement(address user, address legacyAddress, uint256 timestamp, bytes calldata signature) external;
}