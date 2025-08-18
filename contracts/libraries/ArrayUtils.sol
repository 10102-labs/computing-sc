// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ArrayUtils {
    function makeAddressArray(address addr) internal pure returns (address[] memory) {
        address[] memory arr = new address[](1);
        arr[0] = addr;
        return arr;
    }

    function makeStringArray(string memory str) internal pure returns (string[] memory) {
        string[] memory arr = new string[](1);
        arr[0] = str;
        return arr;
    }
}
