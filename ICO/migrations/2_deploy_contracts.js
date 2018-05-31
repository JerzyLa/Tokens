 var MediarToken = artifacts.require("./MediarToken.sol");
 var MediarCrowdsale = artifacts.require("./MediarCrowdsale.sol");

module.exports = function(deployer, network, accounts) {
   let token;
   let owner;
   let wallet;

   if(network == "development") {
      owner = accounts[0];
      wallet = accounts[1];
   }
   if(network == "rinkeby") {
      owner = accounts[0];
      wallet = "0x70276Be6bEcF1D24670BDA1F139B30e271ADAAA2";
   }
   else if(network == "live") {
       owner = accounts[0]; 
       wallet = "0xfac4a6886ce86acefee83f6b56bf7dc39ef14d23";
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
