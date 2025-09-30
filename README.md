# Digital Inheritance SC


This repository contains the smart contracts for the project **Digital Inheritance**, implemented in **Solidity** and managed with **Hardhat**.  
It includes source code, deployment scripts, and tests.

## 🚀 Getting Started

### 1. Clone the repo
```bash
git clone <repo-url>
cd <repo-name>
```

## 2. Install dependencies
```bash
npm install
# or
yarn install
```

## 3. Compile contracts
```bash
npx hardhat compile
```

## 4. Run unit tests
``` bash
npx hardhat test
```


## 5. Deployment
Update the hardhat.config.ts with your network settings (e.g., Testnet, Mainnet).
``` bash
npx hardhat deploy --network <network-name> --tags <tag-name>
```


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

