 var MediarToken = artifacts.require("./MediarToken.sol");
 var MediarCrowdsale = artifacts.require("./MediarCrowdsale.sol");

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

   deployer.deploy(MediarToken).then(() => {
       return deployer.deploy(MediarCrowdsale, wallet, MediarToken.address);
   }).then(() => {
       return MediarToken.deployed();
   }).then((instance) => {
       token = instance;
       return token.setTransferAgent(owner, true);
   }).then(() => {
       return token.setTransferAgent(MediarCrowdsale.address, true);
   }).then(() => {
       return token.setReleaseAgent(MediarCrowdsale.address);
   }).then(() => {
       return token.transfer(MediarCrowdsale.address, 210000000000000000000000000);
   });
};
