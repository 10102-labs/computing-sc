// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

library FormatUnits {
    function format(uint256 amount, uint8 decimals) internal pure returns (string memory) {
        return format(amount, decimals, 6);  // maximum 6 digits after .
    }

    function format(uint256 amount, uint8 decimals, uint8 fractionalDigits) internal pure returns (string memory) {
        if (decimals == 0) {
            return _toString(amount);
        }

        uint256 integerPart = amount / (10 ** decimals);
        uint256 fractionalPart = amount % (10 ** decimals);

        if (fractionalDigits < decimals) {
            fractionalPart /= 10 ** (decimals - fractionalDigits);
        }

        string memory fractionalStr = _padZeros(_toString(fractionalPart), fractionalDigits);
        return string(abi.encodePacked(_toString(integerPart), ".", fractionalStr));
    }

    function _toString(uint256 value) private pure returns (string memory) {
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
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function _padZeros(string memory str, uint8 length) private pure returns (string memory) {
        bytes memory bStr = bytes(str);
        if (bStr.length >= length) {
            return str;
        }
        bytes memory padded = new bytes(length);
        uint256 padLen = length - bStr.length;
        for (uint256 i = 0; i < padLen; i++) {
            padded[i] = "0";
        }
        for (uint256 i = 0; i < bStr.length; i++) {
            padded[padLen + i] = bStr[i];
        }
        return string(padded);
    }
}
