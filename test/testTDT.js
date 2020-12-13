const { expect } = require("chai");
const { ethers } = require("hardhat");

const {
    deployAllContracts,
    loadFixture,
} = require("./helpers/fixtures.js");

describe("TDT Token", function () {
    let weth, TDT;
    let deployer;
    let users, user1, user2;
    let factory, router;


    before(async function () {
        ({
            accounts: users,
            owner: deployer,
            weth: weth,
            TDT: TDT,
            factory: factory,
            router: router,
        } = await deployAllContracts());
        user1 = users[0];
        user2 = users[1];
    });

    it("Should burn TDT token at the period 1", async function () {
        const mintAmount = "10000";
        const transferAmount = ethers.utils.parseEther("1000");

        console.log("before transfer, scalingFactor is:", (await TDT.scalingFactor()).toString());
        console.log("before transfer, user2 balance is:", (await TDT.balanceOf(user2.address)).toString(), "\n");
        console.log("deployer will transfer token to user2: ", transferAmount);
        console.log("amount is:", (await TDT.balanceOf(deployer.address)).toString() / 10 ** 18);
        let beforeTransferSupply = await TDT.totalSupply();

        await TDT.connect(deployer).transfer(user2.address, transferAmount);

        console.log("after transfer, scalingFactor is:", (await TDT.scalingFactor()).toString());
        let afterTransferDeployerBalance = await TDT.balanceOf(deployer.address);
        console.log("after transfer, deployer balance is:", (afterTransferDeployerBalance).toString(), "\n");
        let afterTransferUser2Balance = await TDT.balanceOf(user2.address);
        // let afterTransferUser2Balance = await TDT.balanceOfUnderlying(user2.address);
        console.log("after transfer, user2 balance is:", (afterTransferUser2Balance).toString(), "\n");
        console.log("after transfer, user2 underlying balance is:", (await TDT.balanceOfUnderlying(user2.address)).toString(), "\n");
        console.log("deployer + user2", (afterTransferDeployerBalance.add(afterTransferUser2Balance)).toString());

        // Cause transfer amount is 1000, so burn rate is 3%
        // TODO: use bignumber
        const burnAmount = transferAmount.mul(3).div(100);
        const afterTransferSupply = await TDT.totalSupply();
        console.log("after transfer, total supply is: ", afterTransferSupply.toString());
        expect(beforeTransferSupply, afterTransferSupply.add(burnAmount));
    });

});
