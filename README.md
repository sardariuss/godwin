# Politiballs

## What is it?

Politiballs (previously Godwin) is an everlasting survey where you build your political profile by answering polls. For more information, read our [whitepaper](https://superb-forest-0ae.notion.site/Politiballs-whitepaper-a18ad36a1df74042a1e33bc49e81f38d).

## Requirements

dfx: https://internetcomputer.org/docs/current/developer-docs/setup/install/#installing-the-ic-sdk-1
nodejs: https://nodejs.org/en
mops: https://docs.mops.one/quick-start

## Local deployement

To deploy a functional app and start fooling around, run:
  ```./scripts/local/install-local.sh```

To create a sub and fill it with a fictive scenario, run:
  ```./scripts/local/run-scenario.sh```

## Tests

To execute the tests, run:
  ```mops test```

## Architecture

Politiballs is currently composed of the following canisters:
 - godwin_master: the main canister, it can create and manage godwin_subs
 - godwin_sub: there is one godwin_sub canister per sub created
 - godwin_clock: responsible of calling the godwin_subs run() method to update the canister states over time
 - godwin_token: icrc1 ledger used by the master and the subs
 - godwin_airdrop: canister that holds and can distribute tokens for the airdrop - not to be used in production
 - godwin_frontend: the front-end canister

## Migrations

The master and sub canisters follow use a [migration pattern](https://forum.dfinity.org/t/day-origyn-motoko-gift-1-migration-pathway/14756/9) to store the variables in stable memory and keep a record of the migrations in the code.