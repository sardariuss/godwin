default:
	$(shell vessel bin)/moc $(shell vessel sources) -wasi-system-api -o testCategories.wasm testCategories.mo && wasmtime testCategories.wasm
	rm -f testCategories.wasm
