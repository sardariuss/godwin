default:
	dfx stop
	dfx start --clean --background
	dfx canister create godwin_sub
	dfx build godwin_sub
	ic-repl test.sh