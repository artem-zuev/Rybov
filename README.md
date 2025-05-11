# Rybov Token

Rybov is an ERC20 token designed for use between spouses, friends, and family members to reward each other for completing tasks like "Make tea", "Clean the bathroom", etc. The token is built to be deployed on the Polygon network for low transaction costs and fast confirmations.

## Features

- **Task Management**: Create, complete, verify, and cancel tasks
- **Relationship Management**: Establish and remove relationships between users
- **Reward System**: Automatically mint and distribute tokens as rewards for completed tasks
- **Upgradeable**: Uses OpenZeppelin's UUPS upgradeable pattern for future improvements

## Smart Contract

The Rybov token is implemented as an ERC20 token with additional functionality for task management and relationship tracking. Key features include:

- **Task Creation**: Users can create tasks and assign them to people they have a relationship with
- **Task Completion**: Assignees can mark tasks as completed
- **Task Verification**: Task creators can verify completed tasks, which automatically rewards the assignee
- **Relationship Management**: Users can establish relationships with others (spouse, friend, etc.)

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

### For Task Creators

1. **Establish a Relationship**:
   ```javascript
   // Establish a relationship with a friend
   await rybovContract.establishRelationship(friendAddress, "friend");
   ```

2. **Create a Task**:
   ```javascript
   // Create a task "Make tea" with a reward of 5 tokens
   await rybovContract.createTask(friendAddress, "Make tea", 5);
   ```

3. **Verify a Completed Task**:
   ```javascript
   // Verify task completion and reward the assignee
   await rybovContract.verifyTask(taskId);
   ```

### For Task Assignees

1. **View Assigned Tasks**:
   ```javascript
   // Get all tasks assigned to you
   const myTasks = await rybovContract.getUserTasks(myAddress);
   ```

2. **Complete a Task**:
   ```javascript
   // Mark a task as completed
   await rybovContract.completeTask(taskId);
   ```

3. **Check Your Balance**:
   ```javascript
   // Check your token balance
   const balance = await rybovContract.balanceOf(myAddress);
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

// Create a task
async function createTask(assigneeAddress, description, reward) {
  const tx = await rybovContract.createTask(assigneeAddress, description, reward);
  await tx.wait();
  console.log("Task created successfully!");
}
```

## License

This project is licensed under the MIT License.
