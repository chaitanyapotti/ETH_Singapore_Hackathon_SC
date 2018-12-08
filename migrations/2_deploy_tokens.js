/* global artifacts */
const Dai = artifacts.require("./Dai.sol");
const DaicoToken = artifacts.require("./DaicoToken.sol");
const KNC = artifacts.require("./KyberNetworkCrystal.sol");
const KGT = artifacts.require("./KyberGenesisToken.sol");

module.exports = async deployer => {
  // Deploy the tokens
  await deployer.deploy(Dai, "DAI", "DAI", 18);
  await deployer.deploy(DaicoToken, "DAICO", "DAICO", "1000000000000000000000000000", "50");
  await deployer.deploy(KNC, "KNC", "Kyber Network Crystal", 18);
  await deployer.deploy(KGT, "KGT", "Kyber Genesis Token", 0);
};
