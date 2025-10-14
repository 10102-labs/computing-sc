// SPDX-License-Identifier: UNLICENSED
// OpenZeppelin Contracts v5.x
pragma solidity 0.8.20;

interface ILegacyDeployer {
    function getNextAddress(bytes calldata byteCode, address user) external view returns (address nextLegacy);
    function createLegacy(bytes calldata byteCode, address user)  external returns (address legacyAddress, address guardAddress);
}