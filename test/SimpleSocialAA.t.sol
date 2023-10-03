// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {SimpleSocialAA} from "../src/SimpleSocialAA.sol";
import {SimpleAAv2} from "../src/SimpleAAv2.sol";
import {SimpleAAv3} from "../src/SimpleAAv3.sol";
import {SimpleAAv4} from "../src/SimpleAAv4.sol";
import {VmSafe} from "forge-std/Vm.sol";

contract SimpleAATest is Test {
    //SimpleSocialAA public saa;
    SimpleAAv3 saa;
    VmSafe.Wallet[10] wt;

    function setUp() public {
        //here you need to get 4 accounts. one for owner, and 3 for agents.

        for (uint256 i = 0; i < wt.length; i++) {
            wt[i] = vm.createWallet(i + 1000); //1000 is a random seed
        }

        //saa = new SimpleSocialAA(wt[0].addr);
        saa = new SimpleAAv3(wt[0].addr);
        vm.deal(address(this), 10 ether);
        (bool success,) = address(saa).call{value: 1 ether}("");
        assertEq(success, true);
    }

    function displayWalletData() public view {
        console2.log("***-***-");
        console2.log("address of saa", address(saa));
        console2.log("balance of saa", address(saa).balance);
        console2.log("owner/signer of saa", saa.owner());
        console2.log("num of agents for recovery", saa.numAgent());
        console2.log("number of min_agent_approval", saa.min_agent_approval());
        for (uint256 i = 0; i < saa.numAgent(); i++) {
            //console2.log("agent addr:", saa.agents_recordj(i));
        }
    }

    function testNewAA() public {
        new SimpleSocialAA(wt[0].addr);
    }

    function testNewAAv2() public {
        new SimpleAAv2(wt[0].addr);
    }

    function testNewAAv3() public {
        new SimpleAAv3(wt[0].addr);
    }

    function testNewAAv4() public {
        new SimpleAAv4(wt[0].addr);
    }

    function testAddAgent() public {
        vm.prank(wt[0].addr);
        bool b_rst = saa.addAgent(wt[1].addr);
        console2.log("add agent return value: ", b_rst);
        assertEq(b_rst, true);
        assertEq(saa.numAgent(), 1);
        displayWalletData();
    }

    function testFailAddAgentNotByOwner() public {
        bool b_rst = saa.addAgent(wt[1].addr);
        assertEq(b_rst, false);
    }

    function testFailChangeOwnerInsuf() public {
        //you need to add 3 agents, and let 1 propose and another 1 approve.
        displayWalletData();

        // add 3 agents
        vm.startPrank(wt[0].addr);
        saa.addAgent(wt[1].addr);
        saa.addAgent(wt[2].addr);
        saa.addAgent(wt[3].addr);
        saa.addAgent(wt[4].addr);
        saa.addAgent(wt[5].addr);
        saa.removeAgent(wt[5].addr);
        vm.stopPrank();

        displayWalletData();

        // first agent propose change
        vm.prank(wt[1].addr);
        saa.proposeChangeOwner(wt[9].addr);

        console2.log("owner before:", saa.owner());
        assertEq(saa.owner(), wt[0].addr);

        vm.prank(wt[3].addr);
        saa.approveProposedOwner(wt[9].addr); // the approve should be success

        console2.log("owner after:", saa.owner());
        assertEq(saa.owner(), wt[9].addr);
    }

    function testChangeOwner() public {
        //you need to add 3 agents, and let 1 propose and another 1 approve.
        displayWalletData();

        // add 3 agents
        vm.startPrank(wt[0].addr);
        saa.addAgent(wt[1].addr);
        saa.addAgent(wt[2].addr);
        saa.addAgent(wt[3].addr);
        vm.stopPrank();

        displayWalletData();

        // first agent propose change
        vm.prank(wt[1].addr);
        saa.proposeChangeOwner(wt[9].addr);

        console2.log("owner before:", saa.owner());
        assertEq(saa.owner(), wt[0].addr);

        vm.prank(wt[2].addr);
        saa.approveProposedOwner(wt[9].addr); // the approve should be success

        console2.log("owner after:", saa.owner());
        assertEq(saa.owner(), wt[9].addr);
    }

    struct TestStruct {
        uint256 a;
        uint256 b;
        uint256 c;
    }

    function testStructGas1() public pure returns (bytes memory) {
        TestStruct memory a = TestStruct((123), 100, 200);
        return abi.encode(a.a, a.b, a.c);
    }

    function testStructGas2a() public pure returns (bytes memory) {
        TestStruct memory a = TestStruct((123), 100, 200);
        uint256 aa = a.a;
        return abi.encode(aa, a.b, a.c);
    }

    function testStructGas2() public pure returns (bytes memory) {
        TestStruct memory a = TestStruct((123), 100, 200);
        uint256 c = a.c;
        return abi.encode(a.a, a.b, c);
    }

    function testStructGas3() public pure returns (bytes memory) {
        TestStruct memory a = TestStruct((123), 100, 200);
        uint256 b = a.b;
        uint256 c = a.c;
        return abi.encode(a.a, b, c);
    }

    function testStructGas4() public pure returns (bytes memory) {
        TestStruct memory a = TestStruct((123), 100, 200);
        uint256 a1 = a.a;
        uint256 b = a.b;
        uint256 c = a.c;
        return abi.encode(a1, b, c);
    }
}
