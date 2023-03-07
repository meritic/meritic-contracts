import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
//import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";






describe("Token contract", function () {
  // We define a fixture to reuse the same setup in every test. We use
  // loadFixture to run this setup once, snapshot that state, and reset Hardhat
  // Network to that snapshot in every test.
  async function deployTokenFixture() {
    // Get the ContractFactory and Signers here.
    const mWETH = await ethers.getContractFactory("mWETH");
    const Swap = await ethers.getContractFactory("Swap");
    
    const [owner, addr1, addr2] = await ethers.getSigners();


    const mweth = await mWETH.deploy();
    const mswap = await Swap.deploy(mweth.address);
    
    
    
    await mweth.deployed();
	await mswap.deployed();

    return { mswap, mweth, owner, addr1, addr2 };
  }

  describe("Deployment", function () {

    it("Should set the right owner", async function () {

      const { mswap, mweth, owner } = await loadFixture(deployTokenFixture);
      const bal = await owner.getBalance();
      console.log(bal);
      await mswap.connect(owner).wrapEther({ value: ethers.utils.parseEther("10") });
      const val = await owner.getBalance();
      console.log(val);
      const cal = await mweth.balanceOf(owner.address);

      //expect(await mweth.owner()).to.equal(owner.address);
    });
    
    
    it("Should unwrap WETH", async function () {

      const { mswap, mweth, owner } = await loadFixture(deployTokenFixture);
      const bal = await owner.getBalance();
 
      await mswap.connect(owner).wrapEther({ value: ethers.utils.parseEther("10") });
      mweth.connect(owner).approve(mswap.address, ethers.utils.parseEther("10"));
      //const cal = await mweth.balanceOf(owner.address);
      //console.log(cal);
      
      await mswap.connect(owner).unwrapEther(ethers.utils.parseEther("10"));
      const val = await owner.getBalance();

      //onst cal = await mweth.balanceOf(owner.address);
      //console.log(cal);
      //expect(await mweth.owner()).to.equal(owner.address);
    });
    
    
  });
  
});
  


  
  
  
  
  
