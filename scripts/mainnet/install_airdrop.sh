# Airdrop
export AIRDROP_AMOUNT="10_000_000_000_000_000" # 10 million
export AIRDROP_PER_USER="10_000_000_000_000" # 10_000 tokens per user, for 1000 users
export AIRDROP_ALLOW_SELF="true"

dfx canister install godwin_airdrop --argument '('${AIRDROP_PER_USER}', '${AIRDROP_ALLOW_SELF}')' --network=ic