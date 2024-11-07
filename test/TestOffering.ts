
import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { v4 as uuidv4 } from 'uuid';
import UtilArtifact from '../artifacts/contracts/util/Util.sol/Util.json';
import OfferingArtifact from '../artifacts/contracts/Offering.sol/Offering.json';
import CashCreditArtifact from '../artifacts/contracts/CashCredit.sol/CashCredit.json';
import RegistryArtifact from '../artifacts/contracts/Registry.sol/Registry.json';
import PoolArtifact from '../artifacts/contracts/Pool.sol/Pool.json';
import { parseUnits } from "ethers/lib/utils";






describe("TimeCredit", function () {
	
	const decimals = 6;
	
	async function deployTokenFixture() {
		const decimals = new Map(Object.entries({USDC: 6, ETH: 18, MATIC: 18}));
		const [svcRevenueAcct, meriticAcct, user1, user2] = await ethers.getSigners();
		const HardhatUSDC = await ethers.getContractFactory("TestUSDC");
		const usdc = await HardhatUSDC.connect(meriticAcct).deploy();
		await usdc.deployed();
	    await usdc.connect(meriticAcct).mint(user1.address, ethers.utils.parseUnits('1000000000', 6));
	    
		const utilFactory = await ethers.getContractFactory('Util', UtilArtifact.abi, UtilArtifact.bytecode);
		const regFactory = await ethers.getContractFactory('Registry', RegistryArtifact.abi, RegistryArtifact.bytecode);
		const offeringFactory = await ethers.getContractFactory('Offering', OfferingArtifact.abi, OfferingArtifact.bytecode);
		const cashCreditFactory = await ethers.getContractFactory('CashCredit', CashCreditArtifact.abi, CashCreditArtifact.bytecode);
		const poolFactory = await ethers.getContractFactory('Pool', PoolArtifact.abi, PoolArtifact.bytecode);

		const util = await utilFactory.connect(meriticAcct).deploy();
		await util.deployed();
	
		const registry = await regFactory.connect(meriticAcct).deploy(util.address);
		await registry.deployed();
		const defaultSlot = 12345;
		const slot = {	currency: 'USDC', 
						slotId: 12345,
						name: 'First slot', 
						uri: 'http://sloturi',
						description: 'First slot description',
						decimals: 6,
						by_invite: true}

		const pool = await poolFactory.connect(meriticAcct).deploy(registry.address, slot.currency,
															'Pool', 'MER','baseuri','Description','contractImage', 6);
		const slotType  = {contract: 0, network: 1, networkRevShare: 2};

		await registry.connect(meriticAcct).registerSlot(svcRevenueAcct.address,
															usdc.address,
															slot.currency,
															slot.slotId, 
															slot.name, 
															slot.uri, 
															slot.description, 
															slotType.contract,
															slot.decimals,
															slot.by_invite);

		const service = {	name: 'XYZ Time Service', 
								symbol: 'XYZ',
								uri: 'http://baseuri',
								description:'XYZ is a Web3 sevice',
								image: 'image_1.png',
								currency: 'USDC'
							}
	    const offeringContract = await offeringFactory.deploy(
									svcRevenueAcct.address,
									registry.address,
									pool.address,
									usdc.address,
									service.name, service.symbol, service.uri, 
									service.description, service.image, service.currency, slot.decimals);
		await offeringContract.deployed();
		
		
		const cashCreditContract = await cashCreditFactory.deploy(svcRevenueAcct.address,
											        		registry.address,
											        		pool.address,
											        		usdc.address,
											        		meriticAcct.address,
											        		slot.slotId,
											        		service.name, 
											        		service.symbol, 
											        		service.uri,
											        		service.description,
											        		service.image,
											        		service.currency,
											        		slot.decimals);
       	await cashCreditContract.deployed();
        		
		return { svcRevenueAcct, meriticAcct, usdc, pool, slot, service,
					registry, offeringContract, offeringFactory, cashCreditContract, decimals, user1, user2 };
  	}
  	
  	
  	
  	
  	
  	describe("mint token", async function () {

		  it("Mint", async function () {
			  const { usdc, offeringContract, decimals, meriticAcct, user1, user2, slot} = await loadFixture(deployTokenFixture);
		
			  await usdc.connect(user1).transfer(offeringContract.address,  ethers.utils.parseUnits('10.0',  decimals.get('USDC')));
			  const tokenId = 1
			  const initValue = ethers.utils.parseUnits('50.0', decimals.get('USDC'));
			  const mintValue = ethers.utils.parseUnits('10.0', decimals.get('USDC'));
        	  const offeringAssetId = uuidv4();
        	  
			      				
        	  await offeringContract.connect(meriticAcct).mktListOffering(	user1.address,
				  														[uuidv4()], 
			  															['asseturi'], 
			  															['data'],
			  															initValue,
			  															slot.slotId,
			  															offeringAssetId,
			  															"sell",
			  															'offer description',
			  															'offer_image',
			  															'offer_properties',
			  															false, true );
			  															
			  const mintTx = await offeringContract.connect(meriticAcct).mint(	user1.address, 
					  															slot.slotId, 
					  															mintValue, 
					  															offeringAssetId);
			  						
			  expect(mintTx).to.emit(offeringContract, "MintOffering").withArgs(tokenId, slot.slotId, mintValue);
		  });
		  
		  
		  /*it("Should allow owner to mint tokens with correct details", async function () {
			  const { usdc, offeringContract, service, decimals, meriticAcct, user1, user2, defaultSlot} = await loadFixture(deployTokenFixture);
			  const value = ethers.utils.parseUnits('10.0', decimals.get('USDC'));
        	  const offeringAssetId = uuidv4();
        	  const tokenId = 1
        	  const tokenInfo = {	
				  					name: service.name + ' #' + tokenId,
				  					description: 'token description', 
				  					image: 'token_image', 
				  					properties: 'token_properties'
				  				}
			  await offeringContract.connect(meriticAcct).mint(user1.address, 
			  															defaultSlot, 
			  															value, 
			  															[uuidv4()], 
			  															['asseturi'], 
			  															['data'], 
			  															offeringAssetId, 
			  															tokenInfo.description, 
			  															tokenInfo.image, tokenInfo.properties, false, true);
			  const tokenURI = await offeringContract.connect(meriticAcct).tokenURI(tokenId);
			  const info = {	
				  			name: tokenInfo.name,
			  				description: tokenInfo.description,
                            image: tokenInfo.image,
                            balance: value.toString(),
                            slot: defaultSlot.toString(),
                            properties: tokenInfo.properties,
                         }
			  expect(atob(tokenURI.split('base64,')[1])).to.equal(JSON.stringify(info));
		  });*/
		  
		  it("Should revert if non-owner tries to mint tokens", async function () {
			  const { usdc, offeringContract, decimals, meriticAcct, user1, user2, slot} = await loadFixture(deployTokenFixture);
			  const initValue = ethers.utils.parseUnits('50.0', decimals.get('USDC'));
			  const mintValue = ethers.utils.parseUnits('10.0', decimals.get('USDC'));
			  
        	  const offeringAssetId = uuidv4();
        	  
        	  await offeringContract.connect(meriticAcct).mktListOffering(	user1.address,
				  														[uuidv4()], 
			  															['asseturi'], 
			  															['data'],
			  															initValue,
			  															slot.slotId,
			  															offeringAssetId,
			  															"sell",
			  															'offer description',
			  															'offer_image',
			  															'offer_properties',
			  															false, true );
			  															
			  															
        	  const mintTx = offeringContract.connect(user1).mint(user2.address, 
			  															slot.slotId, 
			  															mintValue, 
			  															offeringAssetId);
     			
			  await expect(mintTx).to.be.revertedWith("Sender not authorized to mint");
  		  });
  		  
  		  
  		  
  		  
  		  
  		  it("Should revert if assets are already in another offering", async function () {
				// Minting tokens with assets already in another offering
				// Deploy another offering contract and mint some tokens with same assets
				const { usdc, offeringContract, registry, pool, slot, offeringFactory, decimals, meriticAcct, svcRevenueAcct, user1, user2} = await loadFixture(deployTokenFixture);
    			const anotherOfferingContract = await offeringFactory.deploy(
									svcRevenueAcct.address,
									registry.address,
									pool.address,
									usdc.address,
									'XYZ Time Service', 'XYZ', 'http://baseuri', 
									'XYZ is a Web3 sevice', 'image_1.png', 'USDC', slot.decimals);
									
				const initValue = ethers.utils.parseUnits('50.0', decimals.get('USDC'));
			  	const mintValue = ethers.utils.parseUnits('10.0', decimals.get('USDC'));
			  	
				const assetId = uuidv4();
        	  	const offeringAssetId = uuidv4();
        	  	
        	  	
        	  	
        	  	await offeringContract.connect(meriticAcct).mktListOffering(	user1.address,
				  														[assetId], 
			  															['asseturi'], 
			  															['data'],
			  															initValue,
			  															slot.slotId,
			  															offeringAssetId,
			  															"sell",
			  															'offer description',
			  															'offer_image',
			  															'offer_properties',
			  															false, true );
			  															
   				await expect(
					anotherOfferingContract.connect(meriticAcct).mktListOffering(	user1.address,
				  														[assetId], 
			  															['asseturi'], 
			  															['data'],
			  															initValue,
			  															slot.slotId,
			  															offeringAssetId,
			  															"sell",
			  															'offer description',
			  															'offer_image',
			  															'offer_properties',
			  															false, true )
   
				).to.be.revertedWith("Asset can only be in one offering");
  			});
    });
    describe("mint from credits", async function () {
		
		it("should mint cash credits with discount", async function () {
		    // Mint some credits to creditContract and approve offeringContract to spend them
		  	const {usdc, offeringContract, cashCreditContract, registry, slot, offeringFactory, decimals, meriticAcct, svcRevenueAcct, user1 } = await loadFixture(deployTokenFixture);
    		
    		const creditValue = ethers.utils.parseUnits('100.0', decimals.get('USDC'));
    		await usdc.connect(user1).transfer(meriticAcct.address, ethers.utils.parseUnits('1000.0', decimals.get('USDC')));
			await usdc.connect(meriticAcct).approve(cashCreditContract.address, creditValue)
    		var discountMilliBasisPts = 3000 * 1000;
    		
    		const ethDiscountMilliBasisPts = ethers.utils.parseUnits(discountMilliBasisPts.toString(), decimals.get('USDC'));
    		
    		const assetId = uuidv4();
    		const tokenDescription = 'token description'
    		const tokenImage = 'token_image';
    		const properties = 'token_properties';
    		const creditTokenId = 1;
    		const creditTx = await cashCreditContract.connect(meriticAcct).mintWithDiscount(
																					user1.address, 
																        			slot.slotId, 
																        			creditValue,
																        			ethDiscountMilliBasisPts,
																        			assetId,
																        			tokenDescription,
																        			tokenImage,
																        			properties)
    			
    	    await expect(creditTx).to.emit(cashCreditContract, "MintCashToken").withArgs(creditTokenId, slot.slotId, creditValue);
    	   
		});
		
		
		
		it("should mint tokens from credits with discount", async function () {
		    // Mint some credits to creditContract and approve offeringContract to spend them
		  	const {usdc, offeringContract, cashCreditContract, registry, slot, offeringFactory, decimals, meriticAcct, svcRevenueAcct, user1 } = await loadFixture(deployTokenFixture);
    		
    		const creditValue = ethers.utils.parseUnits('100.0', decimals.get('USDC'));
    		await usdc.connect(user1).transfer(meriticAcct.address, ethers.utils.parseUnits('1000.0', decimals.get('USDC')));
			await usdc.connect(meriticAcct).approve(cashCreditContract.address, creditValue)
    		var discountMilliBasisPts = 3000 * 1000;
    		
    		const ethDiscountMilliBasisPts = ethers.utils.parseUnits(discountMilliBasisPts.toString(), decimals.get('USDC'));
    		
    		const assetId = uuidv4();
    		const tokenDescription = 'token description'
    		const tokenImage = 'token_image';
    		const properties = 'token_properties';
    		const creditTokenId = 1;
    		const creditTx = await cashCreditContract.connect(meriticAcct).mintWithDiscount(
																					user1.address, 
																        			slot.slotId, 
																        			creditValue,
																        			ethDiscountMilliBasisPts,
																        			assetId,
																        			tokenDescription,
																        			tokenImage,
																        			properties);
																        			

	    						
    	    const value = ethers.utils.parseUnits('10.0', decimals.get('USDC'));
    	    const realValue = ethers.utils.parseUnits('7.0', decimals.get('USDC'));
		    const asset = ["asset1", "asset2"]; 
		    const assetUri = ["uri1", "uri2"]; 
		    const assetType = ["data", "content"]; 
		    const offeringAssetId = uuidv4();
		    const canShareOwn = true;
		    const isMultiAccess = true;
			const tokenId = 1;
			const assetTokenId = 1;
			await offeringContract.connect(meriticAcct).mktListOffering(svcRevenueAcct.address,
				  														asset, 
			  															assetUri, 
			  															assetType,
			  															value,
			  															slot.slotId,
			  															offeringAssetId,
			  															"sell",
			  															'offer description',
			  															'offer_image',
			  															'offer_properties',
			  															false, true );
			  															
			const tx = await cashCreditContract.connect(user1).redeemForAsset(offeringContract.address, 
													    					creditTokenId, 
													    					slot.slotId,
													    					value, offeringAssetId);							
			  														

    	   await expect(tx).to.emit(cashCreditContract, "RedeemForAsset").withArgs(assetTokenId, user1.address, realValue);

		});
		

		
		it("should revert if redemption value exceeds credit value", async function () {
			const {usdc, offeringContract, cashCreditContract, registry, slot, offeringFactory, decimals, meriticAcct, svcRevenueAcct, user1 } = await loadFixture(deployTokenFixture);
		  	var discountMilliBasisPts = 3000 * 1000;
		  	const ethDiscountMilliBasisPts = ethers.utils.parseUnits(discountMilliBasisPts.toString(), decimals.get('USDC'));;
		  	const value = ethers.utils.parseUnits('10.0', decimals.get('USDC'));
		  	const asset = ["asset1", "asset2"]; // Sample asset details
		  	const assetUri = ["uri1", "uri2"]; // Sample asset URIs
		  	const assetType = ["data", "data"]; // Sample asset types
		  	const offeringAssetId = uuidv4();
		  	const canShareOwn = true;
		  	const isMultiAccess = true;
		  	await offeringContract.connect(meriticAcct).mktListOffering(user1.address,
				  														asset, 
			  															assetUri, 
			  															assetType,
			  															value,
			  															slot.slotId,
			  															offeringAssetId,
			  															"sell",
			  															'offer description',
			  															'offer_image',
			  															'offer_properties',
			  															false, true );
		   const assetId = uuidv4();
		   const tokenDescription = 'token description'; 
		   const tokenImage = 'token_image';
		   const properties = 'token_properties';
		   const creditTokenId = 1;
		   const creditValue = ethers.utils.parseUnits('10.0', decimals.get('USDC'));
		   
		   await usdc.connect(user1).transfer(meriticAcct.address, ethers.utils.parseUnits('10.0', decimals.get('USDC')));
		   await usdc.connect(meriticAcct).approve(cashCreditContract.address, creditValue)
			
		   const creditTx = await cashCreditContract.connect(meriticAcct).mintWithDiscount(
																					user1.address, 
																        			slot.slotId, 
																        			creditValue,
																        			ethDiscountMilliBasisPts,
																        			assetId,
																        			tokenDescription,
																        			tokenImage,
																        			properties);
			  															
		   const redeemValue = ethers.utils.parseUnits('11.0', decimals.get('USDC'));
		   
		   const tx = cashCreditContract.connect(user1).redeemForAsset(
												  				offeringContract.address, 
									    						creditTokenId,
									    						slot.slotId,
									    						redeemValue,
									    						offeringAssetId);
									    						
		   await expect( tx ).to.be.revertedWith("Value exceeds credit balance");
		});
		
		
		
		it('redeem for access', async function () {
			const {usdc, offeringContract, cashCreditContract, registry, slot, offeringFactory, decimals, meriticAcct, svcRevenueAcct, user1 } = await loadFixture(deployTokenFixture);
		  	var discountMilliBasisPts = 3000 * 1000;
		  	const ethDiscountMilliBasisPts = ethers.utils.parseUnits(discountMilliBasisPts.toString(), decimals.get('USDC'));;
		  	const value = ethers.utils.parseUnits('10.0', decimals.get('USDC'));
		  	const asset = ["asset1", "asset2"]; // Sample asset details
		  	const assetUri = ["uri1", "uri2"]; // Sample asset URIs
		  	const assetType = ["data", "data"]; // Sample asset types
		  	const offeringAssetId = uuidv4();
		  	const canShareOwn = true;
		  	const isMultiAccess = true;
		  	await offeringContract.connect(meriticAcct).mktListOffering(user1.address,
				  														asset, 
			  															assetUri, 
			  															assetType,
			  															value,
			  															slot.slotId,
			  															offeringAssetId,
			  															"sell",
			  															'offer description',
			  															'offer_image',
			  															'offer_properties',
			  															false, true );
			  															
			const assetId = uuidv4();
			const tokenDescription = 'token description';
			const tokenImage = 'token_image';
			const properties = 'token_properties';
			const creditTokenId = 1;
			const creditValue = ethers.utils.parseUnits('10.0', decimals.get('USDC'));
		   
		   	await usdc.connect(user1).transfer(meriticAcct.address, ethers.utils.parseUnits('10.0', decimals.get('USDC')));
		   	await usdc.connect(meriticAcct).approve(cashCreditContract.address, creditValue)
			
		   	const creditTx = await cashCreditContract.connect(meriticAcct).mintWithDiscount(
				   																	user1.address, 
																        			slot.slotId, 
																        			creditValue,
																        			ethDiscountMilliBasisPts,
																        			assetId,
																        			tokenDescription,
																        			tokenImage,
																        			properties);

			const resDate = new Date();										        			
			resDate.setMonth(resDate.getMonth() + 1);		
			const redeemValue = ethers.utils.parseUnits('10.0', decimals.get('USDC'));
			const realValue = ethers.utils.parseUnits('7.0', decimals.get('USDC'));					        													
			const tx = cashCreditContract.connect(user1).redeemForAccess(
																	offeringContract.address, 
											    					creditTokenId, 
											    					slot.slotId, 
											    					redeemValue,
											    					resDate.getTime(),
											    					offeringAssetId);
									    		
			await expect(tx).to.emit(cashCreditContract, "RedeemForAccess").withArgs(user1.address, redeemValue, realValue);
		});

	});
	
	
	describe("Transfer", async function () {
		it('Mint offering token', async function () {
			const {usdc, offeringContract, cashCreditContract, registry, slot, offeringFactory, decimals, meriticAcct, svcRevenueAcct, user1 } = await loadFixture(deployTokenFixture);
			var discountMilliBasisPts = 3000 * 1000;
			const ethDiscountMilliBasisPts = ethers.utils.parseUnits(discountMilliBasisPts.toString(), decimals.get('USDC'));
			const value = ethers.utils.parseUnits('10.0', decimals.get('USDC'));
			
			const asset = ["asset1", "asset2"]; // Sample asset details
			const assetUri = ["uri1", "uri2"]; // Sample asset URIs
			const assetType = ["data", "data"]; // Sample asset types
			const offeringAssetId = uuidv4();
			const canShareOwn = true;
			const isMultiAccess = true;
			
			await offeringContract.connect(meriticAcct).mktListOffering(meriticAcct.address,
					  														asset, 
				  															assetUri, 
				  															assetType,
				  															value,
				  															slot.slotId,
				  															offeringAssetId,
				  															"sell",
				  															'offer description',
				  															'offer_image',
				  															'offer_properties', false, true );
				  															
			const offerToken = 1;									
			const mintTx = offeringContract.connect(meriticAcct).mint(user1.address, 
				  															slot.slotId, 
				  															value, 
				  															offeringAssetId);
			//MintOffering(tokenId, slotId_, value_);	
															
			//const tx = offeringContract.connect(user1).transferFrom(uint256 fromTokenId_, address to_, uint256 value_);
			await expect(mintTx).to.emit(offeringContract, "MintOffering").withArgs(offerToken, slot.slotId, value);
			
		});			
		
		it("should revert with value less than minimum", async function () {
			const {usdc, offeringContract, cashCreditContract, registry, slot, 
						offeringFactory, decimals, meriticAcct, svcRevenueAcct, user1, user2 } = await loadFixture(deployTokenFixture);
			var discountMilliBasisPts = 3000 * 1000;
			const ethDiscountMilliBasisPts = ethers.utils.parseUnits(discountMilliBasisPts.toString(), decimals.get('USDC'));
			const value = ethers.utils.parseUnits('10.0', decimals.get('USDC'));
			
			const asset = ["asset1", "asset2"]; // Sample asset details
			const assetUri = ["uri1", "uri2"]; // Sample asset URIs
			const assetType = ["data", "data"]; // Sample asset types
			const offeringAssetId = uuidv4();
			const canShareOwn = true;
			const isMultiAccess = true;
			
			await offeringContract.connect(meriticAcct).mktListOffering(meriticAcct.address,
					  														asset, 
				  															assetUri, 
				  															assetType,
				  															value,
				  															slot.slotId,
				  															offeringAssetId,
				  															"sell",
				  															'offer description',
				  															'offer_image',
				  															'offer_properties', false, true );
				  															
			const offerToken = 1;									
			const mintTx = offeringContract.connect(meriticAcct).mint(user1.address, 
				  															slot.slotId, 
				  															value, 
				  															offeringAssetId);
				  															
				  															
			const halfValue =  ethers.utils.parseUnits('0', decimals.get('USDC'));
			const tx = offeringContract.connect(user1)["transferFrom(uint256,address,uint256)"](offerToken, user2.address, halfValue);
	
			await expect( tx ).to.be.revertedWith("Value less than minimum");
			//await expect(tx).to.emit(offeringContract, "MintOffering").withArgs(offerToken, slot.slotId, halfValue);
		});		
		
		
		it("token address transfer - should increase number of owners of an offering", async function () {
			const {usdc, offeringContract, cashCreditContract, registry, slot, 
						offeringFactory, decimals, meriticAcct, svcRevenueAcct, user1, user2 } = await loadFixture(deployTokenFixture);
			var discountMilliBasisPts = 3000 * 1000;
			const ethDiscountMilliBasisPts = ethers.utils.parseUnits(discountMilliBasisPts.toString(), decimals.get('USDC'));
			const value = ethers.utils.parseUnits('10.0', decimals.get('USDC'));
			
			const asset = ["asset1", "asset2"]; // Sample asset details
			const assetUri = ["uri1", "uri2"]; // Sample asset URIs
			const assetType = ["data", "data"]; // Sample asset types
			const offeringAssetId = uuidv4();
			const canShareOwn = true;
			const isMultiAccess = true;
			
			await offeringContract.connect(meriticAcct).mktListOffering(meriticAcct.address,
					  														asset, 
				  															assetUri, 
				  															assetType,
				  															value,
				  															slot.slotId,
				  															offeringAssetId,
				  															"sell",
				  															'offer description',
				  															'offer_image',
				  															'offer_properties', false, true );
				  															
			const offerToken = 1;									
			const mintTx = offeringContract.connect(meriticAcct).mint(user1.address, 
				  															slot.slotId, 
				  															value, 
				  															offeringAssetId);
				  															
				  															
			const halfValue =  ethers.utils.parseUnits('5.0', decimals.get('USDC'));
			const tx = await offeringContract.connect(user1)["transferFrom(uint256,address,uint256)"](offerToken, user2.address, halfValue);
			const numOwners = await offeringContract.numOwners(offerToken);
			expect(numOwners).to.equal(2);
		});			
		
		it("token address transfer - changes share ownership for one offering", async function () {
			const {usdc, offeringContract, cashCreditContract, registry, slot, 
						offeringFactory, decimals, meriticAcct, svcRevenueAcct, user1, user2 } = await loadFixture(deployTokenFixture);
			var discountMilliBasisPts = 3000 * 1000;
			const ethDiscountMilliBasisPts = ethers.utils.parseUnits(discountMilliBasisPts.toString(), decimals.get('USDC'));
			const value = ethers.utils.parseUnits('10.0', decimals.get('USDC'));
			
			const asset = ["asset1", "asset2"]; // Sample asset details
			const assetUri = ["uri1", "uri2"]; // Sample asset URIs
			const assetType = ["data", "data"]; // Sample asset types
			const offeringAssetId = uuidv4();
			const canShareOwn = true;
			const isMultiAccess = true;
			
			await offeringContract.connect(meriticAcct).mktListOffering(meriticAcct.address,
					  														asset, 
				  															assetUri, 
				  															assetType,
				  															value,
				  															slot.slotId,
				  															offeringAssetId,
				  															"sell",
				  															'offer description',
				  															'offer_image',
				  															'offer_properties', false, true );
				  															
			const offerToken = 1;									
			const mintTx = offeringContract.connect(meriticAcct).mint(user1.address, 
				  															slot.slotId, 
				  															value, 
				  															offeringAssetId);
				  															
			const hundredPctMilliBasisPts = 10000 * 1000							
			const oneThirdValue =  ethers.utils.parseUnits('3.33', decimals.get('USDC'));
			const tx = await offeringContract.connect(user1)["transferFrom(uint256,address,uint256)"](offerToken, user2.address, oneThirdValue);
			const ownerShip = await offeringContract.ownershipMilliBasisPts(offeringAssetId, offerToken);
			expect(ownerShip / parseFloat(hundredPctMilliBasisPts)).to.equal(0.667);
		});		
		
		
		
		it("token-token value transfer - changes share ownership for one offering", async function () {
			const {usdc, offeringContract, cashCreditContract, registry, slot, 
						offeringFactory, decimals, meriticAcct, svcRevenueAcct, user1, user2 } = await loadFixture(deployTokenFixture);
			var discountMilliBasisPts = 3000 * 1000;
			const ethDiscountMilliBasisPts = ethers.utils.parseUnits(discountMilliBasisPts.toString(), decimals.get('USDC'));
			const valueOffering1 = ethers.utils.parseUnits('10.0', decimals.get('USDC'));
			const valueOffering2 = ethers.utils.parseUnits('20.0', decimals.get('USDC'));
			
			
			const assetGroup1 = ["asset1", "asset2"]; 
			const assetGroup1Uri = ["uri1", "uri2"]; 
			const assetGroup1Type = ["data", "data"]; 
			
			const assetGroup2 = ["asset3", "asset4"]; 
			const assetGroup2Uri = ["uri3", "uri4"]; 
			const assetGroup2Type = ["data", "data"]; 
			
			const offeringAssetId1 = uuidv4();
			const offeringAssetId2 = uuidv4();
			
			const canShareOwn = true;
			const isMultiAccess = true;
			
			await offeringContract.connect(meriticAcct).mktListOffering(meriticAcct.address,
					  														assetGroup1, 
				  															assetGroup1Uri, 
				  															assetGroup1Type,
				  															valueOffering1,
				  															slot.slotId,
				  															offeringAssetId1,
				  															"sell",
				  															'offer description',
				  															'offer_image',
				  															'offer_properties', false, true );
				  															
			await offeringContract.connect(meriticAcct).mktListOffering(meriticAcct.address,
					  														assetGroup2, 
				  															assetGroup2Uri, 
				  															assetGroup2Type,
				  															valueOffering2,
				  															slot.slotId,
				  															offeringAssetId2,
				  															"sell",
				  															'offer description',
				  															'offer_image',
				  															'offer_properties', false, true );
				  															
			const offerToken1 = 1;									
			const mintTx1 = await offeringContract.connect(meriticAcct).mint(user1.address, slot.slotId, valueOffering1, offeringAssetId1);
			const offerToken2 = 2;	
			const mintTx2 = await offeringContract.connect(meriticAcct).mint(user2.address, slot.slotId, valueOffering2, offeringAssetId2);
			 															
			//const hundredPctMilliBasisPts = 10000 * 1000							
			const oneFourthValue =  ethers.utils.parseUnits('5', decimals.get('USDC'));
			const tx = await offeringContract.connect(user2)["transferFrom(uint256,uint256,uint256)"](offerToken2, offerToken1, oneFourthValue);
			const balance1 = await offeringContract["balanceOf(uint256)"](offerToken1);
			///const ownerShip = await offeringContract.ownershipMilliBasisPts(offeringAssetId, offerToken);
			expect(ethers.utils.formatUnits(balance1, decimals.get('USDC'))).to.equal('15.0');
			
		});																			
	});
	
	
});