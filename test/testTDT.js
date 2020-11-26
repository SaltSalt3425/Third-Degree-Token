const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TDT Token", function () {
    let TDT;
    let deployer;
    let users, user1, user2;

    before(async function () {
        [deployer, ...users] = await ethers.getSigners();
        user1 = users[0];
        user2 = users[1];

        const TDTToken = await ethers.getContractFactory("TDTToken");
        TDT = await upgrades.deployProxy(TDTToken, ["Thrid Degree Token", "TDT"], {
            initializer: "initialize",
        });
    });

    it("Should burn TDT token at the period 1", async function () {
        const mintAmount = "10000";
        const transferAmount = "1000";

        console.log("before mint, user1 balance is: ", (await TDT.balanceOf(user1.address)).toString(), "\n");
        console.log("mint for user1: ", mintAmount);
        await TDT.connect(deployer).mint(user1.address, ethers.utils.parseEther(mintAmount));
        console.log("after mint, user1 balance is : ", (await TDT.balanceOf(user1.address)).toString(), "\n");

        // Cause there is only one user, so minting amount is equal to current total supply
        const beforeTransferSupply = (await TDT.totalSupply()).toString();
        expect(beforeTransferSupply, ethers.utils.parseEther(mintAmount));

        console.log("before transfer, user2 balance is:", (await TDT.balanceOf(user2.address)).toString(), "\n");
        console.log("user1 will transfer token to user2: ", transferAmount);
        await TDT.connect(user1).transfer(user2.address, ethers.utils.parseEther(transferAmount));
        console.log("after transfer, user1 balance is:", (await TDT.balanceOf(user1.address)).toString(), "\n");
        console.log("after transfer, user2 balance is:", (await TDT.balanceOf(user2.address)).toString(), "\n");

        // Cause transfer amount is 1000, so burn rate is 3%
        // TODO: use bignumber
        const burnAmount = transferAmount * "3" / "100";
        const afterTransferSupply = (await TDT.totalSupply()).toString();
        console.log("after transfer, total supply is: ", afterTransferSupply);
        expect(beforeTransferSupply, afterTransferSupply + burnAmount);
    });
});
