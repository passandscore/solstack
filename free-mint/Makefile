
all: remove install build
# all:  install build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"


install :; forge install foundry-rs/forge-std --no-commit && forge install openzeppelin/openzeppelin-contracts@4.9.2 --no-commit && forge install openzeppelin/openzeppelin-contracts-upgradeable@4.9.2 --no-commit 

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test --match-path "test/*.t.sol" --fork-url $MAINNET_RPC_URL 
