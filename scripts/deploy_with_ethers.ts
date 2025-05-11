import { deploy } from './ethers-lib'

/**
 * Deployment script for Rybov token on Polygon network
 *
 * To deploy to Polygon mainnet:
 * - Configure your .env file with PRIVATE_KEY and POLYGON_RPC_URL
 * - Run: npx hardhat run scripts/deploy_with_ethers.ts --network polygon
 *
 * To deploy to Polygon Mumbai testnet:
 * - Configure your .env file with PRIVATE_KEY and MUMBAI_RPC_URL
 * - Run: npx hardhat run scripts/deploy_with_ethers.ts --network mumbai
 *
 * To deploy to Polygon Amoy testnet:
 * - Configure your .env file with PRIVATE_KEY
 * - Run: npx hardhat run scripts/deploy_with_ethers.ts --network amoy
 */
(async () => {
  try {
    // Deploy the Rybov contract
    // Pass the deployer's address as the initial owner
    const result = await deploy('Rybov', [])
    console.log(`Rybov token deployed to: ${result.address}`)
    console.log(`Network: ${process.env.HARDHAT_NETWORK || 'local'}`)
    console.log(`Transaction hash: ${result.deployTransaction?.hash || 'N/A'}`)

    // Initialize the contract if needed
    // This step is handled by the proxy deployment in production

    console.log('Deployment completed successfully')
  } catch (e) {
    console.error('Deployment failed:')
    console.error(e.message)
  }
})()
