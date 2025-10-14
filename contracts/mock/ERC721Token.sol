// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MockERC721 is ERC721 {
  uint256 private tokenId;

  constructor() ERC721("Test Token", "Test Token") {}

  function mint(address user, uint256 amount) public {
    for (uint256 i = 0; i < amount; i++) {
      _mint(user, tokenId);
      tokenId++;
    }
  }
}
