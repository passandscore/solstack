
all: remove install build test

.PHONY: all clean remove install build test

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"


install :; forge install foundry-rs/forge-std --no-commit && forge install openzeppelin/openzeppelin-contracts@v4.9.2 --no-commit && forge install openzeppelin/openzeppelin-contracts-upgradeable@v4.9.2 --no-commit 


build:; forge build

test :; forge test --match-path "test/*.t.sol" --fork-url $(MAINNET_RPC_URL)
