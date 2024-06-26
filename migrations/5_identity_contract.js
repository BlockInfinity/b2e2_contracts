const IdentityContractLib = artifacts.require('IdentityContractLib');

const marketAuthority = artifacts.require('IdentityContract');

module.exports = function(deployer, network, accounts) {
    deployer.link(IdentityContractLib, marketAuthority);
    deployer.deploy(marketAuthority, '0x0000000000000000000000000000000000000000', [900, 1, 3*30*24*3600], accounts[0]);
};

