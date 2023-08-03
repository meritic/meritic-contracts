import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";



/*
describe("WUSDC", function () {

  async function deployTokenFixture() {
	  
	const HardhatUSDC = await ethers.getContractFactory("HardhatUSDC");
    const WUSDC = await ethers.getContractFactory("WUSDC");
    
    const [meriticAcct, user1] = await ethers.getSigners();
    
    const USDCToken = await HardhatUSDC.deploy();
    await USDCToken.deployed();
    
    
    const WUSDCToken = await WUSDC.deploy(USDCToken.address);
    await WUSDCToken.deployed();
    
    return { WUSDCToken, USDCToken, meriticAcct, user1 };
  }
  
  
  describe("Mint WUSDC", function () {

    it("Mint USDC", async function () {

      const { USDCToken, meriticAcct } = await loadFixture(deployTokenFixture);
      await USDCToken.mint(meriticAcct.address, 10);
      expect(await USDCToken.balanceOf(meriticAcct.address)).to.equal(10);
    });
    
    it("Mint WUSDC", async function () {

      const { WUSDCToken, USDCToken, meriticAcct, user1 } = await loadFixture(deployTokenFixture);
      await USDCToken.mint(meriticAcct.address, 10);

    
      await USDCToken.connect(meriticAcct).approve(WUSDCToken.address, 5);
      await WUSDCToken.connect(meriticAcct).mint(5, user1.address);
      expect(await WUSDCToken.balanceOf(user1.address)).to.equal(5);

    });
    
    it("Transfer WUSDC", async function () {
	  
      const { WUSDCToken, USDCToken, meriticAcct, user1 } = await loadFixture(deployTokenFixture);
      await USDCToken.mint(meriticAcct.address, 10);

    
      await USDCToken.connect(meriticAcct).approve(WUSDCToken.address, 5);
      await WUSDCToken.connect(meriticAcct).mint(5, user1.address);
      
      
      expect(await WUSDCToken.balanceOf(user1.address)).to.equal(5);

    });
    
    
  });
});
*/