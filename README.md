# Computing SC

This repository contains the smart contracts for the project **Computing** by [10102](https://10102.io/), implemented in **Solidity** and managed with **Hardhat**.  

## ⚖️ License & Copyright

Copyright (c) 2025 **10102**. All rights reserved.

This software and associated documentation files are **not** licensed under any open-source license. No part of this repository may be copied, modified, distributed, or used for commercial purposes without the express written permission of the copyright holder.


## ⚠️ Disclaimer: Use at Your Own Risk

**IMPORTANT:** The smart contracts in this repository are provided "as is", without warranty of any kind, express or implied. 

* **Financial Risk:** Interacting with smart contracts involves inherent risks, including but not limited to technical vulnerabilities, bugs, and permanent loss of funds.
* **No Liability:** In no event shall **10102** or the contributors be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the software or the use or other dealings in the software.


# 🧪 Project Structure
```
├── LICENSE
├── README.md
├── contract-addresses.json     # Deployed contract addresses
├── contracts
│   ├── SafeGuard.sol           
│   ├── common                  # Deployer, Factory, Generic Contracts
│   ├── forwarding              # Contracts for Transfer Legacy 
│   ├── inheritance             # Contracts for Multisig Legacy 
│   ├── interfaces
│   ├── libraries
│   ├── mock
│   ├── premium                 # Contracts for Premium Function
│   ├── term                    # Verify Term of Services Signature
│   └── timelock                # Contracts for Timelock
├── deploy
├── hardhat.config.ts
├── package.json
├── scripts
├── test
├── tsconfig.json
```
