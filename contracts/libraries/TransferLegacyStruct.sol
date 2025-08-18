// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library TransferLegacyStruct {
  struct LegacyExtraConfig {
    uint256 lackOfOutgoingTxRange;
    uint256 delayLayer2;
    uint256 delayLayer3;
  }

  struct Distribution {
    address user;
    uint8 percent;
  }

  struct Swap {
    address router;
    address weth;
  }
}
