pragma solidity ^0.5.0;

import "../node_modules/openzeppelin-solidity/contracts/cryptography/ECDSA.sol";
import "./ClaimCommons.sol";
import "./ClaimVerifier.sol";
import "./IdentityContract.sol";

library IdentityContractLib {
    // Events ERC-725
    event DataChanged(bytes32 indexed key, bytes value);
    event ContractCreated(address indexed contractAddress);
    event OwnerChanged(address indexed ownerAddress);
    
    // Events ERC-735
    event ClaimRequested(uint256 indexed claimRequestId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimAdded(uint256 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimRemoved(uint256 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    event ClaimChanged(uint256 indexed claimId, uint256 indexed topic, uint256 scheme, address indexed issuer, bytes signature, bytes data, string uri);
    
    // Structs ERC-735
    struct Claim {
        uint256 topic;
        uint256 scheme;
        address issuer; // msg.sender
        bytes signature; // this.address + topic + data
        bytes data;
        string uri;
    }
    
    // Constants ERC-735
    bytes constant public ETH_PREFIX = "\x19Ethereum Signed Message:\n32";
    uint256 constant public ECDSA_SCHEME = 1;
    
    function addClaim(mapping (uint256 => Claim) storage claims, mapping (uint256 => uint256[]) storage topics2ClaimIds, mapping (bytes => bool) storage burnedSignatures, IdentityContract marketAuthority, uint256 _topic, uint256 _scheme, address _issuer, bytes memory _signature, bytes memory _data, string memory _uri) public returns (uint256 claimRequestId) {
        require(keccak256(_signature) != keccak256(new bytes(32))); // Just to be safe. (See existence check below.)
        
        // Make sure that claim is correct if the topic is in the relevant range.
        if(_topic >= 10000 && _topic <= 11000) {
            ClaimCommons.ClaimType claimType = ClaimCommons.topic2ClaimType(_topic);
            require(ClaimVerifier.validateClaim(marketAuthority, claimType, _topic, _scheme, _issuer, _signature, _data));
        }
        
        // TODO: Addition or concatenation?
        bytes memory preimageIssuer = abi.encodePacked(_issuer);
        bytes memory preimageTopic = abi.encodePacked(_topic);
        claimRequestId = uint256(keccak256(abi.encodePacked(preimageIssuer, preimageTopic)));
        
        // Emit and modify before adding to save gas.
        if(keccak256(claims[claimRequestId].signature) != keccak256(new bytes(32))) { // Claim existence check since signature cannot be 0.
            emit ClaimAdded(claimRequestId, _topic, _scheme, _issuer, _signature, _data, _uri);
            
            uint256 prevTopicCardinality = topics2ClaimIds[_topic].length;
            topics2ClaimIds[_topic].length = prevTopicCardinality + 1;
            topics2ClaimIds[_topic][prevTopicCardinality] = claimRequestId;
        } else {
            // Make sure that only issuer or holder can change claims
            require(msg.sender == address(this) || msg.sender == _issuer);
            emit ClaimChanged(claimRequestId, _topic, _scheme, _issuer, _signature, _data, _uri);
            
            // Make sure that the old signature cannot be used again later. But do not burn the signature when adding the same claim as is currently in effect or when only changing the URI.
            if(keccak256(claims[claimRequestId].signature) != keccak256(_signature))
                burnedSignatures[_signature] = true;
        }
        
        claims[claimRequestId] = Claim(_topic, _scheme, _issuer, _signature, _data, _uri);
    }
    
    function removeClaim(address owner, mapping (uint256 => Claim) storage claims, mapping (uint256 => uint256[]) storage topics2ClaimIds, mapping (bytes => bool) storage burnedSignatures, uint256 _claimId) public returns (bool success) {
        require(msg.sender == owner || msg.sender == claims[_claimId].issuer);
        
        // Emit event and store burned signature before deleting to save gas for copy.
        IdentityContractLib.Claim storage claim = claims[_claimId];
        emit ClaimRemoved(_claimId, claim.topic, claim.scheme, claim.issuer, claim.signature, claim.data, claim.uri);
        burnedSignatures[claim.signature] = true; // Make sure that this same claim cannot be added again.

        // Delete entries of helper directories.
        // Locate entry in topics2ClaimIds.
        uint32 positionInArray = 0;
        while(positionInArray < topics2ClaimIds[claim.topic].length && _claimId != topics2ClaimIds[claim.topic][positionInArray]) {
            positionInArray++;
        }
        
        // Make sure that the element has actually been found.
        require(positionInArray < topics2ClaimIds[claim.topic].length);
        
        // Swap the last element in for it.
        topics2ClaimIds[claim.topic][positionInArray] = topics2ClaimIds[claim.topic][topics2ClaimIds[claim.topic].length - 1];
        
        // Delete the (now duplicated) last entry by shrinking the array.
        topics2ClaimIds[claim.topic].length--;
        
        // Delete the actual directory entry.
        claim.topic = 0;
        claim.scheme = 0;
        claim.issuer = address(0);
        claim.signature = "";
        claim.data = "";
        claim.uri = "";
        
        return true;
    }
    
    function claimAttributes2SigningFormat(address _subject, uint256 _topic, bytes memory _data) internal pure returns (bytes32 __claimInSigningFormat) {
        return keccak256(abi.encodePacked(_subject, _topic, _data));
    }
    
    function getSignerAddress(bytes32 _claimInSigningFormat, bytes memory _signature) internal pure returns (address __signer) {
        return ECDSA.recover(_claimInSigningFormat, _signature);
    }
    
    function verifySignature(uint256 _topic, uint256 _scheme, address _issuer, bytes memory _signature, bytes memory _data) public view returns (bool __valid) {
         // Check for currently unsupported signature.
        if(_scheme != ECDSA_SCHEME)
            return false;
        
        address signer = getSignerAddress(claimAttributes2SigningFormat(address(this), _topic, _data), _signature);
        return signer == _issuer;
    }
}