const {waffle, ethers} = require("hardhat");
const { createFixtureLoader, deployMockContract } = waffle;

let owner, accounts;
let uniswapFactory, router
let weth, TDT
// Use ethers provider instead of waffle's default MockProvider
const loadFixture = createFixtureLoader([], ethers.provider);

async function getAccount() {
  [owner, ...accounts] = await ethers.getSigners();
}

async function distributeUnderlying(weth, TDT) {
  const mintAmount = ethers.utils.parseEther("10000");

  // mints weth.
  await weth.connect(owner).deposit({ value: ethers.utils.parseEther("10") });
  // mints TDT token.
  await TDT.connect(owner).mint(owner.getAddress(), mintAmount);
}

async function deployTokens() {
  await getAccount();
  const WETH9 = await ethers.getContractFactory("WETH9");
  weth = await WETH9.deploy();
  await weth.deployed();

  const TDTToken = await ethers.getContractFactory("TDTToken");
  TDT = await upgrades.deployProxy(TDTToken, ["Thrid Degree Token", "TDT", owner.address, ethers.utils.parseEther("0.05"), ethers.utils.parseEther("0.475"), ethers.utils.parseEther("0.475")], {
      initializer: "initialize",
  });

  await distributeUnderlying(weth, TDT);

}

// deploys uniswap system.
async function deployUniswap() {
  // deploys uniswap factory contract.
  const UniswapV2Factory = await ethers.getContractFactory("UniswapV2Factory");
  uniswapFactory = await UniswapV2Factory.deploy(owner.getAddress());
  await uniswapFactory.deployed();

  // deploys uniswap pair contract.
  const UniswapV2Router02 = await ethers.getContractFactory("UniswapV2Router02");
  router = await UniswapV2Router02.deploy(uniswapFactory.address, weth.address);
  await router.deployed();

  // adds eth-TDT liquidity.
}

// deploys all contracts
async function deployAllContracts() {
  await deployTokens();
  await deployUniswap();

  // add liquidity
  return {
    "owner": owner,
    "accounts": accounts,
    "weth": weth,
    "TDT": TDT,
    "factor": uniswapFactory,
    "router": router,
  }
}


module.exports = {
  deployAllContracts,
  loadFixture,
};
