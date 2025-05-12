# Rybov Token

Rybov is a simple ERC20 token designed to be deployed on the Polygon network for low transaction costs and fast confirmations.

## Features

- **Standard ERC20 Functionality**: Transfer tokens between addresses
- **Mintable**: New tokens can be minted by the contract owner
- **Pausable**: Token transfers can be paused/unpaused by the contract owner
- **Upgradeable**: Uses OpenZeppelin's UUPS upgradeable pattern for future improvements

## Smart Contract

The Rybov token is implemented as a standard ERC20 token with the following features:

- **ERC20 Standard**: Implements the standard ERC20 interface
- **Ownable**: Contract has an owner with special privileges
- **Pausable**: Token transfers can be paused in case of emergency
- **Upgradeable**: Contract can be upgraded using the UUPS pattern

## Deployment

### Prerequisites

- Node.js and npm installed
- Hardhat installed (`npm install --save-dev hardhat`)
- OpenZeppelin Contracts installed (`npm install @openzeppelin/contracts-upgradeable`)
- A wallet with MATIC for gas fees
- API key from a provider like Infura or Alchemy

### Configuration

1. Create a `.env` file in the project root with the following variables:
   ```
   PRIVATE_KEY=your_private_key
   POLYGON_RPC_URL=your_polygon_rpc_url
   MUMBAI_RPC_URL=your_mumbai_rpc_url
   ```

   Note: For Amoy testnet, the RPC URL is hardcoded in the configuration.

2. Configure Hardhat to use Polygon networks by adding the following to your `hardhat.config.js`:
   ```javascript
   require("@nomiclabs/hardhat-ethers");
   require('dotenv').config();

   module.exports = {
     solidity: "0.8.20",
     networks: {
       polygon: {
         url: process.env.POLYGON_RPC_URL,
         accounts: [process.env.PRIVATE_KEY]
       },
       mumbai: {
         url: process.env.MUMBAI_RPC_URL,
         accounts: [process.env.PRIVATE_KEY]
       },
       amoy: {
         url: "https://rpc-amoy.polygon.technology",
         accounts: [process.env.PRIVATE_KEY],
         chainId: 80002, // Amoy testnet chain ID
         gasPrice: 35000000000 // Default gas price for Amoy (35 Gwei)
       }
     }
   };
   ```

### Deployment Steps

#### Using Ethers.js

```bash
npx hardhat run scripts/deploy_with_ethers.ts --network mumbai
```

#### Using Web3.js

```bash
npx hardhat run scripts/deploy_with_web3.ts --network mumbai
```

Replace `mumbai` with:
- `polygon` to deploy to the Polygon mainnet
- `amoy` to deploy to the Polygon Amoy testnet

## Usage Guide

### For Token Owner

1. **Mint Tokens**:
   ```javascript
   // Mint 100 tokens to a specific address
   await rybovContract.mint(recipientAddress, ethers.utils.parseEther("100"));
   ```

2. **Pause Token Transfers**:
   ```javascript
   // Pause all token transfers in case of emergency
   await rybovContract.pause();
   ```

3. **Unpause Token Transfers**:
   ```javascript
   // Resume token transfers
   await rybovContract.unpause();
   ```

### For Token Holders

1. **Check Your Balance**:
   ```javascript
   // Check your token balance
   const balance = await rybovContract.balanceOf(myAddress);
   console.log("Balance:", ethers.utils.formatEther(balance));
   ```

2. **Transfer Tokens**:
   ```javascript
   // Transfer 10 tokens to another address
   await rybovContract.transfer(recipientAddress, ethers.utils.parseEther("10"));
   ```

3. **Approve Spending**:
   ```javascript
   // Approve another address to spend 20 tokens on your behalf
   await rybovContract.approve(spenderAddress, ethers.utils.parseEther("20"));
   ```

## Frontend Integration

To integrate with a frontend application:

1. Use ethers.js or web3.js to connect to the Polygon network
2. Load the Rybov token contract ABI
3. Connect to the deployed contract address
4. Call contract functions to interact with the token

Example with ethers.js:

```javascript
const { ethers } = require("ethers");
const rybovABI = require("./RybovABI.json");

// Connect to Polygon
const provider = new ethers.providers.JsonRpcProvider(process.env.POLYGON_RPC_URL);
const signer = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

// Connect to the Rybov contract
const rybovAddress = "YOUR_DEPLOYED_CONTRACT_ADDRESS";
const rybovContract = new ethers.Contract(rybovAddress, rybovABI, signer);

// Transfer tokens
async function transferTokens(recipientAddress, amount) {
  const tx = await rybovContract.transfer(recipientAddress, ethers.utils.parseEther(amount));
  await tx.wait();
  console.log("Tokens transferred successfully!");
}
```

## License

This project is licensed under the MIT License.
