/* global artifacts */
/* eslint-disable no-unused-vars, no-eval */
const fs = require("fs");

const Network = artifacts.require("./KyberNetwork.sol");
const ConversionRates = artifacts.require("./ConversionRates.sol");
// const SanityRates = artifacts.require("./SanityRates.sol");
const PollFactory = artifacts.require("./PollFactory.sol");

const KNC = artifacts.require("./KyberNetworkCrystal.sol");
const DAI = artifacts.require("./Dai.sol");

const tokenConfig = JSON.parse(fs.readFileSync("../config/tokens.json", "utf8"));

function tx(result, call) {
  const logs = result.logs.length > 0 ? result.logs[0] : { address: null, event: null };

  console.log();
  console.log(`   Calling ${call}`);
  console.log("   ------------------------");
  console.log(`   > transaction hash: ${result.tx}`);
  console.log(`   > contract address: ${logs.address}`);
  console.log(`   > gas used: ${result.receipt.gasUsed}`);
  console.log(`   > event: ${logs.event}`);
  console.log();
}

module.exports = async (deployer, network, accounts) => {
  const reserveWallet = accounts[5];

  // Set the instances
  const NetworkInstance = await Network.at(Network.address);
  const PollFactoryInstance = await PollFactory.at(PollFactory.address);

  // Set the reserve contract addresses
  tx(await PollFactoryInstance.setContracts(Network.address, ConversionRates.address, 0), "setContracts()");

  // Add reserve to network
  tx(await NetworkInstance.addReserve(PollFactoryInstance.address, true), "addReserve()");

  Object.keys(tokenConfig.Reserve).forEach(async key => {
    // Add the withdrawal address for each token
    // tx(await PollFactoryInstance.approveWithdrawAddress(eval(key).address, reserveWallet, true), "approveWithdrawAddress()");

    // List token pairs for the reserve
    tx(await NetworkInstance.listPairForReserve(PollFactoryInstance.address, eval(key).address, true, true, true), "listPairForReserve()");
  });
};
