default:
	$(shell vessel bin)/moc $(shell mops sources) -wasi-system-api -o suite.wasm suite.mo && wasmtime suite.wasm
	rm -f suite.wasm

test:
	$(shell vessel bin)/moc $(shell mops sources) -r suite.mo