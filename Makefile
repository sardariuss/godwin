.PHONY: check test docs

check:
	find src -type f -name '*.mo' -print0 | xargs -0 $(shell vessel bin)/moc $(shell mops sources) --check

all: check-strict

check-strict:
	find src/godwin_backend -type f -name '*.mo' -print0 | xargs -0 $(shell vessel bin)/moc $(shell mops sources) -Werror --check

test:
	make -C test/motoko
	make -C test/ic-repl

docs:
	$(shell vessel bin)/mo-doc