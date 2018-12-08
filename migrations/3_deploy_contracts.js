const Network = artifacts.require("./KyberNetwork.sol");
const NetworkProxy = artifacts.require("./KyberNetworkProxy.sol");
const ConversionRates = artifacts.require("./ConversionRates.sol");
const LiquidityConversionRates = artifacts.require("./LiquidityConversionRates.sol");
// const SanityRates = artifacts.require("./SanityRates.sol");
const CrowdSale = artifacts.require("./CrowdSale.sol");
const PollFactory = artifacts.require("./PollFactory.sol");
const PollDeployer = artifacts.require("./PollDeployer.sol");
// const AutomatedReserve = artifacts.require("./KyberAutomatedReserve.sol");
const FeeBurner = artifacts.require("./FeeBurner.sol");
const WhiteList = artifacts.require("./WhiteList.sol");
const ExpectedRate = artifacts.require("./ExpectedRate.sol");
const KNC = artifacts.require("./KyberNetworkCrystal.sol");
const KGT = artifacts.require("./KyberGenesisToken.sol");
const DAI = artifacts.require("./Dai.sol");
const DaicoToken = artifacts.require("./DaicoToken.sol");

module.exports = async (deployer, network, accounts) => {
  console.log(DAI.address);
  const admin = accounts[0];

  // DAICO
  await deployer.deploy(PollDeployer);

  // Deploy the contracts
  await deployer.deploy(Network, admin);
  await deployer.deploy(NetworkProxy, admin);
  await deployer.deploy(ConversionRates, admin);
  await deployer.deploy(LiquidityConversionRates, admin, DAI.address);
  // await deployer.deploy(SanityRates, admin);

  await deployer.deploy(
    PollFactory,
    DaicoToken.address,
    accounts[2],
    "30864197530864",
    "50",
    "80",
    "50",
    "150",
    PollDeployer.address,
    Network.address,
    ConversionRates.address,
    DAI.address
  );
  const timeStamp = (await web3.eth.getBlock(await web3.eth.getBlockNumber())).timestamp;

  await deployer.deploy(
    CrowdSale,
    "1000000000000000000",
    "10000000000000000000",
    timeStamp + 12960,
    timeStamp,
    "63800000000000000000000",
    "6380",
    PollFactory.address,
    DaicoToken.address
  );

  // await deployer.deploy(AutomatedReserve, Network.address, LiquidityConversionRates.address, admin);
  await deployer.deploy(FeeBurner, admin, KNC.address, Network.address);
  await deployer.deploy(WhiteList, admin, KGT.address);
  await deployer.deploy(ExpectedRate, Network.address, admin);

  // // Deploy the examples
  // await deployer.deploy(SwapEtherToToken, NetworkProxy.address);
  // await deployer.deploy(SwapTokenToEther, NetworkProxy.address);
  // await deployer.deploy(SwapTokenToToken, NetworkProxy.address);
  // await deployer.deploy(Trade, NetworkProxy.address);
};
