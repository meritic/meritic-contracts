import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { v4 as uuidv4 } from 'uuid';
//import  Service   from '../artifacts/contracts/Service.sol/Service.json';
import ServiceArtifact from "../artifacts/contracts/Service.sol/Service.json";



describe("Service", function () {

  async function deployTokenFixture() {
	  
	const serviceFactory = await ethers.getContractFactory('Service');
	const SlotRegistry = await ethers.getContractFactory("SlotRegistry");
    
    const [serviceAcct, user1, user2] = await ethers.getSigners();


	const slotRegContract = await SlotRegistry.deploy();
	await slotRegContract.deployed();
	
        		
    const serviceContract = await serviceFactory.deploy(
								serviceAcct.address,
								slotRegContract.address,
								'XYZ Service',
								'XYZ',
								'http://baseuri',
								'XYZ is a Web3 sevice',
								'image_1.png',
								18);
								
    await serviceContract.deployed();
    
  

    
    return { serviceContract, serviceAcct, slotRegContract, user1, user2 };
  }
  
  
  describe("Mint Token", async function () {


	it("Check MintServiceToken event fired on mint", async function () {
		const { serviceContract, serviceAcct, slotRegContract, user1, user2 } = await loadFixture(deployTokenFixture);
		await slotRegContract.addSlot(1, '1st Slot', 'http://sloturi', 'First slot description');
		const mintTx = await serviceContract.mint(serviceAcct.address, 1, 10, uuidv4(),  'first minted token', 'token_image.png')
      	await expect(mintTx).to.emit(serviceContract, "MintServiceToken").withArgs(1, 1, 10);
    });
    
    
    it("Check ServiceMetadataDescriptor set token uuid on mint", async function () {
		const { serviceContract, serviceAcct, slotRegContract, user1, user2 } = await loadFixture(deployTokenFixture);
		await slotRegContract.addSlot(1, '1st Slot', 'http://sloturi', 'First slot description');
		const token_uuid = uuidv4();
		const mintTx = await serviceContract.mint(serviceAcct.address, 1, 10, token_uuid,  'first minted token', 'token_image.png');
	
		expect(await serviceContract.getTokenUUID(1)).to.equal(token_uuid);
    });
    
    it("Check ServiceMetadataDescriptor set token description on mint", async function () {
		const { serviceContract, serviceAcct, slotRegContract, user1, user2 } = await loadFixture(deployTokenFixture);
		await slotRegContract.addSlot(1, '1st Slot', 'http://sloturi', 'First slot description');
		const token_uuid = uuidv4();
		const mintTx = await serviceContract.mint(serviceAcct.address, 1, 10, token_uuid,  'first minted token', 'token_image.png');
	
		expect(await serviceContract.getTokenDescription(1)).to.equal('first minted token');
    });
    
    it("Check ServiceMetadataDescriptor set token image on mint", async function () {
		const { serviceContract, serviceAcct, slotRegContract, user1, user2 } = await loadFixture(deployTokenFixture);
		await slotRegContract.addSlot(1, '1st Slot', 'http://sloturi', 'First slot description');
		const token_uuid = uuidv4();
		const mintTx = await serviceContract.mint(serviceAcct.address, 1, 10, token_uuid,  'first minted token', 'token_image.png');
	
		expect(await serviceContract.getTokenImage(1)).to.equal('token_image.png');
    });
    
  });
  
  
  describe("Token-to-address Value Transfer ", async function () {

    
	 it("Check Token-to-address value transfer - emits  MintServiceTokenToAddress", async function () {
		const { serviceContract, serviceAcct, slotRegContract, user1, user2 } = await loadFixture(deployTokenFixture);
		await slotRegContract.addSlot(1, '1st Slot', 'http://sloturi', 'First slot description');
		const mintTx = await serviceContract.mint(serviceAcct.address, 1, 10, uuidv4(),  'first minted token', 'token_image.png')
    	const tokenId = 1;
		await serviceContract.connect(serviceAcct)["approve(uint256,address,uint256)"](tokenId, user1.address, 5);   
		const transTx = await serviceContract.connect(serviceAcct)["transferFrom(uint256,address,uint256)"](tokenId, user1.address, 5);
		
		await expect(transTx).to.emit(serviceContract, "MintServiceTokenToAddress").withArgs(2, 1, 5);
    });
    
    
    it("Check owner Token-to-address value transfer", async function () {
		const { serviceContract, serviceAcct, slotRegContract, user1, user2 } = await loadFixture(deployTokenFixture);
		await slotRegContract.addSlot(1, '1st Slot', 'http://sloturi', 'First slot description');
		const mintTx = await serviceContract.mint(serviceAcct.address, 1, 10, uuidv4(),  'first minted token', 'token_image.png')
    	const tokenId = 1;
		await serviceContract.connect(serviceAcct)["approve(uint256,address,uint256)"](tokenId, user1.address, 5);   
		await serviceContract.connect(serviceAcct)["transferFrom(uint256,address,uint256)"](tokenId, user1.address, 5);
		const newTokenId = 2;
		expect(await serviceContract.ownerOf(newTokenId)).to.equal(user1.address);
    });
 });
   
   
 describe("Token-to-token Value Transfer", async function () {

	 it("Check transfer - emits ValueTransfer", async function () {
		const { serviceContract, serviceAcct, slotRegContract, user1, user2 } = await loadFixture(deployTokenFixture);
		await slotRegContract.addSlot(1, '1st Slot', 'http://sloturi', 'First slot description');
		const mintTx = await serviceContract.mint(serviceAcct.address, 1, 20, uuidv4(),  'first minted token', 'token_image.png')
    	const tokenId_0 = 1;
		await serviceContract.connect(serviceAcct)["approve(uint256,address,uint256)"](tokenId_0, user1.address, 5);   
		await serviceContract.connect(serviceAcct)["approve(uint256,address,uint256)"](tokenId_0, user2.address, 5);   
		
		await serviceContract.connect(serviceAcct)["transferFrom(uint256,address,uint256)"](tokenId_0, user1.address, 5);
		await serviceContract.connect(serviceAcct)["transferFrom(uint256,address,uint256)"](tokenId_0, user2.address, 7);
		const tokenId_1 = 2;
		const tokenId_2 = 3;
		await serviceContract.connect(user2)["approve(uint256,address,uint256)"](tokenId_2, user1.address, 2);   
		const transTx = await serviceContract.connect(user2)["transferFrom(uint256,uint256,uint256)"](tokenId_2, tokenId_1, 2);
		await expect(transTx).to.emit(serviceContract, "ValueTransfer").withArgs(tokenId_2, tokenId_1, 2);
    });
    
    
    it("Check balance after transfer", async function () {
		const { serviceContract, serviceAcct, slotRegContract, user1, user2 } = await loadFixture(deployTokenFixture);
		await slotRegContract.addSlot(1, '1st Slot', 'http://sloturi', 'First slot description');
		const mintTx = await serviceContract.mint(serviceAcct.address, 1, 20, uuidv4(),  'first minted token', 'token_image.png')
    	const tokenId_0 = 1;
		await serviceContract.connect(serviceAcct)["approve(uint256,address,uint256)"](tokenId_0, user1.address, 5);   
		await serviceContract.connect(serviceAcct)["approve(uint256,address,uint256)"](tokenId_0, user2.address, 5);   
		
		await serviceContract.connect(serviceAcct)["transferFrom(uint256,address,uint256)"](tokenId_0, user1.address, 5);
		await serviceContract.connect(serviceAcct)["transferFrom(uint256,address,uint256)"](tokenId_0, user2.address, 7);
		const tokenId_1 = 2;
		const tokenId_2 = 3;
		await serviceContract.connect(user2)["approve(uint256,address,uint256)"](tokenId_2, user1.address, 2);   
		await serviceContract.connect(user2)["transferFrom(uint256,uint256,uint256)"](tokenId_2, tokenId_1, 2);
		expect(await serviceContract['balanceOf(uint256)'](tokenId_1)).to.equal(7);
    });
    
    
    it("Check transfer to different slot - reverts with ERC3525 different slot", async function () {
		const { serviceContract, serviceAcct, slotRegContract } = await loadFixture(deployTokenFixture);
		const slot_1 = 1;
		const slot_2 = 2;
		await slotRegContract.addSlot(slot_1, '1st Slot', 'http://sloturi', 'First slot description');
		await slotRegContract.addSlot(slot_2, '2nd Slot', 'http://sloturi', 'Second slot description');
	
		await serviceContract.mint(serviceAcct.address, slot_1, 20, uuidv4(),  'minted token', 'token_image.png')
		await serviceContract.mint(serviceAcct.address, slot_2, 20, uuidv4(),  'another minted token', 'token_image.png')
		
    	const tokenId_1 = 1;
    	const tokenId_2 = 2;
 
		await expect(serviceContract["transferFrom(uint256,uint256,uint256)"](tokenId_2, tokenId_1, 2)).to.be.revertedWith('ERC3525: transfer to token with different slot')
    });
 });
 
 
 describe("Address-to-Address Token transfer", async function () {
	 it("Check transfer to different slot - reverts with ERC3525 different slot", async function () {
		 const { serviceContract, serviceAcct, slotRegContract, user1, user2 } = await loadFixture(deployTokenFixture);
		 await slotRegContract.addSlot(1, '1st Slot', 'http://sloturi', 'First slot description');
		 const mintTx = await serviceContract.mint(serviceAcct.address, 1, 20, uuidv4(),  'first minted token', 'token_image.png');
		 const tokenId_0 = 1;
		 await serviceContract.connect(serviceAcct)["approve(uint256,address,uint256)"](tokenId_0, user1.address, 5);  
		 await serviceContract.connect(serviceAcct)["approve(uint256,address,uint256)"](tokenId_0, user2.address, 5);   
		 
		 await serviceContract.connect(serviceAcct)["transferFrom(uint256,address,uint256)"](tokenId_0, user1.address, 5);
		 await serviceContract.connect(serviceAcct)["transferFrom(uint256,address,uint256)"](tokenId_0, user2.address, 7);
		 const tokenId_1 = 2;
		 const tokenId_2 = 3;
		 await serviceContract.connect(user1)["approve(uint256,address,uint256)"](tokenId_1, user2.address, 5);  
		 await serviceContract.connect(user1)["transferFrom(address,address,uint256)"](user1.address, user2.address, tokenId_1);
		 expect(await serviceContract['balanceOf(address)'](user2.address)).to.equal(2);
	});
 })

});