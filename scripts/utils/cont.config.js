const { network } = require("hardhat");

const zero_address = "0x0000000000000000000000000000000000000000"

let blbAddr = zero_address
let initialAdmin = zero_address
let busdAddr = zero_address
let blbIoAddr = zero_address
let stakingAddr = zero_address
let aggrAddr = zero_address

  if(network.config.chainId == 56) {

    initialAdmin = "0x31FBc230BC6b8cE2eE229eCfbACCc364Da3eD7fC";
    // const initialAdmin = "0xfd4299C480dEcE1f48e514e2D3c6F38815677106";
    busdAddr = "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56"
    aggrAddr = "0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE"
    blbAddr = "0x13D67Fd10BDBe8301E978e4AdCBD2c0AD26F7549"
    blbIoAddr = "0xF3516758a3D6Ac6d9182e86b069BCac132e0D790"

  } else if(network.config.chainId == 97) {
    
    initialAdmin = "0x165D9C0f0328faE2aa2222D6b366035592eDBdaC"
    busdAddr = "0x87cdBfc8531CE5C6f2f07abD0E6E46D06467BA0D"
    aggrAddr = "0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526"
    blbAddr = "0x31b900DBb288A1FC9BF131a880caA294A9eeAA46"
    blbIoAddr = "0x9bb8F0C78fFfd32C416955A37588b92a2F5f5de1"
    stakingAddr = "0x23C96CAD1f14f3FED4B382547d0c90D8e989bFa1"

  } else if(network.config.chainId == 80001) {
    blbAddr = "0x8e1F21378DD47dA995bD14AFA14b5a2aBCD44d73"
    initialAdmin = "0x165D9C0f0328faE2aa2222D6b366035592eDBdaC"
  } else {
    blbAddr = "0x8e1F21378DD47dA995bD14AFA14b5a2aBCD44d73"
    initialAdmin = "0x165D9C0f0328faE2aa2222D6b366035592eDBdaC"
  }


module.exports = {
  initialAdmin,
  busdAddr,
  aggrAddr,
  blbAddr,
  blbIoAddr,
  stakingAddr,
}