// instead of using a deploy.js script with the usual main() function which gets called later in the script,
// we use a deploy folder which gets accessed by hardhat when we run "yarn hardhat deploy"
// hardhat will call whichever function is in the first script in the deploy folder

// function deployFunc() {}

//instead let's use an async anon function

// module.exports = async (hre) => {
//     const {getNamedAccounts, deployments } = hre
//     //hr.getNamedAccounts, hre.deployments
// }
// because hre is the input to the anon function we don't need to declare the const variables,
// we can just do the following:

const { networkConfig, developmentChains } = require("../helper-hardhat-config") // get network configuration info from helper file
const { network } = require("hardhat")
const { verify } = require("../utils/verify.js")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments //pull these from deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    //const ethUsdPriceFeedAddress = networkConfig[chainId]["EthUsdPriceFeed"]
    let ethUsdPriceFeedAddress
    if (developmentChains.includes(network.name)) {
        const ethUsdAggregator = await deployments.get("MockV3Aggregator")
        ethUsdPriceFeedAddress = ethUsdAggregator.address
    } else {
        ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"]
    }
    // if the contract doesn't exist, we edploy a minimal version for local testing

    // Before we deploy to a testnet or mainnet we want to do testing on our smart contract,
    // but sometimes we may want information that might not be local.
    // When we test on a localhost or hardhat network we can use a mock to simulate information
    // that isn't local (like live ETH/USD prices which we would usually grab from chainlink)
    const args = [ethUsdPriceFeedAddress]
    const fundMe = await deploy("FundMe", {
        from: deployer, //overrides
        args: args, // put price feed address
        log: true,
        waitConfirmations: network.config.blockConfirmations || 1,
    })

    if (
        !developmentChains.includes(network.name) &&
        process.env.ETHERSCAN_API_KEY
    ) {
        await verify(fundMe.address, args)
    }
    log("-------------------------------")
}
module.exports.tags = ["all", "fundme"]
