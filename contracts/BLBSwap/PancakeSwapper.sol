// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@pancakeswap/v3-core/contracts/interfaces/callback/IPancakeV3SwapCallback.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';


interface IwERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function balanceOf(address _owner) external view returns(uint256);
}

interface IV3Factory {
    function getPool(address token0, address token1, uint24 fee) external view returns(address);
}

interface IV3PairPool {
    struct Slot0 {
        // the current price
        uint160 sqrtPriceX96;
        // the current tick
        int24 tick;
        // the most-recently updated index of the observations array
        uint16 observationIndex;
        // the current maximum number of observations that are being stored
        uint16 observationCardinality;
        // the next maximum number of observations to store, triggered in observations.write
        uint16 observationCardinalityNext;
        // the current protocol fee for token0 and token1,
        // 2 uint32 values store in a uint32 variable (fee/PROTOCOL_FEE_DENOMINATOR)
        uint32 feeProtocol;
        // whether the pool is locked
        bool unlocked;
    }
    function slot0() external view returns(Slot0 memory);
    function token0() external view returns(address);
    function token1() external view returns(address);
}

interface IV3SwapRouter is IPancakeV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);
}

library pricer {
    
    function getPrice0(uint256 sqrtPriceX96) internal pure returns(uint256) {
        uint256 denom = ((2 ** 96) ** 2);
        denom /= 10 ** 18;
        return (sqrtPriceX96 ** 2) / denom;
    }

    function getPrice1(uint256 sqrtPriceX96) internal pure returns(uint256) {
        uint256 denom = (sqrtPriceX96 ** 2) / 10 ** 18;
        return ((2 ** 96) ** 2) / denom;
    }
}

contract PancakeSwapper {
    using pricer for uint160;

    IV3SwapRouter internal constant swapRouter = IV3SwapRouter(0x13f4EA83D0bd40E75C8222255bc855a974568Dd4);
    IV3Factory internal constant factory = IV3Factory(0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865);
    address internal constant wBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address internal constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address public BLB = 0x13D67Fd10BDBe8301E978e4AdCBD2c0AD26F7549;
    uint24 internal constant poolFee = 500;

// BLBsForBNB
    function _BLBsForBNB(uint256 amountBNB) internal view returns(uint256) {
        return amountBNB * BNB_BLB() / 10 ** 18;
    }
// BLBsForUSD
    function _BLBsForUSD(uint256 amountBUSD) internal view returns(uint256) {
        return amountBUSD * BUSD_BLB() / 10 ** 18;
    }
// BNBsforBLB
    function _BNBsForBLB(uint256 amountBLB) internal view returns(uint256) {
        return amountBLB * BLB_BNB() / 10 ** 18;
    }
// BUSD_for_BLB
    function _USDsForBLB(uint256 amountBLB) internal view returns(uint256) {
        return amountBLB * BLB_BUSD() / 10 ** 18;
    }

    function BUSD_BNB() public view returns(uint256) {
        IV3PairPool pool = IV3PairPool(factory.getPool(wBNB, BUSD, poolFee));
        (uint160 sqrtPriceX96) = pool.slot0().sqrtPriceX96;
        return pool.token0() == wBNB ? sqrtPriceX96.getPrice1() : sqrtPriceX96.getPrice0();
    }

    function BNB_BUSD() public view returns(uint256) {
        IV3PairPool pool = IV3PairPool(factory.getPool(wBNB, BUSD, poolFee));
        (uint160 sqrtPriceX96) = pool.slot0().sqrtPriceX96;
        return pool.token0() == wBNB ? sqrtPriceX96.getPrice0() : sqrtPriceX96.getPrice1();
    }

    function BLB_BUSD() public view returns(uint256) {
        IV3PairPool pool = IV3PairPool(factory.getPool(BLB, BUSD, poolFee));
        (uint160 sqrtPriceX96) = pool.slot0().sqrtPriceX96;
        return pool.token0() == BLB ? sqrtPriceX96.getPrice0() : sqrtPriceX96.getPrice1();
    }

    function BUSD_BLB() public view returns(uint256) {
        IV3PairPool pool = IV3PairPool(factory.getPool(BLB, BUSD, poolFee));
        (uint160 sqrtPriceX96) = pool.slot0().sqrtPriceX96;
        return pool.token0() == BLB ? sqrtPriceX96.getPrice1() : sqrtPriceX96.getPrice0();
    }

    function BLB_BNB() public view returns(uint256) {
        return BLB_BUSD() * BUSD_BNB() / 10 ** 18;
    }

    function BNB_BLB() public view returns(uint256) {
        return BNB_BUSD() * BUSD_BLB() / 10 ** 18;
    }


    function _purchaseBLB(
        address userAddr,
        uint256 amountBUSD,
        uint256 amountBNB
    ) internal returns(uint256 amountBLB) {


        IV3SwapRouter.ExactInputSingleParams memory params;

        if(amountBUSD == 0) {
            IwERC20 wbnb = IwERC20(wBNB);
            wbnb.deposit{value: amountBNB}();

            TransferHelper.safeApprove(wBNB, address(swapRouter), amountBNB);
            params = IV3SwapRouter.ExactInputSingleParams({
                tokenIn: wBNB,
                tokenOut: BLB,
                fee: poolFee,
                recipient: userAddr,
                amountIn: amountBNB,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        } else {
            require(amountBNB == 0, "not allowed to purchase in BUSD and BNB in sameTime");
            TransferHelper.safeTransferFrom(BUSD, userAddr, address(this), amountBUSD);
            TransferHelper.safeApprove(BUSD, address(swapRouter), amountBUSD);
            
            params = IV3SwapRouter.ExactInputSingleParams({
                tokenIn: BUSD,
                tokenOut: BLB,
                fee: poolFee,
                recipient: userAddr,
                amountIn: amountBUSD,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        }
        
        amountBLB = swapRouter.exactInputSingle(params);
    }

    function _sellBLB(
        address userAddr,
        uint256 amountBLB,
        bool toBUSD
    ) internal returns(uint256 amountOut) {

        TransferHelper.safeTransferFrom(BLB, userAddr, address(this), amountBLB);
        TransferHelper.safeApprove(BLB, address(swapRouter), amountBLB);

        if(toBUSD) {
            IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams({
                tokenIn: BLB,
                tokenOut: BUSD,
                fee: poolFee,
                recipient: userAddr,
                amountIn: amountBLB,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

            amountOut = swapRouter.exactInputSingle(params);

        } else {

            IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams({
                tokenIn: BLB,
                tokenOut: wBNB,
                fee: poolFee,
                recipient: address(this),
                amountIn: amountBLB,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

            amountOut = swapRouter.exactInputSingle(params);
            IwERC20 wbnb = IwERC20(wBNB);
            wbnb.withdraw(amountOut);
            payable(userAddr).transfer(amountOut);
        }
    }

    receive() external payable{}
}