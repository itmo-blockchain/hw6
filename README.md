# HW6 Take flashloan from Aave and use it make circular arbitrage

## Usage

First, install dependencies:

```bash
npm install
```

And specify at `.env` file your api key for Alchemy `ALCHEMY_TOKEN`

Then, run the script:

```bash
npm test
```

## Output

```bash
➜  hw6 (main) npm test

> hw6@1.0.0 test
> npx hardhat test



  BestLoserContract
BestLoserContract deployed to: 0xbf2ad38fd09F37f50f723E35dd84EEa1C282c5C9
Balance of BestLoserContract: 1000000000000000000 WGwei 

Swap event:
        Token0: 0x6b175474e89094c44da98b954eedeac495271d0f -> In: 0, Out: 1264424005225384649043
        Token1: 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2 -> In: 1000000000000000000, Out: 0
Swap event:
        Token0: 0x2260fac5e5542a773aa44fbcfedf7c193bc2c599 -> In: 0, Out: 5768110
        Token1: 0x6b175474e89094c44da98b954eedeac495271d0f -> In: 1264424005225384649043, Out: 0
Swap event:
        Token0: 0x2260fac5e5542a773aa44fbcfedf7c193bc2c599 -> In: 5768110, Out: 0
        Token1: 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2 -> In: 0, Out: 772474400413017667

Balance of BestLoserContract: 771574400413017667 WGwei

Loss: 228425599586982333 WGwei
    ✔ Should take flashloan and make tx (21779ms)


  1 passing (22s)