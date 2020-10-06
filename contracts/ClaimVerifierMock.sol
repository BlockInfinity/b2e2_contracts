pragma solidity ^0.5.0;

import "./Commons.sol";
import "./IdentityContract.sol";
import "./IdentityContractLib.sol";
import "./ClaimCommons.sol";
import "./../dependencies/jsmnSol/contracts/JsmnSolLib.sol";
import "./../dependencies/dapp-bin/library/stringUtils.sol";
import "./../node_modules/openzeppelin-solidity/contracts/cryptography/ECDSA.sol";
import "./ClaimVerifier.sol";

library ClaimVerifierMock {
    // Constants ERC-735
    uint256 constant public ECDSA_SCHEME = 1;
    
    /**
     * Iff _requiredValidAt is not zero, only claims that are not expired at that time and are already valid at that time are considered. If it is set to zero, no expiration or starting date check is performed.
     */
    function verifyClaim(IdentityContract /*marketAuthority*/, address /*_subject*/, uint256 /*_claimId*/, uint64 /*_requiredValidAt*/, bool /*allowFutureValidity*/) public view returns(bool __valid) {
        return true;
    }
    
    function verifyClaim(IdentityContract /*marketAuthority*/, address /*_subject*/, uint256 /*_claimId*/) public view returns(bool __valid) {
        return true;
    }
    
    /**
     * This method does not verify that the given claim exists in the contract. It merely checks whether it is a valid claim.
     * 
     * Use this method before adding claims to make sure that only valid claims are added.
     */
    function validateClaim(IdentityContract /*marketAuthority*/, ClaimCommons.ClaimType /*_claimType*/, address /*_subject*/, uint256 /*_topic*/, uint256 /*_scheme*/, address /*_issuer*/, bytes memory /*_signature*/, bytes memory /*_data*/) public view returns(bool) {
        return true;
    }
    
    /**
     * Returns the claim ID of a claim of the stated type. Only valid claims are considered.
     * 
     * Iff _requiredValidAt is not zero, only claims that are not expired at that time and are already valid at that time are considered. If it is set to zero, no expiration or startig date check is performed.
     */
    function getClaimOfType(IdentityContract /*marketAuthority*/, address /*_subject*/, ClaimCommons.ClaimType /*_claimType*/, uint64 /*_requiredValidAt*/) public view returns (uint256 __claimId) {
        return 1;
    }
    
    function getClaimOfType(IdentityContract /*marketAuthority*/, address /*_subject*/, ClaimCommons.ClaimType /*_claimType*/) public view returns (uint256 __claimId) {
        return 1;
    }
    
    function getClaimOfTypeByIssuer(IdentityContract /*marketAuthority*/, address /*_subject*/, ClaimCommons.ClaimType /*_claimType*/, address /*_issuer*/, uint64 /*_requiredValidAt*/) public view returns (uint256 __claimId) {
        return 1;
    }
    
    function getClaimOfTypeByIssuer(IdentityContract /*marketAuthority*/, address /*_subject*/, ClaimCommons.ClaimType /*_claimType*/, address /*_issuer*/) public view returns (uint256 __claimId) {
        return 1;
    }
    
    function getClaimOfTypeWithMatchingField(IdentityContract /*marketAuthority*/, address /*_subject*/, ClaimCommons.ClaimType /*_claimType*/, string memory /*_fieldName*/, string memory /*_fieldContent*/, bool /*_requireNonExpired*/) public view returns (uint256 __claimId) {
        return 1;
    }
    
    function doesMatchingFieldExist(string memory /*_fieldName*/, string memory /*_fieldContent*/, bytes memory /*_data*/) internal pure returns(bool) {
        return true;
    }
    
    function getUint64Field(string memory _fieldName, bytes memory _data) public pure returns(uint64) {
        int fieldAsInt = JsmnSolLib.parseInt(getStringField(_fieldName, _data));
        require(fieldAsInt >= 0, "fieldAsInt must be greater than or equal to 0.");
        require(fieldAsInt < 0x10000000000000000, "fieldAsInt must be less than 0x10000000000000000.");
        return uint64(fieldAsInt);
    }
    
    function getUint256Field(string memory _fieldName, bytes memory _data) public pure returns(uint256) {
		if(keccak256(abi.encodePacked(_fieldName)) == keccak256(abi.encodePacked("maxGen"))) {
			return 5000000000000000000000;
		}
        int fieldAsInt = JsmnSolLib.parseInt(getStringField(_fieldName, _data));
        require(fieldAsInt >= 0, "fieldAsInt must be greater than or equal to 0.");
        return uint256(fieldAsInt);
    }
    
    function getStringField(string memory _fieldName, bytes memory _data) public pure returns(string memory) {
        string memory json = string(_data);
        (uint exitCode, JsmnSolLib.Token[] memory tokens, uint numberOfTokensFound) = JsmnSolLib.parse(json, 20);

        require(exitCode == 0, "Error in getStringField. Exit code is not 0.");
        for(uint i = 1; i < numberOfTokensFound; i += 2) {
            JsmnSolLib.Token memory keyToken = tokens[i];
            JsmnSolLib.Token memory valueToken = tokens[i+1];
            
            if(StringUtils.equal(JsmnSolLib.getBytes(json, keyToken.start, keyToken.end), _fieldName)) {
                return JsmnSolLib.getBytes(json, valueToken.start, valueToken.end);
            }
        }
        
        require(false, "_fieldName not found.");
    }
    
    function getExpiryDate(bytes memory _data) public pure returns(uint64) {
        return getUint64Field("expiryDate", _data);
    }
    
    function getStartDate(bytes memory _data) public pure returns(uint64) {
        return getUint64Field("startDate", _data);
    }
    
    function claimAttributes2SigningFormat(address _subject, uint256 _topic, bytes memory _data) internal pure returns (bytes32 __claimInSigningFormat) {
        return keccak256(abi.encodePacked(_subject, _topic, _data));
    }
    
    function getSignerAddress(bytes32 _claimInSigningFormat, bytes memory _signature) internal pure returns (address __signer) {
        return ECDSA.recover(_claimInSigningFormat, _signature);
    }
    
    function verifySignature(address /*_subject*/, uint256 /*_topic*/, uint256 /*_scheme*/, address /*_issuer*/, bytes memory /*_signature*/, bytes memory /*_data*/) public view returns (bool __valid) {
        return true;
    }
    
    // https://stackoverflow.com/a/40939341
    function isContract(address _addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(_addr) }
        return size > 0;
    }
}
