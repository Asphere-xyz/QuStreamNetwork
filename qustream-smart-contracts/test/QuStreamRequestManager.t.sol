// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../contracts/QuStreamRequestManager.sol";

contract QuStreamRequestManagerTest is Test {
    QuStreamRequestManager qustreamRequestManager;
    address owner = address(0x1);
    address masterNode = address(0x4);
    address user = address(0x5);

    function setUp() public {
        // Fail: zero address in whitelist
        qustreamRequestManager = new QuStreamRequestManager(owner, masterNode);
    }

    function testConstructorRevertsOnZeroAddressesAndPercentage() public {
        // Fail: master node zero
        vm.expectRevert("master node zero");
        new QuStreamRequestManager(address(1), address(0));
    }

    function testSetMasterNode() public {
        // Success: owner sets master node address
        vm.expectEmit(address(qustreamRequestManager));
        emit QuStreamRequestManager.MasterNodeUpdated(user);
        vm.prank(owner);
        qustreamRequestManager.setMasterNode(user);
        assertEq(qustreamRequestManager._masterNode(), user);

        // Fail: only owner can set master node address
        vm.expectRevert();
        vm.prank(user);
        qustreamRequestManager.setMasterNode(owner);

        // Fail: zero address
        vm.expectRevert("zero address");
        vm.prank(owner);
        qustreamRequestManager.setMasterNode(address(0));
    }

    function testReceiveReverts() public {
        // Fail: ETH send reverts
        vm.deal(user, 1 ether);
        vm.expectRevert("direct sends not accepted");
        vm.prank(user);
        address(qustreamRequestManager).call{value: 1 ether}("");
    }

    function testRegisterRequest() public {
        // Success
        vm.expectEmit(address(qustreamRequestManager));
        emit QuStreamRequestManager.RequestRegistered(1, user, "user1", "qBlockData");
        vm.prank(user);
        uint256 id = qustreamRequestManager.registerRequest("user1", "qBlockData");
        assertEq(id, 1);
        (uint256 rid, address sender, string memory userID, string memory qBlock) = qustreamRequestManager._requests(id);
        assertEq(rid, id);
        assertEq(sender, user);
        assertEq(userID, "user1");
        assertEq(qBlock, "qBlockData");

        // Success: id auto increments and accepts empty strings
        vm.expectEmit(address(qustreamRequestManager));
        emit QuStreamRequestManager.RequestRegistered(2, user, "", "");
        vm.prank(user);
        uint256 id2 = qustreamRequestManager.registerRequest("", "");
        assertEq(id2, 2);
        (uint256 rid2,, string memory userID2, string memory qBlock2) = qustreamRequestManager._requests(id2);
        assertEq(rid2, id2);
        assertEq(userID2, "");
        assertEq(qBlock2, "");
    }

    // Whitelist logic removed: contract no longer supports node whitelisting

    function testProcessRequest() public {
        // Success: process as Success
        vm.prank(user);
        uint256 id = qustreamRequestManager.registerRequest("", "");
        vm.expectEmit(address(qustreamRequestManager));
        emit QuStreamRequestManager.RequestStatusUpdated(id, QuStreamRequestManager.Status.Success);
        vm.prank(masterNode);
        qustreamRequestManager.processRequest(id, QuStreamRequestManager.Status.Success);
        (uint256 rid,,,) = qustreamRequestManager._requests(id);
        assertEq(rid, 0); // deleted

        // Success: process as Fail
        vm.prank(user);
        id = qustreamRequestManager.registerRequest("", "");
        vm.expectEmit(address(qustreamRequestManager));
        emit QuStreamRequestManager.RequestStatusUpdated(id, QuStreamRequestManager.Status.Fail);
        vm.prank(masterNode);
        qustreamRequestManager.processRequest(id, QuStreamRequestManager.Status.Fail);
        (uint256 rid2,,,) = qustreamRequestManager._requests(id);
        assertEq(rid2, 0); // deleted

        // Fail: not master node
        address notMaster = address(0x999);
        vm.prank(user);
        id = qustreamRequestManager.registerRequest("", "");
        vm.expectRevert("not authorized");
        vm.prank(notMaster);
        qustreamRequestManager.processRequest(id, QuStreamRequestManager.Status.Success);

        // Fail: nonexistent request
        vm.expectRevert("request does not exist or is already processed");
        vm.prank(masterNode);
        qustreamRequestManager.processRequest(999, QuStreamRequestManager.Status.Success);

        // Fail: invalid status
        vm.expectRevert("invalid status");
        vm.prank(masterNode);
        qustreamRequestManager.processRequest(id, QuStreamRequestManager.Status.Pending);
    }
}

