const { ethers, upgrades } = require("hardhat");

async function main() {

  const [deployer] = await ethers.getSigners();

  console.log(
      "Deploying contracts with the account:",
      deployer.address
  );

  console.log("Account balance:", (await deployer.getBalance()).toString());

  // const EthCallTest = await ethers.getContractFactory("EthCallTest");
  // const ethCall = await EthCallTest.deploy();
  // console.log("ethCall address:", ethCall.address);

  // v0.7.0， optimizer:true , 200
  // const Token = await ethers.getContractFactory("Staking");
  // const token = await Token.deploy();
  // console.log("Token address:", token.address);

  // // v0.8.0，optimizer:false , 200
  const token20 = await ethers.getContractFactory("token20");
  const token20ContractAddress = await token20.deploy();
  console.log("token20 address:", token20ContractAddress.address);

  // const Logic = await ethers.getContractFactory("Logic");
  // const LogicContractAddress = await Logic.deploy();
  // console.log("Logic address:", LogicContractAddress.address);

  // opbnb-testnet
  // Deploying contracts with the account: 0x6836CbaCbBd1E798cC56802AC7d8BDf6Da0d0980
  // Account balance: 1240328687031628852
  // Logic address: 0x095026bf2C2fB14501E814B53Da9c4646335d1E4
  // proxy address: 0xd0B8D7bAB692040DA5879F4Df86c7bD97A58448c

  // bsc-testnet
//   Deploying contracts with the account: 0x6836CbaCbBd1E798cC56802AC7d8BDf6Da0d0980
// Account balance: 13714054872115846426
// Logic address: 0x9503A1ac565730E916ee80268f7AF0f0B975D5De
// proxy address: 0x162673B5fe2747f0464e18417b4F94Ba2B7Fe085

    // const Logic = await ethers.getContractFactory("Logic");
    // const logic = await Logic.deploy({gasPrice: 5000000000});
    // console.log("Token address:", logic.address);

    // const Proxy = await ethers.getContractFactory("Proxy");
    // const proxy = await Proxy.deploy(LogicContractAddress.address,{gasPrice: 5000000000});
    // console.log("proxy address:", proxy.address);

// 0xa0d707C3fC25C4E0Fe47dBfeE888a558E7354Fef
// 0x981c1aEb81541ac301AfA83E4b4D423FE7C9c158
  // const Proxy = await ethers.getContractFactory("Proxy");
  // const ProxyContractAddress = await Proxy.deploy();
  // console.log("Proxy address:", ProxyContractAddress.address);

  // //
  // // // v0.8.1，optimizer:true , 100
  // const token20Run = await ethers.getContractFactory("token20Run");
  // const token20RunContractAddress = await token20Run.deploy();
  // console.log("token20Run address:", token20RunContractAddress.address);
  //
  // // v0.6.12 , true ,200 , args
  // const ChainAnexToken = await ethers.getContractFactory("ChainAnexToken");
  // const ChainAnexTokenContractAddress = await ChainAnexToken.deploy(deployer.address ,"verifyArgs","VA",50000000 );
  // console.log("ChainAnexToken address:", ChainAnexTokenContractAddress.address);

  // // RecruitCoinTest openzeppelin link v0.8.9
  // const RecruitCoinTest = await ethers.getContractFactory("RecruitCoinTest");
  // const RecruitCoinTestAddress = await RecruitCoinTest.deploy();
  // console.log("RecruitCoinTestAddresslink code  address:", RecruitCoinTestAddress.address);

  // v0.6.12 , true ,200 , lib multi
  // const Utils = await ethers.getContractFactory("Utils");
  // const UtilsAddress = await Utils.deploy();
  // console.log("Utils address:", UtilsAddress.address);

  // const contractFactory = await ethers.getContractFactory("HODL1", {
  //     libraries: {
  //         Utils: UtilsAddress.address,
  //     },
  // });
  // const HODL1ContractAddress = await contractFactory.deploy();
  // console.log("HODL1 address:", HODL1ContractAddress.address);




  // SafeMath singlefile lib multi lib fail
  // const SafeMath = await ethers.getContractFactory("contracts/FTTSDAODividendTracker.sol:SafeMath");
  // const SafeMathAddress = await SafeMath.deploy();
  // console.log("SafeMathAddress:", SafeMathAddress.address);
  // const IterableMapping = await ethers.getContractFactory("contracts/FTTSDAODividendTracker.sol:IterableMapping");
  // const IterableMappingAddress = await IterableMapping.deploy();
  // console.log("IterableMappingAddress:", IterableMappingAddress.address);
  // const SafeMathInt = await ethers.getContractFactory("contracts/FTTSDAODividendTracker.sol:SafeMathInt");
  // const SafeMathIntAddress = await SafeMathInt.deploy();
  // console.log("SafeMathIntAddress:", SafeMathIntAddress.address);
  //
  // const contractFactory = await ethers.getContractFactory("FTTSDAODividendTracker", {
  //     libraries: {
  //         SafeMath:SafeMathAddress.address,
  //     },
  //     libraries: {
  //         IterableMapping:IterableMappingAddress.address,
  //     },
  //     libraries: {
  //         SafeMathInt:SafeMathIntAddress.address,
  //     },
  // });
  // const FTTSDAODividendTrackerAddress = await contractFactory.deploy();
  // console.log("FTTSDAODividendTracker address:", FTTSDAODividendTrackerAddress.address);

  // ETR SafeMath singlefile lib
  // const Checker = await ethers.getContractFactory("Checker");
  // const CheckerAddress = await Checker.deploy();
  // const contractFactory = await ethers.getContractFactory("RichHusky", {
  //         libraries: {
  //             Checker: CheckerAddress.address,
  //         },
  //     });
  //     const ERTContractAddress = await contractFactory.deploy(deployer.address);
  //     console.log("RichHusky address:", ERTContractAddress.address);

  // Json
  // const Presale = await ethers.getContractFactory("Presale");
  // const PresaleAddress = await Presale.deploy("0x3b7ddd013cfdf143c06a7fae0d91906eb56dcf8d","0x55d398326f99059ff775485246999027b3197955","0x727ac17b55f5c4f8a68781322f6c7f8a47bf18ff",1661961599);
  // console.log("PresaleAddress address:", PresaleAddress.address);



}

main()
  .then(() => process.exit(0))
  .catch(error => {
      console.error(error);
      process.exit(1);
  });