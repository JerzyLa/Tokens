 var CustomToken = artifacts.require("./CustomToken.sol");
 var CustomCrowdsale = artifacts.require("./CustomCrowdsale.sol");

// deploy only for ganache-cli & rinkeby
module.exports = function(deployer, network, accounts) {
   let token;
   let owner = accounts[0]; 

   if(network == "rinkeby") {
       owner = "0xc76844F091888e059a2cE74B5A7Ffd386F9187e1";
   }

   deployer.deploy(CustomToken).then(() => {
       return deployer.deploy(CustomCrowdsale, owner, CustomToken.address);
   }).then(() => {
       return CustomToken.deployed();
   }).then((instance) => {
       token = instance;
       return token.setTransferAgent(owner, true);
   }).then(() => {
       return token.setTransferAgent(CustomCrowdsale.address, true);
   }).then(() => {
       return token.setReleaseAgent(CustomCrowdsale.address);
   }).then(() => {
       return token.transfer(CustomCrowdsale.address, 210000000000000000000000000);
   });
};

// TODO: deploy to main net