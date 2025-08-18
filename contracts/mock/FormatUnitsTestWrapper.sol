// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../libraries/FormatUnits.sol";

contract FormatUnitsTestWrapper {
    using FormatUnits for uint256;

    function callFormat(uint256 amount, uint8 decimals) external pure returns (string memory) {
        return amount.format(decimals);
    }
}
