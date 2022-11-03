default:
	dfx stop
	dfx start --clean --background
	dfx canister create godwin_backend
	dfx build godwin_backend
	ic-repl test.sh