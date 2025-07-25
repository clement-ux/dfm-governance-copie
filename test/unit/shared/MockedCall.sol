// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {Vm} from "forge-std/Vm.sol";

library MockedCall {
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    // --- Vault ---
    function notifyRegisteredId(address receiver) public {
        vm.mockCall({
            callee: receiver,
            data: abi.encodeWithSignature("notifyRegisteredId(uint256[])"),
            returnData: abi.encode(true)
        });
    }

    function getReceiverVotePct(address callee, uint256 id, uint256 epoch, uint256 pct) public {
        vm.mockCall({
            callee: callee,
            data: abi.encodeWithSignature("getReceiverVotePct(uint256,uint256)", id, epoch),
            returnData: abi.encode(pct)
        });
    }
}
