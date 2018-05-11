// var MediarToken = artifacts.require("./MediarToken.sol");
 var CustomCrowdsale = artifacts.require("./CustomCrowdsale.sol");

module.exports = function(deployer) {
    deployer.deploy(CustomCrowdsale, "0xc76844F091888e059a2cE74B5A7Ffd386F9187e1", "0x1719d20c8eDa2Ec1e878708CeD69e5D322e8423c");

//    deployer.deploy(MediarToken).then(() => {
//        return deployer.deploy(MediarCrowdsale, accounts[0], MediarToken.address, 100000000000000000, 
//         4000, 1524560400, 1524571200, 
//         3000, 1524574800, 1524585600, 
//         2000, 1524589200, 1524600000,
//         1524603600, 1524686400);
//    });

   // TODO: dodać przsył tokenow
};
