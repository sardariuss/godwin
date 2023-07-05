# @todo: the actor-idl path does not work, find out how dfx does it

.PHONY: check test docs

check:
	dfx start --clean --background
	dfx canister create --all
	dfx build

test:
	mops test

docs:
	$(shell dfx cache show)/mo-doc