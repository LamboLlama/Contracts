# LamboLlama Contracts

This repository contains the smart contracts for the LamboLlama ecosystem. The contracts include the LamboLlama token, presale, airdrop, and team vesting functionality.

## Contracts Overview

### 1. **LamboLlama Token (LLL)**

The LamboLlama token (LLL) is an ERC20 token integrated with LayerZero’s Omnichain Fungible Token (OFT) standard. This enables seamless cross-chain token transfers, enhancing token interoperability across multiple blockchain networks.
Contract: LamboLlama.sol

### 2. **Presale Contract**

The presale contract allows users to participate in token sales before the official public launch. It includes features such as:

- **Whitelist**: A dedicated whitelist for special addresses. These addresses are able to invest on the first day of the presale.
- **Bonus Structure**: Early investors earn bonus tokens based on their ETH contribution thresholds on the total amount raised.
- **Bonus Tokens Vesting**: Bonus tokens are vested linear for 1 month

### 3. **Airdrop Contract**

The airdrop contract facilitates the distribution of LLL tokens to eligible users. It allows:

- **Airdrop Claim**: Users can claim their airdrop directly through the contract. The airdrop is vested linear over 6 months

### 4. **Vesting Contract (Team Vesting)**

The vesting contract ensures that team tokens are released over a specified time period, preventing immediate dumping and ensuring long-term commitment to the project.

- **Time-based Vesting**: Tokens are gradually released over time. Vesting is linear and the vesting time is 12 months

## How to Use

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/LamboLlama/Contracts.git
   ```

1. **Install the dependencies**:

   ```bash
   npm i
   ```

1. **Compile all contracts**:

   ```bash
   npm run compile
   ```

1. **Test all contracts**:
   ```bash
   npm run test
   ```
1. **Coverage of all contracts**:

   ```bash
   npm run coverage
   ```

   The current status of the tests:

   ![Run Tests](https://github.com/LamboLlama/Contracts/actions/workflows/main.yml/badge.svg?branch=main)
