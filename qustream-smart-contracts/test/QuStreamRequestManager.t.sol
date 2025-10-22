// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/QuStreamRequestManager.sol";

contract QuStreamRequestManagerTest is Test {
    QuStreamRequestManager qustreamRequestManager;
    address owner = address(0x1);
    address feeOwner = address(0x2);
    address qustreamFeeOwner = address(0x2);
    address encryptionNodeFeeOwner = address(0x3);
    address masterNode = address(0x4);
    address user = address(0x5);
    uint256 userFee = 1 ether;
    uint256 qustreamFeePercentage = 40;

    function setUp() public {
        // Fail: zero address in whitelist
        qustreamRequestManager = new QuStreamRequestManager(
            owner, qustreamFeeOwner, encryptionNodeFeeOwner, masterNode, userFee, qustreamFeePercentage
        );
    }

    function testConstructorRevertsOnZeroAddressesAndPercentage() public {
        // Fail: qustream fee owner zero
        vm.expectRevert("qustream fee owner zero");
        new QuStreamRequestManager(address(1), address(0), address(2), address(3), 1 ether, 40);

        // Fail: encryption node fee owner zero
        vm.expectRevert("encryption node fee owner zero");
        new QuStreamRequestManager(address(1), address(2), address(0), address(3), 1 ether, 40);

        // Fail: master node zero
        vm.expectRevert("master node zero");
        new QuStreamRequestManager(address(1), address(2), address(3), address(0), 1 ether, 40);

        // Fail: percentage > 100
        vm.expectRevert("percentage>100");
        new QuStreamRequestManager(address(1), address(2), address(3), address(4), 1 ether, 101);
    }

    function testSetQuStreamFeeOwner() public {
        // Success: owner sets fee owner
        vm.expectEmit(address(qustreamRequestManager));
        emit QuStreamRequestManager.QuStreamFeeOwnerUpdated(user);
        vm.prank(owner);
        qustreamRequestManager.setQuStreamFeeOwner(user);
        assertEq(qustreamRequestManager._qustreamFeeOwner(), user);

        // Fail: only owner can set fee owner
        vm.expectRevert();
        vm.prank(user);
        qustreamRequestManager.setQuStreamFeeOwner(owner);

        // Fail: zero address
        vm.expectRevert("zero address");
        vm.prank(owner);
        qustreamRequestManager.setQuStreamFeeOwner(address(0));
    }

    function testSetEncryptionNodeFeeOwner() public {
        // Success: owner sets encryption node fee owner
        vm.expectEmit(address(qustreamRequestManager));
        emit QuStreamRequestManager.EncryptionNodeFeeOwnerUpdated(user);
        vm.prank(owner);
        qustreamRequestManager.setEncryptionNodeFeeOwner(user);
        assertEq(qustreamRequestManager._encryptionNodeFeeOwner(), user);

        // Fail: only owner can set encryption node fee owner
        vm.expectRevert();
        vm.prank(user);
        qustreamRequestManager.setEncryptionNodeFeeOwner(owner);

        // Fail: zero address
        vm.expectRevert("zero address");
        vm.prank(owner);
        qustreamRequestManager.setEncryptionNodeFeeOwner(address(0));
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

    function testSetUserFee() public {
        // Success: owner sets user fee
        vm.expectEmit(address(qustreamRequestManager));
        emit QuStreamRequestManager.UserFeeUpdated(2 ether);
        vm.prank(owner);
        qustreamRequestManager.setUserFee(2 ether);
        assertEq(qustreamRequestManager._userFee(), 2 ether);

        // Fail: only owner can set user fee
        vm.expectRevert();
        vm.prank(user);
        qustreamRequestManager.setUserFee(3 ether);
    }

    function testSetQuStreamFeePercentage() public {
        // Success: owner sets fee percentage
        vm.expectEmit(address(qustreamRequestManager));
        emit QuStreamRequestManager.QuStreamFeePercentageUpdated(50);
        vm.prank(owner);
        qustreamRequestManager.setQuStreamFeePercentage(50);
        assertEq(qustreamRequestManager._qustreamFeePercentage(), 50);

        // Fail: only owner can set fee percentage
        vm.expectRevert();
        vm.prank(user);
        qustreamRequestManager.setQuStreamFeePercentage(30);

        // Fail: percentage > 100
        vm.expectRevert("percentage>100");
        vm.prank(owner);
        qustreamRequestManager.setQuStreamFeePercentage(101);
    }

    function testReceiveReverts() public {
        // Fail: Direct ETH send reverts
        vm.deal(user, 1 ether);
        vm.expectRevert("direct sends not accepted; use registerRequest()");
        vm.prank(user);
        address(qustreamRequestManager).call{value: 1 ether}("");
    }

    function testRegisterRequest() public {
        // Success: correct fee
        vm.deal(user, 2 ether);
        vm.expectEmit(address(qustreamRequestManager));
        emit QuStreamRequestManager.RequestRegistered(1, user, userFee);
        vm.prank(user);
        uint256 id = qustreamRequestManager.registerRequest{value: userFee}();
        assertEq(id, 1);
        (uint256 rid, address sender, QuStreamRequestManager.Status status, uint256 paidFee) =
            qustreamRequestManager._requests(id);
        assertEq(rid, id);
        assertEq(sender, user);
        assertEq(uint256(status), uint256(QuStreamRequestManager.Status.Pending));
        assertEq(paidFee, userFee);

        // Success: id auto increments
        vm.deal(user, 2 ether);
        vm.expectEmit(address(qustreamRequestManager));
        emit QuStreamRequestManager.RequestRegistered(2, user, userFee);
        vm.prank(user);
        uint256 id2 = qustreamRequestManager.registerRequest{value: userFee}();
        assertEq(id2, 2);
        (uint256 rid2,,,) = qustreamRequestManager._requests(id2);
        assertEq(rid2, id2);

        // Fail: incorrect fee
        vm.deal(user, 2 ether);
        vm.expectRevert("incorrect fee");
        qustreamRequestManager.registerRequest{value: 0.5 ether}();
    }

    // Whitelist logic removed: contract no longer supports node whitelisting

    function testProcessRequest() public {
        // Success: process as Success
        vm.deal(user, 2 ether);
        vm.prank(user);
        uint256 id = qustreamRequestManager.registerRequest{value: userFee}();
        uint256 qustreamFee = (userFee * qustreamFeePercentage) / 100;
        uint256 nodeFee = userFee - qustreamFee;
        uint256 qustreamOwnerBalanceBefore = qustreamFeeOwner.balance;
        uint256 nodeOwnerBalanceBefore = encryptionNodeFeeOwner.balance;
        vm.expectEmit(address(qustreamRequestManager));
        emit QuStreamRequestManager.RequestStatusUpdated(id, QuStreamRequestManager.Status.Success);
        vm.expectEmit(address(qustreamRequestManager));
        emit QuStreamRequestManager.FeeDistributed(id, qustreamFee, nodeFee, qustreamFeeOwner, encryptionNodeFeeOwner);
        vm.prank(masterNode);
        qustreamRequestManager.processRequest(id, QuStreamRequestManager.Status.Success);
        (uint256 rid,,,) = qustreamRequestManager._requests(id);
        assertEq(rid, 0); // deleted
        assertEq(qustreamFeeOwner.balance, qustreamOwnerBalanceBefore + qustreamFee);
        assertEq(encryptionNodeFeeOwner.balance, nodeOwnerBalanceBefore + nodeFee);

        // Success: process as Fail
        vm.deal(user, 2 ether);
        vm.prank(user);
        id = qustreamRequestManager.registerRequest{value: userFee}();
        vm.expectEmit(address(qustreamRequestManager));
        emit QuStreamRequestManager.RequestStatusUpdated(id, QuStreamRequestManager.Status.Fail);
        vm.prank(masterNode);
        qustreamRequestManager.processRequest(id, QuStreamRequestManager.Status.Fail);
        (,, QuStreamRequestManager.Status status,) = qustreamRequestManager._requests(id);
        assertEq(uint256(status), uint256(QuStreamRequestManager.Status.Fail));

        // Fail: not master node
        address notMaster = address(0x999);
        vm.deal(user, 2 ether);
        vm.prank(user);
        id = qustreamRequestManager.registerRequest{value: userFee}();
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

