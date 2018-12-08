/* global artifacts */
/* eslint-disable no-unused-vars, no-eval */
const fs = require("fs");

const Network = artifacts.require("./KyberNetwork.sol");
const NetworkProxy = artifacts.require("./KyberNetworkProxy.sol");
const ConversionRates = artifacts.require("./ConversionRates.sol");
const LiquidityConversionRates = artifacts.require("./LiquidityConversionRates.sol");
// const SanityRates = artifacts.require("./SanityRates.sol");
const PollFactory = artifacts.require("./PollFactory.sol");
// const AutomatedReserve = artifacts.require("./KyberAutomatedReserve.sol");
const FeeBurner = artifacts.require("./FeeBurner.sol");
const WhiteList = artifacts.require("./WhiteList.sol");
const ExpectedRate = artifacts.require("./ExpectedRate.sol");
const DaicoToken = artifacts.require("./DaicoToken.sol");
const CrowdSale = artifacts.require("./CrowdSale.sol");

const KNC = artifacts.require("./KyberNetworkCrystal.sol");
const DAI = artifacts.require("./Dai.sol");

const networkConfig = JSON.parse(fs.readFileSync("../config/network.json", "utf8"));
const tokenConfig = JSON.parse(fs.readFileSync("../config/tokens.json", "utf8"));

module.exports = (deployer, network, accounts) => {
  console.log("\n");

  console.log("Network");
  console.log("==================");
  console.log(network);

  console.log("\n");

  console.log("Permissions");
  console.log("==================");
  console.log(`(admin) ${accounts[0]}`);
  console.log(`(operator) ${accounts[0]}`);
  console.log(`(alerter) ${accounts[0]}`);

  console.log("\n");

  console.log("Wallets");
  console.log("==================");
  console.log(`(user) ${accounts[4]}`);
  console.log(`(reserve) ${accounts[5]}`);
  console.log(`(tax) ${accounts[6]}`);
  Object.keys(networkConfig.feeSharingWallets).forEach(key => {
    console.log(`(${key}) ${eval(networkConfig.feeSharingWallets[key].wallet)}`);
  });

  console.log("\n");

  console.log("Tokens");
  console.log("==================");
  Object.keys(tokenConfig.Reserve).forEach(key => {
    console.log(`(${key}) ${eval(key).address}`);
  });
  Object.keys(tokenConfig.AutomatedReserve).forEach(key => {
    console.log(`(${key}) ${eval(key).address}`);
  });

  console.log("\n");

  console.log("Contracts");
  console.log("==================");
  console.log(`(KyberNetwork) ${Network.address}`);
  console.log(`(KyberNetworkProxy) ${NetworkProxy.address}`);
  console.log(`(ConversionRates) ${ConversionRates.address}`);
  console.log(`(LiquidityConversionRates) ${LiquidityConversionRates.address}`);
  // console.log(`(SanityRates) ${SanityRates.address}`);
  console.log(`(KyberReserve) ${PollFactory.address}`);
  // console.log(`(AutomatedKyberReserve) ${AutomatedReserve.address}`);
  console.log(`(FeeBurner) ${FeeBurner.address}`);
  console.log(`(WhiteList) ${WhiteList.address}`);
  console.log(`(ExpectedRate) ${ExpectedRate.address}`);
  console.log("==================");
  console.log(`(DaicoToken) ${DaicoToken.address}`);
  console.log(`(CrowdSale) ${CrowdSale.address}`);
  console.log(`(PollFactory) ${PollFactory.address}`);
};
