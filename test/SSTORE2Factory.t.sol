// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/SSTORE2Factory.sol";

contract SSTORE2FactoryTest is Test {
    SSTORE2Factory factory;

    address constant _RECEIVER = 0x9500E1518EcBD22e5AfCB39daadb93617707b588;

    event Pointer(uint256 index, address pointer);
    event Pointer(address pointer);

    error Unauthorized();
    error ArrayLengthMismatch();

    function setUp() public {
        factory = new SSTORE2Factory();
    }

    function test_EmitPointer_Write() public {
        bytes memory data = "0x123456789abcedef";
        vm.expectEmit();
        emit Pointer(0x104fBc016F4bb334D775a19E8A6510109AC63E00);
        factory.write(data);
    }

    function test_EmitPointer_BatchWrite() public {
        bytes[] memory data = _getArrayOfData();

        vm.expectEmit();
        emit Pointer(0, 0x104fBc016F4bb334D775a19E8A6510109AC63E00);
        emit Pointer(1, 0x037eDa3aDB1198021A9b2e88C22B464fD38db3f3);
        emit Pointer(2, 0xDDc10602782af652bB913f7bdE1fD82981Db7dd9);
        factory.write(data);
    }

    function test_EmitPointer_WriteCounterfactual() public {
        bytes memory data = "0x123456789abcedef";
        bytes32 salt = 0x085cfce4666f58f44ff4b5c6b7ec5cdb72c2eb18f83600af9d2f9bd1636c6f1c;

        address predicted = factory.predictCounterfactualAddress(data, salt);

        vm.expectEmit();
        emit Pointer(predicted);
        factory.writeCounterfactual(data, salt);
    }

    function test_EmitPointer_BatchWriteCounterfactual() public {
        bytes[] memory data = _getArrayOfData();
        bytes32[] memory salt = _getArrayOfSalt();

        address predicted0 = factory.predictCounterfactualAddress(data[0], salt[0]);
        address predicted1 = factory.predictCounterfactualAddress(data[1], salt[1]);
        address predicted2 = factory.predictCounterfactualAddress(data[2], salt[2]);

        vm.expectEmit();
        emit Pointer(0, predicted0);
        emit Pointer(1, predicted1);
        emit Pointer(2, predicted2);
        factory.writeCounterfactual(data, salt);
    }

    function test_EmitPointer_WriteDeterministic() public {
        bytes memory data = "0x123456789abcedef";
        bytes32 salt = 0x085cfce4666f58f44ff4b5c6b7ec5cdb72c2eb18f83600af9d2f9bd1636c6f1c;

        address predicted = factory.predictDeterministicAddress(salt);

        vm.expectEmit();
        emit Pointer(predicted);
        factory.writeDeterministic(data, salt);
    }

    function test_EmitPointer_BatchWriteDeterministic() public {
        bytes[] memory data = _getArrayOfData();
        bytes32[] memory salt = _getArrayOfSalt();

        address predicted0 = factory.predictDeterministicAddress(salt[0]);
        address predicted1 = factory.predictDeterministicAddress(salt[1]);
        address predicted2 = factory.predictDeterministicAddress(salt[2]);

        vm.expectEmit();
        emit Pointer(0, predicted0);
        emit Pointer(1, predicted1);
        emit Pointer(2, predicted2);
        factory.writeDeterministic(data, salt);
    }

    function test_RevertIf_WriteCounterfactual_WhenArrayLengthOfArgumentsIsMismatch() public {
        bytes[] memory data = _getArrayOfData();
        bytes32[] memory salt = new bytes32[](2);
        salt[0] = 0x085cfce4666f58f44ff4b5c6b7ec5cdb72c2eb18f83600af9d2f9bd1636c6f1c;
        salt[1] = 0x01f96fdc02e731bed05290ce1c01891d27b1d72e321310089f2ac64e87f07271;

        vm.expectRevert(ArrayLengthMismatch.selector);
        factory.writeCounterfactual(data, salt);
    }

    function test_RevertIf_WriteDeterministic_WhenArrayLengthOfArgumentsIsMismatch() public {
        bytes[] memory data = _getArrayOfData();
        bytes32[] memory salt = new bytes32[](2);
        salt[0] = 0x085cfce4666f58f44ff4b5c6b7ec5cdb72c2eb18f83600af9d2f9bd1636c6f1c;
        salt[1] = 0x01f96fdc02e731bed05290ce1c01891d27b1d72e321310089f2ac64e87f07271;

        vm.expectRevert(ArrayLengthMismatch.selector);
        factory.writeDeterministic(data, salt);
    }

    function test_Withdraw() public {
        uint256 contractBalanceBefore = address(factory).balance;
        assertEq(contractBalanceBefore, 0);

        hoax(address(0xA11CE), 1 ether);
        bytes memory data = "0x123456789abcedef";
        factory.write{value: 0.001 ether}(data);

        uint256 contractBalanceAfter = address(factory).balance;
        assertEq(contractBalanceAfter, 0.001 ether);

        vm.prank(address(_RECEIVER));
        factory.withdraw();

        uint256 contractBalanceAfterWithdraw = address(factory).balance;
        assertEq(contractBalanceAfterWithdraw, 0);
    }

    function test_RevertIf_Withdraw_WhenTheCallerIsNotReceiver() public {
        uint256 contractBalanceBefore = address(factory).balance;
        assertEq(contractBalanceBefore, 0);

        hoax(address(0xA11CE), 1 ether);
        bytes memory data = "0x123456789abcedef";
        factory.write{value: 0.001 ether}(data);

        uint256 contractBalanceAfter = address(factory).balance;
        assertEq(contractBalanceAfter, 0.001 ether);

        vm.prank(address(0xBAD));
        vm.expectRevert(Unauthorized.selector);
        factory.withdraw();
    }

    function _getArrayOfData() internal pure returns (bytes[] memory) {
        bytes[] memory data = new bytes[](3);
        data[0] = "0x7768617420746865206675636b";
        data[1] = "0x123456789abcedef";
        data[2] = "0x";
        return data;
    }

    function _getArrayOfSalt() internal pure returns (bytes32[] memory) {
        bytes32[] memory salt = new bytes32[](3);
        salt[0] = 0x085cfce4666f58f44ff4b5c6b7ec5cdb72c2eb18f83600af9d2f9bd1636c6f1c;
        salt[1] = 0x01f96fdc02e731bed05290ce1c01891d27b1d72e321310089f2ac64e87f07271;
        salt[2] = 0x97ffde8f93071e7e114475c8259750d4f76de53b0fed8e9360280726f7de5481;
        return salt;
    }
}