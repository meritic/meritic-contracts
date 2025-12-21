

//SPDX-License-Identifier: 	BUSL-1.1
pragma solidity ^0.8.9;

interface ILedgerUpdate {
    // Allows a trusted contract to notify that it sent funds for a specific slot
    function addSlotLiquidity(uint256 slotId, uint256 amount) external;
}