default:
	$(shell vessel bin)/moc $(shell mops sources) -wasi-system-api -o suite.wasm suite.mo && wasmtime suite.wasm
	rm -f suite.wasm

test:
	find questions -type f -name 'test*.mo' -print0 | xargs -0 $(shell vessel bin)/moc $(shell mops sources) -r