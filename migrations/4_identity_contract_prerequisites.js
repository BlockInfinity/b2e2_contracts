const Commons = artifacts.require('Commons');
const ClaimCommons = artifacts.require('ClaimCommons');
const ClaimVerifier = artifacts.require('ClaimVerifier');

const IdentityContractLib = artifacts.require('IdentityContractLib');

module.exports = function(deployer) {
    deployer.link(Commons, IdentityContractLib);
    deployer.link(ClaimCommons, IdentityContractLib);
    deployer.link(ClaimVerifier, IdentityContractLib);
    deployer.deploy(IdentityContractLib);
};

