import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { v4 as uuidv4 } from 'uuid';
//import  Service   from '../artifacts/contracts/Service.sol/Service.json';
import SpendArtifact from "../artifacts/contracts/Service.sol/Service.json";








describe("SpendCredit", function () {
	const decimals = 6;
  	async function deployTokenFixture() {
	  
		const [svcRevenueAcct, svcAdminAcct, abcSvcRevenueAcct, abcSvcAdminAcct,  
					meriticAcct, meriticAdminAcct, user1, user2, user3] = await ethers.getSigners();
	
		const HardhatUSDC = await ethers.getContractFactory("TestUSDC");
		const WUSDC = await ethers.getContractFactory("WUSDC");
		    
		const usdcContract = await HardhatUSDC.connect(meriticAcct).deploy();
		await usdcContract.deployed();
		    
		await usdcContract.connect(meriticAcct).mint(user1.address, ethers.utils.parseUnits('10000000', 6));
		await usdcContract.connect(meriticAcct).mint(user2.address, ethers.utils.parseUnits('10000000', 6));
	
		const wusdcContract = await WUSDC.connect(meriticAcct).deploy(usdcContract.address, meriticAcct.address);
		await wusdcContract.deployed();
		    
		const spendCreditFactory = await ethers.getContractFactory('SpendCredit', SpendArtifact.abi, SpendArtifact.bytecode,);
		const SlotRegistry = await ethers.getContractFactory("SlotRegistry");
	
		const slotRegContract = await SlotRegistry.connect(meriticAcct).deploy('Meritic Slot Registry', 'MSR', 'uri', 'description', 'image.png', 18);
		await slotRegContract.deployed();
	    
		
		const defaultSlot = 12345;
		const abcDefaultSlot = 67890;
		
		let decimalPlaces = 18;
		
        const slotType  = {contract: 0, network: 1, networkRevShare: 2};
        
        
		await slotRegContract.connect(svcAdminAcct).registerSlot(defaultSlot, 
								'1st Slot', 'http://sloturi', 'a contract slot', slotType.contract);
		await slotRegContract.connect(abcSvcAdminAcct).registerSlot(abcDefaultSlot, 
								'2nd Slot', 'http://sloturi', 'a contract slot', slotType.contract);
								
		
									
									
	    const spendContract = await spendCreditFactory.deploy(
									svcRevenueAcct.address,
									svcAdminAcct.address,
									slotRegContract.address,
									wusdcContract.address,
									meriticAdminAcct.address,
									defaultSlot,
									'XYZ Service',
									'XYZ',
									'http://baseuri',
									'XYZ is a Web3 sevice',
									'image_1.png',
									'USDC',
									decimalPlaces);
		const abcSpendContract = await spendCreditFactory.deploy(
									abcSvcRevenueAcct.address,
									abcSvcAdminAcct.address,
									slotRegContract.address,
									wusdcContract.address,
									meriticAdminAcct.address,
									abcDefaultSlot,
									'ABC Service',
									'ABC',
									'http://baseuri',
									'ABC is a Web3 sevice',
									'image_1.png',
									'USDC',
									decimalPlaces);
												
	    await spendContract.deployed();
	    			
		await abcSpendContract.deployed();
		
		
		return { spendContract, abcSpendContract, defaultSlot, abcDefaultSlot, svcRevenueAcct, meriticAcct, 
					svcAdminAcct, abcSvcRevenueAcct, abcSvcAdminAcct, 
					usdcContract, wusdcContract, slotRegContract, user1, user2, user3 };
  	}
  
  
  
  
  	
  	describe("Mint WUSDC", function () {
		  it("Mint WUSDC token without USDC - reverts with ERC20: transfer amount exceeds balance", async function () {
			  const { spendContract, defaultSlot, wusdcContract, meriticAcct, user1 } = await loadFixture(deployTokenFixture);
			  const amount = ethers.utils.parseUnits('10.0', decimals);
			  await expect(wusdcContract.mint(meriticAcct.address, defaultSlot, amount)).to.be.revertedWith('ERC20: transfer amount exceeds balance')
		  });
		  
		  
		  
		  it('Mint WUSDC amount that exceeds USDC balance - reverts with ERC20: transfer amount exceeds balance', async function () {
			  const { usdcContract, defaultSlot, wusdcContract, spendContract } = await loadFixture(deployTokenFixture);
			  await usdcContract.mint(wusdcContract.address, ethers.utils.parseUnits('10.0', decimals));
			  await expect(wusdcContract.mint(spendContract.address, defaultSlot, ethers.utils.parseUnits('15.0', decimals))).to.be.revertedWith('ERC20: transfer amount exceeds balance')

		  });
	});
	
	
	describe("Transfer WUSDC", function () {
		  it("Transfer WUSDC from non-admin account - reverts with WUSDC: Transfer refused. Unauthorized account", async function () {
			  const { wusdcContract, usdcContract, meriticAcct, user1 } = await loadFixture(deployTokenFixture);
			  await usdcContract.mint(wusdcContract.address, ethers.utils.parseUnits('10.0', decimals));
			  
			  const amount = ethers.utils.parseUnits('10.0', decimals);
			  await expect(wusdcContract.connect(user1).transfer(meriticAcct.address, amount)).to.be.revertedWith('WUSDC: Transfer refused. Unauthorized account')
		  });
		  
		it("Transfer WUSDC from admin account", async function () {
			  const { wusdcContract, defaultSlot, usdcContract, spendContract, meriticAcct } = await loadFixture(deployTokenFixture);
			  
			  await usdcContract.mint(wusdcContract.address, ethers.utils.parseUnits('30.0', decimals));
			  
			  await wusdcContract.mint(meriticAcct.address, defaultSlot, ethers.utils.parseUnits('10.0', decimals));
			  await wusdcContract.mint(spendContract.address, defaultSlot, ethers.utils.parseUnits('10.0', decimals));
			  const amount = ethers.utils.parseUnits('10.0', decimals);
			  await wusdcContract.connect(meriticAcct).transfer(spendContract.address, amount)
			  const balance = await wusdcContract.balanceOf(spendContract.address);
			  expect(ethers.utils.formatUnits(balance, decimals)).to.equal('20.0');
			  
		  });
		  
		it("Transfer WUSDC from admin account check usdc balance euals wusdc", async function () {
			  const { wusdcContract, defaultSlot, usdcContract, spendContract, meriticAcct } = await loadFixture(deployTokenFixture);
			  
			  await usdcContract.mint(wusdcContract.address, ethers.utils.parseUnits('30.0', decimals));
			  
			  await wusdcContract.mint(meriticAcct.address, defaultSlot, ethers.utils.parseUnits('10.0', decimals));
			  await wusdcContract.mint(spendContract.address, defaultSlot, ethers.utils.parseUnits('10.0', decimals));
			  const amount = ethers.utils.parseUnits('10.0', decimals);
			  await wusdcContract.connect(meriticAcct).transfer(spendContract.address, amount)
			  const usdcBalance = await usdcContract.balanceOf(spendContract.address);
			  const wusdcBalance = await wusdcContract.balanceOf(spendContract.address);
			  expect(ethers.utils.formatUnits(usdcBalance, decimals)).to.equal(ethers.utils.formatUnits(wusdcBalance, decimals));
			  
		  });
	});
	
	
	describe("Redeem WUSDC", function () {
		it("Check redeem WUSDC burns WUSDC", async function () {
			const { wusdcContract, defaultSlot, usdcContract, spendContract, svcAdminAcct, meriticAcct } = await loadFixture(deployTokenFixture);
			
			await usdcContract.mint(wusdcContract.address, ethers.utils.parseUnits('30.0', decimals));
			await wusdcContract.mint(meriticAcct.address, defaultSlot, ethers.utils.parseUnits('10.0', decimals));
			const amount = ethers.utils.parseUnits('10.0', decimals);
			await wusdcContract.connect(meriticAcct).redeem(svcAdminAcct.address, defaultSlot, amount); 
			const balance = await wusdcContract.balanceOf(meriticAcct.address);
			expect(ethers.utils.formatUnits(balance, decimals)).to.equal('0.0');
		});
		
		it("Check redeem WUSDC transfers equivalent USDC", async function () {
			const { wusdcContract, defaultSlot, usdcContract, spendContract, svcAdminAcct, meriticAcct } = await loadFixture(deployTokenFixture);
			
			await usdcContract.mint(wusdcContract.address, ethers.utils.parseUnits('30.0', decimals));
			await wusdcContract.mint(meriticAcct.address, defaultSlot, ethers.utils.parseUnits('10.0', decimals));
			const amount = ethers.utils.parseUnits('10.0', decimals);
			await wusdcContract.connect(meriticAcct).redeem(svcAdminAcct.address, defaultSlot, amount); 
			const balance = await usdcContract.balanceOf(svcAdminAcct.address);
			expect(ethers.utils.formatUnits(balance, decimals)).to.equal('10.0');
		});
    
    
    	it("Check redeem WUSDC emits Redeem", async function () {
			const { wusdcContract, defaultSlot, usdcContract, spendContract, svcAdminAcct, meriticAcct } = await loadFixture(deployTokenFixture);
			
			await usdcContract.mint(wusdcContract.address, ethers.utils.parseUnits('30.0', decimals));
			await wusdcContract.mint(meriticAcct.address,defaultSlot,  ethers.utils.parseUnits('10.0', decimals));
			const amount = ethers.utils.parseUnits('10.0', decimals);
			const reedTx =  wusdcContract.connect(meriticAcct).redeem(svcAdminAcct.address, defaultSlot, amount); 
			
			await expect(reedTx).to.emit(wusdcContract, "Redeem").withArgs(meriticAcct.address, ethers.utils.parseUnits('10.0', decimals));
	
		});
	});
	
	
	describe("Mint SpendCredit", function () {
		it("Check mint emits MintServiceToken", async function () {
			const { wusdcContract, usdcContract, spendContract, slotRegContract, svcAdminAcct, meriticAcct, defaultSlot, user1 } = await loadFixture(deployTokenFixture);
			
			await usdcContract.connect(user1).transfer(meriticAcct.address, ethers.utils.parseUnits('10.0', 6));
			await usdcContract.connect(meriticAcct).transfer(wusdcContract.address, ethers.utils.parseUnits('10.0', 6));
			 
			const value = ethers.utils.parseUnits('10.0', decimals);
			const tx = spendContract.mint(user1.address, defaultSlot, value, uuidv4(), 'first minted token', 'token_image.png');
			await expect(tx).to.emit(spendContract, "MintServiceToken").withArgs(1, defaultSlot, ethers.utils.parseUnits('10.0', decimals));
		});
		
		
		it("Check mint emits MintSpendToken", async function () {
			const { wusdcContract, usdcContract, spendContract, slotRegContract, svcAdminAcct, meriticAcct, defaultSlot, user1 } = await loadFixture(deployTokenFixture);
			
			await usdcContract.connect(user1).transfer(meriticAcct.address, ethers.utils.parseUnits('10.0', 6));
			await usdcContract.connect(meriticAcct).transfer(wusdcContract.address, ethers.utils.parseUnits('10.0', 6));

			const value = ethers.utils.parseUnits('10.0', decimals);
			const tx = await spendContract.mint(user1.address, defaultSlot, value, uuidv4(), 'first minted token', 'token_image.png');
			await expect(tx).to.emit(spendContract, "MintSpendToken").withArgs(1, defaultSlot, ethers.utils.parseUnits('10.0', decimals));
		});
		
		
		it("Check WUSDC balance match credit balance for contract on common slot", async function () {
			const { wusdcContract, usdcContract, spendContract, slotRegContract, svcAdminAcct, meriticAcct, defaultSlot, user1, user2 } = await loadFixture(deployTokenFixture);
			
			await usdcContract.connect(user1).transfer(meriticAcct.address, ethers.utils.parseUnits('10.0', 6));
			await usdcContract.connect(meriticAcct).transfer(wusdcContract.address, ethers.utils.parseUnits('10.0', 6));
			
			await usdcContract.connect(user2).transfer(meriticAcct.address, ethers.utils.parseUnits('10.0', 6));
			await usdcContract.connect(meriticAcct).transfer(wusdcContract.address, ethers.utils.parseUnits('10.0', 6));
			
			const value = ethers.utils.parseUnits('10.0', decimals);
			
			await spendContract.mint(user1.address, defaultSlot, value, uuidv4(), 'first minted token', 'token_image1.png');
			await spendContract.mint(user2.address, defaultSlot, value, uuidv4(), 'second minted token', 'token_image2.png');
			
			expect(await spendContract.totalBalance()).to.equal(await wusdcContract.balanceOf(spendContract.address));
		});
	});
	
	
	
	describe("Token-to-address value transfer SpendCredit", function () {
		
		it("Check Token-to-address value transfer - emits  MintServiceTokenToAddress", async function () {
			const { spendContract, wusdcContract, usdcContract,meriticAcct,  svcAdminAcct, defaultSlot, user1, user2 } = await loadFixture(deployTokenFixture);
		
			await usdcContract.connect(user1).transfer(meriticAcct.address, ethers.utils.parseUnits('10.0', 6));
			await usdcContract.connect(meriticAcct).transfer(wusdcContract.address, ethers.utils.parseUnits('10.0', 6));
			
			
			const value = ethers.utils.parseUnits('5.0', decimals);
			const tx = await spendContract.mint(user1.address, defaultSlot, value, uuidv4(), 'first minted token', 'token_image1.png');
			const tokenId = 1;
			
			//await expect(tx).to.emit(spendContract, "MintSpendToken").withArgs(1, defaultSlot, ethers.utils.parseUnits('5.0', decimals));
			//const address = await spendContract['ownerOf(uint256)'](tokenId);
			//console.log(address);
	
			await spendContract.connect(user1)["approve(uint256,address,uint256)"](tokenId, user2.address, ethers.utils.parseUnits('2.0', decimals));   
		
			const transTx = await spendContract.connect(user1)["transferFrom(uint256,address,uint256)"](tokenId, user1.address, ethers.utils.parseUnits('2.0', decimals));
			const newTokenId = 2;
			
			await expect(transTx).to.emit(spendContract, "MintServiceTokenToAddress").withArgs(newTokenId, defaultSlot, ethers.utils.parseUnits('2.0', decimals));
		
		});	
		
		
			it("Check Token-to-address value transfer address token count", async function () {
			const { spendContract, wusdcContract, usdcContract, meriticAcct, svcAdminAcct, defaultSlot, user1, user2 } = await loadFixture(deployTokenFixture);
			
			await usdcContract.connect(user1).transfer(meriticAcct.address, ethers.utils.parseUnits('10.0', 6));
			await usdcContract.connect(meriticAcct).transfer(wusdcContract.address, ethers.utils.parseUnits('10.0', 6));
				
			const value = ethers.utils.parseUnits('5.0', decimals);
			
			await spendContract.mint(user1.address, defaultSlot, value, uuidv4(), 'first minted token', 'token_image1.png');
		
			const tokenId = 1;
			await spendContract.connect(user1)["approve(uint256,address,uint256)"](tokenId, user2.address, ethers.utils.parseUnits('2.0', decimals));   
		
			const transTx = await spendContract.connect(user1)["transferFrom(uint256,address,uint256)"](tokenId, user2.address, ethers.utils.parseUnits('2.0', decimals));
			const newTokenId = 2;
			const balance = await spendContract['balanceOf(address)'](user1.address)
			expect(balance).to.equal(1);
		});
	
	
		it("Check Token-to-address value transfer token balance", async function () {
			const { spendContract, wusdcContract, usdcContract, meriticAcct, svcAdminAcct, slotRegContract, defaultSlot, user1, user2 } = await loadFixture(deployTokenFixture);
		
			await usdcContract.connect(user1).transfer(meriticAcct.address, ethers.utils.parseUnits('10.0', 6));
			await usdcContract.connect(meriticAcct).transfer(wusdcContract.address, ethers.utils.parseUnits('10.0', 6));
			
			const value = ethers.utils.parseUnits('5.0', decimals);
			
			await spendContract.mint(user1.address, defaultSlot, value, uuidv4(), 'first minted token', 'token_image1.png');
		
			const tokenId = 1;
			await spendContract.connect(user1)["approve(uint256,address,uint256)"](tokenId, user2.address, ethers.utils.parseUnits('2.0', decimals));   
		
			await spendContract.connect(user1)["transferFrom(uint256,address,uint256)"](tokenId, user2.address, ethers.utils.parseUnits('2.0', decimals));
			const newTokenId = 2;
			const balance = await spendContract['balanceOf(uint256)'](newTokenId)
			expect(ethers.utils.formatUnits(balance, decimals)).to.equal('2.0');
		});
		
	});
	
	describe("Token-to-token Value Transfer", async function () {
		it("Check transfer - emits ValueTransfer", async function () {
			const decimals = 6
			const { spendContract, wusdcContract, usdcContract, meriticAcct, svcAdminAcct, slotRegContract, defaultSlot, user1, user2, user3 } = await loadFixture(deployTokenFixture);
			await usdcContract.connect(user1).transfer(meriticAcct.address, ethers.utils.parseUnits('20.0', 6));
			await usdcContract.connect(meriticAcct).transfer(wusdcContract.address, ethers.utils.parseUnits('20.0', 6));
			
			const value = ethers.utils.parseUnits('20.0', decimals);
			const mintTx = await spendContract.mint(user1.address, defaultSlot, value, uuidv4(),  'first minted token', 'token_image.png')
	    	const tokenId_1 = 1;
	    	
			await spendContract.connect(user1)["approve(uint256,address,uint256)"](tokenId_1, user2.address, ethers.utils.parseUnits('5', decimals));   
			await spendContract.connect(user1)["approve(uint256,address,uint256)"](tokenId_1, user3.address, ethers.utils.parseUnits('7', decimals));   
			
			await spendContract.connect(user1)["transferFrom(uint256,address,uint256)"](tokenId_1, user2.address, ethers.utils.parseUnits('5', decimals));
			await spendContract.connect(user1)["transferFrom(uint256,address,uint256)"](tokenId_1, user3.address, ethers.utils.parseUnits('7', decimals));
			const tokenId_2 = 2;
			const tokenId_3 = 3;
			await spendContract.connect(user2)["approve(uint256,address,uint256)"](tokenId_2, user3.address, ethers.utils.parseUnits('2', decimals));   
			const transTx = await spendContract.connect(user2)["transferFrom(uint256,uint256,uint256)"](tokenId_2, tokenId_3, ethers.utils.parseUnits('2', decimals));
			await expect(transTx).to.emit(spendContract, "ValueTransfer").withArgs(tokenId_2, tokenId_3, ethers.utils.parseUnits('2', decimals));
			
	    });
	});
	
	
	
	
	
	describe("Mint to network token", async function () {
		it("Check register network slot", async function () {
			const decimals = 6
			const { spendContract, abcSpendContract, wusdcContract, usdcContract, meriticAcct, svcAdminAcct, abcSvcAdminAcct, slotRegContract, 
					defaultSlot, abcDefaultSlot, user1, user2, user3 } = await loadFixture(deployTokenFixture);
			
			
			const netSlot1 = 111111;
			const slotType  = {contract: 0, network: 1, networkRevShare: 2};
			
			const transTx = await slotRegContract.connect(svcAdminAcct).registerSlot(netSlot1, 
								'Network slot', 'http://sloturi', 'First network slot description', slotType.network);
			
			
			await expect(transTx).to.emit(slotRegContract, "NewSlot").withArgs(netSlot1, 'Network slot');		
			/*slotRegContract.connect(svcAdminAcct).approveContractForSlot(abcSpendContract.address, netSlot1);
			
			const value = ethers.utils.parseUnits('20.0', decimals);
			await spendContract.mint(user1.address, netSlot1, value, uuidv4(),  'first minted token', 'token_image.png')
			const transTx = await abcSpendContract.mint(user2.address, netSlot1, value, uuidv4(),  'first minted token', 'token_image.png')
			const tokenId1 = 1;
			await expect(transTx).to.emit(spendContract, "MintNetworkServiceToken").withArgs(tokenId1, netSlot1, value);
			*/
	    	/*const tokenId1 = 1;
	    	const tokenIdAbc1 = 1;
	    	
	    	const networkTokenId1 = await spendContract.networkId(tokenId1);
	    	const networkTokenId1Abc = await spendContract.networkId(tokenIdAbc1);
	    	console.log(networkTokenId1);
	    	console.log(networkTokenId1Abc);
	    	
			await spendContract.connect(user1)["approve(uint256,address,uint256)"](tokenId_1, user2.address, ethers.utils.parseUnits('5', decimals));   
			await spendContract.connect(user1)["approve(uint256,address,uint256)"](tokenId_1, user3.address, ethers.utils.parseUnits('7', decimals));   
			
			await spendContract.connect(user1)["transferFrom(uint256,address,uint256)"](tokenId_1, user2.address, ethers.utils.parseUnits('5', decimals));
			await spendContract.connect(user1)["transferFrom(uint256,address,uint256)"](tokenId_1, user3.address, ethers.utils.parseUnits('7', decimals));
			const tokenId_2 = 2;
			const tokenId_3 = 3;
			await spendContract.connect(user2)["approve(uint256,address,uint256)"](tokenId_2, user3.address, ethers.utils.parseUnits('2', decimals));   
			const transTx = await spendContract.connect(user2)["transferFrom(uint256,uint256,uint256)"](tokenId_2, tokenId_3, ethers.utils.parseUnits('2', decimals));
			await expect(transTx).to.emit(spendContract, "ValueTransfer").withArgs(tokenId_2, tokenId_3, ethers.utils.parseUnits('2', decimals));
			*/
	    });
	    
	    it("Check register network slot", async function () {
			const decimals = 6
			const { spendContract, abcSpendContract, wusdcContract, usdcContract, meriticAcct, svcAdminAcct, abcSvcAdminAcct, slotRegContract, 
					defaultSlot, abcDefaultSlot, user1, user2, user3 } = await loadFixture(deployTokenFixture);
			
			await usdcContract.connect(user1).transfer(meriticAcct.address, ethers.utils.parseUnits('10.0', 6));
			await usdcContract.connect(meriticAcct).transfer(wusdcContract.address, ethers.utils.parseUnits('10.0', 6));
			
			const netSlot1 = 111111;
			const slotType  = {contract: 0, network: 1, networkRevShare: 2};
			const transTx = await slotRegContract.connect(svcAdminAcct).registerSlot(netSlot1, 
								'Network slot', 'http://sloturi', 'First network slot description', slotType.network);
			const txCtrtSlotReg = await slotRegContract.connect(svcAdminAcct).registerContract(svcAdminAcct.address, netSlot1);

			const value = ethers.utils.parseUnits('10.0', decimals);
			const transTx3 = await spendContract.mint(user1.address, netSlot1, value, uuidv4(),  'first minted token', 'token_image.png')
			
			const tokenId1 = 1;
			const networkTokenId1 = await spendContract.networkId(tokenId1);
			await expect(transTx3).to.emit(spendContract, "MintNetworkServiceToken").withArgs(tokenId1, netSlot1, value);
			
			
			//const transTx = await abcSpendContract.mint(user2.address, netSlot1, value, uuidv4(),  'first minted token', 'token_image.png')
			
			
			
	    	/*const tokenId1 = 1;
	    	const tokenIdAbc1 = 1;
	    	
	    	const networkTokenId1 = await spendContract.networkId(tokenId1);
	    	const networkTokenId1Abc = await spendContract.networkId(tokenIdAbc1);
	    	console.log(networkTokenId1);
	    	console.log(networkTokenId1Abc);
	    	
			await spendContract.connect(user1)["approve(uint256,address,uint256)"](tokenId_1, user2.address, ethers.utils.parseUnits('5', decimals));   
			await spendContract.connect(user1)["approve(uint256,address,uint256)"](tokenId_1, user3.address, ethers.utils.parseUnits('7', decimals));   
			
			await spendContract.connect(user1)["transferFrom(uint256,address,uint256)"](tokenId_1, user2.address, ethers.utils.parseUnits('5', decimals));
			await spendContract.connect(user1)["transferFrom(uint256,address,uint256)"](tokenId_1, user3.address, ethers.utils.parseUnits('7', decimals));
			const tokenId_2 = 2;
			const tokenId_3 = 3;
			await spendContract.connect(user2)["approve(uint256,address,uint256)"](tokenId_2, user3.address, ethers.utils.parseUnits('2', decimals));   
			const transTx = await spendContract.connect(user2)["transferFrom(uint256,uint256,uint256)"](tokenId_2, tokenId_3, ethers.utils.parseUnits('2', decimals));
			await expect(transTx).to.emit(spendContract, "ValueTransfer").withArgs(tokenId_2, tokenId_3, ethers.utils.parseUnits('2', decimals));
			*/
	    });
	});
	
	
		
});
  