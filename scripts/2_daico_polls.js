/* global artifacts, web3 */
/* eslint-disable no-underscore-dangle, no-unused-vars */
const BN = require("bn.js");
const moment = require("moment");
const increaseTime = require("./increaseTime");

const CrowdSale = artifacts.require("./CrowdSale.sol");
const PollFactory = artifacts.require("./PollFactory.sol");
const DaicoToken = artifacts.require("./DaicoToken.sol");
const IPoll = artifacts.require("./IPoll.sol");

function stdlog(input) {
  console.log(`${moment().format("YYYY-MM-DD HH:mm:ss.SSS")}] ${input}`);
}

module.exports = async callback => {
  try {
    stdlog("- START -");
    const accounts = await web3.eth.getAccounts();
    const crowdSale = await CrowdSale.at(CrowdSale.address);
    const pollFactory = await PollFactory.at(PollFactory.address);
    const daicoToken = await DaicoToken.at(DaicoToken.address);

    // Created Tap Poll
    await pollFactory.createTapIncrementPoll();
    const tapAddress = await pollFactory.tapPoll();
    console.log("Tap Poll Address: ", tapAddress);

    // Created Kill Poll
    // await pollFactory.createKillPoll();
    const killAddress = await pollFactory.killPollAddress();
    console.log("Kill Poll Address: ", killAddress);

    await increaseTime(10000, web3);

    // Vote in Tap Poll
    const tapPollInstance = await IPoll.at(tapAddress);
    await tapPollInstance.vote(0, { from: accounts[2] });
    await tapPollInstance.vote(0, { from: accounts[4] });
    await tapPollInstance.vote(0, { from: accounts[6] });

    const tapPollNum = await tapPollInstance.getVoteTally(0);
    const tapPollDenom = await daicoToken.totalSupply();
    const tapPollConsensus = parseFloat(tapPollNum) / parseFloat(tapPollDenom);
    console.log("Tap Poll Consensus: ", tapPollConsensus);

    // Vote in Kill Poll
    const killPollInstance = await IPoll.at(killAddress);
    await killPollInstance.vote(0, { from: accounts[3] });
    await killPollInstance.vote(0, { from: accounts[6] });
    await killPollInstance.vote(0, { from: accounts[8] });

    const killPollNum = await killPollInstance.getVoteTally(0);
    const killPollDenom = await killPollInstance.getVoterBaseDenominator();
    const killPollConsensus = parseFloat(killPollNum) / parseFloat(killPollDenom);
    console.log("Kill Poll Consensus: ", killPollConsensus);

    stdlog("- END -");
    callback();
  } catch (error) {
    callback(error);
  }
};
