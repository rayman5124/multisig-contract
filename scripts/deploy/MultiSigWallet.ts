import { ethers } from "hardhat";

async function main() {
  const owners = (await ethers.getSigners()).slice(0, 3);
  const MultiSigWallet = await ethers.getContractFactory("MultiSigWallet");
  const multiSigWallet = await MultiSigWallet.deploy(
    owners.map((owner) => owner.address),
    "3"
  );
  await multiSigWallet.deployed();
  console.log(multiSigWallet.address);

  console.log(await multiSigWallet.getOwners());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
