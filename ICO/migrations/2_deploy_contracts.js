var FixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");
var Crowdsale = artifacts.require("./Crowdsale.sol");

module.exports = function(deployer) {
  deployer.deploy(FixedSupplyToken).then(instance => {
    deployer.link(FixedSupplyToken, Crowdsale);
    deployer.deploy(
      Crowdsale,
      instance.address,
      0.00125,      // price in ether
      1525132800,   // start time timestamp
      60,           // duration in minutes
      0.0025,       
      1525219200,   
      60,           
      0.005,         
      1525305600,
      60,
      0.01,
      1525392000,
      60
    );
  });
};
