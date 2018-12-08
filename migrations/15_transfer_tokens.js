/* global artifacts, web3 */
/* eslint-disable no-unused-vars */
const BN = require("bn.js");
const fs = require("fs");

const PollFactory = artifacts.require("./PollFactory.sol");

const KNC = artifacts.require("./KyberNetworkCrystal.sol");
const DAI = artifacts.require("./Dai.sol");
// const SALT = artifacts.require("./mockTokens/Salt.sol");
// const ZIL = artifacts.require("./mockTokens/Zilliqa.sol");
// const MANA = artifacts.require("./mockTokens/Mana.sol");

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
  const admin = accounts[0];
  const userWallet = accounts[4];

  // Set the instances
  const ReserveInstance = await PollFactory.at(PollFactory.address);
  const KNCInstance = await KNC.at(KNC.address);
  const DAIInstance = await DAI.at(DAI.address);

  // Set token amounts to transfer to user and reserve wallet
  const KNCAmount = new BN(100000).mul(new BN(10).pow(await KNCInstance.decimals())).toString();
  const DAIAmount = new BN(100000).mul(new BN(10).pow(await DAIInstance.decimals())).toString();

  // Transfer tokens to the user
  tx(await KNCInstance.transfer(userWallet, KNCAmount), "transfer()");
  tx(await DAIInstance.transfer(userWallet, DAIAmount), "transfer()");
  // Transfer tokens and ETH to the reserve
  tx(await KNCInstance.transfer(PollFactory.address, KNCAmount), "transfer()");
  // tx(await DAIInstance.transfer(PollFactory.address, DAIAmount), "transfer()");
  tx(await ReserveInstance.sendTransaction({ from: admin, value: web3.utils.toWei(new BN(100)) }), "sendTransaction()");
};
