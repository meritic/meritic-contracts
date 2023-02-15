import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";





// `describe` is a Mocha function that allows you to organize your tests.
// Having your tests organized makes debugging them easier. All Mocha
// functions are available in the global scope.
//
// `describe` receives the name of a section of your test suite, and a
// callback. The callback must define the tests of that section. This callback
// can't be an async function.
describe("Token contract", function () {
  // We define a fixture to reuse the same setup in every test. We use
  // loadFixture to run this setup once, snapshot that state, and reset Hardhat
  // Network to that snapshot in every test.
  async function deployTokenFixture() {
    // Get the ContractFactory and Signers here.
    const ServiceToken = await ethers.getContractFactory("ERC3525Service");
    const SlotRegistry = await ethers.getContractFactory("ERC3525SlotRegistry");
    
    const [owner, addr1, addr2] = await ethers.getSigners();
    
	const slotRegistryBaseURI = "abc";
	
	
    // To deploy our contract, we just have to call Token.deploy() and await
    // its deployed() method, which happens once its transaction has been
    // mined.
    const registry = await SlotRegistry.deploy(slotRegistryBaseURI);
    await registry.deployed();
    
        		
    const name = "Orange"; 		
    const symbol = "ORG";
    const serviceOwner = owner.address;
    const proxyAddress = owner.address;
    const slotRegistry = registry.address;
    const lockAdmin = owner.address;
    
    const serviceToken = await ServiceToken.deploy(serviceOwner, proxyAddress, slotRegistry, lockAdmin, name, symbol);
    await serviceToken.deployed();

    // Fixtures can return anything you consider useful for your tests
    return { serviceToken, registry, owner, addr1, addr2 };
  }

  describe("Deployment", function () {

    it("Should set the right owner", async function () {

      const { serviceToken, owner } = await loadFixture(deployTokenFixture);
      expect(await serviceToken.owner()).to.equal(owner.address);
    });
    
    it("Mint one service token", async function () {
		const { serviceToken, owner } = await loadFixture(deployTokenFixture);
		serviceToken.create(owner.address, 1, 0);
		const numServiceTokens = serviceToken["balanceOf(address)"](owner.address);
		expect(await numServiceTokens).to.equal(1);
	});
	
	it("Token id of minted service token", async function () {
		const { serviceToken, owner } = await loadFixture(deployTokenFixture);
		serviceToken.create(owner.address, 1, 0);
		serviceToken.create(owner.address, 1, 0);
		serviceToken.create(owner.address, 1, 0);
		const tokenId = serviceToken.tokenOfOwnerByIndex(owner.address, 2); 
		expect(await tokenId).to.equal(3);
	});
	
	
	it("Lock owner ", async function () {
		const { serviceToken, owner } = await loadFixture(deployTokenFixture);
		serviceToken.create(owner.address, 1, 0);
		const tokenId = serviceToken.tokenOfOwnerByIndex(owner.address, 0); 
		const lockId = serviceToken.getLockId(tokenId);
		const ownerAddress = serviceToken.lockOwner(lockId);
		expect(await ownerAddress).to.equal(owner.address);
	});
	
  });
  
  
  
  
  
  
  
  describe("Token transfer", function () {
	  
	  it("Owns tokens at index", async function () {
		  const { serviceToken, owner } = await loadFixture(deployTokenFixture);
		  serviceToken.create(owner.address, 1, 10);
		  const tokenId = serviceToken.ownedTokens(owner.address, 0);
		  expect(await tokenId).to.equal(1);
	  });
	  
	  		
	  it("Emit Transfer evemt on token transfer", async function () {
		const { serviceToken, owner, addr1 } = await loadFixture(deployTokenFixture);
		serviceToken.create(owner.address, 1, 0);
		serviceToken.create(owner.address, 1, 0);
		const tokenId = serviceToken.ownedTokens(owner.address, 1);
		const lockId = serviceToken.getLockId(tokenId);
		const lockOwner = serviceToken.lockOwner(lockId);
		
		const msgAddr = serviceToken.lockMsgSender();

		
		expect(await serviceToken.tokenTransfer(owner.address, addr1.address, lockId)).to.emit(serviceToken, "Transfer").withArgs(owner.address, addr1.address, lockId);

	  });
	  
	  it("Token ownership after transfer", async function () {
		const { serviceToken, owner, addr1 } = await loadFixture(deployTokenFixture);
		serviceToken.create(owner.address, 1, 0);
		serviceToken.create(owner.address, 1, 0);
		const tokenId = serviceToken.ownedTokens(owner.address, 1);
		serviceToken.tokenTransfer(owner.address, addr1.address, tokenId);
		const tokenOwner = serviceToken.tokenOwner(tokenId);
		expect(await tokenOwner).to.equal(addr1.address);
	  });
	  
	  
	  it("Lock ownership after transfer", async function () {
		const { serviceToken, owner, addr1 } = await loadFixture(deployTokenFixture);
		serviceToken.create(owner.address, 1, 0);
		serviceToken.create(owner.address, 1, 0);
		const tokenId = serviceToken.ownedTokens(owner.address, 1);
		const lockId = serviceToken.getLockId(tokenId);
		
		serviceToken.tokenTransfer(owner.address, addr1.address, tokenId);
		const lockOwner = serviceToken.lockOwner(lockId);
		expect(await lockOwner).to.equal(addr1.address);
	  });

  });
  
  
  
  describe("Value transfer", function () {
	  
	  it("Approve value for to contract", async function () {
		const { serviceToken, owner, addr1, addr2 } = await loadFixture(deployTokenFixture);
		
		serviceToken.create(owner.address, 1, 100);
		serviceToken.create(addr1.address, 1, 0);
		
		const tokenIdA = serviceToken.ownedTokens(owner.address, 0);
		const tokenIdB = serviceToken.ownedTokens(addr1.address, 0);
		
		serviceToken["approve(uint256,address,uint256)"](tokenIdA, serviceToken.address, 100);
		const allowance = serviceToken.allowance(tokenIdA, serviceToken.address);
		
		serviceToken["transferFrom(uint256,uint256,uint256)"](tokenIdA, tokenIdB, 50); 
		
		//const balanceA = serviceToken["balanceOf(uint256)"](tokenIdA);
		//const balanceB = serviceToken["balanceOf(uint256)"](tokenIdB);
		
		expect(await allowance).to.equal(100);
		
	 });
	 
	 it("Transfer value between tokens", async function () {
		const { serviceToken, owner, addr1, addr2 } = await loadFixture(deployTokenFixture);
		
		serviceToken.create(owner.address, 1, 100);
		serviceToken.create(addr1.address, 1, 0);
		
		const tokenIdA = serviceToken.ownedTokens(owner.address, 0);
		const tokenIdB = serviceToken.ownedTokens(addr1.address, 0);
		//transferFrom
		const tx1 = await serviceToken["approve(uint256,address,uint256)"](tokenIdA, serviceToken.address, 100);
		const tx2 = await serviceToken["transferFrom(uint256,uint256,uint256)"](tokenIdA, tokenIdB, 30);
		await tx1.wait();
		await tx2.wait();
		const balanceA = serviceToken["balanceOf(uint256)"](tokenIdA);
		expect(await balanceA).to.equal(70);

	 });
	 

  });
  
});
  
  
  
  
  
