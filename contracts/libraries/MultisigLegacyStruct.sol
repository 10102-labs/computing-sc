// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

library MultisigLegacyStruct {
  struct LegacyExtraConfig {
    uint128 minRequiredSignatures;
    uint128 lackOfOutgoingTxRange;
  }
}
