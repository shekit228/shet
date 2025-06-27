# SHET Token

This repository contains the source code for the **SHET (MEM)** ERC‑20 token.

## Features

- Standard ERC‑20 based on OpenZeppelin v5
- Owner controlled minting and burning
- Optional transaction fee that is sent to the developer wallet
- Address white/black listing
- Transaction and wallet holding limits
- Basic anti‑bot protection on launch
- Trading can be toggled on or off

## Deployment

1. Install dependencies and compile:

```bash
npm install
npm run compile
```

2. Deploy the contract (update the developer wallet address in `scripts/deploy.js`):

```bash
npm run deploy
```

The script uses Hardhat's local network by default. Use the `--network` option to deploy to other networks.

## Important Notes

- Ensure the developer wallet address is correct before deploying.
- Adjust transaction limits and fee percentages using the owner‑only functions as needed.
- After enabling trading via `toggleTrading`, the anti‑bot protection applies for the configured number of blocks.
