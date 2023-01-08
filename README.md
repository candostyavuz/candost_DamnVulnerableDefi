**This repo contains my attempt to complete DamnVulnerableDefi CTF as my journey to become a Solidity Security Researcher & Smart Contract Auditor.**
After completing each challenge, I will document my findings, takeaways and my mental model to exploit the target asset.

# 1- Unstoppable:
**Issue:** This is a classic DOS attack pattern that is caused by relying on two irrelevant parameters being equal.
`poolBalance` only increases when depositTokens() called, whereas actual token balance of the contract can be increased by a simple ERC20 transfer.

**My Exploit Pattern:** Just increase the balance of the contract by depositing some DVT tokens from attacker.

**Takeaway**: Contracts don't have to necessarily work exactly as developer intended. Never forget that anyone can send any asset to any address.
In that case DVT balance can be increased without calling the `depositTokens()`, causes mismatch between `poolBalance` and the actual balance.
*In the case of ETH, generally it's good to avoid relying on `address(this).balance` since it can always be manipulated by `self.destruct()`.*
