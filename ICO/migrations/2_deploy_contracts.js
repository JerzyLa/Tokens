 var CustomToken = artifacts.require("./CustomToken.sol");
 var CustomCrowdsale = artifacts.require("./CustomCrowdsale.sol");

// deploy only for ganache-cli & rinkeby
module.exports = function(deployer, network, accounts) {
   let token;
   let owner;
   let wallet;

   if(network == "development" || network == "rinkeby") {
      owner = accounts[0];
      wallet = accounts[1];
   }
   else if(network == "live") {
       // TODO: fill for live network
       // owner = 
       // wallet =
   }
   else if(network == "live") {
       // TODO add owner address owner =
   }

   deployer.deploy(CustomToken).then(() => {
       return deployer.deploy(CustomCrowdsale, wallet, CustomToken.address);
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
