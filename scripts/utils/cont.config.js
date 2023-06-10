const { network } = require("hardhat");

const zero_address = "0x0000000000000000000000000000000000000000"

let blbAddr = zero_address
let initialAdmin = zero_address

  if(network.config.chainId == 56) {

    // const initialAdmin = "0x31FBc230BC6b8cE2eE229eCfbACCc364Da3eD7fC";
    // const initialAdmin = "0xfd4299C480dEcE1f48e514e2D3c6F38815677106";
    blbAddr = "0x13D67Fd10BDBe8301E978e4AdCBD2c0AD26F7549"

  } else if(network.config.chainId == 97) {

    blbAddr = "0xC5197e5dcEE9268EA665086Fe918872bD3Bb5318"
    initialAdmin = "0x165D9C0f0328faE2aa2222D6b366035592eDBdaC"

  } else if(network.config.chainId == 80001) {

    blbAddr = "0x8e1F21378DD47dA995bD14AFA14b5a2aBCD44d73"
    initialAdmin = "0x165D9C0f0328faE2aa2222D6b366035592eDBdaC"
  }


module.exports = {
  blbAddr,
  initialAdmin
}