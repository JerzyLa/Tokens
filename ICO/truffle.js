// Allows us to use ES6 in our migrations and tests.
require('babel-register')

module.exports = {
  networks: {
    development: {
      host: '127.0.0.1',
      port: 8545,
      network_id: '*', // Match any network id
      gas: 6000000
    }, 
    rinkeby: {
      host: "localhost", // Connect to geth on the specified
      port: 8545,
      from: "0xc76844F091888e059a2cE74B5A7Ffd386F9187e1",
      network_id: 4,
      gas: 6000000 // Gas limit used for deploys
    }
  }
}
