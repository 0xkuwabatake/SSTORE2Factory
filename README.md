# SSTORE2Factory

## SSTORE2 Brief Introduction
> SSTORE2 is a set of Solidity libraries for writing and reading contract storage paying a fraction of the cost, it uses contract code as storage, writing data takes the form of contract creations and reading, data use EXTCODECOPY.

> So what this means is that instead of storing data in the contract storage, which is the more conventional and costly way, SSTORE2 allows us to pass data as a contract’s bytecode using the CREATE opcode and read the data through EXTCODECOPY.

Check out [this article](https://mirror.xyz/0x53478A49d7c16D85082659BCE9EDba5a6FBFd1Cf/_DIgJiM0_ETNuAUOq77wklNJ-L6GHlBcvVrm2_jNvKo) to get better understanding about SSTORE2.

## About
A repository for a factory contract to deploy any arbitrary data (bytes) into a contract's bytecode using various methods by utilizing [SSTORE2 library from Solady](https://github.com/Vectorized/solady/blob/main/src/utils/SSTORE2.sol).

## Purpose
The main purpose of this factory contract is to get the storage contract address or `pointer` from each `data` either with or without `salt` that been deployed as storage contract and then store its value at another contract independently from this contract.

Therefore, neither storage provided by this contract to store the `pointer` nor a tracker to track if a `pointer` from a `data` either with or without `salt` had been deployed or not, instead its value with its `index` are queryable via emitted `{Pointer}` event from each successful transaction.

## Deployed Contract

| Chain           | Address                                                                                                               |
| ----------------| --------------------------------------------------------------------------------------------------------------------- |
| Base Mainnet    | [0x00000000a0a3A66B67c805563Ea4AB0F76EF8a84](https://basescan.org/address/0x00000000a0a3A66B67c805563Ea4AB0F76EF8a84) |


## Important Notes
The contract had not been audited and only passed [minimal unit testing](https://github.com/0xkuwabatake/SSTORE2Factory/blob/main/test/SSTORE2Factory.t.sol), so use it with caution.