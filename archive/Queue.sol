//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

contract Queue {
    
    
    struct Item {
	    uint256 expiry;
	    uint256 msgId;
	    bytes32 next;
	}
	
    mapping (bytes32 => Item) private queue;
    uint256  private len;

	
    Item first;
    Item last;
    
    
    function enqueue(uint256 msgId, uint256 expiryTime) public returns (bytes32) {
        require(block.timestamp < expiryTime, 'Message has expired');
        
        if(expiryTime <= first.expiry){
            first = Item({expiry: expiryTime,  msgId: msgId, next: keccak256(abi.encode(first))});
            bytes32 hash = keccak256(abi.encode(first));
            queue[hash] = first;
            len++;
            return hash;
        }else if (expiryTime > last.expiry){
            last = Item({expiry: expiryTime, msgId: msgId, next: keccak256(abi.encode(last))});
            bytes32 hash = keccak256(abi.encode(last));
            queue[hash] = last;
            len++;
            return  hash;
        }else{
            bytes32 j = first.next;
            bytes32 i = keccak256(abi.encode(first));
            uint256 nitr;
            
            while (j != bytes32(0) && nitr < len) {
                if(expiryTime < queue[j].expiry){
                    bytes32 hash = keccak256(abi.encode(queue[j]));
                    Item memory newItem =  Item({msgId: msgId, expiry: expiryTime, next:  hash});
                    bytes32 niHash = keccak256(abi.encode(newItem));
                    queue[i].next = niHash;
                    len++;
                    return  hash;
                }
                nitr++;
	        }
      
        }
        return  bytes32(0);
    }
    
    

    function dequeue() public returns (Item memory) {
        
        require(len > 0);
       	bytes32 hfirst = keccak256(abi.encode(first));
       	
        Item memory data = queue[hfirst];
        bytes32 next = data.next;
        
        delete queue[hfirst];
   
        first = queue[next]; 
        len--;
        
        return data;
    }
    
    
    function length() public view returns (uint256) {
        return len;
    }

}
