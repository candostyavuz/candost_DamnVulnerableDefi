**This repo contains my attempt to complete DamnVulnerableDefi CTF as my journey to become a Solidity Security Researcher & Smart Contract Auditor.**
After completing each challenge, I will document my findings, takeaways and my mental model to exploit the target asset.

Solutions can be found in `./test` directory under the relevant challenge directory.

Attacker contracts can be found in `./contracts` directory under the relevant challenge directory.

🥷🏻 [Can Dost Yavuz](https://www.linkedin.com/in/candosty/)
---

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


# 4- Side Entrance:
**Issue:** Problem here is assets acquired with `flashLoan()` can be deposited into the same contract with `deposit()` , so attacker can get free ownership of assets.

**My Exploit Pattern:** My attacker contract includes implementation of `execute()` function and it is triggered when it's called by `flashLoan()` when it's called from the attacker contract. Since all `msg.value` is sent to the `execute()` , I make the `deposit()` call to vulnerable contract. Since all balance is sent to the contract, flash loan will not revert. But as the depositor, we get the whole ownership of the loaned assets. In another function, I make the `withdraw()` call to acquire the assets.
*Note: I initially forgot to include `receive()` function into attacker contract, so it failed to withdraw assets!*  

**Takeaway:** Contract shouldn't allow `deposit()` calls made inside the `flashLoan()` calls. Generally speaking, it's good idea to limit external calls inside flash loan related functions as much as possible. *In some posts I've seen that this challenge can also be categorized as reentrancy attack, but I disagree with that. We are executing the functions only once, pass all the require checks and we don't use fallback methods to trigger consecutive calls.*  


# 5- The Rewarder:
**Issue:** 
```
Them city-folk engineers done went and made a right mess,
A vulnerability in the biz logic, nonetheless.
A contract that didn't keep tokens timely staked,
Allowing users to quickly get rich and make.
But now it's fixed, and all's back to right,
In the wild west of business, everything's tight.
```

**My Exploit Pattern:**
An attacker contract which first takes the flashloan and then triggers the `deposit()` function is enough to get most of the `accTokens` .

**Takeaway:** If a pool is doing operations based on stakes of users, then `timestamp` of each deposit operation should be recorded for the staked tokens. Otherwise, protocol would not be fair since attackers can exploit the rewards with flashloans.


# 6- Selfie:
**Issue:** This contract has a very obvious attack pattern for a level-6 challenge. Of course, the biggest vulnerability is having the `drainAllFunds` function in the pool :) . But the main vulnerability is that the governance contract doesn't check the balance deposited into contract for an account to have voting power for a proposal. Instead, it checks the snapshot of the funds which can be easily bypassed by first obtaining the tokens via `flashLoan` and triggering `snapshot` afterwards.

**My Exploit Pattern:** 
1. Trigger the `flashLoan`, get all the balance from pool.
   In the fallback function:
    - Activate `snapshot`
    - Repay the loan
2. Put new proposal into queue with call data of `drainAllFunds(address)` and address of the attacker contract
3. Retrive and store `actionId` as a future reference for execution
4. Wait for two days at least
5. Trigger execute with stored ID.
6. Withdraw stolen funds to attacker's wallet

**Takeaway:** Putting `ACTION_DELAY_IN_SECONDS` is a good idea to prevent actions paid with flashloans but using snapshot information for determining the voting power kills the whole idea. Instead, forcing users to stake funds (at least some period of time) might have prevented the issue.


# 7- Compromised:
**Issue:** Oracle Price Manipulation

**My Exploit Pattern:** After spending 45 minutes examining all the contracts, I've concluded that contracts seem fine and there's no significant exploit pattern. Then, I focused on the leaked data from the server. Notice that hex values represent ASCII characters. So converting it to string gives a value of: `MHhjNjc4ZWYxYWE0NTZkYTY1YzZmYzU4NjFkNDQ4OTJjZGZhYzBjNmM4YzI1NjBiZjBjOWZiY2RhZTJmNDczNWE5`. After another thought process, this seemed like a base64 encoded data. By encoding it, we get a 32-bytes long hex character which can be only one thing in our case: an Ethereum private key!

By using private keys of trusted oracles, we can set the NFT prices for the exchange. And here's the steps of my first 'Oracle Price Manipulation' exploit:

1. Set NFT prices to 0 by using oracle accounts
2. Attacker buys nft with lowest wei price possible (1 wei)
3. Set nft oracle price to 9990 ETH
4. Approve & sell nft to contract
5. Set nft price to initial price

Still, this exploit wouldn't be possible if there was only one oracle key leaked.

**Takeaway:** Never leak private keys. Period.


# 8- Puppet:
**Issue:** Lending pool collateral is dependent on `constant product formula` for ETH price of the token in AMM.
This is a bad idea because price of ETH can easily be manipulated by changing the amount of exchange token. The goal is draining as much ETH as possible from the exchange (by swapping with DVT tokens) so that `_computeOraclePrice()` will result in much small number. So 100K $DVT in the lending pool can be borrowed with much less ETH collateral instead of 200K $ETH.

**My Exploit Pattern:** Prior to the swap, the collateral deposit required is 200K $ETH. To lower this amount, the `_computeOraclePrice()` function, which calculates the ratio between the ETH balance and DVT token balance on the Uniswap Pair, needs to be altered.
By swapping 1000 $DVT for $ETH on the automated market maker (AMM) exchange, the required ETH collateral for borrowing all $DVT tokens is reduced to 19,6643. With an initial balance of 25 $ETH, the attacker has sufficient collateral to drain the pool.

**Takeaway:** Using the AMM price in an on-chain pool poses a high level of risk and requires a different approach. In addition to the lack of liquidity, if the pool has higher liquidity, it could be vulnerable to a flash loan attack, resulting in similar negative outcomes.