# @todo: the actor-idl path does not work, find out how dfx does it

.PHONY: check test docs

all: check-strict

check:
	find src -type f -name '*.mo' -print0 | xargs -0 $(shell dfx cache show)/moc $(shell mops sources) \
		--check \
		--actor-alias "godwin_master" "bkyz2-fmaaa-aaaaa-qaaaq-cai" \
		--actor-alias "godwin_clock" "br5f7-7uaaa-aaaaa-qaaca-cai" \
		--actor-alias "godwin_token" "bd3sg-teaaa-aaaaa-qaaba-cai" \
		--actor-idl ".dfx/local/canisters/idl/"

check-strict:
	find src/godwin_sub -type f -name '*.mo' -print0 | xargs -0 $(shell dfx cache show)/moc $(shell mops sources) \ 
		-Werror \
		--check \
		--actor-alias "godwin_master" "bkyz2-fmaaa-aaaaa-qaaaq-cai" \
		--actor-alias "godwin_clock" "br5f7-7uaaa-aaaaa-qaaca-cai" \
		--actor-alias "godwin_token" "bd3sg-teaaa-aaaaa-qaaba-cai" \
		--actor-idl ".dfx/local/canisters/idl/" 

test:
	mops test

docs:
	$(shell dfx cache show)/mo-doc