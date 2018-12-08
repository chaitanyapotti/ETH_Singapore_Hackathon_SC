/* global artifacts, web3 */
/* eslint-disable no-underscore-dangle, no-unused-vars */
const BN = require("bn.js");
const moment = require("moment");
const increaseTime = require("./increaseTime");

const DaicoToken = artifacts.require("./DaicoToken.sol");

module.exports = async callback => {
  try {
    const accounts = await web3.eth.getAccounts();

    const daicoToken = await DaicoToken.at(DaicoToken.address);
    console.log(await daicoToken.balanceOf(accounts[0]));
    await daicoToken.transfer(accounts[2], 1000, { from: accounts[0] });
    await daicoToken.transfer(accounts[3], 100, { from: accounts[2] });
    console.log(await daicoToken.balanceOf(accounts[2]));
    callback();
  } catch (error) {
    console.log(error);
    callback(error);
  }
};
