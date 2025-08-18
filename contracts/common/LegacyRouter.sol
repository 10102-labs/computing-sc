// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v5.x
pragma solidity 0.8.20;

import {AccessGuard} from "../access/AccessGuard.sol";

contract LegacyRouter is AccessGuard {
  /* State variable */
  // guard storage slot in safe wallet
  uint256 public constant BENEFICIARIES_LIMIT = 10;

  /* Internal function */
  /**
   * @dev Check beneficiaries limit
   * @param numBeneficiaries_ number of beneficiaries
   */
  function _checkNumBeneficiariesLimit(uint256 numBeneficiaries_) internal pure returns (bool) {
    if (numBeneficiaries_ == 0 || numBeneficiaries_ > BENEFICIARIES_LIMIT) {
      return false;
    }
    return true;
  }
}
