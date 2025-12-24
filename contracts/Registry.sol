//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Service.sol";
import "./util/Util.sol";

interface IServiceAdmin {
    function contractAdmin() external view returns (address);
}


contract Registry is AccessControl {

    
    bytes32 public constant MKT_ARBITRATOR_ROLE = keccak256("MKT_ARBITRATOR_ROLE");
    bytes32 public constant MKT_ADMIN_ROLE = keccak256("MKT_ADMIN_ROLE");
    
    enum SlotType {contract_, network_, networkRevShare_}
    enum CreditType {time_, cash_, counts_, priority_}
    
    struct Slot {
    	address creator;
        uint256 slotId;
        string name;
        string description;
        string slotURI;
        string valueCurrency;
        address underlyingContract;
        uint valueDecimals;
        SlotType slotType;
        bool joinByInvite;
        bool isValid;
    }
    
    
  	struct UserInfo {
        address userAddress;
        string metadataUri;
    }

	Util private _util;
	
    string [] private _underlyingCurrency = ['usdc'];
    address public underlyingContractAddress = 0x873D813190b60193E229262d3376652C2E06F94f;
    
	mapping(uint256 => address[]) private _poolMembers;
	mapping(uint256 => mapping(address => bool)) private _isPoolMember;
	
	
	mapping(address => CreditType) private _contractType;
	
	
	mapping(address => bool) private _registeredContracts;
	
    
    mapping(address => string) private _userInfo;
    address[] private _users;  
    
    
    mapping(uint256 => Slot) private _slotRegistry;  
	uint256[] private _slotIds;  
    mapping(address => mapping(uint256 => uint256)) private _contractTokenSlot;
    
    mapping(uint256 => mapping(address => bool)) public _isSlotAdmin;
  	mapping(uint256 => mapping(address => address)) private _invited;
  	
    mapping(bytes32 => uint256) internal  _assetOffering;
    
    string private _baseuri;    
    
    uint256 internal _discountDecimals = 18;
    
    event NewSlot(uint256 slotId, string slotName);
    
    
    constructor(address utilContract_) {
       	_setupRole(MKT_ARBITRATOR_ROLE, msg.sender);
       	_setupRole(MKT_ADMIN_ROLE, msg.sender);
       	_util = Util(utilContract_);
 
    }
    
    function isRegisteredContract(address contract_) external view returns (bool) {
        return _registeredContracts[contract_];
    }
    
    
    function slot(uint256 slot_) public view returns (Slot memory) {
        return _slotRegistry[slot_];
    }
    
    
    
    
    function setUserInfo(string memory _metadataUri) public {

        require(bytes(_metadataUri).length != 0, "metadataUri argument cannot be empty");
        if(bytes(_userInfo[msg.sender]).length == 0){
            _userInfo[msg.sender] = _metadataUri;
        	_users.push(msg.sender);
        }else if(bytes(_userInfo[msg.sender]).length != 0){
            _userInfo[msg.sender] = _metadataUri;
        }
    }
    
    function setUserInfoForUser(address _user, string memory _metadataUri) public {
        require(_user != address(0), 'User address cannot be zero address');
		require(hasRole(MKT_ADMIN_ROLE, msg.sender), 'Sender not authorized');
        require(bytes(_metadataUri).length != 0, "metadataUri argument cannot be empty");
        
        if(bytes(_userInfo[_user]).length == 0){
            _userInfo[_user] = _metadataUri;
        	_users.push(_user);
        }else if(bytes(_userInfo[_user]).length != 0){
            _userInfo[_user] = _metadataUri;
        }
    }
    
    
    function userInfo(address user_) public view returns (string memory) {
        return _userInfo[user_];
    }
    
    
    function allUserInfo() public view returns (UserInfo[] memory) {
        
        UserInfo[] memory uinfo = new UserInfo[](_users.length);
        
        for (uint256 i = 0; i < _users.length; i++) {
            uinfo[i] = UserInfo({ userAddress: _users[i], metadataUri: _userInfo[_users[i]] });        
        }
        return uinfo;
    }
    
    
    function userAddresses() public view returns (address[] memory) {
        /*address[] memory user = new address[](_users.length);
        for (uint256 i = 0; i < _users.length; i++) {
            user[i] = _users[i];
        }*/
        return _users;
    }
    
    
    function registerContract(address adminAddress_, uint256 slot_, CreditType type_) external {
        require(_isSlotAdmin[slot_][adminAddress_], "Contract admin is not authorized to register to this slot");
        require(tx.origin != msg.sender, "Caller not a contract");
        
        
        if(!_isPoolMember[slot_][msg.sender]){
            _poolMembers[slot_].push(msg.sender);
            _isPoolMember[slot_][msg.sender] = true;
        }
		
		
        _contractType[msg.sender] = type_;
        _registeredContracts[msg.sender] = true;
    }
    
    
    function poolMembers(uint256 slotId_) public view returns (address[] memory) {
        return _poolMembers[slotId_];
    }
    
    
    function isPoolMember(uint256 slotId_, address user_) public view returns(bool) {
        return _isPoolMember[slotId_][user_];
    }
    
    
    
    function slotInvite(uint256 slot_,  address invitee_)external {
        require(_slotRegistry[slot_].isValid, "Slot does not exist");
        require(_isSlotAdmin[slot_][msg.sender], "Sender not authorized to invite to this slot");
        
        _invited[slot_][invitee_] = msg.sender;
        
    }
   
   function joinSlot(uint256 slot_) external {
       
       require(_slotRegistry[slot_].isValid, "Slot does not exist");
       
       if(_slotRegistry[slot_].joinByInvite){
           require(_invited[slot_][msg.sender] != address(0), "Sender not invited to join");
       }
       
       if(!_isPoolMember[slot_][msg.sender]){
            _poolMembers[slot_].push(msg.sender);
            _isPoolMember[slot_][msg.sender] = true;
       }
   }
   
   
   function approveContractForSlot(address contract_, uint256 slotId_) public  {
        require(_isSlotAdmin[slotId_][msg.sender], "Sender not authorized to approve on this slot");
        
        address contractAdmin_ = IServiceAdmin(contract_).contractAdmin();
        _isSlotAdmin[slotId_][contractAdmin_] = true;
        
        // emit event notfying approvial
    }
    
    function registerTokenSlot(uint256 tokenId_, uint256 slotId_) external {
        require(_isPoolMember[slotId_][msg.sender], 'Sender not authorized');
        _contractTokenSlot[msg.sender][tokenId_] = slotId_;
    }
    
    
    function slotOf(address contract_, uint256 tokenId_) public view returns (uint256) {
        
        return _contractTokenSlot[contract_][tokenId_];
    }
   
   
    function registerSlot(address ctrctSvcAdminAdress_, 
        address underlyingContractAddress_, string memory valueCurrency_, 
        uint256 slotId_, 
        string memory slotName_,  
        string memory slotURI_, 
        string memory description_, 
        uint8 type_, uint8 valueDecimals_, 
        bool joinByInviteOnly_) external returns (bool){
        
        require(hasRole(MKT_ARBITRATOR_ROLE, msg.sender), 'Sender not authorized to register this slot');
        require(!_slotRegistry[slotId_].isValid, 'Pool with SlotId already exists');
        
        SlotType stype;
        
        if(type_ == 0){
            stype = SlotType.contract_;
        }
		
	
		_slotRegistry[slotId_] = Slot({
								    creator: ctrctSvcAdminAdress_,
						        	slotId: slotId_,
						        	name: slotName_,
						        	description: description_,
						    		underlyingContract: underlyingContractAddress_,
						    		valueCurrency: valueCurrency_,
						    		valueDecimals: valueDecimals_,
						    		slotURI: slotURI_,
						    		slotType: stype,
						        	joinByInvite: joinByInviteOnly_,
						        	isValid: true
								});
		_slotIds.push(slotId_);
		
			
		_isPoolMember[slotId_][ctrctSvcAdminAdress_] = true;
		_poolMembers[slotId_].push(ctrctSvcAdminAdress_);
		
		
		
        _isSlotAdmin[slotId_][ctrctSvcAdminAdress_] = true;
        _registeredContracts[ctrctSvcAdminAdress_] = true;
        
        
        emit NewSlot(_slotRegistry[slotId_].slotId, _slotRegistry[slotId_].name);
        
        return _isSlotAdmin[slotId_][ctrctSvcAdminAdress_];
    }
    
    
    
    
    
    function isSlotAdmin(uint256 slotId_, address user_) public view returns (bool) {
        return _isSlotAdmin[slotId_][user_];
    }
    
    
    
    
    function setIsAdmin(uint256 slotId_, address admin_, bool value) public  {
        require(_slotRegistry[slotId_].isValid, "Slot does not exist");
        
       if(_slotRegistry[slotId_].joinByInvite){
           require(_invited[slotId_][admin_] != address(0), "Sender not invited to join");
       }
       _isSlotAdmin[slotId_][admin_] = value;
    }
   	
   	
   	
   	
   	function pools() public view returns (Slot[] memory) {
   	    
   	    Slot[] memory slots = new Slot[]( _slotIds.length);
   	    for (uint256 i = 0; i < _slotIds.length; i++) {
            slots[i] = _slotRegistry[_slotIds[i]];
        }
        return slots;
   	}
   	
    
    function contractType(address contractAddress_) public view returns (CreditType) {
        return _contractType[contractAddress_];
    }
    
    
    function setAssetOffering(bytes32 assetIdBytes, uint256 offeringId) public{
        _assetOffering[assetIdBytes] = offeringId;
    }
    
    function assetOffering(bytes32 assetIdBytes) public view returns (uint256) {
        return _assetOffering[assetIdBytes];
    }

 
    function isApprovedCurrency(string memory symbol_) public view returns (bool) {
	    for (uint i = 0; i < _underlyingCurrency.length; i++) {
	        if(keccak256(bytes(_underlyingCurrency[i])) == keccak256(bytes(_util.strToLower(symbol_)))) {
	        	return true;
	  		}
	    }
	
	    return false;
	}
	
	
	function hasAccess(string memory role_, address addr) public view returns (bool) {
	    if(keccak256(bytes(role_)) == keccak256(bytes('MKT_ADMIN'))){
	        return hasRole(MKT_ADMIN_ROLE, addr);
	    }
	    return false;
	}
	
}