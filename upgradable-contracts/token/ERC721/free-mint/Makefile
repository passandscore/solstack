all: remove install build test

.PHONY: all clean remove install build test

clean  :; forge clean

remove :; rm -rf dependencies

install :; forge soldeer update

build:; forge build

test :; forge test --match-path "test/*.t.sol" --fork-url $(MAINNET_RPC_URL)
