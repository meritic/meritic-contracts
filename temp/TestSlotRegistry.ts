import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";





describe("Slot Registry", function () {

  async function deployTokenFixture() {
	  
	const SlotRegistry = await ethers.getContractFactory("SlotRegistry");
    

	const slotRegContract = await SlotRegistry.deploy();
	await slotRegContract.deployed();
	

    return { slotRegContract };
  }
  
  
  describe("Register slot", async function () {
	
	
	it("Register 0 slot", async function () {
		const { slotRegContract} = await loadFixture(deployTokenFixture);
      	await slotRegContract.addSlot(0, '1st Slot', 'http://sloturi', 'First slot description');
      	expect(await slotRegContract.exists(0)).to.equal(true);
    });
    
    it("Register 1 slot", async function () {
		const { slotRegContract} = await loadFixture(deployTokenFixture);
      	await slotRegContract.addSlot(1, '2nd Slot', 'http://sloturi', '2nd slot description');
      	expect(await slotRegContract.exists(1)).to.equal(true);
    });
    
    it("Double register a slot - should revert", async function () {
		const { slotRegContract} = await loadFixture(deployTokenFixture);
		await slotRegContract.addSlot(0, '1st Slot', 'http://sloturi', 'First slot description');
		await slotRegContract.addSlot(1, '2nd Slot', 'http://sloturi', '2nd slot description');
      	await slotRegContract.addSlot(2, '3rd Slot', 'http://sloturi', '3rd slot description');
      	await expect(slotRegContract.addSlot(2, '3rd Slot', 'http://sloturi', '3rd slot description')).to.be.revertedWith('Slot already registered')
    });
    
    
    it("Double register a slot but with string Slot ID - should revert", async function () {
		const { slotRegContract  } = await loadFixture(deployTokenFixture);
		await slotRegContract.addSlot(0, '1st Slot', 'http://sloturi', 'First slot description');
		await slotRegContract.addSlot(1, '2nd Slot', 'http://sloturi', '2nd slot description');
		await slotRegContract.addSlot(2, '3rd Slot', 'http://sloturi', '3rd slot description');
      	await expect(slotRegContract.addSlot("2", '4th Slot', 'http://sloturi', '4th slot description')).to.be.revertedWith('Slot already registered')
    });
    
    it("Read slot description", async function () {
		 const {  slotRegContract } = await loadFixture(deployTokenFixture);
		 await slotRegContract.addSlot(0, '1st Slot', 'http://sloturi', 'First slot description');
		 expect(await slotRegContract.slotDescription(0)).to.equal('First slot description');
	});
    
    it("Read slot name", async function () {
		 const { slotRegContract } = await loadFixture(deployTokenFixture);
		 await slotRegContract.addSlot(0, '1st Slot', 'http://sloturi', 'First slot description');
		 expect(await slotRegContract.slotName(0)).to.equal('1st Slot');
	});
    
    it("Read slot uri", async function () {
		 const { slotRegContract } = await loadFixture(deployTokenFixture);
		 await slotRegContract.addSlot(0, '1st Slot', 'http://sloturi', 'First slot description');
		 expect(await slotRegContract.slotURI(0)).to.equal('http://sloturi');
	});
	
	it("Read name of unregistered slot - should revert", async function () {
		 const { slotRegContract } = await loadFixture(deployTokenFixture);
		 await expect(slotRegContract.slotName(4)).to.be.revertedWith('Slot is not registered')
	});
    
  });
});