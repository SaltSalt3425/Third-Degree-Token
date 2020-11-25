## Third-Degree-Token(TDT) Token

The TDT(Third-Degree-Token) token contract is derived from the standard ERC20 token contract, so it has all the features of the ERC20 contract, but it also has a few other special feature:

1. TDT is a deflationary token, when users transfer tokens, it will burn some extra tokens and charge some fee, the rules are as follows:
   - When `7000 < total supply <= 10000`, the fee of burning is 3% and the fee of the transaction is 7%;

   - When `4000 < total supply <= 7000`, the fee of burning is 6% and the fee of the transaction is 14%;

   - When `300 < total supply <= 4000`, the fee of burning is 9% and the fee of the transaction is 21%;

   - When `total supply <= 300`, there is no fee when burning, and the fee of the transaction is 3%;
