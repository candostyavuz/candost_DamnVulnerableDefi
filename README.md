**This repo contains my attempt to complete DamnVulnerableDefi CTF as my journey to become a Solidity Security Researcher & Smart Contract Auditor.**
After completing each challenge, I will document my findings, takeaways and my mental model to exploit the target asset.

Solutions can be found in `./test` directory under the relevant challenge directory.

Attacker contracts can be found in `./contracts` directory under the relevant challenge directory.

🥷🏻 [Can Dost Yavuz](https://twitter.com/0xDost)

# 1- Unstoppable:
**Issue:** This is a classic DOS attack pattern that is caused by relying on two irrelevant parameters being equal.
`poolBalance` only increases when depositTokens() called, whereas actual token balance of the contract can be increased by a simple ERC20 transfer.

**My Exploit Pattern:** Just increase the balance of the contract by depositing some DVT tokens from attacker.

**Takeaway**: Contracts don't have to necessarily work exactly as developer intended. Never forget that anyone can send any asset to any address.
In that case DVT balance can be increased without calling the `depositTokens()`, causes mismatch between `poolBalance` and the actual balance.
*In the case of ETH, generally it's good to avoid relying on `address(this).balance` since it can always be manipulated by `self.destruct()`.*

# 2- Naive Receiver:
**Issue:** Lack of access control in FlashLoanReceiver contract makes it possible anyone to use this contract's address as the borrower in lender pool, hence forcing it to pay service fees.

**My Exploit Pattern:** An exploit can be easily carried out by using the Receiver contract's address as the borrower in the lender pool and executing a flash loan until the balance is drained due to the service fees. A naive approach is to send the flash loan transaction 10 times. A more professional approach involves deploying an Attack.sol contract, which executes the flash loan in a single transaction until the balance is completely drained.

**Takeaway:** For external / public functions, one should always remember that anyone (or everyone) can be and will be executing it on their behalf. In this case, deployer of the receiver contract should have a `tx.origin` check to see if the `flashLoan()` transaction is initialized by a authorized wallet. Also, reverting the flashLoan calls with exceptionaly high service fees might be a good idea.

# 3- Truster:
**Issue:** `TrusterLenderPool` enables making a low level call to any given `target` address with any given calldata. Since it is not a `delegatecall()` the `msg.sender` value will always be the pool contract. By using `flashLoand()` function, an attacker contract can make a low-level call to DVT ERC-20 token contract and set infinite number of allowence for itself.

**My Exploit Pattern:** I have written the attacker contract which sets allowence for itself from the pool contract by sending relevant calldata. Also, another function enables attacker to make a `transferFrom()` call to withdraw stolen funds.

**Takeaway:** Making calls to external contracts are dangerous. Trust no one. Limit your contracts with certain call types to only certain (trusted) addresses.


# 4- Side Entrance:
**Issue:** Problem here is assets acquired with `flashLoan()` can be deposited into the same contract with `deposit()` , so attacker can get free ownership of assets.

**My Exploit Pattern:** My attacker contract includes implementation of `execute()` function and it is triggered when it's called by `flashLoan()` when it's called from the attacker contract. Since all `msg.value` is sent to the `execute()` , I make the `deposit()` call to vulnerable contract. Since all balance is sent to the contract, flash loan will not revert. But as the depositor, we get the whole ownership of the loaned assets. In another function, I make the `withdraw()` call to acquire the assets.
*Note: I initially forgot to include `receive()` function into attacker contract, so it failed to withdraw assets!*  

**Takeaway:** Contract shouldn't allow `deposit()` calls made inside the `flashLoan()` calls. Generally speaking, it's good idea to limit external calls inside flash loan related functions as much as possible. *In some posts I've seen that this challenge can also be categorized as reentrancy attack, but I disagree with that. We are executing the functions only once, pass all the require checks and we don't use fallback methods to trigger consecutive calls.*  