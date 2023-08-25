import { ethers } from "hardhat";

async function main() {
  const factory = await ethers.getContractFactory("ERC20");
  const contract = await factory.deploy(
    ethers.utils.parseEther((10_000_000).toString()),
    "TestToken",
    18,
    "TTK"
  );
  await contract.deployed();

  console.log(contract.address);
}

main().catch((err) => {
  console.log(err);
  process.exitCode = 1;
});
