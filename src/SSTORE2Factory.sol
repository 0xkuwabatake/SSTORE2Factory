// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SSTORE2} from "lib/solady/src/utils/SSTORE2.sol";

/**
 * @title  SSTORE2Factory
 * @author 0xkuwabatake(0xkuwabatake)
 * @notice A factory contract to deploy any arbitrary `data` with or without `salt`
 *         as storage contract.
 * @dev    All of the methods of this contract are just external or public visibility methods
 *         to utilize Solady-SSTORE2 library by vectorized.eth:
 *         https://github.com/Vectorized/solady/blob/main/src/utils/SSTORE2.sol
 *        
 * @custom:notes
 * - The main purpose of this contract is to get the storage contract address or `pointer` 
 *   from each `data` either with or without `salt` (it depends on which method is being called)
 *   that has been deployed as a storage contract and then stored its value at another contract 
 *   independently from this contract.
 *   Because of that reason, neither storage provided by this contract to store the `pointer`
 *   nor a tracker to track if a `pointer` from a `data` either with or without `salt`
 *   had been deployed or not.
 * - To get the value of `pointer` with or without its `index` is/are queryable 
 *   via emitted {Pointer} event from each successful transaction.
 * - Every state-changing method is marked as payable merely for the sake of gas optimization,
 *   meaning the caller does NOT need to send ether to this contract when sending a transaction.
 *   Therefore, make sure to always set msg.value to 0 (zero) before calling a method.
 * 
 * @custom:warning
 * - This contract has the capability to receive ether,
 *   therefore a withdrawal function to `_RECEIVER` is provided 
 *   just in case the ether balance of this contract is non-zero. 
 *   With this feature, it does not mean the `_RECEIVER` must refund the received ether 
 *   to whichever caller address had sent ether to this contract.
 */
contract SSTORE2Factory { 

    /*//////////////////////////////////////////////////////////////
                                CONSTANT
    //////////////////////////////////////////////////////////////*/

    /// @dev Ether receiver address.
    address private constant _RECEIVER = 0x9500E1518EcBD22e5AfCB39daadb93617707b588;

    /*//////////////////////////////////////////////////////////////
                            CUSTOM EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Emitted when data is written as storage contract and return its `pointer` with `index`.
    event Pointer(uint256 index, address pointer);

    /// @dev Emitted when data is written as storage contract and return its `pointer`.
    event Pointer(address pointer);

    /*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @dev Revert with an error if {withdraw} function being called not by `_RECEIVER` address.
    error Unauthorized();

    /// @dev Revert with an error if length of array for `data` and `salt` arguments is mismatch.
    error ArrayLengthMismatch();

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @dev To save some gas during deployment.
    constructor() payable {}

    /*//////////////////////////////////////////////////////////////
                        RECEIVE & FALLBACK
    //////////////////////////////////////////////////////////////*/

    /// @dev To silence the compiler warning because of {fallback} function.
    receive() external payable {}

    /// @dev It's provided to receive calldata directly from a transaction.
    fallback() external payable {}

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL PAYABLE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Deploy `data` as a storage contract.
     * @param data The data that will be deployed via {SSTORE2 - write}.
     */
    function write(bytes calldata data) external payable {
        address pointer = SSTORE2.write(data);
        emit Pointer(pointer);
    }
 
    /**
     * @dev Deploy `data` as storage contract in batch.
     * @param data The data that will be deployed via {SSTORE2 - write}.
     */
    function write(bytes[] calldata data) external payable {
        uint256 i;
        do {
            address pointer = SSTORE2.write(data[i]);
            emit Pointer(i, pointer);
            unchecked { ++i; }
        } while (i != data.length);
    }
 
    /**
     * @dev Deploy `data` as a storage contract with `salt` and returns its counterfactual `pointer`.
     * @param data The data that will be deployed via {SSTORE2 - writeCounterFactual}.
     * @param salt The nonce that will be passed into {SSTORE2 - writeCounterfactual}.
     * @custom:note Once `data` with specific `salt` is deployed, it can't not be redeployed.
     */
    function writeCounterfactual(bytes calldata data, bytes32 salt) external payable {
        address pointer = SSTORE2.writeCounterfactual(data, salt);
        emit Pointer(pointer);
    }

    /**
     * @dev Deploy `data` as storage contract with `salt` in batch 
     * and returns its counterfactual `pointer`.
     * @param data The data that will be deployed via {SSTORE2 - writeCounterFactual}.
     * @param salt The nonce that will be passed into {SSTORE2 - writeCounterfactual}.
     * @custom:note Once `data` with specific `salt` is deployed, it can't not be redeployed.
     */
    function writeCounterfactual(bytes[] calldata data, bytes32[] calldata salt) external payable {
        if (data.length != salt.length) revert ArrayLengthMismatch();
        uint256 i;
        do {
            address pointer = SSTORE2.writeCounterfactual(data[i], salt[i]);
            emit Pointer(i, pointer);
            unchecked { ++i; }
        } while (i != data.length);
    }

    /**
     * @dev Deploy `data` as a storage contract with `salt` and returns its deterministic `pointer`.
     * @param data The data that will be deployed via {SSTORE2 - writeDeterministic}.
     * @param salt The nonce that will be passed into {SSTORE2 - writeDeterministic}.
     * @custom:note `salt` is no longer usable if it had been used to deploy `data` deterministically.
     */
    function writeDeterministic(bytes calldata data, bytes32 salt) external payable {
        address pointer = SSTORE2.writeDeterministic(data, salt);
        emit Pointer(pointer);
    }
 
    /**
     * @dev Deploy `data` as a storage contract with `salt` in batch 
     * and returns its deterministic `pointer`.
     * @param data The data that will be deployed via {SSTORE2 - writeDeterministic}.
     * @param salt The nonce that will be passed into {SSTORE2 - writeDeterministic}.
     * @custom:note `salt` is no longer usable if it had been used to deploy `data` deterministically.
     */
    function writeDeterministic(bytes[] calldata data, bytes32[] calldata salt) external payable {
        if (data.length != salt.length) revert ArrayLengthMismatch();
        uint256 i;
        do {
            address pointer = SSTORE2.writeDeterministic(data[i], salt[i]);
            emit Pointer(i, pointer);
            unchecked { ++i; }
        } while (i != data.length);
    }

    /**
     * @dev Withdraw all of ether balance from contract to `_RECEIVER`.
     * @custom:note See: https://github.com/Vectorized/solady/blob/main/src/utils/SafeTransferLib.sol
     */
    function withdraw() external payable {
        if (msg.sender != _RECEIVER) revert Unauthorized();
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            if iszero(call(100000, _RECEIVER, selfbalance(), codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, _RECEIVER) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(selfbalance(), 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Returns the CREATE2 address of the storage contract for `data` deployed with `salt`.
     * @param data The data that is intended to be deployed via {SSTORE2 - writeCounterFactual}.
     * @param salt The nonce that is intended to be passed into {SSTORE2 - writeCounterfactual}.
     * @return predicted The predicted deployed storage contract address.
     */
    function predictCounterfactualAddress(bytes memory data, bytes32 salt)
        public
        view
        returns (address predicted)
    {
        predicted = SSTORE2.predictCounterfactualAddress(data, salt);
    }
 
    /**
     * @dev Returns the "CREATE3" deterministic address for `salt`.
     * @param salt The nonce that is intended to be passed into {SSTORE2 - writeDeterministic}.
     * @return predicted The predicted deployed storage contract address.
     */
    function predictDeterministicAddress(bytes32 salt)
        public
        view
        returns (address predicted)
    {
        predicted = SSTORE2.predictDeterministicAddress(salt);
    }
 
    /**
     * @dev Returns `data` from `pointer`.
     * @param pointer The deployed storage contract address.
     * @return data The data from `pointer`.
     */
    function read(address pointer) public view returns (bytes memory data) {
        data = SSTORE2.read(pointer);
    }

    /**
     * @dev Returns the initialization code hash of the storage contract for `data`.
     * @param data The data that is intended to be deployed via {SSTORE2 - writeCounterFactual}.
     * @return hash The initialization code hash of the storage contract for `data`.
     * @custom:note It is used for mining vanity addresses with create2crunch.
     */
    function initCodeHash(bytes memory data) public pure returns (bytes32 hash) {
        hash = SSTORE2.initCodeHash(data);
    }
}