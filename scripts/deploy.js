const { ethers } = require("hardhat");

async function main() {
  // TODO: replace with the developer wallet address
  const devWallet = "0x000000000000000000000000000000000000dEaD";

  const Token = await ethers.getContractFactory("SHET");
  const token = await Token.deploy(devWallet);
  await token.waitForDeployment();
  console.log("SHET deployed to:", await token.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
