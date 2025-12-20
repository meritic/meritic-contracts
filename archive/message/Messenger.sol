//SPDX-License-Identifier: 	BUSL-1.1
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../Registry.sol";
import "../Pool.sol";
import "../Offering.sol";
import "../underlying/TestUSDC.sol";
import "../util/Util.sol";
import "../util/Queue.sol";




contract Messenger is AccessControl {
    
    bytes32 public constant MKT_ADMIN_ROLE = keccak256("MKT_ADMIN_ROLE");
    using Strings for address;
    using Strings for uint256;
    
    Registry internal _registry;
    Pool internal _pool;
    Util internal _util;
    
    
    ERC20 internal _usdc;
    //address internal _underlyingContractAddress = 0x14F137110c3Bb7c44CefCBcF2e96C46A6ADCfb8B;
    
    
   
    // enum MsgType {simple_, comment_, like_,  dislike_, tip_, consumed_, refund_, request_, offer_}

    struct Message {
        uint256 messageId;
        bool isPoolMsg;
        address sender;     
        address recipient;  
        Offering.ActionType msgType;
        uint256 replyTo;
       	uint256 slotId;
       	uint256 seqId;
        string content;     
        uint256 timestamp;  
        bool isRead;   
        bool isAccepted;  
        bool isExpired;  
    }
    
	struct PoolAesKey {
        string aesKey;
        string aesIv;
    }
    
    struct RsaKeys {
        string pub;
        string priv;
    }
    
    struct MsgUserInfo {
        address userAddress;
        string metadataUri;
        string rsaPubKey;
    }
    
    mapping(uint256 => uint256) private _msgExpiryTime;  
    Queue private _unexpMessageQ;
    
    mapping(uint256 => uint256) private _msgValueLocked;  
    
    mapping(address => uint256) private _msgFloorValue;  
    
    
    mapping(uint256 => PoolAesKey) private _poolAes;  
    mapping(address => string) private _privateKeys;
    mapping(address => string) public _publicKeys;
    
    
    

    // Event to emit when a new public key is set
    event PublicKeySet(address indexed userAddress, string publicKey);

    mapping(uint256 => Message) internal msgStore; 
    
    mapping(address => uint256[]) userMessages;
    mapping(address => uint256[]) accetComments;
    
    uint256 private _msgIdGenerator;

    // Event to emit when a new message is sent
    event MessageSent(address indexed sender, address indexed recipient, string content);



	constructor(address regContract_, address poolContract_, address utilContract_, address queueContract_){
	    _setupRole(MKT_ADMIN_ROLE, msg.sender);
	    _registry = Registry(regContract_); 
	    _pool = Pool(poolContract_);
	    _util = Util(utilContract_);
	    _usdc = ERC20(_registry.underlyingContractAddress());
	    _unexpMessageQ = Queue(queueContract_);
	    _msgIdGenerator = 1;
	}



    
    // Function to generate and set the private key for a user
    function setPrivateKey(string memory _privateKey) public {
        _privateKeys[msg.sender] = _privateKey;
    }
    
    // Function to generate and set the public key for a user
    function setPublicKey(string memory _publicKey) public {
        _publicKeys[msg.sender] = _publicKey;
        emit PublicKeySet(msg.sender, _publicKey);
    }
    
    
    function setKeys(string memory _publicKey, string memory _privateKey) public {
        setPrivateKey(_privateKey);
        setPublicKey(_publicKey);
    }
    
    function setKeysForUser(address _user, string memory _publicKey, string memory _privateKey) public {
        require(_user != address(0), 'User address cannot be zero address');
        require(hasRole(MKT_ADMIN_ROLE, msg.sender), 'Sender not authorized');
        
        _privateKeys[_user] = _privateKey;
		_publicKeys[_user] = _publicKey;
    	emit PublicKeySet(_user, _publicKey);
    }
    
    
    function rsaKeys() public view returns (RsaKeys memory) {
        
        RsaKeys memory userKeys = RsaKeys({pub: _publicKeys[msg.sender], priv: _privateKeys[msg.sender] });

        return userKeys;
    }
    
    
    
    function allMsgUserInfo() public view returns (MsgUserInfo[] memory){ 
        address[] memory addresses = _registry.userAddresses();
        MsgUserInfo[] memory uinfo = msgUserInfo(addresses);
        return uinfo;
    }
    
    
    
    
    function msgUserInfo(address[] memory users_) public view returns (MsgUserInfo[] memory){
        
        MsgUserInfo[] memory uinfo = new MsgUserInfo[](users_.length);
        
        for(uint256 i = 0; i < users_.length; ++i){
            string memory metadataUri = _registry.userInfo(users_[i]);
            uinfo[i] = MsgUserInfo({ userAddress: users_[i], metadataUri: metadataUri, rsaPubKey: _publicKeys[users_[i]] });
        }
        
        return uinfo;
    }
    
    
    
    function setDMFloorValue(uint256 floor_, string memory currency_) public {
        require(_registry.isApprovedCurrency(currency_), "Currency is not approved");
        _msgFloorValue[msg.sender] = floor_;
    }
    
    
    
    
    
    function lockUsdc(uint256 slotId_, uint256 amount_) public {

        require(amount_ > 0, "amount should be > 0");
        require(_registry.slot(slotId_).isValid, "Pool not valid");
        
        _usdc.transferFrom(msg.sender, address(this), amount_);
        _pool.addUnderlying(msg.sender, slotId_, amount_);
    }
    
    
    function allowance() public view returns (uint256) {
        return _usdc.allowance(msg.sender, address(this));
    }
    
    
    function contractAddress() public view returns (address) {
        return address(this);
    }
    
    
    
    
    
    
    function sendValuedMessage(address recipient_, string memory content_, string memory msgType_, 
        								uint256 seqId_, uint256 value_, string memory currency_,
        								uint256 msgExpiryTime_, uint256 valueUnlockTime_) public {
        								    
        require(_registry.isApprovedCurrency(currency_), "Currency is not approved");
        require(_msgFloorValue[msg.sender] <= value_, "Value below floor price");

        lockUsdc(1, value_);
        
        uint256 msgId = sendMessage(recipient_, content_, msgType_, seqId_, msgExpiryTime_, valueUnlockTime_);
        _msgValueLocked[msgId] = value_;
  
    }
    
    
    
    function getMessageType(string memory msgType_) internal view returns (Offering.ActionType) {
        
        if(keccak256(bytes('simmsg')) == keccak256(bytes(_util.strToLower(msgType_)))) {
            return Offering.ActionType.simmsg_;
        }else if(keccak256(bytes('tip')) == keccak256(bytes(_util.strToLower(msgType_)))) {
            return Offering.ActionType.tip_;
        }else if(keccak256(bytes('request')) == keccak256(bytes(_util.strToLower(msgType_)))) {
            return Offering.ActionType.request_;
        }else if(keccak256(bytes('offer')) == keccak256(bytes(_util.strToLower(msgType_)))) {
            return Offering.ActionType.offer_;
        }else if(keccak256(bytes('refund')) == keccak256(bytes(_util.strToLower(msgType_)))) {
            return Offering.ActionType.refund_;
        }else{
            revert("Unrecognized message type");
        }
    }
    
    
    
    function sendMessage(address recipient_, string memory content_,  
        			string memory msgType_, uint256 seqId_,  uint256 expiryTime_, uint256 valueUnlockTime_) public returns (uint256) {
        
        Offering.ActionType mtype = getMessageType(msgType_);
        uint256 msgId = _createMsgId();
        
        msgStore[msgId].sender = msg.sender;
        msgStore[msgId].recipient = recipient_;
        msgStore[msgId].content = content_;
        msgStore[msgId].seqId = seqId_;
        msgStore[msgId].msgType = mtype;
        msgStore[msgId].timestamp =  block.timestamp;
        msgStore[msgId].isRead = false;
        msgStore[msgId].isAccepted = false;
        msgStore[msgId].messageId = msgId;
        
        if(mtype == Offering.ActionType.request_ || mtype == Offering.ActionType.offer_){
            msgStore[msgId].isExpired = false;
            _unexpMessageQ.enqueue(msgId, expiryTime_);
        }else{
            msgStore[msgId].isExpired = true;
        }
        _msgExpiryTime[msgId] = expiryTime_;
        
        
        userMessages[msg.sender].push(msgId);
        userMessages[recipient_].push(msgId);


        emit MessageSent(msg.sender, recipient_, content_);
        
        return msgId;
    }
    
    
    
    
    function unlockRejectedFunds(uint256 msgId) public {
        Message memory m = msgStore[msgId];
       	require(m.sender != address(0), 'Message not found');
       	
       	address valueOwner = m.sender;
       	uint256 amount = _msgValueLocked[msgId];

     
       	_usdc.transferFrom(address(this), valueOwner, amount);
       	
    }
    
    

    function postComment(address offeringContract_, address sender_, address recipient_, 
        				 string memory  offeringAssetId_, uint256 replyTo_, uint256 slotId_,  
        					string memory content_, string memory msgType_) public {
        
        Offering.ActionType mtype = getMessageType(msgType_);
      
		uint256 msgId = _createMsgId();
		msgStore[msgId].replyTo = replyTo_;
		msgStore[msgId].isPoolMsg = true;
		msgStore[msgId].slotId = slotId_;
		msgStore[msgId].sender = sender_;
		msgStore[msgId].msgType = mtype;
		msgStore[msgId].recipient = recipient_;
		msgStore[msgId].content = content_;
		msgStore[msgId].timestamp = block.timestamp;
		msgStore[msgId].messageId = msgId;
		
		
		userMessages[sender_].push(msgId);
		userMessages[recipient_].push(msgId);
		

		Offering(offeringContract_).addUserAction(offeringAssetId_, msgId,  mtype);

    }
    
    
    function readComments(address offeringContract_, string memory assetId_) public view returns (Message[] memory) {
       Offering.UserAction[] memory interactions =  Offering(offeringContract_).getAssetUserActions(assetId_);
       Message[] memory comments = new Message[](interactions.length);
       
       for(uint8 i=0; i < interactions.length; ++i){
           comments[i] = msgStore[interactions[i].messageId];
       }
       return comments;
    }
    
    function sendPoolMessage(address sender_, uint256 slotId_,  string memory content_, string memory msgType_, uint256 seqId_) public {
        
        Offering.ActionType mtype = getMessageType(msgType_);
        address[] memory members = _registry.poolMembers(slotId_);
        
        for (uint256 i = 0; i < members.length; i++) {
            /*Message memory m = Message({
						            isPoolMsg: true,
						            slotId: slotId_,
						            sender: sender_,
						            msgType: mtype,
						            seqId: seqId_,
						            recipient: address(0),
						            content: content_,
						            timestamp: block.timestamp,
						            isRead: false,
						            isAccepted: false,
						            isExpired: false
						        });
        
            m.recipient = members[i];*/
            
            uint256 msgId = _createMsgId();
            msgStore[msgId].isPoolMsg = true;
      		msgStore[msgId].slotId = slotId_;
      		msgStore[msgId].sender = sender_;
      		msgStore[msgId].msgType = mtype;
      		msgStore[msgId].seqId = seqId_;
      		msgStore[msgId].recipient = members[i];
      		msgStore[msgId].content = content_;
      		msgStore[msgId].timestamp = block.timestamp;
      		
      		
      		userMessages[sender_].push(msgId);
            userMessages[members[i]].push(msgId);
        }
    }
    
    
    
    function userMsgCount() public view returns (uint256) {
        uint256[] memory msgIds = userMessages[msg.sender];
        return msgIds.length;
    }
    
    
    
    
    
    function getMyMessages() public view returns (Message[] memory) {
        uint256[] memory msgIds = userMessages[msg.sender];
        Message[] memory myMsgs = new Message[](msgIds.length);
        
        
        for(uint256 i = 0; i < msgIds.length; i++) {
            uint256 msgId = msgIds[i];
            /*if(!msgStore[msgId].isExpired && (block.timestamp > _msgExpiryTime[msgId])){
                msgStore[msgId].isExpired = true;
            }*/
            
            myMsgs[i] = msgStore[msgIds[i]];
        }
        
        return myMsgs;
    }
    
    
    
    
    function getMyMessagesWithParty(address party) public view returns (Message[] memory) {
        
        uint256[] memory msgIds = userMessages[msg.sender];
     
        
        uint256 msgCount = 0;
        for (uint256 i=0; i < msgIds.length; i++) {
            if(msgStore[msgIds[i]].sender == party || msgStore[msgIds[i]].recipient == party){
                msgCount++;
            }
        }
        
        Message[] memory myMsgs = new Message[](msgCount);
        uint256 j=0;
        
        for (uint256 i=0; i < msgIds.length; i++) {
            if(msgStore[msgIds[i]].sender == party || msgStore[msgIds[i]].recipient == party){
                myMsgs[j++] = msgStore[msgIds[i]];
            }
        }
    
        return myMsgs;
    }

    // Function to update the status of a message to "read"
    function markAsRead(uint256 _messageIndex) public {
        require(_messageIndex < userMessages[msg.sender].length, "Invalid message index");
        msgStore[_messageIndex].isRead = true;
    }
    
    
    function poolAes(uint256 slotId_) public view returns (PoolAesKey memory) {
        require(_registry.isPoolMember(slotId_, msg.sender), 'Sender not authorized');
        return _poolAes[slotId_];
    }
    
    
    function setPoolAesForOwner(address ownerAddress, uint256 slotId_, string memory aesKey_, string memory aesIv_) public {
        
        Registry.Slot memory slot = _registry.slot(slotId_);
        require((slot.creator == ownerAddress) || hasRole(MKT_ADMIN_ROLE, msg.sender), 'Sender not authorized');
        
	    _poolAes[slotId_] = PoolAesKey({ aesKey: aesKey_, aesIv: aesIv_ });
    }
    
    function setPoolAes(uint256 slotId_, string memory aesKey_, string memory aesIv_) public {
        
        Registry.Slot memory slot = _registry.slot(slotId_);
        require((slot.creator == msg.sender) || hasRole(MKT_ADMIN_ROLE, msg.sender), 'Sender not authorized');
        
	    _poolAes[slotId_] = PoolAesKey({ aesKey: aesKey_, aesIv: aesIv_ });
    }
    
    
    
    
    function poolAesKeys(uint256[] memory slotId_) public view returns (PoolAesKey[] memory) {
        PoolAesKey[] memory keys = new PoolAesKey[](slotId_.length);
        
        for (uint256 i = 0; i < slotId_.length; i++) {
            require(_registry.isPoolMember(slotId_[i], msg.sender), 'Sender not authorized');
            keys[i] = _poolAes[slotId_[i]];
        }
        
        return keys;
    }
    
    
    
    
    
    
    function _createMsgId() internal virtual returns (uint256) {
        return _msgIdGenerator++;
    }
}