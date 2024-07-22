// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
require("@nomicfoundation/hardhat-toolbox")
async function main() {

  const FoodToken = await hre.ethers.deployContract("FoodToken");
  const FoodSupplyChain = await hre.ethers.deployContract("FoodSupplyChain",[FoodToken.target]);
  const manufacturer = await hre.ethers.deployContract("Manufacturer",[FoodSupplyChain.target]);
  const distributor = await hre.ethers.deployContract("Distributor",[FoodSupplyChain.target]);
  const Food= await hre.ethers.deployContract("Food",[FoodSupplyChain.target]);
  const consumer = await hre.ethers.deployContract("Consumer",[FoodSupplyChain.target]);

  await FoodToken.waitForDeployment();
//Contract Address
  console.log(`FoodToken deployed to ${FoodToken.target}`);
  console.log(`FoodSupplyChain deployed to ${FoodSupplyChain.target}`);
  console.log(`Manufacturer deployed to ${manufacturer.target}`);
  console.log(`Distributor deployed to ${distributor.target}`);
  console.log(`Foodto deployed ${Food.target}`);
  console.log(`Consumer to deployed ${consumer.target}`);


  const WAIT_BLOCK_CONFIRMATION = 4;
  await FoodToken.deployTransaction.wait(WAIT_BLOCK_CONFIRMATION);
  await run("verify:verify", {
    address:FoodToken.target,
  });
  await run("verify:verify", {
    address:FoodSupplyChain.target,
    constructorArguments: [FoodToken.target],
  });
  await run("verify:verify", {
    address:manufacturer.target,
    constructorArguments: [FoodSupplyChain.target],
  });
  await run("verify:verify", {
    address:distributor.target,
    constructorArguments: [FoodSupplyChain.target],
  });
  await run("verify:verify", {
    address:Food.target,
    constructorArguments: [FoodSupplyChain.target],
  });
  await run("verify:verify", {
    address:consumer.target,
    constructorArguments: [FoodSupplyChain.target],
  });
  console.log("Contract Verified:");


}



// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
