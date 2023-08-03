
import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { v4 as uuidv4 } from 'uuid';
//import  Service   from '../artifacts/contracts/Service.sol/Service.json';
import TimeCreditArtifact from '../artifacts/contracts/TimeCredit.sol/TimeCredit.json';

import { parseUnits } from "ethers/lib/utils";



describe("TimeCredit", function () {
	
	
  const decimals = 18;
	
  async function deployTokenFixture() {
	  
	const [svcRevenueAcct, svcAdminAcct, meriticAcct, meriticAdminAcct, user1, user2] = await ethers.getSigners();
	
	const HardhatUSDC = await ethers.getContractFactory("TestUSDC");
	const WUSDC = await ethers.getContractFactory("WUSDC");
	    
	const usdcContract = await HardhatUSDC.connect(meriticAcct).deploy();
	await usdcContract.deployed();
	    
	await usdcContract.connect(meriticAcct).mint(user1.address, ethers.utils.parseUnits('10000000', 6));
	await usdcContract.connect(meriticAcct).mint(user2.address, ethers.utils.parseUnits('10000000', 6));

	const wusdcContract = await WUSDC.connect(meriticAcct).deploy(usdcContract.address, meriticAcct.address);
	await wusdcContract.deployed();
	    
	const timeCreditFactory = await ethers.getContractFactory('TimeCredit', TimeCreditArtifact.abi, TimeCreditArtifact.bytecode,);
	const SlotRegistry = await ethers.getContractFactory("SlotRegistry");

	const slotRegContract = await SlotRegistry.connect(meriticAcct).deploy('Meritic Slot Registry', 
			'MSR', 'uri', 'description', 'image.png', 18);

	await slotRegContract.deployed();
	
	const defaultSlot = 12345;
	let decimalPlaces = 18;
	
	const slotType  = {contract: 0, network: 1, networkRevShare: 2};
	
	await slotRegContract.connect(svcAdminAcct).registerSlot(defaultSlot, 
								'1st Slot', 'http://sloturi', 'First slot description', slotType.contract);
        		
    const timeCreditContract = await timeCreditFactory.deploy(
								svcRevenueAcct.address,
								svcAdminAcct.address,
								slotRegContract.address,
								wusdcContract.address,
								meriticAdminAcct.address,
								defaultSlot, 'XYZ Time Service', 'XYZ', 'http://baseuri', 'XYZ is a Web3 sevice',
								'image_1.png', 'hours', 'USDC', decimalPlaces);
								
	const timeCreditContractMonths = await timeCreditFactory.deploy(
								svcRevenueAcct.address,
								svcAdminAcct.address,
								slotRegContract.address,
								wusdcContract.address,
								meriticAdminAcct.address,
								defaultSlot, 'XYZ Time Service', 'XYZ', 'http://baseuri', 'XYZ is a Web3 sevice',
								'image_1.png', 'months', 'USDC', decimalPlaces);			
								

    await timeCreditContract.deployed();
    await timeCreditContractMonths.deployed();
    
    return { timeCreditContract, timeCreditContractMonths, defaultSlot, svcRevenueAcct, meriticAcct, svcAdminAcct, usdcContract, wusdcContract, slotRegContract, user1, user2 };
  }
 
 
 
	describe("Mint Time Token", async function () {
		 
		 it("Check MintServiceToken fired on mint", async function () {
			 
			 const { timeCreditContract, defaultSlot, svcRevenueAcct, meriticAcct, svcAdminAcct, usdcContract, wusdcContract, slotRegContract, user1, user2 } = await loadFixture(deployTokenFixture);
			 
			 await usdcContract.connect(user1).transfer(meriticAcct.address, ethers.utils.parseUnits('10.0', 6));
			 await usdcContract.connect(meriticAcct).transfer(wusdcContract.address, ethers.utils.parseUnits('10.0', 6));
		
			 const timeValueHours = ethers.utils.parseUnits('10.0', 18);
			 const paidValue = ethers.utils.parseUnits('10.0', 6);
			 const startTime = 1714680343; // Thu May 02 2024 20:05:43 GMT+0000
			 const expiration = 1719864343; // Mon Jul 01 2024 20:05:43 GMT+0000
			 const minTransfer = 0;
			 
			 const mintTx = await timeCreditContract.mintTime(user1.address, defaultSlot, timeValueHours, paidValue, startTime, expiration, uuidv4(),  'first minted token', 'token_image.png', true, minTransfer);
			 const tokenId = 1;
			 await expect(mintTx).to.emit(timeCreditContract, "MintServiceToken").withArgs(tokenId, defaultSlot, ethers.utils.parseUnits('3600', 1));
			 
		 });
		 
		 
		 it("Check mint token with start time greater than expiration - reverts: TimeCredit: valid start time must be less than expiration time", async function () {
			 const { timeCreditContract, defaultSlot, svcAdminAcct, meriticAcct,  usdcContract, wusdcContract, slotRegContract, user1, user2 } = await loadFixture(deployTokenFixture);
			 
			 await usdcContract.connect(user1).transfer(meriticAcct.address, ethers.utils.parseUnits('10.0', 6));
			 await usdcContract.connect(meriticAcct).transfer(wusdcContract.address, ethers.utils.parseUnits('10.0', 6));
		
			 
			 const timeValueHours = ethers.utils.parseUnits('10.0', 18);
			 const paidValue = ethers.utils.parseUnits('10.0', 6);
			 const startTime = 1714680343; // Thu May 02 2024 20:05:43 GMT+0000
			 const expiration = 1712001943; // Mon Apr 01 2024 20:05:43 GMT+0000
			 const mintTx = timeCreditContract.mintTime(user1.address, defaultSlot, timeValueHours, paidValue, startTime, expiration, 
			 									uuidv4(),  'first minted token', 'token_image.png', true, 0);
		
			 await expect(mintTx).to.be.revertedWith('TimeCredit: valid start time must be less than expiration time');
	
		 });
		 
		 
	
		 it("Check mint token with value exceeding valid period - reverts: TimeCredit: time value cannot exceed valid period", async function () {
			 const { timeCreditContract, defaultSlot, svcAdminAcct, meriticAcct, usdcContract, wusdcContract, slotRegContract, user1, user2 } = await loadFixture(deployTokenFixture);
			 
			 await usdcContract.connect(user1).transfer(meriticAcct.address, ethers.utils.parseUnits('10.0', 6));
			 await usdcContract.connect(meriticAcct).transfer(wusdcContract.address, ethers.utils.parseUnits('10.0', 6));
		
			 const valueHours = ethers.utils.parseUnits('24.0', 18);
			 const paidValue = ethers.utils.parseUnits('10.0', 6);
			 const start = 1717221943; // Sat Jun 01 2024 06:05:43 GMT+0000
			 const expiration = 1717293943; // Sun Jun 02 2024 02:05:43 GMT+0000
	
		
			 await expect(timeCreditContract.mintTime(user1.address, defaultSlot, valueHours, paidValue, start, expiration, uuidv4(),  
			 				'first minted token', 'token_image.png', true, 0)).to.be.revertedWith('TimeCredit: time value cannot exceed valid period');
	
		 });
		 
		 
		 it("Check mint expired token - reverts: TimeCredit: cannot mint an expired token", async function () {
			 const { timeCreditContract, defaultSlot, svcAdminAcct, meriticAcct, usdcContract, wusdcContract, slotRegContract, user1, user2 } = await loadFixture(deployTokenFixture);
			 
			 await usdcContract.connect(user1).transfer(meriticAcct.address, ethers.utils.parseUnits('10.0', 6));
			 await usdcContract.connect(meriticAcct).transfer(wusdcContract.address, ethers.utils.parseUnits('10.0', 6));
		
			 const valueHours = ethers.utils.parseUnits('10.0', 18);
			 const paidValue = ethers.utils.parseUnits('10.0', 6);
			 const start = 1682917200; // Mon May 01 2023 05:00:00 GMT+0000
			 const expiration = 1683003600; // 	Tue May 02 2023 05:00:00 GMT+0000
			 const mintTx = timeCreditContract.mintTime(user1.address, defaultSlot, valueHours, paidValue, start, expiration, uuidv4(),  'first minted token', 'token_image.png', true, 0);
	
			 await expect(mintTx).to.be.revertedWith('TimeCredit: cannot mint an expired token')
	
		 });
		 
		 
		 it("Check mint emits MintServiceToken", async function () {
			 const { timeCreditContract, defaultSlot, svcAdminAcct, meriticAcct, usdcContract, wusdcContract, slotRegContract, user1, user2 } = await loadFixture(deployTokenFixture);
			 
			 await usdcContract.connect(user1).transfer(meriticAcct.address, ethers.utils.parseUnits('10.0', 6));
			 await usdcContract.connect(meriticAcct).transfer(wusdcContract.address, ethers.utils.parseUnits('10.0', 6));
		
			 const valueHours = ethers.utils.parseUnits('10.0', 18);
			 const paidValue = ethers.utils.parseUnits('10.0', 6);
			 const start = 1717221943; // Sat Jun 01 2024 06:05:43 GMT+0000
			 const expiration = 	1719813943; // 	Mon Jul 01 2024 06:05:43 GMT+0000
			 const mintTx = timeCreditContract.mintTime(user1.address, defaultSlot, valueHours, paidValue, start, expiration, uuidv4(),  'first minted token', 'token_image.png', true, 0);
			 									
			 const tokenId = 1;
			 await expect(mintTx).to.emit(timeCreditContract, "MintServiceToken").withArgs(tokenId, defaultSlot, ethers.utils.parseUnits('3600', 1));
		 });
	});
	
	
	
	describe("Check balance", async function () {
		it("Check balance in hours", async function () {
			const decimals = 18
			const { timeCreditContract, defaultSlot, svcAdminAcct, meriticAcct, usdcContract, wusdcContract, slotRegContract, user1, user2 } = await loadFixture(deployTokenFixture);
			await usdcContract.connect(user1).transfer(meriticAcct.address, ethers.utils.parseUnits('10.0', 6));
			await usdcContract.connect(meriticAcct).transfer(wusdcContract.address, ethers.utils.parseUnits('10.0', 6));
			
			const valueHours = ethers.utils.parseUnits('10.0', 18);
			const paidValue = ethers.utils.parseUnits('10.0', 6);
			const start = 1714539375; // Mon May 01 2024 05:00:00 GMT+0000
			const expiration = 1719809775; // Sat Jul 01 2024 05:00:00 GMT+0000
			await timeCreditContract.mintTime(user1.address, defaultSlot, valueHours, paidValue, start, expiration, uuidv4(),  'first minted token', 'token_image.png', true, 0);
			
			const tokenId = 1;
			const balance = await timeCreditContract['balanceOf(uint256)'](tokenId);

			expect(ethers.utils.formatUnits(balance, decimals)).to.equal('10.0');
         });
         
         
         
         it("Check MintTimeToken fired on mint", async function () {
			 const decimals = 18;
			 const { timeCreditContractMonths, defaultSlot, svcRevenueAcct, meriticAcct, svcAdminAcct, usdcContract, wusdcContract, slotRegContract, user1, user2 } = await loadFixture(deployTokenFixture);
			 
			 await usdcContract.connect(user1).transfer(meriticAcct.address, ethers.utils.parseUnits('10.0', 6));
			 await usdcContract.connect(meriticAcct).transfer(wusdcContract.address, ethers.utils.parseUnits('10.0', 6));
		
			 const valueHours = ethers.utils.parseUnits('1.0', decimals);
			 const paidValue = ethers.utils.parseUnits('10.0', 6);
	
			 const start = 1714539375; // Wed May 01 2024 04:56:15 GMT+0000
			 const expiration = 1752037200; // Wed Jul 09 2025 05:00:00 GMT+0000
			 const mintTx = await timeCreditContractMonths.mintTime(user1.address, defaultSlot, valueHours, paidValue, start, expiration, uuidv4(),  'first minted token', 'token_image.png', true, 0);
			 const tokenId = 1;
			 
			 await expect(mintTx).to.emit(timeCreditContractMonths, "MintTimeToken").withArgs('2592000', ethers.utils.parseUnits('1.0', decimals));
			 
		 });
		 
		 
         it("Check balance in months", async function () {
	            const decimals = 18;
	            const { timeCreditContractMonths, defaultSlot, svcAdminAcct, meriticAcct, usdcContract, wusdcContract, slotRegContract, user1, user2 } = await loadFixture(deployTokenFixture);
				await usdcContract.connect(user1).transfer(meriticAcct.address, ethers.utils.parseUnits('10.0', 6));
				await usdcContract.connect(meriticAcct).transfer(wusdcContract.address, ethers.utils.parseUnits('10.0', 6));
		
	            const valueHours = ethers.utils.parseUnits('1.0', decimals);
	            const paidValue = ethers.utils.parseUnits('10.0', 6);
	        
	            
	            const start = 1714539375; // Wed May 01 2024 04:56:15 GMT+0000
	            const expiration = 1752037200; // Wed Jul 09 2025 05:00:00 GMT+0000
	            await timeCreditContractMonths.mintTime(user1.address, defaultSlot, valueHours, paidValue, start, expiration, uuidv4(),  'first minted token', 'token_image.png', true, 0);
	            const tokenId = 1;
	            const balance = await timeCreditContractMonths['balanceOf(uint256)'](tokenId)
	           
	            expect(ethers.utils.formatUnits(balance, decimals)).to.equal('1.0');
	     });
	});
	
	
	describe("Transfer", async function () {
		it("Check Token-to-address value transfer - emits  MintServiceTokenToAddress", async function () {
            const { timeCreditContract, defaultSlot, svcAdminAcct, meriticAcct, usdcContract, wusdcContract, slotRegContract, user1, user2 } = await loadFixture(deployTokenFixture);
         	await usdcContract.connect(user1).transfer(meriticAcct.address, ethers.utils.parseUnits('10.0', 6));
			await usdcContract.connect(meriticAcct).transfer(wusdcContract.address, ethers.utils.parseUnits('10.0', 6));
		
            const valueHours = ethers.utils.parseUnits('12.0', decimals);
			const paidValue = ethers.utils.parseUnits('10.0', 6);
			
            const start = 1714539375; // Wed May 01 2024 04:56:15 GMT+0000
            const expiration = 1720500975 // Tue Jul 09 2024 04:56:15 GMT+0000
            await timeCreditContract.mintTime(user1.address, defaultSlot, valueHours, paidValue, start, expiration, uuidv4(),  'first minted token', 'token_image.png', true, 0);
            const tokenId = 1;
            await timeCreditContract.connect(user1)["approve(uint256,address,uint256)"](tokenId, user2.address, ethers.utils.parseUnits('5.0', decimals));
            
            const transTx = await timeCreditContract.connect(user1)["transferFrom(uint256,address,uint256)"](tokenId, user2.address, ethers.utils.parseUnits('5.0', decimals));
            const newTokenId = 2;
            await expect(transTx).to.emit(timeCreditContract, "MintServiceTokenToAddress").withArgs(newTokenId, 12345, ethers.utils.parseUnits('18000', 0));
            
    	});
    	
    	it("Check Token-to-address value traansfer, value below minimum transfer threshold - should revert", async function () {

            const { timeCreditContract, defaultSlot, svcAdminAcct, meriticAcct, usdcContract, wusdcContract, slotRegContract, user1, user2 } = await loadFixture(deployTokenFixture);
			await usdcContract.connect(user1).transfer(meriticAcct.address, ethers.utils.parseUnits('10.0', 6));
			await usdcContract.connect(meriticAcct).transfer(wusdcContract.address, ethers.utils.parseUnits('10.0', 6));
		
            const valueHours = ethers.utils.parseUnits('10.0', decimals); //10 hours
            const paidValue = ethers.utils.parseUnits('10.0', 6);
            const start = 1714556155; // Wed May 01 2024 09:35:55 GMT+0000
            const expiration =  1720517755 // Tue Jul 09 2024 09:35:55 GMT+0000
            const minTransferVal = ethers.utils.parseUnits('1.0', decimals)
            await timeCreditContract.mintTime(user1.address, defaultSlot, valueHours, paidValue, start, expiration, uuidv4(),  'first minted token', 'token_image.png', true, minTransferVal);
            const tokenId = 1;
            await timeCreditContract.connect(user1)["approve(uint256,address,uint256)"](tokenId, user2.address, ethers.utils.parseUnits('0.5', decimals));

            await expect(timeCreditContract.connect(user1)["transferFrom(uint256,address,uint256)"]
                            (tokenId, user1.address, ethers.utils.parseUnits('0.5', decimals))).to.be.revertedWith('TimeCredit: amount being transfered is less than minimum transferable value')
        });
        
        
        it("Check Token-to-token value traansfer, value below minimum transfer threshold - should revert", async function () {

            const { timeCreditContract, defaultSlot, svcAdminAcct, meriticAcct, usdcContract, wusdcContract, slotRegContract, user1, user2 } = await loadFixture(deployTokenFixture);
			await usdcContract.connect(user1).transfer(meriticAcct.address, ethers.utils.parseUnits('10.0', 6));
			await usdcContract.connect(meriticAcct).transfer(wusdcContract.address, ethers.utils.parseUnits('10.0', 6));
			
			await usdcContract.connect(user2).transfer(meriticAcct.address, ethers.utils.parseUnits('10.0', 6));
			await usdcContract.connect(meriticAcct).transfer(wusdcContract.address, ethers.utils.parseUnits('10.0', 6));
			
            const valueHours = ethers.utils.parseUnits('10.0', decimals); //10 hours
            const paidValue = ethers.utils.parseUnits('10.0', 6);
            
            const start = 1714556155; // Wed May 01 2024 09:35:55 GMT+0000
            const expiration =  1720517755 // Tue Jul 09 2024 09:35:55 GMT+0000
            const minTransferVal = ethers.utils.parseUnits('1.0', decimals)
            await timeCreditContract.mintTime(user1.address, defaultSlot, valueHours, paidValue, start, expiration, uuidv4(),  'first minted token', 'token_image.png', true, minTransferVal);
            await timeCreditContract.mintTime(user2.address, defaultSlot, valueHours, paidValue, start, expiration, uuidv4(),  'first minted token', 'token_image.png', true, minTransferVal);
            const tokenId1 = 1;
            const tokenId2 = 2;
            await timeCreditContract.connect(user1)["approve(uint256,address,uint256)"](tokenId1, user2.address, ethers.utils.parseUnits('0.5', decimals));

            await expect(timeCreditContract.connect(user1)["transferFrom(uint256,uint256,uint256)"]
                            (tokenId1, tokenId2, ethers.utils.parseUnits('0.5', decimals))).to.be.revertedWith('TimeCredit: amount being transfered is less than minimum transferable value')
        });

    	it("Check Token-to-token value traansfer", async function () {

            const { timeCreditContract, defaultSlot, svcAdminAcct, meriticAcct, usdcContract, wusdcContract, slotRegContract, user1, user2 } = await loadFixture(deployTokenFixture);
			await usdcContract.connect(user1).transfer(meriticAcct.address, ethers.utils.parseUnits('10.0', 6));
			await usdcContract.connect(meriticAcct).transfer(wusdcContract.address, ethers.utils.parseUnits('10.0', 6));
			
			await usdcContract.connect(user2).transfer(meriticAcct.address, ethers.utils.parseUnits('10.0', 6));
			await usdcContract.connect(meriticAcct).transfer(wusdcContract.address, ethers.utils.parseUnits('10.0', 6));
			
            const valueHours = ethers.utils.parseUnits('10.0', decimals); //10 hours
            const paidValue = ethers.utils.parseUnits('10.0', 6);
            
            const start = 1714556155; // Wed May 01 2024 09:35:55 GMT+0000
            const expiration =  1720517755 // Tue Jul 09 2024 09:35:55 GMT+0000
            const minTransferVal = ethers.utils.parseUnits('1.0', decimals)
            await timeCreditContract.mintTime(user1.address, defaultSlot, valueHours, paidValue, start, expiration, uuidv4(),  'first minted token', 'token_image.png', true, minTransferVal);
            await timeCreditContract.mintTime(user2.address, defaultSlot, valueHours, paidValue, start, expiration, uuidv4(),  'first minted token', 'token_image.png', true, minTransferVal);
            const tokenId1 = 1;
            const tokenId2 = 2;
            await timeCreditContract.connect(user1)["approve(uint256,address,uint256)"](tokenId1, user2.address, ethers.utils.parseUnits('2.0', decimals));

			const transTx = await timeCreditContract.connect(user1)["transferFrom(uint256,uint256,uint256)"](tokenId1, tokenId2, ethers.utils.parseUnits('2.0', decimals))
			const token2Balance = await timeCreditContract['balanceOf(uint256)'](tokenId2);
            expect(ethers.utils.formatUnits(token2Balance, decimals)).to.equal('12.0')

        });

	});
});