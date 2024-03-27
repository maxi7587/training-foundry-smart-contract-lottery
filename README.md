# Foundry Smart Contract Lottery

## About it

Goal is to create a provably random smart contract lottery.

## What do we want it to do?

1. Users can enter by paying for a ticket
   1. The tickets fees are going to the winner during the draw
2. After X period of time, the lottery will automatically pick a winner
   1. And this will be done programatically
3. Using Chainlink VRF and Chainlink atuomation
   1. Chainlink VRF -> Randomness
   2. Chainlik automation -> Time-based trigger

## Tests

1. Write some deploy scripts
2. Write our tests
   1. Work on a local chain
   2. Forked Testnet
   3. Forked Mainnet