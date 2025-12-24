//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";





contract RoyaltyDistributor is AccessControl, ReentrancyGuard {
    
    bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");
    
    // The backing token (USDC, DAI, etc.)
    IERC20 public underlying;
    
    mapping(address => uint256) public claimableBalance;
    uint256 public totalUnclaimed;

    event RoyaltiesDeposited(uint256 totalAmount, uint256 recipientCount);
    event RoyaltyClaimed(address indexed user, uint256 amount);

    constructor(address underlyingAddress_, address mktAdmin_) {
        underlying = IERC20(underlyingAddress_);
        _setupRole(DEFAULT_ADMIN_ROLE, mktAdmin_);
    }

    function depositRoyalties(address[] calldata recipients, uint256[] calldata amounts) external nonReentrant {
        require(hasRole(DISTRIBUTOR_ROLE, msg.sender), "Caller not authorized to distribute");
        require(recipients.length == amounts.length, "Mismatched arrays");

        uint256 totalDeposit = 0;

        for (uint256 i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient");
            if (amounts[i] > 0) {
                claimableBalance[recipients[i]] += amounts[i];
                totalDeposit += amounts[i];
            }
        }

        if (totalDeposit > 0) {
            require(underlying.transferFrom(msg.sender, address(this), totalDeposit), "Underlying Transfer failed");
            totalUnclaimed += totalDeposit;
            emit RoyaltiesDeposited(totalDeposit, recipients.length);
        }
    }

    function claim() external nonReentrant {
        uint256 amount = claimableBalance[msg.sender];
        require(amount > 0, "No royalties to claim");

        claimableBalance[msg.sender] = 0;
        totalUnclaimed -= amount;

        require(underlying.transfer(msg.sender, amount), "Transfer failed");
        
        emit RoyaltyClaimed(msg.sender, amount);
    }
}