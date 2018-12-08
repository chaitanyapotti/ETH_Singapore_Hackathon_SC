/* global artifacts, web3 */
/* eslint-disable no-underscore-dangle, no-unused-vars */
const BN = require("bn.js");
const moment = require("moment");
const increaseTime = require("./increaseTime");

const CrowdSale = artifacts.require("./CrowdSale.sol");
const PollFactory = artifacts.require("./PollFactory.sol");
const DaicoToken = artifacts.require("./DaicoToken.sol");
const DaiToken = artifacts.require("./Dai.sol");
const IPoll = artifacts.require("./IPoll.sol");
const NetworkProxy = artifacts.require("./KyberNetworkProxy.sol");

function stdlog(input) {
  console.log(`${moment().format("YYYY-MM-DD HH:mm:ss.SSS")}] ${input}`);
}

function tx(result, call) {
  const logs = result.logs.length > 0 ? result.logs[0] : { address: null, event: null };

  console.log();
  console.log(`   ${call}`);
  console.log("   ------------------------");
  console.log(`   > transaction hash: ${result.tx}`);
  console.log(`   > contract address: ${logs.address}`);
  console.log(`   > gas used: ${result.receipt.gasUsed}`);
  console.log(`   > event: ${logs.event}`);
  console.log();
}

module.exports = async callback => {
  try {
    stdlog("- START -");
    let expectedRate;
    let slippageRate;
    const ETH_ADDRESS = "0xeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee";
    const accounts = await web3.eth.getAccounts();
    const userWallet = accounts[4];
    const crowdSale = await CrowdSale.at(CrowdSale.address);
    const pollFactory = await PollFactory.at(PollFactory.address);
    const daicoToken = await DaicoToken.at(DaicoToken.address);
    const DAIInstance = await DaiToken.at(DaiToken.address);
    const NetworkProxyInstance = await NetworkProxy.at(NetworkProxy.address);

    await increaseTime(10000000, web3);

    let contractEthBalance = web3.utils.fromWei(await web3.eth.getBalance(pollFactory.address));
    console.log("Contract ETH balance: ", contractEthBalance, " ETH");

    let contractDaiBalance = web3.utils.fromWei(await DAIInstance.balanceOf(pollFactory.address));
    console.log("Contract DAI balance: ", contractDaiBalance, " DAI");

    const userDaiBalance = web3.utils.fromWei(await DAIInstance.balanceOf(userWallet));
    console.log("User DAI balance: ", userDaiBalance, " DAI");

    // Approve the KyberNetwork contract to spend user's tokens
    await DAIInstance.approve(NetworkProxy.address, web3.utils.toWei(new BN(100000)), { from: userWallet });
    ({ expectedRate, slippageRate } = await NetworkProxyInstance.getExpectedRate(
      DaiToken.address, // srcToken
      ETH_ADDRESS, // destToken
      web3.utils.toWei(new BN(200)) // srcQty
    ));
    console.log("Received expected rate : ", web3.utils.fromWei(expectedRate));

    for (let index = 0; index < 35; index++) {
      const result = await NetworkProxyInstance.swapTokenToEther(
        DaiToken.address, // srcToken
        web3.utils.toWei(new BN(200)), // srcAmount
        expectedRate, // minConversionRate
        { from: userWallet }
      );
      tx(result, "DAI <-> ETH swapTokenToEther()");
    }

    contractEthBalance = web3.utils.fromWei(await web3.eth.getBalance(pollFactory.address));
    console.log("Contract ETH balance: ", contractEthBalance, " ETH");

    await pollFactory.withdrawAmount(web3.utils.toWei("25"));

    contractEthBalance = web3.utils.fromWei(await web3.eth.getBalance(pollFactory.address));
    console.log("Contract ETH balance: ", contractEthBalance, " ETH");

    contractDaiBalance = web3.utils.fromWei(await DAIInstance.balanceOf(pollFactory.address));
    console.log("Contract DAI balance: ", contractDaiBalance, " DAI");

    stdlog("- END -");
    callback();
  } catch (error) {
    callback(error);
  }
};
