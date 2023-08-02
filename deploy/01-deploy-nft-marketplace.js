const { network } = require("hardhat")
const { developmetnChains, VERIFICATION_BLOCK_CONFIRMATIONS } = require('../helper-hardhat-config')
const { verify } = require("../utils/verify")

module.exports = async ({ getNamedAccounts, deployments}) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts
    const waitBlockConfirmations = developmentChains.includes(network.name)
        ? 1
        : VERIFICATION_BLOCK_CONFIRMATIONS
    
    log("-----------------------------------")
    const arguments = []
    const nftMarketplace = await deploy("NftMarketplace", {
        from: deployer ,
        args: arguments,
        log: true,
        waitConfirmations: waitBlockConfirmations,
    })

    // verifying the deployments
    if (!developmetnChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
        log("Verifying...")
        await verify(nftMarketplace.address, arguments)
    }
    log("-----------------------------------")
}

module.exports.tags = ["all", "nftmarketplace"]