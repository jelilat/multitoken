async function main() {
    // We get the contract to deploy
    const Creator = await ethers.getContractFactory("Creator");
    const creator = await Creator.deploy();
  
    console.log("Creator deployed to:", creator.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });