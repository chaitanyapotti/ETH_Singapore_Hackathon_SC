/* global artifacts, web3 */
/* eslint-disable no-underscore-dangle, no-unused-vars */
const BN = require("bn.js");
const moment = require("moment");
const increaseTime = require("./increaseTime");

const CrowdSale = artifacts.require("./CrowdSale.sol");
const DaicoToken = artifacts.require("./DaicoToken.sol");

function stdlog(input) {
  console.log(`${moment().format("YYYY-MM-DD HH:mm:ss.SSS")}] ${input}`);
}

module.exports = async callback => {
  try {
    stdlog("- START -");
    const accounts = await web3.eth.getAccounts();
    const crowdSale = await CrowdSale.at(CrowdSale.address);
    const daicoToken = await DaicoToken.at(DaicoToken.address);

    await increaseTime(10, web3);

    await crowdSale.startNewRound();

    await crowdSale.sendTransaction({
      value: await web3.utils.toWei("1", "ether").toString(),
      from: accounts[2]
    });
    const balance2 = await daicoToken.balanceOf(accounts[2]);
    console.log("Account 2 token balance: ", web3.utils.fromWei(balance2));
    await crowdSale.sendTransaction({
      value: await web3.utils.toWei("2", "ether").toString(),
      from: accounts[3]
    });

    const balance3 = await daicoToken.balanceOf(accounts[3]);
    console.log("Account 3 token balance: ", web3.utils.fromWei(balance3));
    await crowdSale.sendTransaction({
      value: await web3.utils.toWei("2", "ether").toString(),
      from: accounts[4]
    });

    const balance4 = await daicoToken.balanceOf(accounts[4]);
    console.log("Account 4 token balance: ", web3.utils.fromWei(balance4));
    await crowdSale.sendTransaction({
      value: await web3.utils.toWei("1", "ether").toString(),
      from: accounts[6]
    });

    const balance6 = await daicoToken.balanceOf(accounts[6]);
    console.log("Account 6 token balance: ", web3.utils.fromWei(balance6));
    await crowdSale.sendTransaction({
      value: await web3.utils.toWei("4", "ether").toString(),
      from: accounts[8]
    });

    const balance8 = await daicoToken.balanceOf(accounts[8]);
    console.log("Account 8 token balance: ", web3.utils.fromWei(balance8));
    stdlog("- END -");
    callback();
  } catch (error) {
    callback(error);
  }
};
