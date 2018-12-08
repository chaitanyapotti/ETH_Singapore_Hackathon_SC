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

function stdlog(input) {
  console.log(`${moment().format("YYYY-MM-DD HH:mm:ss.SSS")}] ${input}`);
}

module.exports = async callback => {
  try {
    stdlog("- START -");
    const accounts = await web3.eth.getAccounts();
    const pollFactory = await PollFactory.at(PollFactory.address);
    const daicoToken = await DaicoToken.at(DaicoToken.address);
    const daiToken = await DaiToken.at(DaiToken.address);

    const killAddress = await pollFactory.killPollAddress();
    console.log("Kill Poll Address: ", killAddress);

    // Vote in Kill Poll
    const killPollInstance = await IPoll.at(killAddress);
    // await killPollInstance.vote(0, { from: accounts[3] });
    // await killPollInstance.vote(0, { from: accounts[6] });
    // await killPollInstance.vote(0, { from: accounts[8] });
    await killPollInstance.vote(0, { from: accounts[4] });

    const killPollNum = await killPollInstance.getVoteTally(0);
    const killPollDenom = await daicoToken.totalSupply();
    const killPollConsensus = parseFloat(killPollNum) / parseFloat(killPollDenom);
    console.log("Kill Poll Consensus: ", killPollConsensus);

    await pollFactory.executeKill();
    const userEtherBalance = await web3.eth.getBalance(accounts[4]);
    const userDaiBalance = await daiToken.balanceOf(accounts[4]);
    await pollFactory.refundByKill({ from: accounts[4] });
    const postUserEtherBalance = await web3.eth.getBalance(accounts[4]);
    const postUserDaiBalance = await daiToken.balanceOf(accounts[4]);
    console.log("Before Refund, ether balance: ", web3.utils.fromWei(userEtherBalance));
    console.log("Before Refund, dai balance: ", web3.utils.fromWei(userDaiBalance));
    console.log("After Refund, ether balance: ", web3.utils.fromWei(postUserEtherBalance));
    console.log("After Refund, dai balance: ", web3.utils.fromWei(postUserDaiBalance));
    const userBalance = await daicoToken.balanceOf(accounts[4]);
    console.log("After kill, user tokens are burnt and his token balance: ", web3.utils.fromWei(userBalance));

    stdlog("- END -");
    callback();
  } catch (error) {
    callback(error);
  }
};
