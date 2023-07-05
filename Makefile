# @todo: the actor-idl path does not work, find out how dfx does it

.PHONY: check test docs

check:
	mops install
	npm install
	dfx start --clean --background
	dfx canister create --all
	dfx build godwin_token
	dfx build godwin_airdrop
	dfx build godwin_master
	dfx build godwin_sub
	dfx build godwin_clock
	dfx build scenario_sub
	dfx build scenario_airdrop
	dfx generate
	dfx build godwin_frontend

test:
	mops install
	mops test

docs:
	$(shell dfx cache show)/mo-doc