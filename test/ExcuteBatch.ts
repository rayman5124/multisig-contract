import { ethers } from "hardhat";
import { MultiSigWallet, TestToken } from "../typechain-types";
import { expect } from "chai";

describe("Excute Batch", () => {
  let txIndex: string;
  let multiSigWallet: MultiSigWallet;
  let testToken: TestToken;
  let owners: any[];
  const users = new Array(200).fill(0).map(() => ethers.Wallet.createRandom());

  before(async () => {
    const CONFIRM_NUM_REQUIRED = 2;

    owners = (await ethers.getSigners()).slice(0, 3);

    multiSigWallet = (await ethers.deployContract("MultiSigWallet", [
      owners.map((owner: any) => owner.address),
      CONFIRM_NUM_REQUIRED,
    ])) as MultiSigWallet;
    await multiSigWallet.deployed();

    testToken = (await ethers.deployContract("TestToken")) as TestToken;
    await testToken.deployed();

    return { owners, users, multiSigWallet, testToken };
  });

  it("Submit excute batch transaction", async () => {
    // parameters for excuteBatch
    const dataList = users.map((each) => {
      return testToken.interface.encodeFunctionData("transfer", [
        each.address,
        ethers.utils.parseEther("10"),
      ]);
    });
    const valueList = new Array(dataList.length).fill(0);
    const toList = valueList.map(() => testToken.address);

    const data = multiSigWallet.interface.encodeFunctionData("excuteBatch", [
      toList,
      valueList,
      dataList,
    ]);
    const tx = await multiSigWallet
      .connect(owners[0])
      .submitTransaction(multiSigWallet.address, "0", data, false);
    const receipt = await tx.wait();
    receipt.events?.forEach((event) => {
      expect(event.args?.data).to.equal(data);
      txIndex = (event.args?.txIndex).toString();
    });
  });

  it("Confirm tx", async () => {
    for (const owner of owners) {
      const tx = await multiSigWallet.connect(owner).confirmTransaction(txIndex, false);
      tx.wait();
    }

    for (const owner of owners) {
      expect(await multiSigWallet.isConfirmed(txIndex, owner.address)).to.be.true;
    }
  });

  it("Transfer TestTokens to MultisigWallet", async () => {
    const amount = ethers.utils.parseEther("10").mul(users.length);
    const tx = await testToken.connect(owners[0]).transfer(multiSigWallet.address, amount);
    await tx.wait();

    expect(await testToken.balanceOf(multiSigWallet.address)).to.equal(amount);
  });

  it("Excute Transaction", async () => {
    const beforeBalance = new Map();
    let promises = users.map(async (each) => {
      beforeBalance.set(
        each.address,
        ethers.utils.formatEther(await testToken.balanceOf(each.address))
      );
    });
    await Promise.all(promises);
    console.log("before balance");
    console.log(beforeBalance);
    console.log("");

    const tx = await multiSigWallet.connect(owners[0]).executeTransaction(txIndex);
    const receipt = await tx.wait();

    const afterBalance = new Map();
    promises = users.map(async (each) => {
      afterBalance.set(
        each.address,
        ethers.utils.formatEther(await testToken.balanceOf(each.address))
      );
    });
    await Promise.all(promises);
    console.log("after balance");
    console.log(afterBalance);

    console.log("@@@@@", receipt.gasUsed);
  });
});
