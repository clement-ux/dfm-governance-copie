// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

// External imports
import {StdAssertions} from "forge-std/StdAssertions.sol";
import {Vm} from "forge-std/Vm.sol";

abstract contract Assertions is StdAssertions {
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    function assertEq(uint16[2] memory array, uint16[2] memory expectedArray) internal pure {
        for (uint256 i = 0; i < array.length; i++) {
            assertEq(array[i], expectedArray[i], vm.toString(i));
        }
    }
}
