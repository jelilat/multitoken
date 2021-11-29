/**
 * @type import('hardhat/config').HardhatUserConfig
 */
 require('@nomiclabs/hardhat-ethers');
//  require('@openzeppelin/hardhat-upgrades');
 require("@nomiclabs/hardhat-etherscan");
 
 
 module.exports = {
   etherscan: {
     apiKey: "key"
   },
   defaultNetwork: "matic",
   networks: {
     hardhat: {
     },
     matic: {
       url: "https://polygon-mainnet.infura.io/v3/key",
       accounts: ["key"],
      //  gasPrice: 110000000000, //110 Gwei 
     }
   },
   solidity: {
     version: "0.8.9",
     settings: {
       optimizer: {
         enabled: true,
         runs: 200
       }
     }
   }
 };
 